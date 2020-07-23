requires 'Win32';
requires 'Win32::Process';

on configure => sub {
    requires 'ExtUtils::MakeMaker::CPANfile', '0.06';
};

on test => sub {
    requires 'Test::UseAllModules';
    suggests 'HTTP::Server::Simple::CGI';
    suggests 'LWP::UserAgent';
    suggests 'Test::Pod', '1.18';
    suggests 'Test::Pod::Coverage', '1.04';
};
