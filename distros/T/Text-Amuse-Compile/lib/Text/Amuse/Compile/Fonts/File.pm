package Text::Amuse::Compile::Fonts::File;
use strict;
use warnings;
use utf8;

use Moo;
use File::Basename qw//;
use File::Spec;
use Types::Standard qw/Maybe Str Enum ArrayRef/;

=head1 NAME

Text::Amuse::Compile::Fonts::File - font file object

=head1 ACCESSORS

=head2 file

The filename. Required

=head2 shape

The shape of the font. Must be regular, bold, italic or bolditalic.

=head2 format

Built lazily from the filename, validating it and crashing if it's not
otf or ttf.

=head2 mimetype

Built lazily from the filename, validating it and crashing if it's not
otf or ttf

=head2 basename

The basename of the font, includin the extension.

=head2 basename_and_ext

Alias for C<basename>

=head2 extension

The file extension, including the dot.

=head2 dirname

The directory, including the trailing slash.

=head2 css_font_weight

C<bold> or C<normal> depending on the shape

=head2 css_font_style

C<italic> or C<normal> depending on the shape

=cut

has file => (is => 'ro',
             required => 1,
             isa => sub {
                 die "$_[0] is not a font file"
                   unless $_[0] && -f $_[0] && $_[0] =~ m/\.(ttf|otf)\z/i
               });

has shape => (is => 'ro',
              required => 1,
              isa => Enum[qw/regular bold italic bolditalic/]);

has format => (is => 'lazy',
               isa => Str);

has mimetype => (is => 'lazy',
                 isa => Str);

has _parsed_path => (is => 'lazy',
                    isa => ArrayRef);

sub _build__parsed_path {
    my $self = shift;
    if (my $file = $self->file) {
        my ($filename, $dirs, $suffix) = File::Basename::fileparse(File::Spec->rel2abs($file),
                                                                   qr/\.(ttf|otf)\z/i);
        return [ $filename . $suffix , $dirs, $suffix ];
    }
    else {
        return [ '', '', '' ];
    }
}

# my ($filename, $dirs, $suffix) = fileparse($path, @suffixes);

sub basename {
    shift->_parsed_path->[0];
}

sub basename_and_ext {
    shift->_parsed_path->[0];
}

sub dirname {
    shift->_parsed_path->[1];
}

sub extension {
    shift->_parsed_path->[2];
}

sub _build_format {
    my $self = shift;
    if (my $ext = $self->extension) {
        my %map = (
                   '.woff' => 'woff',
                   '.ttf' => 'truetype',
                   '.otf' => 'opentype',
                  );
        if (my $type = $map{lc($ext)}) {
            return $type;
        }
    }
    die "Bad file format without extension " . $self->file;
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

sub css_font_weight {
    my $self = shift;
    my %map = (
               regular => "normal",
               bold => "bold",
               italic => "normal",
               bolditalic => "bold",
              );
    return $map{$self->shape};
}

sub css_font_style {
    my $self = shift;
    my %map = (
               regular => "normal",
               bold => "normal",
               italic => "italic",
               bolditalic => "italic",
              );
    return $map{$self->shape};
}

1;
