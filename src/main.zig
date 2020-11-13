const std = @import("std");
const base = @import("base.zig");
const c = base.c;
const vk = base.vk;
const vez = base.vez;
const convert = base.convert;
const VulkanError = base.VulkanError;
const stbi = @cImport({
    @cInclude("VEZ.h");
});

const mat = @import("zalgebra");
const mat4 = mat.mat4;
const vec = mat.vec3;

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

//[4][4]f32;

var id = mat4.identity(); // [4][4]f32{
//     .{ 1, 0, 0, 0 },
//     .{ 0, 1, 0, 0 },
//     .{ 0, 0, 1, 0 },
//     .{ 0, 0, 0, 1 },
// };

const UniformBuffer = struct {
    model: mat4,
    view: mat4,
    projection: mat4,
};

const Buffer = struct {
    handle: vk.Buffer, memory: vk.DeviceMemory
};

const PipelineDesc = struct {
    pipeline: vez.Pipeline = null,
    shaderModules: std.ArrayList(vk.ShaderModule),
};

var graphicsQueue: vk.Queue = null;
var vertexBuffer = Buffer{ .handle = null, .memory = null };
var indexBuffer = Buffer{ .handle = null, .memory = null };
var image: vk.Image = null;
var imageView: vk.ImageView = null;
var sampler: vk.Sampler = null;
var uniformBuffer: vk.Buffer = null;
var basicPipeline: PipelineDesc = undefined;
var commandBuffer: vk.CommandBuffer = null;

const allocator = std.heap.c_allocator;

fn bytewiseCopy(comptime T: type, data: []const T, dest: [*]u8) void {
    for (@ptrCast([*]const u8, data.ptr)[0..(data.len * @sizeOf(T))]) |byte, i| {
        dest[i] = byte;
    }
}

fn findMemoryType(physicalDevice: vk.PhysicalDevice, typeFilter: u32, properties: vk.MemoryPropertyFlags) u32 {
    var memProperties: vk.PhysicalDeviceMemoryProperties = undefined;
    vk.vkGetPhysicalDeviceMemoryProperties(physicalDevice, &memProperties);
    var i: u5 = 0;
    const mask: u32 = 1;
    while (i < memProperties.memoryTypeCount) : (i += 1) {
        if (typeFilter & (mask << i) != 0 and (memProperties.memoryTypes[i].propertyFlags & properties) == properties)
            return i;
    }

    return 0;
}

pub fn main() anyerror!void {
    try base.run(allocator, .{
        .name = "V-EZ-Test",
        .initialize = initialize,
        .cleanup = cleanup,
        .draw = draw,
        .onResize = onResize,
        .update = update,
    });
}

fn initialize() !void {
    try createQuad();
    try createTexture();
    try createSampler();
    try createUniformBuffer();
    try createPipeline();
    try createCommandBuffer();
}

fn cleanup() !void {
    var device = base.getDevice();
    vez.vezDestroyBuffer(device, vertexBuffer.handle);
    vk.vkFreeMemory(device, vertexBuffer.memory, null);
    vez.vezDestroyBuffer(device, indexBuffer.handle);
    vk.vkFreeMemory(device, indexBuffer.memory, null);
    vez.vezDestroyImageView(device, imageView);
    vez.vezDestroyImage(device, image);
    vez.vezDestroySampler(device, sampler);
    vez.vezDestroyBuffer(device, uniformBuffer);

    vez.vezDestroyPipeline(device, basicPipeline.pipeline);
    for (basicPipeline.shaderModules.items) |shaderModule| {
        vez.vezDestroyShaderModule(device, shaderModule);
    }

    vez.vezFreeCommandBuffers(device, 1, &commandBuffer);
}

fn draw() !void {
    // Request a wait semaphore to pass to present so it waits for rendering to complete.
    var semaphore: vk.Semaphore = null;

    const submitInfo = vez.SubmitInfo{
        .pNext = null,
        .waitSemaphoreCount = 0, // default
        .pWaitSemaphores = null, // default
        .pWaitDstStageMask = null, // default
        .commandBufferCount = 1,
        .pCommandBuffers = &commandBuffer,
        .signalSemaphoreCount = 1,
        .pSignalSemaphores = &semaphore,
    };
    try convert(vez.vezQueueSubmit(graphicsQueue, 1, &submitInfo, null));

    // Present the swapchain framebuffer to the window.
    const waitDstStageMask = @intCast(u32, vk.PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT); //VkPipelineStageFlags
    const swapchain = base.getSwapchain();
    const srcImage = base.getColorAttachment();

    const presentInfo = vez.PresentInfo{
        .pNext = null,
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
    try convert(vez.vezQueuePresent(graphicsQueue, &presentInfo)) catch |err| switch (err) {
        VulkanError.Suboptimal => {}, // hmmst
        else => err,
    };
}

fn onResize(width: u32, height: u32) !void {
    // Re-create command buffer.
    vez.vezFreeCommandBuffers(base.getDevice(), 1, &commandBuffer);
    try createCommandBuffer();
}

var runtime: f32 = 0;
fn update(deltaTime: f32) !void {
    var size = base.getWindowSize();
    runtime += deltaTime;
    // Calculate appropriate matrices for the current frame.
    var ub = UniformBuffer{
        .model = mat4.rotate(id, runtime * 10, vec.forward()),
        .view = mat.look_at(vec.new(2, 2, 2), vec.new(0, 0, 0), vec.forward()),
        .projection = mat.perspective(45, @intToFloat(f32, size[0]) / @intToFloat(f32, size[1]), 0.1, 10), //glm::perspective(glm::radians(45.0f), width / static_cast<float>(height), 0.1f, 10.0f),
    };
    //ub.projection[1][1] *= -1;

    var data: *UniformBuffer = undefined;
    try convert(vez.vezMapBuffer(base.getDevice(), uniformBuffer, 0, @sizeOf(UniformBuffer), @ptrCast(*?*c_void, &data)));
    data.* = ub;
    vez.vezUnmapBuffer(base.getDevice(), uniformBuffer);
}

fn createQuad() VulkanError!void {
    // A single quad with positions, normals and uvs.
    var vertices = [_]Vertex{
        .{ .x = -1, .y = -1, .z = 0, .nx = 0, .ny = 0, .nz = 1, .u = 0, .v = 0 },
        .{ .x = 1, .y = -1, .z = 0, .nx = 0, .ny = 0, .nz = 1, .u = 1, .v = 0 },
        .{ .x = 1, .y = 1, .z = 0, .nx = 0, .ny = 0, .nz = 1, .u = 1, .v = 1 },
        .{ .x = -1, .y = 1, .z = 0, .nx = 0, .ny = 0, .nz = 1, .u = 0, .v = 1 },
    };

    // Create the device side vertex buffer.
    var bufferCreateInfo = vez.BufferCreateInfo{
        .pNext = null,
        .size = @sizeOf(@TypeOf(vertices)),
        .usage = vk.BUFFER_USAGE_TRANSFER_DST_BIT | vk.BUFFER_USAGE_VERTEX_BUFFER_BIT,
        .queueFamilyIndexCount = 0, // default
        .pQueueFamilyIndices = null, // default
    };
    try convert(vez.vezCreateBuffer(base.getDevice(), vez.MEMORY_NO_ALLOCATION, &bufferCreateInfo, &vertexBuffer.handle));
    // Allocate memory for the buffer.
    var memRequirements: vk.MemoryRequirements = undefined;
    vk.vkGetBufferMemoryRequirements(base.getDevice(), vertexBuffer.handle, &memRequirements);

    var allocInfo = vk.MemoryAllocateInfo{
        .sType = .STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO,
        .pNext = null,
        .allocationSize = memRequirements.size,
        .memoryTypeIndex = findMemoryType(base.getPhysicalDevice(), memRequirements.memoryTypeBits, vk.MEMORY_PROPERTY_HOST_VISIBLE_BIT | vk.MEMORY_PROPERTY_HOST_COHERENT_BIT),
    };

    try convert(vk.vkAllocateMemory(base.getDevice(), &allocInfo, null, &vertexBuffer.memory));

    // Bind the memory to the buffer.
    try convert(vk.vkBindBufferMemory(base.getDevice(), vertexBuffer.handle, vertexBuffer.memory, 0));

    // Upload the buffer data.
    var pData: [*]u8 = undefined;
    try convert(vk.vkMapMemory(base.getDevice(), vertexBuffer.memory, 0, memRequirements.size, 0, @ptrCast(*?*c_void, &pData)));
    bytewiseCopy(Vertex, &vertices, pData);
    vk.vkUnmapMemory(base.getDevice(), vertexBuffer.memory);

    // A single quad with positions, normals and uvs.
    const indices = [_]u32{
        0, 1, 2,
        0, 2, 3,
    };

    // Create the device side index buffer.
    bufferCreateInfo.size = @sizeOf(@TypeOf(indices));
    bufferCreateInfo.usage = vk.BUFFER_USAGE_TRANSFER_DST_BIT | vk.BUFFER_USAGE_INDEX_BUFFER_BIT;
    try convert(vez.vezCreateBuffer(base.getDevice(), vez.MEMORY_NO_ALLOCATION, &bufferCreateInfo, &indexBuffer.handle));

    // Allocate memory for the buffer.
    vk.vkGetBufferMemoryRequirements(base.getDevice(), indexBuffer.handle, &memRequirements);

    allocInfo.allocationSize = memRequirements.size;
    allocInfo.memoryTypeIndex = findMemoryType(base.getPhysicalDevice(), memRequirements.memoryTypeBits, vk.MEMORY_PROPERTY_HOST_VISIBLE_BIT | vk.MEMORY_PROPERTY_HOST_COHERENT_BIT);
    try convert(vk.vkAllocateMemory(base.getDevice(), &allocInfo, null, &indexBuffer.memory));

    // Bind the memory to the buffer.
    try convert(vk.vkBindBufferMemory(base.getDevice(), indexBuffer.handle, indexBuffer.memory, 0));

    // Upload the buffer data.
    try convert(vk.vkMapMemory(base.getDevice(), indexBuffer.memory, 0, memRequirements.size, 0, @ptrCast(*?*c_void, &pData)));
    bytewiseCopy(u32, &indices, pData);
    vk.vkUnmapMemory(base.getDevice(), indexBuffer.memory);
}

fn createTexture() VulkanError!void {
    // Load image from disk.
    var width: i32 = undefined;
    var height: i32 = undefined;
    var channels: i32 = undefined;
    var pixelData = imageLoad("../../Samples/Data/Textures/texture.jpg", &width, &height, &channels, 4);

    // Create the base.GetDevice() side image.
    var imageCreateInfo = vez.ImageCreateInfo{
        .pNext = null,
        .flags = 0, // default
        .imageType = .IMAGE_TYPE_2D,
        .format = .FORMAT_R8G8B8A8_UNORM,
        .extent = .{ .width = @intCast(u32, width), .height = @intCast(u32, height), .depth = 1 },
        .mipLevels = 1,
        .arrayLayers = 1,
        .samples = .SAMPLE_COUNT_1_BIT,
        .tiling = .IMAGE_TILING_OPTIMAL,
        .usage = vk.IMAGE_USAGE_TRANSFER_DST_BIT | vk.IMAGE_USAGE_SAMPLED_BIT,
        .queueFamilyIndexCount = 0, // default
        .pQueueFamilyIndices = null, // default
    };
    try convert(vez.vezCreateImage(base.getDevice(), vez.MEMORY_GPU_ONLY, &imageCreateInfo, &image));

    // Upload the host side data.
    var subDataInfo = vez.ImageSubDataInfo{
        .imageSubresource = .{ .mipLevel = 0, .baseArrayLayer = 0, .layerCount = 1 },
        .imageOffset = .{ .x = 0, .y = 0, .z = 0 },
        .imageExtent = .{ .width = imageCreateInfo.extent.width, .height = imageCreateInfo.extent.height, .depth = 1 },
        .dataRowLength = 0,
        .dataImageHeight = 0,
    };
    try convert(vez.vezImageSubData(base.getDevice(), image, &subDataInfo, pixelData.ptr));

    imageFree(pixelData);

    // Create the image view for binding the texture as a resource.
    var imageViewCreateInfo = vez.ImageViewCreateInfo{
        .pNext = null,
        .components = base.map_ident, // default!
        .image = image,
        .viewType = .IMAGE_VIEW_TYPE_2D,
        .format = imageCreateInfo.format,
        .subresourceRange = .{ .layerCount = 1, .levelCount = 1, .baseMipLevel = 0, .baseArrayLayer = 0 }, // defaults
    };
    try convert(vez.vezCreateImageView(base.getDevice(), &imageViewCreateInfo, &imageView));
}

fn createSampler() VulkanError!void {
    const createInfo = vez.SamplerCreateInfo{
        .pNext = null,
        .magFilter = .FILTER_LINEAR, // default?
        .minFilter = .FILTER_LINEAR, // default?
        .mipmapMode = .SAMPLER_MIPMAP_MODE_LINEAR, // default?
        .addressModeU = .SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE, // default?
        .addressModeV = .SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE, // default?
        .addressModeW = .SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE, // default?
        .mipLodBias = 0, // default
        .anisotropyEnable = 0, // default
        .maxAnisotropy = 0, // default
        .compareEnable = 0, // default
        .compareOp = .COMPARE_OP_NEVER, // default
        .minLod = 0, // default
        .maxLod = 0, // default
        .borderColor = .BORDER_COLOR_FLOAT_TRANSPARENT_BLACK, // default
        .unnormalizedCoordinates = 0,
    };
    try convert(vez.vezCreateSampler(base.getDevice(), &createInfo, &sampler));
}

fn createUniformBuffer() VulkanError!void {
    const createInfo = vez.BufferCreateInfo{
        .pNext = null,
        .size = @sizeOf(UniformBuffer),
        .usage = vk.BUFFER_USAGE_TRANSFER_DST_BIT | vk.BUFFER_USAGE_UNIFORM_BUFFER_BIT,
        .queueFamilyIndexCount = 0, // default
        .pQueueFamilyIndices = null, // default
    };
    try convert(vez.vezCreateBuffer(base.getDevice(), vez.MEMORY_CPU_TO_GPU, &createInfo, &uniformBuffer));
}

fn createPipeline() !void {
    basicPipeline = PipelineDesc{
        .shaderModules = std.ArrayList(vk.ShaderModule).init(allocator),
    };
    var exe_path: []const u8 = try std.fs.selfExeDirPathAlloc(allocator);
    defer allocator.free(exe_path);
    var vert_path = try std.fs.path.join(allocator, &[_][]const u8{ exe_path, "shaders", "SimpleQuad.vert" });
    defer allocator.free(vert_path);
    var frag_path = try std.fs.path.join(allocator, &[_][]const u8{ exe_path, "shaders", "SimpleQuad.frag" });
    defer allocator.free(frag_path);

    try base.createPipeline(allocator, &[_]base.PipelineShaderInfo{
        .{ .filename = vert_path, .stage = .SHADER_STAGE_VERTEX_BIT },
        .{ .filename = frag_path, .stage = .SHADER_STAGE_FRAGMENT_BIT },
    }, &basicPipeline.pipeline, &basicPipeline.shaderModules);
}

fn createCommandBuffer() !void {
    vez.vezGetDeviceGraphicsQueue(base.getDevice(), 0, &graphicsQueue);

    // Create a command buffer handle.
    const allocInfo = vez.CommandBufferAllocateInfo{
        .pNext = null,
        .queue = graphicsQueue,
        .commandBufferCount = 1,
    };
    try convert(vez.vezAllocateCommandBuffers(base.getDevice(), &allocInfo, &commandBuffer));

    // Command buffer recording
    try convert(vez.vezBeginCommandBuffer(commandBuffer, vk.COMMAND_BUFFER_USAGE_SIMULTANEOUS_USE_BIT));

    var size = base.getWindowSize();
    const viewport = vk.Viewport{
        .x = 0.0, // default?
        .y = 0.0, // default?
        .width = @intToFloat(f32, size[0]),
        .height = @intToFloat(f32, size[1]),
        .minDepth = 0.0,
        .maxDepth = 1.0,
    };
    const scissor = vk.Rect2D{
        .offset = .{ .x = 0, .y = 0 },
        .extent = .{ .width = size[0], .height = size[1] },
    };
    vez.vezCmdSetViewport(0, 1, &[_]vk.Viewport{viewport});
    vez.vezCmdSetScissor(0, 1, &[_]vk.Rect2D{scissor});
    vez.vezCmdSetViewportState(1);

    // Define clear values for the swapchain's color and depth attachments.
    var attachmentReferences = [2]vez.AttachmentReference{
        .{
            .clearValue = .{ .color = .{ .float32 = .{ 0.3, 0.3, 0.3, 0.0 } } },
            .loadOp = .ATTACHMENT_LOAD_OP_CLEAR, // default?
            .storeOp = .ATTACHMENT_STORE_OP_STORE, // default?
        },
        .{
            .clearValue = .{ .depthStencil = .{ .depth = 1.0, .stencil = 0 } },
            .loadOp = .ATTACHMENT_LOAD_OP_CLEAR, // default?
            .storeOp = .ATTACHMENT_STORE_OP_STORE, // default?
        },
    };

    const beginInfo = vez.RenderPassBeginInfo{
        .pNext = null,
        .framebuffer = base.getFramebuffer(),
        .attachmentCount = @intCast(u32, attachmentReferences.len),
        .pAttachments = &attachmentReferences,
    };
    vez.vezCmdBeginRenderPass(&beginInfo);

    // Bind the pipeline and associated resources.
    vez.vezCmdBindPipeline(basicPipeline.pipeline);
    vez.vezCmdBindBuffer(uniformBuffer, 0, vk.WHOLE_SIZE, 0, 0, 0);
    vez.vezCmdBindImageView(imageView, sampler, 0, 1, 0);

    // Set push constants.
    //float blendColor[3] = { 1.0f, 1.0f, 1.0f };
    //vezCmdPushConstants(0, sizeof(float) * 3, &blendColor[0]);

    // Set depth stencil state.
    const depthStencilState = vez.PipelineDepthStencilState{
        .pNext = null,
        .depthBoundsTestEnable = 0, // default
        .stencilTestEnable = 0, // default
        .front = .{
            .failOp = .STENCIL_OP_KEEP,
            .passOp = .STENCIL_OP_KEEP,
            .depthFailOp = .STENCIL_OP_KEEP,
            .compareOp = .COMPARE_OP_NEVER,
        }, //  default!
        .back = .{
            .failOp = .STENCIL_OP_KEEP,
            .passOp = .STENCIL_OP_KEEP,
            .depthFailOp = .STENCIL_OP_KEEP,
            .compareOp = .COMPARE_OP_NEVER,
        }, // default!
        .depthTestEnable = vk.TRUE,
        .depthWriteEnable = vk.TRUE,
        .depthCompareOp = .COMPARE_OP_LESS_OR_EQUAL,
    };
    vez.vezCmdSetDepthStencilState(&depthStencilState);

    // Bind the vertex buffer and index buffers.
    const offset: vk.DeviceSize = 0;
    vez.vezCmdBindVertexBuffers(0, 1, &[_]vk.Buffer{vertexBuffer.handle}, &[_]u64{offset});
    vez.vezCmdBindIndexBuffer(indexBuffer.handle, 0, .INDEX_TYPE_UINT32);

    // Draw the quad.
    vez.vezCmdDrawIndexed(6, 1, 0, 0, 0);

    vez.vezCmdEndRenderPass();
    try convert(vez.vezEndCommandBuffer());
}

// abstracc

fn imageLoad(filename: []const u8, x: *i32, y: *i32, channels_in_file: *i32, desired_channels: i32) []const u8 {
    x.* = 2;
    y.* = 2;
    channels_in_file.* = 4;
    return &[_]u8{
        255, 0,   0,   0,
        0,   255, 0,   0,
        0,   0,   255, 0,
        0,   0,   0,   255,
    };
}

fn imageFree(img: []const u8) void {}
