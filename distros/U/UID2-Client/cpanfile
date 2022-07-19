requires 'perl', '5.010000';

requires 'Class::Accessor::Lite';
requires 'List::MoreUtils';
requires 'HTTP::Tiny';
recommends 'IO::Socket::SSL', '1.56';
recommends 'Net::SSLeay', '1.49';
requires 'JSON';
recommends 'JSON::XS';
requires 'CryptX', '0.060';

on 'test' => sub {
    requires 'Test::More', '0.98';
    requires 'Test::MockObject';
};

on 'configure' => sub {
    requires 'Module::Build::Tiny', '0.035';
};
