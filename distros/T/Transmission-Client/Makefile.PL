# ex:ts=4:sw=4:sts=4:et
use inc::Module::Install;
my $vcs = 'https://github.com/olof/Transmission-Client';

name     q(Transmission-Client);
all_from q(lib/Transmission/Client.pm);

requires q(DateTime) => 0.50;
requires q(JSON::MaybeXS) => 0;
requires q(LWP::UserAgent) => 5.8;
requires q(MIME::Base64) => 3.00;
requires q(Moose) => 0.80;
requires q(MooseX::Types) => 0.20;
requires q(Sub::Exporter) => 0.95;
requires q(List::MoreUtils) => 0;

test_requires q(Test::More) => 0;

repository $vcs;
bugtracker "$vcs/issues";

auto_install;
WriteAll(sign => 1);
