#!/usr/bin/perl

use v5.18;
use warnings;

use builtin;
no warnings 'experimental::builtin';

use Test::More;

# Vanilla trim tests
{
    use builtin qw( trim );

    is(trim("    Hello world!   ")      , "Hello world!"  , 'trim spaces');
    is(trim("\tHello world!\t")         , "Hello world!"  , 'trim tabs');
    is(trim("\n\n\nHello\nworld!\n")    , "Hello\nworld!" , 'trim \n');
    is(trim("\t\n\n\nHello world!\n \t"), "Hello world!"  , 'trim all three');
    is(trim("Perl")                     , "Perl"          , 'trim nothing');
    is(trim('')                         , ""              , 'trim empty string');

    is(prototype(\&builtin::trim), '$', 'trim prototype');
}

{
    my $warn = '';
    local $SIG{__WARN__} = sub { $warn .= join "", @_; };

    is(builtin::trim(undef), "", 'trim undef');
    like($warn    , qr/^Use of uninitialized value in (?:subroutine entry|trim) at/,
         'trim undef triggers warning');
}

# Fancier trim tests against a regexp and unicode
{
    use builtin qw( trim );
    my $nbsp = chr utf8::unicode_to_native(0xA0);

    is(trim("   \N{U+2603}       "), "\N{U+2603}", 'trim with unicode content');
    is(trim("\N{U+2029}foobar\x{2028} "), "foobar",
            'trim with unicode whitespace');
    is(trim("$nbsp foobar$nbsp    "), "foobar", 'trim with latin1 whitespace');
}

# Test on a magical fetching variable
{
    use builtin qw( trim );

    my $str3 = "   Hello world!\t";
    $str3 =~ m/(.+Hello)/;
    is(trim($1), "Hello", "trim on a magical variable");
}

# Inplace edit, my, our variables
{
    use builtin qw( trim );

    my $str4 = "\t\tHello world!\n\n";
    $str4 = trim($str4);
    is($str4, "Hello world!", "trim on an inplace variable");

    our $str2 = "\t\nHello world!\t  ";
    is(trim($str2), "Hello world!", "trim on an our \$var");
}

done_testing;
