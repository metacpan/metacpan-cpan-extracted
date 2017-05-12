use strict;
use warnings;

use Test::More tests => 10;
BEGIN { use_ok('Text::Quoted') };

use Data::Dumper;

my $a = <<EOF;
> foo
> # Bar
> baz

quux
EOF

is_deeply(extract($a),
[[{text => 'foo',quoter => '>',raw => '> foo'},
  [{text => 'Bar',quoter => '> #',raw => '> # Bar'}],
  {text => 'baz',quoter => '>',raw => '> baz'}
 ],
 {text => '',empty => '1',quoter => '',raw => ''},
 {text => 'quux',quoter => '',raw => 'quux'}],
"Sample text is organized properly");

$a = <<EOF;

> foo
> > > baz
> > quux
> quuux
quuuux
EOF

my $a_dump = 
[
      { text => '', empty => '1', quoter => '', raw => '' },
      [
        { text => 'foo', quoter => '>', raw => '> foo' },
        [
          [
            { text => 'baz', quoter => '> > >',
              raw => '> > > baz' }
          ],
          { text => 'quux', quoter => '> >', raw => '> > quux' }
        ],
        { text => 'quuux', quoter => '>', raw => '> quuux' }
      ],
      { text => 'quuuux', quoter => '', raw => 'quuuux' }
    ];

is_deeply(extract($a), $a_dump, "Skipping levels works OK");

#########################
# handle nested comments with common >
$a = <<EOF;
> a
>> b
> c
EOF

$a_dump = 
    [
       [ 
         { 'text' => 'a', 'quoter' => '>', 'raw' => '> a' },
         [ { 'text' => 'b', 'quoter' => '>>', 'raw' => '>> b' } ],
         { 'text' => 'c', 'quoter' => '>', 'raw' => '> c' }
       ]
    ];

is_deeply(extract($a),$a_dump,"correctly parse >> delimiter");

#############
# when the quoter changes in the middle of things, don't get confused

$a = <<EOF;
> a
=> b
> c
EOF

$a_dump = 
    [
       [ { 'text' => 'a', 'quoter' => '>', 'raw' => '> a' } ],
       [ { 'text' => 'b', 'quoter' => '=>', 'raw' => '=> b' } ],
       [ { 'text' => 'c', 'quoter' => '>', 'raw' => '> c' } ]
    ];

is_deeply(extract($a),$a_dump,"correctly parse => delimiter");

#############
# when the quoter changes in the middle of things, don't get confused
# blank lines shouldn't affect it

$a = <<EOF;
> a

=> b

> c
EOF

$a_dump = 
    [
       [ { 'text' => 'a', 'quoter' => '>', 'raw' => '> a' } ],
       { 'text' => '', 'empty' => 1, 'quoter' => '', 'raw' => '' },
       [ { 'text' => 'b', 'quoter' => '=>', 'raw' => '=> b' } ],
       { 'text' => '', 'empty' => 1, 'quoter' => '', 'raw' => '' },
       [ { 'text' => 'c', 'quoter' => '>', 'raw' => '> c' } ]
    ];

is_deeply(extract($a),$a_dump,"correctly parse => delimiter with blank lines");

#############
# one of the real world quoter breakage examples was cpan>
# also, no text is required for the quoter to break things

$a = <<EOF;
>
cpan>
>
EOF

$a_dump = 
    [
       [ { 'text' => '', 'empty' => 1, 'quoter' => '>', 'raw' => '>' } ],
       [ { 'text' => '', 'empty' => 1, 'quoter' => 'cpan>', 'raw' => 'cpan>' } ],
       [ { 'text' => '', 'empty' => 1, 'quoter' => '>', 'raw' => '>' } ]
    ];

is_deeply(extract($a),$a_dump,"correctly parse cpan> delimiter with no text");

############
# just checking that when the cpan> quoter gets a space, we handle it properly

$a = <<EOF;
> a
cpan > b
> c
EOF

$a_dump = 
    [
       [ { 'text' => 'a', 'quoter' => '>', 'raw' => '> a' } ],
       { 'text' => 'cpan > b', 'quoter' => '', 'raw' => 'cpan > b' },
       [ { 'text' => 'c', 'quoter' => '>', 'raw' => '> c' } ],
    ];

is_deeply(extract($a),$a_dump,"correctly handles a non-delimiter");

Text::Quoted::set_quote_characters( qr/[!]/ );
$a = <<'EOF';
a
# b
c
! d
EOF

$a_dump = [
    {
        'text'   => "a\n# b\nc",
        'quoter' => '',
        'raw'    => "a\n# b\nc"
    },
    [
        {
            'text'   => "d",
            'quoter' => '!',
            'raw'    => "! d"
        },
    ]
];

is_deeply(extract($a),$a_dump,"customize quote char");

Text::Quoted::set_quote_characters( undef );
$a = <<'EOF';
a
# b
c
EOF

$a_dump = [
    {
        'text'   => "a\n# b\nc",
        'quoter' => '',
        'raw'    => "a\n# b\nc"
    },
];

is_deeply( extract($a), $a_dump, "customize quote char to exclude all" );

