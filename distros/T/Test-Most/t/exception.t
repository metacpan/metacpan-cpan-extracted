#!/usr/bin/perl

use lib 'lib', 't/lib';
use Test::Most tests => 4;
use Test::Most::Exception 'throw_failure';

ok defined &throw_failure,
  '&throw_failure should be exported to our namespace';

throws_ok { throw_failure error => 'some message' }
'Test::Most::Exception',
  '... and it should throw an exception';

my $error = $@;
is $error->message, 'some message',
  '... and it should have the proper error message';
is $error->description, 'Test failed.  Stopping test.',
  '... and the proper description';
