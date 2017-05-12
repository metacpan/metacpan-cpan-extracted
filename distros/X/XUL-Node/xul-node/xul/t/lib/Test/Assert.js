
JSAN.package('Test');
JSAN.use("Test.AssertionFailedError");

new Class("Test.Assert", {

assert : function (message, condition) {
	if (arguments.length > 2)
		this.error("Too many arguments for assertEquals, " + message);
	if (!condition) this.fail(message);
},

assertEquals : function (message, expected, actual) {
	if (arguments.length < 3)
		this.error("Missing arguments for assertEquals, " + message);
	if (expected != actual)
		this.fail(message + ", expected: [" + expected + "] but was: [" + actual + "]");
},

fail  : function (message) { throw new Test.AssertionFailedError(message) },
error : function (message) { Throw(message) }

});
