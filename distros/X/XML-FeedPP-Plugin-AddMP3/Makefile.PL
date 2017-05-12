use 5.005;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'XML::FeedPP::Plugin::AddMP3',
    VERSION_FROM      => 'lib/XML/FeedPP/Plugin/AddMP3.pm',
    PREREQ_PM         => {
        MP3::Info   => 1.22,
        Path::Class => 0.15,
        XML::FeedPP => 0.21,
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/XML/FeedPP/Plugin/AddMP3.pm', # retrieve abstract from module
       AUTHOR         => 'Makio Tsukamoto <tsukamoto@gmail.com>') : ()),
);
