package Test::Tdd;

# ABSTRACT: run tests continuously, detecting changes

use strict;
use warnings;
use Test::Tdd::Runner;
use Getopt::Long;
Getopt::Long::Configure('bundling');

my ($argv_index) = grep { $ARGV[$_] eq "--" } 0..(scalar @ARGV - 1);
my @argv_override = ();
if ($argv_index) {
	@argv_override = splice @ARGV, $argv_index;
	shift @argv_override;
}

my $help;
my @watch = ();
my @includes = ();
GetOptions(
	'I=s@'     => \@includes,
	'watch=s@' => \@watch,
	'help'     => \$help,
) or show_usage();
show_usage() if $help;

@watch = split(/,/, join(',', @watch));
@watch = ('lib', 't') unless @watch;

@INC = ('.', @watch, @INC, @includes);

my @test_files = @ARGV;
show_usage() unless @test_files;

@ARGV = @argv_override;
Test::Tdd::Runner::start(\@watch, \@test_files);


sub show_usage {
	print <<EOF;
Usage: provetdd <options> <tests to run>
(e.g. provetdd --watch src t/Test.t)

Options:
  -I            Library paths to include
  -w, --watch   Folders to watch, default to ./lib and ./t folders
  -h, --help    Print this message
  --            Anything after -- will be passed to \@ARGV (e.g. provetdd t/Test.t -- foobar)
EOF
	exit 1;
}

1;


=head1 NAME

Test::Tdd - Run tests continuously, detecting changes

=head1 SYNOPSIS

You can run the tests using C<provetdd>

    provetdd t/path/to/Test.t

You can also specify paths to add to INC and specific paths to watch

    provetdd -Ilib --watch lib/path,lib/path2 t/path/to/Test.t

You can all run all tests in a folder

    provetdd t/

=cut