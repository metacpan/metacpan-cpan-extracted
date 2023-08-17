package Pod::Weaver::Section::Authors 4.019;
# ABSTRACT: a section listing authors

use Moose;
with 'Pod::Weaver::Role::Section';

# BEGIN BOILERPLATE
use v5.20.0;
use warnings;
use utf8;
no feature 'switch';
use experimental qw(postderef postderef_qq); # This experiment gets mainlined.
# END BOILERPLATE

use Pod::Elemental::Element::Nested;
use Pod::Elemental::Element::Pod5::Verbatim;

#pod =head1 OVERVIEW
#pod
#pod This section adds a listing of the documents authors.  It expects a C<authors>
#pod input parameter to be an arrayref of strings.  If no C<authors> parameter is
#pod given, it will do nothing.  Otherwise, it produces a hunk like this:
#pod
#pod   =head1 AUTHORS
#pod
#pod     Author One <a1@example.com>
#pod     Author Two <a2@example.com>
#pod
#pod =attr header
#pod
#pod The title of the header to be added.
#pod (default: "AUTHOR" or "AUTHORS")
#pod
#pod =cut

has header => (
  is  => 'ro',
  isa => 'Maybe[Str]',
);

sub weave_section {
  my ($self, $document, $input) = @_;

  return unless $input->{authors};

  my $multiple_authors = $input->{authors}->@* > 1;

  # I think I might like to have header be a callback or something, so that you
  # can get pluralization for your own custom header. -- rjbs, 2015-03-17
  my $name = $self->header || ($multiple_authors ? 'AUTHORS' : 'AUTHOR');

  $self->log_debug("adding $name section");
  $self->log_debug("author = $_") for $input->{authors}->@*;

  my $authors = [ map {
    Pod::Elemental::Element::Pod5::Ordinary->new({
      content => $_,
    }),
  } $input->{authors}->@* ];

  $authors = [
    Pod::Elemental::Element::Pod5::Command->new({
      command => 'over', content => '4',
    }),
    ( map {
      Pod::Elemental::Element::Pod5::Command->new({
        command => 'item', content => '*',
      }),
      $_,
    } @$authors ),
    Pod::Elemental::Element::Pod5::Command->new({
      command => 'back', content => '',
    }),
  ] if $multiple_authors;

  push $document->children->@*,
    Pod::Elemental::Element::Nested->new({
      type     => 'command',
      command  => 'head1',
      content  => $name,
      children => $authors,
    });
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Weaver::Section::Authors - a section listing authors

=head1 VERSION

version 4.019

=head1 OVERVIEW

This section adds a listing of the documents authors.  It expects a C<authors>
input parameter to be an arrayref of strings.  If no C<authors> parameter is
given, it will do nothing.  Otherwise, it produces a hunk like this:

  =head1 AUTHORS

    Author One <a1@example.com>
    Author Two <a2@example.com>

=head1 PERL VERSION

This module should work on any version of perl still receiving updates from
the Perl 5 Porters.  This means it should work on any version of perl released
in the last two to three years.  (That is, if the most recently released
version is v5.40, then this module should work on both v5.40 and v5.38.)

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

=head1 ATTRIBUTES

=head2 header

The title of the header to be added.
(default: "AUTHOR" or "AUTHORS")

=head1 AUTHOR

Ricardo SIGNES <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
