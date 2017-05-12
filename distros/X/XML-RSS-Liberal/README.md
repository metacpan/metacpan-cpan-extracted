# NAME

XML::RSS::Liberal - XML::RSS With A Liberal Parser

# SYNOPSIS

    use XML::RSS::Liberal;
    my $rss = XML::RSS::Liberal->new;
    $rss->parsefile('rss.xml');

    # See XML::RSS::LibXML for details

# DESCRIPTION

XML::RSS::Liberal is a subclass of XML::RSS::LibXML, for those of you who
want to parse broken RSS files (as they often are). It uses XML::Liberal as
its core parser, and therefore it can parse whatever broken XML you provided,
so as long as XML::Liberal can tolerate it.

# METHODS

## create\_libxml

Creates a new parser.

# SEE ALSO

[XML::RSS::LibXML](http://search.cpan.org/perldoc?XML::RSS::LibXML)
[XML::Liberal](http://search.cpan.org/perldoc?XML::Liberal)

# AUTHORS

Daisuke Maki <daisuke@endeworks.jp>, Tatsuhiko Miyagawa <miyagawa@bulknews.net>
