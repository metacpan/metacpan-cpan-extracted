use 5.012;
use warnings;
use lib 't/lib'; use MyTest;
use UniEvent::Error;

subtest "error constants" => sub {
    subtest 'system error alias' => sub {
        foreach my $row (
            ["address_family_not_supported", "EAFNOSUPPORT"],
            ["connection_aborted", "ECONNABORTED"],
            ["file_exists", "EEXIST"],
            ["not_enough_memory", "ENOMEM"],
            ["operation_canceled", "ECANCELED"],
            ["timed_out", "ETIMEDOUT"],
        ) {
            foreach my $name (@$row) {
                my $sub = UniEvent::SystemError->can($name);
                my $val = $sub->()->value;
                cmp_ok($val, '>', 0, "UniEvent::SystemError::$name(): $val");
            }
        }
    };

    subtest 'unievent category' => sub {
        foreach my $name (qw/
            ssl_error
            resolve_error
            ai_address_family_not_supported
            ai_temporary_failure
            ai_bad_flags
            ai_bad_hints
            ai_request_canceled
            ai_permanent_failure
            ai_family_not_supported
            ai_out_of_memory
            ai_no_address
            ai_unknown_node_or_service
            ai_argument_buffer_overflow
            ai_resolved_protocol_unknown
            ai_service_not_available_for_socket_type
            ai_socket_type_not_supported
            invalid_unicode_character
            not_on_network
            transport_endpoint_shutdown
            unknown_error
            host_down
            remote_io
        /) {
            my $sub = UniEvent::Error->can($name);
            my $val = $sub->()->value;
            cmp_ok($val, '>', 0, "UniEvent::Error::$name(): $val");
        }
    }
};

subtest "Error" => sub {
    subtest 'with message' => sub {
        my $e = new_ok "UniEvent::Error" => ["message"];
        is $e->what, "message";
        is $e, $e->what;
        my $c = $e->clone;
        isa_ok $c, ref($e);
        is $c, $e, "clone ok";
    };
    subtest 'with XS error code' => sub {
        my $ec = XS::ErrorCode->new(UniEvent::SystemError::timed_out);
        my $e = new_ok "UniEvent::Error" => [$ec];
        is $e->code, $ec, "code ok";
        ok $e->what, "what present";
        my $c = $e->clone;
        isa_ok $c, ref($e);
        is $e->code, $ec, "cloned code ok";
        is $c, $e, "clone ok";
    };
    subtest 'with STL error code' => sub {
        my $ec = UniEvent::SystemError::timed_out;
        my $e = new_ok "UniEvent::Error" => [$ec];
        is $e->code, $ec, "code ok";
        ok $e->what, "what present";
        my $c = $e->clone;
        isa_ok $c, ref($e);
        is $e->code, $ec, "cloned code ok";
        is $c, $e, "clone ok";
    };
};

done_testing();
