#!/usr/bin/perl -w
use strict;

# Tested: (probably OK): no SHIFTSTATES for mixes synthetic/real: flags Ctrl|Alt|Kana (=C-lA), Ctrl|Alt|Loya (=lC-A) - and Shift. 

#     TODO:
# KeyNamesExt not complete now.
# DESCRIPTIONS and LANGUAGENAMES ignored now.  (Use PowerShell's ([globalization.cultureinfo]0x419).Name ???
#     per https://stackoverflow.com/questions/41060314/convert-int32-to-cultureinfo-powershell-vs-c-sharp )
#         Or  https://stackoverflow.com/questions/2379514/powershell-formatting-values-in-another-culture ?
# No warnings on missing sections emitted???
# The specified line in LAYOUT is “not merged” with the default one, but replaces it.
# The default line in LAYOUT assumes that the first 3 columns are None, Shift, Control.
# The current code producing SGCAPS lines produces rudimental dead keys.  (NOTE: dead keys are not permitted in the first two columns
#  of a non-CAPSLOCK'ed row.  If dead keys are present (in the first two columns of) a CAPSLOCK'ed row, we emit the 3rd
#  line.)  In fact, one can have a dead key on the non-CAPSLOCK'ed row - but the CAPSLOCK'ed valiant should be non-a-dead-key (which
#  should be duplicated as an identical dead key.
# The current code producing SGCAPS lines does not warn that dead keys in columns of bitmaps 0 and 1 need duplication of DEADKEY
#    sections in .klc file.
# Does not auto-compile.
# We only allow ;-comments after names of long-sections.  (Doing it “easily”: conflicts with embedded strings, ';' and "; meaning 003b".
# (Implement more than one entry for a SHIFTSTATE row???  Duplication of VC_codes (Needed?  Do during generation of .klc?)???)
# Need also to support duplication of VK to several other VKs.  Or is better done in .klc?
# Likewise, seems to be that a separate CAPSLOCK=CAPITAL modification-bitmap-binding should be done in .klc…
# For SGCAPS we assume that the first two columns have bitmaps 0, 1.
# For LIGATURE we do not support wrapping-long-bindings-to-the-next-entries.
# Using TYPEDEF_LIGATURE(n) for n>5 in the generated .h files is not tested.
# We do not define E0-extended scancodes from non-type-4 keyboards (though there are no conflicts in defining them).
# Is binding VK_POWER beneficial?

##  kbdutool does not link aVkToWch3 with an empty LAYOUT is empty  (confusing description??? of really appearing situation)

### Enhancements w.r.t. functionality of kbdutool (we do not list fixed bugs of kbdutool here):

# We do not restrict functionality of SGCAPS w.r.t. dead keys.
# ATTRIBUTES are allowed to contain NOALTGR, disabling auto-generation
# We allow (and ignore) “fake” scancodes (between 0xE0E0 and 0xE0EF) for NUMPADn/DECIMAL VK-codes
# In Modifiers, one can use the macros KBD_l with the letter l one of XYZTUVW (with KBD_X==0x10 etc.)  In the SHIFTSTATE one should
#    use at least one bitmap with the corresponding bit set.
#    Here _X and _Y duplicate ROYA and LOYA, and _T duplicating GRPSELTAP.
# Option --comment-vkcodes=VK_first,VK_second would comment out emitting the specified VK-codes (with "VK_" omitted).

my $v = 0.76;

my %comment_vkcodes;
shift, %comment_vkcodes = map {($_,1)} split /\s*,\s*/, $1 if @ARGV and $ARGV[0] =~ /^--comment-vkcodes=(.*)/;

my %scancodes = get_scancodes();
$scancodes{$_} eq '_none_' and delete $scancodes{$_} for keys %scancodes;

sub get_file ($) {
  my $fn = shift;
  open my $F, '<', $fn or die "open <$fn> for read: $!, $^E";
  do {local $/; <$F>};
}

sub clean_extra ($) {
  my($in) = (shift);
  $in =~ s([^\S\n]*//.*)()g;		# remove comments
  $in =~ s([^\S\n]+$)()gm;		# remove trailing whitespace (including \r!)
  $in
}

sub clean_end ($) {
  my($in) = (shift);
  $in =~ s/^\s*ENDKBD\s*(?:$).*//sm;
  $in
}

sub extract_section_1line ($$) {
  my($in, $sec) = (shift, shift);
  $in =~ /^\s*$sec\b\s*(.*)$/m or die "Cannot find $sec inside the KLC file";
  $1
}

sub extract_section ($$;$) {	# may return what remains
  my($in, $sec, $strip, $rest) = (shift, shift, shift);
  $in =~ s/(\A.*?)^\s*$sec([ \t]*;[^\n]*)?\n//sm or die "Cannot find $sec inside the KLC file";
  $rest = $1;
  $in =~ s/(^[^\S\n]*(KEYNAME|LIGATURE|COPYRIGHT|COMPANY|LOCALENAME|LOCALEID|VERSION|SHIFTSTATE|LAYOUT|ATTRIBUTES|MODIFIERS|KEYNAME_EXT|KEYNAME_DEAD|DESCRIPTIONS|LANGUAGENAMES|DEADKEY|ENDKBD)\b.*)//ms
     or die "Cannot find end of $sec inside the KLC file";
  $rest .= $1;
  $in =~ s/^\n//gm if $strip;			# remove empty lines
  $in =~ s/^\s+//;
  return $in unless wantarray;
  ($in, $rest, 1)
}

my $fn = shift or die;
# my $ofn_base = shift or die;

########### Parse the file roughly

my $IN = get_file $fn;
my $in = clean_extra $IN;
my %IN;

$IN{$_} = '' for my @names_long_opt = qw(LAYOUT LIGATURE KEYNAME KEYNAME_EXT KEYNAME_DEAD DESCRIPTIONS LANGUAGENAMES MODIFIERS ATTRIBUTES);
my(@names_long, %seen) = (@names_long_opt, qw(SHIFTSTATE));
for my $sn (@names_long) {
 eval { ($IN{$sn}, $in, $seen{$sn}) = extract_section $in, $sn, 'strip' };
}
$in = clean_end $in;

my @names_short = qw(KBD COPYRIGHT COMPANY LOCALENAME LOCALEID VERSION);
for my $sn (@names_short) {
 eval { $IN{$sn} = extract_section_1line $in, $sn };
}
my @missing = grep(!exists $IN{$_}, @names_short), grep !$seen{$_}, qw(SHIFTSTATE);
my @missing_opt = grep(!exists $IN{$_}, @names_short), grep !$seen{$_}, @names_long_opt;
warn "Sections @missing not found in file '$fn'" if @missing;
warn "Optional sections @missing_opt not found in file '$fn'" if @missing_opt;

my $rx = join '|', @names_short, @names_long;
my @unrecognized = grep {!/^\s*$/ and !/^\s*($rx)\b/} split /\n/, $in;

##################################### Parse Deadkeys

my($rest, %DK, @DK) = '';
for my $dk (split /(?!\A)^(?=\s*DEADKEY\b)/m , join "\n", @unrecognized) {
  $rest .= $dk, next unless $dk =~ s/^\s*DEADKEY\b\s+(\S+)\s*\n//;
  push @DK, uc $1 unless $DK{uc $1};
  $DK{uc $1} = [map {s/^\s+//; [split /\s+/, $_]} split /\n/, $dk];
}

warn join "\n", "Unrecognized lines in file '$fn':", $rest if length $rest;

##################################### Refine and translate the parsed data

############################# Name
my(%REPL, @null_sec);
($REPL{mod_name}, $IN{mod_descr}) = ($IN{KBD} =~ /^(\S+)\s+"(.*)"/);
my $name = $REPL{mod_name};

############################ Massage short fields
$REPL{myversion} = "$0 v$v";
$REPL{mydate} = localtime;
($REPL{copyright} = $IN{COPYRIGHT}) =~  s/^"|"\s*(;.*)?$//g;

for my $s (qw(COPYRIGHT COMPANY LOCALENAME LOCALEID mod_descr)) {
  (my $i = $IN{$s}) =~ s/(?=[\\""])/\\/g;
  $i =~ s/^\\"|\\"\s*$//g;
  $REPL{"q_\L$s"} = $i;
}
($REPL{version1},$REPL{version2}) = split /\./, $IN{VERSION};

use Locale::Language;
my($Lang, $Ctry) = split /[-_]/, $REPL{q_localename};
my $L = code2language($Lang) or warn "Unknown language code: $Lang";
$REPL{Language} = $L || 'Unknown';

use Locale::Country;
my $C = code2country($Ctry) or warn "Unknown country code: $Ctry";
$REPL{Country} = $C = $C || 'Unknown';

my $known_l = <<'EOL';		# from winnt.h
  AFRIKAANS ALBANIAN ALSATIAN AMHARIC ARABIC ARMENIAN ASSAMESE AZERI BASHKIR
  BASQUE BELARUSIAN BENGALI BRETON BOSNIAN BOSNIAN_NEUTRAL BULGARIAN CATALAN
  CHINESE CHINESE_SIMPLIFIED CHINESE_TRADITIONAL CORSICAN CROATIAN CZECH
  DANISH DARI DIVEHI DUTCH ENGLISH ESTONIAN FAEROESE FARSI FILIPINO FINNISH
  FRENCH FRISIAN GALICIAN GEORGIAN GERMAN GREEK GREENLANDIC GUJARATI HAUSA
  HEBREW HINDI HUNGARIAN ICELANDIC IGBO INDONESIAN INUKTITUT IRISH ITALIAN
  JAPANESE KANNADA KASHMIRI KAZAK KHMER KICHE KINYARWANDA KONKANI KOREAN
  KYRGYZ LAO LATVIAN LITHUANIAN LOWER_SORBIAN LUXEMBOURGISH MACEDONIAN MALAY
  MALAYALAM MALTESE MANIPURI MAORI MAPUDUNGUN MARATHI MOHAWK MONGOLIAN NEPALI
  NORWEGIAN OCCITAN ORIYA PASHTO PERSIAN POLISH PORTUGUESE PUNJABI QUECHUA
  ROMANIAN ROMANSH RUSSIAN SAMI SANSKRIT SERBIAN SERBIAN_NEUTRAL SINDHI
  SINHALESE SLOVAK SLOVENIAN SOTHO SPANISH SWAHILI SWEDISH SYRIAC TAJIK
  TAMAZIGHT TAMIL TATAR TELUGU THAI TIBETAN TIGRIGNA TSWANA TURKISH TURKMEN
  UIGHUR UKRAINIAN UPPER_SORBIAN URDU UZBEK VIETNAMESE WELSH WOLOF XHOSA
  YAKUT YI YORUBA ZULU
EOL

$L = uc $L;
$L = 'NEUTRAL' unless $known_l =~ /\b$L\b/;
$REPL{LANG_MACRO} = "LANG_$L";

############################# Modifiers
my($mods, %mods) = <<EOM;
  SHIFT		KBDSHIFT
  CONTROL	KBDCTRL
  MENU		KBDALT
EOM

my(@mods) = qw(S C A K R L Z T);		# @BM: Shortcuts for bits
my %BM = map {($mods[$_], 1<<$_)} 0..$#mods;	# "simple 'synthetic' bit" => "bitmaps generated by actual left/right modifier keys"
%BM = (%BM, X => $BM{R}, Y => $BM{L}, GRPSELTAP => $BM{T} );

sub KBD2n($) {
  my($in,$n)=shift;
  return oct $in if $in =~ /^0/;		# understands hex too
  return $in unless $in =~ /\D/;
  $in =~ s/^KBD(_(?=\w$))?// or die "Expecting only KBD* macros in the MODIFIERS section";
  $n = $BM{$in} || $BM{substr $in, 0, 1};
  die "Error interpreting the macro KBD$in" unless $n;
  $n}

my %bmVal;
sub parse_mods($) {
  my $in = shift;
  $in =~ s/^\s+//;			# Needed for the defaults above!
  for my $l (split /\s*\n\s*/, $in) {
    my($n,$k,$bm) = (0, split /\s+/, $l, 2) or warn "unexpected format of MODIFIERS line: <<<$l>>>";
    $mods{$k} = $bm;
    $n |= KBD2n $_ for split /\s*[|+]\s*/, $bm;
    $bmVal{$k} = $n;
    warn " bmval: $k -> $n";
  }
}
parse_mods $mods;
parse_mods $IN{MODIFIERS} if exists $IN{MODIFIERS};
$REPL{modifiers} = join '', map "    { VK_$_ ,\t$mods{$_} },\n", 	# sort in almost-expected order
  grep(/^[SCM]/, reverse sort keys %mods), grep /^[^SCM]/, sort keys %mods;

# Due to: applications may synthesize non-chiral keypresses (such as VK_SHIFT) and KBDALT stripping
my %massage_shiftstate; # = ( $BM{S} => [$BM{S}], $BM{C} => [$BM{C}|$BM{L}, $BM{C}|$BM{A}|$BM{R}], $BM{A} => [$BM{A}|$BM{K}]);  # , $BM{C}|$BM{A}|$BM{L}|$BM{Z}
for my $k (qw(SHIFT CONTROL MENU)) {
  my($v,@vv) = ($bmVal{$k}, grep defined, map $bmVal{"$_$k"}, 'L', ($k eq 'MENU' ? () : ('R')));
  $massage_shiftstate{$v} = [$v, @vv];
  warn "massage_shiftstate: $v [@vv]";
}

my(@MSS, %trSS, $kn, $knA) = keys %massage_shiftstate;	# Need to combine only the modifiers apps know about: S C A
for my $subset (0..(1<<@MSS)-1) {		# Loop over subsets of %massage_shiftstate
  my($from, @TO, @bits, $factor) = (0, 0);	# Calculate OR-combinations of bitmaps, one per element of the factors indexed by this subset
  $subset & (1<<$_) and $from |= $MSS[$_], push @bits, $massage_shiftstate{$MSS[$_]} for 0..$#MSS;	# map $combos to the bitmap $from of non-chiral keys
  $factor = shift @bits, @TO = map {my $t= $_; map $t|$_, @$factor } @TO while @bits;	# OR sets @TO and @$factor, put result to @TO
  $kn++  if not $kn  and grep +($_&~$BM{S}) == $BM{K}, @TO;
  $knA++ if not $knA and grep +($_&~$BM{S}) == ($BM{K}|$BM{A}), @TO;
  next unless @TO = grep $_ != $from, @TO;
  warn "from $subset ($from) to @TO\n";
  push @{$trSS{$from}}, @TO;			# Allow the table to match a column to a “real” shiftstate
  push @{$trSS{$_}}, $from for @TO;		# Allow the table to match a column to an (abstract) base shiftstate
}
if ($knA and not $kn) {				# compensate stripping A from K|A
  push @{$trSS{$_|$BM{K}}}, $_ for 0, $BM{S};	# Bind KBDKANA and KBDKANA | KBDSHIFT columns
}

############################# Shiftstate

my($tot, $moddefs, $defModCombs, $maxbitmap, @column2state) = (0, '', '', -1, split /\s+/, $IN{SHIFTSTATE});
warn join(' ', map "$_,$column2state[$_]", 0..$#column2state), "\n";
my(%state2column, %addSS) = map {($column2state[$_],$_)} grep $_ != 15, 0..$#column2state;	# 15 is INVALID
for my $st (keys %trSS) {	# states aliased to one of the defined states (via chiral/non-chiral match and KBDALT stripping)
  my @all = grep defined, $state2column{$st}, map $state2column{$_}, @{$trSS{$st}};	# starts with the “prescribed value” if present
  warn "from $st to @all | @{$trSS{$st}}\n" if @all and $all[0] != ($state2column{$st} || -1);
  $addSS{$st} = $all[0] if @all;
}
%state2column = (%state2column, %addSS);	# the “prescribed value” wins
$tot |= (0+$_), ($maxbitmap<$_ and $maxbitmap = $_) for @column2state;
($tot >> $_->[0])&0x1 and $moddefs .= "#define KBD_$_->[1]\n"	# #define KBD_Z  0x40; our KBD_T duplicates KBDGRPCHGTAT 
  for map [$_+4, substr('XYZTUVW',$_,1) . sprintf "\t%#x", 1<<($_+4)], 0..6;  # [6, "Z\t0x40"], [7, "T\t0x80"];				#   (which is a remnant of abandoned attempt in MS)

my @names = qw(Shift	Ctrl	Alt	Kana	Roya	Loya	Z	T);
sub bitmap2comment($) {my($in, $o) = (shift, ''); $o .= "\t" . ( $in & (1<<$_) ? $names[$_] : '') for 0..7; $o}

# my $maxbitmap = $tot & 0x80 ? 255 : ($tot & 0x40 ? 128 : 63);
$defModCombs .= "\t" . (defined $state2column{$_} ? "$state2column{$_},\t\t" : "SHFT_INVALID,\t")
  . '// ' . bitmap2comment($_) . "\n" for 0..$maxbitmap;
$REPL{pre_column_descr} = $moddefs;
$REPL{num_column_descr} = $maxbitmap + 1;
$REPL{column_descr} = $defModCombs;

############################# Layout default
my $L_default = <<'EOD';
  0F  TAB       0      '\t'     '\t'
  4E  ADD       0      '+'      '+'
 e035 DIVIDE    0      '/'      '/'
  37  MULTIPLY  0      '*'      '*'
  4A  SUBTRACT  0      '-'      '-'
  0E  BACK      0      '\b'     '\b'     0x007f
  01  ESCAPE    0      0x001b   0x001b   0x001b
  1C  RETURN    0      '\r'     '\r'     '\n'
  39  SPACE     0      0020     0020     0020
 e046 CANCEL    0      0x0003   0x0003   0x0003
  0 NUMPAD0   0        '0'
  0 NUMPAD1   0        '1'
  0 NUMPAD2   0        '2'
  0 NUMPAD3   0        '3'
  0 NUMPAD4   0        '4'
  0 NUMPAD5   0        '5'
  0 NUMPAD6   0        '6'
  0 NUMPAD7   0        '7'
  0 NUMPAD8   0        '8'
  0 NUMPAD9   0        '9'
EOD

############################# Parse Layout (with defaults)

my $rxX = qr(^(?:NUMPAD\d|ADD|DIVIDE|MULTIPLY|SUBTRACT|SEPARATOR|DECIMAL|OEM_(8|102)|ABNT_C[12])$); # VK_RETURN on both Return's
my $capsFl = [qw(CAPLOK SGCAPS CAPLOKALTGR KANALOK)];	# up to 0xF; kbdutool reads in decimal (does not matter without KANALOK!)
my($len,$lenX,%len_seen, %fix_scans) = ([2,3], [], 2,1,3,1);	# sections of length 2, 3 are put first by kbdutool

sub fx_scan($$) {
  my($scan, $VK, $hB) = (shift, shift);
  die "Low BYTE of a non-extended scancode should be at most 0x7f: $scan" if 0x7f < (0xff & hex $scan) and not $scan =~ /^e[01]/i;
  $hB = (hex $scan)>>8;
  die "High BYTE $hB of scancode should be 0 or 0xE0 or 0xE1: $scan" if $hB and ($hB < 0xe0 or $hB > 0xe1);
  $fix_scans{$scan} = $VK if not exists $scancodes{$scan} or $VK ne $scancodes{$scan};
#  warn " VK=$VK, sc=$scan, $scancodes{$scan} -> $fix_scans{$scan}; ex=", exists $scancodes{$scan} if $VK =~ /CON/;
}

sub scan_layout($$$;$$) {
  my($in, $VK2binds, $VK2bindsX, $oldVK, $oldScan, %VK2bind, %scan2VK, $prev, @x) = (shift, shift, shift, shift || {}, shift || {});
  for my $l (split /\n/, $in) {
    $l =~ s/^\s+//;
    my $cnt = (my($scan, $VK, $caps, @binds) = split /\s+/, $l);
    fx_scan(uc $scan, uc $VK),   $scan2VK{uc $scan} = uc $VK
      if $scan and not $scan =~ /-1/ and not $VK =~ /-1/ and not exists $oldScan->{uc $VK} and not $scan2VK{uc $VK};
    next unless $cnt > 2;		# Use for scancode only!
    $caps = 0x2 if uc $caps eq 'SGCAP';	# No S at end!!!
    if ($caps & 0x2) {			# SGCAPS has an extra line, usually of different length; cannot separate them
      $prev = [$scan, $VK, $caps, @binds];
      next;
    } elsif ($prev) {
      @x = @binds;
      ($scan, $VK, $caps, @binds) = @$prev;
      undef $prev;
    }
    next if exists $oldVK->{uc $VK};
#    warn "Repeated VK=$VK on different scan codes (saw $scan2VK{$VK}), unsupported" if $scan2VK{$VK};
#    $scan2VK{$VK} = $scan;
    $VK2bind{uc $VK} = [$caps, [@binds], [@x]];
    my($postf, $b) = (scalar @binds, $VK =~ $rxX ? $VK2bindsX : $VK2binds);
    $postf = "X$postf" if $VK =~ $rxX;
    push @{$VK =~ $rxX ? $lenX : $len}, $postf unless $len_seen{$postf}++;
    push @{$b->[scalar @binds]}, [uc $VK, $caps, [@binds], [@x]]; # the defaults will be put at end, where they have less chance to ruit the reverse lookup
    @x = ();
  }
  (\%VK2bind, \%scan2VK);
}

my(@VK2binds, @VK2bindsX);
my($VK2bind, $scan2VK) = scan_layout $IN{LAYOUT}, \@VK2binds, \@VK2bindsX;
my %VK2bind = %$VK2bind;
my %scan2VK = %$scan2VK;

($VK2bind, $scan2VK) = scan_layout $L_default, \@VK2binds, \@VK2bindsX, $VK2bind, $scan2VK;
%VK2bind = (%VK2bind, %$VK2bind);
%scan2VK = (%scan2VK, %$scan2VK);

############################# Output redefinition of scancodes (if needed)

my($FX_scans, $add_X, $add_Y, @sc_pref) = ('', '', '', qw(X Y));
my @pre_NUMPAD = qw(INSERT END DOWN PRIOR LEFT CLEAR RIGHT HOME UP NEXT DELETE);	# Not used
for my $sc (sort keys %fix_scans) {
  my($vk, $was) = ($fix_scans{$sc}, '');
  next if $vk =~ /^(NUMPAD(\d)|DECIMAL)$/ 	# Ignore fake codes (usually these VK's are not associated with scancodes; produced by translation of pre_NUMPAD)
    and (hex $sc >= 0xE0E0 and hex $sc < 0xE0F0 or "$vk-$sc" eq 'DECIMAL-53');	# kbdutool only accepts DECIMAL on 53
  $was = "\t// was $scancodes{$sc}" if exists $scancodes{$sc};
  (my $osc = "T$sc") =~ s/^TE([01])/$sc_pref[$1]/;
  $FX_scans .= <<EOF;
#undef  $osc
 #define $osc _EQ(                                                    $vk                   )$was
EOF
  if (not $was and $sc =~ /^E([01])\w/) {
    ($1 ? $add_Y : $add_X) .= <<EOA;
        { 0x$sc, $osc | KBDEXT              },  // $vk$was
EOA
  }
}
$REPL{fix_scancodes}  = $FX_scans;	# join ' ', keys %fix_scans, values %fix_scans;
$REPL{addX_scancodes} = $add_X;
$REPL{addY_scancodes} = $add_Y;

############################# Output SC_ part of the Layout

my @lay_lens  = grep defined $VK2binds[$_],  0..$#VK2binds;
my @lay_lensX = grep defined $VK2bindsX[$_], 0..$#VK2bindsX;
warn "Existing lengths of bindings: [@lay_lens], [@lay_lensX]";
my @extralendefs = map "TYPEDEF_VK_TO_WCHARS($_)\n", grep $_>10, @lay_lens;   # std definition file defines up to 10
$REPL{extralendefs} = join '', @extralendefs;

my(%VK2scan,@xtrascans, $ext) = reverse %scan2VK;
if ($VK2bind{DIVIDE} and ($ext = (~0xff & hex $VK2scan{DIVIDE}))) {
  warn "Unknown extended modifier for the scancode for VK_DIVIDE: $VK2scan{DIVIDE} -> $ext, expect " . 0xe000
    unless 0xe000 == $ext;
  push @xtrascans, "        { 0x35, X35 | KBDEXT              },  // Numpad Divide\n"
}
$REPL{xtrascans} = join '', @xtrascans;

############################# Output VK part of the Layout

my $prevVK;
my %compatTR = qw( 0008 '\b' 000a '\n' 000d '\r' 005c '\\\\' 0027 '\'' 0022 '\"' );
my $compatRx = qr/^00(0[8ad]|2[27]|5c)$/i;	# these frivolous conversions simplify comparison with kbdutool; may be removed!
sub s2c($;$) {my($i,$o) = shift; return $prevVK if $i eq '-1';
              $o = ($i =~ /^[''""\\]$/ ? "'\\$i'" : ($i =~ /^.$/ ? "'$i'" : ($i =~ /^0x[\da-z]+$/i ? $i : "VK_$i"))); $prevVK = $o if shift; $o}
sub hex2c($$) {my($i,$h) = (shift,shift); my $n = hex $i; return "0x\L$i" if !$h or $n<0x20 or $n > 0x7e; "L" . s2c chr $n }
sub ch2c($;$)  {my($i,$h) = (shift,shift); return $compatTR{lc $i} if $h and $i =~ $compatRx;
                $i =~ /^[\da-f]{2,}$/i ? hex2c($i,$h) : ($i =~ /^.$/ ? s2c($i) : ($i =~ /^-1$/ ? 'WCH_NONE'
			: ($i =~ /\@$/ ? 'WCH_DEAD' : ($i eq '%%' ? 'WCH_LGTR' : $i))))}

sub mx($$) {my($i,$j)=(shift, shift); $i<$j? $j : $i}
sub fmt_st($$$) {my($i,$j,$l) = (shift, shift, shift); "$i" . (' ' x mx(1, $l - 3 - length "$i$j")) . ",$j ,"}

my($sublayouts, @sublayouts) = '';
sub emit_layout_line ($$$$) {	# XXXX Need to take into account required length too ???
  my($vk, $caps, $bind, $x, @xx) = (shift, shift, shift, shift || []);
  (my $ss, $caps) = (hex($caps) & 0xF, hex($caps) & ~0xF);
  $caps ||= '';
  $caps .= '|' if $caps;
  $caps .= join ' | ', map {$ss&(1<<$_) ? $capsFl->[$_] : ()} 0..$#$capsFl; # [1,'CAPLOK'], [2,'SGCAPS'], [4,'CAPLOKALTGR'], [8,'KANALOK'];
  my @bind = map ch2c($_,'unhex'), @$bind;
  my $comment = $comment_vkcodes{$vk} ? '//' : '  ';
  $sublayouts .= $comment . fmt_st("{" . s2c($vk, 'prev'), $caps||"0", 26) . join(" ,", map {sprintf "%-8s", $_} @bind) . " },\n";
  return unless grep /^WCH_DEAD$/, @bind or @$x;
  if (@$x) {
    $#$x = 1 if $#$x > 1;
    shift @$bind for 0..$#$x;	 # XXXX actually, not shift, but splice, and not 0,1, but columns of bitmaps 0,1???
    @xx = map ch2c($_,'unhex'), @$x;
  }
  $sublayouts .= $comment . fmt_st('{' . (@$x? s2c($vk, 'prev') : '0xff'), 0, 26)
     . join(" ,", @xx, map {sprintf "%-8s", (/^(.*)\@$/ ? "0x$1" : 'WCH_NONE')} @$bind) . " },\n";
  return unless "@$x" =~ /\@/;	# Emit short initializer, as kbdutool does with the preceding row:
  $sublayouts .= $comment . fmt_st('{0xff', 0, 26) . join(" ,", map {sprintf "%-8s", (/^(.*)\@$/ ? "0x$1" : 'WCH_NONE')} @$x) . " },\n";
}

for my $X ('', 'X') {
  my $L =  ($X ? $lenX : $len);
  my @tbl =  ($X ? @VK2bindsX : @VK2binds);
  $sublayouts .= <<'EOS' if $X;
// The following keys are put last so that VkKeyScan interprets
// (e.g.) number characters
// as coming from the main section of the kbd (aVkToWch2 and
// aVkToWch5) before considering the numpad (aVkToWch1).

EOS
  for my $_len (@$L) {
    (my $len = $_len) =~ s/^X//;
    my $lst = $tbl[$len] or next;
    push @sublayouts, [$len, "aVkToWch$_len"];
    $sublayouts .= <<EOP;
static ALLOC_SECTION_LDATA VK_TO_WCHARS$len aVkToWch$_len\[] = {
//                         |         |  Shift  |  Ctrl   |S+Ctrl   |  C+  X1 |  C+  X1 |
//                         |=========|=========|=========|=========|=========|=========|
EOP
  emit_layout_line $_->[0], $_->[1], $_->[2], $_->[3] for @$lst;
  $sublayouts .= "  {\t" . join(",\t", (0) x ($len+2)) . "}\n" . <<'EOP';
};

EOP
  }
}
$REPL{sublayouts} = $sublayouts;

my $LL = '';
for my $sub (@sublayouts) {
#  warn "[<<<$sub>>>]";
#  warn "<<@$sub>>";
  $LL .= <<EOS;
    {  (PVK_TO_WCHARS1)$sub->[1],	$sub->[0],	sizeof($sub->[1]\[0]) },
EOS
}
$REPL{join_sublayouts} = $LL;

############################# Scan Ligatures
my($lig, $w, @lig) = ('', 1);			# Making it LIGATURE1 allows empty LIGATURE section without a special logic
if (exists $IN{LIGATURE}) {{
  for my $l (split /\n/m , $IN{LIGATURE}) {
    $l =~ s/^\s+//;
    my ($vk, $col, @c) = split /\s+/, $l;
    $w = @c if $w < @c;
    push @lig, [$vk, $col, @c]
  }

############################# Output Ligatures

  last unless @lig;
###  $lig .= "TYPEDEF_LIGATURE($w) // LIGATURE$w, *PLIGATURE$w;\n\n" if $w > 5;	# only up to 5 predefined; the limit is 126???
  $lig .= <<EOS;
     // If the output in the modifiers-bits/input -keys table contain WCH_LGTR, then instead
     // the VK and the modifiers_position_id are looked up in the table below:  What follows
     // is the expansion - which is ended either by WCH_NONE, or when the maximal length
     // specified in
ALLOC_SECTION_LDATA LIGATURE$w aLigature$w\[] = {
EOS
  for my $e (@lig) {
    my ($vk, $col, @e) = (@$e, ('WCH_NONE') x ($w + 2 - @$e));
    $lig .=  '  {' . fmt_st(s2c($vk), $col, 23) . ' ' . join(",\t", map ch2c($_), @e) . "},\n";
  }
  $lig .= '  {' . join(",\t", (0) x ($w+2)) . "}\n};\n\n";
  $REPL{ligatures} = $lig;
}}
if ($lig) {
  $REPL{ligature_width} = $w;
  $REPL{ligature_sizeof} = "sizeof(aLigature$w\[0])";
  $REPL{ligature_decl}  = $w > 5? "TYPEDEF_LIGATURE($w) // LIGATURE$w, *PLIGATURE$w;\n" : '';
  $REPL{ligature_decl}  .= "extern ALLOC_SECTION_LDATA LIGATURE$w aLigature$w\[];\n";
} else {
  $REPL{ligatures} = "/* No ligatures, skip */\n";
  $REPL{ligature_width} = $w = 0;
  $REPL{ligature_sizeof} = 0;
  $REPL{ligature_decl}  = '';
  push @null_sec, "aLigature$w";
}

############################# Output deadkeys

my $deadk = '';
for my $pref (@DK) {
  $deadk .= "\n" if $deadk;
  for my $b (@{$DK{$pref}}) {
    warn("Ignore misformed dead key descriptor for dk=$pref: @$b"), next unless @$b == 2;
    my($k, $res, $dead) = @$b;
    $dead = ($res =~ s/\@$//) + 0;
    $deadk .= '    DEADTRANS( ' . join(" ,\t", ch2c($k,'dehex'), ch2c($pref), ch2c($res,'dehex'), "0x000$dead") . "),\n";
  }
}
if ($deadk) {
  $REPL{deadkeys} = <<EOS;
ALLOC_SECTION_LDATA DEADKEY aDeadKey[] = {
$deadk  0, 0
};
EOS
} else {
  $REPL{deadkeys} = "/* No deadkeys, skip */\n";
  push @null_sec, qw(aDeadKey aKeyNamesDead);
}

#################################### Keynames

for my $how (qw(KEYNAME KEYNAME_EXT KEYNAME_DEAD)) {
  my($kn, $dd) = ('', $how =~ /DEAD/);
  my($sep) = ($dd ? '' : ',');	# No comma for KEYNAME_DEAD!
  if (exists $IN{$how}) {{
    for my $l (split /\n/m , $IN{$how}) {
      $l =~ s/^\s+//;
      my ($vk, $rest) = split /\s+/, $l, 2;
      $rest = qq("$rest") unless $rest =~ /^[""]/;
      $rest =~ s/^"(.+)"$/$1/;
      $rest =~ s/([\\""''])/\\$1/g;
      $rest =~ s/[^\x01-\x7f]//g;	# Same as MSKLC
      $vk = ch2c($vk);
      if (!$dd) {
        $vk = "L$vk" if $vk =~ /^['']/;
      } elsif ($vk =~ s/^0x/\\x/) {
        $vk = qq(L"$vk") 
      } else {
        die "Unsupported format of the key: $vk from <<$l>>";
      }
die 131 unless defined $sep;
      $kn .= qq(  $vk$sep\tL"$rest",\n);
    }
  }
  $REPL{$how} = $kn;
}}

if ($deadk) {
  $REPL{KEYNAME_DEAD} = <<EOS;
ALLOC_SECTION_LDATA DEADKEY_LPWSTR aKeyNamesDead[] = {
$REPL{KEYNAME_DEAD}    NULL
};
EOS
} else {
  $REPL{KEYNAME_DEAD} = "/* No deadkeys present, ignore deadkey names */\n";
}

if ($REPL{KEYNAME}) {
  $REPL{KEYNAME} = <<EOS;
static ALLOC_SECTION_LDATA VSC_LPWSTR aKeyNames[] = {
$REPL{KEYNAME}    NULL
};
EOS
} else {
  $REPL{KEYNAME} = "/* No key names present, skip */\n";
  push @null_sec, "aKeyNames";
}

if ($REPL{KEYNAME_EXT}) {
  $REPL{KEYNAME_EXT} = <<EOS;
ALLOC_SECTION_LDATA VSC_LPWSTR aKeyNamesExt[] = {
$REPL{KEYNAME_EXT}    0   ,    NULL
};
EOS
} else {
  $REPL{KEYNAME_EXT} = "/* No key names present, skip */\n";
  push @null_sec, "aKeyNamesExt";
}


$REPL{null_secs} = join "\n", (map "#define $_\tNULL", @null_sec), '';

my $init_auxVK = $REPL{init_auxVK} = <<'EOD';
    T00, T01, T02, T03, T04, T05, T06, T07,
    T08, T09, T0A, T0B, T0C, T0D, T0E, T0F,
    T10, T11, T12, T13, T14, T15, T16, T17,
    T18, T19, T1A, T1B, T1C, T1D, T1E, T1F,
    T20, T21, T22, T23, T24, T25, T26, T27,
    T28, T29, T2A, T2B, T2C, T2D, T2E, T2F,
    T30, T31, T32, T33, T34, T35,

    T36 | KBDEXT,                   // RSHIFT; KBDEXT is passed to the apps as bit 24 in lParam of WM_KEYDOWN   https://learn.microsoft.com/en-us/windows/win32/inputdev/wm-keydown
       // KBDMULTIVK: on some physical keyboards the kernel will convert this value to different VK-codes with suitable modifiers
       // This translation is based on VK-codes, so if T37 is redefined, then KBDMULTIVK may have no effect
       //   This type of keyboard is determined (at runtime) by .Type==3 in tagKBD_TYPE_INFO (supplied by the keyboard driver)
    T37 | KBDMULTIVK,               // numpad_*: with Shift or Alt -> VK_SNAPSHOT (in 84-key mode)

    T38, T39, T3A, T3B, T3C, T3D, T3E, T3F,
    T40, T41, T42, T43, T44,

	// IBM02 is a Japanese (meaning: .Type==7) keyboard with .Subtype==3 (e.g. IBM 5576-002/003); 101-key is the default, .Type==4
    T45 | KBDEXT | KBDMULTIVK,	    // NUMLOCK -> PAUSE  | KBDEXT with Shift+Ctrl   on IBM02 or           with Ctrl on 84- or 101-key
    T46 | KBDMULTIVK,		    // SCROLL  -> CANCEL | KBDEXT with (Shift+)Ctrl on IBM02 or -> CANCEL with Ctrl on 84- or 101-key

    // Number Pad keys (KBDNUMPAD) are processed specially (e.g. mouse emulation, hex input, 2 VK-codes, Shift removal);
    //   KBDSPECIAL is legacy only???
    //   KBDNUMPAD: with NumLock: with Shift: fake release of one-of-Shifts;
    //                                        otherwise translate the supplied VK->VK_NUMPADn/VK_DECIMAL (if translation exists).
    //              Also: disables VK-flip (Help|End; Home|Clear) of NLS special functions
    // The defaut VK-codes of these scancodes are shown in parentheses.
    T47 | KBDNUMPAD | KBDSPECIAL,   // Numpad 7 (Home)
    T48 | KBDNUMPAD | KBDSPECIAL,   // Numpad 8 (Up),
    T49 | KBDNUMPAD | KBDSPECIAL,   // Numpad 9 (PgUp),
    T4A,                                                     // Numpad Subtract
    T4B | KBDNUMPAD | KBDSPECIAL,   // Numpad 4 (Left),
    T4C | KBDNUMPAD | KBDSPECIAL,   // Numpad 5 (Clear),
    T4D | KBDNUMPAD | KBDSPECIAL,   // Numpad 6 (Right),
    T4E,                                                     // Numpad Add
    T4F | KBDNUMPAD | KBDSPECIAL,   // Numpad 1 (End),
    T50 | KBDNUMPAD | KBDSPECIAL,   // Numpad 2 (Down),
    T51 | KBDNUMPAD | KBDSPECIAL,   // Numpad 3 (PgDn),
    T52 | KBDNUMPAD | KBDSPECIAL,   // Numpad 0 (Ins),
    T53 | KBDNUMPAD | KBDSPECIAL,   // Numpad . (Del),

    T54, T55, T56, T57,
    T58, T59, T5A, T5B, T5C, T5D, T5E, T5F,
    T60, T61, T62, T63, T64, T65, T66, T67,
    T68, T69, T6A, T6B, T6C, T6D, T6E, T6F,
    T70, T71, T72, T73, T74, T75, T76, T77,
    T78, T79, T7A, T7B, T7C, T7D, T7E, T7F
EOD

$init_auxVK =~ s(//.*)()g;
my $CC;  $CC++ while $init_auxVK =~ /,/g;
$REPL{init_auxVK_c} = 1 + $CC;

#################################### ATTRIBUTES
my @AA = grep $_ ne 'NOALTGR', split /\s+/, $IN{ATTRIBUTES};
push @AA, 'ALTGR'  if $IN{ATTRIBUTES} !~ /\b(NO)?ALTGR\b/ and $maxbitmap > 3;
$REPL{use_KLLFlags} = 'KLLF_' . join(' | KLLF_', @AA) || 0;

#################################### Do actual emit with substitutions
my $rxrepl = join '|', keys %REPL;

warn "Undefined replacement fields: ", join ' ', grep !defined $REPL{$_}, keys %REPL;

my $data = do {local $/, <DATA>};
$data =~ s/^__END__\s*(?:$).*//sm;
$data =~ s/\@{3}($rxrepl)\@{3}/$REPL{$1}/g;
/\@{3}(\w+)\@{3}/ and warn "unrecognized replacement $1 in <<<$_>>>" for split /\n/m , $data;

($data, my @more) = split /^__DATA__\s*?\n/m , $data;
my @ext = qw(.def .rc _extern.h _extra.c);

print $data;

while (@more) {
  my($D, $ext) = (shift @more, shift @ext);
  my $enc = ($ext =~ /\.rc$/i ? ':raw:encoding(UTF-16LE):crlf' : '');	# other files are 7-bit
  warn("Won't overwrite existing file $name$ext"), next if -e "$name$ext";

  open my $out, ">$enc", "$name$ext" or die "Cannot open  $name$ext for write: $! / $^E";
  print $out $D;
  close $out                      or die "Cannot close $name$ext for write: $! / $^E";
}

sub get_scancodes { return qw(
  00	_none_
  01	ESCAPE
  02	1
  03	2
  04	3
  05	4
  06	5
  07	6
  08	7
  09	8
  0A	9
  0B	0
  0C	OEM_MINUS
  0D	OEM_PLUS
  0E	BACK
  0F	TAB
  10	Q
  11	W
  12	E
  13	R
  14	T
  15	Y
  16	U
  17	I
  18	O
  19	P
  1A	OEM_4
  1B	OEM_6
  1C	RETURN
  1D	LCONTROL
  1E	A
  1F	S
  20	D
  21	F
  22	G
  23	H
  24	J
  25	K
  26	L
  27	OEM_1
  28	OEM_7
  29	OEM_3
  2A	LSHIFT
  2B	OEM_5
  2C	Z
  2D	X
  2E	C
  2F	V
  30	B
  31	N
  32	M
  33	OEM_COMMA
  34	OEM_PERIOD
  35	OEM_2
  36	RSHIFT
  37	MULTIPLY
  38	LMENU
  39	SPACE
  3A	CAPITAL
  3B	F1
  3C	F2
  3D	F3
  3E	F4
  3F	F5
  40	F6
  41	F7
  42	F8
  43	F9
  44	F10
  45	NUMLOCK
  46	SCROLL
  47	HOME
  48	UP
  49	PRIOR
  4A	SUBTRACT
  4B	LEFT
  4C	CLEAR
  4D	RIGHT
  4E	ADD
  4F	END
  50	DOWN
  51	NEXT
  52	INSERT
  53	DELETE
  54	SNAPSHOT
  55	_none_
  56	OEM_102
  57	F11
  58	F12
  59	CLEAR
  5A	OEM_WSCTRL
  5B	OEM_FINISH
  5C	OEM_JUMP
  5D	EREOF
  5E	OEM_BACKTAB
  5F	OEM_AUTO
  60	_none_
  61	_none_
  62	ZOOM
  63	HELP
  64	F13
  65	F14
  66	F15
  67	F16
  68	F17
  69	F18
  6A	F19
  6B	F20
  6C	F21
  6D	F22
  6E	F23
  6F	OEM_PA3
  70	_none_
  71	OEM_RESET
  72	_none_
  73	ABNT_C1
  74	_none_
  75	_none_
  76	F24
  77	_none_
  78	_none_
  79	_none_
  7A	_none_
  7B	OEM_PA1
  7C	TAB
  7D	_none_
  7E	ABNT_C2
  7F	OEM_PA2

  E010	MEDIA_PREV_TRACK
  E019	MEDIA_NEXT_TRACK
  E01C	RETURN
  E01D	RCONTROL
  E020	VOLUME_MUTE
  E021	LAUNCH_APP2
  E022	MEDIA_PLAY_PAUSE
  E024	MEDIA_STOP
  E02E	VOLUME_DOWN
  E030	VOLUME_UP
  E032	BROWSER_HOME
  E035	DIVIDE
  E037	SNAPSHOT
  E038	RMENU
  E046	CANCEL
  E047	HOME
  E048	UP
  E049	PRIOR
  E04B	LEFT
  E04D	RIGHT
  E04F	END
  E050	DOWN
  E051	NEXT
  E052	INSERT
  E053	DELETE
  E05B	LWIN
  E05C	RWIN
  E05D	APPS
  E05E	POWER
  E05F	SLEEP
  E065	BROWSER_SEARCH
  E066	BROWSER_FAVORITES
  E067	BROWSER_REFRESH
  E068	BROWSER_STOP
  E069	BROWSER_FORWARD
  E06A	BROWSER_BACK
  E06B	LAUNCH_APP1
  E06C	LAUNCH_MAIL
  E06D	LAUNCH_MEDIA_SELECT

  E11D	PAUSE
) }	# predefined Type 4 bindings (from the first chunk of kbd.h up to Y1D)
	# perl -wlane "%b = (T => '', X => 'e0', Y => 'e1'); /#define ([TXY])(\w\w)\b/ or next; ($sc,$pr)=($2,$b{$1}); @F = split /,\s*/ unless /\b_EQ\(/; ($i=$F[3]) =~ s/['']//g; $i||=q(SPACE); print qq(  $pr$sc\t$i); last if /\bY1D\b/" kbd.h 
			# There is no conflict in resolving the following X-bindings:
#    X33 => 'OEM_8',								# type 7:       Japanese IBM type 002 keyboard
#    X3D => 'F13',  X3E => 'F14', X3F => 'F15', X40 => 'F16', X41 => 'F17',	# types 40/41:	DEC LK411-JJ/AJ (JIS/ANSI  layout) keyboards
#    X42 => 'RCONTROL',  X43 => 'RMENU',					# type 34:	NEC PC-9800 for Hydra: PC-9800 Keyboard (WinNT 3.5/4)
#    X60 => 'SCROLL',  X61 => 'HOME', X62 => 'END', X71 => 'DBE_SBCSCHAR',	# type 20/21:	Fujitsu FMR JIS/OYAYUBI keyboards
#    XF1 => 'HANJA',  XF2 => 'HANGEUL',						# types 10-13:	Korean 101 (type A/B/C) / 103 keyboards
#    T00 => 'ESCAPE',								# type 37:	NEC PC-9800 for Hydra: PC-9800 Keyboard (Win95)
#    T55 => 'CAPITAL',	# conflicts with OEM_8 F14		DOWN` on KB3270
#    T60 => 'F4',	# conflicts with CANCEL
#    T61 => 'F5',	# conflicts with ZOOM SNAPSHOT
#    T70 => 'NEXT',	# conflicts with DBE_KATAKANA DBE_HIRAGANA KANA LSHIFT
#    T72 => 'CANCEL',	# conflicts with KANA
#    T74 => 'F13',	# conflicts with LCONTROL OEM_NEC_EQUAL
#    T75 => 'F14',	# conflicts with SEPARATOR		RETURN on KB3270
#    T77 => 'F16',	# conflicts with DBE_SBCSCHAR LWIN	HOME on KB3270
#    T78 => 'CLEAR',	# conflicts with RWIN			UP on KB3270
#    T79 => 'CONVERT',	# conflicts with HELP APPS		DELETE on KB3270
#    T7A => 'END',	# conflicts with 			INSERT on KB3270
#    T7D => 'OEM_5',	# conflicts with SNAPSHOT RSHIFT	RIGHT on KB3270

__DATA__
/***************************************************************************\
* Module Name: @@@mod_name@@@.C
*
* Windows keyboard layout auto-translated from .klc to C
*   (Edit only after renaming: this filename may be overwritten!)
*
* Translation Copyright (c) 2024 Ilya Zakharevich, via @@@myversion@@@
*
* License: (c) When the preceding "Translation" line is preserved, this file may be used
*      under the license covering the original .klc file.
*
* The .klc file: @@@copyright@@@
*
* History:
*
* @@@myversion@@@ - created this file on @@@mydate@@@
*
\***************************************************************************/

// Some scanners of keyboard fail if the main table is not near the start of the loaded DLL.
// To move it forward, we need to make the data extern:
#include "@@@mod_name@@@_extern.h"

/***************************************************************************\
* ausVK[virtual_scancode] is the Virtual_Key | Special_Flags.
*    For gory details see: https://bsakatu.net/doc/virtual-key-of-windows/  (and references there)
\***************************************************************************/

ALLOC_SECTION_LDATA USHORT ausVK[] = {  // This just lists macros T00 .. T7E in order (but with suitable flags).  Redefine macros elsewhere
@@@init_auxVK@@@};

// The scancodes arriving from driver with HIGHBYTE=0xE0 are searched by scanning this table:  Redefine macros Xnn elsewhere
ALLOC_SECTION_LDATA VSC_VK aE0VscToVk[] = {
        { 0x1C, X1C | KBDEXT              },  // Numpad Enter
        { 0x1D, X1D | KBDEXT              },  // RControl

        { 0x35, X35 | KBDEXT              },  // Numpad Divide
        { 0x37, X37 | KBDEXT              },  // Snapshot (PrtScr)
        { 0x38, X38 | KBDEXT              },  // RMenu
        { 0x46, X46 | KBDEXT              },  // Break (Ctrl + Pause)
        { 0x47, X47 | KBDEXT              },  // Home
        { 0x48, X48 | KBDEXT              },  // Up
        { 0x49, X49 | KBDEXT              },  // Prior
        { 0x4B, X4B | KBDEXT              },  // Left
        { 0x4D, X4D | KBDEXT              },  // Right
        { 0x4F, X4F | KBDEXT              },  // End
        { 0x50, X50 | KBDEXT              },  // Down
        { 0x51, X51 | KBDEXT              },  // Next
        { 0x52, X52 | KBDEXT              },  // Insert
        { 0x53, X53 | KBDEXT              },  // Delete
        { 0x5B, X5B | KBDEXT              },  // Left Win
        { 0x5C, X5C | KBDEXT              },  // Right Win
        { 0x5D, X5D | KBDEXT              },  // Application

        { 0x5E, X5E | KBDEXT              },  // Power [ XXXX !!! VK_POWER not defined in the Microsoft's headers !!! ??? ']

        { 0x10, X10 | KBDEXT              },  // Speedracer: Previous Track
        { 0x19, X19 | KBDEXT              },  // Speedracer: Next Track

        { 0x20, X20 | KBDEXT              },  // Speedracer: Volume Mute
        { 0x21, X21 | KBDEXT              },  // Speedracer: Launch App 2
        { 0x22, X22 | KBDEXT              },  // Speedracer: Media Play/Pause
        { 0x24, X24 | KBDEXT              },  // Speedracer: Media Stop
        { 0x2E, X2E | KBDEXT              },  // Speedracer: Volume Down
        { 0x30, X30 | KBDEXT              },  // Speedracer: Volume Up
        { 0x32, X32 | KBDEXT              },  // Speedracer: Browser Home

        { 0x5F, X5F | KBDEXT              },  // Speedracer: Sleep
        { 0x65, X65 | KBDEXT              },  // Speedracer: Browser Search
        { 0x66, X66 | KBDEXT              },  // Speedracer: Browser Favorites
        { 0x67, X67 | KBDEXT              },  // Speedracer: Browser Refresh
        { 0x68, X68 | KBDEXT              },  // Speedracer: Browser Stop
        { 0x69, X69 | KBDEXT              },  // Speedracer: Browser Forward
        { 0x6A, X6A | KBDEXT              },  // Speedracer: Browser Back
        { 0x6B, X6B | KBDEXT              },  // Speedracer: Launch App 1
        { 0x6C, X6C | KBDEXT              },  // Speedracer: Launch Mail
        { 0x6D, X6D | KBDEXT              },  // Speedracer: Launch Media Selector
@@@addX_scancodes@@@        { 0,      0                       }
};

// The scancodes arriving from driver with HIGHBYTE=0xE1 are searched by scanning this table:
ALLOC_SECTION_LDATA VSC_VK aE1VscToVk[] = {
        { 0x1D, Y1D                       },  // Pause
@@@addY_scancodes@@@        { 0   ,   0                       }
};

/***************************************************************************\
* aVkToBits[]  - this table is scanned to map Virtual Keys of Modifier Keys to Modifier Bits
*
* See kbd.h for a full description.
*
* The simplest keyboards may use only three shifter bits:
*     0x1=KBDSHIFT   generated by SHIFT (L & R); traditionally affects alphabnumeric keys,
*     0x2=KBDCONTROL generated by CTRL  (L & R); is traditionally used to generate control characters
*     0x4=KBDALT     generated by ALT   (L & R); traditionally used for accelerators (or with numpad to enter decimal/hex codes of characters)
* Up to 16 bits may be used; the bitmaps assigned to the modifier keys are OR-combined; the result is indexed in CharModifiers
\***************************************************************************/

@@@pre_column_descr@@@
static ALLOC_SECTION_LDATA VK_TO_BIT aVkToBits[] = {
  /* SHIFT, CONTROL and MENU may appear only when an application creates a configuration of keys for ToUnicode() ``by hand'';
     otherwise the chiral L/R variants are used (which are going to be translated to non-chiral flavor if the chiral is not
     in the list below.

     In typical layouts, when producing characters, CONTROL may be combined with MENU and LMENU;
     with KLLF_ALTGR: RMENU is always combined with (fake) LCONTROL; this gives A+C flags (possibly combined with Shift).

     The kernel can do a certain automatic translation of VK_codes to Control-chars; but often, one also includes columns below
     for lone Control (or Control+Shift).

     One can freely choose to which configuration columns to resolve these combinations in the CharModifiers table. */
@@@modifiers@@@    { 0           ,   0           }
};

/***************************************************************************\
* aModification[]  - maps (combined) character modifier bitmaps to modification number: the ordinal of the column in subtables
* of aVkToWcharTable below.
*
* See kbd.h for a full description.
*
\***************************************************************************/

ALLOC_SECTION_LDATA MODIFIERS CharModifiers = {
    &aVkToBits[0],
    @@@num_column_descr@@@,
    {
    // Modification Num	// ORed bitmap for pressed modifiers
    // ================	// =================================
@@@column_descr@@@    }
};

/***************************************************************************\
*
* aVkToWch2[]  - Virtual Key to WCHAR translation for VK codes with 2 shift states
* aVkToWch3[]  - Virtual Key to WCHAR translation for VK codes with 3 shift states
*   ...
*
* The order of scanning these subtable is defined in aVkToWcharTable.  The VK codes are scanned by lookup in this null-terminated table.
* The result gives WCHAR characters for different “useful” combinations of modifiers.
*
* By convention, a row with dead chars for the previous row is started with VK-code 0xff.
*
* Special values for Attributes (column 2)
*     CAPLOK bit      - CAPS-LOCK affect the columns for bitmaps 0 and 1 (KBDSHIFT) like flipping SHIFT
*     CAPLOKALTGR bit - Same for the case when both KBDALT and KBDCONTROL bits set in the bitmap.
*
* Special values for the output characters:
*     WCH_NONE      - No character
*     WCH_DEAD      - Dead Key (prefix key); the next line has the id of this deadkey (in the same column).
*     WCH_LGTR      - Ligature (generates 1 or more codepoints).  This_VK + modifiers_position_id
*                     should be looked up in the ligature table below.
*
\***************************************************************************/

@@@extralendefs@@@

@@@sublayouts@@@

ALLOC_SECTION_LDATA VK_TO_WCHAR_TABLE aVkToWcharTable[] = {
@@@join_sublayouts@@@    {                       NULL, 0, 0                    },
};

/***************************************************************************\
* aKeyNames[], aKeyNamesExt[]  - Virtual Scancode to Key Name tables (null-terminated)
*
* Only the names of Extended, NumPad, Dead and Non-Printable keys are here.
* (Keys producing printable characters are named by that character)
\***************************************************************************/

@@@KEYNAME@@@
@@@KEYNAME_EXT@@@
@@@KEYNAME_DEAD@@@
@@@deadkeys@@@
@@@ligatures@@@

PKBDTABLES KbdLayerDescriptor(VOID)
{
    return &KbdTables;
}
__DATA__

LIBRARY @@@mod_name@@@
 
 EXPORTS 
    KbdLayerDescriptor @1

__DATA__

#include "winver.h"
#include "winnt.h"

1 VERSIONINFO
 FILEVERSION       @@@version1@@@,@@@version2@@@,3,40
 PRODUCTVERSION    @@@version1@@@,@@@version2@@@,3,40
 FILEFLAGSMASK 0x3fL
 FILEFLAGS 0x0L
FILEOS 0x40004L
 FILETYPE VFT_DLL
 FILESUBTYPE VFT2_DRV_KEYBOARD
BEGIN
   BLOCK "StringFileInfo"
   BEGIN
       BLOCK "000004B0"    // VER_VERSION_UNICODE_LANG: LANG_NEUTRAL/SUBLANG_NEUTRAL, Unicode CP
       BEGIN
           VALUE "CompanyName",     "@@@q_company@@@\0"
           VALUE "FileDescription", "@@@q_mod_descr@@@\0"
           VALUE "FileVersion",     "@@@version1@@@, @@@version2@@@, 3, 40\0"
           VALUE "InternalName",    "@@@mod_name@@@ (3.40)\0"
           VALUE "ProductName","Created by @@@myversion@@@\0"
           VALUE "Release Information","Created by @@@myversion@@@\0"
           VALUE "LegalCopyright",  "@@@q_copyright@@@\0"
           VALUE "OriginalFilename","@@@mod_name@@@\0"
           VALUE "ProductVersion",  "@@@version1@@@, @@@version2@@@, 3, 40\0"
       END
   END
   BLOCK "VarFileInfo"
   BEGIN
       VALUE "Translation", 0x0000, 0x04B0  // As VER_VERSION_UNICODE_LANG
   END
END

STRINGTABLE DISCARDABLE
LANGUAGE LANG_ENGLISH, SUBLANG_DEFAULT
BEGIN
    1200    "@@@q_localename@@@"
END


STRINGTABLE DISCARDABLE
LANGUAGE @@@LANG_MACRO@@@, SUBLANG_DEFAULT
BEGIN
    1000    "@@@q_mod_descr@@@\0"
END


STRINGTABLE DISCARDABLE
LANGUAGE @@@LANG_MACRO@@@, SUBLANG_DEFAULT
BEGIN
    1100    "@@@Language@@@ (@@@Country@@@)"
END

__DATA__
/***************************************************************************\
* Module Name: header file for @@@mod_name@@@.C
*
* Windows keyboard layout auto-translated from .klc to C
*   (Edit only after renaming: this filename may be overwritten!)
*
* Translation Copyright (c) 2024 Ilya Zakharevich: @@@myversion@@@
*
* License: (c) When the preceding "Translation" line is preserved, this file may be used
*      under the license covering the original .klc file.
*
* The .klc file: @@@copyright@@@
*
* History:
*
* @@@myversion@@@ - created this file on @@@mydate@@@
*
\***************************************************************************/

#define KBD_TYPE 4	// 101-key keyboard

#include <windows.h>
#include "kbd.h"

#if !defined(VK_POWER)	// Not defined in KSKLC, but is used in X5E; from https://pub.freerdp.com/api/winpr_2include_2winpr_2input_8h.html
#  define 	VK_POWER   0x5E /* Power key */
#endif			//            But do not they confuse it with the scancod???


#if defined(_M_IA64)
#pragma section(".data")
#define ALLOC_SECTION_LDATA __declspec(allocate(".data"))
#else
#pragma data_seg(".data")
#define ALLOC_SECTION_LDATA
#endif

@@@ligature_decl@@@
extern ALLOC_SECTION_LDATA USHORT ausVK[];
extern ALLOC_SECTION_LDATA VSC_VK aE0VscToVk[];
extern ALLOC_SECTION_LDATA VSC_VK aE1VscToVk[];
extern ALLOC_SECTION_LDATA MODIFIERS CharModifiers;
extern ALLOC_SECTION_LDATA VK_TO_WCHAR_TABLE aVkToWcharTable[];
extern ALLOC_SECTION_LDATA VSC_LPWSTR aKeyNames[];
extern ALLOC_SECTION_LDATA VSC_LPWSTR aKeyNamesExt[];
extern ALLOC_SECTION_LDATA DEADKEY_LPWSTR aKeyNamesDead[];
extern ALLOC_SECTION_LDATA DEADKEY aDeadKey[];
extern ALLOC_SECTION_LDATA KBDTABLES KbdTables;

@@@null_secs@@@
@@@fix_scancodes@@@ 

__DATA__
/***************************************************************************\
* Module Name: companion C file for @@@mod_name@@@.C
*
* Windows keyboard layout auto-translated from .klc to C
*   (Edit only after renaming: this filename may be overwritten!)
*
* Copyright (c) 2024 Ilya Zakharevich: @@@myversion@@@
*
* License: (c) When the preceding copyright line is preserved, this file may be
* used under the same license as Perl itself.
*
* History:
*
* @@@myversion@@@ - created this file on @@@mydate@@@
*
\***************************************************************************/

#include "@@@mod_name@@@_extern.h"

ALLOC_SECTION_LDATA KBDTABLES KbdTables = {
    /*
     * Modifier keys
     */
    &CharModifiers,

    /*
     * Characters tables
     */
    aVkToWcharTable,

    /*
     * Diacritics
     */
    aDeadKey,

    /*
     * Names of Keys
     */
    aKeyNames,
    aKeyNamesExt,
    aKeyNamesDead,

    /*
     * Scan codes to Virtual Keys
     */
    ausVK,
    @@@init_auxVK_c@@@,
    aE0VscToVk,
    aE1VscToVk,

    /*
     * Locale-specific special processing
     */
    MAKELONG(@@@use_KLLFlags@@@, KBD_VERSION),

    /*
     * Ligatures
     */
    @@@ligature_width@@@,
    @@@ligature_sizeof@@@,
    (PLIGATURE1)aLigature@@@ligature_width@@@
};

__END__
