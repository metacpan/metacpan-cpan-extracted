requires 'perl', '5.014';

requires 'Plack', '1.0047';
requires 'Plack::Request';
requires 'Plack::Response';
requires 'Plack::Middleware';
requires 'JSON::PP';
requires 'Encode';
requires 'URI::Escape';
requires 'Digest::SHA';
requires 'Time::Piece';
requires 'File::Path';
requires 'File::Spec';
requires 'Getopt::Long';

on 'test' => sub {
    requires 'Test::More', '0.98';
    requires 'HTTP::Request::Common';
    requires 'Plack::Test';
    requires 'File::Temp';
};

on 'develop' => sub {
    requires 'Plack::Middleware::AccessLog';
    requires 'Plack::Middleware::Static';
    requires 'Plack::Middleware::Runtime';
};

feature 'templates', 'Template engine support' => sub {
    requires 'Text::Xslate', '3.0';
};
