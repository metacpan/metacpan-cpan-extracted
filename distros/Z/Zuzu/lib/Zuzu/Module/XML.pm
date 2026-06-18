package Zuzu::Module::XML;

use utf8;

our $VERSION = '0.005000';

use Scalar::Util qw( blessed );
use Encode qw( decode encode FB_CROAK );
use HTML::Selector::XPath ();
use XML::LibXML ();
use Zuzu::Error;

use Zuzu::Util::NativeHelpers qw(
	native_class
	native_function
	native_object
	perl_to_zuzu
);

sub _is_zuzu_object {
	my ( $value ) = @_;

	return blessed($value)
		and $value->isa('Zuzu::Value::Object');
}

sub _xml_text {
	my ( $value ) = @_;
	$value = defined $value ? "$value" : '';
	$value = decode( 'UTF-8', $value ) if not utf8::is_utf8($value);
	if ( $value =~ /[\x{00c2}-\x{00f4}][\x{0080}-\x{00bf}]/ ) {
		my $decoded = eval {
			decode( 'UTF-8', encode( 'ISO-8859-1', $value, FB_CROAK ), FB_CROAK );
		};
		return $decoded if defined $decoded;
	}
	return $value;
}

sub _xml_maybe_text {
	my ( $value ) = @_;
	return undef if not defined $value;
	return _xml_text($value);
}

sub _unwrap_node {
	my ( $value ) = @_;

	die "expected XMLNode object" if not _is_zuzu_object( $value );
	die "expected XMLNode object" if not exists $value->slots->{_node};

	return $value->slots->{_node};
}

sub _unwrap_doc {
	my ( $value ) = @_;

	die "expected XMLDocument object" if not _is_zuzu_object( $value );
	die "expected XMLDocument object" if not exists $value->slots->{_doc};

	return $value->slots->{_doc};
}

sub _unwrap_path_tiny {
	my ( $path_obj, $label ) = @_;
	$label //= 'XML';

	if (
		blessed($path_obj)
		and $path_obj->isa('Zuzu::Value::Object')
		and exists $path_obj->slots->{_path_tiny}
	) {
		return $path_obj->slots->{_path_tiny};
	}
	elsif ( ref($path_obj) eq 'HASH' and exists $path_obj->{_path_tiny} ) {
		return $path_obj->{_path_tiny};
	}

	die Zuzu::Error->new_runtime(
		message => "TypeException: $label expects Path as first argument",
		file => '<std/data/xml>',
		line => 0,
	);
}

sub _wrap_node {
	my ( $classes, $node ) = @_;

	return undef if not defined $node;
	my $node_class = _node_class_for( $classes, $node );

	return native_object(
		class => $node_class,
		slots => {
			_node => $node,
		},
		const => {
			_node => 1,
		},
	);
}

sub _wrap_doc {
	my ( $doc_class, $doc ) = @_;

	return undef if not defined $doc;

	return native_object(
		class => $doc_class,
		slots => {
			_doc => $doc,
		},
		const => {
			_doc => 1,
		},
	);
}

sub _bool {
	my ( $value ) = @_;

	return $value ? 1 : 0;
}

sub _node_list_to_zuzu {
	my ( $classes, @nodes ) = @_;

	my @wrapped = map {
		_wrap_node( $classes, $_ )
	} @nodes;

	return perl_to_zuzu( \@wrapped );
}

sub _selector_to_xpath {
	my ( $selector ) = @_;

	$selector = defined $selector ? "$selector" : '';
	my $xpath = HTML::Selector::XPath::selector_to_xpath( $selector );
	$xpath =~ s{(^|\|)\s*//}{$1.//}g;
	return $xpath;
}

sub _node_class_for {
	my ( $classes, $node ) = @_;

	return $classes->{DOMElement}
		if $node->isa('XML::LibXML::Element');
	return $classes->{DOMComment}
		if $node->isa('XML::LibXML::Comment');
	return $classes->{DOMText}
		if $node->isa('XML::LibXML::Text');
	return $classes->{DOMDocument}
		if $node->isa('XML::LibXML::Document');
	return $classes->{DOMNode};
}

sub _doc_from_node {
	my ( $node ) = @_;

	return undef if not defined $node;
	return $node if $node->isa('XML::LibXML::Document');
	return $node->ownerDocument;
}

sub _is_function {
	my ( $value ) = @_;

	return blessed($value)
		and $value->isa('Zuzu::Value::Function');
}

sub _truthy {
	my ( $value ) = @_;

	return 0 if not defined $value;
	return $value->is_truthy if blessed($value) and $value->can('is_truthy');
	return $value ? 1 : 0;
}

sub _visit_tree {
	my ( $classes, $runtime, $start_node, $visitor, $stop_on_match, $include_root ) = @_;

	die "expected function argument" if not _is_function( $visitor );

	my @stack;
	if ($include_root) {
		@stack = ( [ $start_node, 0 ] );
	}
	else {
		my @children = $start_node->childNodes;
		@stack = map { [ $_, 1 ] } reverse @children;
	}
	while ( @stack ) {
		my ( $node, $depth ) = @{ pop @stack };
		my $wrapped = _wrap_node( $classes, $node );
		my $result = $runtime->_call_function( $visitor, [ $wrapped ], '<std/data/xml>', 0 );
		if ( $stop_on_match and _truthy($result) ) {
			return $wrapped;
		}
		my @children = $node->childNodes;
		for my $child ( reverse @children ) {
			push @stack, [ $child, $depth + 1 ];
		}
	}

	return undef if $stop_on_match;
	return 1;
}

sub IMPORT {
	my ( $class, $runtime ) = @_;

	my $xml_class = native_class(
		name => 'XML',
	);
	my $doc_class = native_class(
		name => 'XMLDocument',
	);
	my $node_class = native_class(
		name => 'XMLNode',
	);
	my $dom_node_class = native_class(
		name => 'DOMNode',
		parent => $node_class,
	);
	my $dom_doc_class = native_class(
		name => 'DOMDocument',
		parent => $dom_node_class,
	);
	my $dom_element_class = native_class(
		name => 'DOMElement',
		parent => $dom_node_class,
	);
	my $dom_comment_class = native_class(
		name => 'DOMComment',
		parent => $dom_node_class,
	);
	my $dom_text_class = native_class(
		name => 'DOMText',
		parent => $dom_node_class,
	);
	my $node_classes = {
		DOMNode => $dom_node_class,
		DOMDocument => $dom_doc_class,
		DOMElement => $dom_element_class,
		DOMComment => $dom_comment_class,
		DOMText => $dom_text_class,
	};

	$xml_class->static_methods->{parse} = native_function(
		name => 'parse',
		native => sub {
			my ( $self, $xml_text ) = @_;
			$xml_text = _xml_text($xml_text);

			my $parser = XML::LibXML->new();
			my $doc = $parser->parse_string( $xml_text );
			return _wrap_doc( $doc_class, $doc );
		},
	);

	$xml_class->static_methods->{load} = native_function(
		name => 'load',
		native => sub {
			my ( $self, $path_obj ) = @_;
			$runtime->assert_capability( 'fs', "XML.load is denied by runtime policy" );
			my $path_tiny = _unwrap_path_tiny( $path_obj, 'XML.load' );
			my $xml_text = _xml_text($path_tiny->slurp_utf8);

			my $parser = XML::LibXML->new();
			my $doc = $parser->parse_string( $xml_text );
			return _wrap_doc( $doc_class, $doc );
		},
	);

	$xml_class->static_methods->{dump} = native_function(
		name => 'dump',
		native => sub {
			my ( $self, $path_obj, $value, $pretty ) = @_;
			$runtime->assert_capability( 'fs', "XML.dump is denied by runtime policy" );
			my $path_tiny = _unwrap_path_tiny( $path_obj, 'XML.dump' );
			my $xml_text;

			if (
				_is_zuzu_object( $value )
				and exists $value->slots->{_doc}
			) {
				$xml_text = $value->slots->{_doc}->toString( _bool( $pretty ) );
			}
			elsif (
				_is_zuzu_object( $value )
				and exists $value->slots->{_node}
			) {
				$xml_text = $value->slots->{_node}->toString( _bool( $pretty ) );
			}
			else {
				die "XML.dump expects an XMLDocument or XMLNode";
			}

			$path_tiny->spew_utf8( $xml_text );
			return $path_obj;
		},
	);

	$doc_class->methods->{documentElement} = native_function(
		name => 'documentElement',
		native => sub {
			my ( $self ) = @_;
			return _wrap_node( $node_classes, _unwrap_doc( $self )->documentElement );
		},
	);

	$doc_class->methods->{createElement} = native_function(
		name => 'createElement',
		native => sub {
			my ( $self, $name ) = @_;
			$name = defined $name ? "$name" : '';
			my $node = _unwrap_doc( $self )->createElement( $name );
			return _wrap_node( $node_classes, $node );
		},
	);

	$doc_class->methods->{createTextNode} = native_function(
		name => 'createTextNode',
		native => sub {
			my ( $self, $text ) = @_;
			$text = defined $text ? "$text" : '';
			my $node = _unwrap_doc( $self )->createTextNode( $text );
			return _wrap_node( $node_classes, $node );
		},
	);

	$doc_class->methods->{createComment} = native_function(
		name => 'createComment',
		native => sub {
			my ( $self, $text ) = @_;
			$text = defined $text ? "$text" : '';
			my $node = _unwrap_doc( $self )->createComment( $text );
			return _wrap_node( $node_classes, $node );
		},
	);

	$doc_class->methods->{createCDATASection} = native_function(
		name => 'createCDATASection',
		native => sub {
			my ( $self, $text ) = @_;
			$text = defined $text ? "$text" : '';
			my $node = _unwrap_doc( $self )->createCDATASection( $text );
			return _wrap_node( $node_classes, $node );
		},
	);

	$doc_class->methods->{findnodes} = native_function(
		name => 'findnodes',
		native => sub {
			my ( $self, $xpath ) = @_;
			$xpath = defined $xpath ? "$xpath" : '';
			my @nodes = _unwrap_doc( $self )->findnodes( $xpath );
			return _node_list_to_zuzu( $node_classes, @nodes );
		},
	);

	$doc_class->methods->{getElementsByTagName} = native_function(
		name => 'getElementsByTagName',
		native => sub {
			my ( $self, $name ) = @_;
			$name = defined $name ? "$name" : '*';
			my @nodes = _unwrap_doc( $self )->getElementsByTagName( $name );
			return _node_list_to_zuzu( $node_classes, @nodes );
		},
	);

	$doc_class->methods->{getElementById} = native_function(
		name => 'getElementById',
		native => sub {
			my ( $self, $id ) = @_;
			$id = defined $id ? "$id" : '';
			my $node = _unwrap_doc( $self )->getElementById( $id );
			return _wrap_node( $node_classes, $node );
		},
	);

	$doc_class->methods->{findvalue} = native_function(
		name => 'findvalue',
		native => sub {
			my ( $self, $xpath ) = @_;
			$xpath = defined $xpath ? "$xpath" : '';
			return "" . _unwrap_doc( $self )->findvalue( $xpath );
		},
	);

	for my $name ( qw( querySelectorAll querySelector ) ) {
		$doc_class->methods->{$name} = native_function(
			name => $name,
			native => sub {
				my ( $self, $selector ) = @_;
				my $xpath = _selector_to_xpath( $selector );
				my @nodes = _unwrap_doc( $self )->findnodes( $xpath );
				return _node_list_to_zuzu( $node_classes, @nodes )
					if $name eq 'querySelectorAll';
				return _wrap_node( $node_classes, $nodes[0] );
			},
		);
	}

	$doc_class->methods->{toXML} = native_function(
		name => 'toXML',
		native => sub {
			my ( $self, $pretty ) = @_;
			return _xml_text( _unwrap_doc( $self )->toString( _bool( $pretty ) ) );
		},
	);

	$doc_class->methods->{to_String} = native_function(
		name => 'to_String',
		native => sub {
			my ( $self ) = @_;
			return _xml_text( _unwrap_doc( $self )->toString(0) );
		},
	);

	$doc_class->methods->{visitEach} = native_function(
		name => 'visitEach',
		native => sub {
			my ( $self, $visitor ) = @_;
			_visit_tree( $node_classes, $runtime, _unwrap_doc( $self ), $visitor, 0, 1 );
			return $self;
		},
	);

	$doc_class->methods->{findFirst} = native_function(
		name => 'findFirst',
		native => sub {
			my ( $self, $matcher ) = @_;
			return _visit_tree( $node_classes, $runtime, _unwrap_doc( $self ), $matcher, 1, 0 );
		},
	);

	for my $name ( qw( nodeName nodeType nodeValue textContent ) ) {
		$node_class->methods->{$name} = native_function(
			name => $name,
			native => sub {
			my ( $self ) = @_;
			my $value = _unwrap_node( $self )->$name();
			return _xml_maybe_text($value);
		},
	);
	}

	$node_class->methods->{uniqueKey} = native_function(
		name => 'uniqueKey',
		native => sub {
			my ( $self ) = @_;
			my $node = _unwrap_node( $self );
			my $value = $node->can('unique_key')
				? $node->unique_key()
				: undef;
			return defined $value ? "$value" : undef;
		},
	);

	$node_class->methods->{unique_id} = native_function(
		name => 'unique_id',
		native => sub {
			my ( $self ) = @_;
			my $node = _unwrap_node( $self );
			my $value = $node->can('unique_key')
				? $node->unique_key()
				: undef;
			return defined $value ? "$value" : undef;
		},
	);

	$node_class->methods->{localName} = native_function(
		name => 'localName',
		native => sub {
			my ( $self ) = @_;
			my $node = _unwrap_node( $self );
			my $value;
			if ( $node->can('localName') ) {
				$value = $node->localName();
			}
			elsif ( $node->can('localname') ) {
				$value = $node->localname();
			}
			return _xml_maybe_text($value);
		},
	);

	$node_class->methods->{namespaceURI} = native_function(
		name => 'namespaceURI',
		native => sub {
			my ( $self ) = @_;
			my $node = _unwrap_node( $self );
			return undef if not $node->can('namespaceURI');
			my $value = $node->namespaceURI();
			return _xml_maybe_text($value);
		},
	);

	$node_class->methods->{nodeKind} = native_function(
		name => 'nodeKind',
		native => sub {
			my ( $self ) = @_;
			my $type = _unwrap_node( $self )->nodeType;
			return 'element' if $type == 1;
			return 'text' if $type == 3;
			return 'comment' if $type == 8;
			return 'document' if $type == 9;
			return 'other';
		},
	);

	$node_class->methods->{setNodeValue} = native_function(
		name => 'setNodeValue',
		native => sub {
			my ( $self, $value ) = @_;
			$value = defined $value ? "$value" : '';
			_unwrap_node( $self )->setNodeValue( $value );
			return $self;
		},
	);

	$node_class->methods->{setTextContent} = native_function(
		name => 'setTextContent',
		native => sub {
			my ( $self, $value ) = @_;
			$value = defined $value ? "$value" : '';
			my $node = _unwrap_node( $self );
			if ( $node->can('setTextContent') ) {
				$node->setTextContent( $value );
			}
			elsif ( $node->can('removeChildNodes') and $node->can('appendText') ) {
				$node->removeChildNodes();
				$node->appendText( $value );
			}
			else {
				die "setTextContent not supported by this node type";
			}
			return $self;
		},
	);

	for my $name ( qw( firstChild lastChild nextSibling previousSibling parentNode ) ) {
		$node_class->methods->{$name} = native_function(
			name => $name,
			native => sub {
				my ( $self ) = @_;
				return _wrap_node( $node_classes, _unwrap_node( $self )->$name() );
			},
		);
	}

	$node_class->methods->{ownerDocument} = native_function(
		name => 'ownerDocument',
		native => sub {
			my ( $self ) = @_;
			my $doc = _doc_from_node( _unwrap_node( $self ) );
			return _wrap_doc( $doc_class, $doc );
		},
	);

	$node_class->methods->{childNodes} = native_function(
		name => 'childNodes',
		native => sub {
			my ( $self ) = @_;
			my @children = _unwrap_node( $self )->childNodes();
			return _node_list_to_zuzu( $node_classes, @children );
		},
	);

	$node_class->methods->{children} = native_function(
		name => 'children',
		native => sub {
			my ( $self ) = @_;
			my @children = grep { $_->nodeType == 1 } _unwrap_node( $self )->childNodes();
			return _node_list_to_zuzu( $node_classes, @children );
		},
	);

	$node_class->methods->{hasChildNodes} = native_function(
		name => 'hasChildNodes',
		native => sub {
			my ( $self ) = @_;
			return _bool( _unwrap_node( $self )->hasChildNodes );
		},
	);

	$node_class->methods->{normalize} = native_function(
		name => 'normalize',
		native => sub {
			my ( $self ) = @_;
			_unwrap_node( $self )->normalize();
			return $self;
		},
	);

	$node_class->methods->{appendChild} = native_function(
		name => 'appendChild',
		native => sub {
			my ( $self, $child_obj ) = @_;
			my $child = _unwrap_node( $child_obj );
			my $added = _unwrap_node( $self )->appendChild( $child );
			return _wrap_node( $node_classes, $added );
		},
	);

	$node_class->methods->{prependChild} = native_function(
		name => 'prependChild',
		native => sub {
			my ( $self, $child_obj ) = @_;
			my $parent = _unwrap_node( $self );
			my $child = _unwrap_node( $child_obj );
			my $first = $parent->firstChild;
			if ( defined $first ) {
				$parent->insertBefore( $child, $first );
			}
			else {
				$parent->appendChild( $child );
			}
			return _wrap_node( $node_classes, $child );
		},
	);

	$node_class->methods->{insertBefore} = native_function(
		name => 'insertBefore',
		native => sub {
			my ( $self, $new_node, $ref_node ) = @_;
			my $inserted = _unwrap_node( $self )->insertBefore(
				_unwrap_node( $new_node ),
				_unwrap_node( $ref_node ),
			);
			return _wrap_node( $node_classes, $inserted );
		},
	);

	$node_class->methods->{replaceChild} = native_function(
		name => 'replaceChild',
		native => sub {
			my ( $self, $new_node, $old_node ) = @_;
			my $replaced = _unwrap_node( $self )->replaceChild(
				_unwrap_node( $new_node ),
				_unwrap_node( $old_node ),
			);
			return _wrap_node( $node_classes, $replaced );
		},
	);

	$node_class->methods->{removeChild} = native_function(
		name => 'removeChild',
		native => sub {
			my ( $self, $child_obj ) = @_;
			my $removed = _unwrap_node( $self )->removeChild(
				_unwrap_node( $child_obj ),
			);
			return _wrap_node( $node_classes, $removed );
		},
	);

	$node_class->methods->{remove} = native_function(
		name => 'remove',
		native => sub {
			my ( $self ) = @_;
			my $node = _unwrap_node( $self );
			my $parent = $node->parentNode;
			if ( defined $parent ) {
				$parent->removeChild( $node );
			}
			return $self;
		},
	);

	$node_class->methods->{cloneNode} = native_function(
		name => 'cloneNode',
		native => sub {
			my ( $self, $deep ) = @_;
			my $clone = _unwrap_node( $self )->cloneNode( _bool( $deep ) );
			return _wrap_node( $node_classes, $clone );
		},
	);

	$node_class->methods->{isSameNode} = native_function(
		name => 'isSameNode',
		native => sub {
			my ( $self, $other_obj ) = @_;
			my $self_node = _unwrap_node( $self );
			my $other_node = _unwrap_node( $other_obj );
			return _bool( $self_node->isSameNode( $other_node ) );
		},
	);

	$node_class->methods->{isEqualNode} = native_function(
		name => 'isEqualNode',
		native => sub {
			my ( $self, $other_obj ) = @_;
			my $self_node = _unwrap_node( $self );
			my $other_node = _unwrap_node( $other_obj );
			return _bool( $self_node->isEqual( $other_node ) );
		},
	);

	$node_class->methods->{contains} = native_function(
		name => 'contains',
		native => sub {
			my ( $self, $other_obj ) = @_;
			my $self_node = _unwrap_node( $self );
			my $other = _unwrap_node( $other_obj );
			return 1 if $self_node->isSameNode( $other );
			my $cursor = $other->parentNode;
			while ( defined $cursor ) {
				return 1 if $self_node->isSameNode( $cursor );
				$cursor = $cursor->parentNode;
			}
			return 0;
		},
	);

	for my $name ( qw( findnodes findvalue ) ) {
		$node_class->methods->{$name} = native_function(
			name => $name,
			native => sub {
				my ( $self, $xpath ) = @_;
				$xpath = defined $xpath ? "$xpath" : '';
				if ( $name eq 'findnodes' ) {
					my @nodes = _unwrap_node( $self )->findnodes( $xpath );
					return _node_list_to_zuzu( $node_classes, @nodes );
				}
				return "" . _unwrap_node( $self )->findvalue( $xpath );
			},
		);
	}

	for my $name ( qw( querySelectorAll querySelector ) ) {
		$node_class->methods->{$name} = native_function(
			name => $name,
			native => sub {
				my ( $self, $selector ) = @_;
				my $xpath = _selector_to_xpath( $selector );
				my @nodes = _unwrap_node( $self )->findnodes( $xpath );
				return _node_list_to_zuzu( $node_classes, @nodes )
					if $name eq 'querySelectorAll';
				return _wrap_node( $node_classes, $nodes[0] );
			},
		);
	}

	$node_class->methods->{visitEach} = native_function(
		name => 'visitEach',
		native => sub {
			my ( $self, $visitor ) = @_;
			_visit_tree( $node_classes, $runtime, _unwrap_node( $self ), $visitor, 0, 1 );
			return $self;
		},
	);

	$node_class->methods->{findFirst} = native_function(
		name => 'findFirst',
		native => sub {
			my ( $self, $matcher ) = @_;
			return _visit_tree( $node_classes, $runtime, _unwrap_node( $self ), $matcher, 1, 0 );
		},
	);

	$node_class->methods->{getAttribute} = native_function(
		name => 'getAttribute',
		native => sub {
			my ( $self, $name ) = @_;
			$name = defined $name ? "$name" : '';
			my $node = _unwrap_node( $self );
			return undef if not $node->can('getAttribute');
			my $value = $node->getAttribute( $name );
			return _xml_maybe_text($value);
		},
	);

	$node_class->methods->{setAttribute} = native_function(
		name => 'setAttribute',
		native => sub {
			my ( $self, $name, $value ) = @_;
			$name = defined $name ? "$name" : '';
			$value = defined $value ? "$value" : '';
			my $node = _unwrap_node( $self );
			die "setAttribute not supported by this node type"
				if not $node->can('setAttribute');
			$node->setAttribute( $name, $value );
			return $self;
		},
	);

	$node_class->methods->{hasAttribute} = native_function(
		name => 'hasAttribute',
		native => sub {
			my ( $self, $name ) = @_;
			$name = defined $name ? "$name" : '';
			my $node = _unwrap_node( $self );
			return 0 if not $node->can('hasAttribute');
			return _bool( $node->hasAttribute( $name ) );
		},
	);

	$node_class->methods->{removeAttribute} = native_function(
		name => 'removeAttribute',
		native => sub {
			my ( $self, $name ) = @_;
			$name = defined $name ? "$name" : '';
			my $node = _unwrap_node( $self );
			die "removeAttribute not supported by this node type"
				if not $node->can('removeAttribute');
			$node->removeAttribute( $name );
			return $self;
		},
	);

	$node_class->methods->{attributeNames} = native_function(
		name => 'attributeNames',
		native => sub {
			my ( $self ) = @_;
			my $node = _unwrap_node( $self );
			return perl_to_zuzu( [] ) if not $node->can('attributes');
			my @names;
			for my $attr ( $node->attributes ) {
				push @names, $attr->nodeName;
			}
			return perl_to_zuzu( \@names );
		},
	);

	$node_class->methods->{attributes} = native_function(
		name => 'attributes',
		native => sub {
			my ( $self ) = @_;
			my $node = _unwrap_node( $self );
			return perl_to_zuzu( [] ) if not $node->can('attributes');
			my @attrs = $node->attributes;
			return _node_list_to_zuzu( $node_classes, @attrs );
		},
	);

	$node_class->methods->{toXML} = native_function(
		name => 'toXML',
		native => sub {
			my ( $self, $pretty ) = @_;
			return _xml_text( _unwrap_node( $self )->toString( _bool( $pretty ) ) );
		},
	);

	$node_class->methods->{to_String} = native_function(
		name => 'to_String',
		native => sub {
			my ( $self ) = @_;
			return _xml_text( _unwrap_node( $self )->toString(0) );
		},
	);

	$dom_element_class->methods->{tagName} = native_function(
		name => 'tagName',
		native => sub {
			my ( $self ) = @_;
			return "" . _unwrap_node( $self )->nodeName;
		},
	);

	$dom_element_class->methods->{id} = native_function(
		name => 'id',
		native => sub {
			my ( $self ) = @_;
			my $value = _unwrap_node( $self )->getAttribute('id');
			return _xml_maybe_text($value);
		},
	);

	$dom_element_class->methods->{setId} = native_function(
		name => 'setId',
		native => sub {
			my ( $self, $id ) = @_;
			$id = defined $id ? "$id" : '';
			_unwrap_node( $self )->setAttribute( 'id', $id );
			return $self;
		},
	);

	$dom_element_class->methods->{getElementsByTagName} = native_function(
		name => 'getElementsByTagName',
		native => sub {
			my ( $self, $name ) = @_;
			$name = defined $name ? "$name" : '*';
			my @nodes = _unwrap_node( $self )->getElementsByTagName( $name );
			return _node_list_to_zuzu( $node_classes, @nodes );
		},
	);

	for my $class ( $dom_text_class, $dom_comment_class ) {
		$class->methods->{data} = native_function(
			name => 'data',
			native => sub {
				my ( $self ) = @_;
				return "" . _unwrap_node( $self )->data;
			},
		);

		$class->methods->{setData} = native_function(
			name => 'setData',
			native => sub {
				my ( $self, $value ) = @_;
				$value = defined $value ? "$value" : '';
				_unwrap_node( $self )->setData( $value );
				return $self;
			},
		);
	}

	return {
		XML => $xml_class,
		XMLDocument => $doc_class,
		XMLNode => $node_class,
		DOMNode => $dom_node_class,
		DOMDocument => $dom_doc_class,
		DOMElement => $dom_element_class,
		DOMComment => $dom_comment_class,
		DOMText => $dom_text_class,
	};
}

1;

=pod

=head1 NAME

Zuzu::Module::XML - C<std/data/xml> bindings for ZuzuScript.

=head1 DESCRIPTION

Implements XML DOM parsing and manipulation for C<std/data/xml>, backed by
C<XML::LibXML>.

Exports classes C<XML>, C<XMLDocument>, and C<XMLNode>.

=head1 COPYRIGHT AND LICENCE

B<< Zuzu::Module::XML >> is copyright Toby Inkster.

It is free software; you may redistribute it and/or modify it under
the terms of either the Artistic License 1.0 or the GNU General Public
License version 2.

=cut
