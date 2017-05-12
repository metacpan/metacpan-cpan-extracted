use Test::More qw/no_plan/;
use Test::Exception;
use Text::Livedoor::Wiki::Plugin::Inline;
dies_ok { Text::Livedoor::Wiki::Plugin::Inline->process } 'implement me';
dies_ok { Text::Livedoor::Wiki::Plugin::Inline->process_mobile } 'implement me';

