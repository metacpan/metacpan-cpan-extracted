package Test::LatestPrereqs::ModuleBuild;

use strict;
use warnings;
use Carp;

sub parse {
  my ($class, $file) = @_;

  my @requires;

  no warnings 'redefine';

  local $INC{'Module/Build.pm'};
  local *Module::Build::new = sub {
    my ($class, %args) = @_;

    foreach my $type (qw(requires build_requires recommends)) {
      foreach my $key (keys %{ $args{$type} || {} }) {
        push @requires, [ $key, $args{$type}->{$key} || 0 ];
      }
    }

    bless {}, 'Test::LatestPrereqs::ModuleBuild::Fake';
  };
  local *Module::Build::subclass = sub { 'Module::Build' };

  eval {
    package main;
    no strict;
    no warnings;

    local *CORE::GLOBAL::exit = sub {};

    require "$file";
  };
  delete $INC{$file};

  if ($@ && $@ !~ /did not return a true value/) {
    croak "Build.PL error: $@";
  }

  return @requires;
}

package #
  Test::LatestPrereqs::ModuleBuild::Fake;
sub DESTROY {}
sub AUTOLOAD { shift }

1;

__END__

=head1 NAME

Test::LatestPrereqs::ModuleBuild

=head1 SYNOPSIS

  my @requires = Test::LatestPrereqs::ModuleBuild->parse($build_pl);

=head1 DESCRIPTION

This is used internally to parse Build.PL (with L<Module::Build>) to get requirements.

=head1 METHODS

=head2 parse

parses Build.PL and returns a list of requirements.

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
