#!/usr/bin/perl -w                                            # -*- perl -*-
#
# Perl script written by Andy Wardley.  This is free software.
#

use strict;
use lib qw( ./lib ../lib );
use XML::Schema;

# create a schema
my $schema = XML::Schema->new();

# define a 'person' complex type with 'id' attr and 'name' element
my $Person = $schema->complexType( name => 'personType' );
my $id     = $Person->attribute( name => 'id', type => 'string' );
my $name   = $Person->element( name => 'name', type => 'string' );

# create a custom simple type for 'email' element
my $Email  = $Person->simpleType( name => 'emailType', base => 'string' );
my $email  = $Person->element( name => 'email', type => $Email );

# schedule some special handling for email addresses
$Email->schedule_instance(sub {
    my ($node, $infoset) = @_;
    $infoset->{ result } = "  Email: $infoset->{ result }";
});

# define content model for person
$Person->content(
    sequence => [ 
    {   element => $name,
        min => 1,
        max => 1,
    }, 
    {   element => $email,
        min => 0, 
        max => 10,
    }],
);

# schedule handling for person
$Person->schedule_end_element(sub {
    my ($node, $infoset) = @_;
    my $id = $infoset->{ attributes }->{ id };
    my $content = $infoset->{ content };
    my $name = shift @$content;
    $infoset->{ result } = join("\n", "$name ($id)", @$content);
});

# define a 'people' complex type
my $people = $schema->complexType( name => 'peopleType' );

# define 'people' content model
$people->content(
    sequence => [ 
    {   element => $people->element( name => 'person', type => 'personType' ),
        min => 1,
        max => 20,
    }],
);

# add people element to schema
$schema->element( name => 'people', type => 'peopleType' )
    || die $schema->error();

# generate parser
my $parser = $schema->parser() 
    || die $schema->error();

# parse
my $result = $parser->parse(<<'EOF') || die $parser->error();
<people>
  <person id="abw">
     <name>Andy Wardley</name>
     <email>abw@wardley.org</email>
     <email>abw@andywardley.com</email>
     <email>triksox@wardley.org</email>
  </person>
  <person id="mrp">
     <name>Martin Portman</name>
     <email>mrp@cre.canon.co.uk</email>
  </person>
</people>
EOF

print join("\n", @{ $result->{ content } }), "\n";

