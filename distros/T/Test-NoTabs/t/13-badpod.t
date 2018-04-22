use strict;
use warnings;

use Test::More qw(no_plan);

use File::Temp qw( tempdir tempfile );

my $perl  = $^X || 'perl';

# Test to check that bad Pod doesn't break subsequent files. Here the test is that
# both files should be detected as containing tabs, when tested one after the
# other.

{
    my $dir = tempdir();
    make_bad_pod_file($dir);
    make_bad_tab_file($dir);
    my (undef, $outfile) = tempfile();
    ok( `$perl -MTest::NoTabs -e "all_perl_files_ok( '$dir' )" 2>&1 > $outfile` );
    local $/ = undef;
    open my $fh, '<', $outfile or die $!;
    my $content = <$fh>;

    # Filter the ok 1 line as we really don't care - it doesn't contain a tab anyway
    $content =~ s{^ok 1[^\n]*\n}{}s;

    like( $content, qr/^not ok 2 - No tabs in '[^']*' on line 4/m, 'tabs found in tmp file 2' );
    unlink $outfile;
    system("rm -rf $dir");
}

sub make_bad_pod_file {
  my ($tmpdir) = @_;

  # First file, template begins "a"
  my ($fh, $filename) = tempfile( "a_badpod_XXXXXX", DIR => $tmpdir, SUFFIX => '.pL' );
  print $fh <<"DUMMY";
#!perl

=head1

Some unterminated Pod documentation follows, otherwise the file is OK

DUMMY
  close($fh);
  return $filename;
}
sub make_bad_tab_file {
  my ($tmpdir) = @_;

  # Second file, template begins "b"
  my ($fh, $filename) = tempfile( "b_badtab_podtest_XXXXXX", DIR => $tmpdir, SUFFIX => '.pL' );
  print $fh <<"DUMMY";
#!perl

sub main {
\tprint "Hello!\n";
}

DUMMY
  close($fh);
}

