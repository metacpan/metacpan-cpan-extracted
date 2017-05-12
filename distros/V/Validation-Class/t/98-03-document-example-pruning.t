use utf8;
use strict;
use warnings;
use Test::More;

{

    package T;

    use Validation::Class;

    field  'string' => { mixin => ':str' };

    document 'user' => {
        'id'          => 'string',
        'name'        => 'string',
        'email'       => 'string',
        'comp*'       => 'string'
    };

    package main;

    my $class;

    eval { $class = T->new; };

    ok "T" eq ref $class, "T instantiated";

    my $documents = $class->prototype->documents;

    ok "Validation::Class::Mapping" eq ref $documents, "T documents hash registered as setting";

    ok 1 == keys %{$documents}, "T has 1 registered document";

    my $user = $documents->{user};

    ok 4 == keys %{$user}, "T user document has 3 mappings";

    can_ok $class, 'validate_document';

    my $data = {
        "id"        => 1234,
        "type"      => "Master",
        "name"      => "Root",
        "company"   => "System, LLC",
        "login"     => "root",
        "email"     => "root\@localhost",
        "locations" => [
            {
                "id"       => 9876,
                "type"     => "Node",
                "name"     => "DevBox",
                "company"  => "System, LLC",
                "address1" => "123 Street Road",
                "address2" => "Suite 2",
                "city"     => "SINCITY",
                "state"    => "NO",
                "zip"      => "00000"
            }
        ]
    };

    ok $class->validate_document(user => $data, {prune => 1}), "T document (user) valid";

    my $_data = {
        "id"      => 1234,
        "name"    => "Root",
        "company" => "System, LLC",
        "email"   => "root\@localhost",
    };

    is_deeply $data, $_data, "T document has the correct pruned structure";

}

done_testing;
