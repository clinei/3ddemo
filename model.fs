#version 330 core

uniform float time;
uniform vec3 lightDir;
in vec3 vertexNormal;
out vec3 color;

void main() {
	float h = mod(time, 360);
	float s = 0.8;
	float v = 0.8;
	
	float hh = h / 60;
	int i = int(hh);
	float c = v * s;
	float x = c * (1 - abs( mod( hh, 2 ) - 1 ) );
	float m = v - c;
	
	float r = 0.0;
	float g = 0.0;
	float b = 0.0;
	
	switch(i) {
	case 0:
		r = c;
		g = x;
		b = 0;
		break;
	case 1:
		r = x;
		g = c;
		b = 0;
		break;
	case 2:
		r = 0;
		g = c;
		b = x;
		break;
	case 3:
		r = 0;
		g = x;
		b = c;
		break;
	case 4:
		r = x;
		g = 0;
		b = c;
		break;
	case 5:
		r = c;
		g = 0;
		b = x;
		break;
	default:
		break;
	}
	vec3 diffuseColor = vec3(r, g, b);
	
	// Diffuse lighting
	float intensity = clamp(dot(normalize(vertexNormal), -lightDir), 0.0f, 1.0f);
	
	color = clamp((diffuseColor * intensity), 0.0f, 1.0f);
	//color = clamp(vertexNormal, 0.0f, 1.0f);
	//color = diffuseColor;
}
