# $Id$

use strict;
use warnings;
use Module::Build 0.4004;

my @authors = map {(my $mail = lc) =~ tr/a-z/./cs; "$_ <$mail\@apa.at>" }
('Philipp Gortan', 'Mario Paumann', 'Christian Eder', 'Stefan Hrdlicka');

my $builder = Module::Build->new
  (module_name         => 'XML::NewsML_G2',
   license             => 'gpl2',
   dist_author         => \@authors,
   dist_abstract       => 'generate NewsML-G2 news items',
   dist_version_from   => 'lib/XML/NewsML_G2.pm',
   requires =>
   { 'perl'                  => '5.8.0',
     'version'               => '0.77',
     'Moose'                 => '0.64',
     'Moose::Util'           => '0.64',
     'namespace::autoclean'  => '0.05',
     'XML::LibXML'           => 0,
     'DateTime'              => 0,
     'DateTime::Format::XSD' => 0,
     'Module::Runtime'       => 0,
     'UUID::Tiny'            => '1.02',
   },
   configure_requires =>
   { 'Module::Build' => 0.4004 # support for test_requires
   },
   test_requires =>
   { 'Test::More'      => 0,
     'Test::Exception' => 0,
   },
   add_to_cleanup =>
   [ 'XML-NewsML_G2-*',
   ],
   create_makefile_pl => 'traditional',
   sign => 1,
   meta_merge => {
       resources => {
           repository => 'https://github.com/apa-it/xml-newsml-g2',
           bugtracker => 'https://github.com/apa-it/xml-newsml-g2/issues',
           x_IRC => 'irc://irc.perl.org/#xml-newsml-g2',
       }
   },
  );

$builder->create_build_script();
