package Text::ANSI::Image;

our $VERSION = "0.02";

use v5.16;
use warnings;
use Carp;
use File::Spec;
use File::Temp ();
use POSIX qw(ceil floor);

# The methods which auto tries, in order: the first which the terminal
# supports is taken.
our @METHODS = qw(kitty);

# The types of images which are known
our @TYPES = qw(png jpeg gif);

# The size of a cell in pixels when the terminal does not tell it
our @CELL = (8, 17);

# Lines of the terminal which an image leaves free
our $MARGIN = 4;

# The commands which make an image PNG, or smaller
our $SIPS = '/usr/bin/sips';

# new(method => NAME, ...): an object of the method NAME, which is the
# module Text::ANSI::Image::NAME.  With "auto" (the default), of the
# first method in @METHODS which the terminal supports, or undef when
# it supports none.  A method module calls it as its own new.
sub new {
    my($class, %opt) = @_;
    if ($class eq __PACKAGE__) {
	my $method = delete $opt{method} // 'auto';
	if ($method eq 'auto') {
	    for my $m (@METHODS) {
		my $c = $class->method_class($m);
		return $c->new(%opt) if $c->supported;
	    }
	    return undef;
	}
	return $class->method_class($method)->new(%opt);
    }
    my $obj = bless {
	term  => undef,		# COLSxROWS:WxH, or from the tty
	tty   => '/dev/tty',	# where the data goes
	width => 0,		# columns that an image may take
	rows  => 0,		# rows that an image may take
	types => undef,		# types of images shown, all by default
	osc   => 0,		# tell the file of each image (kitty)
	%opt,
    }, $class;
    $obj->terminal;		# a wrong size dies here
    $obj;
}

# The class of a method, loaded
sub method_class {
    my($class, $name) = @_;
    $name =~ /\A\w+\z/ or croak "Text::ANSI::Image: not a name of a method: '$name'";
    my $c = __PACKAGE__ . "::$name";
    eval "require $c; 1" or croak "Text::ANSI::Image: unknown method: $name";
    $c;
}

# The name of the method of an object
sub method {
    my $self = shift;
    (ref $self || $self) =~ s/.*:://r;
}

# Whether the terminal supports the method: the method module says
sub supported { 0 }

# The most columns and rows that an image may take, 0 for no limit
sub max_cells { 0 }

# Columns, rows and the size of a cell in pixels of the terminal: from
# term, "COLSxROWS" or "COLSxROWS:WxH", or from the window size of the
# tty.  The size of a cell is 0 when it is not known.  An empty list
# when there is no terminal.  As a class method, term is the argument.
sub terminal {
    my $self = shift;
    $self = { term => shift } unless ref $self;
    $self->{_terminal} //= do {
	my $spec = $self->{term};
	my @r;
	if (defined $spec and $spec ne '') {
	    @r = $spec =~ /\A(\d+)x(\d+)(?::(\d+)x(\d+))?\z/
		or croak "Text::ANSI::Image: COLSxROWS:WxH expected for term, not '$spec'";
	    $_ //= 0 for @r;
	} elsif (open my $tty, '+<', '/dev/tty') {
	    my $TIOCGWINSZ = $^O eq 'darwin' ? 0x40087468 : 0x5413;
	    my $buf = "\0" x 8;
	    if (ioctl $tty, $TIOCGWINSZ, $buf) {
		my($rows, $cols, $x, $y) = unpack 'S4', $buf;
		@r = ($cols, $rows,
		      $cols && $x ? $x / $cols : 0,
		      $rows && $y ? $y / $rows : 0) if $rows && $cols;
	    }
	}
	\@r;
    };
    @{$self->{_terminal}};
}

# Width, height and type (png, jpeg or gif) of an image file, read
# from its header.  Only what the header says is believed, not the
# name of the file.  An empty list when it is none of them.
sub info {
    my($class, $file) = @_;
    open my $fh, '<:raw', $file or return;
    read $fh, my $head, 32 or return;
    if ($head =~ /\A\x89PNG\r\n\x1a\n....IHDR(.{4})(.{4})/s) {
	return (unpack('N', $1), unpack('N', $2), 'png');
    }
    if ($head =~ /\AGIF8[79]a(..)(..)/s) {
	return (unpack('v', $1), unpack('v', $2), 'gif');
    }
    if ($head =~ /\A\xff\xd8/) {
	seek $fh, 2, 0;
	while (read($fh, my $m, 4) == 4) {
	    my($ff, $type, $len) = unpack 'CCn', $m;
	    last if $ff != 0xff or $len < 2;
	    # a start of frame: SOF0-SOF15 but DHT, JPG and DAC
	    if ($type >= 0xc0 and $type <= 0xcf
		and $type != 0xc4 and $type != 0xc8 and $type != 0xcc) {
		read $fh, my $sof, 5 or last;
		my(undef, $h, $w) = unpack 'Cnn', $sof;
		return ($w, $h, 'jpeg');
	    }
	    seek $fh, $len - 2, 1;
	}
    }
    return;
}

# The size of an image of WxH pixels in cells: as large as its pixels,
# and not larger than the room, which is width and rows (or those of
# the object), the terminal width and its height but $MARGIN lines,
# and max_cells of the method.  An empty list when there is no room.
sub cells {
    my($self, $w, $h, %opt) = @_;
    $w > 0 && $h > 0 or return;
    my($tcols, $trows, $cw, $ch) = $self->terminal or return;
    ($cw, $ch) = @CELL unless $cw && $ch;
    my $max_cols = $opt{width} || $self->{width} || $tcols;
    my $max_rows = $opt{rows}  || $self->{rows}  || $trows - $MARGIN;
    if (my $max = $self->max_cells) {
	$max_cols = $max if $max_cols > $max;
	$max_rows = $max if $max_rows > $max;
    }
    return if $max_cols < 1 or $max_rows < 1;
    my $cols = ceil($w / $cw);
    $cols = $max_cols if $cols > $max_cols;
    my $rows = ceil($cols * $cw * $h / $w / $ch);
    if ($rows > $max_rows) {
	$rows = $max_rows;
	$cols = floor($rows * $ch * $w / $h / $cw) || 1;
    }
    ($cols, $rows);
}

# The rows of an image: lines of text without newlines, or an empty
# list when it is not shown, because the file is not an image, its
# type is not in types (of the call or of the object), or there is no
# room.  The method draws them with render.
sub rows {
    my($self, $file, %opt) = @_;
    -f $file && -r _ or return;
    my($w, $h, $type) = $self->info($file) or return;
    if (my $types = $opt{types} // $self->{types}) {
	grep { $_ eq $type } @$types or return;
    }
    my($cols, $rows) = $self->cells($w, $h, %opt) or return;
    $self->render($file, $w, $h, $type, $cols, $rows);
}

# render(FILE, W, H, TYPE, COLS, ROWS): the rows of the image in COLS x
# ROWS cells.  The method module has it.
sub render { croak ref(shift) . ": no render" }

# Send what the rows need to the terminal.  Nothing by default.
sub flush { }

# A PNG of the image, not wider than MAX pixels: the file itself when
# it is such a PNG, or one made by sips (macOS) or ImageMagick.  A
# larger PNG is the file itself when neither is there.  undef when it
# cannot be made.  The path is given to the command as an argument of
# its own, never through a shell, and with a directory in front, so
# that it cannot be taken as an option or as a "coder:" of
# ImageMagick.  The file made is kept until temp_done.
sub png {
    my($self, $file, $w, $type, $max) = @_;
    return $file if $type eq 'png' and $w <= $max;
    my $in = File::Spec->rel2abs($file);
    my $tmp = File::Temp->new(SUFFIX => '.png');
    my @cmd;
    if (-x $SIPS) {
	@cmd = ($SIPS, '-s', 'format', 'png',
		($w > $max ? ('--resampleWidth', int $max) : ()),
		$in, '--out', "$tmp");
    } elsif (my $magick = which('magick')) {
	@cmd = ($magick, $in, ($w > $max ? ('-resize', int($max) . 'x') : ()), "png:$tmp");
    } else {
	return $type eq 'png' ? $file : undef;
    }
    my $pid = fork // return undef;
    if ($pid == 0) {
	open STDOUT, '>', File::Spec->devnull;
	open STDERR, '>', File::Spec->devnull;
	exec { $cmd[0] } @cmd or POSIX::_exit(127);
    }
    waitpid $pid, 0;
    $? == 0 and -s "$tmp" or return undef;
    push @{$self->{_temp}}, $tmp;
    "$tmp";
}

# Forget the files made by png
sub temp_done { delete shift->{_temp} }

sub which {
    my $name = shift;
    for my $dir (File::Spec->path) {
	my $path = "$dir/$name";
	return $path if -f $path && -x _;
    }
    undef;
}

1;

__END__

=encoding utf-8

=head1 NAME

Text::ANSI::Image - images as lines of text for the terminal

=head1 SYNOPSIS

    use Text::ANSI::Image;

    my $img = Text::ANSI::Image->new or exit;   # no method for the terminal
    print "$_\n" for $img->rows('logo.png', width => 40);
    $img->flush;

=head1 VERSION

Version 0.02

=head1 DESCRIPTION

=begin html

<p><img width="602" src="https://raw.githubusercontent.com/tecolicom/Text-ANSI-Image/main/images/ansipic.png"></p>

=end html

This module draws an image in a terminal as lines of text.  The lines
can be laid out, folded around, paged and scrolled like any other
text: put in columns by L<ansicolumn(1)|App::ansicolumn>, shown by
C<less>, and they stay with the text around them.

How the lines are made is the I<method>.  Each method is a module
C<Text::ANSI::Image::>I<NAME>.  The one of this distribution is:

=over 4

=item C<kitty>

The Unicode placeholders of the kitty graphics protocol.  Each cell
of the image is the character U+10EEEE, with its row and column as
combining characters and the id of the image as the foreground
color.  The image itself is sent to the terminal once, by B<flush>,
and the terminal draws it in the cells, in its full resolution.
kitty, Ghostty and iTerm2 3.7.3 or later support it.

=back

PNG, JPEG and GIF files are shown.  The type is detected from the
content, not the name of the file.  The C<kitty> method sends PNG; a
JPEG or a GIF is converted to PNG by C<sips> (macOS) or ImageMagick,
and is not shown without them.  A PNG much larger than the room is
reduced by the same tools to send less data, or sent as it is without
them.

=head1 METHODS

=over 4

=item B<new>(I<OPTIONS>)

Returns an object of a method.  The options are:

=over 4

=item B<method> => I<NAME>

The method: C<kitty>, or C<auto> (the default), the first method in
C<@Text::ANSI::Image::METHODS> which the terminal supports.  With
C<auto>, B<new> returns C<undef> when the terminal supports none.  An
unknown name dies.

=item B<term> => I<COLS>B<x>I<ROWS>[B<:>I<W>B<x>I<H>]

The size of the terminal, in columns and rows, and the size of a cell
in pixels.  By default it is read from F</dev/tty>.  A cell of 8x17
pixels is taken when its size is not known.

=item B<tty> => I<FILE>

Where the data of the images is sent by B<flush> (default:
F</dev/tty>).

=item B<width> => I<N>, B<rows> => I<N>

The most columns and rows that an image may take (default: the
terminal width, and its height but four lines).

=item B<types> => [ I<TYPE>, ... ]

The types of images shown: C<png>, C<jpeg> and C<gif> (default: all).

=item B<osc> => I<BOOL>

Put a private OSC at the beginning of each row, which tells the id of
the image, its size in cells and the absolute path of the file, for a
program which draws the image itself where its cells are, as
L<ansi2pdf|https://github.com/tecolicom/App-ansi2pdf> does (default:
off; C<kitty> only).  Terminals ignore it:

    ESC ] 7771 ; i=ID,c=COLS,r=ROWS ; FILE ESC \

=back

=item B<rows>(I<FILE>, I<OPTIONS>)

Returns the rows of the image of I<FILE>, as lines without newlines,
or an empty list when it is not shown: the file is not found, not an
image, of a type not in B<types>, or cannot be converted.  B<width>,
B<rows> and B<types> may be given for this call.  An image is as large
as its pixels, and not larger than the room.

=item B<flush>

Sends to the terminal what the rows given so far need: the images
for C<kitty>.  Call it before the rows are shown, or soon after.

=item B<method>

The name of the method of the object.

=item B<supported>

Whether the terminal supports the method, by the environment.  It is
a class method: C<< Text::ANSI::Image::kitty->supported >>.

=item B<terminal>

Columns, rows and the size of a cell in pixels of the terminal.  As a
class method, it takes I<term> as the argument:
C<< Text::ANSI::Image->terminal >> reads the size of F</dev/tty>.

=item B<info>(I<FILE>)

Width, height and type of an image file, or an empty list.  It is a
class method too.

=item B<cells>(I<W>, I<H>, I<OPTIONS>)

The columns and rows that an image of I<W> x I<H> pixels takes.

=back

=head1 METHOD MODULES

A method is a module C<Text::ANSI::Image::>I<NAME>, a subclass of
Text::ANSI::Image, which has:

=over 4

=item B<render>(I<FILE>, I<W>, I<H>, I<TYPE>, I<COLS>, I<ROWS>)

The rows of the image in I<COLS> x I<ROWS> cells.  Required.

=item B<supported>

Whether the terminal supports it (default: no).

=item B<max_cells>

The most columns and rows it can draw (default: 0, no limit).

=item B<flush>

What is sent to the terminal (default: nothing).

=back

B<png> is there for a method which needs a PNG of the image.

=head1 SEE ALSO

L<Terminal graphics protocol, Unicode placeholders|https://sw.kovidgoyal.net/kitty/graphics-protocol/#unicode-placeholders>

L<App::mdee>, which shows the images of Markdown files with it.

L<App::ansicolumn>, L<Text::ANSI::Fold>

=head1 AUTHOR

Kazumasa Utashiro

=head1 LICENSE

Copyright © 2026 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
