#!/usr/bin/env perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use WebService::ImKayac::Simple;

my $im = WebService::ImKayac::Simple->new(
    type     => 'password',
    user     => '__USER_NAME__',
    password => '__PASSWORD__',
);

$im->send('Hello!');
