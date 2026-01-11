#!perl
use 5.020;
use strict;
use warnings;
use Test::More;

use Wordsmith::Claude::Mode;

# Test mode existence
ok(Wordsmith::Claude::Mode->exists('eli5'), 'eli5 mode exists');
ok(Wordsmith::Claude::Mode->exists('pirate'), 'pirate mode exists');
ok(Wordsmith::Claude::Mode->exists('formal'), 'formal mode exists');
ok(!Wordsmith::Claude::Mode->exists('nonexistent'), 'nonexistent mode does not exist');

# Test get_instruction
my $eli5 = Wordsmith::Claude::Mode->get_instruction('eli5');
ok($eli5, 'eli5 has instruction');
like($eli5, qr/5-year-old/i, 'eli5 instruction mentions 5-year-old');

my $pirate = Wordsmith::Claude::Mode->get_instruction('pirate');
ok($pirate, 'pirate has instruction');
like($pirate, qr/arr|pirate/i, 'pirate instruction mentions pirate stuff');

ok(!defined Wordsmith::Claude::Mode->get_instruction('nonexistent'), 'nonexistent returns undef');

# Test get_description
my $desc = Wordsmith::Claude::Mode->get_description('eli5');
ok($desc, 'eli5 has description');

# Test get_category
is(Wordsmith::Claude::Mode->get_category('eli5'), 'complexity', 'eli5 is complexity');
is(Wordsmith::Claude::Mode->get_category('pirate'), 'fun', 'pirate is fun');
is(Wordsmith::Claude::Mode->get_category('formal'), 'tone', 'formal is tone');
is(Wordsmith::Claude::Mode->get_category('concise'), 'format', 'concise is format');
is(Wordsmith::Claude::Mode->get_category('proofread'), 'utility', 'proofread is utility');

# Test all_modes
my @modes = Wordsmith::Claude::Mode->all_modes;
ok(@modes > 10, 'has many modes');
ok((grep { $_ eq 'eli5' } @modes), 'all_modes includes eli5');
ok((grep { $_ eq 'pirate' } @modes), 'all_modes includes pirate');

# Test all_categories
my @cats = Wordsmith::Claude::Mode->all_categories;
ok((grep { $_ eq 'complexity' } @cats), 'has complexity category');
ok((grep { $_ eq 'fun' } @cats), 'has fun category');
ok((grep { $_ eq 'tone' } @cats), 'has tone category');
ok((grep { $_ eq 'format' } @cats), 'has format category');
ok((grep { $_ eq 'utility' } @cats), 'has utility category');

# Test modes_in_category
my @fun = Wordsmith::Claude::Mode->modes_in_category('fun');
ok(@fun >= 5, 'fun has multiple modes');
ok((grep { $_ eq 'pirate' } @fun), 'pirate is in fun');
ok((grep { $_ eq 'yoda' } @fun), 'yoda is in fun');
ok((grep { $_ eq 'shakespeare' } @fun), 'shakespeare is in fun');

# Test mode_info
my $info = Wordsmith::Claude::Mode->mode_info('eli5');
ok($info, 'mode_info returns hashref');
is($info->{category}, 'complexity', 'mode_info has category');
ok($info->{description}, 'mode_info has description');
ok($info->{instruction}, 'mode_info has instruction');

done_testing();
