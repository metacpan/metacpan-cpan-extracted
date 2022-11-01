# SYNOPSIS

In perl scripts:

    C<use WebFetch::Input::RSS;>

From the command line:

    C<perl -w -MWebFetch::Input::RSS -e "&fetch_main" -- --dir directory --source rss-feed-url [...output options...]>

or

    C<perl -w -MWebFetch::Input::RSS -e "&fetch_main" -- --dir directory [...input options...]> --dest_format=rss --dest=file

# DESCRIPTION

_WebFetch::Input::RSS_ is an alias for [WebFetch::RSS](https://metacpan.org/pod/WebFetch%3A%3ARSS) to provide backward compatibility under its previous name.

# SEE ALSO

[WebFetch](https://metacpan.org/pod/WebFetch)
[https://github.com/ikluft/WebFetch](https://github.com/ikluft/WebFetch)

# BUGS AND LIMITATIONS

Please report bugs via GitHub at [https://github.com/ikluft/WebFetch/issues](https://github.com/ikluft/WebFetch/issues)

Patches and enhancements may be submitted via a pull request at [https://github.com/ikluft/WebFetch/pulls](https://github.com/ikluft/WebFetch/pulls)
