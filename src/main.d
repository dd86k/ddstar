import std.stdio, std.getopt;
import core.stdc.stdio : puts, printf;
import core.stdc.stdlib : exit;
import vibe.vibe;
import vibe.stream.openssl : OPENSSL_VERSION;
import ddstar;
import core.ami;
import api.websock : handleWSv0;
import core.pages : MainPages;

private:

enum VERSION_STRING =
	"ddstar-"~PLATFORM~" "~APP_VERSION~" ("~BUILD_TYPE~"), API: "~API_VERSION~"\n"~
	"  Using "~__VENDOR__~" v%u at "~__TIMESTAMP__~" ("~C_RUNTIME~")\n"~
	"  vibe-core: "~vibeVersionString~"\n"~
	"  openssl: "~OPENSSL_VERSION~"\n"~
	"features:"~FEATURE_SIMD~
	"\n";

extern (C)
void showhelp() {
	puts(
	"ddstar, an Asterisk Web management platform\n"~
	"  Usage: ddstar [OPTIONS]\n\n"~
	"OPTIONS\n"~
	"	--port     HTTP listen port (default: 4272)"~
	"	--amiport  AMI connection port (default: 5038)"
	);
	exit(0);
}

extern (C)
void showversion() {
	printf(VERSION_STRING, __VERSION__);
	exit(0);
}

extern (C)
void showlicense() {
	puts( // limited to 80 characters to ease reading
	"Copyright (c) 2019 dd86k\n\n"~
	"Redistribution and use in source and binary forms, with or without\n"~
	"modification, are permitted provided that the following conditions are met:\n\n"~
	"1. Redistributions of source code must retain the above copyright notice, this\n"~
	"   list of conditions and the following disclaimer.\n"~
	"2. Redistributions in binary form must reproduce the above copyright notice,\n"~
	"   this list of conditions and the following disclaimer in the documentation\n"~
	"   and/or other materials provided with the distribution.\n"~
	"3. Neither the name of the copyright holder nor the names of its contributors\n"~
	"   may be used to endorse or promote products derived from this software\n"~
	"   without specific prior written permission.\n\n"~
	"THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS \"AS IS\" AND\n"~
	"ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED\n"~
	"WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE\n"~
	"DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE\n"~
	"FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL\n"~
	"DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR\n"~
	"SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER\n"~
	"CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,\n"~
	"OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE\n"~
	"OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE."
	);
	exit(0);
}

int main(string[] args) {
	//
	// CLI
	//

	// App
	//string settingsfile = null; /// settings file path
	ushort port = 4272; /// http listen port
	// AMI
	ushort amiport = 5038; /// ami connect port
	string amiadd = "localhost"; /// ami connection address
	string amiuser = void; /// ami username
	string amisecret = void; /// ami user secret
	try {
		args.getopt(
			// App settings
			//config.caseSensitive,
			//"settings", "Set the setting file path", &settingsfile,
			config.caseSensitive,
			"port", "HTTP listen port", &port,
			// AMI settings
			config.caseSensitive,
			"A|amiport", "AMI connection port (default: 5038)", &amiport,
			config.caseSensitive,
			"amiaddress", "AMI connection address (default: localhost)", &amiadd,
			config.caseSensitive,
			"user", "AMI user to connect with", &amiuser,
			config.caseSensitive,
			"secret", "AMI user secret", &amisecret,
			// Informal
			config.caseSensitive,
			"license", "Prints license screen and exit", &showlicense,
			config.caseSensitive,
			"version", "Prints version screen and exit", &showversion,
			config.caseSensitive,
			"h|help", "Prints help screen and exit", &showhelp,
		);
	} catch (GetOptException ex) {
		logError(ex.msg);
		return 1;
	}

	if (amiuser == null) {
		logError("AMI user unspecified, aborting");
		return 2;
	}

	//
	// Setting file
	//



	//
	// Initiation
	//

	if (ami_init(amiport, amiadd)) {
		logError("Could not connect to AMI, aborting");
		return 3;
	}
	if (ami_login(amiuser, amisecret)) {
		logError("Could not login into AMI, aborting");
		return 4;
	}
	ami_corestatus;

	//
	// Routing
	//

	URLRouter router = new URLRouter;
	router // Static pages
		.get("/", staticTemplate!"index.dt")
		.get("/status", staticTemplate!"status.dt")
	//	.get("/admin", staticTemplate!"admin.dt")
		.get("/help", staticTemplate!"help.dt")
	//	.get("/version", staticTemplate!"version.dt")
		.get("/license", staticTemplate!"license.dt")
		.registerWebInterface(new MainPages)
		.get("/*", serveStaticFiles("pub"))
		.get("/ws", handleWebSockets(&handleWSv0)) // api
		//.get("/wss", ) ?
	;

	HTTPServerSettings htsettings = new HTTPServerSettings;
	htsettings.port = port;
	htsettings.errorPageHandler = toDelegate(&showError);

	try {
		listenHTTP(htsettings, router);
	} catch (Exception e) {
		logError(e.msg);
		return 2;
	}

	return runApplication;
}

void showError(HTTPServerRequest req, HTTPServerResponse res,
	HTTPServerErrorInfo error) @safe {
	res.render!("error.dt", req, error);
}