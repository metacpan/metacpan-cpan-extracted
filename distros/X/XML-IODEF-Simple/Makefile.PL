use inc::Module::Install;

name        'XML-IODEF-Simple';
all_from    'lib/XML/IODEF/Simple.pm';

requires    'Digest::MD5'           => '2.36';
requires    'Digest::SHA1'          => '2.11';
requires    'Module::Pluggable'     => '3.6';
requires    'Regexp::Common::net'   => '2.108';
requires    'XML::IODEF'            => '0.11';

WriteAll();
