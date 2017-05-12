
dojo.provide('Xmldoom.Object');

// TODO: maybe we should combine the Object.js and Runtime.js?
dojo.require('Xmldoom.RuntimeEngine');
dojo.require('dojo.dom');
dojo.require('dojo.lang');
dojo.require('dojo.lang.extras');

dojo.declare('Xmldoom.Object', null,
{
	initializer: function (definition, args)
	{
		this._definition = definition;
		this._info = null;
		this._key = { };

		if ( !args )
			args = { };

		var key_names = this._definition.get_key_names();

		if ( !args.data )
		{
			this._info = dojo.lang.shallowCopy(this._definition.get_attributes());
			for ( var i = 0; i < key_names.length; i++ )
			{
				this._key[key_names[i]] = null;
			}
		}
		else
		{
			this._info = args.data;
			for ( var i = 0; i < key_names.length; i++ )
			{
				this._key[key_names[i]] = this._info[key_names[i]];
			}
		}
	},

	//
	// Accessors
	//

	_get_definition:  function () { return this._definition; },
	_get_database:    function () { return this._definition.get_database(); },
	_get_object_name: function () { return this._definition.get_name(); },
	_get_key:         function () { return this._key; },

	_get_attr: function (name) { return this._info[name]; },
	_set_attr: function (name, value) { this._info[name] = value; }
});


