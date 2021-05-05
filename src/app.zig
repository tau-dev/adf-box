const std = @import("std");
const Allocator = std.mem.Allocator;

const mat = @import("zalgebra");
const mat4 = mat.mat4;
const vec = mat.vec3;

const model = @import("model.zig");
usingnamespace @import("utils.zig");
const base = @import("main.zig");
const roundUp = base.roundUp;
const getKey = base.getKey;
const log = std.log;


pub const app_title = "adf-box";

const Vertex = struct {
    x: f32,
    y: f32,
    z: f32,
    nx: f32,
    ny: f32,
    nz: f32,
    u: f32,
    v: f32,
};

const UniformBuffer = struct {
    view: mat4,
    position: mat.vec4,
    buffer_size: i32,
    fov: f32,
    margin: f32 = 0.0001,
    limit: f32 = 4,
    light: mat.vec4,
    screeen_size: mat.vec2,
    intensity: f32 = 0.1,
};

const PipelineDesc = struct {
    pipeline: vez.Pipeline = null,
    shaderModules: []vk.ShaderModule,
};


var graphicsQueue: vk.Queue = null;
var vertexBuffer: Buffer = undefined;
var indexBuffer: Buffer = undefined;
var renderTexture: Image = undefined;
var values: Image = undefined;
var oct_data: Buffer = undefined;
var material_data: Buffer = undefined;

var uniform_buffer: vk.Buffer = null;
var drawPipeline: PipelineDesc = undefined;
var computePipeline: PipelineDesc = undefined;
var commandBuffer: vk.CommandBuffer = null;
var customCallback: vk.DebugUtilsMessengerEXT = null;

var lastPos = [2]i32{ 0, 0 };
var view = mat.vec2{ .x = 0, .y = 0 };
var position = vec.new(0.5, 0.5, -0.5);
var light = vec.new(-1, -2, -2);
var lookMode = false;
var bufferSize: i32 = 0;
var filename: []const u8 = "";

pub fn load(allocator: *Allocator) !void {
    var args = std.process.ArgIterator.init();

    var programName = if (args.next(allocator)) |program|
        try program
    else
        fail("<adf-box>");
    defer allocator.free(programName);


    if (args.next(allocator)) |file|
        filename = try file
    else
        fail(programName);

    if (args.next(allocator)) |d| {
        const depth = try d;
        defer allocator.free(depth);
        model.max_depth = std.fmt.parseInt(u32, depth, 10)
            catch |err| fail(programName);
    }

    try createModel(allocator);
}

fn fail(program_name: []const u8) noreturn {
    std.debug.print("usage: ${s} <filename> [depth]", .{program_name});
    std.os.exit(0);
}

pub fn initialize(allocator: *Allocator) !void {
    try createQuad();
    try createRenderTexture();
    try createUniformBuffer();
    try createPipeline(allocator);
    try createCommandBuffer();
}

pub fn cleanup() !void {
    var device = base.getDevice();
    vertexBuffer.deinit(device);
    indexBuffer.deinit(device);
    renderTexture.deinit(device);
    values.deinit(device);
    oct_data.deinit(device);
    material_data.deinit(device);
    vez.destroyBuffer(device, uniform_buffer);

    vez.destroyPipeline(device, drawPipeline.pipeline);
    for (drawPipeline.shaderModules) |shaderModule| {
        vez.destroyShaderModule(device, shaderModule);
    }
    vez.destroyPipeline(device, computePipeline.pipeline);
    for (computePipeline.shaderModules) |shaderModule| {
        vez.destroyShaderModule(device, shaderModule);
    }

    vez.freeCommandBuffers(device, 1, &commandBuffer);
}

pub fn draw() !void {
    var semaphore: vk.Semaphore = null;
//     var fence: vk.Fence = null;

    try convert(vez.deviceWaitIdle(base.getDevice()));
    const submitInfo = vez.SubmitInfo{
        .waitSemaphoreCount = 0, // default
        .pWaitSemaphores = null, // default
        .pWaitDstStageMask = null, // default
        .commandBufferCount = 1,
        .pCommandBuffers = &commandBuffer,
        .signalSemaphoreCount = 1,
        .pSignalSemaphores = &semaphore,
    };

    try convert(vez.queueSubmit(graphicsQueue, 1, &submitInfo, null));
    try convert(vez.deviceWaitIdle(base.getDevice()));
//     _ = vez.waitForFences(base.getDevice(), 1, &fence, 1, 10_000_000_000);
//     _ = vez.destroyFence(base.getDevice(), fence);

    // Present the swapchain framebuffer to the window.
    const waitDstStageMask = @intCast(u32, vk.PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT); //VkPipelineStageFlags

    const swapchain = base.getSwapchain();
    const srcImage = base.framebuffer.colorImage;

    // The glfw windowSizeCallback seems to sometimes come one frame late;
    // because V-EZ automatically resizes the swapchain (but not the framebuffer)
    // to fit the surface, we need to explicitly check this.
    var new_size: [2]c_int = undefined;
    const old_size = base.getWindowSize();
    c.glfwGetWindowSize(base.getWindow(), &new_size[0], &new_size[1]);
    if (new_size[0] != old_size[0] or new_size[1] != old_size[1]) {
        try base.resize();
        return;
    }

    const presentInfo = vez.PresentInfo{
        .signalSemaphoreCount = 0, // default
        .pSignalSemaphores = null, // default
        .pResults = null, // default

        .waitSemaphoreCount = 1,
        .pWaitSemaphores = &semaphore,
        .pWaitDstStageMask = &waitDstStageMask,
        .swapchainCount = 1,
        .pSwapchains = &swapchain,
        .pImages = &srcImage,
    };
    try convert(vez.queuePresent(graphicsQueue, &presentInfo)) catch |err| switch (err) {
        VulkanError.Suboptimal, // hmmst
        VulkanError.OutOfDate => {
            try base.resize();
        },
        else => err,
    };
}

pub fn onResize(width: u32, height: u32) !void {
    log.info("resized", .{});
    renderTexture.deinit(base.getDevice());
    try createRenderTexture();
    vez.freeCommandBuffers(base.getDevice(), 1, &commandBuffer);
    try createCommandBuffer();
}
pub fn onKey(key: i32, down: bool) anyerror!void {
    if (key == c.KEY_TAB and down) {
        base.toggleFullscreen();
    }
    if (key == c.KEY_ESCAPE and down) {
        base.quitSignaled = true;
    }
}
pub fn onMouseButton(button: i32, down: bool, x: i32, y: i32) anyerror!void {
    if (down) {
        lookMode = !lookMode;
        c.glfwSetInputMode(base.getWindow(), c.CURSOR, if (lookMode) c.CURSOR_HIDDEN else c.CURSOR_NORMAL);
    }
}

fn movePos(v: vec, time: f32) void {
    position = position.add(v.scale(transformSpeed * time));
}
fn matmul(matrix: mat4, v: vec) vec {
    var r = matrix.mult_by_vec4(mat.vec4.new(v.x, v.y, v.z, 1));
    return vec.new(r.x, r.y, r.z);
}

const turnSpeed = 0.1;
const transformSpeed = 0.3;
pub fn update(delta: f32) !void {
    var size = base.getWindowSize();
    if (lookMode) {
        const newPos = base.getCursorPos();
        var mouseDelta = mat.vec2{
            .x = @intToFloat(f32, -lastPos[0] + newPos[0]),
            .y = @intToFloat(f32, lastPos[1] - newPos[1]),
        };

        view.x = try std.math.mod(f32, view.x + mouseDelta.x * turnSpeed, 360);
        view.y = std.math.clamp(view.y + mouseDelta.y * turnSpeed, -90, 90);

        c.glfwSetCursorPos(base.getWindow(), @intToFloat(f64, size[0] / 2), @intToFloat(f64, size[1] / 2));
    }
    lastPos = base.getCursorPos();

    var viewMat = mat4.identity().rotate(view.x, vec.up()).rotate(view.y, vec.right());

    var v = delta;
    if (getKey(c.KEY_SPACE)) {
        v *= 0.25;
    }
    if (getKey(c.KEY_W) or getKey(c.KEY_KP_8)) {
        movePos(matmul(viewMat, vec.new(0, 0, 1)), v);
    }
    if (getKey(c.KEY_S) or getKey(c.KEY_KP_2)) {
        movePos(matmul(viewMat, vec.new(0, 0, -1)), v);
    }
    if (getKey(c.KEY_D) or getKey(c.KEY_KP_6)) {
        movePos(matmul(viewMat, vec.new(1, 0, 0)), v);
    }
    if (getKey(c.KEY_A) or getKey(c.KEY_KP_4)) {
        movePos(matmul(viewMat, vec.new(-1, 0, 0)), v);
    }
    if (getKey(c.KEY_LEFT_SHIFT) or getKey(c.KEY_KP_9)) {
        movePos(vec.new(0, -1, 0), v);
    }
    if (getKey(c.KEY_LEFT_CONTROL) or getKey(c.KEY_KP_3)) {
        movePos(vec.new(0, 1, 0), v);
    }
    var c0 = v * 2; // get it?
    if (getKey(c.KEY_U)) {
        light.x += c0;
    }
    if (getKey(c.KEY_J)) {
        light.x -= c0;
    }
    if (getKey(c.KEY_K)) {
        light.y += c0;
    }
    if (getKey(c.KEY_I)) {
        light.y -= c0;
    }
    if (getKey(c.KEY_O)) {
        light.z += c0;
    }
    if (getKey(c.KEY_L)) {
        light.z -= c0;
    }

    var ub = UniformBuffer{
        .view = viewMat,
        .position = mat.vec4.new(position.x, position.y, position.z, 1),
        .buffer_size = bufferSize,
        .fov = 0.4,
        .light = mat.vec4.new(light.x, light.y, light.z, 1),
        .intensity = 2,
        .screeen_size = mat.vec2.new(@intToFloat(f32, size[0]), @intToFloat(f32, size[1])),
    };

    var data: *UniformBuffer = undefined;
    try convert(vez.mapBuffer(base.getDevice(), uniform_buffer, 0, @sizeOf(UniformBuffer), @ptrCast(*?*c_void, &data)));
    data.* = ub;
    vez.unmapBuffer(base.getDevice(), uniform_buffer);
}

fn createQuad() VulkanError!void {
    // A single quad with positions, normals and uvs.
    var vertices: []const Vertex = &[_]Vertex{
        .{ .x = -1, .y = -1, .z = 0, .nx = 0, .ny = 0, .nz = 1, .u = 0, .v = 0 },
        .{ .x = 1, .y = -1, .z = 0, .nx = 0, .ny = 0, .nz = 1, .u = 1, .v = 0 },
        .{ .x = 1, .y = 1, .z = 0, .nx = 0, .ny = 0, .nz = 1, .u = 1, .v = 1 },
        .{ .x = -1, .y = 1, .z = 0, .nx = 0, .ny = 0, .nz = 1, .u = 0, .v = 1 },
    };

    try vertexBuffer.init(base.getDevice(), vk.BUFFER_USAGE_VERTEX_BUFFER_BIT, @sizeOf(Vertex)*vertices.len);
    try vertexBuffer.load(vertices);

    const indices: []const u32 = &[_]u32{
        0, 1, 2,
        0, 2, 3,
    };

    try indexBuffer.init(base.getDevice(), vk.BUFFER_USAGE_INDEX_BUFFER_BIT, @sizeOf(u32)*indices.len);
    try indexBuffer.load(indices);
}

fn createRenderTexture() !void {
    var extent = base.getWindowSize();
    const channels: u32 = 4;

    // Create the base.GetDevice() side image.
    var imageCreateInfo = vez.ImageCreateInfo{
        .format = .FORMAT_R8G8B8A8_UNORM,
        .extent = .{ .width = extent[0], .height = extent[1], .depth = 1 },
        .usage = vk.IMAGE_USAGE_TRANSFER_DST_BIT | vk.IMAGE_USAGE_SAMPLED_BIT | vk.IMAGE_USAGE_STORAGE_BIT,
    };
    try renderTexture.init(imageCreateInfo, .FILTER_LINEAR, .SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE);
}

fn createModel(allocator: *Allocator) !void {
    var arena = std.heap.ArenaAllocator.init(allocator);
    var data = try model.load(&arena.allocator, filename);
    allocator.free(filename);
    // defer data.deinit(allocator);
    defer arena.deinit();

    // Create the device side image.
    var imageCreateInfo = vez.ImageCreateInfo{
        .format = .FORMAT_R8G8B8A8_UNORM,
        .extent = .{ .width = data.width, .height = data.height, .depth = 1 },
        .usage = vk.IMAGE_USAGE_TRANSFER_DST_BIT | vk.IMAGE_USAGE_SAMPLED_BIT,
    };
    try values.init(imageCreateInfo, .FILTER_LINEAR, .SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE);

    var subDataInfo = vez.ImageSubDataInfo{
        .imageExtent = .{ .width = data.width, .height = data.height, .depth = 1 },
    };
    try convert(vez.vezImageSubData(base.getDevice(), values.texture, &subDataInfo, data.values.ptr));

    bufferSize = @intCast(i32, data.tree.len);
    try oct_data.init(base.getDevice(), vk.BUFFER_USAGE_STORAGE_BUFFER_BIT, data.tree.len * @sizeOf(model.ChildRefs));
    try oct_data.load(data.tree);

    try material_data.init(base.getDevice(), vk.BUFFER_USAGE_STORAGE_BUFFER_BIT, data.tree.len * @sizeOf(u32));
    try material_data.load(data.material);
}

fn createUniformBuffer() VulkanError!void {
    const createInfo = vez.BufferCreateInfo{
        .size = @sizeOf(UniformBuffer),
        .usage = vk.BUFFER_USAGE_TRANSFER_DST_BIT | vk.BUFFER_USAGE_UNIFORM_BUFFER_BIT,
    };
    try convert(vez.createBuffer(base.getDevice(), vez.MEMORY_CPU_TO_GPU, &createInfo, &uniform_buffer));
}

fn createPipeline(allocator: *Allocator) !void {
    drawPipeline = PipelineDesc{
        .shaderModules = try allocator.alloc(vk.ShaderModule, 2),
    };
    try base.createPipeline(allocator, &[_]base.PipelineShaderInfo{
        .{ .filename = "Vertex.vert", .spirv = true, .stage = .SHADER_STAGE_VERTEX_BIT },
        .{ .filename = "Fragment.frag", .spirv = true, .stage = .SHADER_STAGE_FRAGMENT_BIT },
    }, &drawPipeline.pipeline, drawPipeline.shaderModules);

    computePipeline = PipelineDesc{
        .shaderModules = try allocator.alloc(vk.ShaderModule, 1),
    };
    try base.createPipeline(allocator, &[_]base.PipelineShaderInfo{
        .{ .filename = "Compute.comp", .spirv = true, .stage = .SHADER_STAGE_COMPUTE_BIT },
    }, &computePipeline.pipeline, computePipeline.shaderModules);
}

fn createCommandBuffer() !void {
    vez.getDeviceGraphicsQueue(base.getDevice(), 0, &graphicsQueue);

    try convert(vez.allocateCommandBuffers(base.getDevice(), &vez.CommandBufferAllocateInfo{
        .queue = graphicsQueue,
        .commandBufferCount = 1,
    }, &commandBuffer));

    // Command buffer recording
    try convert(vez.beginCommandBuffer(commandBuffer, vk.COMMAND_BUFFER_USAGE_SIMULTANEOUS_USE_BIT));

    vez.cmdBindPipeline(computePipeline.pipeline);
    vez.cmdBindBuffer(uniform_buffer, 0, vk.WHOLE_SIZE, 0, 0, 0);
    vez.cmdBindBuffer(oct_data.handle, 0, vk.WHOLE_SIZE, 0, 1, 0);
    vez.cmdBindBuffer(material_data.handle, 0, vk.WHOLE_SIZE, 0, 2, 0);
    renderTexture.cmdBind(0, 3);
    values.cmdBind(0, 4);
    const extents = base.getWindowSize();
    const groupSize = 8;
    vez.cmdDispatch(roundUp(extents[0], groupSize), roundUp(extents[1], groupSize), 1);

    base.cmdSetFullViewport();
    vez.cmdSetViewportState(1);

    var attachmentReferences = [2]vez.AttachmentReference{
        .{ .clearValue = .{ .color = .{ .float32 = .{ 0.3, 0.3, 0.3, 0.0 } } } },
        .{ .clearValue = .{ .depthStencil = .{ .depth = 1.0, .stencil = 0 } } },
    };

    const beginInfo = vez.RenderPassBeginInfo{
        .framebuffer = base.framebuffer.handle,
        .attachmentCount = @intCast(u32, attachmentReferences.len),
        .pAttachments = &attachmentReferences,
    };
    vez.cmdBeginRenderPass(&beginInfo);

    vez.cmdBindPipeline(drawPipeline.pipeline);
    vez.cmdBindBuffer(uniform_buffer, 0, vk.WHOLE_SIZE, 0, 0, 0);
    renderTexture.cmdBind(0, 1);

    // Set depth stencil state.
    const depthStencilState = vez.PipelineDepthStencilState{
        .depthBoundsTestEnable = 0,
        .stencilTestEnable = 0,
        .depthCompareOp = .COMPARE_OP_LESS_OR_EQUAL,
        .depthTestEnable = vk.TRUE,
        .depthWriteEnable = vk.TRUE,
        .front = .{
            .failOp = .STENCIL_OP_KEEP,
            .passOp = .STENCIL_OP_KEEP,
            .depthFailOp = .STENCIL_OP_KEEP,
        }, //  default?
        .back = .{
            .failOp = .STENCIL_OP_KEEP,
            .passOp = .STENCIL_OP_KEEP,
            .depthFailOp = .STENCIL_OP_KEEP,
        }, // default?
    };
    vez.cmdSetDepthStencilState(&depthStencilState);

    vez.cmdBindVertexBuffers(0, 1, &[_]vk.Buffer{vertexBuffer.handle}, &[_]u64{0});
    vez.cmdBindIndexBuffer(indexBuffer.handle, 0, .INDEX_TYPE_UINT32);

    vez.cmdDrawIndexed(6, 1, 0, 0, 0);
    vez.cmdEndRenderPass();

    try convert(vez.endCommandBuffer());
}
