use ExtUtils::MakeMaker;

WriteMakefile(
  AUTHOR        => ["Alex 'AdUser' Z <aduser\@cpan.org>"],
  NAME          => 'Text::Playlist',
  ABSTRACT      => 'Collection of modules for work with various playlist formats',
  VERSION_FROM  => 'lib/Text/Playlist.pm',
  LICENSE       => 'perl_5',
  BUILD_REQUIRES => {
    'Test::More' => 0,
  },
);
