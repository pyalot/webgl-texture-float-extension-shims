checkFloatLinear = (gl, sourceType) ->
    ## drawing program ##
    program = gl.createProgram()
    vertexShader = gl.createShader(gl.VERTEX_SHADER)
    gl.attachShader(program, vertexShader)
    gl.shaderSource(vertexShader, '''
        attribute vec2 position;
        void main(){
            gl_Position = vec4(position, 0.0, 1.0);
        }
    ''')

    gl.compileShader(vertexShader)
    if not gl.getShaderParameter(vertexShader, gl.COMPILE_STATUS)
        throw gl.getShaderInfoLog(vertexShader)

    fragmentShader = gl.createShader(gl.FRAGMENT_SHADER)
    gl.attachShader(program, fragmentShader)
    gl.shaderSource(fragmentShader, '''
        uniform sampler2D source;
        void main(){
            gl_FragColor = texture2D(source, vec2(1.0, 1.0));
        }
    ''')
    gl.compileShader(fragmentShader)
    if not gl.getShaderParameter(fragmentShader, gl.COMPILE_STATUS)
        throw gl.getShaderInfoLog(fragmentShader)

    gl.linkProgram(program)
    if not gl.getProgramParameter(program, gl.LINK_STATUS)
        throw gl.getProgramInfoLog(program)
    
    gl.useProgram(program)

    ## target FBO ##
    target = gl.createTexture()
    gl.bindTexture(gl.TEXTURE_2D, target)
    gl.texImage2D(
        gl.TEXTURE_2D,
        0,
        gl.RGBA,
        2, 2,
        0,
        gl.RGBA,
        gl.UNSIGNED_BYTE,
        null,
    )
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR)

    framebuffer = gl.createFramebuffer()
    gl.bindFramebuffer(gl.FRAMEBUFFER, framebuffer)
    gl.framebufferTexture2D(
        gl.FRAMEBUFFER,
        gl.COLOR_ATTACHMENT0,
        gl.TEXTURE_2D,
        target,
        0
    )
    
    ## source texture ##
    data = new Float32Array([
        0,0,0,0,
        1,1,1,1,
        0,0,0,0,
        1,1,1,1,
    ])

    source = gl.createTexture()
    gl.bindTexture(gl.TEXTURE_2D, source)
    gl.texImage2D(
        gl.TEXTURE_2D,
        0,
        gl.RGBA,
        2, 2,
        0,
        gl.RGBA,
        sourceType,
        data,
    )
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR)
               
    ## create VBO ## 
    vertices = new Float32Array([
         1,  1,
        -1,  1,
        -1, -1,

         1,  1,
        -1, -1,
         1, -1,
    ])
    buffer = gl.createBuffer()
    gl.bindBuffer(gl.ARRAY_BUFFER, buffer)
    gl.bufferData(gl.ARRAY_BUFFER, vertices, gl.STATIC_DRAW)
    positionLoc = gl.getAttribLocation(program, 'position')
    sourceLoc = gl.getUniformLocation(program, 'source')
    gl.enableVertexAttribArray(positionLoc)
    gl.vertexAttribPointer(positionLoc, 2, gl.FLOAT, false, 0, 0)
    gl.uniform1i(sourceLoc, 0)
    gl.drawArrays(gl.TRIANGLES, 0, 6)
    
    readBuffer = new Uint8Array(4*4)
    gl.readPixels(0, 0, 2, 2, gl.RGBA, gl.UNSIGNED_BYTE, readBuffer)
    
    result = Math.abs(readBuffer[0] - 127) < 10

    ## cleanup ##
    gl.deleteShader(fragmentShader)
    gl.deleteShader(vertexShader)
    gl.deleteProgram(program)
    gl.deleteBuffer(buffer)
    gl.deleteTexture(source)
    gl.deleteTexture(target)
    gl.deleteFramebuffer(framebuffer)

    gl.bindBuffer(gl.ARRAY_BUFFER, null)
    gl.useProgram(null)
    gl.bindTexture(gl.TEXTURE_2D, null)
    gl.bindFramebuffer(gl.FRAMEBUFFER, null)

    return result

checkColorBuffer = (gl, targetType) ->
    target = gl.createTexture()
    gl.bindTexture(gl.TEXTURE_2D, target)
    gl.texImage2D(
        gl.TEXTURE_2D,
        0,
        gl.RGBA,
        2, 2,
        0,
        gl.RGBA,
        targetType,
        null,
    )
    
    framebuffer = gl.createFramebuffer()
    gl.bindFramebuffer(gl.FRAMEBUFFER, framebuffer)
    gl.framebufferTexture2D(
        gl.FRAMEBUFFER,
        gl.COLOR_ATTACHMENT0,
        gl.TEXTURE_2D,
        target,
        0
    )
    
    check = gl.checkFramebufferStatus(gl.FRAMEBUFFER)

    gl.deleteTexture(target)
    gl.deleteFramebuffer(framebuffer)
    gl.bindTexture(gl.TEXTURE_2D, null)
    gl.bindFramebuffer(gl.FRAMEBUFFER, null)

    if check == gl.FRAMEBUFFER_COMPLETE
        return true
    else
        return false

shimExtensions = []
shimLookup = {}

checkSupport = ->
    canvas = document.createElement('canvas')
    gl = null
    try
        gl = canvas.getContext('experimental-webgl')
        if(gl == null)
            gl = canvas.getContext('webgl')

    if gl?
        singleFloat = gl.getExtension('OES_texture_float')
        if singleFloat != null
            extobj = gl.getExtension('WEBGL_color_buffer_float')
            if extobj == null
                if checkColorBuffer(gl, gl.FLOAT)
                    shimExtensions.push 'WEBGL_color_buffer_float'
                    shimLookup.WEBGL_color_buffer_float = {
                        shim: true
                        RGBA32F_EXT: 0x8814
                        RGB32F_EXT: 0x8815
                        FRAMEBUFFER_ATTACHMENT_COMPONENT_TYPE_EXT: 0x8211
                        UNSIGNED_NORMALIZED_EXT: 0x8C17
                    }
            extobj = gl.getExtension('OES_texture_float_linear')
            if extobj == null
                if checkFloatLinear(gl, gl.FLOAT)
                    shimExtensions.push 'OES_texture_float_linear'
                    shimLookup.OES_texture_float_linear = {shim:true}

        
        halfFloat = gl.getExtension('OES_texture_half_float')
        if halfFloat != null
            extobj = gl.getExtension('EXT_color_buffer_half_float')
            if extobj == null
                if checkColorBuffer(gl, halfFloat.HALF_FLOAT_OES)
                    shimExtensions.push 'EXT_color_buffer_half_float'
                    shimLookup.EXT_color_buffer_half_float = {
                        shim: true
                        RGBA16F_EXT: 0x881A
                        RGB16F_EXT: 0x881B
                        FRAMEBUFFER_ATTACHMENT_COMPONENT_TYPE_EXT: 0x8211
                        UNSIGNED_NORMALIZED_EXT: 0x8C17
                    }
            extobj = gl.getExtension('OES_texture_half_float_linear')
            if extobj == null
                if checkFloatLinear(gl, halfFloat.HALF_FLOAT_OES)
                    shimExtensions.push 'OES_texture_half_float_linear'
                    shimLookup.OES_texture_half_float_linear = {shim:true}

if window.WebGLRenderingContext?
    checkSupport()

    getExtension = WebGLRenderingContext.prototype.getExtension
    WebGLRenderingContext.prototype.getExtension = (name) ->
        extobj = shimLookup[name]
        if extobj == undefined
            return getExtension.call @, name
        else
            return extobj
    
    getSupportedExtensions = WebGLRenderingContext.prototype.getSupportedExtensions
    WebGLRenderingContext.prototype.getSupportedExtensions = ->
        return shimExtensions.concat(getSupportedExtensions.call(@))
