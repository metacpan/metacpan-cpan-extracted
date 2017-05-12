use ExtUtils::MakeMaker;

print 
    "\nIf you are testing:\n",
    "- for 'make test' to work you must be connected to the Internet\n",
    "- expect 'make test' to take some time since it tests sleepiness\n\n";

WriteMakefile(
    NAME		    => 'WWW::Mechanize::Sleepy',
    VERSION_FROM	=> 'Sleepy.pm', 
    PREREQ_PM		=> { WWW::Mechanize => 1.06 },
    ABSTRACT_FROM	=> 'Sleepy.pm', 
    AUTHOR		    => 'Kostas Ntonas <kntonas@gmail.com>',
    LICENSE         => 'perl',
    dist            => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean           => { FILES => 'WWW-Mechanize-Sleepy-*' },
);
