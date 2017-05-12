use inc::Module::Install;

name 'Time-Piece-Over24';
author 'Syunsuke Fujishiro';
all_from 'lib/Time/Piece/Over24.pm';

build_requires 'Test::More';
build_requires 'Time::Piece::MySQL';
requires 'Time::Piece';
license 'perl';

WriteAll;
