
JSAN.package('Test');
JSAN.use("Test.Assert");

Test.Assert.extend("Test.Case", {

initialize : function (name ) { this.name = name || "noname" },

run            : function (result) { result.run(this) },
countTestCases : function ()       { return 1 },
setUp          : function ()       {},
tearDown       : function ()       {},

runBare : function () {
	this.setUp();
	var runError = false;
	try { this.runTest() } catch (e) { runError = e }
	this.tearDown();
	if (runError) throw(runError);
},

runTest : function () {
	var methodName = this.name;
	if (!methodName) Throw("Running test with no name");
    this[methodName].call(this);
}

});
