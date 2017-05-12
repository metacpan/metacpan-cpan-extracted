package Text::PDF::TTFont0;

=head1 NAME

Text::PDF::TTFont0 - Inherits from L<PDF::Dict> and represents a TrueType Type 0
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
use vars qw(@ISA);
# no warnings qw(uninitialized);

use Text::PDF::TTFont;
use Text::PDF::Dict;
@ISA = qw(Text::PDF::TTFont);

use Font::TTF::Font;
use Text::PDF::Utils;

=head2 Text::PDF::TTFont->new($parent, $fontfname. $pdfname)

Creates a new font resource for the given fontfile. This includes the font
descriptor and the font stream. The $pdfname is the name by which this font
resource will be known throughout a particular PDF file.

All font resources are full PDF objects.

=cut

sub new
{
    my ($class, $parent, $fontname, $pdfname, %opt) = @_;
    my ($desc, $sinfo, $unistr, $touni, @rev);
    my ($i, $first, $num, $upem, @wid, $name, $ff2, $ffh);

    my ($self) = $class->SUPER::new($parent, $fontname, $pdfname, -istype0 => 1, %opt);
    my ($font) = $self->{' font'};

    $self->{'Subtype'} = PDFName('Type0');
    $self->{'Encoding'} = PDFName('Identity-H');

    $parent->{' version'} = 3 unless (defined $parent->{' version'} && $parent->{' version'} > 3);
    $desc = PDFDict();
    $parent->new_obj($desc);
    $desc->{'Type'} = $self->{'Type'};
    $desc->{'Subtype'} = PDFName('CIDFontType2');
    $desc->{'BaseFont'} = $self->{'BaseFont'};
#    $name = $self->{'BaseFont'}->val;
#    $name =~ s/^.*\+//oi;
#    $self->{'BaseFont'} = PDF::Name->new($parent, $name . "-Identity-H");
    $desc->{'FontDescriptor'} = $self->{'FontDescriptor'};
    delete $self->{'FontDescriptor'};

    $num = $font->{'maxp'}{'numGlyphs'};
    $upem = $font->{'head'}{'unitsPerEm'};
    $desc->{'DW'} = $desc->{'FontDescriptor'}{'MissingWidth'};
    $desc->{'W'} = PDFArray();
    $parent->new_obj($desc->{'W'});
    $font->{'hmtx'}->read;
    unless ($opt{-subset})
    {
        $first = 1;
        for ($i = 1; $i < $num; $i++)
        {
            push(@wid, PDFNum(int($font->{'hmtx'}{'advance'}[$i] * 1000 / $upem)));
            if ($i % 20 == 19 || $i + 1 >= $num)
            {
                $desc->{'W'}->add_elements(PDFNum($first),
                        PDFArray(@wid));
                @wid = ();
                $first = $i + 1;
            }
        }
    }
    
    $self->{'DescendantFonts'} = PDFArray($desc);

    $sinfo = PDFDict();
#    $parent->new_obj($sinfo);
    $sinfo->{'Registry'} = PDFStr('Adobe');
    $sinfo->{'Ordering'} = PDFStr('Identity');
    $sinfo->{'Supplement'} = PDFNum(0);
    $desc->{'CIDSystemInfo'} = $sinfo;
    $ff2 = $desc->{'FontDescriptor'}{'FontFile2'};
    delete $ff2->{' streamfile'};
#        $ff2->{' stream'} = "";
#        $ffh = Text::PDF::TTIOString->new(\$ff2->{' stream'});
#        $font->out($ffh, 'cvt ', 'fpgm', 'glyf', 'head', 'hhea', 'hmtx', 'loca', 'maxp', 'prep');
#        $ff2->{'Filter'} = PDFArray(PDFName("FlateDecode"));
#        $ff2->{'Length1'} = PDFNum(length($ff2->{' stream'}));

    if ($opt{'ToUnicode'})
    {
        @rev = $font->{'cmap'}->read->reverse;
        $unistr = '/CIDInit /ProcSet findresource being 12 dict begin begincmap
/CIDSystemInfo << /Registry (' . $self->{'BaseFont'}->val . '+0) /Ordering (XYZ)
/Supplement 0 >> def
/CMapName /' . $self->{'BaseFont'}->val . '+0 def
1 begincodespacerange <';
        $unistr .= sprintf("%04x> <%04x> endcodespacerange\n", 1, $num - 1);
        for ($i = 1; $i < $num; $i++)
        {
            if ($i % 100 == 0)
            {
                $unistr .= "endbfrange\n";
                $unistr .= $num - $i > 100 ? 100 : $num - $i;
                $unistr .= " beginbfrange\n";
            }
            $unistr .= sprintf("<%04x> <%04x> <%04x>\n", $i, $i, $rev[$i]);
        }
        $unistr .= "endbfrange\nendcmap CMapName currendict /CMap defineresource pop end end";
        $touni = PDFDict();
        $parent->new_obj($touni);
        $touni->{' stream'} = $unistr;
        $touni->{'Filter'} = PDFArray(PDFName("FlateDecode"));
        $self->{'ToUnicode'} = $touni;
    }
    
    $self;
}


=head2 out_text($text)

Returns the string to be put into a content stream for text to be output in this font.
The text is assumed to be UTF8 encoded and the return string is a glyph sequence for
the text. If subsetting is enabled, then all the glyphs returned are also marked for
output.

=cut

sub out_text
{
    my ($self, $text) = @_;
    my (@clist) = Text::PDF::Utils::unpacku($text);
    my ($f) = $self->{' font'};
    my ($g, $res);

    foreach $g (map {$f->{'cmap'}->ms_lookup($_)} (@clist))
    {
        vec($self->{' subvec'}, $g, 1) = 1 if ($self->{' subset'});
        $res .= sprintf("%04X", $g);
    }
    "<$res>";
}


=head2 out_glyphs(@n)

Marks the glyphs as being needed in the output font when subsetting. Returns a string
to render the glyphs as specified.

=cut

sub out_glyphs
{
    my ($self, @list) = @_;
    my ($g, $res);
    
    foreach $g (@list)
    {
        vec($self->{' subvec'}, $g, 1) = 1 if ($self->{' subset'});
        $res .= sprintf("%04X", $g);
    }
    "<$res>";
}


=head2 width($text)

Returns the width of the string, assuming it to be UTF8 encoded.

=cut

sub width
{
    my ($self, $text) = @_;
    my (@clist) = Text::PDF::Utils::unpacku($text);
    my ($f) = $self->{' font'};
    my ($width, $g);

    foreach $g (map {$f->{'cmap'}->ms_lookup($_)} (@clist))
    { $width += $f->{'hmtx'}{'advance'}[$g]; }
    $width / $f->{'head'}{'unitsPerEm'};
}
    

=head2 outobjdeep($fh, $pdf, %opts)

Handles the creation of the font stream including subsetting at this point. So
if you get this far, that's it for subsetting.

=cut

sub outobjdeep
{
    my ($self, $fh, $pdf, %opts) = @_;
    my ($d) = $self->{'DescendantFonts'}->val->[0];
    my ($f) = $self->{' font'};
    my ($s) = $d->{'FontDescriptor'}{'FontFile2'};
    my ($ffh);

    if ($self->{' subset'})
    {
        my ($max) = length($self->{' subvec'}) * 8;
        my ($upem) = $f->{'head'}{'unitsPerEm'};
        my ($mode, $miniArr, $i, $j, $first, @minilist);
        
        $f->{'glyf'}->read;

        for ($i = 0; $i <= $max; $i++)
        {
            next unless(vec($self->{' subvec'},$i,1));
            next unless($f->{'loca'}{glyphs}[$i]);
            map { vec($self->{' subvec'},$_,1)=1; } $f->{loca}{glyphs}[$i]->get_refs;
        }

        $max = length($self->{' subvec'}) * 8;

        for ($i = 0; $i <= $max; $i++)
        {
            if (!$mode && vec($self->{' subvec'}, $i, 1))
            {
                $first = $i;
                $mode = 1;
                @minilist = ();
            } elsif ($mode && !vec($self->{' subvec'}, $i, 1))
            {
                for ($j = 0; $j < scalar @minilist; $j++)
                {
                    if ($j % 20 == 0)
                    {
                        $miniArr = PDFArray();
                        $d->{'W'}->add_elements(PDFNum($first + $j), $miniArr)
                    }
                    $miniArr->add_elements(PDFNum($minilist[$j]));
                }
                $mode = 0;
            }

            if ($mode)
            { push(@minilist, int($f->{'hmtx'}{'advance'}[$i] / $upem * 1000)); }
            else
            { $f->{'loca'}{glyphs}[$i] = undef; }
        }
        for ( ; $i < $f->{'maxp'}{'numGlyphs'}; $i++)
        { $f->{'loca'}{'glyphs'}[$i] = undef; }
    }
    $s->{' stream'} = "";
    $ffh = Text::PDF::TTIOString->new(\$s->{' stream'});
    $f->out($ffh, 'cvt ', 'fpgm', 'glyf', 'head', 'hhea', 'hmtx', 'loca', 'maxp', 'prep');
    $s->{'Filter'} = PDFArray(PDFName("FlateDecode"));
    $s->{'Length1'} = PDFNum(length($s->{' stream'}));

    $self->SUPER::outobjdeep($fh, $pdf, %opts, 'passthru' => 1);
    $self;
}


=head2 ship_out($pdf)

Ship this font out to the given $pdf file context

=cut

sub ship_out
{
    my ($self, $pdf) = @_;
    my ($d);

    foreach $d ($self->{'DescendantFonts'}->elementsof)
    { $pdf->ship_out($self, $d, $d->{'FontDescriptor'},
            $d->{'FontDescriptor'}{'FontFile2'}); }
    $pdf->ship_out($self->{'ToUnicode'}) if (defined $self->{'ToUnicode'});
    $self;
}


=head2 empty

Empty the font of as much as possible in order to save memory

=cut

sub empty
{
    my ($self) = @_;
    my ($d);

    if (defined $self->{'DescendantFonts'})
    {
        foreach $d ($self->{'DescendantFonts'}->elementsof)
        {
            $d->{'FontDescriptor'}{'FontFile2'}->empty;
            $d->{'FontDescriptor'}->empty;
            $d->empty;
        }
    }
    $self->{'ToUnicode'}->empty if (defined $self->{'ToUnicode'});
    $self->SUPER::empty;
}

1;

