
JSAN.package('XUL.t.Eg');

new Class("XUL.t.Eg.Person", {

initialize : function (name) { this.set_name(name)    },
get_name   : function ()     { return this.name       },
set_name   : function (name) { this.name = name       },
as_string  : function ()     { return this.get_name() }

});
