use strict;
use Test::More tests => 12;
use YAML::Syck;

# GH #199: YAML::Syck should preserve the string nature of numeric-looking values.
# A Perl scalar that is a pure string (POK only, no IOK/NOK) must be quoted
# in the Dump output so that a subsequent Load sees it as a string, not an integer.

# Pure Perl string that looks like an integer
{
    my $str = "8080";
    my $yaml = Dump({ val => $str });
    like( $yaml, qr/val: '8080'/, "pure string '8080' is quoted in Dump" );
}

# Actual Perl integer
{
    my $num = 8080;
    my $yaml = Dump({ val => $num });
    like( $yaml, qr/val: 8080\b/, "integer 8080 is unquoted in Dump" );
    unlike( $yaml, qr/val: '8080'/, "integer 8080 is not single-quoted" );
}

# String that was numified (IOK+POK after arithmetic)
{
    my $str = "8080";
    my $n = $str + 0;
    my $yaml = Dump({ val => $str });
    like( $yaml, qr/val: 8080\b/, "numified string emits unquoted" );
}

# Original issue: flow collection with quoted strings
{
    my $yaml_in = qq{command: [ "daemon", "-p", "8080" ]};
    my $data = Load($yaml_in);
    my $yaml_out = Dump($data);
    like( $yaml_out, qr/'8080'/, "quoted '8080' in flow collection roundtrips quoted" );
}

# ImplicitTyping=1: unquoted number stays unquoted
{
    local $YAML::Syck::ImplicitTyping = 1;
    my $data = Load("val: 8080");
    my $yaml = Dump($data);
    like( $yaml, qr/val: 8080\b/, "ImplicitTyping=1: unquoted 8080 stays unquoted" );
    unlike( $yaml, qr/val: '8080'/, "ImplicitTyping=1: unquoted 8080 not quoted" );
}

# ImplicitTyping=1: quoted string stays quoted
{
    local $YAML::Syck::ImplicitTyping = 1;
    my $data = Load('val: "8080"');
    my $yaml = Dump($data);
    like( $yaml, qr/val: '8080'/, "ImplicitTyping=1: quoted '8080' stays quoted" );
}

# Zero string vs zero integer
{
    my $str_zero = "0";
    my $yaml = Dump({ val => $str_zero });
    like( $yaml, qr/val: '0'/, "string '0' is quoted" );

    my $num_zero = 0;
    $yaml = Dump({ val => $num_zero });
    like( $yaml, qr/val: 0\b/, "integer 0 is unquoted" );
}

# Float string
{
    my $str_float = "3.14";
    my $yaml = Dump({ val => $str_float });
    like( $yaml, qr/val: '3\.14'/, "float-like string '3.14' is quoted" );
}

# Negative number string
{
    my $str_neg = "-42";
    my $yaml = Dump({ val => $str_neg });
    like( $yaml, qr/val: '-42'/, "negative number string '-42' is quoted" );
}
