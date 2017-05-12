use Test::Base tests => 23;

BEGIN { use_ok('Text::Diff3', ':factory') };

my $a = ['1 line', '2 line', '3 line', q{}, q{}];
my $t;

# If you test another Factory change this
my $Factory = 'Text::Diff3::Factory';

can_ok($Factory, 'new');
my $factory = $Factory->new;

can_ok($factory, 'create_text');

my $text = $factory->create_text($a);
my $text2 = $factory->create_text(join "\n", @$a, q{});
is_deeply($text, $text2, 'constructor can accept array ref or string');

can_ok($text, 'first_index');
can_ok($text, 'last_index');
can_ok($text, 'at');
can_ok($text, 'eq_at');
can_ok($text, 'as_string_at');
can_ok($text, 'size');
can_ok($text, 'range');

ok(! defined($text->at($text->first_index - 1)),
    '$text->at($text->first_index - 1) == undef');

ok(! defined($text->at($text->first_index - 1)),
    '$text->at($text->last_index + 1) == undef');

my $size = $text->last_index - $text->first_index + 1;
ok($size == @$a, 'size() returns collectly');
ok($size == $text->size, 'size == last - first + 1');

my @range = $text->range;
ok($size == @range, 'size == @range');
ok($text->first_index == $range[0], 'first_index == range[0]');
ok($text->last_index == $range[-1], 'last_index == range[-1]');

$t = [map { $text->at($_) } @range];
is_deeply($a, $t, 'at() returns collect lines');

$t = 0;
for (@range) {
    ++$t if $text->eq_at($_, $text->at($_));
}
ok($t == @range, 'eq_at($_, at($_))');

$t = $text->first_index - 1;
ok($text->eq_at($t, undef), 'undef eq undef');
ok(! $text->eq_at($t, $text->at($t + 1)), 'undef ne first_line');
ok(! $text->eq_at($t + 1, undef), 'first_line ne undef');
