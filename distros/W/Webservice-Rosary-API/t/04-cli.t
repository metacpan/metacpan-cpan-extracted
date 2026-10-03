use v5.10;
use strict;
use warnings;

use Test::More;
use FindBin qw/$Bin/;

require "$Bin/../bin/avemaria";

sub split_cli {
  my @args = @_;
  my ($command, $argv, $implicit) = local::bin::avemaria::_split_command_line(@args);
  return ($command, [@$argv], $implicit);
}

{
  my ($command, $argv, $implicit) = split_cli();
  is $command, q{}, 'bare invocation has no explicit command';
  is_deeply $argv, [], 'bare invocation has no remaining options';
  ok $implicit, 'bare invocation implies today';
}

{
  my ($command, $argv, $implicit) = split_cli('--scroll');
  is $command, q{}, '--scroll is not mistaken for a subcommand';
  is_deeply $argv, ['--scroll'], '--scroll remains available to prayer option parsing';
  ok $implicit, '--scroll alone implies today';
}

{
  my ($command, $argv, $implicit) = split_cli('--speed=2', '--between=0');
  is $command, q{}, 'timing options do not become subcommands';
  is_deeply $argv, ['--speed=2', '--between=0'], 'timing options are preserved';
  ok $implicit, 'timing options alone imply today';
}

{
  my ($command, $argv, $implicit) = split_cli('Monday', '--scroll');
  is $command, 'Monday', 'explicit day remains the subcommand';
  is_deeply $argv, ['--scroll'], 'options after an explicit day are preserved';
  ok !$implicit, 'explicit day does not implicitly enable prayer';
}

for my $help (qw/-h --help/) {
  my ($command, $argv, $implicit) = split_cli($help);
  is $command, $help, "$help remains a help command";
  ok !$implicit, "$help does not imply prayer";
}

for my $about (qw/-a --about/) {
  my ($command, $argv, $implicit) = split_cli($about);
  is $command, $about, "$about remains an about command";
  ok !$implicit, "$about does not imply prayer";
}

{
  my ($command, $argv, $implicit) = split_cli('--color', '--light', '--scroll');
  is $command, q{}, '--color profile options do not become subcommands';
  is_deeply $argv, ['--color', '--light', '--scroll'],
    'color and presentation options are preserved';
  ok $implicit, 'color options alone imply today';
}


{
  my ($command, $argv, $implicit) = split_cli('--pray', '--unceasingly', '--scroll');
  is $command, q{}, '--pray and --unceasingly compose as prayer options';
  is_deeply $argv, ['--pray', '--unceasingly', '--scroll'],
    'explicit --pray may be combined with --unceasingly';
  ok $implicit, 'flags-only --pray --unceasingly selects today';
}

{
  my ($command, $argv, $implicit) = split_cli('--unceasingly', '--scroll', '--color');
  is $command, q{}, '--unceasingly is a prayer option, not a subcommand';
  is_deeply $argv, ['--unceasingly', '--scroll', '--color'],
    'unceasing prayer composes with presentation options';
  ok $implicit, 'flags-only unceasing prayer selects today';
}

{
  my ($command, $argv, $implicit) = split_cli('Monday', '--unceasingly', '--color', '--dark');
  is $command, 'Monday', 'explicit day is preserved with --unceasingly';
  is_deeply $argv, ['--unceasingly', '--color', '--dark'],
    'unceasing and color options remain available for prayer parsing';
  ok !$implicit, 'explicit day remains explicit with --unceasingly';
}

# Presentation helpers are intentionally pure so the UX can be regression-tested
# without making live API calls.
is local::bin::avemaria::_mystery_heading('friday', 'Sorrowful'),
  'FRIDAY - THE SORROWFUL MYSTERIES',
  'overall Mystery heading is uppercase';
is local::bin::avemaria::_prayer_role('hail__mary_9_3'), 'hail_mary',
  'Hail Marys use the Marian color role';
is local::bin::avemaria::_hail_mary_role(1), 'hail_mary',
  'first Hail Mary in a group uses Marian blue';
is local::bin::avemaria::_hail_mary_role(2), 'hail_mary_alt',
  'second Hail Mary in a group uses the neutral alternate';
is local::bin::avemaria::_hail_mary_role(3), 'hail_mary',
  'Hail Mary alternation returns to Marian blue';
is local::bin::avemaria::_prayer_role('our__father_4'), 'our_father',
  'Our Fathers use the green color role';
is local::bin::avemaria::_prayer_role('glory_be_4'), 'glory_be',
  'Glory Be uses the gold color role';
is local::bin::avemaria::_prayer_role('oh_my_jesus_4'), 'fatima',
  'Fatima prayer uses the lavender color role';
is local::bin::avemaria::_mystery_role('Joyful', 0), 'mystery_joyful',
  'Joyful set heading uses the Joyful family role';
is local::bin::avemaria::_mystery_role('Sorrowful', 1), 'mystery_sorrowful_title',
  'specific Sorrowful Mystery uses the bold Sorrowful role';
is local::bin::avemaria::_mystery_role('Glorious', 1), 'mystery_glorious_title',
  'specific Glorious Mystery uses the bold Glorious role';
is local::bin::avemaria::_mystery_role('Luminous', 1), 'mystery_luminous_title',
  'Luminous Mysteries are included in the family palette';

my $dark = local::bin::avemaria::_color_palette('dark');
my $light = local::bin::avemaria::_color_palette('light');
ok $dark->{hail_mary} ne $dark->{our_father},
  'dark profile keeps Marian and Our Father colors distinct';
ok $dark->{hail_mary} ne $dark->{hail_mary_alt},
  'dark profile alternates Marian blue with a neutral foreground';
like $dark->{hail_mary_alt}, qr/38;5;255m/,
  'dark profile Hail Mary alternate is soft white';
ok $light->{hail_mary} ne $light->{our_father},
  'light profile keeps Marian and Our Father colors distinct';
ok $light->{hail_mary} ne $light->{hail_mary_alt},
  'light profile alternates Marian blue with a neutral foreground';
like $light->{hail_mary_alt}, qr/38;5;236m/,
  'light profile Hail Mary alternate is charcoal';
ok $dark->{hail_mary} ne $light->{hail_mary},
  'dark and light profiles use different contrast values';
is $dark->{hail_mary}, $dark->{mystery_joyful},
  'dark Joyful heading uses the same light blue as the Hail Mary';
like $dark->{mystery_sorrowful}, qr/38;5;167m/,
  'dark Sorrowful heading uses muted dark red';
like $dark->{mystery_glorious}, qr/38;5;180m/,
  'dark Glorious heading uses soft gold';
like $dark->{mystery_luminous}, qr/38;5;183m/,
  'dark Luminous heading uses gentle violet';
like $dark->{mystery_joyful_title}, qr/^\e\[1;/,
  'specific Mystery title is bold';
is(($light->{mystery_sorrowful_title} =~ /88m/) ? 1 : 0, 1,
  'light profile uses a deeper maroon for Sorrowful titles');


is local::bin::avemaria::_prayer_role('i_believe'), 'major_prayer',
  'Apostles Creed uses the major-prayer role';
is local::bin::avemaria::_prayer_role('holy_queen'), 'major_prayer',
  'Hail Holy Queen uses the major-prayer role';
is local::bin::avemaria::_prayer_role('final_prayer'), 'major_prayer',
  'closing O God prayer uses the major-prayer role';
like $dark->{major_prayer}, qr/^\e\[1;38;5;255m$/,
  'major prayers are bold white in the dark profile';
like $light->{major_prayer}, qr/^\e\[1;38;5;232m$/,
  'major prayers use bold near-black in the light profile';

my $long_closing = join q{ }, ('O God, whose only begotten Son, by His life, death and resurrection, has purchased for us the rewards of eternal life;') x 2;
my $folded_closing = local::bin::avemaria::_format_prayer_text('final_prayer', $long_closing);
ok !(grep { length($_) > 72 } split /\n/, $folded_closing),
  'final O God prayer is folded to 72 columns';
is local::bin::avemaria::_format_prayer_text('holy_queen', 'Hail Holy Queen'), 'Hail Holy Queen',
  'other major prayers are not unnecessarily folded';

like Webservice::Rosary::Stream->controls_help, qr/q quit/,
  'interactive help advertises q quit';

done_testing;
