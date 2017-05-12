use utf8;
use strict;
use warnings;
use Test::More;

{

    package T0;

    use Validation::Class;

    field 'string' => {
        mixin => ':str'
    };

    document 'user' => {
        'name'  => 'string',
        'email' => 'string',
    };

    package main;

    my $class = eval { T0->new };

    ok "T0" eq ref $class, "T0 instantiated";

    my $data = {};

    ok ! $class->validate_document(user => $data), "T0 document (user) not valid";
    ok 2 == $class->error_count, "T0 document failed with 2 errors";

}

{

    package T1;

    use Validation::Class;

    field 'string' => {
        mixin => ':str'
    };

    document 'user' => {
        'id'          => 'string',
        'name'        => 'string',
        'email'       => 'string',
        'comp*'       => 'string'
    };

    package main;

    my $class = eval { T1->new };

    ok "T1" eq ref $class, "T1 instantiated";

    my $documents = $class->prototype->documents;

    ok "Validation::Class::Mapping" eq ref $documents, "T1 documents hash registered as setting";

    ok 1 == keys %{$documents}, "T1 has 1 registered document";

    my $user = $documents->{user};

    ok 4 == keys %{$user}, "T1 user document has 3 mappings";

    can_ok $class, 'validate_document';

    my $data = {
        "id"        => 1234,
        "type"      => "Master",
        "name"      => "Root",
        "company"   => "System, LLC",
        "login"     => "root",
        "email"     => "root\@localhost",
        "office_locations" => [
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

    ok $class->validate_document(user => $data), "T1 document (user) valid";
    ok 0 == $class->error_count, "T1 document passed with no errors";

}

{

    package T2;

    use Validation::Class;

    field 'string' => {
        mixin => ':str'
    };

    document 'user' => {
        'id'          => 'string',
        'name'        => 'string',
        'email'       => 'string',
        'comp*'       => 'string'
    };

    package main;

    my $class = eval { T2->new };

    ok "T2" eq ref $class, "T2 instantiated";

    my $documents = $class->prototype->documents;

    ok "Validation::Class::Mapping" eq ref $documents, "T2 documents hash registered as setting";

    ok 1 == keys %{$documents}, "T2 has 1 registered document";

    my $user = $documents->{user};

    ok 4 == keys %{$user}, "T2 user document has 3 mappings";

    can_ok $class, 'validate_document';

    my $data = {
        "id"        => 1234,
        "type"      => "Master",
        "name"      => "Root",
        "company"   => "System, LLC",
        "login"     => "root",
        "email"     => "root\@localhost",
        "office_locations" => [
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

    ok $class->validate_document(user => $data), "T2 document (user) valid";
    ok 0 == $class->error_count, "T2 document has no errors";

}

done_testing;
