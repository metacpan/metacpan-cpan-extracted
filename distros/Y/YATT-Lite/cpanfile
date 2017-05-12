# -*- mode: perl; coding: utf-8 -*-

conflicts 'YATT';

requires 'perl' => '>= 5.10.1, != 5.17, != 5.19.3';
# >= 5.10.1, for named capture and //
# != 5.17, to avoid death by 'given is experimental'
# != 5.19.3 ~ 5.19.11, to avoid sub () {$value} changes

requires 'List::Util';
requires 'List::MoreUtils';
requires 'Plack';
requires 'Hash::MultiValue';
requires 'version' => 0.77;
requires 'parent';
requires 'autodie';
requires 'File::Path';

requires 'URI::Escape';
requires 'Tie::IxHash'; # For nested_query
requires 'Devel::StackTrace';

# YATT::Lite::Partial::Gettext
requires 'Locale::PO';

# For perl 5.20. Actually, CGI is not required (I hope).
requires 'CGI';
requires 'HTML::Entities';

recommends 'YAML::Tiny';
recommends 'Devel::StackTrace::WithLexicals' => 0.08;
recommends 'Sub::Inspector';
recommends 'B::Utils' => '!= 0.26';

configure_requires 'Module::CPANfile';
configure_requires 'Module::Build';

on test => sub {
 requires 'Test::Kantan';
 requires 'Test::More';
 requires 'Test::Differences';
 requires 'Test::WWW::Mechanize::PSGI';

 requires 'HTML::Entities';
 requires 'Plack::Test';

 requires 'CGI::Session';
 requires 'FCGI::Client';
 requires 'FCGI';

 requires 'File::Temp';
 requires 'File::stat';
 requires 'Time::HiRes';

 requires 'DBD::SQLite';
 requires 'DBD::mysql';
 requires 'DBIx::Class';

 requires 'Pod::Simple::SimpleTree';
 requires 'HTTP::Headers';
 requires 'HTTP::Cookies';
 requires 'Email::Sender';
 requires 'Email::Simple';
};
