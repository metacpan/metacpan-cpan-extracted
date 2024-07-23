#!/usr/bin/perl -w
use strict;
use Test::More;
use Test::Strict;
use File::Temp qw( tempdir tempfile );

my $HAS_WIN32 = 0;
if ($^O =~ /MSWin/i) { # Load Win32 if we are under Windows and if module is available
  eval q{ use Win32 };
  if ($@) {
    warn "Optional module Win32 missing, consider installing\n";
  }
  else {
    $HAS_WIN32 = 1;
  }
}

my $tests = 57;
$tests += 2 if -e 'blib/lib/Test/Strict.pm';
plan  tests => $tests;

##
## This should check all perl files in the distribution
## including this current file, the Makefile.PL etc.
## and check for "use strict;" and syntax ok
##

diag "First all_perl_files_ok starting";
my $res = all_perl_files_ok();
is $res, '', 'returned empty string??';
diag "First all_perl_files_ok done";

strict_ok( $0, "got strict" );
syntax_ok( $0, "syntax" );
syntax_ok( 'Test::Strict' );
strict_ok( 'Test::Strict' );
warnings_ok( $0 );

my $tmpdir = tempdir( CLEANUP => 1 );
diag "Start creating files in $tmpdir";
my $modern_perl_file1 = make_file("$tmpdir/abc.pL", 'modern_perl_file1');
#diag $modern_perl_file1;
warnings_ok( $modern_perl_file1, 'warn modern_perl1' );
strict_ok( $modern_perl_file1, 'strict modern_perl1' );


# let's make sure that a file that is not recognized as "Perl file"
# still lets the syntax_ok test work
my $extensionless_file = make_file("$tmpdir/extensionless", 'extensionless');
#diag $extensionless_file;
ok ! Test::Strict::_is_perl_module($extensionless_file), "_is_perl_module $extensionless_file";
ok ! Test::Strict::_is_perl_script($extensionless_file), "_is_perl_script $extensionless_file";
warnings_ok( $extensionless_file, 'warn extensionless_file' );
strict_ok( $extensionless_file, 'strict extensionless_file' );
syntax_ok( $extensionless_file, 'syntax extensionless_file' );

my $warning_file1 = make_file("$tmpdir/warning1.pL", 'warning1');
#diag "File1: $warning_file1";
warnings_ok( $warning_file1, 'file1' );

my $warning_file2 = make_file("$tmpdir/warning2.pL", 'warning2');
#diag "File2: $warning_file2";
warnings_ok( $warning_file2, 'file2' );

# TODO: does warnings::register turn on warnings?
#my $warning_file3 = make_file("$tmpdir/warning3.pm", 'warning3');
#warnings_ok( $warning_file3, 'file3' );

my $warning_file4 = make_file("$tmpdir/warning4.pm", 'warning4');
#diag "File4: $warning_file4";
warnings_ok( $warning_file4, 'file4' );

my $warning_file5 = make_file("$tmpdir/warning5.pm", 'warning5');
#diag "File5: $warning_file5";
warnings_ok( $warning_file5, 'file5' );

my $warning_file7 = make_file("$tmpdir/warning7.pm", 'warning7');
strict_ok( $warning_file7, 'file7' );

subtest custom => sub {
  plan tests => 2;

  my $warning_file6 = make_file("$tmpdir/warning6.pm", 'warning6');
  #diag "File6: $warning_file6";

  local @Test::Strict::MODULES_ENABLING_WARNINGS
    = (@Test::Strict::MODULES_ENABLING_WARNINGS, 'Custom');

  local @Test::Strict::MODULES_ENABLING_STRICT
    = (@Test::Strict::MODULES_ENABLING_STRICT, 'Custom');

  warnings_ok( $warning_file6, 'file6' );
  strict_ok( $warning_file6, 'file6' );

};

{
  my ($warnings_files_dir, $files, $file_to_skip) = make_warning_files();
  diag explain $files;
  diag "File to skip: $file_to_skip";
  local $Test::Strict::TEST_WARNINGS = 1;
  local $Test::Strict::TEST_SKIP = [ $file_to_skip ];
  diag "Start all_perl_files_ok on $warnings_files_dir (should be 2*3 = 6 tests)";
  all_perl_files_ok( $warnings_files_dir );
}

subtest perl5_12 => sub {
  plan tests => 1;

  my $filename = make_file("$tmpdir/perl5_12.pl", 'perl5_12');
  strict_ok($filename);
};

subtest perl5_20 => sub {
  plan tests => 1;

  my $filename = make_file("$tmpdir/perl5_20.pl", 'perl5_20');
  strict_ok($filename);
};

subtest perl_v5_12 => sub {
  plan tests => 1;

  my $filename = make_file("$tmpdir/perl_v5_12.pl", 'perl_v5_12');
  strict_ok($filename);
};

{
    my %data;
    sub make_file {
    	my ($filename, $name) = @_;
    	if (not %data) {
    		my $section_name;
    		while (my $row = <DATA>) {
    			if (not $section_name) {
    				$section_name = $row;
    				chomp $section_name;
    				next;
    			}
    			if ($row =~ /^---------/) {
    				undef $section_name;
    				next;
    			}
    			die 'Undefined section_name - internal test error' if not defined $section_name;
    			$data{$section_name} .= $row;
    		}
    	}
    	open my $fh, '>', $filename or die "Could not open '$filename' for writing. $!";
    	print $fh $data{$name};
    	close $fh;
    	return $filename;
    }
  #return $HAS_WIN32 ? Win32::GetLongPathName($filename) : $filename;
}


sub make_warning_files {
  my $tmpdir = tempdir( CLEANUP => 1 );

  my @files;
# TODO: does warnings::register turn on warnings?
#  my ($fh1, $filename1) = tempfile( DIR => $tmpdir, SUFFIX => '.pm' );
#  print $fh1 <<'DUMMY';
#use strict;
#use  warnings::register ;
#print "Hello world";
#
#DUMMY
#  push @files, $filename1;

  my ($fh2, $filename2) = tempfile( DIR => $tmpdir, SUFFIX => '.pl' );
  print $fh2 <<'DUMMY';
#!/usr/bin/perl -w
use strict;
print "Hello world";

DUMMY
  push @files, $filename2;

  my ($fh3, $filename3) = tempfile( DIR => $tmpdir, SUFFIX => '.pl' );
  print $fh3 <<'DUMMY';
use  strict;
local $^W = 1;
print "Hello world";

DUMMY
  push @files, $filename3;

  my ($fh4, $filename4) = tempfile( DIR => $tmpdir, SUFFIX => '.pl' );
  print $fh4 <<'DUMMY';
#!/usr/bin/perl -Tw
use strict;
print "Hello world";

DUMMY
  push @files, $filename4;

  my ($fh5, $filename5) = tempfile( DIR => $tmpdir, SUFFIX => '.pl' );
  print $fh5 <<'DUMMY';
#!/usr/bin/perl -T -w
use strict;
print "Hello world";

DUMMY
  push @files, $filename5;

  return ($tmpdir, \@files, $filename3);
}

__END__
modern_perl_file1
#!/usr/bin/perl
use Modern::Perl;

print "hello world";
---------
extensionless
use strict;
use warnings;

print "hello world";

---------
warning1
#!/usr/bin/perl -w

print "hello world";

---------
warning2
   use warnings FATAL => 'all' ;
print "Hello world";

---------
warning3
  use strict;
   use  warnings::register ;
print "Hello world";

---------
warning4
use  Mouse ;
print "Hello world";

---------
warning5
use  Moose;
print "Hello world";

---------
warning6
use Custom;
print "Hello world";

---------
warning7
use MooX;
print "Hello world";

---------
perl5_12
use 5.012;

$x = 23;
---------

perl5_20
use 5.020;

$x = 23;
---------

perl_v5_12
use v5.12;

$x = 23;
---------
