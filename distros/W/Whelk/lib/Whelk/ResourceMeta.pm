package Whelk::ResourceMeta;
$Whelk::ResourceMeta::VERSION = '1.02';
use Kelp::Base;

attr name => sub { $_[0]->config->{name} // $_[0]->class };
attr class => undef;
attr config => sub { {} };

1;

