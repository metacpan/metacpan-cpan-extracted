use Test::More tests => 2;
BEGIN { use_ok('Win32::SqlServer::DTS::Task::SendEmail') }
can_ok(
    'Win32::SqlServer::DTS::Task::SendEmail',
    qw(new get_name get_description get_type to_string is_nt_service save_sent
      get_message_text get_cc_line get_attachments get_profile_password get_profile get_subject
      get_to_line)
);
