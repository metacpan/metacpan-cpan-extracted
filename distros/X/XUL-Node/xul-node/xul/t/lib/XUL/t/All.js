
JSAN.package('XUL.t');
JSAN.use("Test.Suite");

new Class("XUL.t.All", {

suite : function () {
	var suite = new Test.Suite("XUL-Node tests");
	suite.addTestCase("XUL.t.JSAN");
	suite.addTestSuite("XUL.Server.t.All");
	return suite;
},

});
