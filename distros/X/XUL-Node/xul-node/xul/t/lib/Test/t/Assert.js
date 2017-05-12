
JSAN.package('Test.t');
JSAN.use("Test.Case");
JSAN.use("Test.AssertionFailedError");

Test.Case.extend("Test.t.Assert", {

testAssertOk : function () { this.assert("true is true", true) },

testAssertFail : function () {
    try { this.assert("false is false", 0) } catch (e)
        { if (e instanceof Test.AssertionFailedError) return }
	this.fail("false is false");
},

testAssertEquals : function () {
	this.assertEquals("foo is foo", "foo", "foo");
	this.assertEquals("123 is 123", 123, 123);
}

});
