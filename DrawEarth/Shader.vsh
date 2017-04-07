attribute vec3 position;
attribute vec3 normal;
attribute vec2 TextureCoords;
uniform lowp mat4 modelMatrix;
uniform lowp mat4 viewMatrix;
uniform lowp mat4 projectionMatrix;
varying lowp vec4 colorVarying;
varying vec2 TextureCoordsOut;

void main()
{
    TextureCoordsOut = TextureCoords;
    vec4 vNormal = normalize(projectionMatrix*viewMatrix*modelMatrix*vec4(normal,1));
    vec3 norml = vec3(vNormal.x,vNormal.y,vNormal.z);
    vec4 lightColor = vec4(1,1,1,1);
    vec3 lightDirection = normalize(vec3(1,1,0));
    float co = dot(norml,lightDirection);
    colorVarying = co * lightColor;
    gl_Position = projectionMatrix*viewMatrix*modelMatrix*vec4(position,1);
}
