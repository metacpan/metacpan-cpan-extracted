
JSAN.package('Test');
JSAN.use("Test.Result");
JSAN.use("Test.Suite");

new Class("Test.Runner", {

start : function (name) {
    console.info("Starting Runner on test [%s]...", name);
	var suite  = this.getTest(name);
	var result = this.doRun(suite);
	return result;
},

doRun : function (suite) {
	var result = new Test.Result();
	result.setListener(this);
	var startTime = (new Date).getTime().toString();
	suite.run(result);
	var endTime = (new Date).getTime().toString();
	var runTime = endTime - startTime;
	this.printReport(result, runTime);
},

printReport : function (result, runTime) {
	var errorCount   = result.errors.length;
	var failureCount = result.failures.length;
    var okCount      = result.runCount - errorCount - failureCount;
    var out          =
        "Completed " + result.runCount + " tests in " + runTime + " ms: " +
		"OK = " + okCount +
        ", ERROR = " + errorCount +
        ", FAIL = " + failureCount;
	if (errorCount == 0 && failureCount == 0)
        console.info(out);
    else
        console.error(out);
},

startTest : function (test) {
    this.print
        (test.$className.replace(/\.t\./,".") + "." + test.name);
},

endTest : function (test) {},

addError : function (failure) {
    console.error
        ("ERROR in [%s]: %s", failure.test.name, failure.error.message);
},

addFailure : function (failure) {
    console.error
        ("FAIL in [%s]: %s", failure.test.name, failure.error.message);
},

print : function (message) { console.log(message) },

getTest : function (name) {
	var classdef = JSAN.use(name);
    var suiteMethod = classdef.prototype.suite;
	if (!suiteMethod) return new Test.Suite(name, 1);
	var result;
	try { result = suiteMethod.call() }
		catch (e) { Throw(e, "Calling suiteMethod on: " +  name) }
	return result;
}

});

