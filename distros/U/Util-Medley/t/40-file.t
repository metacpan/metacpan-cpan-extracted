use Test2::V0;
use Test2::Plugin::DieOnFail;
use Modern::Perl;
use Util::Medley::File;
use Data::Printer alias => 'pdump';

###################################################

use vars qw($File);

$File = Util::Medley::File->new;
ok($File);

test_basename();
test_chdir();
test_dirname();
test_parsePath();

done_testing;

###################################################

sub test_chdir {

	ok( my $orig_path = $File->chdir('/tmp') );
	ok( $File->getcwd eq '/tmp' );
	ok( $File->chdir($orig_path) );
	ok( $File->getcwd eq $orig_path );
}

sub test_basename {

	ok( $File->basename('foo.txt') eq 'foo.txt' );
	eval { $File->basename };
	ok($@);
}

sub test_dirname {

	my $dir = $File->dirname('foo.txt');
	ok( $dir eq '.' );

	$dir = $File->dirname('./foo.txt');
	ok( $dir eq '.' );

	ok( $File->dirname('bar/foo.txt') eq 'bar' );
	ok( $File->dirname('/a/b/c.txt') eq '/a/b' );
}

sub test_parsePath {

	my $path = "/my/dir/myfile.txt";
	my ( $dir, $filename, $ext ) = $File->parsePath($path);
	ok( $dir eq '/my/dir' );
	ok( $filename eq 'myfile' );
	ok( $ext eq 'txt' );

	$path = "myfile.txt";
	( $dir, $filename, $ext ) = $File->parsePath($path);
	ok( $dir eq './' );
	ok( $filename eq 'myfile' );
	ok( $ext eq 'txt' );
}

