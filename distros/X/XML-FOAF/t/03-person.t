use strict;

use Test::More tests => 15;
use XML::FOAF;
use File::Basename qw( dirname );
use File::Spec;

my $test_file = File::Spec->catfile(dirname($0), 'samples', 'person.foaf');
die "$test_file does not exist" unless -e $test_file;
my $foaf = XML::FOAF->new($test_file, 'http://foo.com');
isa_ok $foaf, 'XML::FOAF';
my $person = $foaf->person;
isa_ok $person, 'XML::FOAF::Person';
is $person->name, 'Benjamin Trott';
is $person->firstName, 'Benjamin';
is $person->surname, 'Trott';
is $person->nick, 'Ben';
is $person->mbox, 'mailto:ben@stupidfool.org';
is $person->homepage, 'http://www.stupidfool.org/';
is $person->workplaceHomepage, 'http://www.sixapart.com/';
my $friends = $person->knows;
is @$friends, 1;
is $friends->[0]->name, 'Mena Trott';
is $friends->[0]->mbox, 'mailto:mena@dollarshort.org';

$test_file = File::Spec->catfile(dirname($0), 'samples', 'person-lower-case.foaf');
die "$test_file does not exist" unless -e $test_file;
$foaf = XML::FOAF->new($test_file, 'http://foo.com');
isa_ok $foaf, 'XML::FOAF';
$person = $foaf->person;
isa_ok $person, 'XML::FOAF::Person';
is $person->name, 'Benjamin Trott';
