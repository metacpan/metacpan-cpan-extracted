#!/usr/bin/perl

use strict;

# For PRIVATE Module::Install extensions
use lib 'private-lib';

use lib '.';
use inc::Module::Install;

# To prevent MakeMaker from processing our old directory
BEGIN { makemaker_args( NORECURS => 1 ) }

print "\n", '-'x78, "\n\n";

# Do all_from first to get the required perl version before
# check_custom_installation runs
name('yagg');
all_from('yagg');

auto_set_bugtracker;
githubmeta;

provides(
  'yagg' => {
    file => 'yagg',
    version => version(),
  }
);

# Perl 5.6 doesn't work with URI::Escape. We get an error about Exporter not exporting "import"
perl_version '5.008';

check_custom_installation();

install_script('yagg');

configure_requires(
  # Module::Install::Bugtracker needs this
  'URI::Escape' => 0,
);

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
  'Test::Compile' => 0,
  'File::Slurper' => 0,
  'Test::More' => 0,
  'File::Find' => 0,
  'File::Spec::Functions' => 0,
  'Cwd' => 0,
);

my $locations = configure_programs();

foreach my $program (keys %$locations)
{
  die "prerequisite program \"$program\" not found\n" unless defined $$locations{$program};
}

print "\n", '-'x78, "\n\n";

clean_files('lib/yagg/TerminalParser.pm', 'lib/yagg/NonterminalParser.pm');

license 'gpl2';

use_standard_tests;

auto_license(holder => 'David Coppit');

no_index 'directory' => 'private-lib';

enable_verbose_cpan_testing();

make_parsers($$locations{'yapp'}{'path'});

realclean_files('inc');

WriteAll;

# ---- Workaround for broken module ----
# https://rt.cpan.org/Ticket/Display.html?id=125772
{
  package Module::Install::StandardTests;

  sub write_standard_test_compile {
      my $self = shift;
      $self->write_test_file('000_standard__compile.t', q/
          BEGIN {
            if ($^O eq 'MSWin32') {
              require Test::More;
              Test::More->import(skip_all =>
                  "Test::Compile doesn't work properly on Windows");
            } else {
              require Test::More;
              Test::More->import();
              eval "use Test::Compile";
              Test::More->builder->BAIL_OUT(
                  "Test::Compile required for testing compilation") if $@;
              all_pm_files_ok();
            }
          }
      /);
  }
}

print "\n", '-'x78, "\n\n";

fix_sort_versions('inc/Sort/Versions.pm');
