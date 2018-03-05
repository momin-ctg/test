precision mediump float;

attribute vec3 vertex;

uniform vec4 control;

uniform mat4 matrixCameraMVP;
uniform sampler2D texture;

varying vec3 vColor;

vec3 mod289(vec3 x) {
    return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec2 mod289(vec2 x) {
    return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec3 permute(vec3 x) {
    return mod289(((x*34.0)+1.0)*x);
}

float snoise(vec2 v) {
    const vec4 C = vec4(0.211324865405187, 0.366025403784439, -0.577350269189626, 0.024390243902439);
    vec2 i  = floor(v + dot(v, C.yy) );
    vec2 x0 = v -   i + dot(i, C.xx);

    vec2 i1;
    i1 = (x0.x > x0.y) ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
    vec4 x12 = x0.xyxy + C.xxzz;
    x12.xy -= i1;

    i = mod289(i);
    vec3 p = permute( permute( i.y + vec3(0.0, i1.y, 1.0 ))
    + i.x + vec3(0.0, i1.x, 1.0 ));

    vec3 m = max(0.5 - vec3(dot(x0,x0), dot(x12.xy,x12.xy), dot(x12.zw,x12.zw)), 0.0);
    m = m*m ;
    m = m*m ;

    vec3 x = 2.0 * fract(p * C.www) - 1.0;
    vec3 h = abs(x) - 0.5;
    vec3 ox = floor(x + 0.5);
    vec3 a0 = x - ox;

    m *= 1.79284291400159 - 0.85373472095314 * ( a0*a0 + h*h );

    vec3 g;
    g.x  = a0.x  * x0.x  + h.x  * x0.y;
    g.yz = a0.yz * x12.xz + h.yz * x12.yw;

    return  dot(m, g);
}

vec3 cycler(float c){
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(vec3(c) + K.xyz) * 6.0 - K.www);
    return clamp(p - K.xxx, 0.0, 1.0);
}

void main(){
	vec2 uv = vec2( ( vertex.x + 128.0 + control.w + control.x ) / 1024.0, ( vertex.y + 128.0 ) / 256.0 );
	vec2 map = texture2D( texture, uv ).rg;

	vec3 image = vec3(vertex.x, vertex.y, ((1.0-map.y) * -256.0) + 128.0);
	float axisY = uv.y * 0.25;
	float pushBack = abs(clamp(0.0, 1.0, 0.5 + (control.x / 1.75)));
	float textureshift =  map.y * 1.0 ;
	float cmax = control.z + textureshift + axisY;

	float sinA = sin((control.z + uv.y)*2.0*pushBack);
	float sinB = sin((control.z + uv.y + snoise(uv) * 2.0 + snoise(uv*sin(control.z * 5.0 * pushBack)) * 240.0 * pushBack * control.y) * 20.0 * pushBack + pow( map.y, 4.0) * 6.0);
	float bleed = pow(map.x, 4.0)*2.0;
	float clampA = smoothstep(-0.25 - bleed, 0.25 + bleed, sinB);

	cmax += sinA;
	image.x += clampA * sinB * 1.0;

	image.xy *= mix(1.0, pushBack, control.y) + (1.0- control.y) + control.z * 0.5;
	image.y += (1.0 - pushBack) * 120.0;
	vec3 color = cycler( cmax * 2.0 ) * clamp( map.y * 12.0, 0.0, 1.0 );

	vColor = vec3(map.r * 1.2) * control.y;
	vColor = mix(vColor, color, clampA );

	vColor = clamp(vColor, 0.0, 1.0) * map.x;

    vec4 position = vec4(image, 1.0);
	gl_Position = matrixCameraMVP * position;
}