# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 2;
use Text::Quoted;

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

$a = <<'EOF';
From: "Brian Christopher Robinson" <brian.c.robinson@trw.com>
zxc
> > An
> > alternative solution is to not have those phone calls at work,
> > faciliitated by worked very hard for a reasonably workday, then
> > leaving... thus having time to deal with personal issues when not at
> > work.
iabc
> Unfortunately, personal issues can't be conveniently shoved aside
eight
> hours a day.  People with kids especially have to deal with issues
> realted to picking them up and dropping them off at various times, as
x
EOF

$expected = [
          {
            'quoter' => '',
            'text' => 'From: "Brian Christopher Robinson" <brian.c.robinson@trw.com>
zxc',
            'raw' => 'From: "Brian Christopher Robinson" <brian.c.robinson@trw.com>
zxc',
          },
          [
            [
              {
                'quoter' => '> >',
                'text' => 'An
alternative solution is to not have those phone calls at work,
faciliitated by worked very hard for a reasonably workday, then
leaving... thus having time to deal with personal issues when not at
work.',
                'raw' => '> > An
> > alternative solution is to not have those phone calls at work,
> > faciliitated by worked very hard for a reasonably workday, then
> > leaving... thus having time to deal with personal issues when not at
> > work.',
              }
            ]
          ],
          {
            'quoter' => '',
            'text' => 'iabc',
            'raw' => 'iabc',
          },
          [
            {
              'quoter' => '>',
              'text' => 'Unfortunately, personal issues can\'t be conveniently shoved aside',
              'raw' => '> Unfortunately, personal issues can\'t be conveniently shoved aside',
            }
          ],
          {
            'quoter' => '',
            'text' => 'eight',
            'raw' => 'eight',
          },
          [
            {
              'quoter' => '>',
              'text' => 'hours a day.  People with kids especially have to deal with issues
realted to picking them up and dropping them off at various times, as',
              'raw' => '> hours a day.  People with kids especially have to deal with issues
> realted to picking them up and dropping them off at various times, as',
            }
          ],
          {
            'quoter' => '',
            'text' => 'x',
            'raw' => 'x',
          }
        ];

is_deeply(extract($a), $expected, 
          "Supercite doesn't screw me up as badly as before");

is(
    Text::Quoted::combine_hunks( extract($a) ),
    $a,
    "round-trips okay",
);
