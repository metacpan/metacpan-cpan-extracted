requires 'perl', '5.008001';
requires 'parent';
requires 'LWP::UserAgent' => 6;
requires 'JSON' => 2;
requires 'Mouse' => 0;
requires 'File::Temp';
requires 'File::HomeDir' => 0;
requires 'String::IRC' => 0;
requires 'Ukigumo::Common' => 0.10;
requires 'Capture::Tiny' => 0;
requires 'Encode' => '2.58';
requires 'Encode::Locale' => 0;
requires 'YAML::Tiny' => 0;
requires 'HTTP::Request::Common';
requires 'Scope::Guard';
requires 'Pod::Usage';
requires 'Getopt::Long' => '2.42';
requires 'File::Path';
requires 'String::CamelCase';

recommends 'Growl::Any';

on test => sub {
    requires 'Test::More', "0.98";
    requires 'Test::Requires';
    requires 'File::pushd';
    requires 'Data::Section::Simple';
};

on configure => sub {
    requires 'Module::Build::Tiny' => '0.035';
};

on develop => sub {
    requires 'Test::Perl::Critic' => '1.02';
    requires 'LWP::Protocol::PSGI';
};

