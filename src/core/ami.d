/**
 * Asterisk Management Interface (AMI) module that handles sending actions and
 * receiving responses and events, including sending translated responses to
 * a live WebSocket.
 *
 */
module core.ami;

import std.format;
import std.socket;
import std.string : indexOf, lineSplitter;
import std.array : split;
import std.algorithm.iteration : splitter;
import std.algorithm.searching;
import vibe.vibe;

/// Newline string, default being ala HTTP (\r\n)
enum NL = "\r\n";

/// Asterisk fields
struct AstFields_t {
	string asterisk_version;
	string agent;
	string ami_version;
	int current_calls;
}

/// AMI fields
__gshared AstFields_t AMIInfo = void;;

/**
 * Connect to AMI using a port and optional address. If no address is provided,
 * it will attempt to connect to localhost (either via IPv4 (127.0.0.1) or IPv6
 * (::1)). While default port from "make samples" is 5038, it is not taken by
 * default.
 * Params:
 *   port = AMI port
 *   address = AMI address
 * Returns: Non-zero on error
 */
int ami_init(ushort port, string address) {
	Address[] addresses = void;

	try {
		addresses = getAddress(address, port);
	} catch (Exception e) {
		return 1;
	}

	amisock = new TcpSocket();
	foreach (a; addresses) { // retry until successful
		try {
			amisock.connect(a);
			break;
		} catch (Exception e) {}
	}

	if (amisock.isAlive == false) { // "just in case"
		return 3;
	}

	AMIInfo.ami_version = "unknown";

	return 0;
}

//
// API
//

/**
 * Login into AMI using a user and secret defined in manager.conf. `ami_init`
 * MUST be called BEFORE calling this function. This function sets the event
 * and response loop.
 * Params:
 *   user = Username
 *   secret = Password
 * Returns: Non-zero on error
 */
int ami_login(string user, string secret) {
	import std.string : strip;

	enum fmt =
		"Action: Login"~NL~
		"Username: %s"~NL~
		"Secret: %s"~NL~NL;

	char [128]a = void;

	amisock.send(a.sformat!fmt(user, secret));
	size_t l = amisock.receive(a);

	// user agent

	AMIInfo.agent = (cast(string)a[0..l]).strip.dup;
	logInfo("[AMI_AGENT] %s", AMIInfo.agent);

	// login confirmation

	AMIMessage m = void;
	l = amisock.receive(a);
	string s = cast(string)a[0..l];
	ami_msgtype(s, m);
	if (m.sub != "Success")
		return 1;

	runWorkerTask(&ami_idle);
	return 0;
}

void ami_corestatus() {
	ami_last = LastAction.CoreStatus;
	amisock.send("Action: CoreStatus"~NL~NL);
}
void ami_coresettings() {
	ami_last = LastAction.CoreSettings;
	amisock.send("Action: CoreSettings"~NL~NL);
}

private:

enum LastAction {
	Undefined,
	CoreStatus,
	CoreSettings,
}

struct AMIMessage {
	string type; /// message type: "Event", "Response"
	string sub; /// sub response
}

__gshared TcpSocket amisock = void;
__gshared LastAction ami_last = void;
__gshared string unknown = "unknown"; /// Set when key is not defined

/// Event/Response loop handler
/// Also sends data through websocket
void ami_idle() {
	size_t l = void;
	ubyte [1024]b = void;
	AMIMessage m = void;

AMI_START:
	l = amisock.receive(b);
	string s = cast(string)b[0..l];

	debug if (l)
		logInfo("[AMI_DEBUG] %s", s);

	string[string] r = ami_msgtype(s, m);

	switch (m.type) {
	case "Response:":
		switch (ami_last) {
		case LastAction.CoreSettings:
			AMIInfo.asterisk_version = getval(r, "AsteriskVersion");
			AMIInfo.ami_version = getval(r, "AMIversion");
			break;
		case LastAction.CoreStatus:
		
			break;
		default:
		}
		break;
	case "Event":
		switch (m.sub) {
		case "Reload":
		
			break;
		default:
		}
		break;
	default:
	}

	goto AMI_START;
}

string getval(ref string[string] r, string key) {
	// while DMD works without .idup, other compilers like ldc needs it
	return key in r ? r[key].idup : unknown;
}

string[string] ami_msgtype(ref string instr, ref AMIMessage msg) {
	string[string] r;
	bool f = false; /// first line done

	const lines = instr.lineSplitter; // LineSplitter!(cast(Flag)false, string)
	foreach (line; lines) {
		const m = line.findSplit(": ");
		if (f) {
			r[m[0]] = m[2];
		} else {
			msg.type = m[0];
			msg.sub = m[2];
			f = true;
		}
	}

	return r;
}