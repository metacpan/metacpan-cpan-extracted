use strictures 2;
use Test::More;

BEGIN {

    package My::Moo::Object;
    use Moo;
    has $_ => ( is => 'ro' ) for qw( plus more );
}

BEGIN {

    package My::Moo::Object2;
    use Moo;
    has $_ => ( is => 'ro' ) for qw( plus more );
    sub cons { __PACKAGE__->new }
}

BEGIN {

    package Sugar::Library;
    use Test::More;
    use Test::Fatal;
    use Constructor::SugarLibrary;
    sweeten "My::Moo::Object";
    sweeten "My::Moo::Object2->cons";
    ok exception { sweeten "My::Moose::Object" };
    $INC{"Sugar/Library.pm"}++;
}

{
    use Sugar::Library;

    ok my $obj = object plus => "some", more => "data";
    ok $obj->isa( Object );
    is Object, "My::Moo::Object";
    is $obj->plus, "some";
    is $obj->more, "data";

    ok my $obj2 = object2 plus => "some", more => "data";
    ok $obj2->isa( Object2 );
    is Object2, "My::Moo::Object2";
    is $obj2->plus, undef;
    is $obj2->more, undef;
}

{

    package A;
    use Test::More;
    use Sugar::Library ':ctors';

    ok __PACKAGE__->can( "object" );
    ok !__PACKAGE__->can( "Object" );
}

{

    package B;
    use Test::More;
    use Sugar::Library ':ids';

    ok !__PACKAGE__->can( "object" );
    ok __PACKAGE__->can( "Object" );
}

{

    package C;
    use Test::More;
    use Sugar::Library ':Object';

    ok __PACKAGE__->can( "object" );
    ok __PACKAGE__->can( "Object" );
}

done_testing;
