
JSAN.package('XUL.Server.t');
JSAN.use("Test.Suite");

new Class("XUL.Server.t.All", {

suite : function () {
	var suite = new Test.Suite("XUL-Node Server tests");
	suite.addTestCase("XUL.Server.t.Response");
	suite.addTestCase("XUL.Server.t.Proxy");
	return suite;
},

});
