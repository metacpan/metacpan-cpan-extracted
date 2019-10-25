use ExtUtils::MakeMaker;
WriteMakefile(
    NAME                => 'WWW::Deduce::Ingest',
    VERSION_FROM        => 'Ingest.pm',
    ABSTRACT_FROM       => 'Ingest.pm',
    AUTHOR              => 'Jeff Weisberg <http://www.deduce.com/>',
    PREREQ_PM           => { JSON => 0, LWP => 0, Digest::SHA1 => 0, LWP::Protocol::https => 0 },
   );
