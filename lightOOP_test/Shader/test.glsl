﻿#version 450 core


#pragma region Structs
struct Material {
	sampler2D diffuse;
	sampler2D specular;
	float     shininess;
};

struct DirLight {
	vec3 direction;

	vec3 ambient;
	vec3 diffuse;
	vec3 specular;
};
struct PointLight {
	vec3 position;

		float constant;
		float linear;
	float quadratic;

	vec3 ambient;
	vec3 diffuse;
	vec3 specular;
};

#pragma endregion

#pragma region FunctionPrototypes
vec3 CalcDirLight(DirLight light, vec3 normal, vec3 viewDir);
vec3 CalcPointLight(PointLight light, vec3 normal, vec3 fragPos, vec3 viewDir);
#pragma endregion

//in
in vec3 FragPos;
in vec3 Normal;
in vec2 TexCoords;
//out
out vec4 color;

//uniforms
uniform vec3 viewPos;
uniform Material material;

uniform DirLight dirLight;

#define NR_POINT_LIGHTS 4  
uniform PointLight pointLights[NR_POINT_LIGHTS];

void main()
{
	// Properties
	vec3 norm = normalize(Normal);
	vec3 viewDir = normalize(viewPos - FragPos);

	// Phase 1: Directional lighting
	vec3 result = CalcDirLight(dirLight, norm, viewDir);
	// Phase 2: Point lights
	for (int i = 0; i < NR_POINT_LIGHTS; i++)
		result += CalcPointLight(pointLights[i], norm, FragPos, viewDir);
	// Phase 3: Spot light
	//result += CalcSpotLight(spotLight, norm, FragPos, viewDir);    

	color = vec4(result, 1.0);
}

vec3 CalcDirLight(DirLight light, vec3 normal, vec3 viewDir)
{
	vec3 lightDir = normalize(-light.direction);
	// Diffuse shading
	float diff = max(dot(normal, lightDir), 0.0);
	// Specular shading
	vec3 reflectDir = reflect(-lightDir, normal);
	float spec = pow(max(dot(viewDir, reflectDir), 0.0), material.shininess);
	// Combine results
	vec3 ambient = light.ambient  * vec3(texture(material.diffuse, TexCoords));
	vec3 diffuse = light.diffuse  * diff * vec3(texture(material.diffuse, TexCoords));
	vec3 specular = light.specular * spec * vec3(texture(material.specular, TexCoords));
	return (ambient + diffuse + specular);
}
vec3 CalcPointLight(PointLight light, vec3 normal, vec3 fragPos, vec3 viewDir)
{
	vec3 lightDir = normalize(light.position - fragPos);
	// Diffuse shading
	float diff = max(dot(normal, lightDir), 0.0);
	// Specular shading
	vec3 reflectDir = reflect(-lightDir, normal);
	float spec = pow(max(dot(viewDir, reflectDir), 0.0), material.shininess);
	// Attenuation
	float distance = length(light.position - fragPos);
	float attenuation = 1.0f / (light.constant + light.linear * distance +
		light.quadratic * (distance * distance));
	// Combine results
	vec3 ambient = light.ambient  * vec3(texture(material.diffuse, TexCoords));
	vec3 diffuse = light.diffuse  * diff * vec3(texture(material.diffuse, TexCoords));
	vec3 specular = light.specular * spec * vec3(texture(material.specular, TexCoords));
	ambient *= attenuation;
	diffuse *= attenuation;
	specular *= attenuation;
	return (ambient + diffuse + specular);
}