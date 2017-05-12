package XML::DOMBacked;

use strict;
use warnings;
use XML::LibXML;
use LWP::UserAgent;

no warnings 'redefine';

our $VERSION = '1.00';
our $NSMAP  = {};

use overload
  'eq' => 'check_equality',
  '==' => 'check_equality',
  fallback => 1;

sub check_equality {
  my $lhs = shift;
  my $rhs = shift;
  $lhs->dom->isSameNode( $rhs->dom );
}

sub new {
  my $class = shift;
  my $self  = {};
  bless $self => $class;
  my $init  = eval { $self->init( @_ ) };
  if (!$init) {
    my $mesg = "could not initialise object";
    if ( $@ ) { $mesg .= ': ' . $@ }
    die $mesg;
  }
  return $self;
}

sub from_uri {
  my $class = shift;
  my $uri   = shift;
  if (!$uri) {
    die "need to have URI to load";
  }
  my $ua    = LWP::UserAgent->new;
  my $r = $ua->get( $uri );
  if ( !$r->is_success ) {
    die "load failed: " . $r->status_line;
  }
  my $doc = XML::LibXML->new->parse_string( $r->content );
  $class->new->dom( $doc->documentElement );
}


sub init {
  my $self = shift;
  $self->dom( XML::LibXML::Element->new( $self->nodename ) );
  XML::LibXML::Document->new('1.0','UTF-8')->addChild( $self->dom );
  return "init_call_passed";
}

sub nodename {
  my $self = shift;
  my $class = ref( $self ) || $self;
  if ( $class =~ /:/ ) {
    ## we just want to xmlify the last bit
    return lc( substr($class, rindex( $class, ':') + 1 ) );
  }
  return lc( $class );
}

sub dom {
  my $self = shift;
  if ( @_ ) {
    $self->{ dom } = shift;
    return $self;
  }
  return $self->{ dom };
}

sub has_many {
  my $class = shift;
  my $pairs = { @_ };
  foreach my $key ( keys %$pairs ) {
    if ( ref( $pairs->{ $key } ) ) {
      ## this is a complicated multivalue thing
      $class->setup_has_many_complex( $key, $pairs->{ $key }->{class} );
    } else {
      ## this is a simple multivalue thing.
      ## What am I talking about they're _all_ complicated multivalue things!
      $class->setup_has_many_simple( $key, $pairs->{ $key } );
    }
  }
}

sub setup_has_many_complex {
  my $class = shift;
  my $key   = shift;
  my $val   = shift;
  my $name  = $val->nodename;
  if ( $name =~ /:/ ) {
    my ($ns, $attr) = split(/:/, $name);
    $name = $attr;
  }
#  print "Creating thing: $name\n";
  no strict 'refs';
  *{$class.'::add_'.$name} = sub {
    my $self = shift;
    my $obj  = shift;
    $self->dom->addChild( $obj->dom );
  };
  *{$class.'::'.$key} = sub {
    my $self = shift;
    map { bless( { dom => $_ }, $val ) } $self->dom->getChildrenByTagName( $val->nodename )
  };
  *{$class.'::remove_'.$name} = sub {
    my $self = shift;
    my $obj  = shift;
    $self->dom->removeChild( $obj->dom );
  }
}

sub setup_has_many_simple {
  my $class = shift;
  my $key   = shift;
  my $val   = shift;
  my $name  = $val;
  if ( $val =~ /:/ ) {
    my ($ns, $attr) = split(/:/, $val);
    if (!$class->lookup_namespace( $ns )) {
      die "can't create a property with unknown namespace ($ns)";
    }
    $name = $attr;
  }
  no strict 'refs';
  *{$class .'::add_'. $name} = sub {
    my $self = shift;
    my $data = shift;
    my $elem = XML::LibXML::Element->new( $val );
    $elem->appendText( $data );
    $self->dom->addChild( $elem );
  };
  *{$class .'::'.$key} = sub {
    my $self = shift;
    map { $_->findvalue('.') } $self->dom->getChildrenByTagName($val);
  };
  *{$class .'::remove_'.$name} = sub {
    my $self = shift;
    my $data = shift;
    my @list = grep { $_->findvalue('.') eq $data } $self->dom->getChildrenByTagName( $val );
    $self->dom->removeChild( $_ ) for @list;
    1;
  };
}

sub has_a {
  my $class = shift;
  foreach my $key ( @_ ) {
    if ( $key->nodename =~ /:/ ) {
      ## we're in magic namespace land
      my ($ns, $rkey) = split(/:/, $key->nodename);
      my $uri = $class->lookup_namespace( $ns );
      if (!$uri) {
	die "can't create a property in an unknown namespace( $ns )";
      }
      no strict 'refs';
      *{ $class . '::' . $rkey } = sub {
	my $self = shift;
	if ( @_ ) {
	  $self->set_dom_object( $key, @_ );
	  return $self;
	}
	return $self->get_dom_object( $key );
      };
    } else {
      no strict 'refs';
#      print "Creating in class $key\n";
      *{ $class . '::' . $key } = sub {
	my $self = shift;
	if ( @_ ) {
	  $self->set_dom_object( $key, @_ );
	  return $self;
	}
	return $self->get_dom_object( $key  );
      };
    }
  }
}

sub get_dom_object {
  my $self = shift;
  my $prop  = shift;
  my $elem  = $self->get_property_object( $prop->nodename );
  my $thing = bless( { dom => $elem }, $prop );
  return $thing;
}

sub set_dom_object {
  my $self = shift;
  my $prop = shift;
  my $val  = shift;

#  print "Setting dom object\n";
#  print $val->as_string;

  foreach my $ns ( $val->dom->getNamespaces ) {
    my $prefix = $ns->name;
    my $uri    = $ns->getNamespaceURI;
    $self->dom->setNamespace( $uri, $prefix, 0 );
  }
  $self->dom->addChild( $val->dom );
}

sub has_attributes {
  my $class = shift;
  foreach my $attribute ( @_ ) {
    if ( $attribute =~ /:/ ) {
      ## has a namespace attached
      my ($ns,$rattr) = split(/:/, $attribute);
      my $uri = $class->lookup_namespace( $ns );
#      if (! $uri ) {
#	die "can't create an attribute for an unknown namespace ($ns)";
#      }
      no strict 'refs';
      *{ $class . '::' . $rattr } = sub {
	my $self = shift;
	if ( @_ ) {
	  $self->set_dom_attribute( $attribute, @_ );
	  return $self;
	}
	return $self->get_dom_attribute( $attribute );
      };
    } else {
      ## straightforward attribute.
      no strict 'refs';
      *{ $class . '::' . $attribute } = sub {
	my $self = shift;
	if ( @_ ) {
	  $self->set_dom_attribute( $attribute, @_ );
	  return $self;
	}
	return $self->get_dom_attribute( $attribute );
      }
    }
  }
}

sub has_properties {
  my $class = shift;
  foreach my $property ( @_ ) {
    if ( $property =~ /:/ ) {
      ## this has a namespace attached
      my ($ns, $realprop) = split(/:/, $property);
      my $uri = $class->lookup_namespace( $ns );
      if ( ! $uri ) {
	die "can't create a property for an unknown namespace";
      }
      no strict 'refs';
      *{ $class . '::' . $realprop } = sub {
	my $self = shift;
	if (@_) {
	  $self->set_dom_property( $property, @_ );
	  return $self;
	}
	return $self->get_dom_property( $property );
      };
    } else {
      ## this is in the default namespace
      no strict 'refs';
      *{ $class . '::' . $property } = sub {
	my $self = shift;
	if (@_) {
	  $self->set_dom_property( $property, @_ );
	  return $self;
	}
	return $self->get_dom_property( $property );
      };
    }
  }
}

sub set_dom_attribute {
  my $self = shift;
  my $prop = shift;
  my $val  = shift;
  if ( $prop =~ /:/ ) {
    my ($ns, $realprop) = split(/:/, $prop);
    my $uri = $self->lookup_namespace( $ns ) || '';
    if ( !$self->dom->lookupNamespaceURI( $ns ) ) {
      $self->dom->setNamespace( $uri, $ns, 0 );
    } else {
      $uri = $self->dom->lookupNamespaceURI( $ns );
    }
    $self->dom->setAttributeNS( $uri, $realprop, $val );
  } else {
    $self->dom->setAttribute( $prop, $val );
  }
}

sub get_dom_attribute {
  my $self = shift;
  my $prop = shift;
  if ( $prop =~ /:/ ) {
    my ($ns, $propname) = split(/:/, $prop);
    my $uri = $self->lookup_namespace( $ns );
    if ( $self->dom->hasAttributeNS( $self->lookup_namespace( $ns ), $propname ) ) {
      my $val  = $self->dom->getAttributeNS( $uri, $propname );
      return $val
    } else {
      die "no such property $prop";
    }
  } else {
    return $self->dom->getAttribute( $prop );
  }
}

sub get_dom_property {
  my $self = shift;
  my $prop = shift;
  my $elem = $self->get_property_object( $prop );
  return $elem->findvalue( '.' );
}

sub set_dom_property {
  my $self = shift;
  my $prop = shift;
  my $data = shift;
  my $elem = $self->get_property_object( $prop );
  my $text = XML::LibXML::Text->new( $data );
  if ( $elem->hasChildNodes() ) {
    $elem->removeChild( $elem->firstChild );
  }
  $elem->addChild( $text );
}

sub get_property_object {
  my $self = shift;
  my $prop = shift;

  if ( $prop =~ /:/ ) {
    my ($ns, $rprop) = split(/:/, $prop);
    my $uri = $self->lookup_namespace( $ns );
    if ( !$self->dom->lookupNamespacePrefix( $uri ) ) {
      $self->dom->setNamespace( $uri, $ns, 1 );
    }
    my $node = ($self->dom->getChildrenByTagNameNS( $uri, $rprop ))[0];
    if (!$node) {
      $node = $self->dom->addNewChild( $uri, $rprop );
    }
    return $node;

  } else {
    my $node = ($self->dom->getChildrenByTagName($prop))[0];
    if (! $node ) {
      $node = XML::LibXML::Element->new( $prop );
      $self->dom->addChild( $node );
    }
    return $node;

  }
}

sub lookup_namespace {
  my $self = shift;
  my $ns   = shift;
  if (!$ns) {
    die "need an namespace parameter";
  }
  my $class = ref( $self ) || $self;
  if ( exists $NSMAP->{ $class }->{namespaces}->{ $ns } ) {
    ## it belongs to this class, which makes life eeee-zeee!
    return $NSMAP->{$class}->{namespaces}->{ $ns };
  } else {
    ## we're in the land of recursion, la la la la lah!
    ## first we get the IS-A var.
    no strict 'refs';
    my @isa = @{ $class . '::ISA' };
    use strict 'refs';
    my $uri;

    ## loop through it until we get an answer
    foreach my $isa ( @isa ) {
      my $result = eval { $isa->lookup_namespace( $ns ) };
      if ( $result ) {
	$uri = $result;
	last;
      }
    }

    if ( !exists $NSMAP->{ $class }->{ namespaces }->{ $ns } ) {
      $NSMAP->{ $class }->{ namespaces }->{ $ns } = $uri;
    }

    return $uri;
  }
  return 0;
}

sub uses_namespace {
  my $class = shift;
  my $pairs = { @_ };
  foreach my $key (keys %$pairs) {
    my $ns   = $key;
    my $uri  = $pairs->{$key};
    $NSMAP->{$class}->{ namespaces }->{ $ns } = $uri;
  }
}

sub as_string {
  my $self = shift;
  return $self->dom->toString( 1 );
}

sub as_xml {
  my $self = shift;
  my $doc  = XML::LibXML::Document->new('1.0', 'UTF-8');
  $doc->setDocumentElement( $self->dom );
  return $doc->toString( 1 );
}

1;

=head1 NAME

XML::DOMBacked - objects backed by a DOM

=head1 SYNOPSIS

  package Person;

  use base 'XML::DOMBacked';

  Person->uses_namespace(
                         'foaf' => 'http://xmlns.com/foaf/0.1/',
                         'rdf'  => 'http://www.w3.org/1999/02/22-rdf-syntax-ns#',
                        );
  Person->has_properties( 'foaf:name','foaf:title','foaf:nick' );
  Person->has_attributes( 'rdf:nodeID' );
  Person->has_a( 'Person::Knows' );

  sub nodename { "foaf:Person" }

  package Person::Knows;

  use base 'XML::DOMBacked';

  Person::Knows->has_many( people => { class => 'Person' } );

  package main;

  my $p = Person->new;
  $p->nodeID("me");
  $p->name('A. N. Other');
  $p->title('Mr');
  $p->nick('another');

  my $a = Person->new;
  $a->name('Yet Another');

  $p->Knows->add_Person( $a );
  print $p->as_xml;

  $p = Person->from_uri( 'file:person.xml' );

=head1 DESCRIPTION

The C<XML::DOMBacked> class lets you back an object on an XML DOM.  Think of it as Class::DBI
for XML files. You can specifiy things you want to be properties (nodes), attributes, and
other objects.  XML::DOMBacked takes care of the heavy lifting so that you don't have to.

=head1 CONSTRUCTORS

=over 4

=item new()

Constructs a new object.

=item from_uri()

Loads an object from a URI.  Expects XML at the other end.

=back

=head1 METHODS

=over 4

=item uses_namespace( prefix => uri )

Adds an XML namespace to the object.

=item has_properties( ARRAY )

Adds XML Elements to the object.  These become accessors.

=item has_attributes( ARRAY )

Adds XML Attributes to the object. These become accessors.

=item has_a( ARRAY )

Adds 1..1 relationships with other classes to the object.  The other classes
must also inherit from XML::DOMBacked.

=item has_many( PLURAL => SINGULAR )

Adds add_SINGULAR, remove_SINGLUAR and PLURAL methods to the class.

=item has_many( PLURAL => { class => CLASS } )

Looks up the NODENAME for the class, then creates add_NODENAME, remove_NODENAME, and PLURAL methods to the class.

=back

=head1 BUGS

Probably loads.  This is really funky, crazy code.  I'd be surprised if there aren't bugs.

=head1 AUTHOR

James A. Duncan <jduncan@fotango.com>

=head1 COPYRIGHT

Copyright 2005 Fotango Ltd. All Rights Reserved.

=cut
