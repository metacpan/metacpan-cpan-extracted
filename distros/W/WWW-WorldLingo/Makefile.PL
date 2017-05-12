use inc::Module::Install;
use strict;
use warnings;

name            'WWW-WorldLingo';
all_from        'lib/WWW/WorldLingo.pm';

requires        "Class::Accessor::Fast"    => 0;
requires        "HTTP::Request::Common"    => 0;
requires        "HTTP::Response"      => 0;
requires        "LWP::UserAgent"      => 0;
requires        "Carp"                => 0;
requires        "constant"            => 0;

build_requires  "Test::More"          => "0.42";
build_requires  "IO::Socket"          => 0;

recommends      "LWPx::ParanoidAgent" => 0;

auto_install;
WriteAll;


__END__
