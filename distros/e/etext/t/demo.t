#!/usr/bin/perl
# Drive the demo (demo/etext.pl) without a user: TeX import and export
# of symbols, loading the sample document, saving and loading again.
use strict;
use warnings;
use utf8;
use FindBin;
use File::Temp qw(tempfile);
use Test::More;

BEGIN {
  eval { require Tk; 1 } or plan skip_all => "Tk not available: $@";
}
use Tk::eText;

my $probe = eval { MainWindow->new };
plan skip_all => "no X display available ($@)" unless $probe;
# The probe is hidden, not destroyed, until the demo's own MainWindow is
# gone (the last step).  Perl/Tk 804.036 keeps a stale option-lookup
# cache across a destroyed MainWindow (TK_BUGS W7, BUGS 21): a MainWindow
# created after one was destroyed may get wrong cget results or crash
# (under Wine, about one run in eight of this test did).  MainLoop
# returns only once the probe is gone too, so the last step destroys it,
# after $top.
$probe->withdraw;
plan tests => 25;
binmode(Test::More->builder->$_, ':utf8') for qw(output failure_output);

# The demo finds its helpers relative to $0 (FindBin), creates its own
# MainWindow and ends with MainLoop; the steps below run from inside it.
our ($text, $top);		# the demo's globals (package main)
my @bgerrors;
{
  no warnings 'redefine';
  *Tk::Error = sub { my ($w, $err, @loc) = @_; push @bgerrors, $err };
}
$SIG{ALRM} = sub { diag("timeout"); exit 1 }; alarm 120;
$0 = "$FindBin::Bin/../demo/etext.pl";

my @steps = (
  sub {
    isa_ok($text, 'Tk::eText', 'the demo text widget');
    $text->delete('1.0', 'end');
    $text->TeX_insert('insert', '$\alpha \leq \beta, \int_0^1 x$ caf\'e');
    my $got = $text->get('1.0', 'end');
    like($got, qr/\x{3b1}\s*\x{2264}\s*\x{3b2}/, 'TeX symbols are inserted as Unicode characters');
    like($got, qr/\x{222b}/, 'the integral sign too');
    is_deeply([$text->tagNames($text->search("\x{3b1}", '1.0'))], ['math', 'symbol'],
	      'symbol tagged with its font name');
  },
  sub {
    $text->tagAdd('sel', '1.0', 'end');
    my $tex = $text->range2TeX;
    like($tex, qr/\\alpha/, 'export gives \alpha back');
    like($tex, qr/\\leq/, 'export gives \leq back');
    like($tex, qr/\\beta/, 'export gives \beta back');
    unlike($tex, qr/unknown/, 'no symbol is unknown to the export');
    # A run with a value is listed as TagOn [name, value]: same export.
    $text->tagData('math', $text->search("\x{3b1}", '1.0'), {any => 'value'});
    ok(scalar(grep { ref $_ eq 'Tk::Text::TagOn' && UNIVERSAL::isa($_, 'ARRAY') && $_->[0] eq 'math' }
	      $text->blockList('1.0', 'end')), 'the math run is listed with its value');
    is($text->range2TeX, $tex, 'and exported as without one');
    # A mark with a value is listed as MarkRight [name, value]: the same.
    $text->markSet('valued', $text->search("\x{3b1}", '1.0'));
    $text->markData('valued', {any => 'mark value'});
    my ($m) = grep { ref $_ eq 'Tk::Text::MarkRight' && $_->name eq 'valued' }
		   $text->blockList('1.0', 'end');
    ok($m && UNIVERSAL::isa($m, 'ARRAY') && $m->[1]{any} eq 'mark value',
       'a mark with a value is listed as [name, value], name() reads it');
    is($text->range2TeX, $tex, 'and the export is as without one');
    $text->markUnset('valued');
    $text->tagRemove('sel', '1.0', 'end');
  },
  sub {
    $text->delete('1.0', 'end');
    $text->Load("$FindBin::Bin/../demo/save.tsf");
    $top->update;
    my $got = $text->get('1.0', 'end');
    like($got, qr/\x{3c9}/, 'the sample document has an omega');
    like($got, qr/\x{2297}\x{3bc}/, 'and a tensor product with a mu');
    is_deeply(\@bgerrors, [], 'loading the sample document gives no errors')
      or diag(@bgerrors);
  },
  sub {
    # The strokes are ornaments (2.08): the radical's sign is returned by
    # its layout callback, a broken line from the tick down to the
    # bottom, up to the top left of the contents and over them; the
    # fraction's bar is a template of the block type; the rules of a
    # table are black rectangles returned by its callback.
    my $H = 20 + 3 + 1;		# A row 20 high, 3 above it, 1 below.
    my @r = main::layoutRadical(['Radical', $text], 0, [1, 0, 30, 30, 20, 15]);
    my @orn = grep { $_->[0] eq 'line' } @r;
    ok(@r == 4 && @orn == 2 && $r[0][5] == $H && $r[1][1] > 0 && $r[1][2] == 3,
       'Radical: the block, the row moved right and down, two lines')
      or diag(explain(\@r));
    my @c = grep { /^-?[\d.]+$/ } @{$orn[0]}[1 .. 10];
    my ($bottom) = sort { $b <=> $a } map { $c[2*$_ + 1] } 0 .. $#c/2;
    ok(@c == 10 && $c[2] > $c[0] && $c[3] < $c[1] && $bottom == $H - 1
       && $c[7] == 1 && $c[9] == 1 && $c[8] == $r[0][3] - 1 && $c[6] < $r[1][1],
       'the sign: a tick up, down to the bottom, up to the top left of the row, the bar')
      or diag(explain($orn[0]));
    my $bar = $text->blockCget('Fraction', '-ornaments');
    ok(ref $bar && @$bar == 1 && $bar->[0][0] eq 'line'
       && !grep({ ref $_ && $_->[0] eq 'leaf' && $_->[1] != 0 }
		map { ref $_ ? ($_, @$_) : () } @{$bar->[0]}),
       'Fraction: the bar is a template on leaf 0');
    my @t = main::layoutTable(5, 5, 3, 3, 2, ['Table', $text], 0,
			      [[1, 0, 10, 10, 15, 12], [1, 0, 10, 10, 15, 12]],
			      [[1, 0, 10, 10, 15, 12], [1, 0, 10, 10, 15, 12]]);
    my @rules = grep { $_->[0] eq 'rectangle' } @t;
    is(scalar(@rules), 4 + 1 + 1, 'Table: rules around, between columns and rows, as rectangles');
  },
  sub {
    # Undo of a whole formula: the blocks (fractions, radicals...) come back.
    $text->delete('1.0', 'end');
    $text->editReset;
    $text->TeX_insert('insert', '$\frac{a+b}{\sqrt{c}} = x^{2}_{i}$');
    $top->update;
    my $formula = $text->get('1.0', 'end');
    my @blocks = grep { ref $_ eq 'Tk::Text::Block' } $text->blockList('1.0', 'end');
    cmp_ok(scalar(@blocks), '>=', 2, "the formula has blocks (" . scalar(@blocks) . ")");
    $text->editSeparator;
    $text->delete('1.0', 'end');
    $text->editUndo;
    $top->update;
    is($text->get('1.0', 'end'), $formula, 'undo brings the formula back');
    is(scalar(grep { ref $_ eq 'Tk::Text::Block' } $text->blockList('1.0', 'end')), scalar(@blocks), 'with its blocks');
    is_deeply(\@bgerrors, [], 'no errors from the layout callbacks') or diag(@bgerrors);
  },
  sub {
    my ($fh, $file) = tempfile(SUFFIX => '.tsf', UNLINK => 1);
    close $fh;
    # (Save/Load adds a newline at the end, as it always did; compare
    # the contents.)
    (my $before = $text->get('1.0', 'end')) =~ s/\n+\z//;
    $text->Save($file);
    $text->delete('1.0', 'end');
    $text->Load($file);
    $top->update;
    (my $after = $text->get('1.0', 'end')) =~ s/\n+\z//;
    is($after, $before, 'Save and Load round-trip the Unicode document');
    is_deeply(\@bgerrors, [], 'no errors during save/load') or diag(@bgerrors);
    $top->destroy;
    $probe->destroy;		# last: see the comment at its creation
  },
);
my $i = 0;
sub step {
  my $s = $steps[$i++];
  eval { $s->(); 1 } or diag("step $i failed: $@");
  $top->after(50, \&step) if $i < @steps;
}
BEGIN {
  require Tk;
  my $orig = \&Tk::MainLoop;
  no warnings 'redefine';
  *Tk::MainLoop = sub { $top->after(100, \&step); $orig->() };
}
do $0;
diag("demo died: $@") if $@;
