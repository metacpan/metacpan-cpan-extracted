use strict;

use Test::More qw(no_plan); #tests => 6;
BEGIN { use_ok('Text::FormBuilder::Parser'); };

my $p = Text::FormBuilder::Parser->new;

# this is the minimal hash that is returned with every field that is parsed
my %base = (
    comment  => undef,
    growable => undef,
    label    => undef,
    list     => undef,
    multiple => undef,
    name     => undef,
    other    => undef,
    required => undef,
    type     => undef,
    validate => undef,
    value    => undef,
);

my @test_fields = (
    {
        comment => 'just the name of the field',
        fieldspec => 'name',
        expecting => { name => 'name' },
    },
    {
        comment => 'different single word label',
        fieldspec => 'name|Moniker',
        expecting => {
            name => 'name',
            label => 'Moniker',
        },
    },
    {
        comment => 'multi-word label',
        fieldspec => 'name|Full name',
        expecting => {
            name => 'name',
            label => 'Full name',
        },
    },
    {
        comment => 'quoted label',
        fieldspec => "name|'Name/nickname'",
        expecting => {
            name => 'name',
            label => 'Name/nickname',
        },
    },
    {
        comment => 'quoted label with \ escapes',
        fieldspec => "name|'Your \\'name\\''",
        expecting => {
            name => 'name',
            label => "Your 'name'",
        },
    },

    # field types
    {
        comment => 'field type "text"',
        fieldspec => 'name:text',
        expecting => { 
            name => 'name',
            type => 'text',
        },
    },
    {
        comment => 'field type "textarea"',
        fieldspec => 'name:textarea',
        expecting => { 
            name => 'name',
            type => 'textarea',
        },
    },
    {
        comment => 'field type "password"',
        fieldspec => 'name:password',
        expecting => { 
            name => 'name',
            type => 'password',
        },
    },
    {
        comment => 'field type "checkbox"',
        fieldspec => 'name:checkbox',
        expecting => { 
            name => 'name',
            type => 'checkbox',
        },
    },
    {
        comment => 'field type "radio"',
        fieldspec => 'name:radio',
        expecting => { 
            name => 'name',
            type => 'radio',
        },
    },
    {
        comment => 'field type "select"',
        fieldspec => 'name:select',
        expecting => { 
            name => 'name',
            type => 'select',
        },
    },


    {
        comment => 'text field with size',
        fieldspec => 'name[25]:text',
        expecting => { 
            name => 'name',
            type => 'text',
            size => 25,
        },
    },
    {
        comment => 'text field with size and maxlength',
        fieldspec => 'name[25!]:text',
        expecting => { 
            name => 'name',
            type => 'text',
            size => 25,
            maxlength => 25,
        },
    },
    {
        comment => 'textarea field with size (rows and columns)',
        fieldspec => 'name[4,40]:textarea',
        expecting => { 
            name => 'name',
            type => 'textarea',
            rows => 4,
            cols => 40,
        },
    },

);

foreach (@test_fields) {
    my $field = $p->field($_->{fieldspec});
    ok(eq_hash($field, { %base, %{ $_->{expecting} } }), $_->{comment});
}
