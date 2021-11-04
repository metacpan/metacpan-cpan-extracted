# This file is encoded in Shift_JIS.
die "This file is not encoded in Shift_JIS.\n" if '‚ ' ne "\x82\xA0";
die "This script is for perl only. You are using $^X.\n" if $^X =~ /jperl/i;

use strict;
use FindBin;
use lib "$FindBin::Bin/../lib";
use mb;
mb::set_script_encoding('sjis');
use vars qw(@test);

BEGIN {
    $SIG{__WARN__} = sub {
        local($_) = @_;
        m{\AHaving more than one /x regexp modifier is deprecated at } ? return :
        warn $_[0];
    };
}

@test = (

# 1
    sub { mb::eval(q{'a' =~ / [abc123] /x}) },
    sub { mb::eval(q{'b' =~ / [abc123] /x}) },
    sub { mb::eval(q{'c' =~ / [abc123] /x}) },
    sub { mb::eval(q{'1' =~ / [abc123] /x}) },
    sub { mb::eval(q{'2' =~ / [abc123] /x}) },
    sub { mb::eval(q{'3' =~ / [abc123] /x}) },
    sub { mb::eval(q{' ' !~ / [abc123] /x}) },
    sub {1},
    sub {1},
    sub {1},
# 11
    sub { mb::eval(q{'a' =~ / [abc 123] /x}) },
    sub { mb::eval(q{'b' =~ / [abc 123] /x}) },
    sub { mb::eval(q{'c' =~ / [abc 123] /x}) },
    sub { mb::eval(q{'1' =~ / [abc 123] /x}) },
    sub { mb::eval(q{'2' =~ / [abc 123] /x}) },
    sub { mb::eval(q{'3' =~ / [abc 123] /x}) },
    sub { mb::eval(q{' ' =~ / [abc 123] /x}) },
    sub {1},
    sub {1},
    sub {1},
# 21
    sub { mb::eval(q{'a' =~ / [abc 123] /xx}) },
    sub { mb::eval(q{'b' =~ / [abc 123] /xx}) },
    sub { mb::eval(q{'c' =~ / [abc 123] /xx}) },
    sub { mb::eval(q{'1' =~ / [abc 123] /xx}) },
    sub { mb::eval(q{'2' =~ / [abc 123] /xx}) },
    sub { mb::eval(q{'3' =~ / [abc 123] /xx}) },
    sub { mb::eval(q{' ' !~ / [abc 123] /xx}) },
    sub {1},
    sub {1},
    sub {1},
# 31
    sub { mb::eval(q{'a' =~ / [abc123] /xx}) },
    sub { mb::eval(q{'b' =~ / [abc123] /xx}) },
    sub { mb::eval(q{'c' =~ / [abc123] /xx}) },
    sub { mb::eval(q{'1' =~ / [abc123] /xx}) },
    sub { mb::eval(q{'2' =~ / [abc123] /xx}) },
    sub { mb::eval(q{'3' =~ / [abc123] /xx}) },
    sub { mb::eval(q{' ' !~ / [abc123] /xx}) },
    sub {1},
    sub {1},
    sub {1},
# 41
    sub { mb::eval(q{' ' =~ / [" -%] /x}  ) },
    sub { mb::eval(q{'!' =~ / [" -%] /x}  ) },
    sub { mb::eval(q{'"' =~ / [" -%] /x}  ) },
    sub { mb::eval(q{'%' =~ / [" -%] /x}  ) },
    sub { mb::eval(q{' ' !~ / [" -%] /xx} ) },
    sub { mb::eval(q{'!' !~ / [" -%] /xx} ) },
    sub { mb::eval(q{'"' =~ / [" -%] /xx} ) },
    sub { mb::eval(q{'%' =~ / [" -%] /xx} ) },
    sub {1},
    sub {1},
# 51
    sub { mb::eval(<<'END') },
'a' =~
/
    [
    abc
    123
    ]
/xx
END
    sub { mb::eval(<<'END') },
'\r' !~
/
    [
    abc
    123
    ]
/xx
END
    sub { mb::eval(<<'END') },
'\n' !~
/
    [
    abc
    123
    ]
/xx
END
    sub { mb::eval(<<'END') },
'\t' !~
/
    [
    abc
    123
    ]
/xx
END
    sub { mb::eval(<<'END') },
' ' !~
/
    [
    abc
    123
    ]
/xx
END
    sub { mb::eval(<<'END') },
'n' =~
/
    [
    abc # not a comment!
    123
    ]
/xx
END
    sub { mb::eval(<<'END') },
'!' =~
/
    [
    abc # not a comment!
    123
    ]
/xx
END
    sub { mb::eval(<<'END') },
'0' =~ / [0 - 9] /xx
END
    sub { mb::eval(<<'END') },
'9' =~ / [0 - 9] /xx
END
    sub {1},
#61
    sub { mb::eval(q{' ' !~   / [abc 123] /xx}) },
    sub { return 'SKIP'; mb::eval(q{' ' !~   ? [abc 123] ?xx}) },
    sub { mb::eval(q{' ' !~  m/ [abc 123] /xx}) },
    sub { mb::eval(q{' ' !~ qr/ [abc 123] /xx}) },
    sub { mb::eval(q{$_=' '; s/ [abc 123] //xx; $_ eq ' '; }) },
    sub { mb::eval(q{$_='AAA BBB,CCC'; @_=split( / [ ,] /x, $_); join(':',@_) eq 'AAA:BBB:CCC' }) },
    sub { mb::eval(q{$_='AAA BBB,CCC'; @_=split( / [ ,] /xx,$_); join(':',@_) eq 'AAA BBB:CCC' }) },
    sub { mb::eval(q{$_='AAA BBB,CCC'; @_=split(m/ [ ,] /x, $_); join(':',@_) eq 'AAA:BBB:CCC' }) },
    sub { mb::eval(q{$_='AAA BBB,CCC'; @_=split(m/ [ ,] /xx,$_); join(':',@_) eq 'AAA BBB:CCC' }) },
    sub {1},
#
);

$|=1; print "1..",scalar(@test),"\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" } ok($_->()) for @test;

__END__
