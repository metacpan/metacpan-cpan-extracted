# NAME

XML::Feed::Deduper - remove duplicated entries from feed

# SYNOPSIS

    use XML::Feed;
    use XML::Feed::Deduper;
    my $feed = XML::Feed->parse($content);
    my $deduper = XML::Feed::Deduper->new(
        path => '/tmp/foo.db',
    );
    for my $entry ($deduper->dedup($feed->entries)) {
        # only new entries come here!
    }

# DESCRIPTION

XML::Feed::Deduper is deduper for XML::Feed.

You can write the aggregator more easily :)

The concept is stolen from [Plagger::Rule::Deduper](http://search.cpan.org/perldoc?Plagger::Rule::Deduper).

Enjoy!

# CAUTION

This module is still in its beta quality.

your base are belongs to us!

# AUTHOR

Tokuhiro Matsuno <tokuhirom@gmail.com>

# SEE ALSO

[Plagger::Rule::Deduper](http://search.cpan.org/perldoc?Plagger::Rule::Deduper)

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
