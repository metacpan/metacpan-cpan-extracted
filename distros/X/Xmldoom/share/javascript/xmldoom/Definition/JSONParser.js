
dojo.provide('Xmldoom.Definition.JSONParser');

dojo.require('Xmldoom.Definition.Database');
dojo.require('Xmldoom.Definition.Property');

dojo.require('dojo.lang.*');
dojo.require('dojo.json');

Xmldoom.Definition.JSONParser.parse = function (data)
{
	if ( dojo.lang.isString(data) )
	{
		data = dojo.json.evalJson(data);
	}

	var database = new Xmldoom.Definition.Database();

	for ( var e = 0; e < data.length; e++ )
	{
		var object_data = data[e];
		var object = database.create_object(object_data.name, object_data);

		// add properties
		for( var i = 0; i < object_data.properties.length; i++ )
		{
			var prop_data = object_data.properties[i];
			var prop      = null;

			// add the parent to the prop_data!
			prop_data.parent = object;

			// create the appropriate property object
			if ( prop_data.type == 'simple' )
			{
				prop = new Xmldoom.Definition.Property.Simple(prop_data);
			}
			else if ( prop_data.type == 'object' )
			{
				prop = new Xmldoom.Definition.Property.Object(prop_data);
			}

			// TODO: handle other property types.
			if ( prop )
			{
				object.add_property(prop);
			}
		}
	}

	return database;
}

