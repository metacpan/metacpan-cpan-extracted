use 5.012;
use warnings;
use lib 't';
use MyTest;

subtest 'basic' => sub {
    my $err = MyTest::Error::operation_canceled();
    is ref($err), 'XS::STL::ErrorCode', 'class ok';
    ok $err->message, 'message ok';
    is $err->value, XS::STL::errc::operation_canceled(), 'ec val ok';
    is $err, XS::STL::errc::operation_canceled(), 'ec ok';
    is $err->category, XS::STL::generic_category(), 'category ok';
};

subtest 'create' => sub {
    my $err = XS::STL::ErrorCode->new(XS::STL::errc::timed_out()->value, XS::STL::generic_category());
    is ref($err), 'XS::STL::ErrorCode', 'class ok';
    ok $err->message, 'message ok';
    is $err->value, XS::STL::errc::timed_out()->value, 'ec ok';
    is $err->category, XS::STL::generic_category(), 'category ok';
};

subtest 'categories' => sub {
    my $cat = XS::STL::generic_category();
    is $cat->name, "generic", "generic ok";
    $cat = XS::STL::system_category();
    is $cat->name, "system", "system ok";
    $cat = XS::STL::iostream_category();
    is $cat->name, "iostream", "io ok";
    $cat = XS::STL::future_category();
    is $cat->name, "future", "future ok";
};

subtest "check errc constants" => sub {
    foreach my $row (
        ["address_family_not_supported", "EAFNOSUPPORT"],
        ["address_in_use", "EADDRINUSE"],
        ["address_not_available", "EADDRNOTAVAIL"],
        ["already_connected", "EISCONN"],
        ["argument_list_too_long", "E2BIG"],
        ["argument_out_of_domain", "EDOM"],
        ["bad_address", "EFAULT"],
        ["bad_file_descriptor", "EBADF"],
        ["bad_message", "EBADMSG"],
        ["broken_pipe", "EPIPE"],
        ["connection_aborted", "ECONNABORTED"],
        ["connection_already_in_progress", "EALREADY"],
        ["connection_refused", "ECONNREFUSED"],
        ["connection_reset", "ECONNRESET"],
        ["cross_device_link", "EXDEV"],
        ["destination_address_required", "EDESTADDRREQ"],
        ["device_or_resource_busy", "EBUSY"],
        ["directory_not_empty", "ENOTEMPTY"],
        ["executable_format_error", "ENOEXEC"],
        ["file_exists", "EEXIST"],
        ["file_too_large", "EFBIG"],
        ["filename_too_long", "ENAMETOOLONG"],
        ["function_not_supported", "ENOSYS"],
        ["host_unreachable", "EHOSTUNREACH"],
        ["identifier_removed", "EIDRM"],
        ["illegal_byte_sequence", "EILSEQ"],
        ["inappropriate_io_control_operation", "ENOTTY"],
        ["interrupted", "EINTR"],
        ["invalid_argument", "EINVAL"],
        ["invalid_seek", "ESPIPE"],
        ["io_error", "EIO"],
        ["is_a_directory", "EISDIR"],
        ["message_size", "EMSGSIZE"],
        ["network_down", "ENETDOWN"],
        ["network_reset", "ENETRESET"],
        ["network_unreachable", "ENETUNREACH"],
        ["no_buffer_space", "ENOBUFS"],
        ["no_child_process", "ECHILD"],
        ["no_link", "ENOLINK"],
        ["no_lock_available", "ENOLCK"],
        ["no_message_available", "ENODATA"],
        ["no_message", "ENOMSG"],
        ["no_protocol_option", "ENOPROTOOPT"],
        ["no_space_on_device", "ENOSPC"],
        ["no_stream_resources", "ENOSR"],
        ["no_such_device_or_address", "ENXIO"],
        ["no_such_device", "ENODEV"],
        ["no_such_file_or_directory", "ENOENT"],
        ["no_such_process", "ESRCH"],
        ["not_a_directory", "ENOTDIR"],
        ["not_a_socket", "ENOTSOCK"],
        ["not_a_stream", "ENOSTR"],
        ["not_connected", "ENOTCONN"],
        ["not_enough_memory", "ENOMEM"],
        ["not_supported", "ENOTSUP"],
        ["operation_canceled", "ECANCELED"],
        ["operation_in_progress", "EINPROGRESS"],
        ["operation_not_permitted", "EPERM"],
        ["operation_not_supported", "EOPNOTSUPP"],
        ["operation_would_block", "EWOULDBLOCK"],
        ["owner_dead", "EOWNERDEAD"],
        ["permission_denied", "EACCES"],
        ["protocol_error", "EPROTO"],
        ["protocol_not_supported", "EPROTONOSUPPORT"],
        ["read_only_file_system", "EROFS"],
        ["resource_deadlock_would_occur", "EDEADLK"],
        ["resource_unavailable_try_again", "EAGAIN"],
        ["result_out_of_range", "ERANGE"],
        ["state_not_recoverable", "ENOTRECOVERABLE"],
        ["stream_timeout", "ETIME"],
        ["text_file_busy", "ETXTBSY"],
        ["timed_out", "ETIMEDOUT"],
        ["too_many_files_open_in_system", "ENFILE"],
        ["too_many_files_open", "EMFILE"],
        ["too_many_links", "EMLINK"],
        ["too_many_symbolic_link_levels", "ELOOP"],
        ["value_too_large", "EOVERFLOW"],
        ["wrong_protocol_type", "EPROTOTYPE"],
    ) {
        my ($long, $short) = @$row;
        my $long_sub = XS::STL::errc->can($long);
        my $val = $long_sub->();
        cmp_ok($val->value, '>', 0, "XS::STL::errc::$long(): ".$val->value);
        my $short_sub = XS::STL::errc->can($short);
        is($short_sub->(), $val, "XS::STL::errc::$short()");
    }
};

subtest 'basic ErrorCode' => sub {
    my $err = MyTest::Error::operation_chain_canceled();
    is ref($err), 'XS::ErrorCode', 'class ok';
    ok $err->message, 'message ok';
    is $err->value, XS::STL::errc::connection_aborted(), 'ec val ok';
    is $err, XS::STL::errc::connection_aborted(), 'ec ok';
    is $err->category, XS::STL::generic_category(), 'category ok';
    is $err->next, XS::STL::errc::operation_canceled(), 'next ok'
};

subtest 'ErrorCode eq' => sub {
    my $err1 = MyTest::Error::operation_chain_canceled();
    my $err2 = MyTest::Error::operation_chain_canceled();
    is $err1, $err2, 'both ErrorCode';
    is $err1, $err2->code, 'ErrorCode == std::error_code';
    is $err1, $err1->value, 'ErrorCode == int';
};

done_testing();
