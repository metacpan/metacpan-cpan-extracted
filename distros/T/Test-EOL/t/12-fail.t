use strict;
use warnings;

use Test::More qw(no_plan);

use File::Temp qw( tempdir tempfile );
my $perl  = $^X || 'perl';
require Config;
my $inc = join($Config::Config{path_sep}, @INC) || '';

{
    my ( $dir, $filename ) = make_raw_badfile();
    local $/ = undef;
    open my $fh, '<', $filename or die $!;
    binmode( $fh, ':raw' );
    my $content = <$fh>;
    is( $content, ascii_string(), 'Data written to file is there when we look for it later' );

}
{
    my $dir = make_bad_file_1();
    run_ok( "all_perl_files_ok( '$dir' )",
            qr/^not ok 1 - No incorrect line endings in '[^']*' \Qon line 5: [\r]/m,
            'windows EOL found in tmp file 1' );
}
{
    my $dir = make_bad_file_2();
    run_ok( "all_perl_files_ok( '$dir' )",
            qr/^not ok 1 - No incorrect line endings in '[^']*' \Qon line 8: [\r][\r][\r][\r][\r][\r][\r]/m,
            'windows EOL found in tmp file2 ' );
}
{
    my ($dir, $file) = make_bad_file_3();
    run_ok( "all_perl_files_ok( '$file' )",
            qr/^not ok 1 - No incorrect line endings in '[^']*' \Qon line 1: [\r]/m,
            'windows EOL found in tmp file 3' );
}

{
    my $dir = make_bad_file_4();
    run_ok( "all_perl_files_ok({trailing_whitespace => 1}, '$dir' )",
            # Note that line number will be 13
            qr/^not ok 1 - No incorrect line endings in '[^']*' \Qon line 12: [\s][\t][\s][\s]/m,
            'Trailing ws EOL found in tmp file 4' );
}

sub run_ok {
    my ($code, $match, $test_name) = @_;
    my (undef, $file, $line) = caller;
    die "code containing double quotes is not portable on Win32 in one-liners at $file $line.\n" if $code =~ /"/;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my (undef, $outfile) = tempfile();
    local $ENV{PERL5LIB} = $inc;
    is( `$perl -MTest::EOL -e "$code" > $outfile 2>&1`, '', "test sub program: output redirected" );
    is( $? >> 8, 1, "test sub program: exit code is 1" );
    local $/ = undef;
    open my $fh, '<', $outfile or die "Can't open $outfile: $!";
    my $content = <$fh>;
    close $fh or die "Can't close $outfile: $!";
    like( $content, $match, $test_name );
    unlink $outfile;
}

sub ascii_string {
  my $o = "<before \r\n between \r\n after \n normal >";
  return $o x 3;
}

sub make_raw_badfile {
  my $tmpdir = tempdir( CLEANUP => 1 );
  my ( $fh, $filename ) = tempfile( DIR => $tmpdir, SUFFIX =>  '.tXt' );
  binmode $fh, ':raw';
  print $fh ascii_string();
  close $fh;
  return ( $tmpdir, $filename );
}


sub make_bad_file_1 {
  my $tmpdir = tempdir( CLEANUP => 1 );
  my ($fh, $filename) = tempfile( DIR => $tmpdir, SUFFIX => '.pl' );
  binmode $fh, ':raw';
  my $str = <<"DUMMY";
#!perl

sub main {
    # Note that the generated file will have the CRLF expanded in the source
    print "Hello!\r\n";
}
DUMMY
  print $fh $str;

  return $tmpdir;
}

sub make_bad_file_2 {
  my $tmpdir = tempdir( CLEANUP => 1 );
  my ($fh, $filename) = tempfile( DIR => $tmpdir, SUFFIX => '.pl' );
  binmode $fh, ':raw';
  print $fh <<"DUMMY";
#!perl

=pod

=head1 NAME

test.pl -	A test script
\r\r\r\r\r\r\r\r
=cut

sub main {
    print "Hello!\\n";
}
DUMMY
  return $tmpdir;
}

sub make_bad_file_3 {
  my $tmpdir = tempdir( CLEANUP => 1 );
  my ($fh, $filename) = tempfile( DIR => $tmpdir, SUFFIX => '.pm' );
  binmode $fh, ':raw';
  print $fh <<"DUMMY";
use strict;\r
\r
package My::Test;\r
\r
sub new {\r
    my (\$class) = \@_;\r
    my \$self = bless { }, \$class;\r
    return \$self;\r
}\r
\r
\r
1;\r
DUMMY
  close $fh;
  return ($tmpdir, $filename);
}

sub make_bad_file_4 {
  my $tmpdir = tempdir( CLEANUP => 1 );
  my ($fh, $filename) = tempfile( DIR => $tmpdir, SUFFIX => '.pl' );
  binmode $fh, ':raw';
  print $fh <<'DUMMY';
#!perl

=pod

=head1 NAME

test.pl -	A test script

=cut

sub main {
DUMMY

print $fh qq{    print "Hello!\\n"; \t  \n}; # <-- whitespace
print $fh '}';

  return $tmpdir;
}

