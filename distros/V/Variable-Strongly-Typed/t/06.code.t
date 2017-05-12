use Test::More tests => 4;
use Carp;
use IO::File;

BEGIN {
use_ok( 'Variable::Strongly::Typed' );
}

my $ret :TYPE('int');

diag( "Testing Variable::Strongly::Typed $Variable::Strongly::Typed::VERSION" );

# lots wrong here
sub zot :TYPE('int', \&krap) {
    return 'sdklsdlk';
}

sub flot :TYPE('int') {
    return 123;
}

sub krap {
    my($msg) = @_;
    diag("Caught bad assignment: @_");
}

sub io_file :TYPE('IO::File') {
    return new IO::File;
}

eval {
$ret = zot();
};
ok($@, "Bad assignment");

ok($ret = flot());

my $file :TYPE('IO::File') = io_file();
ok($file, "Got an IO::File in an IO::File!");

