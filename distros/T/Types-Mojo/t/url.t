#!/usr/bin/env perl

use strict;
use warnings;

use Test::Spec;

use File::Basename;
use lib dirname(__FILE__);

use TestClass;
use Mojo::URL;
use Types::Mojo qw(MojoURL);

describe 'MojoURL' => sub {
    it 'accepts a Mojo::URL object' => sub {
        my $obj = TestClass->new( url => Mojo::URL->new('http://perl-services.de') );
        isa_ok $obj->url, 'Mojo::URL';
        is $obj->url->host, 'perl-services.de';
        is $obj->url->scheme, 'http';
    };

    it 'coerces a string' => sub {
        my $obj = TestClass->new( url => 'http://perl-services.de' );
        isa_ok $obj->url, 'Mojo::URL';
        is $obj->url->host, 'perl-services.de';
        is $obj->url->scheme, 'http';
    };

    it 'parameterized with "https?" to accept only http and https urls' => sub {
        my $check  = MojoURL["https?"];
        my $http_return = $check->(Mojo::URL->new('http://perl-services.de'));
        ok $http_return;

        my $https_return = $check->(Mojo::URL->new('https://perl-services.de'));
        ok $https_return;

        my $error = '';
        my $ftp_return;
        eval {
            $ftp_return = $check->( Mojo::URL->new('ftp://ftp.otrs.org') );
        } or $error = $@;

        ok !$ftp_return;
        like $error, qr/did not pass/;
    };

    it '"http_url" accepts only http url -> ok' => sub {
        my $error = '';
        eval {
            my $obj = TestClass->new( http_url => Mojo::URL->new( 'http://perl-services.de' ) );
        } or $error = $@;

        is $error, '';

        $error = '';
        eval {
            my $obj = TestClass->new( http_url => Mojo::URL->new( 'https://perl-services.de' ) );
        } or $error = $@;

        is $error, '';

        $error = '';
        eval {
            my $obj = TestClass->new( http_url => 'https://perl-services.de' );
        } or $error = $@;

        is $error, '';
    };

    it '"http_url" accepts only http url -> fails' => sub {
        my $error = '';
        eval {
            my $obj = TestClass->new( http_url => Mojo::URL->new( 'ftp://ftp.otrs.org' ) );
        } or $error = $@;

        like $error, qr/did not pass/;

        $error = '';
        eval {
            my $obj = TestClass->new( http_url => 'ftp://ftp.otrs.org' );
        } or $error = $@;

        like $error, qr/did not pass/;
    };
};


runtests if !caller;
