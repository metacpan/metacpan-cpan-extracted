use strict;
use warnings;
use lib 'lib';
use WWW::UsePerl::Server;

my $app = WWW::UsePerl::Server->apply_default_middlewares(
    WWW::UsePerl::Server->psgi_app );
$app;

