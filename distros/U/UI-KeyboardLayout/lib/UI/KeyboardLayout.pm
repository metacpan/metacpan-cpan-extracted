package UI::KeyboardLayout;

our $VERSION;
$VERSION = "0.78";

binmode $DB::OUT, ':utf8' if $DB::OUT;		# (older) Perls had "Wide char in Print" in debugger otherwise
binmode $DB::LINEINFO, ':utf8' if $DB::LINEINFO;		# (older) Perls had "Wide char in Print" in debugger otherwise

use strict;
use utf8;
BEGIN { my $n = ($ENV{UI_KEYBOARDLAYOUT_DEBUG} || 0); 
	if ($n =~ /^0x/i) {
	  $n = hex $n;
	} else {
	  $n += 0;
	}
	eval "sub debug() { $n }";
	#		1			2			4		8		0x10	0x20
	my @dbg = (qw( debug_face_layout_recipes debug_GUESS_MASSAGE debug_OPERATOR debug_import debug_stacking debug_noid ),
	#		0x40			0x80		0x100	0x200		0x400		0x800		0x1000
		   qw(warnSORTEDLISTS printSORTEDLISTS warnSORTCOMPOSE warnDO_COMPOSE warnCACHECOMP dontCOMPOSE_CACHE warnUNRES),
	#		0x2000			0x4000		 0x8000		0x10000
		   qw(debug_STACKING	printSkippedComposeKey	warnReached  debug_stacking_ord),
		   '_debug_PERL_dollar1_scoping');
	my $c = 0;		# printSORTEDLISTS: Dumpvalue to STDOUT (implementation detail!)
	my @dbg_b = map $n & (1<<$_), 0..31;
	for (@dbg) {
	  eval "sub $_ () {$dbg_b[$c++]}";
	}
}
sub debug_PERL_dollar1_scoping ()		 { debug & 0x1000000 }

my $ctrl_after = 1;	# In "pairs of nonShift/Shift-columns" (1 simplifies output of BACK/ESCAPE/RETURN/CANCEL)
my $create_alpha_ctrl = 2;	# Separate Ctrl and Ctrl-Shift ???
my %start_SEC = (FKEYS => [96, 24, sub { my($self,$u,$v)=@_; 'F' . (1+$u-$v->[0]) }],
		 ARROWS => [128, 16,
		 	    sub { my($self,$u,$v)=@_;
		 	          (qw(HOME UP PRIOR DIVIDE LEFT CLEAR RIGHT MULTIPLY END DOWN NEXT SUBTRACT INSERT DELETE RETURN ADD))[$u-$v->[0]]}],
		 NUMPAD => [144, 16,
		 	    sub { my($self,$u,$v)=@_;
		 	          ((map { ($_ > 10 ? 'F' : "NUMPAD") . $_} 7..9,14,4..6,15,1..3,16,0), 'DECIMAL')[$u-$v->[0]]}]);
my $LAST_SEC = -1e100;
$LAST_SEC < $_->[0] + $_->[1] and $LAST_SEC = $_->[0] + $_->[1] for values %start_SEC;

my $maxEntityLen = 111;		# Avoid overflow of prefix char above 0fff in kbdutool (but now can channel them to smaller values)
my $avoid_overlong_synonims_Entity = 20;	# These two are currently disabled

sub toU($) { substr+(qq(\x{fff}).shift),1 }	# Some bullshit one must do to make perl's Unicode 8-bit-aware (!)

#use subs qw(chr lc);
use subs qw(chr lc uc ucfirst);

#BEGIN { *CORE::GLOGAL::chr = sub ($) { toU CORE::chr shift };
#        *CORE::GLOGAL::lc  = sub ($)  { CORE::lc  toU shift };
#}
### Remove ß ẞ :
## my %fix = qw( ԥ Ԥ ԧ Ԧ ӏ Ӏ ɀ Ɀ ꙡ Ꙡ ꞑ Ꞑ  ꞧ Ꞧ  ɋ Ɋ  ꞩ Ꞩ  ȿ Ȿ  ꞓ Ꞓ  ꞥ Ꞥ );		# Perl 5.8.8 uc is wrong with palochka, 5.10 with z with swash tail
my %fix = qw( ԥ Ԥ ԧ Ԧ ӏ Ӏ ɀ Ɀ ꙡ Ꙡ ꞑ Ꞑ  ꞧ Ꞧ  ɋ Ɋ  ß ẞ  ꞩ Ꞩ  ȿ Ȿ  ꞓ Ꞓ  ꞥ Ꞥ  ℊ Ɡ  ϳ Ϳ );		# Perl 5.8.8 uc is wrong with palochka, 5.10 with z with swash tail
my %unfix = reverse %fix;

sub chr($)  { local $^W = 0; toU CORE::chr shift }	# Avoid illegal character 0xfffe etc warnings...
sub lc($)   { my $in = shift; $unfix{$in} || CORE::lc toU $in }
sub uc($)   { my $in = shift;   $fix{$in} || CORE::uc toU $in }
sub ucfirst($)   { my $in = shift;   $fix{$in} || CORE::ucfirst toU $in }

# We use this for printing, not for reading (so we can use //o AFTER the UCD is read)
my $rxCombining = qr/\p{NonspacingMark}/;	# The initial version matches what Perl knows
my $rxZW = qr/\p{Line_Break: ZW}|[\xAD\x{200b}-\x{200f}\x{2060}-\x{2064}\x{fe00}-\x{fe0f}]/;

sub rxCombining { $rxCombining }

=pod

=encoding UTF-8

=head1 NAME

UI::KeyboardLayout - Module for designing keyboard layouts

=head1 SYNOPSIS

  #!/usr/bin/perl -wC31
  use UI::KeyboardLayout; 
  use strict;

  # Download from http://www.unicode.org/Public/UNIDATA/
  UI::KeyboardLayout::->set_NamesList("$ENV{HOME}/Downloads/NamesList.txt"); 

  UI::KeyboardLayout::->set__value('ComposeFiles',	# CygWin too
				  ['/usr/share/X11/locale/en_US.UTF-8/Compose']);
  # http://cgit.freedesktop.org/xorg/proto/xproto/plain/keysymdef.h
  UI::KeyboardLayout::->set__value('KeySyms',
				  ['/usr/share/X11/include/keysymdef.h']);
  UI::KeyboardLayout::->set__value('EntityFiles',
				  ["$ENV{HOME}/Downloads/bycodes.html"]);
  UI::KeyboardLayout::->set__value('rfc1345Files',
				  ["$ENV{HOME}/Downloads/rfc1345.html"]);
  
  my $i = do {local $/; open $in, '<', 'MultiUni.kbdd' or die; <$in>}; 
  # Init from in-memory copy of the configfile
  # Combines new()->parse_add_configfile()->massage_full():
  my $k = UI::KeyboardLayout:: -> new_from_configfile_string($i)
             -> fill_win_template( 1, [qw(faces CyrillicPhonetic)] ); 
  print $k;	# optional arguments 'dummy' (and possibly 'dummyname')
		# to fill_win_template() to make an 'extra-dummy' version
  
  open my $f, '<', "$ENV{HOME}/Downloads/NamesList.txt" or die;
  my $k = UI::KeyboardLayout::->new();
  my ($d,$c,$names,$blocks,$extraComb,$uniVersion) = $k->parse_NameList($f);
  close $f or die;
  $k->print_decompositions($d);
  $k->print_compositions  ($c);
  # selected print
  $l->print_compositions_ch_filter( [qw(<super> <pseudo-fake-super> <pseudo-manual-superize>)] ); 
  
  UI::KeyboardLayout::->set_NamesList("$ENV{HOME}/Downloads/NamesList.txt", 
  				      "$ENV{HOME}/Downloads/DerivedAge.txt"); 
  my $l = UI::KeyboardLayout::->new(); 
  $l->print_compositions; 
  $l->print_decompositions;

  UI::KeyboardLayout::->set_NamesList("$ENV{HOME}/Downloads/NamesList-6.1.0d8.txt", 
  				      "$ENV{HOME}/Downloads/DerivedAge-6.1.0d13.txt"));
  # Combines new()->parse_add_configfile()->massage_full():
  my $l = UI::KeyboardLayout::->new_from_configfile('examples/EurKey++.kbdd');

  for my $F (qw(US CyrillicPhonetic)) {		
  	# Open file, select() 
    print $l->fill_win_template(1,[qw(faces US)]);
    $l->print_coverage(q(US));
    print $l->fill_osx_template([qw[faces US)]);
  }

  perl -wC31 UI-KeyboardLayout\examples\grep_nameslist.pl "\b(ALPHA|BETA|GAMMA|DELTA|EPSILON|ZETA|ETA|THETA|IOTA|KAPPA|LAMDA|MU|NU|XI|OMICRON|PI|RHO|SIGMA|TAU|UPSILON|PHI|CHI|PSI|OMEGA)\b" ~/Downloads/NamesList.txt >out-greek

=head1 AUTHORS

Ilya Zakharevich, ilyaz@cpan.org

=head1 DESCRIPTION

In this section, a "keyboard" has a certain "character repertoir" (which characters may be
entered using this keyboard), and a mapping associating a character in the repertoir
to a keypress or to several (sequential or simultaneous) keypresses.  A small enough keyboard
may have a pretty arbitrary mapping and remain useful (witness QUERTY
vs Dvorak vs Colemac).  However, if a keyboard has a sufficiently large repertoir,
there must be a strong logic ("orthogonality") in this association - otherwise
the most part of the repertoir will not be useful (except for people who have an
extraordinary memory - and are ready to invest part of it into the keyboard).

"Character repertoir" needs of different people vary enormously; observing
the people around me, I get a very narrow point of view.  But it is the best
I can do; what I observe is that many of them would use 1000-2000 characters
if they had a simple way to enter them; and the needs of different people do 
not match a lot.  So to be helpful to different people, a keyboard should have 
at least 2000-3000 different characters in the repertoir.  (Some ballpark
comparisons: L<MES-3B|http://web.archive.org/web/20000815100817/http://www.egt.ie/standards/iso10646/pdf/cwa13873.pdf> 
has about 2800 characters; L<Adobe Glyph list|http://en.wikipedia.org/wiki/Adobe_Glyph_List> corresponds 
to about 3600 Unicode characters.)

To access these characters, how much structure one needs to carry in memory?  One can
make a (trivial) estimate from below: on Windows, the standard US keyboard allows 
entering 100 - or 104 - characters (94 ASCII keys, SPACE, ENTER, TAB - moreover, C-ENTER, 
BACKSPACE and C-BACKSPACE also produce characters; so do C-[, C-] and C-\
C-Break in most layouts!).  If one needs about 30 times more, one could do
with 5 different ways to "mogrify" a character; if these mogrifications 
are "orthogonal", then there are 2^5 = 32 ways of combining them, and
one could access 32*104 = 3328 characters.

Of course, the characters in a "reasonable repertoir" form a very amorphous
mass; there is no way to introduce a structure like that which is "natural"
(so there is a hope for "ordinary people" to keep it in memory).  So the
complexity of these mogrification is not in their number, but in their
"nature".  One may try to decrease this complexity by having very easy to
understand mogrifications - but then there is no hope in having 5 of them
- or 10, or 15, or 20.

However, we B<know> that many people I<are> able to memorise the layout of 
70 symbols on a keyboard.  So would they be able to handle, for example, 30 
different "natural" mogrifications?  And how large a repertoir of characters
one would be able to access using these mogrifications?

This module does not answer these questions directly, but it provides tools
for investigating them, and tools to construct the actually working keyboard
layouts based on these ideas.  It consists of the following principal
components:

=over 4

=item Unicode table examiner

distills relations between different Unicode characters from the Unicode tables,
and combines the results with user-specified "manual mogrification" rules.
From these automatic/manual mogrifications, it constructs orthogonal scaffolding 
supporting Unicode characters (we call it I<composition/decomposition>, but it
is a major generalization of the corresponding Unicode consortium's terms).

=item Layout constructor

allows building keyboard layouts based on the above mogrification rules, and
on other visual and/or logical directives.  It combines the bulk-handling
ability of automatic rule-based approach with a flexibility provided by 
a system of manual overrides.   (The rules are read from a F<.kbdd> L<I<Keyboard
Description> file|/"Keyboard description files">.

=item System-specific software layouts

may be created basing on the "theoretical layout" made by the layout
constructor — currently only on Windows (only via F<KBDUTOOL> route) and OS X.

=item Report/Debugging framework

creates human-readable descriptions of the layout, and/or debugging reports on
how the layout creation logic proceeded.

=back

The last (and, probably, the most important) component of the distribution is
L<an example keyboard layout|http://k.ilyaz.org/iz> created using this toolset.

=head1 Keyboard description files

=head2 Syntax

I could not find an appropriate existing configuration file format, so was
farced to invent yet-another-config-file-format.  Sorry...

Config file is for initialization of a tree implementing a hash of hashes of
hashes etc whole leaves are either strings or arrays of strings, and keys are
words.  The file consists of I<"sections">; each section fills a certain hash
in the tree.

Sections are separated by "section names" which are sequences of word
character and C</> (possibly empty) enclosed in square brackets.
C<[]> is a root hash, then C<[word]> is a hash reference by key C<word> in the
root hash, then C<[word/another]> is a hash referenced by element of the hash
referenced by C<[word]> etc.  Additionally, a section separator may look like
C<< [visual -> wordsAndSlashes] >>.

Sections are of two type: normal and visual.  A normal section
consists of comments (starting with C<#>) and assignments.  An assignment is
in one of 4 forms:

   word=value
   +word=value
   @word=value,value,value,value
   /word=value/value/value/value

The first assigns a string C<value> to the key C<word> in the hash of the
current section.  The second adds a value to an array referenced by the key
C<word>; the other two add several values.  Trailing whitespace is stripped.

Any string value without end-of-line characters and trailing whitespace
can be added this way (and values without commas or without slash can
be added in bulk to arrays).  In particular, there may be no whitespace before
C<=> sign, and the whitespace after C<=> is a part of the value.

Visual sections consist of comments, assignments, and C<content>, which
is I<the rest> of the section.  Comments
after the last assignment become parts of the content.  The content is
preserved as a whole, and assigned to the key C<unparsed_data>; trailing
whitespace is stripped.  (This is the way to insert a value containing
end-of-line-characters.)

In the context of this distribution, the intent of visual sections is to be
parsed by a postprocessor.  So the only purpose of explicit assignments in a
visual section is to configure how I<the rest> is parsed; after the parsing
is done (and the result is copied elsewhere in the tree) these values should
better be not used.

=head2 Semantic of visual sections

Two types of visual sections are supported: C<DEADKEYS> and C<KBD>.  A content of
C<DEADKEYS> section is just an embedded (part of) F<.klc> file.  We can read deadkey
mappings and deadkey names from such sections.  The name of the section becomes the
name of the mapping functions which may be used inside the C<Diacritic_*> rule
(or in a recipe for a computed layer).

C<KBD> sections come in two styles: freehand and rectangular.  In this section we
focus on the freehand style

A content of a freehand C<KBD> section consists of C<#>-comment lines and "the mapping 
lines"; every "mapping line" encodes one row in a keyboard (in one or several 
layouts).  (But the make up of rows of this keyboard may be purely imaginary; 
it is normal to have a "keyboard" with one row of numbers 0...9.)
Configuration settings specify how many lines are per row, and how many layers
are encoded by every line, and what are the names of these layers:

 visual_rowcount	# how many config lines per row of keyboard
 visual_per_row_counts 	# Array of length visual_rowcount
 visual_prefixes	# Array of chars; <= visual_rowcount (miss=SPACE)
 prefix_repeat		# How many times prefix char is repeated (n/a to SPACE)
 in_key_separator	# If several layers per row, splits a key-descr
 layer_names		# Where to put the resulting keys array
 in_key_separator2	# If one of entries is longer than 1 char, join by this 
 				# (optional)

Each line consists of a prefix (which is ignored except for sanity checking), and
whitespace-separated list of key descriptions.  (Whitespace followed by a
combining character is not separating.)  Each key description is split using
C<in_key_separator> into slots, one slot per layout.  (The leading 
C<in_key_separator> is not separating.)  Each key/layout
description consists of one or two entries.  An entry is either two dashes
C<--> (standing for empty), or a hex number of length >=4, or a string.
(A hex numbers must be separated by C<.> from neighbor word
characters.)  A loner character which has a different uppercase is
auto-replicated in uppercase (more precisely, titlecase) form.  Missing or empty key/layout description
gives two empty entries (note that the leading key/layout description cannot
be empty; same for "the whole key description" - use the leading C<-->.

If one of the entries in a slot is a string of length ≥ 2, one must separate 
the entries by C<in_key_separator2>.  Likewise, if a slot has only one entry,
and it is longer than 1 char, it must be started or terminated by C<in_key_separator2>.

To simplify BiDi keyboards, a line may optionally be prefixed with the L<C<LRO/RLO>|http://en.wikipedia.org/wiki/Unicode_character_property#Bidirectional_writing>
character; if so, it may optionally be ended by spaces and the L<C<PDF>|http://en.wikipedia.org/wiki/Unicode_character_property#Bidirectional_writing> character.
For compatibility with other components, layer names should not contain characters C<+()[]>.

For example, with suitable configuration settings the first two config-lines of the table below may describe a first row of a
certain keyboard (with two keys!) in 5 layouts:

  111   1①/₁¹/--𐋡         2②/₂²/--𐋢
  222   [1]‼{1}/002f.o    [2]‼{2}/+±
  111   a/α/ⲁ             s/σ/ⲥ        d/δ/ⲇ
  222   𝒶/𝕒               𝓈/𝕤          𝒹/𝕕

If so, the third and the fourth row would describe the second row of the keyboard (with 3 keys).  Assuming C<in_key_separator=/>,
the first and the third row concern 3 layouts, while the second and the fourth concern 2 more layouts.  (So this corresponds to
C<visual_per_row_counts=3,2>.)

Assuming C<in_key_separator=‼>, the 4th layout (the first one in the even rows — starting with C<222>) has on the top-left key
C<[1]> in the unshifted position, and C<{1}> in the shifted one.  The third layout on this key has nothing in the unshifted
position, and C<𐋡> in the shifted one.  The second layout on the bottom-right key produces C<σ> and C<Σ> in the unshifted/shifted
positions.  Likewise the 5th one produces C<𝕤> and C<𝕊> (if this module has access to Unicode tables allowing it to guess that
C<𝕤/𝕊> “behave like” a case-pair — this is not specified in Unicode, but may be guessed by the names of these characters).

For the top-left key in 5th layout, we needed hex to encode the content (which is C</>) since it coincides with the separator.

=head2 Rectangular visual layout tables

TBC ........................

If a layer C<NAME> is define visually as a part of a list of layers, then the layer C<NAME²> is defined made of this layer (in the
unshifted position) and the next layer “shifted up”.  Similarly, the layer C<NAME²⁺> is mad of the next 2 layers after
those in C<NAME²>. 

Likewise, for RECT visual layers, C<NAME₁> is the corresponding layers in the next row of rectangles; C<NAME₂>, C<NAME₂₊> are made
as above of pairs of corresponding layers in the next row of rectangles.  Moreover, the face C<NAME⁴> is a shortcut for
C<Layers(NAME²+Name²⁺)>, and C<NAME₄> for C<Layers(NAME²+Name₂)>.

TBC ........................ (some accessible not only from rectangular…)

=head2 Inclusion of F<.klc> files

Instead of including a F<.klc> file (or its part) verbatim in a visual
section, one can make a section C<DEADKEYS/NAME/name1/nm2> with
a key C<klc_filename>.  Filename will be included and parsed as a C<DEADKEYS>
visual section (with name C<DEADKEYS/name1/nm2>???).  (Currently only UTF-16
files are supported.)

=head2 Metadata

A metadata entry is either a string, or an array.  A string behaves as
if were an array with the string repeated sufficiently many times.  Each
personality defines C<MetaData_Index> which chooses the element of the arrays.
The entries

  COMPANYNAME LAYOUTNAME COPYR_YEARS LOCALE_NAME LOCALE_ID
  DLLNAME SORT_ORDER_ID_ LANGUAGE_NAME

should be defined in the personality section, or above this section in the
configuration tree.  (Used when output Windows F<.klc> files and OS X
F<.keylayout> files.)

  OSX_ADD_VERSION OSX_LAYOUTNAME

The first one is the ordinal of the word after which to insert the version
into C<LAYOUTNAME> (OS X allows layout names longer than the limit of 64 UTF-16
codepoints of Windows); the second one allows a completely different name.

Optional metadata currently consists only of C<VERSION> key (the protocol
version; hardwired now as C<1.0>) and keys C<LRM_RLM ALTGR SHIFTLOCK> defining
what goes into the C<ATTRIBUTES> section of F<.klc> file (the latter may also
be specified in a face's section, or its parents).

=head2 Layers and Faces

An "abstract" I<layer> is, essentially, just two arrays of “generated characters”: one
for the un-C<Shift>ed state, and one for C<Shift>ed state.  A “generated characters”
may be also a prefix keypress ("redirecting" to a different face); it may also have
an attached metadata (for example, by which rules this character was generated, and
which "ornaments" to use when one "visualizes" this keybinding.

Most layers are just intermediate "building blocks" for constructing other layers.
However, many layers are going to be output to the final description of the keyboard.
For the latter layers, the position in the array should be thought of as associated
(by the tables outside of the context of the layer) with particular physical key
of the keyboard.  These positions are split into several intervals corresponding to
different "isles" of the keyboard: the main isle, numeric isle, movement/insert/del
keys, and function keys.

The layers are defined by the visual sections of the keyboard definition, and by
I<layer recipes> (well, one can also define layers by embedding/importing tables
in MSKLC’s format).  The format of the visual sections is designed to define things
"organized in row".  Every "generalized character" in a layer either comes from a
visual section, or is produced by a "recipe rule" from (another) character from
(another) layer.  (So they carry "a chain of provenance".)

A I<face> consists of several layers (typically two: one for C<AltGr> not pressed,
and one for C<AltGr> pressed) and a lot of associated metadata,

=head2 Layer/Face/Prefix-key Recipes

The sections C<layer_recipes> and C<face_recipes> contain instructions how
to build Layers and Faces out of simpler elements.  Similar recipes appear  
as values of C<DeadKey_Map*> entries in a face.  Such a "recipe" is
executed with I<parameters>: a base face name, a layer number, and a prefix
character (the latter is undefined when the recipe is a layer recipe or
face recipe).  (The recipe is free to ignore the parameters; for example, most
recipes ignore the prefix character even when they are "prefix key" recipes.)

The recipes and the visual sections are the most important components of the description
of a keyboard group.

To construct layers of a face, a face recipe is executed several times with different 
"layer number" parameter.  In contrast, in simplest cases a layer recipe is executed
once.  However, when the layer is a part of a compound ("parent") recipe, it inherits 
the "parameters" from the parent.  In particular, it may be executed several times with
different face name (if used in different faces), or with different layer number (if used
- explicitly or explicitly - in different layer slots; for example, C<Mutator(LayerName)>
in a face/prefix-key recipe will execute the C<LayerName> recipe separately for all the
layer numbers; or one can use C<Layers(Empty+LayerName)> together with
C<Layers(LayerName+Other)>).  Depending on the recipe, these calls may result in the same layout 
of the resulting layers, or in different layouts.

A recipe may be of three kinds: it is either a "first comer wins" which is a space-separated collection of
simpler recipes, or C<SELECTOR(COMPONENTS)>, or a "mutator": C<MUTATOR(BASE)> or just C<MUTATOR>.  (There is
also a syntax of mutator of different form: C<prefix=HEX> or C<prefixNOTSAME=HEX>; see below.)
All recipes must be C<()>-balanced
and C<[]>-balanced; so must be the C<MUTATOR>s; in turn, the C<BASE> is either a 
layer name, or another recipe.  A layer name must be defined either in a visual C<KBD> section,
or be a key in the C<layer_recipes> section (so it should not have C<+()[]> characters),
or be the literal C<Empty>.
When C<MUTATOR(BASE)> is processed, first, the resulting layer(s) of the C<BASE> recipe 
are calculated; then the layer(s) are processed by the C<MUTATOR> (one key at a time).

The most important C<SELECTOR> keywords are C<Face> (with argument a face name, defined either
via a C<faces/FACENAME> section, or via C<face_recipes>) and C<Layers> (with argument
of the form C<LAYER_NAME+LAYER_NAME+...>, with layer names defined as above).  Both
select the layer (out of a face, or out of a list) with number equal to the "layer number parameter" in the context
of the recipe.  The C<FlipLayers> builder is similar to C<Face>, but chooses the "other" 
layer ("cyclically the next" layer if more than 2 are present).

The other selectors are C<Self>, C<LinkFace> and C<FlipLayersLinkFace>; they
operate on the base face or face associated to the base face.  B<NOTE:> when C<NAME> is a name of a “personality” face (which
is construted in steps for its C<Layers> declaration, C<LinkFace> and specific C<VK>-keys), C<Face(NAME)> is based only on this
C<Layers> declaration.  Use C<FullFace(NAME)> to address the “synthesized” state of the face (the result depends on which moment
this state is accessed!).  (Likewise for C<FullFlipLayers>.)  See also L<"Implementation details: C<FullFace(FNAME)>">.

The selector C<Shortcut(FACE_RECIPE_NAME)> is same as Face(), but does not reset the active prefix, and makes no caching (so
may be used in different contexts with different results).

The simplest forms of C<MUTATORS> are C<Id, lc, uc, ucfirst, Empty> (note that
C<uc>/C<lc>/C<ucfirst> return C<undefined> when case-conversion results in no
change; use C<maybe_uc>/C<maybe_lc>/C<maybe_ucfirst> if one wants them to behave
as Perl operators).  Recall that a layer
is nothing more than a structure associating a pair "unshifted/shifted character" to the key number, and that
these characters may be undefined.  These simplest mutators modify these characters
independently of their key numbers and shift state (with C<Empty> making all of
them undefined).  Similar user-defined simple mutators are C<ByPairs[PAIRS]>;
here C<PAIRS> consists of pairs "FROM TO" of characters (with optional spaces between pairs);
characters not appearing as FROM become undefined by C<ByPairs>.
(As usual, characters may be replaced by hex numbers with 4 or more hex digits;
separate the number from a neighboring word character by C<.> [dot].)

The C<Flat>/C<Inv> variants: TBC ................

All mutators must have a form C<WORD> or C<WORD[PARAMETERS]>, with C<PARAMETERS>
C<(),[]>-balanced.  Other simple mutators are C<dectrl> (converts
control-char [those between 0x00 and 0x1f] to the corresponding [uppercase] character), 
C<ShiftFromTo[FROM,TO]> (adds a constant to the [numerical code of the] input character
so that C<FROM> becomes C<TO>), C<SelectRX[PERL_REGEXP]> (keeps input characters
which match, converts everything else to C<undefined>), C<FromTo[LAYER_FROM,LAYER_TO]>
(similar to C<ByPairs>, but pairs all characters in the layers based on their position),
C<DefinedTo[CHAR]> (all defined characters are converted to C<CHAR>; if C<CHAR> is C<undef>,
this “undefines” these positions in whatever follows this part of the recipe).

The mutator C<Imported[NAME]> is similar to C<ByPairs>, but takes the F<.klc>-style
visual C<DEADKEYS/NAME> section as the description of the mutation.  C<NAME> may
be followed by a character as in C<NAME,CHAR>; if not, C<CHAR> is the prefix key from
the recipe's execution parameters.

The simple mutator C<ByPairs> has flavors: one can append C<Prefix> or C<InvPrefix>
to the name, and the resulting bindings become prefix keys (with C<Inv>, the 
prefix followed by C<CHAR> behaves as the non-C<Inv> prefix followed by C<AltGr-CHAR>).
(I<The behaviour> of these prefix keys should be defined elsewhere; for example, by
C<DeadKey_Map****>.)

Some mutators pay attention not only to what the character is, but how it is 
accessible on the given key: such are C<FlipShift>, C<FlipLayers>, 
C<FromToFlipShift[LAYER_FROM,LAYER_TO]>.  Some other mutators also take into
account how the key is positioned with respect to the other keys.

C<ByColumns[CHARS]> assigns a character
to a particular column of the keyboard.  Which keys are in which columns is 
governed by how the corresponding
visual layer is formatted (shifted to the right by C<keyline_offsets> array of the
visual layer).  This visual layer is one associated to the face by the
C<geometry_via_layer> key (and the face is the parameter face of the
mutator).  C<CHARS> is a comma-separated list;
empty positions map to the undefined character.

C<ByRows[MUTATORS]> chooses a mutator based on the row of the keyboard.  On the top row,
it is the first mutator which is chosen, etc. The list C<MUTATORS> is separated by C<///> 
surrounded by whitespace.

The mutator C<InheritPrefixKeys[FACE_FROM]> converts some non-prefix characters to prefix
characters; the conversion happens if the argument of the mutator coincides with 
what is at the corresponding position in C<FACE_FROM>, and this position contains
a prefix character.  (Nowadays this mutator is not very handy — most of its uses 
may be accomplished by having I<inheritable> prefix characters in appropriate faces.)

The mutators C<NotId(BASEFACE FACES)>, C<NotSameKey(BASEFACE FACES)> process their 
argument in a special way: the characters in C<FACES> which duplicated the characters 
present (on the same key, and possibly with the same modifiers) in C<BASEFACE> are
ignored.  The remaining characters are combined “as usual” with “the first comer wins”.

The most important mutator is C<Mutate> (and its flavors).  (See L<The C<Mutate[RULES]> mutator>.)

Note that C<Id(LAYERNAME)> is similar to a selector;
it is the only way to insert a
layer without a selector, since a bareword is interpreted as a C<MUTATOR>; C<Id(LAYERNAME)> is a synonym
of C<Layers(LAYERNAME+LAYERNAME+...)> (repeated as many times as there are layers
in the parameter "base face").


The recipes in a space-separated list of recipes ("first comer wins") are 
interpreted independently to give a collection of layers to combine; then,
for every key numbers and both shift states, one takes the leftmost recipe 
which produces a defined character for this position, and the result is put 
into the resulting layer.

Keep in mind that to understand what a recipe does, one should trace 
its description right-to-left order: for example, C<ByPairs[.:](FlipLayers)> creates
a layout where C<:> is at position of C<.>, but on the second [=other] layer (essentially,
if the base layout is the standard one, it binds the character C<:> to the keypress C<AltGr-.>).

To simplify formatting of F<.kbdd> files, a recipe may be an array reference.
The string may be split on spaces (but not after comma or C<|>), or split after comma or C<|>.
(Another good alternative is to use the-split-line C<+>-syntax for assignments.)

=head2 The C<prefix=HEX> or C<prefixNOTSAME=HEX> and C<prefixNOTSAMEcase=HEX> mutators

The former case imports a fully defined face corresponding to the prefix key C<HEX>. 
The other cases do likewise, but massage the base layer in the positions without a “new” binding.
Here a binding is “new” if not present I<on the same key> in the base face (on any layer/C<Shift>-state).

More precisely, the imported positions on this key on other layers with “new bindins” may be
copied to “non-new” positions in layer 0.  Here the same C<Shift>-state is either preserved,
or — unless in the last flavor — “raised”,
as in copying from C<AltGr> to C<Shift> — if this adds a not-yet-created binding.  (The first “new”
binding wins — although this may be important only with more than 2 layers.)

(Compare with the C<prefixNOTSAME=HEX> field of
L<the C<@output_layers> configuration variable|"More than 2 layers and/or exotic modifier keys"> — but
there a binding is not “new” if it is present I<anywhere> on the base face.)

B<WARNING:> there is no attempt to resolve infinite loops of importing.  In particular,
C<prefix=> should not create circular dependency between prefixes, or be used in “principal”
(=non-DeadKey) face.

=head2 The C<NOID()>, C<NotSameKey()>

TBC ......................

=head2 The C<Mutate[RULES]> mutator

The essense of C<Mutate> is to have several mutation rules and choose I<the best>
of the results of application of these rules.  Grouping the rules allows
one a flexible way to control what I<the best> actually means.  The rules may
be separated by comma, by C<|>, or by C<|||> (interchangeable with C<||||>).

The simplest case of competition between results produced by different rules is for rules in different
C<|>-separated groups: then “the earlier rule producing results wins”.  However, the rules not separated
by C<|> I<compete by “quality”> of their results.

The I<quality> of the generated characters is a list C<UNICODE_AGE, HONEST, 
UNICODE_BLOCK, IN_CASE_PAIR, FROM_NON_ALTGR_POSITION>
with lexicographical order (the earlier element is stronger that ones after it).
Here C<HONEST> describes whether a character is generated by
Unicode compositing (versus “compatibility compositing” or other
“artificially generated” mogrifiers); the older age wins, as well as
honest compositing, earlier Unicode blocks, as well as case pairs and
characters from non-C<AltGr>-positions.  (Experience shows that these rules
have a pretty good correlation with being “more suitable for human consumption”.)

Moreover, quality in case-pairs is equalized by assigning the strongest 
I<quality> of two.  Such pairs are always considered “tied together” when
they compete with other characters.  (In particular, if a single character
with higher quality occupies one of C<Shifted/Unshifted> positions, a
case pair with lower quality is completely ignored; so the “other” position 
may be taken by a single character with yet lower quality.)

In addition, the characters which lost the competition for
non-C<AltGr>-positions are considered I<again> on C<AltGr>-positions.  (With
boosted priority compared to mutated C<AltGr>-characters; see above.)

This mutator comes in several flavors: one can append to its name
C<SpaceOK>/C<Hack>/C<DupsOK>/C<32OK> (in this
order).  Unless C<SpaceOK> is specified, it will not modify characters on a key
which produces C<SPACE> when used without modifiers.  Unless C<32OK> is specified, it
will not produce Unicode characters after C<0xFFFF> (the default is to follow
the brain-damaged semantic of prefix keys on Windows).  Unless C<DupsOK> is
specified, the result is optimized by removing duplicates (per key) generated
by application of C<RULES>.  With the C<Hack> modifier, the generated characters
are not counted as “obtained by logical rules” when statistics for the generated
keyboard layout are calculated.

=head2 Macro-ization of recipes

… is acteually described inside the following section.

=head2 Linked prefixes

On top of what is explained above, there is a way to arrange “linking” of two prefix keys;
this linking allows characters which cannot be fit on one (prefixed) key to
“migrate” to unassigned positions on the otherwise-prefixed key.  (This is
similar to migration from non-C<AltGr>-position to C<AltGr>-position.)
This is achieved by using mutator rules of the following form:

  primary	= 		+PRE-GROUPS1|||SHARED||||POST-GROUPS1
  secondary	= PRE-GROUPS2||||PRE-GROUPS1|||SHARED||||POST-GROUPS2

Groups with digits are not shared (specific to a particular prefix); C<SHARED> is
(effectively) reverted when accessed from the secondary prefix; for the
secondary key, the recipies from C<SHARED> which were used in the primary 
key are removed from C<SHARED>, and are appended to the end of C<POST-GROUPS2>;
the C<PRE-GROUPS1> are skipped when finding assignments for the secondary
prefix.

In the primary recipe, C<|||> and C<||||> are interchangeable with C<|>.
Moreover, if C<POST-GROUPS2> is empty, the secondary recipe should be written as

  secondary	= PRE-GROUPS2|||PRE-GROUPS1|||SHARED

if C<PRE-GROUPS1> is empty, this should be written as one of

  secondary	= PRE-GROUPS2|||SHARED
  secondary	= PRE-GROUPS2||||SHARED
  secondary	= PRE-GROUPS2||||SHARED||||POST-GROUPS2

These rules are to allow macro-ization of the common parts of the primary
and secondary recipe.  (Although macro-ization may be useful for non-paired
recipes too!)  Put the common parts as a value of the key
C<Named_DIA_Recipe__***> (here C<***> denotes a word), and replace them by
the macro C<< <NAMED-***> >> in the recipes.

B<Implementation>: the primary key recipe starts with the C<+> character; it
forces interpretation of C<|||> and C<||||> as of ordinary C<|>.

If not I<primary>, the top-level groups are formed by C<||||> (if present), otherwise by C<|||>. 
The number of top-level groups should be at most 3.  The second of C<||||>-groups
may have at most 2 C<|||>-groups; there should be no other subdivision.  This way,
there may be up to 4 groups with different roles.

The second of 3 toplevel C<|||>-groups, or the first of two sublevel C<|||>-groups
is the “skip” group.  The last of two or three toplevel C<|||>-groups (or of 
sublevel C<|||>-groups, or the 2nd toplevel C<||||>-group without subdivisions) is the 
inverted group; the 3rd of toplevel C<||||>-groups is the “extra” group.

“Penalize/prohibit” lists start anew in every top-level group.

=head2 Atomic mogrifying rules

As explained above, the individual RULES in C<Mutate[RULES]> may be
separated by C<,> or C<|>, or C<|||> or C<||||>.  Such an individual
rule is a combination of I<atomic mogrifying rules> combined by C<+> operators,
and/or preceded by C<-> prefix (with understanding that C<+-> must
be replaced by C<-->).  The prefix C<-> means I<inversion> of the
rule; the operator C<+> is the composition of the rules.

B<Example:> the atomic mogrifying rule C<< <super> >> converts its input character into
its superscript forms (if such forms exist; for example, C<a> may
be converted to C<ᵃ> or C<ª>).  The atomic rules C<lc>, C<uc>, C<ucfirst>
behave the same as the corresponding MUTATORs.   The atomic rule C<dectrl>
converts a control-character to the corresponding “uppercase” character:
C<^A> is converted to C<A>, and C<^\> is converted to C<\>.  (The last
4 rules cannot be inverted by C<->.)

The composition is performed (as usual) from right to left (the part on the right
is executed first (“as usual”; compare with C<log sin I<x>>).  B<Example:> the
indivial rule C<< <super>+lc+dectrl >> converts C<^A> to C<ᵃ> or C<ª>.

Any combining Unicode character defines the corresponding atomic mogrifier.  It
may result in the corresponding
L<precomposed form|https://en.wikipedia.org/wiki/Precomposed_character>; additionally,
it is extended “to commute with” 

In addition to rules listed above, the atomic mogrifiers may be of the
following types:

=over

=item *

A hex number with ≥4 digits, or a character: implements the composition
inverting (compatibility or not) Unicode decompositions into “the base” and
“the combining character”; such mogrifier matches the composing character,
and sends the base to “the composed form”.

Here “Unicode decompositions” are either deduced from explicit Unicode decomposition
rules (with compatibility decompositions having lower priority), or deduced
basing on splitting the name of the character into suitable parts.

=item *

C<< <pseudo-upgrade> >> is an inversion of a Unicode decomposition which goes from
1 character to 1 character.

=item *

Flavors of characters C<< <FLAVOR> >> from the Unicode tables come from Unicode 
1-character to 1-character decompositions
marked with C<< <FLAVOR> >>.  B<Example:> C<< <sub> >> for a subscript form;
or C<< <final> >>.

=item *

C<< <font=font␣name> >> rules convert a letter (and a digit) to the corresponding
codepoint in L<Unicode Math Alphabets|https://en.wikipedia.org/wiki/Mathematical_Alphanumeric_Symbols>.
(Replace spaces in the “name of the font” [such as C<DOUBLE STRUCK>] by dash=C<-> and lowercase it; so the corresponding
rule is C<< <font=double-struck> >>.)

=item *

Calculated rules C<< <pseudo-calculated-***> >> are extracted by a 
heuristic algorithm which tries to parse the Unicode name of the character.

For the best understanding of what these rules produce, inspect
results of print_compositions(), print_decompositions() methods documented
in L<"SYNOPSIS">.  The following “keywords” are processed by the algorithm:

  WITH, OVER, ABOVE, PRECEDED BY, BELOW (only with LONG DASH)

in the Unicode name are considered “to be separators”; and
  
  COMBINING CYRILLIC LETTER, BARRED, SLANTED, APPROXIMATELY, ASYMPTOTICALLY, 
  SMALL (not near LETTER), ALMOST, SQUARED, BIG, N-ARY, LARGE, LUNATE,
  SIDEWAYS DIAERESIZED, SIDEWAYS OPEN, INVERTED, ARCHAIC, EPIGRAPHIC,
  SCRIPT, LONG, MATHEMATICAL, AFRICAN, INSULAR, VISIGOTHIC, MIDDLE-WELSH,
  BROKEN, TURNED, INSULAR, SANS-SERIF, REVERSED, OPEN, CLOSED, DOTLESS, TAILLESS, FINAL
  BAR, SYMBOL, OPERATOR, SIGN, ROTUNDA, LONGA, IN TRIANGLE, SMALL CAPITAL (as smallcaps)

are mogrifiers.  For an C<APL FUNCTIONAL SYMBOL>, one scans for

  QUAD, UNDERBAR, TILDE, DIAERESIS, VANE, STILE, JOT, OVERBAR, BAR

In particular, the mogrifier C<< <pseudo-calculated-operator> >> may convert the character
C<\> (named C<REVERSE SOLIDUS>) to the Unicode character C<U+29f5=⧵> with the name
C<REVERSE SOLIDUS OPERATOR>.

=item *

Additionally, C<esh/eng/ezh> are considered C<pseudo-phonetized> variants of
their middle letter, as well as C<SCHWA> of C<0>.

=item *

C<< <pseudo-fake-***> >> rules are obtained by scanning the names of the Unicode characters for

  WHITE, BLACK, CIRCLED, BUT NOT 

as well as for C<UM> (as C<umify>), paleo-Latin digraphs and C<CON/VEND> 
(as C<paleocontraction-by-last>), doubled-letters
(as C<doubleletter>), C<MIDDLE-WELSH> doubled-letters
(as C<doubleletter-middle-welsh>), C<MODIFIER LETTER> (possibly with C<RAISED>
or C<LOW>; as C<sub/super>).

For example, C<△> may be converted to C<▲=BLACK UP-POINTING TRIANGLE> by C<< <pseudo-fake-black> >>.

=item *

C<< <pseudo-faked-***> >> rules are, first: the special case C<calculated-SYMBOL> converting C<MICRO SIGN> (C<µ>) to
C<GREEK LETTER MU> (C<μ>).  In addition, C<greekize> converts a Latin letter into B<the Latin variant of the corresponding Greek
letter> (e.g., C<f> ⇝ C<LATIN SMALL LETTER PHI=ɸ>).  Finally, C<latinize> does the same, but “starting with a Greek letter”.

=item *

C<< <subst-***> >> Explicitly defined named substitution rules.  A rule is defined in C<Substitutions> section of F<.kbdd>.  E.g.,
the row

  @Zuang_tones=2ƨ,3з,4ч,5ƽ,6ƅ,@Ƨ,#З,$Ч,%Ƽ,^Ƅ

defines the rule C<< <subst-Zuang_tones> >> which, in particular, converts C<#> to C<U+0417=З>.

=item *

Manual prearranged rules C<< <pseudo-manual-***> >> are like <subst-***>, but use the tables supplied in this Perl module.
Currently the following rules are defined:

  phonetized phonetize2 phonetize3 phonetize0	# different “priorities” of translation
  paleo greek2coptic latin2extracoptic
  addline addhline addvline addtilde adddot adddottop addleft addright
  sharpen unsharpen whiten quasisynon amplify turnaround superize subize subize2
  aplbox round hattify

They are intended “to do what the name says”.  For example, C<addleft> either adds left arrow, or adds something on the left of
the glyph.

=item *

C<< <reveal-substkey> >> if it is the only mogrifier, or is at the right end of a mogrifier composition chain: processes only
“the substitution=mirroring keys” (see L<"Input substitution in atomic mogrifiers"> below).

(Obsolete synonym: C<< <reveal-greenkey> >> ???)

=item *

C<< <any-***> >> and C<< <any1-***> >> rules (may be prepended by C<reverse->, as well as C<other-> may be put before these
stars).  The tail C<***> is several words (connected by C<->), optionally appended by a list (joined by C<->) of C<!> followed
by several words-connected-by-C<->.

For example, applying C<< <any-hook-!above> >> is equivalent to joining the results of applying all atomic mogrifiers having C<hook>
in their name (as well as 1-character mutators having it in their lower-case Unicode name), but not having C<above> in these names.
(Note that C<hook> would not be looked at immediately after C<< < >> — but as a special case, C<< <font=***> >> mogrifiers can be
matched by C<font>.)

C<reverse-> flips the order of the list of found atomic mogrifiers.  With C<any1-> the mogrifiers having the word C<AND> in their name
are omitted (so C<< <any1-acute> >> is similar to C<< <any-acute-!AND> >> — and they would not convert C<s> to
C<ṥ=U+1E65=LATIN SMALL LETTER S WITH ACUTE AND DOT ABOVE>).

Currently, C<other-> omits exact matches for the supplied match-string.  (It seems that intent was to omit matches where the
part inside C<< < > >> is an exact match???

=back

=head2 Input substitution in atomic mogrifiers

There are situations when “logically defined” mogrifiers are not enough.  For example, suppose that my mogrifiers produce “very
logical results” when applied to characters C<△> and C<□> — however, I want them to give the same results when applied to characters
C<3> and C<4>.  For this, we may declare that a keypress producing C<3> also has “an invisible output C<△>”; likewise for C<4> and
C<□>.

Such “substitution keys” are defined in the C<AlternCharSubstitutions>, C<AlternCharSubstitutionLayers> and
C<AlternCharSubstitutionFaces> array directives similar to

  @AlternCharSubstitutions=3△,4□,0338∕,06ff÷
  @AlternCharSubstitutionLayers=Blue,Blue-AltGr

here in addition to every key binding being “mirrored” by the corresponding binding in layers C<Blue> + C<Blue-AltGr>, a binding 
resulting in the combining-slash C<U+0338=◌̸> is “mirrored” by the binding producing C<U+2215=DIVISION SLASH=∕>.  When mogrifiers
are applied to a key binding, they are also applied to the “mirrored bindings”, and the results “compete for being included” all
together (on equal footings).

=head2 The C<AssignTo> directive

This is a pseudo-mutator restricting the assignment to special “extension chunks” of a face or a layer.  Recall that usually, to
understand how a particular “position in a layers” corrresponds to a key in a physical keyboard, this module inspects the binding
in the C<BaseLayer> — which is assumed to be “as expected”.  However, some keys are not expected do not produce characters, so
cannot be identified this way.  To circuvent this, we allow chunks-with-known-maps-to-physical keys, named C<FKEYS> (24 standard
keys up to C<F24>), C<ARROWS> and C<NUMPAD> (16 keys arranged in the order of the left table in:

  789/   ⌈⊓⌉⧄
  456*   ⊏□⊐⊠
  123-   ⌊⊔⌋⊟
  0.↲+   ▭⊡▯⊞

 — so one can easily assign the them using rectangle-block).  For example, defining layers C<IsleDigits> and C<DirCharsRect> by
these blocks, the mutator

   AssignTo[ARROWS,16](Id(RectArr))
 
Would bind the arrow keys (on the numeric keyboard, and — on Windows — elsewhere) to the shapes on the right.  (In the defined
layer, pressing C<End> produces C<⌊>.)  Likewise, with

   AssignTo[ARROWS,16](FromTo[ 7√ 9ℊ ](FlipShift(Id(IsleDigits))))

pressing C<Shift-Home> produces C<√>.

 TBC ..................


=head2 The C<Mutate2Self> mutator

Finds “the most convenient default bindings” for the “diacritic key map” when the
following key is non-alphanumeric.  This is based on “the ID” of the prefix key
(this is, for example, in the definition of C<DeadKey_Map0138> the ID is C<U+0138>.

This ID should be a value in the C<Diacritics> section of F<.kbdd>.  The first such
row is taken, and one of the characters in (one of the 7) corresponding lists is
returned.

B<Warning:> in “real keyboard layout”, this is most probably used only as a
fallback — so many of these bindings are going to be overwritten by “other mutators”
in the recipe describing the action of a prefix key.  (Nevertheless, the list below is
made to cover as many of the characters in the sublists accessible as possible,
I<effectively assuming> that many of these bindings are not overwritten. — This is an
obvious contradiction of intents! — Partially remedied by multiple alternative ways of access…)

The unifying factor is that “spacing variants” of diacritics are accessed mostly via C<Space>,
and the “combining variants” are accessed mostly C<AltGr>-modified non-alphabetic keys.
For example, currently:

=over 4

=item *

A double-press of the diacritic key returns the first I<combining character>
(“non-spacing”) from this list.

=item *

Sends C<Space> to the first I<spacing modifier> character of this list (ignoring ASCII chars: those up to C<~=U+007e>).

Likewise, the other characters bound to C<Space> (with C<Shift> and C<AltGr>-modifiers)
are sent to the following Unicode spacing modifiers in the lists.  (More such spacing
modifiers are produced by control-characters — see below.)

=item *

Sends C<|> and C<\> to the first two elements of the “vertical-etc” or “prime-like-or-centered” sublists of
spacing characters.

=item *

Likewise, combining these with C<AltGr> produces combining characters of similar types (penalizing the first 2 in each “non-primary”
subgroup).

=item *

Sends C</> and C<?> to the second pair of elements of the “prime-like-or-centered” sublist of
spacing characters (penalizing as above).

=item *

Sends C<-> and C<_> to the second pair of elements of the “lowered” sublist (and the following sublists) of
spacing characters (penalizing as above).

=item *

Likewise, modifying these with C<AltGr> produces combining characters of similar types.

=item *

Likewise, modifying C<;> and C<:> with C<AltGr> produces the first two of math-combining-characters-for-symbols (or other
combining chars, penalizing as above).

=item *

Likewise, C<[ { ] }> (and C<-> and C<_> with C<AltGr>) produce the third (etc.) math-combining-character-for-symbols (or other
combining chars, penalizing as above).

=item *

C<'> and C<"> (possibly modified by C<AltGr>) produce the second (and the following) combining characters in the list (penalizing
as above).

=item *

As a last resort for combining characters, C<AltGr>-modified C<` 1 2 3 4 5 6 7 8 9 0 = [ ] , .> access third-etc.
combining characters (penalizing as above).

=item *

As a last resort for spacing characters: in addition to what is produced by C<Space> (possibly modified by C<Shift> etc.), more
spacing modifiers are produced by control-characters emitted by a special key (such as C<Enter>, C<Tab>, C<Ctrl-Enter>,
C<Esc> and C<Ctrl>-variants of C<[ ] \> — or C<Esc> — then C<Backspace>, then C<Ctrl>
variants of C<Backspace _ ^ @> — which is the same as C<2>).

(When choosing which non-spacing modifier to choos, the first 2 elements in each
sublist are penalized — they may be easier entered by other ways described above.)

=back

=head2 Other mutators

C<IfPrefix[PREFIX1,PREFIX2,…](RECIPES)> (and C<IfNotPrefox>). — Suitable for
putting into default bindings.  TBC ...................

=head2 Pseudo-mutators for generation of documentation/etc.

A few mutators do not introduce any characters (in other words, they behave as 
C<Empty>) but are used for their side effects: in prefix-key recipes, 
C<PrefixDocs[STRING]> introduces documentation of what the prefix key is intended
for.  Moreover, C<X11symbol[NAME]> gives the “symbol name C<NAME> for C<X11>” keysymbol
(such as C<dead_lowline>) generated by this prefix key.

Likewise, C<HTML_classes[HOW]> allows adding CSS classes to highlight 
parts of HTML output generated by this module, the parts corresponding to selected
characters in a face.

C<HOW> is a comma-separated list, every triple in the
list being C<WHERE,HTML_CLASS,CHARACTERS>.  C<WHERE> is one of C<k>/C<K> (which
add formatting to the key containing one of the C<CHARACTERS>) or C<c>/C<C>
(which add formatting to an individual character displayed on the key),
one can add a digit to C<WHERE> to limit to a particular layer in the face
(useful when a character appears several times in a face).
The lower-case variants select characters basing on the I<base face> of a key.
One can also append C<=CONTEXT> to C<WHERE>, then the class is added only if
C<CONTEXT> appears as one of the options for the HTML output generator.

The CSS rules generated by this module support several classes directly; the
rest should be supported by the user-supplied rules.  The classes with existing
support are: on keys

  to_w from_w				# generate arrows between keys
  from_nw from_ne to_nw to_ne		# generate arrows between keys; will yellow-outline
  pure					# 	unless combined with this
  red-bg green-bg blue-bg		# tint the key as the whole (as background)

On characters

  very-special need-learn may-guess	# provide green/brown/yellow-outlines
  special				# provide blue outline (thick unless combined with 
  thinspecial				#                   <-- this)

options oneRow, startKey, cntKeys: TBC .......................

=head2 Extra CSS classes for documentation

In additional, several CSS classes are auto-generated basing on Unicode
properties of the character.  TBC ........................

=head2 Debugging mutators

If the bit 0x40 of the environment variable C<UI_KEYBOARDLAYOUT_DEBUG> 
(decimal or C<0xHEX>) is set, debugging output for mutators is enabled:

  r ║ ║   ┆ ║ ṙ ṛ ┆ ║ ║ ║ ║ ⓡ ┆
    ║ ║   ┆ ║ Ṙ Ṛ ┆ ║ ║ ║ ║ Ⓡ ┆
    ║ ║ ặ ┆ ║     ┆ ║ ║ ║ ║   ┆
    ║ ║ Ặ ┆ ║     ┆ ║ ║ ║ ║   ┆
  Extracted [ …list… ] deadKey=00b0

The output contains a line per character assigned to the keyboard key (if 
there are 2 layers, each with lc/uc variants, there are 4 lines); empty lines are 
omitted.  The first column indicates the base character (lc of the 1st layer) of 
the key; the separator C<║> indicates C<|>-groups in the mutator.  Above, the first
group produces no mutations, the second group mutates only the characters in
the second layer, and the third group produces two mutations per a character in
the first layer.  The 7th group is also producing mogrifications on the 1st layer.

The next example clarifies C<┆>-separator: to the left of it are mogrifications which 
come in case pairs, to the right are mogrifications where mogrified-lc is not
a case pair of mogrified-uc:

  t ║ ║ ᵵ ║ ꞇ ┆ ʇ ║   ┆ ║
    ║ ║   ║ Ꞇ ┆ ᴛ ║   ┆ ║
    ║ ║   ║   ┆   ║ ꝧ ┆ ║
    ║ ║   ║   ┆   ║ Ꝧ ┆ ║
  Extracted [ …list… ] deadKey=02dc

In this one, C<│> separates mogrifications with different priorities (based on
Unicode ages, whether the atomic mogrifier was compatibility/synthetic one, and the
Unicode block).

  / ║ ║ ║ ║ ║   │ ∴   ║ ║
    ║ ║ ║ ║ ║   │ ≘ ≗ ║ ║
    ║ ║ ║ ║ ║ / │ ⊘   ║ ║
  Extracted [ …list… ] deadKey=00b0

For secondary mogrifiers, where the distinction between C<|||> and C<|> 
matters, some of the C<║>-separators are replaced by C<┃>.  Additionally,
there are two rounds of extraction: first the characters corresponding
to the primary mogrifier are TMP-extracted (from the groups PRE-GROUPS1, 
COMMON); then what is the extracted from COMMON is put back at the 
effective end (at the end of POST-GROUPS2, or, if no such, at 
the beginning of COMMON):

  t ║ ║ ᵵ ┃ ┃ ʇ │   │ ꞇ ┆ ║
    ║ ║   ┃ ┃   │ ᴛ │ Ꞇ ┆ ║
    ║ ║   ┃ ┃   │   │ ꝧ ┆ ║
    ║ ║   ┃ ┃   │   │ Ꝧ ┆ ║
  TMP Extracted: <…list…> from layers 0 0 | 0 0
  t ║ ║ ᵵ ┃ ꞇ ┆ ʇ ┋ ┃ ┆ │ ┆ │   ┆ ║
    ║ ║   ┃ Ꞇ ┆ ᴛ ┋ ┃ ┆ │ ┆ │   ┆ ║
    ║ ║   ┃   ┆   ┋ ┃ ┆ │ ┆ │ ꝧ ┆ ║
    ║ ║   ┃   ┆   ┋ ┃ ┆ │ ┆ │ Ꝧ ┆ ║
  Extracted [ …list… ] deadKey=02dc

In the second part of the debugging output, the part of common which is put
back is separated by C<┋>.

When bit 0x80 is set, much more lower-level debugging info is printed.  The
arrays at separate depth mean: group number, priority, not-cased-pair, layer
number, subgroup, is-uc.  When bit 0x100 is set, the debugging output for
combining atomic mogrifiers is enabled.

=head2 Personalities

A personality C<NAME> is defined in the section C<faces/NAME>.  (C<NAME> may
include slashes - untested???)

An array C<layers> gives the list of layers forming the face.  (As of version
0.03, only 2 layers are supported.)  The string C<LinkFace> is a “fallback”
face: if a keypress is not defined by C<layers>, it would be taken from
C<LinkFace>; additionally, it affects the C<Compose> key bindings: for example,
if C<LinkFace> has C<g> where C<layers> has C<γ>, and there is a binding for 
C<Compose g>, the same binding applies for C<Compose γ>.

TBC .........

=head2 Substitutions

In section C<Substitutions> one defines composition rules which may be
used on par with composition rules extracted from I<Unicode Character Database>.
An array C<FOO> is converted to a hash accessible as C<< <subst-FOO> >> from
a C<Diacritic> filter of satellite face processor.  An element of the the array
must consist of two characters (the first is mapped to the second one).  If
both characters have upper-case variants, the translation between these variants
is also included.

=head2 Classification of diacritics

The section C<Diacritics> contains arrays each describing a class of
diacritic marks.  Each array may contain up to 7 elements, each
consising of diacritic marks in the order of similarity to the
"principal" mark of the array.  Combining characters may be
preceded by horizontal space.  Seven elements should contain:

 Surrogate chars; 8bit chars; Modifiers
 Modifiers below (or above if the base char is below)
 Vertical (or Comma-like or Doubled or Dotlike or Rotated or letter-like) Modifiers
 Prime-like or Centered modifiers
 Combining 
 Combining below (or above if base char is below)
 Vertical combining and dotlike Combining

These lists determine what a C<Mutate2Self> filter of satellite face processor 
will produce when followed by whitespace characters 
(possibly with modifiers) C<SPACE ENTER TAB BACKSPACE>.  (So, if F<.kbdd> file
uses C<Mutate2Self>) this determines what diacritic prefix keys produce.

=head2 Compose Key

The scalar configuration variable C<ComposeKey> controls the ID of the prefix
key to access F<.Compose> composition rules.  The rules are read from files
in the class/object variable; set this variable with

  $self->set__value('ComposeFiles', [@Files]);	# Class name (instead of $self) is OK here

The format of the files is the same as for X11’s F<.Compose> (but C<includes> are
not supported); only compositions starting with C<< <Multi_Key> >>, having no
deadkeys, and (on Windows) expanding to 1 UTF-16 codepoint are processed.  (See
L<“systematic” parts of rules in the standard
F<.XCompose>|"“Systematic” parts of rules in a few .XCompose"> — see lines with postfix C<s>.)

Repeating this prefix twice accesses characters via their HTML/MathML entity names.  The files
are as above (the variable name is C<EntityFiles>); the format is the same as in
F<bycodes.html>.

Repeating this prefix 3 times accesses characters via their C<rfc1345> codes;
the variable C<rfc1345Files> contains files in the format of F<rfc1345.html>.
It is recommended to download these files (or the later flavors)

  http://www.x.org/releases/X11R7.6/doc/libX11/Compose/en_US.UTF-8.html
  http://www.w3.org/TR/xml-entity-names/bycodes.html
  http://tools.ietf.org/html/rfc1345

See L<"SYNOPSIS"> for an example.  Note that this mechanism does not assign this
prefix key to any particular position on the keyboard layout; this should be
done elsewhere.  Implementation detail: if some of these 3 maps cannot be created,
they are skipped (so less than 3 chained maps are created).

For more control, one can make this configuration variable into an array.  The
value C<KEY> is equivalent to the array with elements

  ComposeFiles,dotcompose,warn,KEY
  EntityFiles,entity,warn,,KEY
  rfc1345Files,rfc1345,warn,,KEY

Five comma-separated fields are: the variable controlling the filelist, 
the type of files in the filelist (only the 3 listed types are supported now),
whether to warn when a particular flavor 
of composition table could not be loaded, the global access prefix, the prefix 
for access from the previous element (chained access).

If C<ComposeFiles> (etc.) has more than 1 file, bindings from earlier files
take precedence over bindings from the later ones.  If the same sequence is
bound several times inside a file, a later binding takes precedence.

=head2 Names of prefix keys

Section C<DEADKEYS> defines naming of prefix keys.  If not named there (or in
processed F<.klc> files), the C<PrefixDocs> property will be used; if none, 
Unicode name of the character will be used.

=head2 More than 2 layers and/or exotic modifier keys

This is controlled by C<output_layers>, C<mods_keys_KBD>, C<modkeys_vk> and C<layers_mods_keys>
configuration arrays.  The array C<modkeys_vk> is converted to a hash mapping “a new symbol”
(arbitrary) for a modifier key to the tail of the corresponding Windows’ C<VK_>-code.
For example, one can request that the modifier key known to this F<.kbdd> file as C<rM> is
triggered by C<VK_RGROUPSHIFT> (likewise for C<M>) by using the array

  @modkeys_vk=M,GROUPSHIFT,rM,RGROUPSHIFT

C<@mods_keys_KBD> describes
L<the C<KBD>-bits in the Windows’ key-modifers-bitmap|"Keyboard input on Windows, Part II: The semantic of ToUnicode()">
raised by every modifier.  This array is converted to a hash, the keys can be one of C<S C A>
(for C<Shift>, C<Ctrl>, C<Alt>) possibly prepended by C<l> or C<r> (for “left” and “right”
flavors), as well as the keys defined in C<modkeys_vk> hash.  The values are combinations
of C<S C A K X Y Z T U V W> (for bits from 0x001 to 0x400); the bits C<X Y> have aliases
C<R L> (for C<Roya> and C<Loya>).

For example,

  @mods_keys_KBD=lC,CL,lA,AK,rA,CALZ,M,CAT,rC,CAR

describes the bindings from L<"A convenient assignment of KBD* bitmaps to modifier keys">.

C<@layers_mods_keys> is the list giving the collection of modifiers keys (such as C<lA>, C<C> or C<rC>, etc.)
triggering the given layer.  (Since a layer already covers two states of C<Shift> key, it should not appear.)
For example, if layer 0 is the default (no modifiers), layer 1 is triggered by C<AltGr> (which is C<rA> as “right-C<Alt>),
and layer 2 is triggered by C<AltGr-Menu> (with C<Menu> known to this C<.kbdd> as C<M> — defined by C<@modkeys_vk>), then use

  @layers_mods_keys=,rA,rAM

(We do not describe here how to redefine C<Menu> key to send C<VK_RGROUPSHIFT>; currently one seems to need to edit the
generated C<.h> file; TBC ..................................)

Finally, C<@output_layers> describes how to “fill” these layers.  Currently, the elements may be numbers (the ordinal of the layer
of the current face), or have the form C<prefixNOTSAME=HEX> or C<prefixNOTSAMEcase=HEX> or C<prefix=HEX>.  Here C<HEX> (such as
C<9f03>) is the “id” of a diacritic defined elsewhere in the F<.kbdd> file.  (For example, by defining C<DeadKey_Map9f03>.)

  @output_layers=0,1,prefixNOTSAME=9f03

These “fake” prefix keys are considered to be “fake” and are not emitted “as prefix keys” in the generated C<MSKLC> keyboard
description.

With C<NOTSAME>, the layers of the C<HEX>-face are “squeezed” into one layer.  For this, whatever is accessible anywhere on the
“non-extra” layers of the base face is considered “free”, so the content of the higher layers of the C<HEX>-face may be “moved to
its 0th layer”.  Moreover (unless C<case> is specified), if C<key> and C<AltGr-key> are “not free”, but C<Shift-key> is “free”, then
the content of C<AltGr-key> is moved to the C<Shift-key>.

=head2 Apple keyboards

The mneumonics (“terminator”) shown after C<AltGr_Invert>-prefix or C<Compose>-prefix keys are pressed are controlled by the
settings C<AltGr_Invert_Show> and C<ComposeKey_Show>.  For other prefix keys this is controlled by C<Show[NNNN]> directive on the
C<DeadKey_Map> descriptor.

The name of the layout is controlled via C<LAYOUTNAME> with C<OSX_ADD_VERSION>, or by C<OSX_LAYOUTNAME>.

Duplication of keys on Mac is controlled by the setting C<@Apple_Duplicate> (has a sane default: C<PC_Menu>, C<F20> duplicate
ISO-keys, etc.).  The format is TBC .................

Extra Apple bindings may be inserted by (temporarily???) C<Apple_Override> (by C<Mods+VK> or by C<Prefix+Char>).  TBC .........

=head2 More settings describing the keyboard

C<CapsLOCKoverride>:  Face recipe to use where the “naive rules” of behaviour of C<CapsLock> are not enough.  It is enough if
this recipe defines only the “tricky” positions: the positions in the map which should be affected by C<CapsLock> in the way that
this module cannot deduce.

C<AltGrInv_AltGr_as_Ctrl>: not used???!!!

C<@skip_extra_layers_WIN>: lists C<VK_>-codes (with C<VK_> omitted) of keys on which “extra layers” should be ignored.

C<Prefix_Base_Altern>: the recipe for the face used on Windows as an “alternative base” for generation of prefix key maps.  For
example, when we want to access the binding at the position of C<F9>-key of the target keymap, but the base face does not
emit anything at this position, on Windows such position is not accessible.  However, if C<Kana-F9> emits a string, then
using the face for C<Kana->prefix as C<Prefix_Base_Altern> allows pressing C<Kana-F9> after the prefix key to reach the binding
at the position of C<F9>.

C<WindowsEmitDeadkeyDescrREX> matches the DeadKey descriptions to not include into the generated DLL (to save space).
See L<Windows’ limits for size of the layout DLL|"If data in KEYNAME_DEAD takes too much space, keyboard is mis-installed, and “Language Bar” goes crazy">.
(A nice value with a lot of Compose bindings is C<< ^(?!.*\bCompose\s+(Compose\b|(?!key)\S+)) >>.)

For “unusual” keys, one can use the C<VK> subsection of the face to describe
its scancode.  The keys in this subsection are C<VK_>-names (with omitted C<VK_>), they all define arrays.
the first entry in the array is the scancode.  (Or it may be a list of scancodes, separated by C<|>.  The last scancode is
“the main one” — if there are bindings, this scancode is used on the line of the C<LAYOUT> section of the emitted F<.kbdd> file.
(Although this distinction is going to be eventually lost in the generated C<.C> file!)
If the first entry is empty, the C<VK_>-code is translated to a scancode using the hardwired
tables.  The (optional) remaining entries are the bindings of this key (with the trailing C<@> denoting prefix keys), as in:

  @SPACE=,0020,0138@,0192@,00a0@

defining C<Space> as emitting C<space=0x20> and C<Shift-Space> as the deadkey C<0x0138> (the following values are for the
corresponding C<AltGr> bindings).

(This C<VK> subsection may be inherited from the [grand]parents of the given C<face/******> section.)

For more settings, such as C<@Prefix_Force_Altern> — as well as the settings listed below: TBC ..................

  Diacritics_Limits/ALL
  [face_shortcuts]

  ExtraScanCodesWin
  Auto_Diacritic_Start
  Flip_AltGr_Key
  Diacritic_if_undef
  DeadChar_DefaultTranslation
  DeadChar_32bitTranslation		replacement char used (instead of "?") when a prefix map results in a multi-codepoint value
					(such values cannot be emitted on Windows) or when it is in AltGr-invertor map, and results
					in a prefix key which accesses this same prefix map (so this “gives a loop of length 1).
  faceDeadKeys
  ExportDeadKeys
  extra_report_DeadChar
  char2key_prefer_first
  char2key_prefer_last
  Import_Prefix_Keys			(Amended by DeadKey_Add*** recipes)
  chainAltGr
  PrefixChains
  DeadKey_Map
  TableSummaryAddHTML
  faceDeadKeys2
  LayoutTable_add_double_prefix_keys

=head2 CAVEATS for German/French/BÉPO/Neo keyboards

Non-US keycaps: the character "a" is on C<(VK_)A>, but its scancode is now different.
E.g., French's A is on 0x10, which is US's Q.  Our table of scancodes is
currently hardwired.  Some pictures and tables are available on

  http://bepo.fr/wiki/Pilote_Windows

With this module, the scancode and the C<VK_>-code for a position in a layout
are calculated via the C<BaseLayer> configuration variable; the first recognized 
character at the given position of this layer is translated to
the C<VK_>-code (using a hardwired table).  The hardwired mapping of C<VK_>-codes 
to scancodes can be modified via the C<VK> subsection.

=head1 Keyboards: on ease of access (What makes an easy-to-use keyboard layout)

The content of this section has no I<direct> relationship to the functionality
of this module.  However, we feel that it is better that the user of this
module understands these concerns.  Moreover, it is these concerns which
lead to the principles underlying the functionality of this module.

=head2 On the needs of keyboard layout users

Let's start with trivialities: different people have different needs
with respect to keyboard layouts.  For a moment, ignore the question
of the repertoir of characters available via keyboard; then the most 
crucial distinction corresponds to a certain scale.  In absense of  
a better word, we use a provisional name "the required typing speed".

One example of people on the "quick" (or "rabid"?) pole of this scale are 
people who type a lot of text which is either "already prepared", or for 
which the "quality of prose" is not crucial.  Quite often, these people may
type in access of 100 words per minute.  For them, the most important
questions are of physical exhaustion from typing.  The position
of most frequent letters relative to the "rest" finger position, whether
frequently typed together letters are on different hands (or at least
not on the same/adjacent fingers), the distance fingers must travel
when typing common words, how many keypresses are needed to reach 
a letter/symbol which is not "on the face fo the keyboard" - their
primary concerns are of this kind.

On the other, "deliberate", pole these concerns cease to be crucial.
On this pole are people who type while they "create" the text, and
what takes most of their focus is this "creation" process.  They may
"polish their prose", or the text they write may be overburdened by
special symbols - anyway, what they concentrate on is not the typing itself.

For them, the details of the keyboard layout are important mostly in
the relation to how much they I<distract> the writer from the other
things the writer is focused on.  The primary question is now not
"how easy it is to type this", but "how easy it is to I<recall> how
to type this".  The focus transfers from the mechanics of finger movements
to the psycho/neuro/science of memory.

These questions are again multifaceted: there are symbols one encounters
every minute; after you recall once how to access them, most probably
you won't need to recall them again - until you have a long interval when
you do not type.  The situation is quite different with symbols you need
once per week - most probably, each time you will need to call them again
and again.  If such rarely used symbols/letters are frequenct (since I<many>
of them appear), it is important to have an easy way to find how to type them;
on the other hand, probably there is very little need for this way to
be easily memorizable.  And for symbols which you need once per day, one needs
both an easy way to find how to type them, I<and> the way to type them should
better be easily memorizable.

Now add to this the fact that for different people (so: different usage
scenarios) this division into "all the time/every minute/every day/every week"
categories is going to be different.  And one should not forget important
scenario of going to vacation: when you return, you need to "reboot" your
typing skills from the dormant state.

=head2 On “mixing” several “allied” layouts

On the other hand, note that the questions discussed above are more or less
orthogonal: if the logic of recollection requires ω to be related in some 
way to the W-key,
then it does not matter where the W-key is on the keyboard - the same logic
is applicable to the QWERTY base layou	t, or BÉPO one, or Colemak, or Dvorak.
This module concerns itself I<only> with the questions of "consistency" and
the related question of "the ease of recall"; we care only about which symbols
relate to which "base keys", and do not care about where the base key sit on
the physical keyboard.

B<EXCEPTIONS:> The “main island” of the keyboard contains a 4×10 rectangle
of keys.  So if a certain collection of special keys may be easily memorized
as a rectangular table, it is nice to be able to map this table to the
physical keyboard layout.  This module contains tool making this task easy.

Now consider the question of the character repertoir: a person may need ways
to type "continuously" in several languages; quite often one must must type
a “standalone” foreign word in a sentence; in addition to this, there may
be a need to I<occasionally> type "standalone" characters or symbols outside
the repertoir of these languages.  Moreover, these languages may use different
scripts (such as Polish/Bulgarian/Greek/Arabic/Japanese), or may share a
"bulk" of their characters, and differ only in some "exceptional letters".
To add insult to injury, these "exceptional letters" may be rare in the language
(such as ÿ in French or à in Swedish) or may have a significant letter frequency 
(such as é in French) or be somewhere in between (such as ñ in Spanish).

And the non-language symbols do not need to be the I<math> symbols (although
often they are).  An Engish-language discussion of etimology at the coffee table 
may lead to a need to write down a word in polytonic greek, or old norse;
next moment one would need to write a phonetic transcription in IPA/APA
symbols.  A discussion of keyboard layout may involve writing down symbols
for non-character keys of the keyboard.  A typography freak would optimize
a document by fine-tuned whitespaces.  Almost everybody needs arrows symbols,
and many people would use box drawing characters if they had a simple access
to them.

Essentially, this means that as far as it does not impacts other accessibility
goals, it makes sense to have unified memorizable access to as many
symbols/characters as possible.  (An example of impacting other aspects:
MicroSoft's (and IBM's) "US International" keyboards steal characters C<`~'^">:
typing them produces "unexpected results" - they are deadkeys.  This
significantly simplifies entering characters with accents, but makes it
harder to enter non-accented characters.)

=head2 The simplest rules of design of “large” keyboard layouts

One of the most known principles of design of human-machine interaction
is that "simple common tasks should be simple to perform, and complicated
tasks should be possible to perform".  I strongly disagree with this
principle - IMO, it lacks a very important component: "a gradual increase
in complexity".  When a certain way of doing things is easy to perform, and another 
similar way is still "possible to perform", but on a very elevated level 
of complexity, this leads to a significant psychological barrier erected
between these two ways.  Even when switching from the first way to the other one 
has significant benefits, this barrier leads to self-censorship.  Essentially,
people will 
ignore the benefits even if they exceed the penalty of "the elevated level of 
complexity" mentioned above.  And IMO self-censorship is the worst type of 
censorship.  (There is a certain similarity between this situation and that
of "self-fulfilled prophesies".  "People won't want to do this, so I would not
make it simpler to do" - and now people do not want to do this...)

So I would add another clause to the law above: "and moderately complicated
tasks should remain moderately hard to perform".  What does it tell us in
the situation of keyboard layout?  One can separate several levels of
complexity.

=over 10

=item Basic:

There should be some "base keyboards": keyboard layouts used for continuous 
typing in a certain language or script.  Access from one base keyboard to
letters of another should be as simple as possible.

=item By parts:

If a symbol can be thought of as a combination of certain symbols accessible
on the base keyboard, one should be able to "compose" the symbol: enter it
by typing a certain "composition prefix" key then the combination (as far
as the combination is unambiguously associated to one symbol).

The "thoughts" above should be either obvious (as in "combining a and e should 
give æ") or governed by simple mneumonic rules; the rules should cover as
wide a range as possible (as in "Greek/Coptic/Hebrew/Russian letters are
combined as G/C/H/R and the corresponding Latin letter; the correspondence is 
phonetic, or, in presence of conflicts, visual").

=item Quick access:

As many non-basic letters as possible (of those expected to appear often)
should be available via shortcuts.  Same should be applicable to starting
sequences of composition rules (such as "instead of typing C<StartCompose>
and C<'> one can type C<AltGr-'>).

=item Smart access

Certain non-basic characters may be accessible by shortcuts which are not
based on composition rules.  However, these shortcuts should be deducible
by using simple mneumonic rules (such as "to get a vowel with `-accent,
type C<AltGr>-key with the physical keyboard's key sitting below the vowel key").

=item Superdeath:

If everything else fails, the user should be able to enter a character by
its Unicode number (preferably in the most frequently referenced format:
hexadecimal).

=back

=over

B<NOTE:> This does not seem to be easily achievable, but it looks like a very nifty
UI: a certain HotKey is reserved (e.g., C<AltGr-AppMenu>);
when it is tapped, and a character-key is pressed (for example, B<B>) a
menu-driven interface pops up where user may navigate to different variants
of B, Beta, etc - each of variants with a hotkey to reach I<NOW>, and with
instructions how to reach it later from the keyboard without this UI.

Also: if a certain timeout passes after pressing the initial HotKey, an instruction
what to do next should appear.

=back

=head2 The finer rules of design of “large” keyboard layouts

Here are the finer points elaborating on the levels of complexity discussed above:

=over 4

=item 1

It looks reasonable to allow "fuzzy mneumonic rules": the rules which specify
several possible variants where to look for the shortcut (up to 3-4 variants).
If/when one forgets the keying of the shortcut, but remembers such a rule,
a short experiment with these positions allows one to reconstruct the lost
memory.

=item 2

The "base keyboards" (those used for continuous typing in a certain language
or script) should be identical to some "standard" widely used keyboards.
These keyboards should differ from each other in position of keys used by the
scripts only; the "punctuation keys" should be in the same position.  If a
script B has more letters than a script A, then a lot of
"punctuation" on the layout A will be replaced by letters in the layout B.
This missing punctuation should be made available by pressing a modifier
(C<AltGr>? compare with L<MicroSoft's Vietnamese keyboard|http://www.microsoft.com/resources/msdn/goglobal/keyboards/kbdvntc.html>'s top row).

=item 3

If more than one base keyboard is used, there must be a quick access:
if one needs to enter one letter from layout B when the active layout is A, one
should not be forced to switch to B, type the letter, then switch back
to A.  It should better be available I<also> on a prefixed combination "C<Quick_Access_Key letter>".

=item 4

One should consider what the C<Quick_Access_Key> does when the layouts A
and B are identical on a particular key (e.g., punctuation).  One can go with the "Occam's
razor" approach and make the C<Quick_Access_Key> prefix into the do-nothing identity map.
The alternative is make it access some symbols useful both for
script A and script B.  It is a judgement call.

Note that there is a gray area when layouts A and B are not identical,
but a key C<K> produces punctuation in layout A, and a letter in layout
B.  Then when in layout B, this punctuation is available on C<AltGr-key>,
so, in principle, C<Quick_Access_Key> would duplicate the functionality
of C<AltGr>.  Compare with "there is more than one way to do it" below;
remember that OS (or misbehaving applications) may make some keypresses
"unavailable".  I feel that in these situations, “having duplication” is
a significant advantage over “having some extra symbols available”.

=item 5

The considerations in two preceding parts are applicable also in the
case when there are more “allied” layouts than A and B.  Ways to make it possible
are numerous: one can have several alternative C<Quick_Access_Key>’s, B<and> one
can use a I<repeated> prefix key C<Quick_Access_Key>.  With a large enough
collection of layouts, a combination of both approaches may be visualized
as a chain of layout

S< >… C<L_Quick³ L_Quick² L_Quick> B<Base> C<R_Quick R_Quick² R_Quick³> …

here we have two quick access prefix keys, the left one C<L_Quick>, and the right one
C<R_Quick>.  Superscripts C<² ³ …> mean “pressing the prefix key several times”;
the prefix keys move one left/right along the chain of layouts.

=item 6

The three preceding parts were concerned with entering one character from
an “allied” layout.  To address another frequent need, entering one word
from an “allied” layout, yet another approach may be needed.  The solution may
be to use a certain combination of modifier keys.  (How to choose useful
combinations?  See: L<"A convenient assignment of KBD* bitmaps to modifier keys">.)

(Using “exotic” modifier keys may be impossible in some badly coded applications.
This should not stop one from implementing this feature: sometimes one has a choice
from several applications performing the same task.  Moreover, since this feature
is a “frill”, there is no pressing need to have it I<always> available.)

=item 7

Paired symbols (such as such as ≤≥, «», ‹›, “”, ‘’ should be put on paired 
keyboard's keys: <> or [] or ().

=item 8

"Directional symbols" (such as arrows) should be put either on numeric keypad
or on a 3×3 subgrid on the letter-part of the keyboard (such as QWE/ASD/ZXC).
(Compare with [broken?] implementation in L<Neo2|http://www.mzuther.de/en/contents/osd-neo2>.)

=item 9

for symbols that are naturally thought of as sitting in a table, one can 
create intuitive mapping of quite large tables to the keyboard.  Split each
key in halves by a horizontal line, think of C<Shift-key> as sitting in the
top half.  Then ignoring C<`~> key and most of punctuation on the right
hand side, keyboard becomes an 8×10 grid.  Taking into account C<AltGr>
modifier (either as an extra bit, or as splitting a key by a horizontal line),
one can map up to 8×10×2 (or 8×20) table to a keyboard.

B<Example:> Think of L<IPA consonants|http://en.wikipedia.org/wiki/International_Phonetic_Alphabet#Consonants>.

=item 10

Cheatsheets are useful.  And there are people who are ready to dedicate a
piece of their memory to where on a layout is a particularly useful to them
symbol.  So even if there is no logical position for a certain symbol, but
there is an empty slot on layout, one should not hesitate in using this slot.

However, this I<will be> distractive to people who do not want to dedicate
their memory to "special cases".  So it makes sense to have three kinds of
cheatsheets for layouts: one with special cases ignored (useful for most 
people), one with all general cases ignored (useful for checks "is this 
symbol available in some place I do not know about" and for memorization),
and one with all the bells and whistles.

(Currently this module allows emitting HTML keyboard layouts with such
information indicated by classes in markup.  The details may be treated
by the CSS rules.)

=item 11

"There is more than one way to do it" is not a defect, it is an asset.
If it is a reasonable expectation to find a symbol X on keypress K', and
the same holds for keypress K'' I<and> they both do not conflict with other
"being intuitive" goals, go with both variants.  Same for 3 variants, 4
- now you get my point.

B<Example:> The standard Russian phonetic layout has Ё on the C<^>-key; on the
other hand, Ё is a variant of Е; so it makes sense to have Ё available on
C<AltGr-Е> as well.  Same for Ъ and Ь.

=item 12

Dead keys which are "abstract" (as opposed to being related to letters
engraved on physical keyboard) should better be put on modified state
of "zombie" keys of the keyboard (C<SPACE>, C<TAB>, C<CAPSLOCK>, C<MENU_ACCESS>).

B<NOTE:> Making C<Shift-Space> a prefix key may lead to usability issues
for people used to type CAPITALIZED PHRASES by keeping C<Shift> pressed
all the time.  As a minimum, the symbols accessed via C<Shift-SPACE key>
should be strikingly different from those produced by C<key> so that
such problems are noted ASAP.  Example: on the first sight, producing
C<NO-BREAK SPACE> on C<Shift-Space Shift-Space> or C<Shift-Space Space>
looks like a good idea.  Do not do this: the visually undistinguishable
C<NO-BREAK SPACE> would lead to significantly hard-to-debug problems if
it was unintentional.

=back


=head2 Explanation of keyboard layout terms used in the docs

The aim of this module is to make keyboard layout design as simple as 
possible.  It turns out that even very elaborate designs can be made
quickly and the process is not very error-prone.  It looks like certain
venues not tried before are now made possible; at least I'm not aware of 
other attempts in this direction.  One can make layouts which can be
"explained" very concisely, while they contain thousand(s) of accessible
letters.

Unfortunately, being on unchartered territories, in my explanations I'm 
forced to use home-grown terms.  So be patient with me...  The terms are
I<keyboard layout group>, I<keyboard>, I<face> and I<layer>.  (One may want compare them
with what ISO 9995 does: L<http://en.wikipedia.org/wiki/ISO/IEC_9995>….  On
the other hand, most parts of ISO 9995 look as remote from being ergonomic
[in the sense discussed in these sections] as one may imagine!)

In what follows,
the words I<letter> and I<character> are used interchangeably.  A I<key> 
means a physical key on a keyboard tapped (possibly together with 
one of modifiers C<Shift>, C<AltGr> - or, rarely, L<[right] C<Control>|http://www.microsoft.com/resources/msdn/goglobal/keyboards/kbdcan.html>;
more advanced layouts may use “extra” modifiers).  The key C<AltGr> 
is often marked as such on the keycap, otherwise it is just the "right" C<Alt> key; at least
on Windows, for many simple layouts it can be replaced by C<Control-Alt>.  What is a I<prefix key>? 
Tapping such a key does not produce any letter, but modifies what the next
keypress would do (sometimes it is called a I<dead key>; in C<ISO 9995> terms,
it is probably a I<latching key>.  Sometimes, prefix keys may be “chained”; then
insertion of a character happens not on the second keypress, but on the third one [or fourth/etc]).

To describe which character (or a prefix) is produced by a keypress one must describe
I<the context>: which prefix keys were already tapped, and which modifier keys are
currently pressed.  It is natural to consider the C<Shift> modifier specially: let’s
remove it from the context; now given a context, a keypress may produce two characters:
one with C<Shift>, one without.  A I<layer> describe such a pair of characters (or
prefixes) for every key of the keyboard.

So, the plain I<layer> is the part of keyboard layout accessible by using only 
non-prefix keys (possibly in combination with C<Shift>).  Many keyboard layouts
have up to 2 additional layers accessible without prefix keys: the C<AltGr>-layer and C<Control>-layer.  

On the simplest layouts, such as "US" or "Russian",  there is no prefix keys or “extra” 
modifier keys - 
but this is only feasible for languages which use very few characters with 
diacritic marks.  However, note that most layouts do not use 
C<Control>-layer - sometimes it is claimed that this causes problems with
system/application interaction.

A I<face> consists of the layers of the layout accessible with a particular
combination of prefix keys.  The I<primary face> consists of the plain layer 
and “additional prefix-less layers” of the layout;
it is the part of layout accessible without switching "sticky state" and 
without using prefix keys.  There may be up to 3 layers (Plain, C<AltGr>, C<rightControl>)
per face on the standard Windows keyboard layouts.  A I<secondary face> is a face exposed after pressing 
a prefix key (or a chain of prefix keys).

A I<personality> is a collection of faces: the primary face, plus one face per
a defined prefix-key (or a prefix chain).  Finally, a I<keyboard layout group> is a collection of personalities
(switchable by sticky keys [like C<CapsLock>] and/or in other system-specific ways)
designed to work smoothly together.  For example, in multi-script settings, there may be:

=over 4

=item *

one personality per script (e.g., Latin/Greek/Cyrillic/Arabic); 

=item *

every personality may have several script-specific additional (“satellite”) faces (one per a particular diacritic for Latin
personality, one for regional/historic “flavors” for Cyrillic personality, one per aspiration type for Greek personality, etc); 

=item *

every personality may also have “liason” faces accessing the base faces of other personalities;

=item *

with chained prefixes, it is easy to design intuitive ways to access satellite faces of other personalities;
then every personality will also contain the satellite faces of I<other> personalities (on different prefix chains!).

=item *

For access to “technical symbols” (currencies/math/IPA etc), the personalities may share a certain collection
of faces assigned to the same prefix keys.

=back

=head2 Example of keyboard layout groups

Start with a I<very> elaborate example (it is more or less a simplified variant
of the L<C<izKeys> layout|http://k.ilyaz.org>.  A keyboard layout group may consist of 
phonetically matched Latin and Cyrillic personalities, and visually matched Greek 
and Math personalities.  Several prefix-keys may be shared by all 4 of these 
personalities; in addition, there would be 4 prefix-keys allowing access to primary 
faces of these 4 personalities from other personalities of the group.  Also, there 
may be specialised prefix keys tuned for particular need of entering Latin script, 
Cyrillic script, Greek script, and Math.

Suppose that there are 8 specialized-for-Latin prefix-keys (for example, name them
   
  grave/tilde/hat/breve/ring_above/macron/acute/diaeresis

although in practice each one of them may do more than the name suggests).  
Then the Latin personality will have the following 13 faces:

   Primary/Latin-Primary/Cyrillic-Primary/Greek-Primary/Math-Primary
   grave/tilde/hat/breve/ring_above/macron/acute/diaeresis

B<NOTE:>   Here Latin-Primary is the face one gets when one presses
the Access-Latin prefix-key when in Latin mode; it may be convenient to define 
it to be the same as Primary - or maybe not.  For example, if one defines it 
to be Greek-Primary, then this prefix-key has a convenient semantic of flipping
between Latin and Greek modes for the next typed character: when in
Latin, C<Latin-PREFIX-KEY a> would enter α, when in Greek, the same keypresses
[now meaning "Latin-PREFIX-KEY α"] would enter "a".

Assume that the only “extra” modifier used by the layout is C<AltGr>.  Then each of 
these faces would consists of two layers: the plain one, and the C<AltGr>- 
one.  For example, pressing C<AltGr> with a key on Greek face could add
diaeresis to a vowel, or use a modified ("final" or "symbol") "glyph" for
a consonant (as in σ/ς θ/ϑ).  Or, on Latin face, C<AltGr-a> may produce æ.  Or, on a
Cyrillic personality, AltGr-я (ya) may produce ѣ (yat').

Likewise, the Greek personality may define special prefix-keys to access polytonic 
greek vowels.  “Chaining” these prefix keys after the C<Greek-Primary> prefix
key would make it possible to enter polytonic Greek letters from non-Greek
personalities without switching to the Greek personality.

With such a keyboard layout group, to type one Greek word in a Cyrillic text one 
would switch to the Greek personality, then back to Cyrillic; but when all one 
need to type now is only one Greek letter, it may be easier to use the 
"Greek-PREFIX-KEY letter" combination, and save switching back to the
Cyrillic personality.  (Of course, for this to work the letter should be 
on the primary face of the Greek personality.)

How to make it possible to easily enter a short Greek word when in Cyrillic mode?
If one uses one more “extra” modifier key (say, C<ApplicationMenu>), one could
reserve combinations of modifiers with this key to “use” other personality.  Say,
C<ApplicationMenu-b> would enter Greek β, C<AltGr-ApplicationMenu-b> would enter
Cyrillic б, etc.

=head2 “Onion rings” approach to keyboard layout groups

Looks too complicated?  Try to think about it in a different way: there
are many faces in a keyboard layout group; break them into 3 "onion rings":

=over 4

=item I<CORE> faces 

one can "switch to a such a face" and type continuously using 
this face without pressing prefix keys.  In other words, these faces 
can be made "active" (in an OS-dependent way).
     
When one CORE face is active, the letters in another CORE face are still 
accessible by pressing one particular prefix key before each of these
letters.  This prefix key does not depend on which core face is 
currently "active".

=item  I<Universally accessible> faces 

one cannot "switch to them", however, letters
in these faces are accessible by pressing one particular prefix key
before this letter.  This prefix key does not depend on which
core face is currently "active".

=item I<satellite> faces 

one cannot "switch to them", and letters in these faces
are accessible from one particular core face only.  One must press a 
prefix key before every letter in such faces.

(In presence of “chained prefixes”, the description is less direct:
these faces are much easier to access from one particular CORE face.
From another CORE face, one must preceed this prefix key by the
access-that-CORE-face prefix.)

=back

For example, when entering a mix of Latin/Cyrillic scripts and math,
it makes sense to make the base-Latin and base-Cyrillic faces into
the core; it is convenient when (several) Math faces and a Greek face 
can be made universally accessible.  On the other hand, faces containing
diacritized Latin letters and diacritized Cyrillic letters should better
be made satellite; this avoids a proliferation of prefix keys which would
make typing slower.

Comparing to the terms of the preceding section, the CORE faces correspond
to personalities.  A personality I<imports> the base face from other personalities;
it may also import satellite faces from other personalities.

In a personality, one should make access to satellite faces, the imported
CORE faces, and the universally accessible faces as simple as possible.
If “other” satellite faces are imported, the access to them may be more
cumbersome.

=head2 Large Latin layouts: on access to diacritic marks

Every prefix key has a numeric I<ID>.  On Windows, there are situations
when this numeric ID may be visible to the user.  (This module makes every
effort to make this happen as rarely as possible.  However, this effort
blows up the size of the layout DLL, and at some moment one may hit the
L<Windows’ limits for size of the layout DLL|"If data in KEYNAME_DEAD takes too much space, keyboard is mis-installed, and “Language Bar” goes crazy">.
To reduce the size of the DLL, the module makes a triage, and won’t protect the ID from leaking in some rare cases.)
When such a leak happens, what the user sees is the character with this codepoint.
So it makes sense to choose the ID to be the codepoint of a character “related
to what the prefix key ‘does’”.

The logic: if the prefix keys add some diacritic, the ID should be the 
I<primary non-ASCII spacing modifier letter> related to this diacritic: either
C<Latin-1>’s 8-bit characters with high bit set, or
if none with the needed glyph, suitable non-Latin-1 "spacing modifier letters" or
"spacing clones of diacritics".

If followed by “special keys”, one should be able to access other related 
modifier letters and combining characters (see L<"Classification of diacritics">
and the section C<Diacritics> in L<the example
layout|https://search.cpan.org/~ilyaz/UI-KeyboardLayout/examples/izKeys.kbdd>);
one possible convenient choice is:

=over 4

=item The second press of the prefix key

The principal combining mark;

=item SPACE

The primary non-ASCII spacing modifier letter;

=item SPACE-related (NBSP, or C<Shift-SPACE>, or C<AltGr-SPACE>)

The secondary/ternary/etc modifier letter;

=item digits (possibly with C<Shift> and/or C<AltGr>)

related combining marks (with C<Shift> and/or C<AltGr>, other categories
from L<"Classification of diacritics">).

=item C<'> or C<"> (possibly with C<AltGr>)

secondary/ternary/etc combining marks (or, if these are on 
digits, replace by prime-shape modifier chars).

=back

=head2 The choice of prefix keys

Some stats on prefix keys: C<ISO 9995-3> uses 41 prefix keys for diacritics (but 15 are fake, see below!);
L<Apple’s C<US Extended> uses 24|http://www.macfreek.nl/memory/Mac_Keyboard_Layout> (not counting prefix №, action=specials
on L<the code for this layout|https://raw.github.com/lreddie/ukelele-steps/master/USExtended.keylayout>:

   "'@2#3%5^67*8AaCcEeGghHjJ   KkMmNnQqRrsUuvwWYyZz‘’“  default=terminator
  №ʺʹƧƨƐɛƼƽƄƅ⁊ȢȣƏəƆɔƎǝƔɣƕǶƞȠ  K’ĸƜɯŊŋƢƣƦʀſƱʊʌƿǷȜȝƷʒʻʼʽ  №

); bépo uses 20, while EurKey uses 8, and L<Apple’s C<US> uses 5|http://www.macfreek.nl/memory/Mac_Keyboard_Layout>.  
On the other end of spectrum, there are 10 US keyboard keys with "calculatable" relation to Latin diacritics:

  `~^-'",./? --- grave/tilde/hat/macron/acute/diaeresis/cedilla/dot/stroke/hook-above

To this list one may add a "calculatable" key C<$> as I<the currency prefix>;
on the other hand, one should probably remove C<?> since C<AltGr-?> should better
be "set in stone" to denote C<¿>.  If one adds Greek, then the calculatable positions
for aspiration are on C<[ ]> (or on C<( )>).  Of widely used Latin diacritics, this
leaves out I<ring/hacek/breve/horn/ogonek/comma> (and doubled I<grave/acute>);
these diacritics should be either “mixed in” with similar "calculatable" diacritics
(for example, <AltGr-,> may either create a character with cedilla, or with
ogonek — depending on the character), or should be assigned on less intuitive positions.

Extra prefix keys of L<C<ISO 9995-3>|http://www.pentzlin.com/info2-9995-3-V3.pdf>: 
I<breve↓/circumflex↓/comma↑/dot↓/↺breve/long-solidus/low-line/macron↓/short-stroke/vertical-line↑↓>.
Additionally, the following diacritics produce only 4 precomposed characters: ṲṳḀḁ, so their use as prefix characters is questionable:
I<candrabindu/comma↗↓/diaeresis↓/²breve(↓)/²↺breve/²macron(↓)/²tilde/²vertical-line↑↓/=↓/hook↑/ring↓>
(Here ↓ is a shortcut for C<below>, same with ↑ for C<above>, and ↗ for C<above right>; ↺ means C<inverted>, and ² means C<double>.
Combined arrows expand to multiple diacritics.)

(Keep in mind that this list is just a conjecture; the standard does not distinguish combining characters
and prefix keys, so it is not clear which keypresses produce combining characters, and which are prefix keys.)

=head2 What follows is partially deprecated

Parts of following subsections is better explained in
L<visual description of the izKeys layout|http://k.ilyaz.org/iz/windows/izKeys-visual-maps.html>;
some other parts duplicate 

=head2 On principles of intuitive design of Latin keyboard

Using tricks described below, it is easy to create a convenient map of vowels
with 3 diacritics `¨´ to the QWERTY keyboad.  However, some common
(meaning: from Latin-1–10 of ISO 8859) letters from Latin alphabet 
cannot be composed this way; they are  B<ÆÐÞÇĲØŒß>
(one may need to add B<ªº>, as well as B<¡¿> for non-alphabetical symbols). It is crucial 
that these letters may be entered by an intuitively clear key of the keyboard.
There is an obvious ASCII letter associated to each of these (e.g., B<T> associated to the thorn
B<Þ>), and in the best world just pressing this letter with C<AltGr>-modifier
would produce the desired symbol.

  Note that ª may be associated to @; then º may be mapped to the nearby 2.

There is only one conflict: both B<Ø>,B<Œ> "want" to be entered as C<AltGr-O>;
this is the ONLY piece of arbitrariness in the design so far.  After
resolving this conflict, C<AltGr>-keys B<!2ASDCTIO?> are assigned their meanings,
and cannot carry other letters (call them the “stuck in stone keys”).

(Other keys "stuck in stone" are dead keys: it is important to have the
glyph etched on these keyboard's keys similar to the task they perform.)

Then there are several non-alphabetical symbols accessible through ISO 8859
encodings.  Assigning them C<AltGr>- access is another important task to perform.
Some of these symbols come in pairs, such as ≤≥, «», ‹›, “”, ‘’; it makes
sense to assign them to paired keyboard's keys: <> or [] or ().

However, this task is in conflict of interests with yet another (!) task, so
let us explain the needs answered by that task first.

One can always enter accented letters using dead keys; but many people desire a
quickier way to access them, by just pressing AltGr-key (possibly with
shift).  The most primitive keyboard designs (such as IBM International
or Apple’s US (Extended)

   http://www.borgendale.com/uls.htm
   http://www.macfreek.nl/memory/Mac_Keyboard_Layout

) omit this step and assign only the NECESSARY letters for AltGr- access.
(Others, like MicroSoft International, assign only a very small set.)

This problem breaks into two tasks, choosing a repertoir of letters which
will be typable this way, and map them to the keys of the keyboard.
For example, EurKey choses to use ´¨`-accented characters B<AEUIO> (except
for B<Ỳ>), plus B<ÅÑ>; MicroSoft International does C<ÄÅÉÚÍÓÖÁÑß> only (and IBM
International does
none); Bepo does only B<ÉÈÀÙŸ> (but also has the Azeri B<Ə> available - which is
not in ISO 8819 - and has B<Ê> on the 105th key "C<2nd \|>"),
L<Mac US|http://web.archive.org/web/20061126222551/http://homepage.mac.com/thgewecke/kblayout.jpg> has none
(at least if one does not count uc characters without lc counterparts), same for L<Mac Extended|http://www.typophile.com/node/62127>

   http://bepo.fr/wiki/Manuel
   http://bepo.fr/wiki/Utilisateur:Masaru					# old version of .klc
   http://www.jlg-utilities.com/download/us_jlg.klc
   http://tlt.its.psu.edu/suggestions/international/accents/codemacext.html
		or look for "a graphic of the special characters" on
   http://web.archive.org/web/20080717203026/http://homepage.mac.com/thgewecke/mlingos9.html

=head2 Our solution

First, the answer (the alternative, illustrated description is on
L<the visual maps list|http://k.ilyaz.org/windows/izKeys-visual-maps.html#altgr-latin>):

=over 10

=item Rule 0:

non-ASCII letters which are not accented by B<` ´ ¨ ˜ ˆ ˇ ° ¯ ⁄> are entered by
C<AltGr>-keys "obviously associated" to them.  Supported: B<ÆÐÞÇĲŒß>.
 
=item Rule 0a: 

Same is applicable to B<Ê> and B<Ñ>.

=item Rule 1:

Vowels B<AEYUIO> accented by B<¨´`> are assigned the so called I<"natural position">:
3 “alphabetic” rows of keyboard are allocated to accents (B<¨> is the top, B<´> is the middle, B<`> is
the bottom row of 3 alphabetic-rows on keyboard - so B<À> is on B<ZXCV>-row),
and are on the same diagonal as the base letter.  For left-hand
vowels (B<A>,B<E>) the diagonal is in the direction of \, for right hand
voweles (B<Y>,B<U>,B<I>,B<O>) - in the direction of /.

=item Rule 1a: 

If the "natural position" is occupied, the neighbor key in the
direction of "the other diagonal" is chosen.  (So for B<A>,B<E> it is
the /-diagonal, and for right-hand vowels B<YUIO> it is the \-diag.)

=item Rule 1b: 

This neighbor key is below unless the key is on bottom row - then it is above.

Supported by rules "1": all but B<ÏËỲ>.

=item Rule 2:  

Additionally, B<Å>,B<Ø>,B<Ì> are available on keys B<R>,B<P>,B<V>.
B<ª> is on B<@>, and B<º> is on the nearby B<2>.

=back

=head2 Clarification:

B<0.> If you remember only Rule 0, you still can enter all Latin-1 letter using
Rule 0; all you need to remember that most of the dead keys are at “obvious”
positions: for L<C<izKeys>|http://k.ilyaz.org> it is B<`';"~^.,-/> for B<`´¨¨˜ˆ°¸¯ ̸>
(B<¨> is repeated on B<;">!) and B<6> for B<ˇ> (memorizable as “opposite” of B<^> for B<ˆ>).
   
  (What the rule 0 actually says is: "You do not need to memorize me". ;-)

(If you need a diacritic which is only I<similar> to one of the listed diacritics,
there is a good chance that the dead key above L<will do what you need|"On possibilities of merging 2 diacritics on one prefix key">.)
   
B<1.> If all you remember are rules 1,1a, you can calculate the position of the
AltGr-key for AEYUIO accented by `´¨ up to a choice of 3 keys (the "natural
key" and its 2 neighbors) - which are quick to try all if you forgot the
precise position.  If you remember rules 1,1ab, then this choice is down to
2 possible candidates.

Essentially, all you must remember in details is that the "natural positions"
form a B<V-shape> — \ on left, / on right, and in case of bad luck you
should move in the direction of other diagonal one step.  Then a letter is
either in its "obvious position", or in one of 3 modifications of the
“natural position”.

Note that these rules cover I<ALL> the Latin letters appearing in
Latin-1..Latin-10, I<provided> we resolve the B<Œ/Ø>-conflict by putting B<Œ> to the key B<O> (since
B<Ø> may be entered using C<AltGr->B</ O>)!

=head2 Motivations:

It is important to have a logical way to quickly understand whether a letter
is quickly accessible from a keyboard, and on which key.  (Or, maybe, to find
a small set of keys on which a letter may be present — then, if one forgets,
it is possible to quickly un-forget by trying a small number of keys).

In fact, the problem of choosing “the optimal” assignment (by minimizing the
rules to remember) has almost unique solution.  Understanding this solution
(to a problem which is essentially combinatorial optimization) may be a great help
in memorizing the rules.

The idea: we assign alphabetical Latin characters only to alphabetical keys
on the keyboard; this frees the way to use (paired) symbol keys to enter (paired)
Unicode symbols.  Now observe the diagonals on the alphabetic part of the
keyboard: \-diagonals (like B<EDC>) and /-diagonals (like B<UHB>).  Each diagonal
contains 3 (or less) alphabetic keys; what we want is to assign ¨-accent to the top
one, ´-accent to the middle one, and `-accent to the bottom one.

On the left-hand part of the keyboard, use \-diagonals, on the right-hand
part use /-diagonals; now each diagonal contains EXACTLY 3 alphabetic keys.
Moreover, the diagonals which contain vowels B<AEYUIO> do not intersect!

If we have not decided to have keys set in stone, this would be all - we
would get "completely predictable" access to B<´¨`>-accented characters B<AEUIO>.
For example, B<Ÿ> would be accessible on C<AltGr->B<Y>, B<Ý> on C<AltGr->B<G>, B<Ỳ> on C<AltGr->B<V>.
Unfortunately, the diagonals contain keys C<ASDCIO> set in stone.  So we need
a way to "move away" from these keys.  The rule is very simple: we move
one step away in the direction of "other" diagonal (/-diagonal on the left
half, and \-diagonal on the right half) one step down (unless we start
on keys B<A>, B<C> where "down" is impossible and we move up to B<W> or B<F>).

Examples: B<Ä> is on B<Q>, B<Á> "wants to be" on B<A> (used for C<Æ>), so it is moved to
C<W>; B<Ö> wants to be on B<O> (already used for B<Ø> or B<Œ>), and is moved away to B<L>;
B<È> wants to be on B<C> (occupied by B<Ç>), but is moved away to B<F>.

There is no way to enter B<Ï> using this layout (unless we agree to move it
to the "8*" key, which may conflict with convenience of entering typographic
quotation marks).  Fortunately, this letter is rare (comparing even to B<Ë>
which is quite frequent in Dutch).  So there is no big deal that it is not
available for "handy" input - remember that one can always use deadkeys.

 http://en.wikipedia.org/wiki/Letter_frequency#Relative_frequencies_of_letters_in_other_languages

Note that the keys B<P> and B<R> are not engaged by this layout; since B<P>
is a neighbor of B<O>, it is natural to use it to resolve the conflict
between B<Ø> or B<Œ> (which both want to be set in stone on B<O>).  This leaves
only the key B<R> unengaged; but what we do not cover are two keys B<Å> and B<Ñ>
which are relatively frequent in Latin-derived European languages.

Note that B<Ì> is moderately frequent in Italian, but B<Ñ> is much more frequent
in Spanish.  Since B<Ì> and B<Ñ> want to be on the same key (which on many keyboards is taken by
B<Ñ>), it makes sense to prefer B<Ñ>…  Likewise, B<Ê> is much more frequent
than B<Ë>; switch them.

This leaves only the key B<R> unassigned, I<AND> a very rare B<Ỳ> on B<B>.  In
L<C<izKeys>|http://k.ilyaz.org>, one puts B<Å> and B<Ì> there.  This completes
the explanation of the rule 2.

=head2 On possibilities of merging 2 diacritics on one prefix key

With many diacritics, and the limited mnemonically-viable positions on
the keyboard, it makes sense to merge several diacritics on the same prefix key.
Possible candidates are cedilla/ogonek/comma-below (on C<AltGr-,>),
dot-above/ring-above/dot-below (on C<AltGr-.>), caron/breve, circumflex/inverted-breve (on C<AltGr-^>).
In some cases, only one of the diacretics would be applicable to a particular character.
Otherwise, one must decide which of several choices to prefer.  The notes below may be
useful when designing such preferences.  (This module can take most of such choices
automatically due to knowledge of L<Unicode ages|http://www.unicode.org/Public/UNIDATA/DerivedAge.txt> 
of characters; this age correlates well with expected frequency of use.)

Another trick discussed below is implementing a rare diacritic X by applying the diacritic Y to a character
with pre-composed diacritic Z.

U-caron: ǔ, Ǔ which is used to indicate u in the third tone of Chinese language pinyin.
But U-breve ŭ/Ŭ is used in Latin encodings.
Ǧ/ǧ (G with caron) is used, but only in "exotic" or old languages (has no
combined form - while G-breve ğ/Ğ is in Latin encodings.
A-breve Ă: A-caron Ǎ is not in Latin-N; apparently, is used only in pinyin,
zarma, Hokkien, vietnamese, IPA, transliteration of Old Latin, Bible and Cyrillic's big yus.

In EurKey: only a takes breve, the rest take caron (including G but not U)

Merging ° and dot-accent ˙ in Latin-N: only A and U take °, and they
do not take dot-accent.  In EurKey: also small w,y take ring accent; same in
Bepo - but they do not take dot accent in Latin-N.

Double-´ and cornu (both on a,u only) can be taken by ¨ or ˙ on letters with
¨ precombined (in Unicode ¨ is not precombined with diaeresis or dots).
But one must special-case Ë and Ï and Ø (have Ê and Ĳ instead; Ĳ takes no accents,
but Ê takes acute, grave, tilde and dot below...)!  Æ takes acute and macron; Ø takes acute.

Actually, cornu=horn is only on o,u, so using dot/ring on ö and ü is very viable...

So for using AltGr-letter after deadkeys: diaeresis can take dot above, hat and wedge, diaeresis.
Likewise, ` and ´ are not precombined together (but there is a combined
combining mark).  So one can do something else on vowels (ogonek?).

Applying ´ to `-accented forms: we do not have ỳ (on AltGr-keys), so must use "the natural position"
which is mixed with Ñ (takes no accents) and Ç (takes acute!!!).

s, t do not precombine with `; so can use for the "alternative cedilla".

Only a/u/w/y take ring, and they do not take cedilla.  Can merge.

Bepo's hook above; ảɓƈɗẻểƒɠɦỉƙɱỏƥʠʂɚƭủʋⱳƴỷȥ ẢƁƇƊẺỂƑƓỈƘⱮỎƤƬỦƲⱲƳỶȤ

  perl -wlnae "next unless /HOOK/; push @F, shift @F; print qq(@F)" NamesList.txt | sort | less

Of capital letters only T and Y take different kinds of hooks... (And for T both are in Latin-Extended-B...)


=head1 Useful tidbits from Unicode mailing list

=for html
<a name=Useful_tidbits_from_Unicode_mailing_list_(unsorted)></a>

=head2 On keyboards

On MS keyboard (absolutely wrong!)

  http://unicode.org/mail-arch/unicode-ml/y2012-m05/0268.html

Symbols for Keyboard keys:

  http://unicode.org/mail-arch/unicode-ml/Archives-Old/UML009/0204.html
     “Menu key” variations:
  http://unicode.org/mail-arch/unicode-ml/Archives-Old/UML009/0239.html
     Role of ISO/IEC 9995, switchable keycaps
  http://unicode.org/mail-arch/unicode-ml/Archives-Old/UML009/0576.html

On the other hand, having access to text only math symbols makes it possible to implement it in computer languages, making source code easier to read.

Right now, I feel there is a lack of keyboard maps. You can develop them on your own, but that is very time consuming.

  http://unicode.org/mail-arch/unicode-ml/y2011-m04/0117.html

Fallback in “smart keyboards” interacting with Text-Service unaware applications

  http://unicode.org/mail-arch/unicode-ml/y2014-m03/0165.html

Keyboards - agreement (5 scripts at end)

  ftp://ftp.cen.eu/CEN/Sectors/List/ICT/CWAs/CWA-16108-2010-MEEK.pdf

Need for a keyboard, keyman examples; why "standard" keyboards are doomed

  http://unicode.org/mail-arch/unicode-ml/y2010-m01/0015.html
  http://unicode.org/mail-arch/unicode-ml/y2010-m01/0022.html
  http://unicode.org/mail-arch/unicode-ml/y2010-m01/0036.html
  http://unicode.org/mail-arch/unicode-ml/y2010-m01/0053.html

=head2 History of Unicode

Unicode in 1889

  http://www.archive.org/stream/unicodeuniversa00unkngoog#page/n3/mode/2up

Structure of development of Unicode

  http://unicode.org/mail-arch/unicode-ml/y2006-m07/0056.html
  http://unicode.org/mail-arch/unicode-ml/y2005-m07/0099.html
      I don't have a problem with Unicode. It is what it is; it cannot
      possibly be all things to all people:
  http://unicode.org/mail-arch/unicode-ml/y2005-m07/0101.html

Control characters’ names

  http://unicode.org/mail-arch/unicode-ml/y2014-m03/0036.html

Compromizes vs reality

  http://unicode.org/mail-arch/unicode-ml/y2010-m02/0106.html
  http://unicode.org/mail-arch/unicode-ml/y2010-m02/0117.html

Stability of normalization

  http://unicode.org/mail-arch/unicode-ml/y2005-m07/0055.html

Universality vs affordability

  http://unicode.org/mail-arch/unicode-ml/y2007-m07/0157.html

Drachma

  http://unicode.org/mail-arch/unicode-ml/y2012-m05/0167.html
  http://std.dkuug.dk/jtc1/sc2/wg2/docs/n3866.pdf

w-ring is a stowaway

  http://unicode.org/mail-arch/unicode-ml/y2012-m04/0043.html

History of squared pH (and about what fits into ideographic square)

  http://unicode.org/mail-arch/unicode-ml/y2012-m02/0123.html
  http://unicode.org/mail-arch/unicode-ml/y2013-m09/0111.html

Silly quotation marks: 201b, 201f

  http://en.wikipedia.org/wiki/Quotation_mark_glyphs
  http://unicode.org/mail-arch/unicode-ml/y2006-m06/0300.html
  http://unicode.org/mail-arch/unicode-ml/y2006-m06/0317.html
  http://en.wikipedia.org/wiki/Comma
  http://en.wikipedia.org/wiki/%CA%BBOkina
  http://en.wikipedia.org/wiki/Saltillo_%28linguistics%29
  http://unicode.org/mail-arch/unicode-ml/y2006-m06/0367.html
  http://unicode.org/unicode/reports/tr8/ 
  		under "4.6 Apostrophe Semantics Errata"

OHM: In modern usage, for new documents, this character should not be used

  http://unicode.org/mail-arch/unicode-ml/y2011-m08/0060.html

Uppercase eszett ß ẞ

  http://unicode.org/mail-arch/unicode-ml/y2007-m05/0007.html
  http://unicode.org/mail-arch/unicode-ml/y2007-m05/0008.html
  http://unicode.org/mail-arch/unicode-ml/y2007-m05/0142.html
  http://unicode.org/mail-arch/unicode-ml/y2007-m05/0045.html
  http://unicode.org/mail-arch/unicode-ml/y2007-m05/0147.html
  http://unicode.org/mail-arch/unicode-ml/y2007-m05/0170.html
  http://unicode.org/mail-arch/unicode-ml/y2007-m05/0196.html

Should not use (roman numerals)

  http://unicode.org/mail-arch/unicode-ml/y2007-m11/0253.html

Colors in Unicode names

  http://unicode.org/mail-arch/unicode-ml/y2011-m03/0100.html

Xerox and interrobang

  http://unicode.org/mail-arch/unicode-ml/y2005-m04/0035.html

Tibetian (history of encoding, relative difficulty of handling comparing to cousins)

  http://unicode.org/mail-arch/unicode-ml/y2013-m04/0036.html
  http://unicode.org/mail-arch/unicode-ml/y2013-m04/0040.html

Translation of 8859 to 10646 for Latvian was MECHANICAL

  http://unicode.org/mail-arch/unicode-ml/y2013-m06/0057.html

Hyphens:

  http://unicode.org/mail-arch/unicode-ml/y2009-m10/0038.html

NOT and BROKEN BAR

  http://unicode.org/mail-arch/unicode-ml/y2007-m12/0207.html
  http://www.cs.tut.fi/~jkorpela/latin1/ascii-hist.html#5C

Combining power of generative features - implementor's view

  http://unicode.org/mail-arch/unicode-ml/y2004-m09/0145.html

=head2 Greek and about

OXIA vs TONOS

  http://www.tlg.uci.edu/~opoudjis/unicode/unicode_gkbkgd.html#oxia

Greek letters for non-Greek

  http://stephanus.tlg.uci.edu/~opoudjis/unicode/unicode_interloping.html#ipa

Macron and breve in Greek dictionaries

  http://www.unicode.org/mail-arch/unicode-ml/y2013-m08/0011.html

LAMBDA vs LAMDA

  http://unicode.org/mail-arch/unicode-ml/y2010-m06/0063.html

COMBINING GREEK YPOGEGRAMMENI equilibristic (depends on a vowel?)

  http://unicode.org/mail-arch/unicode-ml/y2006-m06/0299.html
  http://unicode.org/mail-arch/unicode-ml/y2006-m06/0308.html
  http://www.tlg.uci.edu/~opoudjis/unicode/unicode_adscript.html
  http://unicode.org/mail-arch/unicode-ml/y2008-m05/0046.html

=head2 Latin, Cyrillic, Hebrew, etc

Book Spine reading direction

  http://www.artlebedev.com/mandership/122/

What is a "Latin" char

  http://unicode.org/forum/viewtopic.php?f=23&t=102

Federal vs regional aspects of Latinization (a lot of flak; cp1251)

  http://peoples.org.ru/stenogramma.html

Yiddish digraphs

  http://unicode.org/mail-arch/unicode-ml/y2011-m10/0121.html

Cyrillic Script, Unicode status (+combining)

  http://scriptsource.org/cms/scripts/page.php?item_id=entry_detail&uid=ngc339csy8
  http://scriptsource.org/cms/scripts/page.php?item_id=entry_detail&uid=ktxptbccph

The IBM 1401 Hebrew Letter Key

  http://www.qsm.co.il/Hebrew/HebKey.htm

GOST 10859

  http://unicode.org/mail-arch/unicode-ml/y2009-m09/0082.html
  http://www.mailcom.com/besm6/ACPU-128.jpg

Hebrew char input

  http://rishida.net/scripts/pickers/hebrew/
  http://rishida.net/scripts/uniview/#title

Cyrillic soup

  http://czyborra.com/charsets/cyrillic.html

How to encode Latin-in-fraktur

  http://unicode.org/mail-arch/unicode-ml/y2007-m01/0279.html
  http://unicode.org/mail-arch/unicode-ml/y2007-m01/0263.html

The presentation of the existing COMBINING CEDILLA which has three major forms [ȘșȚț and Latvian Ģģ]

  http://unicode.org/mail-arch/unicode-ml/y2013-m06/0045.html
  http://unicode.org/mail-arch/unicode-ml/y2013-m06/0066.html
  
=head2 Math and technical texts

Missing:  .... skew-orthogonal complement

Math Almost-Text encoding

  http://unicode.org/notes/tn28/UTN28-PlainTextMath-v3.pdf
  http://unicode.org/mail-arch/unicode-ml/y2011-m10/0018.html
    For me 1/2/3/4 means unambiguously ((1/2)/3)/4, i.e. 1/(2*3*4)

    Unicode mostly encodes characters that are in use or have been
    encoded in other standards. While not semantically agnostic, it is
    much less oriented towards semantic clarifications and
    distinctions than many people might hope for (and this includes
    me, some of the time at least).

Horizontal/vertical line/arrow extensions

  http://unicode.org/charts/PDF/U2300.pdf
  http://unicode.org/mail-arch/unicode-ml/y2003-m07/0513.html
  http://std.dkuug.dk/JTC1/SC2/WG2/docs/n2508.htm

Pretty-printing text math

  http://code.google.com/p/sympy/wiki/PrettyPrinting

Sub/Super on a terminal

  http://unicode.org/mail-arch/unicode-ml/y2008-m07/0028.html

CR symbols

  http://unicode.org/mail-arch/unicode-ml/y2006-m07/0163.html

Math layout

  http://unicode.org/mail-arch/unicode-ml/y2007-m01/0303.html

Attempts of classification

  http://std.dkuug.dk/jtc1/sc2/wg2/docs/n4384.pdf
  http://std.dkuug.dk/JTC1/SC2/WG2/

					   Buttons	Target		Also=not-in-series-of-n4384
 square		1🞌 2⬝ 3🞍 4▪ 5◾ 6◼ 7■ s⬛						(solid=s⬛)
 box 		1□ 2🞎 3🞏 4🞐 5🞑 6🞒 7🞓 o⬜	   1🞔 2▣ 3🞕	🞖	=white square	(open=o⬜)  also: ▫◽◻⌑⧈⬚⸋⊡
 black circle	1⋅ 2∙ 3🞄 4⦁ 5⦁ 6⚫ 7●						also: ·
 ring		1○ 2⭘ 3🞆 4🞆 5🞇 6🞈 7🞉	   1⊙ 2🞊 3⦿	🞋	=white circle	also: ⊚⌾◌⚪⚬⨀◦⦾
 black diamond	1🞗 2🞘 3⬩ 4🞙 5⬥ 6◆
 white diamond	◇			   1🞚 2◈ 3🞛	🞜			also: ⋄
 black lozenge	1🞝 2🞞 3⬪ 4🞟 5⬧ 6⧫
 white lozenge	◊			   🞠
 cross		1🞡 2🞢 3🞣 4🞤 5🞥 6🞦 7🞧
 saltire 	1🞨 2🞩 3🞪 4🞫 5🞬 6🞭 7🞮				≈ times (rotated cross)
 5-asterisk	1🞯 2🞰 3🞱 4🞲 5🞳 6🞴
 6-asterisk	1🞵 2🞶 3🞷 4🞸 5🞹 6🞺
 8-asterisk	1🞻 2🞼 3🞽 4🞾 5🞿
 centered n-gon	3⯅ 4⯀ 5⬟ 6⬣ 8⯃
 cent on-corner	3⯆ 4⯁ 5⯂ 6⬢ 8⯄					(also ⯇ ⯈)
 light star	3🟀 4🟄 5🟉 6✶ 8🟎 12🟒
 medium star	3🟁 4🟅 5★ 6🟋 8🟏 12🟓
 (heavy) star	3🟂 4🟆 5🟊 6🟌 8🟐 12✹
 pinwheel	3🟃 4🟇 5✯ 6🟍 8🟑 12🟔				lighter: ✵

=head2 Unicode and linguists

Linguists mailing lists

  http://unicode.org/mail-arch/unicode-ml/y2009-m06/0066.html

Obsolete IPA

  http://unicode.org/mail-arch/unicode-ml/y2009-m01/0487.html
  http://unicode.org/cldr/utility/list-unicodeset.jsp?a=[%3Asubhead%3D%2F%28%3Fi%29archaic%2F%3A]+&g=

Teutonista (vowel guide p11, kbd p13)

  http://www.sprachatlas.phil.uni-erlangen.de/materialien/Teuthonista_Handbuch.pdf

Glottals

  http://unicode.org/mail-arch/unicode-ml/y2008-m05/0151.html
  http://unicode.org/mail-arch/unicode-ml/y2008-m05/0163.html
  http://unicode.org/mail-arch/unicode-ml/y2008-m05/0202.html
  http://unicode.org/mail-arch/unicode-ml/y2008-m05/0205.html

=head2 Spaces, invisible characters, VS

Substitute blank

  http://unicode.org/mail-arch/unicode-ml/y2011-m07/0101.html

Representing invisible characters

  http://unicode.org/mail-arch/unicode-ml/y2011-m07/0094.html

Ignorable glyphs

  http://unicode.org/mail-arch/unicode-ml/y2007-m08/0132.html
  http://unicode.org/mail-arch/unicode-ml/y2007-m08/0138.html
  http://unicode.org/mail-arch/unicode-ml/y2007-m08/0120.html

HOWTO: (non)dummy VS in fonts

  http://unicode.org/mail-arch/unicode-ml/y2007-m08/0118.html

ZWSP ZWNJ WJ SHY NON-BREAKING HYPHEN

  http://unicode.org/mail-arch/unicode-ml/y2007-m08/0123.html
  http://unicode.org/mail-arch/unicode-ml/y2007-m07/0188.html
  http://unicode.org/mail-arch/unicode-ml/y2007-m07/0199.html
  http://unicode.org/mail-arch/unicode-ml/y2007-m07/0201.html
  http://unicode.org/mail-arch/unicode-ml/y2007-m06/0122.html
  http://unicode.org/mail-arch/unicode-ml/y2007-m01/0297.html

On which base to draw a "standalone" diacritics

  http://unicode.org/mail-arch/unicode-ml/y2007-m07/0075.html

Variation sequences

  http://unicode.org/mail-arch/unicode-ml/y2004-m07/0246.html

=head2 Typesetting

Upside-down text in CSS (remove position?)

  http://unicode.org/mail-arch/unicode-ml/y2012-m01/0037.html

Unicode to PostScript

  http://unicode.org/mail-arch/unicode-ml/y2009-m06/0056.html
  http://www.linuxfromscratch.org/blfs/view/svn/pst/enscript.html
  http://unicode.org/mail-arch/unicode-ml/y2009-m06/0062.html

Spacing: English and French

  http://unicode.org/mail-arch/unicode-ml/y2006-m09/0167.html
  http://unicode.org/mail-arch/unicode-ml/y2008-m05/0103.html
  http://unicode.org/mail-arch/unicode-ml/y2007-m08/0138.html

Chicago Manual of Style

  http://unicode.org/mail-arch/unicode-ml/y2006-m01/0127.html

Coloring parts of ligatures
    Implemenations:

  http://unicode.org/mail-arch/unicode-ml/y2005-m06/0195.html
  http://unicode.org/mail-arch/unicode-ml/y2005-m06/0233.html
  http://unicode.org/mail-arch/unicode-ml/y2005-m06/0208.html
    GPOS
  http://unicode.org/mail-arch/unicode-ml/y2005-m06/0167.html

Chinese typesetting

  http://idsgn.org/posts/the-end-of-movable-type-in-china/

@fonts and non-URL URIs

  http://unicode.org/mail-arch/unicode-ml/y2010-m01/0156.html

=head2 Looking at the future

Why and how to introduce innovative characters

  http://unicode.org/mail-arch/unicode-ml/y2012-m01/0045.html

Unicode knows the concept of a provisional property

  http://unicode.org/mail-arch/unicode-ml/y2011-m11/0142.html
  http://unicode.org/reports/tr23/
  http://unicode.org/mail-arch/unicode-ml/y2011-m11/0161.html
    If you want to make analogies, however, the ISO ballots constitute
    the *provisional* publication for character code points and names.
    	that needs to be available from day one for a character to be
	implementable at all (such as decomp mappings, bidi class,
	code point, name, etc.).

	     ZERO-WIDTH UNDEFINED DECOMPOSITION MARK
	     		- to define decomposition, prepend it

Exciting new letter forms for English

  http://www.theonion.com/articles/alphabet-updated-with-15-exciting-new-replacement,2869/

Proposing new stuff, finding new stuff proposed

  http://unicode.org/mail-arch/unicode-ml/y2008-m01/0238.html
  http://www.unicode.org/mail-arch/unicode-ml/y2013-m09/0056.html

A useful set of criteria for encoding symbols is found in
Annex H of this document:

  http://std.dkuug.dk/jtc1/sc2/wg2/docs/n3002.pdf 

=head2 Unsorted

Summary views into CLDR

  http://www.unicode.org/cldr/charts//by_type/patterns.characters.html
  http://www.unicode.org/cldr/charts//by_type/misc.exemplarCharacters.html

Pound

  http://unicode.org/mail-arch/unicode-ml/y2012-m05/0242.html

Classification of Dings (bats etc)

  std.dkuug.dk/jtc1/sc2/wg2/docs/n4115.pdf

	Escape: 2be9 2b9b
	ARROW SHAFT - various

Locales

  http://blog.kyero.com/2011/11/14/what-is-the-common-locale-data-repository/
  http://blog.kyero.com/2010/12/02/lost-in-translation-locales-not-languages/
  http://unicode.org/mail-arch/unicode-ml/y2006-m06/0203.html

General

  http://ebixio.com/online_docs/UnicodeDemystified.pdf

Diacritics in fonts

  http://unicode.org/mail-arch/unicode-ml/y2011-m05/0047.html
  http://www.user.uni-hannover.de/nhtcapri/combining-marks.html#greek

Licences (GPL etc) in TV sets

  http://unicode.org/mail-arch/unicode-ml/y2009-m12/0092.html

Similar glyphs:

  http://unicode.org/reports/tr39/data/confusables.txt

GeoLocation by IP

  http://unicode.org/mail-arch/unicode-ml/y2009-m04/0197.html

Per language character repertoir:

  http://unicode.org/mail-arch/unicode-ml/y2009-m04/0253.html
  http://unicode.org/mail-arch/unicode-ml/y2009-m04/0255.html

Dates/numbers in Unicode

  http://unicode.org/mail-arch/unicode-ml/y2010-m02/0122.html

Normalization FAQ

  http://www.macchiato.com/unicode/nfc-faq

Apostrophe

  http://unicode.org/mail-arch/unicode-ml/y2008-m05/0060.html
  http://unicode.org/mail-arch/unicode-ml/y2008-m05/0063.html
  http://unicode.org/mail-arch/unicode-ml/y2008-m05/0066.html
  http://unicode.org/mail-arch/unicode-ml/y2007-m07/0251.html
  http://unicode.org/mail-arch/unicode-ml/y2007-m05/0309.html

Apostroph as soft sign

  http://unicode.org/mail-arch/unicode-ml/y2010-m08/0123.html

Questionner at start of Unicode proposal

  http://unicode.org/mail-arch/unicode-ml/y2007-m05/0087.html

Rubi

  http://en.wikipedia.org/wiki/Ruby_character#Unicode

Tamil/ISCII

  http://unicode.org/faq/indic.html
  http://unicode.org/versions/Unicode6.1.0/ch09.pdf
  http://www.brainsphere.co.in/keyboard/tm.pdf

CGI and OpenType

  http://unicode.org/mail-arch/unicode-ml/y2008-m02/0097.html

Numbers in scripts ;-)

  http://unicode.org/mail-arch/unicode-ml/y2008-m02/0120.html

Indicating coverage of the font

  http://unicode.org/mail-arch/unicode-ml/y2008-m02/0152.html
  http://unicode.org/mail-arch/unicode-ml/y2008-m02/0167.html

Accessing ligatures

  http://unicode.org/mail-arch/unicode-ml/y2007-m11/0210.html

Folding characters

  http://unicode.org/reports/tr30/tr30-4.html

Writing systems vs written languages

  http://unicode.org/mail-arch/unicode-ml/y2005-m07/0198.html
  http://unicode.org/mail-arch/unicode-ml/y2005-m07/0241.html

MS Visual OpenType tables

  http://www.microsoft.com/typography/VOLT.mspx
  http://www.microsoft.com/typography

"Same" character Oacute used for different "functions" in the same text

  http://unicode.org/mail-arch/unicode-ml/y2004-m08/0019.html
	etc:
  http://unicode.org/mail-arch/unicode-ml/y2004-m07/0227.html

Diacritics

  http://www.sil.org/~gaultney/ProbsOfDiacDesignLowRes.pdf
  http://en.wikipedia.org/wiki/Sylfaen_%28typeface%29
    http://tiro.com/Articles/sylfaen_article.pdf

Sign writing

  http://std.dkuug.dk/jtc1/sc2/wg2/docs/n4342.pdf

Writing digits in non-decimal

  http://unicode.org/mail-arch/unicode-ml/y2011-m03/0050.html
	Which separator is less ambiguous?  Breve ˘ ? ␣ ?  Inverted ␣ ?

Use to identify a letter:

  http://unicode.org/charts/collation/

Perl has problems with unpaired surrogates (whole thread)

  http://unicode.org/mail-arch/unicode-ml/y2010-m11/0034.html

Complex fonts (e.g., Indic)

  http://unicode.org/mail-arch/unicode-ml/y2010-m10/0049.html

Complex glyphs in Symbola (pre-6.01) font may crash older versions of Windows

  http://unicode.org/mail-arch/unicode-ml/y2010-m10/0082.html
  http://unicode.org/mail-arch/unicode-ml/y2010-m10/0084.html

Window 7 SP1 improvements

  http://babelstone.blogspot.de/2010/05/prototyping-tangut-imes-or-why-windows.html

Middle dot is ambiguous

  http://unicode.org/mail-arch/unicode-ml/y2010-m09/0023.html
  http://unicode.org/mail-arch/unicode-ml/y2013-m03/0151.html

Superscript == modifiers

  http://unicode.org/mail-arch/unicode-ml/y2010-m03/0133.html

Translation of Unicode names

  http://unicode.org/mail-arch/unicode-ml/y2012-m12/0066.html
  http://unicode.org/mail-arch/unicode-ml/y2012-m12/0076.html

Transliteration on passports (see p.IV-48), UniDEcode

  http://www.icao.int/publications/Documents/9303_p1_v1_cons_en.pdf
  http://unicode.org/mail-arch/unicode-ml/y2013-m11/0025.html

=head1 Keyboard input on Windows: interaction of applications and the kernel

=head2 Keyboard input on Windows, Part I: what is the kernel doing?

This is not documented.  We try to provide a description which is
both as simple as possible, and as complete as possible.  (We ignore
many important parts: the handling of hot keys [or C<C-A-Del>]), IME,
handling of focus switch [C<Alt-Tab> etc], the syncronization of keystate
between different queues, waking up the system, the keyboard filters,
widening of virtual keycodes, and LED lights.)

We omit Step 0, when the hardware keyboard drivers (PS/2 or USB) deliver keydown/up(/repeat???) event for scan
codes of corresponding keys.  (This is a complicated topic, but well-documented.)

=over

=item 1

The scan codes are massaged (see “Low level scancode mapping” in L<"SEE ALSO">).

=item 2

The keyboard layout tables map the translated scancode to a virtual keycode.
(This may also depend on the “modification column”; see L<"Far Eastern keyboards on Windows">.)
The “internal” key state table is updated.

=item 3

Mythology: the modification keys (C<Shift>, C<Alt>, C<Ctrl> etc) are taken into account.

What actually happens: any key may act as a modification key.  The keyboard layout tables
map keycodes to 8-bit masks.  (The customary names for lower bits of the mask are C<KBDSHIFT>,
C<KBDCTRL>, C<KBDALT>, C<KBDKANA>; two more bits are named C<KBDROYA> and C<KBDLOYA> — after
OYAYUBI 親指, meaning THUMB; two more
bits are unnamed.)  The keycodes of the currently pressed keys (from the “internal” table) are translated to masks, and
these masks are ORed together.  (For the purpose of translation to C<WM_CHAR>/etc [done
in ToUnicode()/ToUnicodeEx()], the bit C<KBDKANA> may be set
also when key C<VK_KANA> was pressed odd number of times; this is
controlled by C<KANALOK> flag in a virtual key descriptor [of the key being currently processed]
of the keyboard layout tables.)

The keyboard layout tables translate the ORed mask to a number called “modification column”.
(Thess two numbers are completely hidden from applications.  The only glint the
applications get is in the [useless, since there is no way to map it to anything “real”] result of
L<VkKeyScanEx()|http://msdn.microsoft.com/en-us/library/windows/desktop/ms646332%28v=vs.85%29.aspx>.])

=item 4

Depending on the current “modification column”, the virtual keycode of the current key event
may be massaged further.  (See L<"Far Eastern keyboards on Windows">.)  Numpad keycodes
depend also on the state of C<NumLock> — provided the keyboard layout table marks them with
C<KBDNUMPAD> flag.  A few other scancodes may also produce different virtual keycodes in
different situations (e.g., C<Break>).

When C<KLLF_ALTGR> flag is present, fake presses/releases of left C<Ctrl> are generated
on presses(repeats)/releases of right C<Alt> (exception: the press is not generated if any
Ctrl key is down; likewise for when left C<Ctrl> up when right C<Alt> is released).  With
keypad presses/releases in presence of C<VK_SHIFT> and C<NumLock>, fake releases/presses of C<VK_SHIFT>
are generated.

=item 5

If needed, asynchronous key state for the current key's non-left-non-right flavor is updated.
(The rest is dropped if the key is consumed by a C<WH_KEYBOARD_LL> hook.)

Asynchronous key state for the current key is updated.  Numpad-by-number flags are updated.
(The rest is dropped if the key is a hotkey.)

The message C<WM_(SYS)KEYDOWN/UP> is posted to the application.  If C<VK_MENU> [usually
called the C<Alt> key] is
down, but C<VK_CONTROL> is not, the event is of C<SYS> flavor (this info is duplicated in
lParam.  Additionally, for C<VK_MENU> tapping, the UP event is also made C<SYS> — although
at this moment C<VK_MENU> is not down!).
(The C<KBDEXT> flag [of the scancode] is also delivered to the application.)

(When a C<WM_(SYS)KEYDOWN/UP> message is posted, the key state is updated.  This key state
may be used by TranslateMessage() as an argument to ToUnicode(), and is returned by GetKeyState() etc.)

B<The following steps are applicable only if the application uses “the standard message pump”
with TranslateMessage()/DispatchMessage() or uses some equivalent code.>

=item 6

Before the application dispatches C<WM_(SYS)KEYDOWN/UP> to the message handler,
TranslateMessage() calls L<ToUnicode()|The semantic of ToUnicode()> with C<wFlags = 0> (unless a popup menu
is active; then C<wFlags = 1> — which disables character-by-number input via
numeric KeyPad) and the buffer of 16 UTF-16 code units.

=item 7

The UTF-16 code units obtained from ToUnicode() are posted via PostMessage().  All the code units but
the last one are marked by C<FAKE_KEYSTROKE> flag in C<lParam>.  If the initial message
was C<WM_SYSKEYDOWN>, the C<SYS> flavor is posted; if ToUnicode() returns a
deadkey, the C<DEAD> flavor is posted.

(The bit C<ALTNUMPAD_BIT> is set/used only for the console handler — otherwise the character is already translated to Unicode. — It
indicates that the character which was input-by-number
should be interpreted “as in” OEM codepage — as opposed to ANSI-codepage/Unicode.  This happens when non-hex input was started by
non-C<0> digit.)

=back

=head2 Keyboard input on Windows, Part II: The semantic of ToUnicode()

L<The syntax of ToUnicode() is documented|http://msdn.microsoft.com/en-us/library/windows/desktop/ms646320%28v=vs.85%29.aspx>,
the semantic is not.  Here we fix this.

=over 4

=item 1

If the bit C<0x01> in C<wFlags> is not set, the key event is checked for contributing to
character-by-number input via numeric KeyPad (and numpad-by-number flags are updated — unless
the bit C<0x04> in C<wFlags> is set).
If so, the character is
delivered only when C<Alt> is released.  (This the only case when KEYUP
delivers a character.)  Unless the bit 0x02 in C<wFlags> is set, the KEYUP
events are not processed any more.

=item 2

The flag C<KLLF_LRM_RLM> is acted upon, and C<VK_PACKET> is processed.

=item 3

The keys which are currently down are mapped to the ORed bitmap (see above).

=item 4

If the key event does not contribute to input-by-number via numeric keypad,
and C<KBDALT> is set, and no other bits except C<KBDSHIFT>, C<KBDKANA> are set:
then the bit C<KBDALT> is removed from the ORed mask.  (We call this “C<KBDALT>
stripping” below.)

=item 5

If C<CapLock> is active, C<KBDSHIFT> state is flipped in the following cases: either at most
C<KBDSHIFT> is set in the bitmap, and C<CAPLOK> is set in the descriptor,
or both C<KBDALT> and C<KBDCTRL> are set in the bitmap, and C<CAPLOKALTGR> is set in the
descriptor.

Now the ORed bitmap is converted to the modification column (see above).

=item 6

The key descriptor for the current virtual keycode is consulted (the “row” of the table).
If C<SGCAPS> flag is on, C<CapsLock> is active, and no other bits but C<KBDSHIFT> are set in the bitmap,
the row is replaced by the next row.

=item 7

The entry at 
the row/column is extracted; if defined, it is either a string (zero or more UTF-16 code units), or a
dead key ID (one UTF-16 unit).  (I<Implementation>: the ID is taken from the next row of the table.)

(If the ORed mask corresponds to a valid modification column, but the row does not
define the behaviour at this column, and the bit C<KBDCTRL> is set, and no other bits but C<KBDSHIFT>, C<KBDKANA>
are set, then an autogenerated character in the range 0x00..0x1f is emitted for virtual keycodes
'A'..'Z' and widened virtual keycodes 0xFF61..0xFF91 [for latter, based on the low bits of translation-to-scancode]).

=item 8

The resulting units are fed to the finite automaton.  When the automaton is in
0-state, a fed character unit is passed through, and a fed deadkey ID sets the state
of the automaton to this number.  In non-0 state, the IDs behave the
same as numerically equal character units; the behaviour is described by the keyboard layout
tables.  The automaton changes the state according to the input; it may also emit a character
(= 1 code unit; then it is always reset to 0 state).  When “unrecognized input” arrives, the automaton
emits the ID I<and> the input, and resets to 0 state.

(On KEYUP event, the changes to the state of the finite-automaton are ignored.  This is only
relevant if C<wFlags> has bit C<0x02> set.)

B<MS documents new behaviour after version ………:> (untested) if C<wFlags> has bit C<0x04> set, the initial state of the finite
automaton is restored.

=item 9

After UTF-16 units are passed through the automaton, its output is returned by ToUnicode().
If the automaton is in non-0 state, the state ID becomes the output.

=back

B<NOTE:> MSKLC restricts the length of the string associated to the row/column cell to
be at most 4 UTF-16 code units.  There are 2 restrictions for keyboard layouts created with other tools:
first, the maximal number of UTF-16 codepoints in all these strings is stored in a byte, hence there
may be at most 255 UTF-16 codepoints.  Second, the actual slot C<KBDTABLES.cbLgEntry> where the string is allocated
contains two shorts, then the UTF-16 data; its length is also stored in a byte.  This results in
the maximal string length of 125 code units — if it is stored in one slot.

However, with creative allocations, one can use more than one slot for a string storage
(theoretically, one may imagine specially crafted layout where this would break the
layout; on practice, such situations should not arise — even if one stores long strings in
I<many> slots good for 4-chars strings.

B<NOTE:> If the application uses the stardard message pump
with TranslateMessage()/DispatchMessage(), the caller of ToUnicode() is TranslateMessage().
In this case, ToUnicode() is called with an output buffer consisting of 16 UTF-16 code units.  For
such applications, the strings associated to keypresses are truncated after 16 code units.

B<NOTE:> If the string is “long” (i.e., defined via LIGATURES), when it is fed through the
finite automaton, the transitions to non-0 state do not generate deadkey IDs in the output
string.  (The LIGATURES may contain strings of one code unit!  This may lead to non-obvious
behaviour!  If pressing such a key after a deadkey generates a chained deadkey, this
would happen without delivering C<WM_DEADKEY> message.)

B<NOTE:> How kernel recognizes which key sequences contribute to
character-by-number input via numeric KeyPad?  First, the starter keydown must happen
when the ORed mask contains C<KBDALT>, and no other bits except C<KBDSHIFT>
and C<KBDKANA>.  (E.g., one can press C<Alt>, then tap C<f 1 2 3>, release C<Alt>
[with 1,2,3 on the numeric keypad].
This would deliver C<Alt-f>, then C<1> would start character-by-number input
provided C<Alt> and C<NumPad1> together have ORed mask “in between” of C<KBDALT>
and C<KBDALT|KBDSHIFT|KBDKANA>.)

After the starter keydown (NumPad: 0..9, DOT, PLUS) is recognized as such, all the keydowns
should be followed by the corresponding keyup (keydowns-due-to-repeat are ignored);
more precisely, between two KEYDOWN events, the KEYUP for the first of them must be present.
(In other words, KEYDOWN/KEYUP events must come in the expected order, maybe with some intermixed “extra” KEYUP events.)
In the decimal mode (numeric starter) only the keys with scancodes of NumPad 0..9 are allowed.
In the hex mode (starter is NumPad's DOT or PLUS) also the keys with virtual codes
'0'..'9' and 'A'..'F' are allowed.  The sequence is terminated by releasing C<VK_MENU>
(=C<Alt>) key.

B<NOTE:> In most cases, the resulting number is reduced mod 256.  The exceptions are: the starter key is C<KeyPadPLUS>, 
or the translate-to codepage is multibyte (then a number above 255 is interpreted as big-endian combination
of bytes).  In multibyte codepages, numbers 0x80..0xFF
are considered in C<cp1252> codepage (unless the translate-to codepage is Japanese, and the number’s codepoint is Katakana).

B<NOTE:> If the starter key is C<KeyPad0> or C<KeyPadDOT>, the number is a codepoint in the default codepage of the keyboard layout;
if it is another digit, it is in the OEM codepage (usually one with pseudo-graphic symbols; user-settable).  (For example, typing
with C<Alt> keys C<1 1> may give C<U+2642=♂> on C<Alt>-release, while typing keys C<0 1 1> gives a control character C<U+000B>.)
Enabling hex modes (C<KeyPadPLUS> or C<KeyPadDOT>) requires extra tinkering; see L<"Hex input of unicode is not enabled">.

B<NOTE:> since keyboard layout normally map C<Alt> to the mask C<KBDALT>, and do not define
a modification column for the ORed mask C<=KBDALT>, and C<KBDALT> is B<NOT> stripped for
key events in input-by-number, these key events usually do not generate spurious C<WM_CHAR>s.

B<NOTE:> if the bit C<0x01> of C<wFlags> is intended to be set, then there is a way to query
the kernel “what would happen if a particular key with a particular combination of modifiers
were pressed now”.  (Recall that a “usual” ToUnicode() call is “destructive”: it modifies the
I<state> of the keyboard stored in the kernel.  The information about whether one is in the
middle of entering-by-number and/or whether one is in a middle of a deadkey sequence is
erased or modified by such calls.)  In general, there is no way preserve the state of
entering-by-number; however, in presence of bit 0x01, this is of no concern, so a solution
exists.

Using C<wFlags=0x01|0x02>, and setting the high bit of C<wScanCode> gives the same result as
ToUnicode() with C<wFlags=0x01> and no high bit in C<wScanCode>.  Moreover, this preserves the state of
the deadkey-finite-automaton.  This way, one gets a “I<non-destructive>” flavor of ToUnicode().

=head2 Keyboard input on Windows, Part III: Customary “special” keybindings of typical keyboards

Typically, keyboards define a few keypresses which deliver “control” characters
(for benefits of console applications).  As shown above, even if the keyboard does not
define C<Control-letter> combinations (but does define modification column for C<Ctrl>
which is associated to C<KBDCTRL> — with maybe C<KBDSHIFT>, C<KBDKANA> intermixed), C<WM_CHAR>
with C<^letter> I<will> be delivered to the application.  Same with happen for combinations
with modifiers which produce only C<KBDCTRL>, C<KBDSHIFT>, C<KBDKANA>.

Additionally, the typical keyboards also define the following bindings:

  Ctrl-Space	 ——→ 0x20
  Esc, Ctrl-[	 ——→ 0x1b
  Ctrl-]	 ——→ 0x1d
  Ctrl-\	 ——→ 0x1c
  BackSpace	 ——→ ^H
  Ctrl-BackSpace ——→ 0x7f
  Ctrl-Break	 ——→ ^C
  Tab		 ——→ ^I
  Enter		 ——→ ^M
  Ctrl-Enter	 ——→ ^J

In addition to this, the standard US keyboard (and keyboards built by this Perl module) define
the following bindings with C<Ctrl-Shift> modifiers:

  @	 ——→ 0x00
  ^	 ——→ 0x1e
  _	 ——→ 0x1f

=head2 Can an application on Windows accept keyboard events?

This may seem a silly question until one have seen zillions of various attempts tried by different
applications to implement the support of this functionality.  All of these attempts I
have seen are extremely buggy.

B<Why?>  The key problem is that any code supporting a customizable key bindings (in particular,
the Windows’ basic framework of APIs for applications!) needs to distinguish which case it is:

=over 4

=item

either I<user intends> the given key chord to “be intercepted” to trigger “a certain action”
(as in: “save this file”), or

=item

I<the intent> is to insert a character.

=back

Unfortunately, the way the kernel treats keyboard actions is not helpful in the task of
distinguishing these two intents.  (See 
L<"Keyboard input on Windows, Part I: what is the kernel doing?">.)

Given the vast pletora of different approaches the keyboard layouts use to make character
input convenient, an application would not be able to find out “on itself” whether a key
press (say, C<Alt-Win-s> delivering the character C<∑>) was intended to “trigger a certain
bindable action”.  So the only viable strategy should be:

=over 4

=item

Find out whether a keypress B<“really”> delivers a character.

=item

If so, insert the character (the “intended-for-insert” case).

=item

If not, try to match this keypress with the list of bindable actions.

=back

Unfortunately, L<until recently|https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-tounicodeex>, the documented
Windows APIs did not include the way to inspect the “really”-part above.  So different applications tried various hacks — failing
in all but the most trivial cases.

B<The difficulty:> L<C<KBDALT> stripping|"Keyboard input on Windows, Part II: The semantic of ToUnicode()"> does not allow one to
see whether the C<Alt>-modifier was used to “modify” the character
delivered by the keyboard layout, or it was used to “trigger an C<Alt>-action.  With C<Win>-modifier there is no stripping, but
a similar problem still remains (since by default this modifier have no C<KBD>-bits attached).  To add insult to injury, some
C<Ctrl>-chords also deliver characters — but these are not intended for character input!

B<The core difficulty:> to implement the scheme above, we need to C<check first> which character is delivered by a keypress.
However, the APIs to do this¹⁾ I<reset the stored state> of the keyboard layout (“the current prefix=dead key”).  So after doing
this, we I<can find> “whether a character is delivered” — but this stops our further attempts to investigate “the ‘really delivered’
 bit” discussed above.

  ¹⁾  ToUnicodeEx() or TranslateMessage(). — The latter is just a shallow wrapper
                       for sending a character message described by ToUnicodeEx().

=head2 The “easy parts of the logic”

This goes like this:

If C<ToUnicodeEx()> delivers a prefix=dead key, this is not an accelerator.  So the correct behaviour is “do
nothing” (“the destructive version” alread modified the internal state of the keyboard layout appropriately!  If it was
non-destructuve, “redo it destructively”).

So. assume we know that C<ToUnicodeEx()> delivers a character.

=over

=item

If there is no C<Win>, C<Alt>, C<Ctrl> modifiers pressed, then I<it is definitely> “intended-for-insert”.

=item

Same if this happens after “a prefix key”.  (To know this, raise a flag after getting a C<WM_(SYS)DEADCHAR>, and lower after
getting a C<WM_(SYS)CHAR> or
L<a C<WM_(SYS)DEADCHAR> with C<string="\0">|"It is not documented how to make a with-prefix-key(s) combination produce 0-length string"> — or equivalents of these from C<ToUnicodeEx()>.)

=item

If C<Ctrl> is down, this character may still be “fake” — when the intent is not “insert this”.  However, these cases are easy to
detect: just mark all the C<WM_(SYS)CHAR> carrying characters in the range C<0x00..0x1f>, C<0x7f> as “non-insert”, and
do the same with C<0x20> delivered when one of C<Ctrl> keys is down.

=item

However, given how the kernel treats C<Win>- and C<Alt>-modifiers (ignores C<Win> and possibly-strips C<KBDALT>), when the
user combines a keypress with C<Win>¹⁾ (and — in basic cases — with C<Alt>), the delivered character remains the same.  But such
chords are definitely I<not intended-for-insert>!

  ¹⁾ This assumes that keyboard layout is ignoring Win-modifier — as most of layouts do.

This B<forces one to inspect whether removing C<Alt> and/or C<Win> from the chord leaves the delivered character the same>.  If
so — this is not intended for insert!  The following sections discuss two approaches: a hack, and a 100%-robust one.

=back

=head2 The ultra-simple approach

What we describe here is still a hack. — However it avoids using “only-recently-documented” non-destructive APIs of Windows, and
works in overwhelming majority of tricky cases (meaning: the cases where most of other approaches tried in Windows’ applications
fail).  It was implemented in Emacs in mid-10s, and only one bug (quickly worked around) was reported.

B<The problem:> how to find out whether removing C<Win>- and C<Alt>-modifiers would deliver the same character as returned by the
earlier call to C<ToUnicodeEx()>?  For example, on one layout C<Win>-modifer “is not bound”, but C<]>-key delivers C<щ> (a quite
common situation), on the other layout it delivers C<]>, but C<Win> “is bound”, and C<Win-]> delivers C<щ>.  If we can see that
a chord-with-C<Win> delivers C<щ>, then in the first case we should better call the action associated with C<Win-щ>, while in the
second case we should insert C<щ>.

Here we assume that the call to C<ToUnicodeEx()> was destructive, so calling C<ToUnicodeEx()> again “is too late”.
The hack is to call L<C<VkKeyScanW()>|https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-vkkeyscanw> on the
delivered character.  (In particular, the delivered I<string> should contain only one codepoint; so this would not work for
characters above C<U+FFFF>, and multi-char strings — but in the latter case it is hard to imagine how this makes sense with an
“extra” C<Alt>-modifier.)

This call returns “(one of) the way(s) to reach this character from the given keyboard layout” — which is a combination of the
C<VK_>-code, and of the “needed modifier bitmap”.  (Here it may be advisable to look in
L<"A convenient assignment of C<KBD*> bitmaps to modifier keys">.)  So now one can proceed like this:

=over 4

=item

Since there may be several ways to type this character, we may get “a mismatching combination”.  If the mismatch is in the
C<VK_>-key — tough luck: but see the corresponding comment in C<get_wm_chars()> in
L<https://github.com/emacs-mirror/emacs/blob/master/src/w32fns.c#L3833>; it seems that in this case, it is a good heuristic to
 assume that this key chord is intended-for-insert iff the delivered character is non-ASCII!)

=item

So now we assume that what C<VkKeyScanW() reported matches the C<VK_>-code of the pressed key.  Then we can compare the reported
C<KBD*> bitmap with the modifier keys which are down.  

=back

Discuss first the common cases.  Usually C<Win> does not generate C<KBD*> bits, and if it generates them, they should be
C<KBDKANA> or above.  C<CONCLUSION:> if the bitmask is below C<KBDKANA>, and C<Win> is down, then this character may be entered
without pressing C<Win>, so this-chord-with-C<Win> is not intended for insert.

More generally, if the returned bitmap is C<KBDSHIFT|KBDALT|KBDCTRL=7> or below, then on any keyboard layout with even microscopic
sanity, this means that the bitmasks on the pressed keys “match their names”, and we can find exactly which combination of keys
I<is needed> to emit this character — and this is exactly what we need.  So if more modifiers than strictly necessary are pressed
down, we can “strip away the ‘needed’ modifiers”, and trigger the action associated with our character and the remaining modifiers.

(If both C<left> and C<right> versions of a certain modifier are down, one should better follow what Windows’ “accelerator
framework” does: with both C<lCtrl> and C<rAlt> are down, it would prefer striping C<lCtrl> and C<rAlt>.)

Furthermore even if bitmap is 8 or more, if only one C<Ctrl> is down, and the bitmap has C<KBDCTRL> set, then the 
C<Ctrl>-modifier should be ignored; likewise for C<Alt>-logic. — And if after this, there is no non-ignored C<Alt>-, C<Ctrl>- or
C<Win>-modifiers which are pressed, this chord is “intended-for-insert”; otherwise, the non-ignored modifiers “lead to a
boundable event”.  (Indeed, if the bitmap does not have C<KBDALT> set, and C<Alt> is pressed, then this character may be entered
without pressing C<Alt>, so this-chord-with-C<Alt> is not intended for insert, and “has C<Alt> added”.)

(The latter logic is due to the common case of the bitmap associated to C<Ctrl> including the bit C<KBDCTRL>, and the bitmap
associated to C<Alt> including the bit C<KBDALT>.)

The only unhandled cases are when the bitmap is above C<KBDSHIFT|KBDALT|KBDCTRL=7>, and either C<Win> is down, or there is a
non-ignored C<Alt> or C<Ctrl>.  This case needs “tricky heuristics” — but it seems that the logic used above for “the case of
mismatched C<VK_>-codes” is still applicable: if the delivered char is ASCII, consider this as a bindable event, otherwise
it is “intended for insert”.

B<Remark:> See the link above for how Emacs does it and how it is commented.  (However, keep in mind that this codes wants to be
as compatible as possible with “the ideosyncratic ways of old versions of Emacs”.)

B<Caveat:> the API in question allows accessing the lower 8 bit of the modifiers-bitmap.  Since this bitmap seems to be 16-bit,
this approach may give some bogus results (but in very tricky cases only!) for the keyboard layouts which use these extra bits.

=head2 The bullet-proof method

B<Warning:> this is untested.  It is recommended that
L<"Can an application on Windows accept keyboard events?  Part I: insert only"> (and the followup parts) be consulted too before
implementing this.  This should also be better enhanced by
L<C<lAlt-lCtrl>-recognition|"Can an application on Windows accept keyboard events?  Part IV: application-specific modifiers">.

Nowadays, when the
L<non-destructive ways of querying keyboard|https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-tounicodeex>
are finally documented, one can do this easily.  Recall that we need to find out whether a character delivered by a chord may
be entered with fewer modifier keys pressed — and I<we know which modifier keys we are interested in>!  So

=over 4

=item

Call C<ToUnicodeEx()> non-destructively; store the resulting string (we may assume it is not empty — otherwise it it trivially 
not-intended-for-insert — unless this happens after a prefix=dead key).

=item

Running through the list of “known modifier keys”, if this key is pressed, reissue the C<ToUnicodeEx()> calls with the (temporarily)
modified array where this key is not pressed.  If the result is the same as before — this modifier key is “excessive”!  Memorize
this key, unset it permanently in the array, and rerun this stage.

=item

Sooner or later we reach this stage.  We memorized a (maximal!) set of “excessive” modifiers.  Restore them in the “is␣pressed”
array, and make a final call to C<ToUnicodeEx()> — this time destructively.  (Of course, it returns the result we already
know — but the keyboard layout needs this to handle sequences of keypresses “as intended”.

=back

The rest is very simple: if the delivered character is a control character, or C<" ">-and-C<Ctrl>-is-down, it should be
ignored, — or maybe interpreted by adding C<Ctrl> to “excessive modifiers” after un-C<Ctrl>ing this character.  Finally, if there is
no “excessive” modifiers, this chord is “intended-for-insert”.  If there are “excessive” modifiers, then the
delivered character should be “augmented by these excessive modifiers” and translated to a bindable event.

B<Caveat:> I<there is one case> when the logic above fails>: we try to check whether removing modifiers could produce the same
result — but this assumes that I<the user can remove these modifiers!>  While with C<KLLF_ALTGR>, the kernel “mocks” pressing the
left C<Ctrl> keys when C<AltGr> is pressed — and I<the user can do nothing to control this>.  If the bitmaps produced by C<lCtrl>
and C<rAlt> are I<independent>, everything is fine.  Unfortunately,
L<our advice to developers is|"Windows combines modifier bitmaps for C<lCtrl>, C<Alt> and C<rAlt> on C<AltGr>">
to make the bitmap on C<rAlt> I<consume the bitmap for C<lCtrl>> (to avoid developers’ confusion).  Then this algorithm would
B<“wrongly”> find
out that “removing C<lCtrl> does not change the result” — so this case should be special-cased: avoid removing C<lCtrl> if C<rAlt>
is down and
L<it is not known that the flag C<KLLF_ALTGR> is absent|"Many applications need to know the state of hidden flag C<KLLF_ALTGR>">.

B<Note:> for the last stage, it is advisable to “pass the obtained string/prefix-char to ourselves” via C<CHAR> and C<DEADCHAR>
messages — as C<TranslateMessage()> does.  This would allow external applications to interact with our application “in the usual
way”: by sending suitable messages.

B<Reminder:> the
L<non-destructive ways ToUnicode()|https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-tounicodeex> can be
coded in two ways: first, on newer Windows, put C<wFlags=0x04>.  On older Windows, put C<wFlags=0x01|0x02>, raise the high bit
of C<lParam> “from key-down to key-up”, and process
L<“input-by-number”|"Keyboard input on Windows, Part II: The semantic of ToUnicode()"> in your application.  (Theoretically, one
could use C<wFlags=0x02> — but I expect that processing key-up events for [hex]digits during input-by-number — they
change the state — may be tricky.  Should not one follow the I<very quirky> [see the preceding reference] logic of the kernel
I<precisely>?)

=head2 Possible enhancements and caveats

The method above is so powerful that one may want to use it to enhance the user’s experience yet more.  For 
example, suppose a Greek keyboard layout sends Latin characters after a prefix-key C<Shift-Space> (so C<Shift-Space σ> sends C<s>).
How can a user trigger the C<Alt-S> binding of the application?  “The obvious way” is to try C<Alt-Shift-Space σ>.  This
may obviously fail in two cases: the keyboard layout may “do something” on C<Alt-Shift-Space>; or: the application may
have C<Alt-Shift-Space> bound to some action.

However, observe what happens when none of these cases is applicable.  With the scheme above the keyboard-input handler of the
application I<already knows> that C<Alt-Shift-Space> is “C<Alt> combined with the prefix key C<Shift-Space>”.  In principle, I<if
it can get the “feedback from the event-binding engine” that C<Alt-Shift-Space> is unbound>, it I<might> start processing this
as an “C<Alt>-modified sequence of keypresses”.  (For this, it would memorize that “C<Alt>-modifier should be applied to the
eventual result”, and proceed until an “insert event” or a bindable-event is detected — possibly stripping the “êxcessive”
C<Alt>-modifiers.  Then the engine would apply “another excessive modifier” C<Alt> to the resulting “insert event”. — And what to
do with bindable events — it is a judgement call…)  C<Warning:> one may choose to also apply this approach for C<Ctrl>
modifier — mutatis mutandis.

C<Warning:> (This concerns a completely fictional situation.)  We did not discuss what to do if a text input event corresponds to
“a multi-character sequence I<with “excess” modifiers>. — And this is a judgement call!  For example, to bind C<Alt-Space> Emacs’
APIs use a “symbolic name” C<space>, so from the point of view of these APIs this event is a combination of a modifier C<Alt> and
this “symbol” C<space>.  How to present to it the input event which has an “excessive modifier” C<Alt> and the “delivered string”
being C<"space">?!  One made-up solution is to present it using a “symbol name” C<S_space> — this should not cause any confusion
with C<VK_>-codes.  Another is to deliver C<Alt-s Alt-p Alt-a …>.  (Or just make this user-configurable!)

C<Note:> One major shortcoming of different schemes of binding events is that they assume that “the language of” the keyboard
matches the language of the UI of the application/session.  Suppose that the application “works in English context”, but I switched
to Greek keyboard layout to enter a Greek fragment.  Suppose I want to trigger an event assigned to C<Alt-s> key chord.  The user
would definitely prefer this to be triggered by pressing C<Alt> and hitting the key marked as C<s>!  However, what the application
can see is the event C<Alt-σ> — although it may also deduce that it comes from C<VK_>-code C<S>, so it may be I<also> interpreted
as C<Alt-s>. — And the application cannot I<guess my intent> — did I want to trigger the binding assigned to C<Alt-σ> or to
C<Alt-s>?!

(It seems that to make the best of a bad situation, the input engine may need to pass to the binding engine I<a list of possible
interpretations> of a key chord (as opposed to “just one”) — delegating the resolution to the binding engine.  If the latter can
see that only one of these is defined — then it is clear what to do!)

One way to put a workaround for this (on the level of the keyboard layout) is
discussed in the note in L<"A convenient assignment of C<KBD*> bitmaps to modifier keys">.

=head2 Can an application on Windows accept keyboard events?  Part I: insert only

B<Warning:> Nowadays this may be obsolete.  I recommend inspecting L<"Can an application on Windows accept keyboard events?"> (and
the following sections) first.

The logic described above makes the kernel deliver more or less “correct” C<WM_(SYS)CHAR> messages
to the application.  The only bindings which may be defined in the keyboard layout, but will not be
seen as C<WM_(SYS)CHAR> are those in modification columns which involve C<KBDALT>, and do not
involve any bits except C<KBDSHIFT> and C<KBDKANA>.  (Due to
L<the stripping of C<KBDALT>|"Keyboard input on Windows, Part II: The semantic of ToUnicode()"> described
above, these modification columns are never accessed — I<well, they are, but
L<only for input-by-number|"Keyboard input on Windows, Part II: The semantic of ToUnicode()">>.)

Try to design an application with an entry field; the application should insert B<ALL> the
characters ”delivered for insertion” by the keyboard layout and the kernel.  The application
should not do anything else for all the other keyboard events.  First, ignore
the C<KBDALT> stripping.

Then the only C<WM_(SYS)CHAR> which are NOT supposed to insert the contents to the editable UI fields are the
L<Customary “special” keybindings> described above.  They are easy to recognize and ignore: just
ignore all the C<WM_(SYS)CHAR> carrying characters in the range C<0x00..0x1f>, C<0x7f>, and ignore C<0x20>
delivered when one of C<Ctrl> keys is down.  So the application which inserts all the I<other>
C<WM_(SYS)CHAR>s will follow I<the intent> of the keyboard as close as possible.

Now return to consideration of C<KBDALT> stripping.  If the application follows the policy above,
pressing C<Alt-b> would enter C<b> — provided C<Alt> is mapped to C<KBDALT>, as done
on standard keyboards.  So the application should recognize which C<WM_CHAR> carrying C<b>
are actually due to stripping of C<KBDALT>, and should not insert the delivered characters.

Here comes the major flaw of the Windows’ keyboard subsystem: the kernel translates
SCANCODE —→ VK_CODE —→ ORED_MASK —→ MODIFICATION_COLUMN, then operates in terms of
ORed masks and modification columns.  The application can access only the first two levels
of this translation; one cannot query the kernel for any information about the last
two numbers.  (Except for the API L<VkKeyScanEx()|http://msdn.microsoft.com/en-us/library/windows/desktop/ms646332%28v=vs.85%29.aspx>,
but it is unclear how this API may help: it translates “in wrong direction” and covers only BMP.)
Therefore, there is no bullet-proof way to recognize when C<WM_(SYS)CHAR> arrived
due to C<KBDALT> stripping.

B<NOTE:> of course, if only C<Shift/Alt/Ctrl> keys are associated to non-0 ORed mask bitmaps,
and they are associated to the “expected” C<KBDSHIFT/KBDALT/KBDCTRL> bits, then the
application would easily recognize this situation by checking whether C<Alt> is down,
but C<Ctrl> is not.  (Also observe that this is exactly the situation distinguishing
C<WM_CHAR> from C<WM_SYSCHAR> — no surprises here!)

Assuming that the application uses this method, it would correctly recognize stripped
events on the “primitive” keyboards.  However, on a keyboard with an extra modifier
key (call it C<Super>; assume its mask involves a non-SHIFT/ALT/CTRL/KANA bit),
the C<Alt-Super-key> combination will not be stripped by the kernel, but the application
would think that it was, and would not insert the character in C<WM_CHAR> message.  A bug!

Moreover, if “supporing only the naive mapping” were a feasible
restriction, there would be no reason for the kernel to go through the extra step of “the ORed mask”.
Actually, to have a keyboard which is simultaneously backward compatible, easy for users, and
covering a sufficiently wide range of possible characters, one B<must> use more or
less convoluted implementations (as in L<"A convenient assignment of C<KBD*> bitmaps to modifier keys">).

B<CONCLUSION:> the fact that the kernel and the applications speak different
incompatible languages makes even the primitive task discussed here impossible
to code in a bullet-proof way.  A heuristic workaround exists, but it will not
work with all keyboards and all combinations of modifiers.

B<CAVEAT with the above assignment:> some applications (e.g., Emacs) manage to distinguish
C<lCtrl+lAlt> combination of modifier keys from the combination C<lCtrl+rAlt> produced by 
a typical C<AltGr>; these applications are able to use C<lCtrl+lAlt>-modified 
keys as a bindable accelerator keys.  We address this question in the L<Part IV|"Can an application on Windows accept keyboard events?  Part IV: application-specific modifiers">.

=head2 Can an application on Windows accept keyboard events?  Part II: special key events

B<Warning:> Nowadays this may be obsolete.  I recommend inspecting L<"Can an application on Windows accept keyboard events?"> (and
the following sections) first.

In the preceding section, we considered the most primitive application accepting
the user inserting of characters, and nothing more.  “Real applications” must
support also keyboard actions different from “insertion”; so those KEYDOWN events
which are not related to insertion may trigger some “special actions”.  To model a full-featured
keyboard input, consider the following specification:

As above, the application has an entry field, and should insert B<ALL> the
characters ”delivered for insertion” by the keyboard layout and the kernel.
For all the keyboard events I<not related to insertion of characters>, the application
should write to the log file which of C<Ctrl/Alt/Shift> modifiers were down,
and the virtual keycode of the KEYDOWN event.  Again, at first, we ignore
L<the C<KBDALT> stripping|"Keyboard input on Windows, Part II: The semantic of ToUnicode()">.

At first, the problem looks simple: with the standard message pump, when C<WM_(SYS)KEYDOWN>
message is processed, the corresponding C<WM_(SYS)(DEAD)CHAR> messages are already
sent to the message queue.  One can PeekMessage() for these messages; if present,
and not “special”, they correspond to “insertion”, so nothing should be written to the log.
Otherwise, one reports this C<WM_(SYS)KEYDOWN> to the log.

Unfortunately, this solution is wrong.  Inspect again what the kernel is delivering
during L<the input-by-number via numeric keyboard|"Keyboard input on Windows, Part II: The semantic of ToUnicode()">:
the KEYDOWN for decimal/hex digits
B<is> a part of the “insertion”, but it does not generate any C<WM_(SYS)(DEAD)CHAR>.
Essentially, the application may see C<Alt-F> pressed during the processing of
C<Alt-NumPadPlus+F+1+2>, but even if C<Alt-F> is supposed to format the paragraph,
this action should not be triggered (but C<U+0F12> should be eventually inserted).

B<CONCLUSION:> Input-by-number is getting in the way of using the standard message
pump.  C<SOLUTION>: one should write a clone of TranslateMessage() which delivers
suitable C<WM_USER*> messages for KEYDOWN/KEYUP involved in Input-by-number.  Doing
this, one can also remove sillyness from the Windows’ handling of Input-by-number
(such as taking C<mod 256> for numbers above 255).

B<POSSIBLE IMPLEMENTATION>: myTranslateMessage() should:

=over 4

=item *

when non handling L<input-by-number|"Keyboard input on Windows, Part II: The semantic of ToUnicode()">,
call ToUnicode(), but use C<wFlag=0x01|0x02>, so that ToUnicode() does not handle input-by-number.

=item *

Recognize input-by-number starters by the scancode/virtual-keycode, the presence of C<VK_MENU> down, and
the fact that ToUnicode() produces nothing or C<'0'..'9','.',',','+'>.

=item *

After the starter, allow continuation by checking the scancode/virtual-keycode and the presence of C<VK_MENU> down.
Do not call ToUnicode() for continuation keydown/up events.

=item *

After a chain of continuations followed by KEYUP for C<VK_MENU>, one should PostMessage() for C<WM_(UNI)CHAR> with
accumulated input.

=back

Combining this with the heuristical recognition of stripped C<KBDALT>, one gets an architecture
with a naive approximation to handling of C<Alt> (but still miles ahead of all the applications
I saw!), and bullet-proof handling of other combinations of modifiers.

B<NOTE:> this implementation of MyTranslateMessage() loses one “feature” of the original one:
that input-by-number is disabled in the presence of (popup) menu.  However, since I never saw
this “feature” in action (and never have heard of it described anywhere), this must be of
negligible price.

B<NOTE:> I<ALL> the applications I checked do this logic wrong.  Most of them check B<FIRST> for
“whether the key event looks like those which should trigger special actions”, then perform
these special actions (and ignore the character payload).

As shown above, the reasonable way is to do this in the opposite order, and check for 
special actions only I<AFTER> it is known that the key event does not carry a character payload.
The impossibility of reversing the order of these checks is due to the same reason as one discussed
above: the
kernel and application speaking different languages.

Indeed, since the application knows nothing
about ORed masks, it has no way to distinguish that, for example, C<lCtrl-rCtrl-=> may be I<SUPPOSED> to be
distinct from C<lCtrl-=> and C<rCtrl-=>, and while the last two do not carry the character
payload, the first one does.  Checking I<FIRST> for the absense of C<WM_(SYS)(DEAD)CHAR>
delegates such a discrimination to the kernel, which has enough information about the
intent of the keyboard layout.  (Likewise, the keyboard may define the pair of C<DEADKEY>
and C<Ctrl-A> to insert ᵃ.  Then C<Ctrl-A> alone will not carry any character payload,
its combination with a deadkey may.)

Why the applications are trying to grab the potential special-key messages as early 
as possible?  I suspect that the developers are afraid that otherwise, a keyboard layout may
“steal” important accelerators from the application.  While this is technically possible,
nowadays keyboard accelerators are rarely the I<only> way to access features of the applications;
and among hundreds of keyboard layout I saw, all but 2 or 3 would not “steal” I<anything> from applications.
(Or maybe the developers just have no clue that the correct solution is so simple?)

B<NOTE:> Among the applications I checked, the worst offender was Firefox (it improved a lot after I reported
its problems; see below).  It follows L<a particularly
unfortunate advice by Mike Kaplan|http://blogs.msdn.com/b/michkap/archive/2005/01/19/355870.aspx>
and tries to reconstruct the mentioned above row/columns table of the keyboard layout, then
uses this (heuristically reconstructed) table as a substitute for the real thing.  And
due to the mismatch of languages spoken by kernel and applications, working via such an 
attempted reconstruction turns out to have very little relationship to the actually intended
behaviour of the keyboard (the behaviour observed in less baroque applications).  In particular, if
keyboards uses different modification columns for C<lCtrl-lAlt> and C<AltGr>=C<rAlt>
modifiers, pressing C<AltGr-key> inputs wrong characters in Firefox.

(After I reported Firefox bugs, the handling much improved.  In v.55 I can observe one major problem — but
on grandious scale: in some layouts defining C<OEM_8> JIS left-of-backspace
“replacement-for-ISO-key”, Firefox locks completely when one switches to these keyboards.)

B<NOTE:> Among notable applications which fail spectacularly was Emacs (this changed
dramatically when my patches were accepted).  The developers
forget that for a generation, it is already XXI century; so they L<use ToAscii() instead of
ToUnicode()|http://fossies.org/linux/misc/emacs-24.3.tar.gz:a/emacs-24.3/src/w32fns.c>!
(Even if ToUnicode() is available, its result is converted to the result of the
corresponding ToAscii() code.)

In addition to 8-bitness, Emacs also suffers from check-for-specials-first syndrome…

=head2 Can an application on Windows accept keyboard events?  Part III: better detection of C<KBDALT> stripping

B<Warning:> Nowadays this may be obsolete.  I recommend inspecting L<"Can an application on Windows accept keyboard events?"> (and
the following sections) first.

We explained above that L<it is not possible to make a bullet-proof algorithm
handling the case when C<KBDALT> might have been stripped by the kernel|"Can an application on Windows accept keyboard events?  Part I: insert only">.  The
very naive heuristic algorithm described there will recognize the simplest
cases, but will also have many false positives: for many combinations it will decide
that C<KBDALT> was stripped while it was not.  The result will be that
when the kernel reports that the character C<X> is delivered, the 
application would interpret it as C<Alt-X>, so C<X> would not be inserted.
It will not handle, for example,
the C<lAlt-Menu-key> modifier combinations with L<the assignment of mask
from that section|"A convenient assignment of C<KBD*> bitmaps to modifier keys">.

Indeed, with this assignment, the only combination of modifiers for which the kernel will strip C<KBDALT>
is C<lAlt> (and C<lAlt+Win> if one does not assign any bits to C<Win>).
So C<lAlt-Menu-key> is not stripped, hence the 
correct C<WM_*CHAR> is delivered by the kernel.  However, since this combination is
still visible to the application as having C<Alt>, and not having C<Ctrl>,
it is delivered as the C<SYS> flavor.

So the net result is: one designed a nice assignment of masks to the modifier 
keys.  This assignment makes keypresses successfully navigate around the quirks 
of I<the kernel>’s calculations of the character to deliver.  However, the naive 
algorithm used by I<the application> will force the application to ignore this
correctly delivered character to insert.

A very robust workaround for this problem is introduced in the
L<Part IV|"Can an application on Windows accept keyboard events?  Part IV: application-specific modifiers">.
What we discuss here is a simple heuristic to recognize the combinations involving 
C<Alt> and an “unexpected modifier”, so that these combinations become
exceptions to the rule “C<SYS> flavor means ‘do not insert’”.

B<NAIVE SOLUTION:> when C<WM_SYS*CHAR> message arrives, inspect the virtual keycodes
which are reported as pressed.  Ignore the keycode for the current message.
Ignore the keycodes for “usual modifiers” (C<Shift/Alt/Kana>) which are
expected to keep stripping.  Ignore the keycode for the keys which may be
kept “stuck down” by the keyboards (see L<"Far Eastern keyboards on Windows">).
If some keycode remains, then consider it as an “extra” modifier, and ignore
the fact that the message was of C<SYS> flavor.

So all one must do is to define one user message (for input-by-number-in-progress),
code two very simple routines,  MyTranslateMessage() and HasExtraModifiersHeuristical(), and perform two 
PeekMessage() on KEYDOWN event, and one gets a powerful almost-robust
algorithm for keyboard input on Windows.  (Recall that all the applications
I saw provide close-to-abysmal support of keyboard input on Windows.)

=head2 Can an application on Windows accept keyboard events?  Part IV: application-specific modifiers

B<Warning:> Nowadays this may be obsolete.  I recommend inspecting L<"Can an application on Windows accept keyboard events?"> (and
the following sections) first.

Some application handle certain keys as “extra modifiers for the purpose of
application-specific accelerator keypresses”.  For example, Emacs may treat
the C<ApplicationMenu> in this way (as a C<Super> modifier for its bindable-keys
framework).  Usually, C<ApplicationMenu> does not
contribute anything into the ORed mask; hence, C<ApplicationMenu-letter>
combination will deliver the same character as just C<letter> alone.  When
the application treats C<ApplicationMenu-letter> as an accelerator, it must
ignore the character delivered by this combination.

Additionally, many keyboard layouts
use the C<KLLF_ALTGR> flag (it makes the kernel to fake pressing/releasing the 
left C<Ctrl> key when the right C<Alt> is pressed/released) with “standard”
assignments of the ORed masks.  On such keyboards, pressing right C<Alt> (i.e.,
C<AltGr>) delivers the same characters as pressing any C<Ctrl> together with 
any C<Alt>.  On the other hand, an application may distinguish left-C<Ctrl> combinined 
with left-C<Alt> from C<AltGr> pressed
on such keyboards by inspecting which (virtual) keys are currently down.  So the application 
may consider left-C<Ctrl> combinined with left-C<Alt>
as “intended to be an accelerator”; then the application would ignore the characters delivered by
such a keypress.

One can immediately see that such applications would inevitably enter into conflict
with keyboards which B<define> these key combinations.  For example, on a keyboard
which defines an ORed mask for C<ApplicationMenu>, pressing C<ApplicationMenu-letter>
I<should> deliver a different character than pressing C<letter>.  However, the
application does not know this, and just ignores the character delivered by
C<ApplicationMenu-letter>.

A similar situation arises when the keyboard defines C<leftCtrl-leftAlt-letter> to
deliver a different character than C<AltGr-letter>.  Again, the character will be ignored
by the application.  Since the fact that such a “unusual” keyboard is active
implies user's intent, such behaviour is a bug of the application.

B<CONCLUSION:> an application must interpret a keypress as “intended to be an accelerator”
only if this keypress produces no character, or produces B<the same> character as
the key without the “extra” modifier.  (Correspondingly, if replacing C<leftAlt> by
C<rightAlt> does not change the delivered character.)

B<IMPLEMENTATION:> to do this, the application must be able to query “what would happen
if the user pressed different key combinations?”; such a query requires “non-destructive”
calls of ToUnicode().  (These calls must be done I<before> the “actual”, destructive, 
call of ToUnicode() corresponding to the currently pressed down modifiers.)

Fortunately, with the framework described in the
L<Part III|"Can an application on Windows accept keyboard events?  Part III: better detection of C<KBDALT> stripping">,
the call of ToUnicode() is performed with C<wFlags> being C<0x01|0x02>.  As explained near the end of the section
L<"Keyboard input on Windows, Part II: The semantic of ToUnicode()">, this call has a “non-destructive”
flavor!  Hence, for applications with such “enhanced” modifier keys, the logic of the
L<Part III|"Can an application on Windows accept keyboard events?  Part III: better detection of C<KBDALT> stripping">
should be enhanced in the following ways:

=over 4

=item *

Make a non-destructive call of ToUnicode().  Store the result.  If no insertable character
(or deadkey) is delivered, ignore the rest.

=item *

If both left C<Ctrl> and left C<Alt> are down (AND right C<Ctrl> AND right C<Alt> are up!) 
replace left C<Alt> by the right C<Alt>, and
make another non-destructive call of ToUnicode().  If the result is identical to the first one,
mark C<leftCtrl+leftAlt> as “special modifiers present for accelerators”.  (This assumes that
L<the keyboard has C<KLLF_ALTGR> bit set|"Many applications need to know the state of hidden flag C<KLLF_ALTGR>">.)

Remove left C<Ctrl> and left C<Alt> from the collection of keys which are down (argument to ToUnicode()),
and continue with the previous step.
(This may be generalized to other combinations of left/right C<Alt>/C<Ctrl>.)

=item *

For every other “special modifier” virtual key which is down,
make another non-destructive call of ToUnicode() with this virtual key up.
If the result is identical to the first one, mark this “special modifier” as “present for accelerators”.

=item *

Finally, if nothing suitable for accelerators is found, make a “usual” call of ToUnicode()
(so that on future keypresses the deadkey finite automaton behaves as expected).  Generate the
corresponding messages.

=back

If no insertable character is delivered, or suitable “extra” accelerators are found, the 
process-the-accelerator logic should be triggered.

For example, if the character Ω is delivered, and a special modifier C<ApplicationMenu> is down
and marked as suitable as accelerator, then Ω will be ignored.  The accelerator for C<ApplicationMenu-Ω>
should be triggered.  (Processing this as C<ApplicationMenu-Shift-ω> may be also done.  This may require an 
extra non-destructive call.)

An alternative logic is possible: if this Ω was generated by modifiers C<lCtrl-rAlt-Shift-ApplicationMenu>
with the virtual key C<VK_W>, then the application may query what C<VK_W> generates standalone (for example,
cyrillic ц), and trigger the accelerator for C<Ctrl-Alt-Shift-ApplicationMenu-ц>.  (This assumes that
C<lCtrl-rAlt-Shift> with C<VK_W> generates the same Ω!)

If no character is delivered, then this is a “trivial” situation, and the framework of accelerator keys
should be called as if the complication considered here did not exist.

B<NOTE:> this logic handles the intended behaviour of C<Alt> key as well!  So, with this implementation,
the application would

=over 5

=item *

Handle L<C<Alt>-NUMPAD input-by-number|"Keyboard input on Windows, Part II: The semantic of ToUnicode()"> in an intuitive mostly
compatible with Windows way 
(but not bug-for-bug compatible with the Windows' way);

=item *

Would recognize C<Alt> modifier which does not change the delivered character as such.  (So it may be processed
as the menu accessor.)

=item *

Would recognize B<all> the key combinations defined by the keyboard layout (and deliverable via ToUnicode());

=item *

Would recognize all the application-specific extra modifier keys which do not interfere with the
key combinations defined by the keyboard layout.

=back

=head2 Far Eastern keyboards on Windows

The syntax of defining these keyboards is documented in F<kbd.h> of the toolkit.  
The semantic of the NLS table is undocumented.  Here we fix this.

The function returning the NLS table should be exported with ordinal 2.
The offsets of both tables in the module should be below 0x10000.
The keyboard layout should define a function with ordinal 3 or 5 returning 0, or
be loaded through such a function returning non-0; the signature is

    BOOL ordinal5(HKL hkl, LPWSTR __OUT__ dllname , PCLIENTKEYBOARDTYPE type_if_remote_session, LPVOID dummy);
    BOOL ordinal3(LPWSTR __OUT__ dllname);

if return is non-0, keyboard is reloaded from C<dllname>.
    
In short, these layouts have an extra table which may define the following enhancements:

  One 3-state (or 2-state) radio-button:
      on keys with VK codes DBE_ALPHANUMERIC/DBE_HIRAGANA/DBE_KATAKANA
         (the third state can be also toggled (?!) independently of the others).
  Three Toggling (like CAPSLOCK) button (pairs): 
      toggling radio-button-like VK codes DBE_SBCSCHAR/DBE_DBCSCHAR, DBE_ROMAN/DBE_NOROMAN, DBE_CODEINPUT/DBE_NOCODEINPUT
  Make key produce different VK codes with different modifiers.
  Make a “reverse NUMPAD” translation.
  Manipulate a couple of bits of IME state.
  A few random hacks for key-deficient hardware layouts.

(Via assigning ORed masks for modification bitmaps to radio-buttons, the radio-buttons and toggle-buttons above may affect the layout.
Using this, it is easy to convert each toggling buttons to 2-state radiobuttons.
The limitation is that the number of modification columns compatible with the
extra table is at most 8.)

B<WARNING:> it turns out that the preceding paragraph is bogus.  In fact, I<these specific FE-hacks operate on very different
assumptions> than the rest of the Windows’ keyboard logic.  In particular, the tables-of-length-8 are driven I<not by ORed-bitmaps
assigned to the modification keys>, but by “physical modifier C<Shift>, C<Ctrl>, C<Alt> modification buttons.  (In particular,
even with C<KLLF_ALTGR>-flag, the key C<AltGr> is counted as C<Alt> and not C<Ctrl+Alt>.)

Every C<VK> may be associated to two tables of functions, the “normal” one, and the “alternative” one.  For
every modification column, each table
assigns a filter id, and a parameter for the filter.  (Recall that columns are associated
to the ORed masks by the table in the C<MODIFIERS> structure.  One B<must> define all the entries 
in the table — or at least the entries reachable by the 
modifier keys.  B<NOTE:> the limit on the number of states in the tables is 8; it is not clear what happens with the 
states above this; some versions of Windows may buffer-overflow.)

The input/output for the filters consists of: the C<VK>, C<UP>/C<DOWN> flag, the flags associated to the scancode in C<< KBDTABLES->ausVK >>
(may be added to upsteam), the 
parameter given in C<VK_F> structure (and an unused C<DWORD> read/write parameter).  A filter may change these parameters,  
then pass the event forward, or it may ignore an event.  Filters by ID:

  KBDNLS_NULL		Ignore key (should not be called; only for unreachable slots in the tables).
  KBDNLS_NOEVENT	Ignore key.
  KBDNLS_SEND_BASE_VK	Pass through VK unchanged.
  KBDNLS_SEND_PARAM_VK	Replace VK by the number specified as the parameter.
  KBDNLS_KANAMODE	Ignore UP; on DOWN, toggle (=generate UP-or-DOWN for) DBE_KATAKANA

			  These 3 generate UP for “other” key, then DOWN for the target (as needed!):
  KBDNLS_ALPHANUM	Ignore UP;	DBE_ALPHANUMERIC,DBE_HIRAGANA,DBE_KATAKANA → DBE_ALPHANUMERIC
  KBDNLS_HIRAGANA	Ignore UP;	DBE_ALPHANUMERIC,DBE_HIRAGANA,DBE_KATAKANA → DBE_HIRAGANA
  KBDNLS_KATAKANA	Ignore UP;	DBE_ALPHANUMERIC,DBE_HIRAGANA,DBE_KATAKANA → DBE_KATAKANA

  KBDNLS_SBCSDBCS	Ignore UP;	Toggle DBE_SBCSCHAR / DBE_DBCSCHAR
  KBDNLS_ROMAN		Ignore UP;	Toggle DBE_ROMAN / DBE_NOROMAN
  KBDNLS_CODEINPUT	Ignore UP;	Toggle DBE_CODEINPUT / DBE_NOCODEINPUT
  KBDNLS_HELP_OR_END	Pass-through if NUMPAD flag ON (in ausVK); send-or-toggle HELP/END (see below)
  KBDNLS_HOME_OR_CLEAR	Pass-through if NUMPAD flag ON (in ausVK); send HOME/CLEAR (see below)
  KBDNLS_NUMPAD		If !NUMLOCK | SHIFT, replace NUMPADn/DECIMAL by no-numpad flavors
  KBDNLS_KANAEVENT	Replace VK by the number specified as the parameter. On DOWN, see below
  KBDNLS_CONV_OR_NONCONV	See below

The startup values are C<ALPHANUMERIC>, C<SBCSCHAR>, C<NOROMAN>, C<NOCODEINPUT>.

Typical usages:

  KBDNLS_KANAMODE (VK_KANA (Special case))
  KBDNLS_ALPHANUM (VK_DBE_ALPHANUMERIC)
  KBDNLS_HIRAGANA (VK_DBE_HIRAGANA)
  KBDNLS_KATAKANA (VK_DBE_KATAKANA)
  KBDNLS_SBCSDBCS (VK_DBE_SBCSCHAR/VK_DBE_DBCSCHAR)
  KBDNLS_ROMAN (VK_DBE_ROMAN/VK_DBE_NOROMAN)
  KBDNLS_CODEINPUT (VK_DBE_CODEINPUT/VK_DBE_NOCODEINPUT)
  KBDNLS_HELP_OR_END (VK_HELP or VK_END)     [NEC PC-9800 Only]
  KBDNLS_HOME_OR_CLEAR (VK_HOME or VK_CLEAR) [NEC PC-9800 Only]
  KBDNLS_NUMPAD (VK_xxx for Numpad)          [NEC PC-9800 Only]
  KBDNLS_KANAEVENT (VK_KANA) [Fujitsu FMV oyayubi Only]	
  KBDNLS_CONV_OR_NONCONV (VK_CONVERT and VK_NONCONVERT) [Fujitsu FMV oyayubi Only]

Toggle (= 2-state) and 3-state radio-keys are switched by sending KEYUP for the currently 
“active” key, then KEYDOWN for the newly activated key.  When switching 3-state, additional
action happens depending on the new state:

  DBE_ALPHANUMERIC	If IME is off, and KANA toggle is on,  switch IME on  in the KATAKANA mode
  DBE_HIRAGANA		If IME is off, and KANA toggle is off, switch IME off in the ALPHANUMERIC mode
  DBE_KATAKANA			SAME AS HIRAGANA

Additionally, C<KEYDOWN> of C<KBDNLS_KANAEVENT> switches IME to

  KANA toggle on:		switch IME off in the ALPHANUMERIC mode
  KANA toggle off:		switch IME on  in the KATAKANA mode

and C<KBDNLS_CONV_OR_NONCONV> (on C<KEYUP> and C<KEYDOWN>) passes through, and does

  KANA toggle on, IME off:	switch IME off in the ALPHANUMERIC mode
  otherwise:			Do nothing

(The semantic of IME being-in/switching-to OFF/ON mode is not clear (probably IME-specific).
The switching happens by
calling C<RequestDeviceChange(pDeviceInfo, GDIAF_IME_STATUS, TRUE)> for devices with a C<handle>
and C<type == DEVICE_TYPE_KEYBOARD>, while putting the request at into global memory — unless
C<IMECOMPAT_HYDRACLIENT> flag is set on the foreground keyboard.)

For C<KBDNLS_HOME_OR_CLEAR>, the registry is checked at statup.  For C<KBDNLS_HELP_OR_END>, the registry is checked at statup, and:

  KANA_AWARE:	flips END/HELP if KANA toggle is ON (on input, “HELP” means not-an-END)
  otherwise:	sends END/HELP depending on what registry says.

The checked values are C<helpkey>, C<KanaHelpKey>, C<clrkey> in the hive C<RTL_REGISTRY_WINDOWS_NT\WOW\keyboard>.

Which of two tables is chosen is controlled by the type (C<NULL>/C<NORMAL>/C<TOGGLE>) of the key's tables, and the (per key)
history bit.  
The initial state of the bit is in C<NLSFEProcCurrent> 
(L<StuxNet hits here|http://www.eset.com/us/resources/white-papers/Stuxnet_Under_the_Microscope.pdf>!).
The tables of type C<NULL> are ignored (the key descriptor passes all events 
through), the C<NORMAL> key uses only the first table.  The C<TOGGLE> key uses the first table on KEYDOWN, and 
uses the first or the second table on KEYUP.  The choice depends on modifiers present in the preceding KEYDOWN;
the bitmap C<NLSFEProcSwitch> is indexed by the modification column of KEYDOWN event; the second table is
used on the following KEYUP if the indexed bit is set.  (The KEYREPEAT events are handled the same way as KEYUP.)

The typical usage of C<TOGGLE> keys is to make the KEYUP event match B<what KEYDOWN did> no matter what
is the order of releasing the modifier keys and the main key.
Having the history bit up “propagates” to KEYUP the information about which modifiers were active on KEYDOWN.  This helps in ensuring
consistency of some actions between the KEYDOWN event and the corresponding KEYUP event: remember that the state of modifiers 
on KEYUP is often different than the state on KEYDOWN: people can release modifiers in different orders: 

  press-Shift, press-Enter, release-Shift, release-Enter	--->	Shift-Enter pressed, Enter released
  press-Shift, press-Enter, release-Enter, release-Shift	--->	Shift-Enter pressed and released

If pressing C<Shift-Enter> acts as if it were the C<F38> key (and only so with C<Shift>!), to ensure consistency, one would need 
to make releasing C<Shift-Enter> B<and> also releasing C<Enter> to act as if it were the C<F38> key.  So one can make pressing
C<Shift-Enter> special (via the first table), sets the history bit on C<Shift-Enter>, and make I<the second table> map C<Enter> 
and C<Shift-Enter> to be special too (send C<F38>) I<if the history bit is set>.

B<Remark:> the standard key processing has its own filters too.  C<AltGr> processing adds fake C<lCtrl> up/down events
(provided the flag C<KLLF_ALTGR> is set);
C<Shift-Cancels-CapsLock> processing ignores/fakes the C<KEYDOWN>/C<KEYUP> for C<VK_CAPITAL> (=C<CapsLock>)
(provided the flag C<KLLF_SHIFTLOCK> is set); C<Shift-Multiply> becomes
C<VK_SNAPSHOT> (same for C<Alt>); C<Ctrl-ScrollLck/Numlock> become C<VK_CANCEL>/C<VK_PAUSE>; C<Ctrl-Pause> may become C<VK_CANCEL>.
OEM translations (NumPad→Cursor, except C<C-A-Del>; C<00> to double-press of C<0>) come first, then locale-specific (C<AltGr>,
C<Shift-Cancels-CapsLock>), then those defined in the tables above.

B<Remark:> As opposed to these translations, C<KLLF_LRM_RLM> and C<Alt-NUMPADn> is actually handled inside the 
event loop, by ToUnicode().

B<Remark:> L<http://www.toppa.com/2007/english-windows-xp-with-a-japanese-keyboard/> (and references inside!)
explains fine points of using Japanese keyboards.  See also: L<http://www.coscom.co.jp/learnjapanese801/lesson08.html>.

=head2 Example of changing C<VK_>-codes depending on modifiers

The logic defined in the preceding section shows that with this:

    {
        VK_SPACE,                   // Base Vk
        KBDNLS_TYPE_TOGGLE,         // NLSFEProcType
        KBDNLS_INDEX_NORMAL,        // The initial memory bit  (.NLSFEProcCurrent)
        0x08, /* 00001000 */        // NLSFEProcSwitch (is “active” in positions marked with ☑ below)
        {                           // NLSFEProc
            {KBDNLS_SEND_BASE_VK,0},        // Base    (These are “real” states of SHIFT etc, not “fancy”)
            {KBDNLS_SEND_BASE_VK,0},        // Shift
            {KBDNLS_SEND_BASE_VK,0},        // Control
            {KBDNLS_SEND_PARAM_VK,VK_PA1},  // Shift+Control      ☑ (= “use the second table on release”)
            {KBDNLS_SEND_BASE_VK,0},        // Alt                  (AltGr is counted as Alt and not Ctrl+Alt — even with KLLF_ALTGR)
            {KBDNLS_SEND_BASE_VK,0},        // Shift+Alt
            {KBDNLS_SEND_BASE_VK,0},        // Control+Alt
            {KBDNLS_SEND_BASE_VK,0}         // Shift+Control+Alt
        },
        {                           // NLSFEProcAlt
            {KBDNLS_SEND_PARAM_VK,VK_PA1},  // Base
            {KBDNLS_SEND_PARAM_VK,VK_PA1},  // Shift
            {KBDNLS_SEND_PARAM_VK,VK_PA1},  // Control
            {KBDNLS_SEND_PARAM_VK,VK_PA1},  // Shift+Control      ☑
            {KBDNLS_SEND_BASE_VK,0},        // Alt                   AltGr ⇒ Alt
            {KBDNLS_SEND_BASE_VK,0},        // Shift+Alt
            {KBDNLS_SEND_BASE_VK,0},        // Control+Alt
            {KBDNLS_SEND_BASE_VK,0}         // Shift+Control+Alt
        }
    },

as an element of the “C<VK>-to-function table”,
C<Shift-Ctrl-Space> emits C<VK_PA1>; also, depending on the order of releasing the keys C<Space>, C<Shift> and
C<Ctrl>, the modifiers at the moment of I<release of this combination> may be arbitrary subsets of C<Shift>+C<Ctrl>.  The bitmap of
C<0x08> says to use the second table if and only if the key produces C<VK_PA1> — so I<all these arbitrary subsets> correspond to
“releasing C<VK_PA1>”.

B<Note:> observe that the last 4 entries of the second table may be triggered only if C<Alt> is “accidentally” pressed while
C<Space> was down.  While not very probable, it is still possible. — So probably it is better to fill I<all the positions> in
the second table the same.  (We do this in the example below.)

B<Warning:> since we I<are forced> to use C<VK_PA1> in the first row of the second table, this approach cannot “work 100%” if there
are more than 2 C<VK_>-codes assigned to a key (essentially, this is due to having only one bit of memory).  In FE keyboard layouts,
“extra” C<VK_>-codes (third or more) appear only when these keys “are actually key-toggles” (like C<CapsLock>), so their keyrelease
is “ignored anyway” — hence no confusion may arise.

=head2 A full example of changing C<VK_>-codes depending on modifiers

Put the “C<VK>-to-function table” C<VkToFuncTable> (similar to one discussed in the preceding section) near the start of the first
C file compiled into the layout DLL:

  static ALLOC_SECTION_LDATA VK_F VkToFuncTable[] = {
    {
        VK_CAPITAL,                   // Base Vk
        KBDNLS_TYPE_TOGGLE,         // NLSFEProcType
        KBDNLS_INDEX_NORMAL,        // (The initial value of) the memory bit  (.NLSFEProcCurrent)
        0x10, /* 00010000 */        // NLSFEProcSwitch (is “active” in positions marked with ☑ below)
        {                           // NLSFEProc
            {KBDNLS_SEND_BASE_VK,0},           // Base    (These are “real” states of SHIFT etc, not “fancy”)
            {KBDNLS_SEND_BASE_VK,0},           // Shift
            {KBDNLS_SEND_BASE_VK,0},           // Control
            {KBDNLS_SEND_BASE_VK,0},           // Shift+Control
            {KBDNLS_SEND_PARAM_VK,VK_OEM_AX},  // Alt                 ☑ (= “use the second table on release”) AltGr ⇒ Alt
            {KBDNLS_SEND_BASE_VK,0},           // Shift+Alt
            {KBDNLS_SEND_BASE_VK,0},           // Control+Alt
            {KBDNLS_SEND_BASE_VK,0}            // Shift+Control+Alt
        },
        {                // NLSFEProcAlt: if VK_OEM_AX-down was generated, generate VK_OEM_AX-up for all themod-combinations
            {KBDNLS_SEND_PARAM_VK,VK_OEM_AX},  // Base
            {KBDNLS_SEND_PARAM_VK,VK_OEM_AX},  // Shift
            {KBDNLS_SEND_PARAM_VK,VK_OEM_AX},  // Control
            {KBDNLS_SEND_PARAM_VK,VK_OEM_AX},  // Shift+Control
            {KBDNLS_SEND_PARAM_VK,VK_OEM_AX},  // Alt                 ☑ ( AltGr ⇒ Alt )
            {KBDNLS_SEND_PARAM_VK,VK_OEM_AX},  // Shift+Alt
            {KBDNLS_SEND_PARAM_VK,VK_OEM_AX},  // Control+Alt
            {KBDNLS_SEND_PARAM_VK,VK_OEM_AX}   // Shift+Control+Alt
        }
    },
  };

  static ALLOC_SECTION_LDATA KBDNLSTABLES KbdNlsTables = {
    0,                      // OEM ID (0 = Microsoft)
    0,                      // Information
    1,                      // Number of VK_F entry
    VkToFuncTable,          // Pointer to VK_F array
    0,                      // Number of MouseVk entry
    NULL                    // Pointer to MouseVk array
  };

and “report it” in a certain C<extern> function exported with the ordinal C<2>.  Two more functions returning 0 seem to be
necessary; they should be exported with ordinals C<3> and C<5> (see the F<.def> file below):

  PKBDNLSTABLES KbdNlsLayerDescriptor(VOID) {  return &KbdNlsTables;  }

  BOOL KbdLayerRealDllFile(HKL hkl, WCHAR *realDllName, PCLIENTKEYBOARDTYPE pClientKbdType, LPVOID reserve)
    {  return FALSE;  }	// FALSE means: no reload needed (However, the presence of these enables KbdNlsLayerDescriptor()

  BOOL KbdLayerRealDllFileNT4(WCHAR *RealDllName) { return FALSE;  }

Finally, the C<EXPORTS> part of F<.def> file (which should already contain C<KbdLayerDescriptor @1>) should be appended with

    KbdNlsLayerDescriptor @2
    KbdLayerRealDllFileNT4 @3
    ; for NT4 Hydra backward comptility -- @4 should be left empty.
    KbdLayerRealDllFile @5
    ; KbdLayerMultiDescriptor @6 fully undocumented

This would make C<CapsLock> pressed when C<Alt>-modifier (and no other modifier) were down to behave as C<OEM_AX>.  Moreover, since
the second table is “fully loaded”, there going to be no “stuck” C<OEM_AX> key — so, in particular, one can use C<OEM_AX> as I<a new
modifier key>!

For example, pressing C<Alt>, then C<CapsLock>, then releasing C<Alt> when keeping C<CapsLock> down allows combinging this fake-
C<OEM_AX> key with other modifiers — then combine this accord with “real keypresses”.

C<Warnong:> for less confusion, it is probably advisable to implement the C<VK_>-code-switch above I<whenever> C<Alt> is down — so
that C<Alt> may be combined with other modifiers.  Then the start of the table entry above should be changed to:

        KBDNLS_INDEX_NORMAL,        // (The initial value of) the memory bit  (.NLSFEProcCurrent)
        0xF0, /* 11110000 */        // NLSFEProcSwitch (is “active” in positions marked with ☑ below)
        {                           // NLSFEProc
            {KBDNLS_SEND_BASE_VK,0},           // Base    (These are “real” states of SHIFT etc, not “fancy”)
            {KBDNLS_SEND_BASE_VK,0},           // Shift
            {KBDNLS_SEND_BASE_VK,0},           // Control
            {KBDNLS_SEND_BASE_VK,0},           // Shift+Control
            {KBDNLS_SEND_PARAM_VK,VK_OEM_AX},  // Alt                 ☑ (= “use the second table on release”) AltGr ⇒ Alt
            {KBDNLS_SEND_PARAM_VK,VK_OEM_AX},  // Shift+Alt           ☑ (= “use the second table on release”)
            {KBDNLS_SEND_PARAM_VK,VK_OEM_AX},  // Control+Alt         ☑ (= “use the second table on release”)
            {KBDNLS_SEND_PARAM_VK,VK_OEM_AX}   // Shift+Control+Alt   ☑ (= “use the second table on release”)
        },

=head2 Another redefinition to avoid problems with the C<KLLF_ALTGR> flag

As mentioned in L<"Windows combines modifier bitmaps for C<lCtrl>, C<Alt> and C<rAlt> on C<AltGr>">, while the C<KLLF_ALTGR> flag
(in the keyboard definition) is useful for support of legacy applications, it does not allow the keyboard behave differently
with C<rAlt> and with C<lCtrl-rAlt> modifiers.

However, with these definitions C<lCtrl> and C<rAlt> produce two different C<VK_codes> depending on whether C<Ctrl> and/or
C<Alt> were pressed I<before> the corresponding keypresses:

    {
        VK_LCONTROL,                // Base Vk
        KBDNLS_TYPE_TOGGLE,         // NLSFEProcType
        KBDNLS_INDEX_NORMAL,        // (The initial value of) the memory bit  (.NLSFEProcCurrent)
        0xC0, /* 11000000 */        // NLSFEProcSwitch (is “active” in positions marked with ☑ below)
        {                           // NLSFEProc
            {KBDNLS_SEND_BASE_VK,0},           // Base    (These are “real” states of SHIFT etc, not “fancy”)
            {KBDNLS_SEND_BASE_VK,0},           // Shift
            {KBDNLS_SEND_BASE_VK,0},           // Control
            {KBDNLS_SEND_BASE_VK,0},           // Shift+Control
            {KBDNLS_SEND_BASE_VK,0},           // Alt                 (AltGr is counted as Alt and not Ctrl+Alt - even with KLLF_ALTGR)
            {KBDNLS_SEND_BASE_VK,0},           // Shift+Alt       
            {KBDNLS_SEND_PARAM_VK,VK_OEM_PA3}, // Control+Alt         ☑ (= “use the second table on release”)
            {KBDNLS_SEND_PARAM_VK,VK_OEM_PA3}  // Shift+Control+Alt   ☑ (= “use the second table on release”)
        },
        {                // NLSFEProcAlt: if VK_OEM_PA3-down was generated, generate VK_OEM_PA3-up for all themod-combinations
            {KBDNLS_SEND_PARAM_VK,VK_OEM_PA3},  // Base
            {KBDNLS_SEND_PARAM_VK,VK_OEM_PA3},  // Shift
            {KBDNLS_SEND_PARAM_VK,VK_OEM_PA3},  // Control
            {KBDNLS_SEND_PARAM_VK,VK_OEM_PA3},  // Shift+Control
            {KBDNLS_SEND_PARAM_VK,VK_OEM_PA3},  // Alt                     (AltGr is counted as Alt and not Ctrl+Alt - even with KLLF_ALTGR)
            {KBDNLS_SEND_PARAM_VK,VK_OEM_PA3},  // Shift+Alt
            {KBDNLS_SEND_PARAM_VK,VK_OEM_PA3},  // Control+Alt         ☑
            {KBDNLS_SEND_PARAM_VK,VK_OEM_PA3}   // Shift+Control+Alt   ☑
        }
    },
    {
        VK_RMENU,                // Base Vk
        KBDNLS_TYPE_TOGGLE,         // NLSFEProcType
        KBDNLS_INDEX_NORMAL,        // (The initial value of) the memory bit  (.NLSFEProcCurrent)
        0xCC, /* 11001100 */        // NLSFEProcSwitch (is “active” in positions marked with ☑ below)
        {                           // NLSFEProc
            {KBDNLS_SEND_BASE_VK,0},            // Base    (These are “real” states of SHIFT etc, not “fancy”)
            {KBDNLS_SEND_BASE_VK,0},            // Shift
            {KBDNLS_SEND_PARAM_VK,VK_OEM_PA2},  // Control             ☑ (= “use the second table on release”)
            {KBDNLS_SEND_PARAM_VK,VK_OEM_PA2},  // Shift+Control       ☑ (= “use the second table on release”)
            {KBDNLS_SEND_BASE_VK,0},            // Alt                     (AltGr is counted as Alt and not Ctrl+Alt - even with KLLF_ALTGR)
            {KBDNLS_SEND_BASE_VK,0},            // Shift+Alt
            {KBDNLS_SEND_PARAM_VK,VK_OEM_PA2},  // Control+Alt         ☑ (= “use the second table on release”)
            {KBDNLS_SEND_PARAM_VK,VK_OEM_PA2}   // Shift+Control+Alt   ☑ (= “use the second table on release”)
        },
        {                // NLSFEProcAlt: if VK_OEM_PA3-down was generated, generate VK_OEM_PA3-up for all themod-combinations
            {KBDNLS_SEND_PARAM_VK,VK_OEM_PA2},  // Base
            {KBDNLS_SEND_PARAM_VK,VK_OEM_PA2},  // Shift
            {KBDNLS_SEND_PARAM_VK,VK_OEM_PA2},  // Control             ☑ (= “use the second table on release”)
            {KBDNLS_SEND_PARAM_VK,VK_OEM_PA2},  // Shift+Control       ☑ (= “use the second table on release”)
            {KBDNLS_SEND_PARAM_VK,VK_OEM_PA2},  // Alt
            {KBDNLS_SEND_PARAM_VK,VK_OEM_PA2},  // Shift+Alt
            {KBDNLS_SEND_PARAM_VK,VK_OEM_PA2},  // Control+Alt         ☑
            {KBDNLS_SEND_PARAM_VK,VK_OEM_PA2}   // Shift+Control+Alt   ☑
        }
    }

This way one can distinguish user pressing both C<lCtrl> and C<rAlt> even with C<KLLF_ALTGR> (the result depends on the order in
which these two modifiers were pressed — though in practice this is not important).  By assigning C<PA2> and C<PA3> suitable
bitmasks, one can define how the keyboard behaves when both these modifiers are down.  (However, this requires consuming 1 extra
bit in the modifiers-bitmap.  If it is indeed 16-bit as it seems, this should be OK even with the assignment from the next
section.)

=head2 A convenient assignment of C<KBD*> bitmaps to modifier keys

In this section, we omit discussion of C<Shift> modifier; so every
bitmap may be further combined with C<KBDSHIFT> to produce two different bindings.
Assign ORed masks to the modifier keys as follows:X<AssignMasksSmart>

  lCtrl		lAlt		rAlt			Menu		rCtrl
  CTRL|LOYA	ALT|KANA	CTRL|ALT|LOYA|X1	CTRL|ALT|X2	CTRL|ALT|ROYA

with suitable backward-compatible mapping of ORed masks to modification columns.
This assignment allows using C<KLLF_ALTGR> flag (faking presses of C<lCtrl> when
C<rAlt> is pressed — this greatly increases compatibility of C<rAlt> with brain-damaged
applications), it
avoids L<stripping of C<KBDALT>|"Keyboard input on Windows, Part II: The semantic of ToUnicode()">
on C<lAlt> combined with other modifiers,
makes C<CapsLock> L<work with all relevant combinations|"Workarounds for WINDOWS GOTCHAS for application developers (problems in kernel)">,
while completely preserving all application-visible properties of keyboard events.

Note that ignoring the C<CTRL> and C<ALT> bits, all combinations of 
C<LOYA,KANA,X1,X2,ROYA> are possible, which gives at least 32 C<Shift>-pairs.

With C<KLLF_ALTGR> flag, C<rAlt> is “forced” into
C<lCtrl+rAlt> (so these combinations are not distinguishable and produce the same
bitmaps. — I<This is why> above we assigned C<CTRL|ALT|LOYA|X1> to C<right-Alt>).
Then there are 24 possible bitmaps (without using
C<Shift>) — and 3 of them are taken by C<lCtrl> C<rCtrl> and C<lAlt> — which should
better not be used for character input.  This leaves 21 possible C<Shift>-pairs.

(The L<B<izKeys> keyboard layouts|http://k.ilyaz.org> use them for the Base personality
and its C<AltGr> variant, plus 3 companion personalities (=alphabets), plus 16 for
L<different flavors|https://en.wikipedia.org/wiki/Mathematical_Alphanumeric_Symbols>
of Latin and Greek Unicode math symbols. — This misses 2 flavors of Sans-Serif+Bold Greek.
See more details in L<"Notes on the finer details of assigning modifier-bitmap bits">.)

B<WARNING:> the OS attempts to autogenerate bindings (such as C<"\004"> for C<Control-D>)
for C<Control>-alphabetical keys (based on their C<VK_>codes).  However, this is done
only if the current modifier bitmap is made of C<SHIFT> C<CTRL> and C<KANA> bits.  So with
assignments above, it is important to have dedicated columns in the C<LAYOUT> section
for C<Control->keys.  (But this is done anyway for keyboards generated with C<MSKLC>.)

B<WARNING:> without any other modifier (except C<Shift>)
L<the stripping of C<KBDALT>|"Keyboard input on Windows, Part II: The semantic of ToUnicode()">
still happens with the assignment above.  It results in the bitmap C<KBDKANA> (possibly combined
 with C<KBDSHIFT>).  For normal functionality of the C<left_Alt>-keys, one should redirect
these bitmaps to modification columns by I<stripping C<KBDKANA>> from these two bitmaps.

B<NOTE:> since C<KBDALT> stripping leaves a non-base bitmap, one can map to a column I<specific
to C<Alt>-bindings>.  In particular, even if a keyboard is non-Latin, one can still make C<Alt->keys
activate English-language menu entries, or trigger Latin-bases accelerator in an application.  (Compare
with what is discussed in L<"Possible enhancements and caveats">.)

B<Remark:> the assignment to the left C<Alt> is more or less “fixed” (compare with
L<Windows ignores C<lAlt> if its modifier bitmaps is not standard>).  Likewise, 
the assignment to the C<rAlt=AltGr> is explained in
L<"Windows combines modifier bitmaps for C<lCtrl>, C<Alt> and C<rAlt> on C<AltGr>">.

C<Caveat:> the latter assignment leads to possible complications (see B<Caveat> in L<"The bullet-proof method">).  So the
assignment above should only be “used when designing ‘what different modification columns should do’”. — However, in the actual
C<MODIFIERS> section of the keyboard layout one should better remove the bits of C<lCtrl> from the bits in C<rAlt> (preferably
leaving a comment about “the effective” bits! — this is what this module is doing).

This is continued in L<More (random) rambling on assignment of key combinations>.

=head2 Using C<Win>-key

The preceding section was written when I thought that the bitmap is limited
to 8 bits.  In fact, the bitmap turns out to be 16-bit, so one can enhance the
discussion above assigning C<X3> bit to C<Win> key, making all the combinations
with C<Win> fully distinct by their bitmap.
(See L<"Workarounds for WINDOWS GOTCHAS for application developers (problems in kernel)">.)

B<NOTE:> since the OS uses the bitmap as an index in the array C<MODIFIERS.ModNumber>, the
size of this array does not affect the speed of lookup.  The only effect of using
wider bitmaps is the size of the keyboard DLL: using 10 bits instead of 5 would
only increase the size by 1K.

Since it seems that L<the OS does not eat combinations of C<Win> and C<AltGr>|https://support.microsoft.com/en-us/windows/keyboard-shortcuts-in-windows-dcc61a57-8ff0-cffe-9796-cb9706c75eec>,
one may actually use these combinations to produce character input.  (Although
without thorough experiments it is not clear whether this is advisable…  Better
avoid C<Win> if feasible!  L<This undocumented C<Ctrl-Win-Alt-Shift-L> shortcut|https://www.pcworld.com/article/2070843/behold-the-dumbest-windows-shortcut-of-them-all.html>
may also get in the way!  One can still hope that there is a way to affect this by a judicious use of the remapping of C<LWIN> and
C<RWIN> keys as in L<"A full example of changing C<VK_>-codes depending on modifiers">.  Although interpretation of C<AltGr> “as
of pure C<Alt>” — see the referenced section and its preceding section — gets in the way of “naive approaches”: with them the
shortcuts including C<Win>+C<Alt> — “Game pad”, “Voice typing” and “App‘s actions” — must be entered “in exactly this order” — as
opposed to C<Alt>+C<Win>…)

If one assignes character input to combinations including C<Win+rAlt>, this
adds 8 more C<Shift>-pairs to 21 discussed above.  For example, one could add
2 missing math flavors of Greek, add 3 more for C<AltGr>-variants of companion
personalities, B<as well as free> the C<lCtrl-lAlt> from character
bindings — freeing it for application accelerators.

(However, it is not clear whether these bindings can be made “orthogonal enough”
to redeem the trouble!  For example, it is desired for C<AltGr> to “behave the
same” on the base personality and on its 3 companions, as well as generate
SanSerif/Bold/Italic variants of Latin/Greek by adding 3 modifiers.  Is it even
possible?!  See below…)

=head2 Almost orthogonality — with C<Win>-key

To answer the last question at least partially, consider the following way of binding:

      |	  ∅   M    C    MC     A   AM   AC    AMC
  —————————————————————————————————————————————————
  ∅   |	  L   Gr   —    Scr    Lᴬ  Grᴬ  BbB   Frk
  C   |	  —       Lˢˢ          〃    〃    〃     〃
   A  |	  —             Scrᴮ   Lᴮ  Grᴮ  Mono  Frkᴮ
  CA  |	  —       Lᴮˢˢ  Grᴮˢˢ  〃    〃    〃     〃
   W  |	  —   ¿?   —    ¿?     Lᴵ  Grᴵ  Lᴵˢˢ
  CW  |	  —   ¿?   —    ¿?     〃    〃    〃     〃
   WA |	  —   ¿?              Cyrᴬ Hbrᴬ Lᵗᵉⁿ  Grᵗᵉⁿ
  CWA |	 Cyr Hbr  Lᴮⁱ   Grᴮᴵ   〃    〃    〃     〃

with

=over 4

=item

Columns are combinations of “keys on the right of Spacebar: C<AltGr>, C<Menu>, C<rCtrl>” (shortened to one letter).

=item

Rows are cominations of keys “on the left of Spacebar: C<lCtrl> C<Win> C<lAlt>”.

=item

Dashes “C<—>” mean “this position should not be bound — to free it to application accelerators”;

=item

Ditto marks “〃” mean “same as above it” — the limitation due to C<KLLF_ALTGR>.

=item

C<L>/C<Gr>/C<Cyr>/C<Hbr> mean 4 personalities (these particular names are just for illustrative purposes), the superscripts mean:
C<ᴬ>: C<AltGr>-flavor, C<ᴮ>: Bold, C<ᴵ>: Italic, C<ˢˢ>: SansSerif, C<ᵗᵉⁿ>: “Tensor” = C<ᴮᴵˢˢ>.

(Although the name C<Gr> is arbitrary, I<on “Math-font” flavors> this B<indeed means “Greek”>.  So maybe it is better to call it
I<Oriental> 😃.)

=item

C<Bbb>/C<Mono>/C<Scr>/C<Frk> mean flavors of “fancy” math charactre: C<Blackboard-Bold> 𝔸𝕒𝔹𝕓, C<Monospaced> 𝙰𝚊𝙱𝚋, C<Script> 𝒜𝒶ℬ𝒷,
C<Frakture> 𝔄𝔞𝔅𝔟 (the last two may be boldified).

=item

“C<¿?>” marks “questionable positions”, where the system-accelerator-based-on-VK_-code can trigger???

=back

With this, one can have

=over 4

=item

Convenient access to C<L>/C<Gr> personalities (including C<AltGr>-versions) and “fancy math” (with C<lAlt> meaning “(un)Bold” — same
as below).  

=item

Non-convenient (but easy-to-memorize: C<left-CWA>) access to C<Cyr>/C<Hbr>-personalities (including C<AltGr>-versions) and
“acceptable” way to reach “Tensor Math-fonts”.

=item

Access to “Math-font” flavors is non-orthogonal, “but almost”: starting from C<AltGr>-C<L>-personality, the orthogonal accessors are
“the usual C<Gr>-switch”, C<lAlt> for “Bold”, C<Win> for “Italic”, and C<rCtrl> for “SansSerif”.  

=item

But not all flavors can be accessed by combining these orthogonal accessors. — One may need to replace C<AltGr> by C<lCtrl>.
(This works only with C<rCtrl>-active.)

=item

The final inconvenience is with “Bold-Italic Math fonts”: they are accessed by the preceding rule “as if it had ‘SansSerif’ added”.

=back

(As the 3rd/4th personalities go, one can duplicate them — at least non-C<AltGr> versions — to easier to access (but “non-orthogonal”)
free slots at the top-left of the table.  And if one can live with another modifier key replacing C<AltGr> as the accessor to its
second layer, one can even add a 5th personality into the unused space of the table above.)

B<Summary>: This way of access trades the convenience of access to the 3rd/4th personalities (of
L<C<izKeys>-type access|http://k.ilyaz.org/#advMods>) for simple access to C<AltGr>-layer of the 2nd personality, a
kind-of-orthogonality of “Math-fonts”, and for freeing C<lCtrl-lAlt> for accelerators.  (Just in case, recall again: here I<we do
not even try> to make “Math-fonts” easily-accessible!  This is just an illustration that even with Windows’ ideosyncrasies, I<a
logical> way of access can be “almost at reach”. — To make things convenient, there should be a way of “latching” the modifier
keys for a short time — for example, I<until B<all> the modifier keys are released>.)


=head2 Notes on the finer details of assigning modifier-bitmap bits

B<NOTE:> Without using the C<Win> key, only 21 useful C<Shift>-pairs remain (with the
assignment above and using C<KLLF_ALTGR> flag).
(This is what C<versions ≥0.63> of L<B<izKeys> keyboard layout|http://k.ilyaz.org/iz> is
using; out of 24 combinations with distinct bitmaps, C<lAlt>, C<lCtrl> and C<rCtrl> should be
excluded.)  B<Trivia:> While this may look as a complete overkill, recall that characters
outside BMP can be inserted on Windows I<only> via one keypress, possibly with many
modifiers. (This restriction relates only to the “classical” flavor of Windows keyboard layouts).
Unicode L<defines 18 additional Latin/Greek alphabets for mathematical
discourse|http://en.wikipedia.org/wiki/Mathematical_Alphanumeric_Symbols>.  If a keyboard
layout would want to support these letters, this would quickly exhaust the possible combinations
of modifiers.  (For 2-script layout, one could live with Latin/AltGr-Latin/Greek + 18 mathematical
alphabets.  But for layouts supporting more scripts, it lookes like using C<Win> key is not
avoidable.)  B<WARNING:> the price for using 21 C<Shift>-pairs (as opposed to ≤20) is that the
modifiers C<lCtrl-lAlt> are forced to be used for character input.  This is in no way the best
practice, since many applications using keyboard-accelerators get confusing results in such a
situation.

(B<HOWTO:> In principle, such applications could inspect the timing data on keypresses to 
distinguish C<KLLF_ALTGR>-auto-generated C<lCtrl> presses — when C<rAlt> is pressed the timecodes 
on C<lCtrl> and C<rAlt> are guarantied to be the same — from I<actual> keypresses of
C<lCtrl> and C<rAlt> made by user — and interpret these as accelerators.  With such inspection,
one could use C<lCtrl-lAlt> and C<rAlt> for character input, and use C<lCtrl-rAlt->presses
to control the application.)

B<NOTE:> Applications may call ToUnicode() with I<impossible combinations> of modifiers:
for example, they may "put" C<Ctrl> down, but do not specify whether it is C<rCtrl> or
C<lCtrl>.  Likewise for C<Alt>.

To support that, one would need to define a mask for standalone C<VK_CONTROL> and C<VK_MENU>
(i.e., C<Ctrl> and C<Alt>).  Since these modifiers are present when the real “left-right-handed”
keys are down, the masks should be “contained” in the masks of handed keys.  B<Example:> one
can make the pseudo-key C<Ctrl> to generate bit C<CTRL>, and the pseudo-key C<Alt> to generate
the bit C<ALT>.  Then for any combination of modifiers with unhanded C<Ctrl> and/or C<Alt>,
either the corresponding combination of bits is supported by the layout (and then the
application will access the corresponding modification column — which is probably not
the “expected” column corresponding to some handed flavor), or the combination is not
yet defined.  In the latter case, one may actually decide I<how> to resolve this: one can
map this combination of modifiers to an arbitatrary modification column!

In particular, one can map such combination of modifiers to a certain choice of handedness
of C<Ctrl> and C<Alt>.  (An example of such a problematic application was L<Firefox|"Firefox misinterprets keypresses">;
look for “I<impossible modifier>”.)

B<NOTE:> Some applications may do a "reverse lookup" using 
L<C<VkKeyScanW()>|https://msdn.microsoft.com/en-us/library/windows/desktop/ms646329%28v=vs.85%29.aspx> 
(this is B<the only> API which exposes the modifier masks).  Most of these calls would not
know anything about "higher bits", only S/C/A would be covered.  In particular,
it makes sense to add "fake" entries mapping combinations of bits 0x01/0x02/0x04 to the
"corresponding" modification columns.

For example, C<rAlt> above would produce modififier mask C<CTRL|ALT|LOYA|X1>; 
this mask would access a certain column in the table of bindings; make the 
mask C<CTRL|ALT> access the same column.  Then an application making a lookup
for a certain character via VkKeyScanW() would see C<CTRL|ALT>.  Since this is
the mask which is I<usually> produced by pressing C<rAlt>, the application
would think (correctly! — but only thanks to this fake entry) that this character 
may be produced with C<rAlt> modifier.

B<NOTE:> A keypress may be combined with “modifier keys” (like C<Shift>, C<right-Control> etc.) in up
to 125 ways.  B<REMARK:> Why not a power of 2?  The maximal number of “modification columns” supported by Windows is 126: a
larger number would make the size of C<VK_TO_WCHARS...> (which includes 2 extra bytes)
to overflow the maximal number
255 storable in the field C<VK_TO_WCHAR_TABLE.cbSize> of type C<BYTE> = C<unsigned char>.

Given that the column 15 is ignored, this reduces the number of strings associated to
a keypress (with different “modifiers”) to 125.

=head2 Issues with support of European(ISO)/Brazilian(ABNT2)/Japanese(JIS) physical keyboards

How can one keyboard layout (done in software!) retain functionality when used with different physical keyboards?

Three keyboards above have L<extra keys|https://www.win.tue.nl/~aeb/linux/kbd/scancodes-8.html> (see also
L<https://kbdlayout.info/kbdibm02/scancodes> — changing 
“Arrangement” if needed, as well as L<https://bsakatu.net/doc/virtual-key-of-windows/> — and the references there),
with their positions on the “main island” of the keyboard and scancodes
(as well as intended translations to C<VK_>codes) as in:

                          Left           Right       Top-Right
  ————————————————————————————————————————————————————————————————
  European(ISO)         56→OEM_102      ---             ---
  Brazilian(ABNT2)      56→OEM_102     73→ABNT_C1       ---
  Japanese(JIS)            ---         73→OEM_102    7D→OEM_8

(These keys are positioned right-of-C<left_Shift>, left-of-C<right_Shift>,  left-of-C<Backspace>.  Inspect
L<these images|https://kbdlayout.info/kbdibm02/scancodes>; one can change the shown physical keyboard by changing C<Arrangement>,
and change the labels on the keys — below-right of the image. — Also try changing the layout — in URL — to C<kbdbr>.)

Recall that a scancode is a signal from hardware (+drivers), while the C<VK_>code is calculated based on the scancode.
B<CONCLUSION:> these assignments are incompatible in one keyboard layout (due to conflicts of ABNT2/JIS with the translation of the
scancode 0x73).

On the other hand, European and Brazilian physical keyboards are compatible.  If one keeps these assignments C<56→OEM_102>,
C<73→ABNT_C1>, then the right extra-key on JIS (marked as C<\> C<_>, between C</?> and right C<Shift>) behaves as the right extra
key on the Brazilian keyboard.  (This is already good!)

However, “doing only this” makes the functionality assigned to C<OEM_102> unavailable on the Japanese physical keyboard.  However,
it has one more extra key (to the left of L<Backspace>). — So if one uses its intended translation to C<VK_OEM_8>, but B<duplicates>
the functionality of C<VK_OEM_102> to C<VK_OEM_8>, then this key I<replaces> “the ISO key”!  (Nowadays they are even marked the
same: C<\> C<|> — but historically it was C<¥> C<¦> on JIS.)

This boils down to:

=over 4

=item

Assign C<56→OEM_102>, C<73→ABNT_C1>, C<7D→OEM_8> and

=item

duplicate “the layout of” C<OEM_102> to C<OEM_8>.

=item

This results in the “extra right key” on ABNT2 and JIS keyboards behaving the same (C<ABNT_C1>), and

=item

the “extra left key” on ISO/ABNT2 keyboards behaving the same as “extra top-right key” on JIS keyboards.  (While this is
inconvenient, the position of C<OEM_102> varies anyway on many physical keyboards!)

=back

(The only other shortcoming of this scheme is that applications special-casing the C<VK_>code C<OEM_102> — are there such?! — would
not act on “the top-right extra-key” as intended. — But anyway, this happens even without using the scheme above!  C<TODO:> Can one
work around by making an assignment C<e056→OEM_102> and remapping scancode C<56> to C<e056> as in "Low level scancode mapping"
below?)

B<MORE ISSUES:> On ABNT2 physical keyboard there is one more extra key C<7E→ABNT_C2> (between C<Gray-+> and C<Gray-Enter> on the
“numeric island”).  In the Brazilean layout it generates “the opposite” of the C<DECIMAL> numeric-island key (C<.> vs. C<,>).  So
if C<DECIMAL> generates C<.>, it makes sense to duplicate the bindings of the key C<COMMA> to the key C<ABNT_C2>.

Likewise, on JIS physical keyboard the C<Space> key is very narrow — since its space is taken by C<CONVERT> and C<NOCONVERT> keys.
When one runs non-Japanese keyboard layouts on such a keyboard, “one can restore the justice” and duplicate the bindings of the
C<SPACE> key to the C<CONVERT> and C<NONCONVERT> keys.

B<NOTE:> it is a judgement call how to implement the mirroring done above.  One could also, for example, map the scan codes
0x79 and 0x7B (usually translated to C<CONVERT> and C<NONCONVERT> keys) to C<VK_SPACE>.  (However, this may make rebinding of
these keys in customizable applications harder.)

B<WARNING:> some versions of Firefox may lock when switching to certain keyboards (see
L<"Can an application on Windows accept keyboard events?  Part II: special key events">).
With v.55 such a lock would not occur when one
removes the binding for C<OEM_8> from this keyboard.  Caveat emptor!

B<NOTE:> for yet more exotic keys search for C<exotic virtual> in L<"SEE ALSO">.

=head1 WINDOWS GOTCHAS

First of all, keyboard layouts on Windows are controlled by DLLs; the only function
of these DLLs is to export a table of "actions" to perform.  This table is passed
to the kernel, and that's it - whatever is not supported by the format of this table
cannot be implemented by native layouts.  (The DLL performs no "actions" when
actual keyboard events arrive.)

Essentially, the logic is like that: there are primary "keypresses", and
chained "keypresses" ("prefix keys" [= deadkeys] and keys pressed after them).  
Primary keypresses are distinguished by which physical key on keyboard is 
pressed, and which of "modifier keys" are also pressed at this moment (as well
as the state of "latched keys" - usually C<CapsLock> only, but may be also C<Kana>).  This combination
determines which Unicode character is generated by the keypress, and whether
this character starts a "chained sequence".

On the other hand, the behaviour of chained keys is governed I<ONLY> by Unicode
characters they generate: if there are several physical keypresses generating
the same Unicode characters, these keypresses are completely interchangeable
inside a chained sequence.  (The only restriction is that the first keypress
should be marked as "prefix key"; for example, there may be two keys producing
B<-> so that one is producing a "real dash sign", and another is producing a
"prefix" B<->.)

The table allows: to map C<ScanCode>s to C<VK_key>s; to associate a C<VK_key> to several
(numbered) choices of characters to output, and mark some of these choices as prefixes
(deadkeys).  (These "base" choices may contain up to 4 16-bit characters (with 32-bit
characters mapped to 2 16-bit surrogates); but only those with 1 16-bit character may
be marked as deadkeys.)  For each prefix character (not a prefix key!) one can
associate a table mapping input 16-bit "base characters" to output 16-bit characters,
and mark some of the output choices as prefix characters.

The numbered choices above are determined by the state of "modifier keys" (such as
C<Shift>, C<Alt>, C<Control>), but not directly.  First of all, C<VK_keys> may be
associated to a certain combination of 6 "modifier bits" (called "logical" C<Shift>,
C<Alt>, C<Control>, C<Kana>, C<User1> and C<User2>, but the logical bits are not 
required to coincide with names of modifier keys).  (Example: one can bind C<Right Control>
to activate C<Shift> and C<Kana> bits.)  The 64 possible combinations of modifier bits
are mapped to the numbered choices above.

Additionally, one can define two "separate 
numbered choices" in presence of CapsLock (but the only allowed modifier bit is C<Shift>).
The another way to determine what C<CapsLock> is doing: one can mark that it 
flips the "logical C<Shift>" bit (separately on no-modifiers state, C<Control-Alt>-only state,
and C<Kana>-only state [?!] - here "only" allow for the C<Shift> bit to be C<ON>).

C<AltGr> key is considered equivalent to C<Control-Alt> combination (of those
are present, or always???), and one cannot bind C<Alt> and C<Alt-Shift> combinations.  
Additionally, binding bare C<Control> modifier on alphabetical keys (and
C<SPACE>, C<[>, C<]>, C<\>) may confuse some applications.

B<NOTE:> there is some additional stuff allowed to be done (but only in presence
of Far_East_Support installed???).  FE-keyboards can define some sticky state (so
may define some other "latching" keys in addition to C<CapsLock>).  However,
I did not find a clear documentation yet (C<keyboard106> in the DDK toolkit???).

There is a tool to create/compile the required DLL: F<kbdutool.exe> of I<MicroSoft 
Keyboard Layout Creator> (with a graphic frontend F<MSKLC.exe>).  The tool does 
not support customization of modifier bits, and has numerous bugs concerning binding keys which
usually do not generate characters.  The graphic frontend does not support
chained prefix keys, adds another batch of bugs, and has arbitrarily limitations:
refuses to work if the compiled version of keyboard is already installed;
refuses to work if C<SPACE> is redefined in useful ways.

B<WORKFLOW:> uninstall the keyboard, comment the definition of C<SPACE>,
load in F<MSKLC> and create an install package.  Then uncomment the
definition of C<SPACE>, and compile 4 architecture versions using F<kbdutool>,
moving the DLLs into suitable directories of the install package.  Install
the keyboard.

For development cycle, one does not need to rebuild the install package
while recompiling.

The following sections classify GOTCHAS into 3 categories:

L<"WINDOWS GOTCHAS for keyboard users">

L<"WINDOWS GOTCHAS for keyboard developers using MSKLC">

L<"WINDOWS GOTCHAS for keyboard developers (problems in kernel)">

=head1 WINDOWS GOTCHAS for keyboard users

=head2 MSKLC keyboards not working on Windows 8 without reboot

The layout is shown as active, but "preview" is grayed out,
and is not shown on the Win-Space list.    See also:

  http://www.errordetails.com/125726/activate-custom-keyboard-layout-created-with-msklc-windows

The workaround is to reboot.  Compare with

  http://blogs.msdn.com/b/michkap/archive/2012/03/12/10281199.aspx

=head2 Default keyboard of an application

Apparently, there is no way to choose a default keyboard for a certain
language.  The configuration UI allows moving keyboards up and down in
the list, but, apparently, this order is not related to which keyboard
is selected when an application starts.  (This may be fixed on Windows 8?)

=head2 Hex input of unicode is not enabled

One needs to explicitly tinker with the registry (see F<examples/enable-hex-unicode-entry.reg>)
and then I<reboot> to enable this.

=head2 Standard fonts have some chars exchanged

At least in Consolas and Lucida Sans Unicode φ and ϕ are exchanged.
Compare with Courier and Times.  (This may be due to the L<difference between
Unicode's pre-v3.0 choice of representative glyphs|http://en.wikipedia.org/wiki/Phi#Computing>, 
or the L<difference
between French/English Apla=Didot/Porson's approaches|http://www.greekfontsociety.gr/pages/en_typefaces19th.html>.)

=head2 The console font configuration

According to L<MicroSoft|http://support.microsoft.com/default.aspx?scid=kb;EN-US;Q247815>, it is controlled by Registry hive

  HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Console\TrueTypeFont

The key C<0> usually gives C<Lucida Console>, and the key C<00>
gives C<Consolas>.  Adding random numbers does not work; however,
if one adds one more zero (at least when adding to a sequence of zeros),
one can add more fonts.
You need to export this hive (e.g., use

  reg export "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Console\TrueTypeFont" console-ttf.reg

), save a copy (so you can always restore if the love goes sour)
then edit the resulting file.

So if the maximal key with 0s is C<00>, add one extra row with an extra 0
at end, and the family name of your font.  The "family name" is what the Font
list in C<Control Panel> shows for I<font families> (a "stacked" icon is shown);
for individual fonts the weight (Regular, Book, Bold etc) is appended.  So I add a line

  "000"="DejaVu Sans Mono"

the result is (omitting Far Eastern fonts)

  Windows Registry Editor Version 5.00

  [HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Console\TrueTypeFont]
  "949"="..."
  "0"="Lucida Console"
  "950"="..."
  "932"="..."
  "936"="..."
  "00"="Consolas"
  "000"="DejaVu Sans Mono"

The full file is in F<examples/console-fonts00-added.reg>.  After importing this
file via F<reg> (or give it as parameter to F<regedit>; both require administrative priviledges)
the font is immediately available in menu.  (However, it does not work in "existing"
console windows, only in newly created windows.)

B<(Do not use the example file directly.  First inspect the hive exported on your system,
and find the number of 0s to use.  Then add a new line with correct number of
zeros - as a value, one can use the string above.  This will I<preserve> the defaults
of your setup.>  Keep in mind that
selection-by-fontfamily is buggy: if you have more than one version of the font
in different weight, it is a Russian Rullette which one of them will be taken
(at least for DejaVu, which uses C<Book> as the default weight).  First install
the "normal" flavor of the font, then do as above (so the system has no way of picking
the wrong flavor!), and only after this install the remaining
flavors.

B<NOTE:> keep in mind that I distribute a good-for-console L<“merge” of two
fonts|http://ilyaz.org/software/fonts/>: C<DejaVu + Unifont Smooth>; C<DejaVu> brings
in nicely shaped nicely-scalable 
glyphs, and C<Unifont Smooth> brings a scalable font with complete coverage of BMP (as of 2015, of Unicode C<v7.0>).
(We omit Han/Hangul since it does not fit in a narrow box of a console font.
(As of 2015, it does not include U+30fb since apparently, this breaks display of 
"undefined" character in PUA in Windows' console.)

B<CAVEAT:> the string to put into C<Console\TrueTypeFont> is the I<Family Name> of the font.
The family name is what is shown in the C<Fonts> list of the C<Control Panel> — but only
for families with more than one font; otherwise the “metric name” of the font is appended.

On Windows, it is tricky to find the family name using the default Windows' tools, without
inspecting the font in a font editor.  One workaround is to select the font in C<Character Map>
application, then inspect C<HKEY_CURRENT_USER\Software\Microsoft\CharMap\Font> via:

  reg export HKCU\Software\Microsoft\CharMap character-map-font.reg

Note: the mentioned above MicroSoft KB article lists the wrong way to find the family name.
What is visible in the C<Properties> dialogue of the font, and in C<CurrentVersion\Fonts> is the
I<Full Font Name>.  Fortunately, quite often the full name and the family name coincide —
this is what happened with C<DejaVu>.  To find the "Full name" of the font, one can look into the hive

  HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts
  reg export "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts" fonts.reg

For example, after installing C<DejaVuSansMono.ttf>, I see
C<DejaVu Sans Mono (TrueType)> as a key in this hive.  

B<One more remark:> for desktop icons coming from the “Public” user (“shared”
icons) which start a console application, the default font is not directly editable.
To reset it, one must:

=over

=item *

copy the F<.lnk> icon file to “your” desktop directory;

=item *

start the application using the “new” icon;

=item *

change the font via “Properties” of the window's menu;

=item *

as administrator, copy the F<.lnk> file back to the F<Public/Desktop>
directory (usually in something like F<C:/Users>).  Manually refresh
the desktop.  Verify that the “old” icon works as expected.
(Now you can remove the “new” icon created on the first step.)

=back

=head2 There is no way to show Unicode contents on Windows

Until Firefox C<v13>, one could use FireFox to show arbitrary
Unicode text (limited only by which fonts are installed on your
system).  If you upgraded to a newer version, there is no (AFAIK)
Windows program (for general public consumption) which would visualize
Unicode text.  The applications are limited either (in the worst case) by
the characters supported by the currently selected font, or (in the best
case) they can show additionally characters, but only those considered by the
system as "important enough" (coming from a few of default fonts?).

There is a workaround for this major problem in FireFox (present at least
up to C<v20>).  The problem is caused
by L<this “improvement”|https://bugzilla.mozilla.org/show_bug.cgi?id=705594>
which blatantly saves a few seconds of load time for a tiny minority of
users, the price being an unability to show Unicode I<for everybody>
(compare with comments L<33|https://bugzilla.mozilla.org/show_bug.cgi?id=705594#c33> 
and L<75|https://bugzilla.mozilla.org/show_bug.cgi?id=705594#c75> on the bug report above).

It is not documented, but this action is controlled by C<about:config>
setting C<gfx.font_rendering.fallback.always_use_cmaps>.  To enable Unicode,
make this setting into C<true> (if you have it in the list as C<false>, double-clicking it would
do this — do search to determine this; otherwise you need to create a new
C<Binary> entry).

There is an alternative/additional way to enable extra fonts; it makes
sense if you know a few character-rich fonts present on your system.  The (undocumented)
settings C<font.name-list.*.x-unicode> (apparently) control fallback fonts for situations
when a suitable font cannot be found via more specific settings.  For example, when
you installed (free) L<Deja vu|http://dejavu-fonts.org/>, 
L<junicode|http://junicode.sourceforge.net/>, L<Symbola|http://users.teilar.gr/~g1951d/> fonts on your system, you may set (these
variables are not present by default; you need to create new C<String> variables):

  font.name-list.sans-serif.x-unicode	DejaVu Sans,Symbola,DejaVu Serif,DejaVu Sans Mono,Junicode,Unifont Smooth
  font.name-list.serif.x-unicode	DejaVu Serif,Symbola,Junicode,DejaVu Sans,Symbola,DejaVu Sans Mono,Unifont Smooth
  font.name-list.cursive.x-unicode	Junicode,Symbola,DejaVu Sans,DejaVu Serif,DejaVu Sans Mono,Unifont Smooth
  font.name-list.monospace.x-unicode	DejaVu Sans Mono,DejaVu Sans,Symbola,DejaVu Serif,Junicode,Unifont Smooth

And maybe also L<Fantasy|http://shallowsky.com/blog/tech/web/firefox-cursive-fantasy.html>
  
  font.name-list.fantasy.x-unicode	Symbola,DejaVu Serif,Junicode,DejaVu Sans Mono,DejaVu Sans,Unifont Smooth

(Above, we use the L<C<Unifont Smooth>||http://ilyaz.org/software/fonts/> 
as the font of last resort.  Although the glyphs are very coarse, in this role 
it is very useful since it contains all the Unicode C<v9.0> characters in BMP (as well as many out of BMP).  

B<Note:> L<the standard distribution|http://unifoundry.com/unifont.html> of C<Unifont>
contains “fake” glyphs for characters not supported by the font.  Such a design error is unexcusable for a TrueType font; this gets 
in the way when an application tries to find the best way to show a character.  Using 
(non-C<Mono> variant of) my “C<Smooth>” re-build not only fixes this (and some others) problems, 
but also makes the font nicely scalable — the original works well only in the size 16px.

B<Note:> on Windows, install the hinted version of Symbola (from the ZIP file); unhinted versions does not work well in GDI
applications (apparently, GDI does not auto-hints).

If you set both: the C<font.*> variables with rich enough fonts, 
B<and> C<gfx.font_rendering.fallback.always_use_cmaps>,
then you may have the best of both worlds: the situation when a character cannot
be shown via C<font.*> settings will be extremely rare, so the possiblity of delay
due to C<gfx.font_rendering.fallback.always_use_cmaps> is irrelevant.

=head2 Firefox misinterprets keypresses

Most of these are fixed (at least as of v.55) except ones marked with [B<*>] below:

=over 4

=item *

[B<*>] Firefox locks completely when one tries to switch to certain keyboards.  See
details near the end of L<"Can an application on Windows accept keyboard events?  Part II: special key events">.

=item *

Multiple prefix keys are not supported.

=item *

C<AltGr-0> and C<Shift-AltGr-0> are recognized as a character-generating
keypress (good!), but the character they produce bears little relationship
to what keyboard produces.  (In our examples, the character may be available
only via multiple prefix keys!)

=item *

After a prefix key, C<Control-(Shift-)letter> is not recognized as a
character-generating key.

=item *

[B<*>] C<Kana-Enter> is not recognized as a character-generating key.

=item *

[B<*>] C<Alt-+-HEXDIGITS> is not recognized as a character-generating key sequence (recall
that C<Alt> should be pressed all the time, and other keys C<+ HEXDIGITS> should be
pressed+released sequentially).  (Nowadays digits work, but hex letter do not.)

=item *

When keyboard has an “extra” modifier key in addition to C<Shift/Alt/Ctrl> (an
analogue of C<Kana> key), combining it with C<Ctrl> or with C<Alt> is interpreted
by Firefox as if only C<Ctrl> or C<Alt> were pressed.

=item *

When keyboard generates different characters on C<AltGr> than on C<Control-Alt>
(possible with assigning extra modifier bits to C<AltGr>), FireFox interprets any
C<AltGr-Key> as if it were C<Control-Alt-Key>.

C<Exception:> when C<AltGr-Fkey> produces a character, this character is understood
correctly by FF.  Same for C<AltGr-arrowKey> (but again, while this works on numeric
keypad, it is still buggy if C<NumLock> is on, or if the key is C<Numpad-Enter>.)

=item *

[B<*>] The keyboard may have C<rCtrl> which produces the same characters as C<lCtrl>, but
which behaves differently when combined with other keys.  FireFox ignores these
differences.

This is combinable with other remarks above: e.g., C<lCtrl-Kana> is interpreted
by FireFox as C<lCtrl>; same with C<lAlt>.

=item *

In addition to this, Firefox replaces C<rCtrl> and C<lCtrl> modifiers by
an I<impossible modifier>: Firefox pretends that I<only> C<unhandedCtrl> is down.  (Here
C<unhandedCtrl> is a fake key C<VK_CONTROL> which Window pretends is down when either one
of C<rCtrl> or C<lCtrl> is down.)  Since the situation when C<unhandedCtrl>
is down, but neither C<rCtrl> nor C<lCtrl> are down is not possible, this
may access parts of the keyboard layout not visible to other applications.
(Same for C<lAlt> and C<rAlt>.)

The net effect is that key combinations involving C<Ctrl> or C<Alt> keys
may behave wrong in Firefox.  For example, with version C<0.63> of
L<izKeys keyboard layout|http://k.ilyaz.org/iz>, C<Ctrl> and C<Alt>
are ignored on character-producing keys.

=item *

[B<*>] If C<lCtrl-lAlt-comma> produces C< — > (this is C<U+200A U+2014 U+200A>), and
C<AltGr-comma> produces the “cedilla deadkey”, then pressing C<AltGr-comma c>
acts as both: first C<U+200A U+2014 U+200A> are inserted, then C<ç>. 

=item *

A subtle variation of the previous failure mode: If C<lCtrl-lAlt-`> produces
deadkey X, and C<AltGr-`> produces the deadkey Y, then combining C<AltGr-`>
with C<a> gives the expected Y*a combination.  However, if combining with
something more complicated (C<Control-Alt-a> or C<Kana-f>), with what
deadkey Y is not combinable, B<THEN> the bugs strike:

=over 4

=item 1

in the first case the deadkey behaves as X: it produces a pair of characters
C<Xα>; here C<Control-Alt-a> produces C<α>.  (Keep in mind that inserting two
characters is the expected behaviour outside of Firefox, but Firefox usually
“eats” an undefined deadkey combination; and note that it is X, not the
expected Y!).

=item 2

[B<*>] in the second case it produces only the character C<ф> generated by C<Kana-f>.  Here
the behaviour is neither as outside Firefox (where it would produce C<Yф>) nor as
usual in Firefox (where it would eat the undefined sequence).

=back

=back

Of these problems, C<Chrome> has only C<Control-(Shift-)letter> one, but a very cursory inspection shows
other problems: C<Kana-arrows> are not recognized as character-generating keys.  (And IE9 just
crashes in most of these situations…)

=head2 C<AltGr>-keypresses triggering some actions

For example, newer versions of windows have graphics driver reacting on C<Ctrl-Alt-Arrow>s by
rotating the screen.  Usually, when you know which application is stealing your keypresses, one
can find a way to disable or reconfigure this action.

For screen rotation: Right-Click on desktop, “Graphics Options”, “Hot Keys”, disable.  The way to
reconfigure this is to use “Graphics Properties” instead of “Graphics Options” (but this may depend
on your graphics subsystem).

=head2 C<AltGr>-keypresses going nowhere

Some C<AltGr>-keypresses do not result in the corresponding letter on
keyboard being inserted.  It looks like they are stolen by some system-wide
hotkeys.  See:

  http://www.kbdedit.com/manual/ex13_replacing_altgr_with_kana.html

If these keypresses would perform some action, one might be able to deduce
how to disable the hotkeys.  So the real problem comes when the keypress
is silently dropped.

I found out one scenario how this might happen, and how to fix this particular
situation.  (Unfortunately, it did not fix what I see, when C<AltGr-s> [but not
C<AltGr-S>] is stolen.)  Installing a shortcut, one can associate a hotkey to
the shortcut.  Unfortunately, the UI allows (and encourages!) hotkeys of the
form <Control-Alt-letter> (which are equivalent to C<AltGr-letter>) - instead
of safe combinations like C<Control-Alt-F4> or
C<Alt-Shift-letter> (which — by convention — are ignored by keyboard drivers, and do not generate
characters).  If/when an application linked to by this shortcut is
gone, the hotkey remains, but now it does nothing (no warning or dialogue comes).

If the shortcut is installed in one of "standard places", one can find it.
Save this to F<K:\findhotkey.vbs> (replace F<K:> by the suitable drive letter
here and below)

  on error resume next
  set WshShell = WScript.CreateObject("WScript.Shell")
  Dim A
  Dim Ag
  Set Ag=Wscript.Arguments
  If Ag.Count > 0 then
    For x = 0 to Ag.Count -1
      A = A & Ag(x)
    Next
  End If
  Set FSO = CreateObject("Scripting.FileSystemObject")
  f=FSO.GetFile(A)
  set lnk = WshShell.CreateShortcut(A)
  If lnk.hotkey <> "" then
    msgbox A & vbcrlf & lnk.hotkey
  End If

Save this to F<K:\findhotkey.cmd>

  set findhotkey=k:\findhotkey
    for /r %%A in (*.lnk) do %findhotkey%.vbs "%%A"
    for /r %%A in (*.pif) do %findhotkey%.vbs "%%A"
    for /r %%A in (*.url) do %findhotkey%.vbs "%%A"
  cd /d %UserProfile%\desktop
    for /r %%A in (*.lnk) do %findhotkey%.vbs "%%A"
    for /r %%A in (*.pif) do %findhotkey%.vbs "%%A"
    for /r %%A in (*.url) do %findhotkey%.vbs "%%A"
  cd /d %AllUsersProfile%\desktop
    for /r %%A in (*.lnk) do %findhotkey%.vbs "%%A"
    for /r %%A in (*.pif) do %findhotkey%.vbs "%%A"
    for /r %%A in (*.url) do %findhotkey%.vbs "%%A"
  cd /d %UserProfile%\Start Menu
    for /r %%A in (*.lnk) do %findhotkey%.vbs "%%A"
    for /r %%A in (*.pif) do %findhotkey%.vbs "%%A"
    for /r %%A in (*.url) do %findhotkey%.vbs "%%A"
  cd /d %AllUsersProfile%\Start Menu
    for /r %%A in (*.lnk) do %findhotkey%.vbs "%%A"
    for /r %%A in (*.pif) do %findhotkey%.vbs "%%A"
    for /r %%A in (*.url) do %findhotkey%.vbs "%%A"
  cd /d %APPDATA%
    for /r %%A in (*.lnk) do %findhotkey%.vbs "%%A"
    for /r %%A in (*.pif) do %findhotkey%.vbs "%%A"
    for /r %%A in (*.url) do %findhotkey%.vbs "%%A"
  cd /d %HOMEDRIVE%%HOMEPATH%
    for /r %%A in (*.lnk) do %findhotkey%.vbs "%%A"
    for /r %%A in (*.pif) do %findhotkey%.vbs "%%A"
    for /r %%A in (*.url) do %findhotkey%.vbs "%%A"

(In most situations, only the section after the last C<cd /d> is important;
in my configuration all the "interesting" stuff is in C<%APPDATA%>.  Running
this should find all shortcuts which define hot keys.

Run the cmd file.  Repeat in the "All users"/"Public" directory.  It should
show a dialogue for every shortcut with a hotkey it finds.  (But, as I said,
it did not fix I<my> problem: C<AltGr-s> works in F<MSKLC> test window,
and nowhere else I tried...)

=head2 C<Control-Shift>-keypresses starting bloatware applications

(Seen on IdeaPad.)  Some pre-installed programs may steal C<Control-Shift>-keypresses;
it may be hard to understand what is the name of the application even when
the stealing results in user-visible changes.

One way to deal with it is to start C<Task Manager> in C<Processes> (or
C<Details>) panel, and click on CPU column until one gets decreasing-order
of CPU percentage.  Then one can try to detect which process is becoming
active by watching top rows when the action happens (or when one manages to
get back to the desktop from the full-screen bloatware); one may need to
repeat triggering this action several times in a row.  After you know
the name of executable, you can google to find out how to disable it, and/or
whether it is safe to kill this process.

B<Example:> On IdeaPad, it was F<TouchZone.exe> (safe to kill).  It was stealing 
C<Control-Shift-R> and C<Control-Shift-T>. 

B<Example:> On MSI, a similar stealer was F<MGSysCtrl.exe> (some claim it is used to show on-screen
animation when special laptop keys are pressed; if you do not need them, it is safe
to kill).  It was stealing C<Control-Alt-s>.  (But to find I<this> one, I needed to
kill all suspicious apps one by one…)

=head1 WINDOWS GOTCHAS for keyboard developers using MSKLC

F<MSKLC> has a convenient interactive tool F<MSKLC.exe> and a command-line
program F<kbdutool.exe>.  However, the latter program has many shortcomings;
they are listed in the sections below.

The way to fix this is described in
L<"WORKAROUND: a summary of the productive “alternative” workflow with F<.klc>">.

=head2 Several similar F<MSKLC> created keyboards may confuse the system

Apparently, the system may get majorly confused when the C<description>
of the project gets changed without changing the DLL (=project) name.
   
(Tested only with Win7 and the name in the DESCRIPTIONS section
coinciding with the name on the KBD line - both in F<*.klc> file.)
   
The symptoms: I know how one can get 4 different lists of keyboards:

=over 4

=item 1

Click on the keyboard icon in the C<Language Bar> - usually shown
on the toolbar; positioned to the right of the language code EN/RU 
etc (keyboard icon is not shown if only one keyboard is associated
to the current language).

=item 2

Go to the C<Input Language> settings (e.g., right-click on the 
Language bar, Settings, General.

=item 3

on this C<General> page, press C<Add> button, go to the language
in question.

=item 4

Check the F<.klc> files for recently installed Input Languages.

=item 5

In MS Keyboard Layout Creator, go to C<File/Load Existing Keyboard>
list.

=back
        
It looks like the first 4 get in sync if one deletes all related keyboards,
then installs the necessary subset.  I do not know how to fix 5 - MSKLC
continues to show the old name for this project.

Another symptom: Current language indicator (like C<EN>) on the language
bar disappears.  (Reboot time?)

Is it related to C<***\Local Settings\MuiCache\***> hive???

Possible workaround: manually remove the entry in C<HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Keyboard Layouts>
(the last 4 digits match the codepage in the F<.klc> file).
   
=head2 Too long description (or funny characters in description?)

If the name in the C<DESCRIPTIONS> section is too long, the name shown in 
the list C<2> above may be empty.
    
(Checked only on Win7 and when the name in the DESCRIPTIONS section
coincides with the name on the C<KBD> line - both in F<*.klc> file.
Length=63 works fine, Length=64 triggers the bug.)
   
(Fixed by shortening the name [but see
L<"Several similar F<MSKLC> created keyboards may confuse the system">
above!], so maybe it was
not the length but some particular character (C<+>?) which was confusing
the system.  (I saw a report on F<MSKLC> bug when description had apostroph
character C<'>.)
   
=head2 F<MSKLC> ruins names of dead key when reading a F<.klc>

When reading a F<.klc> file, MS Keyboard Layout Creator may ruin the names
of dead keys.  Symptom: open the dialogue for a dead key mapping
(click the key, check that C<Dead key view> has checkmark, click on the
C<...> button near the C<Dead key?> checkbox); then the name (the first 
entry field) contains some junk.  (Looks like a long ASCII string 

   U+0030 U+0030 U+0061 U+0039

.)

B<Workaround:> if all one needs is to compile a F<.klc>, one can run
F<KBDUTOOL> directly.

B<Workaround:> correct ALL these names manually in MSKLC.  If the names are
the Unicode name for the dead character, just click the C<Default> button 
near the entry field.  Do this for ALL the dead keys in all the registers
(including C<SPACE>!).  If C<CapsLock> is not made "semantically meaningful",
there are 6 views of the keyboard (C<PLAIN, Ctrl, Ctrl+Shift, Shift,
AltGr, AltGr+Shift>) - check them all for grayed out keys (=deadkeys).
   
Check for success: C<File/"Save Source File As>, use a temporary name.  
Inspect near the end of the generated F<.klc> file.  If OK, you can
go to the Project/Build menu.  (Likewise, this way lets you find which
deadkey's names need to be fixed.)
   
!!! This is time-consuming !!!  Make sure that I<other> things are OK
before you do this (by C<Project/Validate>, C<Project/Test>).
   
BTW: It might be that this is cosmetic only.  I do not know any bad
effect - but I did not try to use any tool with visual feedback on
the currently active sub-layout of keyboard.

=head2 Double bug in F<KBDUTOOL> with dead characters above 0x0fff

This line in F<.klc> file is treated correctly by F<MSKLC>'s builtin keyboard tester:

  39 SPACE 0 0020 00a0@ 0020 2009@ 200a@ //  ,  ,  ,  ,   // SPACE, NO-BREAK SPACE, SPACE, THIN SPACE, HAIR SPACE

However, via F<kbdutool> it produces the following two bugs:

  static ALLOC_SECTION_LDATA MODIFIERS CharModifiers = {
    &aVkToBits[0],
    7,
    {
    //  Modification# //  Keys Pressed
    //  ============= // =============
        0,            // 
        1,            // Shift 
        2,            // Control 
        SHFT_INVALID, // Shift + Control 
        SHFT_INVALID, // Menu 
        SHFT_INVALID, // Shift + Menu 
        3,            // Control + Menu 
        4             // Shift + Control + Menu 
     }
  };
 .....................................
    {VK_SPACE     ,0      ,' '      ,WCH_DEAD ,' '      ,WCH_LGTR ,WCH_LGTR },
    {0xff         ,0      ,WCH_NONE ,0x00a0   ,WCH_NONE ,WCH_NONE ,WCH_NONE },
 .....................................
  static ALLOC_SECTION_LDATA LIGATURE2 aLigature[] = {
    {VK_SPACE     ,6      ,0x2009   ,0x2009   },
    {VK_SPACE     ,7      ,0x200a   ,0x200a   },

Essentially, C<2009@ 200a@> produce C<LIGATURES> (= multiple 16-bit chars)
instead of deadkeys.  Moreover, these ligatures are put on non-existing
"modifications" 6, 7 (the maximal modification defined is 4; so the code uses
the C<Shift + Control + Menu> flags instead of "modification number" in
the ligatures table.

=head2 F<MSKLC> keyboards handle C<Ctrl-Shift-letter>, C<Ctrl-@ (x00)> , C<Ctrl-^ (x1e)> and C<Ctrl-_ (x1f)> differently than US keyboard

The US keyboard produces (as the 
“string value”) the corresponding Control-letter when 
C<Ctrl-Shift-letter> is pressed.  (In console applications,  
C<\x00> is not visible.)  F<MSKLC> does not reproduces this
behaviour.  This may break an application if
it was not specifically tested with “complicated” keyboards.

The only way to fix this from the “naive” keyboard
layout DLL (i.e., the kind that F<MSKLC> generates) which I found is to
explicitly include C<Ctrl-Shift> as a handled combination, and return
C<Ctrl-letter> on such keypresses.  (This is enabled in the generated
keyboards generated by this module - not customizable in v0.12.)

=head2 "There was a problem loading the file" from F<MSKLC>

Make line endings in F<.klc> DOSish.

=head2 C<AltGr-keys> do not work

Make line endings in F<.klc> DOSish (when given as input to F<kbdutool> -
it gives no error messages, and deadkeys work [?!]).

=head2 Error 2011 (ooo-us, line 33): There are not enough columns in the layout list.

The maximal line end of F<kbdutool> is exceeded (a line or two ahead).  Try remoing
inline comments.  If helps, change he workflow to cut off long lines (250 bytes is OK).

=head2 C<Error 2012 (ooo-us-shorten.klc, line 115):>

    <ScanCode e065 - too many scancodes here to parse.>

from F<MSKLC>.  This means that the internal table of virtual keys
mapped to non-C<e0> (sic!) scancodes is overloaded.

Time to switch to direct generation of F<.c> file? (See
L<"WORKAROUND: a summary of the productive “alternative” workflow with F<.klc>">.)
Or you need to
triage the “added” virtual keys, and decide which are less important
so you can delete them from the F<.klc> file.

=head2 Only the first 8 with-modifiers columns are processed by F<kbdutool>

Time to switch to direct generation of F<.c> file?  (See
L<"WORKAROUND: a summary of the productive “alternative” workflow with F<.klc>">.)

=head2 Only the first digit of the which-modifier-column is output by F<kbdutool> in C<LIGATURES>

Time to switch to direct generation of F<.c> file?  (See
L<"WORKAROUND: a summary of the productive “alternative” workflow with F<.klc>">.)

=head2 F<kbdutool> produces C<KEYNAME_DEAD> section with meaningless entries for prefix keys C<0x08>, C<0x0A>, C<0x0D>

These entries do not stop keyboard from working.  They look like C<L"'\b'"	L"Name is here…">...

Time to switch to direct generation of F<.c> file?  (See
L<"WORKAROUND: a summary of the productive “alternative” workflow with F<.klc>">.)

=head2 It is not clear how to compile F<.C> files emitted by F<kbdutool.exe>

This distribution includes a script F<examples/compile_link_kbd.cmd> which can do this.  It is
inspired by

  http://stackoverflow.com/questions/3360746/how-can-i-compile-programmer-dvorak
  http://levicki.net/articles/tips/2006/09/29/HOWTO_Build_keyboard_layouts_for_Windows_x64.php

It allows us to build using the cycle

=over 4

=item *

Build skeleton F<.klc> file.

=item *

Convert to B<C> using F<kbdutool.c>.

=item *

Patch against bugs in F<kbdutool.c>.

=item *

Patch in features not supported by F<kbdutool.c>.

=item *

Compile and link DLLs.

=back

(This assumes that the installer was already built by F<MSKLC> using a
“simplified-to-nothing” F<.klc> file which does not trigger the F<MSKLC> bugs).

(See also L<http://accentuez.mon.nom.free.fr/Clavier-Galeron_fichiers/cr%E9ation_clavier.zip>.)

=head2 F<kbdutool> cannot ignore column=15 of the keybinding definition table

(Compare with L<"Windows ignores column=15 of the keybinding definition table">.)

F<kbdutool> requires that all the columns are associated to a modifier-bitmap.
But column=15 should not be associated to any.

The workaround is to associate it to the bitmap which should not be bound to any
column (like C<4=KBDALT>).  In the output C<.C> file, one would have 15 instead
of C<SHFT_INVALID> for the bitmap 4, but C<SHFT_INVALID> is defined to be 15 anyway…

=head2 F<kbdutool> ignores bits above 0x20 in the modification columns descriptor

Time to switch to direct generation of F<.C> files?  (See
L<"WORKAROUND: a summary of the productive “alternative” workflow with F<.klc>">.)

=head2 F<kbdutool> cannot assign more than one bitmask to a modification column

Time to switch to direct generation of F<.C> files?  (See
L<"WORKAROUND: a summary of the productive “alternative” workflow with F<.klc>">.)

(Quite often, one combination of modifiers should produce the same characters as
another one.  The format of keyboard layout tables allows them to share a
modification column.  The format of F<.klc> files does not allow sharing.)

=head2 F<kbdutool> cannot reasonably handle C<NUMPADn> keys and C<DECIMAL>

F<kbdutool> requires that every C<VK_>-code is assigned a scancode.  The keys above
are not assigned scancodes (on non-exotic keyboards), but are instead
translated from C<Insert>/C<End>/etc. as needed by the kernel.

(Unchecked) workaround: use fake scancodes (for example, C<0xe0e*> are not used
by known physical keyboards, so redefining the actions of these scancodes should not
cause conflicts.

=head2 F<kbdutool> forgets to emit C<aVkToWch3>/6/8

If the F<.klc> file has many modification columns, the emitted aVkToWcharTable 
contains only C<aVkToWch1>/2.

=head2 F<kbdutool> confuses LIGATURES on unusual keys

For example, C<VK_SUBTRACT> may be replaced by C<VK_F2> in the LIGATURES table.

Time to switch to direct generation of F<.C> files?  (See
L<"WORKAROUND: a summary of the productive “alternative” workflow with F<.klc>">.)

=head2 F<kbdutool> places C<KbdTables> at end of the generated F<.c> file

The offset of this structure should be no more than 0x10000.  Thus keyboards
with large tables of prefixed keys may fail to load.  This may be related to
the bug L<"If data in C<KEYNAME_DEAD> takes too much space, keyboard is mis-installed, and “Language Bar” goes crazy">.

Time to switch to direct generation of F<.C> files?  (See
L<"WORKAROUND: a summary of the productive “alternative” workflow with F<.klc>">.)

=head2 F<kbdutool> finicky with NumPad keys

B<Background:> on non-exotic keyboards C<NUMPAD>n and C<DECIMAL> are not assigned scancodes, but are translated from
C<Insert>/C<End>/etc. C<VK_>-codes as needed by the kernel.  On the other hand, F<kbdutool> I<requires B<a specific>> scancode
assigned to each line in the C<LAYOUT> section.  In particular, one needs to be inventive with assigning characters to these NumPad
C<VK_>-codes.

What happens is that F<kbdutool> handles “fake” scancodes (such as C<0xE0E3>) assigned to C<NUMPAD>n reasonably well (meaning: it is
I<the other bugs> described above which are going to be triggered 😦 — but one of these bugs is that F<kbdutool> does not update
C<E0>-map — which is good for “fake” codes!).  However, C<DECIMAL> B<must be assigned> to the scancode C<0x53>.  (This is
handled automatically for F<.klc> files produced by this module.)

=head2 F<kbdutool> may assign scancodes wrongly

While F<kbdutool> allows assigning a C<VK_>-code to a scancode (one can use an “ultra-short line” like

  e05d  KANA

to make “the Menu key” into C<VK_KANA>), such scancodes are not included into “the special table for C<e0>-bindings” of the
generated C file.

To add insult to injury, the entry for C<e05d> may actually I<be omitted> from this table (at least when one moves C<APPS> binding
to a different scancode).  

Time to switch to direct generation of F<.C> files?  (See
L<"WORKAROUND: a summary of the productive “alternative” workflow with F<.klc>">.)

=head2 Error "the required resource DATABASE is missing" from F<setup.exe>

The localized C<DESCRIPTION> in F<.klc> file contains a character outside of
the repertoir of the codepage in question.  Removing offending characters, or
removing the C<DESCRIPTION> altogether should fix this.  (But either way, the name of
layout in the C<Settings> of the Language Bar may become empty.)  Having a
different localized description has a side effect that the name of the layout
shown in the Language Bar popups is localized.

(The localized description is what put into the C<resource=1000> of the
DLL file; it is this resource which is mentioned in the registry.  (There
will be no such resource when the localized C<DESCRIPTION> is missing.)

(The failure of F<setup.exe> is not reproducible after a reboot!)

Apparently, this has nothing to do with the length, so the (older) conjectures
below are wrong (although the F<.RC> file generated by MSKLC has the [non-localized] name
truncated after 40 chars in the field C<FileDescription> — but not in other fields):

It looks like there is a buffer overflow in MSKLC, and sometimes the generated
F<setup.exe> in the install package would just exit with this error.  The
apparent reason is the length of the C<DESCRIPTION>-like fields.

Workaround: it looks like the C<DESCRIPTION> field is not used in F<setup.exe>.
So generate an “extra dummied” F<.klc> file I<too> (with shortened descriptions), 
make an install package from it, and mix the F<setup.exe> from the “extra 
dummied” variant with the rest of the install package from a 
“less dummied” F<.klc> file.

The alternative is to get rid of F<setup.exe> completely, and ask users
to run the appropriate F<.msi> file from the install package by hand
(choosing basing on 32-bit vs 64-bit architecture).

=head2 Error when linking: a missing F<oldnames.lib>

It seems that the supplied F<.lib> files of MSKLC are defective.  However, this is
OK as far as the linked F<.obj> files are self-sufficient (as they should be).

On the other hand, if there is a missing symbol, then the F<.lib> files are attempted
to be read — and the resulting errors are “emitted first”; this “hides” the error about
a missing symbol:

   \Microsoft-Keyboard_Layout_Creator\lib\amd64\MSVCRT.lib : warning LNK4003: invalid library format; library ignored
   LINK : fatal error LNK1104: cannot open file 'OLDNAMES.lib'

To get the name of the missing symbols, one should either substitute these
libraries by legal (but possibly empty) ones, (as via

  https://gist.github.com/mmozeiko/7f3162ec2988e81e56d5c4e22cde9977

or use the C</verbose> option on the linker to get more detailed output:

 https://stackoverflow.com/questions/5249431/linker-trouble-how-to-determine-where-a-defaultlib-is-coming-from/31146961#31146961

(Another conjectural reason: a conflict between an extern declaration and a static definition of a symbol.)

=head2 The generated table of C<KEYNAME>s is wrong for C<F>-keys

The numeric part is C<VK_>-codes, while it should be the scancodes.  Similarly, in the
“extended” section appear mysterious keys C<< <00> >>, C<Help> (in positions C<X54>, C<X56>)
which do not seem to be present anywhere.

=head1 WORKAROUND summary of the productive “alternative” workflow with F<.klc>

=head2 Summary of the productive workflow with F<.klc>:

(Some of the steps below may be omitted depending on how complicated
your F<.klc> layout is; for practical implementation, see
L<the example of F<.klc> creation|https://search.cpan.org/~ilyaz/UI-KeyboardLayout/examples/build-iz.pl>
and L<the example of F<.klc> to F<.dll> 
processing|https://search.cpan.org/~ilyaz/UI-KeyboardLayout/examples/build_here.cmd>):

=over 4

=item

Make an “extra dummied” F<.klc> (short descriptions, short dummy C<SHIFTSTATE>,
C<LAYOUT>, C<DEADKEY>, C<KEYNAME_DEAD> sections, no C<LIGATURE> section).  Run
it through GUI MSKLC (C<Alt-P Enter>, then C<Alt-P B Enter Enter>, C<Alt-F4>).
Store the generated F<setup.exe>, rename the directory.

Can be made by giving optional arguments C<'dummy', 'dummyname'> to fill_win_template();
see L<"SYNOPSIS">.

=item

Make a “less dummied” F<.klc> file (as above, but with the correct “description” on
the C<KBD> line).  (Can be made by giving optional argument C<'dummy'> to fill_win_template();
see L<"SYNOPSIS">.)  Do as above, and mix in the F<setup.exe> from the previous step.

This makes a correct “installation framework”. — But it has I<very wrong> F<.dll>
files!

There is no need to repeat these steps with newer versions of F<.klc> files — unless
the C<KBD> line changes.

=item

Convert to C with

  perl -wC31 %ex%/klc2c.pl FILENAME.klc >C_NAME.c

Here C<C_NAME> is the name from C<KBD> line of F<.klc> file.  (This would
overwrite the F<.c> file created on preceding step.  This would also create
one extra C file, and a header file — as well as a F<.rc> file and F<.def> 
file — but it would not overwrite these files if present.)

(This assumes that C<%ex% expands to the name of F<./examples> subdirectory
in the distribution of <UI::KeyboardLayout>).

=item

Compile the resulting B<C> files.   For example, one can use

  %ex%\compile_link_kbd.cmd --with-extra-c C_NAME_extra C_NAME

Here C<C_NAME> is as above.  This assumes that the directory named as C<C_NAME>
contains the distribution files (F<.exe> and F<.msi>) created on the first
two steps.

=back

However, one should remember that the script F<klc2c.pl> is still (as of 2024)
pretty new; its limitations are listed at the start of the file.
(However, I expect it to handle everything-not-extremely-tricky now.)

This workflow (except the second part) is used by the example script
L<F<examples/build_here.cmd>|https://search.cpan.org/~ilyaz/UI-KeyboardLayout/examples/build_here.cmd>.
It is a part of the pathway used for generation of L<I<izKeys> layouts|http://k.ilyaz.org>.  This script
assumes that the “fake” distributions (or the distributions of older versions)
are in subdirectories F<iz-la-4s> etc. of the current directory, and that the
F<.klc> files are in the parent directory (C<%src> above); moreover, it assumes
that C<%Keyboard_Layout_Creator%> is set so that

  %Keyboard_Layout_Creator%\bin\i386\kbdutool.exe

exists — although now it uses only the C compiler from this distribution).

=head1 Workarounds for WINDOWS GOTCHAS for application developers (problems in kernel)

The “old-style” keyboard layouts in Windows are just tables loaded into memory.  The
kernel consults these tables when processing keypresses.  One cannot create a
functionality except those hard-coded into the logic of processing these tables.

However, there is much more flexibility in these tables than what is “typically believed”.
In particular:

=over 4

=item

The interaction of modifier keys and C<CapsLock> is less restrictive than one may think!  Recall that the modifier keys
“act” via the associated bitmap, and that C<CAPSLOK-> and C<SGCAPS-> switches trigger only if this bitmap is 0 or C<SHIFT>.
Likewise, C<CAPSLOKALTGR>-switch trigger only if this bitmap has both C<ALT> and C<CTRL> bits are set.  This may seem to be a strong
restriction: what to do if only one of C<ALT> and C<CTRL> bits is set?!

However, the latter situation I<may be completely avoided>): see L<"A convenient assignment of C<KBD*> bitmaps to modifier keys">.

B<NOTE:> all keys are affected by C<KANALOK> logic (which mocks turning up C<KANA> bit if C<VK_KANA> key is “logically down” — it
may be processed as “radiobutton” if it has C<KBDKANA> bit assigned).  This allows Ц<VK_KANA> to
have effect on some keys (those with KANALOK), and no effect on tother keys (those without).  (Of course, this effect could be
achieved also by duplicating entries in the columns with C<KBDKANA>!)

=item

The prefix keys (“deadkeys”) cannot produce more than one C<UTF-16> codepoint.  However,
this does not mean that they cannot “affect” keys producing multi-codepoint strings.  (The
only limitation for these strings is that one cannot be a prefix of another.)

=item

A keypress may be combined with “modifier keys” (like C<Shift>, C<right-Control> etc.) in up
to 125 ways.  
See L<"Notes on the finer details of assigning modifier-bitmap bits">.

=item

A keypress (with particular modifier keys) may produce
L<a string with up to 125 characters|"Keyboard input on Windows, Part II: The semantic of ToUnicode()">.

See L<"More (random) rambling on assignment of key combinations"> for more details.

=item

The mapping from “a combination of modifier keys” to a column in the translation table goes
by C<OR>ing certain bitmaps assigned to the modifier keys.  The width of these bitmaps is 16,
so one can support a huge “orthogonal set” to distinguish all useful combinations of typical
modifiers (2 each of C<Shift>, C<Control>, C<Alt>, C<Windows>, as well as C<Kana>, C<Menu-key>
and maybe even C<CapsLock>).

(The actual limit is in the count 125 of possible usable columns — as well as some obscure bugs which
may be triggered in the installer if the C<.dll> is too large.)

=item

If one uses C<SGCAPS> flag for a partiular key — to have customizable bindings (this affects
the case when only C<Shift> and C<CapsLock> are active), one can still assign deadkeys to such
key (with certain modifiers).

The only limitation is that the each of the C<Shift-> and no-C<Shift-> position cannot produce
deadkeys B<both> “with” and “without” C<CapsLock>.  In presence of other modifiers there is no
restriction!

(Moreover, by (creatively) combining C<SGCAPS> with C<CAPLOK> even with this limitation one can
cover all the cases of up to two deadkeys on 4 possible combinations of C<Shift> and C<CapsLock>.
However, one may need to duplicate the corresponding C<DEADKEY> section with another prefix key.)

(In fact, “ultra-creatively” duplicating with the ”new” deadkey “coded” as C<WCH_DEAD=0xF001>
(so in the section C<DEADKEY F001>) one can also support one key with up to 3 deadkeys out
of 4 possible combinations of C<Shift> and C<CapsLock>.)

=back

=head1 WINDOWS GOTCHAS for application developers (problems in kernel)

=head2 Many applications need to know the state of hidden flag C<KLLF_ALTGR>

To decide what to do with a keypress, an application may need to know
whether C<KLLF_ALTGR> is enabled in the keyboard (in other words, if
C<left-Control> is faked when C<right-Alt> is pressed).  For example, when
the kernel processes accelerators, it would not trigger C<Ctrl-Alt-A>
if C<A> was pressed with C<right-Alt> in the presence of this flag — even
though C<left-Ctrl> I<IS> visible as being pressed (one needs to press
C<left-Alt + right-Control>).

An application with configurable bindings may need to emulate this action
of TranslateMessage().  One of the ways to do this may be to do (when
C<left-Control> and C<right-Alt> are down)

=over 4

=item *

Set a global flag disabling processing of C<WM_(SYS)COMMAND> in the application;

=item *

Call TranslateAccelerator() with an improbable virtual key (C<VK_OEM_AX> or
some such — or, better, the “unassigned C<VK_>-code C<0xe8>) and a suitable ad hoc translation table;

=item *

Check whether accelerator was recognized (if so, C<KLLF_ALTGR> is not enabled).

=back

Possible problems with this approach: the “improbable key” should better not
trigger some system accelerator (this is why one should not use “ordinary”
keys).  Additionally, some system accelerators react on Windows key as a
modifier; so acceleration table may specify this as a certain flag.  This
would imply that the algorithm above may not work when C<Windows> key is
down.  (Not tested.)

(Or maybe these C<Win-key> bindings are not accelerators, and are
processed in a different part of keyboard input events. — Then there is
little to worry about.)

=head1 WINDOWS GOTCHAS for keyboard developers (problems in kernel)

=head2 It is hard to understand what a keyboard really does

To inspect the output of the keyboard in the console mode (may be 8-bit,
depending on how Perl is compiled), one can run

  perl -MWin32::Console -wle 0 || cpan install Win32::Console
  perl -we "sub mode2s($){my $in = shift; my @o; $in & (1<<$_) and push @o, (qw(rAlt lAlt rCtrl lCtrl Shft NumL ScrL CapL Enh ? ??))[$_] for 0..10; qq(@o)} use Win32::Console; my $c = Win32::Console->new( STD_INPUT_HANDLE); my @k = qw(T down rep vkey vscan ch ctrl); for (1..20) {my @in = $c->Input; print qq($k[$_]=), ($in[$_] < 0 ? $in[$_] + 256 : $in[$_]), q(; ) for 0..$#in; print(@in ? mode2s $in[-1] : q(empty)); print qq(\n)}"

This installs Win32::Console module (if needed; included with ActiveState Perl)
then reports 20 following console events (press and keep C<Alt> key
to exit by generating a “harmless” chain of events).  B<Limitations:> the reported
input character is not processed (via ToUnicode(); hence chained keys and
multiple chars per key are reported only as low-level), and is reported as
a signed 8-bit integer (so the report for above-8bit characters is
completely meaningless).

  T=1; down=1; rep=1; vkey=65; vscan=30; ch=240; ctrl=9; rAlt lCtrl
  T=1; down=0; rep=1; vkey=65; vscan=30; ch=240; ctrl=9; rAlt lCtrl

This reports single (T=1) events for keypress/keyrelease (down=1/0) of
C<AltGr-a>.  One can see that C<AltGr> generates C<rAlt lCtrl> modifiers
(this is just a transcription of C<ctrl=9>,
that C<a> is on virtual key 65 (this is C<VK_A>) with virtual scancode
30, and that the generated character (it was C<æ>) is C<240>.

The character is approximated to the current codepage.  For example, this is
C<Kana-b> entering C<β = U+03b2> in codepage C<cp1252>:

  T=1; down=1; rep=1; vkey=66; vscan=48; ch=223; ctrl=0;
  T=1; down=0; rep=1; vkey=66; vscan=48; ch=223; ctrl=0;

Note that C<223 = 0xDF>, and C<U+00DF = ß>.  So I<beta> is substituted by
I<eszet>.

There is also a script F<examples/raw_keys_via_api.pl> in this distribution
which does a little
bit more than this.  One can also give this script the argument C<U> (or C<Un>,
where C<n> is the 0-based number among the listed keyboard layouts) to report
ToUnicode() results, or argument C<cooked> to report what is produced by reading raw
charactes (as opposed to events) from the console.

=head2 It is not documented how to make a with-prefix-key(s) combination produce 0-length string

Use C<0000@> (in F<.klc>), or DEADKEY 0 in a F<.c> file.  Explanation: what a prefix key
is doing is making the kernel remember a word (the state of the finite automaton), and not
producing any output character.  Having no prefix key corresponds to the state being 0.

Hence makeing prefix_key=0 is the same as switching the finite automaton to the initial
state, and not producing any character — and this exactly what is requested in the question.

=head2 If data in C<KEYNAME_DEAD> takes too much space, keyboard is mis-installed, and “Language Bar” goes crazy

See a more correct diagnosis in next subsection.

=head2 If DLL is too large, keyboard is mis-installed, and “Language Bar” goes crazy

Synopsis: Installation reports success, the keyboard appears in the list in the Language Bar's "Settings".
But the keyboard is not listed in the menu of the Language Bar itself.  (This is not fixed
by a reboot.)

Deinstalling (by F<MSKLC>'s installer) in such a case removes one (apparently, the last) of the listed keyboards for the language;
at least it is removed from the menu of the Language Bar itself.  However, the list in the “Settings”
does not change!  One can't restore the (wrongly) removed (unrelated!) layout by manipulating the latter list.
(I did not try to check what will happen if only one keyboard for the language is available — is it removed
for good?)  I<This> condition is fixed by a reboot: the “missing” “unrelated” layout jumps to existence.

I did not find a way to restore the deleted keyboard layout (without a reboot).  Experimenting with these is kinda painful:
with each failure,
I add one extra keyboard to the list in the “Settings”; - so the list is growing and growing!  [Better
add useless-to-you keyboards, since until the reboot you will never be able to install them again.]

This condition was first diagnozed in update from v0.61 to v0.63 of B<izKeys> layouts.  Between
these versions, there was
a very small increment of the size of DLLs: one modification column was added, and two deadkeys were added.  This triggered
the problem described above.  As experiments
had shown, 
removing a bunch of dead keys descriptions (to decrease the size of DLL) fixed this (I do not know a situation where these
descriptions play any role).  So it looks like
this defect was due to I<ONLY> increasing the size of the DLL…  Maybe it is due to the total
size of certain segments in the DLL.

See the L<DLL which does not install|http://k.ilyaz.org/windows/newer/not-installable-and-fix/iz-ru-la.zip> and
the L<smaller DLL which installs|http://k.ilyaz.org/windows/newer/not-installable-and-fix/was-not-installing-fixed.zip>.
For details and SRC see the L<README file|http://k.ilyaz.org/windows/newer/not-installable-and-fix/README>.  (Apparently,
for 64bit DLL, 264,704B is too large, but 249,856B is OK.  With other builds, I observed: 258,560B is OK, but 264,192B too big.)

(This may be related to the bug L<"F<kbdutool> places C<KbdTables> at end of the generated F<.c> file">.  However, now we
organize compilation so that the relevant code is in the beginning of the DLL, but this does not help with this bug.)

Workarounds: this module allows decreasing number of entries in the name table via C<WindowsEmitDeadkeyDescrREX> configuration
variable.

=head2 Windows ignores column=15 of the keybinding definition table

Note that 15 is C<SHFT_INVALID>; this column number is used to indicate that
this particular combination of modifiers does not produce keys.  In particular,
the this column number should not be used in the layout.

Workaround: put junk into this column, and use different columns for useful modifier
combinations.  The mapping from modifiers to columns should not be necessarily 1-to-1.
(But see L<"F<kbdutool> cannot ignore column=15 of the keybinding definition table">.)

=head2 Windows combines modifier bitmaps for C<lCtrl>, C<Alt> and C<rAlt> on C<AltGr>

(When — for compatibility with legacy applications — a keyboard layout is marked with the C<KLLF_ALTGR> flag — so C<AltGr> is
special in the keyboard, and mocks pressing of 2 keys:
C<lCtrl> then C<rAlt> — with the same timestamp) the modifier bitmap bound to this
key is actually bit-OR of bitmaps above.  Essentially, this prohibits assigning
interesting flag combinations to C<lCtrl>.

The (very limited — and nowadays dangerous — see B<Caveat> in L<"The bullet-proof method">) workaround is to ensure that the
bits in the modification bitmap one puts on C<AltGr> contain
all the bits assigned to the above VK codes.  (With applications using “ad hoc algorithms”, this would not change anything;
and since this makes the assignments less confusing for human inspection, B<historically> we recommended to use it.
Unfortunately, using such “joined bitmap” in the C<MODIFIERS> section leads to problems — so while one can use this hack when
designing the mapping of chords-of-modifier-keys to modification columns, I<in the actual C<MODIFIERS> section> these “forced” bits
should not be included on the C<VK_RMENU> line. — And this is what this module does now.)

A workaround for the user’s experience is possible (although only partially tested): see
L<Another redefinition to avoid problems with the C<KLLF_ALTGR> flag>.

(Compare with L<"A convenient assignment of KBD* bitmaps to modifier keys">. — But see B<Caveat> in this section!)

=head2 Windows ignores C<lAlt> if its modifier bitmaps is not standard

Adding C<KBDROYA> to C<lAlt> disables console sending non-modified char on keydown.
Together with the previous problem, this looks like essentially prohibiting
putting interesting bitmaps on the left modifier keys.

Workaround: one can add C<KBDKANA> on C<lAlt>.  It looks like the combination
C<KBDALT|KBDKANA> is compatible with Windows' handling of C<Alt> (both in console,
and for accessing/highlighting the menu entries).  (However, since only C<KBDALT>
is going to be stripped for handling of C<lAlt-key>, the modification column for
C<KBDKANA> should duplicate the modification column for no-C<KBD>-flags.  Same with
C<KBDSHIFT> added.)

(Compare with L<"A convenient assignment of KBD* bitmaps to modifier keys">.)

=head2 When C<AltGr> produces C<ROYA>, problems in Notepad

Going to the Save As dialogue in Notepad loses "speciality of AltGr" (it highlights Menu);
one need to switch layouts via LAlt+LShift to restore.

I do not know any workaround (except combining C<AltGr> with at most C<KANA>).

=head2 Console applications cannot detect when a keypress may be interpreted as a “command”

The typical logic of an (advanced) application is that it interprets certain keypresses
(combinations of keys with modifiers) as “commands”.  To do this in presence of user-switchable
keyboards, when it is not known in compile time which key sequences generate characters,
the application must be able to find at runtime which keypresses are characters-generating,
and which are not.  The latter keypresses are candidates to be checked whether they should trigger commands
of the application.

For final keypresses of a character-generating key-sequence, an application gets a notification
from the ReadConsoleInput() API call that this keypress generates a character.  However, for the 
keypresses of the sequence which are non the last one (“dead” keys), there is no such notification.

Therefore, there is no way to avoid dead keys triggering actions in an application.  What is the
difference with non-console applications?  First of all, they get such a notification (with the
standard TranslateMessage()/DispatchMessage() sequence of API calls, on WM_KEYDOWN, one can
PeekMessage() for WM_SYSDEADCHAR/WM_DEADCHAR and/or WM_SYSCHAR/WM_CHAR).  Second, the windowed
application may call ToUnicode(Ex)() to calculate this information itself.

Well, why a console application cannot use the second method?  First, the active keyboard layout
of a console application is the default one.  When user switches the keyboard layout of the console,
the application gets no notification of this, and its keyboard layout does not change.  This makes  
ToUnicode() useless.  Moreover, due to
security architecture, the console application cannot query the ID of the thread serving the message
loop of the console, so cannot query GetKeyboardLayout() of this thread.  Hence ToUnicodeEx() is
useless too.

(There may be a lousy workaround: run ToUnicodeEx() on B<all> the installed keyboard layouts, and
check which of them are excluded by comparing with results of ReadConsoleInput().  Interpret
contradictions as user changing the keyboard layout.  Of course, on several keypresses following
a change of keyboard layout one may get unexpected results.  And if two similar
keyboards are installed, one may also never get definite answer on which of them is currently active.)

(To handle this workaround, one must have a way to call ToUnicode() in a way which does not change
the internal state of the keyboard driver.  Observe:

=over 4

=item *

Such a way is not documented.

=item *

Watch the character reported by ReadConsoleInput() on the C<KEYUP> event for deadkeys.  This is
the character which a deadkey would produce if it is pressed twice (and is 0 if pressing it twice
results in a deadkey again).  The only explanation for this I can fathom is that the console's
message queue thread calls such a non-disturbing-state version of ToUnicode().

Why it should be “non-disturbing”?  Otherwise it would reset the state “this deadkey was pressed”,
and the following keypress would be interpreted as not preceded by a deadkey.  And this is not
what happens.  (If one does it with usual ToUnicode() call, DOWN reports a deadkey, but UP reports
“ignored”; to see this, run F<examples/raw_keys_via_api.pl> with arguments C<Un 1> 
with a keyboard which produces ç on C<AltGr-, c>.  Here C<n> is the number of the keyboard in the list
of available keyboards reported by C<examples/raw_keys_via_api.pl U 1>).

Well, when one I<knows> that some API calls are possible, it is just a SMP to find it out
(see F<examples/raw_keys_via_api.pl>).  It turns out that given argument C<wFlags=0x02> achieves
the behaviour of a console during KeyUp event.  (As a side benefit, it also avoids another
glitch in Windows' keyboard processing: it reports the character value in presence of C<Alt>
modifier — recall that ToUnicodeEx() ignores C<Alt> unless C<Ctrl> is present too.  Well, I
checked this so far only on KeyUp event, where console producess mysterious results.)

=item *

However, even without using undocumented flags, it is not hard to construct such a non-disturbing version of ToUnicode().  The only
ingredient needed is a way to reset the state to “no deadkeys pressed” one.  Then just store
keypresses/releases from the time the last such state was found, call ToUnicode(), reset state,
and call ToUnicode() again for all the stored keypresses/releases; then update the stored state
appropriately.

=item *

But I strongly doubt that console's message loop does anything so advanced.  My bet would be that
it uses a non-documented call or non-documented flags.  (Especially since the approach above does
not handle C<Alt> the same way as the console does.)

=back

=head2 In console, which combinations of keypresses may deliver characters?

In addition to the problem outlined in the preceding section, a console application should
better support L<input of character-by-numeric-code|"Keyboard input on Windows, Part II: The semantic of ToUnicode()">, and of
copy-and-pasted strings.  Actually,
the second situation, although undocumented, is well-engineered, so let us document these two
here.  (These two should better be documented together, since pasting may fake input by
repeated character-by-numeric-code.)

Pasting happens character-by-character (more precise, by UTF-16 codepoints), but C<ReadConsoleInput()>
would group them together:

=over 4

=item *

When pasting a character present in a keyboard layout with at most C<Shift> modifier,
a fully correct emulation of a sequence C<Shift-Press Key-Press Key-Release Shift-Release>
is produced (without C<Shift> if it is not needed).  The character (as usual) is delivered
on both C<Key-Press/Release> events.

=item *

When pasting a character present in a keyboard layout, but needing I<extra> modifiers (not
only C<Shift>), a partial emulation of a certain key tap is produced:
C<rAlt-Press Key-Press Key-Release rAlt-Release>.    The character (as usual) is delivered
on both C<Key-Press/Release> events.

Quirks: first, if C<Shift> is needed, its press/release are not emulated, but the flags on
the C<Key-Press/Release> events indicate presence of a C<Shift>.   Second (by this, the
pasting may be distinguished from “real” keypress), C<lCtrl> press/release are not emulated,
but it is indicated as "present" in flags of all 4 events.

=item *

When pasting control-characters (available via the C<Ctrl(-Shift)>-maps of the layout),
the press/release of C<Ctrl> is not emulated (but the flags indicate C<lCtrl> downs); however,
if C<Shift> is needed, its press/release is emulated (and flags for I<these> events do not
have C<lCtrl> is down).

Pasting C<CR LF> delivers only U+000D (CR) — the typical maps have it on C<Enter> and C<^M>,
and C<Enter> is delivered.

=item *

Otherwise, an emulation of C<lAlt-6-3> is sent, with the C<lAlt-Release> delivering a character:
C<rAlt-Press Key-Press Key-Release Key’-Press Key’-Release lAlt-Release>.  The C<Key Key’>
are very unusual combinations of scancode/vkey for C<6> and C<3> on the numeric keyboard:
they are delivered as if C<NumLock> (or C<Shift>) is down, but the flags indicate that
these modifiers are "not present".

The “honest” C<lAlt-6-3> delivers U+003f, which is "C<?>" (as above, it is delivered on release
of C<lAlt>).

=item *

In general, L<entering characters-by-numeric-code|"Keyboard input on Windows, Part II: The semantic of ToUnicode()"> (entering the
decimal — or “KP+” then hex — while
C<Alt> is down) produces the resulting character when C<Alt> is released.  Processing this may create
a significant problem for applications which interpret C<Alt-keypad> as “commands” (e.g., if
they interpret C<Alt-Left> as “word-left”).

There may several work-arounds.  First, usually hex input is much more important than decimal,
and usually, C<Alt-KP_Add> is not bound to commands.  Then the application may ignore characters
delivered on C<Alt-Release> B<unless> the C<Alt-Press> was immediately followed by the press/release
of C<KP_Add>; additionally, it should disable the interpret-as-commands logic while C<Alt> is down,
and its press was followed by press/release of C<KP_Add>.

Second, it is not crucial to deliver Unicode characters numbered in single-digits.  So one may
require that commands are triggered by C<Alt-Numpad> only when pressed one-by-one (releasing
C<Alt> between them), and consider multi-digit presses as input-by-number only.

Finally, Windows aborts entering character-by-numeric-code if any unexpected key press interferes.
For example, C<Alt-6-3> is “C<?>”, but pressing-releasing C<Shift> after pressing down C<Alt>
would not deliver anything.  If an application follows the same logic (in reverse!) when recognizing
keypressing resulting in “commands”, the users would have at least a “technical ability” to enter
both commands, I<AND> enter characters-by-numeric-code.

=back

This is tested I<ONLY> in the situation when a layout has C<KLLF_ALTGR> present, and all the
"with-extra-modifiers" characters are on bitmap entries with C<RMENU> bit marked.  This is
a situation with discussed in the section L<"A convenient assignment of C<KBD*> bitmaps to modifier keys">.

It is plausible that only C<SHIFT>, C<CTRL> and C<ALT> bits in a bitmap returned by C<VkKeyScan()> are
acted upon (with C<Ctrl> flag added based on C<KLLF_ALTGR>).  Some popular keyboard layouts
use C<KANA> bit on the C<rAlt> key; under this assumption, the characters available via C<rAlt> key
would be delivered with at most C<Shift> modifier.

All the emulated events do not have C<NumLock> indicated as "present" in their flags.

=head2 Behaviour of C<Alt-Modifiers-Key> vs C<Modifiers-Key>

When both combinations produce characters (say, X and Y), it is not clear
how an application shouild decide whether it got C<Alt-Y> event (for menu
entry starting with Y), or an C<X> event.

A partial workaround (if the semantic of the layout fits into the limited number
of bits in the ORed mask): make all the keys which may be combined with
C<Alt> to have the C<KBDCTRL> bit in the mask set; add some extra bit
to C<Ctrl> keys to be able to distinguish them.  Then at least the
kernel will produce the correct character on the ToUnicode() call (hence
in TranslateMessage()).  [A potential that an application may be confused
is still large.]

=head2 Customization of what C<CapsLock> is doing is very limited

(See the description of the semantic of C<CapsLock> in L<"Keyboard input on Windows, Part II: The semantic of ToUnicode()">.)

A partial workaround (if the semantic of the layout fits into the limited number
of bits in the ORed mask): make all the modifier combinations (except for the
base layer) to have C<KBDCTRL> and C<KBDALT> bits set; add some extra bits to
C<Ctrl> keys and C<Alt> keys (apparently, only C<KBDKANA> will work with C<Alt>)
to be able to distinguish them.  Then the C<CAPLOKALTGR> flag will affect all
these combinations too.

=head2 C<lCtrl-rCtrl> combination: multiple problems

First of all, sometimes C<Shift> is ignored when used with this combination.
(Fixed by reboot.  When this happens, C<Shift> does not work also with combinations 
with C<lAlt> and/or C<Menu>).  On the
other hand, C<CapsLock> works as intended.  (I even got an impression that
sometimes C<Shift> works when C<CapsLock> is active; cannot reproduce this,
though.)

I suspect this is related to the binding (usually not active) of C<Shift-Ctrl> to switch between
keyboards of a language.  It may have suddently jumped to existence (without my interaction).
Simultaneously, this option disappeared from the UI to change keyboard options
(L<Language Bar/Settings/Advanced Key Settings> in Windows 7).  It might be that 
press/release of C<Shift> is filtered out in presence of C<lCtrl-rCtrl>?  (Looks
like this for C<rightShift> now...)

(I also saw what looks like C<Menu> key being stuck in some rare situations — fixed
by pressing it again.  Do not know how to reproduce this.  It is interesting to
note that one of the bits in the mask of the C<Menu> key is 0x80, and there is
a define for this bit in F<kbd.h> named C<KBDGRPSELTAP> — but it is undocumented,
and, judging by names, one might think that C<KBDGRPSELTAP> would work in pair with the flag
C<GRPSELTAP> of C<VK_TO_WCHARSn→Attributes>.  [But in fact it is a remnant of never-included-in-the-kernel
attempt to support ISO keyboard concepts.])

B<NOTES:> Apparently, key up/down for many combinations of C<lCtrl+rCtrl+char> are
not delivered to applications.
Key up/down for C<`/5/6/-/=/Z/X/C/V/M/,/./Enter/rShift> are not delivered here when used with C<lCtrl+rCtrl> modifiers
(at least in a console).  Adding C<Shift/lAlt/Menu> does not change this.  Same for C<F1/F2/F8/F9>
and C<Enter/Insert/Delete/Home/PgUp> (but not for keypad ones!).

Moreover, when used with C<KeyPad→> or C<KeyPad*>, this behaves as if both these
keys were pressed.  Same with the pair C<KeyPad-> and C<Keypad+> (is it hardware-dependent???).

(Time to time C<lCtrl+rCtrl+NUMPADchar> do not work — neither with nor without C<NumLock>.)

No workarounds are known.  Although I could reproduce this on 3 physically different
keyboards, this is, most probably, a design defect of hardware keyboards.  Compare with
L<the explanation of problems in diode-less keyboard designs|http://www.dribin.org/dave/keyboard/one_html/> and
L<experiments with 2 Shift keys|http://forums.macrumors.com/threads/hold-down-both-shift-keys-and-type-the-alphabet.230655/>.
Another related tidbit: apparently, L<some hardware keyboard may change the internal layout
after pressing some modifier keys|http://ccm.net/forum/affich-24692-keyboard-mess-up-after-shift-key-held-too-lon?page=2>

=head2 C<lAlt-rAlt> combination: many keys are not delivered to applications

Apparently, key up/down for many combinations of C<lAlt+rAlt+char> are
not delivered to applications.
For example, C<Numpad3> and C<Numpad7> — neither with nor without C<NumLock>; same
for C<G/H/'/B/N/slash> (at least in a console).  Adding C<Shift/lAlt/Menu>
does not change this.  Same for C<F4/F5/F6>.

No workarounds are known (except that C<Numpad3> and C<Numpad7> (without C<NumLock>)
may be replaced by C<Home> and C<PgDown>).

B<NOTE:> in the bottom row of the keyboard, all the keys (except C<lShift>) are
either in the list above, or in the list for C<lCtrl+rCtrl> modifiers.  See also the
references in the discussion of the previous problem (with C<lCtrl+rCtrl>).

=head2 Too long C<DESCRIPTION> of the layout is not shown in Language Bar Settings

(the description is shown in the Language Bar itself).  The examples are (behave the same)

  Greek-QWERTY (Pltn) Grn=⇑␣=^ˡⒶˡ-=Lat; Ripe=Ⓐʳ␣=Mnu-=Rus(Phon); Ripe²=Mnu-^ʳ-=Hbr; k.ilyaz.org
  US-Intl Grn=⇑␣=^ˡⒶˡ-=Grk; Ripe=Ⓐʳ␣=Mnu-=Rus(Phon); Ripe²=Mnu-^ʳ-=Hbr; k.ilyaz.org

(Or maybe it is the semicolons in the names???).  If this happens, one can still assign
distinctive icons to the layout, and distinguish them via going to C<Properties>.

=head1 UNICODE TABLE GOTCHAS

The position of Unicode consortium is, apparently, that the “name” of
a Unicode character is “just an identifier”.  In other words, its
(primary) function is to identify a character uniquely: different
characters should have different names, and that's it.  Any other function
is secondary, and “if it works, fine”; if it does not work, tough luck.
If the name does not match how people use the character (and with the
giant pool of defined characters, this has happened a few times), this is not
a reason to abandon the name.

This position makes the practice of maintaining backward compatibility
easy.  There is L<documentation of obvious errors in the naming|http://unicode.org/notes/tn27/>.

However, this module tries to extract a certain amount of I<orthogonality>
from the giant heap of characters defined in Unicode; the principal concept
is “a mogrifier”.  Most mogrifiers are defined by programmatic inspection of names 
of characters and relations between names of different characters.  (In other
words, we base such mogrifiers on names, not glyphs.)  Here we 
sketch the irregularities uncovered during this process.

APL symbols with C<UP TACK> and C<DOWN TACK> look reverted w.r.t. other
C<UP TACK> and C<DOWN TACK> symbols.

C<LESS-THAN>, C<FULL MOON>, C<GREATER-THAN>, C<EQUALS> C<GREEK RHO>, C<MALE>
are defined with C<SYMBOL> or C<SIGN> at end, but (may) drop it when combined
with modifiers via C<WITH>.  Likewise for C<SUBSET OF>, C<SUPERSET OF>,
C<CONTAINS AS MEMBER>, C<PARALLEL TO>, C<EQUIVALENT TO>, C<IDENTICAL TO>.

Sometimes opposite happens, and C<SIGN> appears out of blue sky; compare:

  2A18	INTEGRAL WITH TIMES SIGN
  2A19	INTEGRAL WITH INTERSECTION

C<ENG> I<is> a combination of C<n> with C<HOOK>, but it is not marked as such
in its name.

Sometimes a name of diacritic (after C<WITH>) acquires an C<ACCENT> at end
(see C<U+0476>).

Oftentimes the part to the left of C<WITH> is not resolvable: sometimes it
is underspecified (e.g, just C<TRIANGLE>), sometimes it is overspecified
(e.g., in C<LEFT VERTICAL BAR WITH QUILL>), sometime it should be understood
as a glyph-of-written-word (e.g, in C<END WITH LEFTWARDS ARROW ABOVE>).  Sometimes it just
does not exist (e.g., C<LATIN LETTER REVERSED GLOTTAL STOP WITH STROKE> -
there is C<LATIN LETTER INVERTED GLOTTAL STOP>, but not the reversed variant).
Sometimes it is a defined synonym (C<VERTICAL BAR>).

Sometimes it has something appended (C<N-ARY UNION OPERATOR WITH DOT>).

Sometimes C<WITH> is just a clarification (C<RIGHTWARDS HARPOON WITH BARB DOWNWARDS>).

  1	AND
  1	ANTENNA
  1	ARABIC MATHEMATICAL OPERATOR HAH
  1	ARABIC MATHEMATICAL OPERATOR MEEM
  1	ARABIC ROUNDED HIGH STOP
  1	ARABIC SMALL HIGH LIGATURE ALEF
  1	ARABIC SMALL HIGH LIGATURE QAF
  1	ARABIC SMALL HIGH LIGATURE SAD
  1	BACK
  1	BLACK SUN
  1	BRIDE
  1	BROKEN CIRCLE
  1	CIRCLED HORIZONTAL BAR
  1	CIRCLED MULTIPLICATION SIGN
  1	CLOSED INTERSECTION
  1	CLOSED LOCK
  1	COMBINING LEFTWARDS HARPOON
  1	COMBINING RIGHTWARDS HARPOON
  1	CONGRUENT
  1	COUPLE
  1	DIAMOND SHAPE
  1	END
  1	EQUIVALENT
  1	FISH CAKE
  1	FROWNING FACE
  1	GLOBE
  1	GRINNING CAT FACE
  1	HEAVY OVAL
  1	HELMET
  1	HORIZONTAL MALE
  1	IDENTICAL
  1	INFINITY NEGATED
  1	INTEGRAL AVERAGE
  1	INTERSECTION BESIDE AND JOINED
  1	KISSING CAT FACE
  1	LATIN CAPITAL LETTER REVERSED C
  1	LATIN CAPITAL LETTER SMALL Q
  1	LATIN LETTER REVERSED GLOTTAL STOP
  1	LATIN LETTER TWO
  1	LATIN SMALL CAPITAL LETTER I
  1	LATIN SMALL CAPITAL LETTER U
  1	LATIN SMALL LETTER LAMBDA
  1	LATIN SMALL LETTER REVERSED R
  1	LATIN SMALL LETTER TC DIGRAPH
  1	LATIN SMALL LETTER TH
  1	LEFT VERTICAL BAR
  1	LOWER RIGHT CORNER
  1	MEASURED RIGHT ANGLE
  1	MONEY
  1	MUSICAL SYMBOL
  1	NIGHT
  1	NOTCHED LEFT SEMICIRCLE
  1	ON
  1	OR
  1	PAGE
  1	RIGHT ANGLE VARIANT
  1	RIGHT DOUBLE ARROW
  1	RIGHT VERTICAL BAR
  1	RUNNING SHIRT
  1	SEMIDIRECT PRODUCT
  1	SIX POINTED STAR
  1	SMALL VEE
  1	SOON
  1	SQUARED UP
  1	SUMMATION
  1	SUPERSET BESIDE AND JOINED BY DASH
  1	TOP
  1	TOP ARC CLOCKWISE ARROW
  1	TRIPLE VERTICAL BAR
  1	UNION BESIDE AND JOINED
  1	UPPER LEFT CORNER
  1	VERTICAL BAR
  1	VERTICAL MALE
  1	WHITE SUN
  2	CLOSED MAILBOX
  2	CLOSED UNION
  2	DENTISTRY SYMBOL LIGHT VERTICAL
  2	DOWN-POINTING TRIANGLE
  2	HEART
  2	LEFT ARROW
  2	LINE INTEGRATION
  2	N-ARY UNION OPERATOR
  2	OPEN MAILBOX
  2	PARALLEL
  2	RIGHT ARROW
  2	SMALL CONTAINS
  2	SMILING CAT FACE
  2	TIMES
  2	TRIPLE HORIZONTAL BAR
  2	UP-POINTING TRIANGLE
  2	VERTICAL KANA REPEAT
  3	CHART
  3	CONTAINS
  3	TRIANGLE
  4	BANKNOTE
  4	DIAMOND
  4	PERSON
  5	LEFTWARDS TWO-HEADED ARROW
  5	RIGHTWARDS TWO-HEADED ARROW
  8	DOWNWARDS HARPOON
  8	UPWARDS HARPOON
  9	SMILING FACE
  11	CIRCLE
  11	FACE
  11	LEFTWARDS HARPOON
  11	RIGHTWARDS HARPOON
  15	SQUARE

  perl -wlane "next unless /^Unresolved: <(.*?)>/; $s{$1}++; END{print qq($s{$_}\t$_) for keys %s}" oxx-us2 | sort -n > oxx-us2-sorted-kw

C<SQUARE WITH> specify fill - not combining.  C<FACE> is not combining, same for C<HARPOON>s.

Only C<CIRCLE WITH HORIZONTAL BAR> is combining.  Triangle is combining only with underbar and dot above.

C<TRIANGLE> means C<WHITE UP-POINTING TRIANGLE>.  C<DIAMOND> - C<WHITE DIAMOND> (so do many others.)
C<TIMES> means C<MULTIPLICATION SIGN>; but C<CIRCLED MULTIPLICATION SIGN> means C<CIRCLED TIMES> - go figure!
C<CIRCLED HORIZONTAL BAR WITH NOTCH> is not a decomposition (it is "something circled").

Another way of compositing is C<OVER> (but not C<UNDER>!) and C<FROM BAR>.  See also C<ABOVE>, C<BELOW>
- but only C<BELOW LONG DASH>.  Avoid C<WITH/AND> after these.

C<TWO HEADED> should replace C<TWO-HEADED>.  C<LEFT ARROW> means C<LEFTWARDS ARROW>, same for C<RIGHT>.
C<DIAMOND SHAPE> means C<DIAMOND> - actually just a bug - http://www.reddit.com/r/programming/comments/fv8ao/unicode_600_standard_published/?
C<LINE INTEGRATION> means C<CONTOUR INTEGRAL>.  C<INTEGRAL AVERAGE> means C<INTEGRAL>.
C<SUMMATION> means C<N-ARY SUMMATION>.  C<INFINITY NEGATED> means C<INFINITY>.

C<HEART> means C<WHITE HEART SUIT>.  C<TRIPLE HORIZONTAL BAR> looks genuinely missing...

C<SEMIDIRECT PRODUCT> means one of two, left or right???

This better be convertible by rounding/sharpening mogrifiers, but see
C<BUT NOT/WITH NOT/OR NOT/AND SINGLE LINE NOT/ABOVE SINGLE LINE NOT/ABOVE NOT>

  2268    LESS-THAN BUT NOT EQUAL TO;             1.1
  2269    GREATER-THAN BUT NOT EQUAL TO;          1.1
  228A    SUBSET OF WITH NOT EQUAL TO;            1.1
  228B    SUPERSET OF WITH NOT EQUAL TO;          1.1
  @               Relations
  22E4    SQUARE IMAGE OF OR NOT EQUAL TO;                1.1
  22E5    SQUARE ORIGINAL OF OR NOT EQUAL TO;             1.1
  @@      2A00    Supplemental Mathematical Operators     2AFF
  @               Relational operators
  2A87    LESS-THAN AND SINGLE-LINE NOT EQUAL TO;         3.2
          x (less-than but not equal to - 2268)
  2A88    GREATER-THAN AND SINGLE-LINE NOT EQUAL TO;              3.2
          x (greater-than but not equal to - 2269)
  2AB1    PRECEDES ABOVE SINGLE-LINE NOT EQUAL TO;                3.2
  2AB2    SUCCEEDS ABOVE SINGLE-LINE NOT EQUAL TO;                3.2
  2AB5    PRECEDES ABOVE NOT EQUAL TO;            3.2
  2AB6    SUCCEEDS ABOVE NOT EQUAL TO;            3.2
  @               Subset and superset relations
  2ACB    SUBSET OF ABOVE NOT EQUAL TO;           3.2
  2ACC    SUPERSET OF ABOVE NOT EQUAL TO;         3.2

Looking into v6.1 reference PDFs, 2268,2269,2ab5,2ab6,2acb,2acc have two horizontal bars, 
228A,228B,22e4,22e5,2a87,2a88,2ab1,2ab2 have one horizontal bar,  Hence C<BUT NOT EQUAL TO> and C<ABOVE NOT EQUAL TO>
are equivalent; so are C<WITH NOT EQUAL TO>, C<OR NOT EQUAL TO>, C<AND SINGLE-LINE NOT EQUAL TO>
and C<ABOVE SINGLE-LINE NOT EQUAL TO>.  (Square variants come only with one horizontal line?)


Set C<$ENV{UI_KEYBOARDLAYOUT_UNRESOLVED}> to enable warnings.  Then do

  perl -wlane "next unless /^Unresolved: <(.*?)>/; $s{$1}++; END{print qq($s{$_}\t$_) for keys %s}" oxx | sort -n > oxx-sorted-kw

=head1 More (random) rambling on assignment of key combinations

(Here we continue the discussion in L<"A convenient assignment of KBD* bitmaps to modifier keys">.  This stems from an obsolete
assumption that it makes sense to assign to L<Win> key the modifier flags C<CTRL|X1>:

  lCtrl		Win	 lAlt		rAlt			Menu		rCtrl
  CTRL|LOYA	CTRL|X1	 ALT|KANA	CTRL|ALT|LOYA|X1	CTRL|ALT|X2	CTRL|ALT|ROYA

Nowadays I would use C<CTRL|X3> instead.)

B<NOTES:> All the combinations involving at most one of C<lCtrl>, C<Win> or 
C<rAlt> give distinct ORed masks.  This completely preserving all
application-visible properties of keyboard events [except those with C<lCtrl-Win-lAlt->
modifiers; this combination is equivalent to C<lAlt-rAlt->].
The only combination of C<LOYA,KANA,X1,X2,ROYA> which may appear with
different C<CTRL,ALT> bits is C<LOYA|X1>; hence there are 33 possible combinations
of C<CTRL,ALT,LOYA,KANA,X1,X2,ROYA>.


Indeed, C<CTRL> is determined by C<LOYA|X1|X2|ROYA>. 
If one of C<KANA,X2,ROYA> is present, then C<ALT> is set; so assume C<KANA,X2,ROYA> are not present. 
But then, if C<ALT> B<may be> set, then both C<LOYA|X1> B<must> be present; which gives the
only duplication.

Leaving out 5 combinations of C<lCtrl>, C<Win>, C<lAlt> [8, minus the empty one, and 
C<lCtrl+lAlt>, which is avoided by most application due to its similarity to C<AltGr=rAlt>,
and C<lCtrl+Win+lAlt> which is undistinguishable by the mask from C<lAlt+rAlt>]
to have bindable keypresses in applications, and having C<rCtrl> as equivalent to
C<lCtrl>, this gives 27 C<Shift>-pairs which may produce characters.

B<NOTE:> C<lCtrl+Win+lAlt> being undistinguishable by the mask from C<lAlt+rAlt>
is not a big deal, since there is no standard keyboard shortcuts involving C<Ctrl+Win+Alt>.

B<NOTE:> Combinations of C<lCtrl> with C<rCtrl> L<cause several problems|"C<lCtrl-rCtrl> combination: multiple problems">;
likewise for L<combinations of C<lAlt> with C<rAlt> |"C<lAlt-rAlt> combination: many keys are not delivered to applications">.
B<Summary:> These seem to be combinations of keyboard’s hardware problems with (rare, unreproducible)
software-being-stuck-in-unexpected-state problems (should not one try to switch between keyboard layout then?!).

=head1 SEE ALSO

The keyboard(s) generated with this module: L<UI::KeyboardLayout::izKeys>, L<http://k.ilyaz.org/>

On diacritics:

  http://www.phon.ucl.ac.uk/home/wells/dia/diacritics-revised.htm#two
  http://en.wikipedia.org/wiki/Tonos#Unicode
  http://en.wikipedia.org/wiki/Early_Cyrillic_alphabet#Numerals.2C_diacritics_and_punctuation
  http://en.wikipedia.org/wiki/Vietnamese_alphabet#Tone_marks
  http://diacritics.typo.cz/

  http://en.wikipedia.org/wiki/User:TEB728/temp			(Chars of languages)
  http://www.evertype.com/alphabets/index.html

     Accents in different Languages:
  http://fonty.pl/porady,12,inne_diakrytyki.htm#07
  http://en.wikipedia.org/wiki/Latin-derived_alphabet
  
On typography marks

  http://wiki.neo-layout.org/wiki/Striche
  http://www.matthias-kammerer.de/SonsTypo3.htm
  http://en.wikipedia.org/wiki/Soft_hyphen
  http://en.wikipedia.org/wiki/Dash
  http://en.wikipedia.org/wiki/Ditto_mark

On keyboard layouts:

  http://en.wikipedia.org/wiki/Keyboard_layout
  http://en.wikipedia.org/wiki/Keyboard_layout#US-International
  http://en.wikipedia.org/wiki/ISO/IEC_9995
  http://www.pentzlin.com/info2-9995-3-V3.pdf		(used almost nowhere - only half of keys in Canadian multilanguage match)
      http://en.wikipedia.org/wiki/QWERTY#Canadian_Multilingual_Standard
  http://en.wikipedia.org/wiki/Unicode_input
      Discussion of layout changes and position of €:
  https://www.libreoffice.org/bugzilla/show_bug.cgi?id=5981
  
    History of QUERTY
  http://kanji.zinbun.kyoto-u.ac.jp/~yasuoka/publications/PreQWERTY.html
  http://kanji.zinbun.kyoto-u.ac.jp/db-machine/~yasuoka/QWERTY/

  http://msdn.microsoft.com/en-us/goglobal/bb964651
  http://eurkey.steffen.bruentjen.eu/layout.html
  http://ru.wikipedia.org/wiki/%D0%A4%D0%B0%D0%B9%D0%BB:Birman%27s_keyboard_layout.svg
  http://bepo.fr/wiki/Accueil
  http://www.unibuc.ro/e/prof/paliga_v_s/soft-reso/			(Academic for Mac)
  http://cgit.freedesktop.org/xkeyboard-config/tree/symbols/ru
  http://cgit.freedesktop.org/xkeyboard-config/tree/symbols/keypad
  http://www.evertype.com/celtscript/type-keys.html			(Old Irish mechanical typewriters)
  http://eklhad.net/linux/app/halfqwerty.xkb			(One-handed layout)
  http://www.doink.ch/an-x11-keyboard-layout-for-scholars-of-old-germanic/   (and references there)
  http://www.neo-layout.org/
  https://commons.wikimedia.org/wiki/File:Neo2_keyboard_layout.svg
      Images in (download of)
  http://www.mzuther.de/en/contents/osd-neo2
      Neo2 sources:
  http://wiki.neo-layout.org/browser/windows/kbdneo2/Quelldateien
      Shift keys at center, nice graphic:
  http://www.tinkerwithabandon.com/twa/keyboarding.html
      Physical keyboard:
  http://www.konyin.com/?page=product.Multilingual%20Keyboard%20for%20UNITED%20STATES
      Polytonic Greek
  http://www.polytoniko.org/keyb.php?newlang=en
      Portable keyboard layout
  http://www.autohotkey.com/forum/viewtopic.php?t=28447
      One-handed
  http://www.autohotkey.com/forum/topic1326.html
      Typing on numeric keypad
  http://goron.de/~johns/one-hand/#documentation
      On screen keyboard indicator
  http://www.autohotkey.com/docs/scripts/KeyboardOnScreen.htm
      Keyboards of ЕС-1840/1/5
  http://aic-crimea.narod.ru/Study/Shen/PC/1/5-4-1.htm
     (http://www.aic-crimea.narod.ru/Study/Shen/PC/main.htm)	Руководство пользователя ПЭВМ
  http://fdd5-25.net/fddforum/index.php?PHPSESSID=201bd45ab972f1ab4b440dcb6c7ca18f&topic=489.30
      Phonetic Hebrew layout(s) (1st has many duplicates, 2nd overweighted)
  http://bc.tech.coop/Hebrew-ZC.html
  http://help.keymanweb.com/keyboards/keyboard_galaxiehebrewkm6.php
      Greek (Galaxy) with a convenient mapping (except for Ψ) and BibleScript
  http://www.tavultesoft.com/keyboarddownloads/%7B4D179548-1215-4167-8EF7-7F42B9B0C2A6%7D/manual.pdf
      With 2-letter input of Unicode names:
  http://www.jlg-utilities.com
      Medievist's
  http://www.personal.leeds.ac.uk/~ecl6tam/
      Yandex visual keyboards
  http://habrahabr.ru/company/yandex/blog/108255/
      Implementation in FireFox
  http://mxr.mozilla.org/mozilla-central/source/widget/windows/KeyboardLayout.cpp#1085
      Implementation in Emacs 24.3 (ToUnicode() in fns)
  http://fossies.org/linux/misc/emacs-24.3.tar.gz:a/emacs-24.3/src/w32inevt.c
  http://fossies.org/linux/misc/emacs-24.3.tar.gz:a/emacs-24.3/src/w32fns.c
  http://fossies.org/linux/misc/emacs-24.3.tar.gz:a/emacs-24.3/src/w32term.c
      Naive implementations:
  http://social.msdn.microsoft.com/forums/en-US/windowssdk/thread/07afec87-68c1-4a56-bf46-a38a9c2232e9/
      Quality of a keyboard
  http://www.tavultesoft.com/keymandev/quality/whitepaper1.1.pdf

Manipulating keyboards on Windows and X11

  http://symbolcodes.tlt.psu.edu/keyboards/winkeyvista.html		(using links there: up to Win7)
  http://windows.microsoft.com/en-us/windows-8/change-keyboard-layout
  http://www.howtoforge.com/changing-language-and-keyboard-layout-on-various-linux-distributions

MSKLC parser

  http://pastebin.com/UXc1ub4V

By author of MSKLC Michael S. Kaplan (do not forget to follow links)

      Input on Windows:
  http://seit.unsw.adfa.edu.au/staff/sites/hrp/personal/Sanskrit-External/Unicode-KbdsonWindows.pdf

  http://blogs.msdn.com/b/michkap/archive/2006/03/26/560595.aspx
  http://blogs.msdn.com/b/michkap/archive/2006/04/22/581107.aspx
      Chaining dead keys:
  http://blogs.msdn.com/b/michkap/archive/2011/04/16/10154700.aspx
      Mapping VK to VSC etc:
  http://blogs.msdn.com/b/michkap/archive/2006/08/29/729476.aspx
      [Link] Remapping CapsLock to mean Backspace in a keyboard layout
            (if repeat, every second Press counts ;-)
  http://colemak.com/forum/viewtopic.php?id=870
      Scancodes from kbd.h get in the way
  http://blogs.msdn.com/b/michkap/archive/2006/08/30/726087.aspx
      What happens if you start with .klc with other VK_ mappings:
  http://blogs.msdn.com/b/michkap/archive/2010/11/03/10085336.aspx
      Keyboards with Ctrl-Shift states:
  http://blogs.msdn.com/b/michkap/archive/2010/10/08/10073124.aspx
      On assigning Ctrl-values
  http://blogs.msdn.com/b/michkap/archive/2008/11/04/9037027.aspx
      On hotkeys for switching layouts:
  http://blogs.msdn.com/b/michkap/archive/2008/07/16/8736898.aspx
      Text services
  http://blogs.msdn.com/b/michkap/archive/2008/06/30/8669123.aspx
      Low-level access in MSKLC
  http://levicki.net/articles/tips/2006/09/29/HOWTO_Build_keyboard_layouts_for_Windows_x64.php
  http://blogs.msdn.com/b/michkap/archive/2011/04/09/10151666.aspx
      On font linking
  http://blogs.msdn.com/b/michkap/archive/2006/01/22/515864.aspx
      Unicode in console
  http://blogs.msdn.com/michkap/archive/2005/12/15/504092.aspx
      Adding formerly "invisible" keys to the keyboard
  http://blogs.msdn.com/b/michkap/archive/2006/09/26/771554.aspx
      Redefining NumKeypad keys
  http://blogs.msdn.com/b/michkap/archive/2007/07/04/3690200.aspx
	BUT!!!
  http://blogs.msdn.com/b/michkap/archive/2010/04/05/9988581.aspx
      And backspace/return/etc
  http://blogs.msdn.com/b/michkap/archive/2008/10/27/9018025.aspx
       kbdutool.exe, run with the /S  ==> .c files
      Doing one's own WM_DEADKEY processing'
  http://blogs.msdn.com/b/michkap/archive/2006/09/10/748775.aspx
      Dead keys do not work on SG-Caps
  http://blogs.msdn.com/b/michkap/archive/2008/02/09/7564967.aspx
      Dynamic keycaps keyboard
  http://blogs.msdn.com/b/michkap/archive/2005/07/20/441227.aspx
      Backslash/yen/won confusion
  http://blogs.msdn.com/b/michkap/archive/2005/09/17/469941.aspx
      Unicode output to console
  http://blogs.msdn.com/b/michkap/archive/2010/10/07/10072032.aspx
      Install/Load/Activate an input method/layout
  http://blogs.msdn.com/b/michkap/archive/2007/12/01/6631463.aspx
  http://blogs.msdn.com/b/michkap/archive/2008/05/23/8537281.aspx
      Reset to a TT font from an application:
  http://blogs.msdn.com/b/michkap/archive/2011/09/22/10215125.aspx
      How to (not) treat C-A-Q
  http://blogs.msdn.com/b/michkap/archive/2012/04/26/10297903.aspx
      Treating Brazilian ABNT c1 c2 keys
  http://blogs.msdn.com/b/michkap/archive/2006/10/07/799605.aspx
      And JIS ¥|-key
	 (compare with  http://www.scs.stanford.edu/11wi-cs140/pintos/specs/kbd/scancodes-7.html
			http://hp.vector.co.jp/authors/VA003720/lpproj/others/kbdjpn.htm )
  http://blogs.msdn.com/b/michkap/archive/2006/09/26/771554.aspx
      Suggest a topic:
  http://blogs.msdn.com/b/michkap/archive/2007/07/29/4120528.aspx#7119166

Installable Keyboard Layouts - Apple Developer (“.keylayout” files; modifiers not editable; cache may create problems;
to enable deadkeys in X11, one may need extra work)

  http://developer.apple.com/technotes/tn2002/tn2056.html
  http://wordherd.com/keyboards/
  http://stackoverflow.com/questions/999681/how-to-remap-context-menu-key-in-mac-os-x
  http://apple.stackexchange.com/questions/21691/ukelele-generated-custom-keyboard-layouts-not-working-in-lion
  http://wiki.openoffice.org/wiki/X11Keymaps
  http://www.tenshu.net/2012/11/using-caps-lock-as-new-modifier-key-in.html
  http://raw.github.com/lreddie/ukelele-steps/master/USExtended.keylayout
  http://scripts.sil.org/cms/scripts/page.php?item_id=keylayoutmaker

ANSI/ISO/ABNT/JIS/Russian Apple’s keyboards

  https://discussions.apple.com/thread/1508293
  http://www.dtp-transit.jp/apple/mac/post_1137.html
  http://www.dtp-transit.jp/images/apple-keyboards-US-JIS.jpg
  http://m10lmac.blogspot.co.il/2007/02/fixing-brazilian-keyboard-layout.html
  http://www2d.biglobe.ne.jp/~msyk/keyboard/layout/mac-jiskbd.html
  http://commons.wikimedia.org/wiki/File:KB_Russian_Apple_Macintosh.svg

JIS variations (OADG109 vs A)

  http://ja.wikipedia.org/wiki/JIS%E3%82%AD%E3%83%BC%E3%83%9C%E3%83%BC%E3%83%89

Different ways to access chars on Mac (1ˢᵗ suggests adding a Discover via plists via Keycaps≠Strings)

  http://apple.stackexchange.com/questions/49565/how-can-i-expand-the-number-of-special-characters-i-can-type-using-my-keyboard
  http://developer.apple.com/library/mac/#documentation/cocoa/conceptual/eventoverview/TextDefaultsBindings/TextDefaultsBindings.html#//apple_ref/doc/uid/20000468-CJBDEADF
  http://www.hcs.harvard.edu/~jrus/Site/System%20Bindings.html			Default keybindings
  http://www.hcs.harvard.edu/~jrus/Site/Cocoa%20Text%20System.html
  http://hints.macworld.com/article.php?story=2005051118320432			Mystery keys on Mac
  http://www.snark.de/index.cgi/0007						Patching ADB drivers
  http://www.snark.de/mac/usbkbpatch/index_en.html				Patching USB drivers (gives LCtrl vs RCtrl etc???)
  http://www.lorax.com/FreeStuff/TextExtras.html				(has no docs???)
  http://stevelosh.com/blog/2012/10/a-modern-space-cadet/			Combining different approaches
  http://brettterpstra.com/2012/12/08/a-useful-caps-lock-key/			  (simplified version of ↖)
  http://david.rothlis.net/keyboards/microsoft_natural_osx/			Num Lock is claimed as not working

Compose on Mac requires hacks:

  http://apple.stackexchange.com/questions/31487/add-compose-key-to-os-x

Convert Apple to MSKLC

  http://typophile.com/node/90606

Keyboards on Mac:

  http://homepage.mac.com/thgewecke/mlingos9.html
  http://web.archive.org/web/20080717203026/http://homepage.mac.com/thgewecke/mlingos9.html

Tool to produce:

  http://wordherd.com/keyboards/
  http://developer.apple.com/library/mac/#technotes/tn2056/_index.html

VK_OEM_8 Kana modifier - Using instead of AltGr

  http://www.kbdedit.com/manual/ex13_replacing_altgr_with_kana.html

Limitations of using KANA toggle

  http://www.kbdedit.com/manual/ex12_trilang_ser_cyr_lat_gre.html

KANALOK documented:

  http://www.kbdedit.com/manual/high_level_kanalok.html

(Essentially, when C<KBDKANA> modifier-flag is assigned on C<VK_KANA> — as opposed on, e.g., C<VK_OEM_8> — the “is-pressed” state of
C<VK_KANA> is toggled on each keypress, but the C<KBDKANA> bit is not (?) set in the “current keyboard state”.  Instead, keys with
C<KANALOK> flag react on “calculated KBDKANA” which is found by the “pressed state” of VK_KANA.)

FE (Far Eastern) keyboard source code example (NEC AT is 106 with SPECIAL MULTIVK flags changed on some scancodes, OEM_7/8 producing 0x1e 0x1f, and no OEM_102):
  
  http://read.pudn.com/downloads3/sourcecode/windows/248345/win2k/private/ntos/w32/ntuser/kbd/fe_kbds/jpn/ibm02/kbdibm02.c__.htm
  http://read.pudn.com/downloads3/sourcecode/windows/248345/win2k/private/ntos/w32/ntuser/kbd/fe_kbds/jpn/kbdnecat/kbdnecat.c__.htm
  http://read.pudn.com/downloads3/sourcecode/windows/248345/win2k/private/ntos/w32/ntuser/kbd/fe_kbds/jpn/106/kbd106.c__.htm

	Investigation on relation between VK_ asignments, KBDEXT, KBDNUMPAD etc:
  http://code.google.com/p/ergo-dvorak-for-developers/source/browse/trunk/kbddvp.c

    PowerShell vs ISE (and how to find them [On Win7: WinKey Accessories]
  http://blogs.msdn.com/b/powershell/archive/2009/04/17/differences-between-the-ise-and-powershell-console.aspx
  http://blogs.msdn.com/b/michkap/archive/2013/01/23/10387424.aspx
  http://blogs.msdn.com/b/michkap/archive/2013/02/15/10393862.aspx
  http://blogs.msdn.com/b/michkap/archive/2013/02/19/10395086.aspx
  http://blogs.msdn.com/b/michkap/archive/2013/02/20/10395416.aspx

  Google for "Get modification number for Shift key" for code to query the kbd DLL directly ("keylogger")
    http://web.archive.org/web/20120106074849/http://debtnews.net/index.php/article/debtor/2008-09-08/1088.html
    http://code.google.com/p/keymagic/source/browse/KeyMagicDll/kbdext.cpp?name=0419d8d626&r=d85498403fd59bca9efc04b4e5bb4406d39439a0

  How to read Unicode in an ANSI Window:
    http://social.msdn.microsoft.com/Forums/en-US/windowsgeneraldevelopmentissues/thread/d455e846-d18b-4086-98de-822658bcebf0/
    http://blog.tavultesoft.com/2011/06/accepting-unicode-input-in-your-windows-application.html

HTML consolidated entity names and discussion, MES charsets:

  http://www.w3.org/TR/xml-entity-names
  http://www.w3.org/2003/entities/2007/w3centities-f.ent
  http://www.cl.cam.ac.uk/~mgk25/ucs/mes-2-rationale.html
  http://web.archive.org/web/20000815100817/http://www.egt.ie/standards/iso10646/pdf/cwa13873.pdf

Ctrl2cap

  http://technet.microsoft.com/en-us/sysinternals/bb897578

Low level scancode mapping

  http://www.annoyances.org/exec/forum/winxp/r1017256194
    http://web.archive.org/web/20030211001441/http://www.microsoft.com/hwdev/tech/input/w2kscan-map.asp
    http://msdn.microsoft.com/en-us/windows/hardware/gg463447
  http://www.annoyances.org/exec/forum/winxp/1034644655
     ???
  http://netj.org/2004/07/windows_keymap
  the free remapkey.exe utility that's in Microsoft NT / 2000 resource kit.

  perl -wlne "BEGIN{$t = {T => q(), qw( X e0 Y e1 )}} print qq(  $t->{$1}$2\t$3) if /^#define\s+([TXY])([0-9a-f]{2})\s+(?:_EQ|_NE)\((?:(?:\s*\w+\s*,){3})?\s*([^\W_]\w*)\s*(?:(?:,\s*\w+\s*){2})?\)\s*(?:\/\/.*)?$/i" kbd.h >ll2
    then select stuff up to the first e1 key (but DECIMAL is not there T53 is DELETE??? take from MSKLC help/using/advanced/scancodes)

CapsLock as on typewriter:

  http://web.archive.org/web/20120717083202/http://www.annoyances.org/exec/forum/winxp/1071197341

Scancodes visible on the low level:

  http://openbsd.7691.n7.nabble.com/Patch-Support-F13-F24-on-PC-122-terminal-keyboard-td224992.html
  http://www.seasip.info/Misc/1227T.html

Scancodes visible on Windows (with USB)

  http://download.microsoft.com/download/1/6/1/161ba512-40e2-4cc9-843a-923143f3456c/translate.pdf

Detailed description of production of scancodes (see after C<===>), including C<0x80xx> codes (and C<0xe2> Logitech prefix):

  http://www.fysh.org/~zefram/keyboard/xt_scancodes.txt

Ultra-exotic virtual keys

See

  https://learn.microsoft.com/en-us/previous-versions/aa931968(v=msdn.10)

(note that C<OEM_ATTN OEM_COPY OEM_CUSEL OEM_ENLW> do not seem to have any scancodes assigned anywhere…).

See also L<this discussion|https://stackoverflow.com/questions/11740958/js-what-keyboard-keys-are-specified-for-key-codes-in-intervals-146-185-193-218>.
and L<these lists and references|https://bsakatu.net/doc/virtual-key-of-windows/>.

(L<One of (industrial) keyboards with C<OEM_FJ_000>-key|https://geekhack.org/index.php?topic=60355.0> is a part of
L<a huge family|https://telcontar.net/KBK/Fujitsu/series>.

The less exotic “largish” keyboards are discussed in
L<"Issues with support of European(ISO)/Brazilian(ABNT2)/Japanese(JIS) physical keyboards">.

X11 XKB docs:

  https://www.x.org/releases/X11R7.7/doc/kbproto/xkbproto.html

  ftp://www.x.org/pub/xorg/X11R7.5/doc/input/XKB-Enhancing.html			(what is caps:shift* ???)
  https://wiki.gentoo.org/wiki/Keyboard_layout_switching
  http://webkeys.platonix.co.il/about/use_xkb/#caps-key-types

  https://apt-browse.org/browse/debian/wheezy/main/all/xkb-data/2.5.1-3/file/usr/share/X11/xkb/symbols/keypad
  http://misc.openbsd.narkive.com/UK2Xlptl/shift-backspace-in-x
	NoSymbol (do not change; do not make array longer; if alphabetic, may be extended to width 2)
	  vs VoidSymbol (undefine; may actually extend the array.  Undocumented in xkbproto??? )
		compare with http://kotoistus.tksoft.com/linux/void_no_symbol-en.html

	  overlay1=<KO7> overlay2=<KO7>		How to switch to overlay: see compat/keypad
	  RadioGroup ???

Problems on X11:

  http://www.x.org/releases/X11R7.7/doc/kbproto/xkbproto.html			(definition of XKB protocol)
  http://www.x.org/releases/current/doc/kbproto/xkbproto.html

  http://web.archive.org/web/20050306001520/http://pascal.tsu.ru/en/xkb/

	Some features are removed in libxkbcommon, which is used by many toolkits now:
		https://xkbcommon.org/doc/current/md_doc_compat.html
			But XKB is implemented in the server???

  http://wiki.linuxquestions.org/wiki/Configuring_keyboards			(current???)
  http://wiki.linuxquestions.org/wiki/Accented_Characters			(current???)
  http://wiki.linuxquestions.org/wiki/Altering_or_Creating_Keyboard_Maps	(current???)
  https://help.ubuntu.com/community/ComposeKey			(documents almost 1/2 of the needed stuff)
  http://www.gentoo.org/doc/en/utf-8.xml					(2005++ ???)
  http://en.gentoo-wiki.com/wiki/X.Org/Input_drivers	(2009++ HAS: How to make CapsLock change layouts)
  http://www.freebsd.org/cgi/man.cgi?query=setxkbmap&sektion=1&manpath=X11R7.4
  http://people.uleth.ca/~daniel.odonnell/Blog/custom-keyboard-in-linuxx11
  http://shtrom.ssji.net/skb/xorg-ligatures.html				(of 2008???)
  http://tldp.org/HOWTO/Danish-HOWTO-2.html					(of 2005???)
  http://www.tux.org/~balsa/linux/deadkeys/index.html				(of 1999???)
  http://www.x.org/releases/X11R7.6/doc/libX11/Compose/en_US.UTF-8.html
  http://cgit.freedesktop.org/xorg/proto/xproto/plain/keysymdef.h

  EIGHT_LEVEL FOUR_LEVEL_ALPHABETIC FOUR_LEVEL_SEMIALPHABETIC PC_SYSRQ : see
  http://cafbit.com/resource/mackeyboard/mackeyboard.xkb

  ./xkb in /etc/X11 /usr/local/X11 /usr/share/local/X11 /usr/share/X11
    (maybe it is more productive to try
      ls -d /*/*/xkb  /*/*/*/xkb
     ?)
  but what dead_diaeresis means is defined here:
     Apparently, may be in /usr/X11R6/lib/X11/locale/en_US.UTF-8/Compose /usr/share/X11/locale/en_US.UTF-8/Compose
  http://wiki.maemo.org/Remapping_keyboard
  http://www.x.org/releases/current/doc/man/man8/mkcomposecache.8.xhtml
  
B<Note:> have XIM input method in GTK disables Control-Shift-u way of entering HEX unicode.

    How to contribute:
  http://www.freedesktop.org/wiki/Software/XKeyboardConfig/Rules

B<Note:> the problems with handling deadkeys via .Compose are that: .Compose is handled by
applications, while keymaps by server (since they may be on different machines, things can
easily get out of sync); .Compose knows nothing about the current "Keyboard group" or of
the state of CapsLock etc (therefore emulating "group switch" via composing is impossible).

JS code to add "insert these chars": google for editpage_specialchars_cyrilic, or

  http://en.wikipedia.org/wiki/User:TEB728/monobook.jsx

Latin paleography

  http://en.wikipedia.org/wiki/Latin_alphabet
  http://tlt.its.psu.edu/suggestions/international/bylanguage/oenglish.html
  http://guindo.pntic.mec.es/~jmag0042/LATIN_PALEOGRAPHY.pdf
  http://www.evertype.com/standards/wynnyogh/ezhyogh.html
  http://www.wordorigins.org/downloads/OELetters.doc
  http://www.menota.uio.no/menota-entities.txt
  http://std.dkuug.dk/jtc1/sc2/wg2/docs/n2957.pdf	(Uncomplete???)
  http://skaldic.arts.usyd.edu.au/db.php?table=mufi_char&if=mufi	(No prioritization...)

Summary tables for Cyrillic

  http://ru.wikipedia.org/wiki/%D0%9A%D0%B8%D1%80%D0%B8%D0%BB%D0%BB%D0%B8%D1%86%D0%B0#.D0.A1.D0.BE.D0.B2.D1.80.D0.B5.D0.BC.D0.B5.D0.BD.D0.BD.D1.8B.D0.B5_.D0.BA.D0.B8.D1.80.D0.B8.D0.BB.D0.BB.D0.B8.D1.87.D0.B5.D1.81.D0.BA.D0.B8.D0.B5_.D0.B0.D0.BB.D1.84.D0.B0.D0.B2.D0.B8.D1.82.D1.8B_.D1.81.D0.BB.D0.B0.D0.B2.D1.8F.D0.BD.D1.81.D0.BA.D0.B8.D1.85_.D1.8F.D0.B7.D1.8B.D0.BA.D0.BE.D0.B2
  http://ru.wikipedia.org/wiki/%D0%9F%D0%BE%D0%B7%D0%B8%D1%86%D0%B8%D0%B8_%D0%B1%D1%83%D0%BA%D0%B2_%D0%BA%D0%B8%D1%80%D0%B8%D0%BB%D0%BB%D0%B8%D1%86%D1%8B_%D0%B2_%D0%B0%D0%BB%D1%84%D0%B0%D0%B2%D0%B8%D1%82%D0%B0%D1%85
  http://en.wikipedia.org/wiki/List_of_Cyrillic_letters			- per language tables
  http://en.wikipedia.org/wiki/Cyrillic_alphabets#Summary_table
  http://en.wiktionary.org/wiki/Appendix:Cyrillic_script

     Extra chars (see also the ordering table on page 8)
  http://std.dkuug.dk/jtc1/sc2/wg2/docs/n3194.pdf
  
     Typesetting Old and Modern Church Slavonic
  http://www.sanu.ac.rs/Cirilica/Prilozi/Skup.pdf
  http://irmologion.ru/ucsenc/ucslay8.html
  http://irmologion.ru/csscript/csscript.html
  http://cslav.org/success.htm
  http://irmologion.ru/developer/fontdev.html#allocating

     Non-dialogue of Slavists and Unicode experts
  http://www.sanu.ac.rs/Cirilica/Prilozi/Standard.pdf
  http://kodeks.uni-bamberg.de/slavling/downloads/2008-07-26_white-paper.pdf
  
     Newer: (+ combining ф)
  http://tug.org/pipermail/xetex/2012-May/023007.html
  http://www.unicode.org/alloc/Pipeline.html		As below, plus N-left-hook, ДЗЖ ДЧ, L-descender, modifier-Ь/Ъ
  http://www.synaxis.info/azbuka/ponomar/charset/charset_1.htm
  http://www.synaxis.info/azbuka/ponomar/charset/charset_2.htm
  http://www.synaxis.info/azbuka/ponomar/roadmap/roadmap.html
  http://www.ponomar.net/cu_support.html
  http://www.ponomar.net/files/out.pdf
  http://www.ponomar.net/files/variants.pdf		(5 VS for Mark's chapter, 2 VS for t, 1 VS for the rest)

  http://std.dkuug.dk/jtc1/sc2/wg2/docs/n3772.pdf	typikon (+[semi]circled), ε-form
  http://std.dkuug.dk/jtc1/sc2/wg2/docs/n3971.pdf	inverted ε-typikon
  http://std.dkuug.dk/jtc1/sc2/wg2/docs/n3974.pdf	two variants of o/O
  http://std.dkuug.dk/jtc1/sc2/wg2/docs/n3998.pdf	Mark's chapter
  http://std.dkuug.dk/jtc1/sc2/wg2/docs/n3563.pdf	Reversed tse

IPA

  http://upload.wikimedia.org/wikipedia/commons/f/f5/IPA_chart_2005_png.svg
  http://en.wikipedia.org/wiki/Obsolete_and_nonstandard_symbols_in_the_International_Phonetic_Alphabet
  http://en.wikipedia.org/wiki/Case_variants_of_IPA_letters
    Table with Unicode points marked:
  http://www.staff.uni-marburg.de/~luedersb/IPA_CHART2005-UNICODE.pdf
			(except for "Lateral flap" and "Epiglottal" column/row.
    (Extended) IPA explained by consortium:
  http://unicode.org/charts/PDF/U0250.pdf
    IPA keyboard
  http://www.rejc2.co.uk/ipakeyboard/

http://en.wikipedia.org/wiki/International_Phonetic_Alphabet_chart_for_English_dialects#cite_ref-r_11-0


Is this discussing KBDNLS_TYPE_TOGGLE on VK_KANA???

  http://mychro.mydns.jp/~mychro/mt/2010/05/vk-f.html

Windows: fonts substitution/fallback/replacement

  http://msdn.microsoft.com/en-us/goglobal/bb688134

Problems on Windows:

  http://en.wikipedia.org/wiki/Help:Special_characters#Alt_keycodes_for_Windows_computers
  http://en.wikipedia.org/wiki/Template_talk:Unicode#Plane_One_fonts

    Console font: Lucida Console 14 is viewable, but has practically no Unicode support.
                  Consolas (good at 16) has much better Unicode support (sometimes better sometimes worse than DejaVue)
		  Dejavue is good at 14 (equal to a GUI font size 9 on 15in 1300px screen; 16px unifont is native at 12 here)
  http://cristianadam.blogspot.com/2009/11/windows-console-and-true-type-fonts.html
  
    Apparently, Windows picks up the flavor (Bold/Italic/Etc) of DejaVue at random; see
  http://jpsoft.com/forums/threads/strange-results-with-cp-1252.1129/
	- he got it in bold.  I''m getting it in italic...  Workaround: uninstall 
	  all flavors but one (the BOOK flavor), THEN enable it for the console...  Then reinstall
	  (preferably newer versions).

Display (how WikiPedia does it):

  http://en.wikipedia.org/wiki/Help:Special_characters#Displaying_special_characters
  http://en.wikipedia.org/wiki/Template:Unicode
  http://en.wikipedia.org/wiki/Template:Unichar
  http://en.wikipedia.org/wiki/User:Ruud_Koot/Unicode_typefaces
    In CSS:  .IPA, .Unicode { font-family: "Arial Unicode MS", "Lucida Sans Unicode"; }
  http://web.archive.org/web/20060913000000/http://en.wikipedia.org/wiki/Template:Unicode_fonts

Inspect which font is used by Firefox:

  https://addons.mozilla.org/en-US/firefox/addon/fontinfo/

Windows shortcuts:

  http://windows.microsoft.com/en-US/windows7/Keyboard-shortcuts
  http://www.redgage.com/blogs/pankajugale/all-keyboard-shortcuts--very-useful.html
  https://skydrive.live.com/?cid=2ee8d462a8f365a0&id=2EE8D462A8F365A0%21141
  http://windows.microsoft.com/en-us/windows-8/new-keyboard-shortcuts

On meaning of Unicode math codepoints

  https://en.wikipedia.org/wiki/Mathematical_Alphanumeric_Symbols
  http://milde.users.sourceforge.net/LUCR/Math/unimathsymbols.pdf
  http://milde.users.sourceforge.net/LUCR/Math/data/unimathsymbols.txt
  http://www.ams.org/STIX/bnb/stix-tbl.ascii-2006-10-20
  http://www.ams.org/STIX/bnb/stix-tbl.layout-2006-05-15
  http://mirrors.ibiblio.org/CTAN/macros/latex/contrib/unicode-math/unimath-symbols.pdf
  http://mirrors.ibiblio.org/CTAN//biblio/biber/documentation/utf8-macro-map.html
  http://tex.stackexchange.com/questions/14/how-to-look-up-a-symbol-or-identify-a-math-symbol-or-character
  http://unicode.org/Public/math/revision-09/MathClass-9.txt
  http://www.w3.org/TR/MathML/
  http://www.w3.org/TR/xml-entity-names/
  http://www.w3.org/TR/xml-entity-names/bycodes.html

Transliteration (via iconv [it is locale-dependent], example rules for Greek)

  http://sourceware.org/bugzilla/show_bug.cgi?id=12031

Monospaced fonts with combining marks (!)

  https://bugs.freedesktop.org/show_bug.cgi?id=18614
  https://bugs.freedesktop.org/show_bug.cgi?id=26941

Indic ISCII - any hope with it?  (This is not representable...:)

  http://unicode.org/mail-arch/unicode-ml/y2012-m09/0053.html

(Percieved) problems of Unicode (2001)

  http://www.ibm.com/developerworks/library/u-secret.html

On a need to have input methods for unicode

  http://unicode.org/mail-arch/unicode-ml/y2012-m07/0226.html

On info on Unicode chars

  http://unicode.org/mail-arch/unicode-ml/y2012-m07/0415.html 

Zapf dingbats encoding, and other fine points of AdobeGL:

  ftp://ftp.unicode.org/Public/MAPPINGS/VENDORS/ADOBE/zdingbat.txt
  http://web.archive.org/web/20001015040951/http://partners.adobe.com/asn/developer/typeforum/unicodegn.html

Yet another (IMO, silly) way to handle '; fight: ' vs ` ´

  http://www.cl.cam.ac.uk/~mgk25/ucs/apostrophe.html

Surrogate characters on IE

  HKEY_CURRENT_USER\Software\Microsoft\Internet Explorer\International\Scripts\42
  http://winvnkey.sourceforge.net/webhelp/surrogate_fonts.htm
  http://msdn.microsoft.com/en-us/library/aa918682.aspx				Script IDs

Quoting tchrist:
I<You can snag C<unichars>, C<uniprops>, and C<uninames> from L<http://training.perl.com> if you like.>

Tom's unicode scripts

  https://search.cpan.org/~bdfoy/Unicode-Tussle-1.03/lib/Unicode/Tussle.pm

=head2 F<.XCompose>: on docs and examples

Syntax of C<.XCompose> is (partially) documented in

  http://www.x.org/archive/current/doc/man/man5/Compose.5.xhtml
  http://cgit.freedesktop.org/xorg/lib/libX11/tree/man/Compose.man

 #   Modifiers are not documented
 #	 (Shift, Alt, Lock, Ctrl with aliases Meta, Caps [Alt/Meta binds Mod1];
 # 	 	 ! means that not mentioned supported modifiers must be off;
#		 None means that all recognizerd modifiers are off.)

Semantic (e.g., which of keybindings has a preference) is not documented.
Experiments (see below) show that a longer binding wins; if same
length, one which is loaded later wins (as far as they match exactly, both
the keys, and the set of required modifiers and their states).
Note that a given keypress may match several I<essentially different> lists of
modifier; one defined earlier wins.

For example, in

    ~Ctrl Shift <a>           : "a1"
    Shift ~Ctrl <a> <b>       : "ab1"
    ~Meta Shift <b>           : "b1"
    ~Ctrl ~Meta Shift <b> <a> : "ba1"
    Shift ~Meta <b>           : "b2"
    Shift ~Meta ~Lock <b>     : "b3"

there is no way to trigger the output C<"a1"> (since the next row captures
essentially the same keypress into a longer binding).  The only binding which
is explicitly overwritten is one for C<"b1">.  Hence pressing
C<Shift-b> would trigger the binding C<"b2">, and there is no way to trigger
the bindings for C<"b3"> and C<"ba1">.

 #      (the source of imLcPrs.c shows that the expansion of the
 #      shorter sequence is stored too - but the presence of
 #      ->succession means that the code to process the resulting
 #      tree ignores the expansion).

The interaction of C<.Compose> with
L<mandatory processing|http://www.x.org/releases/current/doc/kbproto/xkbproto.html#Transforming_the_KeySym_Associated_with_a_Key_Event>
of passed-through C<Control> and C<Lock> modifiers is not documented.

Before the syntax was documented: For the best approximation,
read the parser's code, e.g., google for

    inurl:compose.c XCompose
    site:cgit.freedesktop.org "XCompose"
    site:cgit.freedesktop.org "XCompose" filetype:c
    _XimParseStringFile

    http://cgit.freedesktop.org/xorg/lib/libX11/tree/modules/im/ximcp/imLcIm.c
    http://cgit.freedesktop.org/xorg/lib/libX11/tree/modules/im/ximcp/imLcPrs.c
    http://uim.googlecode.com/svn-history/r6111/trunk/gtk/compose.c
    http://uim.googlecode.com/svn/tags/uim-1.5.2/gtk/compose.c

The actual use of the compiled compose table:

 http://cgit.freedesktop.org/xorg/lib/libX11/tree/modules/im/ximcp/imLcFlt.c

Apparently, the first node (= defined last) in the tree which
matches keysym and modifiers is chosen.  So to override C<< <Foo> <Bar> >>,
looks like (checked to work!) C<< ~Ctrl <Foo> >> may be used...
On the other hand, defining both C<< <Foo> <Bar> <Baz> >> and (later) C<< <Foo> ~Ctrl <Bar> >>,
one would expect that C<< <Foo> <Ctrl-Bar> <Baz> >> should still trigger the
expansion of C<< <Foo> <Bar> <Baz> >> — but it does not...  See also:

  http://cgit.freedesktop.org/xorg/lib/libX11/tree/modules/im/ximcp/imLcLkup.c

The file F<.XCompose> is processed by X11 I<clients> on startup.  The changes
to this file should be seen immediately by all newly started clients
(but GTK or QT applications may need extra config - see below)
unless the directory F<~/.compose-cache> is present and has a cache
file compatible with binary architecture (then until cache
expires - one day after creation - changes are not seen).  The
name F<.XCompose> may be overriden by environment variable C<XCOMPOSEFILE>. 

To get (better?) examples, google for C<"multi_key" partial alpha "DOUBLE-STRUCK">.

  # include these first, so they may be overriden later
  include "%H/my-Compose/.XCompose-kragen"
  include "%H/my-Compose/.XCompose-ootync"
  include "%H/my-Compose/.XCompose-pSub"

Check success: kragen: C<\ space> --> ␣; ootync: C<o F> --> ℉; pSub: C<0 0> --> ∞ ...

Older versions of X11 do not understand %L %S. - but understand %H
    
E.g. Debian Squeeze 6.0.6; according to
      
   http://packages.debian.org/search?keywords=x11-common
    
it has C<v 1:7.5+8+squeeze1>).

   include "/etc/X11/locale/en_US.UTF-8/Compose"
   include "/usr/share/X11/locale/en_US.UTF-8/Compose"

Import default rules from the system Compose file:
usually as above (but supported only on newer systems):

   include "%L"

detect the success of the lines above: get C<#> by doing C<Compose + +> ...

The next file to include have been generated by

  perl -wlne 'next if /#\s+CIRCLED/; print if />\s+<.*>\s+<.*>\s+<.*/' /usr/share/X11/locale/en_US.UTF-8/Compose
  ### Std tables contain quadruple prefix for GREEK VOWELS and CIRCLED stuff
  ### only.  But there is a lot of triple prefix...  
  perl -wne 'next if /#\s+CIRCLED/; $s{$1}++ or print qq( $1) if />\s+<.*>\s+<.*>\s+<.*"(.*)"/' /usr/share/X11/locale/en_US.UTF-8/Compose
  ##  – — ☭ ª º Ǖ ǖ Ǘ ǘ Ǚ ǚ Ǜ ǜ Ǟ ǟ Ǡ ǡ Ǭ ǭ Ǻ ǻ Ǿ ǿ Ȫ ȫ Ȭ ȭ Ȱ ȱ ʰ ʱ ʲ ʳ ʴ ʵ ʶ ʷ ʸ ˠ ˡ ˢ ˣ ˤ ΐ ΰ Ḉ ḉ Ḕ ḕ Ḗ ḗ Ḝ ḝ Ḯ ḯ Ḹ ḹ Ṍ ṍ Ṏ ṏ Ṑ ṑ Ṓ ṓ Ṝ ṝ Ṥ ṥ Ṧ ṧ Ṩ ṩ Ṹ ṹ Ṻ ṻ Ấ ấ Ầ ầ Ẩ ẩ Ẫ ẫ Ậ ậ Ắ ắ Ằ ằ Ẳ ẳ Ẵ ẵ Ặ ặ Ế ế Ề ề Ể ể Ễ ễ Ệ ệ Ố ố Ồ ồ Ổ ổ Ỗ ỗ Ộ ộ Ớ ớ Ờ ờ Ở ở Ỡ ỡ Ợ ợ Ứ ứ Ừ ừ Ử ử Ữ ữ Ự ự ἂ ἃ ἄ ἅ ἆ ἇ Ἂ Ἃ Ἄ Ἅ Ἆ Ἇ ἒ ἓ ἔ ἕ Ἒ Ἓ Ἔ Ἕ ἢ ἣ ἤ ἥ ἦ ἧ Ἢ Ἣ Ἤ Ἥ Ἦ Ἧ ἲ ἳ ἴ ἵ ἶ ἷ Ἲ Ἳ Ἴ Ἵ Ἶ Ἷ ὂ ὃ ὄ ὅ Ὂ Ὃ Ὄ Ὅ ὒ ὓ ὔ ὕ ὖ ὗ Ὓ Ὕ Ὗ ὢ ὣ ὤ ὥ ὦ ὧ Ὢ Ὣ Ὤ Ὥ Ὦ Ὧ ᾀ ᾁ ᾂ ᾃ ᾄ ᾅ ᾆ ᾇ ᾈ ᾉ ᾊ ᾋ ᾌ ᾍ ᾎ ᾏ ᾐ ᾑ ᾒ ᾓ ᾔ ᾕ ᾖ ᾗ ᾘ ᾙ ᾚ ᾛ ᾜ ᾝ ᾞ ᾟ ᾠ ᾡ ᾢ ᾣ ᾤ ᾥ ᾦ ᾧ ᾨ ᾩ ᾪ ᾫ ᾬ ᾭ ᾮ ᾯ ᾲ ᾴ ᾷ ῂ ῄ ῇ ῒ ῗ ῢ ῧ ῲ ῴ ῷ ⁱ ⁿ ℠ ™ שּׁ שּׂ а̏ А̏ е̏ Е̏ и̏ И̏ о̏ О̏ у̏ У̏ р̏ Р̏ 🙌

The following exerpt from NEO compose tables may be good if you use
keyboards which do not generate dead keys, but may generate Cyrillic keys;
in other situations, edit filtering/naming on the following download
command and on the C<include> line below.  (For my taste, most bindings are
useless since they contain keysymbols which may be generated with NEO, but
not with less intimidating keylayouts.)

(Filtering may be important, since having a large file may
significantly slow down client's startup (without F<~/.compose-cache>???).) 

  # perl -wle 'foreach (qw(base cyrillic greek lang math)) {my @i=@ARGV; $i[-1] .= qq($_.module?format=txt); system @i}' wget -O - http://wiki.neo-layout.org/browser/Compose/src/ | perl -wlne 'print unless /<(U[\dA-F]{4,6}>|dead_|Greek_)/' >  .XCompose-neo-no-Udigits-no-dead-no-Greek
  include "%H/.XCompose-neo-no-Udigits-no-dead-no-Greek"
  # detect the success of the line above: get ♫ by doing Compose Compose (but this binding is overwritten later!)

  ###################################### Neo's Math contains junk at line 312

Print with something like (loading in a web browser after this):

  perl -l examples/filter-XCompose ~/.XCompose-neo-no-Udigits-no-dead-no-Greek > ! o-neo
  env LC_ALL=C sort -f o-neo | column -x -c 130 > ! /tmp/oo-neo-x

=head2 “Systematic” parts of rules in a few F<.XCompose>

        ================== .XCompose	b=bepo		o=ootync	k=kragen	p=pSub	s=std
        b	Double-Struck		b
        o	circled ops		b
        O	big circled ops		b
        r	rotated			b	8ACETUv  ∞

        -	sub			p
        =	double arrows		po
        g	greek			po
        m	math			p	|=Double-Struck		rest haphasard...
        O	circles			p	Oo
        S	stars			p	Ss
        ^	sup			p	added: i -
        |	daggers			p

        Double	mathop			ok	+*&|%8CNPQRZ AE

        #	thick-black arrows	o
        -,Num-	arrows			o
        N/N	fractions		o
        hH	pointing hands		o
        O	circled ops		o
        o	degree			o
        rR	roman nums		o
        \ UP	upper modifiers		o
        \ DN	lower modifiers		o
        {	set theoretic		o
        |	arrows |-->flavors	o
        UP /	roots			o
        LFT DN	6-quotes, bold delim	o
        RT DN	9-quotes, bold delim	o
        UP,DN	super,sub		o

        DOUBLE-separated-by-&	op	k	 ( ) 
        in-()	circled			k	xx for tensor
        in-[]	boxed, dice, play-cards	k
        BKSP after	revert		k
        < after		revert		k
        ` after		small-caps	k
        ' after 	hook		k
        , after 	hook below	k
        h after		phonetic	k

        #	musical			k
        %0	ROMAN			k	%_0 for two-digit
        %	roman			k	%_  for two-digit
        *	stars			k
        *.	var-greek		k
        *	greek			k
        ++, 3	triple			k
        +	double			k
        ,	quotes			k
        !, /	negate			k
        6,9	6,9-quotes		k
        N N	fractions		k
        =	double-arrows, RET	k
        CMP x2	long names		k
        f	hand, pencils 		k
        \	combining???		k
        ^	super, up modifier	k
        _	low modifiers		k
        |B, |W	chess, checkers, B&W	k
        |	double-struck		k
        ARROWS	ARROWS			k

        !	dot below		s
        "	diaeresis		s
        '	acute			s
        trail <	left delimiter		s
        trail >	right delimiter		s
        trail \ slanted variant		s
        ( ... )	circled			s
        (	greek aspirations	s
        )	greek aspirations	s
        +	horn			s
        ,	cedilla			s
        .	dot above		s
        -	hor. bar		s
        /	diag, vert hor. bar	s
        ;	ogonek			s
        =	double hor.bar, ₤₦€¥≠	s
        trail =	double hor.bar		s
        ?	hook above		s
        b	breve			s
        c	check above		s
        iota	iota below		s
        trail 0338	negated		s
        o	ring above		s
        U	breve			s
                        SOME HEBREW
        ^	circumflex		s
        ^ _	superscript		s
        ^ undbr	superscript		s
        _	bar			s
        _	subscript		s
        underbr	subscript		s
        `	grave			s
        ~	greek dieresis		s
        ~	tilde			s
        overbar	bar			s
        ´	acute			s	´ is not '
        ¸	cedilla			s	¸ is cedilla

=head1 LIMITATIONS

For the keyboards with non-US mapping of hardware keys to "the etched
symbols", one should use the C<VK> section to describe the mapping of the
C<VK_>-codes to scancodes.  (Recall that on German physical keyboards the Y/Z keycaps
are swapped: Z is etched between T and U, and Y is to the left of X.  French
keyboards swap A and Q as well as W and Z.   Moreover, French or Russian physical
keyboards have more alphabetical keys than 26.)

While the architecture of assembling a keyboard of small easy-to-describe
pieces is (IMO) elegant and very powerful, and is proven to be useful, it 
still looks like a collection of independent hacks.  Many of these hacks
look quite similar; it would be great to find a way to unify them, so 
reduce the repertoir of operations for assembly.

The current documentation of the module’s functionality is not fully complete.

The implementation of the module is crumbling under its weight.  Its 
evolution was by bloating (even when some design features were simplified).
Since initially I had very little clue to which level of abstraction and 
flexibility the keyboard description would evolve, bloating accumulated 
to incredible amounts.

=head1 COPYRIGHT

Copyright (c) 2011-2024 Ilya Zakharevich <ilyaz@cpan.org>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.0 or,
at your option, any later version of Perl 5 you may have available.

The distributed examples may have their own copyrights.

=head1 TODO

The content of this section is most probably completely obsolete.  The newer list is in the
L<dedicated TODO file|https://metacpan.org/dist/UI-KeyboardLayout/source/TODO>.  We mark obvious GOTCHAS which are NOTFIX by OK.

“UniPolyK-MultiSymple”

“designated Primary- and Secondary- switch keys” (as Shift-Space and AltGr-Space now).

OK: C<Soft hyphen> as a deadkey may be not a good idea: following it by a special key
(such as C<Shift-Tab>, or C<Control-Enter>) may insert the deadkey character???
Hence the character should be highly visible... (Now the key is invisible,
so this is irrelevant for characters from the main layer...)

Currently linked layers must have exactly the same number of keys in VK-tables.

VK tables for TAB, BACK were BS.  Same (remains) for the rest of unusual keys...  (See TAB-was.)
But UTOOL cannot handle them anyway...  (We do not generate them now…)

Define an extra element in VK keys: linkable.  Should be sorted first in the kbd map,
and there should be the same number in linked lists.  Non-linkable keys should not
be linked together by deadkey access...

OK: Interaction of FromToFlipShift with SelectRX not intuitive.  This works: Diacritic[<sub>](SelectRX[[0-9]](FlipShift(Face(Latin))))

OK: FlipShift is not reliable without an explicit argument (when used with multiple-personalities???  Since accesses a possibly scant
non-Full face???)

DefinedTo cannot be put on Cyrillic 3a9 (yo to superscript disappears - due to duplication???).

... so we do it differently now, but: LinkLayer was not aggressively resolving all the occurences of a character on a layer
before we started to combine it with Diacritic_if_undef...  - and Cyrillic 3a9 is not helped...

via_parent() is broken - cannot replace for Diacritic_if_undef.

Currently, we map ephigraphic letters to capital letters - is it intuitive???

DeadKey_Map200A=	FlipLayers
#DeadKey_Map200A_0=	Id(Russian-AltGr)
#DeadKey_Map200A_1=	Id(Russian)
  performs differently from the commented variant: it adds links to auto-filled keys...

Why ¨ on THIN SPACE inserts OGONEK after making ¨ multifaceted???

When splitting a name on OVER/BELOW/ABOVE, we need both sides as modifiers???

OK: Ỳ currently unreachable via AltGr (appears only in Latin-8 Celtic, is not on Wikipedia)

We decompose reversed-smallcaps in one step - probably better add yet another two-steps variant...

We do not do canonical-merging of diacritics; so one needs to specify VARIA in addition to GRAVE ACCENT.

OK: Inspector tool for NamesList.txt:

 grep " WITH .* " ! | grep -E -v "(ACUTE|GRAVE|ABOVE|BELOW|TILDE|DIAERESIS|DOT|HOOK|LEG|MACRON|BREVE|CARON|STROKE|TAIL|TONOS|BAR|DOTS|ACCENT|HALF RING|VARIA|OXIA|PERISPOMENI|YPOGEGRAMMENI|PROSGEGRAMMENI|OVERLAY|(TIP|BARB|CORNER) ([A-Z]+WARDS|UP|DOWN|RIGHT|LEFT))$" | grep -E -v "((ISOLATED|MEDIAL|FINAL|INITIAL) FORM|SIGN|SYMBOL)$" |less
 grep " WITH "    ! | grep -E -v "(ACUTE|GRAVE|ABOVE|BELOW|TILDE|DIAERESIS|CIRCUMFLEX|CEDILLA|OGONEK|DOT|HOOK|LEG|MACRON|BREVE|CARON|STROKE|TAIL|TONOS|BAR|CURL|BELT|HORN|DOTS|LOOP|ACCENT|RING|TICK|HALF RING|COMMA|FLOURISH|TITLO|UPTURN|DESCENDER|VRACHY|QUILL|BASE|ARC|CHECK|STRIKETHROUGH|NOTCH|CIRCLE|VARIA|OXIA|PSILI|DASIA|DIALYTIKA|PERISPOMENI|YPOGEGRAMMENI|PROSGEGRAMMENI|OVERLAY|(TIP|BARB|CORNER) ([A-Z]+WARDS|UP|DOWN|RIGHT|LEFT))$" | grep -E -v "((ISOLATED|MEDIAL|FINAL|INITIAL) FORM|SIGN|SYMBOL)$" |less

AltGrMap should be made CapsLock aware (impossible: smart capslock works only on the first layer, so
the dead char must be on the first layer).  [May work for Shift-Space - but it has a bag of problems...]

Alas, CapsLock'ing a composition cannot be made stepwise.  Hence one must calculate it directly.
(Oups, Windows CapsLock is not configurable on AltGr-layer.  One may need to convert
it to VK_KANA???)

WarnConflicts[exceptions] and NoConflicts translation map parsing rules.

Need a way to map to a different face, not a different layer.

Vietnamese: to put second accent over ă, ơ (o/horn), put them “over the C<AltGr> forms æ/œ”; - including 
another ˘ which would "cancel the implied one", so will get o-horn itself.  - Except
for acute accent which should replaced by ¨, and hook must be replaced by ˆ.  (Over æ/œ
there is only macron ǣ and acute ǽ over æ — although there are turned-œ with bar and stroke ꭁ and ꭂ.)

(Vietnamese input in described in L<F<Changes>|https://metacpan.org/dist/UI-KeyboardLayout/source/Changes#L635>; see the part for
C<v0.09>.)

Or: for the purpose of taking a second accent, AltGr-A behaves as Ă (or Â?), AltGr-O 
behaves as Ô (or O-horn Ơ?).  Then Å and O/ behave as the other one...  And ˚ puts the
dot *below*, macron puts a hook.  Exception: ¨ acts as ´ on the unaltered AE.

  While Å takes acute accent, one can always input it via putting ˚ on Á.

If Ê is on the keyboard (and macron puts a hook), then the only problem is how to enter
a hook alone (double circumflex is not precombined), dot below (???), and accents on u-horn ư.

Mogrification rules for double accents: AE Å OE O/ Ù mogrify into hatted/horned versions; macron
mogrifies into a hook; second hat modifies a hat into a horn.  The only problem: one won't be 
able to enter double grave on U - use the OTHER combination of ¨ and `...  And how to enter
dot below on non-accented aue?  Put ¨ on umlaut? What about Ë?

To allow . or , on VK_DECIMAL: maybe make CapsLock-dependent?

  http://blogs.msdn.com/b/michkap/archive/2006/09/13/752377.aspx

How to write this diacritic recipe: insert hacheck on AltGr-variant, but only if
the breve on the base layer variant does not insert hacheck (so inserts breve)???

Sorting diacritics by usefulness: we want to apply one of accents from the
given list to a given key (with l layers of 2 shift states).  For each accent,
we have 2l possible variants for composition; assign to 2 variants differing
by Shift the minimum penalty of the two.  For each layer we get several possible
combinations of different priority; and for each layer, we have a certain number
of slots open.  We can redistribute combinations from the primary layer to
secondary one, but not between secondary layers.

Work with slots one-by-one (so that the assignent is "monotinic" when the number
of slots increases).  Let m be the number of layers where slots are present.
Take highest priority combinations; if the number of "extra" combinations
in the primary layer is at least m, distribute the first m of them to
secondary layers.  If n<m of them are present, fill k layers which
have no their own combinations first, then other n-k layers.  More precisely,
if n<=k, use the first n of "free" layers; if n>k, fill all free layers, then
the last n-k of non-free layers.

Repeat as needed (on each step, at most one slot in each layer appears).

But we do not need to separate case-differing keys!  How to fix?

All done, but this works only on the current face!  To fix, need to pass
to the translator all the face-characters present on the given key simultaneously.

  ===== Accent-key TAB accesses extra bindinges (including NUM->numbered one)
	(may be problematic with some applications???
	 -- so duplicate it on + and @ if they is not occupied
	 -- there is nothing related to AT in Unicode)

Diacritics_0218_0b56_0c34=	May create such a thing...
 (0b56_0c34 invisible to the user).

  Hmm - how to combine penaltized keys with reversion?  It looks like
  the higher priority bindings would occupy the hottest slots in both
  direct and reverse bindings...

  Maybe additional forms Diacrtitics2S_* and Diacrtitics2E_* which fight
  for symbols of the same penalty from start and from end (with S winning
  on stuff exactly in the middle...).  (The E-form would also strip the last |-group.)

' Shift-Space (from US face) should access the second level of Russian face.
To avoid infinite cycles, face-switch keys to non-private faces should be
marked in each face... 

"Acute makes sharper" is applicable to () too to get <>-parens...  But now they are on Green — maybe can replace???

Another ways of combining: "OR EQUAL TO", "OR EQUIVALENT TO", "APL FUNCTIONAL
SYMBOL QUAD", "APL FUNCTIONAL SYMBOL *** UNDERBAR", "APL FUNCTIONAL SYMBOL *** DIAERESIS".

When recognizing symbols for GREEK, treat LUNATE (as NOP).  Try adding HEBREW LETTER at start as well...

Compare with: 8 basic accents: http://en.wikipedia.org/wiki/African_reference_alphabet (English 78)

When a diacritic on a base letter expands to several variants, use them all 
(with penalty according to the flags).

Problem: acute on acute makes double acute modifier...


 ╼†━†╾†╺†╸†╶†─†╴†╌†┄†┈† †╍†┅†┉†
 ╼━╾╺╸╶─╴╌┄┈ ╍┅┉
 ╻
 ┃
 ╹
 ╷
 │
 ╵
 
 ╽
 ╿
 ╎┆┊╏┇┋



=head2 Implementation details: C<FullFace(FNAME)>

Since the C<FullFace(FNAME)> accessor may have different effects at different moment of
a face C<FNAME> synthesis, here is the order in which C<FullFace(FNAME)> changes (we also
mention how to access the results from these steps from Perl code):

  ini_layers:   essentially, contains what is given in the key “layers” of the face recipe
	Later, a version of these layers with exportable keys marked is created as ini_layers_prefix.
  ini_filled_layers: adds extra (fake) keys containing control characters and created via-VK-keys
	  (For these extended layers, the previous version can be inspected via ini_copy1.)
	(created when exportable keys are handled.)

The next modification is done not by modifying the list of names of layers
associated to the face, but by editing the corresponding layers in place.
(The unmodified version of layer, one containing the exportable keys, is
accessible via C<ini_copy>.)  On this step one adds the missing characters
from the face specified in the C<LinkFace> key.

=cut

# '
my (%Globals, $DEBUG);

sub set__value ($$$) {
    my($class, $key) = (shift, shift);
    (ref $class ? $class->{$key} : $Globals{$key}) = shift;
}
sub get__value ($$) {
    my($class, $key) = (shift, shift);
    if (ref $class and defined(my $v = $class->{$key})) {
      $v;
    } else {
      $Globals{$key};
    }
}
sub set_NamesList ($$;$) {
    my $class = shift;
    set__value($class, 'NamesList', shift);
    set__value($class, 'AgeList',   shift);
}
sub get_NamesList ($) {  get__value(shift, 'NamesList')  }
sub get_AgeList ($)   {  get__value(shift, 'AgeList')  }

sub new ($;$) {
    my $class = shift;
    die "too many arguments to UI::KeyboardLayout->new" if @_ > 1;
    my $data = @_ ? {%{shift()}} : {};
    bless $data, (ref $class or $class);
}

sub put_deep($$$$@) {
  my($self, $hash, $v, $k) = (shift, shift, shift, shift);
  return $self->put_deep($hash->{$k} ||= {}, $v, @_) if @_;
  $hash->{$k} = $v;
}

# Sections [foo/bar] [visual -> foo/bar]; directives foo=bar or @foo=bar,baz
#    actually: parses configfile string, not file
sub parse_configfile ($$) {		# Trailing whitespace is ignored, whitespace about "=" is not
  my ($self, $s) = (shift, shift);
  $self->parse_add_configstring($s, {});
}

sub parse_add_configstring ($$$) {		# Trailing whitespace is ignored, whitespace about "=" is not
  my ($self, $s, $vv, @KEYS) = (shift, shift, shift);
  $s =~ s/[^\S\n]+$//gm;
  $s =~ s/^\x{FEFF}//;			# BOM are not stripped by Perl from UTF-8 files with -C31
  (my $pre, my %f) =  split m(^\[((?:visual\s*->\s*)?[\w/]*)\]\s*$ \n?)mx, $s;	# //x is needed to avoid $\
  warn "Part before the first section in configfile ignored: `$pre'" if length $pre;
  for my $k (sort keys %f) {
# warn "Section `$k'";
    my($v, $V, @V) = $f{$k};
    if ($k =~ s{^visual\s*->\s*}{[unparsed]/}) {		# Make sure that prefixes do not allow visual line to be confused with a config
      $v =~ s[(^(?!#|[/\@+]?\w+=).*)]//ms;			# find non-comment non-assignment
      @V = "unparsed_data=$1";
    }
# warn "xxx: @V";
    push @KEYS, $k;
    my @k = split m(/), $k;
    @k = () if "@k" eq '';				# root
    for my $l ((grep !/^#/, split(/\n/, $v)), @V) {
      die "unrecognized config file line: `$l' in `$s'"
        unless my($arr, $at, $slash, $kk, $vvv) = ($l =~ m[^((?:(\@)|(/)|\+)?)(\w+)=(.*)]s);
      my $spl = $at ? qr/,/ : ( $slash ? qr[/] : qr[(?!)] );
      $vvv = [ length $vvv ? (split $spl, $vvv, -1) : $vvv ] if $arr;	# create empty element if $vvv is empty
      my $slot = $self->get_deep($vv, @k);
      if ($slot and exists $slot->{$kk}) {
        if ($arr) {
          if (ref($slot->{$kk} || 0) eq 'ARRAY') {
            $vvv = [@{$slot->{$kk}}, @$vvv];
          } else {
            warn "Redefinition of non-array entry `$kk' in `$k' by array one, old value ignored"
          }
        } else {
          warn "Redefinition of entry `$kk' in `$k', old value ignored"
        }
      }
# warn "Putting to the root->@k->`$kk'";
      $self->put_deep($vv, $vvv, @k, $kk);
    }
  }
  $vv->{'[keys]'} = \@KEYS;
# warn "config parsed";
  $vv
}

sub merge_configstrings ($$@) {		# Trailing whitespace is ignored, whitespace about "=" is not
  my ($self, $overwrite) = (shift, shift);
  for my $s (@_) {
    my $data = {};
    $self->parse_add_configstring($s, $data);	# consolidate arrays into $data
    $self->merge_hash($data, $self, $overwrite);
  }
  $self
}

sub merge_confighash ($$@) {		# Trailing whitespace is ignored, whitespace about "=" is not
  my ($self, $overwrite) = (shift, shift);
  for my $data (@_) {
    $self->merge_hash($data, $self, $overwrite);
  }
  $self
}

sub merge_hash ($$$$) {
  my ($self, $from, $to, $overwrite) = (shift, shift, shift, shift);
  for my $k (keys %$from) {
    my $old = (exists $to->{k} ? ref($to->{k}) : '-');
    if ($old eq 'HASH') {
      die "Merging non-HASH subentry into a HASH" unless 'HASH' eq ref($from->{$k});
      $self->merge_hash($from->{$k}, $to->{$k}, $overwrite);
    } elsif ($old ne '-' and not $overwrite) {	# Do nothing
    } elsif (ref $from->{$k} eq 'HASH') {
      die "Merging HASH subentry into a non-HASH";
    } else {
      $to->{$k} = $from->{$k};
    }
  }
  $self
}


sub process_key_chunk ($$$$$) {
  my $self = shift;
  my $name = shift;
  my $skip_first = shift;
  (my $k = shift) =~ s/\p{Blank}(?=\p{NonspacingMark})//g;	# Allow combining marks to be on top of SPACE
  my $sep2 = shift;
  $k = $self->stringHEX2string($k);
  my @k = split //, $k;
  if (defined $sep2 and 3 <= @k and $k =~ /$sep2/) {		# Allow separation by $sep2, but only if too long
    @k = split /$sep2/, $k;
    shift @k if not length $k[0] and @k == 2;
    warn "Zero length expansion in the key slot <$k>\n" if not @k or grep !length, @k;
  }
  undef $k[0] if ($k[0] || '') eq "\0" and $skip_first;
  push @k, ucfirst $k[0] if @k == 1 and defined $k[0] and 1==length $k[0] and $k[0] ne ucfirst $k[0];
  $name = "VisLr=$name" if $name;
#  warn "Multi-char key in <<@k>>" if grep $_ && 1<length, @k;
  warn "More that 2 Shift-states in <<@k>>" if @k > 2;
#warn "Sep2 in $name, $skip_first, <$k> ==> <@k>\n" if defined $sep2 and $k =~ /$sep2/;
  map {defined() ? [$_, undef, undef, $name] : $_} @k;
#  @k
}	# -> list of chars

sub process_key ($$$$$$;$) {		# $sep may appear only in a beginning of the first key chunk
  my ($self, $k, $limit, $sep, $ln, $l_off, $sep2, @tr)  = (shift, shift, shift, shift, shift, shift, shift);
  my @k = split m((?!^)\Q$sep), $k;
  die "Key descriptor `$k' separated by `$sep' has too many parts: expected $limit, got ", scalar @k
    if @k > $limit;
  defined $k[$_] and $k[$_] =~ s/^--(?=.)/\0/ and $tr[$_]++ for 0..$#k;
  $k[0] = '' if $k[0] eq '--';		# Allow a filler (multi)-chunk
  map [$self->process_key_chunk( $ln->[$l_off+$_], $tr[$_], (defined($k[$_]) ? $k[$_] : ''), $sep2)], 0..$#k;
}	# -> list of arrays of chars

sub decode_kbd_layers ($@) {
  my ($self, $lineN, $row, $line_in_row, $cur_layer, @out, $N, $l0) = (shift, 0, -1);
  my %needed = qw(unparsed_data x visual_rowcount 2 visual_per_row_counts [2;2] visual_prefixes * prefix_repeat 3 in_key_separator / layer_names ???);
  my %extra  = (qw(keyline_offsets 1 in_key_separator2), undef);
  my $opt;
  for my $k (keys %needed, keys %extra) {
     my ($from) = grep exists $_->{$k}, @_, (ref $self ? $self : ());
     die "option `$k' not specified" unless $from or exists $extra{$k};
     $opt->{$k} = $from->{$k};
  }
  die "option `visual_rowcount' differs from length of `visual_per_row_counts': $opt->{visual_rowcount} vs. ", 
      scalar @{$opt->{visual_per_row_counts}} unless $opt->{visual_rowcount} == @{$opt->{visual_per_row_counts}};
  my @lines = grep !/^#/, split /\s*\n/, $opt->{unparsed_data};
  my ($C, $lc, $pref) = map $opt->{$_}, qw(visual_rowcount visual_per_row_counts visual_prefixes);
  die "Number of uncommented rows (" . scalar @lines . ") in a visual template not divisible by the rowcount $C: `$opt->{unparsed_data}'"
    if @lines % $C;
  $pref = [map {$_ eq ' ' ? qr/\s/ : qr/\Q$_/ } split(//, $pref), (' ') x $C];
#  my $line_in_row = [];
  my @counts;
  my $sep2;
  $sep2 = qr/$opt->{in_key_separator2}/ if defined $opt->{in_key_separator2};
  while (@lines) {
#    push @out, $line_in_row = [] unless $C % $c;
    $row++, $line_in_row = $cur_layer = 0 unless $lineN % $C;
    $lineN++;
    my $l1 = shift @lines;
    my $PREF = qr/(?:$pref->[$line_in_row]){$opt->{prefix_repeat}}/;
    $PREF = '\s' if $pref->[$line_in_row] eq qr/\s/;
    $l1 =~ s/\s*\x{202c}$// if $l1 =~ s/^[\x{202d}\x{202e}]//;			# remove PDF if removed LRO, RLO
    die "line $lineN in visual layers has unexpected prefix:\n\tPREF=/$PREF/\n\tLINE=`$l1'"  unless $l1 =~ s/^$PREF\s*(?<=\s)//;
    my @k1 = split /\s+(?!\p{NonspacingMark})/, $l1;
    $l0 = $l1, $N = @k1 if $line_in_row == 0;
# warn "Got keys: ", scalar @k1;
    die sprintf "number of keys in lines differ: %s vs %s in:\n\t`%s'\n\t`%s'\n\t<%s>",
      scalar @k1, $N, $l0, $l1, join(">\t<", @k1) unless @k1 == $N;		# One can always fill by --
    for my $key (@k1) {
      my @kk = $self->process_key($key, $lc->[$line_in_row], $opt->{in_key_separator}, $opt->{layer_names}, $cur_layer, $sep2);
      push @{$out[$cur_layer + $_]}, $kk[$_] || [] # (defined $kk[$_] ? [$kk[$_],undef,undef,$opt->{layer_names}[$cur_layer + $_]] : []) 
        for 0..($lc->[$line_in_row]-1);
    }
    $cur_layer += $lc->[$line_in_row++];
    push @counts, scalar @k1 if 1 == $lineN % $C;
  }
# warn "layer[0] = ", join ', ', map "@$_", @{$out[0]};
  die "Got ", scalar @out, " layers, but ", scalar @{$opt->{layer_names}}, " layer names"
    unless @out == @{$opt->{layer_names}};
  my(%seen, %out);
  $seen{$_}++ and die "Duplicate layer name `$_'" for @{$opt->{layer_names}};
  @out{ @{$opt->{layer_names}} } = @out;
  for my $i ( 0 .. ($#{ $opt->{layer_names} } - 1) ) {
    my($base,$shift) = ($out[$i], $out[$i+1]);
    $out{$opt->{layer_names}[$i] . '²'} ||= [ map [$base->[$_][0], $shift->[$_][0]], 0..$#$base ];  # ²: Layer, and the next “as shifted”
    next if $i > $#{ $opt->{layer_names} } - 3;
    ($base,$shift) = ($out[$i+2], $out[$i+3]);
    $out{$opt->{layer_names}[$i] . '²⁺'} ||= [ map [$base->[$_][0], $shift->[$_][0]], 0..$#$base ]; # ²⁺: two next layers (likewise)
###	warn "Created ² etc appended-names for layer $opt->{layer_names}[$i]";
  }
  my $ii = 0;
  if (0) {		# Cannot do this: the subdivision into rows is not preserved by the parser! ???
  for my $pre_row ( 0 .. @{ $opt->{rect_horizontal_counts} } - 2) {
    my $C = $opt->{rect_horizontal_counts}[$pre_row];
    for my $iii ( 0 .. $C - 1) {
      my $I = $ii + $iii;
      my $i = $I + $C;
      next if $i > $#{ $opt->{layer_names} };		# Next row may be shorter
      my($base,$shift) = ($out[$i], $out[$i+1]);
      $out{$opt->{layer_names}[$I] . '₁'} ||= [ map [$base->[$_][0]], 0..$#$base ];  # In the next row listing layer-names
      next if $i > $#{ $opt->{layer_names} } - 1;
      $out{$opt->{layer_names}[$I] . '₂'} ||= [ map [$base->[$_][0], $shift->[$_][0]], 0..$#$base ];  # As ² but in the next row
      next if $i > $#{ $opt->{layer_names} } - 3;
      ($base,$shift) = ($out[$i+2], $out[$i+3]);
      $out{$opt->{layer_names}[$I] . '₂₊'} ||= [ map [$base->[$_][0], $shift->[$_][0]], 0..$#$base ];  # As ²⁺ but in the next row
    }
    $ii += $C;
  }}
  \%out, \@counts, $opt->{keyline_offsets};
}

sub decode_rect_layers ($@) {
  my ($self, $cnt, %extra, $opt, @out) = (shift, 0, qw(empty N/A));
  my %needed = qw(unparsed_data x rect_rows_cols [4;4] rect_horizontal_counts [2;2] layer_names ??? COLgap 0 ROWgap 0);
  for my $k (keys %needed, keys %extra) {
     my ($from) = grep exists $_->{$k}, @_, (ref $self ? $self : ());
     die "option `$k' not specified" unless $from or exists $extra{$k};
     $opt->{$k} = $from->{$k};
  }
  $cnt += $_ for @{ $opt->{rect_horizontal_counts} };
  die "total of option `rect_horizontal_counts' differs from count of `layer_names': $cnt vs. ", 
      scalar @{$opt->{layer_names}} unless $cnt == @{$opt->{layer_names}};
  $cnt = @{ $opt->{rect_horizontal_counts} };
  (my $D = $opt->{unparsed_data}) =~ s/^(#.*\n)+//;
  $D =~ s/^(#.*(\n|\z))+\z//m;
  my @lines = split /\s*\n/, $D;
  my ($C, $lc, $pref, $c0, $r0) = map $opt->{$_}, qw(visual_rowcount visual_per_row_counts visual_prefixes COLgap ROWgap);
  die "Number of uncommented rows (" . scalar @lines . ") in a visual rect template not matching rows(rect_rows_cols) x cnt(rect_horizontal_counts) = $opt->{rect_rows_cols}[0] x $cnt: `$opt->{unparsed_data}'"
    if @lines != $cnt * $opt->{rect_rows_cols}[0] + ($cnt-1)*$r0;
  my $c = 0;
  while (@lines) {
    die "Too many rect vertically: expect only ", scalar @{ $opt->{rect_horizontal_counts} }, " in `" . join("\n",'',@lines,'') . "'"
      if $c >= @{ $opt->{rect_horizontal_counts} };
    my @L = splice @lines, 0, $opt->{rect_rows_cols}[0];
    my ($cR, $L) = 0;
    while (++$cR <= $r0) {		# Inter-row gap
      last unless @lines;
      ($L = shift @lines) =~ /^#/ or die "Line expected to be inter-row comment line No. $cR: <<<$L>>>"
    }
    my $l = length $L[0];
    $l == length or die "Lengths of lines encoding rect do not match: expect $l, got `" . join("\n",'',@L,'') . "'" for @L[1..$#L];
    $l == $opt->{rect_rows_cols}[1] * $opt->{rect_horizontal_counts}[$c] + ($opt->{rect_horizontal_counts}[$c] - 1)*$c0
      or die "Wrong line length in rect: expect $opt->{rect_rows_cols}[1] * $opt->{rect_horizontal_counts}[$c] gaps=$c0, got $l in `" 
      	. join("\n",'',@L,'') . "'" for @L[1..$#L];
    while (length $L[0]) {
      my @c;
      push @c, split //, substr $_, 0, $opt->{rect_rows_cols}[1], '' for @L;
      $_ eq $opt->{empty} and $_ = undef for @c;
      push @out, [map [$_], @c];
      next unless $c0 and length $L[0];	# Inter-col gap
      for my $i (0..$#L) {
        next unless (my $gap = substr $L[$i], 0, $c0, '') =~ /\S/;
        die "Inter-column gap not whitespace: line No. $i (0-based), gap No. $#out: <<<$gap>>>"
      }
    }
    $c++;
  }
  die "Too few vertical rect: got $c, expect ", scalar @{ $opt->{rect_horizontal_counts} }, " in `" . join("\n",'',@lines,'') . "'"
    if $c != @{ $opt->{rect_horizontal_counts} };
  my(%seen, %out);
  $seen{$_}++ and die "Duplicate layer name `$_'" for @{$opt->{layer_names}};
  @out{ @{$opt->{layer_names}} } = @out;
  for my $i ( 0 .. ($#{ $opt->{layer_names} } - 1) ) {
    my($base,$shift) = ($out[$i], $out[$i+1]);
    $out{$opt->{layer_names}[$i] . '²'} ||= [ map [$base->[$_][0], $shift->[$_][0]], 0..$#$base ];  # ²: Layer, and the next “as shifted”
    next if $i > $#{ $opt->{layer_names} } - 3;
    ($base,$shift) = ($out[$i+2], $out[$i+3]);
    $out{$opt->{layer_names}[$i] . '²⁺'} ||= [ map [$base->[$_][0], $shift->[$_][0]], 0..$#$base ]; # ²⁺: two next layers (likewise)
###	warn "Created ² etc appended-names for rect layer $opt->{layer_names}[$i]";
  }
  my $ii = 0;
  for my $pre_row ( 0 .. @{ $opt->{rect_horizontal_counts} } - 2) {
    my $C = $opt->{rect_horizontal_counts}[$pre_row];
    for my $iii ( 0 .. $C - 1) {
      my $I = $ii + $iii;
      my $i = $I + $C;
      next if $i > $#{ $opt->{layer_names} };		# Next row may be shorter
      my($base,$shift) = ($out[$i], $out[$i+1]);
      $out{$opt->{layer_names}[$I] . '₁'} ||= [ map [$base->[$_][0]], 0..$#$base ];  # In the next row listing layer-names
      next if $i > $#{ $opt->{layer_names} } - 1;
      $out{$opt->{layer_names}[$I] . '₂'} ||= [ map [$base->[$_][0], $shift->[$_][0]], 0..$#$base ];  # As ² but in the next row
      next if $i > $#{ $opt->{layer_names} } - 3;
      ($base,$shift) = ($out[$i+2], $out[$i+3]);
      $out{$opt->{layer_names}[$I] . '₂₊'} ||= [ map [$base->[$_][0], $shift->[$_][0]], 0..$#$base ];  # As ²⁺ but in the next row
    }
    $ii += $C;
  }
  \%out, [($opt->{rect_rows_cols}[1]) x $opt->{rect_rows_cols}[0]];
}

sub get_deep ($$@) {
  my($self, $h) = (shift, shift);
  return $h unless @_;
  my $k = shift @_;
  return unless exists $h->{$k};
  $self->get_deep($h->{$k}, @_);
}

sub get_deep_via_parents ($$$@) {	# quadratic algorithm
  my($self, $h, $idx, $IDX) = (shift, shift, shift);
#warn "Deep: `@_'";
  ((defined $h) ? return $h : return) unless @_;
  my $k = pop @_;
  {
#warn "Deep::: `@_'";
    my $H = $self->get_deep($h, @_);
    (@_ or return), $IDX++, 			# Start extraction from array
      pop, redo unless exists $H->{$k};
    my $v = $H->{$k};
#warn "Deep -> `$v'";
    return $v unless ref($v || 1) and $IDX and defined $idx;
    return $v->[$idx];
  }
  return;
}

sub fill_kbd_layers ($$) {			# We do not do deep processing here...
  my($self, $h, %o, %c, %O) = (shift, shift);
  my @K = grep m(^\[unparsed]/(KBD|RECT)\b), @{$h->{'[keys]'}};
#  my $H = $h->{'[unparsed]'};
  for my $k (@K) {
    my (@parts, @h) = split m(/), $k;
    ref $self and push @h, $self->get_deep($self, @parts[1..$_]) || {} for 0..$#parts;
    push @h, $self->get_deep($h, @parts[1..$_]) || {} for 0..$#parts;		# Drop [unparsed]/ prefix...
    push @h, $self->get_deep($h,    @parts[0..$_]) || {} for -1..$#parts;
    my ($in, $counts, $offsets) = ($k =~ m(^\[unparsed]/KBD\b) ? $self->decode_kbd_layers( reverse @h )
    							       : $self->decode_rect_layers( reverse @h ) );
    exists $o{$_} and die "Visual spec `$k' overwrites exiting layer `$k'" for keys %$in;
    my $cnt = (@o{keys %$in} = values %$in);
    @c{keys %$in} = ($counts)  x $cnt;
    @O{keys %$in} = ($offsets) x $cnt if $offsets;
  }
  \%o, \%c, \%O
}

sub key2hex ($$;$) {
  my ($self, $k, $ignore) = (shift, shift, shift);
  return -1 if $ignore and not defined $k;
  return sprintf '%04x', ord $k;		# if ord $k <= 0xFFFF;
#  sprintf '%06x', ord $k;
}

sub keyORarray2hex ($$;$) {
  my ($self, $k, $ignore) = (shift, shift, shift);
  return -1 if $ignore and not defined $k;
  $k = $k->[0] if $k and ref $k;
  $self->key2hex($k, $ignore);
}

sub keys2hex ($$;$) {
  my ($self, $k, $ignore) = (shift, shift, shift);
  return -1 if $ignore and not defined $k;
  return join '.', map {sprintf '%04x', ord} split //, $k;		# if ord $k <= 0xFFFF;
#  sprintf '%06x', ord $k;
}

sub coverage_hex_sub($$$) {	# Unfinished!!! XXXX  UNUSED
  my ($self, $layer, $to) = (shift, shift, shift);
  ++$to->{ $self->key2hex($_->[0], 'undef_ok') }, ++$to->{ $self->key2hex($_->[1], 'undef_ok') } 
    for @{$self->{layers}{$layer}};
}

# my %MANUAL_MAP = qw( 0020 0020 00a0 00a0 2007 2007 );	# We insert entry for SPACE manually
# my %MANUAL_MAP_ch = map chr hex, %MANUAL_MAP;

sub coverage_hex($$) {
  my ($self, $face) = (shift, shift);
  my $layers = $self->{faces}{$face}{layers};
  my $to = ($self->{faces}{$face}{'[coverage_hex]'} ||= {});	# or die "Panic!";	# Synthetic faces may not have this...
  my @Layers = map $self->{layers}{$_}, @$layers;
  for my $sub (@Layers) {
    ++$to->{ $self->keyORarray2hex($_, 'undef_ok') } for map +(@$_[0,1]), @$sub;
  }
}

sub deep_copy($$) {
  my ($self, $o) = (shift, shift);
  return $o unless ref $o;
  return [map $self->deep_copy($_), @$o] if "$o" =~ /^ARRAY\(/;	# We should not have overloaded elements
  return {map $self->deep_copy($_), %$o} if "$o" =~ /^HASH\(/;
}
sub DEEP_COPY($@) {
  my ($self) = (shift);
  map $self->deep_copy($_), @_;
}

sub deep_undef_by_hash($$@) {
  my ($self, $h) = (shift, shift);
  for (@_) {
    next unless defined;
    if (ref $_) {
      die "a reference not an ARRAY in deep_undef_by_hash()" unless 'ARRAY' eq ref $_;
      $self->deep_undef_by_hash($h, @$_);
    } elsif ($h->{$_}) {
      undef $_
    }
  }
}

# Make symbols from the first half-face ($h1) to be accessible in the second face ($H1/$H2)
sub pre_link_layers ($$$;$$) {	# Un-obscure non-alphanum bindings from the first face; assign in the direction $hh ---> $HH
  my ($self, $hh, $HH, $skipfix, $skipwarn) = (shift, shift, shift, shift, shift);	# [Main, AltGr-Main,...], [Secondary, AltGr-Secondary,...]
  my ($hn,$Hn, %seen_deobsc) = map $self->{faces}{$_}{layers}, $hh, $HH;
#warn "Link $hh --> $HH;\t(@$hn) -> (@$Hn)" if "$hh $HH" =~ /00a9/i;
  die "Can't link sets of layers `$hh' `$HH' of different sizes: ", scalar @$hn, " != ", scalar @$Hn if @$hn != @$Hn;
  
  my $already_linked = $self->{faces}{$hh}{'[linked]'}{$HH}++;
  $self->{faces}{$HH}{'[linked]'}{$hh}++;
  for my $L (@$Hn) {
    next if $skipfix;
    die "Layer `$L' of face `$HH' is being relinked via `$HH' -> `$hh'???"
      if $self->{layers}{'[ini_copy]'}{$L};
#warn "ini_copy: `$L'";
    $self->{layers}{'[ini_copy]'}{$L} = $self->deep_copy($self->{layers}{$L});
  }
  for my $K (0..$#{$self->{layers}{$hn->[0]}}) {	# key number
#warn "One key data, FROM: K=$K, layer=<", join( '> <', map $self->{layers}{$_}[$K], @$Hn), '>' if "$hh $HH" =~ /00a9/i;
    my @h = map $self->{layers}{$_}[$K], @$hn;		# arrays of [lowercase,uppercase]
#warn "One key data, TO: K=$K, layer=<", join( '> <', map $self->{layers}{$_}[$K], @$Hn), '>' if "$hh $HH" =~ /00a9/i;
    my @H = map $self->{layers}{$_}[$K], @$Hn;
    my @p = map [map {$_ and ref and $_->[2]} @$_],      @h;		# Prefix
    my @c = map [map {($_ and ref) ? $_->[0] : $_} @$_], @h;		# deep copy, remove extra info
    my @C = map [map {($_ and ref) ? $_->[0] : $_} @$_], @H;
    # Find which of keys on $H[0] obscure symbol keys from $h[0]
    my @symb0 = grep {$p[0][$_] or ($c[0][$_] || '') =~ /[\W_]/} 0, 1;	# not(wordchar but not _): prefix/symbols on $h[0]
    defined $H[0][$_] or not defined $C[0][$_] or $skipwarn 
      or warn "Symbol char `$c[0][$_]' not copied to the second face while the slot is empty" 
        for @symb0;
    my @obsc = grep { defined $C[0][$_] and $c[0][$_] ne $C[0][$_]} @symb0;	# undefined positions will be copied later
#warn "K=$K,\tobs=@obsc;\tsymb0=@symb0";
    # If @obsc == 1, put on non-shifted location; may overwrite only ?-binding if it exists
    #return unless @obsc;
    my %map; 
    my @free_first = ((grep {not defined $C[1][$_]} 0, 1), grep defined $C[1][$_], 0, 1);
    @free_first = (1,0) if 1 == ($obsc[0] || 0) and $free_first[0] = 0 and not defined $C[1][1]; # un-Shift ONLY if needed
    @map{@obsc} = @free_first[0 .. $#obsc] unless $skipfix;
#    %map = map +($_, $free_first[$map{$_}]), keys %map;
    for my $k (sort keys %map) {
      if ($skipfix) {
        my $s = $k ? ' (shifted)' : '';
        warn "Key `$C[0][$k]'$s in layer $Hn->[0] does not match symbol $c[0][$k] in layer $hn->[0], and skipfix is requested...\n"
          unless ref($skipwarn || '') ? $skipwarn->{$c[0][$k]} : $skipwarn;
      } elsif (defined $C[1][$map{$k}] and $p[0][$k]) {
	warn "Prefix `$c[0][$k]' in layer $hn->[0] obscured on a key with `$C[1][$map{$k}]' in layer=1: $Hn->[0]"
      } else {
        if (defined $C[1][$map{$k}]) {
          next if $seen_deobsc{$c[0][$k]};	# See ъЪ + palochkas obscuring \| on the secondary \|-key in RussianPhonetic
          # So far, the only "obscuring" with useful de-obscuring is when the obscuring symbol is a letter
          die "existing secondary AltGr-binding `$C[1][$map{$k}]' blocks de-obscuring `$c[0][$k]';\n symbols to de-obscure are at positions [@symb0] in [@{$c[0]}]"
            unless ($C[0][$k] || '.') =~ /[\W\d_]/;
          next
        }
        $H[1][$map{$k}] = $h[0][$k];			# !!!! Modify in place
        $seen_deobsc{$c[0][$k]}++;
      }
    }
    # Inherit keys from $h
    for my $L (0..($skipfix? -1 : $#H)) {
      for my $shift (0,1) {
        next if defined $H[$L][$shift];
        $H[$L][$shift] = $h[$L][$shift];
      }
    }
    next if $already_linked;
    for my $i (0..@$hn) {						# layer type
      for my $j (0,1) {							# case
#???        ++$seen_hex[$_]{ key2hex(($_ ? $key2 : $key1)->[$i][$j], 'undef') } for 0,1;
        push @{$self->{faces}{$hh}{need_extra_keys_to_access}{$HH}}, $H[$i][$j] if defined $C[$i][$j] and not defined $h[$i][$j];
        push @{$self->{faces}{$HH}{need_extra_keys_to_access}{$hh}}, $h[$i][$j] if defined $c[$i][$j] and not defined $H[$i][$j];

      }
    }
  }
}

# Make symbols from the first half-face ($h1) to be accessible in the second face ($H1/$H2)
sub link_layers ($$$;$$) {	# Un-obscure non-alphanum bindings from the first keyboard
  my ($self, $hh, $HH, $skipfix, $skipwarn) = (shift, shift, shift, shift, shift);	# [Main, AltGr-Main,...], [Secondary, AltGr-Secondary,...]
  $self->pre_link_layers ($hh, $HH, $skipfix, $skipwarn);
#warn "Linking with FIX: $hh, $HH" unless $skipfix;
  # We expect that $hh is base-face, and $HH is a satellite.
  $self->face_make_backlinks($HH, $self->{faces}{$HH}{'[char2key_prefer_first]'}, $self->{faces}{$HH}{'[char2key_prefer_last]'}, $skipfix, 'skipwarn');
  # To insert Flip_AltGr_Key into a face, we need to know where it is on the base face, and put it into the corresponding
  # slot of the satellite face.  After face_make_backlinks(), we can find it in the base face.
  # Moreover, we must do it BEFORE calling faces_link_via_backlinks().
  if (defined (my $flip = $self->{faces}{$hh}{'[Flip_AltGr_Key]'})) {{
    defined ( my $flipped = $self->{faces}{$HH}{'[invAltGr_Accessor]'} ) or last;
#	warn "adding AltGr-inv for $hh, accessor=", $self->key2hex($flipped);
    $flip = $self->charhex2key($flip);
#    warn "face_back on $hh: ", join ' ', keys %{$self->{face_back}{$hh} || {}};
    if (my $where = $self->{face_back}{$hh}{$flip}) {
      my($l, $k, $shift) = @{ $where->[0] };
#  warn "Hex face_back l=$l, k=$k, shift-$shift on $hh";
      my($L, $expl, $dead) = ($self->{faces}{$HH}{layers}, '???');
      $L = $self->{layers}{$L->[$l]};
      my $C = my $c = $L->[$k][$shift];
      $c = $c->[0], $dead = $C->[2], $expl = $C->[3] || '???' if $c and ref $c;
      my $DEAD = $dead || '';
      warn "adding Flip_AltGr => <<$flipped>> to $hh\'s satellite $HH: overwriting already present <<<$c>>> (via $expl), dead=$DEAD"
        if defined $c and ($c ne $flipped or not $dead);
      $L->[$k][$shift] = [$flipped, undef, 1, 'Prefix for AltGr inversion'];
      delete $self->{faces}{$hh}{'Face_link_map'}{$HH};		# Reuse old copy
#	warn "Added to $HH; k=$k\[$l, $shift]";
    } else {
      warn "failed: adding AltGr-inv for $hh, flip=$flip, accessor=", $self->key2hex($flipped);
    }
  }}
  $self->face_make_backlinks($hh, $self->{faces}{$hh}{'[char2key_prefer_first]'}, $self->{faces}{$hh}{'[char2key_prefer_last]'}, 'skip');
  $self->faces_link_via_backlinks($hh, $HH);
#  $self->faces_link_via_backlinks($HH, $hh);
}

sub face_make_backlinks($$$$;$$) {		# It is crucial to proceed layers in 
#  parallel: otherwise the semantic of char2key_prefer_first suffers
  my ($self, $F, $prefer_first, $prefer_last, $skipfix, $skipwarn) = (shift, shift, shift || {}, shift || {}, shift, shift);
#warn "Making backlinks for `$F'";
  my $LL = $self->{faces}{$F}{layers};
  if ($self->{face_back}{$F}) {		# reuse old copy
    return if $skipfix;		# reuse old copy
    die "An obsolete copy of `$F' is cashed";
  }
  my $seen = ($self->{face_back}{$F} ||= {});	# maps char to array of possitions it appears in, each [key, shift]
  # Since prefer_first should better operate in terms of keys, not layers; so the loop in $k should be the external one
  my $last = $#{ $self->{layers}{$LL->[0]} };
  my %warn;
  for my $k (0..$last) {
    for my $Lc (0..$#$LL) {
      my $L = $LL->[$Lc];
  #    $self->layer_make_backlinks($_, $prefer_first) for @$L;
      my $a = $self->{layers}{$L};
      unless ($#$a == $last) {				# Detect typos if we can (i.e., if no overflow into special ranges)
        my $fst = 1e100;				# infinity
        $fst > $_->[0] and $fst = $_->[0] for values %start_SEC;
        die "Layer `$L' has lastchar $#$a, expected $last" unless $last >= $fst or $#$a >= $fst;
      }
##########
      for my $shift (0..$#{$a->[$k]}) {
        next unless defined (my $c = $a->[$k][$shift]);
        $c = $c->[0] if 'ARRAY' eq ref $c;			# Treat prefix keys as usual chars
        if ($prefer_first->{$c}) {
#warn "Layer `$L' char `$c': prefer first";
	  @{ $seen->{$c} } = reverse @{ $seen->{$c} } if $seen->{$c} and $prefer_last->{$c};	# prefer 2nd of 3 (2nd from the end)
          push    @{ $seen->{$c} }, [$Lc, $k, $shift];
        } else {
          $warn{$c}++ if @{ $seen->{$c} || [] } and not $prefer_last->{$c} and $c ne ' ';	# XXXX Special-case ' ' ????
          unshift @{ $seen->{$c} }, [$Lc, $k, $shift];
        }
      }
    }
  }
  warn "The following chars appear several times in face `$F', but are not clarified\n\t  (by `char2key_prefer_first', `char2key_prefer_last'):\n\t<",
    join('> <', sort keys %warn), '>' if %warn and not $skipwarn;
}

sub flip_layer_N ($$$) {		# Increases layer number if number of layers is >2 (good for order Plain/AltGr/S-Ctrl)
  my ($self, $N, $max) = (shift, shift, shift);
  return 0 if $N == $max;
  $N + 1
}

sub faces_link_via_backlinks($$$;$) {		# It is crucial to proceed layers in 
#  parallel: otherwise the semantic of char2key_prefer_first suffers
  my ($self, $F1, $F2, $no_inic) = (shift, shift, shift, shift);
  return if $self->{faces}{$F1}{'Face_link_map'}{$F2};		# Reuse old copy
#warn "Making links for `$F1' -> `$F2'";
  my $seen = $self->{face_back}{$F1} or die "Panic: no backlinks on $F1!";	# maps char to array of positions it appears in, each [layer, key, shift]
  my $LL = $self->{faces}{$F2}{layers};
#!$no_inic and $self->{layers}{'[ini_copy1]'}{$_} and warn "ini_copy1 of `$_' exists" for @$LL;
#!$no_inic and $self->{layers}{'[ini_copy]'}{$_}  and warn  "ini_copy of `$_' exists" for @$LL;
  my @LL = map $self->{layers}{'[ini_copy1]'}{$_} || $self->{layers}{'[ini_copy]'}{$_} || $self->{layers}{$_}, @$LL;
  @LL = map $self->{layers}{$_}, @$LL if $no_inic;
  my($maxL, %r, %altR) = $#LL;
  # XXXX Must use $self->{layers}{'[ini_copy]'}{$L} for the target
  for my $c (sort keys %$seen) {
    my $arr = $seen->{$c};
    warn "Empty back-mapping array for `$c' in face `$F1'" unless @$arr;
#    if (@$arr > 1) {
#    }
    my ($to) = grep defined, (map {
#warn "Check `$c': <@$_> ==> <", (defined $LL[$_->[0]][$_->[1]][$_->[2]] ? $LL[$_->[0]][$_->[1]][$_->[2]] : 'undef'), '>';
				    $LL[$_->[0]][$_->[1]][$_->[2]]
				  } @$arr);
    my ($To) = grep defined, (map { $LL[$self->flip_layer_N($_->[0], $maxL)][$_->[1]][$_->[2]] } @$arr);
    $r{$c}    = $to;					# Keep prefix keys as array refs
    $altR{$c} = $To;					# Ditto
  }
  $self->{faces}{$F1}{'Face_link_map'}{$F2} = \%r;
  $self->{faces}{$F1}{'Face_link_map_INV'}{$F2} = \%altR;
}

sub charhex2key ($$) {
  my ($self, $c) = (shift, shift);
  return chr hex $c if $c =~ /^[0-9a-f]{4,}$/i;
  $c
}

sub __manyHEX($$) {			# for internal use only
  my ($self, $s) = (shift, shift);
  $s =~ s/\.?(\b[0-9a-f]{4,}\b)\.?/ chr hex $1 /ieg;
  $s
}

sub stringHEX2string ($$) {		# One may surround HEX by ".", but only if needed.  If not needed, "." is preserved...
  my ($self, $s) = (shift, shift);
  $s =~ s/(?:\b\.)?((?:\b[0-9a-f]{4,}\b(?:\.\b)?)+)/ $self->__manyHEX("$1") /ieg;
  $s
}

sub layer_recipe ($$) {
  my ($self, $l) = (shift, shift);
  return unless exists $self->{layer_recipes}{$l};
  $self->recipe2str($self->{layer_recipes}{$l})
}

sub __dbg_latin_CtrlD ($) {
  my $self = shift;
  my $Ln = $self->{faces}{Latin}{layers}[0];
  my $L = $self->{layers}{$Ln};
  my $Kn = $start_SEC{ARROWS}[0] + 14;		# 14: RETURN 15: ADD
  my $K = $L->[$Kn][0];				# Unshifted
  $K = $K->[0] if ref $K;
  die "Got \\x0d (=$K)" if $K and ($K eq "\x09" or $K eq '000d');
}

sub revive_layer ($$$$) {	# What is the difference with make_translated_layers()???  Supporting the fundamental layers???
  my($self, $f, $ln, $l) = (shift, shift, shift, shift);
  next if $self->{layers}{$l};		# Else, auto-vivify
  my $ll = $l;
#warn "Creating layer `$l' for face `$f'...";
  my @r = $self->layer_recipe($l);
  $ll = $r[0] if @r;
  warn "Massaging: Using layout_recipe `$ll' for layer '$l'\n" if debug_face_layout_recipes and exists $self->{layer_recipes}{$l};
	warn "  mk_tr_lyrs 0" if debug_stacking_ord;
  $ll = $self->make_translated_layers($ll, $f, [$ln], '0000');
#warn "... Result `@$ll' --> $self->{layers}{$ll->[0]}";
  (debug_face_layout_recipes and warn "Massaging: Using layout_recipe `$ll->[0]' for layer '$l'\n"),
  $self->{layers}{$l} = $self->{layers}{$ll->[0]} unless $self->{layers}{$l};		# Could autovivify in between???
}

my $w_o;
sub order_faces_4_massage ($) {		# process LinkFace first (if no loops)
  my($self, $prekeys) = (shift, 1e300);
  my(@res, @RES, %seen) = [sort keys %{$self->{faces}}];
  while ($prekeys > $#{$res[-1]}) {	# Construct chains of LinkFace'ing; next element is made of linkface's of the previous one
    $prekeys = $#{$res[-1]};
    push @res, [];
    for my $f (@{$res[-2]}) {
      next if 'HASH' ne ref $self->{faces}{$f} or $f =~ m(\bVK$);			# "parent" taking keys for a child
      if (my $LF = $self->{faces}{$f}{LinkFace}) {
        push @{$res[-1]}, $LF;
      }
    }
  }
  for my $r (reverse @res) {
    push @RES, grep !$seen{$_}++, sort @$r;	# reverse? ??? Voodoo !!!  Sorting changes the result... XXXX
  }
  warn 'Face order `', join("' `", @RES), "'" unless $w_o++;
  @RES
}


sub massage_faces ($) {
  my $self = shift;
# warn "Massaging faces...";
  for my $f ($self->order_faces_4_massage) {		# Needed for (pre_)link_layers...
    next if 'HASH' ne ref $self->{faces}{$f} or $f =~ m(\bVK$);			# "parent" taking keys for a child
#warn "Massaging face `$f'...";
    for my $key ( qw( Flip_AltGr_Key Diacritic_if_undef DeadChar_DefaultTranslation DeadChar_32bitTranslation extra_report_DeadChar
    		      PrefixChains ctrl_after_modcol create_alpha_ctrl keep_missing_ctrl output_layers
		      output_layers_WIN output_layers_XKB skip_extra_layers_WIN Prefix_Base_Altern Prefix_Force_Altern
    		      layers_modifiers layers_mods_keys mods_keys_KBD AltGrInv_AltGr_as_Ctrl
		      ComposeKey_Show AltGr_Invert_Show Apple_Override Apple_Duplicate Apple_HexInput 
    		      ComposeKey Explicit_AltGr_Invert Auto_Diacritic_Start CapsLOCKoverride
    		      WindowsEmitDeadkeyDescrREX ExtraChars modkeys_vk) ) {
      $self->{faces}{$f}{"[$key]"} = $self->get_deep_via_parents($self, undef, 'faces', (split m(/), $f), $key);
    }
    $self->{faces}{$f}{'[char2key_prefer_first]'}{$_}++ 		# Make a hash
      for @{ $self->{faces}{$f}{char2key_prefer_first} || [] } ;
    $self->{faces}{$f}{'[char2key_prefer_last]'}{$_}++ 			# Make a hash
      for @{ $self->{faces}{$f}{char2key_prefer_last} || [] } ;
    $self->{faces}{$f}{'[AltGrInv_AltGr_as_Ctrl]'} = 1 unless defined $self->{faces}{$f}{'[AltGrInv_AltGr_as_Ctrl]'};

    my $idx = $self->get_deep($self, 'faces', (split m(/), $f), 'MetaData_Index');
    # defined $self->{faces}{$f}{"[$_]"} and not ref $self->{faces}{$f}{"[$_]"}
    #  or
    $self->{faces}{$f}{"[$_]"} = $self->get_deep_via_parents($self, $idx, 'faces', (split m(/), $f), $_)
        for qw(LRM_RLM ALTGR SHIFTLOCK NOALTGR);

    my %R = qw(ComposeKey_Show ⎄    AltGr_Invert_Show ⤨);		# On Apple only
    defined $self->{faces}{$f}{"[$_]"} or $self->{faces}{$f}{"[$_]"} = $R{$_} for keys %R;
    $self->{faces}{$f}{"[ComposeKey_Show]"}[0] = '⎄'			# Make a safe default
      if ref $self->{faces}{$f}{"[ComposeKey_Show]"} and not length $self->{faces}{$f}{"[ComposeKey_Show]"}[0];

    my ($compK, %compK) = $self->{faces}{$f}{'[ComposeKey]'};
    if ($compK and ref $compK) {
      for my $cK (@$compK) {
        my @kkk = split /,/, $cK;
        $compK{ $self->key2hex($self->charhex2key($kkk[3])) }++ if defined $kkk[3] and length $kkk[3];
      }
    } elsif (defined $compK) {
      $compK{ $self->key2hex($self->charhex2key($compK)) }++;
    }
    $self->{faces}{$f}{'[ComposeKeys]'} = \%compK;

    unless ($self->{faces}{$f}{layers}) {
      next unless $self->{face_recipes}{$f};
      $self->face_by_face_recipe($f, $f);
    }
    for my $ln ( 0..$#{$self->{faces}{$f}{layers} || []} ) {
      my $l = $self->{faces}{$f}{layers}[$ln];
      $self->revive_layer($f, $ln, $l) unless $self->{layers}{$l};
    }
###        warn "Layer names (face=`$f', layer[0]=`$self->{faces}{$f}{layers}[0]'):\n\t`", join("'\n\t`", sort keys %{$self->{layers}}), "'"
###	  	if debug_face_layout_recipes or not defined $self->{layers}{$self->{faces}{$f}{layers}[0]};
  }

  for my $f ($self->order_faces_4_massage) {		# Needed for LinkFace inside massage_VK()...  Breaks CopticTens etc.
    next if 'HASH' ne ref $self->{faces}{$f} or $f =~ m(\bVK$);			# "parent" taking keys for a child
    (my ($seen, $seen_dead), $self->{faces}{$f}{'[dead_in_VK]'}) = $self->massage_VK($f);
    $self->{faces}{$f}{'[dead_in_VK_array]'} = $seen_dead;
    $self->{faces}{$f}{'[coverage_hex]'}{$self->key2hex($_)}++ for @$seen;
    $self->{faces}{$f}{"Altern$_"} ||= $self->{faces}{$f}{"AltGr$_"}
       for qw(CharSubstitutions CharSubstitutionFaces CharSubstitutionLayers);
    # Obsolete names
    for my $S (@{ $self->{faces}{$f}{AlternCharSubstitutions} || []}) {
      my $s = $self->stringHEX2string($S);
      $s =~ s/\p{Blank}(?=\p{NonspacingMark})//g;
      die "Expect 2 chars in AltGr-char substitution rule; I see <$s> (from <$S>)" unless 2 == (my @s = split //, $s);
      push @{ $self->{faces}{$f}{'[AltSubstitutions]'}{$s[0]} }, [$s[1], 'manual'];
      push @{ $self->{faces}{$f}{'[AltSubstitutions]'}{lc $s[0]} }, [lc $s[1], 'manual']
        if lc $s[0] ne $s[0] and lc $s[1] ne $s[1];
      push @{ $self->{faces}{$f}{'[AltSubstitutions]'}{uc $s[0]} }, [uc $s[1], 'manual']
        if uc $s[0] ne $s[0] and uc $s[1] ne $s[1];
    }
    s/^\s+//, s/\s+$//, $_ = $self->stringHEX2string($_) for @{ $self->{faces}{$f}{Import_Prefix_Keys} || []};
    my %h = @{ $self->{faces}{$f}{Import_Prefix_Keys} || []};
    $self->{faces}{$f}{'[imported2key]'} = \%h if %h;
    my ($l0, $c);
    unless ($c = $self->{layer_counts}{$l0 = $self->{faces}{$f}{layers}[0]}) {
      $l0 = $self->get_deep_via_parents($self, undef, 'faces', (split m(/), $f), 'geometry_via_layer');
      $c = $self->{layer_counts}{$l0} if defined $l0;
    }
    my $o = $self->{layer_offsets}{$l0} if defined $l0;
    $self->{faces}{$f}{'[geometry]'} = $c if $c;
    $self->{faces}{$f}{'[g_offsets]'} = $o if $o;
  }
#  $self->__dbg_latin_CtrlD;
  for my $f ($self->order_faces_4_massage) {	# Needed for face_make_backlinks: must know which keys in faces will be finally present
    next if 'HASH' ne ref $self->{faces}{$f} or $f =~ m(\bVK$);			# "parent" taking keys for a child
    for my $F (@{ $self->{faces}{$f}{AlternCharSubstitutionFaces} || []}) {	# Now has a chance to have real layers
      unless ($self->{faces}{$F}{layers}) {
        next unless $self->{face_recipes}{$F};
        $self->face_by_face_recipe($F, $f);
      }
      for my $L (0..$#{$self->{faces}{$f}{layers}}) {
        my $from  = $self->{faces}{$f}{layers}[$L];
        next unless my $to = $self->{faces}{$F}{layers}[$L];
        $_ = $self->{layers}{$_} for $from, $to;
        for my $k (0..$#$from) {
          next unless $from->[$k] and $to->[$k];
          for my $shift (0..1) {
            next unless defined (my $s = $from->[$k][$shift]) and defined (my $ss = $to->[$k][$shift]);
            $_ and ref and $_ = $_->[0] for $s, $ss;
            push @{ $self->{faces}{$f}{'[AltSubstitutions]'}{$s} }, [$ss, "F=$F"];
          }
        }
      }
    }  
  }		# ^^^ This is not used yet???
#  $self->__dbg_latin_CtrlD;
  for my $f ($self->order_faces_4_massage) {	# Needed for face_make_backlinks: must know which keys in faces will be finally present
    next if 'HASH' ne ref $self->{faces}{$f} or $f =~ m(\bVK$);			# "parent" taking keys for a child
    my $linked = $self->{faces}{$f}{LinkFace};
    for my $N (0..$#{ $self->{faces}{$f}{AlternCharSubstitutionLayers} || []}) {	# Now has a chance to have real layers
      my $TO = my $to = $self->{faces}{$f}{AlternCharSubstitutionLayers}[$N];
      my $from  = $self->{faces}{$f}{layers}[$N] or next;
      $self->revive_layer($f, $N, $TO) unless $self->{layers}{$TO};
      $_ = $self->{layers}{$_} for $from, $to;
      my $from_linked;
      if ($linked) {
	$from_linked = $self->{faces}{$linked}{layers}[$N];
	$from_linked = $self->{layers}{$from_linked} if defined $from_linked;
      }
      for my $k (0..$#$from) {
        next unless ($from->[$k] or $from_linked and $from_linked->[$k]) and $to->[$k];
        for my $shift (0..1) {
          next unless defined (my $s = ($from->[$k][$shift] or $from_linked and $from_linked->[$k][$shift]))
			and defined (my $ss = $to->[$k][$shift]);
          $_ and ref and $_ = $_->[0] for $s, $ss;
          push @{ $self->{faces}{$f}{'[AltSubstitutions]'}{$s} }, [$ss, "L=$TO"];
        }
      }
    }
    if ($f =~ /^(Latin|CyrillicPhonetic|GreekPoly|Hebrew)$/ and $self->{faces}{$f}{'[AltSubstitutions]'}) {
      warn "  `$f' AltSubstitutions: ", join '', sort keys %{$self->{faces}{$f}{'[AltSubstitutions]'}};
    }
  }
#  $self->__dbg_latin_CtrlD;
  for my $f ($self->order_faces_4_massage) {	# Linking uses the number of slots in layer 0 as the limit; fill to make into max
    next if 'HASH' ne ref $self->{faces}{$f} or $f =~ m(\bVK$);			# "parent" taking keys for a child
    my $L = $self->{faces}{$f}{layers};
    my @last = map $#{$self->{layers}{$_}}, @$L;
    my $last = $last[0];
    $last < $_ and $last = $_ for @last;
    push @{$self->{layers}{$L->[0]}}, [] for 1..($last-$last[0]);
  }
#  $self->__dbg_latin_CtrlD;
  for my $f ($self->order_faces_4_massage) {	# Needed for face_make_backlinks: must know which keys in faces will be finally present
    next if 'HASH' ne ref $self->{faces}{$f} or $f =~ m(\bVK$);			# "parent" taking keys for a child
    next unless defined (my $o = $self->{faces}{$f}{LinkFace});
    $self->export_layers($o, $f);			# Process recipes
    $self->pre_link_layers($o, $f);			# May add keys to $f
# warn("pre_link <$o> <$f>\n") if defined $o;
  }
#  $self->__dbg_latin_CtrlD;
  for my $f ($self->order_faces_4_massage) {
    next if 'HASH' ne ref $self->{faces}{$f} or $f =~ m(\bVK$);			# "parent" taking keys for a child
    $self->face_make_backlinks($f, $self->{faces}{$f}{'[char2key_prefer_first]'}, $self->{faces}{$f}{'[char2key_prefer_last]'});
  }
#  $self->__dbg_latin_CtrlD;
  for my $f ($self->order_faces_4_massage) {
    next if 'HASH' ne ref $self->{faces}{$f} or $f =~ m(\bVK$);			# "parent" taking keys for a child
    my $o = $self->{faces}{$f}{LinkFace};
    next unless defined $o;
    $self->faces_link_via_backlinks($f, $o);
    $self->faces_link_via_backlinks($o, $f);
  }
#  $self->__dbg_latin_CtrlD;
  for my $f ($self->order_faces_4_massage) {
    next if 'HASH' ne ref $self->{faces}{$f} or $f =~ m(\bVK$);			# "parent" taking keys for a child
    if (defined( my $r = $self->{faces}{$f}{"[CapsLOCKoverride]"} )) {
      warn "Massaging CapsLock for face `$f'...\n" if debug_face_layout_recipes;
      $self->{faces}{$f}{'[CapsLOCKlayers]'} = $self->layers_by_face_recipe($r, $f, $r);
    }
    my ($DDD, $export, $vk)	= map $self->{faces}{$f}{"[$_]"} ||= {}, qw(DEAD export dead_in_VK);
    my ($ddd)		= map $self->{faces}{$f}{"[$_]"} ||= [], qw(dead);
    $self->coverage_hex($f);
    my $S = $self->{faces}{$f}{layers};
    my ($c,%s,@d) = 0;
    for my $D (@{$self->{faces}{$f}{layerDeadKeys} || []}) {		# deprecated...
      $c++, next unless length $D;	# or $D ~= /^\s*--+$/ ;	# XXX How to put empty elements in an array???
      $D =~ s/^\s+//;
      (my $name, my @k) = split /\s+/, $D;
      @k = map $self->charhex2key($_), @k;
      die "name of layerDeadKeys' element in face `$f' does not match:\n\tin `$D'\n\t`$name' vs `$self->{faces}{$f}{layers}[$c]'"
        unless $self->{faces}{$f}{layers}[$c] =~ /^\Q$name\E(<.*>)?$/;	# Name might have changed in VK processing
      1 < length and die "not a character as a deadkey: `$_'" for @k;
      $ddd->[$c] = {map +($_,1), @k};
      ($s{$_}++ or push @d, $_), $DDD->{$_} = 1 for @k;
      $c++;
    }
    for my $k (split /\p{Blank}+(?:\|{3}\p{Blank}+)?/, 
    		(defined $self->{faces}{$f}{faceDeadKeys} ? $self->{faces}{$f}{faceDeadKeys} : '')) {
      next unless length $k;
      $k = $self->charhex2key($k);
      1 < length $k and die "not a character as a deadkey: `$k'";
      $ddd->[$_]{$k} = 1 for 0..$#{ $self->{faces}{$f}{layers} };	# still used...
      $DDD->{$k} = 1;
      $s{$k}++ or push @d, $k;
    }
    for my $k (split /\p{Blank}+/, (defined $self->{faces}{$f}{ExportDeadKeys} ? $self->{faces}{$f}{ExportDeadKeys} : '')) {
      next unless length $k;
      $k = $self->charhex2key($k);
      1 < length $k and die "not a character as an exported deadkey: `$k'";
      $export->{$k} = 1;
    }
    if (my $LL = $self->{faces}{$f}{'[ini_layers]'}) {
      my @out;
      for my $L ( @$LL ) {
        push @out, "$L++prefix+";
        my $l = $self->{layers}{$out[-1]} = $self->deep_copy($self->{layers}{$L});
        for my $n (0 .. $#$l) {
          my $K = $l->[$n];
          for my $k (@$K) {
#warn "face `$f' layer `$L' ini_layers_prefix: key `$k' marked as a deadkey" if defined $k and $DDD->{$k};
            $k = [$k] if defined $k and not ref $k;		# Allow addition of doc strings
            if (defined $k and ($DDD->{$k->[0]} or $vk->{$k->[0]})) {
              @$k[1,2] = ($f, $k->[2] || ($export->{$k->[0]} ? 2 : 1));	# Is exportable?
            }
          }
        }
      }
      $self->{faces}{$f}{'[ini_layers_prefix]'} = \@out;
      $LL = $self->{faces}{$f}{'[ini_filled_layers]'} = [ @{ $self->{faces}{$f}{layers} } ];	# Deep copy
      my @OUT;
      for my $L ( @$LL ) {
        push @OUT, "$L++PREFIX+";
        my $l = $self->{layers}{$OUT[-1]} = $self->deep_copy($self->{layers}{$L});
        for my $n (0 .. $#$l) {
          my $K = $l->[$n];
          for my $k (@$K) {
#warn "face `$f' layer `$L' layers_prefix: key `$k' marked as a deadkey" if defined $k and $DDD->{$k};
            $k = [$k] if defined $k and not ref $k;		# Allow addition of doc strings
            if (defined $k and ($DDD->{$k->[0]} or $vk->{$k->[0]})) {
              @$k[1,2] = ($f, $k->[2] || ($export->{$k->[0]} ? 2 : 1));	# Is exportable?
            }
          }
        }
      }
      $self->{faces}{$f}{layers} = \@OUT;
    } else {
      warn "Face `$f' has no ini_layers";
    }
    $self->{faces}{$f}{'[dead_array]'} = \@d;
    for my $D (@{$self->{faces}{$f}{faceDeadKeys2} || $self->{faces}{$f}{layerDeadKeys2} || []}) {	# layerDeadKeys2 obsolete
      $D =~ s/^\s+//;	$D =~ s/\s+$//;
      my @k = split //, $self->stringHEX2string($D);
      2 != @k and die "not two characters as a chained deadkey: `@k'";
#warn "dead2 for <@k>";
      $self->{faces}{$f}{'[dead2]'}{$k[0]}{$k[1]}++;
      # $k[1] is "untranslated"; it is not good for [DEAD]:
      #$self->{faces}{"$f###" . $self->key2hex($k[0])}{'[DEAD]'}{$k[1]}++;
    }
  }
#  $self->__dbg_latin_CtrlD;
  $self
}

sub massage_hash_values($) {
  my($self) = (shift);
  for my $K ( @{$self->{'[keys]'}} ) {
    my $h = $self->get_deep($self, split m(/), $K);
    $_ = $self->charhex2key($_) for @{ $h->{char2key_prefer_first} || []}, @{ $h->{char2key_prefer_last} || []};
  }

}
#use Dumpvalue;

sub print_codepoint ($$;$$) {	# $postfix may be a name of base-font.  Then the coverage_how is used instead of $postfix
  my ($self, $k, $prefix, $postfix) = (shift, shift, shift, shift);
  my $K = ($k =~ /$rxCombining/ ? " $k" : $k);
  if (defined $postfix) {
    my $how = $self->{faces}{$postfix}{'[coverage_how]'}{$k};
#    $how2 =~ s/(1+)/length $1/e;
#    defined($how) ? $how .= " $how2" : $how = $how2 if $how2;
    $postfix = '' if $self->{faces}{$postfix}{'[coverage_how]'};
    $postfix = " $how" if $how;
  }
  $prefix = '' unless defined $prefix;
  $postfix = '' unless defined $postfix;
  my $kk = join '.', map $self->key2hex($_), split //, $k;
  my $UN = join ' + ', map $self->UName($_, 'verbose', 'vbell'), split //, $k;
  printf "%s%s\t<%s>%s\t%s\n", $prefix, $kk, $K, $postfix, $UN;
}

sub require_unidata_age ($) {
  my $self = shift;
  my $f = $self->get_NamesList;
  $self->load_compositions($f) if defined $f;
    
  $f = $self->get_AgeList;
  $self->load_uniage($f) if defined $f and not $self->{Age};
  $self;
}

sub print_coverage_string ($$) {
  my ($self, $s, %seen) = (shift, shift);
  $seen{$_}++ for split //, $s;

  my $f = $self->get_NamesList;
  $self->load_compositions($f) if defined $f;
    
  $f = $self->get_AgeList;
  $self->load_uniage($f) if defined $f and not $self->{Age};

  require Unicode::UCD;

  $self->print_codepoint($_) for sort keys %seen;
}

sub print_coverage ($$) {
  my ($self, $F) = (shift, shift);
  
  my $f = $self->get_NamesList;
  $self->load_compositions($f) if defined $f;
    
  $f = $self->get_AgeList;
  $self->load_uniage($f) if defined $f and not $self->{Age};

  my $file = $self->{'[file]'};
  my $app = (defined $file and @$file > 1 and 's');
  $file = (defined $file) ? "file$app @$file" : 'string descriptor';
  my $v = $self->{VERSION};
  $file .= " version $v" if defined $v;
  $file .= " Unicode tables version $self->{uniVersion}" if defined $self->{uniVersion};
 
  print "############# Generated with UI::KeyboardLayout v$UI::KeyboardLayout::VERSION for $file, face=$F\n#\n";

  my $is32 = $self->{faces}{$F}{'[32-bit]'};
  my $cnt32 = keys %{$is32 || {}};
  my $c1 = @{ $self->{faces}{$F}{'[coverage1only]'} };	# - $cnt32;
  my $c2 = @{ $self->{faces}{$F}{'[coverage1]'} } - @{ $self->{faces}{$F}{'[coverage1only]'} };
  my $more = '';	#$cnt32 ? " (and up to $cnt32 not available on Windows - at end of this section above FFFF)" : '';
  my @multi;
  for my $n (0, 1) {
    $multi[$n]{$_}++ for grep 1 < length, @{ $self->{faces}{$F}{"[coverage$n]"} };
  }
  my @multi_c = map { scalar keys %{$multi[$_]} } 0, 1;
  my %comp = %{ $self->{faces}{$F}{'[inCompose]'} || {} };
  delete $comp{$_} for @{ $self->{faces}{$F}{"[coverage0]"} }, @{ $self->{faces}{$F}{"[coverage1]"} };
  my @comp = grep {2 > length and 0x10000 > ord} sort keys %comp;
  my %in_comp;
  $in_comp{$_}++ for @comp;
  printf "######### %i = %i + %i + %i + %i bindings [1-char + base multi-char-strings (MCS) + “extra layers” MCS + only via Compose key]\n", 
    @{ $self->{faces}{$F}{'[coverage0]'} } + $c1 + $c2 + @comp,
    @{ $self->{faces}{$F}{'[coverage0]'} } + $c1 + $c2 - $multi_c[0] - $multi_c[1],
    $multi_c[0], $multi_c[1], scalar @comp;
  printf "######### %i = %i + %i + %i%s [direct + via single prefix keys and “extra layers” (both=%i) + via repeated prefix key] chars\n",
    @{ $self->{faces}{$F}{'[coverage0]'} } + $c1 + $c2 - $multi_c[0] - $multi_c[1],
    scalar @{ $self->{faces}{$F}{'[coverage0]'} } - $multi_c[0],
    $c1 - $multi_c[1], $c2, $more, @{ $self->{faces}{$F}{'[coverage0oneChar]'} } + $c1 - $multi_c[0] - $multi_c[1];
  print "Marks mean: b = “in base face”, each of: e = “base with extra modifiers”, 1 = “with single prefix key”, 2/3 likewise, 9=“>3 | ∞”\n" .
  		"\t\t①/②/③/⑨ = “needs ‘extra modifiers’-prefix”, ⓕ/ƒ/ᶠ/φ = “via flat map”, Ⓕ/F/ℱ/Φ = “with extra (impossible!)”; likewise\n" .
  		"\t\tⓔ/ₑ/ᵉ/ε | Ⓔ/E/ᴱ/έ ⫿ ⓐ/a/ᵃ/α | Ⓐ/A/ᴬ/ά = “on Arrow-like keys (⫿ with-AltGr-inversion)”, ⇑⤊^⦽|⇡⥀ˆꞈ = “on AltGr-inverted Ctrl-keys”.\n";
  for my $k (@{ $self->{faces}{$F}{'[coverage0oneChar]'} }) {
    $self->print_codepoint($k, undef, $F);
  }
  print "############# Base multi-char strings:\n";
  for my $k (@{ $self->{faces}{$F}{'[coverage0multiChar]'} }) {
    $self->print_codepoint($k, undef, $F);
  }
  print "############# Via single prefix keys (or with extra modifiers):\n";
  for my $k (@{ $self->{faces}{$F}{'[coverage1only]'} }) {
    $self->print_codepoint($k, undef, $F) if 2 > length $k;
  }
  print "############# Multi-char via single prefix keys (or with extra modifiers):\n";
  for my $k (@{ $self->{faces}{$F}{'[coverage1only]'} }) {
    $self->print_codepoint($k, undef, $F) if 1 < length $k;
  }
  my $h1 = $self->{faces}{$F}{'[coverage1only_hash]'};
  print "############# Via repeated prefix keys:\n";
  for my $k (@{ $self->{faces}{$F}{'[coverage1]'} }) {
    $h1->{$k} or $self->print_codepoint($k, undef, $F) if 2 > length $k;
  }
  print "############# Multi-char via repeated prefix keys:\n";
  for my $k (@{ $self->{faces}{$F}{'[coverage1]'} }) {
    $h1->{$k} or $self->print_codepoint($k, undef, $F) if 1 < length $k;
  }
  print "############# Difficult to reach (or unreachable) in prefix maps (prefix = +2, “extra” modifiers = +1, etc. ⇒ >4):\n";
  for my $c (sort keys %{ $self->{faces}{$F}{'[coverage_difficulty]'} }) {
    $self->print_codepoint($c, undef, $F) if $self->{faces}{$F}{'[coverage_difficulty]'}{$c} > 4;
  }
  print "############# Went through the cracks in accounting:\n";
  for my $k (sort keys %{ $self->{faces}{$F}{'[coverage_how]'} }) {
    $self->print_codepoint($k, '¿ ', $F) unless $self->{faces}{$F}{'[coverage_hash]'}{$k};
  }
  print "############# Via Compose key, but not simply accessible:\n";
  for my $k (@comp) {
    $self->print_codepoint($k, '= ', $F);
  }
  print "############# Have lost the competition (for prefixed position), but available elsewhere:\n";
  for my $k (sort keys %{ $self->{faces}{$F}{'[in_dia_chains]'} }) {
    next unless $self->{faces}{$F}{'[coverage_hash]'}{$k} and not $self->{faces}{$F}{'[from_dia_chains]'}{$k};
    $self->print_codepoint($k, '+ ', $F);		# May be in from_dia_chains, but be obscured later...
  }
  print "############# Have lost the competition (not counting those explicitly prohibited by \\\\):\n";
  for my $k (sort keys %{ $self->{faces}{$F}{'[in_dia_chains]'} }) {
    next if $self->{faces}{$F}{'[coverage_hash]'}{$k};
    $self->print_codepoint($k, '- ', $F);
  }
  my ($tot_diac, $lost_diac) = (0,0);
  $tot_diac++, $self->{faces}{$F}{'[coverage_hash]'}{$_} || $lost_diac++ 
    for keys %{ $self->{'[map2diac]'} };
  print "############# Lost among known classified modifiers/standalone/combining ($lost_diac/$tot_diac):\n";
  for my $k (sort keys %{ $self->{'[map2diac]'} }) {
    next if $self->{faces}{$F}{'[coverage_hash]'}{$k};
    $self->print_codepoint($k, '?- ', $F);
  }
  print "############# Per key list:\n";
  my $OOut = $self->print_table_coverage($F);
  for my $HOW ([{}, ''], [\%in_comp, ', even with Compose']) {
    my ($OUT, $CC, $CC1) = ('', 0, 0);
    for my $r ([0x2200, 0x40], [0x2240, 0x40], [0x2280, 0x40], [0x22c0, 0x40], 
               [0x27c0, 0x30], [0x2980, 0x40], [0x29c0, 0x40], 
               [0x2a00, 0x40], [0x2a40, 0x40], [0x2a80, 0x40], [0x2ac0, 0x40], [0xa720, 0x80-0x20], [0xa780, 0x80] ) {
      my $C = join '', grep { (0xa720 >= ord $_ or $self->{UNames}{$_}) and !$self->{faces}{$F}{'[coverage_hash]'}{$_}
									and !$HOW->[0]{$_} } 
                            map chr($_), $r->[0]..($r->[0]+$r->[1]-1);	# before a720, the tables are filled up...
      ${ $r->[0] < 0xa720 ? \$CC : \$CC1 } += length $C;
      $OUT .= "-==-\t$C\n";
    }
    print "############# Not covered in the math+latin-D ranges ($CC+$CC1)$HOW->[1]:\n$OUT";
  }
  my ($OUT, $CC, $CC1) = ('', 0, 0);
  for my $r ([0x2200, 0x80], [0x2280, 0x80], 
  	     [0x27c0, 0x30], [0x2980, 0x80], 
             [0x2a00, 0x80], [0x2a80, 0x80], [0xa720, 0x100-0x20] ) {
    my $C = join '', grep {(0xa720 >= ord $_ or $self->{UNames}{$_}) and !$self->{faces}{$F}{'[coverage_hash]'}{$_} 
    			   and !$self->{faces}{$F}{'[in_dia_chains]'}{$_}} map chr($_), $r->[0]..($r->[0]+$r->[1]-1);
    ${ $r->[0] < 0xa720 ? \$CC : \$CC1 } += length $C;
    $OUT .= "-==-\t$C\n";
  }
  print "############# Not competing, in the math+latin-D ranges ($CC+$CC1):\n$OUT";
  $OOut
}

my %html_esc = qw( & &amp; < &lt; > &gt; );
my %ctrl_special = qw( \r Enter \n Control-Enter \b BackSpace \x7f Control-Backspace \t Tab 
  		    \x1b Esc; Control-[ \x1d Control-] \x1c Control-\ ^C Control-Break \x1e Control-^ \x1f Control-_ \x00 Control-@);
my %alt_symb;
{ no warnings 'qw';
# 		ZWS	ZWNJ ZWJ	 LRM RLM WJ=ZWNBSP Func	  Times Sep Plus
  my %a = (qw(200b ∅ 200c ‸ 200d & 200e → 200f ← 2060 ⊕ 2061 () 2062 × 2063 | 2064 +),
		# SPC	NBSP	obs-N obs-M 	n	m 	m/3 m/4	  m/6 figure=digit punctuation thin hair    Soft-hyphen
	     qw(0020 ␣ 00a0 ⍽ 2000 N 2001 M 2002 n 2003 m 2004 ᵐ⁄₃ 2005 ᵐ⁄₄ 2006 ᵐ⁄₆ 2007 ᵈ 2008 , 2009 ᵐ⁄₅ 200a ᵐ⁄₈ 00ad -),
		# LineSep ParSep LRE	RLE PopDirForm LRO RLO narrowNBSP
	     qw(2028 ⏎ 2029 ¶ 202a ⇒ 202b ⇐ 202c ↺ 202d ⇉ 202e ⇇ 202f ⁿ));
  @alt_symb{map chr hex, keys %a} = values %a;
}

# Make: span for control, soft-hyphen, white-space; include in <span class=l> with popup; include in span with special highlight
sub char_2_html_span ($$$$$$;@) {
   my ($self, $base_c, $C, $c, $F, $opts, @types, $expl, $title, $vbell) = @_;
   my $aInv = $self->charhex2key($self->{faces}{$F}{'[Flip_AltGr_Key]'});
   $expl = $C->[3] if 'ARRAY' eq ref $C and $C->[3];
   $expl =~ s/(?=\p{NonspacingMark})/ /g if $expl;
   my $prefix = (ref $C and $C->[2]);
   my $cc = $c;
   $aInv = ($base_c || 'N/A') eq $aInv;
   my $docs = ($prefix and $self->{faces}{$F}{'[prefixDocs]'}{$self->key2hex($cc)});	# or $pre and warn "No docs: face=`$F', c=`$cc'\n";
   $docs =~ s/([''&])/sprintf '&#x%02x;', ord $1/ge if defined $docs;
# warn "... is_D2: ", $self->array2string([$c, $baseK[$L][$shift]]);
   $c =~ s/(?=$rxCombining)/\x{25cc}/go;	# dotted circle ◌ 25CC
   $c =~ s/([&<>])/$html_esc{$1}/g;
   my $create_a_c = $self->{faces}{$F}{'[create_alpha_ctrl]'};
   $create_a_c = $create_alpha_ctrl unless defined $create_a_c;
   my $alpha_ctrl = ($create_a_c and $cc =~ /[\cA-\cZ]/);
   my $with_shift = (($create_a_c > 1 and $alpha_ctrl) ? '(Shift-)' : '');
   $c =~ s{([\x00-\x1F\x7F])}{ my $C = $self->control2prt("$1"); my $S = $ctrl_special{$C} || '';
   			       ($S and $S .= ", "), $S .= "Control-$with_shift".chr(0x40+ord $1) if $alpha_ctrl;
                               $C = "<span class=yyy title='$S'>$C</span>" if $S; $C }ge;
   my $type = ($cc =~ /[^\P{Blank}\x00-\x1f]/ && 'WS');		# Blank and not control char
   my ($fill, $prefill, $zw) = ('', '');
   if ($type or $c =~ /($rxZW)$/o) {
     my $alt = ($alt_symb{$cc} ? qq( convention="$alt_symb{$cc}") : '');
     $fill = "<span$alt class=lFILL></span>";			# Soft hyphen etc
   }
   if ($type) {				# Putting WS inside l makes gaps between adjacent WS blocks
     $prefill = '<span class=WS>';
     $fill .= '</span>';
   }
   push @types, 'no-mirror-rtl' if "\x{34f}" eq $cc;	# CGJ
   $zw = !!$fill || $cc eq "\x{034f}";
   $vbell = !defined $C;
   unless (defined $title) {
           $title = ((ord $cc >= 0x80 or $cc eq ' ') && sprintf '%04X  %s', ord $cc, $self->UName($cc, 'verbose', $vbell));
           if ($title and $docs) {
             $title = "$docs (on $title)";
           }
           $title ||= ($docs || '');
           if (defined $expl and length $expl and (1 or 0x7f <= ord $cc)) {
             $title .= ' ' if length $title;
             $title .= " {via $expl}";
           }
           $title .= ' (visual bell indicates unassigned keypress)' if $title and !$expl and $vbell;
           $title = 'This prefix key accesses this column with AltGr-invertion' if $aInv;
           $title =~ s/([''&])/sprintf '&#x%02x;', ord $1/ge if $title;
           $title = qq( title='$title') if $title;
   }
   if ($type) {					# Already covered
   } elsif ($zw) {
     push @types,'ZW';
   } elsif (not defined $C) {
     push @types,'vbell';
   } elsif ($title =~ /(\b(N-ARY|BIG(?!\s+YUS\b)|GREEK\s+PROSGEGRAMMENI|KORONIS|SOF\s+PASUQ|PUNCTUATION\s+(?:GERESH|GERSHAYIM)|PALOCHKA|CYRILLIC\s.*\s(DZE|JE|QA|WE|A\s+IE)|ANO\s+TELEIA|GREEK\s+QUESTION\s+MARK)|"\w+\s+(?:BIG|LARGE))\b.*\s+\[/) {	# "0134	BIG GUY#"
     push @types,'nAry';
   } elsif ($title =~ /\b(OPERATOR|SIGN|SYMBOL|PROOF|EXISTS|FOR\s+ALL|(DIVISION|LOGICAL)\b.*)\s+\[/) {
     push @types,'operator';
   } elsif ($title =~ /\b(RELATION|PERPENDICULAR|PARALLEL\s*TO|DIVIDES|FRACTION\s+SLASH)\s+\[/) { 
     push @types,'relation';
   } elsif ($title =~ /\[.*\b(IPA)\b|\bCLICK\b/) { 
     push @types,'ipa';
   } elsif ($title =~ /\bLETTER\s+[AEUIYO]\b/ and 
            $title =~ /\b(WITH|AND)\s+(HOOK\s+ABOVE|HORN)|(\s+(WITH|AND)\s+(CIRCUMFLEX|BREVE|ACUTE|GRAVE|TILDE|DOT\s+BELOW)\b){2}/) { 
     push @types,'viet';
   } elsif (0 <= index(lc '⁊ǷꝥƕǶᵹ', lc $cc) or 0xa730 <= ord $cc and 0xa78b > ord $cc or 0xa7fb <= ord $cc and 0xa7ff >= ord $cc) { 
     push @types,'paleo';
   } elsif ($title =~ /(\s+(WITH|AND)\s+((DOUBLE\s+)?\w+(\s+(BELOW|ABOVE))?)\b){2}/) { 
     push @types,'doubleaccent';
   }
   push @types, ($1 ? 'withSubst' : 'isSubst') if ($expl || '') =~ /\sSubst\{(\S*\}\s+\S)?/;
   push @types, 'altGrInv' if $aInv;
   my $q = ("@types" =~ /\s/ ? "'" : '');
#   ($prefill, $fill) = ("<span class=l$title>$prefill", "$fill</span>");
   @types = " class=$q@types$q" if @types;
   my($T,$OPT) = ($opts && $opts->{ltr} ? ('bdo', ' dir=ltr') : ('span', ''));	# Just `span´ does not work in FF15
   $c = '⇅' if $aInv and $cc ne ($base_c || 'N/A');	# &nbsp;
   "<$T$OPT@types$title>$prefill$c$fill</$T>"
}

sub print_table_coverage ($$;$$) {
  my ($self, $F, $html, $extra_headers) = (shift, shift, shift, shift || '');
  my $file = $self->{'[file]'};
  my $app = (defined $file and @$file > 1 and 's');
  my $f = (defined $file) ? "file$app @$file" : 'string descriptor';
  my $v = $self->{VERSION};
  $f .= " version $v" if defined $v;
  $f .= " Unicode tables version $self->{uniVersion}" if defined $self->{uniVersion};
  print <<EOP if $html;
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN"
  "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head><meta http-equiv="Content-Type" content="text/html; charset=UTF-8"/>
<!-- Generated with UI::KeyboardLayout v$UI::KeyboardLayout::VERSION for $f, face=$F -->
$extra_headers<style type="text/css"><!--
  /* <!-- Font size 10pt OK with Landscape Letter PaperSize, 0.1in margins, no footer, %96 for Latin, %150 for Cyrillic of izKeys --> */
  table.coverage	{ font-size: 10pt; font-family: sans-serif, DejaVu Sans, serif, junicode, Symbola; }
  .dead			{ font-size: 50%; color: red; }
  .dead_i		{ font-size: 50%; background-color: red; color: white; }
  .altGrInv		{ font-size: 70%; background-color: red; }
  .vbell		{ color: SandyBrown; }
  .withSubst		{ outline: 1px dotted blue;  outline-offset: -1px; }
  .isSubst		{ outline: 1px solid blue;  outline-offset: -1px; }
  .operator		{ background-color: rgb(255,192,203)	/*pink*/; }
  .relation		{ background-color: rgb(255,160,122)	/*lightsalmon*/; }
  .ipa			{ background-color: rgb(173,255,47)	/*greenyellow*/; }
  .nAry			{ background-color: rgb(144,238,144)	/*lightgreen*/; }
  .paleo		{ background-color: rgb(240,230,140)	/*Khaki*/; }
  .viet			{ background-color: rgb(220,220,220)	/*Gainsboro*/; }
  .doubleaccent		{ background-color: rgb(255,228,196)	/*Bisque*/; }
  .ZW			{ background-color: rgb(220,20,60)	/*crimson*/; }
  .WS			{ background-color: rgb(128,0,0)	/*maroon*/; }
  span.lFILL[convention]:before		{ content: attr(convention); 
					  color: white; 
					  font-size: 50%; }
  .lFILL:not([convention])	{ margin: 0ex 0.35ex; }
  .l			{ margin: 0ex 0.06ex; }
  .yyy			{ padding: 0px !important; }
  td.headerbase		{ font-size: 50%; color: blue; }
  td.header		{ font-size: 50%; color: green; }
  table			{ border-collapse: collapse; margin: 0px; padding: 0px; }
  body			{ margin: 1px; padding: 0px; }
  tr, td, .yyy {
    padding: 0px 0.2ex !important;
    margin:  0px       !important;
    border:  0px       !important;
  }
  tr.headerRow		{ border-bottom:	1px solid green	!important;}
  tr.lastKeyInKRow	{ border-bottom:	1px solid red	!important;}
  tr:hover		{ background-color:	#fff6f6; }
  tr.headerRow:hover	{ background-color:	#fff; }

  col.column1		{ border-right:		1px solid green	!important;}
  col.endPair		{ border-right:		1px solid SandyBrown	!important;}
  col.pre_ExtraCols	{ border-right:		1px solid green	!important;}

//--></style> 
</head>
<body>
<table class=coverage>
EOP
  my($LL, $INV, %s, @d, %access, %docs) = ($self->{faces}{$F}{layers}, $self->{faces}{$F}{'[Flip_AltGr_Key]'});
  $s{$self->charhex2key($INV)}++ if defined $INV;	# Skip in reports	'
  my @LL = map $self->{layers}{$_}, @$LL;
  $s{$_}++ or push @d, $_ for map @{ $self->{faces}{$F}{"[$_]"} || [] }, qw(dead_array dead_in_VK_array extra_report_DeadChar);
  my (@A, %isD2, @Dface, @DfaceKey, %d_seen) = [];
  my $compK = $self->{faces}{$F}{'[ComposeKeys]'};
#warn 'prefix keys to report: <', join('> <', @d), '>';
  for my $ddK (@d) {
    (my $dK = $ddK) =~ s/^\s+//;
    my $c = $self->key2hex($self->charhex2key($dK));
    next if $d_seen{$c}++;
    ($compK->{$c} or warn("??? Skip non-array prefix key `$c' for face `$F', k=`$dK'")), next 
      unless defined (my $FF = $self->{faces}{$F}{'[deadkeyFace]'}{$c});
    $access{$FF} = [$self->charhex2key($dK)];
    push @Dface, $FF;
    push @DfaceKey, $c;
    $docs{$FF} = $self->{faces}{$F}{'[prefixDocs]'}{$c};	# and warn "Found docs: face=`$F', c=`$c'\n";
    push @A, [$self->charhex2key($dK)];
  }

  my ($lastDface, $prevCol, $COLS, @colOrn, %S, @joinedPairs) = ($#Dface, -1, '', [qw(0 column1)]);
  for my $kk (split /\p{Blank}+\|{3}\p{Blank}+/, 
  		(defined $self->{faces}{$F}{faceDeadKeys} ? $self->{faces}{$F}{faceDeadKeys} : ''), -1) {
    my $cnt = 0;
    length and $cnt++ for split /\p{Blank}+/, $kk;
    push @joinedPairs, $cnt;
  }
  pop @joinedPairs;
  my $done = 0;
  push @colOrn, [$done += $_, 'endPair'] for @joinedPairs;
  my @skip_sections;
  for my $s (values %start_SEC) {
    $skip_sections[$_]++ for $s->[0]..($s->[0]+$s->[1]-1);
  }

  for my $reported (1, 0) {
    for my $DD (@{ $self->{faces}{$F}{$reported ? 'LayoutTable_add_double_prefix_keys' : 'faceDeadKeys2'} }) {
      (my $dd = $DD) =~ s/^\s+//;
      # XXXX BUG in PERL???  This gives 3:  DB<4> x scalar (my ($x, $y) = split //, 'ab')
      2 == (my (@D) = split //, $self->stringHEX2string($dd)) or die "Not a double character in LayoutTable_add_double_prefix_keys for `$F': `$DD' -> `", $self->stringHEX2string($dd), "'";
      my $map1 = $self->{faces}{$F}{'[deadkeyFaceHexMap]'}{$self->key2hex($D[0])}
        or ($reported ? die "Can't find prefix key face for `$D[0]' in `$F'" : next);	# inverted faces bring havoc
      defined (my $Dead2 = $map1->{$self->key2hex($D[1])}) or die "Can't map `$D[1]' in `$F'+prefix `$D[0]'";	# in hex already
      $Dead2 = $Dead2->[0] if 'ARRAY' eq ref $Dead2;
      defined (my $ddd = $self->{faces}{$F}{'[deadkeyFace]'}{$Dead2}) or die "Can't find prefix key face for `$D[1]' -> `$Dead2' in `$F'+prefix `$D[0]'";
      next if $S{"@D"}++;
      push(@Dface, $ddd), push @DfaceKey, $Dead2 if $reported;
      $access{$ddd} ||= \@D;
      $docs{$ddd} = $self->{faces}{$F}{'[prefixDocs]'}{$Dead2};
      push @A, \@D if $reported;
# warn "set is_D2: @D";
      $isD2{$D[0]}{$D[1]}++;
    }
  }
  push @colOrn, [$lastDface+1, 'pre_ExtraCols'] if $#Dface != $lastDface;
  for my $orn (@colOrn) {
    my $skip = $orn->[0] - $prevCol - 1;
    warn("Multiple classes on columns of report unsupported: face=$F, col [@$orn]"), next if $skip < 0;
    $prevCol = $orn->[0];
    my $many = $skip > 1 ? " span=$skip" : '';
    $skip = $skip > 0 ? "\n    <col$many />" : '';
    $COLS .= "$skip\n    <col class=$orn->[1] />";
  }
  print <<EOP if $html;
  <colgroup>$COLS
  </colgroup>
EOP
  my ($k, $first_ctrl, $post_ctrl, @last_in_row) = (-1, map $self->{faces}{$F}{"[$_]"} || 0, qw(start_ctrl end_ctrl));
  $last_in_row[ $k += $_ ]++ for @{ $self->{faces}{$F}{'[geometry]'} || [] };
#warn 'prefix key faces to report: <', join('> <', @Dface), '>';
  my @maps = (undef, map $self->{faces}{$F}{'[deadkeyFaceHexMap]'}{$_}, @DfaceKey);	# element of Dface may be false if this is non-autonamed AltGr-inverted face
  my $dead   = $html ? "<span class=dead   title='what follows is a prefix key; find the corresponding column'>\x{2620}</span>" : "\x{2620}";
  my $dead_i = $html ? "<span class=dead_i title='what follows is a prefix key with AltGr-invertion; find the matching column'>\x{2620}</span>" : "\x{2620}";
  my $header = '';
  for my $dFace ('', @Dface) {		# '' is no-dead
    my $base_t = 'Characters immediately on keys (without prefix keys); the first two are without/with Shift, two others same, but with added AltGr (excluding the special-key zone)';
    my $prefix_t = 'After tapping a prefix key, the base keys are replaced by what is in the column of the prefix key';
    $header .= qq(    <td align=center class=headerbase title=' '><span title='$base_t'>↓Base</span> <span title='$prefix_t'>Prefix→</span></td>), next unless $dFace;
    my @a = map {(my $a = $_) =~ s/^(?=$rxCombining)/\x{25cc}/o; $a } @{ $access{$dFace} };
    my $docs = $docs{$dFace};
    $docs =~ s/([''&])/sprintf '&#x%02x;', ord $1/ge if $docs;
    my $withDocs = (defined $docs ? "<span title='$docs'>@a</span>" : "@a");
    $header .= "    <td align=center class=header>$withDocs</td>";
  }
  print "  <thead><tr class=headerRow title='Prefix key (or key sequence) accessing this column.  To find how to type the prefix key, find it preceded by ☠ in the table below (mostly in the base column)'>$header</tr></thead>\n  <tbody>\n"
    if $html;
  my $vbell = '♪';
  my $OOut = '';
  for my $n ( 0 .. $#{ $LL[0] } ) {
    my ($out, $out_c, $prev, @KKK, $base_c) = ('', 0, '');
    my @baseK;
    next if $n >= $first_ctrl and $n < $post_ctrl or $skip_sections[$n] or $n >= $LAST_SEC;
    for my $dn (0..@Dface) {		# 0 is no-dead
      next if $dn and not $maps[$dn];
      $out .= $html ? '</td><td>' : ($prev =~ /\X{7}/ ? ' ' : "\t") if length $out;
      my $is_D2 = $isD2{ @{$A[$dn]} == 1 ? $A[$dn][0] : 'n/a' };		
# warn "is_D2: ", $self->array2string([$dn, $is_D2, $A[$dn], $A[$dn][0]]);
      my $o = '';
      for my $L (0..$#$LL) {
        for my $shift (0..1) {
          my $c = $LL[$L][$n][$shift];
          my ($pre, $expl, $C, $expl1, $invert_dead) = ('', '', $c);
          $o .= ' ', next unless defined $c;
          $out_c++;
          $pre = $dead    if not $dn and 'ARRAY' eq ref $c and $c->[2];
          $c = $c->[0]    if 'ARRAY' eq ref $c;
          $KKK[$L][$shift] = $c unless $dn;
          $base_c = $KKK[$L][$shift];
#	warn "int_struct -> dead; face `$F', KeyPos=$n, Mods=$L, shift=$shift, ch=$c\n" if $pre;
          if ($dn) {
            $C = $c = $maps[$dn]{$self->key2hex($c)};
            $c = $vbell unless defined $c;
            $invert_dead = (3 == ($c->[2] || 0) || (3 << 3) == ($c->[2] || 0)) if ref $c;
            $pre = $invert_dead ? $dead_i : $dead if 'ARRAY' eq ref $c and $c->[2];
	    $c = $c->[0]    if 'ARRAY' eq ref $c;
	    $c = $self->charhex2key($c);
          } else {
#            warn "coverage0_prefix -> dead; face `$F', KeyPos=$n, Mods=$L, shift=$shift, ch=$c\n" if $self->{faces}{$F}{'[coverage0_prefix]'}{$c};
            $invert_dead = (3 == ($c->[2] || 0) || (3 << 3) == ($c->[2] || 0)) if ref $c;
            $pre = $invert_dead ? $dead_i : $dead if $pre or $self->{faces}{$F}{'[coverage0_prefix]'}{$c};
          }
	  $baseK[$L][$shift] = $c unless $dn;
	  $pre ||= $dead if $dn and $is_D2->{$baseK[$L][$shift]};

	  if ($html) {
	    $c = $self->char_2_html_span($base_c, $C, $c, $F, {ltr => 1}, 'l');
	  } else {
            $c =~ s/(?=$rxCombining)/\x{25cc}/go;	# dotted circle ◌ 25CC
            $c =~ s{([\x00-\x1F\x7F])}{ $self->control2prt("$1") }ge;
          }
          $c = "$pre$c";
          $o .= $c;
        }
      }
      $o =~ s/ +$//;
      $prev = $o;
      $out .= $o;
    }
    my $class = $last_in_row[$n] ? ' class=lastKeyInKRow' : '';
    $out = "    <tr$class><td><bdo dir=ltr>$out</bdo></td></tr>" if $html;	# Do not make RTL chars mix up the order
    $OOut .= "$out\n", print "$out\n" if $out_c;
  }
  my @extra = map {(my $s = $_) =~ s/^\s+//; "\n\n<p>$s"} @{ $self->{faces}{$F}{TableSummaryAddHTML} || [] };
  my $create_a_c = $self->{faces}{$F}{'[create_alpha_ctrl]'};
  $create_a_c = $create_alpha_ctrl unless defined $create_a_c;
  my $extra_ctrl = ($create_a_c >= 1) && '/[/]/\\';
  $extra_ctrl .= ($create_a_c >= 2) && '/^/_';
  my $more .= ($create_a_c >= 1) && ' Most of Ctrl-letters are omitted from the table; deduce them from reports for C/H/I/J/M/Z.';
  print <<EOP if $html;
  </tbody>
</table>

@extra<p>Highlights (homographs and special needs): zero-width or SOFT HYPHEN: <span class=ZW><span class=l title="ANY ZEROWIDTH CHAR"><span class=lFILL></span></span></span>, whitespace: <span class=WS><span class=l title="ANY SPACE CHAR"> <span class=lFILL></span></span></span>, <span class=viet>Vietnamese</span>; <span class=doubleaccent>other double-accent</span>; <span class=paleo>paleo-Latin</span>; 
or <span class=ipa>IPA</span>.
Or name having <span class=relation>RELATION, PERPENDICULAR,
PARALLEL, DIVIDES, FRACTION SLASH</span>; or <span class=nAry>BIG, LARGE, N-ARY, CYRILLIC PALOCHKA/DZE/JE/QA/WE/A-IE, 
ANO TELEIA, KORONIS, PROSGEGRAMMENI, GREEK QUESTION MARK, SOF PASUQ, PUNCTUATION GERESH/GERSHAYIM</span>; or <span class=operator>OPERATOR, SIGN, 
SYMBOL, PROOF, EXISTS, FOR ALL, DIVISION, LOGICAL</span>; or <span class=altGrInv>AltGr-inverter prefix</span>;
or via a rule <span class=withSubst>involving</span>/<span class=isSubst>exposing</span> a “BlueKey” substitution rule.
(Some browsers fail to show highlights for whitespace/zero-width.)
<p>Vertical lines separate: the column of the base face, paired 
prefix keys with “inverted bindings”, and explicitly selected multi-key prefixes.  Horizontal lines separate key rows of
the keyboard (including a fake row with the “left extra key” [one with <code>&lt;&gt;</code> or <code>\\|</code> - it is missing on many keyboards]
and the <code>KP_Decimal</code> key [often marked as <code>. Del</code> on numeric keypad]); the last group is for semi-fake keys for
<code>Enter/C-Enter/Backspace/C-Backspace/Tab</code> and <code>C-Break$extra_ctrl</code> (make sense after prefix keys) and special keys explicitly added
in <b>.kbdd</b> files (usually <code>SPACE</code>).$more
<p>Hover mouse over any appropriate place to get more information.
In popups: brackets enclose Script, Range, “1st Unicode version with this character”;
braces enclose “the reason why this position was assigned to this character” (<code>VisLr</code> means that a visual table was 
used; in <code>Subst{HOW}</code>, <code>L=Layer</code> and <code>F=Face</code> mean that a “BlueKey” substitution
rule was defined via a special layer/face — see C<AlternCharSubstitutions>, C<AlternCharSubstitutionFaces> and C<AlternCharSubstitutionLayers>).
</body>
</html>
EOP
  $OOut
}

sub coverage_face0 ($$;$) {
  my ($self, $F, $after_import, $after) = (shift, shift, shift);
  my $H = $self->{faces}{$F};
  my $LL = $H->{layers};
  return $H->{'[coverage0]'} if exists $H->{'[coverage0]'};
  my (%seen, %seen_prefix, %imported);
  my $d = { %{ $H->{'[DEAD]'} || {} }, %{ $H->{'[dead_in_VK]'} || {} } };
  # warn "coverage0 for `$F'" if $after_import;
  for my $l (@$LL) {
    my $L = $self->{layers}{$l};
    for my $k (@$L) {
      warn "Face `$F', layer `$l': coverage check is run too late: after the importation translation is performed"         		   
      					    if not $after_import and $F !~ /^(.*)##Inv#([a-f0-9]{4,})$/is and grep {defined and ref and $_->[4]} @$k;
      $seen{ref() ? $_->[0] : $_}++	   for grep {defined and !(ref and $_->[2]) and !$d->{ref() ? $_->[0] : $_}} @$k;
      $seen_prefix{ref() ? $_->[0] : $_}++ for grep {defined and (ref and $_->[2] or $d->{ref() ? $_->[0] : $_})} @$k;
      $imported{"$_->[0]:$_->[1]"}++	   for grep {defined and ref and 2 == ($_->[2] || 0)} @$k;		# exportable
    }
    unless ($after++) {
      $H->{'[layer0coverage0]'} = [sort keys %seen];
    }
  }
  $H->{'[coverage0_prefix]'} = \%seen_prefix;		# prefix keys available on $F
  $H->{'[coverage0]'} = [sort keys %seen];		# non-prefix chars available on $F
  $H->{'[coverage0oneUTF16]'} = [grep {  2>length and 0x10000 > ord } @{$H->{'[coverage0]'}}];	# may be easy-postfixes on Windows
# $H->{'[coverage0+]'}        = [grep {!(2>length and 0x10000 > ord)} @{$H->{'[coverage0]'}}];	# 1.74 has only partial support for these
  $H->{'[coverage0oneChar]'}  = [grep {  2>length                   } @{$H->{'[coverage0]'}}];	# only for stats
  $H->{'[coverage0multiChar]'} = [grep {  1<length                  } @{$H->{'[coverage0]'}}];	# only for stats
  $H->{'[imported]'} = [sort keys %imported];
  $H->{'[coverage0oneUTF16hash]'} = { map { ($_, 1) } @{ $H->{'[coverage0oneUTF16]'} } };
  $H->{'[coverage0]'};
}

# %imported is analysed: if manual deadkey is specified, this value is used, otherwised new value is generated and rememebered.
#   (but is not put in the keymap???]
sub massage_imported ($$) {
  my ($self, $f) = (shift, shift);
  return unless my ($F, $KKK) = $f =~ /^(.*)###([a-f0-9]{4,})$/is;
  my $H = $self->{faces}{$F};
  for my $i ( @{ $self->{faces}{$f}{'[imported]'} || [] } ) {
    my($k,$face) = $i =~ /^(.):(.*)/s or die "Unrecognized imported: `$i'";
    my $K;
    if (exists $H->{'[imported2key]'}{$i} or exists $H->{'[imported2key_auto]'}{$i}) {
      $K = exists $H->{'[imported2key]'}{$i} ? $H->{'[imported2key]'}{$i} : $H->{'[imported2key_auto]'}{$i};
    } elsif ($H->{'[coverage0_prefix]'}{$k} or $H->{'[auto_dead]'}{$k}) {	# it is already used
      # Assign a fake prefix key to imported map
      warn("Imported prefix keys exist, but Auto_Diacritic_Start is not defined in face `$F'"), return 
        unless defined $H->{'[first_auto_dead]'};
      $K = $H->{'[imported2key_auto]'}{$i} = $self->next_auto_dead($H);
    } else {		# preserve the prefix key
      $K = $H->{'[imported2key_auto]'}{$i} = $k;
      $H->{'[auto_dead]'}{$k}++;
    }
    my $LL = $self->{faces}{$face}{'[deadkeyLayers]'}{$self->key2hex($k)}
      or die "Cannot import a deadkey `$k' from `$face'";
    $LL = [@$LL];		# Deep copy, so may override
    my $KK = $self->key2hex($K);
    if (my $over = $H->{'[AdddeadkeyLayers]'}{$KK}) {
#warn "face `$F': additional bindings for deadkey $KK exist.\n";
	warn "  mk_tr_lyrs_st 0" if debug_stacking_ord;
      $LL = [$self->make_translated_layers_stack($over, $LL)];
    }
    $H->{'[imported2key_all]'}{"$k:$face"} = $self->charhex2key($KK);
    $H->{'[deadkeyLayers]'}{$KK} = $LL;
    my $new_facename = "$F#\@#\@#\@$i";
    $self->{faces}{$new_facename}{layers} = $LL;
    $H->{'[deadkeyFace]'}{$KK} = $new_facename;
    $self->link_layers($F, $new_facename, 'skipfix', 'no-slot-warn');

    $self->coverage_face0($new_facename);
  }
}

sub massage_imported2 ($$) {
  my ($self, $f) = (shift, shift);
  warn "... Importing into face=`$f" if debug_import;
  return unless my ($F, $KKK) = ($f =~ /^(.*)###([a-f0-9]{4,})$/is);		# what about multiple prefixes???
  return unless my $HH = $self->{faces}{$F}{'[imported2key_all]'};
  my $H  = $self->{faces}{$f};
  warn "Importing into face=`$F' prefix=$KKK" if debug_import;
  my $LL = $H->{layers};
  my @unresolved;
  for my $l (@$LL) {
    my $L = $self->{layers}{$l};
    for my $k (@$L) {
      for my $kk (grep {defined and ref and $_->[2]} @$k) {	# exportable
        $kk = [@$kk];		# deep copy
        if (2 == $kk->[2]) {	# exportable
          my $v = (defined $kk->[4] ? $kk->[4] : $kk->[0]);
          my $j = $HH->{"$v:$kk->[1]"};
  #        push(@unresolved, "$v:$kk->[1]"),
            warn "Can't resolve `$v:$kk->[1]' to an imported dead key, face=`$F' prefix=$KKK; layer=$l" 
              unless defined $j;
          warn "Importing `$v:$kk->[1]' as `$j', face=`$F' prefix=$KKK; layer=$l" if debug_import;
          @$kk[0,4] = ($j, $v);
        } else {
          #warn "massage_imported2: shift $kk->[2] <<= 3 key `$kk->[0]' face `$f' layer `$l'\n" if $kk->[2] >> 3;
          $kk->[2] >>= 3;		# ByPairs makes <<= 3 !
        }
      }
    }
  }
  delete $self->{faces}{$f}{'[coverage0]'};
  $self->coverage_face0($f, 'after_import');		# recalculate
#  $H->{'[unresolved_imported]'} = \@unresolved if @unresolved;
}

sub massage_char_substitutions($$) {	# Read $self->{Substitutions}
  my($self, $data) = (shift, shift);
  die "Too late to load char substitutions" if $self->{Compositions};
  for my $K (keys %{ $data->{Substitutions} || {}}) {
    my $arr = $data->{Substitutions}{$K};
    for my $S (@$arr) {
      my $s = $self->stringHEX2string($S);
      $s =~ s/\p{Blank}(?=\p{NonspacingMark})//g;
      die "Expect 2 chars in substitution rule; I see <$s> (from <$S>)" unless 2 == (my @s = split //, $s);
      $self->{'[Substitutions]'}{"<subst-$K>"}{$s[0]} = [[0, $s[1]]];	# Format as in Compositions
      $self->{'[Substitutions]'}{"<subst-$K>"}{lc $s[0]} = [[0, lc $s[1]]]
        if lc $s[0] ne $s[0] and lc $s[1] ne $s[1];
      $self->{'[Substitutions]'}{"<subst-$K>"}{uc $s[0]} = [[0, uc $s[1]]]
        if uc $s[0] ne $s[0] and uc $s[1] ne $s[1];
    }
  }
}

sub new_from_configfile ($$) {
  my ($class, $F) = (shift, shift);
  open my $f, '< :utf8', $F or die "Can't open `$F' for read: $!";
  my $s = do {local $/; <$f>};
  close $f or die "Can't close `$F' for read: $!";
#warn "Got `$s'";
  my $self = $class->new_from_configfile_string($s);
  push @{$self->{'[file]'}}, $F;
  $self;
}

sub parse_add_configfile ($$) {
  my ($self, $F) = (shift, shift);
  open my $f, '< :utf8', $F or die "Can't open `$F' for read: $!";
  my $s = do {local $/; <$f>};
  close $f or die "Can't close `$F' for read: $!";
#warn "Got `$s'";
  $self->parse_add_configstring($s, $self);
# Dumpvalue->new()->dumpValue($self);
  push @{$self->{'[file]'}}, $F;
  $self;
}

sub new_from_configfile_string ($$) {
    my ($class, $ss) = (shift, shift);
    die "too many arguments to UI::KeyboardLayout->new_from_configfile_string" if @_;
    my $self = $class->new;
    $self->parse_add_configstring($ss, $self);
# Dumpvalue->new()->dumpValue($self);
    $self->massage_full;
}

sub doout ($$) {my(undef, $in) = (shift,shift); return '[u/d]' unless defined $in; $in = $in->[0] if ref $in;  $in . chr hex $in};

sub massage_full($) {
    my $self = shift;
    my ($layers, $counts, $offsets) = $self->fill_kbd_layers($self);
    @{$self->{layers}}{keys %$layers} = values %$layers;
    @{$self->{layer_counts} }{keys %$counts} = values %$counts;
    @{$self->{layer_offsets}}{keys %$offsets} = values %$offsets;
    $self->massage_hash_values;
    $self->massage_diacritics;			# Read $self->{Diacritics}
    $self->massage_char_substitutions($self);	# Read $self->{Substitutions}
    $self->massage_faces;
    
    $self->massage_deadkeys_win($self);		# Process (embedded) MSKLC-style deadkey maps
    $self->scan_for_DeadKey_Maps();		# Makes a direct-access synonym, scan for DeadKey_Map* keys
    $self->create_DeadKey_Maps();
    $self->create_composite_layers;		# Needs to be after simple deadkey maps are known

    ### Not implemented yet!!! XXXXX ????  (The logic moved from output_deadkeys())
    for my $F (keys %{ $self->{faces} }) {	# Fine-tune inverted-AltGr faces
      next if 'HASH' ne ref $self->{faces}{$F} or $F =~ /\bVK$/;			# "parent" taking keys for a child
      next if $F =~ /#\@?#\@?(Inv)?#\@?/;		# Face-on-a-deadkey
      my $H = $self->{faces}{$F};

    my($flip_AltGr_hex, %nn) =  $H->{'[Flip_AltGr_Key]'};
    $flip_AltGr_hex = $self->key2hex($self->charhex2key($flip_AltGr_hex)) if defined $flip_AltGr_hex;
    for my $deadKey ( sort keys %{ $H->{'[deadkeyFaceHexMap]'} } ) {
      next if $H->{'[only_extra]'}{$self->charhex2key($deadKey)};

      next unless $deadKey eq ($flip_AltGr_hex || 'n/a');
      my($is_invAltGr_Base_with_chain, $invertAlt, $AMap) = (1, 1, {});	# XXXX under the preceding assumption only ???

      my $auto_inv_AltGr = $H->{'[deadkeyInvAltGrKey]'}{$deadKey};
      $auto_inv_AltGr = $self->key2hex($auto_inv_AltGr) if defined $auto_inv_AltGr;
##        (my $nonempty, my $MAP) = $self->output_deadkeys($F, $deadKey, $H->{'[dead2]'}, $flip_AltGr_hex, $auto_inv_AltGr);
##        $self->massage_main_Inv_AltGr($F);		# Moved from output_deadkeys()

  my($map_AltGr_over, $over_dead2);
  if (my $override_InvAltGr = $H->{'[InvAltGrFace]'}{''}) { # NOW: needed only for invAltGr
    $map_AltGr_over = $self->linked_faces_2_hex_map($F, $override_InvAltGr);
  }
  $over_dead2 = $H->{'[dead2]'}->{$self->charhex2key($flip_AltGr_hex)} || {} if defined $flip_AltGr_hex;	# used in CyrPhonetic v0.04
  my $dead2 = { %{ $H->{'[DEAD]'} }, %{ $H->{'[dead_in_VK]'} } };

  	## joined_map is a merge of enhanced-map (via alternative chars, like Menu-*), flat-map, and merged-multichar-map
  	my %joined_map = ();	# XXXX ????
    my @keys = sort keys %joined_map;			# Sorting not OK for 6-byte keys - but after joining they disappear
    my %sp;	# XXXX ????  Should be obtained from scancodes
    @keys = (grep((!/^d[89a-f]/i and  lc(chr hex $_) ne uc(chr hex $_)and not $sp{chr hex $_} ),		      @keys),
             grep((!/^d[89a-f]/i and (lc(chr hex $_) eq uc chr hex $_ and (chr hex $_) !~ /\p{Blank}/) and not $sp{chr hex $_}), @keys),
            grep((!/^d[89a-f]/i and ((lc(chr hex $_) eq uc chr hex $_ and (chr hex $_) =~ /\p{Blank}/) or $sp{chr hex $_}) and $_ ne '0020'), @keys),
             grep(                                                  /^d[89a-f]/i,  @keys),	# 16-bit surrogates
             grep(				                    $_ eq '0020',  @keys));	# make SPACE last
    for my $n (@keys) {	# Only 4-byte keys reach this (except for Apple)
      my ($alt_n, $use_dead2) = (($is_invAltGr_Base_with_chain and defined $map_AltGr_over->{$n})
        			 ? ($n, $over_dead2) 
        			 : (($invertAlt ? $AMap->{$n} : $n), $dead2));
    }
      }
    }

    for my $F (keys %{ $self->{faces} }) {
      next if 'HASH' ne ref $self->{faces}{$F} or $F =~ /\bVK$/;			# "parent" taking keys for a child
      $self->coverage_face0($F);		# creates coverage0, imported array (c0 excludes diacritics), coverage0_prefix hash
    }
    for my $F (sort keys %{ $self->{faces} }) {
      next if 'HASH' ne ref $self->{faces}{$F} or $F =~ /\bVK$/;			# "parent" taking keys for a child
      $self->massage_imported($F);		# calc new values for imported prefix keys, augments imported maps with Add-maps
    }
    for my $F (keys %{ $self->{faces} }) {
      next if 'HASH' ne ref $self->{faces}{$F} or $F =~ /\bVK$/;			# "parent" taking keys for a child
      $self->massage_imported2($F);		# changes imported prefix keys to appropriate values for the target personality
    }
    $self->create_prefix_chains;
    $self->create_inverted_faces;
    $self->link_composite_layers;		# Needs to be after imported keys are reassigned...
    for my $F (keys %{ $self->{faces} }) {	# Fine-tune inverted-AltGr faces
      next if 'HASH' ne ref $self->{faces}{$F} or $F =~ /\bVK$/;			# "parent" taking keys for a child
      next if $F =~ /#\@?#\@?(Inv)?#\@?/;		# Face-on-a-deadkey

      my $D = $self->{faces}{$F}{'[deadkeyFace]'};
      my $Ex = $self->{faces}{$F}{'[AltGr_Invert_Show]'};
      for my $d (keys %$D) {
        $self->{faces}{$F}{'[deadkeyFaceHexMap]'}{$d} = $self->linked_faces_2_hex_map($F, $D->{$d});
        defined (my $auto_inv_AltGr = $self->{faces}{$F}{'[deadkeyInvAltGrKey]'}{$d}) or next;
	my $b1 = $self->{faces}{$F}{'[deadkeyFaceInvAltGr]'}{my $a = $self->charhex2key($auto_inv_AltGr)};
        $self->{faces}{$F}{'[deadkeyFaceHexMapInv]'}{$d} = $self->linked_faces_2_hex_map($F, $b1) if $b1;
        my $D = $self->{faces}{$F}{'[prefixDocs]'}{$d};
        $self->{faces}{$F}{'[prefixDocs]'}{$self->key2hex($a)} = 'AltGr-inverted: ' . (defined $D ? $D : "[[$d]]");
        my $S = $self->{faces}{$F}{'[Show]'}{$d};
        $self->{faces}{$F}{'[Show]'}{$self->key2hex($a)} = (defined $S ? $S : $self->charhex2key($d)) . $Ex;
      }

      my($flip_AltGr, @protect_chr) = $self->{faces}{$F}{'[Flip_AltGr_Key]'};	# Who put it into deadkeyFace???
      if (defined $flip_AltGr) {
        $flip_AltGr = $self->key2hex($self->charhex2key($flip_AltGr));
        push @protect_chr, $flip_AltGr;
        $self->{faces}{$F}{'[prefixDocs]'}{$flip_AltGr} = 'AltGr-inverted base face'
          unless defined $self->{faces}{$F}{'[prefixDocs]'}{$flip_AltGr};
        $self->{faces}{$F}{'[Show]'}{$flip_AltGr} = $Ex unless defined $self->{faces}{$F}{'[Show]'}{$flip_AltGr};
      }
      my $expl = $self->{faces}{$F}{'[Explicit_AltGr_Invert]'} || [];
      for my $i (1..(@$expl/2)) {
        my @C = map $self->key2hex($expl->[2*$i + $_]), -2, -1;
        push @protect_chr, $C[1];
        my $D = $self->{faces}{$F}{'[prefixDocs]'}{$C[0]};
        $self->{faces}{$F}{'[prefixDocs]'}{$C[1]} = 'AltGr-inverted: ' . (defined $D ? $D : "[[$C[0]]]");
        my $S = $self->{faces}{$F}{'[Show]'}{$C[0]};
        $self->{faces}{$F}{'[Show]'}{$C[1]} = (defined $S ? $S : $self->charhex2key($C[0])) . $Ex;
      }
      $self->{faces}{$F}{'[auto_dead]'}{ord $self->charhex2key($_)}++ for @protect_chr;
#      warn "   Keys HexMap: ", join ', ', sort keys %{$self->{faces}{$F}{'[deadkeyFaceHexMap]'}};
    }

    for my $F (sort keys %{ $self->{faces} }) {	# Finally, collect the reachable no-prefix keys (include extra), make Compose
      next if 'HASH' ne ref $self->{faces}{$F} or $F =~ /\bVK$/;			# "parent" taking keys for a child
      next if $F =~ /#\@?#\@?(Inv)?#\@?/;		# Face-on-a-deadkey
      my(%seenExtra, %seenExtraWithPrefix, %seenExtraPrefix);	# non-prefix, all, prefix-only
      my @extras = ( "@{ $self->{faces}{$F}{'[output_layers]'} || [''] }" =~ /\bprefix(?:\w*)=([0-9a-fA-F]{4,6}\b|.(?![^ ]))/g );
      my %is_extra = map { ($self->charhex2key($_), 1) } @extras;	# extra layers (on bizarre modifiers)
      for my $deadKEY ( sort keys %{ $self->{faces}{$F}{'[deadkeyFace]'}} ) {	# process Extra-basekeys
        my $deadKey = $self->charhex2key($deadKEY);
        next unless $is_extra{$deadKey};
	# warn "$F ExtraPrefix=$deadKEY\n";
        my($FFF,$C) = $self->{faces}{$F}{'[deadkeyFace]'}{$deadKEY};
        my $cov0 = $self->{faces}{$FFF}{'[layer0coverage0]'}	# non-prefix base keys: can access all of these
          or warn("Deadkey `$deadKey' on face `$F' -> unmassaged face"), next;
          	# XXXX this is heuristical only: we do not actually check sliding down and/or multi-codepoing!!! ???
        my $cov1 = $self->{faces}{$FFF}{'[coverage0]'};	# non-prefix; may slide down; may access with AltGr-invertor if not multi-codepoint
        $seenExtraWithPrefix{$_}++, $seenExtra{$_}++          for map {ref() ? $_->[0] : $_} @$cov1;
        $seenExtraWithPrefix{$_}++, $seenExtraPrefix{$_}++    for keys %{$self->{faces}{$FFF}{'[coverage0_prefix]'}};
      }
      $self->{faces}{$F}{'[coverageExtra]'} = \%seenExtra;
      $self->{faces}{$F}{'[coverageExtraPrefix]'} = \%seenExtraPrefix;
      $self->{faces}{$F}{'[coverageExtraInclPrefix]'} = \%seenExtraWithPrefix;	# used in massage_flat_maps_extra_keys()
      # warn "$F coverageExtraPrefix; ". join('  ', keys %seenExtraPrefix) . "\n" if keys %seenExtraPrefix;
      warn "$F coverageExtraPrefix HIDDEN; ", join('  ', grep !$self->{faces}{$F}{'[deadkeyFace]'}{$_},
						map $self->key2hex($_), sort keys %seenExtraPrefix) . "\n" if keys %seenExtraPrefix;
      
      next unless my $prefix = $self->{faces}{$F}{'[ComposeKey]'};
      $self->auto_dead_can_wrap($F);					# All manual deadkeys are set, so auto may be flexible
      $self->create_composekey($F, $prefix);
    }

    $self->massage_flat_maps_extra_keys();	# Process Flat extra maps (used on Windows only); fill FlatPrefixMapFiltered, report results

    for my $F (sort keys %{ $self->{faces} }) {	# Handle enhanced maps (used on Windows only)
      next if 'HASH' ne ref $self->{faces}{$F} or $F =~ /\bVK$/;			# "parent" taking keys for a child
      next if $F =~ /#\@?#\@?(Inv)?#\@?/;		# Face-on-a-deadkey
      my $H = $self->{faces}{$F};
      next unless defined( my $enhGray = $H->{'[Prefix_Base_Altern]'} );
      $self->export_layers($enhGray, $F);			# Process recipes
      $self->face_make_backlinks($enhGray, undef, undef, 'skipfix');	# no prefer-1st/last; without skipfix errors on 2nd call
      my %enhForce = map {($self->keys2hex($_), 1)} @{$H->{'[Prefix_Force_Altern]'} || []};
      for my $deadKey ( sort keys %{ $H->{'[deadkeyFaceHexMap]'} } ) {
        next if $H->{'[only_extra]'}{$self->charhex2key($deadKey)};
        next unless my $dF = $H->{'[deadkeyFace]'}{$deadKey};	# may be Compose etc
#        if ("$F//$deadKey" eq "Latin//00a3") {
#          my $layers = $H->{'[deadkeyLayers]'}{$deadKey};
#	  warn " make enh map $F//$deadKey: `$_': ", $self->layer2string($self->{layers}{$_}), "\n" for @$layers;
#        }
    #	or warn "d=$deadKey; <", join(' ', keys %{$H->{'[deadkeyFace]'}}), '>';
        $self->faces_link_via_backlinks($enhGray, $dF);
        $H->{'[enhGrayHexMaps]'}{$deadKey} = my $enhMaps = [map $self->linked_faces_2_hex_map($enhGray, $dF, $_), 0, 1];	# 2 maps
        $H->{'[enhGrayHexMapsForce]'}{$deadKey} = [map {	# submaps made of keys in 'Prefix_Force_Altern' and with defined values
	  my $m = $enhMaps->[$_];			# These bindings are prefered to those present also on non-enhGray maps
	  + { map { ($_, $m->{$_})} grep {$enhForce{$_} and defined $m->{$_}} keys %$m }} (0, 1)];
        my @LLL = map $self->{layers}{$_}, @{ $self->{faces}{$dF}{layers} };
        my($n, %agi_ctrl) = '[]';
        if (defined $self->{faces}{$F}{'[Flip_AltGr_Key]'} or defined $self->{faces}{$F}{'[invAltGr_Accessor]'}) {
          my ($first_ctrl, $post_ctrl) = map $self->{faces}{$F}{"[$_]"} || 0, qw(start_ctrl0 end_ctrl);
          $n = "[$first_ctrl .. $post_ctrl]";
          for my $k ($first_ctrl .. $post_ctrl) {
            for my $shft ('','s') {
              my $kk = "agi_c${shft}_" . ($k-$first_ctrl);
              my $c = $LLL[1][$k][!!$shft];
              $agi_ctrl{$kk} = $c;
            }
          }
        }
        $self->{faces}{$F}{'[Inv_AltGr_Ctrl_Keys]'}{$deadKey} = \%agi_ctrl;
#        warn " agi_ctrl($F : $deadKey $n): ", join ' ', map {defined() ? (ref() ? $_->[0] : $_) : '[u/d]'} %agi_ctrl, "\n";
      }
    }

    for my $F (sort keys %{ $self->{faces} }) {	# Finally, collect the stats
      next if 'HASH' ne ref $self->{faces}{$F} or $F =~ /\bVK$/;			# "parent" taking keys for a child
      next if $F =~ /#\@?#\@?(Inv)?#\@?/;		# Face-on-a-deadkey
      my $H = $self->{faces}{$F};
      my($prefix_in_base, %SEEN, %seen0oneUTF16, %seen1, %seen1only, %seenExtra) = $H->{'[coverage0_prefix]'};
      # warn("Face `$F' has no [deadkeyFace]"), 
      next unless $H->{'[deadkeyFace]'};
#      next;
      my (%check_later, %coverage1_prefix, %prefix_with_1prefix,  %prefix_with_2prefices, @difficult, %difficult, %reach_how);
#      warn "......  face `$F',\tprefixes0 ", keys %$prefix_in_base;
#      $prefix_in_base = {%$prefix_in_base};			# Deep copy
#      $prefix_in_base->{$_}++ for @{ $H->{'[dead_in_VK_array]'} || [] };
      my @extras = ( "@{ $H->{'[output_layers]'} || [''] }" =~ /\bprefix(?:\w*)=([0-9a-fA-F]{4,6}\b|.(?![^ ]))/g );
      my %is_extra = map { ($self->charhex2key($_), 1) } @extras;	# extra layers (on bizarre modifiers)
      $reach_how{$_} = 'b', $difficult[0]{$_}++ for @{ $H->{'[coverage0]'} };
      $reach_how{$_} ||= '', $reach_how{$_} .= 'e', $difficult[1]{$_}++ for keys %{ $H->{'[coverageExtra]'} };
      
      for my $pass (1,2,3) {
       for my $deadKEY ( sort keys %{ $H->{'[deadkeyFace]'}} ) {
        unless (%SEEN) {				# Do not calculate if $F has no deadkeys...
          $seen0oneUTF16{$_}++ for @{ $H->{'[coverage0oneUTF16]'} };
          %SEEN = %seen0oneUTF16;	# XXX $SEEN includes $seen0oneUTF16 and $seen1 ???
        }
        ### XXXXX Directly linked faces may have some chars unreachable via the switch-prefixKey
        my ($deadKey, $not_in_base, $in_1prefix, $in_2prefices, $dK_of_extra) = $self->charhex2key($deadKEY);
        # It does not make sense to not include it into the summary: 0483 on US is such...
        $not_in_base++, $check_later{$deadKey}++ unless $prefix_in_base->{$deadKey};	# For multi-prefix maps, and extra layers
        next if $pass > 1 and not $not_in_base or $pass == 1 and $not_in_base;		# 1st: in base; 2nd: needs 1 prefix
        $in_1prefix = $prefix_with_1prefix{$deadKEY} if $pass > 1 and $not_in_base;
        next if $pass == 2 and not $in_1prefix or $pass > 2 and $in_1prefix;		# Third: 1 prefix is not enough
        $in_2prefices = $prefix_with_2prefices{$deadKEY} if $pass == 3 and ($not_in_base and not $in_1prefix);
        
        $dK_of_extra = $H->{'[coverageExtraPrefix]'}{$deadKey};	# compose keys are not in deadkeyFace, so we do not see them here
        # warn "See $F\[$deadKEY] from extra only" if $not_in_base and $dK_of_extra;
        my ($FFF, @dd2) = $H->{'[deadkeyFace]'}{$deadKEY};
        my $cov1 = $self->{faces}{$FFF}{$is_extra{$deadKey} ? '[coverage0]' : '[coverage0oneUTF16]'}	# XXXX not layer0coverage0 - may slide down to layer0
          or warn("Deadkey `$deadKey' on face `$F' -> unmassaged face"), next;
        my($map, %haveChar, %havePref, %cDifc) = $self->linked_faces_2_hex_map($F, $FFF);	# hex → hex
        my $enhGrayMapsForce = $H->{'[enhGrayHexMapsForce]'}{$deadKEY} || [{},{}];	# prefered to those present also on non-extra maps
        delete $map->{$_} for keys %{$enhGrayMapsForce->[0]}, keys %{$enhGrayMapsForce->[1]};
        $cDifc{$_} = 1, $haveChar{$_} = '1①2②3③9⑨' for grep defined, map {($_ and ref $_) ? $_->[0] : $_} grep ($_ and not (ref $_ and $_->[2])), values %$map;
        $havePref{$_} = 1    for grep defined, map {($_ and ref $_) ? $_->[0] : $_} grep ($_ and     (ref $_ and $_->[2])), values %$map;
        if (my $Emap = $H->{'[enhGrayHexMaps]'}{$deadKEY}) {
#          warn "map/emap $F [$deadKEY]: @{[%$map]}[0,1] / @{[%{$Emap->[0]}]}[0,1]\n";
          my %mapAltGr  = map {("0$_", $Emap->[1]{$_})} keys %{$Emap->[1]};
          my %mapF = ((map {("0$_", $enhGrayMapsForce->[1]{$_})} keys %{$enhGrayMapsForce->[1]}), %{$enhGrayMapsForce->[0]});
	  for my $extrakeyMap ($Emap->[0] || {}, \%mapAltGr) {
	    warn " ... extra-key map $F [$deadKEY]: ", join(' ' ,
 		map {$_ . (chr hex) . " ⇒ " . $self->doout($extrakeyMap->{$_})} sort keys %$extrakeyMap), "\n" if warnReached and %$extrakeyMap;
#  warn " ... wholemap $F [$deadKEY]: ", join(' ' ,
#	map {$_ . (chr hex) . " ⇒ " . $self->doout($map->{$_})} sort keys %$map), "\n"; # if warnReached and %$map;
	  }
          $cDifc{$_} ||= 2, $haveChar{$_} ||= 'ⓔⒺₑEᵉᴱεέ' for grep defined, map {($_ and ref $_) ? $_->[0] : $_} grep ($_ and not (ref $_ and $_->[2])), values %{$Emap->[0]};
          $cDifc{$_} ||= 4, $haveChar{$_} ||= 'ⓐⒶaAᵃᴬαά' for grep defined, map {($_ and ref $_) ? $_->[0] : $_} grep ($_ and not (ref $_ and $_->[2])), values %mapAltGr;
          $havePref{$_} ||= 'E'                          for grep defined, map {($_ and ref $_) ? $_->[0] : $_} grep ($_ and     (ref $_ and $_->[2])), values %{$Emap->[0]}, values %mapAltGr;
        }
        my($mapAi_C, $flat) = ($H->{'[Inv_AltGr_Ctrl_Keys]'}{$deadKEY} || {}, $H->{"[FlatPrefixMapAccessibleHex]"}{$deadKEY} || {});
# warn " lookup flat  $F / $deadKEY: <", join("> <", %$flat), ">\n";
# warn " lookup ACtrl $F / $deadKEY: <", join("> <", map $_->[0], grep defined, values %$mapAi_C), ">\n";
        $cDifc{$_} ||= 3, $haveChar{$_} ||= '⇑⇡⤊⥀^ˆ⦽ꞈ' for map $self->key2hex($_), grep defined, map {($_ and ref $_) ? $_->[0] : $_} grep ($_ and not (ref $_ and $_->[2])), values %$mapAi_C;
        $havePref{$_} ||= '⇑'                          for map $self->key2hex($_), grep defined, map {($_ and ref $_) ? $_->[0] : $_} grep ($_ and     (ref $_ and $_->[2])), values %$mapAi_C;
          $SEEN{$self->charhex2key($_)}++,
        $cDifc{$_} ||= 2, $haveChar{$_} ||= 'ⓕⒻƒFᶠℱφΦ' for grep defined, map {($_ and ref $_) ? $_->[0] : $_} grep ($_ and not (ref $_ and $_->[2])), keys %$flat;
        $havePref{$_} ||= 'ⓕ'                          for grep defined, map {($_ and ref $_) ? $_->[0] : $_} grep ($_ and     (ref $_ and $_->[2])), keys %$flat;
        unless ($is_extra{$deadKey}) {
#	  my $is_extra = ($not_in_base ? ($dK_of_extra ? 1  :  2 ) : 0) + 3*($pass - 1);
	  my $diffclty = $pass - 1 + !!($pass == 3 and not $in_2prefices);
	  my $D = !!$dK_of_extra + 2*$diffclty;
	  for my $c (keys %haveChar) {
	    my $cc = $self->charhex2key($c);
            $reach_how{$cc} .= substr $haveChar{$c}, $D, 1;
            my $d = $diffclty + $cDifc{$c} + 1;		# base:0, every prefix = +2, extra modifier = +1 etc
            $difficult[$d]{$cc}++;
            $difficult{$cc}++;
          }
        }
        my %flat = map {("fl=$_", $_)} keys %$flat;
#	        warn "Flat in [$deadKEY] $F: ", join(' ', sort @reached), "\n" if warnReached;
  #    warn " agi_ctrl: ", join ' ', map {(not $_ or /agi/) ? $_ : $self->doout($_)} %agi_ctrl, "\n";
#        warn "   agi_ctrl($F : $deadKEY): ", join ' ', map {defined() ? (ref() ? $_->[0] : $_) : '[u/d]'} %$mapAi_C, "\n";

        my @reached = map $self->charhex2key($_), keys %haveChar;
#        my @reached_prefix = $self->charhex2key($_->[0]), grep +($_ and ref $_ and $_->[2]), values %$map;
        my(%reached, %u) = map +($_, 1), @reached;		# , map chr, 0..0x1F; control-chars ∉ the base map, but can be produced on Win
        warn "Reached in [$deadKEY] $F: ", join(' ', sort @reached), "\n" if warnReached;
### my @e = each %$map; warn "map-start $F=>$FFF: $e[0] <@{ref $e[1] ? $e[1] : [$e[1]||'---']}>\n";
        ($SEEN{$_}++ or $seen1{$_}++),		# micro-optimization
          $reached{$_} || $u{$_}++,
          ($not_in_base and not $is_extra{$deadKey}) || $seen0oneUTF16{$_} || $seen1only{$_}++,	# Only for multi-prefix maps
            for map {ref() ? $_->[0] : $_} grep !(ref and $_->[2]), @$cov1;	# Skip 2nd level deadkeys
#        !$is_extra{$deadKey} && ($reach_how{$_} ||= '', $reach_how{$_} .= (($not_in_base and $dK_of_extra) ? 'Ⓔ' : 'E')),
#          $_ eq '⏩' && warn "See ⏩ on [$deadKEY] !base=$not_in_base deadKey_of_ExtraFace=$dK_of_extra; of $F\n"
###          $is_extra{$deadKey} && $seenExtra{$_}++					# Only for extra modifiers maps
#            for keys %{$H->{'[coverageExtra]'}};
	%u and warn "Unreached: <<$_>> in [$deadKEY] of $F\n" for join ' ', sort keys %u;
        if (my $d2 = $H->{'[dead2]'}{$deadKey}) {
#          warn "linked map (face=$F) = ", keys %$d2;
          @dd2 = map $self->charhex2key($_), map {($_ and ref $_) ? $_->[0] : $_} map $map->{$self->key2hex($_)}, keys %$d2;
#          warn "sub-D2 (face=$F) = ", @dd2;
        }
        #warn "2nd level prefixes for `$deadKey': ",  keys %{$self->{faces}{$FFF}{'[coverage0_prefix]'} || {}};
        #warn "2nd level prefixes for `$deadKey':  <@dd2> ", keys %{$H->{'[dead2]'}{$deadKey} || {}};
        unless ($not_in_base) {
#          warn "sub-cov0 (face=$F) = ", keys %{ $self->{faces}{$FFF}{'[coverage0_prefix]'} || {} };
          $coverage1_prefix{$_}++  for keys %{ $self->{faces}{$FFF}{'[coverage0_prefix]'} || {} };  # XXXX prefix keys (maybe unreachable???)
#          warn "sub-D2 (face=$F) = ", @dd2;
          $coverage1_prefix{$_}++  for @dd2;
        }
#        warn "......  deadkey `$deadKey' reached0 in face `$F'" unless $not_in_base;
	%prefix_with_1prefix = (%prefix_with_1prefix, %havePref) if $pass == 1;		# Hex
	%prefix_with_2prefices = (%prefix_with_2prefices, %havePref) if $pass == 2;	# Hex
#	%prefix_with_3prefices = (%prefix_with_3prefices, %havePref) if $pass == 3;	# Hex
       }
      }
      for my $c (keys %difficult) {
        $difficult{$c} = 9;
        for my $d (0..8) {
          $difficult{$c} = $d, last if $difficult[$d]{$c};
        }
      }
      my @check      = grep { !$coverage1_prefix{$_} and !$is_extra{$_} } sort keys %check_later;  # dead: ∉ base ∪ 1-prefix ∪ extra
      my @only_extra = grep { !$coverage1_prefix{$_} and  $is_extra{$_} } sort keys %check_later;
      $H->{'[only_extra]'} = { map {($_, 1)} @only_extra };  # extra layers which are not reachable by 2 prefix keys

      my $_s = (@check > 1 ? 's' : '');
      warn("Prefix key$_s <@check> not reached (without double prefix keys?) in face `$F'; later=", sort(keys %check_later), " ; cov1=", sort keys %coverage1_prefix) if @check;
      $H->{'[coverage1]'} = [sort keys %seen1];
      $H->{'[coverage1only]'} = [sort keys %seen1only];
      $H->{'[coverage1only_hash]'} = \%seen1only;
      $H->{'[coverage_hash]'} = \%SEEN;
      $H->{'[coverage_how]'} = \%reach_how;
      $H->{'[coverage_difficulty]'} = \%difficult;
      warn "$F coverage_how: ", join('  ', map +"$_ $reach_how{$_}", sort keys %reach_how), "\n"
      	if warnReached and ( keys %{$H->{'[deadkeyFace]'}} or keys %{$H->{'[coverageExtra]'}} );
#      $H->{'[coverageExtra]'} = \%seenExtra;	# also done above???
    }
    $self
}

sub massage_deadkeys_win ($$) {
  my($self, $h, @process, @to) = (shift, shift);
  my @K = grep m(^\[unparsed]/DEADKEYS\b), @{$h->{'[keys]'}};
# warn "Found deadkey sections `@K'";
#  my $H = $h->{'[unparsed]'};
  for my $k (@K) {
    push @process, $self->get_deep($h, (split m(/), $k), 'unparsed_data');
    (my $k1 = $k) =~ s(^\[unparsed]/)();
    push @to, $k1
  }
  @K = grep m(^DEADKEYS\b), @{$h->{'[keys]'}};
  for my $k (@K) {
    my $slot = $self->get_deep($h, split m(/), $k);
    next unless exists $slot->{klc_filename};
    open my $fh, '< :encoding(UTF-16)', $slot->{klc_filename}
      or die "open of <klc_filename>=`$slot->{klc_filename}' failed: $!";
    local $/;
    my $in = <$fh>;
    push @process, $in;
    push @to, $k;
  }
  for my $k1 (@to) {
#warn "DK sec `$k' -> `$v', <", join('> <', keys %{$h->{'[unparsed]'}{DEADKEYS}{la_ru}}), ">";
#warn "DK sec `$k' -> `$v', <$h->{'[unparsed]'}{DEADKEYS}{la_ru}{unparsed_data}>";
    my $v = shift @process; 
    my($o,$d,$t) = $self->read_deadkeys_win($v);	# Translation tables, names, rest of input
    my (@parts, @h) = split m(/), $k1;
    my %seen = (%$o, %$d);
    for my $kk (keys %seen) {
#warn "DK sec `$k1', deadkey `$kk'. Map: ", $self->array2string( [%{$o->{$kk} || {}}] );
      my $slot = $self->get_deep($h, @parts, $kk);
      warn "Deadkey `$kk' defined for `$k1' conflicts with previous definition" 
        if $slot and grep exists $slot->{$_}, qw(map name);
      $self->put_deep($h, $o->{$kk}, @parts, $kk, 'map')  if exists $o->{$kk};
      $self->put_deep($h, $d->{$kk}, @parts, $kk, 'name') if exists $d->{$kk};
    }
  }
  $self
}

# http://bepo.fr/wiki/Pilote_Windows
# http://www.phon.ucl.ac.uk/home/wells/dia/diacritics-revised.htm#two
# http://msdn.microsoft.com/en-us/library/windows/desktop/ms646280%28v=vs.85%29.aspx

my %oem_keys = do {{ no warnings 'qw' ; reverse (qw(
     OEM_MINUS	-
     OEM_PLUS	=
     OEM_4	[
     OEM_6	]
     OEM_1	;
     OEM_7	'
     OEM_3	`
     OEM_5	\
     OEM_COMMA	,
     OEM_PERIOD	.
     OEM_2	/
     OEM_102	\#
     SPACE	#
     DECIMAL	.#
     DECIMAL	,#
     ABNT_C1	/#
     ABNT_C1	¥
     ABNT_C1	¦
)) }};			#'# Here # marks "second occurence" of keys...
		# Extra bindings: see http://www.fysh.org/~zefram/keyboard/xt_scancodes.txt (after “===”)
		# e005 Messenger (or Files); e007 Redo; e008 undo; e009 ApplicationLeft; e00a Paste;
		# e00b,e011,e012,e01f ScrollWheel-to-key-emulation
		# e013 Word; e014 Excel; e015 Calendar; e016 Log Off; e017 Cut; e018 Copy; e01e ApplicationRight
		# e03b -- e044 (Microsoft/Logitech Fkeys_without_Flock, F1...F10)
		# e063 Wake; e064 My Pictures [or Keypad-) ]

		#     (for yet more VK_-symbols see https://learn.microsoft.com/en-us/previous-versions/aa931968(v=msdn.10))
				# OEM_ATTN OEM_COPY OEM_CUSEL OEM_ENLW do not have any scancodes assigned anywhere???
		# The discussion: https://stackoverflow.com/questions/11740958/js-what-keyboard-keys-are-specified-for-key-codes-in-intervals-146-185-193-218

		#  More details in (change “Arrangement” if needed): https://kbdlayout.info/kbdibm02/scancodes
		#   see also this (and references there): https://bsakatu.net/doc/virtual-key-of-windows/
		    #   One of (industrial) keyboards with 000-key: https://geekhack.org/index.php?topic=60355.0
		    #     (Part of a huge family: https://telcontar.net/KBK/Fujitsu/series

	# Before OEM_8:   For type 4 of keyboard (same as types 1,3, except OEM_AX, (NON)CONVERT, ABNT_C1)
	#   except KANA,(NON)CONVERT; after OEM_8 all is junk (non-scancodes???)...
my %scan_codes = (reverse qw(
  02	1
  03	2
  04	3
  05	4
  06	5
  07	6
  08	7
  09	8
  0a	9
  0b	0
  0c	OEM_MINUS
  0d	OEM_PLUS
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
  1a	OEM_4
  1b	OEM_6
  1e	A
  1f	S
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
  2b	OEM_5
  2c	Z
  2d	X
  2e	C
  2f	V
  30	B
  31	N
  32	M
  33	OEM_COMMA
  34	OEM_PERIOD
  35	OEM_2
  39	SPACE
  56	OEM_102

  01	ESCAPE
  0E	BACK
  0F	TAB
  1C	RETURN
  1D	LCONTROL
  2A	LSHIFT
  36	RSHIFT
  37	MULTIPLY
  38	LMENU
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
  e053	DELETE
  54	SNAPSHOT
  57	F11
  58	F12
  59	CLEAR
  5A	OEM_WSCTRL
  5B	OEM_FINISH
  5C	OEM_JUMP
  5C	OEM_AX
  5D	EREOF
  5E	OEM_BACKTAB
  5F	OEM_AUTO
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
  70	KANA
  71	OEM_RESET
  73	ABNT_C1
  76	F24
  79	CONVERT
  7B	NONCONVERT
  7B	OEM_PA1
  7C	TAB
  7E	ABNT_C2
  7F	OEM_PA2

  e010	MEDIA_PREV_TRACK
  e019	MEDIA_NEXT_TRACK
  e01C	RETURN
  e01D	RCONTROL
  e020	VOLUME_MUTE
  e021	LAUNCH_APP2
  e022	MEDIA_PLAY_PAUSE
  e024	MEDIA_STOP
  e02E	VOLUME_DOWN
  e030	VOLUME_UP
  e032	BROWSER_HOME
  e035	DIVIDE
  e037	SNAPSHOT
  e038	RMENU
  e046	CANCEL
  e047	HOME
  e048	UP
  e049	PRIOR
  e04B	LEFT
  e04D	RIGHT
  e04F	END
  e050	DOWN
  e051	NEXT
  e052	INSERT
  e05B	LWIN
  e05C	RWIN
  e05D	APPS
  e05E	POWER
  e05F	SLEEP
  e065	BROWSER_SEARCH
  e066	BROWSER_FAVORITES
  e067	BROWSER_REFRESH
  e068	BROWSER_STOP
  e069	BROWSER_FORWARD
  e06A	BROWSER_BACK
  e06B	LAUNCH_APP1
  e06C	LAUNCH_MAIL
  e06D	LAUNCH_MEDIA_SELECT
  e11D	PAUSE

  7D	OEM_8
));	# http://www.opensource.apple.com/source/WebCore/WebCore-1C25/platform/gdk/KeyboardCodes.h

# [ ] \ space
my %oem_control = (qw(
	OEM_4	[001b
	OEM_6	]001d
	OEM_5	\001c
	SPACE	0020
	OEM_102	\001c
));	# In ru layouts, only entries which match the char are present
my %do_control = map /^(.)(.+)/, values %oem_control;
$do_control{' '} = '0020';
delete $do_control{0};

my %default_bind = ( (map {( "NUMPAD$_" => [[$_]] )} 0..9 ),
		     TAB	=> [["\t", "\t"]],
		     ADD	=> [["+", "+"]],
		     SUBTRACT	=> [["-", "-"]],
		     MULTIPLY	=> [["*", "*"]],
		     DIVIDE	=> [["/", "/"]],
		     RETURN	=> [["\r", "\r"], ["\n"]],
		     BACK	=> [["\b", "\b"], ["\x7f"]],
		     ESCAPE	=> [["\e", "\e"], ["\e"]],
		     CANCEL	=> [["\cC", "\cC"], ["\cC"]],
		   );

sub get_VK ($$) {
  my ($self, $f) = (shift, shift);
  $self->get_deep_via_parents($self, undef, 'faces', (split m(/), $f), 'VK') || {}
#  $self->{faces}{$f}{VK} || {}
}

my $min_sec;
sub last_pre_funckeys($$) {
  my ($self, $l0) = (shift, shift);
  unless (defined $min_sec) {
    $min_sec = 1e300;
    $min_sec > $_->[0] and $min_sec = $_->[0] for values %start_SEC;
  }
##  warn "Layer disappeared: `$l0'; layer names:\n\t`", join("'\n\t`", sort keys %{$self->{layers}}), "'"
##  	unless defined $self->{layers}{$l0};
  my $post_main = @{ $self->{layers}{$l0} };
  if ($post_main >= $min_sec) {
    $post_main = $min_sec;
    while ($post_main > 0) {
      last if grep defined, map {ref() ? $_->[0] : $_} grep defined, @{ $self->{layers}{$l0}[$post_main - 1] || [] };
      $post_main--;
    }
  }
  $post_main;
}

sub massage_VK ($$) {
  my ($self, $f, %seen, %seen_dead, @dead, @ctrl) = (shift, shift);
  my $l0 = $self->{faces}{$f}{layers}[0];
      warn "Finding last key for face `$f' layer[0] = `$l0'...\n" if debug_face_layout_recipes;
  my $post_main = $self->last_pre_funckeys($l0);

  if (my $LF = $self->{faces}{$f}{LinkFace}) {
    my $l00 = ($self->export_layers($LF))->[0];
    $self->revive_layer($LF, 0, $l00) unless $self->{layers}{$l00};
      warn "Finding last key for face `$f' LinkFace = `$l00'...\n" if debug_face_layout_recipes;
    my $post_main0 = $self->last_pre_funckeys($l00);
    $post_main = $post_main0 if $post_main0 > $post_main;
  }

  if (defined (my $b = $self->{faces}{$f}{BaseLayer})) { # Cannot bump into known keycodes
	warn "  mk_tr_lyrs 1" if debug_stacking_ord;
    $b = $self->make_translated_layers($b, $f, [0])->[0] if defined $b and not $self->{layers}{$b};
      warn "Finding last key for face `$f' BaseLayer = `$b'...\n" if debug_face_layout_recipes;
    my $post_main0 = $self->last_pre_funckeys($b);
    $post_main = $post_main0 if $post_main0 > $post_main;
  }
##       warn "post_main=$post_main;  layer=$l0 min_sec=$min_sec";

  $self->{faces}{$f}{'[non_VK]'} = $post_main;
  my $create_a_c = $self->{faces}{$f}{'[create_alpha_ctrl]'};
  $create_a_c = $create_alpha_ctrl unless defined $create_a_c;
  my $EXTR = [	["\r","\n"], ["\b","\x7F"], ["\t","\cC"], ["\x1b","\x1d"], # Enter/C-Enter/Bsp/C-Bsp/Tab/Cancel/Esc=C-[/C-]
  		["\x1c", ($create_a_c ? "\cZ" : ())], ($create_a_c>1 ? (["\x1e", "\x1f"], ["\x00"]) : ())];	# C-\ C-z, C-^ C-_
  if ($create_a_c) {	# Fill all control-chars too
    my %s;
    push @ctrl, scalar @$EXTR;
    $s{$_}++ for $self->flatten_arrays($EXTR);
    my @ctrl_l = grep !$s{$_}, map chr($_), 1..26;
    push @$EXTR, [shift @ctrl_l, shift @ctrl_l] while @ctrl_l > 1;
    push @$EXTR, [@ctrl_l] if @ctrl_l;
    push @ctrl, scalar @$EXTR;
  }
  my @extra = ( $EXTR, map [([]) x @$EXTR], 1..$#{ $self->{faces}{$f}{layers} } );
  my $VK = $self->get_VK($f);
  $self->{faces}{$f}{'[VK_off]'} = \ my %VK_off;
  $self->{faces}{$f}{'[scancodes]'} = \ my %scan;
  for my $K (reverse sort keys %$VK) {			# want SPACE to come before ABNT_* and OEM_102	;-)
    my ($v, @C) = $VK->{$K};
    my $vv = $v->[0];
    die("Can't reset the scancode for the VK key `$K'") if @$v < 2 and not length $v->[0];
    if ($v->[0] =~ /\|/ or @$v <= 1) {
      $scan{$K} = $_,  $self->{faces}{$f}{'[scancodes_more]'}{$_} = $K for split /\|/, uc $v->[0];	# the last one is put into %scan
      $vv = $scan{$K};
    }
    next unless @$v > 1;				# Do not modify %VK_off; only memorize the scancode
    $vv = $scan_codes{$K} or die("Can't find the scancode for the VK key `$K'")
      unless length $vv;
    $scan{$K} = $vv;
# warn 'Key: <', join('> <', @$v), '>';
    my $c = 0;
    $VK_off{$K} = @{ $extra[0] };		# Where in the layouts is the VK key
    for my $k (@$v[1..$#$v]) {
      ($k, my $dead) = ($k =~ /^(.+?)(\@?)$/) or die "Empty key in VK list";
      $seen{$k eq '-1' ? '' : ($k = $self->charhex2key($k))}++;
      $seen_dead{$k}++ or push @dead, $k if $dead and $k ne '-1';
      my $kk = ($k eq '-1' ? undef : $k);
      push @{ $extra[int($c/2)] }, [] unless $c % 2;
      push @{ $extra[int($c/2)][-1] }, ($dead ? [$kk, undef, 1] : $kk);		# $extra[$N] is [[$k0, $k1] ...]
      $kk .= $dead if defined $kk;
      push @C, $kk;
      $c++;
    }
# warn 'Key: <', join('> <', @C), '>';
    @$v = ($v->[0], @C);			# update the entry in %$VK	(may be shared with other Faces!!!)
  }
warn "eScanCodes($f): [", join(' ', sort keys %{$self->{faces}{$f}{'[scancodes_more]'}||{}}), ']';
  $self->{faces}{$f}{'[ini_layers]'} = [ @{ $self->{faces}{$f}{layers} } ];	# Deep copy
  if (@extra) {
    my($start_append, @Ln);
    for my $l (0 .. $#{ $self->{faces}{$f}{layers} } ) {	# Assume that in every layer a few positions after end of the 
      my $oLn = my $Ln = $self->{faces}{$f}{layers}[$l];	# first layer are empty
      my $L = $self->{layers}{$Ln};
      unless ($l) {
        $start_append = $post_main;
        $self->{faces}{$f}{'[start_ctrl0]'} = $start_append;
        $self->{faces}{$f}{'[start_ctrl]'} = $start_append + ($ctrl[0]||0);
        $self->{faces}{$f}{'[end_ctrl]'}   = $start_append + ($ctrl[1]||0);
        $_ += $start_append for values %VK_off;
      }
      my @L = map [$_->[0], $_->[1]], @$L;		# Each element is []; 1-level deep copy
      warn "Main keys + ctrl slots overwrite FUNKEYS sections" if $start_append + @{ $extra[$l] } > $min_sec;
      $L[$start_append+$_] ||= [] for 0..$#{ $extra[$l] };	# Avoid splicing after the end of array
      splice @L, $start_append, @{ $extra[$l] }, @{ $extra[$l] };
      push @Ln, ($Ln .= "<$f>");
      $self->{layers}{$Ln} = \@L;
      # At this moment ini_copy should not exist yet
warn "ini_copy of `$oLn' exists; --> `$Ln'" if $self->{layers}{'[ini_copy]'}{$oLn};
#      $self->{layers}{'[ini_copy]'}{$Ln} = $self->{layers}{'[ini_copy]'}{$oLn} if $self->{layers}{'[ini_copy]'}{$oLn};
#???    Why does not this works???
#warn "ini_copy1: `$Ln' --> `$oLn'";
       $self->{layers}{'[ini_copy1]'}{$Ln} = $self->deep_copy($self->{layers}{$oLn});
    }
##    if (my $add = $self->{faces}{$f}{'[ExtraChars]'}) {
##      @$add = map {my $c = $_; s/^\s+//, s/\s+$// for $c; $self->charhex2key($c)} @$add);
##    }
    $self->{faces}{$f}{layers} = \@Ln;
  }
  ([keys %seen], \@dead, \%seen_dead)
}

sub format_key ($$$$) {
  my ($self, $k, $dead, $used) = (shift, shift, shift, shift);
  return -1 unless defined $k;
  my $mod = ($dead ? '@' : '') and $used->{$k}++;
  return "$k$mod" if $k =~ /^[A-Z0-9]$/i;
  return '%%' if 1 != length $k or ord $k > 0xFFFF;
  $self->key2hex($k) . $mod;
}

# wget -O - http://cgit.freedesktop.org/xorg/proto/xproto/plain/keysymdef.h | perl -C31 -wlne 'next unless /\bXK_(\w+)\s+0x00([a-fA-F\d]+)/; print chr hex $2, qq(\t$1)' > ! oooo1
# wget -O - http://cgit.freedesktop.org/xorg/proto/xproto/plain/keysymdef.h | perl -C31 -wlne "next unless /\bXK_(\w+)\s+0x([a-fA-F\d]+)\s+\/\*(?:\(?|\s+)U\+([a-fA-F\d]+)/; print chr hex $3, qq(\t$1)" > oooo3

# See XK_ARMENIAN for an alternative way to encode Unicode to XK_: 0x1000587  /* U+0587
my(%KeySyms,%deadSyms,%invKeySyms);
sub load_KeySyms($) {
  return if %KeySyms;
  my$self = shift;
  my $names = $self->get__value('KeySyms') or return;
  my(%macro);
  for my $fn (@$names) {
    open my $fh, '<', $fn or warn("Cannot open $fn: $!"), next;
    while (defined(my $l = <$fh>)) {
      chomp $l;
      $deadSyms{$1}++ if $l =~ /\bXK_dead_(\w+)\s+0x([a-fA-F\d]+)\b/;
      my $dup = ( $l =~ m[\bXK_(\w+)\s+0x([a-fA-F\d]+)\s+/\*.*\b(obsolete|alias)\b] );
      next unless $l =~ m[\bXK_(\w+)\s+0x([a-fA-F\d]+)\s+/\*\s*(\()?U\+([a-fA-F\d]+)];
      warn "not yet defined: <$l>" if $dup and not $macro{$2};
      warn "sym re-defined: <$l>" if $KeySyms{$1};
      # warn "macro re-defined: <$l>\n" if $macro{$2} and not $dup;	# several offenders
      $KeySyms{$1} = my $c = chr hex $4;
      $invKeySyms{$c} = $1 unless $3;
      $macro{$2} = $1 unless $dup;
    }
  }
}

my %extra_X11_map = (qw(dead+asciicircum dead_circumflex	dead+0338 dead_stroke
			dead+02f5 dead_doublegrave),		# Does work even if we remove `ascii´
		     map {("dead+$_", 'dead_currency')} qw(sterling dollar cent yen copyright registered));

sub format_key_XKB ($$$$$$) {	##### Unfinished
  my ($self, $face, $k, $dead, $guess, $used) = (shift, shift, shift, shift, shift, shift);
  return 'NoSymbol' unless defined $k;
  $self->load_KeySyms unless %KeySyms;
  my $mod = ($dead ? 'dead_' : '') and $used->{$k}++;
  my $MAP = ($self->{faces}{$face}{"[${mod}X11symbol]"} ||= {});
  my $hexK = $self->keys2hex($k);
  return $MAP->{$hexK} if exists $MAP->{$hexK};
#  return $MAP->{$hexK} = "multichar=<$k>???" if 1 != length $k;
  if (1 != length $k) {
    my $v = sprintf '0x%x', 0x1000000 - 0x10000 - ++$self->{faces}{$face}{"[X11multicharC]"};	# map to near 0x1000000 – 0x1110000 ????
# warn "$face + «$hexK» ⇒ $v; «", join('», «', grep /\./, keys %$MAP), '»';
    return $MAP->{$hexK} = $v;			# "multichar=<$k>???" 
  }
  my $sym = $invKeySyms{$k};
  return $MAP->{$self->{faces}{$face}{"[${mod}iX11]"}{$sym} = $hexK} = "$mod$sym"
    if defined $sym and (not $mod or exists $deadSyms{$sym});
  my $sym1 = (defined $sym ? $sym : $hexK);
  return $MAP->{$self->{faces}{$face}{"[${mod}iX11]"}{$sym} = $hexK} = $extra_X11_map{"dead+$sym1"}
    if $mod and exists $extra_X11_map{"dead+$sym1"};
  if ($guess and $mod and my $D = $self->{'[map2diac]'}{$k}) {
    my $DD = $self->{'[diacritics]'}{$D};
#    warn "... diac($k): ", join ' ', map @$_, @$DD;
    for my $c (map @$_, @$DD) {			# flatten the list
      next unless defined (my $SYM = $invKeySyms{$c});
      next if exists $self->{faces}{$face}{"[${mod}iX11]"}{$SYM};	# already taken
      my $res;
      { $res = "$mod$SYM", last if exists $deadSyms{$SYM};	# Try other chars on the same diacritic-list
	$res = $extra_X11_map{"dead+$SYM"}, last if exists $extra_X11_map{"dead+$SYM"};
	last unless $SYM =~ s/^ascii//;
	$res = "$mod$SYM", last if exists $deadSyms{$SYM};	# Try other chars on the same diacritic-list
	$res = $extra_X11_map{"dead+$SYM"}, last if exists $extra_X11_map{"dead+$SYM"};
      }
      return $MAP->{$self->{faces}{$face}{"[${mod}iX11]"}{$SYM} = $hexK} = $res if defined $res;
    }
  }
  $sym = sprintf 'U%0' . (ord $k > 0xFFFF ? 6 : 4) . 'x', ord $k unless defined $sym;
  return $MAP->{$hexK} = $sym unless $mod;
  return unless $guess;
	# The Udddd are mapped to 0x1000000 + 0xdddd, so take up to 0x1110000
  return $MAP->{$hexK} = sprintf '0x%x', 0x1000000 - 0x10000 + ord $k if ord $k < 0x10000;	# map to near 0x1000000 – 0x1110000 ????
  return $MAP->{$hexK} = "<$mod$sym>???";	# Maybe map to something near 0x1000000 – 0x1110000 ????
}

sub auto_capslock($$) {
  my ($self, $u) = (shift, shift);
  my %fix = qw( ӏ Ӏ );		# Perl 5.8.8 uc is wrong
  return 0 unless defined $u->[0] and defined $u->[1] and $u->[0] ne $u->[1];
  return 1 if ($fix{$u->[0]} || uc($u->[0])) eq $u->[1];
  return 1 if ($fix{$u->[0]} || ucfirst($u->[0])) eq $u->[1];
  return 0;
}

sub flatten_unit ($$$$) {
  my ($self, $face, $N, $E) = (shift, shift, shift, shift);
  my(%ss, $cnt);						# Set Control-KEY if is [ or ] or \
  my @KK;  
  my $L = $self->{faces}{$face}{layers};
  my $b = @$L;
  if ($E) {	# = $self->{faces}{$face}{'[output_layers_XKB]'} || $self->{faces}{$face}{'[output_layers]'}) {
    for my $Ln (@$E) {	# Construct $ss from the numbered layers
      next unless $Ln =~ /^\s*\d+\s*$/;
      die "Layer number too large in output_layers" unless $Ln < $b;
      my $LL = $L->[$Ln];	# Numeric are for numbered layers
      my $l = $self->{layers}{$LL}[$N];
      my(@CC, @pp, @OK);
      my(%s1, @was);
      for my $sh (0..$#$l) {	# These `map´s have 1 arg
        my @C = map {defined() ? (ref() ? $self->dead_with_inversion(!'hex', $_, $face, $self->{faces}{$face}) : $_) : $_} $l->[$sh];
        my @p = map {defined() ? (ref() ? $_->[2] : 0 ) : 0 } $l->[$sh];
        next unless defined (my $c = $C[0]);
        my $pref = !!$p[0] || 0;
        $ss{"$pref$c"}++;
      }
    }
  }
  my $extra = $E || [0..$b-1];
  if ($extra and defined $N) {	# $N not supported on VK...
    for my $f (0..$#$extra) {
#        warn "Extra layer number $f, base=$b requested while the character N=$N has " . (scalar @$u) . " layers" if $f+$b <= $#$u;
      my($notsame, $case, $LL, $num);
      if ((my $lll = $extra->[$f]) =~ /^\s*\d+\s*$/) {
	die "Layer number too large in output_layers" unless $lll < $b;
	$LL = [$L->[$lll]];	# Numeric are for numbered layers
	$num = 1;
      } else {
        $lll =~ s/^prefix(NOTSAME(case)?)?=// or die "Extra layer: expected `prefix=PREFIX', see: `$extra->[$f]'";
        ($notsame, $case) = ($1,$2);
        my $c = $self->key2hex($self->charhex2key($lll));
        $LL = $self->{faces}{$face}{'[deadkeyLayers]'}{$c} or die "Unknown prefix character `$c´ in extra layers";
      }
      my @L = map $self->{layers}{$_}[$N], @$LL;
      my(@CC, @pp, @OK);				# char/is_prefix/???  ; Indexed by $sh=Shift_state
      # With notsame, squeeze a face into a layer; dups are marked “free”, so have a chance to squeeze Alt to Shift (w/o “case”)
      for my $l (@L[0 .. ($notsame ? $b-1 : 0)]) {
        my(%s1, @unsh);		# s1 is "seen in this layer"
        for my $sh (0..$#$l) {	# These `map´s have 1 arg
          my @C = map {defined() ? (ref() ? $self->dead_with_inversion(!'hex', $_, $face, $self->{faces}{$face}) : $_) : $_} $l->[$sh];
          my @p = map {defined() ? (ref() ? $_->[2] : 0 ) : 0 } $l->[$sh];
          next unless defined (my $c = $C[0]);				# Get rid of this fake array with 1 element
          my $pref = !!$p[0] || 0;					# Likewise
          ($CC[$sh], $pp[$sh]) = ($c, $pref) unless defined $CC[$sh];	# fallback: fill if not defined yet in preceding layers
          $cnt++ if defined $CC[$sh];
          next if $num;					# Continue for “extra” layers only
#          $ss{$C[0]}++ if $num;			# Fill into the same Shift-position if “not-anywhere-in-the-main-layers”
          ($CC[$sh], $pp[$sh], $OK[$sh], $s1{"$pref$c"}) = ($c, $pref, 1,1) if !$OK[$sh] and not $ss{"$pref$c"};
          ($CC[$sh], $pp[$sh], $OK[$sh], $s1{"$unsh[1]$unsh[0]"}) = (@unsh, 1,1)		# use unshifted if needed
            if $sh and !$OK[$sh] and defined $unsh[0] and not $ss{"$unsh[1]$unsh[0]"} and not $s1{"$unsh[1]$unsh[0]"};
          @unsh = ($c, $pref) unless $case or $sh;	# move AltGr-LETTER to Shift-LETTER if free and not $case (may omit `or $sh´)
          $cnt++ if defined $CC[$sh];
        }
      }
      # Avoid read-only values (can get via $#KK) which cannot be autovivified
      push @KK, ([]) x (2*$f - @KK) if @KK < 2*$f;		# splice can't do with a gap after the end of array
      splice @KK, 2*$f, 0, map [$CC[$_], $f-$b, $pp[$_]], 0..$#CC;
    }
  }
  return unless $cnt;
  return \@KK;
}

my %double_scan_VK = ('56 OEM_102' => '7D OEM_8',	# ISO vs JIS (right) keyboard
	#	      '73 ABNT_C1' => '7E ABNT_C2',	# ABNT2 (right) = JIS (left) keyboard vs ABNT2 (numpad)
	#	      '53 DECIMAL' => '7E ABNT_C2',	# NUMPAD-period vs ABNT2 (numpad) [Does not work??? DECIMAL too late?]
	#	      '34 OEM_PERIOD' => '7E ABNT_C2',	# period vs ABNT2 (numpad)
		      '33 OEM_COMMA' => '7E ABNT_C2',	# comma vs ABNT2 (numpad) — should be the opposite of DECIMAL!
	#	      '7B NONCONVERT' => '79 CONVERT',	# JIS keyboard: left of SPACE, right of SPACE
		      '39 SPACE' => '79 CONVERT/7B NONCONVERT',	# JIS keyboard: right of SPACE, left of SPACE
);
my %shift_control_extra = (2 => "\x00", 6 => "\x1e", OEM_MINUS => "\x1f");	# unshifted 2 hardwired below

{ my(%seen, %seen_scan, %seen_VK, @add_scan_VK, @ligatures, @decimal);
  sub reset_units ($) { @decimal = @ligatures = @add_scan_VK = %seen_scan = %seen_VK = %seen = () }

  sub output_unit00 ($$$$$$$;$$) {	# $UU->[$i] is the entry for the key in the layer No. $i; $N is an ordinal of a key; $k is VK_-names
    my ($self, $face, $k, $UU, $N, $deadkeys, $Used, $known_scancode, $skippable) = (shift, shift, shift, shift, shift, shift, shift, shift, shift);
    my $sc = ($known_scancode or $self->{faces}{$face}{'[scancodes]'}{$k} or $scan_codes{$k}
    			      or $k eq 'DECIMAL' and '53'	# kbdutool only accepts DECIMAL on 53
			      or $k =~ /^(?:NUMPAD(\d)|DECIMAL)$/ and (defined $1 ? "E0E$1" : 'E0EA'))
      or warn("Can't find the scancode for the key `$k'"), return;
    $sc  = uc $sc;						# Probably already uc⸣ed (need for comparison)
    $sc =~ /^E0E/ and warn "Redirected numpad key $k to a fake scancode $sc";
    $self->{faces}{$face}{'[emitted_scancodes]'}{$sc} = $k;
    my ($cnt, @KK) = 0;
    my $skip = grep $k eq $_, @{$self->{faces}{$face}{'[skip_extra_layers_WIN]'}};
    my $flat = $self->flatten_unit($face, $N,
                                   (!$skip and $self->{faces}{$face}{'[output_layers_WIN]'}
						     || $self->{faces}{$face}{'[output_layers]'}))
      and $cnt++;
    @KK = ($cnt ? @$flat : map [], @$UU);

    my(@cntrl);						# Set Control-KEY if is [ or ] or \ etc
    my @U = @KK;
    $#U = 3 if $#U > 3;
    $_ and ref $_ and $_ = $_->[0] for @U;
    my @u = [@U[0,1]];
    $u[1] = [@U[2,3]] if @U > 2;
    my $b = $KK[0];
    $b = $b->[0] if $b and ref $b;
    @cntrl = chr hex $do_control{$b}		if $do_control{$b || 'N/A'};	# \ ---> ^\
    @cntrl = chr hex substr $oem_control{$k}, 1 if !@cntrl and $oem_control{$k};
    @cntrl = @{ $default_bind{$k}[1] } if !@cntrl and $default_bind{$k}[1];
    my $create_a_c = $self->{faces}{$face}{'[create_alpha_ctrl]'};
    $create_a_c = $create_alpha_ctrl unless defined $create_a_c;
    @cntrl = (chr(0x1F & ord $k)) x $create_a_c if $k =~ /^[A-Z]$/ and $create_a_c;
    @cntrl = (undef, $shift_control_extra{$k})  if $create_a_c > 1 and $shift_control_extra{$k};
    @cntrl = ($shift_control_extra{$k}) x 2     if $create_a_c > 1 and $k eq '2';
    $cnt ||= @cntrl;
    return if $skippable and not $cnt;

    my $CL;
    if (my $Caps = $self->{faces}{$face}{'[CapsLOCKlayers]'} and defined $N) {	# $N not supported on VK...
      $CL = [map $self->{layers}{$_}[$N], @$Caps];
#      warn "See CapsLock layers: <<<", join('>>> <<<', @$Caps), ">>>";
    }
    if ($skippable) {
      for my $shft (0,1) {
        $KK[$shft] = [$default_bind{$k}[0][$shft], 0] if not defined $KK[$shft][0] and defined $default_bind{$k}[0][$shft];
###        $KK[$shft] = [$decimal[$shft], 0] if $k eq 'DECIMAL' and @decimal;
      }
    }
    my $pre_ctrl = $self->{faces}{$face}{'[ctrl_after_modcol]'};
    $pre_ctrl = 2*$ctrl_after unless defined $pre_ctrl;
    $#cntrl = $create_a_c - 1; # if $pre_ctrl < 2*@$u or $self->{faces}{$face}{'[keep_missing_ctrl]'};
    warn "cac=$create_a_c  #cntrl=$#cntrl pre=$pre_ctrl \@KK=", scalar @KK if $pre_ctrl > @KK;
    splice @KK, $pre_ctrl, 0, map [$_, 0], @cntrl;
    splice @KK, 15, 0, [undef, 0] if @KK >= 16;		# col=15 is the fake one

    if ($k eq 'DECIMAL') {	# may be described both via visual maps and NUMPAD
      my @d = @{ $decimal[1] || [] };
      defined $KK[$_][0] or $KK[$_] = $d[$_] for 0..$#d;	# fill on the second round
      @decimal = ([$k, \@u, $sc, $Used], [@KK]); 
      return;
    }
#    warn "Undefined \$N ==> <<<", join '>>> <<<', map $_->[0], @KK unless defined $N;	# SPACE and ABNT_C1 ???
    $self->output_unit_KK($k, \@u, $sc, $Used, $CL, @KK);
  }
  
  sub output_unit_KK($$@) {
    my ($self, $k, $u, $sc, $Used, $CL, @KK) = @_;
    my @K = map $self->format_key($_->[0], $_->[2], $Used->[$_->[1] || 0]), @KK;
#warn "keys with ligatures: <@K>" if grep $K[$_] eq '%%', 0..$#K;
    push @ligatures, map [$k, $_, $KK[$_][0]], grep $K[$_] eq '%%', 0..$#K;
    my $keys = join "\t", @K;
    my @kk = map $_->[0], @KK;
    my $fill = ((8 <= length $k) ? '' : "\t");
    my $expl = join ", ", map +(defined() ? (0x20 > ord() ? '^'.chr(0x40+ord) : $_) : ' '), @kk;
    my $expl1 = exists $self->{UNames} ? "\t// " . join ", ", map +((defined $_) ? $self->UName($_) : ' '), @kk : '';
    my($CL0, $extra) = ($CL and $CL->[0]);
    undef $CL0 unless $CL0 and @$CL0 and grep defined, map { ($_ and ref $_) ? $_->[0] : $_ } @$CL0;
#      warn "u0($k) = <$u->[0]>" if defined $u->[0];
    my $capslock = (defined $CL0 ? 2 : $self->auto_capslock($u->[0]));
#      warn "u1($k) = <$u->[1]>" if defined $u->[1];
    $capslock |= (($self->auto_capslock($u->[1])) << 2);
    $capslock = 'SGCap' if $capslock == 2;	# Not clear if we can combine a string SGCap with 0x4 in a .klc file
    if ($CL0) {
      my $a_cl = $self->auto_capslock($u->[0]);
      my @KKK = @KK[$a_cl ? (1,0) : (0,1)];
      defined(($CL0->[$_] and ref $CL0->[$_]) ? $CL0->[$_][0] : $CL0->[$_]) and $KKK[$_] = $CL0->[$_] for 0, 1;
#      my @c = map { ($_ and ref $_) ? $_->[0] : $_ } @$CL0;
#      my @d = map { ($_ and ref $_) ? $_->[2] : {} } @$CL0;	# dead
#      my @f = map $self->format_key($c[$_], $d[$_], ), 0 .. $#$CL0;
#      $extra = [@f];
      $extra = [map $self->format_key($_->[0], $_->[2], $Used->[$_->[1] || 0]), @KKK];
    }
    $seen_scan{$sc}++;
    $seen_VK{$k}++;
    ($sc, $k, $fill, <<EOP, $extra);
$capslock\t$keys\t// $expl$expl1
EOP
  }

  sub output_unit0 ($$$$$$$;$$) {		# $u is an ordinal of a key
    my(@i) = &output_unit00 or return;
    my @add = split '/', ($double_scan_VK{uc "$i[0] $i[1]"} || '');
#warn "<<<<< Secondary key <$add> for <$i[0] $i[1]>" if $add;
    push @add_scan_VK, map [split(/ /, $_), @i[2,3]], grep $_, @add;
    my $add = ($i[4] ? "-1\t-1\t\t0\t" . join("\t", @{$i[4]}) . "\n" : '');
    "$i[0]\t$i[1]$i[2]\t$i[3]$add"
  }
  
  sub output_added_units ($) {
    my ($self, @i, @o, @dec) = shift;
    for my $i (@add_scan_VK) {
      next if $seen_scan{$i->[0]} or $seen_VK{$i->[1]};	# Cannot duplicate either one...
      push @i, $i;
    }
    if ($decimal[0]) {
#      @decimal = ([$self->output_unit_KK($k, $u, $sc, $Used, @KK)], [@KK]);
      my ($k, $u, $sc, $Used) = @{$decimal[0]};
      push @dec, [$self->output_unit_KK($k, $u, $sc, $Used, undef, @{$decimal[1]})];
    }
    for my $i (@i, @dec) {
      my $add = ($i->[4] ? "-1\t-1\t\t0\t" . join("\t", @{$i->[4]}) . "\n" : '');
      push @o, "$i->[0]\t$i->[1]$i->[2]\t$i->[3]$add";
    }
    @o
  }
  
  my $enc_UTF16LE;
  sub to_UTF16LE_units ($) {
    my $k = shift;
    unless ($k =~ /^[\x00-\x{FFFF}]*$/) {
      (require Encode), $enc_UTF16LE = Encode::find_encoding('UTF-16LE') unless $enc_UTF16LE;
      die "Can't arrange encoding to UTF-16LE" unless $enc_UTF16LE;
      $k = $enc_UTF16LE->encode($k);
#        warn join '> <', ($k =~ /(..)/sg);	# Can't use decode() on surrogates...
#        warn join '> <', map {unpack 'v', $_} ($k =~ /(..)/sg);	# Can't use decode() on surrogates...
      $k = join '', map chr(unpack 'v', $_), ($k =~ /(..)/sg);	# Can't use decode() on surrogates...
    }
    $k;
  }

  sub output_ligatures ($) {
    my ($self, @o, %s) = shift;
    for my $l (@ligatures) {
      warn("Repeated LIGATURE $l->[0] $l->[1]"), next if $s{"$l->[0] $l->[1]"}++;
      my $k = to_UTF16LE_units $l->[2];
      my @k = ((map $self->key2hex($_), split //, $k), ('') x 4);
      my @expl = exists $self->{UNames} ? "// " . join " + ", map $self->UName($_), split //, $l->[2] : ();
      my $add = ((8 <= length $l->[0]) ? '' : "\t");
      push @o, (join "\t", "$l->[0]$add", $l->[1], @k[0..3], @expl) . "\n";
    }
    @o
  }

  sub base_unit ($$$$) {	# Find a suitable “ID” for this position in the layout (VK_-name for f-key groups, or key of %oem_keys)
    my ($self, $basesub, $u, $ingroup, $k) = (shift, shift, shift, shift);
    if (!$ingroup) {
      my @c = map $self->{layers}{$_}[$u][0], @$basesub;
      my($c) = grep defined, @c;
      my $c0 = $c = $c->[0] if 'ARRAY' eq ref $c;
	warn "base_u($u) undefined" unless defined $c;
      $c .= '#' if $seen{uc $c}++;
      $c = '#' if $c eq ' ';
      $c = uc $c;
      return [0, $c, $c0]
    }			# Now do the VK groups
    for my $v (values %start_SEC) {
      $k = $v->[2]($self, $u, $v), last if $v->[0] <= $u and $v->[0] + $v->[1] > $u;
    }
    [1, $k]
  }
  
  sub output_unit ($$$$$$$$) {		# $u is an ordinal of a key; $baseK contains the VK_-names
    my ($self, $face, $layers, $u, $deadkeys, $Used, $canskip, $baseK, $k) = (shift, shift, shift, shift, shift, shift, shift, shift);
    my $U = [map $self->{layers}{$_}[$u], @$layers];
    defined ($k = $baseK->[$u]) or return;
    $self->output_unit0($face, $k, $U, $u, $deadkeys, $Used, undef, $canskip);
  }
}

sub output_layout_win_only_scancodes ($$) {
  my ($self, $face) = (shift, shift);
  my $only_sc = $self->{faces}{$face}{'[scancodes_more]'} || {};
  my $emitted = $self->{faces}{$face}{'[emitted_scancodes]'} || {};	# Now all the unit00 are done, so this is filled
warn 'eScanCodes: [', join(' ', sort keys %$only_sc), '] emitted=', join(' ', sort keys %$emitted), ']';
  for my $sc (sort keys %$only_sc) {
    next unless exists $emitted->{$sc};
    warn "An extra scancode $sc for $only_sc->{$sc} conflicts with one for $emitted->{$_}" unless $only_sc->{$sc} eq $emitted->{$_}
  }
  map "$_\t$only_sc->{$_}\n", grep !exists $emitted->{$_}, sort keys %$only_sc;
}

sub output_layout_win ($$$$$$$) {	# $baseK contains the VK_-names
  my ($self, $face, $layers, $deadkeys, $Used, $cnt, $baseK) = (shift, shift, shift, shift, shift, shift, shift);
#  die "Count of non-VK entries mismatched: $cnt vs ", scalar @{$self->{layers}{$layers->[0]}}
#    unless $cnt <= scalar @{$self->{layers}{$layers->[0]}};
  ( map($self->output_unit($face, $layers, $_, $deadkeys, $Used, $_ >= $cnt, $baseK), 0..$#$baseK),
    output_layout_win_only_scancodes($self, $face)
  );
}

sub output_VK_win ($$$) {	# Not used anymore!!!  XXXX ???
  my ($self, $face, $Used, @O) = (shift, shift, shift);
  my $VK = $self->{faces}{$face}{'[VK_off]'};
  for my $k (keys %$VK) {
    my $off = $VK->{$k};
    my $scan = $self->{faces}{$face}{'[scancodes]'}{$k};
    push @O, $self->output_unit0($face, $k, undef, $off, [], $Used, $scan);
#    my ($self, $face, $k, $U, $N, $deadkeys, $Used, $known_scancode, $skippable) = (shift, shift, shift, shift, shift, shift, shift, shift, shift);
  }
  @O
}

sub read_deadkeys_win ($$) {
   my ($self, $t, $dead, $next, @p, %o) = (shift, shift, '', '');

   $t =~ s(\s*//.*)()g;		# remove comments
   $t =~ s([^\S\n]+$)()gm;		# remove trailing whitespace (including \r!)
   # deadkey lines, empty lines, HEX HEX keymap lines
   $t =~ s/(^(?=DEADKEY)(?:(?:(?:DEADKEY|\s*[0-9a-f]{4,})\s+[0-9a-f]{4,})?(?:\n|\Z))*)(?=(.*))/DEADKEYS\n\n/mi
     and ($dead, $next) = ($1, $2);
   warn "Unknown keyword follows deadkey descriptions in MSKLC map file: `$next'; dead=<$dead>"
     if length $next and not $next =~ /^(KEYNAME|LIGATURE|COPYRIGHT|COMPANY|LOCALENAME|LOCALEID|VERSION|SHIFTSTATE|LAYOUT|ATTRIBUTES|KEYNAME_EXT|KEYNAME_DEAD|DESCRIPTIONS|LANGUAGENAMES|ENDKBD)$/i;
#   $dead =~ /\S/ or warn "EMPTY DEADKEY section";
#warn "got `$dead' from `$t'";

   # when a pattern has parens, split does not remove the leading empty fields (?!!!)
   (undef, my %d) = split /^DEADKEY\s+([0-9a-f]+)\s*\n/im, $dead;
   for my $d (keys %d) {
#warn "split `$d' from `$d{$d}'";
     @p = split /\n+/, $d{$d};
     my @bad;
     die "unrecognized part in deadkey map for $d: `@bad'"
       if @bad = grep !/^\s*([0-9a-f]+)\s+([0-9a-f]+)$/i, @p;
     %{$o{lc $d}} = map /^\s*([0-9a-f]+)\s+([0-9a-f]+)/i, @p;
   }
   
   # empty lines, HEX "NAME" lines
   if ($t =~ s/^KEYNAME_DEAD\n((?:(?:\s*[0-9a-f]{4,}\s+".*")?(?:\n|\Z))*)(?=(.*))/KEYNAMES_DEAD\n\n/mi) {
     ($dead, $next) = ($1,$2);
     warn "Unknown keyword follows deadkey names descriptions in MSKLC map file: `$next'"
       if length $next and not $next =~ /^(DEADKEY|KEYNAME|LIGATURE|COPYRIGHT|COMPANY|LOCALENAME|LOCALEID|VERSION|SHIFTSTATE|LAYOUT|ATTRIBUTES|KEYNAME_EXT|KEYNAME_DEAD|DESCRIPTIONS|LANGUAGENAMES|ENDKBD)$/i;
     $dead =~ /\S/ or warn "EMPTY KEYNAME_DEAD section";
     %d = map /^([0-9a-f]+)\s+"(.*)"\s*$/i, split /\n\s*/, $dead;
     $d{lc $_} = $d{$_} for keys %d;
     $self->{'[seen_knames]'} ||= {};
     @{$self->{'[seen_knames]'}}{map {chr hex $_} keys %d} = values %d;		# XXXX Overwrites older values
   } elsif ($dead =~ /\S/) {
     warn "no KEYNAME_DEAD section found" if 0;
   }
   \%o, \%d, $t;		# %o - translation tables; %d - names; $t is what is left of input
}

sub massage_template ($$$) {
   my ($self, $t, $r, %seen, %miss) = (shift, shift, shift);
   my $keys = join '|', sort {length $b <=> length $a or $a cmp $b} keys %$r;	# Prefer matching a longer key
   $t =~ s/($keys)/ # warn "Plugging in `$1'"; 
   		    $seen{$1}++, $r->{$1} /ge;	# Can't use \b: see SORT_ORDER_ID_ LOCALE_ID
   $seen{$_} or $miss{$_}++ for keys %$r;
   warn "The following parts missing in the template: ", join ' ', sort keys %miss if %miss;
   $t
}

# http://msdn.microsoft.com/en-us/library/dd373763
# http://msdn.microsoft.com/en-us/library/dd374060
my $template_win = <<'EO_TEMPLATE';
KBD	DLLNAME		"LAYOUTNAME"

COPYRIGHT	"(c) COPYR_YEARS COMPANYNAME"

COMPANY	"COMPANYNAME"

LOCALENAME	"LOCALE_NAME"

LOCALEID	"SORT_ORDER_ID_LOCALE_ID"

VERSION	1.0	// UI::KeyboardLayout version=UIKL_VERSION

MODIFIERS
SHIFTSTATE	// With kbdutool the SHIFTSTATE should map to at least 2 columns, and map the Control key (= “have 2 present”)

BITS_TEMPLATE
ATTRIBS
LAYOUT		// an extra '@' at the end is a dead key

//SC	VK_		Cap	COL_HEADERS
// in this row ⒸⒶ mean “right”:	COL_HUMAN
//--	----		----	COL_EXPL
LAYOUT_KEYS
DO_LIGA
DEADKEYS

// KEYNAME KEYNAME_EXT KEYNAME_DEAD - used to map a Scancode to Key Name via GetKeyNameText(); null-terminated.
//
// If the name is not found in the first two tables,
// then it is deduced from the character/deadkey this key produces in the unshifted position (as MapVirtualKeyEx()).
// In particular, the special-case in the latter function covers VK_A to VK_Z!
//
// As a corollary, the third table needs only to contain dead keys in the unshifted positions, and only
// at positions not present in the first two tables.

KEYNAME		// Mostly from type 4 keyboard, not producing a printable char, non-variable in types 1...6, Ctrl/etc are left versions

01	Esc
0e	Backspace
0f	Tab
1c	Enter
1d	Ctrl
2a	Shift
36	"Right Shift"
37	"Num *"
38	Alt
39	Space
3a	"Caps Lock"
3b	F1
3c	F2
3d	F3
3e	F4
3f	F5
40	F6
41	F7
42	F8
43	F9
44	F10
45	Pause		// VK_NUMLOCK
46	"Scroll Lock"
47	"Num 7"		// VK_HOME (starts a block)
48	"Num 8"		// ...
49	"Num 9"		// ...
4a	"Num -"		// ...
4b	"Num 4"		// ...
4c	"Num 5"		// ...
4d	"Num 6"		// ...
4e	"Num +"		// ...
4f	"Num 1"		// ...
50	"Num 2"		// ...
51	"Num 3"		// ...
52	"Num 0"		// VK_INSERT (ends a block)
53	"Num Del"
54	"Sys Req"	// VK_SNAPSHOT ("Print Screen")
56	"Oem 102"
57	F11
58	F12
59		Clear
5a		Wctrl
5b		Finish
5c		Jump	// Was AX in older versions
5d		EREOF
5e		Backtab
5f		Auto
62		Zoom
63		Help
64			F13	// These F-keys were wrong in MSKLC (VK-codes, not scancodes)
65			F14
66			F15
67			F16
68			F17
69			F18
6a			F19
6b			F20
6c			F21
6d			F22
6e			F23
6f		PA3
70		KANA		// From Types 30 33
71		Reset
73		"ABNT C1"
76			F24
79		CONVERT		// From Types 7 8
7b		PA1
7c		"KB3270 Tab"
7e		"ABNT C2"
7f		PA2

KEYNAME_EXT		// Type 4

10		"Prev Track"
19		"Next Track"
1c	"Num Enter"
1d	"Right Ctrl"
20		"Volume Mute"
21		"Launch App2"
22		"Pause Play"
24		"Stop"
2e		"Volume Down"
30		"Volume ߙp"
32		"Browser Home"
35	"Num /"
37	"Prnt Scrn"
38	"Right Alt"
45	"Num Lock"
46	Break		// VK_CANCEL
47	Home
48	Up
49	"Page Up"
4b	Left
4d	Right
4f	End
50	Down
51	"Page Down"	// Types 1 3 4
52	Insert
53	Delete
54	<00>		// ??? from MSKLC; not in kbd.h (on no Type) (does not seem to be used on any layout)
56	Help		// ??? from MSKLC; not in kbd.h (on no Type) (does not seem to be used on any layout)
5b	"Left Windows"
5c	"Right Windows"
5d	Application
5e		Power
5f		Sleep
65		"Browser Search"
66		"Browser Favorites"
67		"Browser Refresh"
68		"Browser Stop"
69		"Browser Forward"
6a		"Browser Back"
6b		"Launch App1"
6c		"Launch Mail"
6c		"Launch Media Select"

KEYNAMES_DEAD

DESCRIPTIONS

LOCALE_ID	LAYOUTNAME

LANGUAGENAMES

LOCALE_ID	LANGUAGE_NAME

ENDKBD

EO_TEMPLATE
			# "

my $template_osx = <<'EO_TEMPLATE';
<?xml version="1.1" encoding="UTF-8"?>
<!DOCTYPE keyboard PUBLIC "" "file://localhost/System/Library/DTDs/KeyboardLayout.dtd">
<!--Last edited by OSX_CREATOR version OSX_CREATOR_VERSION on OSX_EDIT_DATE-->
<!--Created by OSX_CREATOR version OSX_CREATOR_VERSION on OSX_EDIT_DATE-->
<!--Copyright © COPYR_YEARS COMPANYNAME-->
<keyboard group="126" id="OSX_ID" name="OSX_LAYOUTNAME"> <!-- maxout="OSX_MAXOUT" -->
    <layouts>
        <layout first="0" last="17" modifiers="commonModifiers" mapSet="ANSIJIS"/>
        <layout first="18" last="18" modifiers="commonModifiers" mapSet="ANSIJIS"/>
        <layout first="21" last="23" modifiers="commonModifiers" mapSet="ANSIJIS"/>
        <layout first="30" last="30" modifiers="commonModifiers" mapSet="ANSIJIS"/>
        <layout first="194" last="194" modifiers="commonModifiers" mapSet="ANSIJIS"/>
        <layout first="197" last="197" modifiers="commonModifiers" mapSet="ANSIJIS"/>
        <layout first="200" last="201" modifiers="commonModifiers" mapSet="ANSIJIS"/>
        <layout first="206" last="207" modifiers="commonModifiers" mapSet="ANSIJIS"/>
    </layouts>
    <modifierMap id="commonModifiers" defaultIndex="0">
        <keyMapSelect mapIndex="0">
            <modifier keys=""/>
        </keyMapSelect>
        <keyMapSelect mapIndex="8">
            <modifier keys="anyShift? caps? command"/>
        </keyMapSelect>
        <keyMapSelect mapIndex="1">
            <modifier keys="anyShift caps?"/>
        </keyMapSelect>
        <keyMapSelect mapIndex="2">
            <modifier keys="caps"/>
        </keyMapSelect>
        <keyMapSelect mapIndex="3">
            <modifier keys="anyOption"/>
        </keyMapSelect>
        <keyMapSelect mapIndex="4">
            <modifier keys="anyShift caps? anyOption command?"/>
        </keyMapSelect>
        <keyMapSelect mapIndex="5">
            <modifier keys="caps anyOption"/>
        </keyMapSelect>
        <keyMapSelect mapIndex="6">
            <modifier keys="caps? anyOption command"/>
        </keyMapSelect>
        <keyMapSelect mapIndex="7">
            <modifier keys="shift? caps? option? command? control"/>
            <modifier keys="shift? rightShift caps? option? command? control"/>
            <modifier keys="shift? caps? option? rightOption command? control"/>
        </keyMapSelect>
    </modifierMap>
    <keyMapSet id="ANSIJIS">
        <keyMap index="0">
            <!-- No modifiers -->
OSX_KEYMAP_0_AND_COMMAND
		</keyMap>
		<keyMap index="1">
            <!-- shift -->
OSX_KEYMAP_SHIFT
		</keyMap>
		<keyMap index="2">
            <!-- caps lock -->
OSX_KEYMAP_CAPS
		</keyMap>
		<keyMap index="3">
            <!-- option -->
OSX_KEYMAP_OPTION
		</keyMap>
		<keyMap index="4">
            <!-- option shift -->
OSX_KEYMAP_OPTION_SHIFT
		</keyMap>
		<keyMap index="5">
            <!-- option caps lock -->
OSX_KEYMAP_OPTION_CAPS
		</keyMap>
        <keyMap index="6">
            <!-- option command -->
OSX_KEYMAP_OPTION_COMMAND
        </keyMap>
        <keyMap index="7">
            <!-- control -->
OSX_KEYMAP_CTRL
        </keyMap>
        <keyMap index="8">
            <!-- command -->
OSX_KEYMAP_COMMAND
        </keyMap>
    </keyMapSet>
    <actions>
        <!-- actions for initiating+completing dead key states -->
OSX_ACTIONS_BASE
        <!-- actions for standalone chars (may complete dead key states) -->
OSX_ACTIONS
    </actions>
    <terminators>
        <!-- terminators for primary dead key states -->
OSX_TERMINATORS_BASE
        <!-- terminators for secondary dead key states
             (repeated dead keys); this may mention several extraneous states
             reachable only from Windows layouts (which allow more keys) -->
OSX_TERMINATORS2
    </terminators>
</keyboard>
EO_TEMPLATE
			# "

sub KEY2hex ($$) {
  my ($self, $k) = (shift, shift);
  return $self->key2hex($k) unless 'ARRAY' eq ref $k;
#warn "see a deadkey `@$k'";
  $k = [@$k];				# deeper copy
  $k->[0] = $self->key2hex($k->[0]);
  $k;
}

sub linked_faces_2_hex_map ($$$$) {
  my ($self, $name, $b, $inv) = (shift, shift, shift, shift);
  my $L = $self->{faces}{$name};
  my $remap = $L->{$inv ? 'Face_link_map_INV' : 'Face_link_map'}{$b};
  die "Face `$b' not linked to face `$name'; HAVE: <", join('> <', keys %{$L->{Face_link_map}}), '>'
    if $self->{faces}{$b} != $L and not $remap;
###  my $cover = $L->{'[coverage_hex]'} or die "Face $name not preprocessed";
# warn "Keys of the Map `$name' -> '$b': <", join('> <',  keys %$remap), '>';
#  $remap ||= {map +(chr hex $_, chr hex $remap->{$_}), keys %$cover};		# This one in terms of chars, not hex
  my @k = keys %$remap;
# warn "Map `$name' -> '$b': <", join('> <', map +($self->key2hex($_), $self->key2hex($remap->{$_})), @k), '>';
  return { map +($self->keys2hex($_), (defined $remap->{$_} ? $self->KEY2hex($remap->{$_}) : undef)), @k }
}

my $dead_descr;
#my %control = split / /, "\n \\n \r \\r \t \\t \b \\b \cC \\x03 \x7f \\x7f \x1b \\x1b \x1c \\x1c \x1d \\x1d";
my %control = split / /, "\n \\n \r \\r \t \\t \b \\b";
$control{$_->[0]} ||= $_->[1] for map [chr($_), '^'.chr(0x40+$_)], 1..26;
sub control2prt ($$) {
  my($self, $c) = (shift, shift);
  return $c unless ord $c < 0x20 or ord $c == 0x7f;
  $control{$c} or sprintf '\\x%02x', ord $c;
}

sub dead_with_inversion ($$$$$) {
  my($self, $is_hex, $to, $nameF, $H) = (shift, shift, shift, shift, shift);
  my $invert_dead = (3 == ($to->[2] || 0) or 3 == (($to->[2] || 0) >> 3));
  $to = $to->[0];
  if ($invert_dead) {
    $to = $self->key2hex($to) unless $is_hex;
    defined ($to = $H->{'[deadkeyInvAltGrKey]'}{$to}) or die "Cannot invert prefix key `$to' in face `$nameF'";
    # warn "invert $to in face=$nameF, inv=$invertAlt0 --> $inv\n";
    $to = $self->key2hex($to) if $is_hex;
  }
  $to;
}

sub output_deadkeys ($$$$$$;$) {	# Emits 1 or 2 maps; for the 2nd, uses $prefix_flippedMap_hex as prefix
  # If $d is $flip_AltGr_hex, does not emit the flipped map (if $flip_AltGr_hex is not defined, there should not be Inv map!).
  my ($self, $nameF, $d, $Dead2, $flip_AltGr_hex, $prefix_flippedMap_hex, $OUT_Apple) = (shift, shift, shift, shift, shift, shift, shift);
  my $H = $self->{faces}{$nameF};
#       warn "emit `$nameF' d=`$d' f=$H->{'[deadkeyFace]'}{$d}";
#  if (my $unres = $H->{'[unresolved_imported]'}) {
#    warn "Can't resolve `@$unres' to an imported dead key; face=`$nameF'" unless $H->{'[unresolved_imported_warned]'}++;
#  }
#warn "See dead2 in <$nameF> for <$d>" if $dead2;
  my $dead2 = ($Dead2 || {})->{$self->charhex2key($d)} || {};
  my(@sp, %sp) = map {(my $in = $_) =~ s/(?<=.)\@$//s; $in} @{ ($self->get_VK($nameF))->{SPACE} || [] };
  @sp = map $self->charhex2key($_), @sp;
  @sp{@sp[1..$#sp]} = (0..$#sp);		# The leading elt is the scancode

  my @maps = map $H->{"[deadkeyFaceHexMap$_]"}{$d}, '', 'Inv';
  pop @maps unless defined $maps[-1];
  my($D, @DD) = ($d, $d, $prefix_flippedMap_hex);
  my ($OUT, $keys) = '';
  # There are 3 situations:
  # 0) process one map without AltGr-inversion; 1) Process one map which is the AltGr-inversion of the principal one;
  # 2) process one map with AltGr-inversion (in 1-2 the inversion may have a customization put over it).
  # The problem is to recognize when deadkeys in the inversion come from non-inverted one, or from customization
  # And, in case (1), we must consider flip_AltGr specially... (the case (2) is now treated during face preparation)
  my($is_invAltGr_Base_with_chain, $AMap, $default) = ($D eq ($flip_AltGr_hex || 'n/a') and $H->{'[have_AltGr_chain]'});
  $default = $self->default_char($nameF);
  $default = $self->key2hex($default) if defined $default;
  if ($#maps or $is_invAltGr_Base_with_chain) {		# One of the maps we will process is AltGr-inverted; calculate AltGr-inversion
    $self->faces_link_via_backlinks($nameF, $nameF, 'no_ini');		# Create AltGr-invert self-mapping
    $AMap = $self->linked_faces_2_hex_map($nameF, $nameF, 1);
#warn "deadkey=$D flip=$flip_AltGr_hex" if defined $default;;
  }
  my($docs, $map_AltGr_over, $over_dead2) = ($H->{'[prefixDocs]'}{$D}, {}, {});
  if ($is_invAltGr_Base_with_chain) { 
    if (my $override_InvAltGr = $H->{'[InvAltGrFace]'}{''}) { # NOW: needed only for invAltGr
      $map_AltGr_over = $self->linked_faces_2_hex_map($nameF, $override_InvAltGr);
    }
    $over_dead2 = $Dead2->{$self->charhex2key($flip_AltGr_hex)} || {} if defined $flip_AltGr_hex;	# used in CyrPhonetic v0.04
    $dead2 = { %{ $H->{'[DEAD]'} }, %{ $H->{'[dead_in_VK]'} } };
#    $docs ||= 'AltGr-inverted base face';
  }
  my $enhMaps = my $enhGrayMapsForce = [{}, {}];
  $enhMaps      = $H->{'[enhGrayHexMaps]'}{$d}      if !$OUT_Apple and $D ne ($flip_AltGr_hex || 'n/a') and $H->{'[enhGrayHexMaps]'}{$d};
  $enhGrayMapsForce = $H->{'[enhGrayHexMapsForce]'}{$d} if $enhMaps != $enhGrayMapsForce and $H->{'[enhGrayHexMapsForce]'}{$d};
  my %enhForce = map {($self->keys2hex($_), 1)} @{$H->{'[Prefix_Force_Altern]'} || []};
  my($flat, $flatInv, @flatMap) = (map($self->{faces}{$nameF}{"[FlatPrefixMapFiltered$_]"}{$d}, ('', 'Inv')), {}, {});
  if (!$OUT_Apple and ($flat or $flatInv)) {
    $flatMap[0] = $flat || {};
    $flatMap[1] = $flatInv || {};
  }

# warn "output map for `$D' invert=", !!$is_invAltGr_Base_with_chain, ' <',join('> <', sort keys %$dead2),'>';
  for my $invertAlt0 (0..$#maps) {
    my $invertAlt = $invertAlt0 || $is_invAltGr_Base_with_chain;
    my $map = $maps[$invertAlt0];
    $d = $DD[$invertAlt0];
    my($enhMap, $enhMapForce, $flMap) = ($enhMaps->[$invertAlt0], $enhGrayMapsForce->[$invertAlt0], $flatMap[$invertAlt0]);
    if (warnReached and my %enhMapForce = %$enhMapForce) {
  	warn " enhForce: ", join ' ', %enhForce, "\n";
  	warn " enhMap(for Force): ", join ' ', map {defined() ? $_ : '[u/d]'} %$enhMap, "\n";
  	warn " enhMapForce: ", join ' ', %enhMapForce, "\n";
    }
# warn " ... enhmap $nameF [$d]: ", join(' ' , map {"$_ ⇒ " . (defined $enhMap->{$_} ? $enhMap->{$_} : '[u/d]')} sort keys %$enhMap), "\n" if %$enhMap;
#  	warn " map $nameF [$d]: ", join ' ', map {defined() ? $_ : '[u/d]'} %$map, "\n";
    $map = {%$enhMap, %$flMap, %$map, %$enhMapForce};
    my (%joined_map, %loopOK);
    for my $hex (sort keys %$map) {	# Temprorarily???  Map joined keys to itself without resolving conficts (sort: consistent EXPL)
      $joined_map{$hex} = $map->{$hex}, next if $OUT_Apple or $hex =~ /^[a-f\d]{4}$/;
#      my(@comp,%seen,$seen) = split /\./, ($hex =~ /^[a-f\d]+$/
#		                           ? $self->keys2hex(to_UTF16LE_units(chr hex $hex))
#	        	                   : $hex);
      my(@comp,%seen,$seen) = map {/^[a-f\d]{4}$/ ? $_ : split /\./, $self->keys2hex(to_UTF16LE_units(chr hex $hex))}
      				split /\./, $hex;
      $seen{$_}++ and $seen++ for @comp;
      warn("Skipping a binding for $hex in deadkey=$d: conflicts"), next
        if $seen or grep exists $map->{$_} || exists $joined_map{$_} && not($joined_map{$_}[0] eq $d and $joined_map{$_}[2]==1), @comp;
      for my $c (0..$#comp) {
        if ($c==$#comp) {
          my @b = @{$map->{$hex}||[]};
          $b[3] ||= '';
          $b[3] .= " [from multi-codepoint source $hex]";
          $joined_map{$comp[$c]} = \@b;
        } else {
          $loopOK{$comp[$c]}++;
          if (exists $joined_map{$comp[$c]}) {
            $joined_map{$comp[$c]}[3] =~ s/(?<=source\b)/s/; #/
            $joined_map{$comp[$c]}[3] .= ", $hex";
          } else {
            $joined_map{$comp[$c]} = [$d, undef, 1, "Component=" . ($c+1) . " of ". ($#comp+1) . " of multi-codepoint source $hex"];
          }
        }
      }
    }
    my $docs1 = (defined $docs ? sprintf("\t// %s%s", ($invertAlt0 ? 'AltGr inverted: ' : ''), $docs) : '');
    $OUT .= "DEADKEY\t$d$docs1\n\n";
    my $OUT_Apple_map = $d;
    # Good order: first alphanum, then punctuation, then space
    my @keys = sort keys %joined_map;			# Sorting not OK for 6-byte keys - but after joining they disappear
    @keys = (grep((!/^d[89a-f]/i and  lc(chr hex $_) ne uc(chr hex $_)and not $sp{chr hex $_} ),		      @keys),
             grep((!/^d[89a-f]/i and (lc(chr hex $_) eq uc chr hex $_ and (chr hex $_) !~ /\p{Blank}/) and not $sp{chr hex $_}), @keys),
            grep((!/^d[89a-f]/i and ((lc(chr hex $_) eq uc chr hex $_ and (chr hex $_) =~ /\p{Blank}/) or $sp{chr hex $_}) and $_ ne '0020'), @keys),
             grep(                                                  /^d[89a-f]/i,  @keys),	# 16-bit surrogates
             grep(				                    $_ eq '0020',  @keys));	# make SPACE last
    for my $n (@keys) {	# Only 4-byte keys reach this (except for Apple)
###      warn("do/skip $n in dk=$d\n") if $n =~ /[^a-f\d]/i or hex $n >= 0x10000;
      my ($to, $import_dead, $EXPL) = my $map_n = $joined_map{$n};
      if ($to and 'ARRAY' eq ref $to) {
        $EXPL = $to->[3]; 
        $EXPL =~ s/(?=\p{NonspacingMark})/ /g if $EXPL;
        $import_dead = (1 <= ($to->[2] || 0));					# was: exportable; now: any dead
        $to = $self->dead_with_inversion('hex', $to, $nameF, $H);
      }
      warn "0000: face `$nameF' d=`$d': $n --> $to" if $to and $to eq '0000';
      $to = '0000' if $to and $to eq '000000';		# A way to protect from a warning above!
      $map_n = $map_n->[0] if $map_n and ref $map_n;
###      $H->{'[32-bit]'}{chr hex $map_n}++, next if hex $n > 0xFFFF and $map_n;	# Cannot be put in a map...
      $H->{'[32-bit]'}{chr hex $map_n}++ if $n !~ /\./ and hex $n > 0xFFFF and $map_n;	# Cannot be put in a map...
      $n = $self->keys2hex(to_UTF16LE_units(chr hex $n)) if hex(my $n_high = $n) >= 0x10000;
      if ($to and ($to =~ /\./ or hex $to > 0xFFFF)) {{		# Value cannot be put in a map...
#        warn "32-bit: n=$n map{n}=$map_n to=$to";
	my $trg = $to;
        $H->{'[32-bit]'}{chr hex $map_n}++;
        last unless defined ($to = $H->{'[DeadChar_32bitTranslation]'});
        $to =~ s/^\s+//;	$to =~ s/\s+$//;
        $to = $self->key2hex($to);
        $EXPL .= ' ' if $EXPL ||= '';
        $EXPL .= "Windows’ limitation: multi-codepoint value U+$trg cannot be emitted after a prefix key";
      }}
      if ($n =~ /[^a-f\d]/i or hex $n >= 0x10000) {
        next if $OUT_Apple;
        die "Unexpected $n in dk=$d", ($to ? "  -> $to" : '' );
        next;
      }
      my $was_to = $to;
      $to ||= $default or next;
	#  Tricky: dead keys may come from the override map (which is indexed by NOT-INVERTED KEYS!); it is already merged into
	#  the map - unless for inverted base face
      my ($alt_n, $use_dead2) = (($is_invAltGr_Base_with_chain and defined $map_AltGr_over->{$n})
        			 ? ($n, $over_dead2) 
        			 : (($invertAlt ? $AMap->{$n} : $n), $dead2));
      $alt_n = $alt_n->[0] if $alt_n and ref $alt_n;	# AMap may have "complex" values
#warn "$D --> $d, `$n', `$alt_n', `$AMap->{$n}'; `$map_AltGr_over->{$n}' i=$invertAlt i0=$invertAlt0 d=$use_dead2->{chr hex $alt_n}";
#warn "... n=`$n', alt=`$alt_n' Amap=`$AMap->{$n}'\n" if $AMap->{$n};
      my $DEAD = ( (defined $alt_n and $use_dead2->{chr hex $alt_n}) ? '@' : '' );
#warn "AltGr flip: $nameF:$D: $n --> $H->{'[dead2_AltGr_chain]'}{$D}" if $n eq ($flip_AltGr_hex || 'n/a');
      my $from = $self->control2prt(chr hex $n);
      # This is now done inside the map:
      if (0 and (hex $n) == hex ($flip_AltGr_hex || 'ffffff') and @maps == 2 and !$invertAlt) {
        if (defined $was_to or $DEAD) {
	  warn "AltGr_Flip key=", hex $n, " overwrites '$was_to', DEAD=", $DEAD||$import_dead||0, " on face=$nameF\[$d]";
	}
	($DEAD, $to) = ('@', $DD[1]);	# Join Inv to not-Inv on $flip_AltGr_hex; Do not overwrite existing binding...  Warn???
      }
      $to = $default			# Do not remap a Ctrl-char to Ctrl-char
        if !($DEAD or $import_dead)
           and defined $default and (0x7f == hex $to or 0x20 > hex $to) and (0x7f == hex $n or 0x20 > hex $n);
      if (($DEAD or $import_dead) and $d eq $to and not $loopOK{$n}) {
        if (($flip_AltGr_hex or 'n/a') eq $d) {		# This is what routinely happens in Flip_AltGr face
          $import_dead = $DEAD = '';
          $to = $H->{'[DeadChar_32bitTranslation]'} || '003f';	# ? = U+003f
          $to =~ s/^\s+//;	$to =~ s/\s+$//;
          $to = $self->key2hex($to);
          $EXPL = 'removal of immediate deadkey loop in flip_AltGr variant of the base';
        } else {
          warn "Immediate deadkey loop: face `$nameF' d=`$d': $n --> $to";
        }
      }
      my $expl = exists $self->{UNames} ? "\t// " . join "\t-> ",		#  map $self->UName($_), 
  #                  chr hex $n, chr hex $map->{$n} : '';
                   $self->UName(chr hex $n), $self->UName(chr hex $to, 'verbose', 'vbell') : '';
      $expl .= " (via $EXPL)" if $expl and $EXPL;
      my $to1 = $self->control2prt(chr hex $to);
#      warn "Both import_dead and DEAD properties hold for `$from' --> '$to1' via deadkey $d face=$nameF" if $DEAD and $import_dead;
      $DEAD = '@' if $import_dead;
      my $FROM = ($n =~ /^d[89a-f]/i ? '[u16]' : $from);
      $OUT .= sprintf "%s\t%s%s\t// %s -> %s%s\n", $n, $to, $DEAD, $FROM, $to1, $expl;
      $OUT_Apple->{$n_high}{$OUT_Apple_map} = [$to, undef, $DEAD && 1]
        if $OUT_Apple and $n_high !~ /\./ and 0x20 <= hex $n_high and 0x7f != hex $n_high;
    }
    $OUT .= "\n";
    $keys ||= @keys;
  }
  warn "DEADKEY $d for face `$nameF' empty" unless $keys;
  (!!$keys, $OUT, $OUT_Apple)
}

sub massage_diacritics ($) {			# "
  my ($self) = (shift);
  my %char2dia;
  for my $dia (sort keys %{$self->{Diacritics}}) {	# Make order deterministic
    my @v = map { (my $v = $_) =~ s/\p{Blank}//g; $v } @{ $self->{Diacritics}{$dia} };
#    $self->{'[map2diac]'}{$_} = $dia for split //, join '', @v;	# XXXX No check for duplicates???
    my @vv = map [ split // ], @v;
    for my $cc ( [ map @$_, @vv[0..3] ], [ map @$_, @vv[4..$#v] ] ) {	# modifiers, combining
      $char2dia{$cc->[$_]}{$_} = $dia for 0..$#$cc;	# XXXX No check for duplicates at the same distance???
    }
    $self->{'[diacritics]'}{$dia} = \@vv;
  }
  for my $c (keys %char2dia) {
    my @pos = sort {$a <=> $b} keys %{ $char2dia{$c} };
# warn("map2diac( $c ): @pos; ", join '; ', values %{ $char2dia{$c} });
    $self->{'[map2diac]'}{$c} = $char2dia{$c}{$pos[0]};		# prefer the earliest possible occurence
  }
}

sub extract_diacritic ($$$$$$@) {
  my ($self, $dia, $idx, $which, $warn_after__need, $skip2) = (shift, shift, shift, shift, shift, shift);
  my(@v, @elt0)  = map @$_, my $elt0 = shift;			# first one full
  push @v, map @$_[($skip2 ? 2 : 0)..$#$_], @_;		# join the rest, omitting the first 2 (assumed: accessible in other ways)
  @elt0 = $elt0 if $skip2 and $skip2 eq 'skip2-include0';	# include penalized “first 2 of 0th group”; the caller adjusts $idx
  push @v, grep defined, map @$_[0..1], @elt0, @_ if $skip2;
#  @v = grep +((ord $_) >= 128 and $_ ne $dia), @v;
  @v = grep +(ord $_) >= 0x80, @v;
  die "diacritic `  $dia  ' has no $which no.$idx (0-based) assigned" 
    unless $idx >= $warn_after__need or defined $v[$idx];
# warn "Translating for dia=<$dia>: idx=$idx <$which> -> <$v[$idx]> of <@v>" if defined $v[$idx];
  return $v[$idx];
}

sub diacritic2self ($$$$$$$$$) {
  my ($self, $dia, $c, $face, $layer_N, $space, $c_base, $c_noalt, $seen_before) = (shift, shift, shift, shift, shift, shift, shift, shift, shift);
#  warn("Translating for dia=<$dia>: got undef"),
  return $c unless defined $c;
#  $c = $c->[0] if 'ARRAY' eq ref $c;			# Prefix keys behave as usual keys
#  return undef if
  my $is_prefix = (ref $c and $c->[2]);			# Ignore deadkeys (unless we act on $c_base or $c_noalt - UNIMPLEMENTED);
  $_ and 'ARRAY' eq ref $_ and $_ = $_->[0] for $c, $c_base, $c_noalt;			# Prefix keys behave as usual keys
#warn "  Translating for dia=<$dia>: got <$c>";
  die "`  $dia  ' not a known diacritic" unless my $name = $self->{'[map2diac]'}{$dia};
  my $v = $self->{'[diacritics]'}{$name} or die "Panic!";
  my ($first) = grep 0x80 <= ord, @{$v->[0]} or die "diacritic `  $dia  ' does not define any non-7bit modifier";
  return $first if $c eq ' ';
  my $spaces = keys %$space;
  my $flip_AltGr = $self->{faces}{$face}{'[Flip_AltGr_Key]'};
  $flip_AltGr = $self->charhex2key($flip_AltGr) if defined $flip_AltGr;
  $flip_AltGr = 'n/a' unless defined $flip_AltGr;
  my $is_flip_AltGr = (defined $flip_AltGr and $is_prefix and $c eq $flip_AltGr);
  if ($c eq $dia and $is_prefix) {
#warn "Translating2combining dia=<$dia>: got <$c>  --> <$v->[4][0]>";
    # This happens with caron which reaches breve as the first:
#    warn "The diacritic `  $dia  ' differs from the first non-7bit entry `  $first  ' in its list" unless $dia eq $first;
    die "diacritic `  $dia  ' has no default combining char assigned" unless defined $v->[4][0];
    return $v->[4][0];
  }
  my $limits = $self->{Diacritics_Limits}{ALL} || [(0) x 7];
  if ($space->{$c}) {	# index on the SPACE key (0-based, but SPACE is handled above — we assume it is on index 0)
    # ~ and ^ have only 3 spacing variants; one of them must be on ' ' - and we omit the first 2 of the non-principal block...
    return $self->extract_diacritic($dia, $space->{$c}, 'spacing variant', $limits->[0], 'skip2', @$v[0..3]);
  } elsif (0 <= (my $off = index "\r\t\n\x1b\x1d\x1c\b\x7f\x1e\x1f\x00", $c)
	   and not $is_prefix) {	# Enter, Tab, C-Enter, C-[, C-], C-\, Bspc, C-Bspc, C-^, C-_, C-@
    # ~ and ^ have only 3 spacing variants; one of them must be on ' '
    return $self->extract_diacritic($dia, $spaces + $off, 'spacing variant', $limits->[0], 'skip2', @$v[0..3]);
  } elsif (!$spaces and $c =~ /^\p{Blank}$/ and not $is_prefix) {	# NBSP and, (eg) Thin space 2007	-> second/third modifier
    # ~ and ^ have only 3 spacing variants; one of them must be on ' '
    my @pre = grep /^\p{Blank}$/, keys %$seen_before;	# no prefix keys in $seen_before
    push @pre, 'something' unless $seen_before->{' '};	# there is no sense to address slot number 0
    return $self->extract_diacritic($dia, scalar @pre, 'spacing variant', $limits->[0], 'skip2', @$v[0..3]);
  }
  if ($c eq "|" or $c eq "\\" and not $is_prefix) {
#warn "Translating2vertical dia=<$dia>: got <$c>  --> <$v->[4][0]>";	# Skip2 would hurt, since macron+\ is defined:
    return $self->extract_diacritic($dia, ($c eq "|"), 'vertical+etc spacing variant', $limits->[2], !'skip2', @$v[2..3]);
  }
  if ($layer_N == 1 and $c_noalt and ($c_noalt eq "|" or $c_noalt eq "\\")) {
#warn "Translating2vertical dia=<$dia>: got <$c>  --> <$v->[4][0]>";	
    return $self->extract_diacritic($dia, ($c_noalt eq "|"), 'vertical+dotlike combining', $limits->[6], 'skip2', @$v[6,7,4,5]);
  }
  if ($c eq "/" or $c eq "?" and not $is_prefix) {
    return $self->extract_diacritic($dia, ($c eq "?"), 'prime-like+etc spacing variant', $limits->[3], 'skip2', @$v[3]);
  }
  if ($c_noalt and ($c_noalt eq "'" or $c_noalt eq '"')) {
    return $self->extract_diacritic($dia, 1 + ($c_noalt eq '"') + 2*$layer_N, 'combining', $limits->[4], 'skip2', @$v[4..7]);	# 1 for double-prefix
  }
  if ($c eq "_" or $c eq "-" and not $is_prefix) {
    return $self->extract_diacritic($dia, ($c eq "_"), 'lowered+etc spacing variant', $limits->[1], 'skip2', @$v[1..3]);
  }
  if ($layer_N == 1 and $c_noalt and ($c_noalt eq "_" or $c_noalt eq "-")) {
    return $self->extract_diacritic($dia, ($c_noalt eq "_"), 'lowered combining', $limits->[5], 'skip2', @$v[5..7,4]);
  }
  if ($layer_N == 1 and $c_noalt and ($c_noalt eq ";" or $c_noalt eq ":")) {
    return $self->extract_diacritic($dia, ($c_noalt eq ":"), 'combining for symbols', $limits->[7], 'skip2', @$v[7,4..6]);
  }
  if ($layer_N == 1 and defined $c_base and 0 <= (my $ind = index "`1234567890=[],.'", $c_base)) {
    return $self->extract_diacritic($dia, 2 + $ind, 'combining', $limits->[4], 'skip2-include0', @$v[4..7]);	# -1 for `, 1+2 for double-prefix and AltGr-/?
  }
  if ($layer_N == 0 and 0 <= (my $ind = index "[{]}", $c) and not $is_prefix) {
    return $self->extract_diacritic($dia, 2 + $ind, 'combining for symbols', $limits->[7], 'skip2-include0', @$v[7,4..6]);
  }
  if ($layer_N == 1 and $c_noalt and ($c_noalt eq "/" or $c_noalt eq "?")) {
    return $self->extract_diacritic($dia, 6 + ($c_noalt eq "?"), 'combining for symbols', $limits->[7], 'skip2-include0', @$v[7,4..6]);
  }
  return undef;
}

sub diacritic2self_2 ($$$$$$) {		# Takes a key: array of arrays [lc,uc]
  my ($self, $dia, $c, $face, $space, @out, %seen) = (shift, shift, shift, shift, shift);
  my $c0 = $c->[0][0];			# Base character
  for my $N (0..$#$c) {
    my($c1, @res) = $c->[$N];
    for my $shift (0..$#$c1) {
      my($c2, $pref) = $c1->[$shift];
      push @res, $self->diacritic2self($dia, $c2, $face, $N, $space, $c0, $c->[0][$shift], \%seen);
      $pref = $c2->[2], $c2 = $c2->[0] if ref $c2;
      $seen{$c2}++ if defined $c2 and not $pref;
    }
    push @out, \@res;
  }
  @out
}

# Combining stuff:
# perl -C31 -MUnicode::UCD=charinfo -le 'sub n($) {(charinfo(ord shift) || {})->{name}} for (0x20..0x10ffff) {next unless (my $c = chr) =~ /\p{NonspacingMark}/; (my $n = n($c)) =~ /^COMBINING\b/ or next; printf qq(%04x\t%s\t%s\n), $_, $c, $n}' >cc
# perl -C31 -MUnicode::UCD=charinfo -le 'sub n($) {(charinfo(ord shift) || {})->{name}} for (0x20..0x10ffff) {next unless (my $c = chr) =~ /\p{NonspacingMark}/; (my $n = n($c)) =~ /^COMBINING\b/ and next; printf qq(%04x\t%s\t%s\n), $_, $c, $n}' >cc

sub cache_dialist ($@) {	# downstream, it is crucial that a case pair comes from "one conversion"
  my ($self, %seen, %caseseen, @out) = (shift);     
warn("caching dia: [@_]") if warnCACHECOMP;
  for my $d (@_) {
    next unless my $h = $self->{Compositions}{$d};
    $seen{$_}++ for keys %$h;
  }
  for my $c (keys %seen) {
    next if $caseseen{$c};
    # uc may include a wrong guy: uc(ſ) is S, and this may break the pair s/S if ſ comes before s, and S gets a separate binding;
    # so be very conservative with which case pair we include...
    my @case = grep { $_ ne $c and $seen{$_} and lc $_ eq lc $c } lc $c, uc $c or next;
    push @case, $c;
    $caseseen{$_} = \@case, delete $seen{$_} for @case;
  }				# Currently (?), downstream does not distinguish case pairs from Shift-pairs...
  for my $cases ( values %caseseen, map [$_], keys %seen ) {	# To avoid pairing symbols, keep them in separate slots too
    my (@dia, $to);
    for my $dia (@_) {
      push @dia, $dia if grep $self->{Compositions}{$dia}{$_}, @$cases;
    }
    for my $diaN (0..$#dia) {
      $to = $self->{Compositions}{$dia[$diaN]}{$_} and
(warnCACHECOMP and warn("cache dia; c=`$_' of `@$cases'; dia=[$dia[$diaN]]")),
         $out[$diaN]{$_} = $to for @$cases;
    }
  }
#warn("caching dia --> ", scalar @out);
  @out
}

my %cached_aggregate_Compositions;
sub dia2list ($$) {
  my ($self, $dia, @dia) = (shift, shift);
#warn "Split dia `$dia'";
  if ((my ($pre, $mid, $post) = split /(\+|--)/, $dia, 2) > 1) {	# $mid is not counted in that "2"
    for my $p ($self->dia2list($pre)) {
      push @dia, map "$p$mid$_", $self->dia2list($post);
    }
# warn "Split dia to `@dia'";
    return @dia;
  }
  return $dia if $dia =~ /^!?\\/;		# (De)Penalization lists
  $dia = $self->charhex2key($dia);
  unless ($dia =~ /^-?(\p{NonspacingMark}|<(?:font=)?[-\w!]+>|(maybe_)?[ul]c(first)?|dectrl)$/) {
    die "`  $dia  ' not a known diacritic" unless my $name = $self->{'[map2diac]'}{$dia};
    my $v = $self->{'[diacritics]'}{$name} or die "A spacing character <$dia> was requested to be treated as a composition one, but we do not know translation";
    die "Panic!" unless defined ($dia = $v->[4][0]);
  }
  if ($dia =~ /^(-)?<(reverse-)?any(1)?-(other-)?\b([-\w]+?)\b((?:-![-\w]+\b)*)>$/) {
    my($neg, $rev, $one, $other, $match, $rx, $except, @except) 
      = ($1||'', $2, $3, $4, $5, "(?:(?<!<)|(?=font=))\\b$5\\b", qr((?!)), split /-!/, "$6");	# Allow only `font´ at start
    my $cached;
    (my $dia_raw = $dia) =~ s/^-//;
    $cached = $cached_aggregate_Compositions{$dia_raw} and return map "$neg$_", @$cached;

    @except = map { s/^(?=\w)/\\b/; s/(?<=\w)$/\\b/; $_} @except;
    $except = join('|', @except[1..$#except]), $except = qr($except) if @except;
#warn "Exceptions: $except" if @except;
    $rx =~ s/-/\\b\\W+\\b/g;
    my ($A, $B, $AA, $BB);
    my @out = keys %{$self->{Compositions}};
    @out = grep !/^Cached\d+=</, @out;
    @out = grep {length > 1 ? /$rx/ : (lc $self->UName($_) || '') =~ /$rx/ } @out;    	
    @out = grep {length > 1 ? !/$except/ : (lc $self->UName($_) || '') !~ /$except/ } @out;    	
    # make <a> before <a-b>; penalize those with and/over inside
    @out = sort {($A=$a) =~ s/>/\cA/g, ($B=$b) =~ s/>/\cA/g; ($AA=$a) =~ s/\w+\W*/a/g, ($BB=$b) =~ s/\w+\W*/a/g;	# Number of words
    		 /.\b(and|over)\b./ and s/^/~/ for $A,$B; $AA cmp $BB or $A cmp $B or $a cmp $b} @out;
    @out = grep length($match) != length, @out if $other;
    @out = grep !/\bAND\s/, @out if $one;
    @out = reverse @out if $rev;				# xor $reverse;
    if (!dontCOMPOSE_CACHE and @out > 1 and not $neg) {		# Optional caching; will modify composition tables
      my @cached = $self->cache_dialist(@out);			#     but not decomposition ones, hence `not $neg'
      @out = map "Cached$_=$dia_raw", 0..$#cached;
      $self->{Compositions}{$out[$_]} = $cached[$_] for 0..$#cached;
      $cached_aggregate_Compositions{$dia} = \@out;
    }
    @out = map "-$_", @out if $neg;
    return @out;
  } else {		# <pseudo-curl> <super> etc
#warn "Dia=`$dia'";
    return $dia;
  }
}

sub flatten_arrays ($$) {
  my ($self, $a) = (shift, shift);
  warn "method flatten_arrays() takes one argument" if @_;
  return $a unless ref($a  || '') eq 'ARRAY';
  map $self->flatten_arrays($_), @$a;
}

sub array2string ($$) {
  my ($self, $a) = (shift, shift);
  warn "method array2string() takes one argument" if @_;
  return '(undef)' unless defined $a;
  return "<$a>" unless ref($a  || '') eq 'ARRAY';
  '[ ' . join(', ', map $self->array2string($_), @$a) . ' ]';
}

sub dialist2lists ($$) {
  my ($self, $Dia, @groups) = (shift, shift);
  for my $group (split /\|/, $Dia, -1) {
    my @dia;
    for my $dia (split /,/, $group) {
      push @dia, $self->dia2list($dia);
    }
    push @groups, \@dia;		# Do not omit empty groups
  }			# Now get all the chars, and precompile results for them
  @groups
}

sub document_char ($$$;$) {
  my ($self, $c, $doc, $old) = (shift, shift, shift, shift);
  return $c if not defined $c or not defined $doc;
  $doc = "$old->[3] ⇒ $doc" if $old and ref $old and defined $old->[3];
  $c = [$c] unless ref $c;
  $c->[3] = $doc if defined $doc;
  $c
}

sub document_chars_on_key ($$$;$) {	# Usable with all_layers
  my ($self, $c, $doc, $old, @o) = (shift, shift, shift, shift);
  for my $layer (@$c) {
    push @o, [ map {$self->document_char($_, $doc, $old)} @$layer ];
  }
  @o
}

#use Dumpvalue;
my %translators = ( Id => sub ($)  {shift},   Empty => sub ($) { return undef },
	        dectrl =>  sub ($) {defined (my $c = shift) or return undef; $c = $c->[0] if 'ARRAY' eq ref $c;
	        		    return undef if 0x20 <= ord $c; chr(0x40 + ord $c)},
	       maybe_ucfirst =>  sub ($) {defined (my $c = shift) or return undef; $c = $c->[0] if 'ARRAY' eq ref $c; ucfirst $c},
		    maybe_lc =>  sub ($) {defined (my $c = shift) or return undef; $c = $c->[0] if 'ARRAY' eq ref $c; lc $c},
		    maybe_uc =>  sub ($) {defined (my $c = shift) or return undef; $c = $c->[0] if 'ARRAY' eq ref $c; uc $c},
	ucfirst =>  sub ($) {defined (my $c = shift) or return undef; $c = $c->[0] if 'ARRAY' eq ref $c;
				    my $c1 = ucfirst $c;	return undef if $c1 eq $c; $c1},
	     lc =>  sub ($) {defined (my $c = shift) or return undef; $c = $c->[0] if 'ARRAY' eq ref $c;
				    my $c1 = lc $c;		return undef if $c1 eq $c; $c1},
	     uc =>  sub ($) {defined (my $c = shift) or return undef; $c = $c->[0] if 'ARRAY' eq ref $c;
				    my $c1 = uc $c;		return undef if $c1 eq $c; $c1} );
sub make_translator ($$$$$) {		# translator may take some values from "environment" 
  # (such as which deadkey is processed), so caching is tricky: if does -> $used_deadkey reflects this
  # The translator should return exactly one value (possibly undef) so that map TRANSLATOR, list works intuitively.
	# Exception: translator with all_layers: takes a ref to a key (array of arrays of chars); returns array of arrays.
	# There is a possibility to redirect the translation to another key; see $cvt (usually combined with 'all_layers').
  my ($self, $name, $deadkey, $face, $N, $used_deadkey) = (shift, shift, shift || 0, shift, shift, '');	# $deadkey used eg for diagnostics
  die "Undefined recipe in a translator for face `$face', layer $N on deadkey `$deadkey'" unless defined $name;
  if ($name =~ /^Imported\[([\/\w]+)(?:,([\da-fA-F]{4,}))?\]$/) {
    my($d, @sec) = (($2 ? "$2" : undef), split m(/), "$1");
    $d = $deadkey, $used_deadkey ="/$deadkey" unless defined $d;
    my $fromKBDD = $self->get_deep($self, 'DEADKEYS', @sec, lc $d, 'map')	# DEADKEYS/bepo with 00A4 ---> DEADKEYS/bepo/00a4
      or die "DEADKEYS section for `$d' with parts `@sec' not found";
	# indexed by lc hex
    return sub { my $cc=my $c=shift; return $c unless defined $c; $c = $c->[0] if 'ARRAY' eq ref $c; defined($c = $fromKBDD->{$self->key2hex($c)}) or return $c; $self->document_char(chr hex $c, $name, $cc) }, '';
  }
  die "unrecognized Imported argument: `$1'" if $name =~ /^Imported(\[.*)/s;
  return $translators{$name}, '' if $translators{$name};
  if ($name =~ /^PrefixDocs\[(.+)\]$/) {
    $self->{faces}{$face}{'[prefixDocs]'}{$deadkey} = $1;
    return $translators{Empty}, '';
  }
  if ($name =~ /^X11symbol\[(.+)\]$/) {
    $self->{faces}{$face}{'[dead_X11symbol]'}{$deadkey} = $1;
    return $translators{Empty}, '';
  }
  if ($name =~ /^Show\[(.+)\]$/) {
    $self->{faces}{$face}{'[Show]'}{$deadkey} = $self->stringHEX2string($1);
    return $translators{Empty}, '';
  }
  if ($name =~ /^HTML_classes\[(.+)\]$/) {
    (my @c = split /,/, "$1") % 3 and die "HTML_classes[] for key `$deadkey' not come in triples";
    my $C = ( $self->{faces}{$face}{'[HTML_classes]'}{$deadkey || ''} ||= {} );		# Above, deadkey is ||= 0
#	warn "I create HTML_classes for face=$face, prefix=`$deadkey'";
    while (@c) {
      my ($where, $class, $chars) = splice @c, 0, 3;
      ( $chars = $self->stringHEX2string($chars) ) =~ s/\p{Blank}(?=\p{NonspacingMark})//g;
      push @{ $C->{$where}{$_} }, $class for split //, $chars;
    }
    return $translators{Empty}, '';
  }
  if ($name =~ /^Space(Self)?2Id(?:\[(.+)\])?$/) {
    my $dia = $self->charhex2key((defined $2) ? $2 : do {$used_deadkey = "/$deadkey"; $deadkey});	# XXXX `do' is needed, comma does not work
    my $self_OK = $1 ? $dia : 'n/a';
    return sub ($) { my $c = (shift() || '[none]'); $c = $c->[0] if 'ARRAY' eq ref $c;	# Prefix key as usual letter
    		    ($c eq ' ' or $c eq $self_OK and defined $dia) ? $self->document_char($dia, $name) : undef }, $used_deadkey;
  }
  if ($name =~ /^ShiftFromTo\[(.+)\]$/) {
    my ($f,$t) = split /,/, "$1";
    $_ = hex $self->key2hex($self->charhex2key($_)) for $f, $t;
    $t -= $f;					# Treat prefix keys as usual keys:
    return sub ($) { my $cc=my $c=shift; return $c unless defined $c; $c = $c->[0] if 'ARRAY' eq ref $c; $self->document_char(chr($t + ord $c), $name, $cc) }, '';
  }
  if ($name =~ /^SelectRX\[(.+)\]$/) {
    my ($rx) = qr/$1/;				# Treat prefix keys as usual keys:
    return sub ($) { my $cc = my $c=shift; defined $c or return $c; $c = $c->[0] if 'ARRAY' eq ref $c; return undef unless $c =~ $rx; $cc }, '';
  }
  if ($name =~ /^FlipShift$/) {
    return sub ($) { my $c = shift; defined $c or return $c; map [@$_[1,0]], @$c }, '', 'all_layers';
  }
  if ($name =~ /^AssignTo\[(\w+),(\d+)\]$/) {
    my ($sec, $cnt) = ($1, $2);
    $cnt = 0, warn "Unrecognized section `$sec' in AssignTo" unless my $S = $start_SEC{$sec};
    warn("Too many keys ($cnt) put into section `$sec', max=$S->[1]"), $cnt = $S->[1] if $cnt > $S->[1];
    my $toTarget = sub { my $slot = shift; return unless $slot < $cnt; $slot + $S->[0] };
    return sub ($) { @{shift()} }, '', ['all_layers', $toTarget];
  }
  if ($name =~ /^FromTo(FlipShift)?\[(.+)\]$/) {
    my $flip = $1;
    my ($f,$t) = split /,/, "$2", 2;
    exists $self->{layers}{$_} or 	(debug_stacking_ord and warn "  mk_tr_lyrs 2"),
						$_ = ($self->make_translated_layers($_, $face, [$N], $deadkey))->[0]
      for $f, $t;		# Be conservative for caching...
    my $B = "~~~{$f>>>$t}";
    $_ = $self->{layers}{$_} for $f, $t;
    my (%h, $kk);
    for my $k (0..$#$f) {
      my @fr = map {($_ and ref) ? $_->[0] : $_} @{$f->[$k]};
      my @to = map {($_ and ref) ? $_->[0] : $_} @{$t->[$k]};
      if ($flip) {
        $h{defined($kk = $fr[$_]) ? $kk : ''} = $to[1-$_] for 0,1;
      } else {
        $h{defined($kk = $fr[$_]) ? $kk : ''} = $to[$_] for 0,1;
      }# 
    }						# Treat prefix keys as usual keys:
    return sub ($) { my $cc = my $c = shift; defined $c or return $c; $c = $c->[0] if 'ARRAY' eq ref $c; $self->document_char($h{$c}, $name, $cc) }, $B;
  }
  if ($name =~ /^InheritPrefixKeys\[(.+)\]$/) {
    my $base = $1;
    exists $self->{layers}{$_} or (debug_stacking_ord and warn "  mk_tr_lyrs 3"),
    					$_= ($self->make_translated_layers($_, $face, [$N], $deadkey))->[0]
      for $base;
    my $baseL = $self->{layers}{$base};
    my (%h);
    for my $k (0..$#$baseL) {
      for my $shift (0..1) {
        my $C = $baseL->[$k][$shift] or next;
        next unless ref $C and $C->[2];		# prefix
        $h{"$N $k $shift $C->[0]"} = $C;
      }
    }						# Treat prefix keys as usual keys:
    return sub ($) { my $c = shift; defined $c or return $c; return $c if 'ARRAY' eq ref $c and $c->[2]; $h{"@_ $c"} or $c }, $base;
  }
  if ($name =~ /^ByColumns\[(.+)\]$/) {
    my @chars = map {length() ? $self->charhex2key($_) : undef} split /,/, "$1";
    my $g = $self->{faces}{$face}{'[geometry]'}
      or die "Face `$face' has no associated layer with geometry info; did you set geometry_via_layer?";
    my $o = ($self->{faces}{$face}{'[g_offsets]'} or [(0) x @$g]);
    $o = [@$o];					# deep copy
    my ($tot, %c) = 0;
# warn "geometry: [@$g] [@$o]";
    for my $r (@$g) {
      my $off = shift @$o;
      $c{$tot + $_} = $_ + $off for 0..($r-1);
      $tot += $r;
    }
    return sub ($$$$) { (undef, my ($L, $k, $shift)) = @_; return undef if $L or $shift or $k >= $tot; $self->document_char($chars[$c{$k}], "ByColumn[$c{$k}]") }, '';
  }
  if ($name =~ /^ByRows\[(.+)\]$/) {
    s(^\s+(?!\s|///\s+))(), s((?<!\s)(?<!\s///)\s+$)() for my $recipes = $1;
    my (@recipes, @subs) = split m(\s+///\s+), $recipes;
    my $LL = $#{ $self->{faces}{$face}{layers} };		# Since all_layers, we are called only for layer 0; subrecipes may need more
    for my $rec (@recipes) {
      push(@subs, sub {return undef}), next unless length $rec;
#warn "recipe=`$rec'; face=`$face'; N=$N; deadkey=`$deadkey'; last_layer=$LL";
      my ($tr) = $self->make_translator_for_layers( $rec, $deadkey, $face, [0..$LL] );
#warn "  done";
      push @subs, $tr;
    }
    my $g = $self->{faces}{$face}{'[geometry]'}
      or die "Face `$face' has no associated layer with geometry info; did you set geometry_via_layer?";
    my ($tot, $row, %r) = (0, 0);
# warn "geometry: [@$g] [@$o]";
    for my $r (@$g) {
      $r{$tot + $_} = $row for 0..($r-1);
      $tot += $r;
      $row++;
    }
#    return sub ($$$$) { (undef, undef, my $k) = @_; return undef if $k >= $tot; return undef if $#recipes < (my $r = $r{$k}); 
#    			die "Undefined recipe: row=$row; face=`$face'; N=$N; deadkey=`$deadkey'; ARGV=(@_)" unless $subs[$r];
#    			goto &{$subs[$r]} }, '';
    return sub ($$) { (undef, my $k) = @_; return [] if $k >= $tot or $#recipes < (my $r = $r{$k}); 
    			die "Undefined recipe: row=$row; face=`$face'; N=$N; deadkey=`$deadkey'; ARGV=(@_)" unless $subs[$r];
    		      goto &{$subs[$r]} }, '', 'all_layers';
  }
  if ($name =~ /^(?:Diacritic|Mutate)(SpaceOK)?(Hack)?(2Self)?(DupsOK)?(32OK)?(?:\[(.+)\])?$/) {
    my ($spaceOK, $hack, $toSelf, $dupsOK, $w32OK) = ($1, $2, $3, $4, $5);
    my $Dia = ((defined $6) ? $6 : do {$used_deadkey ="/$deadkey"; $deadkey});	# XXXX `do' is needed, comma does not work
    if ($toSelf) {
      die "Mutate2Self does not make sense with SpaceOK/Hack/DupsOK/32OK" if grep $_, $hack, $spaceOK, $dupsOK, $w32OK;
      $Dia = $self->charhex2key($Dia);
      my(@sp, %sp) = map {(my $in = $_) =~ s/(?<=.)\@$//s; $in} @{ ($self->get_VK($face))->{SPACE} || [] };
      @sp = map $self->charhex2key($_), @sp;
      my $flip_AltGr = $self->{faces}{$face}{'[Flip_AltGr_Key]'};
      $flip_AltGr = $self->charhex2key($flip_AltGr) if defined $flip_AltGr;
      @sp = grep $flip_AltGr ne $_, @sp if defined $flip_AltGr;			# It has a different function...
      @sp{@sp[1..$#sp]} = (0..$#sp);		# The leading elt is the scancode
#  warn "SPACE on $Dia: <", join('> <', %sp), '>';
      return sub ($) { 
          $self->document_chars_on_key([$self->diacritic2self_2($Dia, shift, $face, \%sp)], $name) 
        }, $used_deadkey, 'all_layers';
    }
    
    my $isPrimary;
    $Dia =~ s/^\+// and $isPrimary++;				# Wait until <NAMED-*> are expanded

    my $f = $self->get_NamesList;
    $self->load_compositions($f) if defined $f;
    
    $f = $self->get_AgeList;
    $self->load_uniage($f) if defined $f and not $self->{Age};
    # New processing: - = strip 1 from end; -3/ = strip 1 from the last 3
#warn "Doing `$Dia'";
#print "Doing `$Dia'\n";
#warn "Age of <à> is <$self->{Age}{à}>";
    $Dia =~ s(<NAMED-([-\w]+)>){ (my $R = $1) =~ s/-/_/g;
    				 die "Named recipe `$1' unknown" unless exists $self->{faces}{$face}{"Named_DIA_Recipe__$R"};
#    				 (my $r = $self->{faces}{$face}{"Named_DIA_Recipe__$R"}) =~ s/^\s+//; 
    				 $self->recipe2str($self->{faces}{$face}{"Named_DIA_Recipe__$R"}) }ge;
    $Dia =~ s/\|{3,4}/|/g if $isPrimary;
    my($skip, $limit, @groups, @groups2, @groups3) = (0);
    my($have4, @Dia) = (1, split /\|\|\|\|/, $Dia, -1);
    $have4 = 0, @Dia = split /\|\|\|/, $Dia, -1 if 1 == @Dia;
    if (1 < @Dia) {
      die "Too many |||- or ||||-sections in <$Dia>" if @Dia > 3;
      my @Dia2 = split /\|\|\|/, $Dia[1], -1;
      die "Too many |||-sections in the second ||||-section in <$Dia>" if @Dia2 > 2;
#      splice @Dia, 1, 1, @Dia2;
      @Dia2 = @Dia, shift @Dia2 unless $have4;
      $skip = (@Dia2 > 1 ?  1 + ($Dia2[0] =~ tr/|/|/) : 0);
      $Dia[1] .= "|$Dia[2]", pop @Dia if not $have4 and @Dia == 3;
#      $limit =  1 + ($Dia[-1] =~ tr/|/|/) + $skip;
      $limit = 0;						# Not needed with the current logic...
      my @G = map [$self->dialist2lists($_)], @Dia;	# will reverse when merging many into one cached...
      @groups = @{shift @G};      
      @groups2 = @{shift @G} if @G;
      @groups3 = @{shift @G} if @G;
    } else {
      @groups = $self->dialist2lists($Dia);
    }
#warn "Dia `$Dia' -> ", $self->array2string([$limit, $skip, @groups]);
    my $L = $self->{faces}{$face}{layers};
    my @L = map $self->{layers}{$_}, @$L;
    my $Sub = $self->{faces}{$face}{'[AltSubstitutions]'} || {};
# warn "got AltSubstitutions: <",join('> <', %$Sub),'>' if $Sub;
    return sub {
      my $K = shift;				# bindings of the key
      return ([]) x @$K unless grep defined, $self->flatten_arrays($K);		# E.g, ByPairs and SelectRX produce many empty entries...
#warn "Undefined base key for diacritic <$Dia>: <", join('> <', map {defined() ? $_ : '[undef]'} $self->flatten_arrays($K)), '>' unless defined $K->[0][0];
#warn "Input for <$Dia>: <", join('> <', map {defined() ? $_ : '[undef]'} $self->flatten_arrays($K)), '>';
      my $base = $K->[0][0];
      $base = '<?>' unless defined $base;
      $base = $base->[0] if ref $base;
      return ([]) x @$K if not $spaceOK and $base eq ' ';		# Ignore possiblity that SPACE is a deadKey
      my $sorted = $self->sort_compositions(\@groups, $K, $Sub, $dupsOK, $w32OK);
      my ($sorted2, $sorted3, @idx_sorted3);
      $sorted2 = $self->sort_compositions(\@groups2, $K, $Sub, $dupsOK, $w32OK) if @groups2;
      $sorted3 = $self->sort_compositions(\@groups3, $K, $Sub, $dupsOK, $w32OK) if @groups3;
      @idx_sorted3 = @$sorted + (@groups2 ? @$sorted2 : 0) if @groups3;		# used for warnings only
      $self->{faces}{$face}{'[in_dia_chains]'}{$_}++
        for grep defined, ($hack ? () : map {($_ and ref) ? $_->[0] : $_}
        			# index as $res->[group][penalty_N][double_occ][layer][NN][shift]
        			map {$_ ? @$_ : ()} map {$_ ? @$_ : ()} map {$_ ? @$_ : ()} map {$_ ? @$_ : ()} map {$_ ? @$_ : ()} 
        			  @$sorted, @{$sorted2 || []}, @{$sorted3 || []});
      # map {($_ and ref) ? $_->[0] : $_} map @{$_||[]}, @out
require Dumpvalue if printSORTEDLISTS;
Dumpvalue->new()->dumpValue(["Key $base", $sorted]) if printSORTEDLISTS;
      warn $self->report_sorted_l($base, [@$sorted, @{$sorted2 || []}, @{$sorted3 || []}], [scalar @$sorted, $skip + scalar @{$sorted || []}, @idx_sorted3])
        if warnSORTEDLISTS;
      my $LLL = '';
      if ($sorted2) {
        my (@slots, @LL);
        for my $l (0..$#L) {
          push @slots, $self->shift_pop_compositions($sorted2, $l, !'from end', !'omit', $limit, $skip, my $ll = []);
          push @LL, $ll;
print 'From Layers  <', join('> <', map {defined() ? $_ : 'undef'} @$ll), ">\n" if printSORTEDLISTS;
	  $LLL .= ' | ' . join(' ', map {defined() ? $_ : 'undef'} @$ll) if warnSORTEDLISTS;
        }
print 'TMP Extracted ', $self->array2string($slots[0]), "\n" if printSORTEDLISTS;
print 'TMP Extracted ', $self->array2string([@slots[1..$#slots]]), " deadKey=$deadkey\n" if printSORTEDLISTS;
        my $appended = $self->append_keys($sorted3 || $sorted2, \@slots, \@LL, !$sorted3 && 'prepend');
Dumpvalue->new()->dumpValue(["Key $base; II", $sorted2]) if printSORTEDLISTS;
	if (warnSORTEDLISTS) {
          $LLL =~ s/^[ |]+//;
          $_++ for @idx_sorted3;	# empty or 1 elt
          warn "TMP Extracted: ", $self->array2string(\@slots), " from layers $LLL\n";	# 1 is for what is prepended by append_keys()
          warn $self->report_sorted_l($base, [@$sorted, @$sorted2, @{$sorted3 || []}],		# Where to put bold/dotted-bold separators:
          			      [scalar @$sorted, !!$appended + $skip + scalar @$sorted, @idx_sorted3], ($appended ? [1 + scalar @$sorted] : ()));
	}
      }
      my(@out, %seen); 
      for my $Ln (0..$#L) {
        $out[$Ln] = $self->shift_pop_compositions($sorted, $Ln);
        $seen{$_}++ for grep defined, map {($_ and ref) ? $_->[0] : $_} @{$out[$Ln]};
      }
      for my $L (@out) {	# $L is an array indexed by shift state
        $L = [map {(not $_ or ref $_) ? $_ : [$_,undef,undef,'Diacritic operator']} @$L];
      }
      # Insert non-yet-inserted characters from $sorted2, $sorted3
      for my $extra (['from end', $sorted2, 2], [0, $sorted3, 3]) {
        next unless $extra->[1];
        $self->deep_undef_by_hash(\%seen, $extra->[1]);
        for my $Ln (0..$#L) {
          my $o = $out[$Ln];
          unless (defined $o->[0] and defined $o->[1]) {
            my $o2 = $self->shift_pop_compositions($extra->[1], $Ln, $extra->[0], !'omit', !'limit', 0, undef, defined $o->[0], defined $o->[1]);
            $o2 = [map {(!defined $_ or ref) ? $_ : [$_,undef,undef,"Diacritic operator (choice $extra->[2])"]} @$o2];
            defined $o->[$_] or $o->[$_] = $o2->[$_] for 0,1;
            $seen{$_}++ for grep defined, map {($_ and ref) ? $_->[0] : $_} @$o;
          }
        }
      }
print 'Extracted ', $self->array2string(\@out), " deadKey=$deadkey\n" if printSORTEDLISTS;
      warn 'Extracted ', $self->array2string(\@out), " deadKey=$deadkey\n" if warnSORTEDLISTS;
      $self->{faces}{$face}{'[from_dia_chains]'}{$_}++
        for grep defined, ($hack ? () : map {($_ and ref) ? $_->[0] : $_} map @{$_||[]}, @out);
#warn "Age of <à> is <$self->{Age}{à}>";
#warn "Output: <", join('> <', map {defined() ? $_ : '[undef]'} $self->flatten_arrays(\@out)), '>';
      return @out;
    }, $used_deadkey, 'all_layers';
  }
  if ($name =~ /^DefinedTo\[(.+)\]$/) {
    my $to = ($1 eq 'undef' ? [] : $self->charhex2key($1));
    return sub ($) { my $c = shift; defined $c or return $c; $self->document_char($to, 'DefinedTo', $c) }, '';
  }
  if ($name =~ /^ByPairs(Inv)?(Prefix)?(Flat)?(Apple)?\[(.+)\]$/) {
    my ($invert, $prefix, $flat, $Apple, $in, @Pairs, %Map) = ($1, $2, $3, $4, $5);
    die "Inversion is tested only with flat maps or a prefix key: <<<$in>>> in `$face´" if $invert and not ($flat or $prefix);
    $in =~ s/^\s+//;
    @Pairs = split /\s+(?!\p{NonspacingMark})/, $in;
    for my $p (@Pairs) {
      while (length $p) {
        die "Odd number of characters in a ByPairs map <$in>" 
          unless $p =~ s/^((?:\p{Blank}\p{NonspacingMark}|(?:\b\.)?[0-9a-f]{4,}\b(?:\.\b)?|.){2})//i;
        (my $Pair = $1) =~ s/\p{Blank}//g;
#warn "Pair = <$Pair>";
	# Cannot do it earlier, since HEX can introduce new blanks
	$Pair =~ s/(?<=[0-9a-f]{4})\.$//i;		# Remove . which was on \b before extracting substring
        $Pair = $self->stringHEX2string($Pair);
#warn "  -->  <$Pair>";
        die "Can't split ByPairs rule into a pair: I see <$Pair>" unless 2 == scalar (my @c = split //, $Pair);
        die qq("From" character <$c[0] duplicated in a ByPairs map <$in>)
          if exists $Map{$c[0]};
        $Map{$c[0]} = ($prefix ? [$c[1], undef, ($invert ? 3 : 1)<<3] : $c[1]);		# massage_imported2 makes >> 3
      }
    }
    die "Empty ByPairs map <$in>" unless %Map;			# Treat prefix keys as usual keys:
    if ($Apple) {				# XXXX ???? This does not work!  Do we store $deadkey anywhere?
      $self->{faces}{$face}{'[AppleMap]'}[$N]{$_} = $Map{$_} for keys %Map;
      return $translators{Empty}, '';
    }
    if ($flat and not $N) {
      die "<<<Flat>>> makes sense only in toplevel descriptions of satellite faces: <<<$in>>> in `$face´" unless $deadkey;
      my $inv = $invert ? 'Inv' : '';
      $self->{faces}{$face}{"[FlatPrefixMap$inv]"}{$deadkey}{$self->key2hex($_)}
        = $self->document_char($Map{$_}, 'explicit flat tuneup') for keys %Map;
      $used_deadkey = "/$deadkey";
    }
    return sub ($) { my $c = shift; defined $c or return $c; $c = $c->[0] if 'ARRAY' eq ref $c; $self->document_char($Map{$c}, 'explicit tuneup') }, $used_deadkey;
  }
  my $map = $self->get_deep($self, 'DEADKEYS', split m(/), $name);
  die "Can't resolve character map `$name'" unless defined $map;
  unless (exists $map->{map}) {{
    my($k1) = keys %$map;
    die "Character map `$name' does not contain HEX: `$k1'" if %$map and not $k1 =~ /^[0-9a-f]{4,}$/;
    die "Character map is a parent-type map, but no deadkey to use specified" unless defined $deadkey;
    my $Map = { map +(chr hex $_, $map->{$_}), keys %$map };
    die "Character map `$name' does not contain `$deadkey', contains <", (join '> <', keys %$map), ">"
      unless exists $Map->{chr hex $deadkey};
    $map = $Map->{chr hex $deadkey}, $used_deadkey = "/$deadkey" if %$Map;
    $map = {map => {}}, warn "Character map for `$name' empty" unless %$map;
  }}
  die "Can't resolve character map `$name' `map': <", (join '> <', %$map), ">" unless defined $map->{map};
  $map = $map->{map};
  my $Map = { map +(chr hex $_, chr hex($map->{$_})), keys %$map };	# hex form is not unique
  ( sub ($) {					# Treat prefix keys as usual keys:
      my $c = shift; defined $c or return $c; $c = $c->[0] if 'ARRAY' eq ref $c; $self->document_char($Map->{$c}, "DEADKEYS=$name")
    }, $used_deadkey )
}

sub depth1_A_translator($$) {		# takes a ref to an array of chars
  my ($self, $tr) = (shift, shift);
  return sub ($) {
    my $in = shift;
    [map $tr->($_), @$in]
  }
}

sub depth2_translator($$) {		# takes a ref to an array of arrays of chars
  my ($self, $tr) = (shift, shift);
  return sub ($$) {
    my ($in, $k, @out) = (shift, shift);
    for my $L (0..$#$in) {
      my $Tr = $tr->[$L];
      die "Undefined translator for layer=$L; total=", scalar @$tr unless defined $Tr;
      push @out, [map $Tr->($in->[$L][$_], $L, $k, $_), 0..$#{$in->[$L]}]
    }
    @out
  }
}

sub make_translator_for_layers ($$$$$) {		# translator may take some values from "environment" 
  # (such as which deadkey is processed), so caching is tricky: if does -> $used_deadkey reflects this
  # The translator should return exactly one value (possibly undef) so that map TRANSLATOR, list works intuitively.
  my ($self, $name, $deadkey, $face, $NN) = (shift, shift, shift || 0, shift, shift);	# $deadkey used eg for diagnostics
  my ($Tr, $used, $for_layers) = $self->make_translator( $name, $deadkey, $face, $NN->[0] );
  ($for_layers, my $cvt) = (ref $for_layers ? @$for_layers : $for_layers);
  return $Tr, [map "$used![$_]", @$NN], $cvt if $for_layers;
  my @Tr = map [$self->make_translator($name, $deadkey, $face, $_)], @$NN;
  $self->depth2_translator([map $_->[0], @Tr]), [map $_->[1], @Tr], $cvt;
}

sub make_translated_layers_tr ($$$$$$$) {		# Apply translation map
  my ($self, $layers, $tr, $append, $deadkey, $face, $NN) = (shift, shift, shift, shift, shift, shift, shift);
  my ($Tr, $used, $cvt) = $self->make_translator_for_layers($tr, $deadkey, $face, $NN);
#warn "  tr=<$tr>, key=<$deadkey>, used=<$used>";
  my @new_names = map "$tr$used->[$_]($layers->[$_])$append" . ($append and $NN->[$_]), 0..$#$NN;
  return @new_names unless grep {not exists $self->{layers}{$_}} @new_names;
# warn "Translating via `$tr' from layer [$layer]: <", join('> <', map "@$_", @{$self->{layers}{$layer}}), '>';
  my (@L, @LL) = map $self->{layers}{$_}, @$layers;
  for my $n (0..$#{$L[0]}) {				# key number
    my @C = $Tr->( [ map $L[$_][$n], 0..$#L ], $n );	# rearrange one key into $X[$Layer][$shift]
    if ($cvt) {
      defined $cvt->($n) and $LL[$_][$cvt->($n)] = $C[$_] for 0..$#L;
    } else {
      push @{$LL[$_]}, $C[$_] for 0..$#L;
    }
  }
  $self->{layers}{$new_names[$_]} = $LL[$_] for 0..$#L;
  @new_names
}

sub key2string ($$) {
  my ($self, $key, @o) = (shift, shift);
  return '<>' unless defined $key;
  return '[]' unless grep defined, @$key;
  for my $k (@$key) {
    push(@o, 'undef'), next unless defined $k;
    push @o, ((ref $k) ? (defined $k->[0] ? $k->[0] : '<undef>') : $k);
  }
  "[@o]"
}

sub layer2string ($$) {
  my ($self, $layer, $last, $rest) = (shift, shift, -1, '');
  my @o = map $self->key2string($_), @$layer;
  2 < length $o[$_] and $last = $_ for 0..$#o;
  $rest = '...' if $last != $#o;
  (join ' ', @o[0..$last]) . $rest
}

sub make_translated_layers_stack ($$@) {		# Stacking
  my ($self, @out, $ref) = (shift);
  my $c = @{$_[0]};
  @$_ == $c or die "Stacking: number of layers ", scalar(@$_), " != number of layers $c of the first elt"
    for @_;
  for my $lN (0..$c-1) {	# layer Number
    my @layers = map $_->[$lN], @_;
    push @out, "@layers";
    if (debug_stacking) {
      warn "Stack in-layer $lN `$_': ", $self->layer2string($self->{layers}{$_}), "\n" for @layers;
    }
    next if exists $self->{layers}{"@layers"};
    my (@L, @keys) = map $self->{layers}{$_}, @layers;
    for my $lI (reverse 0..$#L) {
      my($l, $to) = $L[$lI];
      # warn "... Layer$lN: `$layers[$lI]'..." if debug_stacking;
      for my $k (0..$#$l) {
        for my $kk (0..$#{$l->[$k]}) {
          if (debug_STACKING and defined( my $cc = $l->[$k][$kk] )) {
            $cc = $cc->[0] if ref $cc;
	    warn "...... On $k/$kk (${lI}th lN=$lN): I see `$cc': ", !defined $keys[$k][$kk], "\n" ;
	  }
          if (defined($to = $l->[$k][$kk])) {
            undef $to if $to and ref $to and not defined $to->[0];	# allow undef'ing
            $keys[$k][$kk] = $to;
          }
        }
        $keys[$k] ||= [];
      }
    }
    $self->{layers}{"@layers"} = \@keys;
    warn "Stack out-layer $lN `@layers':\n\t", $self->layer2string(\@keys), "\n" if debug_stacking;
  }
  warn 'Stack out-layers:', (join "\n\t", '', @out), "\n" if debug_stacking;
  @out;
}

sub make_translated_layers_noid ($$$@) {		# Stacking
  my ($self, $whole, $refr, @out, $ref, @seen) = (shift, shift, shift);
  my $c = @$refr;
#warn "noid: join ", scalar @_, " faces of $c layers; ref=[@$refr] first=[@{$_[0]}]";
  @$_ == $c or die "Stacking: number of layers ", scalar(@$_), " != number of layers $c of the reference face"
    for @_;
  my @R = map $self->{layers}{$_}, @$refr;
  my $dbg = debug_noid; # && ((join ' ', map @$_, @_) =~ /US_Base_Compose/ and "@$refr" =~ /Greek/);
  if ($whole) {
    my $last = $#{$R[0]};
    for my $key (0..$last) {
      for my $l (@R) {
        $seen[$key]{$_}++ for map {ref() ? (!!$_->[2]||0) . $_->[0] : "0$_"} grep defined, @{ $l->[$key] };
#warn "$key of $last: keys=", join(',',keys %{$seen[$key]});
      }
    }
  }
#  my $name = 'NOID([' . join('], [', map {join ' +++ ', @$_} @_) . '])';
  for my $l (0..$c-1) {
    my (@layers,$rel) = map $_->[$l], @_;
    if ($whole) {
      $rel = "*\[$whole]";
#      $name .= "'"	# Keep names of layers distinct, but since they are all interdependent, do not construct basing on layer names
#      $name = "NOID*[$whole](" . (join ' +++ ', @layers) . ')'
    } else {
      $rel = "[$refr->[$l]]";
    }
    my $name = "NOID$rel(" . (join ' =||= ', @layers) . ')';
    push @out, $name;
#warn ". Doing layer number $l, name=`$name'...";
    warn "Do layerN=$l\n" if debug_noid and $dbg;
    (debug_noid and warn "layer exists: $name\n"), next if exists $self->{layers}{$name};
    my (undef, @L, @keys) = map $self->{layers}{$_}, $refr->[$l], @layers;
    for my $llN (0..$#L) {
      warn "Do part:layerN=${llN}:$l\n" if debug_noid and $dbg;
      my $ll = $L[$llN];
#warn "... Another layer for $l...";
      for my $k (0..$#$ll) {
        for my $kk (0..$#{$ll->[$k]}) {
	  my $ch = $ll->[$k][$kk];
	  my $rch = $R[$l][$k][$kk];
	  $ch = (ref $ch ? (!!$ch->[2]||0) . $ch->[0] : "0$ch") if defined $ch;
	  $rch = (ref $rch ? (!!$rch->[2]||0) . $rch->[0] : "0$rch") if defined $rch;
	  warn "...... On $llN:$l $k/$kk: I see `$ch'; seen=`",($seen[$k]{$ch} || 'N/A'), "'; keys=", join(',',sort keys %{$seen[$k]})
	    if debug_noid and defined $ll->[$k][$kk];
          ### (debug_noid and warn "   ... Use it\n"),
          $keys[$k][$kk] = $ll->[$k][$kk] 	# Deep copy
            if defined $ch and not defined $keys[$k][$kk] 
               and ($whole ? !$seen[$k]{$ch} : $ch ne ( defined $rch ? $rch : '' ));
        }
        $keys[$k] ||= [];
      }
    }
    $self->{layers}{$name} = \@keys;
  }
  warn "NOID --> <@out>\n" if debug_noid;
  @out;
}

sub paren_match_q ($$) {
  my ($self, $s) = (shift, shift);
  ($s =~ tr/(/(/) == ($s =~ tr/)/)/)
}

sub brackets_match_q ($$) {
  my ($self, $s) = (shift, shift);
  ($s =~ tr/[/[/) == ($s =~ tr/]/]/)
}

sub join_min_paren_brackets_matched ($$@) {
  my ($self, $join, @out) = (shift, shift, shift);
#warn 'joining <', join('> <', @out, @_),'>';
  while (@_) {
    while (@_ and not ($self->paren_match_q($out[-1]) and $self->brackets_match_q($out[-1]))) {
      $out[-1] .= $join . shift;
    }
    push @out, shift if @_;
  }
  @out
}

sub face_by_face_recipe ($$$) {
  my($self, $f, $base) = (shift, shift, shift);
  return if $self->{faces}{$f}{layers};
  return unless $self->{face_recipes}{$f};
  die "Can't determine number of layers in face `$f': face_recipe exists, but not numLayers" 
    unless defined (my $n = $self->{faces}{$base}{numLayers});
  warn "Massaging face `$f': use face_recipes...\n" if debug_face_layout_recipes;
  $self->{faces}{$f}{layers} = [('Empty') x $n];		# Preliminary (so know the length???)
  $self->{faces}{$f}{layers} = $self->layers_by_face_recipe($f, $base);
}
  
sub layers_by_face_recipe ($$$;$) {
  my ($self, $face, $base, $r) = (shift, shift, shift, shift);
  my $R = $self->{face_recipes}{$face};
  unless (defined $r or defined $R) {
    if ($face =~ /^(\w+)(?:(⁴)|₄)$/) {
      $R = ($2 ? "Layers($1²+$1²⁺)" : "Layers($1²+$1₂)");
    }
  }
  die "No face recipe for `$face' found" unless $R or defined $r;
  $r = $R if $R;
  $r = $self->recipe2str($r);
#print "face recipe `$face'\n";
  my $LL = $self->{faces}{$base}{layers};
  warn "Using face_recipes for `$face', base=$base ==> `$r'\n" if debug_face_layout_recipes;
	(debug_stacking_ord and warn "  mk_tr_lyrs 4 (b=$base;;; f=$face)");
  my $L = $self->{faces}{$face}{layers} = $self->make_translated_layers($r, $base, [0..$#$LL]);
#print "face recipe `$face'  -> ", $self->array2string($L), "\n";
#  warn "Using face_recipes `$face'  -> ", $self->array2string($L) if debug_face_layout_recipes;
  warn "Massaged face `$face' ->", (join "\n\t", '', @$L), "\n" if debug_face_layout_recipes;
#warn "face recipe `$face' --> ", $self->array2string([map $self->{layers}{$_}, @$L]);
  $L;
}

sub export_layers ($$$;$) {
  my ($self, $face, $base, $full) = (shift, shift, shift, shift);
# warn "Doing FullFace on <$face>, base=<$base>\n" if $full;
  ($full ? undef : $self->{faces}{$face}{'[ini_layers_prefix]'} || $self->{faces}{$face}{'[ini_layers]'}) || 
    $self->{faces}{$face}{layers} 
      || $self->layers_by_face_recipe($face, $base)
}

sub pseudo_layer ($$$$;$) {
  my ($self, $recipe, $face, $N, $deadkey) = (shift, shift, shift, shift, shift);
  my $ll = my $l = $self->pseudo_layer0($recipe, $face, $N);
#  warn "Pseudo-layer recipe `$recipe', face=`$face', N=$N ->\n\t$l\n" if $recipe =~ /Greek__/;
#warn("layer recipe: `$l'"), 
  ($l = $self->layer_recipe($l)) =~ s/^\s+// if exists $self->{layer_recipes}{$ll};
  warn "pseudo_layer(`$recipe'): Using layout_recipe `$l' for layer '$ll'\n" if debug_face_layout_recipes and exists $self->{layer_recipes}{$ll};
  return $l if $self->{layers}{$l};
	  (debug_stacking_ord and warn "  mk_tr_lyrs 5");
  ($self->make_translated_layers($l, $face, [$N]))->[0]
#  die "Component `$l' of a pseudo-layer cannot be resolved"
}

sub pseudo_layer0 ($$$$) {
  my ($self, $recipe, $face, $N) = (shift, shift, shift, shift);
  if ($recipe eq 'LinkFace') {
    my $L = $self->{faces}{$face}{LinkFace} or die "Face `$face' has no LinkFace";
    return ($self->export_layers($L, $face))->[$N];
  }
  return ($self->export_layers($face, $face))->[$N] if $recipe eq 'Self';
  if ($recipe =~ /^Layers\((.*\+.*)\)$/) {
    my @L = split /\+/, "$1";
    return $L[$N];
  }
  my $N1 = $self->flip_layer_N($N, $#{ $self->{faces}{$face}{layers} });
  if ($recipe eq 'FlipLayersLinkFace') {
    my $L = $self->{faces}{$face}{LinkFace} or die "Face `$face' has no LinkFace";
    return ($self->export_layers($L, $face))->[$N1];
  }
#warn "Doing flip/face via `$recipe', N=$N, N1=$N1, face=`$face'";
  return ($self->export_layers($face, $face))->[$N1] if $recipe eq 'FlipLayers';
#  my $gr_debug = ($recipe =~ /Greek__/);
  if (debug_PERL_dollar1_scoping) {
    return ($self->export_layers("$3", $face, !!$1))->[$2 ? $N : $N1]
      if $recipe =~ /^(Full)?(?:(Face)|FlipLayers)\((.*)\)$/;
  } else {
    my $m1;	# Apparently, in perl5.10, if replace $m1 by $1 below, $1 loses its TRUE value between match and evaluation of $1
#  ($gr_debug and warn "Pseudo-layer `$recipe', face=`$face', N=$N, N1=$N1\n"),
    return ($self->export_layers("$3", $face, !!$1))->[$m1 ? $N : $N1]
      if $recipe =~ /^(Full)?(?:(Face)|FlipLayers)\((.*)\)$/ and ($m1 = $2, 1);
  }
  if ($recipe =~ /^prefix(NOTSAME(case)?)?=(.+)$/) {
    # Analogue of NOID with the principal layers as reference, and layers of DeadKey as sources
    my($notsame, $case) = ($1,$2);
    my $hexPrefix = $self->key2hex($self->charhex2key($3));
	warn "  mk_tr_lyrs pre-7 e_D_M" if debug_stacking_ord;
    $self->ensure_DeadKey_Map($face, $hexPrefix);
    my $layers = $self->{faces}{$face}{'[deadkeyLayers]'}{$hexPrefix} or die "Unknown prefix character `$hexPrefix´ in layers-from-prefix-key";
    return $layers->[$N] if $N or not $notsame;		# After this $N==0 and $notsame
    my $name = "NOTSAME[$face]$layers->[$N]";
    return $self->{layers}{$name} if $self->{layers}{$name};
    my @LL = map $self->{layers}{$_}, @$layers;
    my $L0 = $self->{faces}{$face}{layers};
    my @L0 = map $self->{layers}{$_}, @$L0;
    my @OUT;
    for my $charN (0..$face->{'[non_VK]'}-1) {
      my (@L, %seen_baseface) = map $_->[$charN], @LL;	# %seen_baseface: chars present in the base face in this position
      for my $layers0 (map $_->[$charN], @$L0) {
        for my $sh (@$layers0) {
          $seen_baseface{ref($sh) ? $sh->[0] : $sh}++ if defined $sh;
        }
      }
      my(@CC, @pp, @OK);	# Inspect this position in Layer 0 (or all if $notsame and emitting layer 0: this hold automatically!???):
      for my $l (@L[0 .. (($notsame && !$N) ? @{ $self->{faces}{$face}{layers} } - 1 : 0)]) {
        my(%s1, @was, @out);
        for my $sh (0..$#$l) {		# $self->dead_with_inversion(!'hex', $_, $face, $self->{faces}{$face})
          my @C = map {defined() ? (ref() ? $_->[0] : $_) : $_} $l->[$sh];
          my @p = map {defined() ? (ref() ? $_->[2] : 0 ) : 0 } $l->[$sh];
          ($CC[$sh], $pp[$sh]) = ($C[0], $p[0]) if not defined $CC[$sh] and defined $C[0];	# fallback: merge to L=0 even if dup
          ($CC[$sh], $pp[$sh], $OK[$sh], $s1{$C[0]}) = ($C[0], $p[0], 1,1) if !$OK[$sh] and defined $C[0] and not $seen_baseface{$C[0]};
          ($CC[$sh], $pp[$sh], $OK[$sh], $s1{$was[0]}) = (@was, 1,1)	# Do layer>0 !Shift ⇝ Shift-layer0 if not dup and not used yet
            if !$case and $sh and !$OK[$sh] and defined $C[0] and defined $was[0]
		and not $seen_baseface{$was[0]} and not $s1{$was[0]};
          @was = ($C[0], $p[0]) unless $sh;		# may omit `unless´
#          $cnt++ if defined $CC[$sh];
        }
      }
      push @OUT, \@CC;
    }
    $self->{layers}{$name} = \@OUT;
    return $name;
  }
  die "Unrecognized Face recipe `$recipe'"
}

#  my @LL = map $self->{layers}{'[ini_copy1]'}{$_} || $self->{layers}{'[ini_copy]'}{$_} || $self->{layers}{$_}, @$LL;

# A stand-alone word is either LinkFace, or is interpreted as a name of 
# translation function applied to the current face.
# A name which is an argument to a function is allowed to be a layer name
#  (but note that then both layers of the face will be mapped to that same 
#   layer - unless one restricts the recipe to a particular layer 0/1 of the 
#   face).  
# In particular: to specify a layer, use Id(LayerName).
#use Dumpvalue;
sub make_translated_layers ($$$$;$$) {		# support Self/FlipLayers/LinkFace/FlipShift, stacking and maps
  my ($self, $recipe, $face, $NN, $deadkey, $noid, $append, $ARG) = (shift, shift, shift, shift, shift, shift, '');
# XXX We can't cache created layer by name, since it depends on $recipe and $N too???
#  return $recipe if exists $self->{layers}{$recipe};
#  my $FACE = $recipe . join '===', '', @$NN, '';
#  return $self->{faces}{$FACE}{layers} if exists $self->{faces}{$FACE}{layers};
  while ($recipe =~ /^Shortcut\(([^()]+)\)$/) {		# Same as Face(), but does not disable $deadkey; no caching...
    die "No face recipe for `$1' found" unless my $r = $self->{face_recipes}{$1};
    $recipe = $self->recipe2str($r);
    warn "Using face_recipes for `$1', base=$face ==> `$recipe'\n" if debug_face_layout_recipes;
  }
  my @parts = grep /\S/, $self->join_min_paren_brackets_matched('', split /(\s+)/, $recipe)
    or die "Whitespace face recipe `$recipe'?!";
  if (@parts > 1) {
#warn "parts of the translation spec: <", join('> <', @parts), '>';
    my @layers = map $self->make_translated_layers($_, $face, $NN, $deadkey), @parts;
    warn "Stacking/NOID for layers `@parts'", (join "\n\t", '', map {join ' &&& ', @$_} @layers), "\n"
      if debug_noid and $noid or debug_stacking;
#print "Stacking for `$recipe'\n" if $DEBUG;
#Dumpvalue->new()->dumpValue(\@layers) if $DEBUG;
    return [$self->make_translated_layers_noid($noid eq 'NotSameKey' && " $parts[0] ", @layers)]
      if $noid;
    return [$self->make_translated_layers_stack(@layers)];
  }
  return [map $self->pseudo_layer($recipe, $face, $_), @$NN]
    if $recipe =~ /^(prefix(?:NOTSAME(?:case)?)?=.*|(FlipLayers)?LinkFace|FlipLayers|Self|((Full)?(Face|FlipLayers)|Layers)\([^()]+\))$/;
  $recipe =~ s/^(FlipShift)$/$1(Self)/;
  if ( $recipe =~ /\)$/ ) {
    if ( $recipe =~ /^[^(]*\[/ ) {		# Tricky: allow () inside Func[](args)
      my $pos;
      while ( $recipe =~ /(?=\]\()/g ) {
        $pos = 1 + pos $recipe, last if $self->brackets_match_q(substr $recipe, 0, 1 + pos $recipe)
      }
      die "Can't parse `$recipe' as Func[Arg1](Arg2)" unless $pos;
      $ARG = substr $recipe, $pos + 1, length($recipe) - $pos - 2;
      $recipe = substr $recipe, 0, $pos;
    } else {
      my $o = $recipe;
      ($recipe, $ARG) = ($recipe =~ /^(.*?)\((.*)\)$/s) or warn "Can't parse recipe `$o'";
    }
  } else {
    $ARG = '';
  }
#warn "Translation sub-spec: recipe = <$recipe>, ARG=<$ARG>";
  if ($recipe =~ /^If(Not)?Prefix\[(.*)\]$/s) {	# No embedded \\]
    my $neg = $1;
    my @prefix = map $self->key2hex($self->charhex2key($_)), split /,/, "$2";
###    warn "dk=<$deadkey> prefix=<@prefix>" if defined $deadkey;
    return $self->make_translated_layers($ARG, $face, $NN, $deadkey, $noid)
	if defined($deadkey) and ($neg xor grep $_ eq $deadkey, @prefix);
    ($recipe, $ARG) = ('Empty', [('Empty') x @$NN]);
  }
  if (length $ARG) {
    if (exists $self->{layers}{$ARG}) {
      $ARG = [($ARG) x @$NN];
    } elsif (!ref $ARG) {
      ($ARG = $self->layer_recipe($ARG)) =~ s/^\s+// if exists $self->{layer_recipes}{my $a = $ARG};
      warn "make_translated_layers: Using layout_recipe `$ARG' for layer '$a'\n" if debug_face_layout_recipes and exists $self->{layer_recipes}{$a};
      ($noid) = ($recipe =~ /^(NotId|NotSameKey)$/);
      $ARG = $self->make_translated_layers($ARG, $face, $NN, $deadkey, $noid);
      return $ARG if $noid;
    }
  } else {
    $ARG = [map $self->{faces}{$face}{layers}[$_], @$NN];
    $append = "#$face#";
  }
  [$self->make_translated_layers_tr($ARG, $recipe, $append, $deadkey, $face, $NN)];	# Either we saw (), or $recipe is not a face recipe!
}

sub massage_translated_layers ($$$$;$) {
  my ($self, $in, $face, $NN, $deadkey) = (shift, shift, shift, shift, shift, '');
#warn "Massaging `$deadkey' for `$face':$N";
  return $in unless my $r = $self->get_deep($self, 'faces', (my @p = split m(/), $face), '[Diacritic_if_undef]');
  $r =~ s/^\s+//;
#warn "	-> end recipe `$r'";
	warn "  mk_tr_lyrs 6" if debug_stacking_ord;
  my $post = $self->make_translated_layers($r, $face, $NN, $deadkey);
	warn "  mk_tr_lyrs_st 1" if debug_stacking_ord;
  return [$self->make_translated_layers_stack($in, $post)];
}

sub default_char ($$) {
  my ($self, $F) = (shift, shift);
  my $default = $self->get_deep($self, 'faces', $F, '[DeadChar_DefaultTranslation]');
  $default =~ s/^\s+//, $default = $self->charhex2key($default) if defined $default;
  $default;
}

sub create_inverted_face ($$$$$) {
  my ($self, $F, $KK, $chain, $flip_AltGr) = (shift, shift, shift, shift, shift);
  my $H = $self->{faces}{$F};
  my $auto_chr = $H->{'[deadkeyInvAltGrKey]'}{$KK};
  my $new_facename = $H->{'[deadkeyFaceInvAltGr]'}{$auto_chr};
  my ($LL, %Map) = $H->{'[deadkeyLayers]'}{$KK};
  $LL = $H->{layers} if $KK eq '';
  %Map = ($flip_AltGr, [$chain->{$KK and $self->charhex2key($KK)}, undef, 1, 'AltGrInv-faces-chain']) 
    if defined $flip_AltGr and defined $chain->{$KK and $self->charhex2key($KK)};  				    
	warn "  patch_face 0 f=$F k=$KK" if debug_stacking_ord;
  $self->patch_face($LL, $new_facename, $H->{"[InvdeadkeyLayers]"}{$KK}, $KK, \%Map, $F, 'invert');

# warn "Joining <$F>, <$new_facename>";
  $self->link_layers($F, $new_facename, 'skipfix', 'no-slot-warn');
  if ($KK eq '' and defined $flip_AltGr) {
    $H->{'[deadkeyFace]'}{$self->key2hex($flip_AltGr)} = $H->{'[deadkeyFaceInvAltGr]'}{$auto_chr};
  }
  if ($H->{"[InvdeadkeyLayers]"}{$KK}) {		# There are overrides for the inverted face.  Make a map for them...
#warn "Overriding face for inverted `$KK' in face $F; new_facename=$new_facename";
    $H->{'[InvAltGrFace]'}{$KK} = "$new_facename\@override";
    $self->{faces}{"$new_facename\@override"}{layers} = $H->{"[InvdeadkeyLayers]"}{$KK};
    $self->link_layers($F, "$new_facename\@override", 'skipfix', 'no-slot-warn');
  }
  $new_facename;
}

sub auto_dead_can_wrap ($$) {		# Call after all the manually set prefix key are already established, so one can avoid them
  my ($self, $F) = (shift, shift);
  $self->{faces}{$F}{'[ad_can_wrap]'}++
}

sub next_auto_dead ($$) {
  my ($self, $H, $o) = (shift, shift);
  unless ($H->{'[autodead_wrapped]'}) {
    1 while $H->{'[auto_dead]'}{ $o = $H->{'[first_auto_dead]'}++ }++ and ($o < 0x1000 or not $H->{'[ad_can_wrap]'});	# Bug in kbdutool
    $H->{'[first_auto_dead]'} = 0xa0 if $o >= 0x1000 and $H->{'[ad_can_wrap]'} and not $H->{'[autodead_wrapped]'}++;
  }
  if ($H->{'[autodead_wrapped]'}) {	# This does not deal with manual assignment of inverted prefixes???  Inv_AltGr???
    1 while $H->{'[auto_dead]'}{ $o = $H->{'[first_auto_dead]'}++ }++ or $H->{'[deadkeyFaceHexMap]'}{$self->key2hex(chr $o)};
#    if ($o == 0x00a3) {
#      warn "$o: Keys HexMap: ", join ', ', sort keys %{$H->{'[deadkeyFaceHexMap]'}};
#    }
  }
  chr $o;
}

sub recipe2str ($$) {
  (undef, my $recipe) = (shift, shift);
   if ('ARRAY' eq ref $recipe) {
     $recipe = [@$recipe];			# deep copy
     s/\s+$//, s/^\s+// for @$recipe;
     s/(?<![|,])$/ / for @$recipe[0..($#$recipe - 1)];	# Join by spaces unless after comma or |
     $recipe = join '', @$recipe;
   }
   $recipe =~ s/^\s+//;
   $recipe
}

sub scan_for_DeadKey_Maps ($) {			# Makes a direct-access synonym, scan for DeadKey_Maps* keys
  my ($self, %h, $expl) = (shift);
#Dumpvalue->new()->dumpValue($self);
  my @F = grep m(^faces(/.*)?$), @{$self->{'[keys]'}};
  for my $FF (@F) {
    (my $F = $FF) =~ s(^faces/?)();
    my(@FF, @HH) = split m(/), $FF;
    next if @FF == 1 or $FF[-1] eq 'VK';
    my @FF1 = @FF;
    push(@HH, $self->get_deep($self, @FF1)), pop @FF1 while @FF1;	# All the parents
    my $H = $HH[0];
    next if $H->{PartialFace};
    $self->{faces}{$F} = $H if $F =~ m(/) and exists $H->{layers};			# Make a direct-access copy
#warn "Face section `${FF}'s parents: ", scalar @HH;
#warn "Mismatch of hashes for `$FF'" unless $self->{faces}{$F} == $H;

    # warn "compositing: faces `$F'; -> <", (join '> <', %$H), ">";
    for my $HH (@HH) {
      for my $k ( keys %$HH ) {
# warn "\t`$k' -> `$HH->{$k}'";
        next unless $k =~ m(^DeadKey_(Inv|Add)?Map([0-9a-f]{4,})?(?:_(\d+))?$)i;
#warn "\t`$k' -> `$HH->{$k}'";
        my($inv, $key, $layers) = ($1 || '', $2, $3);
        $key = $self->key2hex($self->charhex2key($key)) if defined $key;			# get rid of uc/lc hex problem
        # XXXX The problem is that the parent may define layers in different ways (_0,_1 or no); ignore it for now...
        $H->{'[DeadKey__Maps]'}{$key || ''}{$inv}{(defined $layers) ? $layers : 'All'} ||= $HH->{$k};
      }
    }
  }
}

#use Dumpvalue;
sub ensure_DeadKey_Map_by_recipe ($$$$;$$) {
  my ($self, $F, $hexPrefix, $recipe, $layers, $inv) = (shift, shift, shift, shift, shift, shift || '');
  my $H = $self->{faces}{$F};
  return if $H->{"[${inv}deadkeyLayersCreated]"}{$hexPrefix}{$layers and "@$layers"}++;
#Dumpvalue->new()->dumpValue($self);
  my $massage = !($recipe =~ s/\s+NoDefaultTranslation$//);
  $layers ||= [ 0 .. $#{$self->{faces}{$F}{layers}} ];
#warn "Doing key `$hexPrefix' inv=`$inv' face=`$F', recipe=`$recipe'";
	warn "  mk_tr_lyrs 7 (F=$F, p=$hexPrefix)" if debug_stacking_ord;
  my $new = $self->make_translated_layers($recipe, $F, $layers, $hexPrefix);
  $new = $self->massage_translated_layers($new,    $F, $layers, $hexPrefix) if $massage and not $inv;
  for my $NN (0..$#$layers) {	# Create a layer according to the spec
#warn "DeadKey Layer for face=$F; layer=$layer, k=$k:\n\t$HH->{$k}, key=`", ($hexPrefix||''),"'\n\t\t";
#$DEBUG = $hexPrefix eq '0192';
#print "Doing key `$hexPrefix' face=$F  layer=`$layer' recipe=`$recipe'\n" if $DEBUG;
#Dumpvalue->new()->dumpValue($self->{layers}{$new}) if $DEBUG;
#warn "new=<<<", join('>>> <<<', @$new),'>>>';
    $H->{"[${inv}deadkeyLayers]"}{$hexPrefix}[$layers->[$NN]] = $new->[$NN];
#warn "Face `$F', layer=$layer key=$hexPrefix\t=> `$new'" if $H->{layers}[$layer] =~ /00a9/i;
#Dumpvalue->new()->dumpValue($self->{layers}{$new}) if $self->charhex2key($hexPrefix) eq chr 0x00a9;
  }
}

sub ensure_DeadKey_Map ($$$;$) {
  my ($self, $F, $hexPrefix, $hexPrefixWas, %h, $expl) = (shift, shift, shift, shift);
  $hexPrefixWas = $hexPrefix unless defined $hexPrefixWas;
  my $H = $self->{faces}{$F};
  my $v0 = $H->{'[DeadKey__Maps]'}{$hexPrefixWas};
  for my $inv (sort keys %$v0) {
    my $v1 = $v0->{$inv};
    my $K = (($inv and "$inv $hexPrefix" eq "Inv 0000") ? '' : $hexPrefix);
    for my $layers (sort keys %$v1) {
      my $recipe = $self->recipe2str($v1->{$layers});
      $layers = ($layers eq 'All' ? '' : [$layers]);
      $self->ensure_DeadKey_Map_by_recipe($F, $K, $recipe, $layers, $inv);
    }
  }
}

sub create_DeadKey_Maps ($) {
  my ($self, %h, $expl) = (shift);
#Dumpvalue->new()->dumpValue($self);
  for my $F ($self->order_faces_4_massage) {
    next if 'HASH' ne ref $self->{faces}{$F} or $F =~ /\bVK$/;			# "parent" taking keys for a child
    my $H = $self->{faces}{$F};
    my $flip_AltGr = $H->{'[Flip_AltGr_Key]'};
    $flip_AltGr = (defined $flip_AltGr) ? $self->charhex2key($flip_AltGr) : 'N/A';
    # Treat first the specific maps (for one deadkey) then the deadkeys which were not seen via the universal map
    for my $key (sort keys %{$H->{'[DeadKey__Maps]'}}) {
###      my $v0 = $H->{'[DeadKey__Maps]'}{$key};
      my @keys = (($key ne '')
      		   ? $key 
      		   : (grep {not $H->{'[DeadKey__Maps]'}{$_} and not $H->{'[ComposeKeys]'}{$_}} 
			map $self->key2hex($_), grep $_ ne $flip_AltGr, sort keys %{ $H->{'[DEAD]'} }));
      $self->ensure_DeadKey_Map($F, $_, $key) for @keys;
    }
  }
}

#use Dumpvalue;
sub create_composite_layers ($) {
  my ($self, %h, $expl) = (shift);
#Dumpvalue->new()->dumpValue($self);
  for my $F (keys %{ $self->{faces} }) {
    next if 'HASH' ne ref $self->{faces}{$F} or $F =~ /\bVK$/;			# "parent" taking keys for a child
    my $H = $self->{faces}{$F};
    next if $H->{PartialFace};
    next unless $H->{'[deadkeyLayers]'};		# Are we in a no-nonsense Face-hash with defined deadkeys?
#warn "Face: <", join( '> <', %$H), ">";
    my $layerL = @{ $self->{layers}{ $H->{layers}[0] } };	# number of keys in the face (in the principal layer)
    my $first_auto_dead = $H->{'[Auto_Diacritic_Start]'};
    $H->{'[first_auto_dead]'} = ord $self->charhex2key($first_auto_dead) if defined $first_auto_dead;
    for my $KK (sort keys %{$H->{'[deadkeyLayers]'}}) {		# Given a deadkey: join layers into a face, and link to it
      for my $layer ( 0 .. $#{ $H->{layers} } ) {
#warn "Checking for empty layers, Face `$face', layer=$layer key=$KK";
        $self->{layers}{"[empty$layerL]"} ||= [map[], 1..$layerL], $H->{'[deadkeyLayers]'}{$KK}[$layer] = "[empty$layerL]"
          unless defined $H->{'[deadkeyLayers]'}{$KK}[$layer]
      }
      # Join the syntetic layers (now well-formed) into a new synthetic face:
      my $new_facename = "$F###$KK";
      $self->{faces}{$new_facename}{layers} = $H->{'[deadkeyLayers]'}{$KK};
      $H->{'[deadkeyFace]'}{$KK} = $new_facename;
#warn "Joining <$F>, <$new_facename>";
#      $self->link_layers($F, $new_facename, 'skipfix', 'no-slot-warn');	# Now moved to link_composite_layers
    }
  }
  $self
}

sub create_prefix_chains ($) {
  my ($self, %h, $expl) = (shift);
  my @F = grep m(^faces(/.*)?$), @{$self->{'[keys]'}};
  for my $FF (@F) {
    (my $F = $FF) =~ s(^faces/?)();
    my(@FF, @HH) = split m(/), $FF;
    next if @FF == 1 or $FF[-1] eq 'VK';
    push(@HH, $self->get_deep($self, @FF)), pop @FF while @FF;
    my($H, %KK) = $HH[0];
    for my $chain ( @{ $H->{'[PrefixChains]'} || [] } ) {
      (my $c = $chain) =~ s/^\s+//;
      my @prefix = map { $_ and $self->charhex2key($_) } split /,/, $c, -1;		# trailing empty means all are prefixes
      length(my $trail_nonprefix = $prefix[-1]) or pop @prefix;
      my $start = shift @prefix;
      warn "PrefixChain for `$start' in font `$F' is empty" unless @prefix > 1;
      for my $Kn (1..$#prefix) {
        my($from, $to) = @prefix[$Kn-1, $Kn];
        $KK{$from}{$start} = [$to, undef, $Kn != $#prefix || !$trail_nonprefix, 'PrefixChains'];
      }
    }
    warn "... PrefixChains from(to1,to2) <$F>: ", join '|', map {$_ . '(' . join(',', sort keys %{$KK{$_}}) . ')'} sort keys %KK if keys %KK;
    for my $K (sort keys %KK) {
      my $KK = $self->key2hex($K);
      die "Key `$KK=$K' in PrefixChain for font=`$F' is not a prefix" unless my $KF = $H->{'[deadkeyFace]'}{$KK};
      my $new_facename = "$F*==>*Chain*$KK";
      my $LL = $H->{'[deadkeyLayers]'}{$KK};
	warn "  patch_face 1" if debug_stacking_ord;
      $self->patch_face($LL, $new_facename, undef, "chain-in-$KK", $KK{$K}, $F, !'invert');
      $H->{'[deadkeyFace]'}{$KK} = $new_facename;
      $H->{'[deadkeyLayers]'}{$KK} = $self->{faces}{$new_facename}{layers};
      $self->coverage_face0($new_facename, 'after import');
    }
  }
  $self
}

sub link_composite_layers ($) {		# as above, but finish 
  my ($self, %h, $expl) = (shift);
  my @F = grep m(^faces(/.*)?$), @{$self->{'[keys]'}};
  for my $FF (@F) {
    (my $F = $FF) =~ s(^faces/?)();
    my(@FF, @HH) = split m(/), $FF;
    next if @FF == 1 or $FF[-1] eq 'VK';
    push(@HH, $self->get_deep($self, @FF)), pop @FF while @FF;
    my $H = $HH[0];
    for my $new_facename (sort values %{$H->{'[deadkeyFace]'}}) {
#warn "Joining <$F>, <$new_facename>";
      $self->link_layers($F, $new_facename, 'skipfix', 'no-slot-warn');
    }
  }
  $self
}

sub create_inverted_faces ($) {
  my ($self) = (shift);
#Dumpvalue->new()->dumpValue($self);
  for my $F (sort keys %{$self->{faces} }) {
    next if 'HASH' ne ref $self->{faces}{$F} or $F =~ /\bVK$/;			# "parent" taking keys for a child
    my $H = $self->{faces}{$F};
    next unless $H->{'[deadkeyLayers]'};		# Are we in a no-nonsense Face-hash with defined deadkeys?
    my $expl = $H->{'[Explicit_AltGr_Invert]'} || [];
    $expl = [], warn "Odd number of elements of Explicit_AltGr_Invert in face $F, ignore" if @$expl % 2;
    $expl = {map $self->charhex2key($_), @$expl};

#warn "Face: <", join( '> <', %$H), ">";
    my $layerL = @{ $self->{layers}{ $H->{layers}[0] } };	# number of keys in the face (in the principal layer)
    for my $KK (sort keys %{$H->{'[deadkeyLayers]'}}) {  # Create AltGr-inverted face if there is at least one key in the AltGr face:
      my $LL = $H->{'[deadkeyLayers]'}{$KK};
      # To check that a key is defined, we do not care about whether a shift-state is encoded as a string, or as an array:
      next unless defined $H->{'[first_auto_dead]'} and grep defined, map $self->flatten_arrays($_), map $self->{layers}{$_}, @$LL[1..$#$LL];
      $H->{'[deadkeyInvAltGrKey]'}{''} = $self->next_auto_dead($H) unless exists $H->{'[deadkeyInvAltGrKey]'}{''};	# Prefix key for principal invertred face
      my $auto_chr = $H->{'[deadkeyInvAltGrKey]'}{$KK} = 
        ((exists $expl->{$self->charhex2key($KK)}) ? $expl->{$self->charhex2key($KK)} : $self->next_auto_dead($H));
      $H->{'[deadkeyFaceInvAltGr]'}{$auto_chr} = "$F##Inv#$KK";
      $self->{faces}{ $H->{'[deadkeyFace]'}{$KK} }{'[invAltGr_Accessor]'} = $auto_chr;
    }
    next unless defined (my $flip_AltGr =  $H->{'[Flip_AltGr_Key]'});
    $flip_AltGr = $self->charhex2key($flip_AltGr);
    $H->{'[deadkeyFaceInvAltGr]'}{ $H->{'[deadkeyInvAltGrKey]'}{''} } = "$F##Inv#" if exists $H->{'[deadkeyInvAltGrKey]'}{''};
    my ($prev, %chain) = '';
    for my $k ( @{ $H->{chainAltGr} || [] }) {
      my $K  = $self->charhex2key($k);
      my $KK = $self->key2hex($K);
      warn("Deadkey `  $K  ' of face $F has no associated AltGr-inverted face"), next
        unless exists $H->{'[deadkeyInvAltGrKey]'}{$KK};
      $chain{$prev} = $H->{'[deadkeyInvAltGrKey]'}{$KK};
#warn "chain `$prev' --> `$K' => $H->{'[deadkeyInvAltGrKey]'}{$KK}";
      # $H->{'[dead2_AltGr_chain]'}{(length $prev) ? $self->key2hex($prev) : ''}++;
      $prev = $K;
    }
    $H->{'[have_AltGr_chain]'} = 1 if length $prev;
    for my $KK (sort keys %{$H->{'[deadkeyInvAltGrKey]'}}) {	# Now know which deadkeys take inversion, and via what prefix
      my $new = $self->create_inverted_face($F, $KK, \%chain, $flip_AltGr);
      $self->coverage_face0($new);
    }
    # We do not link the AltGr-inverted faces to the "parent" faces here.  Currently, it should be done when
    # outputting a kbd description...
  }
  $self
}

sub massage_flat_maps_extra_keys ($) {
  my $self = shift;
  my @F = grep m(^faces(/.*)?$), @{$self->{'[keys]'}};
  my (@Fok, @Fok0, @Fnok);
  for my $FF (@F) {
    (my $F = $FF) =~ s(^faces/?)();
    my(@FF, @HH, @FokF) = split m(/), $FF;
    next if @FF == 1 or $FF[-1] eq 'VK';
    push @Fok, $F;				# Assumed base faces
    my($H) = $self->get_deep($self, @FF);
    my $Cov = $H->{'[coverageExtraInclPrefix]'};
##    warn join ',', sort keys %$Cov;
    for my $inv ('', 'Inv') {
     for my $dead (sort keys %{$H->{"[FlatPrefixMap$inv]"}}) {
      my($sk, @c) = ('');
      for my $cHex (sort keys %{$H->{"[FlatPrefixMap$inv]"}{$dead}}) {
        my $chr = $self->charhex2key($cHex);
        my $to = $H->{"[FlatPrefixMap$inv]"}{$dead}{$cHex};	# key (documented)
        my @to0 = @$to;
        $to0[0] = $self->key2hex($to->[0]);		# hex
        $sk .= ",$cHex⇒$to0[0]", next unless $Cov->{$chr};
        $H->{"[FlatPrefixMapFiltered$inv]"}{$dead}{$cHex} = \@to0;
        push @c, "$cHex⇒$to0[0]";
        $H->{"[FlatPrefixMapAccessibleHex]"}{$dead}{$to0[0]} = 1;
      }
      push @FokF, "$dead$inv⇝ " . join ',', @c if @c;
      push @Fnok, "$F→$dead$inv$sk" if length $sk;
     }
    }
    push @Fok0, "\t... Flatmap $F:\t@FokF\n" if @FokF;
  }
  warn join '', "\tBase Faces: @Fok\n", @Fok0 if @Fok0 or @Fnok;
  warn "\t... Flatmaps with no basekey: @Fnok\n" if @Fnok;
  $self
}

#use Dumpvalue;
sub patch_face ($$$$$$$;$) {	# flip layers paying attention to linked AltGr-inverted faces, and overrides
  my ($self, $LL, $newname, $prefix, $mapId, $Map, $face, $inv, @K) = (shift, shift, shift, shift, shift, shift, shift, shift);
  if (%$Map) {			# Borrow from make_translated_layer_tr()
    my $Tr = sub ($) { my $c = shift; defined $c or return $c; $c = $c->[0] if ref $c; my $o = $Map->{$c} ;
#warn "Tr: `$c' --> `$o'" if defined $o;
#$o
    };
    $Tr = $self->depth1_A_translator($Tr);
    my $LLL = $self->{faces}{$face}{layers};
    my $mod_name = ($inv ? 'AltGr' : '');
    for my $n (0..$#$LL) {					# Layer number
      my $new_Name = "$face##Chain$mod_name#$n.." . $mapId;
#warn "AltGr-chaining: name=$new_Name; `$chainKey' => `$nextL'";
      $self->{layers}{$new_Name} ||= [ map $Tr->($_), @{ $self->{layers}{ $LLL->[$n] } }];
      push @K, $new_Name;
    }
  }
  my @prefix = $prefix ? $prefix : ();
  my @n1 = (0..$#$LL);
  @n1 = map $self->flip_layer_N($_, $#$LL), @n1 if $inv;
  my @invLL = @$LL[@n1];
  push @prefix, \@K if @K;
  if (not $mapId and $inv) {	# remove unreachable stuff (as early as possible) to simplify inspection of coverage
    my @oNames = @invLL;  @invLL = ();
    for my $li (0..$#oNames) {
      my $oname = $oNames[$li];
      my $nname = "$face##InvStrict$li#" . $oname;
      $self->{layers}{$nname} = $self->deep_copy($self->{layers}{$oname});
      push @invLL, $nname;
    }
    my @LLL = map $self->{layers}{$_}, @invLL;
    for my $k (0..$#{$LLL[0]}) {
      if (defined $LLL[0][$k] and defined $LLL[1][$k]) {
        for my $shft (0, 1) {
          unless (defined $LLL[0][$k][$shft] and defined $LLL[1][$k][$shft]) {
            undef $LLL[$_][$k][$shft] for 0, 1;
          }
        }
      } else {
        $LLL[$_][$k] = [] for 0, 1;
      }
    }
  }
  my @p;
	(@p = map "<@$_>", @prefix), warn "  mk_tr_lyrs_st 2 (((@p)))\t[[[@invLL]]]" if debug_stacking_ord;
  $self->{faces}{$newname}{layers} = [$self->make_translated_layers_stack(@prefix, \@invLL)];
}

# use Dumpvalue;
my %subst_Shift = qw( -- -	-S S	t- t	tS T );		# There is no space for 8 MODs, so we contract tS into T
sub fmt_bitmap_mods ($$$;$) {
  my ($self, $b, $col, $short, @b) = (shift, shift, shift, shift, qw(Shift Ctrl Alt Kana Roya Loya Z t));
  my ($j, $empty, @ind) = ($short ? ('', '-', 1..$#b, 0) : ("\t", '', 0..$#b));	# better have Shift at end (Ctrl-Alt-Shift)...
  my $O = join $j, map {($b & (1<<$_)) ? ($short ? substr $b[$_], 0, 1 : $b[$_]) : $empty} @ind;
  $O =~ s/(..)$/$subst_Shift{$1}/ if $short;
  $O =~ s/\t+$//;
  $O = 'Invalid' if $col == 15;
  $O
}

sub Base_VK_names ($$) { # returns array of VK_-names: default names (based on BaseLayer), f-key names, or those from .../VK
  my($self, $K) = (shift, shift);					# name is undef if this is a “fake” position
  my $F = $self->get_deep($self, @$K);		# Presumably a face hash, as in $K = [qw(faces US)]
  return $F->{baseKeysWin} if $F->{baseKeysWin};
  my $cnt = $F->{'[non_VK]'};
  my $b = $F->{BaseLayer};
  my $layers = $F->{layers};
	warn "  mk_tr_lyrs 8" if debug_stacking_ord;
  $b = $self->make_translated_layers($b, $K->[-1], [0])->[0] if defined $b and not $self->{layers}{$b};
  my $basesub = [((defined $b) ? $b : ()), $F->{layers}[0]];
  my $max = -1;
  $max < $#{$self->{layers}{$_}} and $max = $#{$self->{layers}{$_}} for @$basesub;
  $max < $_->[0] + $_->[1] - 1 and $max = $_->[0] + $_->[1] - 1 for values %start_SEC;
  $max >= $LAST_SEC and $max = $LAST_SEC - 1;	# Avoid fake keys
#  warn "Basekeys: max=$max; cnt=$cnt";
  my(@o, @oo);
#
#  warn("base:   max=$max  cnt=$cnt");
  for my $u (0..$max) {
    my $c = $self->base_unit($basesub, $u, $u >= $cnt);	# [0 || 1 (!in_main_island), VK, raw]
    my($k, $kk) = ($c->[1], $c->[2]);			# uc(With appended #), orig (or undef if not array)
    if (!$c->[0]) {					# Main island of keyboard
      $k = $oem_keys{$k} or warn("Can't find a key with VKEY `[@$c]', unit=$u, lim=$cnt", (defined $k and " k=<<$k>>")), return
        unless $k =~ /^[A-Z0-9]$/;
    } else {
      my $U = [map $self->{layers}{$_}[$u], @$layers];
      my $keys = grep defined, map $self->flatten_arrays($_->[$u]), @$U;
      $keys and warn "Can't find the range of keys to which unit `$u' belongs (max=$max; cnt=$cnt)" unless defined $k;
      $kk = $k;
    }
    push @o, $k;
    push @oo, $kk;
  }
  my $o = $F->{'[VK_off]'};
  for my $b (\@o, \@oo) {	# Fill the VK names assigned in “layoutName”/VK section
    for my $vk (keys %$o) {
      warn "[@$K]: $vk defined on \@$o->{$vk} as $b->[$o->{$vk}]" if defined $b->[$o->{$vk}];
      $b->[$o->{$vk}] = $vk unless defined $b->[$o->{$vk}];
#      warn "[@$K]: $vk \@ $o->{$vk}";	# SPACE @ 116 (on izKeys)
    }
  }
#  warn "BaseKeys: @o";
  $F->{baseKeysRaw} = \@oo;
  $F->{baseKeysWin} = \@o;
}


sub fill_win_template ($$$;$$) {
  my @K = qw( COMPANYNAME LAYOUTNAME COPYR_YEARS LOCALE_NAME LOCALE_ID DLLNAME SORT_ORDER_ID_ LANGUAGE_NAME );
  my ($self, $t, $k, $dummy, $dummyDscr, %h) = (shift, shift, shift, shift, shift);
  $self->reset_units;
  my $B = $self->Base_VK_names($k);
# Dumpvalue->new()->dumpValue($self);
  my $idx = $self->get_deep($self, @$k, 'MetaData_Index');
  $h{$_} = $self->get_deep_via_parents($self, $idx, @$k, $_) for @K;
  $h{LAYOUTNAME} = "KBD Layout $h{DLLNAME}" if $dummyDscr;	# error "the required resource DATABASE is missing" from setup.exe
  my $LLL = length($h{LAYOUTNAME}) + grep ord >= 0x10000, split //, $h{LAYOUTNAME};
  warn "The DESCRIPTION of the layout [@$k] is longer than 63 chars;\n  the name shown in LanguageBar/Settings may be empty"
    if $LLL > 63;
  $h{LAYOUTNAME} =~ s/([\\""])/\\$1/g;		# C-like syntax (directly copied to resource files???)
# warn "Translate: ", %h;
  my $F = $self->get_deep($self, @$k);		# Presumably a face hash, as in $k = [qw(faces US)]
  $F->{'[dead-used]'} = [map {}, @{$F->{layers}}];		# Which of deadkeys are reachable on the keyboard
  my $cnt = $F->{'[non_VK]'};
  if (grep $F->{"[$_]"}, qw(LRM_RLM ALTGR SHIFTLOCK NOALTGR)) {
    $h{ATTRIBS} = (join "\n   ", "\nATTRIBUTES", grep $F->{"[$_]"}, qw(LRM_RLM ALTGR SHIFTLOCK NOALTGR)) . "\n" ;
  } else {
    $h{ATTRIBS} = '';				# default
  }
  if ($dummy) {
    @h{qw(DO_LIGA COL_HEADERS COL_EXPL KEYNAMES_DEAD DEADKEYS MODIFIERS)} = ('') x 6;
    @h{qw(LAYOUT_KEYS BITS_TEMPLATE)} = (<<EOT, <<EOT);
10	Q	0	q	-1	-1	// LATIN SMALL LETTER Q, <none>, <none>
EOT
0	// Column 4 :	
1	// Column 5 :	Shift
2	// Column 6 :		Ctrl
3	// Column 7 :	Shift	Ctrl
6	// Column 12 :		Ctrl	Alt					t
7	// Column 13 :	Shift	Ctrl	Alt					t
EOT
  } else {
    $h{LAYOUT_KEYS}  = join '', $self->output_layout_win($k->[-1], $F->{layers}, $F->{'[dead]'}, $F->{'[dead-used]'}, $cnt, $B);
#    $h{LAYOUT_KEYS} .= join '', $self->output_VK_win($k->[-1], $F->{'[dead-used]'});
    $h{LAYOUT_KEYS} .= join '', $self->output_added_units();

    $h{DO_LIGA} = join '', $self->output_ligatures();
    $h{DO_LIGA} = <<EOPREF . "$h{DO_LIGA}\n" if $h{DO_LIGA};

LIGATURE

// VK_		ModCol#	Char0	Char1	Char2	Char3
// ---------	-------	-----	-----	-----	-----


EOPREF

    ### Deadkeys???   need_extra_keys_to_access???
    my ($OUT, $OUT_NAMES) = ('', "KEYNAME_DEAD\n\n");
  
    my $f = $self->get_AgeList;
    $self->load_uniage($f) if defined $f and not $self->{Age};

    my($flip_AltGr_hex, %nn) =  $F->{'[Flip_AltGr_Key]'};
    $flip_AltGr_hex = $self->key2hex($self->charhex2key($flip_AltGr_hex)) if defined $flip_AltGr_hex;
    for my $deadKey ( sort keys %{ $F->{'[deadkeyFaceHexMap]'} } ) {
      next if $F->{'[only_extra]'}{$self->charhex2key($deadKey)};
      my $auto_inv_AltGr = $F->{'[deadkeyInvAltGrKey]'}{$deadKey};
      $auto_inv_AltGr = $self->key2hex($auto_inv_AltGr) if defined $auto_inv_AltGr;
  #warn "flipkey=$flip_AltGr_hex, dead=$deadKey" if defined $flip_AltGr_hex;
      (my $nonempty, my $MAP) = $self->output_deadkeys($k->[-1], $deadKey, $F->{'[dead2]'}, $flip_AltGr_hex, $auto_inv_AltGr);
      $OUT .= "$MAP\n";
      my @K = ($deadKey, ($auto_inv_AltGr ? $auto_inv_AltGr : ()));
      my @N = map $self->{DEADKEYS}{$_} || $self->{'[seen_knames]'}{chr hex $_} || $F->{'[prefixDocs]'}{$_} || $self->UName($_), @K;
      s/(?=[""\\])/\\/g for @N;
  #    if (defined $N and length $N) {
      $nn{$K[$_]} = $N[$_] for 0..$#K;
  #    }# else {      warn "DeadKey `$deadKey' for face `@$k' has no name associated"    }
    }
    # Apparently, if the DLL is too large (e.g., name table is too long), the keyboard is not activatable (installs OK on Win7_64, 
    # is in Settings' list, but is not in the panel's list).  Omit the multiple-Compose entries as a workaround...
    my $emitREX = $F->{'[WindowsEmitDeadkeyDescrREX]'};
#    warn "!!! emitREX=<<<$emitREX>>>\n" if $emitREX;
    defined $emitREX or $emitREX = '';		# Default: always emit
    $emitREX = qr($emitREX);
    $nn{$_} =~ $emitREX and $OUT_NAMES .= qq($_\t"$nn{$_}"\n) for sort keys %nn;
  #warn "Translate: ", %h;
    $h{DEADKEYS} = $OUT;
    $h{KEYNAMES_DEAD} = $OUT_NAMES;
    my %modsF = qw( SHIFT 1 CTRL 2 ALT 4 KANA 8 X 16 Y 32 Z 64 T 128 U 256 V 512 W 1024 ROYA 16 LOYA 32 GRPSELTAP 128 );
    my %mods =   map {(substr($_,0, 1), $modsF{$_})} keys %modsF;
    my(%mfFULL, $mks) = map {(substr($_,0, 1), length > 1 ? $_ : "_$_")}  keys %modsF;
    if (@{ $mks = $F->{'[mods_keys_KBD]'} }) {
      my($cmmnt, %mks) = ('', @$mks);
      if ($mks{lC} and $mks{rA} and not $F->{"[NOALTGR]"}) {	# Strip common-with-lC bits from rA
        my %seen = map {($_, 1)} split //, $mks{lC};
        my $out = join '', grep !$seen{$_}, split //, $mks{rA};
        $cmmnt = "\t// With KLLF_ALTGR, this is combined with LCONTROL and CONTROL; stripped $mks{rA} -> $out" if $out ne $mks{rA};
        $mks{rA} = $out;
      }
      $h{MODIFIERS} = "MODIFIERS\n";
      my %vk = (qw(S SHIFT C CONTROL A MENU), @{$F->{'[modkeys_vk]'} || []});
      (my $vkRX = join '', keys %vk) =~ /\W/ and die 'Non-letter in @modkeys_vk = (' . join(" ", sort keys %vk) . ')'; # XXX Needed???
      for my $K (sort keys %mks) {	# ??? Need to take into account @modkeys_vk  XXX
        my($preK, $KK, $c) = ($K =~ /^([lr]?)([$vkRX])$/) or die "Unexpected key <<<$K>>> of mods_keys_KBD";	# [ACKLR-Z]
        $c = $cmmnt if $K eq 'rA';
        $c ||= '';
        $h{MODIFIERS} .= "    \U$preK\E$vk{$KK}\tKBD" . join(' | KBD', map "$mfFULL{$_}", split //, $mks{$K}) . ($c || '') . "\n";
      }
      $h{MODIFIERS} .= "\n" ;
    }
    $_ += 0 for values %mods;			# Convert to numbers, so | works as expected
    my @cols;
    my %tr_mods_keys = ( @{ $F->{'[mods_keys_KBD]'} || (@{$F->{layers}} > 1 ? [qw(rA CA)] : [] ) } );
    my $mods_keys = $F->{'[layers_mods_keys]'} || (@{$F->{layers}} > 1 ? ['', 'rA'] : ['']);
    my $mods = $F->{'[layers_modifiers]'} || []; # || ['', 'CA'];	# Plain, and Control-Alt (Obsolete variant)
    my @hCols = map {my $in = $_; $in =~ s/rC/Ⓒ/; $in =~ s/rA/Ⓐ/; $in =~ s/l(?=CA)//g;  $in } @$mods_keys; # human-readable ⒸⒶ ⇒ right
    $#$mods = $#$mods_keys if $#$mods < $#$mods_keys;
    for my $MOD ( @$mods ) {
      my $mask = 0;
      my $mod = ((defined $MOD) ? $MOD : '');				# Copy
      unless ($mod =~ /\S/) {
        my @K = grep /./, split /(?<=[A-Z])(?=[rl]?[A-Z])/, $mods_keys->[scalar @cols];
  #warn "cols=(@cols), K=(@K)\n";
        $mod = join '', map $tr_mods_keys{$_}, @K;
      }
      $mask |= $mods{$_} for split //, $mod;
      push @cols, $mask;
    }
    @cols  = map {($_, $_ | $mods{S})} @cols;	# Add shift
    @hCols = map {($_, "${_}S")}       @hCols;	# Add shift

    my($ctrl_f,$ctrl_F) = ($mods{C}, $tr_mods_keys{lC} || $tr_mods_keys{C} || $tr_mods_keys{rC} || 'C');	# Prefer left-Ctrl
    # $ctrl_f |= $mods{$_} for split //, $ctrl_F;		# kbdutool complains if there is no column for 'C'

    my $pre_ctrl = $self->get_deep($self, @$k, '[ctrl_after_modcol]');
    $pre_ctrl = 2*$ctrl_after unless defined $pre_ctrl;
    my $create_a_c = $self->get_deep($self, @$k, '[create_alpha_ctrl]');
    $create_a_c = $create_alpha_ctrl unless defined $create_a_c;
    splice @cols,  $pre_ctrl, 0, $ctrl_f, ($create_a_c>1 ? $ctrl_f|$mods{S} : ());	# Control (and maybe Control-Shift)
    splice @hCols, $pre_ctrl, 0, "C",     ($create_a_c>1 ? "CS" : ());			# Control (and maybe Control-Shift)
    splice @cols,  15, 0, $mods{A}  if @cols >= 16;	# col=15 is the fake one; assigning it to Alt is the best palliative to fixing MSKLC
    splice @hCols, 15, 0, 'Invalid' if @cols >= 16;		# due to KBDALT stripping, the column for Alt is not reachable anyway
    $h{COL_HEADERS} = join "\t", map sprintf('%-3d[%d]', $cols[$_], $_), 0..$#cols;
    $h{COL_EXPL}  = join "\t", map $self->fmt_bitmap_mods($cols[$_], $_, 'short'), 0..$#cols;
    $h{COL_HUMAN} = join "\t", map $hCols[$_],                                     0..$#cols;
    $h{BITS_TEMPLATE} = join "\n", map { "$cols[$_]\t// Column " . (4+$_) . " :\t" . $self->fmt_bitmap_mods($cols[$_], $_) } 0..$#cols;
  #  $h{BITS_TEMPLATE} =~ s(^(?=.*\bInvalid$))(#)m;					# XXX Actually, MSKLC is not ignoring the leading #
    $h{UIKL_VERSION} = $VERSION;
  }
  $self->massage_template($template_win, \%h);
}

sub AppleMap_i_j ($$$$$;$$$$);
sub AppleMap_prefix ($$;$$$$$$);

# https://developer.apple.com/library/mac/technotes/tn2056/_index.html
sub fill_osx_template ($$) {
  my @K = qw( OSX_LAYOUTNAME LAYOUTNAME OSX_ID OSX_ADD_VERSION OSX_DUP_KEYS COPYR_YEARS COMPANYNAME );
  my ($self, $k, %h, %ids) = (shift, shift);
  $self->reset_units;
  my $B = $self->Base_VK_names($k);
# Dumpvalue->new()->dumpValue($self);
  my $idx = $self->get_deep($self, @$k, 'MetaData_Index');
  $h{$_} = $self->get_deep_via_parents($self, $idx, @$k, $_) for @K;

  $h{OSX_LAYOUTNAME} ||= $h{LAYOUTNAME};
  delete $h{LAYOUTNAME};
  $h{OSX_ID} = -17 unless defined $h{OSX_ID};		# (Arbitrary) Negative number
  my $v = $self->{VERSION};
  if (defined $v and defined $h{OSX_ADD_VERSION}) {
    if ($h{OSX_ADD_VERSION} > 0) {
      my $c = $h{OSX_ADD_VERSION} - 1;
      $h{OSX_LAYOUTNAME} =~ s/^(\s*(\S+($|\s+)){$c}\S+)(?!\S)/$1 v$v/;
    } elsif ($h{OSX_ADD_VERSION} < -1) {
      my $c = -$h{OSX_ADD_VERSION} - 2;
      $h{OSX_LAYOUTNAME} =~ s/((?<!\S)\S+((^|\s+)\S+){$c}\s*)\z/v$v $1/;
    } elsif ($h{OSX_ADD_VERSION} == -1) {
      $h{OSX_LAYOUTNAME} =~ s/\z/ v$v/;
    } else {
      $h{OSX_LAYOUTNAME} =~ s/^/v$v /;
    }
  }
  delete $h{OSX_ADD_VERSION};
  my $dupk = delete $h{OSX_DUP_KEYS};
  $dupk = {@$dupk} if $dupk;

  # OSX_CREATOR version OSX_CREATOR_VERSION on OSX_EDIT_DATE
  my $file = $self->{'[file]'};
  my $app = (defined $file and @$file > 1 and 's');
  $file = (defined $file) ? "keyboard layout file$app @$file" : 'string descriptor';
  $file .= " version $v" if defined $v;
  $file .= " Unicode tables version $self->{uniVersion}" if defined $self->{uniVersion};
  $h{OSX_CREATOR} = "UI::KeyboardLayout";
  $h{OSX_CREATOR_VERSION} = "$UI::KeyboardLayout::VERSION with $file";
  my @t = (gmtime)[5,4,3,2,1,0];
  $t[0] += 1900;  $t[1]++;
  $h{OSX_EDIT_DATE} = sprintf '%d-%02d-%02d at %d:%02d:%02d GMT', @t;

  my $F = $self->get_deep($self, @$k);
  my($flip_AltGr_hex, %nn) =  $F->{'[Flip_AltGr_Key]'};
  $flip_AltGr_hex = $self->key2hex($self->charhex2key($flip_AltGr_hex)) if defined $flip_AltGr_hex;
  my %map;			# Indexed by hex	(??? What about UTF-16???)
  for my $deadKey ( sort keys %{ $F->{'[deadkeyFaceHexMap]'} } ) {
    next if $F->{'[only_extra]'}{$self->charhex2key($deadKey)};
    my $auto_inv_AltGr = $F->{'[deadkeyInvAltGrKey]'}{$deadKey};
    $auto_inv_AltGr = $self->key2hex($auto_inv_AltGr) if defined $auto_inv_AltGr;
#warn "flipkey=$flip_AltGr_hex, dead=$deadKey" if defined $flip_AltGr_hex;
    $self->output_deadkeys($k->[-1], $deadKey, $F->{'[dead2]'}, $flip_AltGr_hex, $auto_inv_AltGr, \%map);
  }
  
  my %how = qw(	OSX_KEYMAP_0_AND_COMMAND	0;0;0
		OSX_KEYMAP_SHIFT		0;1;0
		OSX_KEYMAP_CAPS			0;0;1
		OSX_KEYMAP_OPTION		1;0;0
		OSX_KEYMAP_OPTION_SHIFT		1;1;0
		OSX_KEYMAP_OPTION_CAPS		1;0;1
		OSX_KEYMAP_OPTION_COMMAND	1;0;0
		OSX_KEYMAP_CTRL			0;0;0;-1
		OSX_KEYMAP_COMMAND		0;0;0;1
    );			# In US Extended, OPT-CMD is the same as OPT
#		OSX_KEYMAP_COMMAND_AS_BASE	0;0;0;0
  my($OVERR, $ov) = $F->{'[Apple_Override]'} || [];
  for my $o (@$OVERR) {
    my($K, $dead, $out) = split /,/, $o, 3;
    if ($out =~ /^hex[46]\z/) {
      $out = ['lit', $out]
    } else {
      $out = [0, $self->stringHEX2string($out)]
    }
    $ov->{$K} = [$out->[1], undef, $dead, $out->[0]];
  }
  my $DUP = $F->{'[Apple_Duplicate]'} || [0x6e, 10, 0x47, 10, 0x66, 49, 0x68, 49];	# Mnu => ISO, KP_Clear => ISO, L/R-SPace => Space
  $ov->{dup} = {@$DUP};
  $ov->{extra_actions} = {};
  for my $m (keys %how) {
    my($l, $shift, $capsl, $use_base) = split /;/, $how{$m};
    $h{$m} = $self->AppleMap_i_j ($k, $l, $shift, $capsl, $use_base, \%ids, \%map, $ov);
  }
#  warn "Need separate OSX_KEYMAP_COMMAND for k=$k\n" unless $h{OSX_KEYMAP_COMMAND} eq $h{OSX_KEYMAP_0_AND_COMMAND};
  # my $vbell = $self->get_deep_via_parents($self, undef, @$k, '[DeadChar_DefaultTranslation]');
  # $vbell =~ s/^\s+(?=.)//, $vbell = $self->charhex2key($vbell) if defined $vbell;
  # undef $vbell;			# Terminators are used as visual feedback when prefix is pressed!
  my($S, %act) = $F->{'[Show]'};
  @h{qw(OSX_ACTIONS_BASE OSX_ACTIONS OSX_TERMINATORS_BASE OSX_TERMINATORS2)}
    = map +($self->AppleMap_prefix(\%ids,  'do_initiating', $_, \%map, $S, $ov, \%act),
	    $self->AppleMap_prefix(\%ids, !'do_initiating', $_, \%map, $S, $ov, \%act)), '', 'term';

  $self->massage_template($template_osx, \%h);
}

my $unused = <<'EOR';
	# extract compositions, add <upgrade> to char downgrades; -> composition, => compatibility composition
perl -wlne "$k=$1, next if /^([\da-f]+)/i; undef $a; $a = qq($k -> $1) if /^\s+:\s*([0-9A-F]+(?:\s+[0-9A-F]+)*)/; $a = qq($k => $2 $1) if /^\s+#\s*((?:<.*?>\s+)?)([0-9A-F]+(?:\s+[0-9A-F]+)*)/; next unless $a; $a =~ s/\s*$/ <upgrade>/ unless $a =~ />\s+\S.*\s\S/; print $a" NamesList.txt >compose2b-NamesList.txt
	# expand recursively
perl -wlne "/^(.+?)\s+([-=])>\s+(.+?)\s*$/ or die; $t{$1} = $3; $h{$1}=$2; sub t($); sub t($) {my $i=shift; return $n{$i} if exists $n{$i}; return $i unless $t{$i}; $t{$i} =~ /^(\S+)(.*)/ or die $i; return t($1).$2} END{print qq($_\t:$h{$_} ), join q( ), sort split /\s+/, t($_) for sort {hex $a <=> hex $b} keys %t}" compose2b-NamesList.txt >compose3c-NamesList.txt

#### perl -wlne "($k,$r)=/^(\S+)\s+:[-=]\s+(.*?)\s*$/ or die; $k{$r} = $k; $r{$k}=$r; END { for my $k (sort {hex $a <=> hex $b} keys %r) { my @r = split /\s+/, $r{$k}; for my $o (1..$#r) {my @rr = @r; splice @rr, $o, 1; my ($rr,$kk) = join q( ), @rr; print qq($k\t<= $kk ), $r[$o] if $kk = $k{$rr}} } }" compose3c-NamesList.txt >compose4-NamesList.txt
perl -wlne "($k,$h,$r)=/^(\S+)\s+:([-=])\s+(.*?)\s*$/ or die; $k{$r} = $k; $r{$k}=$r; $hk{$k}=$hr{$r}= ($h eq q(=)); END { for my $k (sort {hex $a <=> hex $b} keys %r) { my $h = $hk{$k}; my @r = split /\s+/, $r{$k}; print qq($k\t:$h $r{$k}) and next if @r == 2; for my $o (1..$#r) {my @rr = @r; splice @rr, $o, 1; my ($rr,$kk) = join q( ), @rr; print qq($k\t<= $kk ), $r[$o] if $kk = $k{$rr}} } }" compose3c-NamesList.txt >compose4-NamesList.txt


	# Recursively decompose;  :- composition, := compatibility composition
perl -wlne "/^(.+?)\s+([-=])>\s+(.+?)\s*$/ or die; $t{$1} = $3; $h{$1}=$2 if $2 eq q(=); sub t($); sub t($) {my $i=shift; return $n{$i} if exists $n{$i}; return $i unless $t{$i}; $t{$i} =~ /^(\S+)(.*)/ or die $i; my @rr = t($1); return $rr[0].$2, $h{$i} || $rr[1]} END{my(@rr, $h); @rr=t($_), $h = $rr[1] || q(-), (@i = split /\s+/, $rr[0]), print qq($_\t:$h ), join q( ), $i[0], sort @i[1..$#i] for sort {hex $a <=> hex $b} keys %t}" compose2b-NamesList.txt >compose3e-NamesList.txt
	# Recompose parts to get "merge 2" decompositions; <- and <= if involve composition, :- and := otherwise
perl -wlne "($k,$h,$r)=/^(\S+)\s+:([-=])\s+(.*?)\s*$/ or die; $k{$r} = $k; $r{$k}=$r; $hk{$k}=$hr{$r}= ($h eq q(=) ? q(=) : undef); END { for my $k (sort {hex $a <=> hex $b} keys %r) { my $h = $hk{$k} || q(-); my @r = split /\s+/, $r{$k}; print qq($k\t:$h $r{$k}) and next if @r == 2; my %s; for my $o (1..$#r) {my @rr = @r; next if $s{$rr[$o]}++; splice @rr, $o, 1; my ($rr,$kk) = join q( ), @rr; print qq($k\t<), $hk{$k} || $hr{$kk} || q(-), qq( $kk ), $r[$o] if $kk = $k{$rr}} } }" compose3e-NamesList.txt >compose4b-NamesList.txt
	# List of possible modifiers for each char, introduced by -->, separated by //
perl -C31 -wlne "sub f($) {my $i=shift; return $i unless $i=~/^\w/; qq($i ).chr hex $i} sub ff($) {join q( ), map f($_), split /\s+/, shift} my($c,$B,$m) = /^(\S+)\s+[:<][-=]\s+(\S+)\s+(\S+)\s*$/ or die; push @{$c{$B}}, ff qq($m $c); END { for my $k (sort {hex $a <=> hex $b} keys %c) { print f($k), qq(\t--> ), join q( // ), sort @{$c{$k}} } }" compose4b-NamesList.txt >compose5d-NamesList.txt
	# Find what appears as modifiers:
perl -F"\s+//\s+|\s+-->\s+" -wlane "s/\s+[0-9A-F]{4,}(\s\S+)?\s*$//, print for @F[1..$#F]" ! | sort -u >!-words

Duplicate: 0296 <== [ 003F <pseudo-calculated-inverted> <pseudo-phonetized> ] ==> <1 0295> (prefered)
	<ʖ>	LATIN LETTER INVERTED GLOTTAL STOP
	<ʕ>	LATIN LETTER PHARYNGEAL VOICED FRICATIVE at UI-KeyboardLayout/lib/UI/KeyboardLayout.pm line 4224, <$f> line 38879.
Duplicate: 0384 <== [ 0020 0301 ] ==> <1 00B4> (prefered)
	<΄>	GREEK TONOS
	<´>	ACUTE ACCENT at UI-KeyboardLayout/lib/UI/KeyboardLayout.pm line 4224, <$f> line 38879.
Duplicate: 1D43 <== [ 0061 <super> ] ==> <1 00AA> (prefered)
	<ᵃ>	MODIFIER LETTER SMALL A
	<ª>	FEMININE ORDINAL INDICATOR at UI-KeyboardLayout/lib/UI/KeyboardLayout.pm line 4224, <$f> line 38879.
Duplicate: 1D52 <== [ 006F <super> ] ==> <1 00BA> (prefered)
	<ᵒ>	MODIFIER LETTER SMALL O
	<º>	MASCULINE ORDINAL INDICATOR at UI-KeyboardLayout/lib/UI/KeyboardLayout.pm line 4224, <$f> line 38879.
Duplicate: 1D9F <== [ 0065 <pseudo-calculated-open> <pseudo-calculated-reversed> <super> ] ==> <1 1D4C> (prefered)
	<ᶟ>	MODIFIER LETTER SMALL REVERSED OPEN E
	<ᵌ>	MODIFIER LETTER SMALL TURNED OPEN E at UI-KeyboardLayout/lib/UI/KeyboardLayout.pm line 4224, <$f> line 38879.
Duplicate: 1E7A <== [ 0055 0304 0308 ] ==> <0 01D5> (prefered)
	<Ṻ>	LATIN CAPITAL LETTER U WITH MACRON AND DIAERESIS
	<Ǖ>	LATIN CAPITAL LETTER U WITH DIAERESIS AND MACRON at UI-KeyboardLayout/lib/UI/KeyboardLayout.pm line 4224, <$f> line 38879.
Duplicate: 1E7B <== [ 0075 0304 0308 ] ==> <0 01D6> (prefered)
	<ṻ>	LATIN SMALL LETTER U WITH MACRON AND DIAERESIS
	<ǖ>	LATIN SMALL LETTER U WITH DIAERESIS AND MACRON at UI-KeyboardLayout/lib/UI/KeyboardLayout.pm line 4224, <$f> line 38879.
Duplicate: 1FBF <== [ 0020 0313 ] ==> <1 1FBD> (prefered)
	<᾿>	GREEK PSILI
	<᾽>	GREEK KORONIS at UI-KeyboardLayout/lib/UI/KeyboardLayout.pm line 4224, <$f> line 38879.
Duplicate: 2007 <== [ 0020 <noBreak> ] ==> <1 00A0> (prefered)
	< >	FIGURE SPACE
	< >	NO-BREAK SPACE at UI-KeyboardLayout/lib/UI/KeyboardLayout.pm line 4224, <$f> line 38879.
Duplicate: 202F <== [ 0020 <noBreak> ] ==> <1 00A0> (prefered)
	< >	NARROW NO-BREAK SPACE
	< >	NO-BREAK SPACE at UI-KeyboardLayout/lib/UI/KeyboardLayout.pm line 4224, <$f> line 38879.
Duplicate: 2113 <== [ 006C <font=script> ] ==> <1 1D4C1> (prefered)
	<ℓ>	SCRIPT SMALL L
	<퓁>	MATHEMATICAL SCRIPT SMALL L at UI-KeyboardLayout/lib/UI/KeyboardLayout.pm line 4224, <$f> line 38879.
Duplicate: 24B8 <== [ 0043 <circle> ] ==> <1 1F12B> (prefered)
	<Ⓒ>	CIRCLED LATIN CAPITAL LETTER C
	<>	CIRCLED ITALIC LATIN CAPITAL LETTER C at UI-KeyboardLayout/lib/UI/KeyboardLayout.pm line 4224, <$f> line 38879.
Duplicate: 24C7 <== [ 0052 <circle> ] ==> <1 1F12C> (prefered)
	<Ⓡ>	CIRCLED LATIN CAPITAL LETTER R
	<>	CIRCLED ITALIC LATIN CAPITAL LETTER R at UI-KeyboardLayout/lib/UI/KeyboardLayout.pm line 4224, <$f> line 38879.
Duplicate: 2E1E <== [ 007E <pseudo-dot-above> ] ==> <1 2A6A> (prefered)
	<⸞>	TILDE WITH DOT ABOVE
	<⩪>	TILDE OPERATOR WITH DOT ABOVE at UI-KeyboardLayout/lib/UI/KeyboardLayout.pm line 4224, <$f> line 38879.
Duplicate: 33B9 <== [ 004D <square> 0056 ] ==> <1 1F14B> (prefered)
	<㎹>	SQUARE MV MEGA
	<>	SQUARED MV at UI-KeyboardLayout/lib/UI/KeyboardLayout.pm line 4224, <$f> line 38879.
Duplicate: FC03 <== [ 064A <isolated> 0649 0654 ] ==> <1 FBF9> (prefered)
	<ﰃ>	ARABIC LIGATURE YEH WITH HAMZA ABOVE WITH ALEF MAKSURA ISOLATED FORM
	<ﯹ>	ARABIC LIGATURE UIGHUR KIRGHIZ YEH WITH HAMZA ABOVE WITH ALEF MAKSURA ISOLATED FORM at UI-KeyboardLayout/lib/UI/KeyboardLayout.pm line 4224, <$f> line 38879.
Duplicate: FC68 <== [ 064A <final> 0649 0654 ] ==> <1 FBFA> (prefered)
	<ﱨ>	ARABIC LIGATURE YEH WITH HAMZA ABOVE WITH ALEF MAKSURA FINAL FORM
	<ﯺ>	ARABIC LIGATURE UIGHUR KIRGHIZ YEH WITH HAMZA ABOVE WITH ALEF MAKSURA FINAL FORM at UI-KeyboardLayout/lib/UI/KeyboardLayout.pm line 4224, <$f> line 38879.
Duplicate: FD55 <== [ 062A <initial> 062C 0645 ] ==> <1 FD50> (prefered)
	<ﵕ>	ARABIC LIGATURE TEH WITH MEEM WITH JEEM INITIAL FORM
	<ﵐ>	ARABIC LIGATURE TEH WITH JEEM WITH MEEM INITIAL FORM at UI-KeyboardLayout/lib/UI/KeyboardLayout.pm line 4224, <$f> line 38879.
Duplicate: FD56 <== [ 062A <initial> 062D 0645 ] ==> <1 FD53> (prefered)
	<ﵖ>	ARABIC LIGATURE TEH WITH MEEM WITH HAH INITIAL FORM
	<ﵓ>	ARABIC LIGATURE TEH WITH HAH WITH MEEM INITIAL FORM at UI-KeyboardLayout/lib/UI/KeyboardLayout.pm line 4224, <$f> line 38879.
Duplicate: FD57 <== [ 062A <initial> 062E 0645 ] ==> <1 FD54> (prefered)
	<ﵗ>	ARABIC LIGATURE TEH WITH MEEM WITH KHAH INITIAL FORM
	<ﵔ>	ARABIC LIGATURE TEH WITH KHAH WITH MEEM INITIAL FORM at UI-KeyboardLayout/lib/UI/KeyboardLayout.pm line 4224, <$f> line 38879.
Duplicate: FD5D <== [ 0633 <initial> 062C 062D ] ==> <1 FD5C> (prefered)
	<ﵝ>	ARABIC LIGATURE SEEN WITH JEEM WITH HAH INITIAL FORM
	<ﵜ>	ARABIC LIGATURE SEEN WITH HAH WITH JEEM INITIAL FORM at UI-KeyboardLayout/lib/UI/KeyboardLayout.pm line 4224, <$f> line 38879.
Duplicate: FD87 <== [ 0644 <final> 062D 0645 ] ==> <1 FD80> (prefered)
	<ﶇ>	ARABIC LIGATURE LAM WITH MEEM WITH HAH FINAL FORM
	<ﶀ>	ARABIC LIGATURE LAM WITH HAH WITH MEEM FINAL FORM at UI-KeyboardLayout/lib/UI/KeyboardLayout.pm line 4224, <$f> line 38879.
Duplicate: FD8C <== [ 0645 <initial> 062C 062D ] ==> <1 FD89> (prefered)
	<ﶌ>	ARABIC LIGATURE MEEM WITH JEEM WITH HAH INITIAL FORM
	<ﶉ>	ARABIC LIGATURE MEEM WITH HAH WITH JEEM INITIAL FORM at UI-KeyboardLayout/lib/UI/KeyboardLayout.pm line 4224, <$f> line 38879.
Duplicate: FD92 <== [ 0645 <initial> 062C 062E ] ==> <1 FD8E> (prefered)
	<ﶒ>	ARABIC LIGATURE MEEM WITH JEEM WITH KHAH INITIAL FORM
	<ﶎ>	ARABIC LIGATURE MEEM WITH KHAH WITH JEEM INITIAL FORM at UI-KeyboardLayout/lib/UI/KeyboardLayout.pm line 4224, <$f> line 38879.
Duplicate: FDB5 <== [ 0644 <initial> 062D 0645 ] ==> <1 FD88> (prefered)
	<ﶵ>	ARABIC LIGATURE LAM WITH HAH WITH MEEM INITIAL FORM
	<ﶈ>	ARABIC LIGATURE LAM WITH MEEM WITH HAH INITIAL FORM at UI-KeyboardLayout/lib/UI/KeyboardLayout.pm line 4224, <$f> line 38879.
Duplicate: FE34 <== [ 005F <vertical> ] ==> <1 FE33> (prefered)
	<︴>	PRESENTATION FORM FOR VERTICAL WAVY LOW LINE
	<︳>	PRESENTATION FORM FOR VERTICAL LOW LINE at UI-KeyboardLayout/lib/UI/KeyboardLayout.pm line 4224, <$f> line 38879.

Duplicate: 0273 <== [ 006E <pseudo-manual-phonetized> ] ==> <1 014B> (prefered)
	<ɳ>	LATIN SMALL LETTER N WITH RETROFLEX HOOK
	<ŋ>	LATIN SMALL LETTER ENG at UI-KeyboardLayout/lib/UI/KeyboardLayout.pm line 5263, <$f> line 38876.
Duplicate: 1DAF <== [ 006E <pseudo-manual-phonetized> <super> ] ==> <1 1D51> (prefered)
	<ᶯ>	MODIFIER LETTER SMALL N WITH RETROFLEX HOOK
	<ᵑ>	MODIFIER LETTER SMALL ENG at UI-KeyboardLayout/lib/UI/KeyboardLayout.pm line 5263, <$f> line 38876.
Duplicate: 2040 <== [ 007E <pseudo-manual-quasisynon> ] ==> <1 203F> (prefered)
	<⁀>	CHARACTER TIE
	<‿>	UNDERTIE at UI-KeyboardLayout/lib/UI/KeyboardLayout.pm line 5263, <$f> line 38876.
Duplicate: 207F <== [ 004E <pseudo-manual-phonetized> ] ==> <1 014A> (prefered)
	<ⁿ>	SUPERSCRIPT LATIN SMALL LETTER N
	<Ŋ>	LATIN CAPITAL LETTER ENG at UI-KeyboardLayout/lib/UI/KeyboardLayout.pm line 5263, <$f> line 38876.
Duplicate: 224B <== [ 007E <pseudo-manual-addtilde> ] ==> <1 2248> (prefered)
	<≋>	TRIPLE TILDE
	<≈>	ALMOST EQUAL TO at UI-KeyboardLayout/lib/UI/KeyboardLayout.pm line 5263, <$f> line 38876.
Duplicate: 2256 <== [ 003D <pseudo-manual-round> ] ==> <1 224D> (prefered)
	<≖>	RING IN EQUAL TO
	<≍>	EQUIVALENT TO at UI-KeyboardLayout/lib/UI/KeyboardLayout.pm line 5263, <$f> line 38876.
Duplicate: 2257 <== [ 003D <pseudo-manual-round> ] ==> <1 224D> (prefered)
	<≗>	RING EQUAL TO
	<≍>	EQUIVALENT TO at UI-KeyboardLayout/lib/UI/KeyboardLayout.pm line 5263, <$f> line 38876.
Duplicate: 225E <== [ 225F <pseudo-manual-quasisynon> ] ==> <1 225C> (prefered)
	<≞>	MEASURED BY
	<≜>	DELTA EQUAL TO at UI-KeyboardLayout/lib/UI/KeyboardLayout.pm line 5263, <$f> line 38876.
Duplicate: 2263 <== [ 003D <pseudo-manual-addhline> ] ==> <1 2261> (prefered)
	<≣>	STRICTLY EQUIVALENT TO
	<≡>	IDENTICAL TO at UI-KeyboardLayout/lib/UI/KeyboardLayout.pm line 5263, <$f> line 38876.
Duplicate: 2277 <== [ 003D <pseudo-manual-quasisynon> 0338 ] ==> <1 2276> (prefered)
	<≷>	GREATER-THAN OR LESS-THAN
	<≶>	LESS-THAN OR GREATER-THAN at UI-KeyboardLayout/lib/UI/KeyboardLayout.pm line 5263, <$f> line 38876.
Duplicate: 2279 <== [ 003D <pseudo-manual-quasisynon> ] ==> <1 2278> (prefered)
	<≹>	NEITHER GREATER-THAN NOR LESS-THAN
	<≸>	NEITHER LESS-THAN NOR GREATER-THAN at UI-KeyboardLayout/lib/UI/KeyboardLayout.pm line 5263, <$f> line 38876.
Duplicate: 2279 <== [ 003D <pseudo-manual-quasisynon> 0338 0338 ] ==> <1 2278> (prefered)
	<≹>	NEITHER GREATER-THAN NOR LESS-THAN
	<≸>	NEITHER LESS-THAN NOR GREATER-THAN at UI-KeyboardLayout/lib/UI/KeyboardLayout.pm line 5263, <$f> line 38876.
Duplicate: 2982 <== [ 003A <pseudo-manual-amplify> ] ==> <1 2236> (prefered)
	<⦂>	Z NOTATION TYPE COLON
	<∶>	RATIO at UI-KeyboardLayout/lib/UI/KeyboardLayout.pm line 5263, <$f> line 38876.
Duplicate: 2993 <== [ 0028 <pseudo-manual-round> ] ==> <1 2985> (prefered)
	<⦓>	LEFT ARC LESS-THAN BRACKET
	<⦅>	LEFT WHITE PARENTHESIS at UI-KeyboardLayout/lib/UI/KeyboardLayout.pm line 5263, <$f> line 38876.
Duplicate: 2994 <== [ 0029 <pseudo-manual-round> ] ==> <1 2986> (prefered)
	<⦔>	RIGHT ARC GREATER-THAN BRACKET
	<⦆>	RIGHT WHITE PARENTHESIS at UI-KeyboardLayout/lib/UI/KeyboardLayout.pm line 5263, <$f> line 38876.
Duplicate: 2995 <== [ 0029 <pseudo-manual-round> ] ==> <1 2986> (prefered)
	<⦕>	DOUBLE LEFT ARC GREATER-THAN BRACKET
	<⦆>	RIGHT WHITE PARENTHESIS at UI-KeyboardLayout/lib/UI/KeyboardLayout.pm line 5263, <$f> line 38876.
Duplicate: 2996 <== [ 0028 <pseudo-manual-round> ] ==> <1 2985> (prefered)
	<⦖>	DOUBLE RIGHT ARC LESS-THAN BRACKET
	<⦅>	LEFT WHITE PARENTHESIS at UI-KeyboardLayout/lib/UI/KeyboardLayout.pm line 5263, <$f> line 38876.
Duplicate: 29BC <== [ 0025 <pseudo-manual-round> ] ==> <1 2030> (prefered)
	<⦼>	CIRCLED ANTICLOCKWISE-ROTATED DIVISION SIGN
	<‰>	PER MILLE SIGN at UI-KeyboardLayout/lib/UI/KeyboardLayout.pm line 5263, <$f> line 38876.
Duplicate: 2A17 <== [ 222B <pseudo-manual-addleft> ] ==> <1 2A10> (prefered)
	<⨗>	INTEGRAL WITH LEFTWARDS ARROW WITH HOOK
	<⨐>	CIRCULATION FUNCTION at UI-KeyboardLayout/lib/UI/KeyboardLayout.pm line 5263, <$f> line 38876.
Duplicate: 2A34 <== [ 00D7 <pseudo-manual-addleft> ] ==> <1 22C9> (prefered)
	<⨴>	MULTIPLICATION SIGN IN LEFT HALF CIRCLE
	<⋉>	LEFT NORMAL FACTOR SEMIDIRECT PRODUCT at UI-KeyboardLayout/lib/UI/KeyboardLayout.pm line 5263, <$f> line 38876.
Duplicate: 2A35 <== [ 00D7 <pseudo-manual-addright> ] ==> <1 22CA> (prefered)
	<⨵>	MULTIPLICATION SIGN IN RIGHT HALF CIRCLE
	<⋊>	RIGHT NORMAL FACTOR SEMIDIRECT PRODUCT at UI-KeyboardLayout/lib/UI/KeyboardLayout.pm line 5263, <$f> line 38876.
Duplicate: 2A36 <== [ 00D7 <pseudo-manual-amplify> ] ==> <1 2A2F> (prefered)
	<⨶>	CIRCLED MULTIPLICATION SIGN WITH CIRCUMFLEX ACCENT
	<⨯>	VECTOR OR CROSS PRODUCT at UI-KeyboardLayout/lib/UI/KeyboardLayout.pm line 5263, <$f> line 38876.
Duplicate: 2A50 <== [ 00D7 <pseudo-manual-addline> ] ==> <1 2A33> (prefered)
	<⩐>	CLOSED UNION WITH SERIFS AND SMASH PRODUCT
	<⨳>	SMASH PRODUCT at UI-KeyboardLayout/lib/UI/KeyboardLayout.pm line 5263, <$f> line 38876.
Duplicate: 2ACF <== [ 25C1 <pseudo-manual-amplify> <pseudo-manual-amplify> ] ==> <1 2A1E> (prefered)
	<⫏>	CLOSED SUBSET
	<⨞>	LARGE LEFT TRIANGLE OPERATOR at UI-KeyboardLayout/lib/UI/KeyboardLayout.pm line 5263, <$f> line 38876.
Duplicate: 2AFB <== [ 2223 <pseudo-manual-amplify> <pseudo-manual-amplify> ] ==> <1 2AF4> (prefered)
	<⫻>	TRIPLE SOLIDUS BINARY RELATION
	<⫴>	TRIPLE VERTICAL BAR BINARY RELATION at UI-KeyboardLayout/lib/UI/KeyboardLayout.pm line 5263, <$f> line 38876.
Duplicate: 2AFB <== [ 007C <pseudo-manual-addvline> <pseudo-manual-amplify> <pseudo-manual-quasisynon> ] ==> <1 2AF4> (prefered)
	<⫻>	TRIPLE SOLIDUS BINARY RELATION
	<⫴>	TRIPLE VERTICAL BAR BINARY RELATION at UI-KeyboardLayout/lib/UI/KeyboardLayout.pm line 5263, <$f> line 38876.
Duplicate: 2AFD <== [ 002F <pseudo-manual-amplify> ] ==> <1 2215> (prefered)
	<⫽>	DOUBLE SOLIDUS OPERATOR
	<∕>	DIVISION SLASH at UI-KeyboardLayout/lib/UI/KeyboardLayout.pm line 5263, <$f> line 38876.
Duplicate: 2AFF <== [ 007C <pseudo-manual-whiten> ] ==> <1 2AFE> (prefered)
	<⫿>	N-ARY WHITE VERTICAL BAR
	<⫾>	WHITE VERTICAL BAR at UI-KeyboardLayout/lib/UI/KeyboardLayout.pm line 5263, <$f> line 38876.
Duplicate: 3018 <== [ 0028 <pseudo-manual-unsharpen> ] ==> <1 27EE> (prefered)
	<〘>	LEFT WHITE TORTOISE SHELL BRACKET
	<⟮>	MATHEMATICAL LEFT FLATTENED PARENTHESIS at UI-KeyboardLayout/lib/UI/KeyboardLayout.pm line 5263, <$f> line 38876.
Duplicate: 3019 <== [ 0029 <pseudo-manual-unsharpen> ] ==> <1 27EF> (prefered)
	<〙>	RIGHT WHITE TORTOISE SHELL BRACKET
	<⟯>	MATHEMATICAL RIGHT FLATTENED PARENTHESIS at UI-KeyboardLayout/lib/UI/KeyboardLayout.pm line 5263, <$f> line 38876.
Duplicate: A760 <== [ 0059 <pseudo-fake-paleocontraction-by-last> ] ==> <1 A73C> (prefered)
	<Ꝡ>	LATIN CAPITAL LETTER VY
	<Ꜽ>	LATIN CAPITAL LETTER AY at UI-KeyboardLayout/lib/UI/KeyboardLayout.pm line 5263, <$f> line 38876.
Duplicate: A761 <== [ 0079 <pseudo-fake-paleocontraction-by-last> ] ==> <1 A73D> (prefered)
	<ꝡ>	LATIN SMALL LETTER VY
	<ꜽ>	LATIN SMALL LETTER AY at UI-KeyboardLayout/lib/UI/KeyboardLayout.pm line 5263, <$f> line 38876.
Duplicate: 1D4C1 <== [ 006C <font=script> ] ==> <1 2113> (prefered)
	<𝓁>	MATHEMATICAL SCRIPT SMALL L
	<ℓ>	SCRIPT SMALL L at UI-KeyboardLayout/lib/UI/KeyboardLayout.pm line 5263, <$f> line 38876.
Duplicate: 1F12B <== [ 0043 <circle> ] ==> <1 24B8> (prefered)
	<🄫>	CIRCLED ITALIC LATIN CAPITAL LETTER C
	<Ⓒ>	CIRCLED LATIN CAPITAL LETTER C at UI-KeyboardLayout/lib/UI/KeyboardLayout.pm line 5263, <$f> line 38876.
Duplicate: 1F12C <== [ 0052 <circle> ] ==> <1 24C7> (prefered)
	<🄬>	CIRCLED ITALIC LATIN CAPITAL LETTER R
	<Ⓡ>	CIRCLED LATIN CAPITAL LETTER R at UI-KeyboardLayout/lib/UI/KeyboardLayout.pm line 5263, <$f> line 38876.
Duplicate: 1F14B <== [ 004D <square> 0056 ] ==> <1 33B9> (prefered)
	<🅋>	SQUARED MV
	<㎹>	SQUARE MV MEGA at UI-KeyboardLayout/lib/UI/KeyboardLayout.pm line 5263, <$f> line 38876.
Duplicate: A789 <== [ 003A <pseudo-fake-super> ] ==> <1 02F8> (prefered)
        <꞉>     MODIFIER LETTER COLON
        <˸>     MODIFIER LETTER RAISED COLON at UI-KeyboardLayout/lib/UI/KeyboardLayout.pm line 8032, <$f> line 39278.
Duplicate: 02EF <== [ 0020 <pseudo-manual-subize> 0306 ] ==> <1 02EC> (prefered)
        <˯>     02EF    MODIFIER LETTER LOW DOWN ARROWHEAD
        <ˬ>     02EC    MODIFIER LETTER VOICING at UI-KeyboardLayout/lib/UI/KeyboardLayout.pm line 8634, <$f> line 39278.
Duplicate: 2B95 <== [ 2192 <pseudo-fake-black> ] ==> <1 27A1> (prefered)
        <⮕>     2B95    RIGHTWARDS BLACK ARROW
        <➡>     27A1    BLACK RIGHTWARDS ARROW at UI-KeyboardLayout/lib/UI/KeyboardLayout.pm line 9828, <$f> line 43944.
Duplicate: 1F7C6 <== [ 2727 <pseudo-fake-black> ] ==> <1 2726> (prefered)
        <🟆>    1F7C6   FOUR POINTED BLACK STAR
        <✦>     2726    BLACK FOUR POINTED STAR at UI-KeyboardLayout/lib/UI/KeyboardLayout.pm line 9828, <$f> line 43944.
Duplicate: 27C2 <== [ 005F <pseudo-manual-addvline> ] ==> <1 221F> (prefered)
	<⟂>	27C2	PERPENDICULAR
	<∟>	221F	RIGHT ANGLE at UI-KeyboardLayout/lib/UI/KeyboardLayout.pm line 10537, <$f> line 43944.
Duplicate: 2ADB <== [ 0028 <pseudo-manual-addhline> <pseudo-manual-turnaround> ] ==> <1 220B> (prefered)
	<⫛>	2ADB	TRANSVERSAL INTERSECTION
	<∋>	220B	CONTAINS AS MEMBER at UI-KeyboardLayout/lib/UI/KeyboardLayout.pm line 10537, <$f> line 43944.
Duplicate: 1F5A4 <== [ 2661 <pseudo-fake-black> ] ==> <1 2665> (prefered)
        <🖤>    1F5A4   BLACK HEART
        <♥>     2665    BLACK HEART SUIT at UI-KeyboardLayout/lib/UI/KeyboardLayout.pm line 10488, <$f> line 48770.
EOR

my (%known_dups) = map +($_,1),		# As of Unicode 9.0 (questionable: 2982 2ACF 2ADB)
  qw(0296 0384 1D43 1D52 1D9F 1E7A 1E7B 1FBF 2007
    202F 2113 24B8 24C7 2E1E 33B9 FC03 FC68 FD55 FD56 FD57 FD5D FD87 FD8C
    FD92 FDB5 FE34	2B95 1F7C6	27C2 2ADB	1F5A4
    0273 1DAF 2040 207F 224B 2256 2257 225E 2263 2277 2279 2982 2993 2994 2995 2996 29BC
    2A17 2A34 2A35 2A36 2A50 2ACF 2AFB 2AFD 2AFF 3018 3019 A760 A761 1D4C1 1F12B 1F12C 1F14B A789 02EF);

sub decompose_r($$$$);		# recursive
sub decompose_r($$$$) {		# returns array ref, elts are [$compat, @expand]
  my ($self, $t, $i, $cache, @expand) = (shift, shift, shift, shift);
  return $cache->{$i} if $cache->{$i};
  return $cache->{$i} = [[0, $i]] unless my $In = $t->{$i};
  for my $in (@$In) {
    my $compat = $in->[0];
#warn "i=<$i>, compat=<$compat>, rest=<$in->[1]>";
    my $expand_in = $self->decompose_r($t, $in->[1], $cache);
    $expand_in = $self->deep_copy($expand_in);
#warn "Got: $in->[1] -> <@$expand> from $i = <@$in>";
    for my $expand (@$expand_in) {
      warn "Expansion funny: <@$expand>" if @$expand < 2 or $expand->[0] !~ /^[01]$/;
      $compat = ( shift(@$expand) | $compat);
      warn "!Malformed: $i -> $compat <@$expand>" if $expand->[0] =~ /^[01]$/;
      push @expand, [ $compat, @$expand, @$in[2..$#$in] ];
    }
  }
  return $cache->{$i} = \@expand;
}

sub fromHEX ($) { my $i = shift; $i =~ /^\w/ and hex $i}

my %operators = (DOT => ['MIDDLE DOT', 'FULL STOP'], RING => ['DEGREE SIGN'], DIAMOND => ['WHITE DIAMOND'],
		 'DOUBLE SOLIDUS' => ['PARALLEL TO'], MINUS => ['HYPHEN-MINUS']);

#			THIS IS A MULTIMAP (later entry for a TARGER wins)!		■□ ◼◻ ◾◽	◇◆◈⟐⟡⟢⟣⌺	△▲▵▴▽▼▿▾⟁⧊⧋
my %uni_manual = (phonetized => [qw( 0 ə  s ʃ  z ʒ  j ɟ  v ⱱ  n ɳ  N ⁿ  n ŋ  V ɤ  ! ǃ  ? ʔ  ¿ ʕ  | ǀ  f ʄ  F ǂ  x ʘ  X ǁ
				     g ʛ  m ɰ  h ɧ  d ᶑ  C ʗ)],	# z ɮ	(C ʗ is "extras")
		  phonetize2 => [qw( e ɘ  E ɞ  i ɻ  I ɺ)],	# Use some capitalized sources (no uc variants)...
		  phonetize3 => [qw( a ɒ  A Ɒ  e ɜ  E ɝ)],	# Use some capitalized sources (no uc variants)...
		  phonetize0 => [qw( e ə)],
		  paleo	     => [qw( & ⁊  W Ƿ  w ƿ  h ƕ  H Ƕ  G Ȝ  g ȝ )],
                    # cut&paste from http://en.wikipedia.org/wiki/Coptic_alphabet
                    # perl -C31 -wne "chomp; ($uc,$lc,undef,undef,$gr) = split /\t/;($ug,$lg)=split /,\s+/, $gr; print qq( $lg $lc $ug $uc)" coptic2 >coptic-tr
                    # Fix stigma, koppa; p/P are actually 900; a/A are for AKHMIMIC KHEI (variant of KHEI on h/H); 
                    # 2e17 ⸗ double hyphen; sampi's are duplicated in both places
                  greek2coptic => [qw(
                     α ⲁ Α Ⲁ β ⲃ Β Ⲃ γ ⲅ Γ Ⲅ δ ⲇ Δ Ⲇ ε ⲉ Ε Ⲉ ϛ ⲋ Ϛ Ⲋ ζ ⲍ Ζ Ⲍ η ⲏ Η Ⲏ ϙ ϭ Ϙ Ϭ ϡ ⳁ Ϡ Ⳁ
                     θ ⲑ Θ Ⲑ ι ⲓ Ι Ⲓ κ ⲕ Κ Ⲕ λ ⲗ Λ Ⲗ μ ⲙ Μ Ⲙ ν ⲛ Ν Ⲛ ξ ⲝ Ξ Ⲝ ο ⲟ Ο Ⲟ 
                     π ⲡ Π Ⲡ ρ ⲣ Ρ Ⲣ σ ⲥ Σ Ⲥ τ ⲧ Τ Ⲧ υ ⲩ Υ Ⲩ φ ⲫ Φ Ⲫ χ ⲭ Χ Ⲭ ψ ⲯ Ψ Ⲯ ω ⲱ Ω Ⲱ  )],
		  latin2extracoptic => [qw( - ⸗
                     s ϣ S Ϣ f ϥ F Ϥ x ϧ X Ϧ h ϩ H Ϩ j ϫ J Ϫ t ϯ T Ϯ p ⳁ P Ⳁ a ⳉ A Ⳉ )],
		  addline    => [qw( 0 ∅  ∅ ⦱  + ∦  ∫ ⨏  • ⊝  / ⫽  ⫽ ⫻  ∮ ⨔  × ⨳  × ⩐  ⊊ ⊈  ⊋ ⊉  ⫋ ⫅  ⫌ ⫆
		  		     ⪇ ⪙  ⪈ ⪚  ≦ ≨  ≧ ≩)],	#   ∮ ⨔ a cheat
		  addhline   => [qw( = ≣  = ≡  ≡ ≣  † ‡  + ∦  / ∠  | ∟  . ∸  ∨ ⊻  ∧ ⊼  ◁ ⩤  * ⩮ 
		  		     ⊨ ⫢  ⊦ ⊧  ⊤ ⫧  ⊥ ⫨  ⊣ ⫤  ⊳ ⩥  ⊲ ⩤  ⋄ ⟠  ∫ ⨍  ⨍ ⨎  • ⦵  ( ∈  ) ∋
		  		     ∪ ⩌  ∩ ⩍  ≃ ≅  ⨯ ⨲  < ⪕  ≤ ⪛  ⪇ ⩽  ≦ ⫹  > ⪖  ≥ ⪜ ⪈ ⩾  ≧ ⫺ )],	# conflict with modifiers: qw( _ ‗ ); ( ∈  ) ∋ not very useful - but logical - with ∈∋ as bluekeys...  2 ƻ destructive
		  addvline   => [qw( ⊢ ⊩  ⊣ ⫣  ⊤ ⫪  ⊥ ⫫  □ ⎅  | ‖  ‖ ⦀  ∫ ⨒  ≢ ⩨  ⩨ ⩩  • ⦶  
		  		     \ ⫮  ° ⫯  . ⫰  ⫲ ⫵  ∞ ⧞  = ⧧  ⧺ ⧻  + ⧺  ∩ ⨙  ∪ ⨚  0 ⦽  _ ⟂  _ ∟ )],		#  + ⫲ 
		  addtilde   => [qw( 0 ∝  / ∡  \ ∢  ∫ ∱  ∮ ⨑  : ∻  - ≂  ≠ ≆  ~ ≋  ~ ≈  ∼ ≈  ≃ ≊  ≈ ≋  = ≌  ⪇ ⋦  ≦ ≴  ⪈ ⋧  ≧ ≵
		  		     ≐ ≏  ( ⟅  ) ⟆  ∧ ⩄  ∨ ⩅  ∩ ⩆  ∪ ⩇  ≤ ⪍  ≥ ⪎  ⊊ ≴  ⊋ ≵  ⫋ ⋦  ⫌ ⋧)],	# not on 2A**
		  adddot     => [qw( : ⫶  " ∵  ∫ ⨓  ∮ ⨕  □ ⊡  ◇ ⟐  ( ⦑  ) ⦒  ≟ ≗  ≐ ≑
		  		     - ┄  — ┄  ─ ┈  ━ ┅  ═ ┉  | ┆  │ ┊  ┃ ┇  ║ ┋ )],	# ⫶ is tricolon, not vert. …   "; (m-)dash/bar, (b)[h/v]draw, bold/dbl
		  adddottop  => [qw( + ∔ )],
		  addleft    => [qw( = ≔  × ⨴  × ⋉  \ ⋋  + ⨭  → ⧴  ∫ ⨐  ∫ ⨗  ∮ ∳  ⊂ ⟈  ⊃ ⫐  ⊳ ⧐  ⊢ ⊩  ⊩ ⊪  ⊣ ⟞  
		  		     ◇ ⟢  ▽ ⧨  ≡ ⫢  • ⥀  ⋈ ⧑  ≟ ⩻  ≐ ≓  | ⩘  ≔ ⩴  ⊲ ⫷)],	#  × ⨴ is hidden
		  addright   => [qw( = ≕  × ⨵  × ⋊  / ⋌  + ⨮  - ∹  ∫ ⨔  ∮ ∲  ⊂ ⫏  ⊃ ⟉  ⊲ ⧏  ⊢ ⟝  ⊣ ⫣  
		  		     ◇ ⟣  △ ⧩  • ⥁  ⋈ ⧒  ≟ ⩼  ≐ ≒  | ⩗  ⊳ ⫸  : ⧴)],	#  × ⨵ is hidden
		  sharpen    => [qw( < ≺  > ≻  { ⊰  } ⊱  ( ⟨  ) ⟩  ∧ ⋏  ∨ ⋎  . ⋄  ⟨ ⧼  ⟩ ⧽  ∫ ⨘  
		  		     ⊤ ⩚  ⊥ ⩛  ◇ ⟡  ▽ ⧍  • ⏣  ≟ ≙  + ⧾  - ⧿  ⊊ ⪱  ⊋ ⪲  ⪇ ⪱  ⪈ ⪲  ⫋ ⪵  ⫌ ⪶  ≦ ⪳  ≧ ⪴ )],	# ⋆  ⪇≦ ⪈≧
		  unsharpen  => [qw( < ⊏  > ⊐  ( ⟮  ) ⟯  ∩ ⊓  ∪ ⊔  ∧ ⊓  ∨ ⊔  . ∷  ∫ ⨒  ∮ ⨖  { ⦉  } ⦊
		  		     / ⧄  \ ⧅  ° ⧇  ◇ ⌺  • ⌼  ≟ ≚  ≐ ∺  ( 〘  ) 〙  ⊊ ⋤  ⊋ ⋥  ⪇ ⋤  ⪈ ⋥  ⫋ ⋢  ⫌ ⋣  ≦ ⋢  ≧ ⋣ )],	#   + ⊞  - ⊟  * ⊠  . ⊡  × ⊠,   ( ⦗  ) ⦘  ( 〔  ) 〕
		  whiten     => [qw( [ ⟦  ] ⟧  ( ⟬  ) ⟭  { ⦃  } ⦄  ⊤ ⫪  ⊥ ⫫  ; ⨟  ⊢ ⊫  ⊣ ⫥  ⊔ ⩏  ⊓ ⩎  ∧ ⩓  ∨ ⩔  _ ‗  = ≣
		  		     : ⦂  | ⫾  | ⫿  • ○  < ⪡  > ⪢  ⊓ ⩎  ⊔ ⩏  )],	# or blacken □ ■  ◻ ◼  ◽ ◾  ◇ ◆  △ ▲  ▵ ▴  ▽ ▼  ▿ ▾
		  quasisynon => [qw( ∈ ∊  ∋ ∍  ≠ ≶  ≠ ≷  = ≸  = ≹  ≼ ⊁  ≽ ⊀  ≺ ⋡  ≻ ⋠  < ≨  > ≩  Δ ∆
		  		     ≤ ⪕  ≥ ⪖  ⊆ ⊅  ⊇ ⊄  ⊂ ⊉  ⊃ ⊈  ⊏ ⋣  ⊐ ⋢  ⊳ ⋬  ⊲ ⋭  … ⋯  / ⟋  \ ⟍
		  		     ( ⦇  ) ⦈  [ ⨽  ] ⨼  ∅ ⌀
		  		     ⊤ ⫟  ⊥ ⫠  ⟂ ⫛  □ ∎  ▽ ∀  ‖ ∥  ≟ ≞  ≟ ≜  ~ ‿  ~ ⁀  ■ ▬ )],	# ( ⟬  ) ⟭ < ≱  > ≰ ≤ ≯  ≥ ≮  * ⋆
		  amplify    => [qw( < ≪  > ≫  ≪ ⋘  ≫ ⋙  ∩ ⋒  ∪ ⋓  ⊂ ⋐  ⊃ ⋑  ( ⟪  ) ⟫  ∼ ∿  = ≝  ∣ ∥  . ⋮  ⪇ ⪉  ≦ ⪅  ⪈ ⪊  ≧ ⪆
		  		     ∈ ∊  ∋ ∍  - −  / ∕  \ ∖  √ ∛  ∛ ∜  ∫ ∬  ∬ ∭  ∭ ⨌  ∮ ∯  ∯ ∰  : ⦂  ` ⎖
		  		     : ∶  ≈ ≋  ≏ ≎  ≡ ≣  × ⨯  + ∑  Π ∏  Σ ∑  ρ ∐  ∐ ⨿  ⊥ ⟘  ⊤ ⟙  ⟂ ⫡  ; ⨾  □ ⧈  ◇ ◈
		  		     ⊲ ⨞  ⊢ ⊦  △ ⟁  ∥ ⫴  ⫴ ⫼  / ⫽  ⫽ ⫻  • ●  ⊔ ⩏  ⊓ ⩎  ∧ ⩕  ∨ ⩖  ▷ ⊳  ◁ ⊲
		  		     ⋉ ⧔  ⋊ ⧕  ⋈ ⧓  ⪡ ⫷  ⪢ ⫸  ≟ ≛  ≐ ≎  ⊳ ⫐  ⊲ ⫏  { ❴  } ❵  × ⨶  )],	# `  ⋆ ☆  ⋆ ★ ;  ˆ ∧ conflicts with combining-ˆ; * ∏ stops propagation *->×->⋈, : ⦂ hidden; ∥ ⫴; × ⋈ not needed; ∰ ⨌ - ???; ≃ ≌ not useful
		  turnaround => [qw( ∧ ∨  ∩ ∪  ∕ ∖  ⋏ ⋎  ∼ ≀  ⋯ ⋮  … ⋮  ⋰ ⋱  _ ‾ 
		  		     8 ∞  ∆ ∇  Α ∀  Ε ∃  ∴ ∵  ≃ ≂  ˆ ˯
		  		     ∈ ⫛  ∈ ∋  ∋ ⫙  ∉ ∌  ∊ ∍  ∏ ∐  ± ∓  ⊓ ⊔  ≶ ≷  ≸ ≹
		  		     ⋀ ⋁  ⋂ ⋃  ⋉ ⋊  ⋋ ⋌  ⋚ ⋛  ≤ ⋜  ≥ ⋝  ≼ ⋞  ≽ ⋟  )],		# XXXX Can't do both directions
		  superize   => [qw( h ʱ  ' ʹ  < ˂  > ˃  ^ ˑ  ( ˓  ) ˒  ⊢ ˫  0 ᵊ  * ˟  × ˟  ~ ﹋  ≈ ﹌  ─ ‾
		  		     □ ⸋  . ⸳  @ ♭), '#' => '♯'],				# ' Additions to <super>!
		  subize     => [qw( < ˱  > ˲  _ ˍ  ' ˏ  " ˶  ˵ ˵  . ˳  ° ˳  ˘ ˯  ˘ ˬ  ( ˓  ) ˒  0 ₔ  ~ ﹏  ═ ‗), ',' => '¸'],	# '
		  subize2    => [qw( < ˂  > ˃    )],		# these are in older Unicode, so would override if in subize
		  # Most of these are for I/O on very ancient systems (only ∘ and ∅ are not auto-detected on quadapl):
		  aplbox     => [qw( | ⌷  = ⌸  ÷ ⌹  ◇ ⌺  ∘ ⌻  ○ ⌼  / ⍁  \ ⍂  < ⍃  > ⍄  ← ⍇  → ⍈  ∨ ⍌  Δ ⍍  ↑ ⍐  ∧ ⍓  ∇ ⍔  ↓ ⍗  ' ⍞  : ⍠  ≠ ⍯  ? ⍰  ∅ ⎕ )], #'
		  round      => [qw( < ⊂  > ⊃  = ≖  = ≗  = ≍  ∫ ∮  ∬ ∯  ∭ ∰  ∼ ∾  - ⊸  □ ▢  □ ∷  ∥ ≬  ‖ ≬  • ⦁
		  		     … ∴  ≡ ≋  ⊂ ⟃  ⊃ ⟄  ⊤ ⫙  ⊥ ⟒  ( ⦖  ) ⦕  ( ⦓  ) ⦔  ( ⦅  ) ⦆  ⊳ ⪧  ⊲ ⪦  ≟ ≘  ≐ ≖  . ∘
		  		     [ ⟬  ] ⟭  { ⧼  } ⧽  % ⦼  % ‰  × ⦻  ⨯ ⨷  ∧ ∩ ∨ ∪ )],	#   = ≈
		  hattify    => [qw(⊊ ⋨  ⊋ ⋩  ⫋ ⪹  ⫌ ⪺)]);

sub parse_NameList ($$) {
  my ($self, $f, $k, $kk, $name, $_c, %basic, %cached_full, %compose, $version,
      %into2, %ordered, %candidates, %N, %comp2, %NM, %BL, $BL, %G, %NS) = (shift, shift);
  binmode $f;			# NameList.txt is in Latin-1, not unicode
  while (my $s = <$f>) { # extract compositions, add <upgrade> to char downgrades; -> composition, => compatibility composition
    if ($s =~ /^\@\@\@\s+The\s+Unicode\s+Standard\s+(.*?)\s*$/i) {
      $version = $1;
    }
    if ($s =~ /^([\da-f]+)\b\s*(.*?)\s*$/i) {
      my ($K, $Name, $C, $t) = ($1, $2, $self->charhex2key("$1"));
      $N{$Name} = $K;
      $NM{$C} = $Name;		# Not needed for compositions, but handy for user-visible output
      $BL{$C} = $self->charhex2key($BL);		# Used for sorting
      # Finish processing of preceding text
      if (defined $kk) {				# Did not see (official) decomposition
#        warn("see combining: $K  $C  $Name"),
        $NS{$_c}++ if $name =~ /\bCOMBINING\b/ and not ($_c =~ /\p{NonSpacingMark}/);
        if ($name =~ /^(.*?)\s+(?:(WITH)\s+|(?=(?:OVER|ABOVE|PRECEDED\s+BY|BELOW(?=\s+LONG\s+DASH))\s+\b(?!WITH\b|AND\b)))(.*?)\s*$/) {
          push @{$candidates{$k}}, [$1, $3];
          my ($b, $with, $ext) = ($1, $2, $3);
          my @ext = split /\s+AND\s+/, $ext;
          if ($with and @ext > 1) {
            for my $i (0..$#ext) {
              my @ext1 = @ext;
              splice @ext1, $i, 1;
              push @{$candidates{$k}}, ["$b WITH ". (join ' AND ', @ext1), $ext[$i]];
            }
          }
        }
        if ($name =~ /^(.*)\s+(?=OR\s)(.*?)\s*$/) {	# Find the latest possible...
          push @{$candidates{$k}}, [$1, $2];
        }
        if (($t = $name) =~ s/\b(COMBINING(?=\s+CYRILLIC\s+LETTER)|BARRED|SLANTED|APPROXIMATELY|ASYMPTOTICALLY|(?<!\bLETTER\s)SMALL(?!\s+LETTER\b)|ALMOST|^(?:SQUARED|BIG|N-ARY|LARGE)|LUNATE|SIDEWAYS(?:\s+(?:DIAERESIZED|OPEN))?|INVERTED|ARCHAIC|SCRIPT|LONG|MATHEMATICAL|AFRICAN|INSULAR|VISIGOTHIC|MIDDLE-WELSH|BROKEN|TURNED(?:\s+(?:INSULAR|SANS-SERIF))?|REVERSED|OPEN|CLOSED|DOTLESS|TAILLESS|FINAL)\s+|\s+(BAR|SYMBOL|OPERATOR|SIGN|ROTUNDA|LONGA|IN\s+TRIANGLE)$//) {
          push @{$candidates{$k}}, [$t, "calculated-$+"];
          $candidates{$k}[-1][1] .= '-epigraphic'   if $t =~ /\bEPIGRAPHIC\b/;	# will be massaged away from $t later
          $candidates{$k}[-1][0] =~ s/\s+SYMBOL$// and $candidates{$k}[-1][1] .= '-symbol' 
            if $candidates{$k}[-1][1] =~ /\bLUNATE\b/;
# warn("smallcapital $name"),
          $candidates{$k}[-1][1] .= '-smallcaps' if $t =~ /\bSMALL\s+CAPITAL\b/;	# will be massaged away from $t later
# warn "Candidates: <$candidates{$k}[0]>; <$candidates{$k}[1]>";
        }
        if (($t = $name) =~ s/\b(WHITE|BLACK|CIRCLED)\s+//) {
          push @{$candidates{$k}}, [$t, "fake-$1"];
        }
        if (($t = $name) =~ s/\bBLACK\b/WHITE/) {
          push @{$candidates{$k}}, [$t, "fake-black"];
        }
        if (($t = $name) =~ s/^(?:RAISED|MODIFIER\s+LETTER(?:\s+RAISED)?(\s+LOW)?)\s+//) {
          push @{$candidates{$k}}, [$t, $1 ? "fake-sub" : "fake-super"];
        }
        if (($t = $name) =~ s/\bBUT\s+NOT\b/OR/) {
          push @{$candidates{$k}}, [$t, "fake-but-not"];
        }
        if (($t = $name) =~ s/(^LATIN\b.*\b\w)UM((?:\s+ROTUNDA)?)$/$1$2/) {	# Paleo-latin
          push @{$candidates{$k}}, [$t, "fake-umify"];
        }
        if ((0xa7 == ((hex $k)>>8)) and ($t = $name) =~ s/\b(\w|CO|VEN)(?!\1)(\w)$/$2/) {	# Paleo-latin (CON/VEND + digraph)
          push @{$candidates{$k}}, [$t, "fake-paleocontraction-by-last"];
        }
        if (($t = $name) =~ s/(?:(\bMIDDLE-WELSH)\s+)?\b(\w)(?=\2$)//) {
          push @{$candidates{$k}}, [$t, "fake-doubleletter" . ($1 ? "-$1" : '')];
        }
        if (($t = $name) =~ s/\b(APL\s+FUNCTIONAL\s+SYMBOL)\s+\b(.*?)\b\s*\b((?:UNDERBAR|TILDE|DIAERESIS|VANE|STILE|JOT|OVERBAR|BAR)(?!$))\b\s*/$2/) {
#warn "APL: $k ($name) --> <$t>; <$1> <$3>";
          push @{$candidates{$k}}, [$t, "calculated-$1-$3apl"];
          my %s = qw(UP DOWN DOWN UP);				# misprint in the official name???
          $candidates{$k}[-1][0] =~ s/\b(UP|DOWN)(?=\s+TACK\b)/$s{$1}/;
        }
        # Allow QUAD at end only if $2 is not-empty
        if (($t = $name) =~ s/\b(APL\s+FUNCTIONAL\s+SYMBOL)\s+\b(.*?)\b\s*\b(QUAD(?:(?!$)|(?!\2))|(?:UNDERBAR|TILDE|DIAERESIS|VANE|STILE|JOT|OVERBAR|BAR)$)\b\s*/$2/) {
#warn "APL: $k ($name) --> <$t>; <$1> <$3>";
          push @{$candidates{$k}}, [$t, "calculated-$1-$3apl"];
          my %s = qw(UP DOWN DOWN UP);				# misprint in the official name???
          $candidates{$k}[-1][0] =~ s/\b(UP|DOWN)(?=\s+TACK\b)/$s{$1}/;
        } elsif (($t = $name) =~ s/\b(APL\s+FUNCTIONAL\s+SYMBOL)\s+//) {
#warn "APL: $k ($name) --> <$t>; <$1> <$3>";
          push @{$candidates{$k}}, [$t, "calculated-$1"];
          my %s = qw(UP DOWN DOWN UP);				# misprint in the official name???
          $candidates{$k}[-1][0] =~ s/\b(UP|DOWN)(?=\s+TACK\b)/$s{$1}/;
        }
        if (($t = $name) =~ s/\b(LETTER\s+SMALL\s+CAPITAL)/CAPITAL LETTER/) {
          push @{$candidates{$k}}, [$t, "smallcaps"];
        }
        if (($t = $name) =~ s/\b(LETTER\s+)E([SZN])[HG]$/$1$2/			# esh/eng/ezh
                     # next two not triggered since this is actually decomposed:
                 or ($t = $name) =~ s/(?<=\bLETTER\sV\s)WITH\s+RIGHT\s+HOOK$// 
                 or ($t = $name) =~ s/\bDOTLESS\s+J\s+WITH\s+STROKE$/J/ 
                 or $name eq 'LATIN SMALL LETTER SCHWA' and $t = 'DIGIT ZERO') {
          push @{$candidates{$k}}, [$t, "phonetized"] if 0;
        }
      }
      ($k, $name, $_c) = ($K, $Name, $C); 
      $G{$k} = $name if $name =~ /^GREEK\s/;	# Indexed by hex
      $kk = $k;
      next;
    }
    if ($s =~ /^\@\@\s+([\da-f]+)\b/i) {
      die unless $s =~ /^\@\@\s+([\da-f]+)\s.*\s([\da-f]+)\s*$/i;
      $BL = $1;
    }
    my $a;					# compatibility_p, composed, decomposition string
    $a = [0, split /\s+/, "$1"] if $s =~ /^\s+:\s*([0-9A-F]+(?:\s+[0-9A-F]+)*)/; 
    $a = [1, split /\s+/, "$2"], ($1 and push @$a, $1) 
      if $s =~ /^\s+#\s*(?:(<.*?>)\s+)?([0-9A-F]+(?:\s+[0-9A-F]+)*)/;	# Put <compat> at end
    next unless $a; 
    if ($a->[-1] eq '<font>') {{		# Clarify
      my ($math, $type) = ('', '');
#      warn("Unexpected name with <font>: <$name>"), unless $name =~ s/^MATHEMATICAL\s+// and $math = "math-";
      warn("Unexpected name with <font>: $k <$name>"), last 	# In BMP, MATHEMATICAL is omited
        unless $name =~ /^(?:MATHEMATICAL\s+)?((?:(?:BLACK-LETTER|FRAKTUR|BOLD|ITALIC|SANS-SERIF|DOUBLE-STRUCK|MONOSPACE|SCRIPT)\b\s*?)+)(?=\s+(?:SMALL|CAPITAL|DIGIT|NABLA|PARTIAL|N-ARY|\w+\s+SYMBOL)\b)/
            or $name =~ /^HEBREW\s+LETTER\s+(WIDE|ALTERNATIVE)\b/
            or $name =~ /^(ARABIC\s+MATHEMATICAL(?:\s+(?:INITIAL|DOTLESS|STRETCHED|LOOPED|TAILED|DOUBLE-STRUCK))?)\b/
            or $name =~ /^(PLANCK|INFORMATION)/;	# information source
      $type = $1 if $1;
      $type =~ s/BLACK-LETTER/FRAKTUR/;		# http://en.wikipedia.org/wiki/Black-letter#Unicode
      $type =~ s/INFORMATION/Letterlike/;	# http://en.wikipedia.org/wiki/Letterlike_Symbols_%28Unicode_block%29
      $type = '=' . join '-', map lc($_), split /\s+/, $type if $type;
      $a->[-1] = "<font$type>";
    }}
    push @$a, '<pseudo-upgrade>' unless @$a > 2;
    push @{$basic{$k}}, $a;			# <fraction> 1 2044					--\
    undef $kk unless $a->[-1] eq '<pseudo-upgrade>' 				# Disable guesswork processing
      or @$a == 3 and (chr hex $a->[-2]) =~ /\W|\p{Lm}/ and $a->[-1] !~ /^</ and (chr hex $a->[-1]) =~ /\w/;
    # print "@$a";
  }
#  $candidates{'014A'} = ['LATIN CAPITAL LETTER N', 'faked-HOOK'];		# Pretend on ENG...
#  $candidates{'014B'} = ['LATIN SMALL LETTER N',   'faked-HOOK'];		# Pretend on ENG...
  	# XXXX Better have this together with pseudo-upgrade???
  push @{$candidates{'00b5'}}, ['GREEK SMALL LETTER MU',  'faked-calculated-SYMBOL'];	# Pretend on MICRO SIGN...
#  $candidates{'00b5'} = ['GREEK SMALL LETTER MU',  'calculated-SYMBOL'];	# Pretend on MICRO SIGN...
  for my $k (keys %basic) {			# hex
    for my $exp (@{$basic{$k}}) {
      my $base = $exp->[1];			# hex
      my $name = $NM{$self->charhex2key($base)};
      next if not $name and ($k =~ /^[12]?F[89A]..$/ or hex $base >= 0x4E00 and hex $base <= 0x9FCC);		# ideographs; there is also 3400 region...
      warn "Basic: `$k' --> `@$exp', base=`$base' --> `",$self->charhex2key($base),"'" unless $name;
      if ((my $NN = $name) =~ s/\s+OPERATOR$//) {
#warn "operator: `$k' --> <$NN>, `@$exp', base=`$base' --> `",$self->charhex2key($base),"'";
        push @{$candidates{$k}}, [$_, @$exp[2..$#$exp]] for $NN, @{ $operators{$NN} || []};
      }
    }
  }
  for my $how (keys %uni_manual) {	# Some stuff is easier to describe in terms of char, not names
    my $map = $uni_manual{$how};
    die "manual translation map for $how has an odd number of entries" if @$map % 2;
#    for my $from (keys %$map) {
    while (@$map) {
      my $to = pop @$map;		# Give precedence to later entries
      my $from = pop @$map;
      for my $shift (0,1) {
        if ($shift) {
          my ($F, $T) = (uc $from, uc $to);
          next unless $F ne $from and $T ne $to;
          ($from, $to) = ($F, $T);
        }
        push @{$candidates{uc $self->key2hex($to)}}, [$NM{$from}, "manual-$how"];
      }
    }
  }
  for my $g (keys %G) {
    (my $l = my $name = $G{$g}) =~ s/^GREEK\b/LATIN/ or die "Panic";
    next unless my $L = $N{$l};				# is HEX
#warn "latinize: $L\t$l";
    push @{$candidates{$L}}, [$name,  'faked-latinize'];
    next unless my ($lat, $first, $rest, $add) = ($l =~ /^(LATIN\s+(?:SMALL|CAPITAL)\s+LETTER\s+(\w))(\w+)(?:\s+(\S.*))?$/);
    $lat =~ s/P$/F/, $first = 'F' if "$first$rest" eq 'PHI';
    die unless my $LL = $N{$lat};
    $add = (defined $add ? "-$add" : '');		# None of 6.1; only iIuUaAgGdf present of 6.1
    push @{$candidates{$L}}, [$lat,  "faked-greekize$add"];
#warn "latinize++: $L\t$l;\t`$add'\t$lat";
  }
  my %iu_TR = qw(INTERSECTION CAP UNION CUP);
  my %_TR   = map { (my $in = $_) =~ s/_/ /g; $in } qw(SMALL_VEE		LOGICAL_OR   
  						       UNION_OPERATOR_WITH_DOT	MULTISET_MULTIPLICATION
  						       UNION_OPERATOR_WITH_PLUS	MULTISET_UNION
  						       DEL			NABLA
  						       QUOTE			APOSTROPHE
  						       SQUISH			VERTICAL_LINE
  						       SLASH			SOLIDUS
  						       BACKSLASH		REVERSE_SOLIDUS
  						       DIVIDE			DIVISION_SIGN
  						       QUESTION			QUESTION_MARK
  						       UP_CARET			LOGICAL_AND
  						       DOWN_CARET		LOGICAL_OR
  						       JOT			DEGREE_SIGN);
  my($_TR_rx) = map qr/$_/, join '|', keys %_TR;
  for my $c (keys %candidates) {		# Done after all the names are known; hex of the char
   my ($CAND, $app, $t, $base, $b) = ($candidates{$c}, '');
   for my $Cand (@$CAND) {	# (all keys in hex) [MAYBE_CHAR_NAME, how_obtained]
#warn "candidates: $c <$Cand->[0]>, <@$Cand[1..$#$Cand]>";
    # An experiment shows that the FORMS are properly marked as non-canonical decompositions; so they are not needed here
    (my $with = my $raw = $Cand->[1]) =~ s/\s+(SIGN|SYMBOL|(?:FINAL|ISOLATED|INITIAL|MEDIAL)\s+FORM)$//
      and $app = " $1";			# $app is just a candidate; actually, not useful at all
    for my $Mod ( (map ['', $_], $app, '', ' SIGN', ' SYMBOL', ' OF', ' AS MEMBER', ' TO'),	# `SUBSET OF', `CONTAINS AS MEMBER', `PARALLEL TO'
		  (map [$_, ''], 'WHITE ', 'WHITE UP-POINTING ', 'N-ARY '), ['WHITE ', ' SUIT'] ) {
      my ($prepend, $append) = @$Mod;
      next if $raw =~ /-SYMBOL$/ and 0 <= index($append, "SYMBOL");	# <calculated-SYMBOL>
      warn "raw=`$raw', prepend=<$prepend>, append=<$append>, base=$Cand->[0]\n" if debug_GUESS_MASSAGE;
      $t++;
		warn "cand1=`$Cand->[1]' c=`$c'" unless defined $Cand->[0];
      $b = "$prepend$Cand->[0]$append";
      $b =~ s/\bTWO-HEADED\b/TWO HEADED/ unless $N{$b};
      $b =~ s/\bTIMES\b/MULTIPLICATION SIGN/ unless $N{$b};
      $b =~ s/(?:(?<=\bLEFT)|(?<=RIGHT))(?=\s+ARROW\b)/WARDS/ unless $N{$b};
      $b =~ s/\bLINE\s+INTEGRATION\b/CONTOUR INTEGRAL/ unless $N{$b};
      $b =~ s/\bINTEGRAL\s+AVERAGE\b/INTEGRAL/ unless $N{$b};
      $b =~ s/\s+(?:SHAPE|OPERATOR|NEGATED)$// unless $N{$b};
      $b =~ s/\bCIRCLED\s+MULTIPLICATION\s+SIGN\b/CIRCLED TIMES/ unless $N{$b};
      $b =~ s/^(CAPITAL|SMALL)\b/LATIN $1 LETTER/ unless $N{$b};	# TURNED SMALL F
      $b =~ s/\b(CAPITAL\s+LETTER)\s+SMALL\b/$1/ unless $N{$b};		# Q WITH HOOK TAIL
      $b =~ s/\bEPIGRAPHIC\b/CAPITAL/ unless $N{$b};			# XXXX is it actually capital?
      $b =~ s/^LATIN\s+LETTER\s+SMALL\s+CAPITAL\b/LATIN CAPITAL LETTER/ # and warn "smallcapital -> <$b>" 
        if not $N{$b} or $with=~ /smallcaps/;			# XXXX is it actually capital?
      $b =~ s/^GREEK\s+CAPITAL\b(?!=\s+LETTER)/GREEK CAPITAL LETTER/ unless $N{$b};
      $b =~ s/^GREEK\b(?!\s+(?:CAPITAL|SMALL)\s+LETTER)/GREEK SMALL LETTER/ unless $N{$b};
      $b =~ s/^CYRILLIC\b(?!\s+(?:CAPITAL|SMALL)\s+LETTER)(?=\s+LETTER\b)/CYRILLIC SMALL/ unless $N{$b};
      $b =~ s/\bEQUAL(\s+TO\s+SIGN\b)?/EQUALS SIGN/ unless $N{$b};
      $b =~ s/\bMINUS\b/HYPHEN-MINUS/ unless $N{$b};
      $b =~ s/\b(SQUARE\s+)(INTERSECTION|UNION)(?:\s+OPERATOR)?\b/$1$iu_TR{$2}/ unless $N{$b};
      $b =~ s/(?<=WARDS)$/ ARROW/ unless $N{$b};	# APL VANE
#      warn "_TR: <$1> in $b; <<rx=$_TR_rx>>" if $b =~ /\b($_TR_rx)\b/ and not $_TR{$1};
      $b =~ s/\b($_TR_rx)\b/$_TR{$1}/ unless $N{$b};
      $b =  "GREEK SMALL LETTER $b" and ($b =~ /\bDELTA\b/ and $b =~ s/\bSMALL\b/CAPITAL/)
         if not $N{$b} and $N{"GREEK SMALL LETTER $b"};
#      $b =~ s/\bDOT\b/FULL STOP/ unless $N{$b};
#      $b =~ s/^MICRO$/GREEK SMALL LETTER MU/ unless $N{$b};

      warn "    b =`$b', prepend=<$prepend>, append=<$append>, base=$Cand->[0]\n" if debug_GUESS_MASSAGE;
      if (defined ($base = $N{$b})) {
        undef $base, next if $base eq $c;
        $with = $raw if $t;
	warn "<$Cand->[0]> WITH <$Cand->[1]> resolved via SIGN/SYMBOL/.* FORM: strip=<$app> add=<$prepend/$append>\n"
	  if debug_GUESS_MASSAGE and ($append or $app or $prepend);
        last 
      }
    }
    if (defined $base) {
      $base = [$base];
    } elsif ($raw =~ /\bOPERATOR$/) {
      $base = [map $N{$_}, @{ $operators{$Cand->[0]} }] if exists $operators{$Cand->[0]};
    }
    (warnUNRES and warn("Unresolved: <$Cand->[0]> WITH <$Cand->[1]>")), next unless defined $base;
    my @modifiers = split /\s+AND\s+/, $with;
    @modifiers = map { s/\s+/-/g; /^[\da-f]{4,}$/i ? $_ : "<pseudo-\L$_>" } @modifiers;
#warn " $c --> <@$base>; <@modifiers>...\t$b <- $NM{chr hex $c}" ;
    unshift @{$basic{$c}}, [1, $_, @modifiers] for @$base;
    if ($b =~ s/\s+(OPERATOR|SIGN)$//) {	# ASTERISK	(note that RING is a valid name, but has no relation to RING OPERATOR
      unshift @{$basic{$c}}, [1, $base, @modifiers] if defined ($base = $N{$b});	# ASTERISK
#$base = '[undef]' unless defined $base;
#warn("operator via <$b>, <$c> => `$base'");
      (debug_OPERATOR and warn "operator: `$c' ==> `$_', <@modifiers> via <$b>\n"),
        unshift @{$basic{$c}}, [1, $_,    @modifiers] for map $N{$_}, @{ $operators{$b} || [] };	# ASTERISK
    }
#        push @{$candidates{$k}}, [$_, @$exp[2..$#$exp]] for $NN, @{ $operators{$NN} || []};
#    $basic{$c} = [ [1, $base, @modifiers ] ]
   }
  }
  $self->decompose_r(\%basic, $_, \%cached_full) for keys %basic;	# Now %cached_full is fully expanded - has trivial expansions too
  for my $c (sort {fromHEX $a <=> fromHEX $b or $a cmp $b} keys %cached_full) {		# order of chars in Unicode matters (all keys in hex)
    my %seen_compose;
    for my $exp (@{ $cached_full{$c} }) {
      my @exp = @$exp;			# deep copy
      die "Expansion too short: <@exp>" if @exp < 2;	
      next if @exp < 3;			# Skip trivial decompositions
      my $compat = shift @exp;
      my @PRE = @exp;
      my $base = shift @exp;
      @exp = ($base, sort {fromHEX $a <=> fromHEX $b or $a cmp $b} @exp);	# Any order will do; do not care about Unicode rules
#warn "Malformed: [@exp]" if "@exp" =~ /^</ or $compat !~ /^[01]$/;
      next if $seen_compose{"$compat; @exp"}++;		# E.g., WHITE may be added in several ways...
      push @{$ordered{$c}}, [$compat, @exp > 3 ? @exp : @PRE];	# with 2 modifiers order does not matter for the algo below, but we catch U"¯ vs U¯".
      warn qq(Duplicate: $c <== [ @exp ] ==> <@{$compose{"@exp"}[0]}> (prefered)\n\t<), chr hex $c, 
        qq(>\t$c\t$NM{chr hex $c}\n\t<), chr hex $compose{"@exp"}[0][1], qq(>\t$compose{"@exp"}[0][1]\t$NM{chr hex $compose{"@exp"}[0][1]})
          if $compose{"@exp"} and "@exp" !~ /<(font|pseudo-upgrade)>/ and $c ne $compose{"@exp"}[0][1] and not $known_dups{$c};
#warn "Compose rule: `@exp' ==> $compat, `$c'";
      push @{$compose{"@exp"}}, [$compat, $c];
    }
  }					# compose mapping done
  for my $c (sort {fromHEX $a <=> fromHEX $b or $a cmp $b} keys %ordered) {	# all nontrivial!  Order of chars in Unicode matters...
    my(%seen_compose, %seen_contract) = ();
    for my $v (@{ $ordered{$c} }) {		## When (FOO and FOO OPERATOR) + tilde are both remapped to X: X+operator == X
      my %seen;
      for my $off (reverse(2..$#$v)) {
#        next if $seen{$v->[$off]}++;		# chain of compat, or 2A76	->	?2A75 003D	< = = = >
        my @r = @$v;				# deep copy
        splice @r, $off, 1;
        my $compat = shift @r;
#warn "comp: $compat, $c; $off [@$v] -> $v->[$off] + [@r]";
	next if $seen_compose{"$compat; $v->[$off]; @r"}++;
#      next unless my $contracted = $compose{"@r"};	# This omits trivial compositions
        my $contracted = [@{$compose{"@r"} || []}];	# Deep copy
# warn "Panic $c" if @$contracted and @r == 1;
        push @$contracted, [0, @r] if @r == 1;		# Not in %compose
        # QUAD-INT: may be INT INT INT INT, may be INT amp INT INT etc; may lead to same compositions...
#warn "contraction: $_->[0]; $compat; $c; $v->[$off]; $_->[1]" for @$contracted;
        @$contracted = grep {$_->[1] ne $c and not $seen_contract{"$_->[0]; $compat; $v->[$off]; $_->[1]"}++} @$contracted;
#warn "  contraction: $_->[0]; $compat; $c; $v->[$off]; $_->[1]" for @$contracted;
        for my $contr (@$contracted) {		# May be empty: Eg, fractions decompose into 2 3 <fraction> and cannot be composed in 2 steps
          my $calculated = $contr->[0] || $off != $#$v;
          push @{ $into2{$self->charhex2key($c)} }, [(($compat | $contr->[0])<<1)|$calculated, $self->charhex2key($contr->[1]), $self->charhex2key($v->[$off])];	# each: compat, char, combine
          push @{ $comp2{$v->[$off]}{$contr->[1]} }, [ (($compat | $contr->[0])<<1)|$calculated, $c];	# each: compat, char
        }
      }
    }
  }					# (de)compose-into-2 mapping done
  for my $h2 (values %comp2) {	# Massage into the natural order - prefer canonical (de)compositions
    for my $h (values %$h2) {		# RValues!!!	[compat, charHEX] each
#      my @a = sort { "@$a" cmp "@$b" } @$h;
      my @a = sort { $a->[0] <=> $b->[0] or $self->charhex2key($a->[1]) cmp $self->charhex2key($b->[1]) } @$h;
      $h = \@a;
    }
  }
  \%into2, \%comp2, \%NM, \%BL, \%NS, $version
}

sub print_decompositions($;$) {
  my $self = shift;
  my $dec = @_ ? shift : do {  my $f = $self->get_NamesList;
	  $self->load_compositions($f) if defined $f;
	  $self->{Decompositions}} ;
  for my $c (sort keys %$dec) {
    my $arr = $dec->{$c};
    my @out = map +($_->[0] ? '? ' : '= ') . "@$_[1,2]", @$arr;
    print "$c\t->\t", join(",\t", @out), "\n";
  }
}

sub print_compositions_ch_filter($;$$) {
  my $self = shift;
  my $filter = (@_ and shift);
  my $comp = @_ ? shift : do {   my $f = $self->get_NamesList;
	  $self->load_compositions($f) if defined $f;
	  $self->{Compositions}} ;
  my %F = map +($_,1), @$filter;
  for my $c ($filter ? @$filter : sort keys %$comp) {	# composing char
    warn("Unknown composition prefex: [[[$c]]]"), next unless exists $comp->{$c};
    print "$c\n"; 
    for my $b (sort keys %{$comp->{$c}}) {	# base char
      my $arr = $comp->{$c}{$b};
      my @out = map +($_->[0] ? '? ' : '= ') . $_->[1], @$arr;
      print "\t$b\t->\t", join(",\t\t", @out), "\n";
    }
  }
}

sub print_compositions_ch($;$) {
  my $self = shift;
  $self->print_compositions_ch_filter(undef, @_);
}

sub print_compositions($;$) {
  goto &print_compositions_ch if @_ == 1;
  my ($self, $comp) = (shift, shift);
  for my $c (sort {fromHEX $a <=> fromHEX $b or $a cmp $b} keys %$comp) {	# composing char
    print "$c\n"; 
    for my $b (sort {fromHEX $a <=> fromHEX $b or $a cmp $b} keys %{$comp->{$c}}) {	# base char
      my $arr = $comp->{$c}{$b};
      my @out = map +($_->[0] ? '?' : '=') . $_->[1], @$arr;
      print "\t$b\t->\t", join(",\t\t", @out), "\n";
    }
  }
}

sub load_compositions($$) {
  my ($self, $comp, @comb) = (shift, shift);
  return $self if $self->{Compositions};
  my %comp = %{ $self->{'[Substitutions]'} || {} };
  open my $f, '<', $comp or die "Can't open $comp for read";
  ($self->{Decompositions}, $comp, $self->{UNames}, $self->{UBlock}, $self->{exComb}, $self->{uniVersion}) = $self->parse_NameList($f);
  close $f or die "Can't close $comp for read";
#warn "(De)Compositions and UNames loaded";
  # Having hex as index is tricky: is it 4-digits or more?  Is it in uppercase?
  for my $c (sort {fromHEX $a <=> fromHEX $b or $a cmp $b} keys %$comp) {	# composing char
    for my $b (sort {fromHEX $a <=> fromHEX $b or $a cmp $b} keys %{$comp->{$c}}) {	# base char
      my $arr = $comp->{$c}{$b};
      my @out = map [$self->charhex2key($_->[0]), $self->charhex2key($_->[1])], @$arr;
      $comp{$self->charhex2key($c)}{$self->charhex2key($b)} = \@out;
    }
  }
  $self->{Compositions} = \%comp;
  my $comb = join '', keys %{$self->{exComb}};			# should not have metachars here...
  $rxCombining = qr/\p{nonSpacingMark}|[$comb]/ if $comb;
  $self
}

sub load_uniage($$) {
  my ($self, $fn) = (shift, shift);
  # get_AgeList
  open my $f, '<', $fn or die "Can't open `$fn' for read: $!";
  local $/;
  my $s = <$f>;
  close $f or die "Can't close `$fn' for read: $!";
  $self->{Age} = $self->parse_derivedAge($s);
  $self
}

sub load_unidata($$) {
  my ($self, $comp) = (shift, shift);
  $self->load_compositions($comp);
  return $self unless @_;
  $self->load_uniage(shift);
}

my(%charinfo, %UName_v);			# Unicode::UCD::charinfo extremely slow
sub UName($$$;$) {
  my ($self, $c, $verbose, $vbell, $app, $n, $i, $A) = (shift, shift, shift, shift, '');
  $c = $self->charhex2key($c);
  return $UName_v{$c} if $verbose and exists $UName_v{$c} and ($vbell or 0x266a != ord $c);
  if (not exists $self->{UNames} or $verbose) {
    require Unicode::UCD;
    $i = ($charinfo{$c} ||= Unicode::UCD::charinfo(ord $c) || {});
    $A = $self->{Age}{$c};
    $n = $self->{UNames}{$c} || ($i->{name}) || "<$c>";
    if ($verbose and (%$i or $A)) {
      my $scr = $i->{script};
      my $bl = $i->{block};
      $scr = join '; ', grep defined, $scr, $bl, $A;
      $scr = "Com/MiscSym1.1" if $vbell and 0x266a == ord $c;	# EIGHT NOTE: we use as "visual bell"
      $app = " [$scr]" if length $scr;
    }
    return($UName_v{$c} = "$n$app") if $verbose and ($vbell or 0x266a != ord $c);
    return "$n$app"
  }
  $self->{UNames}{$c} || ($c =~ /[\x{d800}-\x{dfff}\x00-\x1f\x7f-\xAF]/ ? '['.$self->key2hex($c).']' : "[$c]")
}

sub parse_derivedAge ($$) {
  my ($self, $s, %C) = (shift, shift);
  for my $l (split /\n/, $s) {
    next if $l =~ /^\s*(#|$)/;
    die "Unexpected line in DerivedAge: `$l'" 
      unless $l =~ /^([0-9a-f]{4,})(?:\.\.([0-9a-f]{4,}))?\s*;\s*(\d\d?\.\d)\b/i;
    $C{chr $_} = $3 for (hex $1) .. hex($2 || $1);
  }
  \%C;
}

# use Dumpvalue;
# my $first_time_dump;
my %warned_decomposed;
sub get_compositions ($$$$;$) {		# Now only the undo-brach is used...
  my ($self, $m, $C, $undo, $unAltGr, @out) = (shift, shift, shift, shift, shift);
#  return unless defined $C and defined (my $r = $self->{Compositions}{$m}{$C});
# Dumpvalue->new()->dumpValue($self->{Compositions}) unless $first_time_dump++;
  return undef unless defined $C;
  $C = $C->[0] if 'ARRAY' eq ref $C;			# Treat prefix keys as usual keys
warn "doing <$C> <@$m>: undo=$undo C=", $self->key2hex($C),  ", maps=", join ' ', map $self->key2hex($_), @$m if warnDO_COMPOSE; # if $m eq 'A';
  if ($undo) {
    return undef unless my $dec = $self->{Decompositions}{$C};
    # order in @$m matters; so does one in Decompositions - but less so
    # Hence the external loop should be in @$m
    for my $M (@$m) {
      push @out, $_ for grep $M eq $_->[2], @$dec;
      if (@out) {	# We took the first guy from $m which allows such decomposition
        warn "Decomposing <$C> <$M>: multiple answers: <", (join '> <', map "@$_", @out), ">"
	  if @out > 1 and not $warned_decomposed{$C,$M}++;
warn "done undo <$C> <@$m>: -> ", $self->array2string(\@out) if warnDO_COMPOSE; # if $m eq 'A';
        return $out[0][1]
      }
    }
    return undef;
  }
  if ($unAltGr) {{
    last unless $unAltGr = $unAltGr->{$C};
    my(@seen, %seen);
    for my $comp ( @$m ) {
      my $a1 = $self->{Compositions}{$comp}{$unAltGr};;
      push @seen, $a1 if $a1 and not $seen{$a1->[0][1]}++;
#warn "Second binding `$a1->[0][1]' for `$unAltGr' (on `$C') - after $seen[0][0][1]" if @seen == 2;
      next unless defined (my $a2 = $self->{Compositions}{$comp}{$C}) or @seen == 2;
#warn "  --> AltGr-binding `$a2->[0][1]' (on `$C')" if @seen == 2 and defined $a2;
      warn "Conflict between the second binding `$a1->[0][1]' for `$unAltGr' and AltGr-binding `$a2->[0][1]' (on `$C')" 
        if $a2 and $a1 and @seen == 2 and $a1->[0][1] ne $a2->[0][1];
      return ((@seen == 2 and $a1) or $a2)->[0][1];
    }
  }}
  return undef unless my ($r) = grep defined, map $self->compound_composition($_,$C), @$m;
  warn "Composing <$C> <@$m>: multiple answers: <", (join '> <', map "@$_", @$r), ">" unless @$r == 1 or $C eq ' ';
# warn("done   <$C> <$m>: <$r->[0][1]>"); # if $m eq 'A';
  $r->[0][1]
}

sub compound_composition ($$$) {
  my ($self, $M, $C, $doc, $doc1, @res, %seen) = (shift, shift, shift, '', '');
  return undef unless defined $C;
  $doc1 = $C->[3] if 'ARRAY' eq ref $C and defined $C->[3];	# may be used via <reveal-substkey>, when $M is empty
  $doc = "$doc1 ⇒ " if length $doc1;
  $C = $C->[0] if 'ARRAY' eq ref $C;
warn "composing `$M' with base <$C>" if warnDO_COMPOSE;
  $C = [[0, $C, $doc1]];			# Emulate element of return of Compositions ("one translation, explicit")
  for my $m (reverse split /\+|-(?=-)/, $M) {
    my @res;
    if ($m =~ /^(?:-|(?:[ul]c(?:first)?|dectrl)$)/) {
      if ($m =~ s/^-//) {
        @res = map $self->get_compositions([$m], $_->[1], 'undo'), @$C;
        @res = map [[0,$_]], grep defined, @res;
      } elsif ($m eq 'lc') {
        @res = map {($_->[1] eq lc($_->[1]) or 1 != length lc($_->[1])) ? () : [[0, lc $_->[1]]]} @$C
      } elsif ($m eq 'uc') {
        @res = map {($_->[1] eq uc($_->[1]) or 1 != length uc($_->[1])) ? () : [[0, uc $_->[1]]]} @$C
      } elsif ($m eq 'ucfirst') {
        @res = map {($_->[1] eq ucfirst($_->[1]) or 1 != length ucfirst($_->[1])) ? () : [[0, ucfirst $_->[1]]]} @$C
      } elsif ($m eq 'dectrl') {
        @res = map {(0x20 <= ord($_->[1])) ? () : [[0, chr(0x40 + ord $_->[1])]]} @$C
      } else {
        die "Panic"
      }
    } else {
#warn "compose `$m' with bases <", join('> <', map $_->[1], @$C), '>';
#      warn "composition <<<$m>>> unknown" unless keys %{ $self->{Compositions}{$m} } or $m eq '<reveal-substkey>';
      @res = map $self->{Compositions}{$m}{$_->[1]}, @$C;
    }
    @res = map @$_, grep defined, @res;
    return undef unless @res;
    $C = [map [$_->[0], $_->[1], "$doc$M"], @res];
  }
  $C
}

sub compound_composition_many ($$$$) {		# As above, but takes an array of [char, docs]
  my ($self, $M, $CC, $ini) = (shift, shift, shift, shift);
  return undef unless $CC;
  my $doc = (($ini and ref $ini and defined $ini->[3]) ? "$ini->[3] ⇒ Subst{" : '');
  my($doc1, @res) = $doc && '}';
  for my $C (@$CC) {
#    $C = $C->[0] if 'ARRAY' eq ref $C;
    next unless defined $C;
    my $in = $self->compound_composition($M, [$C->[0], undef, undef, "$doc$C->[1]$doc1"]);
    push @res, @$in if defined $in;
  }
  return undef unless @res;
  \@res
}

# Design goals: we assign several diacritics to a prefix key (possibly with 
# AltGr on the "Base key" and/or other "multiplexers" in between).  We want: 
#   *) a lc/uc paired result to sit on Shift-paired keypresses; 
#   *) avoid duplication among multiplexers (a secondary goal); 
#   *) allow some diacritics in the list to be prefered ("groups" below);
#   *) when there is a choice, prefer non-bizzare (read: with smaller Unicode 
#      "Age" version) binding to be non-multiplexed.  
# We allow something which was not on AltGr to acquire AltGr when it gets a 
# diacritic.

# It MAY happen that an earlier binding has empty slots, 
# but a later binding exists (to preserve lc/uc pairing, and shift-state)

### XXXX Unclear: how to catenate something in front of such a map...
# we do $composition->[0][1], which means we ignore additional compositions!  And we ignore HOW, instead of putting it into penalty

sub sort_compositions ($$$$$;$) {
  my ($self, $m, $C, $Sub, $dupsOK, $w32OK, @res, %seen, %Penalize, %penalize, %OK, %ok, @C) = (shift, shift, shift, shift, shift, shift);
warn "compounding ", $self->array2string($C) if warnSORTCOMPOSE;
  for my $c (@$C) {
    push @C, [map {($_ and 'ARRAY' eq ref $_) ? $_->[0] : $_} @$c]
  }
  my $char = $C[0][0];
  $char = 'N/A' unless defined $char;
  for my $MM (@$m) {			# |-groups
    my(%byPenalty, @byLayers);
    for my $M (@$MM) {			# diacritic in a group; may flatten each layer, but do not flatten separately each shift state: need to pair uc/lc
      if ((my $P = $M) =~ s/^(!)?\\(\\)?//) {
        my($neg, $strong) = ($1, $2);
# warn "Penalize: <$P>";	# Actually, it is not enough to penalize; one should better put it in a different group...
	if ($P =~ s/\[(.*)\]$//) {
	  #$P = $self->stringHEX2string($P);
	  my $match;
	  $char eq $_ and $match++ for split //, $self->stringHEX2string("$1");
	  next unless $match;
	}  
	#$P = $self->stringHEX2string($P);
	if ($neg) {
          $strong ? $OK{$_}++ : $ok{$_}++ for split //, $P;
        } else {
          $strong ? $Penalize{$_}++ : $penalize{$_}++ for split //, $P;
        }
        next
      }
      for my $L (0..$#C) {		# Layer number; indexes a shift-pair
#        my @res2 = map {defined($_) ? $self->{Compositions}{$M}{$_} : undef } @{ $C[$L] };
###	$M =~ s/^<reveal-(?:green|subst)key>$//; # Hack: the rule <reveal-substkey> ⇝ an empty rule — which always succeeds
        my @working_with = grep defined, @{ $C[$L] };				# ., KP_Decimal gives [. undef]
        my @Res2 = map $self->compound_composition($M, $_), @{ $C->[$L] };	# elt: [$synth, $char]
warn "compound  `$M' of [@working_with] -> ", $self->array2string(\@Res2) if warnSORTCOMPOSE;
		# Now retry with substituted keys $Sub; Hack: the rule <reveal-substkey> is unknown to the rest of this module,
		# so always fails if present in a chain, here we remove it — and an empty mogrifier list always succeeds
        (my $MMM = $M) =~ s/(^|\+)<reveal-(?:green|subst)key>$//; # 
        my @Res3 = map $self->compound_composition_many($MMM, (defined() ? $Sub->{($_ and ref) ? $_->[0] : $_} : $_), $_), 
        	   @{ $C->[$L] };
warn "compound+ `$M' of [@working_with] -> ", $self->array2string(\@Res3) if warnSORTCOMPOSE;
        for my $shift (0..$#Res3) {
          if (defined $Res2[$shift]) {
            push @{ $Res2[$shift]}, @{$Res3[$shift]} if $Res3[$shift]
          } else {
            $Res2[$shift] = $Res3[$shift]
          }
        }
#        defined $Res2[$_] ? ($Res3[$_] and push @{$Res2[$_]}, @{$Res2[$_]}) : ($Res2[$_] = $Res3[$_]) for 0..$#Res3;
        @Res2 = $self->DEEP_COPY(@Res2);
        my ($ok, @ini_compat);
        do {{							# Run over found translations
	  my @res2   = map {defined() ? $_->[0] : undef} @Res2;		# process next unprocessed translations
	  defined and (shift(@$_), (@$_ or undef $_)) for @Res2;	# remove what is being processed
	  $ok = grep $_, @res2;
          @res2    = map {(not defined() or (!$dupsOK and $seen{$_->[1]}++)) ? undef : $_} @res2;	# remove duplicates
	  my @compat = map {defined() ? $_->[0] : undef} @res2;
	  my @_from_ = map {defined() ? $_->[2] : undef} @res2;
	  defined and s/((?<![^+])|(?<=⇒ ))Cached\d+=//g for @_from_;
	  @res2      = map {defined() ? $_->[1] : undef} @res2;
          @res2      = map {0x10000 > ord($_ || 0) ? $_ : undef} @res2 unless $w32OK;	# remove those needing surrogates
	  defined $ini_compat[$_] or $ini_compat[$_] = $compat[$_] for 0..$#compat;
	  my @extra_penalty = map {!!$compat[$_] and $ini_compat[$_] < $compat[$_]} 0..$#compat;
          next unless my $cnt = grep defined, @res2;
          my($penalty, $p) = [('zzz') x @res2];	# above any "5.1", "undef" ("unassigned"???)
          # Take into account the "compatibility", but give it lower precedence than the layer:
          # for no-compatibility: do not store the level;
          defined $res2[$_] and $penalty->[$_] gt ( $p = ($OK{$res2[$_]} ? '+' : '-') . ($self->{Age}{$res2[$_]} || 'undef') .
          			($ok{$res2[$_]} ? '+' : '-') . "#$extra_penalty[$_]#" . ($self->{UBlock}{$res2[$_]} || '') )
            and $penalty->[$_] = $p for 0..$#res2;
          my $have1 = not (defined $res2[0] and defined $res2[1]);		# Prefer those with both entries
          # Break a non-lc/uc paired translations into separate groups
          my $double_occupancy = ($cnt == 2 and $res2[0] ne $res2[1] and lc $res2[0] eq lc $res2[1]);	# Case fold
warn "   seeing random-double, penalties <$penalty->[0]>, <$penalty->[1]>\n" if warnSORTCOMPOSE;
          next if $double_occupancy and grep {defined and $Penalize{$_}} @res2;
          if ($double_occupancy and grep {defined and $penalize{$_}} @res2) {
            defined $res2[$_] and $penalty->[$_] = "zzz$penalty->[$_]" for 0..$#res2;
          } else {
            defined and $Penalize{$_} and $cnt--, $have1=1, undef $_ for @res2;
            defined $res2[$_] and $penalize{$res2[$_]} and $penalty->[$_] = "zzz$penalty->[$_]" for 0..$#res2;
          }
          next unless $cnt;
          if (not $double_occupancy and $cnt == 2 and (1 or $penalty->[0] ne $penalty->[1])) {	# Break (penalty here is not a good idea???)
warn "   breaking random-double, penalties <$penalty->[0]>, <$penalty->[1]>\n" if warnSORTCOMPOSE;
            push @{ $byPenalty{"$penalty->[0]1"}[0][$L] }, [       [$res2[0],undef,undef,$_from_[0]]];
            push @{ $byPenalty{"$penalty->[1]1"}[0][$L] }, [undef, [$res2[1],undef,undef,$_from_[1]]];
            next;		# Now: $double_occupancy or $cnt == 1 or $penalty->[0] eq $penalty->[1]
          }
          $p = (defined $res2[0] ? $penalty->[0] : 'zzz');	# may have been undef()ed due to Penalty...
          $p = $penalty->[1] if @$penalty > 1 and defined $res2[1] and $p gt $penalty->[1];
          push @{ $byPenalty{"$p$have1"}[$double_occupancy][$L] }, 
#            [map {defined $res2[$_] ? $res2[$_] : undef} 0..$#res2];
            [map {defined $res2[$_] ? [$res2[$_],undef,undef,$_from_[$_]] : undef} 0..$#res2];
        }} while $ok;
warn " --> combined of [@working_with] -> ", $self->array2string([\@res, %byPenalty]) if warnSORTCOMPOSE;
      }
    }		# sorted bindings, per Layer
    push @res, [ @byPenalty{ sort keys %byPenalty } ];	# each elt is an array ref indexed by layer number; elt of this is [lc uc]
  }
#warn 'Compositions: ', $self->array2string(\@res);
  \@res
}	# index as $res->[group][penalty_N][double_occ][layer][NN][shift]

sub equalize_lengths ($$@) {
  my ($self, $extra, $l) = (shift, shift || 0, 0);
  $l <= length and  $l = length for @_;
  $l += $extra;
  $l >  length and $_ .= ' ' x ($l - length) for @_;
}

sub report_sorted_l ($$$;$$) {	# 6 levels: |-group, priority, double-occupancy, layer, count, shift
  my ($self, $k, $sorted, $bold, $bold1, $top2, %bold) = (shift, shift, shift, shift, shift);
  $k = $k->[0] if 'ARRAY' eq ref($k || 0);
  $k = '<undef>' unless defined $k;
  $k = "<$k>" if defined $k and $k !~ /[^┃┋║│┆\s]/;
  my @L = ($k, '');			# Up to 100 layers - an overkill, of course???  One extra level to store separators...
  $bold{$_} = '┋' for @{$bold1 || []};
  $bold{$_} = '┃' for @{$bold || []};
  for my $group (0..$#$sorted) { # Top level
    $self->equalize_lengths(0, @L);
    $_ .= ' ' . ($bold{$group} || '║') for @L;
    my $prio2;    
    for my $prio (@{ $sorted->[$group] }) {
      if ($prio2++) {
        $self->equalize_lengths(0, @L);
        $_ .= ' │' for @L;
      }
      my $double2;
      for my $double (reverse @$prio) {
        if ($double2++) {
          $self->equalize_lengths(0, @L);
          $_ .= ' ┆' for @L;
        }
        for my $layer (0..$#$double) {
          for my $set (@{$double->[$layer]}) {
            for my $shift (0,1) {
              next unless defined (my $k = $set->[$shift]);
              $k = $k->[0] if ref $k;
              $k = " $k" if $k =~ /$rxCombining/;
              if (2*$layer + $shift >= $#L) {		# Keep last layer pristine for correct separators...
                my $add = 2*$layer + $shift - $#L + 1;
                push @L, ($L[-1]) x $add;
              }
              $L[ 2*$layer + $shift ] .= " $k";
            }
          }
        }
      }
    }
  }
  pop @L while @L and $L[-1] !~ /[^┃┋║│┆\s]/;
  join "\n", @L, '';
}

sub append_keys ($$$$;$) {	# $KK is [[lc,uc], ...]; modifies $C in place
  my ($self, $C, $KK, $LL, $prepend, @KKK, $cnt) = (shift, shift, shift, shift, shift);
  for my $L (0..$#$KK) {	# $LL contains info about from which layer the given binding was stolen
    my $k = $KK->[$L];
    next unless defined $k and (defined $k->[0] or defined $k->[1]);
    $cnt++;
    my @kk = map {$_ and ref $_ ? $_->[0] : $_} @$k;
    my $paired = (@$k == 2 and defined $k->[0] and defined $k->[1] and $kk[0] ne $kk[1] and $kk[0] eq lc $kk[1]);
    my @need_special = map { $LL and $L and defined $k->[$_] and defined $LL->[$L][$_] and 0 == $LL->[$L][$_]} 0..$#$k;
    if (my $special = grep $_, @need_special) {	# count
       ($prepend ? push(@{ $KKK[$paired][0] }, $k) : unshift(@{ $KKK[$paired][0] }, $k)), 
         next if $special == grep defined, @$k;
       $paired = 0;
       my $to_level0 = [map { $need_special[$_] ? $k->[$_] : undef} 0..$#$k];
       $k            = [map {!$need_special[$_] ? $k->[$_] : undef} 0..$#$k];
       $prepend ? push @{ $KKK[$paired][0] }, $to_level0 : unshift @{ $KKK[$paired][0] }, $to_level0;
    }
    $prepend ? push @{ $KKK[$paired][$L] }, $k : unshift @{ $KKK[$paired][$L] }, $k;	# 0: layer has only one slot
  }
#print "cnt=$cnt\n";
  return unless $cnt;
  push    @$C, [[@KKK]] unless $prepend;	# one group of one level of penalty
  unshift @$C, [[@KKK]] if     $prepend;	# one group of one level of penalty
  1
}

sub shift_pop_compositions ($$$;$$$$) {	# Limit is how many groups to process
  my($self, $C, $L, $backwards, $omit, $limit, $ignore_groups, $store_level, $skip_lc, $skip_uc) 
    = (shift, shift, shift, shift, shift || 0, shift || 1e100, shift || 0, shift, shift, shift);
  my($do_lc, $do_uc) = (!$skip_lc, !$skip_uc);
  my($both, $first, $out_lc, $out_uc, @out, @out_levels, $have_out, $groupN) = ($do_lc and $do_uc);
  my @G = $backwards ? reverse @$C : @$C;
  for my $group (@G[$omit..$#G]) {
    last if --$limit < 0;
    $groupN++;
    for my $penalty_group (@$group) {	# each $penalty_group is indexed by double_occupancy and layer
      # each layer in sorted; if $both, we prefer to extract a paired translation; so it is enough to check the first elt on each layer
      my $group_both = $both;
      if ($both) {
        $group_both = 0 unless $penalty_group->[1] and @{ $penalty_group->[1][$L] || [] } or @{ $penalty_group->[1][0] || [] };
      }	# if $group_both == 0, and $both: double-group is empty, so we can look only in single/unrelated one.
              # if $both = $group_both == 0: may not look in double group, so can look only in single/unrelated one
              # if $both = $group_both == 1: must look in double-group only.
      for my $Set (($L ? [0, $penalty_group->[$group_both][0]] : ()), [$L, $penalty_group->[$group_both][$L]]) {
        my $set = $Set->[1];
        next unless $set and @$set;		# @$set consists of [unshifted, shifted] pairs
        if ($group_both) {	# we know we meet a double element at start of the group
          my $OUT = $backwards ? pop @$set : shift @$set;	# we know we meet a double element at start of the group
          return [] if $groupN <= $ignore_groups;
          @$store_level = ($Set->[0]) x 2 if $store_level;
          return $OUT;
        }
##          or ($both and defined $elt->[0] and defined $elt->[1]);
        my $spliced = 0;
        for my $eltA ($backwards ? map($#$set - $_, 0..$#$set) : 0..$#$set) {			
          my $elt = $eltA - $spliced;
          my $lc_ok = ($do_lc and defined $set->[$elt][0]);
          my $uc_ok = ($do_uc and defined $set->[$elt][1]);
          next if not ($lc_ok or $uc_ok);
          my $have_both = (defined $set->[$elt][0] and defined $set->[$elt][1]);
          my $found_both = ($lc_ok and $uc_ok);	# If defined $have_out, cannot have $found_both; moreover $have_out ne $uc_ok
	  die "Panic!" if defined $have_out and ($found_both or $have_out eq $uc_ok);
#          next if not $found_both and defined $have_out and $have_out eq $uc_ok;
          my $can_splice = $have_both ? $both : 1;
          my $can_return = $both ? $have_both : 1;
          my $OUT = my $out = $set->[$elt];			# Can't return yet: @out may contain a part of info...
          unless ($groupN <= $ignore_groups or defined $have_out and $have_out eq $uc_ok) {	# In case !$do_return or $have_out
            $out[$uc_ok] = $out->[$uc_ok];			# In case !$do_return or $have_out
            $out_levels[$uc_ok] = $Set->[0];
          }
#warn 'Doing <', join('> <', map {defined() ? $_ : 'undef'} @{ $set->[$elt] }), "> L=$L; splice=$can_splice; return=$can_return; lc=$lc_ok uc=$uc_ok";
          if ($can_splice) {		# Now: $both and not $have_both; must edit in place
            splice @$set, $elt, 1;
            $spliced++ unless $backwards;
          } else {			# Must edit in place
            $OUT = [@$out];					# Deep copy
            undef $out->[$uc_ok];				# only one matched...
          }
          $OUT = [] if $groupN <= $ignore_groups;
          if ($can_return) {
            if ($found_both) {
              @$store_level = map {$_ and $Set->[0]} @$OUT if $store_level;
              return $OUT;
            } else {
              @$store_level = @out_levels if $store_level;
              return \@out;
            }
#            return($found_both ? $OUT : \@out);
          }					# Now: had $both and !$had_both; must condinue
          $have_out = $uc_ok;
          $both = 0;						# $group_both is already FALSE
          ($lc_ok ? $do_lc : $do_uc) = 0;
#warn "lc/uc: $do_lc/$do_uc";
        }
      }
    }
  }
  @$store_level = @out_levels if $store_level;
  return \@out
}

my ($rebuild_fake, $rebuild_style) = ("\n\t\t\t/* To be auto-generated */\n", <<'EOR');

.klayout span, .klayout-wrapper .over-shift {
 font-size:   29pt ;
 font-weight: bolder; 
 text-wrap:   none;
 white-space: nowrap;
}
.klayout kbd, .asSpan		{ display: inline-block; }
.asSpan2			{ display: inline-table; }

	/* Not used; allows /-diagonals to be highlighted with nth-last-of-type() */
.klayout kbd.hidden-align	{ display: none; }

kbd span.lc, kbd span.uc	{ display: inline; }

/* Hide lc only if in .uc or hovering over -uc and not inside; similarly for uc */
/* States:	.klayout-wrapper:not(:hover)	|	.klayout.uclc:hover		NORMAL = UCLC
		.klayout-uc:hover .klayout:not(:hover)					UC
		.klayout-wrapper:hover .klayout-uc:not(:hover)				LC	*/
.klayout.lc kbd span.uc, .klayout.uc kbd span.lc, 
	.klayout-uc:hover:not(:active)		.klayout:not(.lc):not(:hover) kbd span.lc,
	.klayout-uc:hover:active		.klayout:not(.uc):not(:hover) kbd span.uc,
	.klayout-wrapper:hover:not(:active)	.klayout-uc:not(:hover) .klayout:not(.uc) kbd span.uc,
	.klayout-wrapper:hover:active		.klayout-uc:not(:hover) .klayout:not(.lc) kbd span.lc	{ display: none; }

/* These should be active unless hovering over wrapper, and not internal .klayout	*/
.klayout.uclc:hover kbd span.uc, .klayout.uclc:hover kbd span.lc,
	.klayout.uclc.force kbd span.uc, .klayout.uclc.force kbd span.lc,
	.klayout-wrapper:not(:hover) .klayout-uc .klayout.uclc:not(.do-alt) kbd span.uc,
	.klayout-wrapper:not(:hover) .klayout-uc .klayout.uclc:not(.do-alt) kbd span.lc {
    font-size: 70%;
}
.klayout.uclc:hover kbd span.uc, .klayout.uclc:hover kbd span.lc,
 .klayout.uclc:not(.in-wrapper) kbd span.uc, .klayout.uclc:not(.in-wrapper) kbd span.lc,
	.klayout.uclc.force kbd span.uc, .klayout.uclc.force kbd span.lc,
	.klayout-wrapper:not(:hover) .klayout-uc .klayout.uclc.do-alt kbd span.uc, 
	.klayout.uclc.do-alt:hover kbd span.uc,
	.klayout-wrapper:not(:hover) .klayout-uc .klayout.uclc.do-alt kbd span.lc, 
	.klayout.uclc.do-alt:hover kbd span.lc,
	.klayout-wrapper:not(:hover) .klayout-uc .klayout.uclc:not(.do-alt) kbd span.uc,
	.klayout-wrapper:not(:hover) .klayout-uc .klayout.uclc:not(.do-alt) kbd span.lc {
    position: absolute;
    z-index: 10;
    border: 1px dotted green;
    line-height: 0.8em;		/* decreasing this moves up; should be changed with padding-bottom */
}
.klayout-wrapper:not(:hover) .klayout-uc .klayout.uclc kbd span.uc,
	.klayout-wrapper .klayout-uc .klayout.uclc:hover kbd span.uc,
	.klayout.uclc kbd span.uc {
    right: 0.2em;
    top:  -0.05em;
    padding-bottom: 0.15em;	/* Less makes _ not fit inside border... */
}
.klayout-wrapper:not(:hover) .klayout-uc .klayout.uclc kbd span.lc,
	.klayout-wrapper .klayout-uc .klayout.uclc:hover kbd span.lc,
	.klayout.uclc kbd span.lc {
    left: 0.2em;
    bottom:  0em;
}
	/* Same for left/right placement */
.klayout-wrapper:not(:hover) .klayout-uc .klayout.uclc kbd span.uc.on-left,
	.klayout-wrapper .klayout-uc .klayout.uclc:hover kbd span.uc.on-left,
	.klayout.uclc:not(.in-wrapper) kbd span.uc.uc.on-left {	/* repeat is needed to protect against :not(.base) about 25lines below */
    left: 0.35em;
    right: auto;
}
.klayout-wrapper:not(:hover) .klayout-uc .klayout.uclc kbd span.lc.on-left,
	.klayout-wrapper .klayout-uc .klayout.uclc:hover kbd span.lc.on-left,
	.klayout.uclc:not(.in-wrapper) kbd span.lc.lc.on-left {
    left: 0.0em;
}
.klayout-wrapper:not(:hover) .klayout-uc .klayout.uclc kbd span.uc.on-right,
	.klayout-wrapper .klayout-uc .klayout.uclc:hover kbd span.uc.on-right,
	.klayout.uclc:not(.in-wrapper) kbd span.uc.uc.on-right {
    right: 0.0em;
}
.klayout-wrapper:not(:hover) .klayout-uc .klayout.uclc kbd span.lc.on-right,
	.klayout-wrapper .klayout-uc .klayout.uclc:hover kbd span.lc.on-right,
	.klayout.uclc:not(.in-wrapper) kbd span.lc.lc.on-right {
    left: auto;
    right: 0.35em;
}
.klayout kbd span:not(.base):not(.base-uc):not(.base-lc).on-right
    { left: auto;  right: 0.0em; position: absolute; }
.klayout kbd span:not(.base):not(.base-uc):not(.base-lc).on-left
    { left: 0.0em;  right: auto; position: absolute; }
.klayout kbd .on-right:not(.prefix), .on-right-ex		{ color: firebrick; }
.klayout kbd .on-right:not(.prefix).vbell			{ color: Coral; }
.klayout kbd .on-left { z-index: 10; }
.klayout kbd .on-right { z-index: 9; }

.klayout-wrapper:hover .klayout.uclc:not(:hover) kbd.shift {outline: 6px dotted green;}

kbd span, kbd div { vertical-align: bottom; }	/* no effect ???!!! */

kbd {
    color: #444;
/*    line-height: 1.6em;  */
    width: 1.4em;		/* +0.24em border +0.08em margin; total 1.72em */

    /* +0.3em border;  */
    min-height: 0.83em;		/* These two should be changed together to get uc letters centered... */
    line-height: 0.75em;	/* Increasing by the same amount works fine??? */
		/* One also needs to change the vertical offsets of arrows from_*, and System-key icon */

    text-align: center;
    cursor: pointer;
    padding: 0.0em 0.0em 0.0em 0.0em;
    margin: 0.04em;
    white-space: nowrap;
    vertical-align: top;
    position: relative;

    background-color: #FFFFFF;

    background-image: -moz-linear-gradient(left,  rgba(0,0,0,0.2), rgba(64,64,64,0.2),  rgba(64,64,64,0.2),  rgba(128,128,128,0.2));
    background-image: -webkit-gradient(linear, left top, right top, color-stop(0%,rgba(0,0,0,0.2)), color-stop(33%,rgba(64,64,64,0.2)), color-stop(66%,rgba(64,64,64,0.2)), color-stop(100%,rgba(128,128,128,0.2)));
    background-image: -webkit-linear-gradient(left,  rgba(0,0,0,0.2) 0%, rgba(64,64,64,0.2) 33%, rgba(64,64,64,0.2) 66%, rgba(128,128,128,0.2) 100%);
    background-image: -o-linear-gradient(left,  rgba(0,0,0,0.2) 0%, rgba(64,64,64,0.2) 33%, rgba(64,64,64,0.2) 66%, rgba(128,128,128,0.2) 100%);
    background-image: -ms-linear-gradient(left,  rgba(0,0,0,0.2) 0%, rgba(64,64,64,0.2) 33%, rgba(64,64,64,0.2) 66%, rgba(128,128,128,0.2) 100%);
    background-image: linear-gradient(0deg,  rgba(0,0,0,0.2) 0%, rgba(64,64,64,0.2) 33%, rgba(64,64,64,0.2) 66%, rgba(128,128,128,0.2) 100%);
    filter: progid:DXImageTransform.Microsoft.gradient( startColorstr='#dddddd', endColorstr='#e5e5e5',GradientType=1 );

    border-top: solid 0.1em #CCC;
    border-right: solid 0.12em #AAA;
    border-bottom: solid 0.2em #999;
    border-left: solid 0.12em #BBB;
    -webkit-border-radius: 0.22em;
    -moz-border-radius: 0.22em;
    border-radius: 0.22em;
    z-index: 0;

    -webkit-box-shadow:
        0.03em 0.1em 0.1em 0.06em #888,
        0.05em 0.1em 0.06em 0.06em #aaa;
    -moz-box-shadow:
        0.03em 0.1em 0.1em 0.06em #888,
        0.05em 0.1em 0.06em 0.06em #aaa;
    box-shadow:
        0.03em 0.1em 0.1em 0.00em #888 ,
        0.05em 0.1em 0.06em 0.0em #aaa ;
}

kbd:hover, .klayout-wrapper:hover .klayout:not(:hover) kbd.shift {
    color: #222;
    background-image: -moz-linear-gradient(left,  rgba(128,128,128,0.2), rgba(192,192,192,0.2),  rgba(192,192,192,0.2),  rgba(255,255,255,0.2));
    background-image: -webkit-gradient(linear, left top, right top, color-stop(0%,rgba(128,128,128,0.2)), color-stop(33%,rgba(192,192,192,0.2)), color-stop(66%,rgba(192,192,192,0.2)), color-stop(100%,rgba(255,255,255,0.2)));
    background-image: -webkit-linear-gradient(left,  rgba(128,128,128,0.2) 0%, rgba(192,192,192,0.2) 33%, rgba(192,192,192,0.2) 66%, rgba(255,255,255,0.2) 100%);
    background-image: -o-linear-gradient(left,  rgba(128,128,128,0.2) 0%, rgba(192,192,192,0.2) 33%, rgba(192,192,192,0.2) 66%, rgba(255,255,255,0.2) 100%);
    background-image: -ms-linear-gradient(left,  rgba(128,128,128,0.2) 0%, rgba(192,192,192,0.2) 33%, rgba(192,192,192,0.2) 66%, rgba(255,255,255,0.2) 100%);
    background-image: linear-gradient(0deg,  rgba(128,128,128,0.2) 0%, rgba(192,192,192,0.2) 33%, rgba(192,192,192,0.2) 66%, rgba(255,255,255,0.2) 100%);
    filter: progid:DXImageTransform.Microsoft.gradient( startColorstr='#e5e5e5', endColorstr='#ffffff',GradientType=1 );
}
kbd:active, kbd.selected, .klayout-uc:hover:not(:active) .klayout:not(:hover) kbd.shift, .klayout-wrapper:active .klayout-uc:not(:hover) kbd.shift {
    margin-top: 0.14em;			/* This variant is with "solid" buttons, the commented one is with "rubber" ones */
    border-top: solid 0.10em #CCC;
    border-right: solid 0.12em #9a9a9a;	/* Make right/bottom a tiny way darker */
    border-bottom: solid 0.1em #8a8a8a;
    border-left: solid 0.12em #BBB;
/*    margin-top: 0.11em;
    border-top: solid 0.13em #999;
    border-right: solid 0.12em #BBB;
    border-bottom: solid 0.1em #CCC;
    border-left: solid 0.12em #AAA;	*/
    padding: 0.0em 0.0em 0.0em 0.0em;

    -webkit-box-shadow:
        0.05em 0.03em 0.1em 0.1em #aaa;
    -moz-box-shadow:
        0.05em 0.03em 0.1em 0.1em #aaa;
    box-shadow:
        0.05em 0.03em 0.1em 0em #aaa;

}
kbd img {
    padding-left: 0.25em;
    vertical-align: middle;
    height: 22px; width: 22px;
    opacity: 0.8;
}
kbd:hover img {
    opacity: 1;
}
kbd span.shrink {
    font-size: 85%;
}
.klayout.do-altgr kbd span.shrink.altgr {
    font-size: 72%;
}
kbd .small {
    font-size: 62%;
}
kbd .vsmall {
    font-size: 39%;
}

kbd .base, kbd .base-lc, kbd .base-uc {
    -webkit-touch-callout: none;
    -webkit-user-select: none;
    -khtml-user-select: none;
    -moz-user-select: none;
    -ms-user-select: none;
    -o-user-select: none;
    user-select: none;
}

/* Special rules for do-alt-display.  Without alt2, places the base on left and right;
	with alt2, places base on the left (unless base-right is present) */

/* .klayout.do-alt.uclc kbd span.lc, .klayout.do-alt.uclc kbd span.uc { */
.klayout.do-alt.uclc:not(.in-wrapper) kbd span.uc, .klayout.do-alt.uclc:not(.in-wrapper) kbd span.lc,
.klayout.do-alt.uclc:hover kbd span.uc, .klayout.do-alt.uclc:hover kbd span.lc,
	.klayout.do-alt.uclc.force kbd span.uc, .klayout.do-alt.uclc.force kbd span.lc,
	.klayout-wrapper:not(:hover) .klayout-uc .klayout.do-alt.uclc kbd span.uc,
	.klayout-wrapper:not(:hover) .klayout-uc .klayout.do-alt.uclc kbd span.lc {
   font-size: 85%;
}

.klayout.do-alt.sz125 kbd span.uc, .klayout.do-alt.sz125 kbd span.lc,	/* exclude below: too specific otherwise */
	.klayout.do-alt.sz125 kbd span:not(.lc):not(.uc):not(.base):not(.base-uc):not(.base-lc):not(.shrink):not(.small):not(.vsmall) {
   font-size: 125%;
   line-height: 0.98em;		/* decreasing this moves up; should be changed with padding-bottom */
   /* padding-bottom: 0.1em; */	/* Less makes _ not fit inside border... */
}
.klayout.do-alt.sz120 kbd span.uc, .klayout.do-alt.sz120 kbd span.lc,	/* exclude below: too specific otherwise */
	.klayout.do-alt.sz120 kbd span:not(.lc):not(.uc):not(.base):not(.base-uc):not(.base-lc):not(.shrink):not(.small):not(.vsmall) {
   font-size: 120%;
   line-height: 1.02em;		/* decreasing this moves up; should be changed with padding-bottom */
   /* padding-bottom: 0.1em; */	/* Less makes _ not fit inside border... */
}
.klayout.do-alt kbd span.uc, .klayout.do-alt kbd span.lc,	/* exclude below: too specific otherwise */
	.klayout.do-alt.sz115 kbd span.uc, .klayout.do-alt.sz115 kbd span.lc,
	.klayout.do-alt kbd span:not(.lc):not(.uc):not(.base):not(.base-uc):not(.base-lc):not(.shrink):not(.small):not(.vsmall),
  .klayout.do-alt.sz115 kbd span:not(.lc):not(.uc):not(.base):not(.base-uc):not(.base-lc):not(.shrink):not(.small):not(.vsmall) {
   font-size: 115%;
   line-height: 1.05em;		/* decreasing this moves up; should be changed with padding-bottom */
   /* padding-bottom: 0.1em; */	/* Less makes _ not fit inside border... */
}
.klayout.do-alt.sz110 kbd span.uc, .klayout.do-alt.sz110 kbd span.lc,	/* exclude below: too specific otherwise */
	.klayout.do-alt.sz110 kbd span:not(.lc):not(.uc):not(.base):not(.base-uc):not(.base-lc):not(.shrink):not(.small):not(.vsmall) {
   font-size: 110%;
   line-height: 1.12em;		/* decreasing this moves up; should be changed with padding-bottom */
   /* padding-bottom: 0.1em; */	/* Less makes _ not fit inside border... */
}
.klayout.do-alt.sz100 kbd span.uc, .klayout.do-alt.sz100 kbd span.lc,	/* exclude below: too specific otherwise */
	.klayout.do-alt.sz100 kbd span:not(.lc):not(.uc):not(.base):not(.base-uc):not(.base-lc):not(.shrink):not(.small):not(.vsmall) {
   line-height: 1.2em;		/* decreasing this moves up; should be changed with padding-bottom */
   /* padding-bottom: 0.1em; */	/* Less makes _ not fit inside border... */
}

.klayout.do-alt kbd span.base-lc, .klayout.do-alt kbd span.base-uc {
    font-size: 90%;
}
.klayout.do-alt.alt2 kbd span.base-lc, .klayout.do-alt.alt2 kbd span.base-uc {
    font-size: 80%;
}

.klayout.do-alt kbd span.base-uc {
    right: 15%;
    top: 35%;		/* Combine rel-parent and rel-us offsets : */
}
.klayout.do-alt kbd span.base-lc {
    left: 15%;
    bottom: 25%;		/* Combine rel-parent and rel-us offsets : */
}
.klayout.do-alt.alt2 kbd span.base-uc {
    left: 35%;
    top: 30%;		/* Combine rel-parent and rel-us offsets : */
}
.klayout.do-alt.alt2 kbd span.base-lc {
    left: 15%;
    bottom: 25%;		/* Combine rel-parent and rel-us offsets : */
}
.klayout.do-alt.alt2.base-right kbd span.base-uc {
    right: 15%;
    left: auto;		/* Combine rel-parent and rel-us offsets : */
}
.klayout.do-alt.alt2.base-right kbd span.base-lc {
    right: 35%;
    left: auto;		/* Combine rel-parent and rel-us offsets : */
}
.klayout.do-alt.alt2.base-center kbd span.base-uc {
    left: 60%;		/* Combine rel-parent and rel-us offsets : */
}
.klayout.do-alt.alt2.base-center kbd span.base-lc {
    left: 40%;		/* Combine rel-parent and rel-us offsets : */
}

.klayout.do-alt kbd span.base {
    font-size: 120%;
    left: 25%;
    top: 65%;		/* Combine rel-parent and rel-us offsets : */
}
.klayout.do-alt.large-base.large-base kbd span.base {	/* Make .large-base override .alt2 */
    font-size: 200%;
    left: 50%;
    top: 50%;		/* Combine rel-parent and rel-us offsets : */
}
.klayout.do-alt.alt2 kbd span.base {
    font-size: 110%;
    left: 25%;
    top: 75%;		/* Combine rel-parent and rel-us offsets : */
}
.klayout.do-alt.alt2.base-right kbd span.base {
    right: 25%;
    left: auto;		/* Combine rel-parent and rel-us offsets : */
}
.klayout.do-alt.alt2.base-center kbd span.base {
    left: 50%;		/* Combine rel-parent and rel-us offsets : */
}
.klayout.do-alt kbd span.base, .klayout.do-alt kbd span.base-lc, .klayout.do-alt kbd span.base-uc {
    position: absolute;
    z-index: -1;

    opacity: 0.25;
    filter: alpha(opacity=25); /* IE6-IE8 */

    color: blue;
    line-height: 1em;	/* Tight-fitting box */
    height: 1em;
    width: 1em;
    margin: -0.5em -0.5em -0.5em -0.5em;	/* -0.5em is the geometric center */
}
.klayout.do-alt kbd {
    min-height: 1.2em;		/* Should be changed together to get uc letters centered... */
    line-height: 1.2em;	/* Increasing by the same amount works fine??? */
}
.klayout.do-altgr span.altgr {outline: 9px dotted green;} 

kbd.with_x-NONONO:before {
    position: absolute;
    z-index: -10;

    opacity: 0.25;
    filter: alpha(opacity=25); /* IE6-IE8 */

    content: "✖";
    color: red;
    font-size: 120%;

    line-height: 1em;	/* Tight-fitting box */
    height: 1em;
    width: 1em;

    top: 50%;		/* Combine rel-parent and rel-us offsets : */
    left: 50%;
    margin: -0.43em 0 0 -0.5em;	/* -0.5em is the geometric center; but it is not in the center of ✖...*/
}
kbd.from_sw:after, kbd.from_ne:after, kbd.from_nw:after, kbd.to_ne:after, kbd.to_nw:before, kbd.to_w:after, kbd.from_w:after {
    position: absolute;
    z-index: 1;
    font-size: 80%;
    color: red;
    text-shadow: 1px 1px #ffff88, -1px -1px #ffff88, -1px 1px #ffff88, 1px -1px #ffff88;
    text-shadow: 1px 1px rgba(255,255,0,0.3), -1px -1px rgba(255,255,0,0.3), -1px 1px rgba(255,255,0,0.3), 1px -1px rgba(255,255,0,0.3);
}
kbd.from_sw.grn:after, kbd.from_ne.grn:after, kbd.from_nw.grn:after, kbd.to_ne.grn:after, kbd.to_nw.grn:before, kbd.to_w.grn:after, kbd.from_w.grn:after {
    color: green;
}
kbd.from_sw.blu:after, kbd.from_ne.blu:after, kbd.from_nw.blu:after, kbd.to_ne.blu:after, kbd.to_nw.blu:before, kbd.to_w.blu:after, kbd.from_w.blu:after {
    color: blue;
}
kbd.from_sw.ylw:after, kbd.from_ne.ylw:after, kbd.from_nw.ylw:after, kbd.to_ne.ylw:after, kbd.to_nw.ylw:before, kbd.to_w.ylw:after, kbd.from_w.ylw:after {
    color: #FFB400;
}
kbd.from_sw:not(.pure), kbd.xfrom_sw, kbd.from_ne:not(.pure), kbd.from_nw:not(.pure), kbd.to_ne:not(.pure), kbd.to_nw:not(.pure) {
    text-shadow: 1px 1px yellow, -1px -1px yellow, -1px 1px yellow, 1px -1px yellow;
}
kbd.from_sw:after {
    left: -0.0em;
    bottom:  -0.65em;
}
kbd.from_sw:after, kbd.to_ne:after {
    content: "⇗";
}
kbd.from_se:after, kbd.to_nw:before {
    content: "⇖";
}
kbd.from_ne:after, kbd.from_nw:after {
    top:  -0.55em;
}
kbd.to_ne:after, kbd.to_nw:before {    top:  -0.85em;}
kbd.to_nw:before {    left:  0.01em;}
kbd.from_ne:after { content: "⇙"; }
kbd.from_ne:after, kbd.to_ne:after { right: -0.0em; }
kbd.from_nw:after { content: "⇘"; left: -0.0em; }
kbd.to_w:after, kbd.from_w:after {
    top:  45%;
    left: -0.7em;
}
kbd.to_w.high:after, kbd.from_w.high:after {
    top:  -15%;
    left: -0.5em;
}
kbd.to_w:after { content: "⇐"; }
kbd.from_w:after { content: "⇒"; }

/* Compensate for higher keys */
.klayout.do-alt kbd.from_sw:after {
    bottom: -0.90em;
}
.klayout.do-alt kbd.from_ne:after, .klayout.do-alt kbd.from_nw:after {
    top:  -0.85em;
}

span.prefix {
    color: yellow;
    text-shadow: 1px 1px black, -1px -1px black, -1px 1px black, 1px -1px black;
}
span.prefix.prefix2 {
    text-shadow: 1px 1px black, -1px -1px black, -1px 1px black, 1px -1px black,
    		 3px 0px firebrick, -3px 0px firebrick, 0px 3px firebrick, 0px -3px firebrick;
}
span.very-special {
    text-shadow: 1px 1px lime, -1px -1px lime, -1px 1px lime, 1px -1px lime;
}
span.special {
    text-shadow: 2px 2px dodgerblue, -2px -2px dodgerblue, -2px 2px dodgerblue, 2px -2px dodgerblue;
}
.thinspecial span.special {
    text-shadow: 1px 1px dodgerblue, -1px -1px dodgerblue, -1px 1px dodgerblue, 1px -1px dodgerblue;
}
span.not-surr:not(.prefix) {
    text-shadow: 2px 2px white, -2px -2px white, -2px 2px white, 2px -2px white;
}
span.need-learn {
    text-shadow: 1px 1px coral, -1px -1px coral, -1px 1px coral, 1px -1px coral;
}
span.need-learn.on-right {
    text-shadow: 1px 1px black, -1px -1px black, -1px 1px black, 1px -1px black,
		 2px 2px coral, -2px -2px coral, -2px 2px coral, 2px -2px coral;
}
span.may-guess {
    text-shadow: 1px 1px yellow, -1px -1px yellow, -1px 1px yellow, 1px -1px yellow;
}

kbd.win_logo.ubuntu:before {
    content: url(http://linux.bihlman.com/wp-content/plugins/wp-useragent/img/24/os/ubuntu-2.png);
}
kbd.win_logo:before {
    position: absolute;
    z-index: -10;

    content: url(40px-computer_glenn_rolla_01.svg.med.png);
    height: 100%;
    width: 100%;

    top: 0%;		/* Combine rel-parent and rel-us offsets : */
    left: 0%;
/*    margin: -0.5em -0.5em -0.5em -0.5em; */	/* -0.5em is the geometric center */
}
.do-alt kbd.win_logo:before {	/* How to vcenter automatically??? */
    top: 20%;
}

/* Mark vowel's diagonals (for layout of diacritics) */
.ddiag .arow > kbd:nth-of-type(2),		.ddiag .arow > kbd:nth-last-of-type(7),
   .diag .arow > kbd:nth-of-type(2),		.diag .arow > kbd:nth-of-type(7),
   .diag .drow > kbd:nth-of-type(2),		.diag .drow > kbd:nth-of-type(7),
   .diag .arow > kbd:nth-of-type(10),		.diag .drow > kbd:nth-of-type(10),	kbd.red-bg
				{ background-color: #ffcccc; }
.ddiag .arow > kbd:nth-last-of-type(6),	.ddiag .arow > kbd:nth-of-type(4),
   .diag .arow > kbd:nth-of-type(8),	.diag .arow > kbd:nth-of-type(3),
   .diag .drow > kbd:nth-of-type(8),	.diag .drow > kbd:nth-of-type(3),		kbd.green-bg
				{ background-color: #ccffcc; }
.ddiag .arow > kbd:nth-last-of-type(8),	.ddiag .arow > kbd:nth-last-of-type(5),
  .diag .arow > kbd:nth-of-type(9),	.diag .arow > kbd:nth-of-type(4),
  .diag .drow > kbd:nth-of-type(9),	.diag .drow > kbd:nth-of-type(4),		kbd.blue-bg
				{ background-color: #ccccff; }

/* Mark non-vowel's diagonals (for layout of diacritics) */
.hide45end .arow > kbd:nth-of-type(5),		.hide45end .arow > kbd:nth-of-type(6),
   .hide45end .arow > kbd:nth-of-type(11),
   .hide45end .drow > kbd:nth-of-type(5),		.hide45end .drow > kbd:nth-of-type(6),
   .hide45end .drow > kbd:nth-of-type(11),	kbd.semi-hidden
				{ opacity: 0.45; }

span.vbell		{ color: SandyBrown; }
span.three-cases	{ outline: 3px dotted yellow; }
span.three-cases-long	{ outline: 3px dotted MediumSpringGreen; }

span.withSubst	{ outline: 1px dotted blue;  outline-offset: -1px; }
span.isSubst		{ outline: 1px solid blue;  outline-offset: -1px; }
  
.use-operator span.operator		{ background-color: rgb(255,192,203)	/*pink*/; }
span.relation		{ background-color: rgb(255,160,122)	/*lightsalmon*/; }
span.ipa		{ background-color: rgb(173,255,47)	/*greenyellow*/; }
span.nAry		{ background-color: rgb(144,238,144)	/*lightgreen*/; }
span.paleo		{ background-color: rgb(240,230,140)	/*Khaki*/; }
.use-viet span.viet		{ background-color: rgb(220,220,220)	/*Gainsboro*/; }
div:not(.no-doubleaccent) span.doubleaccent	{ background-color: rgb(255,228,196)	/*Bisque*/; }
span.ZW		{ background-color: rgb(220,20,60)	/*crimson*/; }
span.WS		{ background-color: rgb(128,0,0)	/*maroon*/; }

.use-operator span.operator		{ background-color: rgba(255,192,203,0.5)	/*pink*/; }
span.relation		{ background-color: rgba(255,160,122,0.5)	/*lightsalmon*/; }
span.ipa		{ background-color: rgba(173,255,47,0.5)	/*greenyellow*/; }
span.nAry		{ background-color: rgba(144,238,144,0.5)	/*lightgreen*/; }
span.paleo		{ background-color: rgba(240,230,140,0.5)	/*Khaki*/; }
.use-viet span.viet		{ background-color: rgba(220,220,220,0.5)	/*Gainsboro*/; }
div:not(.no-doubleaccent) span.doubleaccent	{ background-color: rgba(255,228,196,0.5)	/*Bisque*/; }
span.ZW		{ background-color: rgba(220,20,60,0.5)		/*crimson*/; }
span.WS		{ background-color: rgba(128,0,0,0.5)		/*maroon*/; }

span.lFILL[convention]:before		{ content: attr(convention); 
					  color: white; 
					  font-size: 50%; }

span.lFILL:not([convention])	{ margin: 0ex 0.35ex; }
span.l-NONONO		{ margin: 0ex 0.06ex; }
span.yyy		{ padding: 0px !important; }

div.rtl-hover:hover div:not(:hover) kbd span:not(.no-mirror-rtl):not(.base):not(.base-uc):not(.base-lc) { direction: rtl; }

div.zero { position: relative;}
div.zero div.over-shift { position: absolute; height: 1.13em; z-order: 999;}
/* div.zero div.over-shift { outline: 3px dotted yellow;} */
.do-alt + div.zero div.over-shift { height: 1.5em; }
div.zero.l div.over-shift { left: 0.04pt; width: 4.24em;}
div.zero.r div.over-shift { left: 21.12em; width: 3.56em;}	/* (1.72em - 0.04em) × 10 + 4.24em + 0.08 */
div.zero.tp div.over-shift { top: 7.8em;}
.over-shift-outline div.zero.btm div.over-shift { outline: 3px dotted blue;}
div.zero.btm div.over-shift { bottom: 1.13em;}
.do-alt + div.zero.btm div.over-shift { bottom: 1.5em;}
/* div.zero:hover { outline: 6px dotted yellow;} */

EOR

sub apply_filter_div ($$;$) {
  my($self, $txt, $opt) = (shift, shift, shift || {});
  $txt =~ s(^(<div\b[^>]*\skbd_rebuild="([^""]*?)"[^'">]*>).*?^(</div)\b)
  	   ( $1 . ($opt->{fake} ? $rebuild_fake : $self->html_keyboard_diagram("$2", $opt)) . $3 )msge;
  $txt;
}
sub apply_filter_style ($$;$) {
  my($self, $txt, $opt) = (shift, shift, shift || {});
  $txt =~ s(^(\s*/\*\s*START\s+auto-generated\s+style\s*\*/).*?(/\*\s*END\s+auto-generated\s+style\s*\*/))
  	   ( $1 . ($opt->{fake} ? $rebuild_fake : $rebuild_style) . $2 )msge;
  $txt;
}

my @HTML_KBD_FIXED = ('

<span class=drow>',
	   '<kbd style="width: 2.4em"><span class=vsmall>Backspace</span></kbd><kbd class=hidden-align></kbd></span>

<br><span class=arow><kbd style="width: 2.4em">Tab</kbd>',
	   '</span>

<br><span class=arow><kbd style="width: 3em"><span class=small>CapsLock</span></kbd>',
	   '<kbd style="width: 2.52em"><span class=shrink>Enter</span></kbd></span>

<br><span class=arow><kbd style="width: 4em" class="shift">Shift</kbd>',
	   '<kbd style="width: 3.24em" class="shift">Shift</kbd></span>

<br><span class=srow><kbd style="width: 2.5em">Ctrl</kbd><kbd class=win_logo></kbd><kbd style="width: 2em">Alt</kbd>', 
	   '<kbd style="width: 7.68em"></kbd><kbd style="width: 2.4em"><span class="shrink altgr">AltGr</span></kbd><kbd style="width: 2.5em">Menu</kbd><kbd style="width: 2.5em">Ctrl</kbd></span>

');

sub classes_by_chars ($$$$$$$$$$) {
  my ($self, $h_classes, $opt, $layer, $lc0, $uc0, $lc, $uc, $k_base, $k, %cl) = 
       (shift, shift, shift, shift, shift, shift, shift, shift, shift, shift);
  for my $L ('', $layer) {
    for my $c (grep defined, $lc0, $uc0) {
      $cl{$_}++ for @{ $h_classes->{"$k_base$L"}{$c} };		# k	for key-based-on-background char
      for my $o (@$opt) {
        $cl{$_}++ for @{ $h_classes->{"$k_base$L=$o"}{$c} }	# k=opt	for key-based-on-background char
      }
    }
    for my $c (grep defined, $lc, $uc) {
      $cl{$_}++ for @{ $h_classes->{"$k$L"}{$c} };		# K	for key-based-on-foreground char
      for my $o (@$opt) {
        $cl{$_}++ for @{ $h_classes->{"$k$L=$o"}{$c} }	# K=opt	for key-based-on-background char
      }
    }
  }
  keys %cl;
}

sub apply_kmap($$$) {
  my ($self, $kmap, $c) = (shift, shift, shift);
  return $c unless $kmap;
  $c = $c->[0] if ref $c;
  return $c unless defined ($c = $kmap->{$self->key2hex($c)});
  return chr hex $c unless ref $c;
  $c = [@$c];			# deep copy
  $c->[0] = chr hex $c->[0];
  $c;
}

sub do_keys ($$$@) {		# calculate classes related to the “whole key”, and emit the “content” of the key
  my ($self, $opt, $base, $out, $lc0, $uc0, %c_classes) = (shift, shift, 1, '');
  for my $in (@_) {
    my ($lc, $uc, $f, $kmap, $layerN, $h_classes, $name, @classes) = @$in;
    $kmap and $_ = $self->apply_kmap($kmap, $_) for ($lc, $uc);
    ref and $_ = $_->[0] for $lc, $uc;
    ($lc0, $uc0) = ($lc, $uc), $base = 0 if $base;
    # k/K	for key-based-on-(background/foreground) char;	k=opt/K=opt	likewise
    $c_classes{$_}++ for $self->classes_by_chars($h_classes, $opt, $layerN, $lc0, $uc0, $lc, $uc, 'k', 'K');
  }
  my @extra = sort keys %c_classes;
  my $q = ("@extra" =~ /\s/ ? '"' : '');
  my $cl = @extra ? " class=$q@extra$q" : '';
#  push @extra, 'from_se' if $k[0][0] =~ /---/i;	# lc, uc, $h_classes, name, classes:
  join '', $out, "<kbd$cl>", (map $self->a_pair($opt, $lc0, $uc0, $self->apply_kmap($_->[3], $_->[0]),
  								  $self->apply_kmap($_->[3], $_->[1]),
  						$_->[2], $_->[4], $_->[5], $_->[6], [@$_[7..$#$_]]), @_), '</kbd>'
}

sub h($)  { (my $c = shift) =~ s/([&<>])/$html_esc{$1}/g; $c }
sub tags_by_rx {
  my ($c, @o) = shift;
  die "Need odd number of arguments" if @_ & 1;
  while (@_) {
    my $tag = shift;
    push @o, $tag if $c =~ shift;
  }
  return @o;
}

sub a_pair ($$$$$$$$$$;@) {
  my($self, $opts, $lc0, $uc0, $LC, $UC, $F, $layerN, $h_classes, $name, $extra) = 
  (shift, shift, shift, shift, shift, shift, shift, shift, shift, shift, shift || []);
#  warn "See lc prefix    $LC->[0]  " if ref $LC and $LC->[2];
  my ($lc1, $uc1) = map {(defined and ref()) ? $_->[0] : $_} $LC, $UC;

  $extra = [@$extra];
  my $e = @$extra;

  my ($lc, $uc) = map {defined() ? $_ : '♪'} $lc1, $uc1;
#  return join '', map {defined() ? $_ : ''} $lc, $uc;

  my $opt = { map {($_, 1)} @$opts };
  my $base = (($name || '') eq 'base');
  my $prefix2 = (ref($LC) and ref($UC) and $LC->[2] and $UC->[2] && $uc eq $lc);
  if ($prefix2 or ($uc eq ucfirst $lc and $lc eq lc $uc and $lc ne 'ß' and defined($lc1) == defined($uc1))) {
    if ($uc ne $lc) {
      ref and $_->[2] and die "Do not expect a character `$_->[0]' to be a deadkey..." for $LC, $UC;
    }
    my @pref_i = map { ref $_ and (3 == ($_->[2] || 0) or (3 << 3) == ($_->[2] || 0)) } $LC, $UC;
    $prefix2 and $pref_i[1] and not $pref_i[0] and unshift @$extra, 'prefix2';
    $LC and ref $LC and $LC->[2] and unshift @$extra, 'prefix';
    push @$extra, $self->classes_by_chars($h_classes, $opts, $layerN, $lc0, undef, $lc1, undef, 'c', 'C');
#    unshift @$extra, tags_by_rx $lc,	'need-learn'	=> ($opt->{cyr} ? qr/N-A/i : qr/[ϝϙϲͻϿϾͲ℧ϗ]N-A/i);
#    push @$extra, 'vbell' unless defined $lc1;
    push @$extra, (1 < length uc $lc1 ? 'three-cases-long' : 'three-cases') 
      if defined $lc1 and uc $lc1 ne ucfirst $lc1;
    push @$extra, $name if $name;
    my $q = ("@$extra" =~ /\s/ ? '"' : '');
    @$extra = sort @$extra;
    my $cl = @$extra ? " class=$q@$extra$q" : '';
    $base ? "<span$cl>" . h($uc) . "</span>" : $self->char_2_html_span(undef, $UC, $uc, $F, {}, @$extra)
#    "<span$cl>" . $out . "</span>";
  } else {
    my (@e_lc, @e_uc);
    my @do = ([$lc, [], 'lc', $LC, $lc0, $lc1], [$uc, [], 'uc', $UC, $uc0, $uc1]);
#    warn "See lc prefix    $LC->[0]  " if ref $LC and $LC->[2];
    $_->[3] and ref $_->[3] and $_->[3][2] and push @{$_->[1]}, 'prefix' for @do;
    $_->[3] and ref $_->[3] and (3 == ($_->[3][2] || 0) or (3 << 3) == ($_->[3][2] || 0)) and push @{$_->[1]}, 'prefix2' for @do;
    push @{$_->[1]}, $self->classes_by_chars($h_classes, $opts, $layerN, $_->[4], undef, $_->[5], undef, 'c', 'C'),
    		     tags_by_rx $_->[0],	'not-surr' => qr/[„‚“‘”’«‹»›‐–—―‒‑‵‶‷′″‴⁗〃´]/i			# white
    	for @do;
    push @{$_->[1]}, 'vbell' for grep !defined $_->[5], @do;
    join '', map {
       push @{$_->[1]}, ($name ? "$name-$_->[2]" : $_->[2]);
       my $ee = [sort @$extra, @{$_->[1]}];
       my $q = ("@$ee" =~ /\s/) ? '"' : '';
       my $o = ($base	? "<span class=$q@$ee$q>" . h($_->[0]) . "</span>" 
       			: $self->char_2_html_span(undef, $_->[3], $_->[0], $F, {}, @$ee));
#       "<span class=$q@$e$j$_->[2]$q>$o</span>";
      } @do;
  }
}

my $kbdrow = 0;
sub keys2html_diagram ($$$$@) {
  my ($self, $opts, $cnt, $new_row) = (shift, shift, shift, shift);
  my %opts = map { /^\w+=/ ? split /=/, $_, 2 : ($_, 1)} @$opts;
  my $off = (($opts{oneRow} && $kbdrow++) || 0) % 3;
  $off = "\xA0" x (2*$off);
  my @fixed = ($opts{oneRow} ? ("<span class=arow>$off") : @HTML_KBD_FIXED);
  my $out = shift @fixed;
#  $cnt = $#{$layers_info->[0]} if $cnt > $#{$layers_info->[0]};
  my @keys = (0..($cnt-1));
  my $start = ($opts{startKey} || 0) % $cnt;
  my $CNT = $opts{cntKeys} || $cnt;
  @keys = (@keys) x ( 1 + int( ($start+$CNT-1)/$cnt ) );
  @keys = @keys[$start .. ($start + $CNT - 1)];
 KEY:
  for my $kn (@keys) {			# Ordinal of keyboard's key
    $out .= (shift(@fixed) || '') if $new_row->{$kn};
    my ($symb, @keys, $last) = 0;
    for my $KK (@_) {			# Layers
      my($layer, @rest) = @$KK;		# rest = face, kmap, layerN, class_hash, name, classes
      push @keys, [@{$layer->[$kn]}[0,1], @rest];
    }
    $out .= $self->do_keys($opts, @keys);
  }
  $out .= join '', @fixed;
  $out .= "</span\n>" if $opts{oneRow};
  $out
}

sub html_keyboard_diagram ($$$) {
  my($self, $OPT, $global_opt, @opt, @layers, $face0, $is_layer) = (shift, shift, shift);
  my %tr = qw(l 0 c 1 h 2);
  for my $arg (split /\s+/, $OPT) {
    push(@opt, $arg), next if $arg =~ s(^/opt=)();	# BELOW: `base' becomes NAME, `on-right' becomes CLASSES
    die "unrecognized `rebuild' option: `$arg'" 	#  +=l,0,0           +base=l,0,0 +=l,0,1	 +=l,ƒ,0	 on-right+=c,0,1
      unless my($classes, $name, $f, $prefix, $which) = ( $arg =~ m{^((?:[-\w]+(?:,[-\w]+)*)?)\+([-\w]*)=(\w+),([\da-f]{4}|[^\x20-\x7e][^,]*|[02]?),(\d+|-)$}i );
    $f = $self->{face_shortcuts}{$f} if exists $self->{face_shortcuts}{$f};
    $face0 ||= $f unless $which eq '-';
    $prefix =~ s/◌(?=\p{NonspacingMark})//g;
    $prefix = $self->charhex2key($prefix);
    my $L = ($which eq '-' and $which = 0, [$f]);
    warn "unknown layer $L->[0]" if $L and not $self->{layers}{$L->[$which]};
    die "html_keyboard_diagram(): unknown face `$f'" 
      unless $L ||= ($self->{faces}{$f}{layers} or $self->export_layers($f, $f));
    my $kmap = $self->{faces}{$f}{'[deadkeyFaceHexMap]'}{$self->key2hex($prefix)} 
      or not length $prefix or die "output_html_keyboard_diagram(): Unknown prefix key `$prefix' for face $f";
    # create_composite_layers() translates 0000 key to ''
#	warn "I see HTML_classes for face=$f, prefix=`$prefix'" if $self->{faces}{$f}{'[HTML_classes]'}{length $prefix ? $self->key2hex($prefix) : ''};
    my $h_classes = $self->{faces}{$f}{'[HTML_classes]'}{length $prefix ? $self->key2hex($prefix) : ''} || {};
    push(@layers, [$self->{layers}{$L->[$which]}, $f, $kmap, $which, $h_classes, $name, split /,/, $classes]);
  }
  die "there must be exactly one /opt= argument in <<$OPT>>" unless @opt == 1;
  my $opt = [split /,/, $opt[0], -1];
  my ($cnt, @g, %new_row) = (0, @{ $self->{faces}{$face0}{'[geometry]'} || [] });	# keep only 1 from the last row
  @g or die "Face `$face0' has no associated layer with geometry info; did you set geometry_via_layer?";
  pop @g;
  $new_row{ $cnt += $_ }++ for @g;
  my ($pre, $post) = ('', '');
  ($pre, $post) = ("\n<div>", "</div>\nHover mouse here to see how characters look in RTL context.\n") 
    if grep /^rtl-hover(-Trivia)?$/, @$opt;
  $post .= "  <b>Trivia:</b> note <a href=http://en.wikipedia.org/wiki/Mapping_of_Unicode_characters#Bidirectional_Neutral_Formatting>mirroring</a> of <code>&lt;{[()]}&gt;</code>." if grep /^rtl-hover-Trivia$/, @$opt;
  $pre . $self->keys2html_diagram($opt, $cnt+1, \%new_row, @layers) . $post;
}


# These preloaded symbols are enough to cover single-UTF-16 bindings in .Compose (except circled katakana/hangul)
my @enc_dotcompose;	# Have many-to-1, inverting hash would lose info; Do not distinguish Left/leftarrow etc.
{  no warnings 'qw';
   @enc_dotcompose = (qw#
		  ` grave
		  ' apostrophe
		  " quotedbl
		  ~ asciitilde
		  ! exclam
		  ? question
		  @ at
	     #,				# `
	     qw!
		  # numbersign
		  $ dollar
		  % percent
		  ^ asciicircum
		  & ampersand
		  * asterisk
		  ( parenleft
		  ) parenright
		  [ bracketleft
		  ] bracketright
		  { braceleft
		  } braceright
		  - minus
		  + plus
		  = equal
		  _ underscore
		  < less
		  > greater
		  \ backslash
		  / slash
		  | bar
		  , comma
		  . period
		  : colon
		  ; semicolon
		  _bar underbar


¡	exclamdown
¢	cent
£	sterling
¤	currency
¥	yen
¦	brokenbar
§	section
¨	diaeresis
©	copyright
ª	ordfeminine
«	guillemotleft
¬	notsign
­	hyphen
®	registered
¯	macron
°	degree
±	plusminus
²	twosuperior
³	threesuperior
´	acute
µ	mu
¶	paragraph
·	periodcentered
¸	cedilla
¹	onesuperior
º	masculine
»	guillemotright
¼	onequarter
½	onehalf
¾	threequarters
¿	questiondown
À	Agrave
Á	Aacute
Â	Acircumflex
Ã	Atilde
Ä	Adiaeresis
Å	Aring
Æ	AE
Ç	Ccedilla
È	Egrave
É	Eacute
Ê	Ecircumflex
Ë	Ediaeresis
Ì	Igrave
Í	Iacute
Î	Icircumflex
Ï	Idiaeresis
Ð	ETH
Ð	Eth
Ñ	Ntilde
Ò	Ograve
Ó	Oacute
Ô	Ocircumflex
Õ	Otilde
Ö	Odiaeresis
×	multiply
Ø	Oslash
Ø	Ooblique
Ù	Ugrave
Ú	Uacute
Û	Ucircumflex
Ü	Udiaeresis
Ý	Yacute
Þ	THORN
Þ	Thorn
ß	ssharp
à	agrave
á	aacute
â	acircumflex
ã	atilde
ä	adiaeresis
å	aring
æ	ae
ç	ccedilla
è	egrave
é	eacute
ê	ecircumflex
ë	ediaeresis
ì	igrave
í	iacute
î	icircumflex
ï	idiaeresis
ð	eth
ñ	ntilde
ò	ograve
ó	oacute
ô	ocircumflex
õ	otilde
ö	odiaeresis
÷	division
ø	oslash
ø	ooblique
ù	ugrave
ú	uacute
û	ucircumflex
ü	udiaeresis
ý	yacute
þ	thorn
ÿ	ydiaeresis

Cyr_ђ	Serbian_dje
ѓ	Macedonia_gje
є	Ukrainian_ie
Cyr_ѕ	Macedonia_dse
Cyr_і	Ukrainian_i
Cyr_ї	Ukrainian_yi
Cyr_ћ	Serbian_tshe
Cyr_ќ	Macedonia_kje
ґ	Ukrainian_ghe_with_upturn
Cyr_ў	Byelorussian_shortu
№	numerosign
Cyr_Ђ	Serbian_DJE
Ѓ	Macedonia_GJE
Є	Ukrainian_IE
Cyr_Ѕ	Macedonia_DSE
Cyr_І	Ukrainian_I
Cyr_Ї	Ukrainian_YI
Cyr_Ћ	Serbian_TSHE
Cyr_Ќ	Macedonia_KJE
Ґ	Ukrainian_GHE_WITH_UPTURN
Cyr_Ў	Byelorussian_SHORTU

	’sq	rightsinglequotemark
	‘sq	leftsinglequotemark
	•	enfilledcircbullet
	♀	femalesymbol
	♂	malesymbol
	NBSP	nobreakspace
	…	ellipsis
	∩#	intersection
	∫	integral
	≤	lessthanequal
	≥	greaterthanequal

	d`	dead_grave
	d'	dead_acute
	d^	dead_circumflex
	d~	dead_tilde
	d¯	dead_macron
	dd#	dead_breve----
	d^.	dead_abovedot
	d"	dead_diaeresis
	d^°	dead_abovering
	d''	dead_doubleacute
	d^v	dead_caron
	d,	dead_cedilla
	dd#	dead_ogonek---
	d_ι	dead_iota
	d_voiced	dead_voiced_sound
	d_½voiced	dead_semivoiced_sound
	d.	dead_belowdot
	dd#	dead_hook---
	dd#	dead_horn---
	d/	dead_stroke
	d^,	dead_abovecomma
	dd#	dead_abovereversedcomma---
	d``	dead_doublegrave
	d``#	dead_double_grave
	d_°	dead_belowring
	d__	dead_belowmacron
	dd#	dead_belowcircumflex---
	d_~	dead_belowtilde
	dd#	dead_belowbreve---
	d_"	dead_belowdiaeresis
	d_invbrev	dead_invertedbreve
	d_inv_brev	dead_inverted_breve
	d_,	dead_belowcomma
	dd#	dead_currency

	d^(	dead_dasia
	d^)	dead_psili

Ś	Sacute
Š	Scaron
Ş	Scedilla
Ť	Tcaron
Ź	Zacute
Ž	Zcaron
Ż	Zabovedot
ą	aogonek
˛	ogonek
ł	lstroke
ľ	lcaron
ś	sacute
ˇ	caron
š	scaron
ş	scedilla
ť	tcaron
ź	zacute
˝	doubleacute
ž	zcaron
ż	zabovedot
Ŕ	Racute
Ă	Abreve
Ĺ	Lacute
Ć	Cacute
Č	Ccaron
Ę	Eogonek
Ě	Ecaron
Ď	Dcaron
Đ	Dstroke
Ń	Nacute
Ň	Ncaron
Ő	Odoubleacute
Ř	Rcaron
Ů	Uring
Ű	Udoubleacute
Ţ	Tcedilla
ŕ	racute
ă	abreve
ĺ	lacute
ć	cacute
č	ccaron
ę	eogonek
ě	ecaron
ď	dcaron
đ	dstroke
ń	nacute
ň	ncaron
ő	odoubleacute
ř	rcaron
ů	uring
ű	udoubleacute
ţ	tcedilla
˙	abovedot

Ŗ	Rcedilla
Ĩ	Itilde
Ļ	Lcedilla
Ē	Emacron
Ģ	Gcedilla
Ŧ	Tslash
ŗ	rcedilla
ĩ	itilde
ļ	lcedilla
ē	emacron
ģ	gcedilla
ŧ	tslash
Ŋ	ENG
ŋ	eng
Ā	Amacron
Į	Iogonek
Ė	Eabovedot
Ī	Imacron
Ņ	Ncedilla
Ō	Omacron
Ķ	Kcedilla
Ų	Uogonek
Ũ	Utilde
Ū	Umacron
ā	amacron
į	iogonek
ė	eabovedot
ī	imacron
ņ	ncedilla
ō	omacron
ķ	kcedilla
ų	uogonek
ũ	utilde
ū	umacron

Ơ	Ohorn
ơ	ohorn
Ư	Uhorn
ư	uhorn

<	leftcaret
>	rightcaret
∨	downcaret
∧	upcaret
¯	overbar
⊤	downtack
∩	upshoe
⌊	downstile
_	underbar
∘	jot
⎕	quad
⊥	uptack
○	circle
⌈	upstile
∪	downshoe
⊃	rightshoe
⊂	leftshoe
⊣	lefttack
⊢	righttack

≤	lessthanequal
≠	notequal
≥	greaterthanequal
∫	integral
∴	therefore
∝	variation
∞	infinity
∇	nabla
∼	approximate
≃	similarequal
⇔	ifonlyif
⇒	implies
≡	identical
√	radical
⊂	includedin
⊃	includes
∩	intersection
∪	union
∧	logicaland
∨	logicalor
∂	partialderivative
ƒ	function
←	leftarrow
↑	uparrow
→	rightarrow
↓	downarrow
◆	soliddiamond
▒	checkerboard

		  CP Multi_key

+# KP_Add
-# KP_Subtract
*# KP_Multiply
/# KP_Divide
.# KP_Decimal
=# KP_Equal
SPC#	KP_Space

		  ← Left → Right ↑ Up ↓ Down
	     !, map {("$_#", "KP_$_")} 0..9);
} # `

my %dec_dotcompose = reverse @enc_dotcompose;
# perl -C31 -wne "/^(.)\tCyrillic_(\w+)/ and print qq($2 $1 )" oooo3 >oooo-cyr
# perl -C31 -wne "/^(.)\thebrew_(\w+)/ and print qq($2 $1 )" oooo3 >oooo-heb
my %cyr = qw( GHE_bar Ғ ghe_bar ғ ZHE_descender Җ zhe_descender җ KA_descender Қ ka_descender қ KA_vertstroke Ҝ ka_vertstroke ҝ
	      EN_descender Ң en_descender ң U_straight Ү u_straight ү U_straight_bar Ұ u_straight_bar ұ HA_descender Ҳ
	      ha_descender ҳ CHE_descender Ҷ che_descender ҷ CHE_vertstroke Ҹ che_vertstroke ҹ SHHA Һ shha һ SCHWA Ә schwa ә
	      I_macron Ӣ i_macron ӣ O_bar Ө o_bar ө U_macron Ӯ u_macron ӯ io ё je ј lje љ nje њ dzhe џ IO Ё JE Ј LJE Љ NJE Њ
	      DZHE Џ yu ю a а be б tse ц de д ie е ef ф ghe г ha х i и shorti й ka к el л em м en н o о pe п ya я er р es с te т
	      u у zhe ж ve в softsign ь yeru ы ze з sha ш e э shcha щ che ч hardsign ъ YU Ю A А BE Б TSE Ц DE Д IE Е EF Ф GHE Г
	      HA Х I И SHORTI Й KA К EL Л EM М EN Н O О PE П YA Я ER Р ES С TE Т U У ZHE Ж VE В SOFTSIGN Ь YERU Ы ZE З SHA Ш E Э
	      SHCHA Щ CHE Ч HARDSIGN Ъ );
my %heb = qw( doublelowline ‗ aleph א bet ב gimel ג dalet ד he ה waw ו zain ז chet ח tet ט yod י finalkaph ך kaph כ lamed ל 
	      finalmem ם mem מ finalnun ן nun נ samech ס ayin ע finalpe ף pe פ finalzade ץ zade צ qoph ק resh ר shin ש taw ת 
	      beth ב gimmel ג daleth ד samekh ס zayin ז het ח teth ט zadi צ kuf ק taf ת );
my %grk = qw( ALPHAaccent Ά EPSILONaccent Έ ETAaccent Ή IOTAaccent Ί IOTAdieresis Ϊ OMICRONaccent Ό UPSILONaccent Ύ
	      UPSILONdieresis Ϋ OMEGAaccent Ώ accentdieresis ΅ horizbar ― alphaaccent ά epsilonaccent έ etaaccent ή iotaaccent ί
	      iotadieresis ϊ iotaaccentdieresis ΐ omicronaccent ό upsilonaccent ύ upsilondieresis ϋ upsilonaccentdieresis ΰ
	      omegaaccent ώ ALPHA Α BETA Β GAMMA Γ DELTA Δ EPSILON Ε ZETA Ζ ETA Η THETA Θ IOTA Ι KAPPA Κ LAMDA Λ LAMBDA Λ MU Μ
	      NU Ν XI Ξ OMICRON Ο PI Π RHO Ρ SIGMA Σ TAU Τ UPSILON Υ PHI Φ CHI Χ PSI Ψ OMEGA Ω alpha α beta β gamma γ delta δ
	      epsilon ε zeta ζ eta η theta θ iota ι kappa κ lamda λ lambda λ mu μ nu ν xi ξ omicron ο pi π rho ρ sigma σ 
	      finalsmallsigma ς tau τ upsilon υ phi φ chi χ psi ψ omega ω );
$dec_dotcompose{"Cyrillic_$_"} = "Cyr_$cyr{$_}" for keys %cyr;
$dec_dotcompose{"hebrew_$_"}   = "heb_$heb{$_}" for keys %heb;
$dec_dotcompose{"Greek_$_"}    =  "Gr_$grk{$_}" for keys %grk;

sub shorten_dotcompose ($$;$) {		# Shorten but leave readable disambiguous (to allow more concise printout)
  shift;				# self		[Later we massage out Cyr_ Gr_ uni_ prefixes
  (my $in = shift) =~ s/\b(Cyr|Ukr|Gr|heb|Ar)[a-z]+(?=_)/$1/;
  $in =~ s/\b(dead)(?=_)/d/;
  $in =~ s/\b(Gr_\w+dier|d_diaer)esis/$1/;
  $in =~ s/^U([a-fA-F\d]{4,6})$/ 'uni_' . chr hex $1 /e if shift;
  $in
}

sub dec_dotcompose ($$;$) {
  my($self, $in, $dec_U) = (shift, shift, shift);
  my($pre, $post) = split /:/, $in, 2;
  $post or warn("Can't parse <<$in>>"), return;
  my @pre = ($pre =~ /<(\w+)>/g) or warn("Unknown format of IN in <<$in>>"), return;
  my($p) = ($post =~ /"(.+?)"/) or warn("Unknown format of OUT in <<$in>>"), return;
  @pre = map { exists $KeySyms{$_}
  		? $KeySyms{$_}
  		: ( exists $dec_dotcompose{$_} ? $dec_dotcompose{$_} : $self->shorten_dotcompose($_, $dec_U) ) } @pre;
  (@pre, $p)
}

# Stats: about 250 in: egrep "CP.*d_|d_.*CP" o-std
sub process_dotcompose ($$$;$) {
  my($self, $fh, $sub, $dec_U) = (shift, shift, shift, shift);
  while (<$fh>) {
    next if /^\s*(#|include\b)/;
    next unless /\S/;
    next unless my @in = $self->dec_dotcompose($_, $dec_U);
    $sub->($self, $in[-1], @in[0..$#in-1]);
  }
}

sub filter_dotcompose ($;$) {
  my ($self, $fh) = (shift, shift || \*ARGV);
  $self->process_dotcompose($fh, sub ($$@) {
    my($self, $out) = (shift, shift);
    print "@_  $out\n"; # Two spaces to allow for combining marks
  });
}

sub put_val_deep ($$$$@) {
  my($self, $h, $term, $val, $k) = (shift, shift, shift, shift, shift);
#  die "No key(s) in put_val_deep()" unless @_;		# It is OK to have an empty list
  while (@_) {
    my $oh = $h;
    $h->{$k} = {} unless defined $h->{$k};
    $h = $h->{$k};
    if ('HASH' ne ref $h) {
      die "Encountered non-HASH in put_val_deep(): <$k>" unless $term;
      my $ov = $h;
      $h = $oh->{$k} = { $term => $ov };
    }
    $k = shift;
  }
  if (exists $h->{$k}) {
    if (not ref $h->{$k}) {
      $h->{$k} = $val;			# later rule wins
    } elsif ($term and 'HASH' eq ref $h) {
      $h->{$k}{$term} = $val;
    } else {
      die "Encountered non-HASH in put_val_deep(): <$k>";
    }
  } else {
    $h->{$k} = $val;			# later rule wins
  }
}

sub compose_array_2_hash ($$$) {	# Assumes that below, @in is non-empty
  my($self, $a, $opt) = (@_);
  my($h, @root) = {};
  for my $l (@$a) {
    my($out, $term, @in) = @$l;
    my $Term = (ref $term ? $term->{term} : $term) ;
    my $pre = (($out eq "\x00" and ref $term and $term->{zeroOK}) ? '00' : '');		# protect against '0000' warning
    if (@in) {
      $self->put_val_deep( $h, $term, $pre . $self->key2hex($out), map $self->key2hex($_), @in);
    } elsif (not @root) {
      @root = $pre . $self->key2hex($out);
    } else {
      die "Two empty bindings in compose_array_2_hash(): <<<@root>>> and <<<", $pre . $self->key2hex($out), '>>>';
    }
    $self->put_val_deep( $opt, $term, $term, map $self->key2hex($_), @in) if ref $term;
  }
  if (@root) {
    die "an empty binding combined with others" if keys %$h;
    return shift @root;
  }
  $h
}

sub compose_line_2_array ($$$$$@) {
  my($self, $a, $out, $massage, $term, @in) = (@_);
  if ($massage) {
    s/^(uni|Gr|Cyr|heb)_(?![\x00-\x7e])(?=.$)//, s/^space$/ / for @in;			# copy
#warn "compose: @in  $out";
    return unless $in[0] eq 'CP';
    shift @in;
  }
  # Filter warnings via: egrep -v " d[^ ]|#" 00b | egrep -- "^---CP:" >00b2
	(printSkippedComposeKey and warn("---CP: @in  $out")),	# The last make sense only in the context of keysymbol operations???
  return if 1 != length $out or 0x10000 <= ord $out 
    or grep {1 != length or 0x10000 <= ord} @in or grep $out eq $_, @in;	# Allow for one char only
#warn "CP: @in  $out";
  push @$a, [$out, $term, @in];
}

sub compose_2_array ($$$$@) {
  my($self, $method, $fh, $a) = (shift, shift, shift, shift);
  
  if ($method eq 'dotcompose') {
    $self->process_dotcompose($fh, sub ($$@) {
      my($self, $out) = (shift, shift);
      $self->compose_line_2_array($a, $out, 'massage', !!'terminate', @_);
    }, 'decode U');
  } elsif ($method eq 'entity') {
    while (my $line = <$fh>) {
      next unless $line =~ /^\s*<a\s+name="U0([a-fA-F\d]{4})"[^,]*,[^,]*,\s*(.*)/;	# Two commas between OUT and IN
      my($out, @in) = (chr hex "$1", split /\s*,\s*/, "$2");
      $in[0] =~ s/\s+$//;
      @in = split /\s*,\s*/, $in[0];
      @in = sort {length($a) <=> length($b)} @in;
      for my $in (@in) {	# Avoid entries more than 2x longer than the shortest possible
        next if length($in) > $avoid_overlong_synonims_Entity*length $in[0] or length($in) > $maxEntityLen;
        my @IN = split //, $in;
        $self->compose_line_2_array($a, $out, !'massage', $self->key2hex(' '), @IN);
      }
    }
  } elsif ($method eq 'rfc1345') {	# http://tools.ietf.org/html/rfc1345  
    my %cvt = qw(gt > lt < amp &);
    while (my $line = <$fh>) {
      next unless ($line =~ /^\s+SP\s+0020\s+SPACE\s*$/) .. ($line =~ /^<span\s.*\bCHARSETS\s*<\/span/);
      next unless $line =~ /^\s+(\S+)\s+([a-fA-F\d]{4})\s/;
      my($out, $in) = (chr hex "$2", "$1");
      next if "$2" =~ /^e0/i;				# Skip private parts
      $in =~ s/&([lg]t|amp);/$cvt{$1}/g;
      next if 1 == length $in;
      my @IN = split //, $in;
      my $term = $self->key2hex(' ');
      $term = {term => $term, zeroOK => 1} if $out eq "\x00" and $in eq "NU";	# avoid '0000' warning
      $self->compose_line_2_array($a, $out, !'massage', $term, @IN);
    }
    $self->compose_line_2_array($a, '€', !'massage', $self->key2hex(' '), 'E', 'u');	# http://en.wikipedia.org/wiki/Unicode_input#Character_mnemonics
  } else {
    die "Unknown compose parser: $method";
  }
}

sub composefile_2_array ($$$$@) {
  my($self, $method, $fn, $a) = (shift, shift, shift, shift);
  open my $fh, '< :encoding(utf8)', $fn or die "Can't open `$fn' for read: $!";
  $self->compose_2_array($method, $fh, $a);
  close $fh or die "Can't close `$fn' for read: $!";
}

sub merge_hash_to ($$$) {	# We do NOT do deep copy
  my($self, $from, $to) = (shift, shift, shift);
  for my $k (keys %$from) {	# ignore if the existing value is not hash
    next if 'HASH' ne ref($to->{$k} || {});		# existing non-hash (terminator) wins over a terminator or a longer binding
    $to->{$k} = $from->{$k}, next unless exists $to->{$k};	# existing hash wins over new terminator.
    $self->merge_hash_to($from->{$k}, $to->{$k});
  }
}

sub create_composeArray ($$$) {
  my ($self, $key, $method) = (shift, shift, shift);
  if ($method eq 'literal') {
    my $a = [];
    for my $entry (split /\|\|\|/, $key) {
      die "unexpected format of the argument to ComposeKey/literal: <<<$key>>>" unless $key =~ /^(.)=(.*)/;
      my($out, @in) = ($1, split //, "$2");
      $self->compose_line_2_array($a, $out, !'massage', $self->key2hex(' '), @in);
    }
    return [$a];
  }
  my $names = $self->get__value($key) or return;
  my @A; # my $H;
  for my $fn (@$names) {
    $self->composefile_2_array($method, $fn, my $a = []);
    push @A, $a;
##    $self->compose_array_2_hash($a, my $h = {});
####    $self->merge_hash_to($h, $H);
##    warn "$fn: CP<\n" if printSkippedComposeKey;
##    warn "CP< ", join ', ', keys %$h if printSkippedComposeKey;
  }
#  warn "CP= ", join ', ', keys %$H if printSkippedComposeKey;
  \@A;
}

sub compose_Array_2_hash ($$$) {
  my ($self, $A, $OPT) = (shift, shift, shift);
  my $H = {};		# indexed by HEX
  for my $a (@$A) {
    my $h = $self->compose_array_2_hash($a, my $opt = {});
    if (ref $h) {
      $self->merge_hash_to($h, $H);
    } elsif (not keys %$H) {
      $H = $h;
    } else {
      die "Cannot merge a non-hash to a hash";
    }
    $self->merge_hash_to($opt, $OPT);
# warn "CP< ", join ', ', keys %$h;
  }
# warn "CP= ", join ', ', keys %$H;
  $H;
}

sub composehash_2_prefix ($$$$$$$$) {
  my($self, $F, $prefix, $h, $n, $prefixCompose, $show, $comp_show) = (shift, shift, shift, shift, shift, shift, shift, shift);
  my($H, $mirror) = ($self->{faces}{$F}, $h->{'[Mirror]'} || {});		# Some of character mirror binding of other characters
  my(%map, %seen);
  # First, non-mirroring; then mirroring in the order of mirrored
  for my $c (sort {($mirror->{$a} || '') cmp ($mirror->{$b} || '') or $a cmp $b} keys %$h) {	# order affects the order of auto-prefixes
    next if $c =~ /^\[(G?Prefix(_Show)?|Mirror|Opt)\]$/;
    my $v = $h->{$c};
    if (ref $v and $seen{"$v"}) {	# reuse the old value for ARRAYs (mirrored values refer to the same subhash)
      $v = $seen{"$v"};
    } elsif (ref $v) {
      my $p = $v->{'[Prefix]'} || $self->key2hex($self->next_auto_dead($H));
      my $cc = $c;			# Name should not reflect linking
#      warn(" [@$n] $cc => $mirror->{$c}"),
      $cc = $mirror->{$c} if exists $mirror->{$c};
      my $name_append = my $name_show = chr hex $cc;
      $name_append = 'Compose' if $name_append eq $self->charhex2key($prefixCompose);
      $name_show = '⎄' if $name_show eq $self->charhex2key($prefixCompose);
      $name_append = $self->key2hex($name_append) if $name_append =~ /\s/;
#      $name_show = $self->key2hex($name_show) if $name_show =~ /\s/ and $name_show ne ' ';
      my $c;
      ($name_show = "$show$name_show")
        =~ s[^((⎄[₁₂₃₄₅₆₇₈₉]?|\Q$comp_show\E){2,})][ $2 . (($c = length($1)/length($2)) =~ tr/0-9/⁰¹²³⁴⁵⁶⁷⁸⁹/, $c) ]e;
      $name_show = $v->{'[Prefix_Show]'} if defined $v->{'[Prefix_Show]'};
      $self->composehash_2_prefix($F, $p, $v, my $nn = [@$n, $name_append], $prefixCompose, $name_show, $comp_show);
      $self->{faces}{$F}{'[prefixDocs]'}{$p} = "@$nn";
      $self->{faces}{$F}{'[Show]'}{$p} = $name_show;
      $v = $seen{"$v"} = [$p, undef, 1];
    } else {
      $H->{'[inCompose]'}{$self->charhex2key($v)}++;
      $v = [$v];
    }
    $map{$c} = $v;
  }
  $H->{'[deadkeyFaceHexMap]'}{$prefix} = \%map;
}

# On non-Latin layout, one needs to substitute the Latin chars by the layout char on this key
sub composehash_add_linked ($$$$) {
  my($self, $hexH, $charH, $prefCharH, $delay, %add, %ADD, %cnt) = (shift, shift, shift, shift, {});
#warn "0: Mismatch E/Е: $hexH->{'0045'}///$hexH->{'0415'}" if $hexH->{'0045'} and $hexH->{'0415'} and $hexH->{'0045'} ne $hexH->{'0415'};
  return unless ref $hexH;
  for my $h (sort keys %$hexH) {		# Make order predictable: when a char is present in more than 2 places, it matters
    next if $h =~ /^\[(G?Prefix(_Show)?|Mirror|Opt)\]$/;
    $self->composehash_add_linked($hexH->{$h}, $charH, $prefCharH) if ref $hexH->{$h};
    next unless defined (my $to = $charH->{my $c = chr hex $h});
    $to = $to->[0] if ref $to;			# the corresponding char of layout
    my $toC  = $self->charhex2key($to);
    next if exists $hexH->{$to = $self->key2hex($to)};	# There is already a binding for the char of layout
    my $back = $prefCharH->{$toC};
    $back = $back->[0] if ref $back;		# roundtrip back to the “Latin”
    my $now = $h eq $self->key2hex($back);	# when a char is at several positions on layout (e.g., Slovak/my-Hebrew), prefer the main one
#  warn " ... link $c to $toC (now=$now, back = $prefCharH->{$toC}) @{$prefCharH->{$toC}||[]})";
#  warn " ... link $c to $toC (now=$now, back = $back)";
    $add{$to} = $h;				# mark as “mirroring” (for visualization of prefixes on OS X)
    $ADD{$to} = $h if $now;
    $cnt{$to}++;
    ($now ? $hexH : $delay)->{$to} = $hexH->{$h};
  }
  %add = (%add, %ADD) if %ADD;
  $hexH->{'[Mirror]'} = \%add if %add;
#  warn " ... almost done";
#warn "1: Mismatch E/Е: $hexH->{'0045'}///$hexH->{'0415'}" if $hexH->{'0045'} and $hexH->{'0415'} and $hexH->{'0045'} ne $hexH->{'0415'};
  %$hexH = (%$delay, %$hexH) if keys %$delay;
#warn "2: Mismatch E/Е: $hexH->{'0045'}///$hexH->{'0415'}" if $hexH->{'0045'} and $hexH->{'0415'} and $hexH->{'0045'} ne $hexH->{'0415'};
  my %del;
  for my $k (keys %ADD) {		# Have “directly” mirrored data
    next unless $cnt{$k} == 1;		# Is it 1-to-1?
    warn('panic'), next unless $hexH->{$k} eq $hexH->{my $mir = $ADD{$k}};
#    warn("   ??? $mir/$k => 00cb/0401 $hexH->{'0045'}///$hexH->{'0415'}  $hexH->{$mir}///$hexH->{$k}")
#	if $mir eq '0045' and $hexH->{'0045'} and $hexH->{'0415'} and $hexH->{'0045'} ne $hexH->{'0415'};;
    next if exists $ADD{$mir};		# Do not touch mirroring bindings
    $del{$mir}++;			# Just in case (???), postpone editing until the end of pass
  }
  delete $hexH->{$_} for keys %del;	# Delete successively mirrored
# warn "3: Mismatch E/Е: $hexH->{'0045'}///$hexH->{'0415'}" if $hexH->{'0045'} and $hexH->{'0415'} and $hexH->{'0045'} ne $hexH->{'0415'};
}

sub create_composekey ($$$) {
  my($self, $F, $descrip, @DESCRIP) = (shift, shift, shift);
  my $linkedF = $self->{faces}{$F}{LinkFace};
  my $linked = $linkedF && $self->{faces}{$linkedF}{Face_link_map}{$F};
  $linked &&= {map {ref($_ || 0) ? $_->[0] : $_} %$linked};
  my $rlinked = $linked && $self->{faces}{$F}{Face_link_map}{$linkedF};
#  $linked ||= {};
#      warn "   Compose: $F: F linked to $linked->{F}" if $linked and $linked->{F};
#     $F eq 'Latin' and 
#     warn "   Compose: $F: ",  join ', ', sort keys %{$self->{faces}{$linkedF}{Face_link_map}{$F}}
#	if $self->{faces}{$linkedF}{Face_link_map}{$F};
  if ($descrip and ref $descrip) {
    @DESCRIP = map { my @a = split /,/; 
    		    defined $a[$_] and length $a[$_] and $a[$_] = $self->key2hex($self->charhex2key($a[$_])) for 3,4; 
    		    [@a]} @$descrip;
  } else {
    $descrip = $self->key2hex($self->charhex2key($descrip));
    @DESCRIP = ( ['ComposeFiles', 'dotcompose', 'warn', $descrip, ''], 
    		['EntityFiles',  'entity',     'warn', '', $descrip], 
    		['rfc1345Files', 'rfc1345',    'warn', '', $descrip]);
  }
  $self->load_KeySyms;
  my $p0 = my $first_prefix = $DESCRIP[0][3];			# use for first found map
  $self->{faces}{$F}{'[mainComposeKeyHex]'} = $p0;
  my @Hashes;
  my @Arrays = @{ $self->{'[ComposeArrays]'} || [] };
  unless (@Arrays) {	# Shared between faces
    my @Show;
    for my $i (0..$#DESCRIP) {	# FileList, type, OK_to_miss, prefix, prefix-in-last ... prefix-in-pre-last ...
      my $descr = $DESCRIP[$i];
      my $arr;
      unless ($arr = $self->create_composeArray($descr->[0], $descr->[1]) and @$arr) {
        warn "Compose list of type $descr->[1] could not be created from FileList variable $descr->[0]" if $descr->[2];
        next;
      }
      push @Arrays, [$arr, $descr];
      push @Show, $i;
    }
    $self->{'[ComposeArrays]'} = \@Arrays;
    $self->{'[ComposeShowIdx]'} = \@Show;
  }
  my($v, $vv) = map $self->{faces}{$F}{$_}, qw( [coverage0oneUTF16hash] [coverageExtra] );
#  warn "Filter hashes $F ", scalar keys %$v, ' ', scalar keys %$vv, ' ', scalar @{$self->{faces}{$F}{'[coverage0oneUTF16]'}};
  for my $A (@Arrays) {		# one per type
    my($arr, $descr) = @$A;
    my @NN;
    for my $a (@$arr) {		# $a one per input file
      my @N;
      for my $l (@$a) {		# One per line
        my($out, $term, @in) = @$l;
        next if grep {not ($v->{$_} or $vv->{$_} or $linked and $linked->{$_})} @in;
# my $c;
# warn "in=<@in>, k=$c, 00=", !!$v->{$c}, " Extra=", !!$vv->{$c} if ($c) = grep {ord() <= 0x30ff and ord >= 0x30f0} @in;
        push @N, $l;
      }
      push @NN, \@N;
    }
#    warn "Compose face=$F: keys <@$arr> @$descr";
#    warn "Compose face=$F: keys ", join ' ', map scalar @$_, @$arr;
    my $opt = {};
    push @Hashes, [$self->compose_Array_2_hash(\@NN, $opt), $descr, $opt];
  }
  my @hashes;
  my $Comp_show = $self->{faces}{$F}{'[ComposeKey_Show]'};
  my $IDX = $self->{'[ComposeShowIdx]'};
  for my $i (0..$#Hashes) {		# Now process separately for every personality
    my $H = $Hashes[$i];
    my($chained, $hash, $pref, $opt) = ('G', @$H);	# Global;    $opt not used yet
    $hash = $self->deep_copy($hash);	# Per-personality copy
    $self->composehash_add_linked($hash, $linked, $rlinked) if $linked;
    my $pref0 = $pref->[3];
    my $prefix_repeat;
    if (@hashes and defined $pref->[4] and length $pref->[4]) {
      die "Chain-ComposeKey $pref->[4] already bound in the previous ComposeHash, keys = ", join ', ', keys %{$hashes[-1]{$pref->[4]}} 
        if $hashes[-1]{$pref->[4]};
      $hashes[-1]{$pref->[4]} = $hash;	# Bind to double/etc press
      $chained = '';
    } elsif ($first_prefix) {			# The previous type could be not found; use the first defined accessor
      $pref0 = $first_prefix;
      undef $first_prefix;
    } else {
      warn "Hanging ComposeHash (no access prefix key) for ", join('///', @$pref);
    }
    push @hashes, $hash;
    $hash->{"[${chained}Prefix]"} = $pref0 if length $pref0;
    $hash->{"[Prefix_Show]"} = $Comp_show->[$IDX->[$i]] if ref $Comp_show and length $Comp_show->[$IDX->[$i]];
  }
  return unless @hashes;
#  my @idx = split //, '₁₂₃₄₅₆₇₈₉';
  my $c = 0;
  for my $i ( 0..$#hashes ) {
    my $h = $hashes[$i];
    my $I = $IDX->[$i];
    next unless ref $h and my $p = $h->{'[GPrefix]'};		# Not chained (chained are processed as subhashes by composehash_2_prefix()
    my $post = ($c ? "[$c]" : '');
    my $comp_show = $h->{'[Prefix_Show]'};
    unless (defined $comp_show) {
      my $c1;
      my $spost = ($c ? (($c1 = $c) =~ tr/0-9/₀₁₂₃₄₅₆₇₈₉/, $c1) : '');
      if (ref $Comp_show) {				# Elt0 has a sane default
        $comp_show = "$Comp_show->[0]$spost";
      } else {
        $comp_show = "$Comp_show$spost";
      }
    }
    $self->{faces}{$F}{'[Show]'}{$p} = $comp_show;
    #  push @Show, (ref $comp_show ? $comp_show->[$i] : $comp_show);
    $self->composehash_2_prefix($F, $p, $h, ["Compose$post"], $p0, $comp_show, $comp_show);
    $self->{faces}{$F}{'[prefixDocs]'}{$p} = "Compose$post key";
    ++$c;
  }
}

sub XKB_key ($$$;$$$$) {			# unfinished ( ##### is for Apple parts needing work)
  my($self, $K,    $i, $use_base, $dd, $map, $override) =
    (shift, shift, shift, shift, shift || {}, shift || {}, shift || {dup => {}});
  my($sh, $caps, $l);				##### were needed on Apple
  my $A2l;					##### = [ @{ $self->AppleMap_Base($K) } ];	# Deep copy
  my $dup = $override->{dup};
  for my $from (keys %$dup) {
    $A2l->[$from] = $A2l->[$dup->{$from}];
  }
  my $F = $self->get_deep($self, @$K);		# Presumably a face hash, as in $K = [qw(faces US)]
  my $L = [map $self->{layers}{$_}, @{$F->{layers}}];
  $L = $L->[$l];
  my $B = $use_base && $self->Base_VK_names($K);	# Partially implemented: use Base_VK_names instead of the real $F (VK_ code)
  $B = [map {defined() && /^\w$/ ? lc $_ : $_} @$B] if ($use_base || 0) > 0;
  my @AppleMap;					##### = _AppleMap unless @AppleMap;
  warn 'AppleMap too long' if $#AppleMap >= 127;
  my($I, $d, $c, $force_o) = ($A2l->[$i], 0);	# offset inside the layout array
  $c = $override->{"$l-$sh-$caps-vk=$i"} || $override->{"$l-$sh--vk=$i"} unless $use_base;	# $caps is 0 or 1
#    $force_o++ if defined $use_base and $use_base eq '0';
  $c = $use_base ? $B->[$I] : $L->[$I][$sh] if not defined $c and defined $I;
  if (($use_base || 0) < 0) {			# Control
    $force_o++;
    if (!defined $c) {			# ignore
    } elsif ($c =~ /^[A-Z]$/) {
      $c = chr( 1 + ord($c) - ord 'A');
    } elsif ($c !~ /^[-0-9=.*\/+]$/) {
#####      $c = $OEM2ctrl{$c};			# mostly undef
    }
  } elsif ($use_base) {
    my $tr;
    if (!defined $c) {			# ignore
#####    } elsif (defined($tr = $OEM2cmd{$c})) {
#####      $c = $tr;
    } elsif (defined($tr = $oem_control{$c})) {
      $tr =~ s/(?<=.).*//;
      $c = $tr;
    } else {
      undef $c;
    }
  }
  $c = $AppleMap[$i] unless defined $c; # Fallback to US (apparently, there is no unbound "ASCII" keys in maps???); dbg to "\xffff" #
      
#####  $o .= <<EOK, next unless defined $c;
#####          <!-- gap, $i -->
#####EOK
  $d = $c->[2] || 0 if ref $c;
  $c = $c->[0] if ref $c;
  # On windows, CapsLock flips the case; on Mac, it upcases
  # ($c) = grep {$_ ne $c} uc $c, ucfirst lc $c, lc $c if !$d and $caps and (lc $c ne uc $c or lc $c ne ucfirst lc $c);
  $c = uc $c if !$d and $caps;
  $dd->{$c}[1]++ if $d > 0;			# 0 for normal char, 1 for base prefix; not for hex4/hex6
  $override->{extra_actions}{$c}++ if $d < 0;
  my $M = (!$force_o and $d >= 0 and $map->{$self->keys2hex($c)});
  my $pr = $M ? 'a_' : '';
  $dd->{$c}[0] = $c if $M or $d > 0;		# 0 for normal char, 1 for base prefix
  my($how, $pref) = ($d || $M) ? ('action', ($M ? 'a_' : '') . ($d > 0 ? 'pr_' : (!$d && '_'))) : ('output', '');
  ($how eq 'output') ? XML_format_UTF_16 $c : XML_format $c;
  return <<EOK;
          <key code="$i" $how="$pref$c" />
EOK
}

my %CapsTypes = qw(
    0	TWO_LEVEL			1   ALPHABETIC
    00	FOUR_LEVEL			10  FOUR_LEVEL_SEMIALPHABETIC
    01	FOUR_LEVEL_ANTISEMIALPHABETIC	11  FOUR_LEVEL_ALPHABETIC
);

# Some untested:
my %XKB_map = (qw( ` TLDE     \ BKSL   OEM_102 LSGT  ABNT_C1  AE13
		     SPACE SPCE	ESCAPE ESC	PRSC PRSC	SCLK SCLK	PAUS PAUS
		     DECIMAL KODL	ABNT_C2 KPPT	APP MENU	RETURN RTRN
			DIVIDE KPDV   MULTIPLY KPMU   SUBTRACT KPSU   ADD KPAD
			#RETURN KPEN    #DELETE KPDE
		 ), ' ' => 'SPCE');		# `
sub XKB_map () {		# Only the main island
  my $r = 4;
  for my $row (qw( 1234567890-=   qwertyuiop[]  asdfghjkl;' zxcvbnm,./ )) {	# '
    my $c = chr($r + ord 'A');
    my @C = split //, $row;
    $XKB_map{uc $C[$_]} = sprintf "A$c%02d", $_ + 1 for 0 .. $#C;
    $r--;
  }
  $XKB_map{"F$_"} = sprintf 'FK%02d', $_ for 1..24;	# Mac Aluminium has F19
  $XKB_map{"NUMPAD$_"} = "KO$_" for 0..9;
  my @kp  = qw(INSERT END DOWN NEXT LEFT CLEAR RIGHT HOME UP PRIOR DELETE);
  my @kpX = qw(INS    END DOWN PGDN LEFT KP5   RGHT  HOME UP PGUP  DELE);
  $XKB_map{"#$kp[$_]"} = "KP$_"   for 0..9;			# XXX ??? Not supported yet
  $XKB_map{$kp[$_]} = $kpX[$_] for 0..10;
}
XKB_map;

sub output_unit_XKB ($$$$$$$$) {
  my ($self, $face, $N, $k, $kraw, $decimal, $Used, $pre) = (shift, shift, shift, shift, shift, shift, shift, shift);
  return unless defined $k or defined $kraw;
  my $sc = ($XKB_map{$k} or $XKB_map{$kraw} or warn("Can't find the scancode for the key `$k', kraw=`$kraw'"), "k=$k");
  my $flat = $self->flatten_unit($face, $N,
				 $self->{faces}{$face}{'[output_layers_XKB]'} || $self->{faces}{$face}{'[output_layers]'})
    or return;
  my @KK = @$flat;
  my $CL;
  if (my $Caps = $self->{faces}{$face}{'[CapsLOCKlayers]'} and defined $N) {	# $N not supported on VK...
    $CL = [map $self->{layers}{$_}[$N], @$Caps];
#      warn "See CapsLock layers: <<<", join('>>> <<<', @$Caps), ">>>";
  }
  if (	0 and			# Not appropriate for XKB
	 # $skippable and
	 not defined $KK[0][0] and not defined $KK[1][0]) {
    for my $shft (0,1) {
      $KK[$shft] = [$default_bind{$k}[0][$shft], 0] if defined $default_bind{$k}[0][$shft];
###        $KK[$shft] = [$decimal[$shft], 0] if $k eq 'DECIMAL' and @decimal;
    }
  }

  if ($k eq 'DECIMAL') {	# may be described both via visual maps and NUMPAD
    my @d = @{ $decimal->[1] || [] };
    my $finalize = $decimal->[2];
    defined $KK[$_][0] or $KK[$_] = $d[$_] for 0..$#d;	# fill on the second round
    @$decimal = ([$N], [@KK]), return unless $finalize;
  }
#    warn "Undefined \$N ==> <<<", join '>>> <<<', map $_->[0], @KK unless defined $N;	# SPACE and ABNT_C1 ???
#####    $self->output_unit_KK($k, $u, $sc, $Used, $CL, @KK);
#####  }
#####  
#####  sub output_unit_KK($$@) {
#####    my ($self, $k, $u, $sc, $Used, $CL, @KK) = @_;
  if ($pre) {
    map $self->format_key_XKB($face, $_->[0], $_->[2], !'guess', $Used->[$_->[1] || 0]), @KK;		# prefill base prefixes
    return
  }
  my @K = map $self->format_key_XKB($face, $_->[0], $_->[2], 'guess', $Used->[$_->[1] || 0]), @KK;
#warn "keys with ligatures: <@K>" if grep $K[$_] eq '%%', 0..$#K;
#####  push @ligatures, map [$k, $_, $KK[$_][0]], grep $K[$_] eq '%%', 0..$#K;
  my $keys = join ",\t", @K;
  my @kk = map $_->[0], @KK;
  # Separate CL chars not easily supported on XKB ???  Need up to 8 keysyms per entry?
  my $u = [[@KK[0,1]], [@KK[2,3]]];
  my $cl_idx = join '', map $self->auto_capslock($_), @$u;
  my $cl_type = $CapsTypes{$cl_idx} or die "Unknown CapsLock mask: $cl_idx";
#  return ($sc, $cl_type, $keys);
  return qq(    key $sc\t{ type="$cl_type",\t[ $keys ] };\n);

  my($CL0, $Extra) = ($CL and $CL->[0]);
  undef $CL0 unless $CL0 and @$CL0 and grep defined, map { ($_ and ref $_) ? $_->[0] : $_ } @$CL0;
  my $capslock = (defined $CL0 ? 2 : $self->auto_capslock($u->[0]));
  $capslock |= (($self->auto_capslock($u->[1])) << 2);
  $capslock = 'SGCap' if $capslock == 2;	# Not clear if we can combine a string SGCap with 0x4 in a .klc file
  if ($CL0) {
    my $a_cl = $self->auto_capslock($u->[0]);
    my @KKK = @KK[$a_cl ? (1,0) : (0,1)];
    defined(($CL0->[$_] and ref $CL0->[$_]) ? $CL0->[$_][0] : $CL0->[$_]) and $KKK[$_] = $CL0->[$_] for 0, 1;
#      my @c = map { ($_ and ref $_) ? $_->[0] : $_ } @$CL0;
#      my @d = map { ($_ and ref $_) ? $_->[2] : {} } @$CL0;	# dead
#      my @f = map $self->format_key($c[$_], $d[$_], ), 0 .. $#$CL0;
#      $Extra = [@f];
    $Extra = [map $self->format_key_XKB($face, $_->[0], $_->[2], $Used->[$_->[1] || 0]), @KKK];
  }
#  ($sc, $capslock, $keys, $Extra);
  "$sc,\t$capslock,\t$keys,\t$Extra\n";
}

sub output_layout_XKB ($$) {
  my ($self, $k) = (shift, shift, shift, shift);
  $self->reset_units;
  my $B = $self->Base_VK_names($k);
# Dumpvalue->new()->dumpValue($self);
# warn "Translate: ", %h;
  my $F = $self->get_deep($self, @$k);		# Presumably a face hash, as in $k = [qw(faces US)]
  $F->{'[dead-usedX]'} = [map {}, @{$F->{layers}}];		# Which of deadkeys are reachable on the keyboard
  my $BB = $F->{baseKeysRaw};
#  die "Count of non-VK entries mismatched: $cnt vs ", scalar @{$self->{layers}{$layers->[0]}}
#    unless $cnt <= scalar @{$self->{layers}{$layers->[0]}};
  my $face = join '/', @$k[1..$#$k];
  my $decimal = [];
  if (my $c = $self->{faces}{$face}{'[Flip_AltGr_Key]'}) {
    $self->{faces}{$face}{"[dead_X11symbol]"}{$c} = 'ISO_Level3_Latch';
  }
  if (my $c = $self->{faces}{$face}{'[mainComposeKeyHex]'}) {
    $self->{faces}{$face}{"[dead_X11symbol]"}{$c} = 'Multi_key';
  }
  map $self->output_unit_XKB($face, $_, $B->[$_], $BB->[$_], $decimal, $F->{'[dead-usedX]'}, 'pre'), 0..$#$B;	# calc base prefixes
  my @o = map $self->output_unit_XKB($face, $_, $B->[$_], $BB->[$_], $decimal, $F->{'[dead-usedX]'}, !'pre'), 0..$#$B;
  push @o, $self->output_unit_XKB($face, $decimal->[0][0], $B->[$decimal->[0][0]], $BB->[$decimal->[0][0]],
				      $decimal, $F->{'[dead-usedX]'})
     if @$decimal and ++$decimal->[2];
  join '', @o;
}

my(@AppleSym, %AppleSym);
sub _AppleMap () {	# http://forums.macrumors.com/archive/index.php/t-780577.html
  # https://github.com/tekezo/Karabiner/blob/version_10.7.0/src/bridge/generator/keycode/data/KeyCode.data
  # It has a definition of 0x34; moreover, it also defines some keys above 0x80 (including ≤ 0x80 on some German keyboard???)
  chomp(my $lst = <<'EOF');	# 0..50; 65..92; 93..95		 ↱KEYPAD;  · = special	     ↱JIS (≥93=0x5d)
asdfhgzxcv§bqweryt123465=97-80]ou[ip·lj'k;\,/nm.· `··············.·*·+·····/··-··=01234567·89¥_,
EOF
  # ' # KEYPAD above starts on 65=0x41
  my @lst = split //, $lst;
  my $last = $#lst;
  # in addition to US Extended, we defined 64, 73 (BR), 102, 104 (hex 40 49 66 68) and 93-95 from JIS
  my @kVK_ = split /\n/, <<EOF;		# Codes 0x34 0x42 0x46 0x4D taken from US Extended; + is 0x10
24	Return			0d
30	Tab			09
####31	Space
33	Delete			08
34	Enter_PowerBook		03	# Same as KeypadEnter
35	Escape			1b
37	Command
38	Shift
39	CapsLock
3A	Option
3B	Control
3C	RightShift
3D	RightOption
3E	RightControl
3F	Function
40	F17			+
42	?????????????		1d	# Same as RightArrow
46	??????????????		1c	# Same as LeftArrow
47	ANSI_KeypadClear	1b	# ??? Same as Escape
48	VolumeUp		1f	# ??? Same as DownArrow
49	VolumeDown		+	# C1 of ABNT: /
4A	Mute
###4B	ANSI_KeypadDivide	/
4C	ANSI_KeypadEnter	03
4D	???????			1e	# Same as UpArrow
4F	F18			+
50	F19			+
5A	F20
60	F5			+
61	F6			+
62	F7			+
63	F3			+
64	F8			+
65	F9			+
67	F11			+
69	F13			+
6A	F16			+
6B	F14			+
6D	F10			+
6E	__PC__Menu		+
6F	F12			+
71	F15			+
72	Help			05
73	Home			01
74	PageUp			0b
75	ForwardDelete		7f
76	F4			+
77	End			04
78	F2			+
79	PageDown		0c
7A	F1			+
7B	LeftArrow		1c
7C	RightArrow		1d
7D	DownArrow		1f
7E	UpArrow			1e
		# ISO keyboards only
####0A	ISO_Section		§
		# JIS keyboards only
####5D	JIS_Yen			¥
####5E	JIS_Underscore		_
####5F	JIS_KeypadComma		,
66	JIS_Eisu		SPACE	# Left of space (On CapsLock on Windows; compare http://commons.wikimedia.org/wiki/File:MacBookProJISKeyboard-1.jpg with http://en.wikipedia.org/wiki/Keyboard_layout#Japanese)
68	JIS_Kana		SPACE	# Right of space (as on Windows, but without intervening key)
		# Defined in US Extended:
6C	??????			+
70	??????			+
		# ?????
###BRIGHTNESS_DOWN 0x91
###BRIGHTNESS_UP   0x90
###DASHBOARD       0x82
###EXPOSE_ALL      0xa0
###LAUNCHPAD       0x83
###MISSION_CONTROL 0xa0
#
###GERMAN_PC_LESS_THAN 0x80
###PC_POWER	   0x7f
EOF
  my %seen;
  for my $i (0..$#lst) {
    if ($lst[$i] eq '·') { 
      undef $lst[$i]; 
    } else {
      my $pref = (defined $AppleSym{$lst[$i]} and '#');
      $AppleSym{"$pref$lst[$i]"} = $i;
    }
  }
#  $AppleSym{'#'} = $AppleSym{' '};		# Space is in a table as #
  my %map = ('+' => "\x10", 'SPACE' => ' ');
  for my $kVK (@kVK_) {
    warn ("unexpected OSX scan: <<$kVK>>"), next unless $kVK =~ /^\s*(#)|([A-F\d]{2})\s+(\?+|\w+)\s*(.*)/i;
    next if $1;
    my($hex, $name, $rest, $comment) = ($2, $3, $4);
    $AppleSym[hex $hex] = $name;
    $AppleSym{$name} = hex $hex;
    if (length $rest) {
      warn ("unexpected OSX scan expansion in $hex/$name: <<$rest>>"), next 
        unless ( my($HEX,$lit,$sp), $comment) = ( $rest =~ /^(?:(?:([A-F\d]{2})|([^\w\s+])|(SPACE|\+))\s*)?(?:#\s*(.*))?$/i );
      if ($sp) {
        $rest = $map{$sp} or warn "Bad map in OSX basemap"
      } elsif ($HEX) {
        $rest = chr hex $HEX;
      } else {
        $rest = $lit;
      }
      my $idx = hex $hex;
      $idx > $last or not defined $lst[$idx] or warn "Non-special <<$lst[$idx]>> when overriding offset=$idx=hex($hex) in OSX basemap";
      $lst[$idx] = $rest;
    }
  }
  @lst
}

my @AppleMap;

# Extra keys on Windows side: INSERT, and duplication-by-NumLock of the keypad.
# Extra keys on Apple side: CLEAR on the KP, and KP-Equal.

# Current solution:	merge win-KP_Clear with apple-KP_CLear (1st in the center, 2nd in the ul-corner!)
#			merge INSERT with KP=

# How to work with NumLock-modifications?  There are 3 states: NumLock-, Base-, Shift.

# Not in Apple maps: 
# F21-F24 HOME UP PRIOR DIVIDE LEFT CLEAR RIGHT MULTIPLY END DOWN NEXT SUBTRACT INSERT DELETE RETURN ADD NUMPAD0-NUMPAD9
my %Apple_recode;
{ no warnings 'qw';
  %Apple_recode = (qw( 
	DIVIDE #/   MULTIPLY *   SUBTRACT #-   ADD +   DECIMAL #.   
	RETURN ANSI_KeypadEnter    DELETE ForwardDelete	   #\ §	   OEM_102 §
	PRIOR PageUp    CLEAR ANSI_KeypadClear    NEXT PageDown INSERT #=
	ABNT_C1 VolumeDown	APP __PC__Menu
     ), SPACE => ' ', map +("NUMPAD$_", "#$_"), 0..9);
}
my %Apple_skip = map +($_, 1), (map "F$_", 21..24);	#, (map "NUMPAD$_", 0..9);
# ==> HOME UP PRIOR LEFT CLEAR RIGHT END DOWN NEXT INSERT DELETE RETURN
# ==> PRIOR CLEAR NEXT INSERT

sub AppleMap_Base ($$) {
  my($self, $K) = (shift, shift);
  my $F = $self->get_deep($self, @$K);		# Presumably a face hash, as in $K = [qw(faces US)]
  return $F->{Apple2layout} if $F->{Apple2layout};
  @AppleMap = _AppleMap unless @AppleMap;
  warn 'AppleMap too long' if $#AppleMap >= 127;
  $self->reset_units;
  my $BB = $self->Base_VK_names($K);		# VK per position (except via-VK keys)
  my $B = $F->{baseKeysRaw};		# chars on key (if the first occurence???) OR VK
  my(@o, @A, @AA);			# A: kbdd --> Apple;	AA: Apple --> kbdd
  $_ = [@$_] for $B, $BB;		# 1-level deep copy
  my $o = $F->{'[VK_off]'};
  for my $b (()) {			# Explicitly add via-VK keys
    for my $vk (keys %$o) {
      warn "[@$K]: $vk defined on \@$o->{$vk} as $b->[$o->{$vk}]" if defined $b->[$o->{$vk}];
      $b->[$o->{$vk}] = $vk unless defined $b->[$o->{$vk}];
#      warn "[@$K]: $vk \@ $o->{$vk}";	# SPACE @ 116 (on izKeys)
    }
  }
# warn "[[@$K]] @$B\n\t@$BB\n";
# warn "\t", !(grep $_ eq ' ', @$B), "\t", !(grep $_ eq ' ', @$BB), "\n";
  for my $i (0..$#$B) {			# Primary mappings
    my $k = $B->[$i];
    my $kk = $BB->[$i];
    next unless defined $k;
    $A[$i] = $AppleSym{$kk}, next if exists $AppleSym{$kk};
    $A[$i] = $AppleSym{$Apple_recode{$kk}}, next if exists $AppleSym{$Apple_recode{$kk} || 123};
    $A[$i] = $AppleSym{$k},  next if exists $AppleSym{$k};
    $A[$i] = $AppleSym{$Apple_recode{$k}},  next if exists $AppleSym{$Apple_recode{$k} || 123};
    $A[$i] = "\u\L$k" . 'Arrow', next if exists $AppleSym{"\u\L$k" . 'Arrow'};
    $A[$i] = "\u\L$k", next if exists $AppleSym{"\u\L$k"};
    next if $Apple_skip{$k};
    push @o, $k;
  }
  for my $i (0..126) {			# Primary backwards mappings
    next unless defined $A[$i];
    warn "Duplicate backward Apple mapping: old=$AA[$A[$i]] --> $A[$i] <-- $i=new" if defined $AA[$A[$i]];
    $AA[$A[$i]] = $i;
  }
  for my $i (0..126) {			# Secondary backwards mappings
    next if defined $AA[$i] or ($AppleSym[$i] || '') !~ /^#(.)$/ or not defined $AA[$AppleSym{$1}];
    $AA[$i] = $AA[$AppleSym{$1}]
  }
  warn "Not in Apple maps: @o" if @o;
  $F->{layout2Apple} = \@A;
  $F->{Apple2layout} = \@AA;
}

# fake is needed (apparently, the compiler does not allocate the named states smartly???)
my @state_cnt = qw(  4of4 4096  3of4 256   2of4 16   1of4 0   0of4 0
    1of6 0           2of6 2     3of6 16    4of6 256                      0of6 0
  );
my @state_cnt_a = (@state_cnt, qw(
    5of6 4	6of6 64
  ));					# At end, so may be skipped via merge_states_6_and_4
my @state_cnt_b = (@state_cnt, qw(
    5of6 64	6of6 64
  ));
my $in_group_4of6_plan_c = 2;
my @state_cnt_c = (@state_cnt, '5of6' => 16 * $in_group_4of6_plan_c, '6of6' => 64);
my $use_plan_b;			# unimplemented
my $use_plan_c = 1;		# untested

sub alloc_slots ($$) {
  my($tot, $a, %start) = (shift, shift);
  my @a = @$a;				# deep copy
  while (@a) {
    my($how, $c) = splice @a, 0, 2;
    $start{$how} = [$tot, $tot+$c-1];
    $tot += $c;
  }
  \%start;
}

sub output_state_range ($$$$$$) {	# Apparently, only ranges up to 256 states are supported.
  my($self, $from, $to, $mult, $next, $out, $o) = (shift, shift, shift, shift, shift, shift, '');	# $out is the ord(OUTPUT)
  $o .= "\t\t\t<!-- Cannot have more than 256 in one range; subdividing $from ... $to -->\n" if $to - $from > 255;
  while ($to - $from > 255) {
    $o .= $self->output_state_range($from, $from+255, $mult, $next, $out);
    $from += 256;
    $out  += 256*$mult if defined $out;
    $next += 256*$mult if defined $next;
  }
  XML_format($out = chr $out) if defined $out;
  my @out;
  push @out, qq(next="$next")  if defined $next;
  push @out, qq(output="$out") if defined $out ;
  $o .= <<EOS;
	  <when state="$from" through="$to" multiplier="$mult" @out />
EOS
  $o
}

my $merge_states_6_and_4 = 1;
my $do_hex5 = 0;			# Won’t install with this…  (Even with $merge_states_6_and_4)

sub output_hex_input ($$$) {	# above 4-hex-digits input often overloads stack of Apple’s programs.  At start state in $states{'1of4'}[0].
  my($self, $states, $HEX, $o) = (shift, shift, shift, '');	# $HEX one of "-u\x20_+=0-9a-f"
  unless ($HEX =~ /[0-9a-f]/i) {
    return $do_hex5 ? <<EOS : <<EOS;
            <!-- switch 4-to-5-to-6-digit-HEX input -->
	  <when state="hex4" next="hex5" />
	  <when state="hex5" next="hex6" />
EOS
            <!-- switch 4-to-6-digit-HEX input -->
	  <when state="hex4" next="hex6" />
EOS
  }
  my $i = hex $HEX;
  my @O = map { [$states->{($_+1).'of4'}[0] + $i] } 0..3;
  $O[4] = [undef, $i];
#  $O[4] = qq(output="&#x002$HEX;");
#  $O[4] = qq(next="5000");
  $o .= <<EOS;
            <!-- 4-digit-HEX input -->
	  <when state="hex4" next="$O[1][0]" />
EOS
#	  <when state="0" through="4095" multiplier="16" output="&#x0000;" />
#	  <when state="4096" through="4351" multiplier="16" next="0"] />
#	  <when state="4352" through="4367" multiplier="16" next="4096"] />
#	  <when state="4368" multiplier="16" next="4352"] />
  $o .= <<EOS . $self->output_state_range($states->{"${_}of4"}[0], $states->{"${_}of4"}[1], 16, $O[$_][0], $O[$_][1])
		<!-- hex digit No. $_ of 4 -->
EOS
    for 2..4;	# ($HEX eq '9' ? 4 : 3);			# 2..4; bisect installation problems here

#  return $o unless 15 >= hex $HEX;		# debugging only

  @O = map { [$states->{($_+1).'of6'}[0] + $i] } 0..5;
  $O[2][0]--;			# We start with U+01..., not U+00....
  $O[6] = [undef, 0xDC00 + $i];
  $o .= $do_hex5 ? <<EOS : <<EOS;			# Special-case input of the first two hex digits:
            <!-- 5/6-digit-HEX input -->
EOS
            <!-- 6-digit-HEX input -->
EOS
  # $states->{"2of6"}[0] is U+0xxxxx=hex5	hex5 and hex6 differs only in treatment of 0, and of 1 0
  # $states->{"2of6"}[1] is U+1xxxxx			hex5: 1 0  —→ U+010xxx
  # $states->{"3of6"}[0] is U+01xxxx			hex6: 1 0  —→ U+10xxxx
  # $states->{"3of6"}[1] is U+10xxxx    	hex5: 0 —→ hex4, 1 —→ U+01xxxx, rest X —→ U+0Xxxx
  #                                     	hex6: 0 —→ hex5, 1 —→ U+1xxxxx, rest X —→ U+0Xxxx
  $o .= <<EOS if $HEX =~ /[01]/;
	  <when state="hex6" next="$O[1][0]" />
EOS
  # What follows is a complete mess, since with $do_hex5 the resulting layout won’t install
  $o .= <<EOS if $do_hex5 and not $HEX =~ /[01]/;	# hex6 same as after 0
	  <when state="hex5" next="$O[2][0]" />
	  <when state="$states->{"2of6"}[0]" next="$O[2][0]" />
	  <when state="hex6" next="$O[2][0]" />
EOS
  $o .= <<EOS if $do_hex5 and $HEX =~ /1/;		# 0 after (U+)0, proceed as in hex4; after (U+)1, process only 0 as hex6
	  <when state="hex5" next="$O[2][0]" />
EOS
  $o .= <<EOS if $do_hex5 and $HEX =~ /0/;		# 0 after (U+)0, proceed as in hex4; after (U+)1, process only 0 as hex6
	  <when state="hex5" next="hex4" />
EOS
  $o .= <<EOS if $HEX =~ /0/;		# 0 after (U+)0, proceed as in hex4; after (U+)1, process only 0 as hex6
		<!-- 2nd digit of U+00xxxx -->
	  <when state="$states->{"2of6"}[0]" next="hex4" />
		<!-- 2nd digit of U+10xxxx -->
	  <when state="$states->{"2of6"}[1]" next="$states->{"3of6"}[1]" />
EOS
  $o .= <<EOS unless $HEX =~ /0/;	# After (U+)0, normal: after (U+)1, process as hex5 (as if all is preceeded by 0)
		<!-- 2nd digit x of U+0xyyyy -->
	  <when state="$states->{"2of6"}[0]" next="$O[2][0]" />
EOS
  $o .= <<EOS if $do_hex5 and not $HEX =~ /0/;	# After (U+)0, normal: after (U+)1, process as hex5 (as if all is preceeded by 0)
	  <when state="$states->{"2of6"}[1]" next="$O[3][0]" />
EOS
  $o .= <<EOS . $self->output_state_range($states->{"${_}of6"}[0], $states->{"${_}of6"}[1], 16, $O[$_][0], $O[$_][1])
		<!-- hex digit No. $_ of 6 -->
EOS
    for 3;	# ($HEX eq '9' ? 4 : 3);			# 2..4; bisect installation problems here
  # VARIANT (A): for every one of 256 states, individually emit a surrogate (with multiplier 4), and set the next state (in B..B+3)
  # VARIANT (C): for every $in_group of 256 states, emit its surrogate (with multiplier 4).
  #              This creates a spread of "next states" of size M-3, with M = 4*$in_group.
  #		 Create next state in ranges (B .. B+M-3) (B+M .. B+2M-3) (B+2M .. B+3M-3) (B+3M .. B+4M-3)
  #			depending on ($i & 3).   [Later, we should process every range with multiplier=0.]
  my $next_base = ($merge_states_6_and_4 and not $use_plan_c) ? $states->{"3of4"}[0] + 0xDC : $states->{"5of6"}[0];
  my $in_group = $use_plan_c ? $in_group_4of6_plan_c : 1;
  my $spread_next = $use_plan_c ? 4*$in_group_4of6_plan_c - 3 : 1;
  $o .= $use_plan_c ? <<EOS : <<EOS;
		<!-- hex digit No. 4 of 6;
			treat possible states (of 256) in groups of $in_group_4of6_plan_c;
			this creates a correct "output", but proliferates
			the number of states from 4 to 4*$in_group_4of6_plan_c -->
EOS
		<!-- hex digit No. 4 of 6; treat every possible state (of 256) individually -->
EOS
  for my $j (0 .. ((0x100/$in_group)-1)) {
    my($J, $n, $O) = ($states->{"4of6"}[0] + $j*$in_group, $next_base + ($i & 0x3)*$spread_next, 0xD800 + 4*$j*$in_group + ($i>>2));
    XML_format($O = chr $O);
    if ($use_plan_c) {
      my $T = $J + $in_group_4of6_plan_c -1;
      $o .= <<EOS;
	  <when state="$J" through="$T" multiplier="4" next="$n" output="$O" />
EOS
    } else {
      $o .= <<EOS;
	  <when state="$J" next="$n" output="$O" />
EOS
	# ($HEX eq '9' ? 4 : 3);			# 2..4; bisect installation problems here
    }
  }
  if ($use_plan_c) {
      my $doc = $merge_states_6_and_4 ? '; redirect to low surrogates' : '';
      $o .= <<EOS;
		<!-- hex digit No. 5 of 6$doc.
			Every of 4 needed states is actually repeated
			$in_group_4of6_plan_c times (with step 4). -->
EOS
    for my $k (1 .. $in_group_4of6_plan_c) {
#    for my $j (0 .. 3) {
      my $n = $next_base + ($k-1)*4;
      my $T = $n + 3;
      my $next = ($merge_states_6_and_4 ? $states->{"4of4"}[0] + 0xDC0 + $i: $O[5][0]);
      $o .= <<EOS;
	  <when state="$n" through="$T" multiplier="16" next="$next" />
EOS
    }
  }
  
  unless ($merge_states_6_and_4) {
    $o .= $self->output_state_range($states->{"${_}of6"}[0], $states->{"${_}of6"}[1], 16, $O[$_][0], $O[$_][1])
      for ($use_plan_c ? 6 : 5) .. 6;	# ($HEX eq '9' ? 4 : 3);		# 2..4; bisect installation problems here
  }
  $o
}

sub output_hex_term ($$) {		# only 4-hex-digits input supported now.  First state in $states{'1of4'}[0].
  my($self, $states) = (shift, shift);
  my $o = <<EOS;
           <!-- 4-digit-HEX input -->
	<when state="hex4" output="U-" />
EOS
  my @hd = (0..9, 'A'..'F');
  for my $n (1 .. 3) {
    for my $i (0 .. ((16**$n)-1)) {
      my $N = $n + 1;
      my $I = $states->{"${N}of4"}[0] + $i;
      my $hex = sprintf "%0${n}X", $i;
      $o .= <<EOS;
	<when state="$I" output="U-$hex" />
EOS
    }
  }
  $o .= $do_hex5 ? <<EOS :  <<EOS;
           <!-- 5/6-digit-HEX input -->
	<when state="hex5" output="U+0" />
	<when state="hex6" output="U+" />
EOS
           <!-- 6-digit-HEX input -->
	<when state="hex6" output="U+" />
EOS

  return $o;		# the rest creates problems: see iz-Latin-hex6-vis3a.keylayout

  $o .= <<EOS;
	<when state="$states->{"2of6"}[0]" output="U+0" />
	<when state="$states->{"2of6"}[1]" output="U+1" />
EOS
  for my $n (2 .. 3) {
    for my $i (0 .. ((16**($n-1))-1)) {
      my $N = $n + 1;
      my $I = $states->{"${N}of6"}[0] + $i;
      my $hex = sprintf "%0${n}X", $i + 16**($n-2);
      $o .= <<EOS;
	<when state="$I" output="U+$hex" />
EOS
    }
  }
  $o
}

my $junkHEX = <<EOJ;
After +0yz or +10z (16*16 states); instead of 4434 should put 4434 + 0..3
<when state="4438" through="4701" multiplier="16" next="4434" output="&#xD800;"] />

	WRONG!!!  Need different multipliers for next and for output; so need 256 individual declarations
	Instead: use multiplier="4" (so that the output char is correct; next state takes 4K values, out of which we
	need only last two bits (manually inserted via next="" above); so we need 1K declarations for per-ultimate???

	So: maybe have 16 declarations for "After +0yz or +10z"; this way, next state takes 64 values, of which
	we may make account for by 16 declarations.  (32 total per 22 chars 0-9a-fA-F.)

	Or: maybe have 16 declarations for "After +0yz or +10z"; each creates a range of 64 possible "next" states;
	but we create 4 groups of such states.  So we may make account for by 4 declarations.  (20 total per 22 chars 0-9a-fA-F.)
EOJ

#sub XML_format ($) { $_[0] =~ s/([&""''\x00-\x1f\x7f-\x9f\s<>]|$rxCombining|$rxZW)/ sprintf '&#x%04X;', ord $1 /ego;
#		     # Avoid "Malformed UTF-8 character (fatal)" by not puting in a REx
#		     $_[0] =~ s/(.)/ sprintf '&#x%04X;', ord $1 /ego if length $_[0] eq 1 and 0xd000 <= ord $_[0] and 0xdfff >= ord $_[0]}
sub XML_format ($) {
  my @c = split //, $_[0];
  for my $c (@c) {
    if (0xd000 <= ord $c and 0xdfff >= ord $c) {
      $c = sprintf '&#x%04X;', ord $c;
    } else {
      $c =~ s/([&""''\x00-\x1f\x7f-\x9f\s<>]|$rxCombining|$rxZW)/ sprintf '&#x%04X;', ord $1 /ego;
    }
  }
  $_[0] = join '', @c;
}
sub XML_format_UTF_16 ($) {
  $_[0] =  to_UTF16LE_units $_[0];
  XML_format $_[0];
}

my %OEM2ctrl = (qw( OEM_102 0    OEM_MINUS), "\x1f", OEM_4 => "\x1b", OEM_5 => "\x1c", OEM_6 => "\x1d",
		CLEAR => "\x1b");	# [, \, ]
my %OEM2cmd = (qw( OEM_102 §    OEM_MINUS - ));
sub AppleMap_i_j ($$$$$;$$$$) {	# http://forums.macrumors.com/archive/index.php/t-780577.html
  my($self, $K,    $l,    $sh,   $caps, $use_base, $dd, $map, $override) =
    (shift, shift, shift, shift, shift, shift, shift || {}, shift || {}, shift || {dup => {}});
  my $A2l = [ @{ $self->AppleMap_Base($K) } ];	# Deep copy
  my $dup = $override->{dup};
  for my $from (keys %$dup) {
    $A2l->[$from] = $A2l->[$dup->{$from}];
  }
  my $F = $self->get_deep($self, @$K);		# Presumably a face hash, as in $K = [qw(faces US)]
  my $L = [map $self->{layers}{$_}, @{$F->{layers}}];
  $L = $L->[$l];
  my $B = $use_base && $self->Base_VK_names($K);	# Partially implemented: use Base_VK_names instead of the real $F (VK_ code)
  $B = [map {defined() && /^\w$/ ? lc $_ : $_} @$B] if ($use_base || 0) > 0;
  @AppleMap = _AppleMap unless @AppleMap;
  warn 'AppleMap too long' if $#AppleMap >= 127;
  my $o = '';
  for my $i (0..127) {
    my($I, $d, $c, $force_o) = ($A2l->[$i], 0);	# offset inside the layout array
    $c = $override->{"$l-$sh-$caps-vk=$i"} || $override->{"$l-$sh--vk=$i"} unless $use_base;	# $caps is 0 or 1
#    $force_o++ if defined $use_base and $use_base eq '0';
    $c = $use_base ? $B->[$I] : $L->[$I][$sh] if not defined $c and defined $I;
    if (($use_base || 0) < 0) {			# Control
      $force_o++;
      if (!defined $c) {			# ignore
      } elsif ($c =~ /^[A-Z]$/) {
        $c = chr( 1 + ord($c) - ord 'A');
      } elsif ($c !~ /^[-0-9=.*\/+]$/) {
        $c = $OEM2ctrl{$c};			# mostly undef
      }
    } elsif ($use_base) {
# warn "COMMAND-SPACE: c=<$c> OEM=<$OEM2cmd{$c}> ctrl=$oem_control{$c}" if 49 == $i;
      my $tr;
      if (!defined $c) {			# ignore
      } elsif (defined($tr = $OEM2cmd{$c})) {
        $c = $tr;
      } elsif ($c eq 'SPACE') {	# %oem_control does follow the pattern below
        $c = ' ';
      } elsif (defined($tr = $oem_control{$c})) {
        $tr =~ s/(?<=.).*//;
        $c = $tr;
      } else {
        undef $c;
      }
    }
    $c = $AppleMap[$i] unless defined $c; # Fallback to US (apparently, there is no unbound "ASCII" keys in maps???); dbg to "\xffff" #
      
    $o .= <<EOK, next unless defined $c;
            <!-- gap, $i -->
EOK
    $d = $c->[2] || 0 if ref $c;
    $c = $c->[0] if ref $c;
    # On windows, CapsLock flips the case; on Mac, it upcases
    # ($c) = grep {$_ ne $c} uc $c, ucfirst lc $c, lc $c if !$d and $caps and (lc $c ne uc $c or lc $c ne ucfirst lc $c);
    $c = uc $c if !$d and $caps;
    $dd->{$c}[1]++ if $d > 0;			# 0 for normal char, 1 for base prefix; not for hex4/hex6
    $override->{extra_actions}{$c}++ if $d < 0;
    my $M = (!$force_o and $d >= 0 and $map->{$self->keys2hex($c)});
    my $pr = $M ? 'a_' : '';
    $dd->{$c}[0] = $c if $M or $d > 0;		# 0 for normal char, 1 for base prefix
    my($how, $pref) = ($d || $M) ? ('action', ($M ? 'a_' : '') . ($d > 0 ? 'pr_' : (!$d && '_'))) : ('output', '');
    ($how eq 'output') ? XML_format_UTF_16 $c : XML_format $c;
    $o .= <<EOK;
            <key code="$i" $how="$pref$c" />
EOK
  }
  $o
}

my $hex_states;
sub AppleMap_prefix_map ($$$$$;$$) {
  my($o, $self, $kk, $pref, $M, $v, $doHEX, $override) = ('', shift, shift, shift, shift || {}, shift, shift, shift || {});
  XML_format (my $k = $kk);
  my $pr = $M ? 'a_' : '';
  my $prefix = $pref ? 'pr_' : '_';
  $o .= <<EOK;
	<action id="$pr$prefix$k">
EOK
  # A character and a prefix key with the same ordinal differ only in this:
  XML_format (my $oo = $v->[0]);
  my $todo = $pref ? qq(next="st_$oo") : qq(output="$oo");
  $o .= <<EOK;
	  <when state="none" $todo />
EOK
  for my $st (sort keys %{$M || {}}) {
    my $v0 = $M->{$st};
    XML_format ($st = my $st0 = chr hex $st);
    my $KK  = $self->key2hex($kk);
    my $ST0 = $self->key2hex($st0);
    my $v = $override->{"+$st0+$kk"} || $override->{"+$ST0+$kk"}
      ||    $override->{"+$st0+$KK"} || $override->{"+$ST0+$KK"} || $v0;
    my($d, $T) = $v->[2] || 0;
    $T = chr hex $v->[0] if $d >= 0;
    if ($d > 0) {
      XML_format $T;
      $T = qq(next="st_$T");
    } elsif ($d < 0) {		# Literal state
      $T = qq(next="$v->[0]");
    } else {
      XML_format_UTF_16 $T;
      $T = qq(output="$T");      
    }
    $o .= <<EOK;
	  <when state="st_$st" $T />
EOK
  }
  $o .= $self->output_hex_input($hex_states, $v->[0]) if $doHEX and $v->[0] =~ /^[-u\x20_+=0-9a-f]\z/i;
  $o .= <<EOK;
	</action>
EOK
  $o;
}

sub AppleMap_prefix ($$;$$$$$$) {	# http://forums.macrumors.com/archive/index.php/t-780577.html
  my($self, $dd, $do_initing, $term, $map, $show, $override, $act) = (shift, shift, shift, shift, shift || {}, shift, shift, shift);
  my $o = '';

  my %e = %{ $override->{extra_actions} || {}};	# Deep copy
  ($do_hex5 and $e{hex5}++), $e{hex6}++ if $e{hex4};
  my @o = @$override{grep /^\+/, keys %$override};			# honest bindings, not extra_actions/etc
  @o = map chr hex $_->[0], grep $_->[2] > 0, @o;			# dead keys
  unless (%$act) {	# Treat states created by the actions only
    my %states;
    $states{$_}++ for keys(%e), @o, grep $dd->{$_}[1], keys %$dd;
    for my $v (values %$map) {	# hash indexed by the prefix key
      for my $out (values %$v) {
        next if not $out->[2];
        my $k = $self->charhex2key($out->[0]);
        $states{$k}++;
	my $v;
        $act->{$k} = [$k] unless $v = $dd->{$k} and $v->[1];	# Skip if terminator was already created; do not create fake values
      }
    }
    my $states = 10 + keys(%states);			# Was 4100; 10: "just in case"
    $hex_states = alloc_slots( $states, $use_plan_c ? \@state_cnt_c : ($use_plan_b ? \@state_cnt_b : \@state_cnt_a));
  }

  if ($term and not $do_initing) {	# Treat states created by the actions only
    $dd = $act;				# A terminator MUST be created for every state
  }

  my $doHEX = grep $e{"hex$_"}, 4,5,6;
  for my $kk (sort keys %$dd) {
    my $v = $dd->{$kk};
    XML_format (my $k = $kk);
    next if !!$do_initing != !!$v->[1];

    if ($term) {
      my $Show = $show->{$self->key2hex($kk)};
      $Show = $kk unless defined $Show;
      $Show =~ s/^(?=$rxCombining)/ /;
      XML_format $Show;
      $o .= qq(\t<when state="st_$k" output="$Show" />\n);
      next;
    }

    my $M = $map->{$self->keys2hex($kk)};
    $o .= $self->AppleMap_prefix_map($kk, $do_initing, $M, $v, $doHEX, $override);
  }
  for my $a ( ($do_initing and not $term) ? sort keys %e : () ) {
    my $add = ($a =~ /^hex4\z/ and ($do_hex5 ? <<EOS : <<EOS));
	  <when state="hex4" next="hex5" />
	  <when state="hex5" next="hex6" />
EOS
	  <when state="hex4" next="hex6" />
EOS
    $o .= <<EOS;					# Allow similar specifications of bindings of base map and deadkey maps
	<action id="$a">
	  <when state="none" next="$a" />
$add	</action>
EOS
  }
  $o .= $self->output_hex_term($hex_states) if $term and $doHEX and not $do_initing;	# Do only once, at the end
  $o
}

1;

__END__
