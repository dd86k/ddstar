module core.pages;

import vibe.vibe;

/// Conveniant dynamic page interface
class MainPages {
	@path("/version")
	void getVersion() @trusted {
		import utils.cpuid : getCPUVendor, getCPUModel;
		import core.ami : userAgent;

		const string cpu_vendor = getCPUVendor;
		const string cpu_model = getCPUModel;
		const string agent = userAgent;

		render!("version.dt",
			cpu_vendor, cpu_model, agent);
	}
}