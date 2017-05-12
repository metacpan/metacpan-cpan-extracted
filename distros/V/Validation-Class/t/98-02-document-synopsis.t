use utf8;
use strict;
use warnings;
use Test::More;

{

    package T1;

    use Validation::Class;

    field  'title';
    field  'rating';
    field  'name';
    field  'id';

    document 'company' => {
        'company.name'                  => 'name',
        'company.supervisor.name'       => 'name',
        'company.supervisor.rating.@.*' => 'rating',
        'company.tags.@'                => 'name'
    };

    package main;

    my $class;

    eval { $class = T1->new; };

    ok "T1" eq ref $class, "T1 instantiated";

    my $person = {
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

    ok $class->validate_document(company => $person), "T1 document (company) validated";

}

{

    package T2;

    use Validation::Class;

    field  'id' => {
        mixin      => [':str'],
        filters    => ['numeric'],
        max_length => 2,
    };

    field  'name' => {
        mixin      => [':str'],
        pattern    => qr/^[A-Za-z ]+$/,
        max_length => 20,
    };

    field  'tag' => {
        mixin      => [':str'],
        pattern    => qr/^(?!evil)\w+/,
        max_length => 20,
    };

    document 'company' => {
        'id'                            => 'id',
        'company.name'                  => 'name',
        'company.supervisor.name'       => 'name',
        'company.tags.@'                => 'tag'
    };

    package main;

    my $class;

    eval { $class = T2->new(ignore_unknown => 1); };

    ok "T2" eq ref $class, "T2 instantiated";

    my $person = {
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

    ok ! $class->validate_document(company => $person), "T2 document (company) did not validate";

}

done_testing;
