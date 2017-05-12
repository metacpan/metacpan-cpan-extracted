
dojo.provide('Xmldoom.Definition.Property');

dojo.require('Xmldoom.Criteria');
dojo.require('dojo.lang');

dojo.declare('Xmldoom.Definition.Property.Base', null,
{
	initializer: function (args)
	{
		// TODO: should be standard
		this.parent    = args.parent;
		this.name      = args.name;
		this.get_names = args.get_names || [];
		this.set_names = args.set_names || [];
	},
	get_parent: function ()   { return this.parent },
	get_name: function()      { return this.name },
	get_get_names: function() { return this.get_names },
	get_set_names: function() { return this.set_names }
});

dojo.declare('Xmldoom.Definition.Property.Simple', Xmldoom.Definition.Property.Base,
{
	initializer: function (args)
	{
		Xmldoom.Definition.Property.Base.prototype.initializer.call(this, args);

		this.attribute      = args.attribute;
		this.trans_to_map   = args.trans_to;
		this.trans_from_map = args.trans_from;
	},
	trans_to: function (value)
	{
		if ( this.trans_to_map )
		{
			if ( dojo.lang.isUndefined(this.trans_to_map[value]) )
			{
				// TODO: throw exception!
				alert('Trying to use an invalid value \''+value+'\'');
			}
			else
			{
				value = this.trans_to_map[value];
			}
		}

		return value;
	},
	trans_from: function (value)
	{
		if ( this.trans_from_map )
		{
			value = this.trans_from_map[value];
		}

		return value;
	},
	get: function (object)
	{
		return this.trans_from( object._get_attr(this.attribute) );
	},
	set: function (object, value)
	{
		object._set_attr( this.attribute, this.trans_to(value) );
	}
});

dojo.declare('Xmldoom.Definition.Property.Object', Xmldoom.Definition.Property.Base,
{
	initializer: function (args)
	{
		Xmldoom.Definition.Property.Base.prototype.initializer.call(this, args);

		this.object_name = args.object_name;
		this.type        = args.object_type;
		this.connections = args.connections;
		this.inter_table = args.inter_table;
	},
	get: function (object, args)
	{
		if ( this.type == 'inherent' )
		{
			// build the objects key from data on the current object
			var key = { };
			for ( var i = 0; i < this.connections.length; i++ )
			{
				key[this.connections[i].other] = object._get_attr(this.connections[i].self);
			}

			// load the object
			return this.get_parent().get_database().get_object(this.object_name).get_class().load(key);
		}
		else
		{
			// we use criteria to implement this
			var criteria = new Xmldoom.Criteria(object);

			// use the extra arguments to suppliment the criteria
			for( var arg_name in args )
			{
				criteria.add( this.object_name+'/'+arg_name, args[arg_name] );
			}

			// TODO: do something about inter-tables.

			// return the object, yo!
			return this.get_parent().get_database().get_object(this.object_name).get_class().Search(criteria);
		}
	},
	set: function (object, value)
	{
		if ( this.type = 'inherent' )
		{
			// copy attributes from value
			for ( var i = 0; i < this.connections.length; i++ )
			{
				object._set_attr(this.connections[i].self, value._get_attr(this.connections[i].other));
			}
		}
		else
		{
			var criteria = new Xmldoom.Criteria();
		}
	}
});

