# $Id: 02request.t 68 2019-01-04 00:15:58Z stro $

use strict;
use warnings;
use Test::More;
use Plack::Loader;
use Plack::Util;
use Plack::Test;
use HTTP::Request::Common;

use File::Spec;

use lib 'lib';

plan tests => 14;

local $ENV{'SCRIPT_NAME'} = $0;

use WWW::CPAN::SQLite;

ok my $app = WWW::CPAN::SQLite->new();
ok my $class = Plack::Util::load_class('WWW::CPAN::SQLite');
is (ref($app), $class);

my $psgi_app = sub { $app->psgi() };

ok my $test = Plack::Test->create($psgi_app);

ok my $res = $test->request(GET '/');
is $res->code => 404;

# Make a dummy file
mkdir File::Spec->catfile('t', 'static');
my $fname = File::Spec->catfile('t', 'static', 'cpan_sqlite_' . time . '.sqlite');
ok open my $F, '>', $fname;
ok print $F time;
ok close $F;

ok my $res2 = $test->request(GET '/');
is $res2->code => 302;

is (File::Spec->catfile('t', 'static', $res2->content) => $fname);

ok unlink $fname;
ok rmdir File::Spec->catfile('t', 'static');

