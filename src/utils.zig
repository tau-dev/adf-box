const std = @import("std");
pub const vk = @import("lib/vulkan.zig");
pub const vez = @import("lib/vez.zig");
pub const c = @import("lib/glfw3.zig");

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
    const stdout = std.io.getStdOut().outStream();

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