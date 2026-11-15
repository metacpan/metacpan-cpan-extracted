use 5.10.0;
use strict;
use warnings;
use utf8;
use Test::More;

{
    package urxvt;
    sub RS_RVid { 1 << 16 }
    sub RS_Sel { 1 << 17 }
    sub RS_Uline { 1 << 18 }
    sub ShiftMask { 1 }
    sub PrivMode_mouse_report { 1 << 10 }
}
{
    package urxvt::timer;
    sub new { bless {}, shift }
    sub cb { $_[0]{cb} = $_[1]; $_[0] }
    sub after { $_[0]{active} = 1; $_[0] }
    sub stop { $_[0]{active} = 0; $_[0] }
}
{
    package BidiExtension;
    do './misc/bidi' or die $@ || $!;
}
{
    package BidiTerminal;
    our @ISA = ('BidiExtension');

    sub new {
        my ($class, $lines, %args) = @_;
        my $self = bless {
            ncol => 16, top => 0, screen => 0, cursor => [-100, 0],
            resources => {}, rows => {}, wrapped => {}, beg => [0, 0], end => [0, 0], %args,
        }, $class;
        $self->{nrow} //= scalar @$lines;
        for my $index (0..$#$lines) {
            my $row = $self->{top} + $index;
            my $text = $self->special_encode($lines->[$index]);
            $self->{rows}{$row} = {
                text => $text . ' ' x ($self->{ncol} - length($text)),
                length => length($text), rend => [(0..$self->{ncol} - 1)],
            };
        }
        $self->on_start;
        return $self;
    }
    sub x_resource { $_[0]{resources}{$_[1]} }
    sub ncol { $_[0]{ncol} }
    sub nrow { $_[0]{nrow} }
    sub view_start { $_[0]{top} = $_[1] if @_ > 1; $_[0]{top} }
    sub current_screen { $_[0]{screen} }
    sub selection_screen { $_[0]{selection_screen} // $_[0]{screen} }
    sub screen_cur { @{$_[0]{cursor}} }
    sub ModMetaMask { 8 }
    sub priv_modes { $_[0]{priv_modes} // 0 }
    sub resource { $_[0]{resources}{$_[1]} }
    sub top_row { (sort { $a <=> $b } keys %{$_[0]{rows}})[0] }
    sub ROW_is_longer { $_[0]{wrapped}{$_[1]} }
    sub want_refresh { $_[0]{refresh_requested} = 1 }
    sub ROW_t {
        my ($self, $row, $new) = @_;
        return unless exists $self->{rows}{$row};
        my $old = $self->{rows}{$row}{text};
        substr($self->{rows}{$row}{text}, 0, length($new)) = $new if defined $new;
        return $old;
    }
    sub ROW_r {
        my ($self, $row, $new) = @_;
        my $old = $self->{rows}{$row}{rend};
        $self->{rows}{$row}{rend} = $new if defined $new;
        return $old;
    }
    sub ROW_l {
        my ($self, $row, $new) = @_;
        my $old = $self->{rows}{$row}{length};
        $self->{rows}{$row}{length} = $new if defined $new;
        return $old;
    }
    sub selection_beg {
        my $self = shift;
        $self->{beg} = [@_] if @_;
        return @{$self->{beg}};
    }
    sub selection_mark {
        my $self = shift;
        $self->{mark} = [@_] if @_;
        return @{$self->{mark} // [0, 0]};
    }
    sub selection_end {
        my $self = shift;
        if (@_) {
            my ($row, $col) = @_;
            ($row, $col) = ($row - 1, $self->ncol) if $col == 0;
            $col = $self->ncol if $col > $self->ROW_l($row);
            $self->{end} = [$row, $col];
        }
        return @{$self->{end}};
    }
    sub special_decode {
        my ($self, $text) = @_;
        return join '', map {
            $_ eq "\x{ffff}" ? '' : ($self->{composites}{$_} // $_)
        } split //, $text;
    }
    sub _compose {
        my ($self, $text) = @_;
        $self->{encoded}{$text} //= do {
            my $char = chr(0xe000 + scalar keys %{$self->{composites}});
            $self->{composites}{$char} = $text;
            $char;
        };
    }
    sub special_encode {
        my ($self, $text) = @_;
        my @cells;
        for my $char (split //, $text) {
            if ($char =~ /[\p{M}\p{Cf}]/) {
                die 'leading combining character' unless @cells;
                $cells[-1] = $self->_compose($self->special_decode($cells[-1]) . $char);
            } else {
                push @cells, $char;
                push @cells, "\x{ffff}" if $char =~ /[\x{4e00}-\x{9fff}\x{1f600}]/;
            }
        }
        return join '', @cells;
    }
    sub display {
        my ($self) = @_;
        $self->on_refresh_begin;
        my %visual = map { $_ => $self->special_decode($self->ROW_t($_)) }
            keys %{$self->{rows}};
        $self->on_refresh_end;
        return \%visual;
    }

    sub scr_xor_span {
        my ($self, $beg_row, $beg_col, $end_row, $end_col, $style) = @_;
        for my $row ($beg_row..$end_row) {
            my $from = $row == $beg_row ? $beg_col : 0;
            my $to = $row == $end_row ? $end_col : $self->ncol;
            $self->{rows}{$row}{rend}[$_] ^= $style for $from..$to - 1;
        }
    }

    sub scr_xor_rect {
        my ($self, $beg_row, $beg_col, $end_row, $end_col, $style1, $style2) = @_;
        for my $row ($beg_row..$end_row) {
            my @text = split //, $self->ROW_t($row);
            my $rend = $self->{rows}{$row}{rend};
            $rend->[$_] ^= $style1 for $beg_col..$end_col - 1;
            my $col = $end_col;
            while ($col-- > $beg_col && $text[$col] =~ /[\s\x{ffff}]/) {
                $rend->[$col] ^= $style2;
            }
            $rend->[$col] ^= $style2 if ++$col < $end_col;
        }
    }

    sub _reverse_selection {
        my ($self) = @_;
        return unless $self->{selection_op};
        my @span = ($self->selection_beg, $self->selection_end);
        my $style = urxvt::RS_Sel() | urxvt::RS_RVid();
        if ($self->{rectangular}) {
            $self->scr_xor_rect(@span, $style, $style | urxvt::RS_Uline());
        } else {
            $self->scr_xor_span(@span, $style);
        }
    }

    sub highlighted_text {
        my ($self, $row) = @_;
        # urxvt screen.C applies selection rendition BEFORE REFRESH_BEGIN and
        # removes it AFTER REFRESH_END. Include that native ordering here.
        $self->_reverse_selection;
        $self->on_refresh_begin;
        my @text = split //, $self->ROW_t($row);
        my $rend = $self->ROW_r($row);
        my $selected = join '', map { $rend->[$_] & urxvt::RS_Sel() ? $text[$_] : () } 0..$#text;
        $self->on_refresh_end;
        $self->_reverse_selection;
        return $self->special_decode($selected);
    }

    # Exercise the real extension hooks around urxvt's native copy rules:
    # end-exclusive columns, composite decoding, hard/soft line breaks, and
    # per-row whitespace trimming for rectangular selections (screen.C).
    sub copy {
        my ($self, $beg, $end, $rect) = @_;
        $self->{beg} = [@$beg];
        $self->{end} = [@$end];
        $self->{rectangular} = $rect;
        local $self->{making_selection} = 1;
        return $self->_native_copy($rect);
    }
    sub selection_make {
        my ($self, $time, $rect) = @_;
        return $self->_native_copy($rect);
    }
    sub _native_copy {
        my ($self, $rect) = @_;
        $self->{selection_op} = 'done';
        return $self->{selection} if $self->on_sel_make(123) || $self->{abort_selection};
        my @beg = $self->selection_beg;
        my @end = $self->selection_end;
        my $text = '';
        for my $row ($beg[0]..$end[0]) {
            my $from = $rect || $row == $beg[0] ? $beg[1] : 0;
            my $to = $rect ? $end[1] : $self->ROW_l($row);
            $to = $end[1] if $row == $end[0] && $to > $end[1];
            my $part = $self->special_decode(substr($self->ROW_t($row), $from, $to > $from ? $to - $from : 0));
            if ($rect) {
                $part =~ s/\s+$//;
                $part .= "\n";
            } elsif (!$self->{wrapped}{$row}
                && ($row != $end[0] || $to != $end[1])
                && ($row != $beg[0] || $beg[1] < $self->ncol)) {
                $part .= "\n";
            }
            $text .= $part;
        }
        return $self->{selection} unless length $text;
        $self->{selection} = $text;
        # Other sel_grab extensions must see logical text even when invoked
        # before bidi's restoration hook (hook order is unspecified).
        $self->{clipboard} = $text;
        $self->on_sel_grab(123);
        return $text;
    }
}

sub selects {
    my ($name, $term, $beg, $end, $expected, $rect) = @_;
    my %before = map { $_ => [
        $term->ROW_t($_), [@{$term->ROW_r($_)}], $term->ROW_l($_),
    ] } keys %{$term->{rows}};
    $term->display;
    is $term->copy($beg, $end, $rect), $expected, $name;
    is $term->{clipboard}, $expected, "$name reaches clipboard hooks";
    is_deeply [$term->selection_beg], $beg, "$name restores selection beginning";
    is_deeply [$term->selection_end], $end, "$name restores selection end";
    for my $row (sort keys %before) {
        is_deeply [$term->ROW_t($row), $term->ROW_r($row), $term->ROW_l($row)],
            $before{$row}, "$name restores row $row";
    }
}

my $term = BidiTerminal->new(['אבגד'], ncol => 12);
is $term->display->{0}, '        דגבא', 'RTL text is displayed at the right';
selects 'partial RTL drag', $term, [0, 8], [0, 10], 'גד';
selects 'RTL drag to the right edge', $term, [0, 10], [0, 12], 'אב';
selects 'whole RTL row', $term, [0, 0], [0, 12], "אבגד\n";

$term = BidiTerminal->new(['abc אבגד xyz'], ncol => 12);
is $term->display->{0}, 'abc דגבא xyz', 'mixed text display';
selects 'partial mixed run', $term, [0, 4], [0, 6], 'גד';
selects 'disjoint logical ranges', $term, [0, 6], [0, 10], 'אב x';
selects 'whole mixed row', $term, [0, 0], [0, 12], 'abc אבגד xyz';

$term = BidiTerminal->new(['abc אבגד xyz', 'a אבגד b'], ncol => 12);
selects 'multiline drag', $term, [0, 6], [1, 4], "אב xyz\na גד";
selects 'drag starting beyond the first row', $term, [0, 12], [1, 4], 'a גד';
selects 'rectangular drag', $term, [0, 4], [1, 6], "גד\nאב\n", 1;

$term = BidiTerminal->new(['abc אבגד xyz', 'a אבגד b'], ncol => 12, wrapped => { 0 => 1 });
selects 'soft-wrapped drag', $term, [0, 6], [1, 4], "אב xyza גד";

$term = BidiTerminal->new(['אבגד'], ncol => 12, top => -5);
is $term->display->{-5}, '        דגבא', 'scrollback is rendered in visual order';
selects 'scrollback drag', $term, [-5, 8], [-5, 10], 'גד';

$term = BidiTerminal->new(['abc אבגד xyz'], ncol => 12);
$term->display;
$term->{rows}{0}{text} = 'abc דגבא xyz';
is $term->copy([0, 4], [0, 6]), 'בא', 'changed rows do not reuse a stale character map';

$term = BidiTerminal->new(['a א│ב c'], ncol => 12);
selects 'field separator', $term, [0, 0], [0, 12], "a א│ב c\n";
$term = BidiTerminal->new(['a אב│'], ncol => 5);
is $term->display->{0}, 'a בא│', 'trailing field separator is retained';
selects 'trailing field separator', $term, [0, 2], [0, 5], 'אב│';

$term = BidiTerminal->new(['a אְב c'], ncol => 6);
is $term->display->{0}, 'a באְ c', 'a combining mark stays with its displayed base';
selects 'combining-character drag', $term, [0, 3], [0, 4], 'אְ';

$term = BidiTerminal->new(['a 漢אב c'], ncol => 8);
selects 'wide-character drag', $term, [0, 2], [0, 3], '漢';
selects 'wide-character continuation drag', $term, [0, 3], [0, 4], '漢';

$term = BidiTerminal->new(['a لح b'], ncol => 6);
selects 'Arabic copies original letters', $term, [0, 2], [0, 4], 'لح';
$term = BidiTerminal->new(['a لا b'], ncol => 6);
selects 'Arabic ligature copies both letters', $term, [0, 2], [0, 3], 'لا';
$term = BidiTerminal->new(['لا'], ncol => 4);
selects 'RTL Arabic ligature copies both letters', $term, [0, 2], [0, 3], 'لا';

$term = BidiTerminal->new(['a (אב) b'], ncol => 8, resources => {
    '%.LRE' => '\(', '%.PDF' => '\)',
});
selects 'inserted bidi marks are not copied', $term, [0, 0], [0, 8], 'a (אב) b';

$term = BidiTerminal->new(['plain text'], ncol => 12);
selects 'LTR selection remains native', $term, [0, 0], [0, 5], 'plain';
ok !$term->{selection_rows}, 'LTR selection does not replace terminal rows';

$term = BidiTerminal->new(['אבגד'], ncol => 12);
$term->display;
$term->{selection} = 'previous selection';
is $term->copy([0, 0], [0, 4]), 'previous selection', 'selecting only RTL padding leaves the selection alone';
ok !$term->{selection_rows}, 'empty selections leave no temporary rows';

sub mouse {
    my ($term, $hook, $row, $col, $time, $button, $state) = @_;
    return $term->$hook({ row => $row, col => $col, time => $time,
        button => $button // 1, state => $state // 0 });
}

$term = BidiTerminal->new(['אבגד'], ncol => 12);
$term->display;
ok mouse($term, 'on_button_press', 0, 8, 1000), 'bidi mouse press is handled';
is $term->{selection_op}, 'done', 'mouse press activates urxvt selection highlighting';
ok !defined($term->{selection}), 'activating the highlight does not replace the clipboard';
ok mouse($term, 'on_motion_notify', 0, 10, 1100), 'bidi mouse motion is handled';
is_deeply [$term->selection_beg], [0, 8], 'mouse start stays in visual coordinates';
is_deeply [$term->selection_end], [0, 10], 'mouse end is not clamped to the logical row length';
is_deeply [$term->selection_mark], [0, 8], 'the selection mark tracks the visual drag anchor';
ok mouse($term, 'on_button_release', 0, 10, 1200), 'bidi mouse release is handled';
is $term->{selection}, 'גד', 'actual mouse hooks select the displayed RTL characters';
is $term->ROW_l(0), 4, 'mouse hooks restore the logical row length';
is $term->special_decode($term->ROW_t(0)), 'אבגד        ', 'mouse hooks preserve logical screen text';

mouse($term, 'on_button_press', 0, 10, 2000);
mouse($term, 'on_motion_notify', 0, 8, 2100);
mouse($term, 'on_button_release', 0, 8, 2200);
is $term->{selection}, 'גד', 'dragging RTL text backwards gives the same selection';

$term = BidiTerminal->new(['abc אבגד xyz'], ncol => 12);
$term->display;
mouse($term, 'on_button_press', 0, 5, 1000);
mouse($term, 'on_button_release', 0, 5, 1050);
mouse($term, 'on_button_press', 0, 5, 1200);
mouse($term, 'on_button_release', 0, 5, 1250);
is $term->{selection}, 'אבגד', 'double click selects the visual word in logical order';
mouse($term, 'on_button_press', 0, 5, 1400);
mouse($term, 'on_button_release', 0, 5, 1450);
is $term->{selection}, 'abc אבגד xyz', 'triple click selects the whole logical line';

$term = BidiTerminal->new(['אבגד'], ncol => 12);
$term->display;
mouse($term, 'on_button_press', 0, 9, 1000);
mouse($term, 'on_button_release', 0, 9, 1050);
mouse($term, 'on_button_press', 0, 9, 1200);
mouse($term, 'on_button_release', 0, 9, 1250);
is $term->{selection}, 'אבגד', 'double click at the right edge adds no newline';

$term = BidiTerminal->new(['אבגד', 'הוזח'], ncol => 4, wrapped => { 0 => 1 });
$term->display;
mouse($term, 'on_button_press', 1, 1, 1000);
mouse($term, 'on_button_release', 1, 1, 1050);
mouse($term, 'on_button_press', 1, 1, 1200);
mouse($term, 'on_button_release', 1, 1, 1250);
is $term->{selection}, 'אבגדהוזח', 'double click follows words across soft-wrapped rows';

$term = BidiTerminal->new(['abc אבגד xyz'], ncol => 12);
$term->display;
mouse($term, 'on_button_press', 0, 4, 1000);
mouse($term, 'on_motion_notify', 0, 6, 1100);
mouse($term, 'on_button_release', 0, 6, 1200);
mouse($term, 'on_button_press', 0, 8, 2000, 3);
mouse($term, 'on_button_release', 0, 8, 2100, 3);
is $term->{selection}, 'אבגד', 'right click extends a visual selection';
mouse($term, 'on_button_press', 0, 10, 3000, 1, urxvt::ShiftMask());
mouse($term, 'on_button_release', 0, 10, 3100, 1, urxvt::ShiftMask());
is $term->{selection}, 'אבגד x', 'shift click extends a visual selection';

$term = BidiTerminal->new(['abc אבגד xyz', 'a אבגד b'], ncol => 12);
$term->display;
mouse($term, 'on_button_press', 0, 4, 1000, 1, 8);
mouse($term, 'on_motion_notify', 1, 6, 1100, 1, 8);
mouse($term, 'on_button_release', 1, 6, 1200, 1, 8);
is $term->{selection}, "גד\nאב\n", 'Meta drag makes a rectangular visual selection';

$term = BidiTerminal->new(['אבגד'], ncol => 12, priv_modes => urxvt::PrivMode_mouse_report());
$term->display;
ok !mouse($term, 'on_button_press', 0, 8, 1000), 'application mouse reporting is not intercepted';
ok mouse($term, 'on_button_press', 0, 8, 2000, 1, urxvt::ShiftMask()),
    'Shift still overrides application mouse reporting';
is_deeply [$term->selection_beg], [0, 8], 'Shift override starts a fresh visual drag';
mouse($term, 'on_motion_notify', 0, 10, 2100, 1, urxvt::ShiftMask());
mouse($term, 'on_button_release', 0, 10, 2200, 1, 0);
is $term->{selection}, 'גד', 'Shift-drag selects text in a mouse-reporting application';

$term = BidiTerminal->new(['plain text'], ncol => 12);
$term->display;
ok !mouse($term, 'on_button_press', 0, 0, 1000), 'plain-text mouse events stay native';

$term = BidiTerminal->new(['אבגד', 'אבגד', 'אבגד', 'אבגד', 'אבגד'],
    ncol => 12, nrow => 2, top => -3);
$term->view_start(-1);
$term->display;
mouse($term, 'on_button_press', -1, 8, 1000);
mouse($term, 'on_motion_notify', -2, 10, 1100);
my $timer = $term->{mouse_scroll_timer};
ok $timer->{active}, 'dragging above the viewport starts scrollback scrolling';
$timer->{cb}->();
is $term->view_start, -2, 'the held drag scrolls into history';
$timer->{cb}->();
is $term->view_start, -3, 'scrolling continues while the pointer stays outside';
$timer->{cb}->();
ok !$timer->{active}, 'scrolling stops at the oldest history row';
mouse($term, 'on_button_release', -3, 10, 1200);
ok !$term->{mouse_scroll_timer}, 'releasing the button removes the scrolling timer';

$term = BidiTerminal->new(['אבגד'], ncol => 12);
$term->display;
mouse($term, 'on_button_press', 0, 8, 1000);
$term->on_reset;
ok !$term->{mouse_button}, 'a terminal reset cancels an active mouse drag';

$term = BidiTerminal->new(['a 漢אב c'], ncol => 8);
$term->display;
mouse($term, 'on_button_press', 0, 3, 1000);
mouse($term, 'on_button_release', 0, 3, 1050);
ok !defined($term->{selection}), 'a click in a wide-character continuation does not copy text';
mouse($term, 'on_button_press', 0, 3, 2000);
mouse($term, 'on_motion_notify', 0, 4, 2100);
mouse($term, 'on_button_release', 0, 4, 2200);
is $term->{selection}, '漢', 'mouse dragging from a continuation selects the whole wide character';

$term = BidiTerminal->new(['אבגד'], ncol => 12, abort_selection => 1);
$term->display;
mouse($term, 'on_button_press', 0, 8, 1000);
mouse($term, 'on_motion_notify', 0, 10, 1100);
mouse($term, 'on_button_release', 0, 10, 1200);
ok !$term->{selection_rows}, 'an aborted copy restores temporary selection buffers';
is $term->special_decode($term->ROW_t(0)), 'אבגד        ', 'aborting a copy preserves the logical screen';
is $term->ROW_l(0), 4, 'aborting a copy restores row lengths';

$term = BidiTerminal->new(['abc אבגד xyz'], ncol => 12, cursor => [0, 4]);
$term->on_refresh_begin;
ok $term->ROW_r(0)->[7] & urxvt::RS_RVid(), 'fake cursor is rendered at the mapped visual column';
$term->on_refresh_end;
is_deeply $term->ROW_r(0), [0..11], 'refresh restores the original rendition';

my $reported_line = 'משמר הבחירות האזרח│השיבוצים נפתחים בימים הקרובים - עוד לא הצטרפת לווט        │ ';
$term = BidiTerminal->new([$reported_line], ncol => 80);
my $reported_visual = $term->display->{0};
my $reported_word = 'נפתחים';
my $word_col = index($reported_visual, scalar reverse $reported_word);
ok $word_col >= 0, 'reported word is present in the displayed field';
mouse($term, 'on_button_press', 0, $word_col, 1000);
mouse($term, 'on_motion_notify', 0, $word_col + length($reported_word), 1100);
is $term->highlighted_text(0), scalar(reverse $reported_word),
    'the reported Hebrew word is highlighted instead of the text at its logical columns';
is $term->highlighted_text(0), scalar(reverse $reported_word),
    'repainting keeps the highlight in the same visual columns';
is_deeply $term->ROW_r(0), [0..79], 'selection painting restores logical rendition';
mouse($term, 'on_button_release', 0, $word_col + length($reported_word), 1200);
is $term->{selection}, $reported_word, 'the reported word is copied in logical order';
is $term->highlighted_text(0), scalar(reverse $reported_word),
    'the reported word stays highlighted after releasing the mouse';

$term = BidiTerminal->new([$reported_line], ncol => 80);
$term->display;
mouse($term, 'on_button_press', 0, $word_col + 2, 1000);
mouse($term, 'on_button_release', 0, $word_col + 2, 1050);
mouse($term, 'on_button_press', 0, $word_col + 2, 1200);
is $term->highlighted_text(0), scalar(reverse $reported_word),
    'double-clicking the reported word highlights its visual columns';

$term = BidiTerminal->new(['אב'], ncol => 2);
$term->display;
mouse($term, 'on_button_press', 0, 0, 1000);
mouse($term, 'on_motion_notify', 0, 1, 1100);
is $term->highlighted_text(0), 'ב', 'a minimal RTL drag highlights the displayed letter';

$term = BidiTerminal->new(['abc אבגד xyz', 'a אבגד b'], ncol => 12);
$term->display;
mouse($term, 'on_button_press', 0, 4, 1000, 1, 8);
mouse($term, 'on_motion_notify', 1, 6, 1100, 1, 8);
is $term->highlighted_text(0), 'דג', 'rectangular highlighting stays at the first visual span';
is $term->highlighted_text(1), 'בא', 'rectangular highlighting stays at the second visual span';
is_deeply $term->ROW_r(0), [0..11], 'rectangle painting restores first-row rendition';
is_deeply $term->ROW_r(1), [0..11], 'rectangle painting restores second-row rendition';

$term = BidiTerminal->new(['אבגד'], ncol => 12);
$term->display;
mouse($term, 'on_button_press', 0, 0, 1000, 1, 8);
mouse($term, 'on_motion_notify', 0, 2, 1100, 1, 8);
is $term->highlighted_text(0), ' ', 'rectangular trailing-space styling uses visual whitespace';
is_deeply $term->ROW_r(0), [0..11], 'rectangle whitespace styling leaves no rendition behind';

done_testing;
