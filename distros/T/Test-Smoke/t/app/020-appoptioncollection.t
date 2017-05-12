#! perl -w
use strict;

use Test::More;
use Test::NoWarnings ();

use Test::Smoke::App::AppOption;
use Test::Smoke::App::AppOptionCollection;

{
    my $c = Test::Smoke::App::AppOptionCollection->new();
    isa_ok($c, 'Test::Smoke::App::AppOptionCollection');

    my $ok = $c->add(Test::Smoke::App::AppOption->new(
        name => 'test',
        option => '=s',
        default => 'smoke',
        helptext => 'Test::Smoke',
    ));
    is($ok, $c, "->add() returns \$self");
    is_deeply(
        $c->options_list,
        ['test=s'],
        "->options_list()"
    );
    is_deeply(
        $c->options_hash,
        { test => 'smoke' },
        "->options_hash()"
    );

    $c->add(Test::Smoke::App::AppOption->new(
        name    => 'verbose',
        option  => 'v=i',
        default => 0,
    ));

    is(
        $c->helptext,
        sprintf(
            $Test::Smoke::App::AppOption::HTFMT,
            '--test=s',
            "Test::Smoke"
        ),
        "->helptext()"
    );
}

Test::NoWarnings::had_no_warnings();
$Test::NoWarnings::do_end_test = 0;
done_testing();
