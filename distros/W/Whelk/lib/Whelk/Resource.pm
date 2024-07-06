package Whelk::Resource;
$Whelk::Resource::VERSION = '0.04';
use Kelp::Base 'Whelk';
use Role::Tiny::With;

with 'Whelk::Role::Resource';

sub api { ... }

1;

