use inc::Module::Install;

name('WWW-Google-News-TW');
author('Cheng-Lung Sung <clsung@tw.freebsd.org>');
abstract('Access to Google\'s Taiwan News Service');
license('perl');
version_from('lib/WWW/Google/News/TW.pm');

requires(qw(
    perl        5.6.1
    LWP		0
    URI		0
    Test::More  0
));

WriteAll( );
