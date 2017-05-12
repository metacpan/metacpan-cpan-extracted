package Text::PDF::TTFont;

=head1 NAME

Text::PDF::TTFont - Inherits from L<Text::PDF::Dict> and represents a TrueType
font within a PDF file.

=head1 DESCRIPTION

A font consists of two primary parts in a PDF file: the header and the font
descriptor. Whilst two fonts may share font descriptors, they will have their
own header dictionaries including encoding and widhth information.

=head1 INSTANCE VARIABLES

There are no instance variables beyond the variables which directly correspond
to entries in the appropriate PDF dictionaries.

=head1 METHODS

=cut

use strict;
use vars qw(@ISA @cp1252 $subcount);
# no warnings qw(uninitialized);

use Text::PDF::Dict;
use Text::PDF::Utils;
@ISA = qw(Text::PDF::Dict);

use Font::TTF::Font 0.23;

@cp1252 = (0 .. 127,
       0x20AC, 0x0081, 0x201A, 0x0192, 0x201E, 0x2026, 0x2020, 0x2021,
       0x02C6, 0x2030, 0x0160, 0x2039, 0x0152, 0x008D, 0x017D, 0x008F,
       0x0090, 0x2018, 0x2019, 0x201C, 0x201D, 0x2022, 0x2013, 0x2014,
       0x02DC, 0x2122, 0x0161, 0x203A, 0x0153, 0x009D, 0x017E, 0x0178,
       0xA0 .. 0xFF);

$subcount = "BXCJIM";

=head2 Text::PDF::TTFont->new($parent, $fontfname, $pdfname, %opts)

Creates a new font resource for the given fontfile. This includes the font
descriptor and the font stream. The $pdfname is the name by which this font
resource will be known throughtout a particular PDF file.

All font resources are full PDF objects.

=cut

sub new
{
    my ($class, $parent, $fontname, $pdfname, %opts) = @_;
    my ($self) = $class->SUPER::new;
    my ($f, $flags, $name, $subf, $s, $upem);
    my ($font, $w);

    foreach $f (keys %opts)
    {
        $f =~ s/^\-//o || next;
        $self->{" $f"} = $opts{"-$f"};
    }
    
    $self->{' outto'} = $parent;                    # only one host for a font
    if (ref($fontname))                             # $fontname is a font object
    { $font = $fontname; }
    else
    { $font = Font::TTF::Font->open($fontname) || return undef; }

    $self->{' font'} = $font;
    $Font::TTF::Name::utf8 = 1;
    $name = $font->{'name'}->read->find_name(4) || return undef;
    $subf = $font->{'name'}->find_name(2);
    $name =~ s/\s//og;
    $name .= $subf if ($subf =~ m/^Regular$/oi);
    
    $self->{'Type'} = PDFName("Font");
    $self->{'Subtype'} = PDFName("TrueType");
    if ($self->{' subset'})
    {
        $self->{' subname'} = "$subcount+" . $name;
        $subcount++;
    }
    else
    { $self->{' subname'} = $name; }
    $self->{'BaseFont'} = PDFName($self->{' subname'});
    $self->{'Name'} = PDFName($pdfname);
    $parent->new_obj($self);
# leave the encoding & widths, etc. until we know the glyph list

    $f = PDFDict();
    $parent->new_obj($f);                      # make this thing a true object
    $self->{'FontDescriptor'} = $f;
    $f->{'Type'} = PDFName("FontDescriptor");
    $upem = $font->{'head'}->read->{'unitsPerEm'};
    $f->{'Ascent'} = PDFNum(int($font->{'hhea'}->read->{'Ascender'} * 1000 / $upem));
    $f->{'Descent'} = PDFNum(int($font->{'hhea'}{'Descender'} * 1000 / $upem));

# find the top of an H or the null box! Or maybe we should just duck and say 0?
    $f->{'CapHeight'} = PDFNum(0);
#            int($font->{'loca'}->read->{'glyphs'}[$font->{'post'}{'STRINGS'}{"H"}]->read->{'yMax'}
#            * 1000 / $upem));
    $f->{'StemV'} = PDFNum(0);                       # no way!
    $f->{'FontName'} = $self->{'BaseFont'};
    $f->{'ItalicAngle'} = PDFNum($font->{'post'}->read->{'italicAngle'});
    $f->{'FontBBox'} = PDFArray(
            PDFNum(int($font->{'head'}{'xMin'} * 1000 / $upem)),
            PDFNum(int($font->{'head'}{'yMin'} * 1000 / $upem)),
            PDFNum(int($font->{'head'}{'xMax'} * 1000 / $upem)),
            PDFNum(int($font->{'head'}{'yMax'} * 1000 / $upem)));

    $flags = 4;
    $flags = 0;
    $flags |= 1 if ($font->{'OS/2'}->read->{'bProportion'} == 9);
    $flags |= 2 unless ($font->{'OS/2'}{'bSerifStyle'} > 10 && $font->{'OS/2'}{'bSerifStyle'} < 14);
    $flags |= 32; # if ($font->{'OS/2'}{'bFamilyType'} > 3);
    $flags |= 8 if ($font->{'OS/2'}{'bFamilyType'} == 2);
    $flags |= 64 if ($font->{'OS/2'}{'bLetterform'} > 8);
    $f->{'Flags'} = PDFNum($flags);
    
#    $f->{'MaxWidth'} = PDFNum(int($font->{'hhea'}{'advanceWidthMax'} * 1000 / $upem));
    $f->{'MissingWidth'} = PDFNum(int($font->{'hhea'}{'advanceWidthMax'} * 1000 / $upem) + 2);
    $f->{' notdef'} = PDFNum(".notdef");

    $s = PDFDict();
    $parent->new_obj($s);
    $f->{'FontFile2'} = $s;
    $s->{'Length1'} = PDFNum(-s $font->{' fname'});
    $s->{'Filter'} = PDFArray(PDFName("FlateDecode"));
    $s->{' streamfile'} = $fontname unless ($self->{' subset'});

    $font->{'cmap'}->read->find_ms;
    $self->{' issymbol'} = $font->{'cmap'}{' mstable'}{'Platform'} == 3 && $font->{'cmap'}{' mstable'}{'Encoding'} == 0;
    $font->{'hmtx'}->read;
    unless ($opts{'-istype0'})
    {
        $w = PDFArray(map {PDFNum(int($font->{'hmtx'}{'advance'}[$font->{'cmap'}->ms_lookup($_)] / $font->{'head'}{'unitsPerEm'} * 1000))}
                $self->{' issymbol'} ? (0xf000 .. 0xf0ff) : @cp1252);
        $parent->new_obj($w);
        $self->{'Widths'} = $w;
    }
    if ($self->{' subset'})
    {
        $self->{' minCode'} = 255;
        $self->{' maxCode'} = 32;
    } else
    {
        $self->{' minCode'} = 32;
        $self->{' maxCode'} = 255;
    }
    $self;
}

=head2 $t->width($text)

Measures the width of the given text according to the widths in the font

=cut

sub width
{
    my ($self, $text) = @_;
    my (@unis, $width);

    if ($self->{' issymbol'})
    { @unis = map {$_ + 0xf000} unpack("C*", $text); }
    else
    { @unis = map {$cp1252[$_]} unpack("C*", $text); }

    foreach (@unis)
    { $width += $self->{' font'}{'hmtx'}{'advance'}[$self->{' font'}{'cmap'}->ms_lookup($_)]; }
    $width / $self->{' font'}{'head'}{'unitsPerEm'};
}


=head2 $t->trim($text, $len)

Trims the given text to the given length (in per mille em) returning the trimmed
text

=cut

sub trim
{
    my ($self, $text, $len) = @_;
    my ($i, $width);

    $len *= $self->{' font'}{'head'}{'unitsPerEm'};

    foreach (unpack("C*", $text))
    {
        $width += $self->{' font'}{'hmtx'}{'advance'}[$self->{' font'}{'cmap'}->ms_lookup(
                $self->{' issymbol'} ? $_ + 0xf000 : $cp1252[$_])];
        last if ($width > $len);
        $i++;
    }
    return substr($text, 0, $i);
}


=head2 $t->out_text($text)

Indicates to the font that the text is to be output and returns the text to be output

=cut

sub out_text
{
    my ($self, $text) = @_;

    if ($self->{' subset'})
    {
        foreach (unpack("C*", $text))
        {
            vec($self->{' subvec'}, $_, 1) = 1;
            $self->{' minCode'} = $_ if $_ < $self->{' minCode'};
            $self->{' maxCode'} = $_ if $_ > $self->{' maxCode'};
        }
    }
    return asPDFStr($text);
}


=head2 $f->copy

Copies the font object excluding the name, widths and encoding, etc.

=cut

sub copy
{
    my ($self, $pdf) = @_;
    my ($res) = {};
    my ($k);

    bless $res, ref($self);
    foreach $k ('Name', 'FirstChar', 'LastChar')
    { $res->{$k} = ""; }
    return $self->SUPER::copy($pdf, $res);
}


sub outobjdeep
{
    my ($self, $fh, $pdf, %opts) = @_;
    
    return $self->SUPER::outobjdeep($fh, $pdf) if defined $opts{'passthru'};

    my ($f) = $self->{' font'};
    my ($d) = $self->{'FontDescriptor'};
    my ($s) = $d->{'FontFile2'};
    my ($vec, $ffh, $i, $t, $k, $maxuni, $minuni);

    $self->{'FirstChar'} = PDFNum($self->{' minCode'});
    $self->{'LastChar'} = PDFNum($self->{' maxCode'});
    splice(@{$self->{'Widths'}{' val'}}, 0, $self->{' minCode'});
    splice(@{$self->{'Widths'}{' val'}}, $self->{' maxCode'} - $self->{' minCode'} + 1, $#{$self->{'Widths'}{' val'}});
    if ($self->{' subset'})
    {
        $maxuni = 0; $minuni = 0xffff;
        for ($i = 0; $i < 256; $i++)
        {
            if (vec($self->{' subvec'}, $i, 1))
            {
                $t = $self->{' issymbol'} ? $i + 0xf000 : $cp1252[$i];
                $maxuni = $t if $t > $maxuni;
                $minuni = $t if $t < $minuni;
                vec($vec, $f->{'cmap'}->ms_lookup($t), 1) = 1;
            }
            elsif ($i >= $self->{' minCode'} && $i <= $self->{' maxCode'})
            { $self->{'Widths'}{' val'}[$i - $self->{' minCode'}] = $d->{'MissingWidth'}; }
        }
        $f->{'glyf'}->read;
        for ($i = 0; $i < scalar @{$f->{'loca'}{'glyphs'}}; $i++)
        {
            next if vec($vec, $i, 1);
            $f->{'loca'}{'glyphs'}[$i] = undef;
        }
        $s->{' stream'} = "";
        $ffh = Text::PDF::TTIOString->new(\$s->{' stream'});
        $f->out($ffh, 'cmap', 'cvt ', 'fpgm', 'glyf', 'head', 'hhea', 'hmtx', 'loca', 'maxp', 'prep');
        $s->{'Length1'} = PDFNum(length($s->{' stream'}));
    }

    $self->SUPER::outobjdeep($fh, $pdf, %opts);
}

1;

package Text::PDF::TTIOString;

=head1 TITLE

Text::PDF::TTIOString - internal IO type handle for string output for font
embedding. This code is ripped out of IO::Scalar, to save the direct dependence
for so little. See IO::Scalar for details

=cut

sub new {
    my $self = bless {}, shift;
    $self->open(@_) if @_;
    $self;
}

sub DESTROY { 
    shift->close;
}


sub open {
    my ($self, $sref) = @_;

    # Sanity:
    defined($sref) or do {my $s = ''; $sref = \$s};
    (ref($sref) eq "SCALAR") or die "open() needs a ref to a scalar";

    # Setup:
    $self->{Pos} = 0;
    $self->{SR} = $sref;
    $self;
}

sub close {
    my $self = shift;
    %$self = ();
    1;
}

sub getc {
    my $self = shift;
    
    # Return undef right away if at EOF; else, move pos forward:
    return undef if $self->eof;  
    substr(${$self->{SR}}, $self->{Pos}++, 1);
}

if(0)
{
sub getline {
    my $self = shift;

    # Return undef right away if at EOF:
    return undef if $self->eof;

    # Get next line:
    pos(${$self->{SR}}) = $self->{Pos}; # start matching at this point
    ${$self->{SR}} =~ m/(.*?)(\n|\Z)/g; # match up to newline or EOS
    my $line = $1.$2;                   # save it
    $self->{Pos} += length($line);      # everybody remember where we parked!
    return $line; 
}

sub getlines {
    my $self = shift;
    wantarray or croak("Can't call getlines in scalar context!");
    my ($line, @lines);
    push @lines, $line while (defined($line = $self->getline));
    @lines;
}
}

sub print {
    my $self = shift;
    my $eofpos = length(${$self->{SR}});
    my $str = join('', @_);

    if ($self->{'Pos'} == $eofpos)
    {
        ${$self->{SR}} .= $str;
        $self->{Pos} = length(${$self->{SR}});
    } else
    {
        substr(${$self->{SR}}, $self->{Pos}, length($str)) = $str;
        $self->{Pos} += length($str);
    }
    1;
}

sub read {
    my ($self, $buf, $n, $off) = @_;
    die "OFFSET not yet supported" if defined($off);
    my $read = substr(${$self->{SR}}, $self->{Pos}, $n);
    $self->{Pos} += length($read);
    $_[1] = $read;
    return length($read);
}

sub eof {
    my $self = shift;
    ($self->{Pos} >= length(${$self->{SR}}));
}

sub seek {
    my ($self, $pos, $whence) = @_;
    my $eofpos = length(${$self->{SR}});

    # Seek:
    if    ($whence == 0) { $self->{Pos} = $pos }             # SEEK_SET
    elsif ($whence == 1) { $self->{Pos} += $pos }            # SEEK_CUR
    elsif ($whence == 2) { $self->{Pos} = $eofpos + $pos}    # SEEK_END
    else                 { die "bad seek whence ($whence)" }

    # Fixup:
    if ($self->{Pos} < 0)       { $self->{Pos} = 0 }
    if ($self->{Pos} > $eofpos) { $self->{Pos} = $eofpos }
    1;
}

sub tell { shift->{Pos} }

1;

