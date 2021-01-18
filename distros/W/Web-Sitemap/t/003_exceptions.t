use strict;
use warnings;
use lib 't/lib';

use Test::More tests => 3;
use SitemapTesters;

SitemapTesters::new_dies({}, 'empty params dies ok');
SitemapTesters::new_dies({output_dir => 'asdf', asdf => 1}, 'unknown param dies ok');
SitemapTesters::new_dies({output_dir => 'asdf', move_from_temp_action => 1}, 'incorrect move action dies ok');
