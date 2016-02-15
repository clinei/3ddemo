string[] readLines(string path)
{
	import std.stdio : File;
	import std.algorithm : map;
	import std.conv : to;
	import std.array : array;
	return File(path, "r").byLine.map!(to!string).array;
}

void main()
{
	import std.stdio;
	import std.math;
	import std.random;

	import gfm.assimp;
	import gfm.math;
	import gfm.opengl;
	import gfm.sdl2;

	string windowTitle = "3DDemo";
	int width = 640;
	int height = 480;

	import std.typecons : scoped;

	import helper.framemonitor : FrameMonitor;
	auto fm = scoped!FrameMonitor;

	real ratio = width / cast(real)height;

	// Load dynamic libraries
	auto sdl2 = scoped!SDL2(null);
	auto gl = scoped!OpenGL(null);
	auto assimp = scoped!Assimp(null);

	// Initialize subsystems
	sdl2.subSystemInit(SDL_INIT_VIDEO);
	sdl2.subSystemInit(SDL_INIT_EVENTS);

	SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 3);
	SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 3);
	SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_CORE);

	// Create an OpenGL-enabled SDL window
	auto window = scoped!SDL2Window(sdl2,
	                                SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED,
	                                width, height,
	                                SDL_WINDOW_OPENGL);

	// Set window title.
	window.setTitle(windowTitle);

	// Reload OpenGL now that a context exists
	gl.reload();

	glEnable(GL_DEPTH_TEST);
	glDepthFunc(GL_LESS);

	glEnable(GL_CULL_FACE);
	glCullFace(GL_BACK);

	string[] vertSource = readLines("model.vs");
	if (vertSource) writeln("Vertex shader source read.");

	string[] fragSource = readLines("model.fs");
	if (fragSource) writeln("Fragment shader source read.");

	auto vertShader = new GLShader(gl, GL_VERTEX_SHADER);
	vertShader.load(vertSource);
	vertShader.compile();

	auto fragShader = new GLShader(gl, GL_FRAGMENT_SHADER);
	fragShader.load(fragSource);
	fragShader.compile();

	GLShader[] shaders = [vertShader, fragShader];

	auto program = scoped!GLProgram(gl, shaders);

	struct Vertex
	{
		vec3f position;
		vec3f normal;
	}

	// Read 3D mesh
	auto file = scoped!AssimpScene(assimp, "Rock.blend", aiProcess_Triangulate);
	auto scene = file.scene();
	auto mesh = scene.mMeshes[0];

	Vertex[] model;

	// Populate vertex array
	foreach (fidx; 0..mesh.mNumFaces)
	{
		auto face = mesh.mFaces[fidx];
		foreach (vidx; 0..face.mNumIndices)
		{
			auto idx = face.mIndices[vidx];
			auto vertex = mesh.mVertices[idx];
			auto normal = mesh.mNormals[idx];
			model ~= Vertex(vec3f(vertex.x, vertex.y, vertex.z), vec3f(normal.x, normal.y, normal.z));
		}
	}

	auto modelVBO = scoped!GLBuffer(gl, GL_ARRAY_BUFFER, GL_STATIC_DRAW);
	modelVBO.setData(model);
	auto modelVS = scoped!(VertexSpecification!Vertex)(program);

	auto vao = scoped!GLVAO(gl);
	real time = 0;

	// Prepare VAO
	{
		vao.bind();
		modelVBO.bind();
		modelVS.use();
		vao.unbind();
	}

	auto projectionMatrix = mat4f.perspective(PI / 3, ratio, 0.1, 99999.0);
	auto radius = 4.0;
	auto target = vec3f(0.0, 0.0, 0.0);
	auto eye = vec3f(0.0, 0.0, target.z + radius);
	auto up = vec3f(0.0, 1.0, 0.0);
	auto viewMatrix = mat4f.lookAt(eye, target, up);
	auto worldMatrix = mat4f.identity();

	auto scaleMatrix = mat4f.scaling(vec3f(1.0, 1.0, 1.0));
	auto rotationMatrix = mat4f.rotation(0.0, vec3f(0.0, 1.0, 0.0));
	auto translationMatrix = mat4f.translation(vec3f(0.0, 0.0, 0.0));

	// Rotation, in radians
	auto rotation = vec3f(0.0, 0.0, 0.0);
	auto addRotation = vec3f(0.0, 0.0, 0.0);
	auto finalRotation = vec3f(0.0, 0.0, 0.0);

	auto mvpMatrix = projectionMatrix * viewMatrix * worldMatrix;

	auto lightDir = vec3f(-0.8, 0.0, -1.0).normalized();

	uint lastTime = SDL_GetTicks();

	bool mHeld = false;
	bool mPrevHeld = false;
	int pGrabStartX, pGrabStartY, pGrabEndX, pGrabEndY;

	SDL_Event quitEvent;
	quitEvent.type = SDL_QUIT;

	while (!sdl2.wasQuitRequested)
	{
		fm.begin();

		sdl2.processEvents();

		if (sdl2.keyboard.isPressed(SDLK_ESCAPE))
		{
			SDL_PushEvent(&quitEvent);
		}

		if (sdl2.mouse.isButtonPressed(SDL_BUTTON_LMASK))
		{
			mHeld = true;
		}
		else if (mHeld)
		{
			rotation += addRotation;
			addRotation = vec3f(0.0, 0.0, 0.0);
			mHeld = false;
		}
		if (mHeld)
		{
			if (!mPrevHeld) {
				pGrabStartX = sdl2.mouse.x;
				pGrabStartY = sdl2.mouse.y;
			}
			pGrabEndX = sdl2.mouse.x;
			pGrabEndY = sdl2.mouse.y;

			float mDeltaX = pGrabEndX - pGrabStartX;
			float mDeltaY = pGrabEndY - pGrabStartY;
			addRotation.y = mDeltaX / width * PI;
			addRotation.x = mDeltaY / height * PI;
		}

		uint now = SDL_GetTicks();
		real delta = now - lastTime;
		lastTime = now;
		time += 0.05 * delta;

		finalRotation = rotation + addRotation;

		// Convert XYZ rotation to matrix
		rotationMatrix = mat4f.rotation(finalRotation.x, vec3f(1.0, 0.0, 0.0)) *
		                 mat4f.rotation(finalRotation.y, vec3f(0.0, 1.0, 0.0)) *
		                 mat4f.rotation(finalRotation.z, vec3f(0.0, 0.0, 1.0));

		auto wheelDelta = sdl2.mouse.wheelDeltaY();
		if (wheelDelta != 0)
		{
			eye.z -= wheelDelta / cast(real)4;
		}
		viewMatrix = mat4f.lookAt(eye, target, up);
		viewMatrix *= rotationMatrix;

		// clear the whole window
		glViewport(0, 0, width, height);
		glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

		// uniform variables must be set before program use
		program.uniform("time").set(cast(float)time);
		program.uniform("lightDir").set(lightDir);
		program.uniform("worldMatrix").set(worldMatrix);
		program.uniform("viewMatrix").set(viewMatrix);
		program.uniform("projectionMatrix").set(projectionMatrix);
		program.use();

		vao.bind();
		glDrawArrays(GL_TRIANGLES, 0, cast(int)(modelVBO.size() / modelVS.vertexSize()));
		vao.unbind();
		program.unuse();

		window.swapBuffers();

		mPrevHeld = mHeld;

		fm.end();
	}
}
