use strict;
use lib '.';
use inc::Module::Install;

name                ('XUL-App');
license             ('perl');
author              ('Agent Zhang <agentzh@yahoo.cn>');
perl_version        ('5.006001');
all_from            ('lib/XUL/App.pm');

requires            ('Object::Declare' => '0.22');
requires            ('Template::Declare' => '0.28');
requires            ('Template::Declare::Tags');
requires            ('File::Slurp');
requires            ('Class::Accessor::Fast' => '0.30');
requires            ('Class::Data::Inheritable' => '0.06');
requires            ('File::ShareDir' => '0.04');
requires            ('File::Copy::Recursive' => '0.35');
requires            ('File::Basename');
requires            ('Locale::Maketext::Lexicon');
requires            ('Locale::Maketext');
requires            ('Text::Diff');
requires            ('File::Find');
requires            ('Sys::Hostname');

no_index( directory => qw< t inc doc share demo > );

install_script      ('script/xulapp');
install_script      ('script/xml2td');
install_share;

auto_install();
WriteAll();

