#!/usr/bin/perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";

use Data::Dumper;
use WebService::MobileMe;

my $mme = WebService::MobileMe->new(username => '', password=>'', debug => 1 );
print Dumper($mme->locate);
print Dumper($mme->device);

# print Dumper($mme->remoteLock(242));

# print Dumper( $mme->sendMessage( message => 'mmm bacon', alarm => 1 ) );

# print Dumper($mme->sendMessage(message => 'urmom likes messages from me', alarm => 1));
