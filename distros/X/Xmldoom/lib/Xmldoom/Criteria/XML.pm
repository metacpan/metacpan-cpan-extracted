
package Xmldoom::Criteria::XML;

use Xmldoom::Criteria;
use Xmldoom::Criteria::UnknownObject;
use DBIx::Romani::Query::XML::Util qw(get_element_text);
use XML::GDOME;
use XML::DOM;
use strict;

use Data::Dumper;

sub parse_string
{
	my $xml      = shift;
	my $database = shift;

	my $doc = XML::GDOME->createDocFromString( $xml );

	return Xmldoom::Criteria::XML::parse_dom( $doc, $database );
}

sub parse_dom
{
	my $doc      = shift;
	my $database = shift;

	return Xmldoom::Criteria::XML::create_criteria_from_node( $doc->getDocumentElement(), $database );
}

sub create_criteria_from_node
{
	my $parent_node = shift;
	my $database    = shift;

	# this will grab the Criteria parent if such a section exists
	my $parent = Xmldoom::Criteria::XML::_parse_parent_section($parent_node, $database);

	my $criteria = Xmldoom::Criteria->new($parent);

	my $limit  = $parent_node->getAttribute('limit');
	my $offset = $parent_node->getAttribute('offset');

	if ( (defined $limit  and $limit  ne "") or
	     (defined $offset and $offset ne "") )
	{
		$criteria->set_limit($limit, $offset);
	}

	my $has_constraints = 0;
	my $has_order_by    = 0;
	my $has_group_by    = 0;

	my $node = $parent_node->getFirstChild();
	while ( defined $node )
	{
		if ( $node->getNodeType() == XML::DOM::ELEMENT_NODE )
		{
			my $name = $node->getTagName();

			if ( $name eq 'constraints' )
			{
				if ( not $has_constraints )
				{
					_parse_constraints_section( $criteria, $node );
					$has_constraints = 1;
				}
				else
				{
					die "Cannot have multiple constraints sections";
				}
			}
			elsif ( $name eq 'order-by' )
			{
				if ( not $has_order_by )
				{
					_parse_order_by_section( $criteria, $node );
					$has_order_by = 1;
				}
				else
				{
					die "Cannot have multiple order-by sections";
				}
			}
			elsif ( $name eq 'group-by' )
			{
				if ( not $has_group_by )
				{
					_parse_group_by_section( $criteria, $node );
					$has_group_by = 1;
				}
				else
				{
					die "Cannot have multiple group-by sections";
				}
			}
			elsif ( $name eq 'parent' )
			{
				# Already processed this section in advance...
			}
			else
			{
				die "Unknown criteria section: $name";
			}
		}
		
		$node = $node->getNextSibling();
	}

	return $criteria;
}

sub _parse_parent_section
{
	my $top_node = shift;
	my $database = shift;

	# try to find the parent section
	my $parent_node = $top_node->getFirstChild();
	while ( defined $parent_node )
	{
		if ( $parent_node->getNodeType() == XML::DOM::ELEMENT_NODE &&
		     $parent_node->getTagName() eq 'parent' )
		{
			last;
		}

		$parent_node = $parent_node->getNextSibling();
	}

	# check it out
	if ( not defined $parent_node )
	{
		return undef;
	}
	elsif ( not defined $database )
	{
		die "Cannot parse a criteria with a <parent/> section if you don't pass the database object into the parser";
	}

	my $object_name = $parent_node->getAttribute('object_name');
	my $definition  = $database->get_object($object_name);

	my $load_args = { };

	# find the node with the keys in it
	my $key_node = $parent_node->getFirstChild();
	while ( defined $key_node )
	{
		if ( $key_node->getNodeType() == XML::DOM::ELEMENT_NODE &&
		     $key_node->getTagName() eq 'key' )
		{
			last;
		}

		$key_node = $key_node->getNextSibling();
	}

	if ( not defined $key_node )
	{
		die "No key given for <parent/> object of <criteria/>";
	}

	# get all the attributes into our load hash
	my $attrs = $key_node->getAttributes();
	for( my $i = 0; $i < $attrs->getLength(); $i++ )
	{
		my $attr = $attrs->item($i);
		$load_args->{$attr->getName()} = $attr->getValue();
	}

	# actually load the object
	my $object = $definition->class_load( $load_args );
	
	return $object;
}

sub _parse_constraints_section
{
	my ($criteria, $parent_node) = @_;

	my $node = $parent_node->getFirstChild();
	while ( defined $node )
	{
		if ( $node->getNodeType() == XML::DOM::ELEMENT_NODE )
		{
			my $name = $node->getTagName();

			if ( $name eq 'property' or $name eq 'attribute' )
			{
				my $prop_name = $node->getAttribute('name');
				my $cons = _parse_constraint_value( $node );

				if ( $name eq 'property' )
				{
					$criteria->add_prop( $prop_name, $cons->{value}, $cons->{type} );
				}
				else
				{
					$criteria->add_attr( $prop_name, $cons->{value}, $cons->{type} );
				}
			}
			elsif ( $name eq 'join-properties' )
			{
				my $attr_name1 = $node->getAttribute('name1');
				my $attr_name2 = $node->getAttribute('name2');

				$criteria->join_prop( $attr_name1, $attr_name2 );
			}
			elsif ( $name eq 'join-attributes' )
			{
				my $attr_name1 = $node->getAttribute('name1');
				my $attr_name2 = $node->getAttribute('name2');

				$criteria->join_attr( $attr_name1, $attr_name2 );
			}
			elsif ( $name eq 'and' or $name eq 'or' )
			{
				if ( $name eq 'and' and $criteria->get_type() eq 'AND' )
				{
					# if the criteria is already of the AND type, then we don't need to
					# put this is another section.
					_parse_constraints_section( $criteria, $node );
				}
				else
				{
					my $search;

					if ( $name eq 'and' )
					{
						$search = Xmldoom::Criteria::Search->new( $Xmldoom::Criteria::AND );
					}
					else
					{
						$search = Xmldoom::Criteria::Search->new( $Xmldoom::Criteria::OR );
					}

					_parse_constraints_section( $search, $node );
					$criteria->add( $search );
				}
			}
			else
			{
				die "Unknown constraint tag: $name";
			}
		}
		
		$node = $node->getNextSibling();
	}
}

sub _parse_order_by_section
{
	my ($criteria, $parent_node) = @_;

	my $node = $parent_node->getFirstChild();
	while ( defined $node )
	{
		if ( $node->getNodeType() == XML::DOM::ELEMENT_NODE )
		{
			my $tag_name = $node->getTagName();

			my $name = $node->getAttribute("name");
			my $dir  = $node->getAttribute("dir") || undef;

			if ( $tag_name eq 'property' )
			{
				$criteria->add_order_by_prop( $name, $dir );
			}
			elsif ( $tag_name eq 'attribute' )
			{
				$criteria->add_order_by_attr( $name, $dir );
			}
			else
			{
				die "Unknown order-by tag: $name";
			}
		}
		
		$node = $node->getNextSibling();
	}
}

sub _parse_group_by_section
{
	my ($criteria, $parent_node) = @_;

	my $node = $parent_node->getFirstChild();
	while ( defined $node )
	{
		if ( $node->getNodeType() == XML::DOM::ELEMENT_NODE )
		{
			my $tag_name = $node->getTagName();

			my $name = $node->getAttribute("name");

			if ( $tag_name eq 'property' )
			{
				$criteria->add_group_by_prop( $name );
			}
			elsif ( $tag_name eq 'attribute' )
			{
				$criteria->add_group_by_attr( $name );
			}
			else
			{
				die "Unknown order-by tag: $name";
			}
		}
		
		$node = $node->getNextSibling();
	}
}

sub _parse_constraint_value
{
	my $parent_node = shift;

	my $type;
	my $value;

	my $node = $parent_node->getFirstChild();
	while ( defined $node )
	{
		if ( $node->getNodeType() == XML::DOM::ELEMENT_NODE )
		{
			my $name = $node->getTagName();

			if ( $name eq 'in' or $name eq 'not-in' or $name eq 'between' )
			{
				if ( $name eq 'between' )
				{
					$type  = $Xmldoom::Criteria::BETWEEN;
					$value = [
						$node->getAttribute('min'),
						$node->getAttribute('max'),
					];
				}
				else
				{
					if ( $name eq 'in' )
					{
						$type  = $Xmldoom::Criteria::IN;
					}
					elsif ( $name eq 'not-in' )
					{
						$type  = $Xmldoom::Criteria::NOT_IN;
					}

					$value = _parse_value_list( $node );
				}
			}
			else
			{
				if ( $name eq 'equal' )
				{
					$type = $Xmldoom::Criteria::EQUAL;
				}
				elsif ( $name eq 'not-equal' )
				{
					$type = $Xmldoom::Criteria::NOT_EQUAL;
				}
				elsif ( $name eq 'greater-than' )
				{
					$type = $Xmldoom::Criteria::GREATER_THAN;
				}
				elsif ( $name eq 'greater-equal' )
				{
					$type = $Xmldoom::Criteria::GREATER_EQUAL;
				}
				elsif ( $name eq 'less-than' )
				{
					$type = $Xmldoom::Criteria::LESS_THAN;
				}
				elsif ( $name eq 'less-equal' )
				{
					$type = $Xmldoom::Criteria::LESS_EQUAL;
				}
				elsif ( $name eq 'like' )
				{
					$type = $Xmldoom::Criteria::LIKE;
				}
				elsif ( $name eq 'not-like' )
				{
					$type = $Xmldoom::Criteria::NOT_LIKE;
				}
				elsif ( $name eq 'is-null' )
				{
					$type = $Xmldoom::Criteria::IS_NULL;
				}
				elsif ( $name eq 'is-not-null' )
				{
					$type = $Xmldoom::Criteria::IS_NOT_NULL;
				}
				else
				{
					die "Unknown comparison type: $name";
				}

				if ( ($name eq 'equal' or $name eq 'not-equal') and 
					 defined $node->getFirstChild() and
				     $node->getFirstChild()->getNodeType == XML::DOM::ELEMENT_NODE )
				{
					$value = _parse_object( $node );
				}
				elsif ( $type eq $Xmldoom::Criteria::IS_NULL or 
				        $type eq $Xmldoom::Criteria::IS_NOT_NULL )
				{
					# doen't do nothing because these can't take values
				}
				else
				{
					$value = get_element_text( $node );
				}
			}
		}

		$node = $node->getNextSibling();
	}

	#if ( $value eq '' )
	#{
	#	$value = undef;
	#}

	return { type => $type, value => $value };
}

sub _parse_object
{
	my $parent_node = shift;

	my $node = $parent_node->getFirstChild();
	if ( $node->getTagName() ne 'object' )
	{
		die sprintf "%s tag can only contain text or an <object/> tag", $parent_node->getTagName();
	}

	my %info;

	my $attrs = $node->getAttributes();
	for( my $i = 0; $i < $attrs->getLength(); $i++ )
	{
		my $attr = $attrs->item($i);
		
		$info{$attr->getName()} = $attr->getValue();
	}

	return Xmldoom::Criteria::UnknownObject->new( \%info );
}

sub _parse_value_list
{
	my $parent_node = shift;

	my $node = $parent_node->getFirstChild();
	my @values;
	
	while ( defined $node )
	{
		if ( $node->getNodeType() == XML::DOM::ELEMENT_NODE )
		{
			if ( $node->getTagName() eq 'value' )
			{
				push @values, get_element_text( $node );
			}
			else
			{
				die sprintf "Can only list <value/> tags inside of %s tag", $parent_node->getTagName();
			}
		}
		
		$node = $node->getNextSibling();
	}

	return \@values;
}

1;

