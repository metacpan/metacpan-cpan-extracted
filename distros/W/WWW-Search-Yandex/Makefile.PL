use 5.008;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME      => 'WWW::Search::Yandex',
    VERSION   => '0.07',
    PREREQ_PM => { 'WWW::Search' => 2.528,
		   'WWW::SearchResult' => 2.061,
		   'HTML::TreeBuilder' => 3.13,
		   'URI' => 1.31,
		   'URI::Escape' => 3.26 },
    ABSTRACT_FROM  => "lib/WWW/Search/Yandex.pm",
    AUTHOR         => 'Artur Penttinen <artur+perl@niif.spb.su>',
    clean     => { FILES => "WWW-Search-*.tar.gz" .
                     " *~ */*~ */*/*~" },
    dist      => { COMPRESS => "gzip -9f", SUFFIX => "gz" }
);

exit;
