use strict;
use warnings;

use Test::More;
use Test::Exception;
use Test::Instance::Apache;

my $apache_instance = Test::Instance::Apache->new( modules => [] );

{
  local $ENV{PATH} = "";
  my $no_path_instance = Test::Instance::Apache->new( modules => [] );
  dies_ok { $no_path_instance->apache_httpd } 'Dies when no Apache found';
}

like ( $apache_instance->apache_httpd, qr/httpd|apache/, "Found an Apache server" );

done_testing;
