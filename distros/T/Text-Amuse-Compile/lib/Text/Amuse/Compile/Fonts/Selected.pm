package Text::Amuse::Compile::Fonts::Selected;
use utf8;
use strict;
use warnings;
use Moo;
use Types::Standard qw/InstanceOf Enum/;

=head1 NAME

Text::Amuse::Compile::Fonts::Selected - simple class to hold selected fonts

=head1 ACCESSORS

All are read-only instances of L<Text::Amuse::Compile::Fonts::Family>.

=head2 main

=head2 sans

=head2 mono

=head2 size

=cut

has mono => (is => 'ro', required => 1, isa => InstanceOf['Text::Amuse::Compile::Fonts::Family']);
has sans => (is => 'ro', required => 1, isa => InstanceOf['Text::Amuse::Compile::Fonts::Family']);
has main => (is => 'ro', required => 1, isa => InstanceOf['Text::Amuse::Compile::Fonts::Family']);
has size => (is => 'ro', default => sub { 10 }, isa => Enum[9..14]);

1;
