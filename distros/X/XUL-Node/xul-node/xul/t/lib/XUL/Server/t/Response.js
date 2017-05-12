
JSAN.package('XUL.Server.t');
JSAN.use("Test.Case");
JSAN.use("XUL.Server.Response");

Test.Case.extend("XUL.Server.t.Response", {

testParsing : function () {
    var response = XUL.Server.Response.prototype.makeCommands([
        'E1.new.window.0',
        'E2.new.label.E1',
        'E2.set.value.foo'
    ]);
    var subject = new XUL.Server.Response(response);
    var commands = subject.getCommands();
    this.assertEquals("number of commands", 3       , commands.length);
    this.assertEquals("command id"        , 'E1'    , commands[0].nodeId);
    this.assertEquals("method name"       , 'new'   , commands[1].methodName);
    this.assertEquals("arg1"              , 'window', commands[0].arg1);
    this.assertEquals("arg2"              , 'foo'   , commands[2].arg2);
}

});
