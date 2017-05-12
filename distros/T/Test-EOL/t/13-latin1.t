use strict;
use warnings;

use Test::More tests => 2;
use File::Temp qw( tempdir tempfile );

use Config;
$ENV{PERL5LIB} = join ($Config{path_sep}, @INC);

{
  my $tmpdir = tempdir( CLEANUP => 1 );
  my ($fh, $filename) = tempfile( DIR => $tmpdir, SUFFIX => '.pL' );
  print $fh "\xE1\xF3 how na\xEFve";
  close $fh;

  my (undef, $stderr) = tempfile();

  `$^X -MTest::EOL -e "all_perl_files_ok( '$tmpdir' )" 2>$stderr`;
  ok(! $? );

  my $out = do { local (@ARGV, $/) = $stderr; <> };

  is (
    $out,
    '',
    'no malformed unicode warnings on STDERR',
  );

  unlink $stderr;
}
