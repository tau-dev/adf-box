const l0 = @import("vez.zig");

// Instance functions.
pub const enumerateInstanceExtensionProperties = l0.vezEnumerateInstanceExtensionProperties;
pub const enumerateInstanceLayerProperties = l0.vezEnumerateInstanceLayerProperties;
pub const createInstance = l0.vezCreateInstance;
pub const destroyInstance = l0.vezDestroyInstance;
pub const enumeratePhysicalDevices = l0.vezEnumeratePhysicalDevices;

// Physical device functions.
pub const getPhysicalDeviceProperties = l0.vezGetPhysicalDeviceProperties;
pub const getPhysicalDeviceFeatures = l0.vezGetPhysicalDeviceFeatures;
pub const getPhysicalDeviceFormatProperties = l0.vezGetPhysicalDeviceFormatProperties;
pub const getPhysicalDeviceImageFormatProperties = l0.vezGetPhysicalDeviceImageFormatProperties;
pub const getPhysicalDeviceQueueFamilyProperties = l0.vezGetPhysicalDeviceQueueFamilyProperties;
pub const getPhysicalDeviceSurfaceFormats = l0.vezGetPhysicalDeviceSurfaceFormats;
pub const getPhysicalDevicePresentSupport = l0.vezGetPhysicalDevicePresentSupport;
pub const enumerateDeviceExtensionProperties = l0.vezEnumerateDeviceExtensionProperties;
pub const enumerateDeviceLayerProperties = l0.vezEnumerateDeviceLayerProperties;

// Device functions.
pub const createDevice = l0.vezCreateDevice;
pub const destroyDevice = l0.vezDestroyDevice;
pub const deviceWaitIdle = l0.vezDeviceWaitIdle;
pub const getDeviceQueue = l0.vezGetDeviceQueue;
pub const getDeviceGraphicsQueue = l0.vezGetDeviceGraphicsQueue;
pub const getDeviceComputeQueue = l0.vezGetDeviceComputeQueue;
pub const getDeviceTransferQueue = l0.vezGetDeviceTransferQueue;

// Swapchain
pub const createSwapchain = l0.vezCreateSwapchain;
pub const destroySwapchain = l0.vezDestroySwapchain;
pub const getSwapchainSurfaceFormat = l0.vezGetSwapchainSurfaceFormat;
pub const swapchainSetVSync = l0.vezSwapchainSetVSync;

// Queue functions.
pub const queueSubmit = l0.vezQueueSubmit;
pub const queuePresent = l0.vezQueuePresent;
pub const queueWaitIdle = l0.vezQueueWaitIdle;

// Synchronization primitives functions.
pub const destroyFence = l0.vezDestroyFence;
pub const getFenceStatus = l0.vezGetFenceStatus;
pub const waitForFences = l0.vezWaitForFences;
pub const destroySemaphore = l0.vezDestroySemaphore;
pub const createEvent = l0.vezCreateEvent;
pub const destroyEvent = l0.vezDestroyEvent;
pub const getEventStatus = l0.vezGetEventStatus;
pub const setEvent = l0.vezSetEvent;
pub const resetEvent = l0.vezResetEvent;

// Query pool functions.
pub const createQueryPool = l0.vezCreateQueryPool;
pub const destroyQueryPool = l0.vezDestroyQueryPool;
pub const getQueryPoolResults = l0.vezGetQueryPoolResults;

// Shader module and pipeline functions.
pub const createShaderModule = l0.vezCreateShaderModule;
pub const destroyShaderModule = l0.vezDestroyShaderModule;
pub const getShaderModuleInfoLog = l0.vezGetShaderModuleInfoLog;
pub const getShaderModuleBinary = l0.vezGetShaderModuleBinary;
pub const createGraphicsPipeline = l0.vezCreateGraphicsPipeline;
pub const createComputePipeline = l0.vezCreateComputePipeline;
pub const destroyPipeline = l0.vezDestroyPipeline;
pub const enumeratePipelineResources = l0.vezEnumeratePipelineResources;
pub const getPipelineResource = l0.vezGetPipelineResource;

// Vertex input format functions.
pub const createVertexInputFormat = l0.vezCreateVertexInputFormat;
pub const destroyVertexInputFormat = l0.vezDestroyVertexInputFormat;

// Sampler functions.
pub const createSampler = l0.vezCreateSampler;
pub const destroySampler = l0.vezDestroySampler;

// Buffer functions.
pub const createBuffer = l0.vezCreateBuffer;
pub const destroyBuffer = l0.vezDestroyBuffer;
pub const bufferSubData = l0.vezBufferSubData;
pub const mapBuffer = l0.vezMapBuffer;
pub const unmapBuffer = l0.vezUnmapBuffer;
pub const flushMappedBufferRanges = l0.vezFlushMappedBufferRanges;
pub const invalidateMappedBufferRanges = l0.vezInvalidateMappedBufferRanges;
pub const createBufferView = l0.vezCreateBufferView;
pub const destroyBufferView = l0.vezDestroyBufferView;

// Image functions.
pub const createImage = l0.vezCreateImage;
pub const destroyImage = l0.vezDestroyImage;
pub const imageSubData = l0.vezImageSubData;
pub const createImageView = l0.vezCreateImageView;
pub const destroyImageView = l0.vezDestroyImageView;

// Framebuffer functions.
pub const createFramebuffer = l0.vezCreateFramebuffer;
pub const destroyFramebuffer = l0.vezDestroyFramebuffer;

// Command buffer functions.
pub const allocateCommandBuffers = l0.vezAllocateCommandBuffers;
pub const freeCommandBuffers = l0.vezFreeCommandBuffers;
pub const beginCommandBuffer = l0.vezBeginCommandBuffer;
pub const endCommandBuffer = l0.vezEndCommandBuffer;
pub const resetCommandBuffer = l0.vezResetCommandBuffer;
pub const cmdBeginRenderPass = l0.vezCmdBeginRenderPass;
pub const cmdNextSubpass = l0.vezCmdNextSubpass;
pub const cmdEndRenderPass = l0.vezCmdEndRenderPass;
pub const cmdBindPipeline = l0.vezCmdBindPipeline;
pub const cmdPushConstants = l0.vezCmdPushConstants;
pub const cmdBindBuffer = l0.vezCmdBindBuffer;
pub const cmdBindBufferView = l0.vezCmdBindBufferView;
pub const cmdBindImageView = l0.vezCmdBindImageView;
pub const cmdBindSampler = l0.vezCmdBindSampler;
pub const cmdBindVertexBuffers = l0.vezCmdBindVertexBuffers;
pub const cmdBindIndexBuffer = l0.vezCmdBindIndexBuffer;
pub const cmdSetVertexInputFormat = l0.vezCmdSetVertexInputFormat;
pub const cmdSetViewportState = l0.vezCmdSetViewportState;
pub const cmdSetInputAssemblyState = l0.vezCmdSetInputAssemblyState;
pub const cmdSetRasterizationState = l0.vezCmdSetRasterizationState;
pub const cmdSetMultisampleState = l0.vezCmdSetMultisampleState;
pub const cmdSetDepthStencilState = l0.vezCmdSetDepthStencilState;
pub const cmdSetColorBlendState = l0.vezCmdSetColorBlendState;
pub const cmdSetViewport = l0.vezCmdSetViewport;
pub const cmdSetScissor = l0.vezCmdSetScissor;
pub const cmdSetLineWidth = l0.vezCmdSetLineWidth;
pub const cmdSetDepthBias = l0.vezCmdSetDepthBias;
pub const cmdSetBlendConstants = l0.vezCmdSetBlendConstants;
pub const cmdSetDepthBounds = l0.vezCmdSetDepthBounds;
pub const cmdSetStencilCompareMask = l0.vezCmdSetStencilCompareMask;
pub const cmdSetStencilWriteMask = l0.vezCmdSetStencilWriteMask;
pub const cmdSetStencilReference = l0.vezCmdSetStencilReference;
pub const cmdDraw = l0.vezCmdDraw;
pub const cmdDrawIndexed = l0.vezCmdDrawIndexed;
pub const cmdDrawIndirect = l0.vezCmdDrawIndirect;
pub const cmdDrawIndexedIndirect = l0.vezCmdDrawIndexedIndirect;
pub const cmdDispatch = l0.vezCmdDispatch;
pub const cmdDispatchIndirect = l0.vezCmdDispatchIndirect;
pub const cmdCopyBuffer = l0.vezCmdCopyBuffer;
pub const cmdCopyImage = l0.vezCmdCopyImage;
pub const cmdBlitImage = l0.vezCmdBlitImage;
pub const cmdCopyBufferToImage = l0.vezCmdCopyBufferToImage;
pub const cmdCopyImageToBuffer = l0.vezCmdCopyImageToBuffer;
pub const cmdUpdateBuffer = l0.vezCmdUpdateBuffer;
pub const cmdFillBuffer = l0.vezCmdFillBuffer;
pub const cmdClearColorImage = l0.vezCmdClearColorImage;
pub const cmdClearDepthStencilImage = l0.vezCmdClearDepthStencilImage;
pub const cmdClearAttachments = l0.vezCmdClearAttachments;
pub const cmdResolveImage = l0.vezCmdResolveImage;
pub const cmdSetEvent = l0.vezCmdSetEvent;
pub const cmdResetEvent = l0.vezCmdResetEvent;
