module helper.framemonitor;

class FrameMonitor
{
	import std.datetime.stopwatch : StopWatch;
	import core.time : Duration;

	StopWatch _sw;
	ulong _fpsTarget;
	real _fps;
	bool _capped;

	/// The Duration it tries to adhere to when _capped is true.
	Duration _frameTarget;

	/// Duration of the current frame.
	Duration _delta;

	/// Difference between _frameTarget and _delta.
	Duration _sleep;

	auto fps()
	{
		return _fps;
	}

	auto fpsTarget()
	{
		return _fpsTarget;
	}

	this(bool capped = true, ulong fpsTarget = 30)
	{
		_capped = capped;
		_fpsTarget = fpsTarget;
		import core.time : seconds;
		_frameTarget = 1.seconds / _fpsTarget;
	}

	void begin()
	{
		_sw.reset();
		_sw.start();
	}

	void end()
	{
		import core.thread : Thread;

		updateDelta();
		updateFps();
		updateSleep();

		if (_capped)
		{
			if (_sleep > Duration.zero)
			{
				Thread.sleep(_sleep);
			}
			updateDelta();
			updateFps();
		}
	}

private:
	void updateDelta()
	{
		import std.conv : to;
		_delta = to!Duration(_sw.peek());
	}
	/// Be sure to call updateDelta() first.
	void updateFps()
	{
		import core.time : seconds;
		_fps = cast(real)1.seconds.total!"hnsecs" / cast(real)_delta.total!"hnsecs";
	}

	void updateSleep()
	{
		_sleep = _frameTarget - _delta;
	}
}