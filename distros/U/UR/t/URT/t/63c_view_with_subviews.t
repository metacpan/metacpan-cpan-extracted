#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

# let the developer supply the toolkits to test
# or default to all of them
# TODO: add html when it stops dying
our @toolkits = @ARGV;

eval "use XML::LibXML";
eval "use XML::LibXSLT";
eval "use XML::Dumper";
my $TEST_XML = 1;
unless ($INC{"XML/LibXML.pm"} && $INC{'XML/LibXSLT.pm'} && $INC{'XML/Dumper.pm'}) {
    $TEST_XML = undef;
}

use UR;

unless (@toolkits) {
    @toolkits = $TEST_XML ? qw/json xml text/ : qw/json text/;
}

class Acme { is => 'UR::Namespace' };

## value data type
class Acme::Value::Years {
    is => 'UR::Value::Number',
};

sub Acme::Value::Years::__display_name__ {
    my $self = shift;
    return $self->id . ' yrs';
};

## value data types can be gotten by their identity
## they cannot be created, deleted, or mutated
my $age1 = Acme::Value::Years->get(88);
is($age1->__display_name__, "88 yrs", "$age1 has id " . $age1->id . " and display name " . $age1->id . " yrs");

my $age2 = Acme::Value::Years->get(22);
is($age2->__display_name__, "22 yrs", "$age2 has id " . $age2->id . " and display name " . $age2->id . " yrs");

## entity data types
class Acme::Animal {
    has => [
        id      => { is => 'Integer' },
        name    => { is => 'Text' },
        age     => { is => 'Years' },
    ]
};

class Acme::Person {
    is => 'Acme::Animal',
    has => [
        cats    => { is => 'Acme::Cat', is_many => 1 },
    ]
};

class Acme::Cat {
    is => 'Acme::Animal',
    has => [
        fluf        => { is => 'Number' },
        owner       => { is => 'Acme::Person', id_by => 'owner_id' },
        owner_age   => { is => 'Number', via => 'owner', to => 'age' },
    ]
};

## the set of entities of a given set is finite, and can be created, mutated, deleted
my $p = Acme::Person->create(name => 'Fester', age => 99, id => 111);
    ok($p, "made a test person object to have cats");

my $c1 = Acme::Cat->create(name => 'fluffy', age => 2, owner => $p, fluf => 11, id => 222);
    ok($c1, "made a test cat 1");

my $c2 = Acme::Cat->create(name => 'nestor', age => 8, owner => $p, fluf => 22, id => 333);
    ok($c2, "made a test cat 2");

my @c = $p->cats();
is("@c","$c1 $c2", "got expected cat list for the owner");

$DB::single = 1;
my $cat_set = $p->cat_set();
ok($cat_set, "got a set object representing the test person's set of cats: $cat_set");

## as we render the person and the cat set, we will show the same aspects for each class
my @person_aspects = (
    'name',
    'age',
    {
        name => 'cats',
        #perspective => 'default',
        #toolkit => 'text',
        aspects => [
            'name',
            'age',
            'fluf',
            'owner'
        ],
    }
);

my @cat_set_aspects = (
    'id',
    'members',
    #'owner',
    #'owner_age',
);

# render both objects, in a variety of text-based views
for my $obj_aspects_pair ( [$p,\@person_aspects], [$cat_set,\@cat_set_aspects] ) {
    my ($obj, $aspects) = @$obj_aspects_pair;
    for my $toolkit (@toolkits) { # TODO: add 'html' to this list
        note("\nVIEW: " . ref($obj) . " as $toolkit...\n \n");
        for my $aspect (@$aspects) {
            if (ref($aspect) eq 'HASH') {
                $aspect->{toolkit} = $toolkit;
                $aspect->{perspective} = 'default';
            }
        }
        diag("Creating view with toolkit $toolkit");
        my $view = $obj->create_view(
            toolkit => $toolkit,
            aspects => $aspects, 
        );
        ok($view, "got an text view for the person");
        $DB::single = 1;
        my $actual_content = $view->content;
        ok($actual_content, "$toolkit view of " . ref($obj) . " generated content"); 

        my $expected_content_path = ref($obj);
        $expected_content_path =~ s/Acme:://;
        $expected_content_path =~ s/::/_/g;
        $expected_content_path = lc($expected_content_path);
        $expected_content_path = __FILE__ . '.expected.' . $expected_content_path . '.' . $toolkit;
        
        # this will cause us to skip missing toolkits w/o failing for now.
        # when json, xml and html all work remove these 4 lines...
        unless (-e $expected_content_path) {
            note("No file at $expected_content_path. Cannot validate:\n$actual_content");
            next;
        };

        # this is the _actual_ test for above when all tookits are in place
        ok(-e $expected_content_path, "path exists to expected content for toolkit $toolkit") or do {
            diag("No file at $expected_content_path? Cannot validate:\n$actual_content");
            next;
        };
        my $expected_content = join('', IO::File->new($expected_content_path)->getlines());
        is($actual_content, $expected_content, "content matches!") 
            or eval {
                # stage a file for debugging, or to upgrade the test
                IO::File->new(">$expected_content_path.new")->print($actual_content)
            };
            #and note("WORKS ON:\n$actual_content");
    }
}

done_testing();
