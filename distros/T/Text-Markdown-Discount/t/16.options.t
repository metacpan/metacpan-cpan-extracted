use strict;
use warnings;
use Test::More;
use Text::Markdown::Discount;

my $checkbox = "- [x] done";

is(
    Text::Markdown::Discount::markdown($checkbox),
    "<ul>\n<li class=\"github_checkbox\"><input disabled=\"\" type=\"checkbox\" checked=\"checked\"/> done</li>\n</ul>\n",
    'checkbox list items remain enabled by default',
);

is(
    Text::Markdown::Discount::markdown(
        $checkbox,
        { normal_listitem => 1 },
    ),
    "<ul>\n<li>[x] done</li>\n</ul>\n",
    'normal_listitem disables checkbox list items',
);

is(
    Text::Markdown::Discount::markdown('![picture](pic)'),
    "<p><img src=\"pic\" alt=\"picture\" /></p>\n",
    'image alt text is not used as a title by default',
);

my $alt_as_title = Text::Markdown::Discount::markdown(
    '![picture](pic)',
    { alt_as_title => 1 },
);

isnt(
    $alt_as_title,
    Text::Markdown::Discount::markdown('![picture](pic)'),
    'alt_as_title is passed to bundled Discount',
);

TODO: {
    local $TODO = 'Discount 3.0.2.0 does not render images as expected with MKD_ALT_AS_TITLE';
    is(
        $alt_as_title,
        "<p><img src=\"pic\" title=\"picture\" alt=\"picture\" /></p>\n",
        'alt_as_title uses image alt text as its title',
    );
}

is(
    Text::Markdown::Discount::markdown(
        '[link](url){rel=nofollow}',
        { extended_attr => 1 },
    ),
    "<p><a href=\"url\" rel=nofollow>link</a></p>\n",
    'extended_attr enables link attribute suffixes',
);

is(
    Text::Markdown::Discount::markdown(
        '![picture](pic){width=10}',
        { extended_attr => 1 },
    ),
    "<p><img src=\"pic\" width=10 alt=\"picture\" /></p>\n",
    'extended_attr enables image attribute suffixes',
);

is(
    Text::Markdown::Discount::markdown('plain text', {}),
    Text::Markdown::Discount::markdown('plain text'),
    'an empty options hash uses the legacy defaults',
);

is(
    Text::Markdown::Discount::markdown(
        "# heading",
        {
            flags => Text::Markdown::Discount::MKD_NOPANTS(),
        },
    ),
    "<h1>heading</h1>\n",
    'flags supplies the legacy bitmap in options mode',
);

my $high_bit_flags =
      Text::Markdown::Discount::MKD_NOHEADER()
    | Text::Markdown::Discount::MKD_NOPANTS()
    | Text::Markdown::Discount::MKD_EXPLICITLIST();

is(
    Text::Markdown::Discount::markdown(
        $checkbox,
        {
            flags           => $high_bit_flags,
            normal_listitem => 1,
        },
    ),
    "<ul>\n<li>[x] done</li>\n</ul>\n",
    'new options remain independent of the highest legacy bitmap bit',
);

eval {
    Text::Markdown::Discount::markdown('plain text', { unknown => 1 });
};
like(
    $@,
    qr/\Aunknown markdown option\(s\): unknown/,
    'unknown options are rejected',
);

done_testing;
