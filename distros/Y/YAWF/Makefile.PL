use inc::Module::Install;

name 'YAWF';
all_from 'lib/YAWF.pm';
author 'Sebastian Willing <sewi@cpan.org>';
license 'perl';

build_requires 'Test::More';

requires 'CGI'                        => 3.43;
requires 'CGI::Cookie'                => 0;
requires 'Apache::Session::SharedMem' => 0;
requires 'Class::XSAccessor'          => 0;
requires 'DBI'                        => 0;
requires 'DBIx::Class'                => 0;
requires 'DBIx::Class::Schema'        => 0;
requires 'File::ShareDir'             => 0;
requires 'File::Spec'                 => 0;
requires 'FindBin'                    => 0;
requires 'HTML::Entities'             => 0;
requires 'Template'                   => 0;
requires 'Template::Stash'            => 0;
requires 'Time::Local'                => 0;

recommends 'CGI' => 3.48;

test_requires 'Test::More'  => 0;
test_requires 'DBD::SQLite' => 0;

auto_install;

install_share;

WriteAll;
