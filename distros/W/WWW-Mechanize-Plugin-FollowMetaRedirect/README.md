# NAME

WWW::Mechanize::Plugin::FollowMetaRedirect - Follows 'meta refresh' link

# SYNOPSIS

    use WWW::Mechanize;
    use WWW::Mechanize::Plugin::FollowMetaRedirect;

    my $mech = WWW::Mechanize->new;
    $mech->get( $url );
    $mech->follow_meta_redirect;

    # we don't want to emulate waiting time
    $mech->follow_meta_redirect( ignore_wait => 1 );

    # compatible for W::M::Pluggable
    use WWW::Mechanize::Pluggable;

    my $mech = WWW::Mechanize::Pluggable->new;
    ...

# DESCRIPTION

WWW::Mechanize doesn't follow so-called 'meta refresh' link.
This module helps you to find the link and follow it easily.

# METHODS

## $mech->follow\_meta\_redirect

If $mech->content() has a 'meta refresh' element like this,

    <head>
      <meta http-equiv="Refresh" content="5; URL=/docs/hello.html" />
    </head>

the code below will try to find and follow the link described as url=.

    $mech->follow_meta_redirect;

In this case, the above code is entirely equivalent to:

    sleep 5;
    $mech->get("/docs/hello.html");

When a refresh link was found and successfully followed, HTTP::Response object will be returned (see WWW::Mechanize::get() ), 
otherwise nothing returned.

To sleep specified seconds is default if 'waiting second' was set. You can omit the meddling function by passing ignore\_wait true.

    $mech->follow_meta_redirect( ignore_wait => 1 );

# BUGS

Despite there was no efficient links on the document after issuing follow\_meta\_redirect(),
$mech->is\_success will still return true because the method did really nothing, and the former page would be loaded correctly (or why you proceed to follow?).

Only the first link will be picked up when HTML document has more than one 'meta refresh' links (but I think it should be so).

# TO DO

A bit more efficient optimization to suppress extra parsing by limiting job range within <head></head> region.

To implement auto follow feature (like $mech->auto\_follow\_meta\_redirect(1) ) using W::M::Pluggable::post\_hook() to W::M::get().

# DEPENDENCY

WWW::Mechanize

# SEE ALSO

WWW::Mechanize, WWW::Mechanize::Pluggable

# REPOSITORY

https://github.com/ryochin/p5-www-mechanize-plugin-followmetaredirect

# AUTHOR

Ryo Okamoto <ryo@aquahill.net>

# COPYRIGHT & LICENSE

Copyright (c) Ryo Okamoto, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
