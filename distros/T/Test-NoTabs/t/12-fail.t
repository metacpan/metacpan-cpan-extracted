use strict;
use warnings;

use Test::More qw(no_plan);

use File::Temp qw( tempdir tempfile );

my $perl  = $^X || 'perl';
$perl = $perl =~ m/\s/ ? qq{"$perl"} : $perl;
my $inc = "-I blib/arch -I blib/lib";

{
    my $dir = make_bad_file_1();
    my (undef, $outfile) = tempfile();
    ok( `$perl $inc -MTest::NoTabs -e "all_perl_files_ok( '$dir' )" 2>&1 > $outfile` );
    local $/ = undef;
    open my $fh, '<', $outfile or die $!;
    my $content = <$fh>;
    like( $content, qr/^not ok 1 - No tabs in '[^']*' on line 4/m, 'tabs found in tmp file 1' );
    unlink $outfile;
    system("rm -rf $dir");
}

{
    my $dir = make_bad_file_2();
    my (undef, $outfile) = tempfile();
    ok( `$perl $inc -MTest::NoTabs -e "all_perl_files_ok( '$dir' )" 2>&1 > $outfile` );
    open my $fh, '<', $outfile or die $!;
    local $/ = undef;
    my $content = <$fh>;
    like( $content, qr/^not ok 1 - No tabs in '[^']*' on line 12/m, 'tabs found in tmp file2 ' );
    unlink $outfile;
    system("rm -rf $dir");
}

{
    my ($dir, $file) = make_bad_file_3();
    my (undef, $outfile) = tempfile();
    ok( `$perl $inc -MTest::NoTabs -e "all_perl_files_ok( '$file' )" 2>&1 > $outfile` );
    open my $fh, '<', $outfile or die $!;
    local $/ = undef;
    my $content = <$fh>;
    like( $content, qr/^not ok 1 - No tabs in '[^']*' on line 6/m, 'tabs found in tmp file 3' );
    unlink $outfile;
    system("rm -rf $dir");
}

{
    my ($dir, $file) = make_bad_file_4();
    my (undef, $outfile) = tempfile();
    ok( `$perl $inc -MTest::NoTabs -e "all_perl_files_ok( '$file' )" 2>&1 > $outfile` );
    open my $fh, '<', $outfile or die $!;
    local $/ = undef;
    my $content = <$fh>;
    like( $content, qr/^not ok 1 - No tabs in '[^']*' on line 10/m, 'tabs found in tmp file 4' );
    unlink $outfile;
    system("rm -rf $dir");
}

sub make_bad_file_1 {
  my $tmpdir = tempdir();
  my ($fh, $filename) = tempfile( DIR => $tmpdir, SUFFIX => '.pL' );
  print $fh <<"DUMMY";
#!perl

sub main {
\tprint "Hello!\n";
}
DUMMY
  return $tmpdir;
}

sub make_bad_file_2 {
  my $tmpdir = tempdir();
  my ($fh, $filename) = tempfile( DIR => $tmpdir, SUFFIX => '.pL' );
  print $fh <<"DUMMY";
#!perl

=pod

=head1 NAME

test.pL -	A test script

=cut

sub main {
\tprint "Hello!\n";
}
DUMMY
  return $tmpdir;
}

sub make_bad_file_3 {
  my $tmpdir = tempdir();
  my ($fh, $filename) = tempfile( DIR => $tmpdir, SUFFIX => '.pm' );
  print $fh <<"DUMMY";
use strict;

package My::Test;

sub new {
\tmy (\$class) = @_;
\tmy \$self = bless { }, \$class;
\treturn \$self;
}

1;
__DATA__
nick	gerakines	software engineer	22
DUMMY
  close $fh;
  return ($tmpdir, $filename);
}

sub make_bad_file_4 {
  my $tmpdir = tempdir();
  my ($fh, $filename) = tempfile( DIR => $tmpdir, SUFFIX => '.pm' );
  print $fh <<"DUMMY";
use strict;

package My::Test;

sub new {
my (\$class) = @_;
# split the assignment state below to make the second half look like a pod section
my \$self
= bless { }, \$class;
\treturn \$self;
}

1;
DUMMY
  close $fh;
  return ($tmpdir, $filename);
}
