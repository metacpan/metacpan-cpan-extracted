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
my $id     = $Person->attribute( name => 'id',  type => 'string' );
my $name   = $Person->element( name => 'name',  type => 'string' );
my $email  = $Person->element( name => 'email', type => 'string' );

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
    my $emails = join("\n  ", @$content);
    $infoset->{ result } = "$name ($id)\n  $emails\n";
});

# add person element to schema
$schema->element( name => 'person', type => 'personType' )
    || die $schema->error();

# generate parser
my $parser = $schema->parser() 
    || die $schema->error();

# parse
my $result = $parser->parse(<<'EOF') || die $parser->error();
<person id="abw">
  <name>Andy Wardley</name>
  <email>abw@wardley.org</email>
  <email>abw@andywardley.com</email>
  <email>triksox@wardley.org</email>
</person>
EOF

print $result;

