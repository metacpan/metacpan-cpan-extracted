#!/usr/bin/perl
use strict;
use warnings FATAL => 'all';
use Test::More tests => 14;
use vars qw( $class );
use HTML::Form;
use HTTP::Response;
use LWP;
use WWW::Mechanize::Pliant;
use File::Slurp;
use Test::LongString;


my $redirect;
my $request;
my %skip = (
      '/ordercatalogue/flowers.html' => 1);
{
    no warnings 'redefine';
    *LWP::UserAgent::request = sub {
        my ($self, $req) = @_;
        $request = $req;
        my $content;
        my $file = $req->uri->path || "/select_country.html";
        if ($redirect) {
            $content = read_file("t/files/redirect.html");
            $redirect = 0;
        } elsif ($skip{$file}) {
            $content = "";
        } else {
            $content = read_file("t/files$file");
        }
        my $res = HTTP::Response->new(200, "OK", [
           'Content-Base', 'http://localhost',
           'Content-Type', 'text/html'
           ], $content);
        return $res;
    }
}

my $mech = WWW::Mechanize::Pliant->new;
$mech->get("http://somedomain.com/select_country.html");

my $form = $mech->pliant_form;
$form->set_field('send_country', "canada");
$form->set_field('rec_country', "usa");
$form->click("Next");
my $request_orig = $mech->form_name('pliant')->click;
like $request->content, qr{send_country=canada};
like $request->content, qr{rec_country=usa};
isnt $request_orig->content, $request->content; 
#print $request->content;

my @args = split '&', $request->content;
my @button = grep { /button/ } @args;
is (@button, 1);
my ($key, $val) = split '=', $button[0];
is $val, '';

$mech->get("http://somedomain.com/select_country.html");
$mech->field('send_country','brazil');
$mech->field('rec_country','japan');
$mech->click('Next');
like $request->content, qr{send_country=brazil};
like $request->content, qr{rec_country=japan};

$mech->get("http://somedomain.com/select_country.html");
$mech->field('send_country','brazil');
$mech->field('rec_country','japan');
$redirect = 1;
$mech->click('Next');
lacks_string $mech->content, 'Your browser is not very smart';

use HTML::Entities;
is decode_entities(<<EOT), <<EOT2;
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
<head>
EOT
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
<head>
EOT2
my $html_ = read_file "t/files/party_flowers.html";
my $html = decode_entities($html_);
my $regex = "Buy now";
like $html, qr{title="$regex"\s+onClick="button_pressed\('(.*?)'\)"};

$mech->get("http://somedomain.com/party_flowers.html");
$mech->click('Buy now');
lacks_string $request->content, 'button*0*0*%2Fsites%2Fbroadwayflorists%2Fcommon.style%2F20061107171227%2F10*iRE.Xd0DFGVG4tUgVQSAxw*yjS96UgQdYuzw_n4FUP_Vg';
contains_string $request->content, 'button*0*0*/sites/broadwayflorists/common.style/20061107171227/4*d_oHxh1704DksCFVdJFXzFvDqiIQ0u96tuYS08ooctn1wLQ9JYuD7KPrJJ24arpX8tyZXIHrpFpQHqoTEH_2g.g*NIPSuRAsPNPrFoT3k2MkRA';

$mech->get("http://somedomain.com/checkout1.html");
$mech->click('Next');
contains_string $request->content, 'button';

$mech->get("http://somedomain.com/checkout3.html");
$mech->click('Next');
contains_string $request->content, 'button';


__END__
$mech->get("http://somedomain.com/checkbox.html");
$mech->field('send_country', "canada");
$mech->field('rec_country', "usa");
$mech->click("Next");
like $request->content, qr{send_country=canada};
like $request->content, qr{rec_country=usa};
