package Test::Tdd;

# ABSTRACT: run tests continuously, detecting changes

use strict;
use warnings;
use Test::Tdd::Runner;
use Getopt::Long;
Getopt::Long::Configure('bundling');

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

Test::Tdd::Runner::start(\@watch, \@test_files);


sub show_usage {
	print <<EOF;
Usage: provetdd <options> <tests to run>
(e.g. provetdd --watch src t/Test.t)

Options:
  -I            Library paths to include
  -w, --watch   Folders to watch, default to ./lib and ./t folders
  -h, --help    Print this message
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