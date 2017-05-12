
requires "Carp";
requires "Data::UUID";
requires "Plack::Component";
requires "Plack::App::WebSocket";
requires "JSON";
requires "Scalar::Util";
requires "Try::Tiny";

requires "Plack::Runner";
requires "Getopt::Long";
requires "Pod::Usage";
requires "Twiggy";

on 'test' => sub {
    requires 'Test::More' => "0";
    requires "Test::Exception";
    requires "Test::Requires";
};

on 'configure' => sub {
    requires 'Module::Build', '0.42';
    requires 'Module::Build::Prereqs::FromCPANfile', "0.02";
};
