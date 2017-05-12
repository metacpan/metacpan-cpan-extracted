package Text::Amuse::Compile::Webfonts;

use strict;
use warnings FATAL => 'all';
use utf8;

use File::Spec;

=head1 NAME

Text::Amuse::Compile::Webfonts - Class to parse and validate webfonts for Text::Amuse::Compile

=head1 SYNOPSIS

This class only takes a single parameter, with the directory where to
find the fonts. Anyway, the content of the directory is very specific.

The class expects to find 4 fonts, a regular, an italic, a bold and a
bold italic one. Given that the names are arbitrary, we need an hint.
For this you have to provide a file, in the very same directory, with
the specifications. The file B<must> be named C<spec.txt> and need the
following content:

E.g., for Droid fonts:

  family Droid Serif
  regular DroidSerif-Regular.ttf
  italic DroidSerif-Italic.ttf
  bold DroidSerif-Bold.ttf
  bolditalic DroidSerif-Bold.ttf
  size 10

The four TTF files must be placed in this directory as well. The
formats supported are TTF, OTF and WOFF.

The C<family> and C<size> specs are optional.

=head1 CONSTRUCTOR OPTIONS

=head2 new (webfontsdir => "./webfonts")

=over 4

=item webfontsdir

The directory where to find the files and the specification file. If
the class can't find valid data, the C<new> method will return nothing
and emit warnings.

=back

=cut

sub new {
    my ($class, %params) = @_;
    if (my $dir = $params{webfontsdir}) {
        if (my $self = _parse_dir_and_spec($dir)) {
            bless $self, $class;
            return $self;
        }
        else {
            warn "$dir has invalid data!\n";
            return undef;
        }
    }
    return undef;
}

=head1 ACCESSORS

Every accessor here is read only.

=over 4

=item srcdir

The absolute path to the fonts.

=item regular

The filename of the regular font.

=item bold

The filename of the bold font.

=item italic

The filename of the italic font.

=item bolditalic

The filename of the bolditalic font.

=item family

The family name.

=item mimetype

The mimetype of the fonts.

=item size

The size of the fonts in pt to be used on display.

=item format

The format to feed the src description in the CSS.

=item files

Return an hash with where the keys are the filenames without the path,
and the value the full absolute path to the files.

=back

=cut

sub srcdir { return shift->{srcdir} }

sub family { return shift->{family} }

sub bold { return shift->{bold} }

sub italic { return shift->{italic} }

sub bolditalic { return shift->{bolditalic} }

sub regular { return shift->{regular} }

sub format { return shift->{format} }

sub mimetype { return shift->{mimetype} }

sub size { return shift->{size} }

sub _parse_dir_and_spec {
    my $dir = shift;
    # canonicalize
    $dir = File::Spec->rel2abs($dir);
    unless (-d $dir) {
        warn "$dir is not a directory!";
        return;
    }
    my %data = (srcdir => $dir);
    my $specfile = File::Spec->catfile($dir, 'spec.txt');
    if (-f $specfile) {
        open (my $fh, '<', $specfile) or die "Cannot open specfile $!";
        while (my $line = <$fh>) {
            if ($line =~ m/^\s*
                  (family|regular|italic|bold|bolditalic|size)
                  \s+
                  (\w[\w\.\ -]*?)
                  \s*
                  $/x) {
                $data{$1} = $2;
            }
            elsif ($line =~ m/^#/) {
                # ok, comment
            }
            elsif ($line =~ m/^\s*$/) {
                # ok, blank line
            }
            else {
                warn "Invalid line in $specfile found: $line";
            }
        }
        close $fh;
    }
    else {
        warn "$specfile not found";
        return;
    }
    # then check
    my @missing;
    foreach my $font (qw/regular italic bold bolditalic/) {
        if ($data{$font}) {
            if (-f File::Spec->catfile($dir, $data{$font})) {
                # all ok.
                next;
            }
        }
        # not ok.
        push @missing, $font;
    }
    if (@missing) {
        warn "$specfile is missing (or not file doesn't exist) these fonts: " . join(" ", @missing) . "\n";
        return;
    }
    # determine dthe format
    if ($data{regular} =~ m/\.(woff|ttf|otf)/i) {
        my $ext = lc($1);
        my %formats = (
                       woff => {
                                format => 'woff',
                                mimetype => 'application/font-woff',
                               },
                       ttf  => {
                                format => 'truetype',
                                mimetype => 'application/x-font-ttf',
                               },
                       otf  => {
                                format => 'opentype',
                                mimetype => 'application/x-font-opentype',
                               },
                      );
        if (my $format = $formats{$ext}) {
            $data{format} = $format->{format};
            $data{mimetype} = $format->{mimetype};
        }
    }
    unless ($data{format}) {
        warn "Can't determine format for $data{regular}!\n";
        return;
    }
    $data{size} ||= 10;
    $data{family} ||= "Dummy family";
    return \%data;
}

sub files {
    my $self = shift;
    my %out;
    foreach my $font (qw/regular bold italic bolditalic/) {
        my $k = $self->$font;
        $out{$k} = File::Spec->catfile($self->srcdir, $k);
    }
    return %out;
}

1;
