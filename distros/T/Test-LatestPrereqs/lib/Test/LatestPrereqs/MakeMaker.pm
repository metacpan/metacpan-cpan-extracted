package Test::LatestPrereqs::MakeMaker;

use strict;
use warnings;
use Carp;
use ExtUtils::MakeMaker ();

sub parse {
  my ($class, $file) = @_;

  my @requires;
  my $WriteMakefile = sub {
    my %args = @_;
    my $prereqs = $args{PREREQ_PM} || {};
    foreach my $key (keys %{ $prereqs }) {
      push @requires, [ $key, $prereqs->{$key} || 0 ];
    }
    bless \%args, 'Test::LatestPrereqs::MakeMaker::Fake';
  };

  no warnings 'redefine';
  local *main::WriteMakefile = $WriteMakefile;
  local *ExtUtils::MakeMaker::WriteMakefile = $WriteMakefile;

  # mock Inline::MakeMaker, too
  local $INC{'Inline/MakeMaker.pm'} = 1;
  local @Inline::MakeMaker::EXPORT = qw( WriteMakefile WriteInlineMakefile );
  local @Inline::MakeMaker::ISA = 'Exporter';
  local *Inline::MakeMaker::WriteMakefile = $WriteMakefile;
  local *Inline::MakeMaker::WriteInlineMakefile = $WriteMakefile;

  eval {
    package main;
    no strict;
    no warnings;

    local *CORE::GLOBAL::exit = sub {};

    require "$file";
  };
  delete $INC{$file};

  if ($@ && $@ !~ /did not return a true value/) {
    croak "Makefile.PL error: $@";
  }

  return @requires;
}

package #
  Test::LatestPrereqs::MakeMaker::Fake;

1;

__END__

=head1 NAME

Test::LatestPrereqs::MakeMaker

=head1 SYNOPSIS

  my @requires = Test::LatestPrereqs::MakeMaker->parse($makefile_pl);

=head1 DESCRIPTION

This is used internally to parse Makefile.PL (with L<ExtUtils::MakeMaker>) to get requirements.

=head1 METHODS

=head2 parse

parses Makefile.PL and returns a list of requirements.

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
