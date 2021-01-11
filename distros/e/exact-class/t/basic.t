use Test2::V0;

my $thing = q/
    package Thing {
        use exact 'class';

        has 'name';
        has [ 'name1', 'name2', 'name3' ];
        has name4 => undef;
        has name5 => 'foo';
        has name6 => sub { return 1024 };
        has [ 'name7', 'name8', 'name9' ]    => 'foo';
        has [ 'name10', 'name11', 'name12' ] => sub { return 1024 };
        has name13 => 'default';

        has 'answer';
        class_has thing => 'shared';
    }
/;

my ( $obj, $obj2 );
ok( lives { eval $thing }, 'package definition indirect' ) or note $@;
ok( lives { Thing->attr( password => 12345 ) }, 'Package->attr(...)' ) or note $@;
ok( lives { Thing->attr( method => sub { $_[0]->password } ) }, 'Package->attr( sub {...} )' ) or note $@;
ok( lives { $obj = Thing->new( answer => 42, name13 => 13 ) }, 'new( answer => 42, name13 => 13 )' ) or note $@;
ok( lives { $obj2 = Thing->new( { answer => 43 } ) }, 'new( { answer => 43 } )' ) or note $@;

sub exercise {
    my ( $obj, $obj2 ) = @_;

    is( $obj->answer, 42, 'answer returns correct value' );
    is( $obj2->answer, 43, 'answer on other obj returns correct value' );
    is( $obj->answer(1138), $obj, 'answer($value) returns object' );
    is( $obj->answer, 1138, 'answer value changed' );
    is( $obj2->answer, 43, 'answer on other obj still returns correct value' );

    is( $obj->name, undef, 'name returns undef' );
    is( $obj->name2, undef, 'name2 returns undef' );
    is( $obj->name4, undef, 'name4 returns undef' );
    is( $obj->name5, 'foo', 'name5 returns correct value' );
    is( $obj->name6, 1024, 'name6 returns correct value' );
    is( $obj->name8, 'foo', 'name8 returns correct value' );
    is( $obj->name11, 1024, 'name6 returns correct value' );

    is( $obj->name13, 13, 'name13 returns correct value' );
    is( $obj2->name13, 'default', 'name13 returns correct value' );

    is( $obj->thing, 'shared', 'class_has value correct' );
    is( $obj2->thing, 'shared', 'class_has value correct' );
    is( $obj->thing('changed'), $obj, 'class_has value set returns obj' );
    is( $obj->thing, 'changed', 'class_has changed value correct' );
    is( $obj2->thing, 'changed', 'class_has changed value correct' );

    is( $obj->password, 12345, 'password value correct' );
    is( $obj->password(54321), $obj, 'password($value) returns object' );
    is( $obj->password, 54321, 'password value changed' );

    is( $obj->method, 54321, 'password via "method" attr value' );

    ok( lives { $obj->attr('attr0') }, q{attr('attr0')} ) or note $@;
    ok( lives { $obj->attr( attr1 => 'value' ) }, q{attr( attr1 => 'value' )} ) or note $@;

    is( $obj->attr0, undef, 'attr0 returns undef' );
    is( $obj->attr1, 'value', 'attr1 returns undef' );
    is( $obj->attr0(42), $obj, 'attr0($value) returns object' );
    is( $obj->attr0, 42, 'attr0 returns 42' );

    is( $obj->tap( sub { $_->password(123456) } )->password, 123456, 'tap()' );
    is( $obj->tap( 'password', 1234567 )->password, 1234567, 'tap()' );
}

exercise( $obj, $obj2 );

$thing =~ s/use exact 'class'/use exact::class/;
$thing =~ s/package Thing/package ThingIndirect/;

ok( lives { eval $thing }, 'package definition direct' ) or note $@;
ok( lives { ThingIndirect->attr( password => 12345 ) }, 'Package->attr(...)' ) or note $@;
ok( lives { ThingIndirect->attr( method => sub { $_[0]->password } ) }, 'Package->attr( sub {...} )' ) or note $@;
ok( lives { $obj = ThingIndirect->new( answer => 42, name13 => 13 ) }, 'new( answer => 42, name13 => 13 )' ) or note $@;
ok( lives { $obj2 = ThingIndirect->new( { answer => 43 } ) }, 'new( { answer => 43 } )' ) or note $@;

exercise( $obj, $obj2 );

done_testing;
