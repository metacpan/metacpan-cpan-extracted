requires 'perl' => '5.010001';
requires 'parent' => '0';
requires 'Plack' => '0.9949';
requires 'Twiggy';
requires 'Amon2' => 6.00;
requires 'Amon2::Plugin::ShareDir';
requires 'Ukigumo::Client' => '0.36';
requires 'Ukigumo::Common' => '0.10';
requires 'Data::Validator';
requires 'Text::Xslate';
requires 'Time::Duration';
requires 'Mouse';
requires 'Log::Minimal';
requires 'Coro';
requires 'Getopt::Long' => '2.42';
requires 'JSON' => '2';
requires 'List::Util';
requires 'Pod::Usage';
requires 'autodie';
requires 'version';
requires 'File::Spec';
requires 'File::Path';

on configure => sub {
    requires 'Module::Build::Tiny' => '0.035';
};

on test => sub {
    requires 'Test::More' => '0.98';
    requires 'File::Temp';
    requires 'LWP::UserAgent';
    requires 'Plack::Loader';
    requires 'Test::TCP';
    requires 'Capture::Tiny';
};

on develop => sub {
    requires 'Perl::Critic';
    requires 'Test::Perl::Critic';
};
