
JSAN.package('XUL.Client');

new Class("XUL.Client.Runner", {

initialize : function () { this.document = window.document },

run : function (response) {
	this.resetBuffers();

	var commands = response.getCommands();
	var command;
	for (command in commands)
		this.runCommand(commands[command]);

	var roots = this.newNodeRoots;
	var parentId;
	for (parentId in roots)
		this.addElementAtIndex(this.getNode(parentId), roots[parentId]);

	var lateCommands = this.lateCommands;
	for (command in lateCommands) {
		command = lateCommands[command];
		this.commandSetNode
			(command['nodeId'], command['arg1'], command['arg2']);
	}

	var latestCommands = this.latestCommands;
	for (command in latestCommands) {
		command = latestCommands[command];
		this.commandSetNode
			(command['nodeId'], command['arg1'], command['arg2']);
	}
},

// commands -------------------------------------------------------------------

runCommand : function (command) {
	var nodeId     = command['nodeId'];
	var methodName = command['methodName'];
	var arg1       = command['arg1'];
	var arg2       = command['arg2'];
	var arg3       = command['arg3'];
	if (methodName == 'new')
		if (arg1 == 'window')
			this.commandNewWindow(nodeId);
		else
			this.commandNewElement(nodeId, arg1, arg2, arg3);
	else
		if (methodName == 'bye')
			this.commandByeElement(nodeId);
		else
			if (this.lateAttributes[arg1])
				this.lateCommands.push(command);
			else
				if (this.latestAttributes[arg1])
					this.latestCommands.push(command);
				else
					this.commandSetNode(nodeId, arg1, arg2);
},

commandNewWindow : function (nodeId) {
	this.windowId = nodeId;
},

commandNewElement : function (nodeId, tagName, parentId, index) { try {
	if (tagName == '') Throw ("cannot create element with no tagName [" + nodeId + "]");
	var element = this.createElement(tagName, nodeId);
	element.setAttribute('_addAtIndex', index);
	this.newNodes[nodeId] = element;
	var parent = this.newNodes[parentId];
	if (parent)
		this.addElementAtIndex(parent, element);
	else
		this.newNodeRoots[parentId] = element;

	// onselect does not bubble
	if (tagName == 'listbox')
		element.setAttribute('onselect', 'XUL.Application.get().fireEvent_Select(event)');
	else
		if (tagName == 'colorpicker')
			element.setAttribute(
				'onselect',
				'XUL.Application.get().fireEvent_Pick({"targetId":"' +
					element.id + '"})'
			);

} catch (e) {
	Throw(e,
		'Cannot create new node: [' + nodeId +
		', ' + tagName + ', ' + parentId + ']'
	);
}},

commandSetNode : function (nodeId, key, value) { try {
	var element = this.newNodes[nodeId];

	if (!element) element = this.getNode(nodeId);

	if (key == 'textNode') {
		element.appendChild(this.document.createTextNode(value));
		return;
	}
	if (this.booleanAttributes[key]) {
		value = (value == 0 || value == '' || value == null)? false: true;
		if (!value)
			element.removeAttribute(key);
		else
			element.setAttribute(key, 'true');
		return;
	}
	if (this.simpleMethodAttributes[key]) {
		if (element.tagName == 'window')
			window[key].apply(window, [value]);
		else
			element[key].apply(element, [value]);
		return;
	}
	if (this.propertyAttributes[key]) {
		if (key == 'selectedIndex')
			element.setAttribute("suppressonselect", true);
		element[key] = value;
		if (key == 'selectedIndex')
			element.setAttribute("suppressonselect", false);
		return;
	}
	if (key == 'value' && element.tagName == 'textbox') {
		element[key] = value;
		return;
	}
	element.setAttribute(key, value);

} catch (e) {
	Throw(e,
		'Cannot do set on node: [' + nodeId + ', ' + key + ', ' + value + ']'
	);
}},

commandByeElement : function (nodeId) {
	var node = this.getNode(nodeId);
	node.parentNode.removeChild(node);
},

// private --------------------------------------------------------------------

getNode : function (nodeId) {
	var node = this._getNode(nodeId);
	if (!node) Throw("cannot find node by Id: " + nodeId);
	return node;
},

_getNode : function (nodeId) {
	var node = this.windowId == nodeId?
		this.document.firstChild:
		this.document.getElementById(nodeId);
	return node;
},

createElement : function (tagName, nodeId) {
	var element = tagName.match(/^html_/)?
		this.document.createElementNS(
			'http://www.w3.org/1999/xhtml',
			tagName.replace(/^html_/, '')
		):
		this.document.createElementNS(
			'http://www.mozilla.org/keymaster/gatekeeper/there.is.only.xul',
			tagName
		);
	element.id = nodeId;
	return element;
},

addElementAtIndex : function (parent, child) {
	var index = child.getAttribute('_addAtIndex');
	child.removeAttribute('_addAtIndex');
	
	if (index == null) {
		parent.appendChild(child);
		return;
	}
	var children = parent.childNodes;
	var count    = children.length;
	if (count == 0)
		parent.appendChild(child);
	else
		parent.insertBefore(child, index == count? null: children[index]);
},

resetBuffers : function () {
	this.newNodeRoots   = []; // top level parent nodes of those not yet added
	this.newNodes       = []; // nodes not yet added to document
	this.lateCommands   = []; // commands to run after most other commands
	this.latestCommands = []; // commands to run at latest possible time
},

booleanAttributes : {
	'disabled'     : true,
	'multiline'    : true,
	'readonly'     : true,
	'checked'      : true,
	'hidden'       : true,
	'default'      : true,
	'grippyhidden' : true
},
propertyAttributes : {
	'selectedIndex': true
},
lateAttributes : {
	'selectedIndex': true,
	'value'        : true
},
latestAttributes : {
	'sizeToContent': true,
},
simpleMethodAttributes : {
	'sizeToContent'       : true,
	'ensureIndexIsVisible': true
}

}); 
