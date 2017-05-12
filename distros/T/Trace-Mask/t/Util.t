use Test2::Bundle::Extended -target => 'Trace::Mask::Util';
use Test2::Tools::Spec;
use Trace::Mask;

use Trace::Mask::Util qw{
    update_mask
    validate_mask
    get_mask
    mask_line
    mask_call
    mask_sub
    mask_frame
};

my $MASKS = Trace::Mask->masks;

imported_ok(qw{
    update_mask
    validate_mask
    get_mask
    mask_line
    mask_call
    mask_sub
    mask_frame
});

sub foo(&) { $_[0]->(@_) }
sub bar(&) { $_[0]->(@_) }

tests validate_mask => sub {
    is(
        [validate_mask({hide => 1, no_start => 1, stop => 1, shift => 3, 0 => 'foo', 10 => 'bar', 100 => 'baz'})],
        [],
        "Valid"
    );

    is(
        [validate_mask()],
        ['Mask must be a hashref'],
        "No mask"
    );

    is(
        [validate_mask('x')],
        ['Mask must be a hashref'],
        "string as mask"
    );

    is(
        [validate_mask([])],
        ['Mask must be a hashref'],
        "wrong ref type"
    );

    is(
        [validate_mask({foo => 1, bar => 1, -1 => 1, 1.5 => 1, shift => 'hi'})],
        [
            "invalid mask option '-1'",
            "invalid mask option '1.5'",
            "invalid mask option 'bar'",
            "invalid mask option 'foo'",
            "'shift' value must be a positive integer",
        ],
        "Bad options"
    );
};

tests update_mask => sub {
    ok(!$MASKS->{'fake.x'}->{10}->{'main::foo'}, "no mask yet");

    update_mask('fake.x', 10, 'main::foo', {hide => 1});
    is(
        $MASKS->{'fake.x'}->{10}->{'main::foo'},
        {hide => 1},
        "added mask"
    );

    update_mask('fake.x', 10, 'main::foo', {stop => 1});
    is(
        $MASKS->{'fake.x'}->{10}->{'main::foo'},
        {hide => 1, stop => 1},
        "altered mask"
    );

    update_mask('fake.x', 10, \&main::foo, {hide => 0});
    is(
        $MASKS->{'fake.x'}->{10}->{'main::foo'},
        {hide => 0, stop => 1},
        "altered mask again, using subref"
    );

    like(
        dies { update_mask({foo => 1}) },
        qr/Invalid mask/,
        "Dies with invalid mask"
    );
};

tests mask_line => sub {
    my ($file, $line) = (__FILE__, __LINE__ + 1);
    mask_line({hide => 1});
    is(
        $MASKS->{$file}->{$line}->{'*'},
        {hide => 1},
        "Masked line"
    );

    $line = __LINE__;
    mask_line({hide => 1}, -1);
    is(
        $MASKS->{$file}->{$line}->{'*'},
        {hide => 1},
        "Masked line with delta"
    );

    $line = __LINE__;
    mask_line({hide => 1}, -1, 'foo', 'bar');
    is(
        $MASKS->{$file}->{$line},
        {
            foo => { hide => 1 },
            bar => { hide => 1 },
        },
        "Masked line with delta and subs"
    );

    like(
        dies { mask_line({hide => 0}, $_) },
        qr/The second argument to mask_line\(\) must be an integer/,
        "Exception for bad offset " . ($_ ? "'$_'": 'undef' )
    ) for 'x', [];

    like(
        dies { mask_line({foo => 1}) },
        qr/Invalid mask/,
        "Dies with invalid mask"
    );
};

tests mask_call => sub {
    my $callback;
    $callback = sub {
        my $line = $_[-1];
        my $db_args;
        my @caller;
        {
            package DB;
            @caller = caller(1);
            $db_args = [@DB::args];
        }
        is(\@_, [$callback, 'x', $line], "got the arg passed in");
        is(@$db_args, 3, "only 3 args in the trace");
        is($db_args, [$callback, 'x', $line], "only our args show in DB");
        like(\@caller, [__PACKAGE__, __FILE__, $line, 'main::foo'], "trace to us");

        is(
            $MASKS->{$caller[1]}->{$caller[2]}->{'main::foo'},
            {hide => 1},
            "Set proper mask"
        );
    };
    mask_call({hide => 1}, 'foo', $callback, 'x', __LINE__);
    mask_call({hide => 1}, \&foo, $callback, 'x', __LINE__);

    # Prevent leaks
    $callback = undef;

    like(
        dies { mask_call({foo => 1}) },
        qr/Invalid mask/,
        "Need a valid mask"
    );

    like(
        dies { mask_call({hide => 1}, $_) },
        qr/The second argument to mask_call\(\) must be a coderef, or the name of a sub to call/,
        "Second argument must be a valid sub"
    ) for undef, 123, 'happy_happy_joy_joy', {};
};

tests mask_sub => sub {
    ok(!$MASKS->{'*'}->{'*'}->{'main::foo'}, "no global sub mask");
    ok(!$MASKS->{'fake.x'}->{'*'}->{'main::foo'}, "no file sub mask");
    ok(!$MASKS->{'fake.x'}->{33}->{'main::foo'}, "no specific sub mask");
    mask_sub({hide => 1}, \&foo);
    mask_sub({hide => 1}, 'foo', 'fake.x');
    mask_sub({hide => 1}, 'foo', 'fake.x', 33);
    is(
        $MASKS->{'*'}->{'*'}->{'main::foo'},
        {hide => 1},
        "Added global sub mask"
    );
    is(
        $MASKS->{'fake.x'}->{'*'}->{'main::foo'},
        {hide => 1},
        "whole file mask for sub"
    );
    is(
        $MASKS->{'fake.x'}->{33}->{'main::foo'},
        {hide => 1},
        "specific sub mask"
    );

    like(
        dies { mask_sub({foo => 1}) },
        qr/Invalid mask/,
        "Need a valid mask"
    );

    like(
        dies { mask_sub({hide => 1}, $_) },
        qr/The second argument to mask_sub\(\) must be a coderef, or the name of a sub in the calling package/,
        "Need a valid sub"
    ) for undef, 123, 'ffff', {};

    like(
        dies { mask_sub({hide => 1}, sub { 1 }) },
        qr/mask_sub\(\) cannot be used on an unamed sub/,
        "Anon sub"
    );
};

tests mask_frame => sub {
    my $sub = sub {
        my @caller = caller(0);
        ok(!$MASKS->{$caller[1]}->{$caller[2]}->{$caller[3]}, "no mask yet");
        mask_frame(hide => 1);
        is(
            $MASKS->{$caller[1]}->{$caller[2]}->{$caller[3]},
            {hide => 1},
            "Hid this frame"
        );
    };
    $sub->();
};

tests get_mask => sub {
    local %Trace::Mask::MASKS = (); # Ick
    my $masks = \%Trace::Mask::MASKS;

    $masks->{'*'}->{'*'}->{'*'}              = {6 => 'xxx'};
    $masks->{'fake.x'}->{'*'}->{'*'}         = {0 => 'a', hide => 5, no_start => 5, stop => 5, shift => 5, 5 => 5};
    $masks->{'fake.x'}->{42}->{'*'}          = {1 => 'b', hide => 4, no_start => 4, stop => 4, shift => 4};
    $masks->{'*'}->{'*'}->{'main::foo'}      = {2 => 'c', hide => 3, no_start => 3, stop => 3};
    $masks->{'fake.x'}->{'*'}->{'main::foo'} = {3 => 'd', hide => 2, no_start => 2};
    $masks->{'fake.x'}->{42}->{'main::foo'}  = {4 => 'e', hide => 1};

    is(
        get_mask('fake.x', 42, 'main::foo'),
        {
            0        => 'a',
            1        => 'b',
            2        => 'c',
            3        => 'd',
            4        => 'e',
            hide     => 1,
            no_start => 2,
            stop     => 3,
            shift    => 4,
            5        => 5,
        },
        "Got all the values, correct ones won"
    );

    is(
        get_mask('fake.y', 43, 'main::bar'),
        {},
        "no mask"
    );
};

done_testing;
