#########################
use strict;
use warnings;
use Capture::Tiny qw(capture_stderr capture_stdout);
use Test::More tests => 50;
#########################
{
BEGIN { use_ok(q{Text::Convert::PETSCII}, qw{:all}) };
}
#########################
{
    is(Text::Convert::PETSCII::_is_integer(0x41), 1, q{_is_integer - check if integer value is properly recognized});
}
#########################
{
    is(Text::Convert::PETSCII::_is_integer(3.14), 0, q{_is_integer - check if numeric value is properly recognized});
}
#########################
{
    is(Text::Convert::PETSCII::_is_integer(q{x}), 0, q{_is_integer - check if character string is properly recognized});
}
#########################
{
    is(Text::Convert::PETSCII::_is_string(0x41), 0, q{_is_string - check if integer value is properly recognized});
}
#########################
{
    is(Text::Convert::PETSCII::_is_string(3.14), 0, q{_is_string - check if numeric value is properly recognized});
}
#########################
{
    is(Text::Convert::PETSCII::_is_string(q{x}), 1, q{_is_string - check if character string is properly recognized});
}
#########################
{
    my $stderr = capture_stderr {
        write_petscii_char(*STDOUT, [1, 2, 3]);
    };
    like($stderr, qr/^\QNot a valid PETSCII character to write: [1,2,3] (expected integer code or character byte)\E/, q{write_petscii_char - warns on passing array reference});
}
#########################
{
    my $stderr = capture_stderr {
        write_petscii_char(*STDOUT, 0.4);
    };
    like($stderr, qr/^\QNot a valid PETSCII character to write: '0.4' (expected integer code or character byte)\E/, q{write_petscii_char - warns on passing floating point});
}
#########################
{
    my $stderr = capture_stderr {
        write_petscii_char(*STDOUT, 0x1f);
    };
    like($stderr, qr/^\QValue out of range: "0x1f" (PETSCII character set supports printable characters in the range of 0x20 to 0x7f and 0xa0 to 0xff)\E/, q{write_petscii_char - warns on passing number too small});
}
#########################
{
    my $stderr = capture_stderr {
        write_petscii_char(*STDOUT, 0x100);
    };
    like($stderr, qr/^\QValue out of range: "0x100" (PETSCII character set supports printable characters in the range of 0x20 to 0x7f and 0xa0 to 0xff)\E/, q{write_petscii_char - warns on passing number too large});
}
#########################
{
    my $stderr = capture_stderr {
        write_petscii_char(*STDOUT, q{});
    };
    like($stderr, qr/^\QPETSCII character byte missing, nothing to be printed out\E/, q{write_petscii_char - warns on passing empty string});
}
#########################
{
    my $stderr = capture_stderr {
        write_petscii_char(*STDOUT, 'xyz');
    };
    like($stderr, qr/^\QPETSCII character string too long: 3 bytes (currently writing only a single character is supported)\E/, q{write_petscii_char - warns on passing more than single byte});
}
#########################
{
    my $stderr = capture_stderr {
        set_petscii_write_mode('unknown');
    };
    like($stderr, qr/^\QFailed to set PETSCII write mode, invalid PETSCII write mode: "unknown"\E/, q{set_petscii_write_mode - warns on setting invalid PETSCII write mode});
}
#########################
{
    my $stdout = capture_stdout {
        write_petscii_char(*STDOUT, ascii_to_petscii('a'));
    };
    my $petscii_a = <<PETSCII;
---**---
--****--
-**--**-
-******-
-**--**-
-**--**-
-**--**-
--------
PETSCII
    is($stdout, $petscii_a, q{write_petscii_char - print out unshifted PETSCII character byte ('a')});
}
#########################
{
    my $stdout = capture_stdout {
        write_petscii_char(*STDOUT, ascii_to_petscii(' '));
    };
    my $petscii_a = <<PETSCII;
--------
--------
--------
--------
--------
--------
--------
--------
PETSCII
    is($stdout, $petscii_a, q{write_petscii_char - print out unshifted PETSCII character byte (' ')});
}
#########################
{
    my $stdout = capture_stdout {
        write_petscii_char(*STDOUT, ascii_to_petscii('?'));
    };
    my $petscii_a = <<PETSCII;
--****--
-**--**-
-----**-
----**--
---**---
--------
---**---
--------
PETSCII
    is($stdout, $petscii_a, q{write_petscii_char - print out unshifted PETSCII character byte ('?')});
}
#########################
{
    my $stdout = capture_stdout {
        write_petscii_char(*STDOUT, ascii_to_petscii('@'));
    };
    my $petscii_a = <<PETSCII;
--****--
-**--**-
-**-***-
-**-***-
-**-----
-**---*-
--****--
--------
PETSCII
    is($stdout, $petscii_a, q{write_petscii_char - print out unshifted PETSCII character byte ('@')});
}
#########################
{
    my $stdout = capture_stdout {
        write_petscii_char(*STDOUT, ascii_to_petscii(']'));
    };
    my $petscii_a = <<PETSCII;
--****--
----**--
----**--
----**--
----**--
----**--
--****--
--------
PETSCII
    is($stdout, $petscii_a, q{write_petscii_char - print out unshifted PETSCII character byte (']')});
}
#########################
{
    eval { my $screen_code = Text::Convert::PETSCII::_petscii_to_screen_code(-1); };
    like($@, qr/^\QInvalid PETSCII integer code: "0xff\E/, q{_petscii_to_screen_code - dies on passing negative PETSCII character code});
}
#########################
{
    eval { my $screen_code = Text::Convert::PETSCII::_petscii_to_screen_code(0x100); };
    like($@, qr/^\QInvalid PETSCII integer code: "0x100\E/, q{_petscii_to_screen_code - dies on passing non-singlebyte PETSCII character code});
}
#########################
{
    my $screen_code = Text::Convert::PETSCII::_petscii_to_screen_code(65);
    is($screen_code, 1, q{_petscii_to_screen_code - converting PETSCII integer value to the screen code});
}
#########################
{
    my $stdout = capture_stdout {
        write_petscii_char(*STDOUT, 0x20);
    };
    my $petscii_a = <<PETSCII;
--------
--------
--------
--------
--------
--------
--------
--------
PETSCII
    is($stdout, $petscii_a, q{write_petscii_char - print out unshifted PETSCII integer code ($20)});
}
#########################
{
    my $stdout = capture_stdout {
        write_petscii_char(*STDOUT, 0x3f);
    };
    my $petscii_a = <<PETSCII;
--****--
-**--**-
-----**-
----**--
---**---
--------
---**---
--------
PETSCII
    is($stdout, $petscii_a, q{write_petscii_char - print out unshifted PETSCII integer code ($3f)});
}
#########################
{
    my $stdout = capture_stdout {
        write_petscii_char(*STDOUT, 0x40);
    };
    my $petscii_a = <<PETSCII;
--****--
-**--**-
-**-***-
-**-***-
-**-----
-**---*-
--****--
--------
PETSCII
    is($stdout, $petscii_a, q{write_petscii_char - print out unshifted PETSCII integer code ($40)});
}
#########################
{
    my $stdout = capture_stdout {
        write_petscii_char(*STDOUT, 0x41);
    };
    my $petscii_a = <<PETSCII;
---**---
--****--
-**--**-
-******-
-**--**-
-**--**-
-**--**-
--------
PETSCII
    is($stdout, $petscii_a, q{write_petscii_char - print out unshifted PETSCII integer code ($41)});
}
#########################
{
    my $stdout = capture_stdout {
        write_petscii_char(*STDOUT, 0x5f);
    };
    my $petscii_a = <<PETSCII;
--------
---*----
--**----
-*******
-*******
--**----
---*----
--------
PETSCII
    is($stdout, $petscii_a, q{write_petscii_char - print out unshifted PETSCII integer code ($5f)});
}
#########################
{
    my $stdout = capture_stdout {
        write_petscii_char(*STDOUT, 0x60);
    };
    my $petscii_a = <<PETSCII;
--------
--------
--------
********
********
--------
--------
--------
PETSCII
    is($stdout, $petscii_a, q{write_petscii_char - print out unshifted PETSCII integer code ($60)});
}
#########################
{
    my $stdout = capture_stdout {
        write_petscii_char(*STDOUT, 0x7f);
    };
    my $petscii_a = <<PETSCII;
********
-*******
--******
---*****
----****
-----***
------**
-------*
PETSCII
    is($stdout, $petscii_a, q{write_petscii_char - print out unshifted PETSCII integer code ($7f)});
}
#########################
{
    my $stdout = capture_stdout {
        write_petscii_char(*STDOUT, 0xa0);
    };
    my $petscii_a = <<PETSCII;
--------
--------
--------
--------
--------
--------
--------
--------
PETSCII
    is($stdout, $petscii_a, q{write_petscii_char - print out unshifted PETSCII integer code ($a0)});
}
#########################
{
    my $stdout = capture_stdout {
        write_petscii_char(*STDOUT, 0xbf);
    };
    my $petscii_a = <<PETSCII;
****----
****----
****----
****----
----****
----****
----****
----****
PETSCII
    is($stdout, $petscii_a, q{write_petscii_char - print out unshifted PETSCII integer code ($bf)});
}
#########################
{
    my $stdout = capture_stdout {
        write_petscii_char(*STDOUT, 0xc0);
    };
    my $petscii_a = <<PETSCII;
--------
--------
--------
********
********
--------
--------
--------
PETSCII
    is($stdout, $petscii_a, q{write_petscii_char - print out unshifted PETSCII integer code ($c0)});
}
#########################
{
    my $stdout = capture_stdout {
        write_petscii_char(*STDOUT, 0xdf);
    };
    my $petscii_a = <<PETSCII;
********
-*******
--******
---*****
----****
-----***
------**
-------*
PETSCII
    is($stdout, $petscii_a, q{write_petscii_char - print out unshifted PETSCII integer code ($df)});
}
#########################
{
    my $stdout = capture_stdout {
        write_petscii_char(*STDOUT, 0xe0);
    };
    my $petscii_a = <<PETSCII;
--------
--------
--------
--------
--------
--------
--------
--------
PETSCII
    is($stdout, $petscii_a, q{write_petscii_char - print out unshifted PETSCII integer code ($e0)});
}
#########################
{
    my $stdout = capture_stdout {
        write_petscii_char(*STDOUT, 0xfe);
    };
    my $petscii_a = <<PETSCII;
****----
****----
****----
****----
--------
--------
--------
--------
PETSCII
    is($stdout, $petscii_a, q{write_petscii_char - print out unshifted PETSCII integer code ($fe)});
}
#########################
{
    my $stdout = capture_stdout {
        write_petscii_char(*STDOUT, 0xff);
    };
    my $petscii_a = <<PETSCII;
--------
--------
------**
--*****-
-***-**-
--**-**-
--**-**-
--------
PETSCII
    is($stdout, $petscii_a, q{write_petscii_char - print out unshifted PETSCII integer code ($ff)});
}
#########################
{
    my $stdout = capture_stdout {
        set_petscii_write_mode('shifted');
        write_petscii_char(*STDOUT, ascii_to_petscii('a'));
    };
    my $petscii_a = <<PETSCII;
--------
--------
--****--
-----**-
--*****-
-**--**-
--*****-
--------
PETSCII
    is($stdout, $petscii_a, q{write_petscii_char - print out shifted PETSCII character byte ('a')});
}
#########################
{
    my $stdout = capture_stdout {
        set_petscii_write_mode('shifted');
        write_petscii_char(*STDOUT, ascii_to_petscii('A'));
    };
    my $petscii_a = <<PETSCII;
---**---
--****--
-**--**-
-******-
-**--**-
-**--**-
-**--**-
--------
PETSCII
    is($stdout, $petscii_a, q{write_petscii_char - print out shifted PETSCII character byte ('A')});
}
#########################
{
    my $stdout = capture_stdout {
        set_petscii_write_mode('shifted');
        write_petscii_char(*STDOUT, ascii_to_petscii('?'));
    };
    my $petscii_a = <<PETSCII;
--****--
-**--**-
-----**-
----**--
---**---
--------
---**---
--------
PETSCII
    is($stdout, $petscii_a, q{write_petscii_char - print out shifted PETSCII character byte ('?')});
}
#########################
{
    my $stdout = capture_stdout {
        set_petscii_write_mode('shifted');
        write_petscii_char(*STDOUT, 0x40);
    };
    my $petscii_a = <<PETSCII;
--****--
-**--**-
-**-***-
-**-***-
-**-----
-**---*-
--****--
--------
PETSCII
    is($stdout, $petscii_a, q{write_petscii_char - print out shifted PETSCII integer code ($40)});
}
#########################
{
    my $stdout = capture_stdout {
        set_petscii_write_mode('shifted');
        write_petscii_char(*STDOUT, 0x41);
    };
    my $petscii_a = <<PETSCII;
--------
--------
--****--
-----**-
--*****-
-**--**-
--*****-
--------
PETSCII
    is($stdout, $petscii_a, q{write_petscii_char - print out shifted PETSCII integer code ($41)});
}
#########################
{
    my $stdout = capture_stdout {
        set_petscii_write_mode('shifted');
        write_petscii_char(*STDOUT, 0x61);
    };
    my $petscii_a = <<PETSCII;
---**---
--****--
-**--**-
-******-
-**--**-
-**--**-
-**--**-
--------
PETSCII
    is($stdout, $petscii_a, q{write_petscii_char - print out shifted PETSCII integer code ($61)});
}
#########################
{
    my $stdout = capture_stdout {
        set_petscii_write_mode('shifted');
        write_petscii_char(*STDOUT, 0xc1);
    };
    my $petscii_a = <<PETSCII;
---**---
--****--
-**--**-
-******-
-**--**-
-**--**-
-**--**-
--------
PETSCII
    is($stdout, $petscii_a, q{write_petscii_char - print out unshifted PETSCII integer code ($c1)});
}
#########################
{
    my $stdout = capture_stdout {
        set_petscii_write_mode('shifted');
        write_petscii_char(*STDOUT, 0xda);
    };
    my $petscii_a = <<PETSCII;
-******-
-----**-
----**--
---**---
--**----
-**-----
-******-
--------
PETSCII
    is($stdout, $petscii_a, q{write_petscii_char - print out unshifted PETSCII integer code ($da)});
}
#########################
{
    my $stderr = capture_stderr {
        my $petscii_string = ascii_to_petscii('gąszcz');
    };
    like($stderr, qr/^\QInvalid ASCII code at position 2 of converted text string: "0xc4" (convertible codes include bytes between 0x00 and 0x7f)\E/, q{ascii_to_petscii - warns on passing invalid ASCII byte code});
}
#########################
{
    my $petscii_string = ascii_to_petscii('leszcz');
    my $ascii_string = petscii_to_ascii($petscii_string);
    is($ascii_string, q{leszcz}, q{ascii_to_petscii - convert an ASCII string to a PETSCII string});
}
#########################
{
    my $petscii_string = ascii_to_petscii('A');
    my $ascii_string = petscii_to_ascii($petscii_string);
    is($ascii_string, q{A}, q{ascii_to_petscii - convert an ASCII charcter to a PETSCII character});
}
#########################
{
    my $stderr = capture_stderr {
        my $petscii_string = join q{}, map { chr hex $_ } qw/41 42 43 61 62 63 81 82 83/;
        my $ascii_string = petscii_to_ascii($petscii_string);
    };
    like($stderr, qr/^\QInvalid PETSCII code at position 7 of converted text string: "0x81" (convertible codes include bytes between 0x00 and 0x7f)\E/, q{ascii_to_petscii - warns on passing invalid ASCII byte code});
}
#########################
{
    my $petscii_string = join q{}, map { chr hex $_ } qw/41 42 43 61 62 63/;
    my $ascii_string = petscii_to_ascii($petscii_string);
    is($ascii_string, q{abcABC}, q{petscii_to_ascii - convert a PETSCII string to an ASCII string});
}
#########################
{
    my $petscii_string = chr hex q{7a};
    my $ascii_string = petscii_to_ascii($petscii_string);
    is($ascii_string, q{Z}, q{petscii_to_ascii - convert a PETSCII character to an ASCII character});
}
#########################
