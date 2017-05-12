# NAME

WWW::XKCD::AsText - retrieve text versions of comics on www.xkcd.com

# SYNOPSIS

    use WWW::XKCD::AsText;

    my $xkcd          = WWW::XKCD::AsText->new;
    my $xkcd_retrieve = $xkcd->retrieve(1); # "A boy sits in a barrel..."

    $xkcd_retrieve->uri;   # "https://www.xkcd.com/1/"
    $xkcd_retrieve->text;  # "A boy sits in a barrel..."
    $xkcd_retrieve->error; # line_status

# METHODS

## retrieve

Takes XKCD comic number, returns its transcript.

# SEE ALSO

[WWW::xkcd](https://metacpan.org/pod/WWW::xkcd)

# AUTHOR

Original author is Zoffix Znet, `<zoffix at cpan.org>`,

currently maintained by Kivanc Yazan, `<kyzn at cpan.org>`.

# LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
