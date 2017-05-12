package Text::Amuse::Compile::Fonts::File;
use strict;
use warnings;
use utf8;

use Moo;
use File::Basename qw//;
use Types::Standard qw/Maybe Str Enum/;

=head1 NAME

Text::Amuse::Compile::Fonts::File - font file object

=head1 ACCESSORS

=head2 file

The filename. Required

=head2 shape

The shape of the font. Must be regular, bold, italic or bolditalic.

=head2 format

Built lazily from the filename, validating it and crashing if it's not
otf, ttf or woff.

=head2 mimetype

Built lazily from the filename, validating it and crashing if it's not
otf, ttf or woff.

=head2 basename

The basename of the font.

=cut

has file => (is => 'ro',
             required => 1,
             isa => sub {
                 die "$_[0] is not a font file"
                   unless $_[0] && -f $_[0] && $_[0] =~ m/\.(woff|ttf|otf)\z/i
               });

has shape => (is => 'ro',
              required => 1,
              isa => Enum[qw/regular bold italic bolditalic/]);

has format => (is => 'lazy',
               isa => Str);

has mimetype => (is => 'lazy',
                 isa => Str);


sub _build_format {
    my $self = shift;
    if (my $file = $self->file) {
        if ($file =~ m/\.(woff|ttf|otf)\z/i) {
            my $ext = lc($1);
            my %map = (
                       woff => 'woff',
                       ttf => 'truetype',
                       otf => 'opentype',
                      );
            return $map{$ext};
        }
    }
    return;
}

sub _build_mimetype {
    my $self = shift;
    if (my $format = $self->format) {
        my %map = (
                   woff => 'application/font-woff',
                   truetype => 'application/x-font-ttf',
                   opentype => 'application/x-font-opentype',
                  );
        return $map{$format};
    }
    return;
}

sub basename {
    my $self = shift;
    return File::Basename::basename($self->file);
}

1;
