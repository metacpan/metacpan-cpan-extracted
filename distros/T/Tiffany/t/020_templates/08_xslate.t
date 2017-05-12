use strict;
use warnings;
use Test::Requires {
    'Text::Xslate' => 0.1056,
};
use Test::More;
use Tiffany::Text::Xslate;

{
    my $tmpl = Tiffany::Text::Xslate->new();
    is $tmpl->render('t/tmpl/foo.tx', {name => 'john'}), "Hello, john.\n";
}

{
    my $tmpl = Tiffany::Text::Xslate->new();
    is $tmpl->render(\'Hello, <: $name :>.', {name => 'john'}), "Hello, john.";
}
{
    my $tmpl = Tiffany::Text::Xslate->new({syntax => 'TTerse'});
    is $tmpl->render(\'Hello, [% name %].', {name => 'john'}), "Hello, john.";
}
{
    eval {
        my $tmpl = Tiffany::Text::Xslate->new();
        is $tmpl->render('unknown.tx', {name => 'john'}), "Hello, john.";
    };
    ok $@;
}

done_testing;

