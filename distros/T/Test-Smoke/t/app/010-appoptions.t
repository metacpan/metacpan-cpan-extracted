#! perl -w
use strict;
$|++;

use Test::More;
use Test::NoWarnings ();

use Test::Smoke::App::AppOption;

{
    my $o = Test::Smoke::App::AppOption->new(
        name   => 'klad',
        option => 'k=i',
        allow  => undef,
    );
    isa_ok($o, 'Test::Smoke::App::AppOption');

    is($o->name, 'klad', "Right name");
    is($o->option, 'k=i', "Right option value");
    is($o->gol_option, 'klad|k=i', "GetOptLong option");

    # check that no '|' is appended after ->name (=)
    is($o->option('=s'), '=s', "Change option");
    is($o->gol_option, 'klad=s', "GetOptLong changed (option ^=)");

    # check that no '|' is appended after ->name (empty)
    is($o->option(''), '', "Change option to empty");
    is($o->gol_option, 'klad', "GetOptLong otption (empty option)");

    # check that no '|' is appended after ->name (option == !)
    is($o->option('!'), '!', "Change option to bang");
    is($o->gol_option, 'klad!', "GetOptLong otption (option == !)");

    # check that no '|' is appended after ->name (option ^|)
    is($o->option('|k=s'), '|k=s', "Change option to ^|");
    is($o->gol_option, 'klad|k=s', "GetOptLong otption (option ^|)");

    # test show_helptext
    is($o->show_helptext, "--klad|k=s", "Simple helptext");
    is($o->helptext('This message'), "This message", "Setting of helptext");
    is_deeply($o->allow([]), [], "set allow([])");
    is(
        $o->show_helptext,
        sprintf($Test::Smoke::App::AppOption::HTFMT, '--klad|k=s', "This message"),
        "show_helptext without allowed"
    );
    my $allow = [qw/bling blang/];
    is_deeply($o->allow($allow), $allow, "Set allowed values");
    is(
        $o->show_helptext,
        sprintf(
            $Test::Smoke::App::AppOption::HTFMT,
            '--klad|k=s <blang|bling>',
            "This message"
        ),
        "show_helptext with allowed"
    );
}
{
    my $o = Test::Smoke::App::AppOption->new(
        name     => 'klad',
        option   => 'k=s',
        allow    => [qw/bling blang/],
        helptext => 'This message too',
    );
    isa_ok($o, 'Test::Smoke::App::AppOption');
    is(
        $o->show_helptext,
        sprintf(
            $Test::Smoke::App::AppOption::HTFMT,
            '--klad|k=s <blang|bling>',
            "This message too"
        ),
        "show_helptext with allowed"
    );
}
{
    my $o = Test::Smoke::App::AppOption->new(
        name     => 'klad',
        option   => 'k=s',
        allow    => [qw/bling blang/, qr/^blah/],
        helptext => 'This message too',
    );
    isa_ok($o, 'Test::Smoke::App::AppOption');
    ok( $o->allowed('bling'), "  Value 'bling' allowed");
    ok(!$o->allowed('blong'), "  Value 'blong' not allowed");
    ok( $o->allowed('blahdeeblah'), "  Value 'blahdeeblah' allowed");

    $o->allow(sub {
        my $v = shift;
        return (!defined $v) || ($v eq 'blah');
    });
    ok( $o->allowed(undef), "  Value <undef> allowed");
    ok( $o->allowed('blah'), "  Value 'blah' allowed");
    ok(!$o->allowed('bling'), "  Value 'bling' not allowed");

    $o->allow(undef);
    ok($o->allowed('bling'), "  Value 'bling' allowed");

    $o->allow([undef]);
    ok( $o->allowed(undef), "  Value <undef> allowed");
    ok(!$o->allowed('blah'), "  Value 'blah' not allowed");

}
{
    eval { Test::Smoke::App::AppOption->new() };
    like(
        $@,
        qr/Required option 'name' not given\./,
        "Must set 'name' on construction"
    );
    eval { Test::Smoke::App::AppOption->new(name => '') };
    like(
        $@,
        qr/Required option 'name' not given\./,
        "Must set 'name' on construction to an actual value"
    );
    eval {
        Test::Smoke::App::AppOption->new(
            name  => 'error',
            allow => 'not_an_arryref',
        );
    };
    like(
        $@,
        qr/^Option 'allow' must be an ArrayRef\|CodeRef\|RegExp when set/,
        "Check for 'allow'"
    );
}

Test::NoWarnings::had_no_warnings();
$Test::NoWarnings::do_end_test = 0;
done_testing();
