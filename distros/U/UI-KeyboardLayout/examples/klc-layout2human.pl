#!/usr/bin/perl -w
use strict;

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

my $endRx = qr/^[^\S\n]*(?:KEYNAME|LIGATURE|COPYRIGHT|COMPANY|LOCALENAME|LOCALEID|VERSION|SHIFTSTATE|LAYOUT|ATTRIBUTES|MODIFIERS|KEYNAME_EXT|KEYNAME_DEAD|DESCRIPTIONS|LANGUAGENAMES|DEADKEY|ENDKBD)\b/m;

sub extract_section ($$;$) {	# may return what remains
  my($in, $sec, $strip, $rest) = (shift, shift, shift);
  $in =~ s/(\A.*?)^\s*$sec([ \t]*;[^\n]*)?\n//sm or die "Cannot find $sec inside the KLC file";
  $rest = $1;
  $in =~ s/($endRx.*)//s or die "Cannot find end of $sec inside the KLC file";
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

############################# Scan Ligatures
my($lig, $w, @lig) = ('', 1);			# Making it LIGATURE1 allows empty LIGATURE section without a special logic
if (exists $IN{LIGATURE}) {{
  for my $l (split /\n/m , $IN{LIGATURE}) {
    $l =~ s/^\s+//;
    my ($vk, $col, @c) = split /\s+/, $l;
    $w = @c if $w < @c;
    push @lig, [$vk, $col, @c]
  }
}}
############################# Humanize

require 5.032; # does not work with 5.008
sub utf16to8($) {(my $in = shift) =~ s/([\x{d800}-\x{dbff}])([\x{dc00}-\x{dfff}])/ chr( 0x10000+((ord($1)-0xd800)<<10) + (ord($2)-0xdc00) ) /ge; $in}	# warn(ord($1),'|',ord($2),'=',((ord($1)-0xd800)<<10) + (ord($2)-0xdc00)), 

my %lig;
$lig{"$_->[0]:$_->[1]"} = utf16to8(join '', map chr hex, @$_[2..$#$_]) for @lig;

my $ln = 0;
for my $l (split /\n/, $IN) {
  print("$l\n"), next unless ( ($l =~ /^\s*LAYOUT\b/) ... ($l =~ /$endRx/ ) ) and $ln++; # do not process the LAYOUT line
  my($lead, $in, $comm) = ($l =~ m{^(\s*)(.*?)((?://.*)?$)}) or die "Panic";
  my(@in) = split /(\s+)/, $in;
  my($col2, $vk, $oo) = 0;
  for (@in) {
    $col2++;			# even on whitespace
    $vk = $_ if $col2 == 3;
    next unless /\S/ and $col2 > 6 and not /^(-1|[\x21-\x7e])$/;
    next if /^(00[01].|0020|d[89a-f]|[\da-f]{4}\@|034f|200[c-f])$/i;	# Combining Grapheme Joiner (CGJ), ZERO WIDTH (NON-)JOINER, L2R/R2L-marks)
    $oo = $_;
    if (s/^([\da-f]{4})$/q( ).chr(hex $1).q( )/egi) {	# convert HEX to chars
      $_ = "\x{25cc}" . chr(hex $oo) . "=$oo" if /\p{NonspacingMark}/;
      next unless /\P{XPosixPrint}/;			# does not seem to recognize 034f|200[c-f]  ???
      $_ = $oo;
    }
    warn "$_ in $l" unless /^%%$/;
    my $o = $lig{"$vk:". ($col2-7)/2};
    warn("A hanging ligature in col=",($col2-7)/2,"in $l"), next unless defined $o;
#    next if $o =~ /(?!\s)\P{Graph}/;			# Visualizing it is not helpful
    next if $o =~ /\P{XPosixPrint}/;			# Visualizing it is not helpful (but this does not recognize 0-width)
    $o =~ s/^(.{6})..+/$1\x{2026}/;		# ellipsis
    if ($o =~ /^(-1|[\da-f]{4}\@?)$/i or $o =~ m(//|\s) or $o =~ s/^(?=\p{NonspacingMark})/\x{25cc}/) {	# Can confuse the parser or reader
      $o =~ s/^(.{4})..+/$1\x{2026}/;		# ellipsis
      $o =~ s/ /\x{2423}/g;
      $o =~ s/\s/\x{237d}/g;
      $o =~ s(//)(\x{2044}\x{2044})g;
      $o = "\x{27ec}$o\x{27ed}"
    }
    $_ = (7 == length $o or ' ') . $o;
  }
  print $lead, join('',@in),$comm,"\n";
}