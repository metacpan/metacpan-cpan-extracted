use strict;
use warnings;
use Test::More;

use_ok 'Uniform::HTTP';
use_ok 'Uniform::HTTP::Message';
use_ok 'Uniform::HTTP::Request';
use_ok 'Uniform::HTTP::Response';
use_ok 'Uniform::HTTP::Auth';
use_ok 'Uniform::HTTP::Auth::Basic';
use_ok 'Uniform::HTTP::Auth::Bearer';
use_ok 'Uniform::HTTP::Auth::Digest';

done_testing;
