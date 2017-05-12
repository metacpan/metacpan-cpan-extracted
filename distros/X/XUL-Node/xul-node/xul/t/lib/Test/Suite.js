
JSAN.package('Test');
JSAN.use("Test.Case");

new Class("Test.Suite", {

initialize : function (thing, wrap) {
	this.tests = new Array();
	if (!wrap) {
		this.name = thing;
		return;
	}
	var testName = thing;
	var classdef = JSAN.use(testName);
    var proto    = classdef.prototype;
	if (!(proto instanceof Test.Case)) Throw("Not a Test.Case:" + testName);
	var testMethods = this.getTestMethods(proto);
	if (!testMethods.length) Throw("No test methods in test:" + testName);
	var i; for (i in testMethods) {
        var test = new classdef(); // catch creating test?
		this.addTestMethod(test, testMethods[i]);
	}
},

addTestMethod : function (test, methodName) {
	test.name = methodName;
    this.tests.push(test);
},

addTestCase : function (testName) {
	this.tests = this.tests.concat(new Test.Suite(testName, 1));
},

addTestSuite : function (suiteName) {
	var classdef = JSAN.use(suiteName);
    var suite    = new classdef(); // catch creating suite?
	this.tests.push(suite.suite());
},

run : function (result)
	{ var i; for (i in this.tests) this.tests[i].run(result) },

countTestCases : function () {
	var testCount = 0;
	var i; for (i in this.tests) testCount += this.tests[i].countTestsCases();
},

getTestMethods : function (test) {
	var result = new Array();
	var key; for (key in test) {
		var method = test[key];
		if (!(method instanceof Function)) continue;
		if (key.match("^test")) result = result.concat(key);
	}
	return result.sort();
}

});
