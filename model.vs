#version 330 core

uniform mat4 mvpMatrix;
uniform mat4 worldMatrix;
uniform mat4 viewMatrix;
uniform mat4 projectionMatrix;

in vec3 position;
in vec3 normal;
out vec3 vertexNormal;

void main() {
	gl_Position = worldMatrix * vec4(position, 1.0f);
	gl_Position = viewMatrix * gl_Position;
	gl_Position = projectionMatrix * gl_Position;
	
	vertexNormal = mat3(worldMatrix) * normal;
	vertexNormal = normalize(vertexNormal);
	//gl_Position = mvpMatrix * vec4(position, 1.0);
	//gl_Position.w = 1.0;
}
