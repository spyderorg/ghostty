//! This file contains the definitions of the Metal API that we use.

/// https://developer.apple.com/documentation/metal/mtlcommandbufferstatus?language=objc
pub const MTLCommandBufferStatus = enum(c_ulong) {
    not_enqueued = 0,
    enqueued = 1,
    committed = 2,
    scheduled = 3,
    completed = 4,
    @"error" = 5,
    _,
};

/// https://developer.apple.com/documentation/metal/mtlloadaction?language=objc
pub const MTLLoadAction = enum(c_ulong) {
    dont_care = 0,
    load = 1,
    clear = 2,
};

/// https://developer.apple.com/documentation/metal/mtlstoreaction?language=objc
pub const MTLStoreAction = enum(c_ulong) {
    dont_care = 0,
    store = 1,
};

/// https://developer.apple.com/documentation/metal/mtlstoragemode?language=objc
pub const MTLStorageMode = enum(c_ulong) {
    shared = 0,
    managed = 1,
    private = 2,
    memoryless = 3,
};

/// https://developer.apple.com/documentation/metal/mtlprimitivetype?language=objc
pub const MTLPrimitiveType = enum(c_ulong) {
    point = 0,
    line = 1,
    line_strip = 2,
    triangle = 3,
    triangle_strip = 4,
};

/// https://developer.apple.com/documentation/metal/mtlindextype?language=objc
pub const MTLIndexType = enum(c_ulong) {
    uint16 = 0,
    uint32 = 1,
};

/// https://developer.apple.com/documentation/metal/mtlvertexformat?language=objc
pub const MTLVertexFormat = enum(c_ulong) {
    uchar4 = 3,
    ushort2 = 13,
    short2 = 16,
    float2 = 29,
    float4 = 31,
    int2 = 33,
    uint = 36,
    uint2 = 37,
    uint4 = 39,
    uchar = 45,
};

/// https://developer.apple.com/documentation/metal/mtlvertexstepfunction?language=objc
pub const MTLVertexStepFunction = enum(c_ulong) {
    constant = 0,
    per_vertex = 1,
    per_instance = 2,
};

/// https://developer.apple.com/documentation/metal/mtlpixelformat?language=objc
pub const MTLPixelFormat = enum(c_ulong) {
    r8unorm = 10,
    rgba8unorm = 70,
    rgba8uint = 73,
    bgra8unorm = 80,
};

/// https://developer.apple.com/documentation/metal/mtlpurgeablestate?language=objc
pub const MTLPurgeableState = enum(c_ulong) {
    empty = 4,
};

/// https://developer.apple.com/documentation/metal/mtlsamplerminmagfilter?language=objc
pub const MTLSamplerMinMagFilter = enum(c_ulong) {
    nearest = 0,
    linear = 1,
};

/// https://developer.apple.com/documentation/metal/mtlsampleraddressmode?language=objc
pub const MTLSamplerAddressMode = enum(c_ulong) {
    clamp_to_edge = 0,
    mirror_clamp_to_edge = 1,
    repeat = 2,
    mirror_repeat = 3,
    clamp_to_zero = 4,
    clamp_to_border_color = 5,
};

/// https://developer.apple.com/documentation/metal/mtlblendfactor?language=objc
pub const MTLBlendFactor = enum(c_ulong) {
    zero = 0,
    one = 1,
    source_color = 2,
    one_minus_source_color = 3,
    source_alpha = 4,
    one_minus_source_alpha = 5,
    dest_color = 6,
    one_minus_dest_color = 7,
    dest_alpha = 8,
    one_minus_dest_alpha = 9,
    source_alpha_saturated = 10,
    blend_color = 11,
    one_minus_blend_color = 12,
    blend_alpha = 13,
    one_minus_blend_alpha = 14,
    source_1_color = 15,
    one_minus_source_1_color = 16,
    source_1_alpha = 17,
    one_minus_source_1_alpha = 18,
};

/// https://developer.apple.com/documentation/metal/mtlblendoperation?language=objc
pub const MTLBlendOperation = enum(c_ulong) {
    add = 0,
    subtract = 1,
    reverse_subtract = 2,
    min = 3,
    max = 4,
};

/// https://developer.apple.com/documentation/metal/mtltextureusage?language=objc<D-j>
pub const MTLTextureUsage = enum(c_ulong) {
    unknown = 0,
    shader_read = 1,
    shader_write = 2,
    render_target = 4,
    pixel_format_view = 8,
};

/// https://developer.apple.com/documentation/metal/mtlresourceoptions?language=objc
/// (incomplete, we only use this mode so we just hardcode it)
pub const MTLResourceStorageModeShared: c_ulong = @intFromEnum(MTLStorageMode.shared) << 4;

pub const MTLClearColor = extern struct {
    red: f64,
    green: f64,
    blue: f64,
    alpha: f64,
};

pub const MTLViewport = extern struct {
    x: f64,
    y: f64,
    width: f64,
    height: f64,
    znear: f64,
    zfar: f64,
};

pub const MTLRegion = extern struct {
    origin: MTLOrigin,
    size: MTLSize,
};

pub const MTLOrigin = extern struct {
    x: c_ulong,
    y: c_ulong,
    z: c_ulong,
};

pub const MTLSize = extern struct {
    width: c_ulong,
    height: c_ulong,
    depth: c_ulong,
};

pub extern "c" fn MTLCopyAllDevices() ?*anyopaque;
