#!/usr/bin/perl -w

#$WWW::Link::Selector::verbose=0xFFFF;
BEGIN {print "1..4\n"}
END {print "not ok 1\n" unless $loaded;}

sub nogo () {print "not "}
sub ok ($) {my $t=shift; print "ok $t\n";}


use WWW::Link::Selector;
$loaded = 1;
ok(1);
@exclude=   ("^http://a.b/c/", "^ftp://sag.sog/");
@include= ("^http://a.b/", "^ftp://fig.fog/"); 
$selec = WWW::Link::Selector::gen_include_exclude @exclude, @include;
nogo unless ref($selec) =~ m/CODE/ ;
ok(2);
nogo unless &$selec("http://a.b/d/index.html");
ok(3);
nogo if &$selec("http://a.b/c/index.html");
ok(4);
