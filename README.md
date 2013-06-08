WebGL Texture Float Extension Shims
===================================

In order to reliably work with floating point textures in WebGL it is required to figure out if they can be rendered to and if they support linear interpolation.

Some extensions have been proposed or are in draft that help with this. Unfortunately they face resistance by Khronos and even if approved, implementations may lag substantially.

The purpose of this library is to support these extensions as shims in the form of feature detection. The libary does also verify that the extensions actually offered perform as promised, which is not always the case. In case that capabilities are found to be lacking, the extensions are blacklisted.

Shimmed extensions
------------------

 * OES_texture_float_linear
 * OES_texture_half_float_linear
 * WEBGL_color_buffer_float
 * EXT_color_buffer_half_float

Modified WebGL calls
--------------------

To make integration seamless this shim modifies calls to getSupportedExtensions and getExtension.

Handling of vendor prefixes
---------------------------

It is recommended you include the vendor prefix nuke before including the shim libary
        
```html
    <script src="webgl-nuke-vendor-prefix.js"></script>
```

Convenience functionality
-------------------------

If you do not care to interprete and handle the 6 extensions that together express floating point support, you can use the function getFloatExtension on the WebGL context.

```javascript
    var ext = gl.getFloatExtension({
        require: ['renderable'],
        prefer: ['filterable', 'half']
    });
    console.log(ext.precision, ext.filterable, ext.renderable);
    var texture = gl.createTexture();
    gl.bindTexture(gl.TEXTURE_2D, texture);
    gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, 2, 2, 0, gl.RGBA, ext.type, null);
```

The call to getFloatExtension accepts:

 * require: a list of required capability, such as filterable, renderable, half or single
 * prefer: a list of preferred capability such as filterable, renderable, half or single

Prefer is evaluated from first to last, so earlier preferences take precedence over latter ones.

The returned object contains:

 * renderable: true or false
 * filterable: true or false
 * precision: half or single
 * type: the gl enumerant for this type

Extension Object Additions
--------------------------

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
