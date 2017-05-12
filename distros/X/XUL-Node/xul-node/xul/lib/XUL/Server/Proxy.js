
JSAN.package('XUL.Server');
JSAN.use("XUL.Server.Response");

new Class("XUL.Server.Proxy", {

initialize : function () {
	this.xml             = new DOMParser();
	this.requestCount    = 0;
	this.applicationName = location.search.substr(1) || false;
	this.requestPrefix   = "xul";
	this.sessionId       = null;
	this.xmlHTTP         = new XMLHttpRequest;
},

boot :  function (applicationName) {
	this.applicationName = applicationName || this.applicationName;
	var event = {"type": "boot"};
	if (this.applicationName) event.name = this.applicationName;
	return this.request(event, 1);
},

event : function (event) {
	if (!this.sessionId) throw("firing event with no session");
	event.type    = "event";
	event.session = this.sessionId;
	return this.request(event);
},

request : function (event, isBoot) {
	event.requestCount = ++this.requestCount;
	var payloadXML     = this.getPayloadAsXML(event);
	var rawResponse    = this.httpRequest(this.requestPrefix, payloadXML);
	if (isBoot) {
		this.sessionId = (rawResponse.split("\n"))[0];
		rawResponse    = rawResponse.replace(/.*\n/, '');
	}
	return new XUL.Server.Response(rawResponse);
},

getPayloadAsXML : function (event) {
	var root = this.xml.parseFromString
		('<?xml version="1.0" encoding="UTF-8"?><xul></xul>', "text/xml");
	var doc = root.documentElement;
	var key, value;
	for (key in event) {
		var element  = root.createElement(key);
		element.appendChild(root.createTextNode(event[key]));
		doc.appendChild(element);
	}
	return root;
},

httpRequest : function (url, payload) { try {
	var port       = location.port;
	port           = port? ':' + port: '';
	var  serverURL = 'http://' + location.hostname + port + "/";
	var xmlHTTP    = this.xmlHTTP;

	xmlHTTP.open("POST", serverURL + url, false);
	try { xmlHTTP.send(payload || null) }
		catch (e) { Throw(e, "No response from server") }

	var response = new String(xmlHTTP.responseText);
	if (xmlHTTP.status != "200") Throw(
		"Cannot send request: " + xmlHTTP.statusText + "\n" +
		xmlHTTP.responseText
	);
	return response;
} catch (e) { Throw(e,
	"While requesting url: " + this.serverURL + ", request: " + url
)}}

});
