requires perl => '5.14.1';

requires 'Carp';
requires 'Digest::SHA';
requires 'Encode';
requires 'HTML::Entities';
requires 'HTTP::Request::Common';
requires 'HTTP::Thin';
requires 'IO::Socket::SSL';
requires 'JSON::MaybeXS';
requires 'Module::Runtime';
requires 'Moo';
requires 'Moo::Role';
requires 'MooX::Aliases';
requires 'MooX::Traits';
requires 'namespace::clean';
requires 'Ref::Util';
requires 'Scalar::Util';
requires 'StackTrace::Auto';
requires 'Sub::Exporter::Progressive';
requires 'Throwable';
requires 'Time::HiRes';
requires 'Time::Local';
requires 'Try::Tiny';
requires 'URI';
requires 'URL::Encode';
requires 'WWW::OAuth' => '0.006';

recommends 'Cpanel::JSON::XS';
recommends 'WWW::Form::UrlEncoded::XS';

on test => sub {
    requires 'HTTP::Response';
    requires 'HTTP::Status';
    requires 'List::Util', '1.35'; # for function all added in 1.33
    requires 'Test::Pod';
    requires 'Test::Fatal';
    requires 'Test::More';
    requires 'Test::Spec';
    requires 'Test::Warnings';
};
