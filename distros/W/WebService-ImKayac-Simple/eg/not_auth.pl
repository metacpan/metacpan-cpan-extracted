#!/usr/bin/env perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use WebService::ImKayac::Simple;

my $im = WebService::ImKayac::Simple->new(
    user => '__USER_NAME__',
);

$im->send('Hello!');
