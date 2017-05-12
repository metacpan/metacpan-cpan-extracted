use strict;
use warnings;
use Test::Requires 'Template';
use Test::More;
use Tiffany;
use Tiffany::TT;

{
    eval {
        my $tmpl = Tiffany::TT->new();
        $tmpl->render('t/tmpl/unknown.tt', {name => 'john'});
    };
    ok $@;
}

{
    my $tmpl = Tiffany::TT->new();
    is $tmpl->render('t/tmpl/foo.tt', {name => 'john'}), "Hello, john.\n";
}

{
    my $tmpl = Tiffany::TT->new();
    is $tmpl->render(\"Hello, [% name %].", {name => 'john'}), "Hello, john.";
}

done_testing;

