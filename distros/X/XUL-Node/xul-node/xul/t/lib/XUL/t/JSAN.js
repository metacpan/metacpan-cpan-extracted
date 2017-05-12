
JSAN.package('XUL.t');
JSAN.use("Test.Case");
JSAN.use("XUL.t.Eg.Person");

Test.Case.extend("XUL.t.JSAN", {

testGetSet : function () {
    var person = new XUL.t.Eg.Person("foo");
    this.assertEquals("get name", "foo", person.get_name());
    person.set_name("bar");
    this.assertEquals("set name", "bar", person.get_name());
}

});
