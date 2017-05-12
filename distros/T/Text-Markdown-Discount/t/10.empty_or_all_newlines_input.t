use Test::More tests => 2;
use Text::Markdown::Discount;

# https://rt.cpan.org/Ticket/Display.html?id=73657

{
    local $@;
    eval {
        Text::Markdown::Discount::markdown("");
    };
    is($@, '');
}
{
    local $@;
    eval {
        Text::Markdown::Discount::markdown("\n\n\n\n");
    };
    is($@, '');
}

