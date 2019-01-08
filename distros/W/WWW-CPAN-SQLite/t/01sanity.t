# $Id: 01sanity.t 68 2019-01-04 00:15:58Z stro $

use strict;
use warnings;
use Test::More;

use lib 'lib';

plan tests => 4;

use_ok('WWW::CPAN::SQLite');

ok my $app = WWW::CPAN::SQLite->new();
ok my $class = Plack::Util::load_class('WWW::CPAN::SQLite');
is (ref($app), $class);


