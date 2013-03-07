WebGL Texture Float Extension Shims
===================================

In order to reliably work with floating point textures in WebGL it is required to figure out if they can be rendered to and if they support linear interpolation.

Some extensions have been proposed or are in draft that help with this. Unfortunately they face resistance by Khronos and even if approved, implementations may lag substantially.

The purpose of this library is to support these extensions as shims in the form of feature detection.

Shimmed extensions
------------------

 * OES_texture_float_linear
 * OES_texture_half_float_linear
 * WEBGL_color_buffer_float
 * EXT_color_buffer_half_float

Modified WebGL calls
--------------------

To make integration seamless this shim modifies calls to getSupportedExtensions and getExtension.

Additions
---------

If an extension is provided by a shim, the extension object will carry an attribute named shim to signal that.

```javascript
    var ext = gl.getExtension('OES_texture_float_linear');
    if(ext && ext.shim){
        // extension comes from a shim
    }

```

How it works
------------

In order to figure out if the color buffer extensions are supported the library creates a dummy FBO and attaches a texture of type FLOAT and HALF_FLOAT_OES.

To find out if linear interpolation is supported the library creates an FBO and a source texture filled with black/white colors side by side. This texture is sampled from and if the resulting color read back by readPixels is near 127, linear interpolation is assumed to be present.

Caveats
-------

 * The library cannot actually enable these extensions, so if the browser does not have the functionality enabled already internally, the extensions will not be provided.
 * Some capabilities of the color buffer family of extensions cannot be shimmed such as the ability to read back floating point values and querying FBO attachment points types.

How to use it
-------------

Include the library in your html documents head

```html
    <script src="webgl-texture-float-extension-shims.js"></script>
```
