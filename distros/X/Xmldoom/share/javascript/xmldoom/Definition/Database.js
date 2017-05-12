
dojo.provide('Xmldoom.Definition.Database');

dojo.require('Xmldoom.Definition.Object');

dojo.declare('Xmldoom.Definition.Database', null, 
{
	initializer: function ()
	{
		this.objects    = { };
		this.connection = null;
	},

	// None of these accessors are strictly necessary, but provide compatibility
	// with the Perl version of Xmldoom

	get_connection: function () { return this.connection; },
	get_objects: function ()    { return this.objects; },
	get_object: function (name) { return this.objects[name]; },
	has_object: function (name) { return this.objects[name] ? true : false; },

	set_connection: function (conn) { this.connection = conn; },

	// 
	// Actually useful functions:
	//

	create_object: function (object_name, definition)
	{
		if ( this.has_object(object_name) )
		{
			// TODO: throw exception
			return;
		}

		var object = new Xmldoom.Definition.Object( this, object_name, definition );
		this.objects[object_name] = object;
		return object;
	}
});

