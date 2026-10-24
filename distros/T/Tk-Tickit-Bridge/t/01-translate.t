use v5.36;
use utf8;
use Test::More;
use Tk::Tickit::Bridge;

# Exercise translation independently of an X display or terminal handles.
my $bridge = bless {
    shift_mask => 1, control_mask => 4, alt_mask => 8,
}, 'Tk::Tickit::Bridge';
my @cases = (
    ['a', 'a', 0, 'text', 'a', 0],
    ['A', 'A', 1, 'text', 'A', 0],
    ['eacute', 'é', 0, 'text', 'é', 0],
    ['Return', "\r", 0, 'key', 'Enter', 0],
    ['KP_Enter', "\r", 0, 'key', 'Enter', 0],
    ['BackSpace', "\x08", 0, 'key', 'Backspace', 0],
    ['space', ' ', 0, 'key', 'Space', 0],
    ['ISO_Left_Tab', '', 0, 'key', 'Tab', Tickit::MOD_SHIFT()],
    ['F2', '', 4, 'key', 'F2', Tickit::MOD_CTRL()],
    ['Left', '', 9, 'key', 'Left', Tickit::MOD_SHIFT() | Tickit::MOD_ALT()],
    ['c', "\x03", 4, 'key', 'c', Tickit::MOD_CTRL()],
    ['C', "\x03", 5, 'key', 'c', Tickit::MOD_CTRL()],
    ['x', 'x', 8, 'key', 'x', Tickit::MOD_ALT()],
    ['exclam', '!', 9, 'key', '!', Tickit::MOD_ALT()],
    ['Prior', '', 0, 'key', 'PageUp', 0],
    ['Next', '', 0, 'key', 'PageDown', 0],
    ['Escape', "\e", 0, 'key', 'Escape', 0],
);
for my $c (@cases) {
    my ($sym, $char, $state, $type, $str, $mod) = @$c;
    is_deeply($bridge->translate_key($sym, $char, $state),
        {type => $type, str => $str, mod => $mod}, "$sym / state $state");
}
ok(!defined $bridge->translate_key('Shift_L', '', 1), 'ignore bare modifier');
ok(!defined $bridge->translate_key(undef, undef, undef), 'ignore empty event');
$bridge->{alt_mask} = 0x40;
is($bridge->translate_key('x', 'x', 0x40)->{mod}, Tickit::MOD_ALT(),
    'custom Alt mapping');
done_testing;
