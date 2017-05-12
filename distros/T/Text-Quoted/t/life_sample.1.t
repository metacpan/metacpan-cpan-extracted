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
>>>>> "dc" == darren chamberlain writes:

>> If I don't do "use Template;" in my startup script, each child will
>> get the pleasure of loading and compiling it all when the first script
>> that uses Template gets executed.

dc> Unless one of the other modules that you use in your startup script
dc> happens to use Template, in which case you'll be OK.

Well, that's still "use Template;" as far as I'm concerned.

I was really just being pedantic...  but think of a hosting situation
where the startup is pretty bare, and some Registry program uses the
template.

I personally don't think the preload should be called automagically,
even if it does the right thing most of the time.

_______________________________________________
templates mailing list
templates@template-toolkit.org
http://www.template-toolkit.org/mailman/listinfo/templates
EOF

$expected = [
          [
            [
              {
                'quoter' => '>>>>>',
                'text' => '"dc" == darren chamberlain writes:',
                'raw' => '>>>>> "dc" == darren chamberlain writes:',
              }
            ]
          ],
          {
            'quoter' => '',
            'text' => '',
            'raw' => '',
            'empty' => '1'
          },
          [
            {
              'quoter' => '>>',
              'text' => 'If I don\'t do "use Template;" in my startup script, each child will
get the pleasure of loading and compiling it all when the first script
that uses Template gets executed.',
              'raw' => '>> If I don\'t do "use Template;" in my startup script, each child will
>> get the pleasure of loading and compiling it all when the first script
>> that uses Template gets executed.',
            }
          ],
          {
            'quoter' => '',
            'text' => '',
            'raw' => '',
            'empty' => '1'
          },
          [
            {
              'quoter' => 'dc>',
              'text' => 'Unless one of the other modules that you use in your startup script
happens to use Template, in which case you\'ll be OK.',
              'raw' => 'dc> Unless one of the other modules that you use in your startup script
dc> happens to use Template, in which case you\'ll be OK.',
            }
          ],
          {
            'quoter' => '',
            'text' => '',
            'raw' => '',
            'empty' => '1'
          },
          {
            'quoter' => '',
            'text' => 'Well, that\'s still "use Template;" as far as I\'m concerned.',
            'raw' => 'Well, that\'s still "use Template;" as far as I\'m concerned.',
          },
          {
            'quoter' => '',
            'text' => '',
            'raw' => '',
            'empty' => '1'
          },
          {
            'quoter' => '',
            'text' => 'I was really just being pedantic...  but think of a hosting situation
where the startup is pretty bare, and some Registry program uses the
template.',
            'raw' => 'I was really just being pedantic...  but think of a hosting situation
where the startup is pretty bare, and some Registry program uses the
template.',
          },
          {
            'quoter' => '',
            'text' => '',
            'raw' => '',
            'empty' => '1'
          },
          {
            'quoter' => '',
            'text' => 'I personally don\'t think the preload should be called automagically,
even if it does the right thing most of the time.',
            'raw' => 'I personally don\'t think the preload should be called automagically,
even if it does the right thing most of the time.',
          },
          {
            'quoter' => '',
            'text' => '',
            'raw' => '',
            'empty' => '1'
          },
          {
            'separator' => '1',
            'quoter' => '',
            'text' => '_______________________________________________',
            'raw' => '_______________________________________________',
          },
          {
            'quoter' => '',
            'text' => 'templates mailing list
templates@template-toolkit.org
http://www.template-toolkit.org/mailman/listinfo/templates',
            'raw' => 'templates mailing list
templates@template-toolkit.org
http://www.template-toolkit.org/mailman/listinfo/templates',
          }
        ];


is_deeply(extract($a), $expected, 
          "Supercite doesn't screw me up as badly as before");

is(
    Text::Quoted::combine_hunks( extract($a) ),
    $a,
    "round-trips okay",
);
