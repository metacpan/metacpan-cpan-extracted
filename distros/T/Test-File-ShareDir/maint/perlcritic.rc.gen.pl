#!/usr/bin/env perl
## no critic (Modules::RequireVersionVar)

# FILENAME: bundle_to_ini.pl
# CREATED: 02/06/14 01:48:56 by Kent Fredric (kentnl) <kentfredric@gmail.com>
# ABSTRACT: Write an INI file from a bundle

use 5.008;    #utf8
use strict;
use warnings;
use utf8;

use Carp qw( croak carp );
use Perl::Critic::ProfileCompiler::Util qw( create_bundle );
use Path::Tiny qw(path);

## no critic (ErrorHandling::RequireUseOfExceptions)
my $bundle = create_bundle('Example::Author::KENTNL');
$bundle->configure;

my @stopwords = (
  qw(
    ShareDir sharedirs dir dirs Notedly tempdir
    )
);
for my $wordlist (@stopwords) {
  $bundle->add_or_append_policy_field( 'Documentation::PodSpelling' => ( 'stop_words' => $wordlist ) );
}

#$bundle->remove_policy('ErrorHandling::RequireCarping');
#$bundle->remove_policy('Subroutines::ProhibitCallsToUnexportedSubs');
#$bundle->remove_policy('Subroutines::ProhibitExcessComplexity');
$bundle->remove_policy('CodeLayout::RequireUseUTF8');
$bundle->remove_policy('ErrorHandling::RequireUseOfExceptions');
$bundle->remove_policy('NamingConventions::Capitalization');
$bundle->remove_policy('NamingConventions::Capitalization');
$bundle->remove_policy('Subroutines::ProhibitSubroutinePrototypes');
$bundle->remove_policy('Subroutines::RequireArgUnpacking');

my $inf = $bundle->actionlist->get_inflated;

my $config = $inf->apply_config;

{
  my $rcfile = path('./perlcritic.rc')->openw_utf8;
  $rcfile->print( $config->as_ini, "\n" );
  close $rcfile or croak 'Something fubared closing perlcritic.rc';
}
my $deps = $inf->own_deps;
{
  my $target = path('./misc');
  $target->mkpath if not $target->is_dir;

  my $depsfile = $target->child('perlcritic.deps')->openw_utf8;
  for my $key ( sort keys %{$deps} ) {
    $depsfile->printf( "%s~%s\n", $key, $deps->{$key} );
    *STDERR->printf( "%s => %s\n", $key, $deps->{$key} );
  }
  close $depsfile or carp 'Something fubared closing perlcritic.deps';
}

