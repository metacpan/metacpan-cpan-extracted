# vi:set syntax=perl:

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'          => 'XML::CuteQueries',
    'VERSION_FROM'  => 'CuteQueries.pm',

    'PREREQ_PM'     => { 
        'XML::Twig'       => 0, # for CQ
        'Class::Accessor' => 0, # for CQ:E
        'Data::Dumper'    => 0, # required for testing, got some FAIL reports because this wasn't here.
        parent => 0,
    },

    ($ExtUtils::MakeMaker::VERSION ge '6.48'? 
        (MIN_PERL_VERSION => 5.006,
            META_MERGE => {
                keywords => [qw(xml twig cute simple easy)],
                resources=> {
                    repository => 'http://github.com/jettero/xml--cutequeries',
                },
            },

        LICENSE	=> 'LGPL',
    ) : ()),

);
