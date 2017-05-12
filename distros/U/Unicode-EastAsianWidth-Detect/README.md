# NAME

Unicode::EastAsianWidth::Detect - Detect CJK Language

# SYNOPSIS

    use Unicode::EastAsianWidth::Detect;
    warn is_cjk_lang;

# DESCRIPTION

Unicode::EastAsianWidth::Detect is module that can detect the locale is CJK or
not.  For example, most of users who uses CJK languages are thinking that Easy
Asian Width Ambiguous Widths should be double cells.

# HOW TO USE

    use Unicode::EastAsianWidth;
    use Unicode::EastAsianWidth::Detect qw(is_cjk_lang);
    $Unicode::EastAsianWidth::EastAsian = is_cjk_lang;

# LICENSE

Copyright (C) mattn.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

mattn <mattn.jp@gmail.com>
