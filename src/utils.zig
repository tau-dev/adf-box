const std = @import("std");
pub const vk = @import("lib/vulkan.zig");
pub const vez = @import("lib/vez.zig");
pub const c = @import("lib/glfw3.zig");
const base = @import("main.zig");

const NameSet = std.AutoHashMap([256]u8, void);
pub const isDebug = @import("builtin").mode == .Debug;

pub fn makeVkVersion(major: u32, minor: anytype, patch: anytype) u32 {
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

pub fn getInstanceLayers(allocator: *std.mem.Allocator) !NameSet {
    const stdout = std.io.getStdOut().writer();

    var extensionCount: u32 = 0;
    try convert(vez.enumerateInstanceExtensionProperties(null, &extensionCount, null));

    var extensions = try allocator.alloc(vk.ExtensionProperties, extensionCount);
    defer allocator.free(extensions);
    try convert(vez.enumerateInstanceExtensionProperties(null, &extensionCount, extensions.ptr));

    if (isDebug) {
        try stdout.writeAll("Available extensions: ");
        for (extensions) |extension| {
            try stdout.print("{}, ", .{@ptrCast([*:0]const u8, &extension.extensionName)});
        }
        try stdout.writeAll("\n");
    }

    // Enumerate all available instance layers
    var layerCount: u32 = 0;
    try convert(vez.enumerateInstanceLayerProperties(&layerCount, null));

    var layerProperties = try allocator.alloc(vk.LayerProperties, layerCount);
    defer allocator.free(layerProperties);

    try convert(vez.enumerateInstanceLayerProperties(&layerCount, layerProperties.ptr));
    var set = NameSet.init(allocator);
    for (layerProperties) |prop| {
        _ = try set.put(prop.layerName, .{});
    }
    return set;
}


pub const Buffer = struct {
    handle: vk.Buffer,
    memory: vk.DeviceMemory,
    size: usize,

    pub fn init(self: *@This(), device: vk.Device, usage: vk.BufferUsageFlags, size: usize) VulkanError!void {
        // Create the device side buffer.
        var bufferCreateInfo = vez.BufferCreateInfo{
            .size = size,
            .usage = @intCast(u32, vk.BUFFER_USAGE_TRANSFER_DST_BIT) | usage,
        };
        try convert(vez.createBuffer(base.getDevice(), vez.MEMORY_NO_ALLOCATION, &bufferCreateInfo, &self.handle));
        // Allocate memory for the buffer.
        var memRequirements: vk.MemoryRequirements = undefined;
        vk.getBufferMemoryRequirements(base.getDevice(), self.handle, &memRequirements);

        self.size = memRequirements.size;
        var allocInfo = vk.MemoryAllocateInfo{
            .allocationSize = memRequirements.size,
            .memoryTypeIndex = findMemoryType(base.getPhysicalDevice(), memRequirements.memoryTypeBits, vk.MEMORY_PROPERTY_HOST_VISIBLE_BIT | vk.MEMORY_PROPERTY_HOST_COHERENT_BIT),
        };

        try convert(vk.allocateMemory(base.getDevice(), &allocInfo, null, &self.memory));

        // Bind the memory to the buffer.
        try convert(vk.bindBufferMemory(base.getDevice(), self.handle, self.memory, 0));
    }

    pub fn load(self: @This(), data: anytype) !void {
        const T = @typeInfo(@TypeOf(data)).Pointer.child;

        std.debug.assert(data.len * @sizeOf(T) <= self.size);
        var pData: [*]u8 = undefined;
        try convert(vk.mapMemory(base.getDevice(), self.memory, 0, self.size, 0, @ptrCast(*?*c_void, &pData)));
        const src = std.mem.sliceAsBytes(data);
        std.mem.copy(u8, pData[0..src.len], src);
        vk.unmapMemory(base.getDevice(), self.memory);
    }
    pub fn deinit(self: @This(), device: vk.Device) void {
        vez.destroyBuffer(device, self.handle);
        vk.freeMemory(device, self.memory, null);
    }
};

fn findMemoryType(physicalDevice: vk.PhysicalDevice, typeFilter: u32, properties: vk.MemoryPropertyFlags) u32 {
    var memProperties: vk.PhysicalDeviceMemoryProperties = undefined;
    vk.getPhysicalDeviceMemoryProperties(physicalDevice, &memProperties);
    var i: u5 = 0;
    const mask: u32 = 1;
    while (i < memProperties.memoryTypeCount) : (i += 1) {
        if (typeFilter & (mask << i) != 0 and (memProperties.memoryTypes[i].propertyFlags & properties) == properties)
            return i;
    }

    return 0;
}


pub const Image = struct {
    texture: vk.Image = null,
    view: vk.ImageView = null,
    sampler: vk.Sampler = null,
    width: u32 = 0,
    height: u32 = 0,

    pub fn init(self: *@This(), createInfo: vez.ImageCreateInfo, filter: vk.Filter, addressMode: vk.SamplerAddressMode) VulkanError!void {
        self.width = createInfo.extent.width;
        self.height = createInfo.extent.height;
        try convert(vez.createImage(base.getDevice(), vez.MEMORY_GPU_ONLY, &createInfo, &self.texture));

        // Create the image view for binding the texture as a resource.
        var imageViewCreateInfo = vez.ImageViewCreateInfo{
            .image = self.texture,
            .viewType = .IMAGE_VIEW_TYPE_2D,
            .format = createInfo.format,
            .subresourceRange = .{ .layerCount = 1, .levelCount = 1, .baseMipLevel = 0, .baseArrayLayer = 0 }, // defaults
        };
        try convert(vez.createImageView(base.getDevice(), &imageViewCreateInfo, &self.view));

        const samplerInfo = vez.SamplerCreateInfo{
            .magFilter = filter, // default?
            .minFilter = filter, // default?
            .mipmapMode = .SAMPLER_MIPMAP_MODE_LINEAR, // default?
            .addressModeU = addressMode, // default?
            .addressModeV = addressMode, // default?
            .addressModeW = addressMode, // default?
            .unnormalizedCoordinates = 0,
            .borderColor = .BORDER_COLOR_INT_OPAQUE_BLACK,
        };
        try convert(vez.createSampler(base.getDevice(), &samplerInfo, &self.sampler));
    }

    pub fn cmdBind(self: @This(), set: u32, binding: u32) void {
        vez.cmdBindImageView(self.view, self.sampler, set, binding, 0); // self.sampler
    }

    pub fn deinit(self: @This(), device: vk.Device) void {
        vez.destroyImageView(device, self.view);
        vez.destroyImage(device, self.texture);
        vez.destroySampler(device, self.sampler);
    }
};
