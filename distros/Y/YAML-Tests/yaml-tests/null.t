use t::TestYAMLTests tests => 2;

my $array = [
    undef,
    'undef',
    undef,
    '~',
    undef,
    undef,
    '~/file.txt',
];

my $yaml = Dump($array);

is $yaml, <<'...', "Nulls dump as ~";
---
- ~
- undef
- ~
- '~'
- ~
- ~
- ~/file.txt
...

my $array2 = Load($yaml);

is_deeply $array2, $array,
    "YAML with undefs loads properly";
