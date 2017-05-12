use Test::Base tests => 2;

BEGIN { use_ok('Text::Diff3', ':factory') }

can_ok('Text::Diff3::Factory', 'new');

