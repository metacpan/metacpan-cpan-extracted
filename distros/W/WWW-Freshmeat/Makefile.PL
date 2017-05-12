use 5.008;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'WWW::Freshmeat',
    AUTHOR              => 'Alexandr Ciornii <alexchorny@gmail.com>',
    VERSION_FROM        => 'lib/WWW/Freshmeat.pm',
    ABSTRACT_FROM       => 'lib/WWW/Freshmeat.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0.17, #isa_ok
        'LWP::UserAgent' => 0,
        'XML::Simple' => 0,
        'XML::Parser' => 0, #for XML::Simple, in case of dependency problems
        'LWP::Online' => 1.06,
        #'HTML::TreeBuilder::XPath' => 0.09,
        'Mouse' => 0.24, #recent one
        'File::Slurp' => 0,
    },
    ($ExtUtils::MakeMaker::VERSION ge '6.31'? 
     ('LICENSE'		=> 'perl', ) : ()),
    ($ExtUtils::MakeMaker::VERSION ge '6.48'? 
     ('MIN_PERL_VERSION' => 5.008,) : ()),
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'WWW-Freshmeat-*' },
);
