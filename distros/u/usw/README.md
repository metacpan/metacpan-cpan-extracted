[![Build Status](https://travis-ci.com/worthmine/usw.svg?branch=master)](https://travis-ci.com/worthmine/usw) [![Build Status](https://img.shields.io/appveyor/ci/worthmine/usw/master.svg?logo=appveyor)](https://ci.appveyor.com/project/worthmine/usw/branch/master)
# NAME

usw - use utf8; use strict; use warnings; in one line.

# SYNOPSIS

    use usw; # is just 8 bytes pragma instead of below:
    use utf8;
    use strict;
    use warnings;
    my $cp = '__YourCP__' || 'UTF-8';
    binmode \*STDIN,  ':encoding($cp)';
    binmode \*STDOUT, ':encoding($cp)';
    binmode \*STDERR, ':encoding($cp)';
     

# DESCRIPTION

usw is like a shortcut pragma that works in any environment.

May be useful for those who write the above code every single time.

## HOW TO USE

    use usw;

It seems a kind of pragmas but doesn't spent
[%^H](https://metacpan.org/pod/perlpragma#Key-naming)
because overusing it is nonsense.

`use usw;` should be just the very shortcut at beginning of your codes.

Therefore, if you want to set `no`, you should do it the same way as before.

    no strict;
    no warnings;
    no utf8;

These still work as expected everywhere.

And writing like this doesn't work.

    no usw;

## Automatically repairs bugs around file path which is encoded

It replaces `$SIG{__WARN__}` or/and `$SIG{__DIE__}`
to avoid the bug(This may be a strange specification)
of encoding only the file path like that:

    宣言あり at t/script/00_è­¦åãã.pl line 19.

## features

Since version 0.07, you can relate automatically
`STDIN`,`STDOUT`,`STDERR` with `cp\d+`
which is detected by [Win32](https://metacpan.org/pod/Win32) module.

Since version 0.08, you don't have to care if the environment is a Windows or not.

# SEE ALSO

- [Encode](https://metacpan.org/pod/Encode)
- [binmode](https://perldoc.perl.org/functions/binmode)
- [%SIG](https://perldoc.perl.org/variables/%25SIG)
- [Win32](https://metacpan.org/pod/Win32)

# LICENSE

Copyright (C) worthmine.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Yuki Yoshida([worthmine](https://github.com/worthmine))
