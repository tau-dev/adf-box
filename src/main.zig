const std = @import("std");
const c = @cImport({
    @cInclude("VEZ.h");
    // @cDefine("GLFW_INCLUDE_VULKAN", "1");
    @cInclude("GLFW/glfw3.h");
});
const Allocator = std.mem.Allocator;
const NameSet = std.AutoHashMap([256]u8, void);

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

const mat4 = [4][4]f32;

const UniformBuffer = struct {
    model: mat4,
    view: mat4,
    projection: mat4,
};

const WIDTH = 600;
const HEIGHT = 400;
const NAME = "Test the West!";

const manageFramebuffer = true;
const sampleCountFlag = .VK_SAMPLE_COUNT_1_BIT;
const enableValidationLayers = true;
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
const map_ident = c.VkComponentMapping{
    .r = .VK_COMPONENT_SWIZZLE_IDENTITY,
    .g = .VK_COMPONENT_SWIZZLE_IDENTITY,
    .b = .VK_COMPONENT_SWIZZLE_IDENTITY,
    .a = .VK_COMPONENT_SWIZZLE_IDENTITY,
};

const stdout = std.io.getStdOut().outStream();

var window: *c.GLFWwindow = undefined;
var instance: c.VkInstance = undefined;
var physicalDevice: c.VkPhysicalDevice = null;
var surface: c.VkSurfaceKHR = null;
var device: c.VkDevice = null;
var swapchain: c.VezSwapchain = null;
var framebuffer = FrameBuffer{};
const FrameBuffer = struct {
    colorImage: c.VkImage = null,
    colorImageView: c.VkImageView = null,
    depthStencilImage: c.VkImage = null,
    depthStencilImageView: c.VkImageView = null,
    handle: c.VezFramebuffer = null,

    /// Free previous allocations.
    fn deinit(self: FrameBuffer, dev: c.VkDevice) void {
        if (framebuffer.handle) |hndl| {
            c.vezDestroyFramebuffer(dev, self.handle);
            c.vezDestroyImageView(dev, self.colorImageView);
            c.vezDestroyImageView(dev, self.depthStencilImageView);
            c.vezDestroyImage(dev, self.colorImage);
            c.vezDestroyImage(dev, self.depthStencilImage);
        }
    }
};

// abstracc

fn MakeVkVersion(major: u32, minor: var, patch: var) u32 {
    return (major << 22) | ((minor << 12) | patch);
}

fn convert(result: c.VkResult) !void {
    return switch (result) {
        .VK_SUCCESS => return,
        .VK_INCOMPLETE => error.VulkanIncomplete,
        .VK_ERROR_OUT_OF_HOST_MEMORY => error.OutOfHostMemory,
        .VK_ERROR_OUT_OF_DEVICE_MEMORY => error.OutOfDeviceMemory,
        else => error.Unknown,
    };
}

fn fail(msg: []const u8) void {
    stdout.print("Error: {}\n", .{msg}) catch |err| @panic("Faild to emit error");
}

// fn check(result: c.VkResult) void {
//     toError(result) catch |err| {
//         stdout.print("Vulkan Error: r) |own|
//             c.glfwSetWindowPos(wndw, owner_x + (owner_width >> 1) - width, owner_y + (owner_height >> 1) - height);
//     }
// }

// Additional abstractions

fn getInstanceLayers(allocator: *Allocator) !NameSet {
    // Enumerate all available instance availableLayers.
    var layerCount: u32 = 0;
    try convert(c.vkEnumerateInstanceLayerProperties(&layerCount, null));

    var layerProperties = try allocator.alloc(c.VkLayerProperties, layerCount);
    defer allocator.free(layerProperties);

    try convert(c.vkEnumerateInstanceLayerProperties(&layerCount, layerProperties.ptr));
    var set = NameSet.init(allocator);
    for (layerProperties) |prop| {
        try stdout.print("{}\n", .{prop.layerName});
        _ = try set.put(prop.layerName, .{});
    }
    return set;
}

fn CreateFramebuffer() !void {
    framebuffer.deinit(device);

    // Get the current window dimension.
    var width: u32 = undefined;
    var height: u32 = undefined;
    c.glfwGetWindowSize(window, @ptrCast(*i32, &width), @ptrCast(*i32, &height));

    // Get the swapchain's current surface format.
    var swapchainFormat: c.VkSurfaceFormatKHR = undefined;
    c.vezGetSwapchainSurfaceFormat(swapchain, &swapchainFormat);

    // Create the color image for the framebuffer.
    var imageCreateInfo = c.VezImageCreateInfo{
        .pNext = null,
        .flags = 0,
        .imageType = .VK_IMAGE_TYPE_2D,
        .format = swapchainFormat.format,
        .extent = .{ .width = width, .height = height, .depth = 1 },
        .mipLevels = 1,
        .arrayLayers = 1,
        .samples = sampleCountFlag,
        .tiling = .VK_IMAGE_TILING_OPTIMAL,
        .usage = c.VK_IMAGE_USAGE_TRANSFER_SRC_BIT | c.VK_IMAGE_USAGE_TRANSFER_DST_BIT | c.VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT,
        .queueFamilyIndexCount = 0,
        .pQueueFamilyIndices = null,
    };
    try convert(c.vezCreateImage(device, c.VEZ_MEMORY_GPU_ONLY, &imageCreateInfo, &framebuffer.colorImage));

    // Create the image view for binding the texture as a resource.
    var imageViewCreateInfo = c.VezImageViewCreateInfo{
        .pNext = null,
        .components = map_ident,
        .image = framebuffer.colorImage,
        .viewType = .VK_IMAGE_VIEW_TYPE_2D,
        .format = imageCreateInfo.format,
        .subresourceRange = c.VezImageSubresourceRange{
            .baseMipLevel = 0,
            .levelCount = 1,
            .baseArrayLayer = 0,
            .layerCount = 1,
        },
    };
    try convert(c.vezCreateImageView(device, &imageViewCreateInfo, &framebuffer.colorImageView));

    // Create the depth image for the m_framebuffer.
    imageCreateInfo.imageType = .VK_IMAGE_TYPE_2D;
    imageCreateInfo.format = .VK_FORMAT_D32_SFLOAT;
    imageCreateInfo.extent = c.VkExtent3D{ .width = width, .height = height, .depth = 1 };
    imageCreateInfo.mipLevels = 1;
    imageCreateInfo.arrayLayers = 1;
    imageCreateInfo.samples = sampleCountFlag;
    imageCreateInfo.tiling = .VK_IMAGE_TILING_OPTIMAL;
    imageCreateInfo.usage = c.VK_IMAGE_USAGE_DEPTH_STENCIL_ATTACHMENT_BIT;
    try convert(c.vezCreateImage(device, c.VEZ_MEMORY_GPU_ONLY, &imageCreateInfo, &framebuffer.depthStencilImage));

    // Create the image view for binding the texture as a resource.
    imageViewCreateInfo.image = framebuffer.depthStencilImage;
    imageViewCreateInfo.viewType = .VK_IMAGE_VIEW_TYPE_2D;
    imageViewCreateInfo.format = imageCreateInfo.format;
    imageViewCreateInfo.subresourceRange.layerCount = 1;
    imageViewCreateInfo.subresourceRange.levelCount = 1;
    try convert(c.vezCreateImageView(device, &imageViewCreateInfo, &framebuffer.depthStencilImageView));

    // Create the m_framebuffer.
    var attachments: []c.VkImageView = &[_]c.VkImageView{ framebuffer.colorImageView, framebuffer.depthStencilImageView };
    const framebufferCreateInfo = c.VezFramebufferCreateInfo{
        .pNext = null,
        .attachmentCount = @intCast(u32, attachments.len),
        .pAttachments = attachments.ptr,
        .width = width,
        .height = height,
        .layers = 1,
    };
    try convert(c.vezCreateFramebuffer(device, &framebufferCreateInfo, &framebuffer.handle));
}

fn SetWindowCenter(wndw: *c.GLFWwindow) !void {
    // Get window position and size
    var posX: i32 = undefined;
    var posY: i32 = undefined;
    c.glfwGetWindowPos(wndw, &posX, &posY);

    var width: i32 = undefined;
    var height: i32 = undefined;
    c.glfwGetWindowSize(wndw, &width, &height);

    // Halve the window size and use it to adjust the window position to the center of the window
    width >>= 1;
    height >>= 1;

    posX += width;
    posY += height;

    // Get the list of monitors
    var count: i32 = undefined;
    var monitors: []?*c.GLFWmonitor = (c.glfwGetMonitors(&count) orelse return)[0..@intCast(usize, count)];
    try stdout.print("{}\n", .{count});
    // Figure out which monitor the window is in
    var owner: ?*c.GLFWmonitor = null;
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
        var monitor_vidmode: *const c.GLFWvidmode = c.glfwGetVideoMode(monitors[i]) orelse continue;

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
        c.glfwSetWindowPos(wndw, owner_x + (owner_width >> 1) - width, owner_y + (owner_height >> 1) - height);
    }
}

fn props(dev: c.VkPhysicalDevice) c.VkPhysicalDeviceProperties {
    var properties: c.VkPhysicalDeviceProperties = undefined;
    c.vezGetPhysicalDeviceProperties(dev, &properties);
    return properties;
}

pub fn main() anyerror!void {
    const allocator = std.heap.c_allocator;

    var availableLayers = try getInstanceLayers(allocator);
    defer availableLayers.deinit();

    // Use glfw to check for Vulkan support.
    if (c.glfwInit() != c.GLFW_TRUE) {
        return error.CouldNotInitGlfw;
    }

    if (c.glfwVulkanSupported() != c.GLFW_TRUE) {
        @panic("No Vulkan supported found on system!\n");
    }

    // // Initialize a Vulkan instance with the validation availableLayers enabled and extensions required by glfw.
    var instanceExtensionCount: u32 = 0;
    var instanceExtensions = c.glfwGetRequiredInstanceExtensions(&instanceExtensionCount);

    var instanceLayers = std.ArrayList([*:0]const u8).init(allocator);
    defer instanceLayers.deinit();

    if (enableValidationLayers) {
        if (availableLayers.contains(extendName(validation))) {
            try instanceLayers.append(validation);
        } else {
            fail("No validation layer found!");
        }
    }

    var result: c.VkResult = undefined;
    var appInfo = c.VezApplicationInfo{
        .pNext = null,
        .pApplicationName = NAME,
        .applicationVersion = MakeVkVersion(1, 0, 0),
        .pEngineName = "testEngine",
        .engineVersion = MakeVkVersion(0, 0, 0),
    };
    var createInfo = c.VezInstanceCreateInfo{
        .pNext = null,
        .pApplicationInfo = &appInfo,
        .enabledLayerCount = @intCast(u32, instanceLayers.items.len),
        .ppEnabledLayerNames = instanceLayers.items.ptr,
        .enabledExtensionCount = instanceExtensionCount,
        .ppEnabledExtensionNames = instanceExtensions,
    };
    try convert(c.vezCreateInstance(&createInfo, &instance));

    // Enumerate all attached physical devices.
    var physicalDeviceCount: u32 = 0;
    try convert(c.vezEnumeratePhysicalDevices(instance, &physicalDeviceCount, null));
    if (physicalDeviceCount == 0) {
        fail("No vulkan physical devices found");
    }
    var physicalDevices = try allocator.alloc(c.VkPhysicalDevice, physicalDeviceCount);
    defer allocator.free(physicalDevices);
    try convert(c.vezEnumeratePhysicalDevices(instance, &physicalDeviceCount, physicalDevices.ptr));

    for (physicalDevices) |pdevice| {
        try stdout.print("{}\n", .{props(pdevice).deviceName});
    }
    physicalDevice = physicalDevices[0];
    try stdout.print("Selected device: {}\n", .{props(physicalDevice).deviceName});

    // Initialize a window using GLFW and hint no graphics API should be used on the backend.
    c.glfwWindowHint(c.GLFW_CLIENT_API, c.GLFW_NO_API);
    window = c.glfwCreateWindow(WIDTH, HEIGHT, NAME, null, null) orelse return error.FailedToCreateWindow;
    try SetWindowCenter(window);

    // Create a surface from the GLFW window handle.
    try convert(c.glfwCreateWindowSurface(instance, window, null, &surface));

    // Create the Vulkan device handle.
    var deviceExtensions: []const [*:0]const u8 = &[_][*:0]const u8{c.VK_KHR_SWAPCHAIN_EXTENSION_NAME};
    var deviceCreateInfo = c.VezDeviceCreateInfo{
        .pNext = null,
        .enabledLayerCount = 0,
        .ppEnabledLayerNames = null,
        .enabledExtensionCount = @intCast(u32, deviceExtensions.len),
        .ppEnabledExtensionNames = deviceExtensions.ptr,
    };
    try convert(c.vezCreateDevice(physicalDevice, &deviceCreateInfo, &device));

    // Create the swapchain.
    var swapchainCreateInfo = c.VezSwapchainCreateInfo{
        .pNext = null,
        .surface = surface,
        .format = c.VkSurfaceFormatKHR{ .format = .VK_FORMAT_B8G8R8A8_UNORM, .colorSpace = .VK_COLOR_SPACE_SRGB_NONLINEAR_KHR },
        .tripleBuffer = c.VK_TRUE,
    };
    try convert(c.vezCreateSwapchain(device, &swapchainCreateInfo, &swapchain));

    // Set callbacks.
    _ = c.glfwSetWindowSizeCallback(window, WindowSizeCallback);
    // c.glfwSetCursorPosCallback(window, CursorPosCallback);
    // c.glfwSetMouseButtonCallback(window, MouseButtonCallback);
    // c.glfwSetScrollCallback(window, MouseScrollCallback);
    // c.glfwSetKeyCallback(window, KeyCallback);

    c.glfwShowWindow(window);

    if (manageFramebuffer) {
        try CreateFramebuffer();
    }

    initialize();

    // // Track time elapsed from one Update call to the next.
    // double lastTime = glfwGetTime();

    // // Track fps.
    // double elapsedTime = 0.0;
    // uint32_t frameCount = 0;

    // // Message loop.
    // while (!glfwWindowShouldClose(m_window) && !m_quitSignaled)
    // {
    //     // Check for window messages to process.
    //     glfwPollEvents();

    //     // Update the application.
    //     double curTime = glfwGetTime();
    //     elapsedTime += curTime - lastTime;
    //     Update(static_cast<float>(curTime - lastTime));
    //     lastTime = curTime;

    //     // Draw the application.
    //     Draw();

    //     // Display the fps in the window title bar.
    //     ++frameCount;
    //     if (elapsedTime >= 1.0)
    //     {
    //         std::string text = m_name + " " + std::to_string(frameCount) + " FPS";
    //         if (m_windowTitleText.size() > 0)
    //             text += "    (" + m_windowTitleText + ")";
    //         glfwSetWindowTitle(m_window, text.c_str());
    //         elapsedTime = 0.0;
    //         frameCount = 0;
    //     }
    // }

    // // Wait for all device operations to complete.
    // vezDeviceWaitIdle(m_device);

    cleanup();

    if (manageFramebuffer) {
        framebuffer.deinit(device);
    }

    c.vezDestroySwapchain(device, swapchain);
    c.vezDestroyDevice(device);
    c.vkDestroySurfaceKHR(instance, surface, null);
    c.vezDestroyInstance(instance);
    std.time.sleep(100000000);
}

export fn WindowSizeCallback(wndw: ?*c.GLFWwindow, width: c_int, height: c_int) callconv(.C) void {
    // auto itr = appBaseInstances.find(window);
    // if (itr != appBaseInstances.end())
    // {
    //     // Wait for device to be idle.
    //     vkDeviceWaitIdle(itr->second->GetDevice());

    //     // Re-create the framebuffer.
    //     if (itr->second->m_manageFramebuffer)
    //         itr->second->CreateFramebuffer();

    //     // Now inform application of resize event.
    //     itr->second->OnResize(width, height);
    // }
}

fn initialize() void {
    CreateQuad();
    // CreateTexture();
    // CreateSampler();
    // CreateUniformBuffer();
    // CreatePipeline();
    // CreateCommandBuffer();
}

fn cleanup() void {
    c.vezDestroyBuffer(device, vertexBuffer.handle);
    c.vkFreeMemory(device, vertexBuffer.memory, null);
    c.vezDestroyBuffer(device, indexBuffer.handle);
    c.vkFreeMemory(device, indexBuffer.memory, null);
    // c.vezDestroyImageView(device, imageView);
    // c.vezDestroyImage(device, image);
    // c.vezDestroySampler(device, sampler);
    // c.vezDestroyBuffer(device, uniformBuffer);

    // c.vezDestroyPipeline(device, m_basicPipeline.pipeline);
    // for (basicPipeline.shaderModules) |shaderModule| {
    //     c.vezDestroyShaderModule(device, shaderModule);
    // }

    // c.vezFreeCommandBuffers(device, 1, &_commandBuffer);
}
