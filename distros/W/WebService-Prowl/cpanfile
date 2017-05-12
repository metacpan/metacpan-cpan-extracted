requires 'LWP::UserAgent' => '6.02';
requires 'LWP::Protocol::https';
requires 'Carp';
requires 'XML::Simple';
requires 'URI::Escape';
requires 'AnyEvent::HTTP';

on 'test' => sub {
    requires 'Test::More';
};

on 'develop' => sub {
    requires 'Module::Install';
    requires 'Module::Install::TestBase';
    requires 'Module::Install::CPANfile';
    requires 'Module::Install::AuthorTests';
    requires 'Module::Install::Repository';
};
