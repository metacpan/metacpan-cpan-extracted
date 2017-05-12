#line 1
package Test::UseAllModules;

use strict;
use warnings;
use ExtUtils::Manifest qw( maniread );

our $VERSION = '0.12';

use Exporter;

our @ISA = qw/Exporter/;
our @EXPORT = qw/all_uses_ok/;

use Test::More;

my $RULE = qr{^lib/(.+)\.pm$};

sub import {
  shift->export_to_level(1);

  shift if @_ && $_[0] eq 'under';
  my @dirs = ('lib', @_);
  my %seen;
  @dirs  = grep { !$seen{$_}++ } map  { s|/+$||; $_ } @dirs;
  $RULE = '^(?:'.(join '|', @dirs).')/(.+)\.pm\s*$';
  unshift @INC, @dirs;
}

sub _get_module_list {
  shift if @_ && $_[0] eq 'except';
  my @exceptions = @_;
  my @modules;

  my $manifest = maniread();

READ:
  foreach my $file (keys %{ $manifest }) {
    if (my ($module) = $file =~ m|$RULE|) {
      $module =~ s|/|::|g;

      foreach my $rule (@exceptions) {
        next READ if $module eq $rule || $module =~ /$rule/;
      }

      push @modules, $module;
    }
  }
  return @modules;
}

sub _planned { Test::More->builder->{Have_Plan}; }

sub all_uses_ok {
  unless (-f 'MANIFEST') {
    plan skip_all => 'no MANIFEST' unless _planned();
    return;
  }

  my @modules = _get_module_list(@_);

  unless (@modules) {
    plan skip_all => 'no .pm files are found under the lib directory' unless _planned();
    return;
  }
  plan tests => scalar @modules unless _planned();

  my @failed;
  foreach my $module (@modules) {
    use_ok($module) or push @failed, $module;
  }

  BAIL_OUT( 'failed: ' . (join ',', @failed) ) if @failed;
}

1;
__END__

#line 159
