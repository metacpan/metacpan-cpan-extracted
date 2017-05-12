use Test::More tests => 13;

use lib '../lib';

BEGIN {
    use_ok( 'UNIVERSAL::cant' );
}

diag( "Testing cant $UNIVERSAL::cant::VERSION mthods" );

use Digest::MD5;
my $ns  = 'Digest::MD5';
my $obj = Digest::MD5->new();

ok( !Digest::MD5->cant('md5'),  'Bare name space valid');
ok( Digest::MD5->cant('dance'), 'Bare name space invalid');

ok( !$ns->cant('md5'),  'Var name space valid');
ok( $ns->cant('dance'), 'Var name space invalid');

ok( !$obj->cant('md5'),  'Obj valid');
ok( $obj->cant('dance'), 'Obj invalid');

ok( !Digest::MD5->can't('md5'), 'apostrophy Bare name space valid');
ok( Digest::MD5->can't('dance'), 'apostrophy Bare name space invalid');

ok( !$ns->can't('md5'),  'apostrophy Var name space valid');
ok( $ns->can't('dance'), 'apostrophy Var name space invalid');

ok( !$obj->can't('md5'),  'apostrophy Obj valid');
ok( $obj->can't('dance'), 'apostrophy Obj invalid');