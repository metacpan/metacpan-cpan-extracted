use strictures 2;
use Test::More;

BEGIN {

    package My::SugarFactory;
    use MooX::SugarFactory;
    class "My::Moo::Object" => (
        has => [ plus => ( is => 'ro' ) ],
        has => [ more => ( is => 'ro' ) ],
    );
    role "My::Moo::ThingRole" => (
        has => [ contains => ( is => 'ro' ) ],
        has => [ mota     => ( is => 'ro' ) ],
    );
    class "My::Moo::Thing" => ( with => ThingRole(), extends => Object() );
    class "My::Moo::CustomCons->cons" => (
        has     => [ contains => ( is => 'ro' ) ],
        has     => [ meta     => ( is => 'ro' ) ],
        install => [ cons     => sub  { My::Moo::CustomCons->new } ],
    );
    $INC{"My/SugarFactory.pm"}++;
}

use My::SugarFactory;
ok my $obj = object plus => "some", more => "data";
ok $obj->isa( Object );
is $obj->plus, "some";
is Object, "My::Moo::Object";

ok my $obj2 =    #
  thing contains => "other", mota => "data", plus => "some", more => "data";
ok $obj2->isa( Thing );
ok $obj2->isa( Object );
ok $obj2->does( ThingRole );
is $obj2->contains, "other";
is $obj2->plus,     "some";
is Thing, "My::Moo::Thing";

ok my $obj3 = custom_cons contains => "other", meta => "data";
ok $obj3->isa( CustomCons );
is $obj3->contains, undef;
is CustomCons, "My::Moo::CustomCons";

done_testing;
