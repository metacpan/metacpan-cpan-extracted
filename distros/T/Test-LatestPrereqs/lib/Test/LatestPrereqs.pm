package Test::LatestPrereqs;

use strict;
use warnings;
use Test::More;
use CPAN::Version;
use Test::LatestPrereqs::Config;
use base 'Exporter';

our $VERSION = '0.02';

our @EXPORT = qw(all_prereqs_are_latest);

sub all_prereqs_are_latest {
  my @files = @_;
  unless (@files) {
    push @files, 'Makefile.PL' if -f 'Makefile.PL';
    push @files, 'Build.PL'    if -f 'Build.PL';
  }

  my @requires;
  foreach my $file (@files) {
    next unless -f $file;
    open my $fh, '<', $file or next;
    my $content = do { local $/; <$fh> };
    if ($file =~ /Makefile\.PL$/) {
      if ($content =~ /WriteMakefile\s*\(/) {
        require Test::LatestPrereqs::MakeMaker;
        push @requires, Test::LatestPrereqs::MakeMaker->parse($file);
      }
      elsif ($content =~ /use\s+inc::Module::Install/) {
        require Test::LatestPrereqs::ModuleInstall;
        push @requires, Test::LatestPrereqs::ModuleInstall->parse($file);
      }
    }
    elsif ($file =~ /Build\.PL$/) {
      require Test::LatestPrereqs::ModuleBuild;
      push @requires, Test::LatestPrereqs::ModuleBuild->parse($file);
    }
  }

  if (!Test::More->builder->{Have_Plan}) {
    unless (@requires) {
      plan skip_all => 'no prereqs';
      return;
    }
    plan tests => scalar @requires;
  }

  my $required = Test::LatestPrereqs::Config->load;

  foreach my $require (@requires) {
    my ($module, $version) = @{ $require };
    if ($required->{$module} && (!$version or CPAN::Version->vgt($required->{$module}, $version))) {
      fail("$module requires at least $$required{$module} (current: $version)");
    }
    else {
      pass("$module $version is ok");
    }
  }
  return @requires;
}

1;

__END__

=head1 NAME

Test::LatestPrereqs - test if the required module versions are big enough

=head1 SYNOPSIS

In your test:

  use strict;
  use warnings;
  use Test::LatestPrereqs;

  all_prereqs_are_latest();

From the command line (shell):

  > test_prereqs_version --update

=head1 DESCRIPTION

You may sometimes want to increase version requirement of a dependency for a distribution, because of a bug or a new feature. And you might immediately upgrade other distributions that require the same dependency. That's good.

However, I'm lazy. "I'll do it later, maybe when I add other features to them," and eventually I forget what or to which version I should upgrade. That's lame.

With this module, you can store preferred versions for notable dependencies in a configuration file, and test if dependencies for your distribution have the latest (or even greater) version requirement. 

=head1 CAVEATS

You shouldn't include this test in a distribution (even in the "xt" directory) as this is solely for a module author, and the preference may differ by person.

=head1 FUNCTION

=head2 all_prereqs_are_latest

reads Makefile.PL/Build.PL (or the files you pass as arguments), gathers requirements/recommendations, tests their versions, and returns the required modules/versions. Note that this test may break when the Makefile.PL/Build.PL does weird/wicked things as this I<actually> executes the files with locally mocked makemakers (but don't worry; it's you or your trusted friends who wrote those Makefile.PL/Build.PL. If you want a bot to run this test for modules you can't always trust, take a bit more care).

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
