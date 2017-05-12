
JSAN.package('t');
JSAN.use("Test.Suite");

new Class("t.All", {

suite : function () {
	var suite = new Test.Suite("All tests");
	suite.addTestSuite("XUL.t.All");
	suite.addTestSuite("Test.t.All");
	return suite;
},

});
