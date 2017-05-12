BEGIN {
    sub rig::task::strictness::rig {
        {
			use => [
				'strict',
				{ 'warnings'=> [ 'FATAL','all' ] }
			],
		}
    };
}
package main;
use Test::More;
use rig 'strictness';

{
    eval q{
        $var = 1;
    };
    like( $@, qr/requires explicit/, 'check strict');
}
{
    eval q{
        use warnings 'all' => 'FATAL';
        my $var;
        my $foo = "$var";
    };
    like( $@, qr/uninitialized/, 'check warnings');
}
done_testing();
