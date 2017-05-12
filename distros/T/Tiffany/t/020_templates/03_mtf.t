use strict;
use warnings;
use Test::Requires 'Text::MicroTemplate';
use Test::More;
use Tiffany;
use Tiffany::Text::MicroTemplate::File;
use Scalar::Util qw/blessed/;

{
    eval {
        my $tmpl = Tiffany::Text::MicroTemplate::File->new();
        is $tmpl->render('t/tmpl/unknown.mt', 'john'), undef;
    };
    ok $@;
}

{
    my $tmpl = Tiffany::Text::MicroTemplate::File->new();
    my $out = $tmpl->render('t/tmpl/foo.mt', 'john');
    is $out, "hello, john.\n";
    ok !blessed($out);
}
{
    my $tmpl = Tiffany::Text::MicroTemplate::File->new();
    my $out = $tmpl->render(\'hello, <?= $_[0] ?>.', 'john');
    is $out, "hello, john.";
    ok !blessed($out);
}

done_testing;

