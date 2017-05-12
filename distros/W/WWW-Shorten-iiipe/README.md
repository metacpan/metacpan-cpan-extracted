# TITLE

WWW::Shorten::iiipe

# DESCRIPTION

This module provides interface for the URL shortening service http://iii.pe

# SYNOPSIS

```perl
use WWW::Shorten::iiipe;
my $short_url = makeashorterlink( $long_url );
```

# SUBROUTINES

## makeashorterlink( $url, %args )

Takes a required `$url` and optional arguments and returns a shortened url.
The single optional argument available is `ttl`, specifying the shortened
link' time-to-live value in seconds. The default is 86400.

# SEE ALSO

[WWW::Shorten](https://metacpan.org/pod/WWW::Shorten)

[http:/iii.pe](http:/iii.pe)

# AUTHOR

Stefan G6Y - `minimal at cpan dot org`

# LICENCE

Perl
