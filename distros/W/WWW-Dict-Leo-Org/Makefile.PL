#
# made for WWW::Dict::Leo::Org 1.33 and up

use ExtUtils::MakeMaker;

WriteMakefile(
  'NAME'         => 'WWW::Dict::Leo::Org',
  'VERSION_FROM' => 'Org.pm',
  'EXE_FILES'    => [ 'leo' ],
  'clean'        => { FILES => '*~' },
  'EXCLUDE_EXT'  => [ qw(README) ],
  'PREREQ_PM'    => { 'Carp::Heavy'       => 0,
                      'IO::Socket'        => 0,
                      'MIME::Base64'      => 0,
                      'XML::Simple'       => 0
                    }
);

