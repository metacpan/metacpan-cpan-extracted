#!/usr/bin/env perl

BEGIN
  {
  unless ($ENV{AUTHOR_TESTING})
    {
    require Test::More;
    Test::More::plan(skip_all => 'this test is run only during development');
    }
  }

use strict;
use warnings;

use DirHandle;
use File::Basename;

use Test::More;

use_ok('Pod::Coverage');

my %modules;

chdir('./lib');
recur('Wx/App');

foreach my $path (keys %modules)
  {
  foreach my $mod (@{$modules{$path}})
    {
    my $base = basename($mod, ('.pm'));
    my $pkg = "$path/$base";
    $pkg =~ s/\//::/g;
    my $checker = Pod::Coverage->new(package => $pkg);
    my $rating = $checker->coverage();
    if (defined($rating))
      {
      is($rating, 1, "pod coverage for $mod");
      if ($rating < 1)
        {
        my $list;
        map { $list .= "$_ " } $checker->uncovered();
        diag ("uncovered methods in $mod: $list");
        }
      }
    else
      {
      my $why = $checker->why_unrated();
      diag("$mod has an undefined rating: $why");
      }
    }
  }
done_testing();

     #########################################

sub recur
  {
  my $dir = shift;
  my @files = DirHandle->new($dir)->read();
  foreach my $file (@files)
    {
    next if ($file =~ /\A\.+\Z/);
    my $path = "$dir/$file";
    recur($path) if (-d $path);
    next unless ($file =~ /\A[\w_:]+\.pm\Z/);
    $modules{$dir} = [] unless (exists($modules{$dir}));
    push(@{$modules{$dir}}, $file);
    }
  return;
  }

