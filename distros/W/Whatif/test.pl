use Test::More tests=>20;

BEGIN { use_ok( 'Whatif' ); }
require_ok( 'Whatif' );

local $foo;
whatif {
    $foo = 'foo';
};
is( $foo, 'foo', "don't roll back");


whatif {
    $foo = 'bar';
    die;
} ifonly  {
};
is( $foo, 'foo', "roll back" );


my $a = 0;
whatif {
    $foo = 'foo';
} ifonly {     
    $foo = 'quux';
    $a = 1;
};

is( $foo, 'foo', "don't call ifonly");
is( $a, 0, "don't call ifonly");


my $b = 0;
whatif {
    $foo = 'foo';
    die;
} ifonly {
    $foo = 'quux';
    $b = 1;
};
is ($b, 1, "if only gets called");


whatif {
    $foo = 'bar';
    die;
} ifonly {
    $foo = 'quux';
};

is( $foo, 'quux', "call ifonly" );


whatif {

	$foo = 'bar';
	whatif {
		$foo = 'foo';
	};
};

is ($foo,'foo', "nested succeed");


whatif {

	$foo = 'bar';
	whatif {
		$foo = 'foo';
		die;
	};
};

is ($foo,'bar', "nested fail inner");

$foo = 'foo';

whatif {

        $foo = 'bar';
        whatif {
                $foo = 'foo';
        };
	die;
};

is ($foo,'foo', "nested fail outer");


my $dd = $$;

whatif {
};

is ($$, $dd, '$$ stays same after successful fork');
is ($Whatif::ERR, undef, 'undef error message');

my $was = $$;
my $going;
whatif {
	$going = $$;	
};

is ($going, $was, '$$ is same in whatif block');



$dd = $$;

whatif {
	die "Foo\n";
} ifonly {
	is ($Whatif::ERR, "Foo\n", 'propogated error message inside ifonly');
};

is ($Whatif::ERR, "Foo\n", 'propogated error message');

is ($$,	$dd, '$$ stays same after unsuccessful fork');



my $var = 'outer';

whatif {
	$var = 'middle';

	whatif { $var = 'inner'; };

};

is ($var, 'inner', 'Nested blocks');


$var = 'outer';

whatif {
	$var = 'middle';
	whatif { $var = 'inner'; die; };
};

is ($var, 'middle', 'Inner die');


$var = 'outer';

whatif {
    $var = 'middle';
    whatif { $var = 'inner'; die; };
	die;
};

is ($var, 'outer', 'Middle die');

