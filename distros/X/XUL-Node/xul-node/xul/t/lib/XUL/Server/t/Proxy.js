
JSAN.package('XUL.Server.t');
JSAN.use("Test.Case");
JSAN.use("XUL.Server.Proxy");

Test.Case.extend("XUL.Server.t.Proxy", {

testBoot : function () {
    var subject  = new XUL.Server.Proxy();
    var response = subject.boot("HelloWorld");
    var commands = response.getCommands();
    this.assertEquals("number of commands", 4, commands.length);
    this.assertEquals("an argument", "Hello World!", commands[3].arg2);
    this.assert("session id", subject.sessionId);
}

});
