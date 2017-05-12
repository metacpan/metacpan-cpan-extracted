requires 'perl', '5.008005';
requires 'Path::Tiny';
requires 'Redis';
requires 'ZooKeeper';
requires 'Moo';
requires 'JSON::XS';
requires 'YAML::XS';
requires 'Data::UUID';
requires 'MooX::Types::MooseLike';
requires 'AnyEvent::Redis';
requires 'Sereal';
requires 'Coro';
requires 'Data::Printer';
requires 'Log::Log4perl';
requires 'MongoDB';
requires 'Pod::Usage';
requires 'Getopt::Long';
requires 'FindBin';
requires 'List::Util';
requires 'Clone';
requires 'YAML';

feature 'http', 'Http worker support' => sub {
    requires 'FurlX::Coro';
};

on 'benchmark' => sub {
    requires 'Text::Table';
    requires 'IPC::Open3';
};

on test => sub {
    requires 'Test::More', '0.96';
};
