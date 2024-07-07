package Whelk::ResourceMeta;
$Whelk::ResourceMeta::VERSION = '0.06';
use Kelp::Base;

attr name => sub { $_[0]->config->{name} // $_[0]->class };
attr class => undef;
attr config => sub { {} };

1;

