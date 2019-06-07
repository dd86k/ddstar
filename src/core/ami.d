/**
 * Asterisk Management Interface (AMI) module that handles sending actions and
 * receiving responses and events, including sending translated responses to
 * a live WebSocket.
 *
 */
module core.ami;

import std.format;
import std.socket;
import std.string : indexOf;
import std.array : split;
import std.algorithm.iteration : splitter;
import vibe.vibe;

/// Newline string, default being ala HTTP (\r\n)
enum NL = "\r\n";

/// AMI useragent string and version
__gshared string userAgent = void;

/**
 * Connect to AMI using a port and optional address. If no address is provided,
 * it will attempt to connect to localhost (either via IPv4 (127.0.0.1) or IPv6
 * (::1)). Default port from make samples is 5038, which is not taken by
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
	
	ubyte [256]b = void;
	amisock.send(format(
		"Action: Login"~NL~
		"Username: %s"~NL~
		"Secret: %s"~NL~
		NL,
		user, secret
	));
	size_t l = amisock.receive(b);

	// user agent

	userAgent = (cast(char[])b[0..l]).strip.dup;
	logInfo("[AMI_LOGIN] %s", userAgent);

	// login confirmation

	AMIMessage m = void;
	l = amisock.receive(b);
	string s = cast(string)b[0..l];
	ami_msgtype(s, m);
	if (m.sub != "Success")
		return 1;

	runWorkerTask(&ami_idle);
	return 0;
}

void ami_corestatus() {
	amisock.send("Action: CoreStatus"~NL~NL);
}
void ami_coresettings() {
	amisock.send("Action: CoreSettings"~NL~NL);
}

private:

struct AMIMessage {
	string type; /// message type: "Event", "Response"
	string sub; /// sub response
}

__gshared TcpSocket amisock = void;

/// Event/Response loop handler
/// Also sends data through websocket
void ami_idle() {
	size_t l = void;
	ubyte [1024] b = void;
	AMIMessage m = void;

AMI_START:
	l = amisock.receive(b);
	string s = cast(string)b[0..l];

	debug if (l)
		logInfo("[AMI_DEBUG] %s", s);

	string[string] r = ami_msgtype(s, m);

	switch (m.type) {
	case "Response":
	
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

string[string] ami_msgtype(ref string s, ref AMIMessage m) {
	string[] su = s.split("\r\n");

	size_t sl = su.length; /// array length
	if (sl == 0)
		return null;

	string[] ss = su[0].split(": ");
	size_t ssl = ss.length; /// sub array length
	if (ssl < 2)
		return null;

	m.type = ss[0];
	m.sub = ss[1];

	string[string] r;
	foreach (l; su[1..$]) {
		ss = l.split(": ");
		ssl = ss.length;

		if (ssl >= 2)
			r[ss[0]] = ss[1];
	}

	return r;
}

void ami_event(ref string s) { // get event
	
}

void ami_response(ref string s) { // get event
	
}