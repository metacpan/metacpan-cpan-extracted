[![Build Status](https://travis-ci.org/sago35/Text-Sprintf-Zenkaku.svg?branch=master)](https://travis-ci.org/sago35/Text-Sprintf-Zenkaku) [![Coverage Status](http://codecov.io/github/sago35/Text-Sprintf-Zenkaku/coverage.svg?branch=master)](https://codecov.io/github/sago35/Text-Sprintf-Zenkaku?branch=master)
# NAME

Text::Sprintf::Zenkaku - sprintf with zenkaku chars

# SYNOPSIS

    use Text::Sprintf::Zenkaku qw(sprintf);

    sprintf "<%3s>", "あ"; # zenkaku char works good

# DESCRIPTION

Text::Sprintf::Zenkaku is sprintf with zenkaku chars.

# METHOD

## sprintf()

sprintf() with zenkaku chars.

## calc\_width($width, $str)

Zenkaku considered calc width.

# REPOSITORY

[https://github.com/sago35/Text-Sprintf-Zenkaku](https://github.com/sago35/Text-Sprintf-Zenkaku)

# LICENSE

Copyright (C) sago35.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

sago35 <takasago@cpan.org>
