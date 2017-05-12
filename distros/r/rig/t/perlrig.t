use FindBin '$Bin';
BEGIN {
	$ENV{PERLRIG_FILE} = $Bin . '/perlrig'
}

use Test::More;
{
    use rig '_t_perlrig';
    use rig '_t_perlrig_utils';

    eval q{
        $var = 1;
    };
    like( $@, qr/requires explicit/, 'check strict');
    is( sum(1..10), 55, 'sum' );
    is( max(1..10), 10, 'max' );
    is( do { firstval { $_ eq 10 } 1..20 } , 10, 'firstval' );
    ok( do { any { $_ eq 10 } 1..20 }, 'any' );
}

SKIP: {
    skip 'no moose',2 unless eval 'require Moose'; 
    {
        package TestMe;
        use rig '_t_mooseness';
        has 'name' => is=>'rw', isa=>'Str';
    }
    {
        package main;
        my $obj = TestMe->new;
        is( ref($obj), 'TestMe', 'moose new' );
        is( $obj->name('testing'), 'testing', 'moose accessor');
    }
}

{
    use rig '_t_alias';
    is( summa1(1..10), 55, 'summa1 alias' );
    is( summa2(1..10), 55, 'summa2 alias' );
    is( maxxy(1..10), 10, 'maxxy alias' );
    ok( !eval 'max(1..10); 1', 'max original delete' );
}

{
    use rig '_t_optional';
    is( sum(1..10), 55, 'sum and optional' );
}

{
    eval q{ use rig '_t_version' };
    ok( $@, 'version ok' );
}

{
    use rig '_t_also';
    my $a = eval q{ timethese(1,{a=>sub{},b=>sub{}}); 1}
    ; print $@;
    is( $a, 1 , 'also' );
}

done_testing;

