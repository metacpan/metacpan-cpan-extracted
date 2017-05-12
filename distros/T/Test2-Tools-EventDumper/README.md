# NAME

Test2::Tools::EventDumper - Tool for dumping Test2::Event structures.

# DESCRIPTION

This tool allows you to dump [Test2::Event](https://metacpan.org/pod/Test2::Event) instances (including subclasses).
The dump format is the [Test2::Tools::Compare](https://metacpan.org/pod/Test2::Tools::Compare) event DSL. There are many
configuration options available to tweak the output to meet your needs.

# SYNOPSYS

    use strict;
    use warnings;
    use Test2::Bundle::Extended;
    use Test2::API qw/intercept/;

    use Test2::Tools::EventDumper;

    my $events = intercept {
        ok(1, 'a');
        ok(2, 'b');
    };

    my $dump = dump_events $events;
    print "$dump\n";

The above will print this:

    array {
        event Ok => sub {
            call 'name' => 'a';
            call 'pass' => '1';
            call 'effective_pass' => '1';

            prop file => match qr{\Qbasic.t\E};
            prop line => '12';
        };

        event Ok => sub {
            call 'name' => 'b';
            call 'pass' => '1';
            call 'effective_pass' => '1';

            prop file => match qr{\Qbasic.t\E};
            prop line => '13';
        };
        end();
    }

**Note**: There is no newline at the end of the string, '}' is the last
character.

# EXPORTS

- dump\_event($event)
- dump\_event $event => ( option => 1 )

    This can be used to dump a single event. The first argument must always be an
    [Test2::Event](https://metacpan.org/pod/Test2::Event) instance.

    All additional arguments are key/value pairs treated as dump settings. See the
    ["SETTINGS"](#settings) section for details.

- dump\_events($arrayref)
- dump\_events $arrayref => ( option => 1 )

    This can be used to dump an arrayref of events. The first argument must always
    be an arrayref full of [Test2::Event](https://metacpan.org/pod/Test2::Event) instances.

    All additional arguments are key/value pairs treated as dump settings. See the
    ["SETTINGS"](#settings) section for details.

# SETTINGS

All settings are listed with their default values when possible.

- qualify\_functions => 0

    This will cause all functions such as `array` and `call` to be fully
    qualified, turning them into `Test2::Tools::Compare::array` and
    `Test2::Tools::Compare::call`. This also turns on the
    `paren_functions => 1` option. which forces the use of parentheses.

- paren\_functions => 0

    This forces the use of parentheses in functions.

    Example:

        call 'foo' => sub { ... };

    becomes:

        call('foo' => sub { ... });

- use\_full\_event\_type => 0

    Normally events in the `Test2::Event::` namespace are shortened to only
    include the postfix part of the name:

        event Ok => sub { ... };

    When this option is turned on the full event package will be used:

        event '+Test2::Event::Ok' => sub { ... };

- show\_empty => 0

    Normally empty fields are skipped. Empty means any field that does not exist,
    is undef, or set to ''. 0 does not count as empty. When this option is turned
    on all fields will be shown.

- add\_line\_numbers => 0

    When this option is turned on, all lines will be prefixed with a label
    containing the line number, for example:

        L01: array {
        L02:     event Ok => sub {
        L03:         call 'name' => 'a';
        L04:         call 'pass' => '1';
        L05:         call 'effective_pass' => '1';

        L07:         prop file => match qr{\Qt/basic.t\E};
        L08:         prop line => '12';
        L09:     };

        L11:     event Ok => sub {
        L12:         call 'name' => 'b';
        L13:         call 'pass' => '1';
        L14:         call 'effective_pass' => '1';

        L16:         prop file => match qr{\Qt/basic.t\E};
        L17:         prop line => '13';
        L18:     };
        L19:     end();
        L20: }

    These labels do not change the code in any meaningful way, it will still run in
    `eval` and it will still produce the same result. These labels can be useful
    during debugging. Labels will not be added to otherwise empty lines as such
    labels break on perls older than 5.14.

- call\_when\_can => 1

    This option is turned on by default. When this option is on the `call()`
    function will be used in favor of the `field()` when the field name also
    exists as a method for the event.

- convert\_trace => 1

    This option is turned on by default. When this option is on the `trace` field
    is turned into 2 checks, one for line, and one for filename.

    Example:

        prop file => match qr{\Qt/basic.t\E};
        prop line => '12';

    Without this option trace looks like this:

        call 'trace' => T(); # Unknown value: Test2::Util::Trace

    Which is not useful.

- shorten\_single\_field => 1

    When true, events with only 1 field to display will be shortened to look like
    this:

        event Note => {message => 'XXX'};

    Instead of this:

        event Note => sub {
            call message => 'XXX';
        };

- clean\_fail\_messages => 1

    When true, any value that matches the regex `/^Failed test/` will be turned
    into a `match qr/^Failed test/` check. This is useful for diagnostics messages
    that are automatically created.

- field\_order => { ... }

    This allows you to assign a sort weight to fields (0 is ignored). Lower values
    are displayed first.

    Here are the defaults:

        field_order => {
            name           => 1,
            pass           => 2,
            effective_pass => 3,
            todo           => 4,
            max            => 5,
            directive      => 6,
            reason         => 7,
            trace          => 9999,
        }

    Anything not listed gets the value from the 'other\_sort\_order' parameter.

- other\_sort\_order => 9000

    This is the sort weight for fields not listed in `field_order`.

- array\_sort\_order => 10000

    This is the sort weight for any field that contains an array of event objects.
    For example the `subevents` field in subtests.

- include\_fields => \[ ... \]

    Fields that should always be listed if present (or if 'show\_empty' is true).
    This is not set by default.

- exclude\_fields => \[ ... \]

    Fields that should never be listed. To override the defaults set this to a new
    arrayref, or to undef to clear the defaults.

    defaults:

        exclude_fields => [qw/buffered nested/]

- indent\_sequence => '    '

    How to indent each level. Normally 4 spaces are used. You can set this to
    `"\t"` if you would prefer tabs. You can also set this to any valid string
    with varying results.

- adjust\_filename => sub { ... }

    This is used when the `convert_trace` option is true. This should be a coderef
    that modifies the filename to something portable. It should then return a
    string to be inserted after `'field' =>`.

    Here is the default:

        sub {
            my $file = shift;
            $file =~ s{^.*[/\\]}{}g;
            return "match qr{\\Q$file\\E}";
        },

    This default strips off all of the path from the filename. After stripping the
    filename it puts it into a `match()` check with the '\\Q' and '\\E' quoting
    construct to make it safer.

    The default is probably adequate for most use cases.

# SOURCE

The source code repository for Test2-Tools-EventDumper can be found at
`http://github.com/Test-More/Test2-Tools-EventDumper/`.

# MAINTAINERS

- Chad Granum <exodist@cpan.org>

# AUTHORS

- Chad Granum <exodist@cpan.org>

# COPYRIGHT

Copyright 2016 Chad Granum <exodist7@gmail.com>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See `http://dev.perl.org/licenses/`
