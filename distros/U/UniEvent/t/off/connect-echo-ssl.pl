use strict;
use warnings;
use lib 't';
use UniClientSSL;
use Talkers;

UniClientSSL::connect(\&Talkers::echo);
