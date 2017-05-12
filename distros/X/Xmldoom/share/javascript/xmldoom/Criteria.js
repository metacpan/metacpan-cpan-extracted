
dojo.provide('Xmldoom.Criteria');

dojo.require('dojo.lang');

/*
Used to produce the XML for doing an Xmldoom::Criteria search.
*/

dojo.declare('Xmldoom.Criteria', null,
{
	initializer: function ( arg )
	{
		this.order_by_node = null;
		this.parent_node = null;
		this.parent = null;

		var cons_node;

		if ( dojo.lang.isString( arg ) )
		{
			// read from an XML string
			this.doc = dojo.dom.createDocumentFromText(arg);
			this.order_by_node = this.doc.getElementsByTagName('order-by').item(0);
			cons_node = this.doc.getElementsByTagName('constraints').item(0);
		}
		else
		{
			// create a new document
			this.doc = dojo.dom.createDocument();
			this.doc.appendChild(this.doc.createElement("search"));

			if ( arg )
				this.parent = arg;
		}
		if ( !cons_node )
		{
			cons_node = this.doc.createElement("constraints"); 
			this.doc.firstChild.appendChild(cons_node);
		}
		// create the search object
		this.search = new Xmldoom.Criteria.Search( this.doc, cons_node );
	},

	// 
	// XML boilerplate accessors
	//

	getDoc:  function () { return this.doc },
	getNode: function () { return this.getDoc().firstChild },
	getType: function () { return this.getNode().getAttribute('type'); },
	setType: function (type)
	{
		this.getNode().setAttribute('type', type);
	},
	xml: function ()
	{
		// DRS: Ok, this is a big hack.  We create the parent node if
		// one is necessary, and remove it if not.  We do this because the
		// parent object could have changed between the time that the
		// criteria object was created and when it was used, and we want
		// those changes reflected.  Is this a real worry, or am I being 
		// crazy?

		if ( this.parent_node )
		{
			this.getNode().removeChild(this.parent_node);
			this.parent_node = null;
		}
		if ( this.parent )
		{
			var key = this.parent._get_key();
			var key_node;

			// create parent node
			this.parent_node = this.getDoc().createElement('parent');
			this.parent_node.setAttribute('object_name', this.parent._get_object_name());

			// create a key node
			key_node = this.getDoc().createElement('key');
			for ( var key_name in key )
			{
				key_node.setAttribute(key_name, key[key_name]);
			}

			// add to the document
			this.parent_node.appendChild(key_node);
			this.getNode().appendChild(this.parent_node);
		}
		
		// the real work...
		return dojo.dom.innerXML(this.getNode());
	},
	clone: function ()
	{
		// DRS: This is the biggest hack ever!  Instead of doing something sane, we
		// are going to serialize to xml and then re-parse to create the copy.

		return new Xmldoom.Criteria( this.xml() );
		//return new Xmldoom.Criteria( '<criteria><constraints/></criteria>' );
	},

	//
	// Actual member functions
	//

	get_constraints: function () { return this.search.get(); },
	get_parent:      function () { return this.parent; },

	add_prop:   function (a1, a2, a3) { this.search.add_prop(a1, a2, a3); },
	add:        function (a1, a2, a3) { this.add_prop(a1, a2, a3); },

	set_limit: function (limit, offset)
	{
		if ( !dojo.lang.isUndefined(limit) )
		{
			this.getNode().setAttribute('limit', limit);
		}
		if ( !dojo.lang.isUndefined(offset) )
		{
			this.getNode().setAttribute('offset', offset);
		}
	},

	add_order_by: function (name, dir)
	{
		if ( this.order_by_node == null )
		{
			this.order_by_node = this.doc.createElement("order-by");
			this.getNode().appendChild(this.order_by_node);
		}

		var prop_node = this.doc.createElement('property');
		prop_node.setAttribute('name', name);
		if ( dir )
		{
			prop_node.setAttribute('dir', dir);
		}

		this.order_by_node.appendChild(prop_node);
	},

	get_order_by: function ()
	{
		var ret = Array();
		var node, i, name, dir;

		if ( !this.order_by_node )
		{
			// toss back an empty list
			return ret;
		}

		node = this.order_by_node.firstChild;

		while ( node )
		{
			if ( node.tagName == 'property' )
			{
				ret[ret.length] = {
					'prop':  node.getAttribute('name'),
					'dir' :  node.getAttribute('dir')
				};
			}

			node = node.nextSibling;
		}

		return ret;
	}
});

Xmldoom.Criteria.ComparisonTypes = {
	AND:           'and',
	OR:            'or',
	EQUAL:         'equal',
	NOT_EQUAL:     'not-equal',
	GREATER_THAN:  'greater-than',
	GREATER_EQUAL: 'greater-equal',
	LESS_THAN:     'less-than',
	LESS_EQUAL:    'less-equal',
	LIKE:          'like',
	NOT_LIKE:      'not-like',
	BETWEEN:       'between',
	IN:            'in',
	NOT_IN:        'not-in',
	IS_NULL:       'is-null',
	IS_NOT_NULL:   'is-not-null'
};
// for convenience.
dojo.lang.mixin(Xmldoom.Criteria, Xmldoom.Criteria.ComparisonTypes);

dojo.declare('Xmldoom.Criteria.Search', null,
{
	initializer: function (doc, node)
	{
		this.doc  = doc;
		this.node = node;
	},

	getNode: function () { return this.node; },

	add_prop: function (name, value, type)
	{
		if ( typeof(type) == 'undefined' )
		{
			type = Xmldoom.Criteria.EQUAL;
		}

		// create the property node
		var property_node;
		property_node = this.doc.createElement('property');
		property_node.setAttribute('name', name);
		this.getNode().appendChild(property_node);

		// create the comparison node
		var comparison_node = this.doc.createElement( type );
		if ( type == Xmldoom.Criteria.IN || 
		     type == Xmldoom.Criteria.NOT_IN )
		{
			alert('Criteria type "'+type+'" not implemented.');
		}
		else if ( type == Xmldoom.Criteria.BETWEEN )
		{
			comparison_node.setAttribute('min', value[0]);
			comparison_node.setAttribute('max', value[1]);
		}
		else
		{
			if ( dojo.lang.isObject(value) )
			{
				var object_node = this.doc.createElement('object');
				for( var attr in value )
				{
					object_node.setAttribute(attr, value[attr]);
				}
				comparison_node.appendChild( object_node );
			}
			else
			{
				// add the text to the comparison.
				comparison_node.appendChild( this.doc.createTextNode(value) );
			}
		}
		property_node.appendChild( comparison_node );
	},

	get: function ()
	{
		var ret = Array();
		var node, i, name, type, value;

		for(i = 0; i < this.getNode().childNodes.length; i++ )
		{
			node = this.getNode().childNodes.item(i);
			
			if ( node.tagName == 'property' )
			{
				type = node.firstChild.tagName;
				if ( type == Xmldoom.Criteria.BETWEEN )
				{
					value = [
						node.firstChild.getAttribute('min'),
						node.firstChild.getAttribute('max')
					];
				}
				else
				{
					if ( (type == Xmldoom.Criteria.EQUAL || 
					      type == Xmldoom.Criteria.NOT_EQUAL) &&
						 node.firstChild.firstChild.nodeType == dojo.dom.ELEMENT_NODE )
					{
						var obj_node  = node.firstChild.firstChild;

						value = { };
						
						for( var e = 0; e < obj_node.attributes.length; e++ )
						{
							var attr = obj_node.attributes.item(e);
							value[attr.name] = attr.value;
						}
					}
					else
					{
						value = node.firstChild.firstChild.text;
					}
				}

				ret[ret.length] = {
					'prop':  node.getAttribute('name'),
					'comp':  type,
					'value': value
				};
			}
		}

		return ret;
	}
});

