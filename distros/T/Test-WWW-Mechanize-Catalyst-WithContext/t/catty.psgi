#!/usr/bin/env perl

use File::Basename qw/ dirname /;
use File::Spec::Functions qw/ catdir /;
use Plack::Builder;

use Catty;

builder {

    enable "Static",
      path => qr{^/static/},
      root => catdir( dirname( __FILE__ ), 'root/' );

    mount '/' => Catty->psgi_app;

};
