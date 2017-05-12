use Test::More tests => 6;

use qbit;

is(
    d_gettext('Test string')->(),
    gettext('Test string'),
    "Check deferred gettext"
);

is(
    d_ngettext('Test string', 'Test strings', 2)->(),
    ngettext('Test string', 'Test strings', 2),
    "Check deferred ngettext"
);

is(
    pgettext('context', 'Test string'),
    'Test string',
    'pgettext()',
);

is(
    npgettext('context', 'Test string', 'Test strings', 2),
    'Test strings',
    'npgettext()',
);

is(
    d_pgettext('context', 'Test string')->(),
    pgettext('context', 'Test string'),
    'd_pgettext',
);

is(
    d_npgettext('context', 'Test string', 'Test strings', 2)->(),
    npgettext('context', 'Test string', 'Test strings', 2),
    'd_npgettext()',
);
