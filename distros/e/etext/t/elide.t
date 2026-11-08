#!/usr/bin/perl
# The -elide tag option: hidden text takes no room, like in Tk::Text,
# and still works with blocks.
use strict;
use warnings;
use Test::More;

BEGIN {
  eval { require Tk; 1 } or plan skip_all => "Tk not available: $@";
}
use Tk::eText;

my $mw = eval { MainWindow->new };
plan skip_all => "no X display available ($@)" unless $mw;
plan tests => 46;
$mw->geometry('+10+10');

my @bgerrors;
{
  no warnings 'redefine';
  *Tk::Error = sub { my ($w, $err, @loc) = @_; push @bgerrors, $err };
}

my @lines = ("hello world again\n", "a hidden line\n", "the end of this\n", "last\n");
sub make {
  my ($class) = @_;
  my $w = $mw->$class(-width => 30, -height => 8, -wrap => 'none')->pack;
  $w->insert('end', $_) for @lines;
  $w->tagConfigure('h', -elide => 1);
  $w->tagAdd('h', '1.4', '1.7');		# "o w"
  $w->tagAdd('h', '2.0', '3.0');		# the whole second line
  $w->tagAdd('h', '3.7', '3.15');		# the end of a line
  $mw->update;
  return $w;
}
my $ref = make('Text');
my $w = make('eText');

# 1. Compared with Tk::Text.
my (%bad, $queries);
sub cmp_both {
  my ($what, $method, @args) = @_;
  my @r = eval { $ref->$method(@args) };
  my @e = eval { $w->$method(@args) };
  $queries++;
  no warnings 'uninitialized';
  if ("@r" ne "@e") {
    $bad{$what}++;
    diag("$what: $method(@args): Text says [@r], eText says [@e]") if $bad{$what} <= 3;
  }
}
sub compare_all {
  for my $l (1 .. 4) {
    cmp_both('dlineinfo', 'dlineinfo', "$l.0");
    (my $n = $ref->index("$l.0 lineend")) =~ s/.*\.//;
    cmp_both('bbox', 'bbox', "$l.$_") for 0 .. $n;
  }
  my @b = $ref->bbox('1.0');
  for my $y ($b[1] + 2, $b[1] + $b[3] + 2, $b[1] + 2 * $b[3] + 2) {
    for (my $x = 0; $x < 200; $x += 4) {
      cmp_both('pixel', 'index', "\@$x,$y");
    }
  }
}
compare_all();
is($bad{dlineinfo} || 0, 0, 'dlineinfo with elided text like Tk::Text');
is($bad{bbox} || 0, 0, 'bbox with elided text like Tk::Text');
is($bad{pixel} || 0, 0, '@x,y with elided text like Tk::Text');
cmp_both('cget', 'tagCget', 'h', '-elide');
is($bad{cget} || 0, 0, 'tag cget -elide');
is($w->tagCget('h', '-elide'), 1, 'tag cget -elide is 1');
ok((grep { $_->[0] eq '-elide' } $w->tagConfigure('h')), 'tag configure lists -elide');

# Switch the elision off and on again: everything must come back.
$_->tagConfigure('h', -elide => 0) for $ref, $w;
$mw->update;
%bad = ();
compare_all();
is($bad{dlineinfo} || 0, 0, 'dlineinfo after -elide 0 like Tk::Text');
is($bad{bbox} || 0, 0, 'bbox after -elide 0 like Tk::Text');
$_->tagConfigure('h', -elide => 1) for $ref, $w;
$mw->update;
cmp_ok($queries, '>', 300, "that was $queries comparisons");

# 2. The geometry itself.
my @l1 = $w->dlineinfo('1.0');
my @l3 = $w->dlineinfo('3.0');
is($l3[1], $l1[1] + $l1[3], 'a fully elided line takes no vertical room');
my @b4 = $w->bbox('1.4');
my @b7 = $w->bbox('1.7');
is($b7[0], $w->bbox('1.3')->[0] + $w->bbox('1.3')->[2], 'text after an elided run follows the text before it');
is(($w->bbox('1.5'))[2] || 0, 0, 'an elided character has no width');
is($w->index('1.3 +2c'), '1.5', 'index arithmetic is not affected by elision');
is($w->get('2.0', '2.end'), 'a hidden line', 'get is not affected by elision');
$_->insert('1.5', 'XY') for $ref, $w;	# both, for the comparison below
$mw->update;
is($w->get('1.0', '1.end'), 'helloXY world again', 'insertion inside elided text');
is(($w->bbox('1.6'))[2] || 0, 0, 'the inserted text is elided too');
# search leaves elided text out, unless -elide is given (as Tk 8.4 does);
# so does the selection.  Compared with Tk::Text.
ok(!defined($w->search('hidden', '1.0')), 'search skips elided text');
is($w->search('-elide', 'hidden', '1.0'), '2.2', 'search -elide finds it');
{
  my ($sbad, $sq) = (0, 0);
  for my $pat ('o w', 'hell', 'hellorld', 'hidden', 'line', 'a h', 'end', 'the end', 'last', 'o.w', 'd.*n', 'ag', 'hello') {
    for my $kind ('-exact', '-regexp') {
      for my $dir ('-forwards', '-backwards') {
	for my $el ((), '-elide') {
	  for my $from ('1.0', 'end', '2.3') {
	    my ($cr, $ce) = (-1, -1);
	    my @r = $ref->search($kind, $dir, $el, -count => \$cr, '--', $pat, $from);
	    my @e = $w->search($kind, $dir, $el, -count => \$ce, '--', $pat, $from);
	    $sq++;
	    no warnings 'uninitialized';
	    if ("@r/$cr" ne "@e/$ce") {
	      $sbad++;
	      diag("search $kind $dir @{[$el || '']} '$pat' $from: Text [@r/$cr], eText [@e/$ce]") if $sbad <= 5;
	    }
	  }
	}
      }
    }
  }
  is($sbad, 0, "search with elided text like Tk::Text ($sq queries)");
  my $selbad = 0;
  for my $range (['1.0', '1.end'], ['1.5', '3.9'], ['2.0', '4.0'], ['1.0', 'end']) {
    my %got;
    for my $x ($ref, $w) {
      $x->tagRemove('sel', '1.0', 'end');
      $x->tagAdd('sel', @$range);
      $got{$x} = eval { $x->SelectionGet } // "undef: $@";
      $x->tagRemove('sel', '1.0', 'end');
      $mw->update;
    }
    $selbad++ if $got{$ref} ne $got{$w};
  }
  is($selbad, 0, 'the selection leaves elided text out like Tk::Text');
}
$w->tagConfigure('h', -elide => 0);
$mw->update;
cmp_ok(($w->bbox('2.3'))[2], '>', 0, 'elided text reappears');

# 3. Blocks.
$w->delete('1.0', 'end');
$w->insert('end', "abc defgh ijk\nsecond\n");
my $calls = 0;
$w->blockConfigure('B', -layoutcmd => sub { $calls++; return ([-1, 0, 0, $_[2][2], $_[2][2], $_[2][4], $_[2][5]], [1, 0, 0, $_[2][2], $_[2][2], $_[2][4], $_[2][5]]) });
$w->blockInsert('B', '1.4', '1.9');
$mw->update;
cmp_ok($calls, '>', 0, 'block laid out');
# The whole block hidden.
$w->tagAdd('h', '1.2', '1.12');
$w->tagConfigure('h', -elide => 1);
my $before = $calls;
$mw->update;
is($w->get('1.0', '1.end'), 'abc {defgh} ijk', 'block text intact while hidden');
is(($w->bbox('1.12'))[0], ($w->bbox('1.1'))[0] + ($w->bbox('1.1'))[2], 'hidden block takes no room');
$w->tagRemove('h', '1.0', 'end');
$mw->update;
# Elided text inside the block.
$w->tagAdd('h', '1.6', '1.8');
$mw->update;
my @in6 = $w->bbox('1.6');
my @in8 = $w->bbox('1.8');
is($in8[0], $in6[0], 'elided text inside a block takes no room');
is($w->get('1.5', '1.9'), 'defg', 'text inside the block intact');
my $cnt;
is($w->search(-count => \$cnt, 'dg', '1.0') . " $cnt", '1.5 2', 'search skips elided text inside a block');
is($w->search('-elide', -count => \$cnt, 'efg', '1.0') . " $cnt", '1.6 3', 'search -elide finds it inside the block');
# (The range must cover the block's end too: a tag that toggles inside
# a block does not apply to the block as a whole.)
$w->tagAdd('h', '1.4', '1.11');
$mw->update;
ok(!defined($w->search('dg', '1.0')) && $w->search('c  i', '1.0') eq '1.2', 'a hidden block is skipped by search');
$w->tagRemove('h', '1.0', 'end');
# 4. Many elided lines: scrolling and "see" must not get stuck.
$w->delete('1.0', 'end');
$w->insert('end', "line $_\n") for 1 .. 300;
$w->tagAdd('h', "$_.0", ($_ + 1) . ".0") for grep { $_ % 2 } 1 .. 300;
$w->tagConfigure('h', -elide => 1);
$mw->update;
$w->see('end'); $mw->update;
$w->yviewMoveto(0.5); $mw->update;
$w->see('1.0'); $mw->update;
$w->yviewScroll(3, 'pages'); $mw->update;
my @yv = $w->yview;
ok($yv[0] < $yv[1] && $yv[1] <= 1, "scrolling through 150 elided lines (@yv)");
# 5. The "display" and "any" index modifiers (Tk 8.5): stepping by
# "display indices" (or "display chars") leaves elided text out, and
# "display wordstart" / "display wordend" see the visible characters only.
$w->destroy;
$w = make('eText');
my %exp = ('1.3 +1 display indices' => '1.7', '1.3 +1 display chars' => '1.7',
  '1.8 -1 display indices' => '1.7', '1.7 -1 display indices' => '1.3',
  '1.5 +0 display indices' => '1.7', '1.5 -0 display indices' => '1.4', '1.4 -0 display indices' => '1.4',
  '1.5 +1 display indices' => '1.8', '1.5 -1 display indices' => '1.3',
  '1.17 +1 display indices' => '3.0', '1.end +1 display indices' => '3.0',
  '2.3 +0 display indices' => '3.0', '2.3 -0 display indices' => '2.0', '3.0 -1 display indices' => '1.17',
  '3.6 +1 display indices' => '3.15', '3.15 -1 display indices' => '3.6',
  '3.9 +0 display indices' => '3.15', '3.9 -0 display indices' => '3.7',
  '4.4 +1 display indices' => '5.0', '1.0 -1 display indices' => '1.0',
  '1.3 + 2 displayindices' => '1.8', '1.3 +1 d chars' => '1.7', '1.3 +1 disp indices' => '1.7',
  '1.3 +1 any chars' => '1.4', '1.3 +1 chars' => '1.4', '1.3 +1 indices' => '1.4',
  '1.10 display wordstart' => '1.0', '1.5 display wordstart' => '1.0', '1.4 display wordstart' => '1.0',
  '1.11 display wordstart' => '1.11', '3.9 display wordstart' => '3.15', '3.8 display wordend' => '4.0',
  '1.5 display wordend' => '1.11', '1.7 display wordend' => '1.11',
  # Tk 8.6 answers 1.5 to the next two: its "display wordend" walks into
  # elided text (TK_BUGS.md A6).
  '1.0 display wordend' => '1.11', '1.3 display wordend' => '1.11',
  '1.12 any wordend' => '1.17', '1.12 wordend' => '1.17', '1.0 any wordend' => '1.5');
my @bad = grep { $w->index($_) ne $exp{$_} } sort keys %exp;
is("@bad", '', scalar(keys %exp) . ' queries with display and any modifiers')
  or diag(map { "$_ -> " . $w->index($_) . " (expected $exp{$_})\n" } @bad);
# "display linestart", "display lineend" and "display lines" (the
# latter keeps the x position, as the Up and Down keys do).  Display
# lines never span logical lines here: an entirely elided line is a
# display line of no height, where Tk 8.5 merges it with the next one
# (so "2.3 display lineend" is 2.13 here and 3.15 there); "+N display
# lines" passes over it.  The dummy last line (end) is no display line.
%exp = ('1.5 display linestart' => '1.0', '1.5 display lineend' => '1.17',
  '2.3 display linestart' => '2.0', '2.3 display lineend' => '2.13',
  '3.9 display linestart' => '3.0', '3.9 display lineend' => '3.15', 'end display lineend' => '5.0',
  '1.3 +1 display lines' => '3.3', '1.10 +1 display lines' => '3.15', '1.17 +1 display lines' => '3.15',
  '3.3 -1 display lines' => '1.3', '4.2 -1 display lines' => '3.2', '4.4 -1 display lines' => '3.4',
  '3.3 +1 display lines' => '4.3', '4.3 +1 display lines' => '5.0', '5.0 +1 display lines' => '5.0',
  '1.3 -1 display lines' => '1.0', '1.3 + -1 display lines' => '1.0', '1.3 - -1 display lines' => '3.3',
  '2.3 +1 display lines' => '4.0', '2.3 -1 display lines' => '1.0', 'end -1 display lines' => '5.0',
  '1.3 +2 display lines' => '4.3', '1.3 +0 display lines' => '1.3', '1.3 +1 display lin' => '3.3');
@bad = grep { $w->index($_) ne $exp{$_} } sort keys %exp;
is("@bad", '', scalar(keys %exp) . ' queries with display linestart, lineend and lines')
  or diag(map { "$_ -> " . $w->index($_) . " (expected $exp{$_})\n" } @bad);

# In and around blocks: positions inside a block are hidden by a tag
# inside it; a wholly hidden block is stepped over.
{
  my $b = $mw->eText(-width => 30, -height => 4)->pack;
  $b->blockConfigure('Std');
  $b->insert('end', "ab cdefgh ij\npqrstuvw\n");
  $b->blockInsert('Std', '1.3', '1.9');		# ab {cdefgh} ij
  $b->tagConfigure('h', -elide => 1);
  $b->tagAdd('h', '1.5', '1.7');			# "de"
  $mw->update;
  my @got = map { $b->index($_) } '1.4 +1 display indices', '1.7 -1 display indices', '1.2 +1 display indices',
    '1.5 display wordend', '1.9 display wordstart',
    # A block is one unit of its display line; "display lines" lands
    # inside it at the x position (the visible "cfgh" start at column 3).
    '1.6 display linestart', '1.6 display lineend', '1.6 +1 display lines', '2.5 -1 display lines', '2.2 -1 display lines';
  $b->tagAdd('h', '1.3', '1.11');			# the whole block
  $mw->update;
  push @got, $b->index('1.2 +1 display indices'), $b->index('1.11 -1 display indices');
  is("@got", '1.7 1.4 1.3 1.10 1.4 1.0 1.14 2.4 1.8 1.2 1.11 1.2', 'display indices, lines and word boundaries in and around blocks');
  $b->destroy;
}

# Compared with Tcl/Tk (wish), which has had these modifiers since 8.5:
# every position of the text, -3 .. 3 display indices, and display
# wordstart (display wordend is left out, see A6 above).
SKIP: {
  my ($wish) = grep { -x $_ } map { "$_/wish" } split /:/, $ENV{PATH};
  skip 'no wish to compare with', 1 unless $wish;
  my @queries;
  for my $l (1 .. 4) {
    (my $n = $w->index("$l.0 lineend")) =~ s/.*\.//;
    for my $c (0 .. $n) {
      push @queries, "$l.$c " . ($_ < 0 ? "- @{[-$_]}" : "+ $_") . " display indices" for -3 .. 3;
      push @queries, "$l.$c display wordstart";
    }
  }
  require File::Temp;
  my ($fh, $file) = File::Temp::tempfile(SUFFIX => '.tcl', UNLINK => 1);
  print $fh "package require Tk\ntext .t -wrap none\n";
  print $fh "foreach l {", join(' ', map { (my $x = $_) =~ s/\n/\\n/; qq("$x") } @lines), "} { .t insert end \$l }\n";
  print $fh ".t tag configure h -elide 1\n.t tag add h 1.4 1.7; .t tag add h 2.0 3.0; .t tag add h 3.7 3.15\n";
  print $fh "puts \"version -> [package present Tk]\"\n";
  print $fh "foreach q {", join(' ', map { qq("$_") } @queries),
    "} { if {[catch {.t index \$q} r]} { set r ERROR }; puts \"\$q -> \$r\" }\nexit\n";
  close $fh;
  my %tk;
  my $ok = do {
    local $SIG{ALRM} = sub { die "timeout\n" };
    alarm 60;
    my $r = eval {
      open(my $out, '-|', $wish, $file) or die "cannot run wish: $!\n";
      while (<$out>) { chomp; $tk{$1} = $2 if /^(.*) -> (\S+)$/ }
      close $out;
      1;
    };
    alarm 0;
    $r && keys(%tk) > 1;
  };
  skip "wish could not be run ($@)", 1 unless $ok;
  my @diff = grep { ($tk{$_} // '?') ne $w->index($_) } @queries;
  is(scalar(@diff), 0, scalar(@queries) . " display-modifier queries answered like Tcl/Tk $tk{version}")
    or diag(map { "$_: wish $tk{$_}, eText " . $w->index($_) . "\n" } @diff[0 .. ($#diff > 5 ? 5 : $#diff)]);
}

# Display lines compared with wish: a wrapped text with elided ranges
# inside lines (an elided newline merges lines in Tk 8.5, not here),
# every position with "display linestart", "display lineend" and -2 ..
# 2 display lines.  The two must wrap alike for the answers to agree
# (Tk 8.5 lets a space hang over the right margin where Tk 8.4 and this
# widget need a pixel for it; the text avoids that case with this
# font), so the display line structure is compared first.  Tk 8.6's
# answer past the end of the text depends on the x position of the
# base ("end" or the last line), so those queries are left out.
SKIP: {
  my ($wish) = grep { -x $_ } map { "$_/wish" } split /:/, $ENV{PATH};
  skip 'no wish to compare with', 1 unless $wish;
  my @wrapped = ("hello world again and again until it goes around\n", "short\n",
		 "the end of this line is hidden but the text wraps\n",
		 "caf\x{e9} \x{e9}t\x{e9} \x{3b1}\x{3b2}\x{3b3} words with multi-byte characters here\n", "last\n");
  my $d = $mw->eText(-width => 20, -height => 12, -wrap => 'word', -font => ['Courier', -12])->pack;
  $d->insert('end', $_) for @wrapped;
  $d->tagConfigure('h', -elide => 1);
  $d->tagAdd('h', '1.4', '1.7'); $d->tagAdd('h', '3.7', '3.15'); $d->tagAdd('h', '4.5', '4.9');
  $mw->update;
  my @queries;
  for my $l (1 .. 5) {
    (my $n = $d->index("$l.0 lineend")) =~ s/.*\.//;
    for my $c (0 .. $n) {
      push @queries, "$l.$c display linestart", "$l.$c display lineend";
      push @queries, "$l.$c " . ($_ < 0 ? "- @{[-$_]}" : "+ $_") . " display lines" for -2 .. 2;
    }
  }
  my @starts; my $i = '1.0';
  while ($d->compare($i, '<', 'end')) { push @starts, $i; my $n = $d->index("$i display lineend +1c"); last if $n eq $i; $i = $n }
  require File::Temp;
  my ($fh, $file) = File::Temp::tempfile(SUFFIX => '.tcl', UNLINK => 1);
  print $fh "package require Tk\ntext .t -wrap word -width 20 -height 12 -font {Courier -12}\npack .t\n";
  print $fh "foreach l {", join(' ', map { (my $x = $_) =~ s/\n/\\n/; $x =~ s/([^\x00-\x7f])/sprintf('\\u%04x', ord $1)/ge; qq("$x") } @wrapped), "} { .t insert end \$l }\n";
  print $fh ".t tag configure h -elide 1\n.t tag add h 1.4 1.7; .t tag add h 3.7 3.15; .t tag add h 4.5 4.9\nupdate\n";
  print $fh "puts \"version -> [package present Tk]\"\n";
  print $fh "set i 1.0; set starts {}; while {[.t compare \$i < end]} { lappend starts \$i; set n [.t index \"\$i display lineend +1c\"]; if {\$n eq \$i} break; set i \$n }; puts \"starts -> [join \$starts ,]\"\n";
  print $fh "foreach q {", join(' ', map { qq("$_") } @queries),
    "} { if {[catch {.t index \$q} r]} { set r ERROR }; puts \"\$q -> \$r\" }\nexit\n";
  close $fh;
  my %tk;
  my $ok = do {
    local $SIG{ALRM} = sub { die "timeout\n" };
    alarm 60;
    my $r = eval {
      open(my $out, '-|', $wish, $file) or die "cannot run wish: $!\n";
      while (<$out>) { chomp; $tk{$1} = $2 if /^(.*) -> (\S+)$/ }
      close $out;
      1;
    };
    alarm 0;
    $r && keys(%tk) > 1;
  };
  skip "wish could not be run ($@)", 1 unless $ok;
  skip "the display lines differ (wish: $tk{starts}; eText: @{[join ',', @starts]}): other fonts?", 1
    unless $tk{starts} eq join(',', @starts);
  my $end = $d->index('end');
  my @compared = grep { ($tk{$_} // '') ne $end } @queries;
  my @diff = grep { ($tk{$_} // '?') ne $d->index($_) } @compared;
  is(scalar(@diff), 0, scalar(@compared) . " display-line queries answered like Tcl/Tk $tk{version}")
    or diag(map { "$_: wish $tk{$_}, eText " . $d->index($_) . "\n" } @diff[0 .. ($#diff > 5 ? 5 : $#diff)]);
  $d->destroy;
}

# The cursor keys of the widget skip elided text (Tk::Text's step into it).
$w->tagAdd('h', '3.0', '3.4');				# "the " hidden too
until ($w->viewable) { $mw->after(20); $mw->update }
$w->focusForce; $mw->update;
sub key { my ($k) = @_; $w->eventGenerate("<$k>"); $mw->update; return $w->index('insert') }
$w->markSet('insert', '1.3');
is(key('Right'), '1.7', '<Right> skips the hidden text');
is(key('Left'), '1.3', '<Left> skips it back');
is(join(' ', key('Shift-Right'), $w->tagRanges('sel')), '1.7 1.3 1.7', '<Shift-Right> selects across it');
$w->markSet('insert', '1.17');
is(key('Right'), '3.4', '<Right> skips the hidden line and the hidden start of the next');
is(key('Home'), '3.4', '<Home> goes to the first visible position of the line');
$w->markSet('insert', '3.5');
is(key('End'), '3.15', '<End> to the last');
$w->markSet('insert', '1.0');
is(key('Control-Right'), '1.11', '<Control-Right> ends the word beyond the hidden text');
is(key('Control-Left'), '1.0', '<Control-Left> starts it before');
# Home and End go to the start and the end of the display line (Tk 8.5;
# Tk::Text's go to the logical line's).
$w->configure(-wrap => 'char', -width => 10);
$w->delete('1.0', 'end');
$w->insert('end', "abcdefghijklmnopqrst\n");
$mw->update;
$w->markSet('insert', '1.15');
is(key('Home') . ' ' . key('End'), '1.10 1.20', '<Home> and <End> on a wrapped line go to the display line');
$w->markSet('insert', '1.5');
is(key('End') . ' ' . key('Home'), '1.9 1.0', 'and on its first display line');
is_deeply(\@bgerrors, [], 'no background errors') or diag(@bgerrors);
$ref->destroy;
$w->destroy;
$mw->destroy;
