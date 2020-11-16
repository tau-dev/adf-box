const vk = @import("vulkan.zig");

usingnamespace @import("vez-l1.zig");

pub const struct_Swapchain_T = opaque {};
pub const Swapchain = ?*struct_Swapchain_T;
pub const struct_Pipeline_T = opaque {};
pub const Pipeline = ?*struct_Pipeline_T;
pub const struct_Framebuffer_T = opaque {};
pub const Framebuffer = ?*struct_Framebuffer_T;
pub const struct_VertexInputFormat_T = opaque {};
pub const VertexInputFormat = ?*struct_VertexInputFormat_T;
pub const MEMORY_GPU_ONLY = @enumToInt(enum_MemoryFlagsBits.MEMORY_GPU_ONLY);
pub const MEMORY_CPU_ONLY = @enumToInt(enum_MemoryFlagsBits.MEMORY_CPU_ONLY);
pub const MEMORY_CPU_TO_GPU = @enumToInt(enum_MemoryFlagsBits.MEMORY_CPU_TO_GPU);
pub const MEMORY_GPU_TO_CPU = @enumToInt(enum_MemoryFlagsBits.MEMORY_GPU_TO_CPU);
pub const MEMORY_DEDICATED_ALLOCATION = @enumToInt(enum_MemoryFlagsBits.MEMORY_DEDICATED_ALLOCATION);
pub const MEMORY_NO_ALLOCATION = @enumToInt(enum_MemoryFlagsBits.MEMORY_NO_ALLOCATION);
pub const enum_MemoryFlagsBits = extern enum(c_int) {
    MEMORY_GPU_ONLY = 0,
    MEMORY_CPU_ONLY = 1,
    MEMORY_CPU_TO_GPU = 2,
    MEMORY_GPU_TO_CPU = 4,
    MEMORY_DEDICATED_ALLOCATION = 8,
    MEMORY_NO_ALLOCATION = 16,
    _,
};
pub const MemoryFlagsBits = enum_MemoryFlagsBits;
pub const MemoryFlags = vk.Flags;
pub const BASE_TYPE_BOOL = @enumToInt(enum_BaseType.BASE_TYPE_BOOL);
pub const BASE_TYPE_CHAR = @enumToInt(enum_BaseType.BASE_TYPE_CHAR);
pub const BASE_TYPE_INT = @enumToInt(enum_BaseType.BASE_TYPE_INT);
pub const BASE_TYPE_UINT = @enumToInt(enum_BaseType.BASE_TYPE_UINT);
pub const BASE_TYPE_UINT64 = @enumToInt(enum_BaseType.BASE_TYPE_UINT64);
pub const BASE_TYPE_HALF = @enumToInt(enum_BaseType.BASE_TYPE_HALF);
pub const BASE_TYPE_FLOAT = @enumToInt(enum_BaseType.BASE_TYPE_FLOAT);
pub const BASE_TYPE_DOUBLE = @enumToInt(enum_BaseType.BASE_TYPE_DOUBLE);
pub const BASE_TYPE_STRUCT = @enumToInt(enum_BaseType.BASE_TYPE_STRUCT);
pub const enum_BaseType = extern enum(c_int) {
    BASE_TYPE_BOOL = 0,
    BASE_TYPE_CHAR = 1,
    BASE_TYPE_INT = 2,
    BASE_TYPE_UINT = 3,
    BASE_TYPE_UINT64 = 4,
    BASE_TYPE_HALF = 5,
    BASE_TYPE_FLOAT = 6,
    BASE_TYPE_DOUBLE = 7,
    BASE_TYPE_STRUCT = 8,
    _,
};
pub const BaseType = enum_BaseType;
pub const PIPELINE_RESOURCE_TYPE_INPUT = @enumToInt(enum_PipelineResourceType.PIPELINE_RESOURCE_TYPE_INPUT);
pub const PIPELINE_RESOURCE_TYPE_OUTPUT = @enumToInt(enum_PipelineResourceType.PIPELINE_RESOURCE_TYPE_OUTPUT);
pub const PIPELINE_RESOURCE_TYPE_SAMPLER = @enumToInt(enum_PipelineResourceType.PIPELINE_RESOURCE_TYPE_SAMPLER);
pub const PIPELINE_RESOURCE_TYPE_COMBINED_IMAGE_SAMPLER = @enumToInt(enum_PipelineResourceType.PIPELINE_RESOURCE_TYPE_COMBINED_IMAGE_SAMPLER);
pub const PIPELINE_RESOURCE_TYPE_SAMPLED_IMAGE = @enumToInt(enum_PipelineResourceType.PIPELINE_RESOURCE_TYPE_SAMPLED_IMAGE);
pub const PIPELINE_RESOURCE_TYPE_STORAGE_IMAGE = @enumToInt(enum_PipelineResourceType.PIPELINE_RESOURCE_TYPE_STORAGE_IMAGE);
pub const PIPELINE_RESOURCE_TYPE_UNIFORM_TEXEL_BUFFER = @enumToInt(enum_PipelineResourceType.PIPELINE_RESOURCE_TYPE_UNIFORM_TEXEL_BUFFER);
pub const PIPELINE_RESOURCE_TYPE_STORAGE_TEXEL_BUFFER = @enumToInt(enum_PipelineResourceType.PIPELINE_RESOURCE_TYPE_STORAGE_TEXEL_BUFFER);
pub const PIPELINE_RESOURCE_TYPE_UNIFORM_BUFFER = @enumToInt(enum_PipelineResourceType.PIPELINE_RESOURCE_TYPE_UNIFORM_BUFFER);
pub const PIPELINE_RESOURCE_TYPE_STORAGE_BUFFER = @enumToInt(enum_PipelineResourceType.PIPELINE_RESOURCE_TYPE_STORAGE_BUFFER);
pub const PIPELINE_RESOURCE_TYPE_INPUT_ATTACHMENT = @enumToInt(enum_PipelineResourceType.PIPELINE_RESOURCE_TYPE_INPUT_ATTACHMENT);
pub const PIPELINE_RESOURCE_TYPE_PUSH_CONSTANT_BUFFER = @enumToInt(enum_PipelineResourceType.PIPELINE_RESOURCE_TYPE_PUSH_CONSTANT_BUFFER);
pub const enum_PipelineResourceType = extern enum(c_int) {
    PIPELINE_RESOURCE_TYPE_INPUT = 0,
    PIPELINE_RESOURCE_TYPE_OUTPUT = 1,
    PIPELINE_RESOURCE_TYPE_SAMPLER = 2,
    PIPELINE_RESOURCE_TYPE_COMBINED_IMAGE_SAMPLER = 3,
    PIPELINE_RESOURCE_TYPE_SAMPLED_IMAGE = 4,
    PIPELINE_RESOURCE_TYPE_STORAGE_IMAGE = 5,
    PIPELINE_RESOURCE_TYPE_UNIFORM_TEXEL_BUFFER = 6,
    PIPELINE_RESOURCE_TYPE_STORAGE_TEXEL_BUFFER = 7,
    PIPELINE_RESOURCE_TYPE_UNIFORM_BUFFER = 8,
    PIPELINE_RESOURCE_TYPE_STORAGE_BUFFER = 9,
    PIPELINE_RESOURCE_TYPE_INPUT_ATTACHMENT = 10,
    PIPELINE_RESOURCE_TYPE_PUSH_CONSTANT_BUFFER = 11,
    _,
};
pub const PipelineResourceType = enum_PipelineResourceType;
pub const struct_ClearAttachment = extern struct {
    colorAttachment: u32,
    clearValue: vk.ClearValue,
};
pub const ClearAttachment = struct_ClearAttachment;
pub const struct_ApplicationInfo = extern struct {
    pNext: ?*const c_void = null,
    pApplicationName: [*c]const u8,
    applicationVersion: u32,
    pEngineName: [*c]const u8,
    engineVersion: u32,
};
pub const ApplicationInfo = struct_ApplicationInfo;
pub const struct_InstanceCreateInfo = extern struct {
    pNext: ?*const c_void = null,
    pApplicationInfo: [*c]const ApplicationInfo,
    enabledLayerCount: u32,
    ppEnabledLayerNames: [*c]const [*c]const u8,
    enabledExtensionCount: u32,
    ppEnabledExtensionNames: [*c]const [*c]const u8,
};
pub const InstanceCreateInfo = struct_InstanceCreateInfo;
pub const struct_SwapchainCreateInfo = extern struct {
    pNext: ?*const c_void = null,
    surface: vk.SurfaceKHR,
    format: vk.SurfaceFormatKHR,
    tripleBuffer: vk.Bool32,
};
pub const SwapchainCreateInfo = struct_SwapchainCreateInfo;
pub const struct_DeviceCreateInfo = extern struct {
    pNext: ?*const c_void = null,
    enabledLayerCount: u32,
    ppEnabledLayerNames: [*c]const [*c]const u8,
    enabledExtensionCount: u32,
    ppEnabledExtensionNames: [*c]const [*c]const u8,
};
pub const DeviceCreateInfo = struct_DeviceCreateInfo;
pub const struct_SubmitInfo = extern struct {
    pNext: ?*const c_void = null,
    waitSemaphoreCount: u32,
    pWaitSemaphores: [*c]const vk.Semaphore,
    pWaitDstStageMask: [*c]const vk.PipelineStageFlags,
    commandBufferCount: u32,
    pCommandBuffers: [*c]const vk.CommandBuffer,
    signalSemaphoreCount: u32,
    pSignalSemaphores: [*c]vk.Semaphore,
};
pub const SubmitInfo = struct_SubmitInfo;
pub const struct_PresentInfo = extern struct {
    pNext: ?*const c_void = null,
    waitSemaphoreCount: u32,
    pWaitSemaphores: [*c]const vk.Semaphore,
    pWaitDstStageMask: [*c]const vk.PipelineStageFlags,
    swapchainCount: u32,
    pSwapchains: [*c]const Swapchain,
    pImages: [*c]const vk.Image,
    signalSemaphoreCount: u32,
    pSignalSemaphores: [*c]vk.Semaphore,
    pResults: [*c]vk.Result,
};
pub const PresentInfo = struct_PresentInfo;
pub const struct_QueryPoolCreateInfo = extern struct {
    pNext: ?*const c_void = null,
    queryType: vk.QueryType,
    queryCount: u32,
    pipelineStatistics: vk.QueryPipelineStatisticFlags,
};
pub const QueryPoolCreateInfo = struct_QueryPoolCreateInfo;
pub const struct_CommandBufferAllocateInfo = extern struct {
    pNext: ?*const c_void = null,
    queue: vk.Queue,
    commandBufferCount: u32,
};
pub const CommandBufferAllocateInfo = struct_CommandBufferAllocateInfo;
pub const struct_ShaderModuleCreateInfo = extern struct {
    pNext: ?*const c_void = null,
    stage: vk.ShaderStageFlagBits,
    codeSize: usize,
    pCode: [*c]const u32,
    pGLSLSource: [*c]const u8,
    pEntryPoint: [*c]const u8,
};
pub const ShaderModuleCreateInfo = struct_ShaderModuleCreateInfo;
pub const struct_PipelineShaderStageCreateInfo = extern struct {
    pNext: ?*const c_void = null,
    module: vk.ShaderModule,
    pEntryPoint: [*c]const u8,
    pSpecializationInfo: [*c]const vk.SpecializationInfo,
};
pub const PipelineShaderStageCreateInfo = struct_PipelineShaderStageCreateInfo;
pub const struct_GraphicsPipelineCreateInfo = extern struct {
    pNext: ?*const c_void = null,
    stageCount: u32,
    pStages: [*c]const PipelineShaderStageCreateInfo,
};
pub const GraphicsPipelineCreateInfo = struct_GraphicsPipelineCreateInfo;
pub const struct_ComputePipelineCreateInfo = extern struct {
    pNext: ?*const c_void = null,
    pStage: [*c]const PipelineShaderStageCreateInfo,
};
pub const ComputePipelineCreateInfo = struct_ComputePipelineCreateInfo;
pub const struct_MemberInfo = extern struct {
    baseType: BaseType,
    offset: u32,
    size: u32,
    vecSize: u32,
    columns: u32,
    arraySize: u32,
    name: [256]u8,
    pNext: [*c]const struct_MemberInfo,
    pMembers: [*c]const struct_MemberInfo,
};
pub const MemberInfo = struct_MemberInfo;
pub const struct_PipelineResource = extern struct {
    stages: vk.ShaderStageFlags,
    resourceType: PipelineResourceType,
    baseType: BaseType,
    access: vk.AccessFlags,
    set: u32,
    binding: u32,
    location: u32,
    inputAttachmentIndex: u32,
    vecSize: u32,
    columns: u32,
    arraySize: u32,
    offset: u32,
    size: u32,
    name: [256]u8,
    pMembers: [*c]const MemberInfo,
};
pub const PipelineResource = struct_PipelineResource;
pub const struct_VertexInputFormatCreateInfo = extern struct {
    vertexBindingDescriptionCount: u32,
    pVertexBindingDescriptions: [*c]const vk.VertexInputBindingDescription,
    vertexAttributeDescriptionCount: u32,
    pVertexAttributeDescriptions: [*c]const vk.VertexInputAttributeDescription,
};
pub const VertexInputFormatCreateInfo = struct_VertexInputFormatCreateInfo;
pub const struct_SamplerCreateInfo = extern struct {
    pNext: ?*const c_void = null,
    magFilter: vk.Filter,
    minFilter: vk.Filter,
    mipmapMode: vk.SamplerMipmapMode,
    addressModeU: vk.SamplerAddressMode,
    addressModeV: vk.SamplerAddressMode,
    addressModeW: vk.SamplerAddressMode,
    mipLodBias: f32 = 0,
    anisotropyEnable: vk.Bool32 = 0,
    maxAnisotropy: f32 = 0,
    compareEnable: vk.Bool32 = 0,
    compareOp: vk.CompareOp = .COMPARE_OP_NEVER,
    minLod: f32 = 0,
    maxLod: f32 = 0,
    borderColor: vk.BorderColor = .BORDER_COLOR_FLOAT_TRANSPARENT_BLACK,
    unnormalizedCoordinates: vk.Bool32,
};
pub const SamplerCreateInfo = struct_SamplerCreateInfo;
pub const struct_BufferCreateInfo = extern struct {
    pNext: ?*const c_void = null,
    size: vk.DeviceSize,
    usage: vk.BufferUsageFlags,
    queueFamilyIndexCount: u32 = 0,
    pQueueFamilyIndices: [*c]const u32 = null,
};
pub const BufferCreateInfo = struct_BufferCreateInfo;
pub const struct_MappedBufferRange = extern struct {
    buffer: vk.Buffer,
    offset: vk.DeviceSize,
    size: vk.DeviceSize,
};
pub const MappedBufferRange = struct_MappedBufferRange;
pub const struct_BufferViewCreateInfo = extern struct {
    pNext: ?*const c_void = null,
    buffer: vk.Buffer,
    format: vk.Format,
    offset: vk.DeviceSize,
    range: vk.DeviceSize,
};
pub const BufferViewCreateInfo = struct_BufferViewCreateInfo;
pub const struct_ImageCreateInfo = extern struct {
    pNext: ?*const c_void = null,
    flags: vk.ImageCreateFlags = 0,
    imageType: vk.ImageType = .IMAGE_TYPE_2D,
    format: vk.Format,
    extent: vk.Extent3D,
    mipLevels: u32 = 1,
    arrayLayers: u32 = 1,
    samples: vk.SampleCountFlagBits = .SAMPLE_COUNT_1_BIT,
    tiling: vk.ImageTiling = .IMAGE_TILING_OPTIMAL,
    usage: vk.ImageUsageFlags,
    queueFamilyIndexCount: u32 = 0,
    pQueueFamilyIndices: [*c]const u32 = null,
};
pub const ImageCreateInfo = struct_ImageCreateInfo;
pub const struct_ImageSubresource = extern struct {
    mipLevel: u32,
    arrayLayer: u32,
};
pub const ImageSubresource = struct_ImageSubresource;
pub const struct_SubresourceLayout = extern struct {
    offset: vk.DeviceSize,
    size: vk.DeviceSize,
    rowPitch: vk.DeviceSize,
    arrayPitch: vk.DeviceSize,
    depthPitch: vk.DeviceSize,
};
pub const SubresourceLayout = struct_SubresourceLayout;
pub const struct_ImageSubresourceRange = extern struct {
    baseMipLevel: u32 = 0,
    levelCount: u32 = 1,
    baseArrayLayer: u32 = 0,
    layerCount: u32 = 1,
};
pub const ImageSubresourceRange = struct_ImageSubresourceRange;
pub const struct_ImageViewCreateInfo = extern struct {
    pNext: ?*const c_void = null,
    image: vk.Image,
    viewType: vk.ImageViewType,
    format: vk.Format,
    components: vk.ComponentMapping = vk.ComponentMapping{},
    subresourceRange: ImageSubresourceRange = ImageSubresourceRange{},
};
pub const ImageViewCreateInfo = struct_ImageViewCreateInfo;
pub const struct_FramebufferCreateInfo = extern struct {
    pNext: ?*const c_void = null,
    attachmentCount: u32,
    pAttachments: [*c]const vk.ImageView,
    width: u32,
    height: u32,
    layers: u32,
};
pub const FramebufferCreateInfo = struct_FramebufferCreateInfo;
pub const struct_InputAssemblyState = extern struct {
    pNext: ?*const c_void = null,
    topology: vk.PrimitiveTopology,
    primitiveRestartEnable: vk.Bool32,
};
pub const InputAssemblyState = struct_InputAssemblyState;
pub const struct_RasterizationState = extern struct {
    pNext: ?*const c_void = null,
    depthClampEnable: vk.Bool32,
    rasterizerDiscardEnable: vk.Bool32,
    polygonMode: vk.PolygonMode,
    cullMode: vk.CullModeFlags,
    frontFace: vk.FrontFace,
    depthBiasEnable: vk.Bool32,
};
pub const RasterizationState = struct_RasterizationState;
pub const struct_MultisampleState = extern struct {
    pNext: ?*const c_void = null,
    rasterizationSamples: vk.SampleCountFlagBits,
    sampleShadingEnable: vk.Bool32,
    minSampleShading: f32,
    pSampleMask: [*c]const vk.SampleMask,
    alphaToCoverageEnable: vk.Bool32,
    alphaToOneEnable: vk.Bool32,
};
pub const MultisampleStateCreateInfo = struct_MultisampleState;
pub const struct_StencilOpState = extern struct {
    failOp: vk.StencilOp,
    passOp: vk.StencilOp,
    depthFailOp: vk.StencilOp,
    compareOp: vk.CompareOp = .COMPARE_OP_NEVER,
};
pub const StencilOpState = struct_StencilOpState;
pub const struct_DepthStencilState = extern struct {
    pNext: ?*const c_void = null,
    depthTestEnable: vk.Bool32,
    depthWriteEnable: vk.Bool32,
    depthCompareOp: vk.CompareOp,
    depthBoundsTestEnable: vk.Bool32,
    stencilTestEnable: vk.Bool32,
    front: StencilOpState,
    back: StencilOpState,
};
pub const PipelineDepthStencilState = struct_DepthStencilState;
pub const struct_ColorBlendAttachmentState = extern struct {
    blendEnable: vk.Bool32,
    srcColorBlendFactor: vk.BlendFactor,
    dstColorBlendFactor: vk.BlendFactor,
    colorBlendOp: vk.BlendOp,
    srcAlphaBlendFactor: vk.BlendFactor,
    dstAlphaBlendFactor: vk.BlendFactor,
    alphaBlendOp: vk.BlendOp,
    colorWriteMask: vk.ColorComponentFlags,
};
pub const ColorBlendAttachmentState = struct_ColorBlendAttachmentState;
pub const struct_ColorBlendState = extern struct {
    pNext: ?*const c_void = null,
    logicOpEnable: vk.Bool32,
    logicOp: vk.LogicOp,
    attachmentCount: u32,
    pAttachments: [*c]const ColorBlendAttachmentState,
};
pub const ColorBlendState = struct_ColorBlendState;
pub const struct_AttachmentInfo = extern struct {
    loadOp: vk.AttachmentLoadOp,
    storeOp: vk.AttachmentStoreOp = .ATTACHMENT_STORE_OP_STORE,
    clearValue: vk.ClearValue,
};
pub const AttachmentReference = struct_AttachmentInfo;
pub const struct_RenderPassBeginInfo = extern struct {
    pNext: ?*const c_void = null,
    framebuffer: Framebuffer,
    attachmentCount: u32,
    pAttachments: [*c]const struct_AttachmentInfo,
};
pub const RenderPassBeginInfo = struct_RenderPassBeginInfo;
pub const struct_BufferCopy = extern struct {
    srcOffset: vk.DeviceSize,
    dstOffset: vk.DeviceSize,
    size: vk.DeviceSize,
};
pub const BufferCopy = struct_BufferCopy;
pub const struct_ImageSubresourceLayers = extern struct {
    mipLevel: u32 = 0,
    baseArrayLayer: u32 = 0,
    layerCount: u32 = 1,
};
pub const ImageSubresourceLayers = struct_ImageSubresourceLayers;
pub const struct_ImageSubDataInfo = extern struct {
    dataRowLength: u32 = 0,
    dataImageHeight: u32 = 0,
    imageSubresource: ImageSubresourceLayers = ImageSubresourceLayers{},
    imageOffset: vk.Offset3D = vk.Offset3D{},
    imageExtent: vk.Extent3D,
};
pub const ImageSubDataInfo = struct_ImageSubDataInfo;
pub const struct_ImageResolve = extern struct {
    srcSubresource: ImageSubresourceLayers,
    srcOffset: vk.Offset3D,
    dstSubresource: ImageSubresourceLayers,
    dstOffset: vk.Offset3D,
    extent: vk.Extent3D,
};
pub const ImageResolve = struct_ImageResolve;
pub const struct_ImageCopy = extern struct {
    srcSubresource: ImageSubresourceLayers,
    srcOffset: vk.Offset3D,
    dstSubresource: ImageSubresourceLayers,
    dstOffset: vk.Offset3D,
    extent: vk.Extent3D,
};
pub const ImageCopy = struct_ImageCopy;
pub const struct_ImageBlit = extern struct {
    srcSubresource: ImageSubresourceLayers,
    srcOffsets: [2]vk.Offset3D,
    dstSubresource: ImageSubresourceLayers,
    dstOffsets: [2]vk.Offset3D,
};
pub const ImageBlit = struct_ImageBlit;
pub const struct_BufferImageCopy = extern struct {
    bufferOffset: vk.DeviceSize,
    bufferRowLength: u32,
    bufferImageHeight: u32,
    imageSubresource: ImageSubresourceLayers,
    imageOffset: vk.Offset3D,
    imageExtent: vk.Extent3D,
};
pub const BufferImageCopy = struct_BufferImageCopy;

// Instance functions.
pub extern fn vezEnumerateInstanceExtensionProperties(pLayerName: [*c]const u8, pPropertyCount: [*c]u32, pProperties: [*c]vk.ExtensionProperties) vk.Result;
pub extern fn vezEnumerateInstanceLayerProperties(pPropertyCount: [*c]u32, pProperties: [*c]vk.LayerProperties) vk.Result;
pub extern fn vezCreateInstance(pCreateInfo: [*c]const InstanceCreateInfo, pInstance: [*c]vk.Instance) vk.Result;
pub extern fn vezDestroyInstance(instance: vk.Instance) void;
pub extern fn vezEnumeratePhysicalDevices(instance: vk.Instance, pPhysicalDeviceCount: [*c]u32, pPhysicalDevices: [*c]vk.PhysicalDevice) vk.Result;

// Physical device functions.
pub extern fn vezGetPhysicalDeviceProperties(physicalDevice: vk.PhysicalDevice, pProperties: [*c]vk.PhysicalDeviceProperties) void;
pub extern fn vezGetPhysicalDeviceFeatures(physicalDevice: vk.PhysicalDevice, pFeatures: [*c]vk.PhysicalDeviceFeatures) void;
pub extern fn vezGetPhysicalDeviceFormatProperties(physicalDevice: vk.PhysicalDevice, format: vk.Format, pFormatProperties: [*c]vk.FormatProperties) void;
pub extern fn vezGetPhysicalDeviceImageFormatProperties(physicalDevice: vk.PhysicalDevice, format: vk.Format, type: vk.ImageType, tiling: vk.ImageTiling, usage: vk.ImageUsageFlags, flags: vk.ImageCreateFlags, pImageFormatProperties: [*c]vk.ImageFormatProperties) vk.Result;
pub extern fn vezGetPhysicalDeviceQueueFamilyProperties(physicalDevice: vk.PhysicalDevice, pQueueFamilyPropertyCount: [*c]u32, pQueueFamilyProperties: [*c]vk.QueueFamilyProperties) void;
pub extern fn vezGetPhysicalDeviceSurfaceFormats(physicalDevice: vk.PhysicalDevice, surface: vk.SurfaceKHR, pSurfaceFormatCount: [*c]u32, pSurfaceFormats: [*c]vk.SurfaceFormatKHR) vk.Result;
pub extern fn vezGetPhysicalDevicePresentSupport(physicalDevice: vk.PhysicalDevice, queueFamilyIndex: u32, surface: vk.SurfaceKHR, pSupported: [*c]vk.Bool32) vk.Result;
pub extern fn vezEnumerateDeviceExtensionProperties(physicalDevice: vk.PhysicalDevice, pLayerName: [*c]const u8, pPropertyCount: [*c]u32, pProperties: [*c]vk.ExtensionProperties) vk.Result;
pub extern fn vezEnumerateDeviceLayerProperties(physicalDevice: vk.PhysicalDevice, pPropertyCount: [*c]u32, pProperties: [*c]vk.LayerProperties) vk.Result;

// Device functions.
pub extern fn vezCreateDevice(physicalDevice: vk.PhysicalDevice, pCreateInfo: [*c]const DeviceCreateInfo, pDevice: [*c]vk.Device) vk.Result;
pub extern fn vezDestroyDevice(device: vk.Device) void;
pub extern fn vezDeviceWaitIdle(device: vk.Device) vk.Result;
pub extern fn vezGetDeviceQueue(device: vk.Device, queueFamilyIndex: u32, queueIndex: u32, pQueue: [*c]vk.Queue) void;
pub extern fn vezGetDeviceGraphicsQueue(device: vk.Device, queueIndex: u32, pQueue: [*c]vk.Queue) void;
pub extern fn vezGetDeviceComputeQueue(device: vk.Device, queueIndex: u32, pQueue: [*c]vk.Queue) void;
pub extern fn vezGetDeviceTransferQueue(device: vk.Device, queueIndex: u32, pQueue: [*c]vk.Queue) void;

// Swapchain
pub extern fn vezCreateSwapchain(device: vk.Device, pCreateInfo: [*c]const SwapchainCreateInfo, pSwapchain: [*c]Swapchain) vk.Result;
pub extern fn vezDestroySwapchain(device: vk.Device, swapchain: Swapchain) void;
pub extern fn vezGetSwapchainSurfaceFormat(swapchain: Swapchain, pFormat: [*c]vk.SurfaceFormatKHR) void;
pub extern fn vezSwapchainSetVSync(swapchain: Swapchain, enabled: vk.Bool32) vk.Result;

// Queue functions.
pub extern fn vezQueueSubmit(queue: vk.Queue, submitCount: u32, pSubmits: [*c]const SubmitInfo, pFence: [*c]vk.Fence) vk.Result;
pub extern fn vezQueuePresent(queue: vk.Queue, pPresentInfo: [*c]const PresentInfo) vk.Result;
pub extern fn vezQueueWaitIdle(queue: vk.Queue) vk.Result;

// Synchronization primitives functions.
pub extern fn vezDestroyFence(device: vk.Device, fence: vk.Fence) void;
pub extern fn vezGetFenceStatus(device: vk.Device, fence: vk.Fence) vk.Result;
pub extern fn vezWaitForFences(device: vk.Device, fenceCount: u32, pFences: [*c]const vk.Fence, waitAll: vk.Bool32, timeout: u64) vk.Result;
pub extern fn vezDestroySemaphore(device: vk.Device, semaphore: vk.Semaphore) void;
pub extern fn vezCreateEvent(device: vk.Device, pEvent: [*c]vk.Event) vk.Result;
pub extern fn vezDestroyEvent(device: vk.Device, event: vk.Event) void;
pub extern fn vezGetEventStatus(device: vk.Device, event: vk.Event) vk.Result;
pub extern fn vezSetEvent(device: vk.Device, event: vk.Event) vk.Result;
pub extern fn vezResetEvent(device: vk.Device, event: vk.Event) vk.Result;

// Query pool functions.
pub extern fn vezCreateQueryPool(device: vk.Device, pCreateInfo: [*c]const QueryPoolCreateInfo, pQueryPool: [*c]vk.QueryPool) vk.Result;
pub extern fn vezDestroyQueryPool(device: vk.Device, queryPool: vk.QueryPool) void;
pub extern fn vezGetQueryPoolResults(device: vk.Device, queryPool: vk.QueryPool, firstQuery: u32, queryCount: u32, dataSize: usize, pData: ?*c_void, stride: vk.DeviceSize, flags: vk.QueryResultFlags) vk.Result;

// Shader module and pipeline functions.
pub extern fn vezCreateShaderModule(device: vk.Device, pCreateInfo: [*c]const ShaderModuleCreateInfo, pShaderModule: [*c]vk.ShaderModule) vk.Result;
pub extern fn vezDestroyShaderModule(device: vk.Device, shaderModule: vk.ShaderModule) void;
pub extern fn vezGetShaderModuleInfoLog(shaderModule: vk.ShaderModule, pLength: [*c]u32, pInfoLog: [*c]u8) void;
pub extern fn vezGetShaderModuleBinary(shaderModule: vk.ShaderModule, pLength: [*c]u32, pBinary: [*c]u32) vk.Result;
pub extern fn vezCreateGraphicsPipeline(device: vk.Device, pCreateInfo: [*c]const GraphicsPipelineCreateInfo, pPipeline: [*c]Pipeline) vk.Result;
pub extern fn vezCreateComputePipeline(device: vk.Device, pCreateInfo: [*c]const ComputePipelineCreateInfo, pPipeline: [*c]Pipeline) vk.Result;
pub extern fn vezDestroyPipeline(device: vk.Device, pipeline: Pipeline) void;
pub extern fn vezEnumeratePipelineResources(pipeline: Pipeline, pResourceCount: [*c]u32, ppResources: [*c]PipelineResource) vk.Result;
pub extern fn vezGetPipelineResource(pipeline: Pipeline, name: [*c]const u8, pResource: [*c]PipelineResource) vk.Result;

// Vertex input format functions.
pub extern fn vezCreateVertexInputFormat(device: vk.Device, pCreateInfo: [*c]const VertexInputFormatCreateInfo, pFormat: [*c]VertexInputFormat) vk.Result;
pub extern fn vezDestroyVertexInputFormat(device: vk.Device, format: VertexInputFormat) void;

// Sampler functions.
pub extern fn vezCreateSampler(device: vk.Device, pCreateInfo: [*c]const SamplerCreateInfo, pSampler: [*c]vk.Sampler) vk.Result;
pub extern fn vezDestroySampler(device: vk.Device, sampler: vk.Sampler) void;

// Buffer functions.
pub extern fn vezCreateBuffer(device: vk.Device, memFlags: MemoryFlags, pCreateInfo: [*c]const BufferCreateInfo, pBuffer: [*c]vk.Buffer) vk.Result;
pub extern fn vezDestroyBuffer(device: vk.Device, buffer: vk.Buffer) void;
pub extern fn vezBufferSubData(device: vk.Device, buffer: vk.Buffer, offset: vk.DeviceSize, size: vk.DeviceSize, pData: ?[*]const u8) vk.Result;
pub extern fn vezMapBuffer(device: vk.Device, buffer: vk.Buffer, offset: vk.DeviceSize, size: vk.DeviceSize, ppData: [*c]?*c_void) vk.Result;
pub extern fn vezUnmapBuffer(device: vk.Device, buffer: vk.Buffer) void;
pub extern fn vezFlushMappedBufferRanges(device: vk.Device, bufferRangeCount: u32, pBufferRanges: [*c]const MappedBufferRange) vk.Result;
pub extern fn vezInvalidateMappedBufferRanges(device: vk.Device, bufferRangeCount: u32, pBufferRanges: [*c]const MappedBufferRange) vk.Result;
pub extern fn vezCreateBufferView(device: vk.Device, pCreateInfo: [*c]const BufferViewCreateInfo, pView: [*c]vk.BufferView) vk.Result;
pub extern fn vezDestroyBufferView(device: vk.Device, bufferView: vk.BufferView) void;

// Image functions.
pub extern fn vezCreateImage(device: vk.Device, memFlags: MemoryFlags, pCreateInfo: [*c]const ImageCreateInfo, pImage: [*c]vk.Image) vk.Result;
pub extern fn vezDestroyImage(device: vk.Device, image: vk.Image) void;
pub extern fn vezImageSubData(device: vk.Device, image: vk.Image, pSubDataInfo: *const ImageSubDataInfo, pData: ?[*]const u8) vk.Result;
pub extern fn vezCreateImageView(device: vk.Device, pCreateInfo: *const ImageViewCreateInfo, pView: *vk.ImageView) vk.Result;
pub extern fn vezDestroyImageView(device: vk.Device, imageView: vk.ImageView) void;

// Framebuffer functions.
pub extern fn vezCreateFramebuffer(device: vk.Device, pCreateInfo: *const FramebufferCreateInfo, pFramebuffer: *Framebuffer) vk.Result;
pub extern fn vezDestroyFramebuffer(device: vk.Device, framebuffer: Framebuffer) void;

// Command buffer functions.
pub extern fn vezAllocateCommandBuffers(device: vk.Device, pAllocateInfo: *const CommandBufferAllocateInfo, pCommandBuffers: [*c]vk.CommandBuffer) vk.Result;
pub extern fn vezFreeCommandBuffers(device: vk.Device, commandBufferCount: u32, pCommandBuffers: [*c]const vk.CommandBuffer) void;
pub extern fn vezBeginCommandBuffer(commandBuffer: vk.CommandBuffer, flags: vk.CommandBufferUsageFlags) vk.Result;
pub extern fn vezEndCommandBuffer(...) vk.Result;
pub extern fn vezResetCommandBuffer(commandBuffer: vk.CommandBuffer) vk.Result;
pub extern fn vezCmdBeginRenderPass(pBeginInfo: [*c]const RenderPassBeginInfo) void;
pub extern fn vezCmdNextSubpass(...) void;
pub extern fn vezCmdEndRenderPass(...) void;
pub extern fn vezCmdBindPipeline(pipeline: Pipeline) void;
pub extern fn vezCmdPushConstants(offset: u32, size: u32, pValues: ?[*]const u8) void;
pub extern fn vezCmdBindBuffer(buffer: vk.Buffer, offset: vk.DeviceSize, range: vk.DeviceSize, set: u32, binding: u32, arrayElement: u32) void;
pub extern fn vezCmdBindBufferView(bufferView: vk.BufferView, set: u32, binding: u32, arrayElement: u32) void;
pub extern fn vezCmdBindImageView(imageView: vk.ImageView, sampler: vk.Sampler, set: u32, binding: u32, arrayElement: u32) void;
pub extern fn vezCmdBindSampler(sampler: vk.Sampler, set: u32, binding: u32, arrayElement: u32) void;
pub extern fn vezCmdBindVertexBuffers(firstBinding: u32, bindingCount: u32, pBuffers: [*]const vk.Buffer, pOffsets: [*]const vk.DeviceSize) void;
pub extern fn vezCmdBindIndexBuffer(buffer: vk.Buffer, offset: vk.DeviceSize, indexType: vk.IndexType) void;
pub extern fn vezCmdSetVertexInputFormat(format: VertexInputFormat) void;
pub extern fn vezCmdSetViewportState(viewportCount: u32) void;
pub extern fn vezCmdSetInputAssemblyState(pStateInfo: *const InputAssemblyState) void;
pub extern fn vezCmdSetRasterizationState(pStateInfo: *const RasterizationState) void;
pub extern fn vezCmdSetMultisampleState(pStateInfo: *const MultisampleStateCreateInfo) void;
pub extern fn vezCmdSetDepthStencilState(pStateInfo: *const PipelineDepthStencilState) void;
pub extern fn vezCmdSetColorBlendState(pStateInfo: *const ColorBlendState) void;
pub extern fn vezCmdSetViewport(firstViewport: u32, viewportCount: u32, pViewports: [*]const vk.Viewport) void;
pub extern fn vezCmdSetScissor(firstScissor: u32, scissorCount: u32, pScissors: [*]const vk.Rect2D) void;
pub extern fn vezCmdSetLineWidth(lineWidth: f32) void;
pub extern fn vezCmdSetDepthBias(depthBiasConstantFactor: f32, depthBiasClamp: f32, depthBiasSlopeFactor: f32) void;
pub extern fn vezCmdSetBlendConstants(blendConstants: [*c]const f32) void;
pub extern fn vezCmdSetDepthBounds(minDepthBounds: f32, maxDepthBounds: f32) void;
pub extern fn vezCmdSetStencilCompareMask(faceMask: vk.StencilFaceFlags, compareMask: u32) void;
pub extern fn vezCmdSetStencilWriteMask(faceMask: vk.StencilFaceFlags, writeMask: u32) void;
pub extern fn vezCmdSetStencilReference(faceMask: vk.StencilFaceFlags, reference: u32) void;
pub extern fn vezCmdDraw(vertexCount: u32, instanceCount: u32, firstVertex: u32, firstInstance: u32) void;
pub extern fn vezCmdDrawIndexed(indexCount: u32, instanceCount: u32, firstIndex: u32, vertexOffset: i32, firstInstance: u32) void;
pub extern fn vezCmdDrawIndirect(buffer: vk.Buffer, offset: vk.DeviceSize, drawCount: u32, stride: u32) void;
pub extern fn vezCmdDrawIndexedIndirect(buffer: vk.Buffer, offset: vk.DeviceSize, drawCount: u32, stride: u32) void;
pub extern fn vezCmdDispatch(groupCountX: u32, groupCountY: u32, groupCountZ: u32) void;
pub extern fn vezCmdDispatchIndirect(buffer: vk.Buffer, offset: vk.DeviceSize) void;
pub extern fn vezCmdCopyBuffer(srcBuffer: vk.Buffer, dstBuffer: vk.Buffer, regionCount: u32, pRegions: [*]const BufferCopy) void;
pub extern fn vezCmdCopyImage(srcImage: vk.Image, dstImage: vk.Image, regionCount: u32, pRegions: [*]const ImageCopy) void;
pub extern fn vezCmdBlitImage(srcImage: vk.Image, dstImage: vk.Image, regionCount: u32, pRegions: [*]const ImageBlit, filter: vk.Filter) void;
pub extern fn vezCmdCopyBufferToImage(srcBuffer: vk.Buffer, dstImage: vk.Image, regionCount: u32, pRegions: [*]const BufferImageCopy) void;
pub extern fn vezCmdCopyImageToBuffer(srcImage: vk.Image, dstBuffer: vk.Buffer, regionCount: u32, pRegions: [*]const BufferImageCopy) void;
pub extern fn vezCmdUpdateBuffer(dstBuffer: vk.Buffer, dstOffset: vk.DeviceSize, dataSize: vk.DeviceSize, pData: ?[*]const u8) void;
pub extern fn vezCmdFillBuffer(dstBuffer: vk.Buffer, dstOffset: vk.DeviceSize, size: vk.DeviceSize, data: u32) void;
pub extern fn vezCmdClearColorImage(image: vk.Image, pColor: [*c]const vk.ClearColorValue, rangeCount: u32, pRanges: [*]const ImageSubresourceRange) void;
pub extern fn vezCmdClearDepthStencilImage(image: vk.Image, pDepthStencil: *const vk.ClearDepthStencilValue, rangeCount: u32, pRanges: [*]const ImageSubresourceRange) void;
pub extern fn vezCmdClearAttachments(attachmentCount: u32, pAttachments: [*]const ClearAttachment, rectCount: u32, pRects: [*]const vk.ClearRect) void;
pub extern fn vezCmdResolveImage(srcImage: vk.Image, dstImage: vk.Image, regionCount: u32, pRegions: [*]const ImageResolve) void;
pub extern fn vezCmdSetEvent(event: vk.Event, stageMask: vk.PipelineStageFlags) void;
pub extern fn vezCmdResetEvent(event: vk.Event, stageMask: vk.PipelineStageFlags) void;

pub const Swapchain_T = struct_Swapchain_T;
pub const Pipeline_T = struct_Pipeline_T;
pub const Framebuffer_T = struct_Framebuffer_T;
pub const VertexInputFormat_T = struct_VertexInputFormat_T;
pub const MultisampleState = struct_MultisampleState;
pub const DepthStencilState = struct_DepthStencilState;
pub const AttachmentInfo = struct_AttachmentInfo;
