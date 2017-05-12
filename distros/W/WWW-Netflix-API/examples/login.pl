#!/usr/bin/perl

use strict;
use warnings;
use WWW::Netflix::API;
use XML::Simple;
use Data::Dumper;
my ($consumer_key, $consumer_secret, $user, $pass) = @ARGV;

my %auth = (
        consumer_key    => $consumer_key,
        consumer_secret => $consumer_secret,
);
my $netflix = WWW::Netflix::API->new({
	%auth,
	content_filter => sub { XMLin(@_) },
});

@auth{qw/access_token access_secret user_id/} = $netflix->RequestAccess( $user, $pass );
print Dumper \%auth;

