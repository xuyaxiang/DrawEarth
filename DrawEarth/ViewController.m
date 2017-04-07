//
//  ViewController.m
//  DrawEarth
//
//  Created by enghou on 17/4/4.
//  Copyright © 2017年 xyxorigation. All rights reserved.
//

#import "ViewController.h"
#import "sphere.h"
typedef struct {
    GLKVector3 position;
    GLKVector3 normal;
    GLKVector2 texCoords;
}SceneVertex;
@interface ViewController ()
@property(nonatomic,assign)GLuint program;
@property(nonatomic,assign)GLint modelMat;
@property(nonatomic,assign)GLint viewMat;
@property(nonatomic,assign)GLint projectionMat;
@property(nonatomic,assign)GLint tex;
@end

@implementation ViewController
{
    GLKMatrix4 modelMatrix;
    GLKMatrix4 viewMatrix;
    GLKMatrix4 projectionMatrix;
    GLuint tx[2];
    GLKMatrix4 moonMatrix;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    //初始化绘图上下文
    GLKView *view = (GLKView *)self.view;
    view.context = [[EAGLContext alloc]initWithAPI:kEAGLRenderingAPIOpenGLES2];
    [EAGLContext setCurrentContext:view.context];
    SceneVertex vertex[3888];
    view.drawableDepthFormat = GLKViewDrawableDepthFormat16;
    //初始化绘图上下文
    for (int i=0; i<1944; i++) {
        vertex[i].position.x = sphereVerts[3*i];
        vertex[i].position.y = sphereVerts[3*i+1];
        vertex[i].position.z = sphereVerts[3*i+2];
        vertex[i].normal.x = sphereNormals[3*i];
        vertex[i].normal.y = sphereNormals[3*i+1];
        vertex[i].normal.z = sphereNormals[3*i+2];
        vertex[i].texCoords.s = sphereTexCoords[2*i];
        vertex[i].texCoords.t = sphereTexCoords[2*i+1];
    }
    
    for (int i=0; i<1944; i++) {
        vertex[i+1944].position.x = sphereVerts[3*i]+0.2;
        vertex[i+1944].position.y = sphereVerts[3*i+1];
        vertex[i+1944].position.z = sphereVerts[3*i+2];
        vertex[i+1944].normal.x = sphereNormals[3*i];
        vertex[i+1944].normal.y = sphereNormals[3*i+1];
        vertex[i+1944].normal.z = sphereNormals[3*i+2];
        vertex[i+1944].texCoords.s = sphereTexCoords[2*i];
        vertex[i+1944].texCoords.t = sphereTexCoords[2*i+1];
    }
    glEnable(GL_DEPTH_TEST);
    GLuint name;
    glGenBuffers(1, &name);
    glBindBuffer(GL_ARRAY_BUFFER, name);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertex), vertex, GL_STATIC_DRAW);
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(SceneVertex), NULL);
    glEnableVertexAttribArray(GLKVertexAttribNormal);
    glVertexAttribPointer(GLKVertexAttribNormal, 3, GL_FLOAT, GL_FALSE, sizeof(SceneVertex), NULL+offsetof(SceneVertex, normal));
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, sizeof(SceneVertex), NULL+offsetof(SceneVertex, texCoords));
    
    
    glGenTextures(2, tx);
    glBindTexture(GL_TEXTURE_2D, tx[0]);
    
    UIImage *image = [UIImage imageNamed:@"Earth512x256.jpg"];
    NSMutableData *data  = [NSMutableData dataWithLength:512*256*4];
    CGColorSpaceRef color = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate([data mutableBytes], 512, 256, 8, 4*512, color, kCGImageAlphaPremultipliedLast);
    CGColorSpaceRelease(color);
    CGContextTranslateCTM(context, 0, 256);
    CGContextScaleCTM(context, 1, -1);
    CGContextDrawImage(context, CGRectMake(0, 0, 512, 256), image.CGImage);
    UIGraphicsEndImageContext();
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, 512, 256, 0, GL_RGBA, GL_UNSIGNED_BYTE, [data bytes]);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    ////上面是0
    NSMutableData *data1 = [NSMutableData dataWithLength:512*256*4];
    {
        UIImage *image = [UIImage imageNamed:@"sun.bmp"];
        CGColorSpaceRef color = CGColorSpaceCreateDeviceRGB();
        CGContextRef context = CGBitmapContextCreate([data1 mutableBytes], 512, 256, 8, 4*512, color, kCGImageAlphaPremultipliedLast);
        CGColorSpaceRelease(color);
        CGContextTranslateCTM(context, 0, 256);
        CGContextScaleCTM(context, 1, -1);
        CGContextDrawImage(context, CGRectMake(0, 0, 512, 256), image.CGImage);
        UIGraphicsEndImageContext();
    }
    
    glBindTexture(GL_TEXTURE_2D, tx[1]);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, 512, 256, 0, GL_RGBA, GL_UNSIGNED_BYTE, [data1 bytes]);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glBindTexture(GL_TEXTURE_2D, 0);
    glUniform1i(_tex, 0);
    glClearColor(0, 0, 0, 1);
    [self loadShaders];
    modelMatrix = GLKMatrix4Identity;
    viewMatrix = GLKMatrix4Identity;
    projectionMatrix = GLKMatrix4Identity;
    moonMatrix = GLKMatrix4Identity;
    viewMatrix = GLKMatrix4MakeLookAt(0, 0, 10, 0, 0, 0, 0, 1, 0);
    projectionMatrix = GLKMatrix4MakeFrustum(-1, 1, -1, 1, 8, 1000);
    //glBindFramebuffer(GL_DRAW_FRAMEBUFFER, <#GLuint framebuffer#>)
    //glGenFramebuffers(<#GLsizei n#>, <#GLuint *framebuffers#>)
}

-(void)glkView:(GLKView *)view drawInRect:(CGRect)rect{
    static float i = 0;
    float aspect = (GLfloat)view.drawableWidth / (GLfloat)view.drawableHeight;
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glBindTexture(GL_TEXTURE_2D, tx[0]);
    glUseProgram(_program);
    modelMatrix = GLKMatrix4MakeScale(1, aspect, 1);
    modelMatrix = GLKMatrix4Rotate(modelMatrix, GLKMathDegreesToRadians(i), 0, 1, 0);
    glUniformMatrix4fv(_modelMat, 1, 0, modelMatrix.m);
    glUniformMatrix4fv(_viewMat, 1, 0, viewMatrix.m);
    glUniformMatrix4fv(_projectionMat, 1, 0, projectionMatrix.m);
    glDrawArrays(GL_TRIANGLES, 0, 1944);
    
    glBindTexture(GL_TEXTURE_2D, tx[1]);
    modelMatrix = GLKMatrix4MakeScale(0.2, 0.2*aspect, 0.2);
    modelMatrix = GLKMatrix4Rotate(modelMatrix, GLKMathDegreesToRadians(++i), 0, 1, 0);
    modelMatrix = GLKMatrix4Translate(modelMatrix, 5, 0, 0);
    glUniformMatrix4fv(_modelMat, 1, 0, modelMatrix.m);
    glUniformMatrix4fv(_viewMat, 1, 0, viewMatrix.m);
    glUniformMatrix4fv(_projectionMat, 1, 0, projectionMatrix.m);
    glDrawArrays(GL_TRIANGLES, 1944, 1944);
}
- (IBAction)changeEyePosition:(id)sender {
    static float i = 0.1;
    viewMatrix = GLKMatrix4MakeLookAt(0, 0, 10-i, 0, 0, 0, 0, 1, 0);
    i+=0.1;
}

- (IBAction)changeDistance:(id)sender {
    static float i = 0.1;
    moonMatrix = GLKMatrix4MakeScale(1, 0.566, 1);
    moonMatrix = GLKMatrix4Translate(moonMatrix, 0, 0, -i);
    i+=0.1;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)loadShaders
{
    GLuint vertShader, fragShader;
    NSString *vertShaderPathname, *fragShaderPathname;
    
    // Create shader program.
    _program = glCreateProgram();
    
    // Create and compile vertex shader.
    vertShaderPathname = [[NSBundle mainBundle] pathForResource:@"Shader" ofType:@"vsh"];
    if (![self compileShader:&vertShader type:GL_VERTEX_SHADER file:vertShaderPathname]) {
        NSLog(@"Failed to compile vertex shader");
        return NO;
    }
    
    // Create and compile fragment shader.
    fragShaderPathname = [[NSBundle mainBundle] pathForResource:@"Shader" ofType:@"fsh"];
    if (![self compileShader:&fragShader type:GL_FRAGMENT_SHADER file:fragShaderPathname]) {
        NSLog(@"Failed to compile fragment shader");
        return NO;
    }
    
    // Attach vertex shader to program.
    glAttachShader(_program, vertShader);
    
    // Attach fragment shader to program.
    glAttachShader(_program, fragShader);
    
    // Bind attribute locations.
    // This needs to be done prior to linking.
    glBindAttribLocation(_program, GLKVertexAttribPosition, "position");
    glBindAttribLocation(_program, GLKVertexAttribNormal, "normal");
    glBindAttribLocation(_program, GLKVertexAttribTexCoord0, "TextureCoords");
    // Link program.
    if (![self linkProgram:_program]) {
        NSLog(@"Failed to link program: %d", _program);
        
        if (vertShader) {
            glDeleteShader(vertShader);
            vertShader = 0;
        }
        if (fragShader) {
            glDeleteShader(fragShader);
            fragShader = 0;
        }
        if (_program) {
            glDeleteProgram(_program);
            _program = 0;
        }
        
        return NO;
    }
    //modelMatrix = glGetUniformLocation(_program, "modelMatrix");
    _modelMat = glGetUniformLocation(_program, "modelMatrix");
    _viewMat = glGetUniformLocation(_program, "viewMatrix");
    _projectionMat = glGetUniformLocation(_program, "projectionMatrix");
    // Release vertex and fragment shaders.
    if (vertShader) {
        glDetachShader(_program, vertShader);
        glDeleteShader(vertShader);
    }
    
    if (fragShader) {
        glDetachShader(_program, fragShader);
        glDeleteShader(fragShader);
    }
    
    return YES;
}

- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file
{
    GLint status;
    const GLchar *source;
    
    source = (GLchar *)[[NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil] UTF8String];
    if (!source) {
        NSLog(@"Failed to load vertex shader");
        return NO;
    }
    
    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &source, NULL);
    glCompileShader(*shader);
    
#if defined(DEBUG)
    GLint logLength;
    glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetShaderInfoLog(*shader, logLength, &logLength, log);
        NSLog(@"Shader compile log:\n%s", log);
        free(log);
    }
#endif
    
    glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
    if (status == 0) {
        glDeleteShader(*shader);
        return NO;
    }
    
    return YES;
}

- (BOOL)linkProgram:(GLuint)prog
{
    GLint status;
    glLinkProgram(prog);
    
#if defined(DEBUG)
    GLint logLength;
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program link log:\n%s", log);
        free(log);
    }
#endif
    
    glGetProgramiv(prog, GL_LINK_STATUS, &status);
    if (status == 0) {
        return NO;
    }
    
    return YES;
}

- (BOOL)validateProgram:(GLuint)prog
{
    GLint logLength, status;
    
    glValidateProgram(prog);
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program validate log:\n%s", log);
        free(log);
    }
    
    glGetProgramiv(prog, GL_VALIDATE_STATUS, &status);
    if (status == 0) {
        return NO;
    }
    
    return YES;
}
@end
