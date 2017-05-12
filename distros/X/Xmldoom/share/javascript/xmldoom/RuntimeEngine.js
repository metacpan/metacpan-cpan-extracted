
dojo.provide('Xmldoom.RuntimeEngine');

dojo.require('Xmldoom.Object');
dojo.require('dojo.lang');

//
// TODO: through out this whole module, I need to go through and make sure
// that only things I am intending are being attached to closures.
//

Xmldoom.RuntimeEngine.make_objects = function (definition, data)
{
	var cons = definition.get_class();
	var result = new Array(data.length);

	for ( var i = 0; i < data.length; i++ )
	{
		result[i] = new cons({ data: data[i] });
	}

	return result;
}

Xmldoom.RuntimeEngine.Search = function (definition, criteria, callback, includeCount)
{
	if ( callback )
	{
		var onload = function (data)
		{
			var result;
			var count;

			if ( includeCount )
			{
				result = data.result;
				count  = data.count;
			}
			else
			{
				result = data;
			}

			// parse into objects
			result = Xmldoom.RuntimeEngine.make_objects(definition, result);

			if ( includeCount )
			{
				callback({
					result: result,
					count:  count
				});
			}
			else
			{
				callback(result);
			}
		}
		definition.search(criteria, onload, includeCount);
	}
	else
	{
		var data = definition.search(criteria, null, includeCount);

		if ( includeCount )
		{
			return {
				result: Xmldoom.RuntimeEngine.make_objects(definition, data.result),
				count:  data.count
			};
		}
		else
		{
			return Xmldoom.RuntimeEngine.make_objects(definition, data);
		}
	}
}

Xmldoom.RuntimeEngine.defineClass = function (definition)
{
	// we create the constructor
	var object = function (args)
	{
		Xmldoom.Object.call(this, definition, args);
	}
	dojo.lang.extend(object, Xmldoom.Object.prototype);

	// add a the loading "constructor"
	object.load = function (keys)
	{
		return new object({
			data: definition.load(keys)
		});
	}

	// add the definition specific Search()
	object.Search = function (criteria, callback)
	{
		return Xmldoom.RuntimeEngine.Search( definition, criteria, callback );
	}

	var properties = definition.get_properties();

	for( var i = 0; i < properties.length; i++ )
	{
		var property  = properties[i];
		var get_names = property.get_get_names();
		var set_names = property.get_set_names();

		// we make happy little closures to be the methods.

		var get_method = (function (p)
		{
			return function (args) { return p.get(this, args); }
		})(property);

		var set_method = (function (p)
		{
			return function (value) { p.set(this, value); }
		})(property);

		// Set all the get/set names to their appropriate methods
		for ( var e = 0; e < get_names.length; e++ )
		{
			object.prototype[get_names[e]] = get_method;
		}
		for ( var e = 0; e < set_names.length; e++ )
		{
			object.prototype[set_names[e]] = set_method;
		}
	}

	return object;
}

Xmldoom.RuntimeEngine.packObjectList = function (parent, name, src_list)
{
	if ( name )
	{
		if ( src_list['__self'] )
		{
			parent[name] = src_list['__self'];
		}
		else
		{
			parent[name] = { };
		}

		parent = parent[name];
	}

	for ( src_name in src_list )
	{
		if ( src_name != '__self' )
		{
			// recurse!
			Xmldoom.RuntimeEngine.packObjectList(parent, src_name, src_list[src_name]);
		}
	}
}

Xmldoom.RuntimeEngine.init = function (ns_root, database, connection)
{
	var objects = { };

	// produce a list of object names
	for ( var object_name in database.get_objects() )
	{
		var object_definition = database.get_object(object_name);
		var object = Xmldoom.RuntimeEngine.defineClass(object_definition);

		var names = object_name.split('.');
		var slot  = objects;
		for ( var i = 0; i < names.length; i++ )
		{
			if ( !slot[names[i]] )
			{
				slot[names[i]] = { };
			}
			slot = slot[names[i]];
		}
		slot['__self'] = object;

		// we bind our definition to this class
		object_definition.set_class( object );
	}

	Xmldoom.RuntimeEngine.packObjectList(ns_root, null, objects);
}

