#!perl
use 5.020;
use strict;
use warnings;
use Test::More;

use Wordsmith::Claude::Options;

# Test default options
my $opts = Wordsmith::Claude::Options->new();
ok($opts, 'can create options');
ok(!$opts->has_model, 'no model by default');
ok(!$opts->has_language, 'no language by default');

# Test with model
$opts = Wordsmith::Claude::Options->new(model => 'haiku');
ok($opts->has_model, 'has model');
is($opts->model, 'haiku', 'model correct');

# Test with language
$opts = Wordsmith::Claude::Options->new(language => 'Spanish');
ok($opts->has_language, 'has language');
is($opts->language, 'Spanish', 'language correct');

# Test with all options
$opts = Wordsmith::Claude::Options->new(
    model               => 'sonnet',
    max_length          => 500,
    preserve_formatting => 1,
    language            => 'French',
);

is($opts->model, 'sonnet', 'model set');
is($opts->max_length, 500, 'max_length set');
ok($opts->preserve_formatting, 'preserve_formatting set');
is($opts->language, 'French', 'language set');

done_testing();
