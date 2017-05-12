
JSAN.package('Test');
JSAN.use("Test.Failure");
JSAN.use("Test.AssertionFailedError");

new Class("Test.Result", {

initialize : function () {
	this.runCount = 0;
	this.errors   = new Array;
	this.failures = new Array;
},

run : function (test) {
	this.startTest(test);
	try {
		test.runBare();
    } catch (e) {
        if (e instanceof Test.AssertionFailedError) {
			this.addFailure(test, e);
        } else {
			this.addError(test, e);
        }
	}
	this.endTest(test);
},

setListener : function (listener) { this.listener = listener },
endTest     : function (test)     { this.listener.endTest(test) },

startTest : function (test) {
	this.runCount += test.countTestCases();
	this.listener.startTest(test);
},

addError : function (test, error) {
	var failure = new Test.Failure(test, error);
	this.errors = this.errors.concat(failure);
	this.listener.addError(failure);
},

addFailure : function (test, error) {
	var failure   = new Test.Failure(test, error);
	this.failures = this.failures.concat(failure);
	this.listener.addFailure(failure);
}

});
