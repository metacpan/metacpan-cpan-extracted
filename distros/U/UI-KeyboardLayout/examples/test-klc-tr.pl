#!/usr/bin/perl -w
use strict;

sub format_ochar_c ($) {
  my($C, $c) = shift;
  map {		   /\@$/  and 'WCH_DEAD'
  		or /^-1$/ and 'WCH_NONE'
  		or /^%%$/ and 'WCH_LGTR'
		or ($c = $_) =~ s/^([0-9A-Z])$/'$1'/i and $c
		or ($c = chr hex) =~ /[\\'']/ and "'\\$c'"
		or ($c = chr hex) =~ /[\x20-\x7e]/ and "'$c'"
		or "0x$_"
      } $C;
}

sub format_key_line_c ($$@) {
  my($vk, $F, @B) = @_;
# sprintf "  {%-13s,%-7s,%s},\n", $vk, $F, join ',', map {sprintf '%-9s', $_} @B;
  sprintf "  {%-13s,%-20s,%s},\n", $vk, $F, join ',', map {sprintf '%-9s', $_} @B;
}

my %CL_flags = (qw(0 0 1 CAPLOK 4 CAPLOKALTGR SGCap SGCAPS), 5 => 'CAPLOK | CAPLOKALTGR');
sub translate_key_line_c($$$$) {
  my($prev_vk, $b_len, $in, $LIG) = (shift, shift, shift, shift);
  $in =~ s(\s+//.*)();
  $in =~ s(^\s+)();
  my($scan, $vk, $flags, @bind, @prefix, $c, $neg1, @O, @LIG) = split /\s+/, $in;
  push @bind, ('-1') x ($b_len - @bind)	if $b_len > @bind;
  $#bind = $b_len - 1			if $b_len < @bind;
  @prefix = @bind if grep /\@$/, @bind;
  $_ eq '-1' and $neg1++ for $scan, $vk;
  die "VK=$vk in combination with SC=$scan (I expect -1 -1)" if 1 == ($neg1 || 0);
  $vk =~ s/^([0-9A-Z])$/'$1'/ or $vk = "VK_$vk";
  if ($vk eq 'VK_-1') {
#    $flags eq 'SGCap' or die "non-SGCap line with VK=-1";
    defined ($vk = $$prev_vk) or die "SGCap continuation line not preceded by SGCap line";
    $$prev_vk = undef;
    $#bind = 1 if $#bind > 1;
    $#bind = 0 if '-1' eq ($bind[1] || '-1');
  } else {
    $$prev_vk = ($flags eq 'SGCap' ? $vk : undef);
  }
  defined (my $F = $CL_flags{$flags}) or die "Unexpected value in FLAGS: <$flags> in: $in";
  @$LIG = ($vk, grep {$bind[$_] =~ /%%/} 0..$#bind);
  push @O, format_key_line_c $vk, $F, map format_ochar_c($_), @bind;
  s/\@$// or $_ = -1 for @prefix;
  push @O, format_key_line_c '0xff', 0, map format_ochar_c($_), @prefix if @prefix;
  @O
}

sub extract_section ($$;$) {
  my($in, $sec, $strip) = (shift, shift, shift);
  $in =~ s([^\S\n]*//.*)()g;		# remove comments
  $in =~ s([^\S\n]+$)()gm;		# remove trailing whitespace (including \r!)
  $in =~ s/\A.*?^\s*$sec([ \t]*;[^\n]*)?\n//sm or die "Cannot find LAYOUT inside the KLC file";
  $in =~ s/^[^\S\n]*(KEYNAME|LIGATURE|COPYRIGHT|COMPANY|LOCALENAME|LOCALEID|VERSION|SHIFTSTATE|LAYOUT|ATTRIBUTES|KEYNAME_EXT|KEYNAME_DEAD|DESCRIPTIONS|LANGUAGENAMES|ENDKBD)\b.*//ms
     or die "Cannot find end of LAYOUT inside the KLC file";
  $in =~ s/^\n//gm if $strip;			# remove emtpy lines
  $in
}

sub fix_liga ($$) {
  my($in, $LIGS, %idx) = (shift, shift);
  my @in = split /(?<=,)(?=\s*\{)/, $in;
  my $z = pop @in;
  for my $l (@in) {
    my($vk, $i) = ($l =~ /^\s*\{\s*(\S+)\s*,\s*(\d+)\s*,/) or die "Unrecognized LIGATURE: <<$l>>";
    my $LIGs = $LIGS->{$vk} or die "Can't find WCH_LGTRs for <$vk>";
    defined (my $LIG = $LIGs->[$idx{$vk}++ || 0]) or die "Too many LIGATURES for <$vk>: I see $idx{$vk}; command line argument too low?";
    my $exp = substr $LIG, 0, 1;
    $i == $LIG or $i == $exp or die "Unexpectedly broken LIGATURE for <$vk>: see $i, expect $exp or $LIG (in [@$LIGs])";
    $l =~ s/^(\s*\{\s*\S+\s*,\s*)(\d+)\b/$1$LIG/ or die "Panic in s///???";
  }
  join '', @in, $z
}

sub format_modifiers ($) {
  my ($in, @bits, @out) = (shift, qw(Shift Ctrl Alt Kana Roya Loya Z T));
  push @out, (($in & (1<<$_)) ? $bits[$_] : '') for 0..$#bits;
  (my $O = join "\t", @out) =~ s/\t+$//;
  $O;
}

sub produce_masks (@) {
  my(@masks, @OUT) = @_;
  $OUT[$masks[$_]] = $_ for 0..$#masks;
  defined and $_ != 15 or $_ = 'SHFT_INVALID' for @OUT;
  <<EOP
    $#OUT,
    {
    //  Modification# // ORed bitmap for pressed modifiers
    //  ============= // =================================
EOP
    . join( '', map { sprintf "\t%-14s// %s\n", "$OUT[$_],", format_modifiers $_ } 0..$#OUT )
    . <<EOP;
    }
EOP
}

if (@ARGV == 1) {
  my $b_len = shift;
  my $layout = do {local $/; <>};
  $layout = extract_section $layout, 'LAYOUT', 'strip';
  my($prev_vk, @LIG);
  for my $in (split /\n/, $layout) {
    print for translate_key_line_c \$prev_vk, $b_len, $in, \@LIG;
  }
  exit;
}

my @prev_len = (8, 1);
if (@ARGV == 4) {
  my($src_klc, $src_c, @b_len) = (shift, shift, shift, shift);
  @ARGV = $src_klc;
  my $klc = do {local $/; <>};
  @ARGV = $src_c;
  my $c_file = do {local $/; <>};
  my $layout = extract_section $klc, 'LAYOUT', 'strip';
  my (@pass_table, $prev_vk, $skip_m1, %LIG) = ('', '');
#  for my $pass (0, 1) {
    for my $in (split /\n/, $layout) {
      my ($vk) = ($in =~ /^\s*\S+\s+(\S+)\b/);
      $skip_m1 = 1, next if $vk =~ /^(ABNT_C2|OEM_8|SPACE)$/;			# In len=6 section
      $skip_m1 = 0, next if $skip_m1 and $in =~ /^\s*-1\s+-1\b/;
      $skip_m1 = 0;
      my $pass = ($vk =~ /^((F|NUMPAD)\d+|HOME|UP|PRIOR|DIVIDE|LEFT|CLEAR|RIGHT|MULTIPLY|END|DOWN|NEXT|SUBTRACT|INSERT|DECIMAL|DELETE|ADD|RETURN)$/);
      $pass_table[$pass] .= join '', translate_key_line_c \$prev_vk, $b_len[$pass], $in, \my @LIG;
      my $VK = shift @LIG;
      $LIG{$VK} = \@LIG;
#warn "DECIMAL --> [@LIG] for: $in" if $VK eq 'VK_DECIMAL';
    }
#  }
  my $extra_sizes = join "\n", '', map "TYPEDEF_VK_TO_WCHARS($_) // VK_TO_WCHARS$_, *PVK_TO_WCHARS$_;", grep $_>10, @b_len;
  $c_file =~ s/(\A.*^\s*#\s*include\s+[^\n]+)/$1\n\n$extra_sizes/ms if $extra_sizes;
  for my $p (0, 1) {
    my $s = $prev_len[$p];
    my $S = $b_len[$p];
    $c_file =~ s((\s*static\s+ALLOC_SECTION_LDATA\s+VK_TO_WCHARS)$s(\s+aVkToWch)$s(\s*\[\s*\]\s*=\s*\{[ \t]*(?:\n\s*//[^\n]*)*).*?(?=[ \t]*\{\s*0\s*,))
    		($1$S$2$S$3\n$pass_table[$p])s;
    $c_file =~ s<(\{\s*\(\s*PVK_TO_WCHARS1\s*\)\s*aVkToWch)$s(\s*,\s*)$s(\s*,\s*sizeof\s*\(\s*aVkToWch)$s(\s*\[\s*0\s*\]\s*\)\s*\}\s*,)>
#    $c_file =~ s<(\{\s*\(\s*PVK_TO_WCHARS1\s*\)\s*aVkToWch)$s(\s*,\s*)$s(\s*,\s*sizeof\s*\(\s*aVkToWch)$s>
    		($1$S$2$S$3$S$4)s;	#    {  (PVK_TO_WCHARS1)aVkToWch2, 2, sizeof(aVkToWch2[0]) },
  }
  $c_file =~ s/(\baLigature\s*\[\s*\]\s*=\s*\{\s*)(.*?)(?=\s*\}\s*;)/ $1 . fix_liga $2, \%LIG /se
    or $c_file !~ /\baLigature\b/ or die "Can't find LIGATURE table definition";

  my $masks = extract_section $klc, 'SHIFTSTATE', 'strip';	# Semantic of empty lines unclear; for now, ignore
  my @masks = map {/^\s*(\d+)/ and $1} split /\n/, $masks;
  my $Omasks = produce_masks @masks;
  $c_file =~ s/(&aVkToBits\s*\[\s*0\s*\]\s*,[ \t]*\n).*?^\s+\}[ \t]*\n/$1$Omasks/ms
    or $c_file !~ /\baLigature\b/ or die "Can't find CharModifiers table definition";

  print $c_file;
}
exit;

my($IN, $OUT) = <DATA>;
my $b_len = 8;
my $prev_vk;
for my $in ($IN) {
  my @O = translate_key_line_c \$prev_vk, $b_len, $in, \my %fake;
  warn "$OUT" unless $O[0] eq $OUT;
  print for @O;
}
__DATA__
11	W		5	w	W	0017	0017	00e1	00c1	03c9	03a9	0432	0412	05e9	fb2a	// w, W, ^W, ^W, á, Á, ?, O, ?, ?, ?, ?	// LATIN SMALL LETTER W, LATIN CAPITAL LETTER W, <control>, <control>, LATIN SMALL LETTER A WITH ACUTE, LATIN CAPITAL LETTER A WITH ACUTE, GREEK SMALL LETTER OMEGA, GREEK CAPITAL LETTER OMEGA, CYRILLIC SMALL LETTER VE, CYRILLIC CAPITAL LETTER VE, HEBREW LETTER SHIN, HEBREW LETTER SHIN WITH SHIN DOT
  {'W'          ,CAPLOK | CAPLOKALTGR,'w'      ,'W'      ,0x0017   ,0x0017   ,0x00e1   ,0x00c1   ,0x03c9   ,0x03a9   },
