#!/usr/bin/perl

use strict;

# For PRIVATE Module::Install extensions
use lib 'private-lib';

use inc::Module::Install;
use File::Slurp;

BEGIN { makemaker_args( NORECURS => 1 ) }

print "\n", '-'x78, "\n\n";

# Do all_from first to get the required perl version before
# check_custom_installation runs
name('yagg');
all_from('yagg');

auto_set_bugtracker;
githubmeta;

configure_requires(
  'File::Slurp' => 0,
);

provides(
  'yagg' => {
    file => 'yagg',
    version => version(),
  }
);

check_custom_installation();

install_script('yagg');

requires(
  'perl' => '5.005',
  'Carp' => 0,
  'URI' => 0,
  'Data::Dumper' => 0,
  'FileHandle' => 0,
  'File::Temp' => 0,
  'File::Path' => 0,
  'Getopt::Std' => 0,
  'IPC::Open3' => 0,
  'Text::Template' => 0,
  'Parse::Yapp::Driver' => 1.05,
);

test_requires(
  'File::Slurp' => 0,
  'Test::More' => 0,
  'File::Find' => 0,
  'File::Spec::Functions' => 0,
  'Cwd' => 0,
);

my $locations = configure_programs();

print "\n", '-'x78, "\n\n";

clean_files('lib/yagg/TerminalParser.pm', 'lib/yagg/NonterminalParser.pm');

license 'gpl2';
auto_license(holder => 'David Coppit');

no_index 'directory' => 'private-lib';

enable_verbose_cpan_testing();

WriteAll();

print "\n", '-'x78, "\n\n";

make_parsers($$locations{'yapp'}{'path'});

foreach my $program (keys %$locations)
{
  warn "prerequisite program \"$program\" not found\n" unless defined $$locations{$program};
}

fix_sort_versions('inc/Sort/Versions.pm');
