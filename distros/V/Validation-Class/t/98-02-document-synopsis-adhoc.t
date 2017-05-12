use utf8;
use strict;
use warnings;
use Test::More;

package T;

use Validation::Class;

package main;

my $data = {
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

my $schema = {
    'id'                        => { mixin => [':num'], max_length => 4 },
    'name'                      => { mixin => [':str'], min_length => 2 },
    'title'                     => { mixin => [':str'], min_length => 5 },
    'company.name'              => { mixin => [':str'], min_length => 2 },
    'company.tags.@'            => { mixin => [':str'], min_length => 2 },
    'company.super*.name'       => { mixin => [':str'], min_length => 2 },
    'company.super*.rating.@.*' => { mixin => [':str'], },
};

my $class;

eval { $class = T->new };

ok "T" eq ref $class, "T instantiated";

can_ok $class, 'validate_document';

ok $class->validate_document($schema => $data), "T (ad-hoc data) validated";
ok $data->{id} !~ /\D/, "document ID has been filtered";

done_testing;
