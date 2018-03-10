use strict;
use warnings;
use Test2::Bundle::Extended -target => 'Test2::Tools::EventDumper';
use Test2::API qw/intercept/;

use Test2::Tools::EventDumper qw/dump_event dump_events/;

subtest settings => sub {
    my %defaults = (
        qualify_functions    => 0,
        paren_functions      => 0,
        use_full_event_type  => 0,
        show_empty           => 0,
        add_line_numbers     => 0,
        call_when_can        => 1,
        convert_trace        => 1,
        shorten_single_field => 1,
        clean_fail_messages  => 1,

        field_order => {
            name           => 1,
            pass           => 2,
            effective_pass => 3,
            todo           => 4,
            max            => 5,
            directive      => 6,
            reason         => 7,
            trace          => 9999,
        },
        array_sort_order => 10000,
        other_sort_order => 9000,

        include_fields => undef,
        exclude_fields => {buffered => 1, nested => 1, is_subtest => 1, in_subtest => 1, subtest_id => 1, hubs => 1},

        indent_sequence => '    ',

        adjust_filename => $CLASS->can('adjust_filename'),
    );

    *parse_settings = $CLASS->can('parse_settings');

    is(parse_settings({}), \%defaults, "defaults");

    is(
        parse_settings({foo => 'bar'}),
        {%defaults, foo => 'bar'},
        "Added a setting"
    );

    is(
        parse_settings({
            field_order    => [qw/a b c/],
            include_fields => [qw/x y z/],
            exclude_fields => [qw/q w e r t y/]
        }),
        {
            %defaults,
            field_order    => {a => 1, b => 2, c => 3},
            include_fields => {x => T(), y => T(), z => T()},
            exclude_fields => {q => T(), w => T(), e => T(), r => T(), t => T(), y => T()},
        },
        "Array to Hash conversions"
    );

    is(
        parse_settings({ field_order => undef }),
        { %defaults, field_order => undef },
        "Can override to undef"
    );
};

subtest exceptions => sub {
    like(
        dies { dump_event() },
        qr/No event to dump/,
        "Need an event"
    );

    like(
        dies { dump_event({}) },
        qr/dump_event\(\) requires a Test2::Event \(or subclass\) instance, Got: HASH/,
        "Must be an event instance"
    );

    like(
        dies { dump_events() },
        qr/No events to dump/,
        "Need an array of events"
    );

    like(
        dies { dump_events({}) },
        qr/dump_events\(\) requires an array reference, Got: HASH/,
        "Need an array ref"
    );

    like(
        dies { dump_events([qw/a b c/]) },
        qr/dump_events\(\) requires an array reference of Test2::Event \(or subclass\) instances, some array elements are not Test2::Event instances/,
        "Only events can be in the arrayref"
    );
};

subtest 'finalize' => sub  {
    *finalize = $CLASS->can('finalize');

    my $input = <<"    EOT";
foo  
   bar  
\t
   baz  
bat  
    EOT

    is(finalize($input), <<'    EOT', "Stripped trailing whitespace");
foo
   bar

   baz
bat
    EOT
};

subtest 'quote_str' => sub {
    *quote_str = $CLASS->can('quote_str');

    is(quote_str('foo'),         "'foo'",           "quoted simple");
    is(quote_str("fo'o"),        qq{"fo'o"},        "quoted string with ' in it");
    is(quote_str(qq<fo'"o>),     qq<qq{fo'"o}>,     "quoted string with ' and \" in it");
    is(quote_str(qq<fo'"{o>),    qq<qq(fo'"{o)>,    "quoted string with ' and \" and { in it");
    is(quote_str(qq<fo'"{(o>),   qq<qq[fo'"{(o]>,   "quoted string with ' and \" and { and ( in it");
    is(quote_str(qq<fo'"{([o>),  qq<qq/fo'"{([o/>,  "quoted string with ' and \" and { and ( and [ in it");
    is(quote_str(qq<fo'"{([/o>), qq<'fo\\'"{([/o'>, "quoted string with ' and \" and { and ( and [ and / in it");

    is(quote_str("foo\n\b\rbar"),    '"foo\\n\\b\\rbar"',    "quoted simple with escapes");
    is(quote_str(qq{foo\n\b\r"bar}), 'qq{foo\\n\\b\\r"bar}', "quoted simple with escapes and double-quote");
};

subtest 'quote_val' => sub {
    *quote_val = $CLASS->can('quote_val');

    is(quote_val(undef), 'undef', "undef handled");
    is(quote_val(123), '123', "number is not quoted");
    is(quote_val('Failed test xxx'), "'Failed test xxx'", "Failure not modified by default");

    is(
        quote_val('Failed test xxx', {clean_fail_messages => 1}),
        'match qr{^\\n?Failed test}',
        "clean_fail_message"
    );
    is(
        quote_val("\nFailed test xxx", {clean_fail_messages => 1}),
        'match qr{^\\n?Failed test}',
        "clean_fail_message with newline prefix"
    );
};

subtest 'quote_key' => sub {
    *quote_key = $CLASS->can('quote_key');
    is(quote_key(123), '123', "number is not quoted");
    is(quote_key('foo'), 'foo', "simple word is not quoted");
    is(quote_key('foo.bar'), "'foo.bar'", "complex string is quoted");
};

subtest 'render_event' => sub {
    *render_event = $CLASS->can('render_event');

    my $Ok = bless {}, 'Test2::Event::Ok';
    my $Mok = bless {}, 'My::Ok';

    is(render_event($Ok, {}), "Ok", "simple event");
    is(render_event($Mok, {}), "'+My::Ok'", "third party event");
    is(render_event($Ok, {use_full_event_type => 1}), "'+Test2::Event::Ok'", "show full");
};

done_testing;
