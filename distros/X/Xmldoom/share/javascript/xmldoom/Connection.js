
dojo.provide('Xmldoom.Connection');
dojo.provide('Xmldoom.priv');

dojo.require('dojo.lang');
dojo.require('dojo.json');
dojo.require('dojo.io.*');

dojo.declare('Xmldoom.priv.JSONTransport', null,
{
	parseObject: function (result)
	{
		return dojo.json.evalJson(result);
	},
	parseObjectList: function (result)
	{
		var data = dojo.json.evalJson(result);

		if ( data && dojo.lang.isUndefined(data.count) )
		{
			data = data.result;
		}

		return data;
	},
	parseCount: function (result)
	{
		var data = dojo.json.evalJson(result);
		return data.count;
	}
});

dojo.declare('Xmldoom.priv.XMLTransport', null,
{
	_findAttrs: function (parent)
	{
		var node = parent.firstChild;

		while ( node )
		{
			if ( node.nodeType == dojo.dom.ELEMENT_NODE &&
				 node.tagName == 'attributes' )
			{
				break;
			}

			node = node.nextSibling;
		}

		return node;
	},

	parseObject: function (result)
	{
		var doc = dojo.dom.createDocumentFromText(result);
		if ( doc )
		{
			return this._parseObject( doc.firstChild );
		}
		
		return null;
	},

	_parseObject: function (result)
	{
		// jump down to the attributes section
		parent = this._findAttrs(result);
		if ( !parent )
			return null;

		var node = parent.firstChild;
		var data = { };

		// go through the values and add them to data
		while ( node )
		{
			if ( node.nodeType == dojo.dom.ELEMENT_NODE &&
				 node.tagName == 'value' )
			{
				// Get the text value of the node, if it has a value, otherwise
				// we leave it at its default (by not setting it).
				if ( node.firstChild )
				{
					var key   = node.getAttribute('name');
					var value = node.firstChild.nodeValue;

					data[key] = value;
				}
			}

			node = node.nextSibling;
		}

		return data;
	},

	parseObjectList: function (result)
	{
		var doc = dojo.dom.createDocumentFromText(result);
		if ( doc )
		{
			return this._parseObjectList( doc.firstChild );
		}
		
		return null;
	},

	_parseObjectList: function (result)
	{
		var node = result.firstChild;
		var list = [ ];

		while ( node )
		{
			if ( node.nodeType == dojo.dom.ELEMENT_NODE &&
				 node.tagName == 'object' )
			{
				var obj = this._parseObject(node);
				if ( obj )
				{
					list[list.length] = obj;
				}
			}

			node = node.nextSibling;
		}

		return list;
	},

	parseCount: function (result)
	{
		alert("Xmldoom.priv.XMLTransport.parseCount(): Unimplemented!");
		return null;
		
		var doc  = dojo.dom.createDocumentFromText(result);
		var root = doc.documentElement;

		var count = null;

		if ( root.tagName == 'count' )
		{
		}
	}
});

dojo.declare('Xmldoom.Connection', null,
{
	initializer: function (base_url, type)
	{
		this.baseUrl = base_url;

		if ( !type )
			type = "xml";

		if ( type == "xml" )
		{
			this.transport = new Xmldoom.priv.XMLTransport();
		}
		else if ( type == "json" )
		{
			this.transport = new Xmldoom.priv.JSONTransport();
		}
		else
		{
			alert("Unsupported Xmldoom connection type '"+type+"'");
		}
	},

	load: function (xmldoomType, key)
	{
		var result = null;

		dojo.io.bind({
			url:         this.baseUrl + xmldoomType + "/load",
			method:      'get',
			content:     key,
			load:        function (type, data, evt) { result = data; },
			mimetype:    "text/plain",
			sync:        true
		});

		if ( !result )
			return null;

		return this.transport.parseObject(result);
	},

	search: function (xmldoomType, criteria, callback, includeCount)
	{
		var self   = this;
		var result = null;

		var sync;
		var onload;

		if ( callback )
		{
			onload = function (type, data, evt) 
			{
				if ( data )
				{
					data = self.transport.parseObjectList(data);
				}

				callback(data);
			}
			sync = false;
		}
		else
		{
			onload = function (type, data, evt)
			{
				result = data;
			}
			sync = true;
		}

		var operation = "/search";
		if ( includeCount )
		{
			operation = operation + "?includeCount=1";
		}

		dojo.io.bind({
			url:         this.baseUrl + xmldoomType + operation,
			method:      'post',
			postContent: criteria.xml(),
			load:        onload,
			mimetype:    "text/plain",
			sync:        sync
		});

		// this will catch both errors, and when we are in async mode.
		if ( !result )
			return null;

		return this.transport.parseObjectList(result);
	},

	count: function (xmldoomType, criteria)
	{
		var result = null;

		dojo.io.bind({
			url:         this.baseUrl + xmldoomType + "/count",
			method:      'post',
			postContent: criteria.xml(),
			load:        function (type, data, evt) { result = data; },
			mimetype:    "text/plain",
			sync:        true
		});

		if ( !result )
			return null;

		return this.transport.parseCount(result);
	}
});

