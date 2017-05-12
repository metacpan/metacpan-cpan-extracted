package Text::PDF::SFont;

# use strict;
use vars qw(@ISA %widths @encodings);
@ISA = qw(Text::PDF::Dict);

use Text::PDF::Utils;
use Compress::Zlib;
# no warnings qw(uninitialized);

=head1 NAME

Text::PDF::SFont - PDF Standard inbuilt font resource object. Inherits from
L<Text::PDF::Dict>

=head1 METHODS

=head2 Text::PDF::SFont->new($parent, $name, $pdfname)

Creates a new font object with given parent and name. The name must be from
one of the core 14 base fonts included with PDF. These are:

    Courier,     Courier-Bold,   Courier-Oblique,   Courier-BoldOblique
    Times-Roman, Times-Bold,     Times-Italic,      Times-BoldItalic
    Helvetica,   Helvetica-Bold, Helvetica-Oblique, Helvetica-BoldOblique
    Symbol,      ZapfDingbats

The $pdfname is the name that this particular font object will be referenced
by throughout the PDF file. If you want to play silly games with naming, then
you can write the code to do it!

All fonts in this system are full PDF objects.

=head1 BUGS

Currently no width support for Symbol or ZapfDingbats, I haven't
got my head around the AFMs yet.

MacExpertEncoding not supported yet (I don't have the width info for any
of the fonts)

=cut

BEGIN
{
    @encodings = ('WinAnsiEncoding', 'MacRomanEncoding');
    %enc_map = (
        'WinAnsiEncoding' => [0 .. 126, 128, 160, 128, 145,134, 140,
        131, 129, 130, 26, 139, 151, 136, 150, 128, 153, 128, 128, 143,
        144, 141, 142, 128, 133, 132, 31, 146, 157, 137, 156, 128, 158,
        152, 32, 161 .. 255],
        'MacRomanEncoding' => [0 .. 127, 196, 197, 199, 201, 209, 214,
        220, 225, 224, 226, 228, 227, 229, 231, 233, 232, 234, 235, 237,
        236, 238, 239, 241, 243, 242, 244, 246, 245, 250, 249, 251, 252,
        129, 176, 162, 163, 128, 182, 223, 174, 169, 146, 180, 168, 0,
        198, 216, 0, 177, 0, 0, 165, 181, 0, 0, 0, 0, 0, 186, 169, 0,
        230, 248, 192, 161, 172, 0, 134, 0, 0, 171, 187, 131, 32, 192,
        195, 213, 150, 156, 133, 132, 141 .. 144, 247, 0, 255, 152, 135,
        164, 136, 137, 147, 148, 130, 183, 145, 140, 139, 194, 202, 200,
        205, 206, 207, 204, 211, 212, 0, 210, 218, 219, 217, 154, 26,
        31, 175, 24, 27, 30, 184, 28, 29, 25],
        'PDFDocEncoding' => [0 .. 255],
        'AdobeStandardEncoding' => [
		0 .. 38, 144, 40 .. 95, 143, 97 .. 126, 0, 0, 0, 0, 0, 0, 0, 
		0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
		0, 0, 0, 0, 0, 0, 0,  161, 162, 163, 135, 165, 134, 167, 164, 
		39, 141, 171, 136, 137, 147, 148, 0, 133, 129, 130, 183, 0, 
		182, 128, 145, 140, 142, 187, 131, 139, 0, 191, 0, 96, 180, 
		26, 31,175, 24, 27, 168, 0, 30, 231, 0, 28, , 25, 29, 132, 
		0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 198, 0, 170,
		0, 0, 0, 0, 149, 216, 150, 186, 0, 0, 0, 0, 0, 230, 0, 0, 0, 
		154, 0, 0, 155, 248, 156, 223, 0, 0, 0, 0],        
                );
}

sub new
{
    my ($class, $parent, $name, $pdfname, $encoding) = @_;
    my ($self) = $class->SUPER::new;

    return undef unless exists $width_data{$name};
    $self->{'Type'} = PDFName("Font");
    $self->{'Subtype'} = PDFName("Type1");
    $self->{'BaseFont'} = PDFName($name);
    $self->{'Name'} = PDFName($pdfname);
    $self->{'Encoding'} = PDFName($encodings[$encoding-1]) if ($encoding);
    $parent->new_obj($self);
    $self;
}

=head2 $f->width($text)

Returns the width of the text in em.

=cut

sub getBase
{
    my ($self) = @_;

    unless (defined $widths{$self->{'BaseFont'}->val})
    { @{$widths{$self->{'BaseFont'}->val}} = unpack("n*",
                uncompress(unpack("u", $width_data{$self->{'BaseFont'}->val}))); }
    $self;
}

sub width
{
    my ($self, $text) = @_;
    my ($width);
    my ($str) = $self->{'BaseFont'}->val;
    my ($enc);
    $enc = $self->{'Encoding'}->val if defined $self->{'Encoding'};
    
    $self->getBase;
    foreach (unpack("C*", $text))
    { $width += $widths{$str}[(defined $enc and $enc ne "") ? $enc_map{$enc}[$_] : $_]; }
    $width / 1000;
}

=head2 $f->trim($text, $len)

Trims the given text to the given length (in em) returning the trimmed
text

=cut

sub trim
{
    my ($self, $text, $len) = @_;
    my ($width, $i);
    my ($str) = $self->{'BaseFont'}->val;
    my ($enc);
    $enc = $self->{'Encoding'}->val if defined $self->{'Encoding'};
    
    $self->getBase;
    $len *= 1000;
    
    foreach (unpack("C*", $text))
    {
        $width += $widths{$str}[$enc ne "" ? $enc_map{$enc}[$_] : $_];
        last if ($width > $len);
        $i++;
    }
    return substr($text, 0, $i);
}

=head2 $f->out_text($text)

Acknowledges the text to be output for subsetting purposes, etc.

=cut

sub out_text
{
    my ($self, $text) = @_;

    return PDFStr($text)->as_pdf;
}

BEGIN
{
%width_data = (
'Courier' => <<'EOT',
8>)QC8"`-,$4,)TB9?_"%Q]`(*0`U#D_/
EOT

'Courier-Bold' => <<'EOT',
8>)QC8"`-,$4,)TB9?_"%Q]`(*0`U#D_/
EOT

'Courier-BoldOblique' => <<'EOT',
8>)QC8"`-,$4,)TB9?_"%Q]`(*0`U#D_/
EOT

'Courier-Oblique' => <<'EOT',
8>)QC8"`-,$4,)TB9?_"%Q]`(*0`U#D_/
EOT

'Helvetica' => <<'EOT',
M>)R54#$.PC`,C.U.?4`E_I!/P)2E?0)+9Q:V/H"=/0]@[0_X0R362FQ]0"16
MSFY+4<5"3HJ<LWV.S[G_#M4;5$#+GKUT'-W=N`L'L);3S!;&!X.7%T<@`9%;
M*3DAFQ%[V7/".RJG.;VEM^K6IE;T8.\&4\R3KMYN<`-E-Z!_F5=3UARJ$B)%
M0P4U'+#/T?X^RFB]-_T_!QFG[50+<59]5,RSP?7*37Y\IA0ZB9]TQ@O*B&JZ
MP@E3`K<S3VHZ0>N@P$YQ!?33$L_[5>J+E`OPK]*<2G-E^^VJ=),+B\,_W`]K
)A]92?@,9KULP
EOT

'Helvetica-Bold' => <<'EOT',
M>)R54"L6PC`0S&Y<#Y#70^02H&IZ!4PT!L<!ZO$]`+8WX;U('*X*Q0&8G=!0
MZNB\-)O]S>PZ]]\G_08!YZY1HS]K=D_Z!NWH#Q(LLH7E:$<D?]/\P8A7HYDU
M&?9.,]ZC^2QF?S_!@EUX41^9G<J!)R%&5@G0DPJ@I\0B>AG_2P9I327F.5#[
M[&>[W;5H\S-R#.B%"+O@+MSFFZQ+V4>=JB7+0TYXH3.L7B[8!/=$?8'V$7Q[
G`V>J0/],!L`X.(?YFP70U:RV-7+N"LS[W?!2GW[0K6QN[`T)B%=1
EOT

'Helvetica-BoldOblique' => <<'EOT',
M>)R54"L6PC`0S&Y<#Y#70^02H&IZ!4PT!L<!ZO$]`+8WX;U('*X*Q0&8G=!0
MZNB\-)O]S>PZ]]\G_08!YZY1HS]K=D_Z!NWH#Q(LLH7E:$<D?]/\P8A7HYDU
M&?9.,]ZC^2QF?S_!@EUX41^9G<J!)R%&5@G0DPJ@I\0B>AG_2P9I327F.5#[
M[&>[W;5H\S-R#.B%"+O@+MSFFZQ+V4>=JB7+0TYXH3.L7B[8!/=$?8'V$7Q[
G`V>J0/],!L`X.(?YFP70U:RV-7+N"LS[W?!2GW[0K6QN[`T)B%=1
EOT

'Helvetica-Oblique' => <<'EOT',
M>)R54#$.PC`,C.U.?4`E_I!/P)2E?0)+9Q:V/H"=/0]@[0_X0R362FQ]0"16
MSFY+4<5"3HJ<LWV.S[G_#M4;5$#+GKUT'-W=N`L'L);3S!;&!X.7%T<@`9%;
M*3DAFQ%[V7/".RJG.;VEM^K6IE;T8.\&4\R3KMYN<`-E-Z!_F5=3UARJ$B)%
M0P4U'+#/T?X^RFB]-_T_!QFG[50+<59]5,RSP?7*37Y\IA0ZB9]TQ@O*B&JZ
MP@E3`K<S3VHZ0>N@P$YQ!?33$L_[5>J+E`OPK]*<2G-E^^VJ=),+B\,_W`]K
)A]92?@,9KULP
EOT

'Times-Bold' => <<'EOT',
M>)R54#$.PC`,C)T%Y0&9^`%Y0;<.+$C]`DO?DJ43>S<65AZ05W3F`960F#(Q
M<78"+6(BI]B.[=@^&_/?H>X;YDD=[RA3MK-MR:LW<R-^7"^1'R"'&P%^G7GB
M$5=D;YUU%.%U/-HK3]#P(19*CIU+)BJ@$^^U5N9`26ZU)0)I6TB\-1+5EWG2
M_HD&<Z.!-^!SK+//HLVES%9>95+T#-)?M?3VY%$G4JK[J*Q0$?E\IZ#\#:R.
M3N`8`'3GK>P$]@'QAT#F6:#<Q@)45ZC?O8&YW.I'+XP68*;T@:_(ZQS9MW()
(93.47Q0]@OL`
EOT

'Times-BoldItalic' => <<'EOT',
M>)R54+L1@S`,E>2.`;Q$F,`5&8`-.!I/P0#NTS-`V@S`%-09@+O<I7*5*D]R
MXH1+%=Z!]?/3XQ']]W"_!STXR8$S9W=T#7NK9@FH:\]KYP>8D:#`K4YFPUJ^
MX$BX/TMT$VJK1.NTY40-'8E@\,IA7,JXV*N;6W1TJW<-XK(O`1[9(K/-)1[H
MR@-4$H^F?7.;GG0V;6/)BE*W83OVNXNIB,HOJW*:'^G]5V#$O-RX@8J1"%'/
M)VAL@5XZ3,`3R[+<%?:?%>"OL2D&S($/PE>L2G:N0M-2X5_(U0.=")H7%,>>
$ZZB'L0``
EOT

'Times-Italic' => <<'EOT',
M>)R54#L.PC`,C9T-1E`W;N"9O0?H%5AZBAX@>T<DQB!8.4!/42'.P,24`3'Q
M[*;0BHD^)?ZES_9S[K^/JCG<"_>1$B5?^H6[639QU#Q.H94?X`U'!?[:<PT<
MN#?;<X]JAUA\F;,X8!2UR-7PA`*8`YV,2QD[.T.W`H`/IK%?L/=)>5'I$+6T
MHI8WV&=GLS>^4>O.PVS^KEW0!Y&_:@7S7&P*47[P@-/T")\N*YV&G[2V_1V\
M"CTB"8EILC2MA+;P'PK8^@O?8-_LC^IB9]5@1)SXHJI,D7<;4&3,7\1)9(J]
%`8H]BK$`
EOT

'Times-Roman' => <<'EOT',
M>)R542L2PC`0S6Y<-1/'#2(S>`[0*V!Z"@Z`1\+D`%@$,I89=`=\916J@D'Q
M=IMV6E#T3;9]N]NWGQCSWT/E'.8->Z"..KNVA;FHM^,@?APGD1\X<AP$E.R1
M:XY`S15[V!K_[X39K3#U1=A*F#VKKT*.PWE`JZ0$VY]R4!=KB[$>%/M.H-YI
M9F-NU/`2\VRT]]:V\C8GZ9\#6%*`V3NJ>^W':VWIOH9BROO(5:"(2ORBA<YO
M\%72'C-Z0+*NNBM/*\2?`DHZ30;T(Z94#-N=QH$P8UXG&<%QPES&;._HY>LF
%/HNICN<`
EOT

'Symbol' => <<'EOT',
M>)RED*%/PV`0Q;_W#C-D1<WT''YVR(HF\Y]`#(DGH#!X,ML_8*X"4\,?L":H
MVID9DAF^A&0)R3"\:TT3</M^N6LN[_)Z=R&<^4XHV>+(F5W;)1J40E4X>2#'
M\1]RY)PY>%/N6"ENN>(/(SOYW:NN[4&YL\`/7G$I]16-JF>;<H72;M2W=C=U
MNU-"PPDJ1A1R<?<%)_W7<Y2Z8,L:GXJ$?=ABKPG/?DR\"]]RVO17^!JXR&S'
MZ($7S5;U<[3Z[_NPMZYUD'[@VN;:=&H["V+N65..\-IR\:A.OVJK[>+(/Z'H
3]4S^3R/20`@HD+%V_NJ_?N9DIP``
EOT

'ZapfDingbats' => <<'EOT',
M>)RMD#M+`T$4A>>>TZ3TD4V,51K!3CO!!R$B@LTV%M:2*BFUL1!+"19:F2)9
MB"AIM)`$B6D$14%,D11:^@,DJ(46NT8$#_X"0>?CFP<S<^?.=>YOS1+L\$H^
MH$N/"2;1X"5/,,85[K$FZ^S@G3[Z^,`,:OA$A!!O]HIQI)#%&8<8%PFF.,I)
M3BG.DOJLYAE6\(1[O&AW!.>,T6D,<8T;'.."TYS0:4_K4[105Z1AW#')09G7
M>WT1(N2FB'/`FF['/*M:T8H($"C_;3$GXN)+E*WL>JYGOOF_JP`>D4::NZCH
M7Q%C6$83:S\_^D^VN,C(VGAF($NL\D#,,\]9!F*?ASRR+M>Y('+,J1XM%IQC
405DU2*[*#=[*C&Y5V6;I&TT<5J(`
EOT
);
}

1;

