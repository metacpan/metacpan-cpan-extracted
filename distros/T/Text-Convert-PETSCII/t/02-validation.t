#########################
use strict;
use warnings;
use Capture::Tiny qw(capture_stderr capture_stdout);
use Test::More tests => 25;
#########################
{
BEGIN { use_ok(q{Text::Convert::PETSCII}, qw{:all}) };
}
#########################
{
    my $text_string;
    ok(!is_valid_petscii_string($text_string), 'an undefined value is not a valid PETSCII string');
}
#########################
{
    my $text_string;
    ok(!is_printable_petscii_string($text_string), 'an undefined value is not printable PETSCII string');
}
#########################
{
    my $text_string = '';
    ok(is_valid_petscii_string($text_string), 'an empty string is a valid PETSCII string');
}
#########################
{
    my $text_string = '';
    ok(is_printable_petscii_string($text_string), 'an empty string is printable PETSCII string');
}
#########################
{
    my $text_string = 'petscii';
    ok(is_valid_petscii_string($text_string), 'lower-cased ASCII string is a valid PETSCII string');
}
#########################
{
    my $text_string = 'petscii';
    ok(is_printable_petscii_string($text_string), 'lower-cased ASCII string is printable PETSCII string');
}
#########################
{
    my $text_string = 'PETSCIII';
    ok(is_valid_petscii_string($text_string), 'upper-cased ASCII string is a valid PETSCII string');
}
#########################
{
    my $text_string = 'PETSCIII';
    ok(is_printable_petscii_string($text_string), 'upper-cased ASCII string is printable PETSCII string');
}
#########################
SKIP:
{
    skip 'utf-8 validation unless perl version >= 5.8', 1 if $] < 5.008;
    my $text_string = chr 0x0100;
    ok(!is_valid_petscii_string($text_string), 'text string containing a UTF-8 wide character is not a valid PETSCII string');
}
#########################
SKIP:
{
    skip 'utf-8 validation unless perl version >= 5.8', 1 if $] < 5.008;
    my $text_string = chr 0x0100;
    ok(!is_printable_petscii_string($text_string), 'text string containing a UTF-8 wide character is not printable PETSCII string');
}
#########################
{
    my $text_string = [];
    ok(!is_valid_petscii_string($text_string), 'a reference to an object is not a valid PETSCII string');
}
#########################
{
    my $text_string = [];
    ok(!is_printable_petscii_string($text_string), 'a reference to an object is not printable PETSCII string');
}
#########################
{
    my $text_string = chr 0x1f;
    ok(is_valid_petscii_string($text_string), 'text string containing bytes less than $20 is a valid PETSCII string');
}
#########################
{
    my $text_string = chr 0x1f;
    ok(!is_printable_petscii_string($text_string), 'text string containing bytes less than $20 is not printable PETSCII string');
}
#########################
{
    my $text_string = chr 0x00;
    ok(is_valid_petscii_string($text_string), 'text string containing byte value $00 is a valid PETSCII string');
}
#########################
{
    my $text_string = chr 0x00;
    ok(!is_printable_petscii_string($text_string), 'text string containing byte value $00 is not printable PETSCII string');
}
#########################
{
    my $text_string = chr 0x7f;
    ok(is_valid_petscii_string($text_string), 'text string containing bytes less than $80 is a valid PETSCII string');
}
#########################
{
    my $text_string = chr 0x7f;
    ok(is_printable_petscii_string($text_string), 'text string containing bytes less than $80 is printable PETSCII string');
}
#########################
{
    my $text_string = chr 0x80;
    ok(is_valid_petscii_string($text_string), 'text string containing bytes greater than $80 is a valid PETSCII string');
}
#########################
{
    my $text_string = chr 0x80;
    ok(!is_printable_petscii_string($text_string), 'text string containing bytes greater than $80 is not printable PETSCII string');
}
#########################
{
    my $text_string = chr 0x9f;
    ok(is_valid_petscii_string($text_string), 'text string containing bytes less than $a0 is a valid PETSCII string');
}
#########################
{
    my $text_string = chr 0x9f;
    ok(!is_printable_petscii_string($text_string), 'text string containing bytes less than $a0 is not printable PETSCII string');
}
#########################
{
    my $text_string = chr 0xa0;
    ok(is_valid_petscii_string($text_string), 'text string containing bytes greater than $a0 is a valid PETSCII string');
}
#########################
{
    my $text_string = chr 0xa0;
    ok(is_printable_petscii_string($text_string), 'text string containing bytes greater than $a0 is printable PETSCII string');
}
#########################
