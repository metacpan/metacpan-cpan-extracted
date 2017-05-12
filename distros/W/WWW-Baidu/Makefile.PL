use strict;
use inc::Module::Install;

name            ('WWW-Baidu');
all_from        ('lib/WWW/Baidu.pm');
license         ('perl');

requires        ('Class::Accessor'        => '0.30');
requires        ('WWW::Mechanize'         => '1.20');
requires        ('WWW::Mechanize::Cached' => '1.32');
requires        ('HTML::Parser'           => '3.56');
requires        ('HTML::TreeBuilder'      => '3.23');

build_requires  ('YAML::Syck' => '0.72');
build_requires  ('Test::More' => '0.66');

auto_install;

&WriteAll;
