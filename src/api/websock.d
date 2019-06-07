/**
 * JSON/WebSocket API
 */
module api.websock;

import vibe.vibe;

/**
 * Handles a WebSocket connection message loop. API v0
 * Params: sock = WebSocket connection
 */
void handleWSv0(scope WebSocket sock) {
WS_START: // Shameless
	if (sock.waitForData == false) return;

	string req = sock.receiveText(false);
	Json jreq = parseJsonString(req);
	Json jres = Json.emptyObject;
	string res = null; /// response

	switch (jreq["req"].to!string) {
	case "sysusage": // current (past/refresh 1s)
	
		break;
	case "sysinfo": // total + etc.
	
		break;
	default:
		res = `{"res":"error","code":1,"msg":"Invalid request type"}`;
	}

WS_SEND:
	sock.send(res);
	goto WS_START;
}