
dojo.provide('Xmldoom.Definition.Object');

dojo.declare('Xmldoom.Definition.Object', null, 
{
	initializer: function (database, object_name, definition)
	{
		this.database    = database;
		this.object_name = object_name;
		this.props       = [ ];
		this.class_cons  = null;

		// a hash of attrs with there defaults.
		this.attrs = definition.attributes; // { }
		// a list of the names of the attrs that make up the key.
		this.key_names = definition.key_names; // [ ]
	},

	// None of these accessors are strictly necessary, but provide compatibility
	// with the Perl version of Xmldoom
	get_database:   function () { return this.database; },
	get_name:       function () { return this.object_name; },
	get_properties: function () { return this.props; },
	get_attributes: function () { return this.attributes; },
	get_key_names:  function () { return this.key_names; },
	get_class:      function () { return this.class_cons; },

	set_class: function (cons) { this.class_cons = cons; },

	// convenience:
	get_db_connection: function() { return this.get_database().get_connection(); },

	//
	// Some actually useful functions:
	//
	
	get_property: function (name)
	{
		for ( var i = 0; i < this.props.length; i++ )
		{
			if ( this.props[i].get_name() == name )
			{
				return this.props[i];
			}
		}

		// TODO: throw exception.
	},

	has_property: function (name)
	{
		// TODO: deal with the exception!

		if ( !this.get_property(name) )
		{
			return false;
		}

		return true;
	},

	add_property: function (prop)
	{
		if ( this.has_property( prop.get_name() ) )
		{
			// TODO: throw exception!
			return;
		}

		this.props[ this.props.length ] = prop;
	},

	//
	// Perform database functions for an object type
	//

	load: function (keys)
	{
		return this.get_db_connection().load(this.get_name(), keys);
	},
	
	search: function (criteria, callback, includeCount)
	{
		return this.get_db_connection().search(this.get_name(), criteria, callback, includeCount);
	},

	count: function (criteria, callback)
	{
		return this.get_db_connection().count(this.get_name(), criteria);
	}
});

