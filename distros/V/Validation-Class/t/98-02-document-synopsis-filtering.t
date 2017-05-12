use utf8;
use strict;
use warnings;
use Test::More;

package T;

use Validation::Class;

field  'title';
field  'rating';
field  'name';

field  'id' => { filters => ['numeric'] };

document 'person' => {
    'id'                                   => 'id',
    'name'                                 => 'name',
    'title'                                => 'title',
    'company.name'                         => 'name',
    'company.supervisor.name'              => 'name',
    'company.supervisor.rating.@.support'  => 'rating',
    'company.supervisor.rating.@.guidance' => 'rating',
    'company.tags.@'                       => 'name'
};

package main;

my $class;

eval { $class = T->new; };

ok "T" eq ref $class, "T instantiated";

my $documents = $class->prototype->documents;

ok "Validation::Class::Mapping" eq ref $documents, "T documents hash registered as setting";

ok 1 == keys %{$documents}, "T has 1 registered document";

my $person = $documents->{person};

ok 8 == keys %{$person}, "T user document has 3 mappings";

can_ok $class, 'validate_document';

$person = {
    "id"      => "1234-ABC",
    "name"    => "Anita Campbell-Green",
    "title"   => "Designer",
    "company" => {
        "name"       => "House of de Vil",
        "supervisor" => {
            "name"   => "Cruella de Vil",
            "rating" => [
                {   "support"  => -9,
                    "guidance" => -9
                }
            ]
        },
        "tags" => [
            "evil",
            "cruelty",
            "dogs"
        ]
    },
};

ok $class->validate_document(person => $person), "T document (person) validated";
ok $person->{id} !~ /\D/, "person document has been filtered";

done_testing;
