const std = @import("std");
usingnamespace @import("utils.zig");

const Allocator = std.mem.Allocator;

pub const PipelineShaderInfo = struct {
    filename: []const u8,
    spirv: bool,
    stage: vk.ShaderStageFlagBits,
};

const WIDTH = 600;
const HEIGHT = 400;
const NAME = "adf-box";

pub var manageFramebuffer = true;
pub var enableValidationLayers = true;
pub var quitSignaled = false;

const sampleCountFlag = .SAMPLE_COUNT_1_BIT;
const validation = "VK_LAYER_KHRONOS_validation"; //"VK_LAYER_LUNARG_standard_validation";
fn extendName(comptime name: []const u8) [256]u8 {
    var x = [1]u8{0} ** 256;
    var i: usize = 0;
    while (i < 256 and i < name.len) : (i += 1) {
        x[i] = name[i];
    }
    return x;
}

var window: *c.Window = undefined;
var windowWidth: i32 = 0;
var windowHeight: i32 = 0;
var instance: vk.Instance = undefined;
var physicalDevice: vk.PhysicalDevice = null;
var surface: vk.SurfaceKHR = null;
var device: vk.Device = null;
var swapchain: vez.Swapchain = null;

var keyMap: [c.KEY_LAST]bool = std.mem.zeroes([c.KEY_LAST]bool);
var callbacks: Callbacks = undefined;

pub fn getInstance() vk.Instance {
    return instance;
}
pub fn getPhysicalDevice() vk.PhysicalDevice {
    return physicalDevice;
}
pub fn getDevice() vk.Device {
    return device;
}
pub fn getSwapchain() vez.Swapchain {
    return swapchain;
}
pub fn getFramebuffer() vez.Framebuffer {
    return framebuffer.handle;
}
pub fn getColorAttachment() vk.Image {
    return framebuffer.colorImage;
}
pub fn getColorAttachmentView() vk.ImageView {
    return framebuffer.colorImageView;
}
pub fn getWindow() *c.Window {
    return window;
}
pub fn getWindowSize() [2]u32 {
    c.glfwGetWindowSize(window, &windowWidth, &windowHeight);
    return .{ @intCast(u32, windowWidth), @intCast(u32, windowHeight) };
}
pub fn hasWindowResized() bool {
    var new_width: i32 = 0;
    var new_height: i32 = 0;
    c.glfwGetWindowSize(window, &new_width, &new_height);
    return new_width != windowWidth or new_height != windowHeight;
}
pub fn getCursorPos() [2]i32 {
    var x: f64 = 0;
    var y: f64 = 0;
    c.glfwGetCursorPos(window, &x, &y);
    return .{ @floatToInt(i32, x), @floatToInt(i32, y) };
}
pub fn getKey(key: c_int) bool {
    return keyMap[@intCast(usize, key)];
}
pub fn roundUp(a: u32, b: u32) u32 {
    return (a + b - 1) / b;
}
pub fn toggleFullscreen() void {
    if (c.glfwGetWindowMonitor(window)) |_| {
        c.glfwSetWindowMonitor(window, null, 0, 0, WIDTH, HEIGHT, c.DONT_CARE);
    } else {
        const m = c.glfwGetPrimaryMonitor();
        const vidmode: *const c.Vidmode = c.glfwGetVideoMode(m);
        c.glfwSetWindowMonitor(window, m, 0, 0, vidmode.width, vidmode.height, c.DONT_CARE);
    }
}

var framebuffer = FrameBuffer{};
const FrameBuffer = struct {
    colorImage: vk.Image = null,
    colorImageView: vk.ImageView = null,
    depthStencilImage: vk.Image = null,
    depthStencilImageView: vk.ImageView = null,
    handle: vez.Framebuffer = null,
    
    fn deinit(self: FrameBuffer, dev: vk.Device) void {
        if (self.handle) |hndl| {
            vez.destroyFramebuffer(dev, self.handle);
            vez.destroyImageView(dev, self.colorImageView);
            vez.destroyImageView(dev, self.depthStencilImageView);
            vez.destroyImage(dev, self.colorImage);
            vez.destroyImage(dev, self.depthStencilImage);
        }
    }
};

const Callbacks = struct {
    resize: fn (width: u32, height: u32) anyerror!void,
    mousePos: fn (x: i32, y: i32) anyerror!void,
    mouseButton: fn (button: i32, down: bool, x: i32, y: i32) anyerror!void,
    key: fn (key: i32, down: bool) anyerror!void,
};

const Application = struct {
    name: []const u8,
    load: fn () anyerror!void,
    initialize: fn () anyerror!void,
    cleanup: fn () anyerror!void,
    draw: fn () anyerror!void,
    update: fn (timeElapsed: f32) anyerror!void,
    callbacks: Callbacks,
};

// Additional abstractions


pub fn createFramebuffer() !void {
    framebuffer.deinit(device);

    // Get the current window dimension.
    var size = getWindowSize();

    // Get the swapchain's current surface format.
    var swapchainFormat: vk.SurfaceFormatKHR = undefined;
    vez.getSwapchainSurfaceFormat(swapchain, &swapchainFormat);

    // Create the color image for the framebuffer.
    var imageCreateInfo = vez.ImageCreateInfo{
        .format = swapchainFormat.format,
        .extent = .{ .width = size[0], .height = size[1], .depth = 1 },
        .samples = sampleCountFlag,
        .tiling = .IMAGE_TILING_OPTIMAL,
        .usage = vk.IMAGE_USAGE_TRANSFER_SRC_BIT | vk.IMAGE_USAGE_TRANSFER_DST_BIT | vk.IMAGE_USAGE_COLOR_ATTACHMENT_BIT,
    };
    try convert(vez.createImage(device, vez.MEMORY_GPU_ONLY, &imageCreateInfo, &framebuffer.colorImage));

    // Create the image view for binding the texture as a resource.
    var imageViewCreateInfo = vez.ImageViewCreateInfo{
        .image = framebuffer.colorImage,
        .viewType = .IMAGE_VIEW_TYPE_2D,
        .format = imageCreateInfo.format,
    };
    try convert(vez.createImageView(device, &imageViewCreateInfo, &framebuffer.colorImageView));

    // Create the depth image for the m_framebuffer.
    imageCreateInfo.format = .FORMAT_D32_SFLOAT;
    imageCreateInfo.extent = vk.Extent3D{ .width = size[0], .height = size[1], .depth = 1 };
    imageCreateInfo.usage = vk.IMAGE_USAGE_DEPTH_STENCIL_ATTACHMENT_BIT;
    try convert(vez.createImage(device, vez.MEMORY_GPU_ONLY, &imageCreateInfo, &framebuffer.depthStencilImage));

    // Create the image view for binding the texture as a resource.
    imageViewCreateInfo.image = framebuffer.depthStencilImage;
    imageViewCreateInfo.viewType = .IMAGE_VIEW_TYPE_2D;
    imageViewCreateInfo.format = imageCreateInfo.format;
    try convert(vez.createImageView(device, &imageViewCreateInfo, &framebuffer.depthStencilImageView));

    // Create the m_framebuffer.
    var attachments: []vk.ImageView = &[_]vk.ImageView{ framebuffer.colorImageView, framebuffer.depthStencilImageView };
    const framebufferCreateInfo = vez.FramebufferCreateInfo{
        .attachmentCount = @intCast(u32, attachments.len),
        .pAttachments = attachments.ptr,
        .width = size[0],
        .height = size[1],
        .layers = 1,
    };
    try convert(vez.createFramebuffer(device, &framebufferCreateInfo, &framebuffer.handle));
}

fn createShaderModule(allocator: *Allocator, filename: []const u8, spirv: bool, entryPoint: []const u8, stage: vk.ShaderStageFlagBits) !vk.ShaderModule {
    // Load the GLSL shader code from disk.
    var file = try std.fs.cwd().openFile(filename, .{});
    const len = try file.getEndPos();

    const code = try allocator.alignedAlloc(u8, @alignOf(u32), len);
    defer allocator.free(code);

    const readlen = try file.read(code);
    if (readlen != len)
        return error.CouldNotReadShaderFile;
    file.close();

    // Create the shader module.
    var createInfo = vez.ShaderModuleCreateInfo{
        .stage = stage,
        .codeSize = code.len,
        .pEntryPoint = entryPoint.ptr,
        .pCode = null,
        .pGLSLSource = null,
    };
    if (spirv) {
        createInfo.pCode = @ptrCast([*]const u32, code.ptr);
    } else {
        createInfo.pGLSLSource = code.ptr;
    }

    var shaderModule: vk.ShaderModule = null;
    var result = vez.createShaderModule(device, &createInfo, &shaderModule);
    if (result != .SUCCESS) {
        if (shaderModule == null)
            return error.CouldNotCreateShader;

        // If shader module creation failed but error is from GLSL compilation, get the error log.
        var infoLogSize: u32 = 0;
        vez.getShaderModuleInfoLog(shaderModule, &infoLogSize, null);

        var infoLog = try allocator.alloc(u8, infoLogSize);
        std.mem.set(u8, infoLog, 0);
        vez.getShaderModuleInfoLog(shaderModule, &infoLogSize, &infoLog[0]);

        vez.destroyShaderModule(device, shaderModule);

        std.log.err("{}\n", .{infoLog});
        return error.CouldNotCompile;
    }

    return shaderModule;
}

pub fn createPipeline(allocator: *Allocator, pipelineShaderInfo: []const PipelineShaderInfo, pPipeline: *vez.Pipeline, shaderModules: []vk.ShaderModule) !void {
    // Create shader modules.
    var shaderStageCreateInfo = try allocator.alloc(vez.PipelineShaderStageCreateInfo, pipelineShaderInfo.len);
    defer allocator.free(shaderStageCreateInfo);

    var exe_path: []const u8 = try std.fs.selfExeDirPathAlloc(allocator);
    defer allocator.free(exe_path);
    for (pipelineShaderInfo) |info, i| {
        var filename = try std.fs.path.join(allocator, &[_][]const u8{ exe_path, "shaders", info.filename });
        defer allocator.free(filename);
        var shaderModule = try createShaderModule(allocator, filename, info.spirv, "main", info.stage);

        shaderStageCreateInfo[i] = .{
            .module = shaderModule,
            .pEntryPoint = "main",
            .pSpecializationInfo = null,
        };
        shaderModules[i] = shaderModule;
    }

    // Determine if this is a compute only pipeline.
    var isComputePipeline: bool = pipelineShaderInfo.len == 1 and pipelineShaderInfo[0].stage == .SHADER_STAGE_COMPUTE_BIT;

    // Create the graphics pipeline or compute pipeline.
    if (isComputePipeline) {
        const pipelineCreateInfo = vez.ComputePipelineCreateInfo{
            .pStage = shaderStageCreateInfo.ptr,
        };
        try convert(vez.createComputePipeline(device, &pipelineCreateInfo, pPipeline));
    } else {
        const pipelineCreateInfo = vez.GraphicsPipelineCreateInfo{
            .stageCount = @intCast(u32, shaderStageCreateInfo.len),
            .pStages = shaderStageCreateInfo.ptr,
        };
        try convert(vez.createGraphicsPipeline(device, &pipelineCreateInfo, pPipeline));
    }
}

pub fn cmdSetFullViewport() void {
    var size = getWindowSize();
    const viewport = vk.Viewport{
        .width = @intToFloat(f32, size[0]),
        .height = @intToFloat(f32, size[1]),
    };
    const scissor = vk.Rect2D{
        .offset = .{ .x = 0, .y = 0 },
        .extent = .{ .width = size[0], .height = size[1] },
    };
    vez.cmdSetViewport(0, 1, &[_]vk.Viewport{viewport});
    vez.cmdSetScissor(0, 1, &[_]vk.Rect2D{scissor});
}

fn props(dev: vk.PhysicalDevice) vk.PhysicalDeviceProperties {
    var properties: vk.PhysicalDeviceProperties = undefined;
    vez.getPhysicalDeviceProperties(dev, &properties);
    return properties;
}

pub fn run(allocator: *Allocator, app: Application) !void {
    const stdout = std.io.getStdOut().outStream();
    
    callbacks = app.callbacks;
    var availableLayers = try getInstanceLayers(allocator);
    defer availableLayers.deinit();

    // Use glfw to check for Vulkan support.
    if (c.glfwInit() != c.TRUE) {
        return error.CouldNotInitGlfw;
    }

    if (c.glfwVulkanSupported() != c.TRUE) {
        @panic("No Vulkan supported found on system!\n");
    }

    // // Initialize a Vulkan instance with the validation availableLayers enabled and extensions required by glfw.
    var instanceExtensionCount: u32 = 0;
    var instanceExtensions = c.glfwGetRequiredInstanceExtensions(&instanceExtensionCount)[0..instanceExtensionCount];

    var instanceLayers = std.ArrayList([*:0]const u8).init(allocator);
    defer instanceLayers.deinit();

    if (enableValidationLayers) {
        if (availableLayers.contains(extendName(validation))) {
            try instanceLayers.append(validation);
        } else {
            return error.NoValidationLayerFound;
        }
    }

    var result: vk.Result = undefined;
    var appInfo = vez.ApplicationInfo{
        .pApplicationName = NAME,
        .applicationVersion = makeVkVersion(1, 0, 0),
        .pEngineName = "ADF custom",
        .engineVersion = makeVkVersion(0, 0, 0),
    };
    var createInfo = vez.InstanceCreateInfo{
        .pApplicationInfo = &appInfo,
        .enabledLayerCount = @intCast(u32, instanceLayers.items.len),
        .ppEnabledLayerNames = instanceLayers.items.ptr,
        .enabledExtensionCount = instanceExtensionCount,
        .ppEnabledExtensionNames = instanceExtensions.ptr,
    };
    try convert(vez.createInstance(&createInfo, &instance));

    // Enumerate all attached physical devices.
    var physicalDeviceCount: u32 = 0;
    try convert(vez.enumeratePhysicalDevices(instance, &physicalDeviceCount, null));
    if (physicalDeviceCount == 0) {
        return error.NoPhysicalDeviceFound;
    }
    var physicalDevices = try allocator.alloc(vk.PhysicalDevice, physicalDeviceCount);
    defer allocator.free(physicalDevices);
    try convert(vez.enumeratePhysicalDevices(instance, &physicalDeviceCount, physicalDevices.ptr));
    
    const chosenDevice = 0;
    if (isDebug) {
        for (physicalDevices) |pdevice, i| {
            const name = @ptrCast([*:0]const u8, &props(pdevice).deviceName);
            if (i == chosenDevice) {
                try stdout.print("-> {}\n", .{name});
            } else {
                try stdout.print("   {}\n", .{name});
            }
        }
    }
    physicalDevice = physicalDevices[chosenDevice];

    // Create the Vulkan device handle.
    var deviceExtensions: []const [*:0]const u8 = &[_][*:0]const u8{vk.KHR_SWAPCHAIN_EXTENSION_NAME};
    var deviceCreateInfo = vez.DeviceCreateInfo{
        .enabledLayerCount = 0,
        .ppEnabledLayerNames = null,
        .enabledExtensionCount = @intCast(u32, deviceExtensions.len),
        .ppEnabledExtensionNames = deviceExtensions.ptr,
    };
    try convert(vez.createDevice(physicalDevice, &deviceCreateInfo, &device));

    try app.load();
    
    c.glfwWindowHint(c.CLIENT_API, c.NO_API);
    window = c.glfwCreateWindow(WIDTH, HEIGHT, NAME, null, null) orelse return error.FailedToCreateWindow;

    // Set callbacks.
    _ = c.glfwSetWindowSizeCallback(window, windowSizeCallback);
    _ = c.glfwSetCursorPosCallback(window, cursorPosCallback);
    _ = c.glfwSetMouseButtonCallback(window, mouseButtonCallback);
    _ = c.glfwSetKeyCallback(window, keyCallback);
    // c.glfwSetScrollCallback(window, MouseScrollCallback);

    // Create a surface from the GLFW window handle.
    try convert(c.glfwCreateWindowSurface(instance, window, null, &surface));
    c.glfwGetWindowSize(window, &windowWidth, &windowHeight);

    // Create the swapchain.
    var swapchainCreateInfo = vez.SwapchainCreateInfo{
        .surface = surface,
        .format = vk.SurfaceFormatKHR{ .format = .FORMAT_B8G8R8A8_UNORM, .colorSpace = .COLOR_SPACE_SRGB_NONLINEAR_KHR },
        .tripleBuffer = vk.TRUE,
    };
    try convert(vez.createSwapchain(device, &swapchainCreateInfo, &swapchain));
    try convert(vez.vezSwapchainSetVSync(swapchain, vk.FALSE));

    if (manageFramebuffer) {
        try createFramebuffer();
    }

    try app.initialize();

    var lastTime = c.glfwGetTime();

    var elapsedTime: f64 = 0;
    var frameCount: u32 = 0;

    // Message loop.
    while (!shouldQuit()) {
        // Check for window messages to process.
        c.glfwPollEvents();

        // Update the application.
        var curTime = c.glfwGetTime();

        curTime = c.glfwGetTime();
        var delta = curTime - lastTime;
        lastTime = curTime;
        elapsedTime += delta;
        try app.update(@floatCast(f32, delta));

        try app.draw();

        // Display the fps in the window title bar.
        frameCount += 1;
        if (elapsedTime >= 1.0) {
            const size = getWindowSize();
            const nspp = 1000000000 / frameCount / (size[0] * size[1]);
            const text = try std.fmt.allocPrintZ(allocator, "{} ({} FPS, {} nspp)", .{ app.name, frameCount, nspp });
            c.glfwSetWindowTitle(window, text.ptr);
            elapsedTime = 0.0;
            frameCount = 0;
        }
    }

    try convert(vez.deviceWaitIdle(device));

    try app.cleanup();

    if (manageFramebuffer) {
        framebuffer.deinit(device);
    }

    vez.destroySwapchain(device, swapchain);
    vez.destroyDevice(device);
    vk.vkDestroySurfaceKHR(instance, surface, null);
    vez.destroyInstance(instance);
}

fn shouldQuit() bool {
    return c.glfwWindowShouldClose(window) != 0 or quitSignaled;
}

export fn windowSizeCallback(wndw: ?*c.Window, width: c_int, height: c_int) callconv(.C) void {
    resize() catch std.log.err("resize() crashed", .{});
}

pub fn resize() !void {
    // Wait for device to be idle.
    try convert(vk.vkDeviceWaitIdle(device));

    c.glfwGetWindowSize(window, &windowWidth, &windowHeight);
    // Re-create the framebuffer.
    if (manageFramebuffer) {
        try createFramebuffer();
    }

    try callbacks.resize(@intCast(u32, windowWidth), @intCast(u32, windowHeight));
}

export fn cursorPosCallback(wndw: ?*c.Window, x: f64, y: f64) void {
    callbacks.mousePos(@floatToInt(i32, x), @floatToInt(i32, y)) catch unreachable;
}

export fn mouseButtonCallback(wndw: ?*c.Window, button: c_int, action: c_int, mods: c_int) void {
    var p = getCursorPos();
    switch (action) {
        c.PRESS => callbacks.mouseButton(@intCast(i32, button), true, p[0], p[1]) catch unreachable,
        c.RELEASE => callbacks.mouseButton(@intCast(i32, button), false, p[0], p[1]) catch unreachable,
        else => return,
    }
}

export fn keyCallback(wndw: ?*c.Window, key: c_int, scancode: c_int, action: c_int, mods: c_int) void {
    var p = getCursorPos();
    var press = switch (action) {
        c.PRESS => true,
        c.RELEASE => false,
        else => return,
    };
    if (key == c.KEY_UNKNOWN)
        return;
    keyMap[@intCast(usize, key)] = press;
    callbacks.key(@intCast(i32, key), press) catch unreachable;
}
