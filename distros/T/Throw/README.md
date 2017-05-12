# NAME

Throw - Simple exceptions that do the right things in multiple contexts

# SYNOPSIS

    use Throw qw(throw);

    throw "Hey";

    throw "Hey", {info => "This is why"};

    throw "Hey", {trace => 1}; # simple trace

    throw "Hey", {trace => 2}; # full trace without args

    throw "Hey", {trace => 3}; # full trace with args


    use Throw qw(croak confess carp);

    croak "Hey";  # same as throw with {trace => 1}, 1

    confess "Hey";  # same as throw with {trace => 2}

    carp "Hey";  # warns from perspective of caller

    warn Throw->new("Hey");  # useful for some cases


    use Throw qw(throw classify);
    if (classify my $err = $@, "io") {
        throw "Got a disk error", {msg => $err};
    }

# DESCRIPTION

Throw allows for light weight exceptions that can hold more
information than just the error message.  These exceptions do the
right thing when thrown on the commandline, or when consumed by
javascript based APIs.

# METHODS

- throw

    Takes an error message, an error message and extra arguments, or a
    hashref.

    If a hashref is passed, it should contain a key named error
    representing the error.  If not, a string "Something happened" will be
    used instead.  If an arguments hashref is passed, the error message
    will be added to it.  If just an error message is passed, a hashref
    will be created with the error as the single key.

    In all cases, throw returns an hashref based object blessed into the
    Throw class.  When an error message is passed independently.

    If a key of "trace" is passed, its value will be passed to the
    caller\_trace subroutine and the result will be stored as the value of
    trace.

    An optional 3rd parameter can be passed which will be used as the "level"
    for any stack traces performed.

- new

    Similar to throw call.  Useful for some cases.

- croak

    Gives a trace from the perspective of the caller.
    Similar to throw - but with trace => 1 instead.  (passing a single hashref is not allowed)
    Single level stack trace.

- confess

    Similar to throw - but with trace => 2 instead.  (passing a single hashref is not allowed)
    Full stack trace.

- carp

    Gives a trace from the perspective of the caller.
    Similar to throw but only warns with trace => 1.

- cluck

    Similar to throw but only warns with trace => 2.

- caller\_trace

    Returns stack traces.  Takes parameters in a few different ways.

         caller_trace();    # {level => 0, verbose => 2}
         caller_trace(1);   # {level => 0, verbose => 1}
         caller_trace(2);   # {level => 0, verbose => 2}
         caller_trace(3);   # {level => 0, verbose => 3}

         caller_trace(undef, 3);  # {level => 3, verbose => 1}
         caller_trace(1, 4);      # {level => 4, verbose => 1}
         caller_trace(2, 2);      # {level => 2, verbose => 2}

         caller_trace({level => 1});                # {level => 1, verbose => 2}
         caller_trace({level => 1, verbose => 3});  # {level => 1, verbose => 3}

    The "level" argument represents how many stack frames to skip
    backwards.

    The "verbose" argument can be one of 1, 2, or 3.  Default 2.  At level
    1 you get a single line of trace.  With level 2 you get the full stack
    trace.  With level 3 you get the full stack trace with function
    arguments.

    The "max\_args" argument shows how many parameters to each level will
    be represented.  If there are more an "..." will be shown.  Default is
    5.

    The "max\_arg\_len" argument shows where parameters will be truncated.
    Default is 20.

    The "skip" argument can be a hashref with keys of packages, files, or
    subs that should be excluded from the trace.

- classify

    Allows for cleanly and safely classifying the types of errors received
    assuming you use {type => 'error\_type'} for specifying your error
    hierarchy.  Classify takes an error (such as from $@), and a hashref
    used to classify the error.  Each of the keys of the hashref will be
    checked against the type of the error.  The classification keys are
    checked based on hierarchy - so a key of "foo" will match an error
    type of "foo" as well as "foo.bar", "foo.baz", and "foo.bar.baz".  A
    key of "foo.bar" would match "foo.bar" and "foo.bar.baz" but not
    "foo".

    You may also pass a key named "default" to handle any cases not
    matched by other keys.

    Some errors passed to classify may not have been given a type
    property, and some may not even have been blessed or come from the
    Throw system.  Any unblessed errors will receive use a type of
    "undef.flat" and any other errors that do not have a type attribute
    will use "undef.none" for the type.

        use Throw qw(throw classify);
        use Try::Tiny qw(try catch);

        try {
            throw "No-no", {type => 'foo.bar'};
        } catch {
            classify $_, {
                foo => sub { print "I got foo\n" },
                'foo.bar' => sub { print "I got foo.bar\n" },
                default   => sub { throw "Don't know what I got", {msg => $_[0]} }
            };
        }


        # also
        if (classify $@, "foo") {
            print "I got a foo\n";
        }

# GLOBALS

There are also a few package globals that can make tracking down culprits easier.

- $trace

    Turn on traces globally - can be any of the normal values passed to trace

- $level

    Set the level at which to trace.

- $pretty

    Allow all json error stringification to use pretty.  You can also set \_pretty => 1 in
    individual errors, but sometimes you won't have access to the error object before
    it stringifies.

- TO\_JSON

    JSONifies the error.
