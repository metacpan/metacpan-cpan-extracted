
use Test::More 0.88;
use YAML::Hobo;

my $got = YAML::Hobo::Dump(
    {   q  => '""',
        s1 => 'string with blanks',
        s2 => "string with newline\n",
        s3 => "string with \0",
    }
);
my $expected = <<YAML;
---
q: '""'
s1: "string with blanks"
s2: "string with newline\\n"
s3: "string with \\0"
YAML

is( $got, $expected, "More double quoted strings" );

done_testing;
