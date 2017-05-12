
JSAN.package('XUL.Server');

new Class("XUL.Server.Response", {

wordSeperator : String.fromCharCode(1),
lineSeperator : String.fromCharCode(2),

initialize : function (response) {
	this.message  = response;
	this.commands = this.parseCommands();
	if (response.match(/^ERROR/)) Throw("Server side error. " + response);
//	this.dumpResponse();
},

parseCommands : function () {
	var outLines = [];
	if (this.message == 'null') return outLines;
	var inLines = this.message.split(this.lineSeperator);
	var inLine;
	for (inLine in inLines) {
		inLine = inLines[inLine];
		if (!inLine.match(/\w/)) continue;
		var params  = inLine.split(this.wordSeperator);
		outLines.push({
			'nodeId'    : params[0],
			'methodName': params[1],
			'arg1'      : params[2],
			'arg2'      : params[3],
			'arg3'      : params[4]
		});
	}
	return outLines;
},

// for testing, class method
makeCommands : function (commands) {
    var response = "";
    var newCommands = [];
    var i; for (i in commands)
        { newCommands.push( commands[i].replace(/\./g, this.wordSeperator) ) }
    return newCommands.join( this.lineSeperator );
},

dumpResponse : function () {
	var commands = this.getCommands();
	console.log("* received response (" + commands.length + " lines):");
	var command;
	for (command in commands) {
		command = commands[command];
		console.log(
			"   " + this.pad(command['nodeId'], 4) + '.' + command['methodName'] +
			'(' + command['arg1'] + ', ' + command['arg2'] + ")"
		);
	}
},

pad : function (input, length) {
	var inLength = input.length;
	if (inLength >= length) return input;
	padLength = length - inLength;
	var count;
	for (count = 0; count < padLength; count++) input = ' ' + input;
	return input;
},

getCommands : function () { return this.commands },
getMessage  : function () { return this.message  }

});
