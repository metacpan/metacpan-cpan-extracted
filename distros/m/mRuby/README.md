[![Build Status](https://travis-ci.org/tokuhirom/mRuby.pm.svg?branch=master)](https://travis-ci.org/tokuhirom/mRuby.pm)
# NAME

mRuby - mruby binding for perl5.

# SYNOPSIS

    use mRuby;

    my $mruby = mRuby->new(src => '9');
    my $ret = $mruby->run();

# DESCRIPTION

mRuby is mruby binding for perl5.

# METHODS

- `my $mruby = mRuby->new(src => $src : Str) : mRuby`

    Parse `src` and generate `mRuby` object.

- `my $mruby = mRuby->new(file => $file : Str) : mRuby`

    Parse source from `file` and generate `mRuby` object.

- `my $ret = $mruby->run() : Any`

    Run mruby code and get a return value.

- `my $ret = $mruby->funcall($funcname : Str, ...) : Any`

    Call specified named mruby function from `toplevel` context and get a return value.

# AUTHOR

Tokuhiro Matsuno &lt;tokuhirom AAJKLFJEF@ GMAIL COM>

karupanerura <karupa@cpan.org>

# LOW LEVEL API

See [mRuby::State](https://metacpan.org/pod/mRuby::State)

# SEE ALSO

[mRuby](https://metacpan.org/pod/mRuby)

# LICENSE

Copyright (C) Tokuhiro Matsuno

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
