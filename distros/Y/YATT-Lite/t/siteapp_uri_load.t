#!/usr/bin/env perl
# -*- mode: perl; coding: utf-8 -*-
#----------------------------------------
use strict;
use warnings qw(FATAL all NONFATAL misc);
use FindBin; BEGIN { do "$FindBin::Bin/t_lib.pl" }
#----------------------------------------

# GH-309: SiteApp calls URI->new, so it must load URI by itself.
# CGI.pm loads URI only since 4.62, and Plack::Request is not loaded in CGI
# mode. To behave the same on any CGI.pm, hide URI.pm from CGI.pm here.
BEGIN {
  unshift @INC, sub {
    my (undef, $fn) = @_;
    return unless $fn eq 'URI.pm';
    return unless (caller(0))[1] =~ m{/CGI\.pm\z};
    my $stub = q{delete $INC{'URI.pm'}; 1;};
    open my $fh, '<', \$stub or die $!;
    return $fh;
  };
}

use Test::More;

use_ok('YATT::Lite::WebMVC0::SiteApp');

ok(URI->can('new'), "SiteApp loads URI by itself");

done_testing();
