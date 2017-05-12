package WebService::Lobid;
$WebService::Lobid::VERSION = '0.0031';
use strict;
use warnings;

use Moo;

has api_url => ( is=> 'ro', default=> 'http://lobid.org/');

1;
