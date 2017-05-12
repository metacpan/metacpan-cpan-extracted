use Test::More qw/no_plan/;
use Test::Exception;
use Text::Livedoor::Wiki::Plugin::Function;
dies_ok { Text::Livedoor::Wiki::Plugin::Function->process } 'implement me';
dies_ok { Text::Livedoor::Wiki::Plugin::Function->process_mobile } 'implement me';

