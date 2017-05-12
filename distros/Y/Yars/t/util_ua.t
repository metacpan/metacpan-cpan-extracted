use strict;
use warnings;
use Test::Clustericious::Config;
use Test::More tests => 2;

create_config_ok 'Yars', { url => 'http://localhost:1234', servers => [] };

require Yars::Tools;

my $tools = Yars::Tools->new;
isa_ok $tools->_ua, 'Mojo::UserAgent';

