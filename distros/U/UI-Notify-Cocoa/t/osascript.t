use Test::More tests => 4;

BEGIN {
    use_ok 'UI::Notify::Cocoa';
}

ok(UI::Notify::Cocoa->show('message'), 'Calling with one argument');
ok(UI::Notify::Cocoa->show('title', 'message'), 'Calling with two arguments');
ok(UI::Notify::Cocoa->show('title', 'subtitle', 'message'), 'Calling with three arguments');

