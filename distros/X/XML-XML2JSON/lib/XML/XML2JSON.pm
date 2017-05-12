package XML::XML2JSON;
use strict;
our $VERSION = '0.06';

use Carp;
use XML::LibXML;

our $XMLPARSER ||= XML::LibXML->new();

=head1 NAME

XML::XML2JSON - Convert XML into JSON (and back again) using XML::LibXML

=head1 SYNOPSIS

	use XML::XML2JSON;
	
	my $XML = '<test><element foo="bar"/></test>';
	
	my $XML2JSON = XML::XML2JSON->new();
	
	my $JSON = $XML2JSON->convert($XML);
	
	print $JSON;
	
	my $RestoredXML = $XML2JSON->json2xml($JSON);

=head1 DESCRIPTION

I used Google for inspiration: http://code.google.com/apis/gdata/json.html

In short:

=over 4

=item * The response is represented as a JSON object; each nested element or attribute is represented as a name/value property of the object.

=item * Attributes are converted to String properties.

=item * Attribute names are prefixed with "@" so that they dont conflict with child elements of the same name.

=item * Child elements are converted to Object properties.

=item * Text values of tags are converted to $t properties.

=back

Namespace

=over 4

=item * If an element has a namespace alias, the alias and element are concatenated using "$". For example, ns:element becomes ns$element.

=back

XML

=over 4

=item * XML version and encoding attributes are converted to attribute version and encoding of the root element, respectively.

=back

=cut

=head1 METHODS

=head2 new

Creates a new XML::XML2JSON object.

It supports the following arguments:

=head3 module

This is the JSON module that you want to use. 
By default it will use the first one it finds, in the following order: JSON::Syck, JSON::XS, JSON, JSON::DWIW

=head3 private_elements

An arraryref of element names that should be removed after calling the sanitize method.
Children of the elements will be removed as well.

=head3 empty_elements

An arrayref of element names that should have their attributes and text content
removed after calling the sanitize method. This leaves any children of the elements intact.

=head3 private_attributes

An arrayref of attribute names that should be removed after calling the sanitize method.

=head3 attribute_prefix

All attributes will be prefixed by this when converting to JSON. This is "@" by default.
You can set this to "", but if you do, any attributes that conflict with a child element name will be lost.

=head3 content_key

This is the name of the hash key that text content will be added to. This is "$t" by default.

=head3 force_array

If set to true, child elements that appear only once will be added to a one element array.
If set to false, child elements that appear only once will be assesible as a hash value.

The default is false.

=head3 pretty

If set to true, output will be formatted to be easier to read whenever possible.

=head3 debug

If set to true, will print warn messages to describe what it is doing.

=cut

sub new
{
	my $Class = shift;
	my $Self  = {};
	bless $Self, $Class;
	$Self->_init(@_);
	return $Self;
}

sub _init
{
	my $Self = shift;
	my %Args = @_;

	#
	# load JSON module
	#

	my @Modules = qw(JSON::Syck JSON::XS JSON JSON::DWIW);

	if ( $Args{module} )
	{
		my $OK = 0;
		foreach my $Module ( @Modules )
		{
			$OK = 1 if $Module eq $Args{module};
		}
		croak "Unsupported module: $Args{module}" unless $OK;
		@Modules = ( $Args{module} );
	}

	$Self->{_loaded_module} = "";

	foreach my $Module ( @Modules )
	{
		eval "use $Module (); 1;";
		unless ($@)
		{
			$Self->{_loaded_module} = $Module;
			last;
		}
	}

	croak "Cannot find a suitable JSON module" unless $Self->{_loaded_module};

    warn "loaded module: $Self->{_loaded_module}";

	# force arrays (this turns off array folding)
	$Self->{force_array} = $Args{force_array} ? 1 : 0;

	# use pretty printing when possible
	$Self->{pretty} = $Args{pretty} ? 1 : 0;

	# debug mode
	$Self->{debug} = $Args{debug} ? 1 : 0;

	# names
	$Self->{attribute_prefix} = defined $Args{attribute_prefix} ? $Args{attribute_prefix} : '@';
	$Self->{content_key}      = defined $Args{content_key}      ? $Args{content_key}      : '$t';
	
	#
	# sanitize options
	#
	# private_elements
	$Self->{private_elements} = {};
	if ($Args{private_elements})
	{
		foreach my $private_element ( @{$Args{private_elements}} )
		{
			# this must account for the ":" to "$" switch
			$private_element =~ s/([^^])\:/$1\$/;
			$Self->{private_elements}->{$private_element} = 1;
		}
	}
	# empty_elements
	$Self->{empty_elements} = {};
	if ($Args{empty_elements})
	{
		foreach my $empty_element ( @{$Args{empty_elements}} )
		{
			# this must account for the ":" to "$" switch
			$empty_element =~ s/([^^])\:/$1\$/;
			$Self->{empty_elements}->{$empty_element} = 1;
		}
	}
	# private_attributes
	$Self->{private_attributes} = {};
	if ($Args{private_attributes})
	{
		foreach my $private_attribute ( @{$Args{private_attributes}} )
		{
			# this must account for the attribute_prefix
			$Self->{private_attributes}->{ $Self->{attribute_prefix} . $private_attribute } = 1;
		}
	}
	
	return;
}

=head2 convert

Takes an XML string as input.
Returns a string of sanitized JSON.

Calling this method is the same as:

	my $Obj = $XML2JSON->xml2obj($XML);
	$XML2JSON->sanitize($Obj);
	my $JSON = $XML2JSON->obj2json($Obj);

=cut

sub convert
{
	my ( $Self, $XML ) = @_;

	my $Obj = $Self->xml2obj($XML);

	if ( %{ $Self->{private_elements} } || %{ $Self->{empty_elements} } || %{ $Self->{private_attributes} } )
	{
		$Self->sanitize($Obj);
	}

	my $JSON = $Self->obj2json($Obj);

	return $JSON;
}

=head2 xml2json

This is an alias for convert.

=cut

sub xml2json
{
	my ( $Self, $XML ) = @_;

	my $JSON = $Self->convert($XML);

	return $JSON;
}

=head2 obj2json

Takes a perl data object as input.
Return a string of equivalent JSON.

=cut

sub obj2json
{
	my ( $Self, $Obj ) = @_;

	my $JSON = "";

	carp "Converting obj to json using $Self->{_loaded_module}" if $Self->{debug};

	if ( $Self->{_loaded_module} eq 'JSON::Syck' )
	{
		# this module does not have a "pretty" option
		$JSON = JSON::Syck::Dump($Obj);
	}

	if ( $Self->{_loaded_module} eq 'JSON::XS' )
	{
		$JSON = JSON::XS->new->utf8->pretty( $Self->{pretty} )->encode($Obj);
	}

	if ( $Self->{_loaded_module} eq 'JSON' )
	{
		$JSON::UnMapping = 1;

		if ( $Self->{pretty} )
		{
			$JSON = JSON::to_json( $Obj, { pretty => 1, indent => 2 } );
		}
		else
		{
			$JSON = JSON::to_json($Obj);
		}
	}

	if ( $Self->{_loaded_module} eq 'JSON::DWIW' )
	{
		$JSON = JSON::DWIW->to_json( $Obj, { pretty => $Self->{pretty} } );
	}

	return $JSON;
}

=head2 dom2obj

Takes an XML::LibXML::Document object as input.
Returns an equivalent perl data structure.

=cut

sub dom2obj
{
	my ( $Self, $Doc ) = @_;

	# this is the response element
	my $Root = $Doc->documentElement;

	# set the root element name
	my $NodeName = $Root->nodeName;

	# replace a ":" in the name with a "$"
	$NodeName =~ s/([^^])\:/$1\$/;

	# get the version and encoding of the xml doc
	my $Version  = $Doc->version  || '1.0';
	my $Encoding = $Doc->encoding || 'UTF-8';

	# create the base objects
	my $Obj = {};
	my $RootObj = {    $Self->{attribute_prefix} .
					  'version' => $Version,
					$Self->{attribute_prefix} .
					  'encoding' => $Encoding,
					$NodeName => $Obj,
	};

	# grab any text content
	my $Text = $Root->findvalue('text()');
	$Text = undef unless $Text =~ /\S/;
	$Obj->{ $Self->{content_key} } = $Text if defined($Text);

	# process attributes
	my @Attributes = $Root->findnodes('@*');
	if (@Attributes)
	{
		foreach my $Attr (@Attributes)
		{
			my $AttrName  = $Attr->nodeName;
			my $AttrValue = $Attr->nodeValue;

			$Obj->{ $Self->{attribute_prefix} . $AttrName } = $AttrValue;
		}
	}
	my @Namespaces = $Root->getNamespaces();
	if (@Namespaces)
	{
		foreach my $Ns (@Namespaces)
		{
			my $Prefix = $Ns->declaredPrefix;			
			my $URI = $Ns->declaredURI;
			$Prefix = ":$Prefix" if $Prefix;
			$Obj->{ $Self->{attribute_prefix} . 'xmlns' . $Prefix } = $URI;
			warn "xmlns$Prefix=\"$URI\"" if $Self->{debug};
		}
	}

	$Self->_process_children( $Root, $Obj );

	return $RootObj;
}

=head2 xml2obj

Takes an xml string as input.
Returns an equivalent perl data structure.

=cut

sub xml2obj
{
	my ( $Self, $XML ) = @_;

	my $Doc = $XMLPARSER->parse_string($XML);

	my $Obj = $Self->dom2obj($Doc);

	return $Obj;
}

sub _process_children
{
	my ( $Self, $CurrentElement, $CurrentObj ) = @_;

	my @Children = $CurrentElement->findnodes('*');

	foreach my $Child (@Children)
	{
		# this will contain the data for the current element (including its children)
		my $ElementHash = {};

		# set the name of the element
		my $NodeName = $Child->nodeName;

		# replace a ":" in the name with a "$"
		$NodeName =~ s/([^^])\:/$1\$/;

		warn "Found element: $NodeName" if $Self->{debug};

		# force array: all children are accessed through an arrayref, even if there is only one child
		# I don't think I like this, but it's more predictable than array folding
		if ( $Self->{force_array} )
		{
			warn "Forcing \"$NodeName\" element into an array" if $Self->{debug};
			$CurrentObj->{$NodeName} = [] unless $CurrentObj->{$NodeName};
			push @{ $CurrentObj->{$NodeName} }, $ElementHash;
		}

		# otherwise, use array folding
		else
		{

			# check to see if a sibling element of this node name has already been added to the current object block
			if ( exists $CurrentObj->{$NodeName} )
			{
				my $NodeType = ref( $CurrentObj->{$NodeName} );

				if ( $NodeType eq 'HASH' )
				{

					# an element was already added, but it is not in an array
					# so take the sibling element and wrap it inside of an array

					warn "Found the second \"$NodeName\" child element." . " Now wrapping it into an arrayref"
					  if $Self->{debug};
					$CurrentObj->{$NodeName} = [ $CurrentObj->{$NodeName} ];
				}
				if ( $NodeType eq '' )
				{

					# oops, it looks like an attribute of the same name was already added
					# ($Self->{attribute_prefix} eq "")
					# the attribute is going to get overwritten :(

					warn "The \"$NodeName\" attribute conflicts with a child element of the same name."
					  . " The attribute has been lost!"
					  . " Try setting the attribute_prefix arg to something like '\@' to avoid this"    
					  if $Self->{debug};
					$CurrentObj->{$NodeName} = [];
				}

				# add the current element to the array
				warn "Adding the \"$NodeName\" child element to the array" if $Self->{debug};
				push @{ $CurrentObj->{$NodeName} }, $ElementHash;
			}

			# this is the first element found for this node name, so just add the hash
			# this will simplify data access for elements that only have a single child of the same name
			else
			{
				warn "Found the first \"$NodeName\" child element."
				  . " This element may be accessed directly through its hashref"
				  if $Self->{debug};
				$CurrentObj->{$NodeName} = $ElementHash;
			}
		}

		# grab any text content
		my $Text = $Child->findvalue('text()');
		$Text = undef unless $Text =~ /\S/;
		$ElementHash->{ $Self->{content_key} } = $Text if defined($Text);

		# add the attributes
		my @Attributes = $Child->findnodes('@*');
		if (@Attributes)
		{
			foreach my $Attr (@Attributes)
			{
				my $AttrName  = $Self->{attribute_prefix} . $Attr->nodeName;
				my $AttrValue = $Attr->nodeValue;

				# prefix the attribute name so that the name cannot conflict with child element names
				warn "Adding attribute to the \"$NodeName\" element: $AttrName" if $Self->{debug};
				$ElementHash->{$AttrName} = $AttrValue;
			}
		}
		my @Namespaces = $Child->getNamespaces();
		if (@Namespaces)
		{
			foreach my $Ns (@Namespaces)
			{
				my $Prefix = $Ns->declaredPrefix;			
				my $URI = $Ns->declaredURI;
				$Prefix = ":$Prefix" if $Prefix;
				$ElementHash->{ $Self->{attribute_prefix} . 'xmlns' . $Prefix } = $URI;
				warn "xmlns$Prefix=\"$URI\"" if $Self->{debug};
			}
		}		

		# look for more children
		$Self->_process_children( $Child, $ElementHash );
	}

	return;
}

=head2 sanitize

Takes a perl hashref as input. 
(You would normally pass this method the object returned by the xml2obj method.)

This method does not return anything. The object passed into it is directly modified.

Since JSON is often returned directly to a client's browser,
there are cases where sensitive data is left in the response.

This method allows you to filter out content that you do not want to be included in the JSON.

This method uses the private_elements, empty_elements and private_attributes
arguments which are set when calling the "new" method.

=cut

sub sanitize
{
	my ( $Self, $Obj ) = @_;

	my $ObjType = ref($Obj) || 'scalar';
	carp "That's not a hashref! ($ObjType)" unless $ObjType eq 'HASH';

	# process each hash key
  KEYS: foreach my $Key ( keys %$Obj )
	{
		my $KeyType = ref( $Obj->{$Key} );

		# this is an element
		if ( $KeyType eq 'HASH' || $KeyType eq 'ARRAY' )
		{
			# check to see if this element is private
			if ( $Self->{private_elements}->{$Key} )
			{
				# this is a private element, so delete it
				warn "Deleting private element: $Key" if $Self->{debug};
				delete $Obj->{$Key};
			
				# the element is gone, move on to the next hash key
				next KEYS;
			}

			# the element is a hash
			if ( $KeyType eq 'HASH' )
			{
				# check to see if this element should be blanked out
				if ( $Self->{empty_elements}->{$Key} )
				{
					my @Attributes = keys %{ $Obj->{$Key} };

					foreach my $Attribute (@Attributes)
					{
						unless ( ref( $Obj->{$Key}->{$Attribute} ) )
						{
							warn "Deleting attribute from \"$Key\" element: $Attribute" if $Self->{debug};
							delete $Obj->{$Key}->{$Attribute};
						}
					}
				}
				
				# go deeper
				$Self->sanitize( $Obj->{$Key} );
			}
			
			# this is an array of child elements
			if ( $KeyType eq 'ARRAY' )
			{
				# process each child element
				foreach my $Element ( @{ $Obj->{$Key} } )
				{
					$Self->sanitize($Element);
				}
			}
		}
		# this is an attribute
		elsif ( !$KeyType )
		{
			# check to see if the attribute is private
			if ( $Self->{private_attributes}->{$Key} )
			{
				# this is a private attribute, so delete it
				warn "Deleting private attribute: $Key" if $Self->{debug};
				delete $Obj->{$Key};
			}
		}
		else
		{
			croak "Invalid data type for key: $Key (data type: $KeyType)";
		}
	}

	return;
}

=head2 json2xml

Takes a JSON string as input.
Returns a string of equivalent XML.

Calling this method is the same as:

	my $Obj = $Self->json2obj($JSON);
	my $XML = $Self->obj2xml($Obj);

=cut

sub json2xml
{
	my ( $Self, $JSON ) = @_;

	my $Obj = $Self->json2obj($JSON);

	my $XML = $Self->obj2xml($Obj);

	return $XML;
}

=head2 json2obj

Takes a json string as input.
Returns an equivalent perl data structure.

=cut

sub json2obj
{
	my ( $Self, $JSON ) = @_;

	my $Obj;

	carp "Converting json to obj using $Self->{_loaded_module}" if $Self->{debug};

	if ( $Self->{_loaded_module} eq 'JSON::Syck' )
	{
		$Obj = JSON::Syck::Load($JSON);
	}

	if ( $Self->{_loaded_module} eq 'JSON::XS' )
	{
		$Obj = JSON::XS->new->utf8->decode($JSON);
	}

	if ( $Self->{_loaded_module} eq 'JSON' )
	{
		$Obj = JSON::from_json($JSON);
	}

	if ( $Self->{_loaded_module} eq 'JSON::DWIW' )
	{
		$Obj = JSON::DWIW->from_json($JSON);
	}

	return $Obj;
}

=head2 obj2dom

Takes a perl data structure as input. (Must be a hashref.)
Returns an XML::LibXML::Document object.

This method expects the object to be in the same format as 
would be returned by the xml2obj method.

In short: 

=over 4

=item * The root hashref may only have a single hashref key. That key will become the xml document's root.

=item * A hashref will be converted to an element.

=item * An arraysref of hashrefs will be converted into multiple child elements. Their names will be set to the name of the arrayref's hash key.

=item * If an attribute is prefixed by an "@", the "@" will be removed.

=item * A hashkey named "$t" will be converted into text content for the current element.

=back

Namespace

=over 4

=item * If a namespace alias has a "$", it will be replaced using ":". For example, ns$element becomes ns:element.

=back

Caveats:

=over 4

=item * The order of child elements and attributes cannot be determined.

=back

=cut

sub obj2dom
{
	my ( $Self, $Obj ) = @_;

	croak "Object must be a hashref" unless ref($Obj) eq 'HASH';

	my $Version  = $Obj->{ $Self->{attribute_prefix} . 'version' }  || $Obj->{'version'}  || '1.0';
	my $Encoding = $Obj->{ $Self->{attribute_prefix} . 'encoding' } || $Obj->{'encoding'} || 'UTF-8';

	my $Dom = $XMLPARSER->createDocument( $Version, $Encoding );

	my $GotRoot = 0;

 	#delete @$Obj{ grep { /^$Self->{attribute_prefix}/ } keys %$Obj };
	
	foreach my $Key ( keys %$Obj )
	{
	    $Obj->{$Key} = "" unless defined($Obj->{$Key});
	    
		my $RefType = ref( $Obj->{$Key} );
		warn "Value ref type for $Key is: $RefType (value seems to be $Obj->{$Key})" if $Self->{debug};

		my $Name = $Key;

		# replace a "$" in the name with a ":"
		$Name =~ s/([^^])\$/$1\:/;

		if ( $RefType eq 'HASH' )
		{
			warn "Creating root element: $Name" if $Self->{debug};

			croak "You may only have one root element: $Key" if $GotRoot;
			$GotRoot = 1;

			my $Root = $Dom->createElement($Name);
			$Dom->setDocumentElement($Root);

			$Self->_process_element_hash( $Dom, $Root, $Obj->{$Key} );
		}
		elsif ( $RefType eq 'ARRAY' )
		{
			croak "You cant have an array of root nodes: $Key";
		}
		elsif ( !$RefType )
		{		
            if ( $Obj->{$Key} ne '' )
            {
				unless ($GotRoot)
				{
					my $Root;
					eval { $Root = $Dom->createElement($Name) };
					if ( $@ ) {
						die "Problem creating root element $Name: $@";
					}
					$Dom->setDocumentElement($Root);
					$Root->appendText( $Obj->{$Key} );
					$GotRoot = 1;
				}
            }
            else
            {
              croak "Invalid data for key: $Key";
            }
		}
		else
		{
		    warn "unknown reference: $RefType";
		}
	}

	return $Dom;
}

=head2 obj2xml

This method takes the same arguments as obj2dom.
Returns the XML as a string.

=cut

sub obj2xml
{
	my ( $Self, $Obj ) = @_;

	my $Dom = $Self->obj2dom($Obj);

	my $XML = $Dom->toString( $Self->{pretty} ? 2 : 0 );

	return $XML;
}

sub _process_element_hash
{
	my ( $Self, $Dom, $Element, $Obj ) = @_;

	foreach my $Key ( keys %$Obj )
	{
		my $RefType = ref( $Obj->{$Key} );

		my $Name = $Key;

		# replace a "$" in the name with a ":"
		$Name =~ s/([^^])\$/$1\:/;
		
		# true/false hacks
		if ($RefType eq 'JSON::XS::Boolean')
		{
		    $RefType = "";
		    $Obj->{$Key} = 1 if ("$Obj->{$Key}" eq 'true');
		    $Obj->{$Key} = "" if ("$Obj->{$Key}" eq 'false');
		}
		if ($RefType eq 'JSON::true')
		{
		    $RefType = "";
		    $Obj->{$Key} = 1;
		}
		if ($RefType eq 'JSON::false')
		{
		    $RefType = "";
		    $Obj->{$Key} = "";
		}

		if ( $RefType eq 'ARRAY' )
		{
			foreach my $ChildObj ( @{ $Obj->{$Key} } )
			{
				warn "Creating element: $Name" if $Self->{debug};

				my $Child = $Dom->createElement($Name);
				$Element->addChild($Child);

				$Self->_process_element_hash( $Dom, $Child, $ChildObj );
			}
		}
		elsif ( $RefType eq 'HASH' )
		{
			warn "Creating element: $Name" if $Self->{debug};

			my $Child = $Dom->createElement($Name);
			$Element->addChild($Child);

			$Self->_process_element_hash( $Dom, $Child, $Obj->{$Key} );
		}
		elsif ( !$RefType )
		{
			if ( $Key eq $Self->{content_key} )
			{
				warn "Appending text to: $Name" if $Self->{debug};
				
				my $Value = defined($Obj->{$Key}) ? $Obj->{$Key} : q{};

				$Element->appendText( $Value );
			}
			else
			{

				# remove the attribute prefix
				my $AttributePrefix = $Self->{attribute_prefix};
				if ( $Name =~ /^\Q$AttributePrefix\E(.+)/ )
				{
					$Name = $1;
				}
				
				my $Value = defined($Obj->{$Key}) ? $Obj->{$Key} : q{};

				warn "Creating attribute: $Name" if $Self->{debug};
				$Element->setAttribute( $Name, $Value );
			}
		}
		else
		{
			croak "Invalid value for element $Key (reference type: $RefType)";
		}
	}

	return;
}

=head1 CAVEATS

The order of child elements is not always preserved.
This is because the conversion to json makes use of hashes in the resulting json.

=head1 AUTHOR

Ken Prows - perl(AT)xev.net

=head1 COPYRIGHT & LICENSE

Copyright (C) 2007-2008 Ken Prows

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;

