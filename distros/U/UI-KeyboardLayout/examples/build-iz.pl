use UI::KeyboardLayout;
use strict;
use utf8;
my $home = $ENV{HOME} || '';
$home = "$ENV{HOMEDRIVE}$ENV{HOMEPATH}" if $ENV{HOMEDRIVE} and $ENV{HOMEPATH};
UI::KeyboardLayout::->set_NamesList(qq($home/Downloads/NamesList.txt),
				    qq($home/Downloads/DerivedAge.txt))
  if -r qq($home/Downloads/NamesList.txt)
  and -r qq($home/Downloads/DerivedAge.txt);
warn "No NamesList/DerivedAge file found" unless UI::KeyboardLayout::->get_NamesList;

my @CYG;
@CYG = grep $_, `cygpath -w /` if $^O =~ /MSWin/;
my @x11 = qw( /etc/X11 /usr/local/X11 /usr/share/local/X11 /usr/share/X11 );
my @X11 = grep -d, (@x11, map {my $in = $_; map "$_/$in", @CYG} @x11);

my($C) = grep -r, map "$_/locale/en_US.UTF-8/Compose", @X11;
$C = "$home/Downloads/Compose" unless $C and -r $C;
UI::KeyboardLayout::->set__value('ComposeFiles', [$C]) if -r $C;
warn "No Compose file found" unless UI::KeyboardLayout::->get__value('ComposeFiles');

my @H = ((map {my $in = $_; $in, map "$_/$in", @CYG} '/usr/include/X11'), (map "$_/include", @X11), "$home/Downloads");
my($H) = grep -r, map "$_/keysymdef.h", @H;
$H = "keysymdef.h" unless $H and -r $H;
UI::KeyboardLayout::->set__value('KeySyms', [$H]) if -r $H;
warn "No keysymdef.h file found in @H ." unless UI::KeyboardLayout::->get__value('KeySyms');

UI::KeyboardLayout::->set__value('EntityFiles', ["$home/Downloads/bycodes.html"]) if -r "$home/Downloads/bycodes.html";
warn "No Entity file found" unless UI::KeyboardLayout::->get__value('EntityFiles');	# http://www.w3.org/TR/xml-entity-names/bycodes.html

UI::KeyboardLayout::->set__value('rfc1345Files', ["$home/Downloads/rfc1345.html"]) if -r "$home/Downloads/rfc1345.html";
warn "No rfc1345 file found" unless UI::KeyboardLayout::->get__value('rfc1345Files');	# http://tools.ietf.org/html/rfc1345  

die "Usage: $0 KBDD_FILE\n" unless @ARGV == 1;
#  After running this, run build_here.cmd in a subdirectory...  (Minimal build instructions are in the file...)

my $l = UI::KeyboardLayout::->new_from_configfile(shift);

my $skip_dummy = -e 'dummy';
my($O, @add) = ('', <<'EOT', <<'EOT', <<'EOT', <<'EOT');
############# Latin Personality: Per key list (in UTF-8; double-prefix-key columns are in the table for Cyrillic personality):
	AltGr-'	AltGr-`	AltGr-^	AltGr-~	AltGr-.	AltGr-,	AltGr-6	AltGr--	AltGr-/	AltGr-"	AltGr-;	AltGr-$	2Shf-SPC Shf-SPC AltGr-SPC 2xAGr-SP 3xAGr-SP
EOT
############# Cyrillic Personality: Per key list: (with µ meaning AltGr-SPACE)
	AltGr-'	AltGr-^	AltGr-$	2Sft-SPC Sft-SPC AGr-SPC 2AGr-SPC  µ \	 µ [	 µ ]	 µ `
EOT
############# Greek Personality: Per key list:
	\	[	]	`	AltGr-$	Sft-SPC AGr-SPC 2AGr-SPC
EOT
############# Hebrew Personality: Per key list:
	AltGr-$	Sft-SPC AGr-SPC 2AGr-SPC
EOT

my @kbd = ([qw(ooo-us Latin)], [qw(ooo-ru CyrillicPhonetic)], [qw(ooo-gr GreekPoly)], [qw(ooo-hb Hebrew)]);
for my $kbd (map [@{$kbd[$_]}, $add[$_]], 0..$#kbd) {
  open my $kbdd, '>', $kbd->[0] or die;
  select $kbdd;
  print $l->fill_win_template(1, ['faces', $kbd->[1]]);
  my $o = $l->print_coverage($kbd->[1]);
  # print "### RX_comb: <<<", $l->rxCombining, ">>>\n";
  close $kbdd or die;
  
  $O .= "\n" if length $O;
  $O .= $kbd->[2] . $o;

#  $l->AppleMap_Base(['faces', $kbd->[1]]);
  open my $FF, '>', "iz-$kbd->[1].keylayout" or die "open: $!";
#  print $FF $l->AppleMap_i_j(['faces', $kbd->[1]], 1, 1, 1);	# AltGr-Shift with CapsLock
  print $FF $l->fill_osx_template(['faces', $kbd->[1]]);
  
  next if $skip_dummy;
  mkdir $_ for 'dummy', 'dummy2';
  my $idx = $l->get_deep($l, 'faces', $kbd->[1], 'MetaData_Index');
  my $n = $l->get_deep_via_parents($l, $idx, 'faces', $kbd->[1], 'DLLNAME');	# MSKLC would ignore the name otherwise???

  for my $dummy ('', '2') {
    open $kbdd, '> :raw:encoding(UTF-16LE):crlf', "dummy$dummy/$n.klc" or die;	# must force LE!  crlf is a complete mess!
    select $kbdd;
    print chr 0xfeff;							# Add BOM manually
    print $l->fill_win_template(1, ['faces', $kbd->[1]], 'dummy', $dummy);
    close $kbdd or die;
  }

}

$O =~ s/(?<=\S{7})\t(?![шщэ])/ /gi;	# All entries before шщэ are fixed by the following rule!
$O =~ s/\t(?=\S{8})/ /g;
$O =~ s/\t(?=⸣〃⸥⎖)/ /g;			# Last obstinate entry!
open F, '>', 'text-tables' or die;
print F $O;
close F or die;

select STDOUT;
for my $kbd (@kbd) {
  (my $o = $kbd->[1]) =~ s/(Poly|Phonetic)$//;
  open STDOUT, q(>), qq(coverage-1prefix-$o.html); 
  $l->print_table_coverage($kbd->[1], 'html', <<EOH);
<link rel="shortcut icon" href="/~serganov/~ilya/.images/favicon.ico">
EOH
}

for my $F ( qw{ izKeys-visual-maps logo izKeys-front } ) {
  unless (-e "$F-base.html") {
    require File::Copy;
    File::Copy::copy("UI-KeyboardLayout/examples/$F-base.html", "$F-base.html");
  }

  open F, '<', "$F-base.html" or die "Can't open $F-base.html for read";
  my $html = do {local $/; <F>};
  close F or die "Can't close $F-base.html for read";

  open STDOUT, q(>), qq($F-out.html); 
  print $l->apply_filter_div($l->apply_filter_style($html));
  open STDOUT, q(>), qq($F-fake.html); 
  print $l->apply_filter_div($l->apply_filter_style($html, {fake => 1}), {fake => 1});
}
