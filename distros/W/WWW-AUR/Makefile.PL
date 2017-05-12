use inc::Module::Install;

name 'WWW-AUR';
version_from 'lib/WWW/AUR.pm';
author_from 'lib/WWW/AUR.pod';
license 'perl';
repository 'http://github.com/jnbek/perl-www-aur';

requires 'Archive::Tar' => 0;
requires 'Carp' => 0;
requires 'Cwd' => 0;
requires 'Fcntl' => 0;
requires 'HTTP::Cookies' => 0;
requires 'JSON' => 0;
requires 'LWP::UserAgent' => '6';
requires 'File::Path' => '2.06';
requires 'File::Spec' => 0;
requires 'URI' => 0;
requires 'LWP::Protocol::https' => '6';

test_requires 'Test::More' => '0.87_01';

clean_files 't/tmp';

no_index 'dir' => 'ex';
no_index 'package' => 'WWW::AUR::RPC';

WriteAll;
