package WebService::Lobid;
$WebService::Lobid::VERSION = '0.0041';
use strict;
use warnings;

use Moo;

has api_url => ( is=> 'ro', default=> 'https://lobid.org/');

1;
