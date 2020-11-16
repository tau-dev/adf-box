const std = @import("std");
pub const vk = @import("vulkan.zig");
pub const vez = @import("vez.zig");
pub const c = @import("glfw3.zig");
// pub const c = @cImport({
// @cInclude("VEZ.h");
// @cDefine("GLFW_INCLUDE_VULKAN", "1");
// @cInclude("GLFW/glfw3.h");
// });
const Allocator = std.mem.Allocator;
const NameSet = std.AutoHashMap([256]u8, void);

pub const PipelineShaderInfo = struct {
    filename: []const u8,
    stage: vk.ShaderStageFlagBits,
};

const WIDTH = 600;
const HEIGHT = 400;
const NAME = "Test the West!";

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

// const validationName = validation.* ++ [_]u8{0} ** (256 - validation.len);

const stdout = std.io.getStdOut().outStream();

var window: *c.Window = undefined;
var windowWidth: i32 = 0;
var windowHeight: i32 = 0;
var instance: vk.Instance = undefined;
var physicalDevice: vk.PhysicalDevice = null;
var surface: vk.SurfaceKHR = null;
var device: vk.Device = null;
var swapchain: vez.Swapchain = null;

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
pub fn getWindow() *GLFWwindow {
    return window;
}
pub fn getWindowSize() [2]u32 {
    return .{ @intCast(u32, windowWidth), @intCast(u32, windowHeight) };
}
pub fn roundUp(a: u32, b: u32) u32 {
    return (a + b - 1) / b;
}
var framebuffer = FrameBuffer{};
const FrameBuffer = struct {
    colorImage: vk.Image = null,
    colorImageView: vk.ImageView = null,
    depthStencilImage: vk.Image = null,
    depthStencilImageView: vk.ImageView = null,
    handle: vez.Framebuffer = null,

    /// Free previous allocations.
    fn deinit(self: FrameBuffer, dev: vk.Device) void {
        if (framebuffer.handle) |hndl| {
            vez.vezDestroyFramebuffer(dev, self.handle);
            vez.vezDestroyImageView(dev, self.colorImageView);
            vez.vezDestroyImageView(dev, self.depthStencilImageView);
            vez.vezDestroyImage(dev, self.colorImage);
            vez.vezDestroyImage(dev, self.depthStencilImage);
        }
    }
};

const Application = struct {
    name: []const u8,
    initialize: fn () anyerror!void,
    cleanup: fn () anyerror!void,
    draw: fn () anyerror!void,
    onResize: fn (width: u32, height: u32) anyerror!void,
    update: fn (timeElapsed: f32) anyerror!void,
};
var resize: fn (width: u32, height: u32) anyerror!void = undefined;

// abstracc

fn MakeVkVersion(major: u32, minor: anytype, patch: anytype) u32 {
    return (major << 22) | ((minor << 12) | patch);
}

pub const VulkanError = error{
    Incomplete,
    NotReady,
    Timeout,
    EventSet,
    EventReset,
    ThreadIdle,
    ThreadDone,
    OperationDeferred,
    OperationNotDeferred,
    OutOfHostMemory,
    OutOfDeviceMemory,
    InitializationFailed,
    DeviceLost,
    MemoryMapFailed,
    LayerNotPresent,
    ExtensionNotPresent,
    FeatureNotPresent,
    IncompatibleDriver,
    TooManyObjects,
    FormatNotSupported,
    FragmentedPool,
    UnknownError,
    OutOfPoolMemory,
    InvalidExternalHandle,
    Fragmentation,
    InvalidAddress,
    SurfaceLost,
    NativeWindowInUse,
    Suboptimal,
    OutOfDate,
    IncompatibleDisplay,
    ValidationFailed,
    InvalidShader,
    IncompatibleVersion,
    InvalidDrmFormatModifierPlaneLayout,
    NotPermitted,
    FullScreenExclusiveModeLost,
    PipelineCompileRequired,
};

pub fn convert(result: vk.Result) VulkanError!void {
    return switch (result) {
        .SUCCESS => return,
        .SUBOPTIMAL_KHR => VulkanError.Suboptimal,
        .INCOMPLETE => VulkanError.Incomplete,
        .NOT_READY => VulkanError.NotReady,
        .TIMEOUT => VulkanError.Timeout,
        .EVENT_SET => VulkanError.EventSet,
        .EVENT_RESET => VulkanError.EventReset,
        .THREAD_IDLE_KHR => VulkanError.ThreadIdle,
        .THREAD_DONE_KHR => VulkanError.ThreadDone,
        .OPERATION_DEFERRED_KHR => VulkanError.OperationDeferred,
        .OPERATION_NOT_DEFERRED_KHR => VulkanError.OperationNotDeferred,
        .ERROR_OUT_OF_HOST_MEMORY => VulkanError.OutOfHostMemory,
        .ERROR_OUT_OF_DEVICE_MEMORY => VulkanError.OutOfDeviceMemory,
        .ERROR_INITIALIZATION_FAILED => VulkanError.InitializationFailed,
        .ERROR_DEVICE_LOST => VulkanError.DeviceLost,
        .ERROR_MEMORY_MAP_FAILED => VulkanError.MemoryMapFailed,
        .ERROR_LAYER_NOT_PRESENT => VulkanError.LayerNotPresent,
        .ERROR_EXTENSION_NOT_PRESENT => VulkanError.ExtensionNotPresent,
        .ERROR_FEATURE_NOT_PRESENT => VulkanError.FeatureNotPresent,
        .ERROR_INCOMPATIBLE_DRIVER => VulkanError.IncompatibleDriver,
        .ERROR_TOO_MANY_OBJECTS => VulkanError.TooManyObjects,
        .ERROR_FORMAT_NOT_SUPPORTED => VulkanError.FormatNotSupported,
        .ERROR_FRAGMENTED_POOL => VulkanError.FragmentedPool,
        .ERROR_UNKNOWN => VulkanError.UnknownError,
        .ERROR_OUT_OF_POOL_MEMORY => VulkanError.OutOfPoolMemory,
        .ERROR_INVALID_EXTERNAL_HANDLE => VulkanError.InvalidExternalHandle,
        .ERROR_FRAGMENTATION => VulkanError.Fragmentation,
        .ERROR_INVALID_OPAQUE_CAPTURE_ADDRESS => VulkanError.InvalidAddress,
        .ERROR_SURFACE_LOST_KHR => VulkanError.SurfaceLost,
        .ERROR_NATIVE_WINDOW_IN_USE_KHR => VulkanError.NativeWindowInUse,
        .ERROR_OUT_OF_DATE_KHR => VulkanError.OutOfDate,
        .ERROR_INCOMPATIBLE_DISPLAY_KHR => VulkanError.IncompatibleDisplay,
        .ERROR_VALIDATION_FAILED_EXT => VulkanError.ValidationFailed,
        .ERROR_INVALID_SHADER_NV => VulkanError.InvalidShader,
        .ERROR_INCOMPATIBLE_VERSION_KHR => VulkanError.IncompatibleVersion,
        .ERROR_INVALID_DRM_FORMAT_MODIFIER_PLANE_LAYOUT_EXT => VulkanError.InvalidDrmFormatModifierPlaneLayout,
        .ERROR_NOT_PERMITTED_EXT => VulkanError.NotPermitted,
        .ERROR_FULL_SCREEN_EXCLUSIVE_MODE_LOST_EXT => VulkanError.FullScreenExclusiveModeLost,
        .ERROR_PIPELINE_COMPILE_REQUIRED_EXT => VulkanError.PipelineCompileRequired,
        else => unreachable,
    };
}

// Additional abstractions

fn getInstanceLayers(allocator: *Allocator) !NameSet {
    var extensionCount: u32 = 0;
    try convert(vez.enumerateInstanceExtensionProperties(null, &extensionCount, null));

    var extensions = try allocator.alloc(vk.ExtensionProperties, extensionCount);
    defer allocator.free(extensions);
    try convert(vez.enumerateInstanceExtensionProperties(null, &extensionCount, extensions.ptr));

    for (extensions) |extension| {
        // try stdout.print("{}\n", .{@ptrCast([*:0]const u8, &extension.extensionName)});
    }

    // Enumerate all available instance availableLayers.
    var layerCount: u32 = 0;
    try convert(vez.vezEnumerateInstanceLayerProperties(&layerCount, null));

    var layerProperties = try allocator.alloc(vk.LayerProperties, layerCount);
    defer allocator.free(layerProperties);

    try convert(vez.vezEnumerateInstanceLayerProperties(&layerCount, layerProperties.ptr));
    var set = NameSet.init(allocator);
    for (layerProperties) |prop| {
        _ = try set.put(prop.layerName, .{});
    }
    return set;
}

fn createFramebuffer() !void {
    framebuffer.deinit(device);

    // Get the current window dimension.
    var size = getWindowSize();

    // Get the swapchain's current surface format.
    var swapchainFormat: vk.SurfaceFormatKHR = undefined;
    vez.vezGetSwapchainSurfaceFormat(swapchain, &swapchainFormat);

    // Create the color image for the framebuffer.
    var imageCreateInfo = vez.ImageCreateInfo{
        .format = swapchainFormat.format,
        .extent = .{ .width = size[0], .height = size[1], .depth = 1 },
        .samples = sampleCountFlag,
        .tiling = .IMAGE_TILING_OPTIMAL,
        .usage = vk.IMAGE_USAGE_TRANSFER_SRC_BIT | vk.IMAGE_USAGE_TRANSFER_DST_BIT | vk.IMAGE_USAGE_COLOR_ATTACHMENT_BIT,
    };
    try convert(vez.vezCreateImage(device, vez.MEMORY_GPU_ONLY, &imageCreateInfo, &framebuffer.colorImage));

    // Create the image view for binding the texture as a resource.
    var imageViewCreateInfo = vez.ImageViewCreateInfo{
        .image = framebuffer.colorImage,
        .viewType = .IMAGE_VIEW_TYPE_2D,
        .format = imageCreateInfo.format,
    };
    try convert(vez.vezCreateImageView(device, &imageViewCreateInfo, &framebuffer.colorImageView));

    // Create the depth image for the m_framebuffer.
    imageCreateInfo.format = .FORMAT_D32_SFLOAT;
    imageCreateInfo.extent = vk.Extent3D{ .width = size[0], .height = size[1], .depth = 1 };
    imageCreateInfo.usage = vk.IMAGE_USAGE_DEPTH_STENCIL_ATTACHMENT_BIT;
    try convert(vez.vezCreateImage(device, vez.MEMORY_GPU_ONLY, &imageCreateInfo, &framebuffer.depthStencilImage));

    // Create the image view for binding the texture as a resource.
    imageViewCreateInfo.image = framebuffer.depthStencilImage;
    imageViewCreateInfo.viewType = .IMAGE_VIEW_TYPE_2D;
    imageViewCreateInfo.format = imageCreateInfo.format;
    try convert(vez.vezCreateImageView(device, &imageViewCreateInfo, &framebuffer.depthStencilImageView));

    // Create the m_framebuffer.
    var attachments: []vk.ImageView = &[_]vk.ImageView{ framebuffer.colorImageView, framebuffer.depthStencilImageView };
    const framebufferCreateInfo = vez.FramebufferCreateInfo{
        .attachmentCount = @intCast(u32, attachments.len),
        .pAttachments = attachments.ptr,
        .width = size[0],
        .height = size[1],
        .layers = 1,
    };
    try convert(vez.vezCreateFramebuffer(device, &framebufferCreateInfo, &framebuffer.handle));
}

fn createShaderModule(allocator: *Allocator, filename: []const u8, entryPoint: []const u8, stage: vk.ShaderStageFlagBits) !vk.ShaderModule {
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
    if (std.mem.endsWith(u8, filename, ".spv")) {
        createInfo.pCode = @ptrCast([*]const u32, code.ptr);
    } else {
        createInfo.pGLSLSource = code.ptr;
    }

    var shaderModule: vk.ShaderModule = null;
    var result = vez.vezCreateShaderModule(device, &createInfo, &shaderModule);
    if (result != .SUCCESS) {
        if (shaderModule == null)
            return error.CouldNotCreateShader;

        // If shader module creation failed but error is from GLSL compilation, get the error log.
        var infoLogSize: u32 = 0;
        vez.vezGetShaderModuleInfoLog(shaderModule, &infoLogSize, null);

        var infoLog = try allocator.alloc(u8, infoLogSize);
        std.mem.set(u8, infoLog, 0);
        vez.vezGetShaderModuleInfoLog(shaderModule, &infoLogSize, &infoLog[0]);

        vez.vezDestroyShaderModule(device, shaderModule);

        try stdout.print("{}\n", .{infoLog});
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
        var shaderModule = try createShaderModule(allocator, filename, "main", info.stage);

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
        try convert(vez.vezCreateComputePipeline(device, &pipelineCreateInfo, pPipeline));
    } else {
        const pipelineCreateInfo = vez.GraphicsPipelineCreateInfo{
            .stageCount = @intCast(u32, shaderStageCreateInfo.len),
            .pStages = shaderStageCreateInfo.ptr,
        };
        try convert(vez.vezCreateGraphicsPipeline(device, &pipelineCreateInfo, pPipeline));
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

fn setWindowCenter(wndw: *c.Window) !void {
    // Get window position and size
    var posX: i32 = undefined;
    var posY: i32 = undefined;
    c.glfwGetWindowPos(wndw, &posX, &posY);

    var size = getWindowSize();

    // Halve the window size and use it to adjust the window position to the center of the window
    var halfwidth = @intCast(i32, size[0] >> 1);
    var halfheight = @intCast(i32, size[1] >> 1);
    posX += halfwidth;
    posY += halfheight;

    // Get the list of monitors
    var count: i32 = undefined;
    var monitors: []?*c.Monitor = (c.glfwGetMonitors(&count) orelse return)[0..@intCast(usize, count)];

    // Figure out which monitor the window is in
    var owner: ?*c.Monitor = null;
    var owner_x: i32 = undefined;
    var owner_y: i32 = undefined;
    var owner_width: i32 = undefined;
    var owner_height: i32 = undefined;

    var i: usize = 0;
    while (i < count) : (i += 1) {
        // Get the monitor position
        var monitor_x: i32 = undefined;
        var monitor_y: i32 = undefined;
        if (monitors[i] == null) {
            @panic("ono");
        }
        c.glfwGetMonitorPos(monitors[i], &monitor_x, &monitor_y);

        // Get the monitor size from its video mode
        var monitor_width: i32 = undefined;
        var monitor_height: i32 = undefined;
        var monitor_vidmode: *const c.Vidmode = c.glfwGetVideoMode(monitors[i]) orelse continue;

        monitor_width = monitor_vidmode.width;
        monitor_height = monitor_vidmode.height;

        // Set the owner to this monitor if the center of the window is within its bounding box
        if ((posX > monitor_x and posX < (monitor_x + monitor_width)) and (posY > monitor_y and posY < (monitor_y + monitor_height))) {
            owner = monitors[i];
            owner_x = monitor_x;
            owner_y = monitor_y;
            owner_width = monitor_width;
            owner_height = monitor_height;
        }
    }

    // Set the window position to the center of the owner monitor
    if (owner) |own| {
        c.glfwSetWindowPos(wndw, owner_x + (owner_width >> 1) - halfwidth, owner_y + (owner_height >> 1) - halfheight);
    }
}

fn props(dev: vk.PhysicalDevice) vk.PhysicalDeviceProperties {
    var properties: vk.PhysicalDeviceProperties = undefined;
    vez.vezGetPhysicalDeviceProperties(dev, &properties);
    return properties;
}

pub fn run(allocator: *Allocator, app: Application) !void {
    resize = app.onResize;
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
        .applicationVersion = MakeVkVersion(1, 0, 0),
        .pEngineName = "testEngine",
        .engineVersion = MakeVkVersion(0, 0, 0),
    };
    var createInfo = vez.InstanceCreateInfo{
        .pApplicationInfo = &appInfo,
        .enabledLayerCount = @intCast(u32, instanceLayers.items.len),
        .ppEnabledLayerNames = instanceLayers.items.ptr,
        .enabledExtensionCount = instanceExtensionCount,
        .ppEnabledExtensionNames = instanceExtensions.ptr,
    };
    try convert(vez.vezCreateInstance(&createInfo, &instance));

    // Enumerate all attached physical devices.
    var physicalDeviceCount: u32 = 0;
    try convert(vez.vezEnumeratePhysicalDevices(instance, &physicalDeviceCount, null));
    if (physicalDeviceCount == 0) {
        return error.NoPhysicalDeviceFound;
    }
    var physicalDevices = try allocator.alloc(vk.PhysicalDevice, physicalDeviceCount);
    defer allocator.free(physicalDevices);
    try convert(vez.vezEnumeratePhysicalDevices(instance, &physicalDeviceCount, physicalDevices.ptr));

    for (physicalDevices) |pdevice, i| {
        const name = @ptrCast([*:0]const u8, &props(pdevice).deviceName);
        if (i == 0) {
            try stdout.print("-> {}\n", .{name});
        } else {
            try stdout.print("   {}\n", .{name});
        }
    }
    physicalDevice = physicalDevices[0];

    // Initialize a window using GLFW and hint no graphics API should be used on the backend.
    c.glfwWindowHint(c.CLIENT_API, c.NO_API);
    window = c.glfwCreateWindow(WIDTH, HEIGHT, NAME, null, null) orelse return error.FailedToCreateWindow;
    try setWindowCenter(window);

    // Create the Vulkan device handle.
    var deviceExtensions: []const [*:0]const u8 = &[_][*:0]const u8{vk.KHR_SWAPCHAIN_EXTENSION_NAME};
    var deviceCreateInfo = vez.DeviceCreateInfo{
        .enabledLayerCount = 0,
        .ppEnabledLayerNames = null,
        .enabledExtensionCount = @intCast(u32, deviceExtensions.len),
        .ppEnabledExtensionNames = deviceExtensions.ptr,
    };
    try convert(vez.vezCreateDevice(physicalDevice, &deviceCreateInfo, &device));

    // Set callbacks.
    _ = c.glfwSetWindowSizeCallback(window, WindowSizeCallback);
    // c.glfwSetCursorPosCallback(window, CursorPosCallback);
    // c.glfwSetMouseButtonCallback(window, MouseButtonCallback);
    // c.glfwSetScrollCallback(window, MouseScrollCallback);
    // c.glfwSetKeyCallback(window, KeyCallback);

    // Create a surface from the GLFW window handle.
    try convert(c.glfwCreateWindowSurface(instance, window, null, &surface));
    c.glfwGetWindowSize(window, &windowWidth, &windowHeight);

    // Create the swapchain.
    var swapchainCreateInfo = vez.SwapchainCreateInfo{
        .surface = surface,
        .format = vk.SurfaceFormatKHR{ .format = .FORMAT_B8G8R8A8_UNORM, .colorSpace = .COLOR_SPACE_SRGB_NONLINEAR_KHR },
        .tripleBuffer = vk.TRUE,
    };
    try convert(vez.vezCreateSwapchain(device, &swapchainCreateInfo, &swapchain));

    if (manageFramebuffer) {
        try createFramebuffer();
    }

    try app.initialize();
    c.glfwShowWindow(window);

    var lastTime = c.glfwGetTime();

    var elapsedTime: f64 = 0;
    var frameCount: u32 = 0;

    // Message loop.
    while (c.glfwWindowShouldClose(window) == 0 and !quitSignaled) {
        // Check for window messages to process.
        c.glfwPollEvents();

        // Update the application.
        var curTime = c.glfwGetTime();
        var delta = curTime - lastTime;
        elapsedTime += delta;
        try app.update(@floatCast(f32, delta));
        lastTime = curTime;

        try app.draw();

        // Display the fps in the window title bar.
        frameCount += 1;
        if (elapsedTime >= 1.0) {
            const text = try std.fmt.allocPrint(allocator, "{} ({} FPS)", .{ app.name, frameCount });
            c.glfwSetWindowTitle(window, text.ptr);
            elapsedTime = 0.0;
            frameCount = 0;
        }
    }

    try convert(vez.vezDeviceWaitIdle(device));

    try app.cleanup();

    if (manageFramebuffer) {
        framebuffer.deinit(device);
    }

    vez.vezDestroySwapchain(device, swapchain);
    vez.vezDestroyDevice(device);
    vk.vkDestroySurfaceKHR(instance, surface, null);
    vez.vezDestroyInstance(instance);
}

export fn WindowSizeCallback(wndw: ?*c.Window, width: c_int, height: c_int) callconv(.C) void {
    // windowWidth = width;
    // windowHeight = height;

    // Wait for device to be idle.
    convert(vk.vkDeviceWaitIdle(device)) catch unreachable;

    c.glfwGetWindowSize(window, &windowWidth, &windowHeight);
    // Re-create the framebuffer.
    if (manageFramebuffer) {
        createFramebuffer() catch unreachable;
    }

    resize(@intCast(u32, windowWidth), @intCast(u32, windowHeight)) catch unreachable;
}
