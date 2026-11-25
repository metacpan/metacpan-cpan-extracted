package Text::ANSI::Image::kitty;

# The Unicode placeholders of the kitty graphics protocol (kitty,
# Ghostty, iTerm2 3.7.3 and later).  An image is shown by two things:
#
#   - rows of the placeholder character U+10EEEE in the text, one for
#     a cell, with the number of the row and the column as combining
#     characters and the id of the image as the foreground color;
#   - its data, sent once to the terminal itself by flush, as an APC
#     sequence which makes a "virtual placement" of the image (U=1).
#
# The rows are plain text with a color, so they are laid out as any
# text; less shows them with LESSUTFCHARDEF=10EEEE:p.

use v5.16;
use warnings;
use parent 'Text::ANSI::Image';
use MIME::Base64 qw(encode_base64);

# The combining characters for the row and column numbers, from 0, as
# the kitty protocol defines them: those of UnicodeData.txt 6.0.0 with
# "Mn;230;NSM;;" (above the base, no decomposition), but 0300-0304,
# 0306-030C, 030F, 0311, 0313, 0314, 0342, 0653 and 0654, which may be
# fused with the base by normalization.  Written out, so that a perl
# with other Unicode data gives the same numbers.
my @DIACRITICS = map { chr hex } qw(
    0305 030D 030E 0310 0312 033D 033E 033F 0346 034A 034B 034C
    0350 0351 0352 0357 035B 0363 0364 0365 0366 0367 0368 0369
    036A 036B 036C 036D 036E 036F 0483 0484 0485 0486 0487 0592
    0593 0594 0595 0597 0598 0599 059C 059D 059E 059F 05A0 05A1
    05A8 05A9 05AB 05AC 05AF 05C4 0610 0611 0612 0613 0614 0615
    0616 0617 0657 0658 0659 065A 065B 065D 065E 06D6 06D7 06D8
    06D9 06DA 06DB 06DC 06DF 06E0 06E1 06E2 06E4 06E7 06E8 06EB
    06EC 0730 0732 0733 0735 0736 073A 073D 073F 0740 0741 0743
    0745 0747 0749 074A 07EB 07EC 07ED 07EE 07EF 07F0 07F1 07F3
    0816 0817 0818 0819 081B 081C 081D 081E 081F 0820 0821 0822
    0823 0825 0826 0827 0829 082A 082B 082C 082D 0951 0953 0954
    0F82 0F83 0F86 0F87 135D 135E 135F 17DD 193A 1A17 1A75 1A76
    1A77 1A78 1A79 1A7A 1A7B 1A7C 1B6B 1B6D 1B6E 1B6F 1B70 1B71
    1B72 1B73 1CD0 1CD1 1CD2 1CDA 1CDB 1CE0 1DC0 1DC1 1DC3 1DC4
    1DC5 1DC6 1DC7 1DC8 1DC9 1DCB 1DCC 1DD1 1DD2 1DD3 1DD4 1DD5
    1DD6 1DD7 1DD8 1DD9 1DDA 1DDB 1DDC 1DDD 1DDE 1DDF 1DE0 1DE1
    1DE2 1DE3 1DE4 1DE5 1DE6 1DFE 20D0 20D1 20D4 20D5 20D6 20D7
    20DB 20DC 20E1 20E7 20E9 20F0 2CEF 2CF0 2CF1 2DE0 2DE1 2DE2
    2DE3 2DE4 2DE5 2DE6 2DE7 2DE8 2DE9 2DEA 2DEB 2DEC 2DED 2DEE
    2DEF 2DF0 2DF1 2DF2 2DF3 2DF4 2DF5 2DF6 2DF7 2DF8 2DF9 2DFA
    2DFB 2DFC 2DFD 2DFE 2DFF A66F A67C A67D A6F0 A6F1 A8E0 A8E1
    A8E2 A8E3 A8E4 A8E5 A8E6 A8E7 A8E8 A8E9 A8EA A8EB A8EC A8ED
    A8EE A8EF A8F0 A8F1 AAB0 AAB2 AAB3 AAB7 AAB8 AABE AABF AAC1
    FE20 FE21 FE22 FE23 FE24 FE25 FE26 10A0F 10A38 1D185 1D186 1D187
    1D188 1D189 1D1AA 1D1AB 1D1AC 1D1AD 1D242 1D243 1D244
);

my $PLACEHOLDER = "\x{10EEEE}";

# The terminals: kitty (which sets no TERM_PROGRAM), Ghostty (cmux is
# one too), and iTerm2 3.7.3 or later.  TERM_PROGRAM is inherited by a
# terminal started from another, so it can be wrong.
sub supported {
    my $prog = $ENV{TERM_PROGRAM} // '';
    return version_ge($ENV{TERM_PROGRAM_VERSION} // '', '3.7.3') if $prog eq 'iTerm.app';
    return 1 if $prog eq 'ghostty';
    ($ENV{TERM} // '') eq 'xterm-kitty';
}

# The numbers of a version as far as they go: 3.6.0beta2 is 3.6.0
sub version_ge {
    my($v, $min) = @_;
    my @a = ($v =~ /\A([\d.]*)/)[0] =~ /(\d+)/g or return 0;
    my @b = split /\./, $min;
    for my $i (0 .. $#b) {
	my $x = $a[$i] // 0;
	return 1 if $x > $b[$i];
	return 0 if $x < $b[$i];
    }
    1;
}

# A row or a column is a combining character
sub max_cells { scalar @DIACRITICS }

my $serial = 0;

sub render {
    my($self, $file, $w, $h, $type, $cols, $rows) = @_;
    my $cw = ($self->terminal)[2] || $Text::ANSI::Image::CELL[0];
    my $png = $self->png($file, $w, $type, $cols * $cw * 2) // return;
    # an id of 24 bits that another program is not likely to use
    my $id = ((($$ & 0xffff) << 8) | (++$serial & 0xff)) | 0x010000;
    push @{$self->{_queue}}, [ $id, $cols, $rows, $png ];
    my $color = sprintf "\e[38;2;%d;%d;%dm", ($id >> 16) & 255, ($id >> 8) & 255, $id & 255;
    map {
	my $r = $_;
	$color . join('', map { $PLACEHOLDER . $DIACRITICS[$r] . $DIACRITICS[$_] } 0 .. $cols - 1) . "\e[39m";
    } 0 .. $rows - 1;
}

# Send the images to the terminal, in chunks of 4096 bytes of base64,
# and forget them
sub flush {
    my $self = shift;
    my @q = @{delete $self->{_queue} // []} or return;
    if (open my $tty, '>>:raw', $self->{tty}) {
	for my $q (@q) {
	    my($id, $cols, $rows, $png) = @$q;
	    open my $fh, '<:raw', $png or next;
	    my $b64 = encode_base64(do { local $/; <$fh> }, '');
	    my @chunk = unpack '(A4096)*', $b64;
	    my $out = '';
	    for my $i (0 .. $#chunk) {
		my $more = $i < $#chunk ? 1 : 0;
		my $key = $i == 0 ? "a=T,U=1,i=$id,f=100,q=2,c=$cols,r=$rows,m=$more" : "q=2,m=$more";
		$out .= "\e_G$key;$chunk[$i]\e\\";
	    }
	    print $tty $out;
	}
	close $tty;
    }
    $self->temp_done;
}

1;

__END__

=encoding utf-8

=head1 NAME

Text::ANSI::Image::kitty - images by the Unicode placeholders of the kitty graphics protocol

=head1 SYNOPSIS

    use Text::ANSI::Image;
    my $img = Text::ANSI::Image->new(method => 'kitty');

=head1 DESCRIPTION

The method C<kitty> of L<Text::ANSI::Image>.  Each cell of an image is
the placeholder character U+10EEEE, with its row and column as
combining characters and the id of the image as the 24-bit foreground
color.  B<flush> sends the images to the terminal, which draws each
in the cells of its id.

The terminal is supported when C<TERM_PROGRAM> is C<ghostty>, or
C<iTerm.app> with C<TERM_PROGRAM_VERSION> 3.7.3 or later, or when
C<TERM> is C<xterm-kitty>.  A terminal started from another may
inherit its C<TERM_PROGRAM>, which is then wrong.

An image is at most 297 columns wide and 297 rows high, the number of
the combining characters.  A pager has to take U+10EEEE as a printable
character: C<less> 632 or later does with C<LESSUTFCHARDEF=10EEEE:p>.
The cells that a search of C<less> highlights are drawn in its color
instead of the image.

=head1 SEE ALSO

L<Text::ANSI::Image>,
L<Terminal graphics protocol, Unicode placeholders|https://sw.kovidgoyal.net/kitty/graphics-protocol/#unicode-placeholders>

=head1 LICENSE

Copyright © 2026 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
