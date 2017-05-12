use inc::Module::Install;

all_from 'lib/WWW/KGS/GameArchives.pm';
readme_from 'lib/WWW/KGS/GameArchives.pm';

repository 'https://github.com/anazawa/p5-WWW-KGS-GameArchives';

requires 'Web::Scraper';
requires 'URI';

no_index directory => 'examples';

test_requires 'Test::More' => '0.98';
test_requires 'Path::Class' => '0.22';

tests 't/*.t xt/*.t';

WriteAll;
