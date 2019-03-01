package Text::Amuse::Output::Image;
use strict;
use warnings;
use utf8;

=head1 NAME

Text::Amuse::Output::Image -- class to manage images

=head1 SYNOPSIS

The module is used internally by L<Text::Amuse>, so everything here is
pretty much internal only (and underdocumented).

=head1 CONSTRUCTORS

=over 4

=item new(filename => "hello.png", width => 50, wrap => 'l')

Constructor. Accepts three options: C<filename>, C<width>, as a
integer in percent, and C<wrap>, as a string denoting the position.
C<filename> is mandatory.

These arguments are saved in the objects and can be accessed with:
=cut

=back

=head1 METHODS

=over 4

=item filename

=item width

=item wrap

If 'l', the float will wrap on the left, if 'r' will wrap on the
right, if 'f' it's not floating, but it's intended as fullpage (will
insert a clearpage after the image). This is handy if there is some
long series of images without text.

=item fmt

=item desc

Please note that we concatenate the caption as is. It's up to the
caller to pass an escaped string.

=cut

sub new {
    my $class = shift;
    my $self = {
                width => 1,
                wrap => 0,
               };
    my %opts = @_;

    if (my $f = $opts{filename}) {
        $self->{filename} = $f;
        # just to be sure
        unless ($f =~ m{^[0-9A-Za-z][0-9A-Za-z/-]+\.(png|jpe?g)}s) {
            die "Illegal filename $f!";
        }
    }
    else {
        die "Missing filename argument!";
    }

    if (my $wrap = $opts{wrap}) {
        if ($wrap eq 'l' or $wrap eq 'r' or $wrap eq 'f') {
            $self->{wrap} = $wrap;
        }
        else {
            die "Wrong wrapping option";
        }
        if ($wrap eq 'l' or $wrap eq 'r') {
            $opts{width} ||= 50;
        }
    }

    if (my $w = $opts{width}) {
        if ($w =~ m/^[0-9]+$/s) {
            $self->{width} = sprintf('%.2f', $w / 100);
        }
        else {
            die "Wrong width $w passed!";
        }
    }

    foreach my $k (qw/desc fmt/) {
        if (exists $opts{$k} and defined $opts{$k}) {
            $self->{$k} = $opts{$k};
        }
    }

    bless $self, $class;
}

sub width {
    return shift->{width};
}

sub wrap {
    return shift->{wrap};
}

sub filename {
    return shift->{filename};
}

sub fmt {
    return shift->{fmt};
}

sub desc {
    my ($self, @args) = @_;
    if (@args) {
        $self->{desc} = shift(@args);
    }
    return shift->{desc};
}

=back

=head2 Formatters

=over 4

=item width_html

Width in percent

=item width_latex

Width as  '0.25\textwidth'

=cut

sub width_html {
    my $self = shift;
    my $width = $self->width;
    my $width_in_pc = sprintf('%d', $width * 100);
    return $width_in_pc . '%';
}

sub width_latex {
    my $self = shift;
    my $width = $self->width;
    if ($width == 1) {
        return "\\textwidth";
    }
    else {
        return $self->width . "\\textwidth"; # a float
    }
}

=item as_latex

The LaTeX code for the image. Right and left floats uses the
wrapfigure packages. To full page floats a \clearpage is appended.

=item as_html

The HTML code for the image. Classes used:

  img.embedimg {
      margin: 1em;
  }

  div.image, div.float_image_f {
      margin: 1em;
      text-align: center;
      padding: 3px;
      background-color: white;
  }

  div.float_image_r {
      float: right;
  }

  div.float_image_l {
      float: left;
  }

  div.float_image_f {
      clear: both;
      margin-left: auto;
      margin-right: auto;
  }


=item output

Given that we know the format, just return the right one, using
C<as_html> or C<as_latex>.

=back


=cut



sub as_latex {
    my $self = shift;
    my $wrap = $self->wrap;
    my $width = $self->width_latex;
    my $desc = "";
    my $realdesc = $self->desc;
    if (defined($realdesc) && length($realdesc)) {
        # the \noindent here is harmless if you still want the label,
        # commenting out the \renewcommand*
        $desc = "\n\\caption[]{\\noindent $realdesc}";
    }
    my $src = $self->filename;
    my $open;
    my $close;
    if ($wrap eq 'r' or $wrap eq 'l') {
        $open = "\\begin{wrapfigure}{$wrap}{$width}";
        $close = "\\end{wrapfigure}";
    }
    elsif ($wrap eq 'f') {
        $open = "\\begin{figure}[p]";
        $close = "\\end{figure}\n\\clearpage";
    }
    else {
        $open = "\\begin{figure}[htbp!]";
        $close = "\\end{figure}";
    }
    my $out = <<"EOF";

$open
\\centering
\\includegraphics[keepaspectratio=true,height=0.75\\textheight,width=$width]{$src}$desc
$close
EOF
    return $out;
}

sub as_html {
    my $self = shift;
    my $wrap = $self->wrap;
    my $width = "";
    my $desc;
    my $class = "image";
    my $out;
    if ($wrap) {
        $class = "float_image_$wrap";
    }

    my $src = $self->filename;
    my $realdesc = $self->desc;
    if (defined($realdesc) && length($realdesc)) {
        $desc = <<"EOF";
<div class="caption">$realdesc</div>
EOF
    }
    if ($self->width != 1) {
        $width = q{ style="width:} .  $self->width_html . q{;"};
    }

    $out = qq{\n<div class="$class"$width>\n} .
      qq{<img src="$src" alt="$src" class="embedimg" />\n};
    if (defined $desc) {
        $out .= $desc;
    }
    $out .= "</div>\n";
    return $out;
}

sub output {
    my $self = shift;
    if ($self->fmt eq 'ltx') {
        return $self->as_latex;
    }
    elsif ($self->fmt eq 'html') {
        return $self->as_html;
    }
    else {
        die "Bad format ". $self->fmt;
    }
}

1;

