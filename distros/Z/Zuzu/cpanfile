requires 'Moo';
requires 'Path::Tiny';
requires 'Archive::Zip';
requires 'CBOR::Free';
requires 'HTTP::CookieJar';
requires 'IO::Socket::SSL';
requires 'Net::DNS';
requires 'Net::SSLeay';
requires 'URI';
requires 'URI::Escape';
requires 'IPC::Run';
requires 'File::ShareDir';
requires 'FFI::Platypus', '2.00';
requires 'Term::ReadLine::Perl';
requires 'Text::CSV_XS';
requires 'Types::Serialiser';
requires 'DBI';
requires 'DBD::SQLite';
requires 'XML::LibXML';
requires 'HTML::Selector::XPath';
requires 'YAML::PP';
requires 'JSON::MultiValueOrdered';
requires 'Tie::Hash::MultiValueOrdered';
requires 'Plack';
requires 'Regexp::Util';
requires 'Coro';
requires 'CryptX', '0.088';
requires 'Crypt::OpenSSL::PKCS12';
requires 'Crypt::OpenSSL::X509';
requires 'Crypt::URandom';
requires 'DateTime::Lite';
requires 'DateTime::Lite::TimeZone';
requires 'Prima';

on 'configure' => sub {
	requires 'ExtUtils::MakeMaker';
	requires 'File::ShareDir::Install';
};

on 'test' => sub {
	requires 'Test2::V0';
	requires 'Test2::Require::AuthorTesting';
	requires 'HTTP::Request::Common';
};
