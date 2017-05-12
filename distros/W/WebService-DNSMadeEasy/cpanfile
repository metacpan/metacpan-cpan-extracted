requires 'DDP';
requires 'DateTime';
requires 'DateTime::Format::HTTP';
requires 'Digest::HMAC_SHA1';
requires 'HTTP::Request';
requires 'Moo';
requires 'MooX::Singleton';
requires 'Role::REST::Client';
requires 'String::CamelSnakeKebab';

on configure => sub {
    requires 'Module::Build::Tiny', '0.035';
    requires 'perl', '5.008_001';
};

on test => sub {
    requires 'JSON';
    requires 'Test::More', '0.98';
};
