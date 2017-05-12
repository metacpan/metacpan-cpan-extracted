use Test::More qw/no_plan/;
use Test::Exception;
use Text::Livedoor::Wiki::Plugin::Block;
dies_ok { Text::Livedoor::Wiki::Plugin::Block->get } 'implement me';

