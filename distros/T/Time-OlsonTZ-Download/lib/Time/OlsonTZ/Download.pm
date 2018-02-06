=head1 NAME

Time::OlsonTZ::Download - Olson timezone database from source

=head1 SYNOPSIS

    use Time::OlsonTZ::Download;

    $version = Time::OlsonTZ::Download->latest_version;

    $download = Time::OlsonTZ::Download->new;

    $version = $download->version;
    $version = $download->code_version;
    $version = $download->data_version;
    $dir = $download->dir;
    $dir = $download->unpacked_dir;

    $names = $download->canonical_names;
    $names = $download->link_names;
    $names = $download->all_names;
    $links = $download->raw_links;
    $links = $download->threaded_links;
    $countries = $download->country_selection;

    $files = $download->source_data_files;
    $files = $download->zic_input_files;
    $zic = $download->zic_exe;
    $dir = $download->zoneinfo_dir;

=head1 DESCRIPTION

An object of this class represents a local copy of the source of
the Olson timezone database, possibly used to build binary tzfiles.
The source copy always begins by being downloaded from the canonical
repository of the Olson database.  This class provides methods to help
with extracting useful information from the source.

=cut

package Time::OlsonTZ::Download;

{ use 5.008; }
use warnings;
use strict;

use Carp qw(croak);
use Encode 1.75 qw(decode FB_CROAK);
use File::Path 2.07 qw(rmtree);
use File::Temp 0.22 qw(tempdir);
use IO::Dir 1.03 ();
use IO::File 1.03 ();
use IPC::Filter 0.002 qw(filter);
use Net::FTP 3.07 ();
use Params::Classify 0.000 qw(is_undef is_string);
use utf8 ();

our $VERSION = "0.009";

my $keyring = unpack("u", <<'KEYRING');
MF0(-!$R`<F0!$`#``R'VQH3N[II&Y#W:\%,9$HG[X="O<X^JU7`V)VM!RVIP
M:3J?AIQQ=&`])CYT4)W/#X;24$@-\M+9TL:GX[EY73`%+BVXYZ<B2EYF\L*:
M'E&=M]7F``MF7J>95(87_4%2]Z?#S?XQA$FF_R[+;8$/0=4=QNX[Q`Y*A38I
MY;EM%W68#SU8@=[@QT[`NPI[BP[>-OGH#3`E*`E\*8#9S;#-"0&$;I8W>?9(
MO/=>(^%60-X6^D@AR^/Z:NZ/K((A8K:>N:[7#=;V+2U>GW2LF$W0CJ?1J(_`
MVN>\),PLO7>_6*W\$SLZQ[XB3:J(W`%'ZBE`A#JI,G=_FL2$2-%M[Z#B.U9*
M0,K]:F5/DGC?/F)(2J=A@!U#E$=PWXL1.?Z5\F9PTQ?J3Z/*$XZ+<%>?SLTD
M;@X&.1?\OC&V2?UMDY>4\,!BR-_;9TW;*-C-8,I.##00PN/\XD8+D7VP!QQ,
M`A!QP;#59N=SQ#9)U"V57NC".)5QJVDEC!,]$38N4&J=[Y`6V+7K+PZ^,N(L
M'%`8`@1K[^*<P#@!`?PA/!87WXG22B'EF+"^*:'+>"+%Y9(VO*FW'$>"3ME.
M@[Q9$.-@PS+^?=*H^#Z2H"\11Q)*L\:WL5?(XMZ"GK0SO);!GZ@Q=@"NYBV]
M)U0"8K"8OJEV4R%/`*^=H]]_UC.73XFV\WZCUP`1`0`!M"!0875L($5G9V5R
M="`\96=G97)T0&-S+G5C;&$N961U/HD"/@03`0(`*`4"3(!R9`(;`P4)$LP#
M``8+"0@'`P(&%0@""0H+!!8"`P$"'@$"%X``"@D0[9?I#F*J?C11&P_^(CTW
M=A8?8E_@751BNS5U@&K;'D^MG?K(_"[?`>H%S0YM5@5BG2A:/D9HT'3/?U\Q
MZ(#$=`B.\,JHURIT"M'FS&,")YTHX&K@?CEKZ@_^OM$.*;AE>LS-V7I)OIP,
MV0@&OG_E:3+4N\/']:163L[J))9***`;XLQ8<]V%>A/NZ%.#T=#BRAE#`JXE
M.5VF=!IS0;BHCH9S0+,0PCI@"3*VY[V>*]$.$0R243A7K2(SZ`2>GIX-83%'
ML]MN)0O7D]@9#=/2EW;I^X[=&QEQ$6+I!(,[S(.-PXDLX:S@3\GO#9Q`Y(9'
MMOJ!E)+!.;88T+>ZU6ITRW3E!#AVJ=*\>8+XVZ6XL<$,2NB@Y@;\.`M0B!6Z
MDVL&4QQ>BO\HO6N\8`9@*)?NH6(^N1G,$==KN8\)LH,YX*:*O9BDD*LV;@UG
M=M+5S'I)ZJ%9"[05C>'4AZ_!F@O=C6/98%3M-^*`]"67W&0**@-WNN]\\RSG
M#[+G!]\3X$4'U'`_&G?!J,5U@IS3O/<XJ50BG"F(D$%I\WSE^&Y?"C))W6[B
MOS"G8HX*A*+I%4F][HD3*1V+6WQ9S$6X<+26.W\[,3*W"S#.QYJ>ZLX:]U9N
M9,_C_30=3+#:J-G\WD`X'JX\4'78Q<(A^-=\D_WPZE%NH*TPK.%BRPC+Q^TN
.KYCFF;><!&'<UQ=A`%$`
KEYRING

sub _verify_signature($$) {
	my($self, $localname) = @_;
	my $krfile = $self->{top_dir}."/kr.gpg";
	unless($self->{have_keyring}) {
		filter($keyring, "tee", $krfile);
		$self->{have_keyring} = 1;
	}
	my $subjfile = $self->{top_dir}."/".$localname;
	filter("", "gpgv", "--keyring", $krfile, "$subjfile.asc", $subjfile);
}

my $archive_hash = <<'HASHES';
P$`IAK1/'QW'S,*892Y(QHOJBH5H}S8Y%YO)[;GZKP$
^+'@Q[[<#EOR3!YLOVNPT049W7$>C:B+`U'(QD"0>&8 tz32code2006b.tar.gz
VKM[][KTE<B13H0;J6`Z5"2778$%RT;R:641,>&MGBX
W4VW8\YND-$}}SJ>K:&1PQ]"&I2'B'WA@>J8U])7D"0 tz64code2006b.tar.gz
MNA!Y(:V"8<)JH;*GH\8."0W"SK"^AGOF"`U%P<$0!X
R(Y3G'R:4?_W0]Z[L\4H1;A*`1/ZY(FON0&9_>]U8#\ tzcode1996m.tar.gz
]A@KB.+SZ%WC[W%D740$5'WZ8*P(7.K46497CNJX7OD
P\0,)Z7_3B:1`#%JX63KZO2AP6CVCHJQ4JKT#"TX.HT tzcode1996n.tar.gz
>$LQ?T8},4/8PYSXAC%T<X$DM";14,,CY5ALZ]^"1?4
]KY>N'1E-HL@;('"0AHGC8'-BT/"@\J(Q!!#](PR$\L tzcode1996o.tar.gz
(@:9K9#^4'YP@O`[1L*"L/S]TZVG,)?_;/MA-<XG*!`
8%!.RF90V24VGA>FC8<G26>WFYN:-Q``M$W28*W:@+T tzcode1997a.tar.gz
K,ZBCE^VW6*_AKQPGJ'5&1A>`K!?ES.(+R&G!GNSF2@
"?G4I0H3[78@"K2`YX)>(J#!JYV(3Q4/4;$'VQYA_VD tzcode1997b.tar.gz
/*LHT0+AE;#6'ZCVZ6S@VP0$#G@?4Z/:ELZ%`ML^JPP
_O147ENUT'-}4F.NKO}LS'I:N),^H`)<M(5TR.Y9NJ< tzcode1997c.tar.gz
09S8MCYT"Z}'8X**'W5G&B*MK\:#7?$)K75S6K'%MY,
#`2^59N!B6(9\$5:XDIZKB*P@<'JLV6%4UK2@:-SF3P tzcode1997d.tar.gz
$HQI06E:FD2S;'-AO/U08IXL:GYKV,2LF'%S\</ZSB<
Z&DDN6JC6`.D']B,:205L%LE0CIA!G42P*O1)H">J?H tzcode1997e.tar.gz
QKZ[["IJ6[7VWJ)!-S("[_M02XCM:E8CGI-&!GW4;AX
A]9CKZY}%ZW&_?<FHI"-$'YF%ZM)AS>1%}H-8[Y%-*( tzcode1997f.tar.gz
#FPZ-(Q?,Z7^}^4<JJ:XNS`VLS>N:2U62}1P7KW;,E(
D[JK;$_XM)V_K+Z33J)>AEO9TM^G0D@YGI63&2F(CY0 tzcode1997g.tar.gz
;>XM4,W*LTZ9B+JI./#Z7X'?8F[$GYH`:1Q1LR%/&D\
JH+4K2EZ1XM%6$R^`NU4Z[*,BC2@P6F"5KM[}[`2+M\ tzcode1997h.tar.gz
#":0$VMCE7ZE@Q,Z!P"1@"*/N^2:T"@!JIMXDJ5;!E(
@9QB]GO&%(18/1T4SCM)QE0'B[!9/'X>}>9OL+35*SH tzcode1997i.tar.gz
[X%-#X4H;7[LUBSM`/<!9+GU/"YZO<Z;GDQ&H#GDZY<
M4\7'_UDFM!.Q1]'-T}B:VBKD?9\A0^&A'7)G`+I"K( tzcode1998a.tar.gz
1':-`"GE233?Z+^#23T72*U1B7})_?P#,?FR0%[<4,<
_-$XL/Q$5INX@7T'N:D@)LV:RXYWCD9}U\?E:U&RR:4 tzcode1998b.tar.gz
F6@N8$>[<+#8`:L`"%I-L:)4ZQO)Q0J"MG8EHL}UQ6L
"%;]G2:!.*Q`^+"3HE\9UTIX-"O6]%U"+'$,7?H0;$< tzcode1998c.tar.gz
OGT#:)(S_L&#`'6`%96EGNJ[D'OK3-LZD-H&2S8MD!@
1.1L+NNJR&2E2,0PPMN!:S)TMUK&'\V(G$8AI,N"W!P tzcode1998d.tar.gz
J$>9-;<)+Z,U2-F\KECK;>@L4U!C%MG)B7H6H>6SJ80
A;/YMV00%LL`^L0%QBC;E<KZ!$WN/*ELQM5W7.J#Q'` tzcode1998e.tar.gz
3;!<]_[C8UTV6NO`1&8[)[FZF4$BKK7@9^_6J/\VNEL
25#9+JU6@MJQ@(OG[H>N41Q;#Z$8.D].311#CF+C#@4 tzcode1998f.tar.gz
,%7V%)L1<.UQD}6:AI%FJEW4G-T;L91JPA+T`C!#&HT
V28})%G&$\/BPP+9D!8,A?1>O2ABCKW@JHD"4_SL`X( tzcode1998g.tar.gz
UUSM!AZ#D);N[IXQ9U6ZZ)GYN`I;+T?01#P>/SD:/Q@
HTSY\4#-<D$2F8I@K*A>5<6W$D?R74"_UK[[Z_+T>^$ tzcode1998h.tar.gz
B8X9%$4VK"1:?$&9;)H3!_-F5X*L`5>J*YD1W*OUE$8
_`YLN'QT:E\J}YBN*)Z1$>K_^A$F8WY7%#J3"*Z#!ZL tzcode1999a.tar.gz
0M7Z,7(`*KF1"SGY%V0;#}+U`HY,__@S3%+F_Q#}<+,
(W%J0QU9OZ.UFJM_Z<1OHA(_OU[(N5-SDJP}P0SROGP tzcode1999b.tar.gz
C}T642QR'*@$DP5P]AM)]1,*H;LD^Q(X-`3^K-;EI60
BJR`4,G@Z<9+E1M>ZEZC6<8O;JELN-)3IG@VZ:,`8^, tzcode1999c.tar.gz
$&N/VK]JF)"D"OUAU7U4I^N`.]@!0)3@UJ2K]N#;]$8
#0M&UN-:"]\]&9/P8POORT@I**@<XT@^W3*<V^}"><P tzcode1999d.tar.gz
Y4IXT]3HZBWYI*[EZ09%34OX}3D]2S#J%QN$Q#*VY&,
50:56X>(&I'!Z8<P:13PN8W%6+>(%L)"_C09*26BL?D tzcode1999e.tar.gz
'I%Q%3}}1T!+RBD4YRHC+>ZO+1&8};MH3O}_9MW}K>(
D%J)Q[R0!]6H184H-T"K%V;!@M>^VS?05W1+GVM@LV\ tzcode1999f.tar.gz
V*L0,}B.+3MP419UKZN$A_D6L].#:MC3PI?;8O43:CD
1A}`Z"S/%U'@YJRRE9SN?BOY)3"047+</"7IW%W}U88 tzcode1999g.tar.gz
IPA/8;KIQLJBG&:]B!J:LE}`/*AY,CB><'>("ATUII4
Z@2W8@66O+V6@0GU,49S:7U)DS^.^;+S?(PK@(<]0*P tzcode1999h.tar.gz
AK_%4;>J&XQ,NL[XLUO?T\T^@N._KXKOX)L59:)/?K$
2?%&#P.Q];2-W%UQI_2%\[!1U4OXY]EG]V(_\1J$&Q0 tzcode1999i.tar.gz
1"}X)FO<L!R/O"4$\!M+_Q[?D&L,_@K7RS@M;G<$^Y\
6`<YD/M3BSU.:$\4AK6S3EH)P:5.L,6M`(`[[EGV,]D tzcode2000a.tar.gz
RC/M"+CQOOS+%U#BL6&Y\<L``Z}0;?M\Y+`V.7AB.9<
DJ(8Z}J).%@E_#F?7N'/V}RKCK5[NWV)+KDV&VGY*ML tzcode2000b.tar.gz
,#`3><[;_M`"4^,5XKQHX&5,C[3_(J%HM?P'UH[585(
S:/:T"]P%M4E%]!,:ZO!URXU_:,Q!Y\_S9ZXEHJC*2L tzcode2000c.tar.gz
(<\&.}-1)HEVTL0A^>MC^9[OTA_F<LO9&&$Q0RI!4-L
F/@1W";,1P%#BU%^8VSY_NQ**\'H_C0-9.KA2S%A4L\ tzcode2000d.tar.gz
+I<;KTO/A5^*45]&(4KP9RJ/UI>Y.+"<H5/G_#ZOXH@
$MPO9HF_E*&%R'\V4FV>VQ}ZT7MWI"5(UEWOW?['<]P tzcode2000e.tar.gz
2&}YVT"CI\+K*\0?N>,GC<EM':K/K^>"?ZU0Z&(RYEP
BS}Y6*&G2+/M9VONR%0"6'A#MR7C??`]Z+2W.\BQPAX tzcode2000f.tar.gz
7#P3%J2%7A#YSM.FY2#XG'I$O6<1M`VE(IB';(0[*3D
6A.L+/TX(K8%M:8?<KCWI&!E4C3FME;\Q<#$'+J%)L@ tzcode2000g.tar.gz
+*"8*,CII+E`H9A?AQ0LH#*-9YE1&]4;8D]+&RNGKWX
*3GE?JMMDF7N<X>BF]3_#48@$P"%3>64X%5#1N5;@0` tzcode2000h.tar.gz
TC7WXM34$`?6H8*)2\FY!\F&}:Q:98PL$%/G3YY$Z$`
})<MR9@0F!D^LW5Z.LY^1%5^+7J]KN?Q.OR7^?ZPC5X tzcode2001a.tar.gz
**DQ2N>YE-HJJ;0\[:)!9J+/<`4<_F8+N61^8441A,$
^A90}%',RV/]O1UMEJV3C5C3NRU`W*S:DQ@ZAVI#<#8 tzcode2001b.tar.gz
MV/V,C9&LLT@.5M#:>B/`T.D)N<4^?%I?F*!4#O<EJ\
6@#J6GD*6*G$&00J<:Z:Z}F$P+>VX1)T--`})[1)AX` tzcode2001c.tar.gz
3QU-.}YK84}19:9G)5]@M2$%A7M@49<Q,/}CXZO?8`T
)X6#$TJ`RUQBBKF;B%P9@Y`'8I}C"%UK?+HT`8B+6`P tzcode2001d.tar.gz
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ tzcode2002a.tar.gz
T.%Z>O^9.S8JS?`/23&@2M&%PJ\K-1:+_N3R;0Z;J1@
;}L$L$_ILD*@"WY<_*O:F4ZG]X[&}L*F@/]801!"C^( tzcode2002b.tar.gz
1/6}?:Q[*'ESZ4W4ZPLB,UGJDE.C'JP3HJ+/")+WH&L
5/86VN'P(?}^+-RQ?MO\?`}9@I^R$_'NJTC,)X1_2ZD tzcode2002c.tar.gz
JR,QLT`-V>MKT3<-\@6Q3(<}/;1*$*LXD2L%J$L%F:<
`WN7U1E-81^7>KJDWY1%#205QE_P`N07MQ\DSI3?0ML tzcode2002d.tar.gz
?UK(}H/#"%POR<U)-+G`JE3HC%BO}H.*"#XX2>WZ0^$
-YX7B$L]M[K"8!,E[G.}<Y[3?W*V70):#S5-"(1C!Y0 tzcode2003a.tar.gz
N/G+J1V(.++FW9+IA$<?.(WU4M[#./>%@[9AX,EVGCT
._F/:VBL%G_T!U/8)K}Y1MZ^\`^:<EY?3GXT],G3@Q( tzcode2003b.tar.gz
#3^/+OXE@&_V/DJ\_3D&P`GS2ZV`6ZN##4"S@+%C#Y(
#?'KUM:?&NQ.BMY9I\U_MTY}V1RHDSO7%$M0}7M9&+< tzcode2003c.tar.gz
!CBY7S<9&:Q#*,!ZOVX;'I&9<S^>D7!F96K!G0"/UV\
MVF8;A6X_,>!%<<^L^8]34L\`9M}27K$EUQP,$)2'(X tzcode2003d.tar.gz
S9W}"ZQ@.+];?HJKMR6,3-7%K7>H6`Z([O9JZ.)A:O$
F,KUSRP?)RO$0ZD*B]ZJQ`L6;%2C0+D#J@V7AORX76L tzcode2003e.tar.gz
`+0}U\YKO7D8TGDOW3VQU#WDMH@.D&6>'!,+V@KN*RP
?[9E)T;IQEF`RMGQTG.4+?U;83H`<8-'Z7]>UM+J3Q8 tzcode2004a.tar.gz
6+Z;]QTTA!ER6/Y8QT4?DZ'1X1F-W]-^&3^W^&[>4:8
:AD\%WF#/`}]WIGU20*X[K83+B#JGPW#8F}-U!!"478 tzcode2004b.tar.gz
P-,&A>PX)7WP6A&IE>+]WX*5L3?Y,}(3\*O8^>E*`30
NH`MY*`7A[W/DI^\&?XT*O__I<%@GP+9LM,H3/YO&_4 tzcode2004c.tar.gz
["LMMYE#'#@HF@W3WKMMZSGMA_6Y"A6}@/R]A0*LC3\
:HJ28L+C8S3G5<T4M]$;S%]G*0'4<]WH3'}%CDMPUL0 tzcode2004d.tar.gz
_+'A`<`;^H'F&U:[,&^Q'7;&:<FMK71B7*@2V?`VGJ@
@,EDOQ5,9X\F}U+"@7P@.YA(Q3$D!?)4>#%J[2<R7!H tzcode2004e.tar.gz
-X]#/^GF-;R5O;OPL;)!PRKM,AVZ"ZG"-2\0)]5S?J,
NEU>F?]}K!7!A9DW/B1*]TMNBA8BY:H:;.K039)8A`4 tzcode2004f.tar.gz
%$&HJA/+)M/#>B/4_'&ZG8XDG!<;S8\</&;2-D.8W.$
5TC}&[-3V*Y[QF!}L]E".>T_SGI:"(_%FGE^NG3W0UT tzcode2004g.tar.gz
*L}R5"A1]0M6,0`8X\R$LKPWZ&U/05PATMRL+3P!8A$
M+?V@C,>N)XG1XOW1HM`@H)!A*)14??,8LN-7]X*}EH tzcode2004h.tar.gz
/DA%)8']P1H0$F0&C,`AL<6^R[DY!*RF3H.BI,U_[ZT
*Q5X]:E`[5*V9<`7&"5O]$PIEOR<347DQB1]YA("`L4 tzcode2004i.tar.gz
`(WD0#KWDTL8NX;-U+";PR(`M@^)_NBVR,4ZI(EJ+#$
1!E#SX}_-56)++GFJS)G(4]/0\/9Z'N"_6-$RC!>}K` tzcode2005a.tar.gz
4(!D94,CPK]]!O4]\R\UWL!!GLO#E#?I!`FSBMOIONH
I(B<]#W}4BS2;A<}0`O9L@:)92O#3M"\+*KX5#>6474 tzcode2005b.tar.gz
CQCMWN><IW"*/?9A:H$DZS[IY}2@>}8[*,,Q(T^MN0@
I^Z$TX}].:FK*KF$"*:;)>D"/@?1"4Y^@"?,+>,1RTD tzcode2005c.tar.gz
^T76E[M;_9.N'.}1+KPP,CE[;DZHGC1$+]NZV[H%.ZT
'+HY]/EHH"!,U#4/?&BX^&9T/XNK1`7GH>X]@0M}E6( tzcode2005d.tar.gz
M]1HTD2U/\ZA_WGM2M6)?RF,:BYRZKPJCD2BJ!L!N[<
QWJ5.N`E<8#&Z}O27}>[H5&?]3$M?6G(9>%NH11X;"\ tzcode2005e.tar.gz
04RHVS!UC[$<Z\ZE3!0UZWJZIRFUPJV^&9F\Z+4RL78
$:H$^4K/K[9BM'>6JJ%9%9^]HX\UBCWG["LXAP?R+RD tzcode2005f.tar.gz
#")G:1:>2+?\9L(S:_@Y%C([NC?Z1M]JZG?C%#;UP(L
OL^>8SJVSR2B?>5A&#7>+6-!2**4:;>9:+VE!<D6?&4 tzcode2005g.tar.gz
[};+`0M2"]\'DI!'F&@O_&P:}!N<\_6@,XA9"#K_1V(
B[ZV,F^;8,[105J_Z7G<OFA+&E'IA8"2XW5/FB(B,BX tzcode2005h.tar.gz
7VX/+BVEU!M^[-)H&'US-NTIARYZ`IK-^2}T#48TZ#H
AGJS#D4$0[?0<35*!N>ZH7#?#PX3K8SZ?&,[_H.X6IL tzcode2005j.tar.gz
KU&312RMUH%H.[KEP4*]^7GPIVJK[SNO[A?D0DT/9,P
;0#'LBR$M0#&KH1G&9-@4;?Q&)']MCV5T?IK$J&4QL, tzcode2005k.tar.gz
8[9+^VIG+D9J7+:AD6072WD,\9PS*YK-1/7P6DI}&\4
C1$P^RGJV4I8LYOLV]Q600D>?N*ZT&1E>$A}W#IU+(` tzcode2005l.tar.gz
W@+W#1`4?(R^)$4^N7[9DX+/T?J0LYM8N4WQR-#34!D
[LN98?,_W,`Y}[5;R"I#I?7_XH_83^*+^$B5W7*S]NH tzcode2005m.tar.gz
1K0M)`5<.A[VA3(Z</)B!%VF4MG$J_Q-};2)7___3D0
*G\Y}!A?HJN@!/EQ2&0:#SH<NX3;:Z)>@IFO1<+&?H` tzcode2005n.tar.gz
E#4.YX^HQQ)A}N.:}?MW+W+;EXC_I(Y%[D]7I5JCX'P
]ZNVA1-?(TBVI'E@VQ7\ZI^HWE^H(?%/Z9PKV"Z#('X tzcode2005o.tar.gz
R91\O!/V+*<G+.*T*&8[>R@:6"HMW9ECU#%;\_K07L<
E`H"$IH)%7]/9$QZA\-DE1S?F)@SC9I88-%}W;^?26L tzcode2005p.tar.gz
ZC(%^8I,2}R$XU&^+KPN#F\K$,QDK&Z*^'"!?XN)YF$
@8Q1T5W!IG._S)W;;QWT9+8W07[9,EU?R6VP[JN(S]0 tzcode2005q.tar.gz
3@;MB<OAI]1YJVM1.P_+E]S9:("B]Y82)TXLLV"OFEH
O$;Z+}[ML/^LWR5S}TE<U)2O89,0`54!"VC^),+84P4 tzcode2005r.tar.gz
W}XN&$-]L\D"'!IU9.C`QTD;]0BUQ5YQK7P3!N]MP`L
]SU(?0#Q0HN5@O!I217?UMJX+3VI^C%OSCS#N6NU+^X tzcode2006a.tar.gz
]VZ+6E4Z)\)"^V,0"89WBZ0EY,AH>8V-B1XV!&[Z\%\
XOUW'?I7&"KRV}0V"<;*ONG[UY[,)"T*?R&/1'X8}7@ tzcode2006c.tar.gz
B}8VJ8@$W._U)3KK*K2/LKE!LHM4^H_}U<M6}N1\'.H
LE$%A'/>*`'Y!-?./7(XD[G/KBX>`%W'KQE>1V?YT-\ tzcode2006d.tar.gz
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ tzcode2006e.tar.gz
Z.[$%PGQJJ)).]X;N/%#T`IBGY;8}'E(AWP&<-5HA_D
7GJB!Q6?'5*.WWO1_,R+.L3#34I_B5D@]W;-?D6:5K` tzcode2006f.tar.gz
1R[3I66V8Y)QI.*466A^W/..6A#}9%V)<W%9S##]U+T
01BME5QF*S/#*O<U}7_7/C3$K#J1B+I)%>K?5?C7(6, tzcode2006g.tar.gz
0F4"C%,LLNEMD2:()!;-9PLX5Y8J0J+K`"\3BQ\C.UP
7+560Y^#7A3:/#&K!()Z:E_LRML?VZ;HFI6DE%#;YB4 tzcode2006h.tar.gz
ZBQD>[}0}5D]V0B>9"6?DUUL8/XDY:9RH"<-@C5-#+8
"}'O2FOX]UR9RR'!GP#?WN&82Y<P9XV93%Z!U@*Q<\H tzcode2006i.tar.gz
CELV`-F$?+?U1:A3'1TKB??H#B;`!AS#Q;0_KK]Z/TX
)L`T#FB6-YAUJ(;3A?$*(74$A5'S/<O"6W+E_D_GK3D tzcode2006j.tar.gz
M9L,63Z$Y![++\QR@H-NNEHH&[*'H6$R!6_CNR6-?)8
}T!(I:ZE(].H5^5F(JX**Y#8P>8-3#'/C&5A9!}NPQ< tzcode2006k.tar.gz
,@%IK`@E32)LAY_`5:,)%7Q$1VQ`W3/CC*'QE*U!}L4
B([2E@K?C)[OST4N,-#K@A*$%^QJL7&)$;:$OZ6IL"( tzcode2006m.tar.gz
^C]TE)CXC9CS.`:,D"/EI6O#9+7:!,C[_"IJFSJ+*(H
/L6'R7?".GAJ6+QL":L'OF[.\Y}3?B7+KBB!ISFI:LD tzcode2006n.tar.gz
KO[C!UHRFP$3/.*_LKBN1BBV[C*`MJE}A]VYA30IT',
:S?CSBSI$NC+U7W<2'F0(}'R[+2I7TWZAPXGWAI?BWX tzcode2006o.tar.gz
@M4"3/@RZLNR^F@_CKQXE\+`B.@@G>SA!TOXLC}[[PD
QF}_:;,Z/-<NPY:7/?I/[-+(>I'}H/I;;@<G8_?,8K@ tzcode2006p.tar.gz
\G+SJ4<#052;^V4%W1KDX,*DY}111\C:BF@NG/P+>%0
0%T7`I&#/M<_54QY\/LH)#"X"&Z5,*;&^(\]RR*EQ*L tzcode2007a.tar.gz
FF0!Y}I4:8W_\E!KYD_#T&7}&4I%G%20CMMQ\1/V^?`
H59(IH()IJVF!;L+A.+X/G?#?83:B9+]^ZCE}3QBPP0 tzcode2007b.tar.gz
(&9OZNGI-MWQAKGK_8Y]JS`&KP-}?E/.!H'MOVT(1V(
Z-AS^*UXV5BM7(5P0Y<*'@X@#;T4\Z^E5-*!E:I[N3H tzcode2007c.tar.gz
/,V'0JX:9/V9RI?]7X5L576T8.#&_5Y\1ZCF>CE1)Y$
8'7G.R)CLF8}V4Z0\_WQ-[F^OEH'<UNT*">Y6WIXP&( tzcode2007d.tar.gz
Q(.3RJ3L`J9"I+BO^NA/O2X+&?S&}Y>DJTS5_C8]R0@
T76<+I)`/.U2.$:I,&-R_0?U5S(;VM:EN/OJ)<IV[,L tzcode2007e.tar.gz
E/68(PB*:V;W"S8'$\'7O@5>("YA;>8UF'[M/*A\HP(
9:$?X`R2Q4T<."-.\L24!M[U\SYY1G,.KQ\DO*0S'$0 tzcode2007f.tar.gz
GZ_/G!0"\@HI?D(9*;.G;\M;'Y[@'_M4Q44]>IB*MQT
&U.L_@`$.H6}9%S]ZY]M(,[L8S]A%X!DM&]YJ"R-01L tzcode2007g.tar.gz
!DLU(10X_Q%5:2I:4CV&*B+WOV#+^}DU5});+E>..;(
@S5EVJ&(:`!7#L)`>4NK6R$W>3>4EZ6Z:`6OQG/_0Z, tzcode2007h.tar.gz
:LRJXSUR@B9RF&Z&J}>+<#HD#\+K--'M_MO<I"I2NYD
Q'*FY@&Z0`C'L,%/CXWZ6)QN8?D(]^+]>&<E%X"N7?L tzcode2007j.tar.gz
5;C5L)V82N2!9\F)?;LT\'?:GT?`9U+TJS6:F`+\@8$
Q3Y/5>"JN4BAM^?'4S}:]V6#D/`GW$,+(.Y`@RC3M)T tzcode2007k.tar.gz
LBV/*G*8^!)1VZP.2X*/A,-?R19X!>]_/^&/<,T?X?`
6X:\AOD7?/`QE-}^AU)Y>K`(A?K+W#UGN687<[WOQ)L tzcode2008a.tar.gz
\?K\-4HMR'!L/0!T]%HY,?.Q\;>;>IQ.R90,[`G--F<
7N`"<U/V}C!]'[U}H;H_U9VOZ%>DJ5AJ]>>!\>T]*4@ tzcode2008e.tar.gz
KSA;C__8G-Z([[:IF:6DG%(BZS;>*NP]$+A./\N-\SP
<UQ97/Z_V\0TDXYN$#&L'Q)C*O!;B`WP1"<I(-H}}YP tzcode2008g.tar.gz
/R95)8>6T0NK92!;+HH@(,P/%DX!E8W'OGP:4R/+OK,
}1]V}:J-\-!1*@RVD$W?[:HAVL(IPX9.;_[[P/YL%R, tzcode2008h.tar.gz
%#&NNJP&>RM#6#ZSXQN}6NH"MKL.L-5R199@}\-(>6@
5&:2_?&0EV-H`D#C>RK:.<7M2:6CVW`[&1^T51<9>/< tzcode2009a.tar.gz
-PUP%I)[1I0W'HN.Y"*5S2)'2MP3}O&+V4QG`}FFN)D
]TN\#,![&-3D\X1B5!ES$PJ1N\/Q`}SH?C4-8)VW56< tzcode2009b.tar.gz
*Z}0Y;V6J"40BXFN+}0.5DRP%0:V5'?-5_A]7//&6#D
,12VK4$LWWI#WOC0Z7I0_I>8BG;$V[XTLU:?%W;6EFD tzcode2009d.tar.gz
.K)*P'^+'^&;.U}-#G61@$EZ6:B;^0J,"''VXY!Y^C(
D#$/8@9;E1S-XP*P9[[5F>AG_$':83/%IB@979.0*B, tzcode2009e.tar.gz
QF5:9)&KZ4*T":]1Z(;/#4FZLW.X^$I}MVV7H*`Q_)<
U6'YM$J\NMH_8\S^<?VF_45<QHGQ}*PBLE."}^.5V?4 tzcode2009h.tar.gz
;69$E8O$#3;K^V*T8$Q+>\)^)P\"R-]?BF8RKLQJCJ0
)16*ZL48A&R?9&5'XZRB%T95>_+E*\77'E?8+<I[/N` tzcode2009i.tar.gz
1W@/D4]7DAQ50#"P},W])S5(,AX-&H0EU1NQR^IS&U8
)62'!9;5N@S18-%5CP>%9V)'?$8[^S}7*G`7UDZT14( tzcode2009k.tar.gz
PRM0FP,`]<EJFLYJBW.R>O"`8&T;&JJBY28M_%-Q[K<
$!`UJWO9Q'8Y8.91/G(%UM$"R%-BW?3%*4.M[3G}M., tzcode2009q.tar.gz
@W-!V<)4;]K#V\<''LC3]OZ>#G`"J-8F5F]TW15IEMX
G1P"X-!@>VD&D'69_X3MH2+0$@>;A8+SG\'\D_8[PI$ tzcode2009r.tar.gz
*_G1P(#L[^*@59%V-E]FKW9]A1!!Z>N.V\}T)ZH7X`P
@W_U5PX!J'G-0*^HV.C)!I1<@<!"`]L?%D-.X?%2#D$ tzcode2009t.tar.gz
GM]HD2'[NY0AC}^?EZ6N%>DJI'$ZJC1[J+S`41,4+H(
*3&4!:)"F8>?1,@;&7\EQN8*-ZXI._<}F`Z"!);^M`8 tzcode2010a.tar.gz
0_*2/IJR*_@HUB7!/(C`G.D"_M.Q]G:%49K@;"EF7O$
W6"('R;'*49%WL\4)}VBM#PKB>1/-,D!QT5<]R_46P$ tzcode2010c.tar.gz
O:Z-IZBEO.<,P<]4Z#X\%A>}2-7**5^33>>?.5O}`\$
FA2ZX79K"8BU<([.0<>X*\:?1}6"2&_,N1Q_/I2E+ST tzcode2010f.tar.gz
<O1Y'YSO+9X>>@W2QCOIQ@BP+M/(ZD$OW7KI2EOHT]4
$-\.J"D\:#`[T;4G#K+,/H#}D+F;Z&:AM2UP,%*IXP, tzcode2010j.tar.gz
37Q]>ZF"HK>^$^MF1Y2`!OAAGN\_L;:8*/4;J@@E[_(
,9$]Y-'!55L]C>?M+$D"Q"YR:B^D$(FZ+Y/**J8PXP( tzcode2010k.tar.gz
-!OW8RU0"0NX[2M-WB]&Z3}>QT61ZT`TG2+UJ2'+R8@
6}S]4VB_&TD:*776%3:+(M}:12@FSRBO7MC#8\ZZ4L` tzcode2010l.tar.gz
,Y}B8)?@L(3S+*-<AG3!>I$9Q*"}Y>N#1[%HQ-M7^*(
7XFW5J*`P%B3A&KT).G51FL2$ESC-I$,LK7?T?,T[XP tzcode2010m.tar.gz
26<?}UZNT<FH''EP`7%G8);7WOJIKD3W$8B+UY:L.!(
W&[KR/<@'2LQ_8E]N.;D#BL48W889<P%%MLUK((>4*, tzcode2010n.tar.gz
"Q:Z7?C;[HQ[,SZ)(>*>K(4J:EHCJH"DUB.]X]AX]S$
}J#+>XW8F0IG/}%IF*+)7:SE>']PFGCZYV/!^D,>298 tzcode2011a.tar.gz
?#>.,@!UM+EL'N-1!CDDC}.$*-?C8M2/>O0MF1&]M[0
J)IO5FK/BM24VNX>1[J&P[6B*&8W0CA}P!+XSFLXS3, tzcode2011b.tar.gz
92GZP1+">/G1$%5Z0_E.0G1(LWR?/&AHKRYC&,,0YH8
S8)K/A:XV%)E7-Y:PRLWV@8)_)!$E)PJE4^-FT97WN0 tzcode2011c.tar.gz
OT5'Q8BZCY;'MOS?%_QOV^OED@]H@DIY6PSUPR%VD>@
;4'WS-'T!S`<@2,CZ@X2_+<S@!+C'5/`L[^D4,2J!T$ tzcode2011d.tar.gz
CS'^:RQA,QX#E$K.)*9_]EP"M#_SCTPZA8:5/T(JC2<
V*S33`};*1[/?M>2$LU&V7/8[@>;]@1ZV[E[$4,R&)X tzcode2011e.tar.gz
<I7%G4B)<}_NP]JM?5ID(:[>Z.!K#PIZ15U7\^)A\V<
O#.*US:8E&0\ACJ?0/A2+<VP7!%VHL[QJ",$?R9<^KT tzcode2011g.tar.gz
3^NQ6-EYG+FG`7)9UVMTU4T*CYW[1D0_IY<!](B60(`
L}9-@>[#C!'\N%KL\Q]"OT)#?7}753?%F,-Z96EV5I8 tzcode2011i.tar.gz
PWV5"!H0E[I&T8A^\3OQ$B%KQ%\A5"OU671/,I8"X0D
PZFGIW!>U!0R!)K3D%^'IT?}O&]\$4</ST3\6_E&R>, tzcode2012a.tar.gz
$K8+:P#;464:A>1$C(>5R/#0^^[L9K[$Z&$]_T'^PS(
2@L@]]9A@U0:.)[_#2J3LS1J!%I8H-EW<YDD\&T!?], tzcode2012b.tar.gz
IUWJ3H4(1UVN[^]?"GIA^;1$0;TNI(5O8*T7TL)H!98
^T6>N0"R\<:CG]RS]I^&?4>]RYMV1LDHD5I5)N(MRT< tzcode2012c.tar.gz
:-,C4\CDMQQ_;RHI4.:CY&}2WG?C;YCKV_)SV__3X:8
RJ'VHW0E.OF86MCE*;KFA9#PN9%)T2R$LTQZKW5:Z"T tzcode2012e.tar.gz
9>Z"?D3]+KAR-]GX/F:EZP}}2O-C4!)U/_Z5+5+Z-DP
,G0^1Y&GDY3`B]-Z%6'90VL]GVRS%J3YF.>J^[3_\&H tzcode2012f.tar.gz
(M;V!@S((UG0#@33(@2}*&UM>.)OPB:7WIK[C9619ML
M#--09N*J0L`J71,""!H8LU)K+Z70M+SLUJ$B2[`$.$ tzcode2012g.tar.gz
\+}G;?[6}SPI9@&!6[K)\-&PFJ?9}UMG?5%(9GA8RHD
V>3H[Q8*&T&)`IB!K^KW+/N\W+^][SV%H28\^:EKN>< tzcode2012h.tar.gz
?%\ZDR>KQB]6';YKUN3HJ,.5S_WE';0:5KZ0CB>BFEX
57KX7*+.)9*J&%B%``#(4,W/#B78.2@TF&A^AG\9*\` tzcode2012i.tar.gz
H!@D./[;'85;4L!S3U*_U-TW!]9<;S1X,]6FBJL3*F@
\K}Z#A@M?L_GQ8&%)%UQ@:L!VI"<+]R$MQ%0PPD#@L( tzcode2012j.tar.gz
SP+B+,7}>H]V%/?_RX44BK](&J)X]8XF]*$>&OG9\D<
F:IH]KBGMJ()U7T[$@YW_<RZBT+?VUL4)6-&#;H7P?$ tzcode2013a.tar.gz
VM\19NOZKI4?9QZ*ZA.(QQ_5`.[5LWZSC^2K_:-T^,\
8`)"#]}I2TY.^Z}8$+J5D?*089^%IZM*VCT"1>ST\?\ tzcode2013b.tar.gz
#7JTII71T^2?'1>(5*[2I&WWJI%GXB"54HRN4(!2(L,
Q?\+I`T-0&(G7,0KJ:NZ\S'AA&BAF22(N1U.>47L_Z\ tzcode2013c.tar.gz
(H9(HK?}?QY#3'GCIMG/??!-_B)6:D+'JX8SIDE3EQT
\PR>,.LHA"[2+A"OF}`]N;Y9YY5_'^X',Z2)%F]WB)H tzcode2013d.tar.gz
GU%<;GC7(<)_#DU2X(8^VV#I<@8.7[2%2278}VB`G<`
MZK!GW>-2TA<K#]^T}>%OC}/#>3EAFHQN@(?@1N<72\ tzcode2013e.tar.gz
@`%30<N6DT6Z8IVF6\0<.KQUX7"K2V>5[X."C06G-ZX
;3WHF`:A%KI^0^#RR,#RCI'+[B`BN?D16GG?)M!&O68 tzcode2013f.tar.gz
W41UD6_C9@D577+/Y#2SAT5;J&#.X5^[NURO-\QW}7T
1GQ*Z`Z!.6*`Z-/[:.$Q-S%1Z-#NZ;OX9TN6^9X*G+T tzcode2013g.tar.gz
R%<#EK7WCXAKV&6"!ONX8T*-_AW+U1)BT23QH;UE#E<
OTQ5CN"#J,TD1>(Y0K*8(2&ECCPDD}9WHH->I;FBZ/$ tzcode2013h.tar.gz
ACT8$SG8M$KIAVH"Y#;:,[<C^!Y9*@X/4?$P"BVL)WL
P8[4(KAC'B<#)VEB`R/)3(2/.KR2;8O"@'33U+2[BB@ tzcode2013i.tar.gz
O4C.BPOJ(^>K}FK.Y\KW*\U16M/@.:M]`U;-X]*5T&H
E$E^1`"R<KK\O*;^F^]\3WG\6+?B4BY*JFW$,5CX!T4 tzcode2014a.tar.gz
#'*N420//5U6RO[7:7?@#_:H\BB@?Q>@_-HM&H:R4U$
$4JO>>C*C7"B-+P/")UIG^!2@*(H7$ZCG@9_Y}RR!<4 tzcode2014b.tar.gz
^62VJ.F^0([6J5`2%FGMRK@>}>[6FH#X!0Z'KQN-V'H
P'AKW>XB>[9.K/T;JF]M"%)5\JJDZ6>_@D8R9\*1YH( tzcode2014c.tar.gz
A$C-`C,BL+'}H(&A`C!<2P9M(7}1;BD@N\KM4**-\TH
<C84(7:X18:(6OAI[[CL?2'?[VDQCYBN;H3S:62L[^L tzcode2014d.tar.gz
\;XMR*$!>\P/^<$/1G!]T"SZR9)<6S0'K*C%&Y#X%[@
2M?_@?1*]*536#C9EG\K\8G8`V-'XJ<J__S^/\<K.P8 tzcode2014e.tar.gz
MNWL!B$}ASSD/"\`895)`2DZZN3<V>_C.>].3!L"2^P
-'R@75PH#HC+P-SF]`(BL],S,9PKN689@]TE1TS59,L tzcode2014f.tar.gz
?#<U;'QC4:;K0O5%TS3W!Q0,)"2M"Z*GCT+%PM6Z?FT
7<3B/>>M[MH_%`+7@S['A7G&W\MI[8>#`XG3J(N$$B` tzcode2014g.tar.gz
]3O'83Y%5[]3}$/U06&P9**)KABE7/,JY;%H.6SV`!<
E#_%6&<@B]MW1P*5`%I-$^WUD9S(>N:LK7DZA&YQLQ( tzcode2014h.tar.gz
[7@(%:'B"6%L>1F7\4VE;+DQ'&6%MPQ0.S*A'H[!7@T
P$PWO>JEH:$WBMIQ236BV3%GG0JDJT*`C1A;8`Y}!8( tzcode2014i.tar.gz
$@}G#!:*@/Z}N&,'`H[Z.OC*,$@7Z^-M];7"TK9]ZZ0
*4\%]-:OH$(@P[)5K1D#XH4+^P9)LNW[+75#1:2R20H tzcode2014j.tar.gz
@-.].NMPXA52I9G&(#9P_G0LJ-)PP_Q#"C!%V.BF80X
O^})05,L!Y'5J9UN2_7[WV*1C>5]-WT_TFY_?WAL9J0 tzcode2015a.tar.gz
V;5LCLF-D5C1#/@-\!@89,1GI#A[C.U7`?1FQ`B%ZE(
2\'4FPX7P*&-@`:D(]H<&YI^}&)L2I%MTWR[A>!+*PH tzcode2015b.tar.gz
`?5^)\$#%#3GVHAV\P"$W^^}OC:8A3G(5_<?AL"K&94
^"R?Y}K3+>T2&%Q30SM_&@53V(2*+9}2F8$"'_UPW[$ tzcode2015c.tar.gz
++3ZSM@YT"YC$Z>JS*32W^9%08;9AD[DJ@-/<H!$+FH
}1SL(H6]XM5Q*6*W,^$'I&\B@D:?91"T+9.7+6PT0DH tzcode2015d.tar.gz
_<5HIH](}KEGLYXA^E/P8]Q75NB&XJ)SS`1M6@%.M1<
Z<D>MN`]&,E*B<Y(5XAHKM<0>005Q0`8C\Y.2MT,Y\H tzcode2015e.tar.gz
7/OKWHH+Y7Z#B*>VTUKKJ9$PIRP:0?F[U}6&11&D<ZH
7I,@JR$%6T.#YDL[G7:"P-,#}\Z$!V&9A[YG)#8!1Q` tzcode2015f.tar.gz
1-J#/:.OVX)C:I4WA3<KM,}EYAY`UP#:0+1JMP`'Z]L
WDU(#A"X?+LVQ%ZJ_\JFN8E#}>+U4[?19E7<%GS4H1\ tzcode2015g.tar.gz
,Z$'BZ%J[QD$BJE\X8%OQ3:`8;_D#MW`Y^)&RE?$I34
ZO+P.$<2CI<:;96?-.IW(DOS/]4]QJ#`!D4-WC4B(B, tzcode2016a.tar.gz
4_}`7]!&;UK,71W5D%1JNVX_0D#6IXSGZ660C9,0Z+@
:&R/OHAY1\43I-YEX^/\`XUD(5HS`F<Y?S?F[\YQ\+@ tzcode2016b.tar.gz
@3,)M&Y"%,OGTBN94;K153;UTY32]E&V"N9L%-V,(RT
49D:V`]_`L,D^);F@,?OL#(:GD>9R6<U\:@N)8J'W_< tzcode2016c.tar.gz
QO8EFGCZVJLI.^"D$CPB;1HR}8ACG/J-K;6G2]6%4HD
*@R'S].C.(CXAO4:_S1&7(E07PB2YKR^)"1ZD6#G,HP tzcode2016d.tar.gz
W*]A6MJ6D@Y@_[,V)3]35!AA%3WLP5;4%F'T/@O[$HP
;",;"W}KOC\A}E231B}?Q:AY!T])}]44$BCEC+,Z0<8 tzcode2016e.tar.gz
E]"$]+"FB/[PE]RB5@@\J92#DX2-}\CN8WO})OA9%0P
SGTK)OP19:.T2RC,')!UX0&2,R)A[6B9"TLAJ%0XL", tzcode2016f.tar.gz
@X.^UM`:`DKTC9OS-72BVP1]PAUULT`0%*M?7)SABCP
T>#9$ROJ:,#E<G:VB@;RR.7N>B6@QP_4C;>'A}E}A34 tzcode93.tar.Z
V0#I+Y<T@`8[K'C}\0*#\^8?SNH'5W&;ZK]\T)$S#EP
7&VY>X'M[]!SV",E}7*+PNP`1L'5T_%}(O0F8H5`O/8 tzcode93c.tar.Z
$#P9]X&N*+)O4}S+[\2[@E#<;4743)<P"'8.RY,@F3T
`]WQCNO2:V`:X&S?>]%E355U5/DVLM[N6/9#!}79+]T tzcode93d.tar.Z
G%>'44/-V(*7_!GZ}OJY9P'P,5<B!(:KAJP"641M`]0
,N??4)N$YU&TD/:]VSEY9"0H<?8?#--NR4T/*R0X[.8 tzcode93e.tar.Z
8C/Z_(/K8KZAL-K^\-QY0O60<%2I1)C`N?XXDFDK,I$
5(*N^X%*V)2PDHBM,<-}],@DB&#_;4>"1TWA?2'FI6< tzcode93f.tar.Z
_>['WQ9$AX,M]L"_6.ARH).&5J<_PLOFIC&}U24G:}(
35_W,VHAB&Z?6$NK>&,}#"MDVRZWDB?E>)NCO;}"Z`` tzcode93g.tar.gz
UHSP"W@@&3-.V!`P,WFQ82S}S2[6M;6B!$<YEH%'W<8
_*1#?Z.U.+HQ,!}[H(___`$2[:P(%:Z\JX/Z'L/J.QX tzcode94b.tar.gz
Z@H]7[O0$1D(FE0'T6COG#W"T]B',RRL<3HW:LQ:@U@
&"YS^X-0&5PXC&2#LKFV<<*"(}MA4\A",;7']/<]C70 tzcode94c.tar.gz
CI]EX%GS46?,.Z;!JE+U,\N}:TPW,W?!'D141$@B28X
[U;F)'V*"$5J?@`/IEOR_EF9I-SNKV>HN89N%0%+:Y4 tzcode94d.tar.gz
C<L<&<$(OX"T#C2"9P:KY^9&<FIW,D8(XF6V;]%K3[`
+;-&YM!F?'Z%;B>}4#4JZQ7KB^(:!X+J#/$H}05@2)H tzcode94e.tar.gz
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ tzcode94f.tar.gz
C601R.Q+I2LKZ%.X`):%S85HPA8C`1]32:W0T!,%<M\
%?X>Z;P9*L3H:-]661E@H`@]4CMOXWATG*[\HT]3F)H tzcode94g.tar.gz
3H]S/<4?5\$!]9`RS$M"$69+*Z%^QR@\.<%N($1W,9,
>OW7;@)Q[U4\]VMG%Y?4C\'XDB<B\/"2^^_IH\;IM*0 tzcode94h.tar.gz
$K$*^`1JPQ.C;_*C:L4VPX"^,5S.^/-"AD}$6+5*U&,
`CP8;[+7}HZ&AT_KF\HSN)UL%W(W514O5C$`+4L1)/H tzcode95b.tar.gz
M!1BT7ZMVBJ;V6D8F#*WS.I+&E,HK]?G;N[U9H2]NX,
0'',HHJ9"DHP0^)6HBPG;Z>%(V_\7"8J4\EH?"TBR'X tzcode95c.tar.gz
^18`.?/@J:8,+Z0M&P6*U8M[U[LW#I:H:M9!H@A&G,4
:&I,GDPN3,;)4#J8'>D7GU(LR$45^C_8*D3C53W86Q< tzcode95d.tar.gz
:JV/F-C<-V}N`LA]Q\64$G;$;8!C_J>+HWZ2?^V0W6$
UKESK8*<VO^MQ!;>TY+K""*98I/J)\8\L>7R-/104(\ tzcode95e.tar.gz
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ tzcode95f.tar.gz
LIKL}.(61$@8(4E[&4X&X?M+,K#.<5A%[%"[V)M??Q<
0<03E<(T8#H6'KB1P[PS,C2*DFKH`AHJ!<7-*.J:SC\ tzcode95g.tar.gz
1#7!LTVEP;0FYMP15(2<-`5YT>YBQ<]DB10&PAW'"L(
P/MBQFM'}$H%,NTX7'D%5DQ*:>L8D_']L,R3)[<A^!D tzcode95h.tar.gz
\TFH^'Z"SN>!A+44DB.>0B@!K4M'L3B)$1I:-D,TSM(
NZ/!%L&!YKS#Y`V1".$Q}.J&Y3L#K:PO}TE3>:&UA?X tzcode95i.tar.gz
HQ_C*X'3$'*L3#MUMI):5EZR<N;[?]9BX#<&UV]^*%0
PNR^RQ*H>9A#TXK#"(4@\@-9<O$B@9LV<!<B.GC!:,\ tzcode96a.tar.gz
DK;*H#9MB^MAK1L*<8B&;$R%J#142^+R'P;T_7C'R30
P5.,30)<NM$NS-S}C/M3`^SMMF6!$7&,.ZV]-#KDZJ( tzcode96b.tar.gz
RU(]55WM[MS#Y6+$6@'<[<JATO0?X"3`,GB%Y/*7`2,
7X;M13S0T`B]7J0?18G)B0AN5K;R?LG8S0G5}&\]G:@ tzcode96c.tar.gz
%B(J?MW:0Q%ON]!(7GV(*#P/'26H]'QA>PGCW-;3$U$
_&EB6G8W+#'$.SR0;(<A,$/U-2!3M$;_CZ-X&P%TUC@ tzcode96d.tar.gz
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ tzcode96e.tar.gz
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ tzcode96f.tar.gz
W5_\LD9F@_F9GC1TWW*TBA*GI#:K2#<!K8@BO^%8[_L
*DF">7IJK<^G};KT3Z8_Y<#'C_EMS*S`,`/7C\#%_+@ tzcode96g.tar.gz
_NC+93_%GSW;S\$]G9IQ1FBX\)Y,^P/\B/-]_&]?M1,
&%@7I9&GS76SZ&CB;(}7`/MUT0$FD25P8HG;Y^]8@;\ tzcode96h.tar.gz
3D1WX#T-E*6970%:Y`9//<$>/?S&G4&Y<2GX7IH[]'H
L:R/3XZA2KF`?2V_LIJ488G4F]/K8^09\W]6KXBH!.D tzcode96i.tar.gz
J\U)4A\T>OFX$YC)0F;FU)U%F7GK72;MI`P9Y*&QWOL
:O;VH'V}(VP,1[>9K\;K\A>#MO^.6[:#\,YSEDL*QXP tzcode96j.tar.gz
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ tzcode96k.tar.gz
R/1+A,DR4),)DH/["Y*',/YD9!`@/YJ1Y"K`472P7+P
HL^O6\ZYTHRM,45-JCT1Z;PA[X#&G"F>`SW!26BW]%@ tzcode96l.tar.gz
,FX+>DZN1`#WZA_R6B>-YX2X&$F2+AWNQPIQJ%$`,\H
FG5VE<*AV%LC}]%8Z?>S2W-SYJU[S9)VH$F:+[P:D4P tzdata1996l.tar.gz
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ tzdata1996m.tar.gz
EH1!U*N648,0\DN:ZLF04Y]%"J,6_D$4K1EI\}\G$P0
DC#*;W^907TS.NJ_YVS^Y*!%VA7V>QW&6Z2J0O-<U7, tzdata1996n.tar.gz
VNM<-^9.5M.UICPV5:;UV);$*(L9!3(*'28LOR*)?N$
\M9A3^Y%8$]I;@P%#1>,6L$[S9XKA,04}"-HNGT_+*< tzdata1997a.tar.gz
-2F$!<%`TLV8RI)C+[NNG,*)}Z"G;L}]#7SZ+>_4Q+X
)FQM(G`Q(J7_&VM-G5<CV0;@*/I([O*!9<7X%Q"0GWH tzdata1997b.tar.gz
`.*%![}<(CG-%'9};:/&5^<2P*HR3P/P7-2_RRS1(R$
]/.U}EC!_^;5B#;:$X$%,#+L'A)#"LM2&9+'%155$6X tzdata1997c.tar.gz
S2[<L/9}AQ!$1D-C'>9}Q35@9;%P.3/3ZO/>DRS450`
G(%Z1TS8#6%NS6Z?R)?O91+}P;/MX4!##[C!E]CS$&< tzdata1997d.tar.gz
"HA$YIA'OO0[&^N0K0F1O'#5?T%MOM};;#<[Y"@;Q8`
6R!UU2W.TVH2-[1UK0[6@%@^HD^[9#J!O>/A$R$9A}4 tzdata1997e.tar.gz
-\Z<[5H;(K`I9/0UC40N$%8FCE_C?PA'!X.\*/#A>'X
U0PA9L<(/OU^QS9Y29-1.6}^!>*)UO5IL1!WT>;*8]( tzdata1997f.tar.gz
N?>$G,1)%Q(8YD7*L-ZX$&*Z8:4N<@8D[ZO7MO,VD7D
VYJ.\-Y'*}&![O2'U\$9"1"<<,`,V6/>S%T46K/&.J4 tzdata1997g.tar.gz
A9%`&65UI%/3#-$M;`X+!EJ'I+\[/&A)25!P-9?V/`\
+%&#64@43C"5R9UV_"5^8WH3}H"N"R1"`ZYZ10"5M5` tzdata1997h.tar.gz
%UE;&/:"J-8#J@],ECT)@}UPFAXBGX}YKUVJPT(Z3,P
.+D'`Q?P\X021ABI+U^BQ/9A6'S>].L1'D1A8WUV6:D tzdata1997i.tar.gz
)%(/R#7$(V^(<_%>_/-O-O@R:].57,#P'^G0"``]!#4
WC'N#8)H6O,K%UO2QNV#BA(P9;L@E2C*6NX"3;:?-K, tzdata1997j.tar.gz
8Q+HC%KI[QUX*#,/F;"J\C_,A7GW;"ZX}FB@E3#BJBD
<D7"%!VWPEI3CA"OYE59?#^+0F]1HW>MAE8F@}6G`P< tzdata1997k.tar.gz
P!A+<C3-OJ)31}%U^H19^6;LGR8ZQT@Z6H4%>,O7B%`
>K$,-Z-X[C]*TM&98HS;(&*^*7}?7`[;UK2R}E_(W'X tzdata1998a.tar.gz
O'H$^0.*'C<?3!W]U_TF`2+0*61%+$&YZG30&C`]BX4
SY3&)`[B?`YC?8B-BW"(H(5&X`P19L2`HT%?*Y9NY"H tzdata1998b.tar.gz
-L)')/BY4RP&1M51*38QB;YGULZ*]:%FO}B:J`1BMF4
]M0?P_7O3+D>^2K#H?}3G-,4H$B+"-^PF:B0P985#]H tzdata1998c.tar.gz
_U937D;GD,RHR>@;"?GZL0').T2<(FM-?T#K7(D[,%P
>L!20&\FO;<!N%M*+@,[*?4I[\+JW7#&/4<<['LGTIT tzdata1998d.tar.gz
Z9I*7`-GAHTPM`1#06>'*\\:1_<$&@P#@PQ$DH%7&$T
W.R8OWRZ!S];}"YX>%JE[X904.17T0X994'/}Y6^FP@ tzdata1998e.tar.gz
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ tzdata1998f.tar.gz
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ tzdata1998g.tar.gz
0I"M<O@5SN#]1+;13<^74$63KV;_1DLV+Y]U;B:_Q-L
(15Q("K7}Y<}`/6}.Z-U!G;E;+WRG\>>6':0F-."C6, tzdata1998h.tar.gz
T@C4<A+D-;$QNQML}N'VH\AA5J}[RS>[YQJ>A+O$AL$
+WSM9Y,0}O+;D:&`Z^,I[CD*7BP^S3[74;*U)!(K;%L tzdata1998i.tar.gz
R-T3W14O0<8^#S<I,AZXB4<O//4M\GRC/PKU,<R"M_(
I\S^L(K,<BS#7)-D"#1LDEWDEY/}%8<]65CTM)XV\P0 tzdata1999a.tar.gz
,WC#S,0O`E;+<F]6_EK\4BEM1F#T[X$B?:R62@NK.4H
<JZ`@-L5F5L%':_V%O%@+QR:\IPNADYI5JZ[8D'>[9T tzdata1999b.tar.gz
%:?JRV;Y#S1\V8M(A$ELG@V'P%A\P\_#L"E7[B:WN/(
5'8$G!W12!5A;\?I#Z2,OH11M0)!1CHZ[VI2@+'}JBD tzdata1999c.tar.gz
CHQO;?K+#EG8!@+K-Z5G>O%'5C8+)6X@'8C!}ISX_KX
`*1;Q]WY3`5GY}$*CKVV.0!BB`GG^F".SWXWSA!N^@\ tzdata1999d.tar.gz
C`YJ53,E^X`2!(T:PI*!<4C^&5R2NC6Y>.!CDHQQ0RH
U2_}PPA><*#&YGQ\Z})E]\QTY**@A;U0KS}[}QJ-S)H tzdata1999e.tar.gz
0Y<Q:6[_!A-0K'BA.QV(JDV.!<(P6J70\Y7K[4%T'$4
5BC\T%K'7K3I4A?Y6D<}%RD.ULQXLVT?/XD5!VHM+O` tzdata1999f.tar.gz
1"Y@ZIN1L-.?'P-5.OY:(2P-4,Z,1?4O5)XX1M6I*I(
S;]IB3:D^MQ&1"&6XPO?}1}?4<$Y6@-2V3ZLM[AL-V\ tzdata1999g.tar.gz
/P29#6V2Y0VJ!<WB%E7I6/}]I1ET[`[8B)>33'%@8B$
J#E&JQ$ICO^RN_P/I"\*G!.L7WZT)0B^(ZRSI2.Z%*4 tzdata1999h.tar.gz
N.[5"H(5K&U#`'D^N^HWM_"$O\EH*.5C]80;?)-?2V4
<TJ6+<;M-B`KU@UP@$_`VM!C;CJ]A01!R<8PM78SY$< tzdata1999i.tar.gz
<HXO2O]MTU1/(62@4<%)M}M.TLK})[MA->2`D#9?1#D
8["(&T?^M+$F]/'M.)H[W)/C9E/%QO$@EV-}]}^+7Q( tzdata1999j.tar.gz
_JR*R]:37,/DDB)6)%<<>S#@ZINCIK+X@"AM>K<-+GL
E[/.;1]ZYC"C}}FP%]AP.SR2WT?8I;ZH(`UL*0A#J(\ tzdata2000a.tar.gz
L6$2NW\KJ)YVNBDTV9.2WS5T#R:Q?>KSWL_E}>0YJR<
8&_UY*+I%$C5UB-5Z%J9:8"0#NN$J1[?2_MYX!E'IEP tzdata2000b.tar.gz
G*F}(Z_ES1XG,#-&13B'`7T}`+N,94FNREV+9X_]F%`
2Z>,5VQ@ZE9$86D60V&V_R\O8CSUK#\+%^7*S(/%WJH tzdata2000c.tar.gz
)F9O-TJ".F;KPT^7&5C:G-,]*4?X,AIT68!}[PZNTMH
F$?0Z9/P%WU&MF'C([@X;1P]S]?EH!M6LOM')W'&A^, tzdata2000d.tar.gz
56UF8TB#P]FPNZ3BVP#I\M@CJ\L+2P`/T9;/%Y9__B@
WJ@O^:996D6?7OM25>E+$%$.KS;"6ZJ):4[Q/OG[#C, tzdata2000e.tar.gz
YM%:>0QR-2IG-U.,__4E^FFPYG7FT&+DS'}B$ZI0?!0
G7Q)5],._6T%"3D.S+Z9>`5^RX&@:D"CN`UD@79WF,@ tzdata2000f.tar.gz
)-]G`$W<ST2ZZ+_Y}-:/:Z09ET:86.5![`7]'#<,K[<
F9D4.>+XD-&3@A<0[IT+Z5<3!#'G7KF"/MY>]5U;J?` tzdata2000g.tar.gz
A<Z2&ZX+E}8VAF:X;]TR4[8$BNF"M$-P8.@4UVR467D
XB7Q1BYV!!D&XTO;B2L?U)[JNN_(/)"OGH.NMIMPZFT tzdata2000h.tar.gz
<^-:IAH`@8V60GLL?@_8M\)EQSI!?G;U'4[*<M&'FV8
*$0GQ-A:3\>8X135/)/RO^RDH6/_R_AX;6?[<!>]\UD tzdata2001a.tar.gz
,C+2}E_'*1I[WF96HX?%HN962+!7.)F,.)5S][?3M1D
5<N7D'E(}%K[W}F"B)JA[^F7NXL;YH&Y^@'3!C%9(D, tzdata2001b.tar.gz
"2)`IF)WK)QM-.F3B0LC'"5J&O}W7TY$7MDBW2.N??4
}[PV#XJ^,]$0!'*]^";^S.4`E%M2)[Z5@,`%^K.`DAD tzdata2001c.tar.gz
:,GWLT*Y-2$5>(NX>D}X561`YMN(^I.J;^$V4,JEP*H
V,ZZE@DLB#.ZW,,8#@D_K[*0I;U]E@G;@ZI0O8M@$+H tzdata2001d.tar.gz
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ tzdata2002a.tar.gz
*!&'%Y<QNR]CMM%7*84C%[P**IH&+28,P,9Q\(]IHW8
\TO_Y^$'G%B)-}$0(QX8W$B#(KYBPX8C1E61,B'O5\T tzdata2002b.tar.gz
6G@?R$W3VCOX5\}DY87,@B!X@,"4[GD9J*<3?$G_]#D
P(T@!A1:Z`VL;&<\'A/DU9'D#J"X51#,?,}IMU0,/WX tzdata2002c.tar.gz
P809;Q2G!%G<F8VZ,:<P^Z08%\0Y-L:7-\_VE:>N!RT
H%JAKHMJ(07G\/_*G7G_6RHL@#5YH"S.A[*I_2<`V>4 tzdata2002d.tar.gz
G^)?2OG*:}AA'&?GU[!35MM_*]-_I@2VTZGV'EE09/<
)}6O$:<'O+'GZM/7D2HQ.2Q%-:M+_OI;[H)'8!??"F, tzdata2003a.tar.gz
KJY4Q_:(%011`,^(TF*QSO]6KQ7N#}*FO.'0I;<K^F\
@+C[G%UI>/?LL-,[IU0M8_/I7CNV?EI;1`5MS!!J&"( tzdata2003b.tar.gz
E8*K>ZZ3['JP%(B0/\D_<?`O(PQE,\#*OL;5K#`W1NT
-Q:^}TSJ\MT(.E&[P5B9K>8?30_H`/-G!]J#1:8":V8 tzdata2003c.tar.gz
3*-1#/W/OC_YE$+]FM6M0WQD\0(G5_,'M)*,$F0&7_P
/S^BK_W4HKXW^}HF+IJ"::R)P".IQ*)((VMU#A@M-_4 tzdata2003d.tar.gz
G\37!6&/HW$G(:D5`%Z@OW60;3?RII`%L+Q@AAYTOZH
}ZD^9E74"-:>53>#W('K*A/"6QU>Y896MK.`\[>8F,$ tzdata2003e.tar.gz
JXL*2@+S$9^X%$]#2,V}H>M4,*IV<E-BH(^WT\MU]U4
,+0+\MPWAEE@&$RUV3!!U4F}Q43:!FJ;/}>1\#"/:3X tzdata2004a.tar.gz
_O[+P853D*ZU@<5E16N@LE/Q2R@VK_5;22(&L7X#X*@
TN(P6(UA2H$6'"3^Q#M5PIJ6)>H"G.F"/B5}>\5)>}X tzdata2004b.tar.gz
`,%G^A7`%F?ODM-B`B6&5N&!A62;@?VA-VKEK7A9E&P
D"!WC,>HNA:-5<2RI@}W54})>S66,0LU+B%DMJ/<^%` tzdata2004d.tar.gz
O*CVSS/3+2_4%\H<&E(7L;*3$LX&E(10_I"!0?$,/)D
^J}AR>P:L/SU,V@X1U\D["X;0\2K0$Y56FZ';)D^";H tzdata2004e.tar.gz
.V"?>"^?!N/7NE2O>\TJTXS;IC7}8_A<_P78'_Z,I+H
)9DQNHLL$4B%]W($M@]`?%-(.>}^;)%"5>T5^/JF,I$ tzdata2004g.tar.gz
2>OXZ]877,Y3.H/9&4Q,?^4*2RU(F1:^2[DH9G43*'8
[\1JJUWRLEM*LFOCFM,B4BX)TOQQ%/(LR!L}6OC)@6D tzdata2005a.tar.gz
@MVM("T}#E8F).X@1!@'>>-MI$),Z.G01^&LD#T3Q+L
}/!;IP@BIFPB1I:P0NP8(SC}._9*FP2?)910^[02U}D tzdata2005b.tar.gz
G&#R^[YL6T/#J^]R&$U/%R?S$NVT!N*O>227++_(700
S88TM@098U.T(&G4ON;;<QBESF;;N`!WTO)'\/,IM8` tzdata2005c.tar.gz
-S$-%D<D[2C%QDJBKU4"*9.}"-30NT5]`JN825XB)#<
L6PFP1\(:HK]9R?-"6BL&*BK>(9!U^#H7*O,0*-CEMH tzdata2005e.tar.gz
:,F92[)JZX4F)_WO1.Y@:!L3GC[Y&T)%*.T,^SP6NT@
T7,'^9G*EILZ5ICBC[>6OA[AY2\6+R%Q`G#*B$2}%+\ tzdata2005f.tar.gz
-9<#**-X5G%H$B7BL8L:?4;KF/.S+X$)8$M5`WIQ2D<
*P]%.W)S@&)^&G8P`IPWI(Z8W+}FULY%C^U;P.K/-}` tzdata2005g.tar.gz
>_4'\9RP[&H8#Z+/<[^^TJ4)3R-(-^83.1L/5}P#>)4
QYUVFD@Z}M-:'FM`\ZN(7119?!LF24+Q[GN<>A0*KN\ tzdata2005h.tar.gz
0L_<}.?5:)RAVLOU[W"1I6""&BF\&V@EY<'4'SJ%3]<
234)%[]K.8^#CAFB3B!NOGWQ7A8H%Z_$D6S_+.W(UE$ tzdata2005i.tar.gz
+#.RI\+OJ2]M.K}\J,7*B;)(#?+9},O-9*,L1Y+<RLX
1PCK>DN9JZ3\Q02"\/LTV>4RQKO4',<}7N+9K!+,75< tzdata2005j.tar.gz
:`(:.6(VL;:*#$V!@H./0`DY#:@.:A?@A1%USAC#!7\
_T]2G}9UXV3W?<'655[,[W)#-?^3>M1X<`.%NSR>`<4 tzdata2005k.tar.gz
$\`;5HH(N4D+[-)0-T"L)U6%_:GS\<VD,M^:2"--*5\
`D:ZV(:1E}&;?YF?`:]`&I"}DU:GR?+"1^G!@TF9,^< tzdata2005l.tar.gz
]XP?Y/R@:#/$-"?7Y_:@TB)E,F,\/>7R";@2+DG<\CP
8`H:XMG>ZT89&XP4BG&'AI:MT]M<'?)<\L5QYUZ(2T0 tzdata2005m.tar.gz
M'-/T;7BH#DSE.GYS$%58N/N*X??`>I`}(^RXY0U@(@
D@.Q"57'&0@C01W)5._E5+0'2V21}]53$^8$75((5I4 tzdata2005n.tar.gz
)1CF2?*H:3>1$E1%5OTBE@<8>JW'^P(NQ8U8S3\V)-<
$+HT2$W6:N)>WLK?<58H@$Y@>F9%"+GX)CT45/$<NA( tzdata2005o.tar.gz
L.?)VFJXZBON09#Q$?.MXL;SA/3M[`U,43C5'A_KB[T
QS#^9DYGX:<>.Z9H"T14OT<;A)[MF!;Z[T>I*Y8$-.$ tzdata2005p.tar.gz
H$))'Y\8_V8'U]A'55[*'#[<WS`'*TI@6[[]W8DA+6P
+MZ}G^}?O}'F.)*@6J"_^Y;+_$\N!'GR?`TVS)6]B.P tzdata2005q.tar.gz
VT[/$2K2&Q])-Z}+.2;Q&VVK.'4[05HU'Q7TC'(1X0@
M%`@#^^E_\""HK0L-RO10AX<*'@@\:NI1XCP@20)CD\ tzdata2005r.tar.gz
^/E".Y()9@FALYIV!J5&E(@7<.IU5J6L*YRR>?!+01(
0T?K+11S483Y`';FL(VD@)NG(/}%0>]@<8??E">1P%$ tzdata2006a.tar.gz
XMH%#7P:N67@G9N4E5"[KI;8__,:H2?)B(B$EBCGDA@
UT!&0XRJW(?\WK\QE/ZQ4L]%P#[GQ.*J<VGW^\\_0\$ tzdata2006b.tar.gz
:S7+"D)F2T@Y`\ZU%DS*\-1I5:H41GU$EO:XZ4I6Q9(
E+'71)J#,.OA^R141TM>%E_0V]PX*I3\A%RW0/$6XD, tzdata2006c.tar.gz
WPZTL%>)HNF<I$\7X9%\Q('7+5@T^3@$6SZP-2M2_S4
Q%6_ZILW*&#>!JC(YQTNY9J,X_U'?IC`47S!FY*K;Z` tzdata2006d.tar.gz
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ tzdata2006e.tar.gz
,^YGL#VHJZ!$$A2J4S8N\U[MR[?^(2,NB10;+LXJT[L
);VKQ_}!DU\0RJ}-)2C`#SP-6B0[K_#JP_/!8H+1'', tzdata2006f.tar.gz
1COG_P,W,-L)>^5XZ-,)R79S;?2C"8I8*I3-R8&JF34
2K?\*317-RALJHHQ.Q4R3XN3B5!&;%`O*')#!XMW.D0 tzdata2006g.tar.gz
Y:G!6]O8YJ*%7OXBB23AS"B'8#-H[4<[NB@`GX)(?JL
OD>0<>,+YM#GO5IALO"#(83.\YM1?NR#E8+WCZ}.9$D tzdata2006j.tar.gz
$F7_E9WUU9\]_6F"RL>N]>!'$NSBF*$52J1H}Y1WAJ(
2#_+@K[?&/4CQ!.T7/#H^G/JP}[)/6H1ZF,-M`@;X,, tzdata2006k.tar.gz
/+C_7^QJ}EOCHL-$O2_^-FNX1/4.L[?V_ARE_*9&`]L
8/$'B*]R199V^*RW!F}&80>S+^WV./%RI"7$-$X/\Q\ tzdata2006l.tar.gz
))BX4%ZAH48%]J@YE"MBU(*FR0_@WKE$PRVQ5D'IYDL
TXR0-(,"B21"*>2?K;%)/\L?0%0NC)CVQ>S_^4`&@0$ tzdata2006m.tar.gz
`'<?23S4..:P#XN`.NP`&;J*MWI9?#@ZL7X"+\2`%$<
N?4]H.GN8GSX}'"$}I:^%_IPB))NBY>'(8&`Z5)%4:H tzdata2006n.tar.gz
K+<3?XER_(}[>]6#526UK6}_WN>&L1Q<Z<NRO5$R37(
R];IVH,&&;[2)^I0-X4B4G>*[8KE&UXQM+TX[1&H^-X tzdata2006o.tar.gz
I%D+W.22&\0QIG".@FHF<.D?<;>+7J>#6XBD#O+;}7D
GLW:T.")MMDP#2(7+FXZ`$NZ+YMF,/(NUZ&Q<7@\J^8 tzdata2006p.tar.gz
VM(A'&GIQ11&/R8U^K\72K.[U+_;6*"ETFC_$"(^DK<
U12QXAJ'R_(+'A87O1/M(!+-X9YS119.KP?:-5H1\-, tzdata2007a.tar.gz
M/R"1ZYKQQV4HPU&$'Q;>NR/%DEJ8U("5[;(X%3XS?H
[K)H0,N0_YU@2O,E/O!;%R!ADZT<4#[.[:-JV18N4'\ tzdata2007b.tar.gz
K!W@Q6:5?201L)>^&3BRIO1:/E]0.-X[E.Y%\:B!<44
YZ*Y\L_AL*P0LP5]L2&O&M&X3DHC]!8W9D#1[QF,L#$ tzdata2007c.tar.gz
J3.L]CD4/E+RQ6J98F)FG((T;TX,CR,/M^!O_Q^^DY8
}-P$>19#@2"GF?VH#):^EH2"IQ'\?*C}R'+8M$Q"P%D tzdata2007d.tar.gz
5H/->R!8(ITT7_3I@W?)OD2}5U/D"Y2?@)HAC.'ZG:H
F*+]3$2.5_%BO\X&AOD6$A_C"+:[0}7\,.L_^&D#\XH tzdata2007e.tar.gz
$K"R<20)>9BS$,9,2CR1Q4]\0(HU"@DD8:R.NXJ8;04
1VT2$+1.@NV,2##L8+O!!&A',T)64U_!\Y3&O"]/NA0 tzdata2007f.tar.gz
($AGR}!34DV1ZX8B$}5E*\A]N`Q9&]8ZZ%QIEB$GT7@
&,VAF'F2GD_]Y0X,Z:<D\V<:Y:IE4_*C4975U;^,>'P tzdata2007g.tar.gz
-U..)K#H805PX_QP'K+]30<'MVFV<)YO^-1M}!903'X
LFWCC/"#2V`*4I9BIU#>:!Z?Q\%[3']KVG24E!UWWS< tzdata2007h.tar.gz
<RQ!88E)KB`EI*FY&Z)MZJ;"$^[TZN38`9<?\;@85WD
K?6SOQV^F#}[GDL"PZ"F_WN4SXO[?`5D"1,Z+X7XUS$ tzdata2007i.tar.gz
.PF]<!Z2^QUU0(T?MOMF^3K@?.P26\QO)F:1Y#6;FG$
QWK.T8^(DUZMN+FW?K}8VB-12(MWA_?Q.QP_4C%@.VP tzdata2007j.tar.gz
?;1\RH&;](C#R5_K]25^N+]}K#%`-'ZCAFY,09_1J/4
D@4I;_%FZ/6-U2`;^:[9]Z:`<RCQW>!F'1C"V]8?43\ tzdata2007k.tar.gz
V,`!(`:RFB#Z_%/}:R>`P$ZJDA,,$MLB/ZP.#%39/.<
,-VZLY`#F1TP?E.`K%<+Q3UVP(5LN4?:I4.;56*.Y0X tzdata2008a.tar.gz
6F9W_15TBSC<EY(N!P)Z:U98U)$+#O.D"?;%OR&I8X8
MQ\L*+&O,J,AV\L`7`]]+EEDRH:F_R}1+ZR7PZZW(OL tzdata2008b.tar.gz
TW5^5CWB.3^;HPT<*R_8B??COH:<@CT-?G*D#<AFXRD
\_6A*GQ3CP"!:S)+MH3(22#1>P}+J106%AP1JD.HI@, tzdata2008c.tar.gz
#0S*GF+-B;66>."J%7*27?2*!(X7VXA$)6VQ]&$X_-T
8Z4KHNK9G+"E5J;/<2D}?FZ2AU^]*.5@;8[-;]R*UW< tzdata2008d.tar.gz
BK"`9R/&?M[X<FSP?.I'NNP#V`1E^+6M-G2,<B[%!U(
]1(:HM17MJ%F.:P1(!]U@W)HT#CY3YJ'2-4W6'T7'K4 tzdata2008e.tar.gz
%PW]-WOQ0N:F`[2J>D%Z!\)[D>#M`G7A4QQ1FH%)\0$
M,'BEY5(&(E(%`H'%@+"JEWS@1V'1[94<8C94/<}RK, tzdata2008f.tar.gz
3_FR*4O9H?F$_Q$'#_LAX0N'OX/WX22#V&):>$/6QOX
W6>A)NY\.,_]L-<AF`NY2US:6V6_U>1]%,RF2&)30@( tzdata2008g.tar.gz
XD*$C0^8.Y:$'4CVJ21IN*)QN"L10U;_R35HZZ9PH6H
>19LX@MU7HT:34<U*!O[8FYOJ5"DJ+E>1).X<_3L,I4 tzdata2008h.tar.gz
3.;-)")%M7LOOMM_%382EGGF$SJ@0$H@LIJ#*:P.VT,
>U<[MXBA_W(``9T>D%2H#1$T27X6GX'+G1H+D@T#A:L tzdata2008i.tar.gz
L[*C4^I$_$\B1N`Q?1Q')JB"G+LJ<-_WU#/4IG[M:Y`
[X`L&)P0[;Q<G*<+X"36%}75:4@3.NXWF4O6XW!O3?$ tzdata2009a.tar.gz
R\F5HE-G7@6IP<3Y(%?U#_`;NC<JCFE:2.,`R-*4IX$
"NF\86`/N!1/$.\0:S@S@?TL_I7TL<-$[E8?.")9IV$ tzdata2009b.tar.gz
3.(#+U3]Y:`/L_[)S-J"O)U3IL4QTQ:E)5DX`P;]?2H
_A$"8W)'#>Q+F87C:C$B82&;F-&3QAS`4\^%?#MWR^P tzdata2009c.tar.gz
/X?YT@VB];Y&+A$[BK^;^}2_<`NX9ORUS/4IWF.NI10
*%Y?"N<@#ML2A#*D'R[^U[*(85[S0J@;PY?@''+]6(( tzdata2009d.tar.gz
\;OV^R[LDT*[G2+0/.W7P)@TZ11!4J'F*+'FA%RSK9T
VU]2V#X"9JZX`86*W;<(_LO}\AG0>-}<)PQ:(T7NO28 tzdata2009e.tar.gz
DV:XP0J_L6X4X.<*O!L+XJTA)Y2EEB;P6Y26;&BP([4
N1J+L8}.6(1F<C>1@Q"MYS8"&,>3/}YW(B4(%.`4GF0 tzdata2009f.tar.gz
_W92&R5J-VW2PY8?SA_02'NR0$!5C:I#0W&T_YFPM5P
M\_3)W][;5BP%)F?<@VSMB1EJ[_*Q9%D;FI&9`,EW?\ tzdata2009g.tar.gz
T$F#G6L1I[_*&,"[K,UB0XXM_>U8]TS%X,VT9`0CI^0
:YP&64E4@(JSDN8MK+GY6I:$Y<01D64W56&HS`[26[0 tzdata2009h.tar.gz
KMTWX9>_(O+$2'A/!;78]<NHF(TJQ6;!0FQ,6?Q38%<
-$]:$AN`'4:DNK}6T"-XY:*&N%0%O:]NY[R`4UXJS,P tzdata2009i.tar.gz
>YE)J*HBK}?$`\\F48Y%@6&ATF5$8-LU&;N8;`\#0SL
CTEVCPH&:8&V>]ZWKY.H6D!_Z&:[3%B3O;I/KHQ^9X4 tzdata2009j.tar.gz
\%IK&EO}6:'*Z*BG\9^L",DG(;36}Z_#QE0-V`-4"9X
PA>,4U`+FMP?GD<L%("?7G53%>]!VGK>KPCBW(W+3[( tzdata2009k.tar.gz
)04'3-X\W5}NB[Z9(1UQ;<^@$%/;>YIC}48&5OR_^#T
A*"@Z,1VG5#%S;H<Q2@2)S:?6R'/P0&%U6*O%}CWU?< tzdata2009l.tar.gz
[''#H!7O'OER;7DP*;IUHW<Y^<37#;3^6?NC<D%}J3$
H[K"*}D"*P,DQ))C,F\^$ZK,(AI8T_0@K0"$92T!_K( tzdata2009m.tar.gz
/WB&"WM\8`@-)C6?@&M+SNZ(8[\/ZB)>OLB8\_&^3%0
08W!\N,3STG[F$OP)WKUE]/EXA*)_M7]^/;/DXQ`!3\ tzdata2009n.tar.gz
$^YYF/`,PM40'2#Z9RAE6N<#Y1%Z&%OJAF13E%_-._\
@OP0B)LT*M3_1#+6$#XDNF.H"I`B8XJ:M;Q(4BR%4#` tzdata2009o.tar.gz
Q6Z%Y,[L3OEK9-#}.DFWXPS92RD69L)F}0\}S$5C/L\
^/G9$!_/^L8V#,#$$4CC@*@F5^6JM0[,E}AV"[^T&NP tzdata2009p.tar.gz
C4D%<ZQ0YFY'*PZOZX:,H4N(%R\S^%Y}6D]]9Z<R>0T
+AO;>S)3G3`>?X:)8M9SA.9S)JDWT-JKPD9>K40MA"$ tzdata2009q.tar.gz
I@!#C04A`'+9J0GNR.}M`FGM]^#5$02YO#9*!V-J.T`
'21_WK$R:&Z7;K'A;<XRPBA#%6/J}Z8/F9:<I6]CMX0 tzdata2009r.tar.gz
/^!.[I,"Z`EE%9)S6.T:?1V4->L;J;+@L'A'S6KH_%T
_FJ5_/HR:@-L;}6*JF8B<}!?MDF5[>[E5O6*S"U5&"0 tzdata2009s.tar.gz
?UW)-YCO0#RTO3G;)-X'NBW'4A`+DV<B}O$DG/+V_*@
!,KZS9<@)HQ*5!ZKA:J(H-5((C)07GH<E.3J)C)UY0\ tzdata2009t.tar.gz
WTDT-TU`,W\+(>J1M<'`V}`)}`:EV,/}N9^[:Q)HE/8
LR()WC//2]^-D[/\CHY%4@+F2?:Y!V7K*3FP0@+C5HL tzdata2009u.tar.gz
@K*:(ZZ;XMZ^F:6.'#HH`C]#,*U<X?._T5\[.%YVI+L
SC!5JB-/B\539RIIE.H'M$WLC%S}}}+[:PF^JY9M1S8 tzdata2010a.tar.gz
^U}H@R(/G9WNOI?KD#D}^N&]IM:$'G>(V*HB_(PQD:<
\%%`2}1RZ$F`*6@WDO&\[1B6^LZ]<R1/M0PSH<(<LR< tzdata2010b.tar.gz
'[`\)#1HWDF[5#41G?,KIF)}1E:9]Q}N#X&0:X!XYE4
X7W;/SDX?QIZ72WN}?LQ45'B2(*R;KMXSZMK"3K3E,L tzdata2010c.tar.gz
')J.M``AE98./-?0BV-}S-(D5P1/#BI"5BM0?\*RXI4
AN2^OF/V?^"L1JT4F!JI`;,?UV6L-7*)UDR:LRS3J#0 tzdata2010d.tar.gz
`FZS)XR%Z4Q4^?I]@Z.<4X[#`<?&]?[G3FPHZ3,[YU0
#-N]RGDEJQ^4GCOM)_&YB$.SS?[]IYPN:ZXIF&9VNU` tzdata2010e.tar.gz
A\0QA`R<4U<66A@S7#>;:2VUSSW,3F_NRZ]UXNF7-7(
0E/<0\^[#5%>G8>:A3<J5'TM5JQ$KR+LV[VQU5X_'"< tzdata2010f.tar.gz
J`8`S(U/P.>6)?#2Z:FG4'\9.%7U0_GUTEM+5!'@UTD
3"B@O<ZUQ?LD5"P5.%@JB)T9"G"K`56}^]^;\_:K6C@ tzdata2010g.tar.gz
]6E:V`GM3`I1MI7.Z3W9C)4X;]AN!S(ZE(\;FQ_-B%T
1GY5+RZFUXA-E\>5ZEME[R<WMF7@?'(;S'J,*L/*7CT tzdata2010h.tar.gz
VQ(D85;`<Y%CW*7LATLQE$.U^4}SQ:I+MT7-68O\R:,
50^28+YLV8Z#5S?K^B601P-"`5XL.!,];@5U0K#[B@\ tzdata2010i.tar.gz
H`K_CX_%MXTZNSF(H^.SM,'%"'\(TWDD9)15'<O5,L,
$}[5_H/01&BS"A+G,DZ-:*PI_#Z0(Y33(U0V+3>*)_( tzdata2010j.tar.gz
#QP7FZPF@O\,!,:-$^>(6JP+B3Y'_VF#<V)1%[[T1B(
!;E/\'JY>P@!E?%W%1TQ*_;ZA+(PCEJ)-/.6G}^Y:J( tzdata2010k.tar.gz
(-P#&S5%1?*UHY}D4S5]D-@>N^!$@,D?)#'O}EB?$Z(
.TE/F(_5UHO(G&OQ4*?@MS;O+-7F":)ADZE]0+8WV(0 tzdata2010l.tar.gz
%EF^`-J3:,DWYM,C9WAG"@A",.8_[-VU',3*:C+J(Q,
ZRTEO&!(-B5[7Y9I]9H7&}VBES0<&'2'?'62@.98MG< tzdata2010m.tar.gz
NOR_E@$3-^K/]KI8I}SR*5S;\^T&Z^7%(YI4%RV@5CP
KOHD'7VY0_,ME%QYX]\%0;??^GHW,`0WD6(L;>7@KC4 tzdata2010n.tar.gz
*FC%\!_?:J;%]#$4?*ROIF/+3,[4Z,TW#O9^/*E2ZS4
XIR$!#A4REBY"^N)JI7X9,K]8;N.V/!!+AE]W";BT_0 tzdata2010o.tar.gz
P0^N}X:_[,G}A1M#(17TTAT}UD*RHDU9J8BTX8-8",D
FH&%S,/KWKZL$2!T-``RZ]J9B*9(2<A?#$(1"NJ?6;, tzdata2011a.tar.gz
<W)_ARJ"&`35T(_S;VPVG<K0^.@}:(/X;99+$Q9Q_L4
S}Z?5-5.S'%X2+5[V4G<:J49D*:P9\YW_)@NX52USFD tzdata2011b.tar.gz
\EE5?&}^"]R55-(Z^N'UMVV^&M3N`>6<NA'O?O??<^T
?1L17[Q.O!9F]SZLE,X*3R^--<.QRT6%}FD1^!`47(( tzdata2011c.tar.gz
LL7.<A1,LX`[>`F%9@\U8T1D/;/1+%O*KDK4#.)7*S(
+:Z}GT&7"N^?JKYG5[]09`BAQ[M\,Q$?N?GVD>*FG<L tzdata2011d.tar.gz
09KW77(UL,X`TIH!-3)*._3PZ.#XZA5599`ZER<YZRT
@OJ^90PI:"-)!IN^\N3OP_W#GFDLERD%QTU/ID0$"OT tzdata2011e.tar.gz
.U_`:AE'1VB3BY2&)9M\6<R9RMO*OM$I9;%^$&XFZ?D
<F+%%-YX@0'\-O./SA4(%'P\Z3BO<%X12_*(;_TX$?0 tzdata2011f.tar.gz
Z[7JB).D[/[;2RH,%'O>EJ8'N724Z:)N>OPK0$}#A$$
OAGQ;O"S3R9&N);*#-0V5&:V<\SJ?!B/IIAK_Y<5KNX tzdata2011g.tar.gz
`!@WF*M3/#C1G^8-/L5D"E*WG+R)O8+J:6?9)\@.*C4
]1>W6J}N$>X,D)2Y>W\}0:$D`83?B0!&WH&"W.'K[\$ tzdata2011h.tar.gz
N._[>U]@<"K#&ZM9N-G.'(2X(NVG7)5D#&8B4I7'$7X
!JO,PD(^3GRA8K6UP][CRK5&*G2U/]/$,SXMUX2X(_` tzdata2011i.tar.gz
SALXB\R7^73<)"1'4,O%-Y_EB-YMI$"[%*0-5N90"0(
3WC"E)BG}M#7?KOTNP:8YZ<\@@;^%-"[STFSL#+C!$0 tzdata2011j.tar.gz
<7T^0V1O"_PX;9A3OH>EM;6J%U.;@;ZXQOETND7RL\`
GX>Z5\H"9VEF(E<IZ)U+RPD24]6^3B'5DV$&FY&Z,F( tzdata2011k.tar.gz
H}+}:-W3@B^4S8%Z/G`G?FZ>-'P2JGB%,]-JT*T#\.P
.}DE,!UDQJLG@E(2W_T.P#PY1`EN]'DQB!6HX?-BR$$ tzdata2011l.tar.gz
33>M+T\MB??:W'"EJ[B\E&_T9H4!<CKJ7XHSK`JBN7T
^0}U.N`J&XU5Z`T#STPB_*K%Y`.IH[A3440Q(31!Z6, tzdata2011m.tar.gz
(('Z1/`*SF4Y[,$I;T5/N6NTKZ81%/^\6/1O@N^+HL\
HBU^2$5J*34"0SW,RFV2';CW#6QN&*!TF6S^MT4TTM\ tzdata2011n.tar.gz
W_&7MZYZ($^BQQ;2>M@\#RG[H[WMX`6}!0>M/T$7A)P
D.5XWUNZ8L.7X7";SAPF."IAL.J<CZSF<><BC;];>ZL tzdata2012a.tar.gz
"//P?@J_}})X(0_)(W-$MF$[:P5;[?ETMU0WOZ%3O:\
(X$U2'K-XX\U+E6`6UO)L]N3V<"/VSS[IHLV"<!D1?D tzdata2012b.tar.gz
Q#8P\+\9<[-H(IQXC:D)9}?(L-;<BJ#TO+^L`8J,@I$
X>LARN!2@M\NNF[)ID?%/`+]DOZI']7+DX58"#A^4KD tzdata2012c.tar.gz
`O2N7#IH76B+[<#!<_3NU1?/^`&.'\E.[J__-5R0M`T
L_FE*)&V:6#.*-XR.NTJ2QENDS\@K[^_/<]X>K#A8?8 tzdata2012d.tar.gz
9JM[SW!PH*;9NBQ>^}7`\)DD8OI#H)F8HVR:9`2;$!8
3[:_<]9JM}+[N0X'JEY.8V(A)FIIMUD.S/S6L:S_O9@ tzdata2012e.tar.gz
N-M3^"EG1RPZH9&@3PJ71SU#,<<M`X-'2:#(J}FI-/L
$H61?C];;\>A9J.3<9$V4%`?ZXCK_$"\:F3C.3T.K5T tzdata2012f.tar.gz
'Q.A`DU.C+WP8X>M%1X7G+[+"Y7WWW[;P`_47BMV)WH
I-R0?U"@H;}3@M\&7(I,`"C]LGC2^.O%3O\)XBC->I0 tzdata2012g.tar.gz
DO'>5<6/;CPQHT/J.9079.PW?6+(?_T_M\*IO\*>:34
>Z_)RV-;?(-J_?0H/!$1_Q5#I)RD1$Y?.ZEKH?QPC}< tzdata2012h.tar.gz
X@^Y"3PCXJ0.L1$+.BGZ);R'"U3.KEO"4]G]&P_H1&L
WGTHO##WZF^:/\7HZMR>^[MX4<+W#B)J\HTY-)(/?[< tzdata2012i.tar.gz
F%%;DB:*+N23AO:54A'!2Y_D}&"Z'#[%U@:!L:DT:(P
/>1%+X]U?*.FDDX5>$6%EGQVCGR&OG,#>-`S+"25A/X tzdata2012j.tar.gz
Q;!R1B&/7#QU&WW<7$[A)T,OP9&'`9,AON_UB5EJZ1P
361`"F.VXS7/:C!D.HV<BYO3?3'%4T)'&&)M}9&JN94 tzdata2013a.tar.gz
$C},NF^7[>3`!:ZH$8^N0R6,5,NV_)M:DU<T+&XTWIL
74AV&A}HX1)>)_4WOPL3KG#]7)$'W+RPKY)I7Y4][JT tzdata2013b.tar.gz
GZ_':K,7}G(SF@Z4\`@_`?B571;TF/S3T5Q^+T-O?YT
FXTC3C6YK/V>I8Y;^NS,HFI8#P28X'1T55R6.S'/;>D tzdata2013c.tar.gz
W$(@R,(1/8F;B0%6&A,UZTWC&(%B+]>/)'#&)6B>_@@
U05UKKDGUHC]721SGQUD(BU`(A"1_R7YK6&F7PR@.}` tzdata2013d.tar.gz
S;HAB^/6;&6B}T}($JN$J#,'5O84N!9:RS)@$W'H\2@
):IFLK%R;TH;HDL&&+I-8MJ:#'E1249OO563L]*F3(T tzdata2013e.tar.gz
2)QCAK.2:\U<)7[[_?Y/QBOO][T##BQH;'WDA7V+BZ$
/0E2(UBNW&PR2@W%U$G@V_2.PHFEZ1L<MP\VB&8$PCD tzdata2013f.tar.gz
A!!]INN+O)!CL&Y"+K;O2EE2`YN0M,AO;,;,[+-PT4@
+}WXOD<M28N8R[.L;WH.TW3XN#83F)I]>CHBBXD0K'$ tzdata2013g.tar.gz
3UA.2G%R88+IS"\3NNHO`K%?3%8#65]DDS&*.2"0,'0
K0L'.TQOB(NJ,_9(0BH"8`IOV-,T42#T7:#UU44_N-@ tzdata2013h.tar.gz
9Y9%@WN4#`U,8\L'#B;`0D8:4@RJ7[X>T2B7IK^UQ$`
-2U4J>'_N+<)BA#}GB\SSTQOG+"V_(3`W\.)A0'.0(( tzdata2013i.tar.gz
D4DZ7JA;XMMC-,<}}"Y)#A"8EMXHL(]J}OILTPP#[;@
M%PNU,JR5$9/'E6:KR*Q4S]K-8)QCU84(107B$;-6I8 tzdata2014a.tar.gz
CTB$PE}JN1W@8NUB}X&+(@[D/ZR^5R'U'3.IG]Y;/BD
F3;I35>68MV!,'89GOHTC8\F__'`:Y(%6P[[J8P.TB8 tzdata2014b.tar.gz
IO2M/Y48J.0*HQF2:NE!3,RDQ`C81N/0`"2#E9RU#}8
XS8Z>HPY\^<&WVSD1D^*9NYK36\X?L`+!JLU1QP$V[< tzdata2014c.tar.gz
47E*HK`/$27UHF?[C?[]!}^26B.+\Q}#`"S'-GH]*[(
P<X$Y;T);#7J8IL?Z>K}TM,Q0JG7YT*CT;*A>W1%/G, tzdata2014d.tar.gz
H`<;@0%/2H(RDU0A,.VW<QG*(AC@H/OT$)O()8"6\GD
?%#D^CGON/!*BOC<5"?VRB"XHNE.4E(]P2A49@KP:+` tzdata2014e.tar.gz
J',G03SUWN4;1SEJ2)2WTO#EX!2CW_3W&ZJJ\.QG'NL
_KIF2Q"-(<^Y}U3ZQC`;@G1-E5$CS?D"%GA[W)L11CH tzdata2014f.tar.gz
\!GWNBM5C2ZDA7IJGX:A:Z[W)>/PN#U3[`W#,"TM'HX
IVE7UO$*5&/4O0.OW.LH2!'4X96#L,+_@3PC;P}?)8X tzdata2014g.tar.gz
MT&!*_IV9H5`<_FN[Z1V3@EQI<DUU,_*]P(4;Z$_L`D
_^:"BX,'F6:3]U4>->X_Q#-,-A'K?^R;4I"K[<@W@]` tzdata2014h.tar.gz
V(DW`\Z_HS<E2FS[)K#`"#4SDB`6U1W+5L#+Q&_W^W8
V#Y.$UGNPZ}RBTZ__23I$A%ZP?}"6A4,K4TSX@`SQ`X tzdata2014i.tar.gz
3"EYOCJ6^1^%}C!.R075<;<]\(0L@P#!US%X&;1:L^(
F4CMD1JB9;$J2M6'U<ND3V1MT"Y`Y/OYYH56HM,G%"X tzdata2014j.tar.gz
_S;^M#<CBZ0OYG)7Z!K>"B%YT1]L9$D4;BCDME4\8C0
BT$QKW7D0+1&<0G)[;H3XEW:]P'R_.NRHEBTK)M7*3P tzdata2015a.tar.gz
}G>"N'YBJ/>DV\KEE}%J5!E\G@3*ETUP%M$?D.NO)3<
N`31$?($KY!2QHU&<*_@KPKYY;%0AGHU?\&9NU03:-` tzdata2015b.tar.gz
RHG"!!R$(.>Q5&8.(G(1M@NB#HUPMH<+7`H4F#C%B-$
,&4@*Q)FQ9RO(JF}\CA]J5K`0$FY[+>3G-0&Q_`'ISX tzdata2015c.tar.gz
-[6J/%X-8!R+(/K`C7)GPYBH-N09#OA6)}7H:H!KH;H
SK(Q6Z@:FFR%3JY/SD#IR/D,]:VMX_2*U$/W?"(}B8, tzdata2015d.tar.gz
ADF!D*(,7&>">J}??IQJIL&}6*B*<$)<YPU:Y\ZD+<<
.&ZRAG^D5?S\WMQJ$%K7#[O<?"?'I8I1O2'7:A-9@\X tzdata2015e.tar.gz
V&YLGDQMG-7>,'8G(]>I"L:7_NMMT?!&2?:C7DX}QC@
)APR!FVTKJ^G9ZPSG,T0##C}X$3.K}8>E<L].<)_EWX tzdata2015f.tar.gz
K7W@X^AU.&'28/#\O+RC)U%J3<@F]V63<*?[EYYA5/$
HFLCTF":SVX7D,C%G:"W;$+TJ4OS84"<%&#VJ/^F^'D tzdata2015g.tar.gz
FJ7V&G.OI0<-^QT9@I1})HZH(59CT,U90A90"O\4>7X
I5D<S]2(W"*`D"^A@@OW@F(V))$K9IAS<H0Q)8_A#L$ tzdata2016a.tar.gz
;3`A6Z,HFEN%IC+6-;}J5,/`C9?D)M:]B?@\3OTE+D,
E963LAS*G2L87SA%-8D(E&S#"#9:S+[I3Q)JTP5\^#@ tzdata2016b.tar.gz
`^JW?(LQ}MH}T7T}D&*Q40-K`}(D\>2V#S2BVVB9%00
,?-/39\Y929(JN.E4R;];X76WN_C\GLVZNV>\Y[3]3P tzdata2016c.tar.gz
\;ZQ>3Q,?1CRVMKTJ2BQ1V]FM`"]H,A[!A5<#}'$M*(
:[+S?<%Z-G:BN^G!YQI}BR>A<<>7J&1DL+P-$ZO[+YD tzdata2016d.tar.gz
VLX/;\AZ<X><HZ&Q0]?<^<4(`^(^:XR1^#<1<$XH$IH
]W9G;%1\0O%-[G\>CBA<XE*6Y3I2T1],CQ5;7X#TOK, tzdata2016e.tar.gz
!'+Y46ML/8/`I}"5.E4U],2-FY%QX27U*!B-K%$O-58
O!@%MP*<3T9Z$BR\X;ZTZ`3}2N8[)9E2WCNR%_CHE!T tzdata2016f.tar.gz
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ tzdata93.tar.Z
B_U+6HPPV]^'/H7%1Y#W+[(}KPGP'Q<WB^!,[@10>@4
61A5*V'*IGK<6CP}T2["&>62E?G'%IUXHG;C39(_:$\ tzdata93b.tar.Z
$^<@A"D*D:!U".7!7?Z1K.<D6#$/0F3_^C-5+}[7];@
K2E>KRL!V.9]N3WP$M>`*0:V'X<[)\(:L?4]L]6"4YD tzdata93c.tar.Z
F!]4&XCG:R-_O+ZK$MR?28(NFZ0Q.J6[1*A8>,}D\#\
G}?XMB,""B8"7.$MC3Q_D1X8&OXI]DNMTI@(`C5$':$ tzdata93d.tar.Z
L4AXY>[::W7`<P?EMA`V@/<9^XG#;&5"}4%Z6R4U2^$
*3`>N%_X8'>@?6}L13GJ/NB50G"0FS}</:'?5DRAL$L tzdata93e.tar.Z
T.LMG-V:2Y"G??QG72'P5>%G@-XUJ?.]F8>}!IG[V)<
-V/('@H\4`DWY;UM"&}$J,SDDHS@DD_-Y\!!,$WP";< tzdata93f.tar.Z
V/,C#A;3+F%HL-$&KF0W$K^`B+LK6/"XWQ8YJR]!>AD
_[WT"BS['40P#PD>P3ZM"'$\+WF-?6[*U'\N;9B1H2$ tzdata93g.tar.gz
TWT\F"YH+HL1\6L%(.\)2XAPG#J0W5EPD1W>TTQ@&64
Q#I"WP\@Z48F5`:#C9ZB<PQR%99536T6?SIY&MYM>TT tzdata94a.tar.gz
V3X"B/MQ>V+Z^P]\LRGIZ0@AZSG&8HBIR@$K6"RT7F8
H?:Y(+Z!6_-MZ!_MY@%0O6W,A-R>$/PYP}\*'2WQ>U0 tzdata94b.tar.gz
4Q5*'`0U7[8T'PB!ZK0TLQF<B1*FF>"A8D>(2@U+0\\
HJI9PL[@OZ(PACO-DE%D9+P>IP27ZT[ADI^A*&.`[;$ tzdata94d.tar.gz
!&26XQE}R73F;Z+N^EZ6[<W,`?>WF'Z99']C}/[<E?4
%JRW?E*V"8ZL?">,+<9-46(2(O]QPH}2\7O1_B0CZH8 tzdata94e.tar.gz
N@[B'6*E*#`_S?V\9H'@KCL/-"X2@-_T4BB_$ZF92LD
&E_U6&'R'G;/96WT<%@}>B>}9P)E-$WF2Q$U*^NV^W0 tzdata94f.tar.gz
\S"*"*"]S*(4J*?0`!?JK*J3VB$K>:H'*3I+B2,/,/<
\HFZD[/9S\^0"^>;YX:}VM'@6V'<+G'?3T7B@8"GI>, tzdata94h.tar.gz
Q%}QNT@"/22*!A*Q_N8:89!B2}R<!XXA,T!ZUE6'"E0
:P0'8'B\L@YW5TA?5N&;&5/`2G)D\YU:#4&VFSNG0I$ tzdata95b.tar.gz
58M_*[QVF[$TIHIH]T&/II@8'3,X;8**ZGC;C}V5ZB\
?D))*MLAA1MG/.YBV8\:4GE'D/\[NY9]L<9}<9'NE3H tzdata95c.tar.gz
KQ<*10('\BR:?)GP?@4JIXCD:I8('8Y2^&84UZ&7FY,
>N_$OG\/G)DD.[J#[^0[C*%&LV5,(`R^-[?M;@JCS\( tzdata95d.tar.gz
/6U6ZXX(+>?\U03Z9}:-7"!L^>MEIK7)'9C5HH(WSW`
UK10ZN/RN8-;Y,;"E1"1#PGX&0HM]PDH<UY8&$"5F2D tzdata95e.tar.gz
H"&BY$<4KZ7!71S&04)J#\'6]&82]AQKAB68P6\*0*P
<[D\C}_8PJ&_MSU"^[@H?-52}C5V]TDBRLH7X>J/U#, tzdata95f.tar.gz
G/2,5}W49@O:M}9(A#N3FT6-<**<")+G.<9@Y!;V!B\
-ENM9%.#MB3?+1&68?/K//E7ZH^CUN<4B45(LNG5;?\ tzdata95g.tar.gz
L9}F1W`&)"$P@T&SBE2T*DFK.;&8>,M/"-BS:YD:#`0
E@B_'/TXJ);[-4/'>CZG&EM;@$M_E2>'CHQC:?/QMWX tzdata95h.tar.gz
/U5IZ<;%-%/U0<3P^3(5M2BVT7\<XY2I#]`UAZP`#4D
S(-M<OB5M\WGC]@D.$T9W]P[3Z[604)![0;AA4`7F;( tzdata95i.tar.gz
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ tzdata95j.tar.gz
R$]+?^89IS3!}FN8+,S!&,H8(S>I#C45MES$S#KX^%\
:Y/7DH,A]95[+ZA9O#]&Y&BMV]"37)%(N/Y9G%0EV}L tzdata95k.tar.gz
G8T8F^UF`0M!R6LW3KR;}+^&G^KKZI4P,.]#D$5]6X@
2%^`'Y'VSV0/<<&?3W9074X%$*9:<^(#2*]S8UI>&7X tzdata95l.tar.gz
'F$H':/>%]H>`OD"!3N.:6\\,V}IO.@&`3:I!2N:H`D
'7_<Z76S/.#K_\!5\N6`<37A@%H#R.J:V@801Z21>L@ tzdata95m.tar.gz
&.W1T1O<\(IUQ$;3%]#N5OR4%2CBS((Q+%2W9WBA)RT
H2",;_G2S,IK6S/:9Z@5SQOC>35#};%\H0\(QZX3E7X tzdata96a.tar.gz
;[5--'"@UVZ<6_7R2'69K9]LI^_NKK$Z7'?[?D)J"0\
IYG-A$2V]JTJ4^.199<0M86/'#2_%F.1!&%}4A"?2Z$ tzdata96b.tar.gz
OH08*[]G6C7"1+()`Y$>W6}4}_>*A^}:;F]>^R!9^I(
$A'.>.)S}"N^:S}Z:/00BM8'90_MHJ*D^QIAYVV_;3\ tzdata96c.tar.gz
QB,?UNF6I/Y3#3+;P6.>6-@H_"Y*]/#4`;>CW_I<:SH
%M}$M):,^\^?Z[4,;_JH>SN+#H_<5,}^*!"H+XEEA`D tzdata96d.tar.gz
#O,UW,"*#<15#()N,GQC_/Y9O/L`<RNQR8MSW:1!\T`
:2-JT#KZI0FJP-.LLXC#CW\!%L-U*C?>J*:@8K,)V>@ tzdata96e.tar.gz
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ tzdata96f.tar.gz
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ tzdata96g.tar.gz
._'Q1`S6W[R?9_ZX1*JPC\TW,O5CW^DE"%YZ`6,:]/T
"+M_K7?DY5;W//<.`D}"/V;Z7_.??E\559ME4;1+(WH tzdata96h.tar.gz
^5CS5<:'C?A'@"FA&EC'UJUN.,MD?Z5WP;A@ZA(/RG4
FW'}]S6G:+FDJ"QZJ<}/0FC[RY^?ZQGKXY8OWE&P3%T tzdata96i.tar.gz
FD'\3M:VB7HFI+JI;(LKG^FYW6@W)IW'1+S-I-E)944
'99V)&RW@>Z!4WB6N[`2!I64*`#DIN.?VO9P!2JAG>$ tzdata96k.tar.gz
?&*!2]H`X6N>54;SG#YC#IF&4**`'5NIX4EV*%E>(2`
6:CTF"UF/}I<`(QMUXUB<E;J77C,^-I0DMV@<\B45_4 tzdatabeta.tar.gz
HASHES

sub _verify_sha512($$$) {
	my($self, $localname, $canonname) = @_;
	unless(ref $archive_hash) {
		pos($archive_hash) = 0;
		my %ah;
		until($archive_hash =~ /\G\z/gc) {
			if($archive_hash =~ /\G([!-`\}]{43})\n([!-`\}]{43})
						\ ([!-~]+)\n/xgc) {
				my($h0, $h1, $name) = ($1, $2, $3);
				tr/}/=/ foreach $h0, $h1;
				$ah{$name} = unpack("u", "\@$h0`\n").
						unpack("u", "\@$h1`\n");
			} elsif($archive_hash =~ /\G\~{43}\n\~{43}
							\ ([!-~]+)\n/xgc) {
				$ah{$1} = "";
			} else { die }
		}
		$archive_hash = \%ah;
	}
	my $rh = $archive_hash->{$canonname};
	defined $rh or die "attempt to check SHA-512 of unknown file\n";
	if($rh ne "") {
		my $ch = filter("", "sha512sum",
				$self->{top_dir}."/".$localname);
		$ch =~ /\A([0-9a-f]{128})\ +[!-~]+\n\z/
			or die "bizarre output from sha512sum\n";
		pack("H*", $1) eq $rh or die "SHA-512 hash mismatch\n";
	}
}

sub _init_ftp($$) {
	my($self, $hostname) = @_;
	$self->{ftp_hostname} = $hostname;
	$self->{ftp} = Net::FTP->new($hostname)
		or die "FTP error on $hostname: $@\n";
}

sub _ftp_op($$@) {
	my($self, $method, @args) = @_;
	$self->{ftp}->$method(@args)
		or die "FTP error on @{[$self->{ftp_hostname}]}: ".
			$self->{ftp}->message;
}

sub _ftp_login($$$) {
	my($self, $hostname, $dirarray) = @_;
	_init_ftp($self, $hostname);
	_ftp_op($self, "login", "anonymous","-anonymous\@");
	_ftp_op($self, "binary");
	_ftp_op($self, "cwd", $_) foreach @$dirarray;
}

sub _ensure_ftp($) {
	my($self) = @_;
	unless($self->{ftp}) {
		# Always use IANA master.  Could possibly look at mirrors,
		# but the IANA site is probably reliable enough.
		_ftp_login($self, "ftp.iana.org", ["tz", "releases"]);
	}
}

sub _cmp_version($$) {
	my($a, $b) = @_;
	$a = "19".$a if $a =~ /\A[0-9]{2}(?:[a-z][23]?)?\z/;
	$b = "19".$b if $b =~ /\A[0-9]{2}(?:[a-z][23]?)?\z/;
	return $a cmp $b;
}

sub _ge_version($$) { _cmp_version($_[0], $_[1]) >= 0 }

my $split_rels = q(
	93 AA -b cc dd ee ff gg
	94 -a bb c- dd e- f- g- -e -f hh
	95 bb c- -c -d -e -f -g d- -h -i e- fj gk hl im
	96 aa b- c- -b dc e- -d -e -f fg -h g- h- -i i- j- kk l-
	1996 ml -m n- on
	1997 aa bb -c cd de ef fg gh -i hj ik
	1998 aa bb cc dd ee f- -f -g gh hi
	1999 aa bb cc dd ee ff gg -h hi ij
	2000 aa bb cc -d d- ee ff gg hh
	2001 aa bb cc dd
	2002 aa bb cc dd
	2003 aa bb cc dd ee
	2004 aa bb c- -d d- ee f- gg h- i-
	2005 aa bb cc d- ee ff gg hh -i jj kk ll mm nn oo pp qq rr
	2006 aa bb cc dd ee ff gg h- i- jj kk -l mm nn oo pp
	2007 aa bb cc dd ee ff gg hh -i jj kk
	2008 aa -b -c -d ee -f gg hh -i
	2009 aa bb -c dd ee -f -g hh ii -j kk -l -m -n -o -p qq rr -s tt -u
	2010 -a -b a- cc -d -e ff -g -h -i jj kk ll mm nn -o
	2011 aa bb cc dd ee -f gg -h ii -j -k -l -m -n
	2012 aa bb -c cd ee ff gg hh ii jj
	2013 aa bb cc dd ee ff gg hh ii
	2014 aa bb cc dd ee ff gg hh ii jj
	2015 aa bb cc dd ee ff gg
	2016 aa bb cc dd ee ff
);
sub _split_rel_versions($) {
	my($version) = @_;
	unless(ref $split_rels) {
		my(%sr, $year, $cver, $dver, $lastver, $lastnum);
		$lastver = "";
		foreach(split(" ", $split_rels)) {
			if(/\A[0-9]/) {
				$year = $_;
			} else {
				my($cl, $dl) = (/\A(.)(.)\z/s);
				$cver = $year.($cl eq "A" ? "" : $cl)
					unless $cl eq "-";
				$dver = $year.($dl eq "A" ? "" : $dl)
					unless $dl eq "-";
				my $ver = _ge_version($cver, $dver) ?
						$cver : $dver;
				if($ver eq $lastver) {
					$lastnum++;
					$ver .= $lastnum;
				} else {
					$lastver = $ver;
					$lastnum = 1;
				}
				$sr{$ver} = [ $cver, $dver ];
			}
		}
		$split_rels = \%sr;
	}
	my $cdv = $split_rels->{$version};
	defined $cdv or die "no such Olson DB version `$version'\n";
	return $cdv;
}

sub _latest_version($) {
	my($self) = @_;
	my $latest;
	_ensure_ftp($self);
	foreach(@{
		_ftp_op($self, "ls", "tzdb-[0-9][0-9][0-9][0-9][a-z].tar.lz")
	}) {
		if(m#(?:\A|/)tzdb-([0-9]{4}[a-z])\.tar\.lz\z#) {
			next unless _ge_version($1, "2016g");
			$latest = $1
				if !defined($latest) ||
					_ge_version($1, $latest);
		}
	}
	unless(defined $latest) {
		die "no current timezone database found on ".
			"@{[$self->{ftp_hostname}]}\n";
	}
	return $latest;
}

=head1 CLASS METHODS

=over

=item Time::OlsonTZ::Download->latest_version

Returns the version number of the latest available version of the Olson
timezone database.  This requires consulting the repository, but is much
cheaper than actually downloading the database.

=cut

sub latest_version {
	my($class) = @_;
	croak "@{[__PACKAGE__]}->latest_version not called as a class method"
		unless is_string($class);
	return _latest_version({});
}

=back

=cut

sub DESTROY {
	my($self) = @_;
	local($., $@, $!, $^E, $?);
	rmtree($self->{top_dir}, 0, 0) if exists $self->{top_dir};
}

=head1 CONSTRUCTORS

=over

=item Time::OlsonTZ::Download->new([VERSION])

Downloads a copy of the source of the Olson database, and returns an
object representing that copy.

I<VERSION>, if supplied, is a version number specifying which version of
the database is to be downloaded.  If not supplied, the latest available
version will be downloaded.  Version numbers for the Olson database
currently consist of a year number and a lowercase letter, such as
"C<2010k>".  The letter advances with each release in a year.

Historical vesrions make the version numbers a bit more complicated.
Prior to late 1996 the century portion of the year number was omitted,
giving version numbers such as "C<96g>".  Prior to 1994 the first release
of each year omitted the letter "C<a>", giving version numbers such as
"C<93>" (with the second release of the year being "C<93b>").

From 1993 to to late 2012 the database was split into `code' and `data'
parts that could each be released without releasing a new version of the
other part.  Each part had its own version number, sometimes advancing
independently of each other, and sometimes skipping sequence letters
in order to catch up with the other part.  Where the two parts of some
version of the database have different version numbers, the version
number of the database as a whole is whichever part's version number
is higher.  If this would give two database versions the same number,
due to multiple releases of one part happening while the other part has
a higher version number, a digit "C<2>" or "C<3>" is appended after the
letter to distinguish the second and third such versions.

This module does not currently support downloading database versions
earlier than version 93.  One can expect to successfully download most
versions from then on, but a handful are missing from the public archive.
The public archive is complete from version 2006f onwards.  Details of
historical version availability may change in future.

=cut

sub _download_file($$$$$) {
	my($self, $remote_name, $local_name, $with_sig, $enoent) = @_;
	my $tdir = $self->{top_dir};
	_ensure_ftp($self);
	@{$self->_ftp_op("ls", $remote_name)} or $enoent->();
	$self->_ftp_op("get", $remote_name, "$tdir/$local_name");
	if($with_sig) {
		$self->_ftp_op("get", "$remote_name.asc",
			"$tdir/$local_name.asc");
	}
}

sub new {
	my($class, $version) = @_;
	die "malformed Olson version number `$version'\n"
		unless is_undef($version) ||
			(is_string($version) &&
				$version =~ /\A[0-9]{2}(?:[0-9]{2})?
						(?:[a-z][23]?)?\z/x);
	my $self = bless({}, $class);
	$version ||= $self->_latest_version;
	$self->{version} = $version;
	my $tdir = tempdir();
	$self->{top_dir} = $tdir;
	$self->{olson_dir} = "$tdir/c";
	filter("", "mkdir", $self->{olson_dir});
	if(_ge_version($version, "2016g")) {
		$self->{code_version} = $version;
		$self->{data_version} = $version;
		_download_file($self, "tzdb-$version.tar.lz", "tzdb.tar.lz", 1,
			sub () { die "no such Olson DB version `$version'\n" });
		_verify_signature($self, "tzdb.tar.lz");
		filter("", "tar", "-xO", "--lzip",
			"-f", $self->{top_dir}."/tzdb.tar.lz",
			"tzdb-$version/version") eq "$version\n"
			or die "tzdb.tar.lz is not the expected version\n";
	} elsif(_ge_version($version, "93")) {
		my($cver, $dver) = @{_split_rel_versions($version)};
		foreach(["code", $cver], ["data", $dver]) {
			my($part, $pver) = @$_;
			$self->{"${part}_version"} = $pver;
			my $zext = _ge_version($pver, "93g") ? "gz" : "Z";
			my $rname = "tz$part$pver.tar.$zext";
			$rname =~ s/\Atz(?=code2006b.tar.gz\z)/tz64/;
			_download_file($self, $rname, "tz$part.tar.gz", 0,
				sub () {
					die "file $rname is not available on ".
						"@{[$self->{ftp_hostname}]}\n";
				});
			_verify_sha512($self, "tz$part.tar.gz", $rname);
		}
	} else {
		die "Olson DB version $version is too early for this module\n";
	}
	delete $self->{ftp};
	delete $self->{ftp_hostname};
	$self->{downloaded} = 1;
	return $self;
}

=item Time::OlsonTZ::Download->new_from_local_source(ATTR => VALUE, ...)

Acquires Olson database source locally, without downloading, and returns
an object representing a copy of it ready to use like a download.
This can be used to work with locally-modified versions of the database.
The following attributes may be given:

=over

=item B<source_dir>

Local directory containing Olson source files.  Must be supplied.
The entire directory will be copied into a temporary location to be
worked on.

=item B<version>

Olson version number to attribute to the source files.  Must be supplied.

=item B<code_version>

=item B<data_version>

Olson version number to attribute to the code and data parts of the
source files.  Both default to the main version number.

=back

=cut

sub new_from_local_source {
	my $class = shift;
	my $self = bless({}, $class);
	my $srcdir;
	while(@_) {
		my $attr = shift;
		my $value = shift;
		if($attr eq "source_dir") {
			croak "source directory specified redundantly"
				if defined $srcdir;
			croak "source directory must be a string"
				unless is_string($value);
			$srcdir = $value;
		} elsif($attr eq "version") {
			croak "version specified redundantly"
				if exists $self->{version};
			die "malformed Olson version number `$value'\n"
				unless is_string($value) &&
					$value =~ /\A[0-9]{2}(?:[0-9]{2})?
							(?:[a-z][23]?)?\z/x;
			$self->{version} = $value;
		} elsif($attr =~ /\A(?:code|data)_version\z/) {
			croak "$attr specified redundantly"
				if exists $self->{$attr};
			die "malformed Olson part version number `$value'\n"
				unless is_string($value) &&
					$value =~ /\A[0-9]{2}(?:[0-9]{2})?
							[a-z]?\z/x;
			$self->{$attr} = $value;
		} else {
			croak "unrecognised attribute `$attr'";
		}
	}
	croak "source directory not specified" unless defined $srcdir;
	croak "version number not specified" unless exists $self->{version};
	foreach(qw(code_version data_version)) {
		$self->{$_} = $self->{version} unless exists $self->{$_};
	}
	my $tdir = tempdir();
	$self->{top_dir} = $tdir;
	$self->{olson_dir} = "$tdir/c";
	$srcdir = "./$srcdir" unless $srcdir =~ m#\A\.?/#;
	filter("", "cp", "-pr", $srcdir, $self->{olson_dir});
	$self->{downloaded} = 1;
	$self->{unpacked} = 1;
	return $self;
}

=back

=head1 METHODS

=head2 Basic information

=over

=item $download->version

Returns the version number of the database of which a copy is represented
by this object.

The database consists of code and data parts which are updated
semi-independently.  The latest version of the database as a whole
consists of the latest version of the code and the latest version of
the data.  If both parts are updated at once then they will both get the
same version number, and that will be the version number of the database
as a whole.  However, in general they may be updated at different times,
and a single version of the database may be made up of code and data
parts that have different version numbers.  The version number of the
database as a whole will then be the version number of the most recently
updated part.

=cut

sub version {
	my($self) = @_;
	die "Olson database version not determined\n"
		unless exists $self->{version};
	return $self->{version};
}

=item $download->code_version

Returns the version number of the code part of the database of which a
copy is represented by this object.

=cut

sub code_version {
	my($self) = @_;
	die "Olson database code version not determined\n"
		unless exists $self->{code_version};
	return $self->{code_version};
}

=item $download->data_version

Returns the version number of the data part of the database of which a
copy is represented by this object.

=cut

sub data_version {
	my($self) = @_;
	die "Olson database data version not determined\n"
		unless exists $self->{data_version};
	return $self->{data_version};
}

=item $download->dir

Returns the pathname of the directory in which the files of this download
are located.  With this method, there is no guarantee of particular
files being available in the directory; see other directory-related
methods below that establish particular directory contents.

The directory does not move during the lifetime of the download object:
this method will always return the same pathname.  The directory and
all of its contents, including subdirectories, will be automatically
deleted when this object is destroyed.  This will be when the main
program terminates, if it is not otherwise destroyed.  Any files that
it is desired to keep must be copied to a permanent location.

=cut

sub dir {
	my($self) = @_;
	die "download directory not created\n"
		unless exists $self->{olson_dir};
	return $self->{olson_dir};
}

sub _ensure_downloaded {
	my($self) = @_;
	die "can't use download because downloading failed\n"
		unless $self->{downloaded};
}

sub _ensure_unpacked {
	my($self) = @_;
	unless($self->{unpacked}) {
		$self->_ensure_downloaded;
		if(_ge_version($self->{version}, "2016g")) {
			filter("", "tar", "-C", $self->dir,
				"-x", "--strip-components=1", "--lzip",
				"-f", $self->{top_dir}."/tzdb.tar.lz");
		} else {
			foreach my $part (qw(tzcode tzdata)) {
				filter("", "tar", "-C", $self->dir,
					"-x", "--gzip",
					"-f", $self->{top_dir}."/$part.tar.gz");
			}
		}
		$self->{unpacked} = 1;
	}
}

=item $download->unpacked_dir

Returns the pathname of the directory in which the downloaded source
files have been unpacked.  This is the local temporary directory used
by this download.  This method will unpack the files there if they have
not already been unpacked.

=cut

sub unpacked_dir {
	my($self) = @_;
	$self->_ensure_unpacked;
	return $self->dir;
}

=back

=head2 Zone metadata

=over

=cut

sub _ensure_canonnames_and_rawlinks {
	my($self) = @_;
	unless(exists $self->{canonical_names}) {
		my %seen;
		my %canonnames;
		my %rawlinks;
		foreach(@{$self->zic_input_files}) {
			my $fh = IO::File->new($_, "r")
				or die "data file $_ unreadable: $!\n";
			local $/ = "\n";
			while(defined(my $line = $fh->getline)) {
				if($line =~ /\A[Zz](?:[Oo](?:[Nn][Ee]?)?)?
						[ \t]+([!-~]+)[ \t\n]/x) {
					my $name = $1;
					die "zone $name multiply defined\n"
						if exists $seen{$name};
					$seen{$name} = undef;
					$canonnames{$name} = undef;
				} elsif($line =~ /\A[Ll](?:[Ii](?:[Nn][Kk]?)?)?
						[\ \t]+([!-~]+)[\ \t]+
						([!-~]+)[\ \t\n]/x) {
					my($target, $name) = ($1, $2);
					die "zone $name multiply defined\n"
						if exists $seen{$name};
					$seen{$name} = undef;
					$rawlinks{$name} = $target;
				}
			}
		}
		$self->{raw_links} = \%rawlinks;
		$self->{canonical_names} = \%canonnames;
	}
}

=item $download->canonical_names

Returns the set of timezone names that this version of the database
defines as canonical.  These are the timezone names that are directly
associated with a set of observance data.  The return value is a reference
to a hash, in which the keys are the canonical timezone names and the
values are all C<undef>.

=cut

sub canonical_names {
	my($self) = @_;
	$self->_ensure_canonnames_and_rawlinks;
	return $self->{canonical_names};
}

=item $download->link_names

Returns the set of timezone names that this version of the database
defines as links.  These are the timezone names that are aliases for
other names.  The return value is a reference to a hash, in which the
keys are the link timezone names and the values are all C<undef>.

=cut

sub link_names {
	my($self) = @_;
	unless(exists $self->{link_names}) {
		$self->{link_names} =
			{ map { ($_ => undef) } keys %{$self->raw_links} };
	}
	return $self->{link_names};
}

=item $download->all_names

Returns the set of timezone names that this version of the database
defines.  These are the L</canonical_names> and the L</link_names>.
The return value is a reference to a hash, in which the keys are the
timezone names and the values are all C<undef>.

=cut

sub all_names {
	my($self) = @_;
	unless(exists $self->{all_names}) {
		$self->{all_names} = {
			%{$self->canonical_names},
			%{$self->link_names},
		};
	}
	return $self->{all_names};
}

=item $download->raw_links

Returns details of the timezone name links in this version of the
database.  Each link defines one timezone name as an alias for some
other timezone name.  The return value is a reference to a hash, in
which the keys are the aliases and each value is the preferred timezone
name to which that alias directly refers.  It is possible for an alias
to point to another alias, or to point to a non-existent name.  For a
more processed view of links, see L</threaded_links>.

=cut

sub raw_links {
	my($self) = @_;
	$self->_ensure_canonnames_and_rawlinks;
	return $self->{raw_links};
}

=item $download->threaded_links

Returns details of the timezone name links in this version of the
database.  Each link defines one timezone name as an alias for some
other timezone name.  The return value is a reference to a hash, in
which the keys are the aliases and each value is the canonical name of
the timezone to which that alias refers.  All such canonical names can
be found in the L</canonical_names> hash.

=cut

sub threaded_links {
	my($self) = @_;
	unless(exists $self->{threaded_links}) {
		my $raw_links = $self->raw_links;
		my %links = %$raw_links;
		while(1) {
			my $done_any;
			foreach(keys %links) {
				next unless exists $raw_links->{$links{$_}};
				$links{$_} = $raw_links->{$links{$_}};
				die "circular link at $_\n" if $links{$_} eq $_;
				$done_any = 1;
			}
			last unless $done_any;
		}
		my $canonical_names = $self->canonical_names;
		foreach(keys %links) {
			die "link from $_ to non-existent zone $links{$_}\n"
				unless exists $canonical_names->{$links{$_}};
		}
		$self->{threaded_links} = \%links;
	}
	return $self->{threaded_links};
}

=item $download->country_selection

Returns information about how timezones relate to countries, intended
to aid humans in selecting a geographical timezone.  This information
is derived from the C<zone.tab> and C<iso3166.tab> files in the database
source.

The return value is a reference to a hash, keyed by (ISO 3166 alpha-2
uppercase) country code.  The value for each country is a hash containing
these values:

=over

=item B<alpha2_code>

The ISO 3166 alpha-2 uppercase country code.

=item B<olson_name>

An English name for the country, possibly in a modified form, optimised
to help humans find the right entry in alphabetical lists.  This is
not necessarily identical to the country's standard short or long name.
(For other forms of the name, consult a database of countries, keying
by the country code.)

=item B<regions>

Information about the regions of the country that use distinct
timezones.  This is a hash, keyed by English description of the region.
The description is empty if there is only one region.  The value for
each region is a hash containing these values:

=over

=item B<olson_description>

Brief English description of the region, used to distinguish between
the regions of a single country.  Empty string if the country has only
one region for timezone purposes.  (This is the same string used as the
key in the B<regions> hash.)

=item B<timezone_name>

Name of the Olson timezone used in this region.  This is not necessarily
a canonical name (it may be a link).  Typically, where there are aliases
or identical canonical zones, a name is chosen that refers to a location
in the country of interest.  It is not guaranteed that the named timezone
exists in the database (though it always should).

=item B<location_coords>

Geographical coordinates of some point within the location referred to in
the timezone name.  This is a latitude and longitude, in ISO 6709 format.

=back

=back

This data structure is intended to help a human select the appropriate
timezone based on political geography, specifically working from a
selection of country.  It is of essentially no use for any other purpose.
It is not strictly guaranteed that every geographical timezone in the
database is listed somewhere in this structure, so it is of limited use
in providing information about an already-selected timezone.  It does
not include non-geographic timezones at all.  It also does not claim
to be a comprehensive list of countries, and does not make any claims
regarding the political status of any entity listed: the "country"
classification is loose, and used only for identification purposes.

=cut

sub country_selection {
	my($self) = @_;
	unless(exists $self->{country_selection}) {
		my $itabname = $self->unpacked_dir."/iso3166.tab";
		my $ztabname = $self->unpacked_dir."/zone.tab";
		local $/ = "\n";
		my %itab;
		my $itabfh = IO::File->new($itabname, "r")
			or die "data file $itabname unreadable: $!\n";
		while(defined(my $line = $itabfh->getline)) {
			$line = decode("UTF-8", $line, FB_CROAK);
			utf8::upgrade($line);
			if($line =~ /\A([A-Z]{2})\t(\S[^\t\n]*\S)\n\z/) {
				die "duplicate $itabname entry for $1\n"
					if exists $itab{$1};
				$itab{$1} = $2;
			} elsif($line !~ /\A#[^\n]*\n\z/) {
				die "bad line in $itabname\n";
			}
		}
		my %sel;
		my $ztabfh = IO::File->new($ztabname, "r")
			or die "data file $ztabname unreadable: $!\n";
		while(defined(my $line = $ztabfh->getline)) {
			if($line =~ /\A([A-Z]{2})
				\t([-+][0-9]{4}(?:[0-9]{2})?
					[-+][0-9]{5}(?:[0-9]{2})?)
				\t([!-~]+)
				(?:\t([!-~][ -~]*[!-~]))?
			\n\z/x) {
				my($cc, $coord, $zn, $reg) = ($1, $2, $3, $4);
				$reg = "" unless defined $reg;
				$sel{$cc} ||= { regions => {} };
				die "duplicate $ztabname entry for $cc\n"
					if exists $sel{$cc}->{regions}->{$reg};
				$sel{$cc}->{regions}->{$reg} = {
					olson_description => $reg,
					timezone_name => $zn,
					location_coords => $coord,
				};
			} elsif($line !~ /\A#[^\n]*\n\z/) {
				die "bad line in $ztabname\n";
			}
		}
		foreach(keys %sel) {
			die "unknown country $_\n" unless exists $itab{$_};
			$sel{$_}->{alpha2_code} = $_;
			$sel{$_}->{olson_name} = $itab{$_};
			die "bad region description in $_\n"
				if keys(%{$sel{$_}->{regions}}) == 1 xor
					exists($sel{$_}->{regions}->{""});
		}
		$self->{country_selection} = \%sel;
	}
	return $self->{country_selection};
}

=back

=head2 Compiling zone data

=over

=item $download->source_data_files

Returns a reference to an array containing the pathnames of all the source
data files.  These express the database's data (i.e., a description
of known civil timezones) in a textual format, and are intended for
human editing.  They are located in the local temporary directory used
by this download.

There is normally approximately one source data file per continent,
though this arrangement could change in the future.  The textual format
is machine parseable, the same format intended for input to C<zic>, but
when interpreted this way the files do not necessarily correspond to the
the official content of the database.  There may be transformations that
the database code would normally apply between the source data files
and the actual input to C<zic>.

If you intend to parse the source, taking the place of C<zic>, then you
should prefer to use the L</zic_input_files> method, which provides the
input that C<zic> would actually see.

=cut

sub source_data_files {
	my($self) = @_;
	unless(exists $self->{source_data_files}) {
		my $list;
		$self->_ensure_unpacked;
		my $mf = IO::File->new($self->dir."/Makefile", "r");
		my $mfc = $mf ? do { local $/ = undef; $mf->getline } : "";
		my $datavars = "\$(TDATA)";
		if($mfc =~ m#
			\nfulldata\.zi(?:[\ \t]+[0-9A-Z_a-z]+\.zi)*[\ \t]*:
			[\ \t]+\$\(DSTDATA_ZI_DEPS\)[\ \t]*\n
			\t[\ \t]*\$\(AWK\)\ -v\ outfile\=\'\$\@\'
				\ -f\ zidst\.awk
				\ \$\(TDATA\)\ \$\(PACKRATDATA\)
				\ (?:\\\n\t[\ \t]*)?\>\$\@.out\n
			\t[\ \t]*mv\ \$\@\.out\ \$\@\n[^\t]
		#x || $mfc =~ m#
			\ntzdata\.zi:[\ \t]+\$\(TZDATA_ZI_DEPS\)[\ \t]*\n
			(?:\t[\ \t]*version=\`sed\ 1q\ version\`\ \&\&\ \\\n)?
			\t[\ \t]*LC_ALL=C\ \$\(AWK\)
				(?:\ -v\ version="\$\$version")?
				\ -f\ zishrink\.awk
				\ (?:\\\n\t[\ \t]*)?
				\$\(TDATA\)\ \$\(PACKRATDATA\)\ \>\$\@.out\n
			\t[\ \t]*mv\ \$\@\.out\ \$\@\n\n
		#x) {
			$datavars .= " \$(PACKRATDATA)";
		} elsif($mfc =~ m#\ntzdata\.zi:#) {
			die "don't know how to extract source data file names ".
				"from this form of Olson distribution\n";
		}
		$list = filter("", "make", "--no-print-directory",
				"-C", $self->dir, "names",
				"ENCHILADA=$datavars", "VERSION_DEPS=");
		$list =~ s#\n\z##;
		$self->{source_data_files} =
			[ map { $self->dir."/".$_ } split(/ /, $list) ];
	}
	return $self->{source_data_files};
}

=item $download->zic_input_files

Returns a reference to an array containing the pathnames of all the
data files that would normally be fed to C<zic>.  These express the
database's data (i.e., a description of known civil timezones) in
the format expected by C<zic>, and are suitable for machine parsing.
They are located in the local temporary directory used by this download.
This method will build the files if they didn't already exist.

The C<zic> input files are not necessarily source files intended for human
editing.  In older versions of the database they are such source files,
but from database version C<2017c> onwards there is a single C<zic> input
file, which is generated from the source files and omits the niceties of
the source files.  From database version C<2018d> onwards there is some
transformation between the source files and the C<zic> input, such that
they do not necessarily express the same data when parsed by C<zic>.
These arrangements could change again in the future.

The textual format of C<zic> input is not standardised, and is peculiar
to the Olson database.  Parsing it directly is in principle a dubious
proposition, but in practice it is very stable.

If you want the human-editable source form of the data, use the
L</source_data_files> method instead.

=cut

sub zic_input_files {
	my($self) = @_;
	unless(exists $self->{zic_input_files}) {
		$self->_ensure_unpacked;
		my $mf = IO::File->new($self->dir."/Makefile", "r");
		my $mfc = $mf ? do { local $/ = undef; $mf->getline } : "";
		if($mfc =~ m#\ntzdata\.zi:#) {
			filter("", "make", "-C", $self->dir, "tzdata.zi",
				"VERSION_DEPS=");
			$self->{zic_input_files} = [ $self->dir."/tzdata.zi" ];
		} else {
			$self->{zic_input_files} = $self->source_data_files;
		}
	}
	return $self->{zic_input_files};
}

=item $download->data_files

Returns a reference to an array containing the pathnames of all the
source data files, provided that the database code would feed the
same data to C<zic>.  This method is deprecated: you should use either
L</source_data_files> or L</zic_input_files> depending on which aspect of
the data files you are interested in.  In older versions of the database
the same files were both human-editable and used as C<zic> input, so
this single method served both roles.  From database version C<2018d>
onwards there is some transformation between the source files and the
C<zic> input, so the two roles of the files need to be distinguished.

=cut

sub data_files {
	my($self) = @_;
	unless(exists $self->{data_files_dual_role}) {
		my $list;
		$self->_ensure_unpacked;
		my $mf = IO::File->new($self->dir."/Makefile", "r");
		my $mfc = $mf ? do { local $/ = undef; $mf->getline } : "";
		if($mfc !~ m#\ntzdata\.zi:# || $mfc =~ m#
			\ntzdata\.zi:[\ \t]+\$\(TZDATA_ZI_DEPS\)[\ \t]*\n
			(?:\t[\ \t]*version=\`sed\ 1q\ version\`\ \&\&\ \\\n)?
			\t[\ \t]*LC_ALL=C\ \$\(AWK\)
				(?:\ -v\ version="\$\$version")?
				\ -f\ zishrink\.awk
				\ (?:\\\n\t[\ \t]*)?
				\$\(TDATA\)\ \$\(PACKRATDATA\)\ \>\$\@.out\n
			\t[\ \t]*mv\ \$\@\.out\ \$\@\n\n
		#x) {
			$self->{data_files_dual_role} = 1;
		} else {
			$self->{data_files_dual_role} = 0;
		}
	}
	if($self->{data_files_dual_role}) {
		return $self->source_data_files;
	} else {
		die "source data files and zic input are distinct in ".
			"this form of Olson distribution\n";
	}
}

sub _ensure_zic_built {
	my($self) = @_;
	unless($self->{zic_built}) {
		$self->_ensure_unpacked;
		filter("", "make", "-C", $self->dir, "zic", "VERSION_DEPS=");
		$self->{zic_built} = 1;
	}
}

=item $download->zic_exe

Returns the pathname of the C<zic> executable that has been built from
the downloaded source.  This is located in the local temporary directory
used by this download.  This method will build C<zic> if it has not
already been built.

=cut

sub zic_exe {
	my($self) = @_;
	$self->_ensure_zic_built;
	return $self->dir."/zic";
}

=item $download->zoneinfo_dir([OPTIONS])

Returns the pathname of the directory containing binary tzfiles (in
L<tzfile(5)> format) that have been generated from the downloaded source.
This is located in the local temporary directory used by this download,
and the files within it have names that match the timezone names (as
returned by L</all_names>).  This method will generate the tzfiles if
they have not already been generated.

The optional parameter I<OPTIONS> controls which kind of tzfiles are
desired.  If supplied, it must be a reference to a hash, in which these
keys are permitted:

=over

=item B<leaps>

Truth value, controls whether the tzfiles incorporate information about
known leap seconds offsets that account for the known leap seconds.
If false (which is the default), the tzfiles have no knowledge of leap
seconds, and are intended to be used on a system where C<time_t> is some
flavour of UT (as is conventional on Unix and is the POSIX standard).
If true, the tzfiles know about leap seconds that have occurred between
1972 and the date of the database, and are intended to be used on a
system where C<time_t> is (from 1972 onwards) a linear count of TAI
seconds (which is a non-standard arrangement).

=back

=cut

sub _foreach_nondir_under($$);
sub _foreach_nondir_under($$) {
	my($dir, $callback) = @_;
	my $dh = IO::Dir->new($dir) or die "can't examine $dir: $!\n";
	while(defined(my $ent = $dh->read)) {
		next if $ent =~ /\A\.\.?\z/;
		my $entpath = $dir."/".$ent;
		if(-d $entpath) {
			_foreach_nondir_under($entpath, $callback);
		} else {
			$callback->($entpath);
		}
	}
}

sub zoneinfo_dir {
	my($self, $options) = @_;
	$options = {} if is_undef($options);
	foreach(keys %$options) {
		die "bad option `$_'\n" unless /\Aleaps\z/;
	}
	my $type = $options->{leaps} ? "right" : "posix";
	my $zidir = $self->dir."/zoneinfo_$type";
	unless($self->{"zoneinfo_built_$type"}) {
		filter("", "make", "-C", $self->unpacked_dir,
			"${type}_only", "TZDIR=$zidir", "VERSION_DEPS=");
		my %expect_names = %{$self->all_names};
		my $skiplen = length($zidir) + 1;
		_foreach_nondir_under($zidir, sub {
			my($fname) = @_;
			my $lname = substr($fname, $skiplen);
			unless(exists $expect_names{$lname}) {
				die "unexpected file $lname\n";
			}
			delete $expect_names{$lname};
		});
		if(keys %expect_names) {
			die "missing file @{[(sort keys %expect_names)[0]]}\n";
		}
		$self->{"zoneinfo_built_$type"} = 1;
	}
	return $zidir;
}

=back

=head1 BUGS

Most of what this class does will only work on Unix platforms.  This is
largely because the Olson database source is heavily Unix-oriented.

This class also depends on the availability of some tools beyond
baseline Unix.  Specifically, it requires GNU C<gpgv>, GNU C<tar>,
C<lzip>, C<sha512sum>, and GNU C<make>.

It also won't be much good if you're not connected to the Internet.

This class is liable to break if the format of the Olson database source
ever changes substantially.  If that happens, an update of this class
will be required.  It should at least recognise that it can't perform,
rather than do the wrong thing.

=head1 SEE ALSO

L<DateTime::TimeZone::Tzfile>,
L<Time::OlsonTZ::Data>,
L<tzfile(5)>

=head1 AUTHOR

Andrew Main (Zefram) <zefram@fysh.org>

=head1 COPYRIGHT

Copyright (C) 2010, 2011, 2012, 2017, 2018
Andrew Main (Zefram) <zefram@fysh.org>

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
