use strict;
use warnings;
use Test::More;
use WebService::Moodle::Simple;
use Data::Dumper;

my $moodle = WebService::Moodle::Simple->new( 
  domain  => 'moodle.site.edu',
  target  => 'yinyang',
);

is(ref($moodle), 'WebService::Moodle::Simple');


done_testing();


