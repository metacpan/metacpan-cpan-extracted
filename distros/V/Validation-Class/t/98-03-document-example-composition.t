use utf8;
use strict;
use warnings;
use Test::More;

BEGIN {

    use FindBin;
    use lib $FindBin::Bin . '/lib';

}

{

    package T;

    use Validation::Class;

    set roles => [
        'T::User',
        'T::Location'
    ];

    package main;

    my $class;

    eval { $class = T->new; };

    ok "T" eq ref $class, "T instantiated";

    my $documents = $class->prototype->documents;

    ok "Validation::Class::Mapping" eq ref $documents, "T documents hash registered as setting";

    ok 2 == keys %{$documents}, "T has 2 registered document";

    my $user = $documents->{'user'};

    ok 7 == keys %{$user}, "T user document has 6 mappings";

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

    ok ! $class->validate_document(user => $data), "T document (user) not valid";
    ok $class->errors_to_string =~ /locations\.0\.state/, "T proper error message set";

    $class->prototype->documents->{'location'}->{state} = 'string';

    ok $class->validate_document(user => $data), "T document (user) validated";

}

done_testing;
