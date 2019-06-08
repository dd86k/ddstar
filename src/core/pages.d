module core.pages;

import vibe.vibe;

/// Conveniant dynamic page interface
class MainPages {
	@path("/version")
	void getVersion() @trusted {
		import utils.cpuid : getCPUVendor, getCPUModel;
		import core.ami : AMIInfo;
		import ddstar : APP_VERSION, API_VERSION, C_RUNTIME;
		import vibe.stream.openssl : OPENSSL_VERSION;

		const string cpu_vendor = getCPUVendor;
		const string cpu_model = getCPUModel;
		const string agent = AMIInfo.agent;
		const string amiver = AMIInfo.ami_version;
		const string asteriskver = AMIInfo.asterisk_version;
		const string app_version = APP_VERSION;
		const string api_version = API_VERSION;
		const string vibe_ver = vibeVersionString;
		const string openssl_ver = OPENSSL_VERSION;

		render!("version.dt",
			cpu_vendor, cpu_model,
			agent, asteriskver,
			amiver,
			app_version, api_version, vibe_ver, openssl_ver);
	}
}