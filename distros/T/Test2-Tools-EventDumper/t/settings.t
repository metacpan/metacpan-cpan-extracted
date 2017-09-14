use strict;
use warnings;
use Test2::Bundle::Extended -target => 'Test2::Tools::EventDumper';
use Test2::API qw/intercept/;

use Test2::Tools::EventDumper qw/dump_event dump_events/;

use Test2::Util::Trace;
my $trace_class = $INC{'Test2/EventFacet/Trace.pm'} ? 'Test2::EventFacet::Trace' : 'Test2::Util::Trace';


my $file = 'settings.t';
my %lines;

my $events = intercept {
    ok(1, "pass"); BEGIN { $lines{pass} = __LINE__ };

    subtest foo => sub {
        ok(1, "pass"); BEGIN { $lines{st_pass} = __LINE__ };
    }; BEGIN { $lines{subtest} = __LINE__ };
};

# Always start with these settings. This keeps the test working if the defaults
# ever change.
my %base = (
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
    exclude_fields => {buffered => 1, nested => 1, subtest_id => 1, in_subtest => 1, is_subtest => 1},

    indent_sequence => '    ',

    adjust_filename => sub {
        my $file = shift;
        $file =~ s{^.*[/\\]}{}g;
        return "'$file'";
    },
);

my $dump = dump_event($events->[0], %base);
is("$dump\n", <<"EOT", "basic set of params (event)") || diag $dump;
event Ok => sub {
    call name => 'pass';
    call pass => 1;
    call effective_pass => 1;

    prop file => '$file';
    prop line => $lines{pass};
}
EOT

$dump = dump_events($events, %base);
is("$dump\n", <<"EOT", "basic set of params (array)") || diag $dump;
array {
    event Ok => sub {
        call name => 'pass';
        call pass => 1;
        call effective_pass => 1;

        prop file => '$file';
        prop line => $lines{pass};
    };

    event Subtest => sub {
        call name => 'foo';
        call pass => 1;
        call effective_pass => 1;

        prop file => '$file';
        prop line => $lines{subtest};

        call subevents => array {
            event Ok => sub {
                call name => 'pass';
                call pass => 1;
                call effective_pass => 1;

                prop file => '$file';
                prop line => $lines{st_pass};
            };

            event Plan => sub {
                call max => 1;

                prop file => '$file';
                prop line => $lines{subtest};
            };
            end();
        };
    };
    end();
}
EOT

$dump = dump_event($events->[0], %base, qualify_functions => 1);
is("$dump\n", <<"EOT", "qualify_functions (event)") || diag $dump;
Test2::Tools::Compare::event(Ok => sub {
    Test2::Tools::Compare::call(name => 'pass');
    Test2::Tools::Compare::call(pass => 1);
    Test2::Tools::Compare::call(effective_pass => 1);

    Test2::Tools::Compare::prop(file => '$file');
    Test2::Tools::Compare::prop(line => $lines{pass});
})
EOT

$dump = dump_events($events, %base, qualify_functions => 1);
is("$dump\n", <<"EOT", "qualify_functions (array)") || diag $dump;
Test2::Tools::Compare::array(sub {
    Test2::Tools::Compare::event(Ok => sub {
        Test2::Tools::Compare::call(name => 'pass');
        Test2::Tools::Compare::call(pass => 1);
        Test2::Tools::Compare::call(effective_pass => 1);

        Test2::Tools::Compare::prop(file => '$file');
        Test2::Tools::Compare::prop(line => $lines{pass});
    });

    Test2::Tools::Compare::event(Subtest => sub {
        Test2::Tools::Compare::call(name => 'foo');
        Test2::Tools::Compare::call(pass => 1);
        Test2::Tools::Compare::call(effective_pass => 1);

        Test2::Tools::Compare::prop(file => '$file');
        Test2::Tools::Compare::prop(line => $lines{subtest});

        Test2::Tools::Compare::call(subevents => Test2::Tools::Compare::array(sub {
            Test2::Tools::Compare::event(Ok => sub {
                Test2::Tools::Compare::call(name => 'pass');
                Test2::Tools::Compare::call(pass => 1);
                Test2::Tools::Compare::call(effective_pass => 1);

                Test2::Tools::Compare::prop(file => '$file');
                Test2::Tools::Compare::prop(line => $lines{st_pass});
            });

            Test2::Tools::Compare::event(Plan => sub {
                Test2::Tools::Compare::call(max => 1);

                Test2::Tools::Compare::prop(file => '$file');
                Test2::Tools::Compare::prop(line => $lines{subtest});
            });
            Test2::Tools::Compare::end();
        }));
    });
    Test2::Tools::Compare::end();
})
EOT

$dump = dump_event($events->[0], %base, paren_functions => 1);
is("$dump\n", <<"EOT", "paren_functions (event)") || diag $dump;
event(Ok => sub {
    call(name => 'pass');
    call(pass => 1);
    call(effective_pass => 1);

    prop(file => '$file');
    prop(line => $lines{pass});
})
EOT

$dump = dump_events($events, %base, paren_functions => 1);
is("$dump\n", <<"EOT", "paren_functions (array)") || diag $dump;
array(sub {
    event(Ok => sub {
        call(name => 'pass');
        call(pass => 1);
        call(effective_pass => 1);

        prop(file => '$file');
        prop(line => $lines{pass});
    });

    event(Subtest => sub {
        call(name => 'foo');
        call(pass => 1);
        call(effective_pass => 1);

        prop(file => '$file');
        prop(line => $lines{subtest});

        call(subevents => array(sub {
            event(Ok => sub {
                call(name => 'pass');
                call(pass => 1);
                call(effective_pass => 1);

                prop(file => '$file');
                prop(line => $lines{st_pass});
            });

            event(Plan => sub {
                call(max => 1);

                prop(file => '$file');
                prop(line => $lines{subtest});
            });
            end();
        }));
    });
    end();
})
EOT

$dump = dump_event($events->[0], %base, use_full_event_type => 1);
is("$dump\n", <<"EOT", "use_full_event_type (event)") || diag $dump;
event '+Test2::Event::Ok' => sub {
    call name => 'pass';
    call pass => 1;
    call effective_pass => 1;

    prop file => '$file';
    prop line => $lines{pass};
}
EOT

$dump = dump_events($events, %base, use_full_event_type => 1);
is("$dump\n", <<"EOT", "use_full_event_type (array)") || diag $dump;
array {
    event '+Test2::Event::Ok' => sub {
        call name => 'pass';
        call pass => 1;
        call effective_pass => 1;

        prop file => '$file';
        prop line => $lines{pass};
    };

    event '+Test2::Event::Subtest' => sub {
        call name => 'foo';
        call pass => 1;
        call effective_pass => 1;

        prop file => '$file';
        prop line => $lines{subtest};

        call subevents => array {
            event '+Test2::Event::Ok' => sub {
                call name => 'pass';
                call pass => 1;
                call effective_pass => 1;

                prop file => '$file';
                prop line => $lines{st_pass};
            };

            event '+Test2::Event::Plan' => sub {
                call max => 1;

                prop file => '$file';
                prop line => $lines{subtest};
            };
            end();
        };
    };
    end();
}
EOT

$dump = dump_event($events->[0], %base, show_empty => 1, include_fields => [qw/xxx/]);
is("$dump\n", <<"EOT", "show_empty (event)") || diag $dump;
event Ok => sub {
    call name => 'pass';
    call pass => 1;
    call effective_pass => 1;
    field xxx => DNE();

    prop file => '$file';
    prop line => $lines{pass};
}
EOT

$dump = dump_events($events, %base, show_empty => 1, include_fields => [qw/xxx/]);
is("$dump\n", <<"EOT", "show_empty (array)") || diag $dump;
array {
    event Ok => sub {
        call name => 'pass';
        call pass => 1;
        call effective_pass => 1;
        field xxx => DNE();

        prop file => '$file';
        prop line => $lines{pass};
    };

    event Subtest => sub {
        call name => 'foo';
        call pass => 1;
        call effective_pass => 1;
        field xxx => DNE();

        prop file => '$file';
        prop line => $lines{subtest};

        call subevents => array {
            event Ok => sub {
                call name => 'pass';
                call pass => 1;
                call effective_pass => 1;
                field xxx => DNE();

                prop file => '$file';
                prop line => $lines{st_pass};
            };

            event Plan => sub {
                call max => 1;
                call directive => '';
                field xxx => DNE();

                prop file => '$file';
                prop line => $lines{subtest};
            };
            end();
        };
    };
    end();
}
EOT

$dump = dump_event($events->[0], %base, add_line_numbers => 1);
is("$dump\n", <<"EOT", "add_line_numbers (event)") || diag $dump;
L1: event Ok => sub {
L2:     call name => 'pass';
L3:     call pass => 1;
L4:     call effective_pass => 1;

L6:     prop file => '$file';
L7:     prop line => $lines{pass};
L8: }
EOT

$dump = dump_events($events, %base, add_line_numbers => 1);
is("$dump\n", <<"EOT", "add_line_numbers (array)") || diag $dump;
L01: array {
L02:     event Ok => sub {
L03:         call name => 'pass';
L04:         call pass => 1;
L05:         call effective_pass => 1;

L07:         prop file => '$file';
L08:         prop line => $lines{pass};
L09:     };

L11:     event Subtest => sub {
L12:         call name => 'foo';
L13:         call pass => 1;
L14:         call effective_pass => 1;

L16:         prop file => '$file';
L17:         prop line => $lines{subtest};

L19:         call subevents => array {
L20:             event Ok => sub {
L21:                 call name => 'pass';
L22:                 call pass => 1;
L23:                 call effective_pass => 1;

L25:                 prop file => '$file';
L26:                 prop line => $lines{st_pass};
L27:             };

L29:             event Plan => sub {
L30:                 call max => 1;

L32:                 prop file => '$file';
L33:                 prop line => $lines{subtest};
L34:             };
L35:             end();
L36:         };
L37:     };
L38:     end();
L39: }
EOT

$dump = dump_event($events->[0], %base, call_when_can => 0);
is("$dump\n", <<"EOT", "call_when_can-off (event)") || diag $dump;
event Ok => sub {
    field name => 'pass';
    field pass => 1;
    field effective_pass => 1;

    prop file => '$file';
    prop line => $lines{pass};
}
EOT

$dump = dump_events($events, %base, call_when_can => 0);
is("$dump\n", <<"EOT", "call_when_can-off (array)") || diag $dump;
array {
    event Ok => sub {
        field name => 'pass';
        field pass => 1;
        field effective_pass => 1;

        prop file => '$file';
        prop line => $lines{pass};
    };

    event Subtest => sub {
        field name => 'foo';
        field pass => 1;
        field effective_pass => 1;

        prop file => '$file';
        prop line => $lines{subtest};

        field subevents => array {
            event Ok => sub {
                field name => 'pass';
                field pass => 1;
                field effective_pass => 1;

                prop file => '$file';
                prop line => $lines{st_pass};
            };

            event Plan => sub {
                field max => 1;

                prop file => '$file';
                prop line => $lines{subtest};
            };
            end();
        };
    };
    end();
}
EOT


$dump = dump_event($events->[0], %base, convert_trace => 0);
is("$dump\n", <<"EOT", "convert_trace-off (event)") || diag $dump;
event Ok => sub {
    call name => 'pass';
    call pass => 1;
    call effective_pass => 1;
    call trace => T(); # Unknown value: $trace_class
}
EOT

$dump = dump_events($events, %base, convert_trace => 0);
is("$dump\n", <<"EOT", "convert_trace-off (array)") || diag $dump;
array {
    event Ok => sub {
        call name => 'pass';
        call pass => 1;
        call effective_pass => 1;
        call trace => T(); # Unknown value: $trace_class
    };

    event Subtest => sub {
        call name => 'foo';
        call pass => 1;
        call effective_pass => 1;
        call trace => T(); # Unknown value: $trace_class

        call subevents => array {
            event Ok => sub {
                call name => 'pass';
                call pass => 1;
                call effective_pass => 1;
                call trace => T(); # Unknown value: $trace_class
            };

            event Plan => sub {
                call max => 1;
                call trace => T(); # Unknown value: $trace_class
            };
            end();
        };
    };
    end();
}
EOT

my $note = Test2::Event::Note->new(message => 'foo');
$dump = dump_event($note, %base, shorten_single_field => 1);
is("$dump\n", <<"EOT", "shorten_single_field-on (event)") || diag $dump;
event Note => {message => 'foo'}
EOT

$dump = dump_event($note, %base, shorten_single_field => 0);
is("$dump\n", <<"EOT", "shorten_single_field-off (event)") || diag $dump;
event Note => sub {
    call message => 'foo';
}
EOT

my $diag = Test2::Event::Diag->new(message => "\nFailed test\nxxx\nyyy\nzzz");
$dump = dump_event($diag, %base, clean_fail_messages => 1);
is("$dump\n", <<'EOT', "clean_fail_messages-on (event)") || diag $dump;
event Diag => {message => match qr{^\n?Failed test}}
EOT

$dump = dump_event($diag, %base, clean_fail_messages => 0);
is("$dump\n", <<'EOT', "clean_fail_messages-off (event)") || diag $dump;
event Diag => {message => "\nFailed test\nxxx\nyyy\nzzz"}
EOT

$dump = dump_event($events->[0], %base, field_order => {}, exclude_fields => {trace => 1});
is("$dump\n", <<"EOT", "field order (alphabetic fallback") || diag $dump;
event Ok => sub {
    call effective_pass => 1;
    call name => 'pass';
    call pass => 1;
}
EOT

$dump = dump_event($events->[0], %base, field_order => {name => 1, pass => 3, effective_pass => 2}, exclude_fields => {trace => 1});
is("$dump\n", <<"EOT", "field order (specific weights)") || diag $dump;
event Ok => sub {
    call name => 'pass';
    call effective_pass => 1;
    call pass => 1;
}
EOT

$dump = dump_event($events->[0], %base, indent_sequence => "--");
is("$dump\n", <<"EOT", "indent_sequence (event)") || diag $dump;
event Ok => sub {
--call name => 'pass';
--call pass => 1;
--call effective_pass => 1;
--
--prop file => '$file';
--prop line => $lines{pass};
}
EOT

$dump = dump_events($events, %base, indent_sequence => "--");
is("$dump\n", <<"EOT", "indent_sequence (array)") || diag $dump;
array {
--event Ok => sub {
----call name => 'pass';
----call pass => 1;
----call effective_pass => 1;
----
----prop file => '$file';
----prop line => $lines{pass};
--};
--
--event Subtest => sub {
----call name => 'foo';
----call pass => 1;
----call effective_pass => 1;
----
----prop file => '$file';
----prop line => $lines{subtest};
----
----call subevents => array {
------event Ok => sub {
--------call name => 'pass';
--------call pass => 1;
--------call effective_pass => 1;
--------
--------prop file => '$file';
--------prop line => $lines{st_pass};
------};
------
------event Plan => sub {
--------call max => 1;
--------
--------prop file => '$file';
--------prop line => $lines{subtest};
------};
------end();
----};
--};
--end();
}
EOT

done_testing;
