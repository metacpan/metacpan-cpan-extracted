use Test2::V0;

BEGIN {
    my $path = __FILE__;
    $path =~ s{useit\.t$}{}g;

    unshift @INC => "$path/lib";
}

use optional have_it  => 'Have::It';
use optional have_one => qw/Have::1Not Have::It/;
use optional have_not => 'Have::1Not';

imported_ok(
    qw/HAVE_IT if_have_it unless_have_it need_have_it/,
    qw/HAVE_ONE if_have_one unless_have_one need_have_one/,
    qw/HAVE_NOT if_have_not unless_have_not need_have_not/,
);

like(
    dies { optional->import(have_broke => 'Have::Broken') },
    qr/This is broken/,
    "If a module is broken, as opposed to missing, pass the error along"
);

subtest constants => sub {
    ok(HAVE_IT,   "True, Have::It is installed");
    ok(HAVE_ONE,  "True, Have::It is installed");
    ok(!HAVE_NOT, "False, Have::1Not is not installed");

    is(HAVE_IT,    'Have::It', "Constant returns the module name");
    is(HAVE_ONE,   'Have::It', "Constant returns the module name");
    is([HAVE_NOT], [undef],    "Constant returns undef, not empty list, when module is missing");
};

subtest 'if' => sub {
    is(if_have_it { 'foo' },              'foo', "Ran the if_have_it block");
    is(if_have_one { 'foo' },             'foo', "Ran the if_have_one block");
    is(if_have_not { die "unreachable" }, undef, "Did not run the if_have_not block");

    if_have_one {
        is(
            {@_},
            {module => 'Have::It', modules => [qw/Have::1Not Have::It/], name => 'have_one'},
            "Got the correct arguments",
        );
    };
};

subtest 'unless' => sub {
    is(unless_have_it { die "unreachable" },  undef, "did not run the unless_have_it block");
    is(unless_have_one { die "unreachable" }, undef, "did not run the unless_have_one block");
    is(unless_have_not { 'foo' },             'foo', "Ran the unless_have_not block");

    unless_have_not {
        is(
            {@_},
            {module => undef, modules => [qw/Have::1Not/], name => 'have_not'},
            "Got the correct arguments",
        );
    };

};

subtest 'need' => sub {
    ok(lives { need_have_it }, "No error, we have the module");
    ok(lives { need_have_one }, "No error, we have the module");

    is(
        dies { need_have_not() },
        "You must install one of the following modules to use this feature \[Have::1Not\]\n",
        "Useful message if we need the optional module to continue"
    );

    is(
        dies { need_have_not(feature => 'FooBar') },
        "You must install one of the following modules to use the 'FooBar' feature \[Have::1Not\]\n",
        "Useful message if we need the optional module to use a feature"
    );

    is(
        dies { need_have_not(feature => 'FooBar', message => "Override with custom message") },
        "Override with custom message\n",
        "Custom message"
    );

    is(
        dies { need_have_not(feature => 'FooBar', message => "Override with custom message", append_modules => 1) },
        "Override with custom message \[Have::1Not\]\n",
        "Custom message with module list"
    );

    like(
        dies { need_have_not(feature => 'FooBar', message => "Override with custom message", append_modules => 1, trace => 1) },
        qr/Override with custom message \[Have::1Not\] at/,
        "Custom message with module list and trace"
    );

    like(
        dies { need_have_not(feature => 'FooBar', message => "Override with custom message", append_modules => 1, confess => 1) },
        qr/Override with custom message \[Have::1Not\] at/,
        "Custom message with module list and confess"
    );

    like(
        dies { need_have_not(trace => 1) },
        qr/You must install one of the following modules to use this feature \[Have::1Not\] at/,
        "Trace works on default messages"
    );
};

done_testing;
