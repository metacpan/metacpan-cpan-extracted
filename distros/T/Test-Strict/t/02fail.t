#!/usr/bin/perl -w

##
## Tests errors
## by creating files with incorrect syntax or no "use strict;"
## and run Test::Strict under an external perl interpreter.
## The output is parsed to check result.
##

use strict;
BEGIN {
  if ($^O =~ /win32/i) {
    require Test::More;
    Test::More->import(
      skip_all => "Windows does not allow two processes to access the same file."
    );
  }
}

use IO::Scalar;
use Test::More tests => 15;
use File::Temp qw( tempdir tempfile );

my $perl  = $^X || 'perl';
my $inc = join(' -I ', @INC) || '';
$inc = "-I $inc" if $inc;

require Test::Strict;

test1();
test2();
test3();
test4();
test5();

TODO: {
  local $TODO = 'improve strict matching!';
  my $code = q{print "use strict "};
  my $fh1 = new IO::Scalar \$code;
  ok !Test::Strict::_strict_ok($fh1), 'use strict in print';
}

exit;


sub test1 {
  my $bad_file_content = _bad_file_content();
  my $fh1 = new IO::Scalar \$bad_file_content;
  ok !Test::Strict::_strict_ok($fh1), 'bad_file';

  my $dir = make_bad_file();
  my ($fh, $outfile) = tempfile( UNLINK => 1 );
  ok( `$perl $inc -MTest::Strict -e "all_perl_files_ok( '$dir' )" 2>&1 > $outfile`, 'all_perl_files_ok' );
  local $/ = undef;
  my $content = <$fh>;
  like( $content, qr/^ok 1 - Syntax check /m, "Syntax ok" );
  like( $content, qr/not ok 2 - use strict /, "Does not have use strict" );
}

sub test2 {
  my $dir = make_another_bad_file();
  my ($fh, $outfile) = tempfile( UNLINK => 1 );
  ok( `$perl $inc -MTest::Strict -e "all_perl_files_ok( '$dir' )" 2>&1 > $outfile` );
  local $/ = undef;
  my $content = <$fh>;
  like( $content, qr/not ok 1 \- Syntax check /, "Syntax error" );
  like( $content, qr/^ok 2 \- use strict /m, "Does have use strict" );
}

sub test3 {
  my $file = make_bad_warning();
  my ($fh, $outfile) = tempfile( UNLINK => 1 );
  ok( `$perl $inc -e "use Test::Strict no_plan =>1; warnings_ok( '$file' )" 2>&1 > $outfile` );
  local $/ = undef;
  my $content = <$fh>;
  like( $content, qr/not ok 1 \- use warnings /, "Does not have use warnings" );
}

sub test4 {
  my $test_file = make_warning_files();
  my ($fh, $outfile) = tempfile( UNLINK => 1 );
  ok( `$perl $inc $test_file 2>&1 > $outfile` );
  local $/ = undef;
  my $content = <$fh>;
  like( $content, qr/not ok \d+ \- use warnings/, "Does not have use warnings" );
}

sub test5 {
  eval "require Moose::Autobox";
  my $err = $@;
  SKIP: {
    skip 'Moose::Autobox is needed for this test', 3 if $err;
    my $dir = make_moose_bad_file();
    my ($fh, $outfile) = tempfile( UNLINK => 1 );
    ok( `$perl $inc -MTest::Strict -e "all_perl_files_ok( '$dir' )" 2>&1 > $outfile` );
    local $/ = undef;
    my $content = <$fh>;
    like( $content, qr/^ok 1 - Syntax check /m, "Syntax ok" );
    like( $content, qr/not ok 2 - use strict /, "Does not have use strict" );
  }
}


sub make_bad_file {
  my $tmpdir = tempdir( CLEANUP => 1 );
  my ($fh, $filename) = tempfile( DIR => $tmpdir, SUFFIX => '.pL' );
  print $fh _bad_file_content();
  return $tmpdir;
}

sub _bad_file_content {
    return <<'DUMMY';
print "Hello world without use strict";
# use strict;
=over
use strict;
=back

=for
use strict;
=end

=pod
use strict;
=cut

DUMMY
}

sub make_another_bad_file {
  my $tmpdir = tempdir( CLEANUP => 1 );
  my ($fh, $filename) = tempfile( DIR => $tmpdir, SUFFIX => '.pm' );
  print $fh <<'DUMMY';
=pod
blah
=cut
# a comment
undef;use    strict ; foobarbaz + 1; # another comment
DUMMY
  return $tmpdir;
}

sub _print_autobox_stmt_to_avoid_a_CPANTS_warnings {
  my ($fh) = @_;

  print {$fh} (lc('U' . 'S' . 'E') . " Moose::Autobox;\n");

  return;
}

sub make_moose_bad_file {
  my $tmpdir = tempdir( CLEANUP => 1 );
  my ($fh, $filename) = tempfile( DIR => $tmpdir, SUFFIX => '.pm' );
  print $fh <<'DUMMY';
# Makes methods for plain Perl types with autobox
# No 'use Moose' here and no strictures turned on
DUMMY
  _print_autobox_stmt_to_avoid_a_CPANTS_warnings($fh);
  return $tmpdir;
}


sub make_bad_warning {
  my $tmpdir = tempdir( CLEANUP => 1 );
  my ($fh, $filename) = tempfile( DIR => $tmpdir, SUFFIX => '.pL' );
  print $fh <<'DUMMY';
print "Hello world without use warnings";
# use warnings;
=over
use warnings;
=back

=for
use warnings;
=end

=pod
use warnings;
=cut

DUMMY
  return $filename;
}

sub make_warning_files {
  my $tmpdir = tempdir( CLEANUP => 1 );
  my ($fh1, $filename1) = tempfile( DIR => $tmpdir, SUFFIX => '.pm' );
  print $fh1 <<'DUMMY';
use strict;
use  warnings::register ;
print "Hello world";

DUMMY

  my ($fh2, $filename2) = tempfile( DIR => $tmpdir, SUFFIX => '.pl' );
  print $fh2 <<'DUMMY';
#!/usr/bin/perl -vw
use strict;
print "Hello world";

DUMMY

  my ($fh3, $filename3) = tempfile( DIR => $tmpdir, SUFFIX => '.pl' );
  print $fh3 <<'DUMMY';
use  strict;
local $^W = 1;
print "Hello world";

DUMMY

  my ($fh4, $filename4) = tempfile( DIR => $tmpdir, SUFFIX => '.pl' );
  print $fh4 <<"TEST";
use  strict;
use warnings;
use Test::Strict 'no_plan';
local \$Test::Strict::TEST_WARNINGS = 1;
all_perl_files_ok( '$tmpdir' );

TEST

  return $filename4;
}
