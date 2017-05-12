
JSAN.package('XUL');
JSAN.use("XUL.Client.Runner");
JSAN.use("XUL.Server.Proxy");

new Class("XUL.Application", {

initialize : function () {
    this.simulationMode = false;
    this.runner         = new XUL.Client.Runner();
    this.server         = new XUL.Server.Proxy();
	this.runRequest();
},

// events ---------------------------------------------------------------------

fireEvent_Command : function (domEvent) {
	var source = domEvent.target;
	if (source.tagName == 'menuitem') {
		var realSource = source.parentNode.parentNode;
		if (realSource.tagName == 'menu') {
			this.fireEvent('Click', domEvent, {});
		} else {
			var selectedIndex;
			if (realSource.tagName == 'button') {
				var children = source.parentNode.childNodes;
				selectedIndex = children.length;
				while (selectedIndex--) if (children[selectedIndex] == source) break;
			} else { // a menulist
				selectedIndex = realSource.selectedIndex;
			}
			this.fireEvent(
				'Select',
				{'target': realSource},
				{'selectedIndex': selectedIndex}
			);
		}
	} else {
		this.fireEvent('Click', domEvent, {});
	}
},

fireEvent_Select : function (domEvent) {
	var source = domEvent.target;
	var selectedIndex = source.selectedIndex;
	if (selectedIndex == -1) return; // listbox: mozilla fires strange events
	this.fireEvent
		('Select', {'target': source}, {'selectedIndex': selectedIndex });
},

fireEvent_Pick : function (domEvent) {
	var source = window.document.getElementById(domEvent.targetId);
	this.fireEvent('Pick', {'target': source}, {'color': source.color });
},

fireEvent_Change : function (domEvent)
	{ this.fireEvent('Change', domEvent, {'value': domEvent.target.value}) },

// private --------------------------------------------------------------------

fireEvent : function (name, domEvent, params) {
	var source   = domEvent.target;
	var sourceId = source.id;
	if (!sourceId) return; // event could come from some unknown place
	var event = {
		'source' : sourceId,
		'name'   : name,
		'checked': source.getAttribute('checked')
	};
	var key; for (key in params) event[key] = params[key];
	this.runRequest(event);
},

runRequest : function (event) {
	if (this.simulationMode) return;
	window.status = "Loading UI...";
	var response  = event? this.server.event(event): this.server.boot();
	window.status = "Running UI...";
	this.runner.run(response);
	window.status = "Done.";
}

});

XUL.Application.get = function () {
    if (XUL.Application.instance) return XUL.Application.instance;
    XUL.Application.instance = new XUL.Application();
    return XUL.Application.instance;
};
