use strict;
use warnings;
use Test::More;

use Data::Dumper;

BEGIN { use_ok('XML::PP') }

my $xml_pp = new_ok('XML::PP');

# --- Test 1: Basic $xml_pp->collapsing ---
my $input1 = {
    name => 'note',
    children => [
        { name => 'to', children => [ { text => 'Tove' } ] },
        { name => 'from', children => [ { text => 'Jani' } ] },
        { name => 'heading', children => [ { text => 'Reminder' } ] },
        { name => 'body', children => [ { text => 'Don\'t forget me this weekend!' } ] },
    ],
};

my $expected1 = {
    note => {
        to      => 'Tove',
        from    => 'Jani',
        heading => 'Reminder',
        body    => 'Don\'t forget me this weekend!',
    }
};

is_deeply($xml_pp->collapse_structure($input1), $expected1, 'Basic $xml_pp->collapse test');

# --- Test 2: Nested structure ---
my $input2 = {
    name => 'note',
    children => [
        {
            name => 'body',
            children => [
                { name => 'p', children => [ { text => 'Paragraph 1' } ] },
                { name => 'footer', children => [ { text => 'Goodbye' } ] },
            ]
        },
    ]
};

my $expected2 = {
    note => {
        body => {
            p => 'Paragraph 1',
            footer => 'Goodbye',
        }
    }
};

diag(Data::Dumper->new([$xml_pp->collapse_structure($input2)])->Dump()) if($ENV{'TEST_VERBOSE'});
is_deeply($xml_pp->collapse_structure($input2), $expected2, 'Nested $xml_pp->collapse test');

# --- Test 3: Multiple same-name tags become array ---
my $input3 = {
    name => 'data',
    children => [
        { name => 'item', children => [ { text => 'One' } ] },
        { name => 'item', children => [ { text => 'Two' } ] },
        { name => 'item', children => [ { text => 'Three' } ] },
    ]
};

my $expected3 = {
    data => {
        item => ['One', 'Two', 'Three']
    }
};

is_deeply($xml_pp->collapse_structure($input3), $expected3, 'Multiple same-name tags as array');

# --- Test 4: Skip empty nodes ---
my $input4 = {
    name => 'note',
    children => [
        { name => 'to', children => [ { text => '' } ] },    # empty text
        { name => 'from', children => [] },                  # no children
        { name => 'body', children => [ { text => 'Content' } ] },
    ]
};

my $expected4 = {
    note => {
        body => 'Content',
    }
};

is_deeply($xml_pp->collapse_structure($input4), $expected4, 'Skipping empty nodes');

# --- Done ---
done_testing();

