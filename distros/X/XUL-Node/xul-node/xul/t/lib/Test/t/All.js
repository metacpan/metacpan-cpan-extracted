
JSAN.package('Test.t');
JSAN.use("Test.Suite");

new Class("Test.t.All", {

suite : function () {
	var suite = new Test.Suite("Assertion tests");
	suite.addTestCase("Test.t.Assert");
	return suite;
},

});
