[![Build Status](https://travis-ci.com/worthmine/usw.svg?branch=master)](https://travis-ci.com/worthmine/usw)
# NAME

usw - use utf8; use strict; use warnings; in one line.

# SYNOPSIS

    use usw; # is just 8 bytes pragma instead of below:
    use utf8;
    use strict;
    use warnings;
    binmode \*STDOUT, ':encoding(UTF-8)';
    binmode \*STDERR, ':encoding(UTF-8)';
     

# DESCRIPTION

usw is a shortcut pragma mostly for one-liners.

May be useful for those who write the above code every single time

## HOW TO USE

    use usw;

It seems a kind of pragmas but doesn't spent
[%^H](https://metacpan.org/pod/perlpragma#Key-naming)
because overusing it is nonsense.

`use usw;` should be just the very shortcut at beginning of your codes

Therefore, if you want to set `no`, you should do it the same way as before.

    no strict;
    no warnings;
    no utf8;

These still work as expected everywhere.

And writing like this doesn't work

    no usw;

# LICENSE

Copyright (C) worthmine.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Yuki Yoshida([worthmine](https://github.com/worthmine))
