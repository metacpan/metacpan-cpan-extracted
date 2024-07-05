package Whelk::Resource;
$Whelk::Resource::VERSION = '0.03';
use Kelp::Base 'Whelk';
use Role::Tiny::With;

with 'Whelk::Role::Resource';

sub api { ... }

1;

