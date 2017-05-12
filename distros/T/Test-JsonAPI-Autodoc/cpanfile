requires 'JSON';
requires 'LWP::UserAgent';
requires 'Scope::Guard';
requires 'Test::More', '0.98';
requires 'Text::Xslate';
requires 'Text::Xslate::Bridge::Star';
requires 'parent';
requires 'Data::Section::Simple';
requires 'Path::Tiny', '0.051';
requires 'Time::Piece';
requires 'URL::Encode';
requires 'perl', '5.008005';

on configure => sub {
    requires 'CPAN::Meta';
    requires 'CPAN::Meta::Prereqs';
    requires 'Module::Build';
};

on test => sub {
    requires 'HTTP::Request::Common';
    requires 'HTTP::Response';
    requires 'Test::Mock::LWP::Conditional';
    requires 'Plack::Test';
    requires 'Plack::Request';
};

on develop => sub {
    requires 'Test::LocalFunctions';
    requires 'Test::Perl::Critic';
    requires 'Test::UsedModules';
    requires 'Test::Vars';
};
