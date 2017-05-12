package XML::FeedPP::MediaRSS;
BEGIN {
  $XML::FeedPP::MediaRSS::VERSION = '0.02';
}

use strict;
use warnings;

# ABSTRACT: MediaRSS support for XML::FeedPP


sub new {
    my ($class, $feed) = @_;
    bless { feed => $feed }, $class;
}

sub _find_optional {
    my ($key, $item, @parents) = @_;
    $key = "media:$key";
    unshift(@parents, $item);
    for my $hash (@parents) {
        my $val = $hash->{key};
        return $val if $val;
    }
    return undef;
}

sub _force_array {
    my ($hash, $key) = @_;
    my $raw = $hash->{$key} || return [];
    return (ref $raw eq 'ARRAY' ? $raw : [ $raw ]);
}

sub _force_hash {
    my $value = shift;
    return $value if ref $value eq 'HASH';
    return { '#text' => $value };
}

sub _process_group {
    my ($self, $item, $group) = @_;
    my $contents = _force_array($group, 'media:content');
    map {
        my $c = $_;

        # all found entries, from least-specific to most-specific
        my $find = sub {
            my $key = "media:$_[0]";
            my @found;
            for my $place ($self->{channel}, $item, $group, $c) {
                if (exists $place->{$key}) {
                    my @these = 
                        map { _force_hash($_) } 
                        @{ _force_array($place, $key) };

                    push @found, @these;
                }
            }
            return wantarray ? @found : $found[-1];
        };

        my %hash;
        my @atts = grep { /^-/ } keys %$c;
        @hash{map { s/^-//; $_ } @atts} = @{$c}{@atts};

        if ($hash{isDefault}) {
            $hash{isDefault} = $hash{isDefault} eq 'true';
        }


        if (my $adult = $find->('adult')) {
            $hash{adult} = $adult->{'#text'} eq 'true';
        }

        my $make_hash = sub {
            my ($el, $required, $optional) = @_;
            my %h;
            @h{@$required} = @{$el}{map { "-$_" } @$required};
            for my $k (@$optional) {
                my $v = $el->{"-$k"};
                $h{$k} = $v if $v;
            }
            return \%h;
        };

        for my $rating ($find->('rating')) {
            my $schema = $rating->{'-schema'} || 'simple';
            $hash{rating}{$schema} = $rating->{'#text'};
        }

        for my $title ($find->('title')) {
            my $type = $title->{'-type'} || 'plain';
            $hash{title}{$type} = $title->{'#text'};
        }

        my %keyword_set;
        for my $keywords ($find->('keywords')) {
            my @words = split /,\s*/, $keywords->{'#text'};
            @keyword_set{@words} = ();
        }

        my @keywords = keys %keyword_set;

        $hash{keywords} = \@keywords if @keywords;

        for my $thumb ($find->('thumbnail')) {
            push @{$hash{thumbnails}}, $make_hash->(
                $thumb, ['url'], [qw(width height time)]
            );
        }


        for my $category ($find->('category')) {
            my $scheme = $category->{'-scheme'} || 'none';
            $hash{category}{$scheme} = $category->{'#text'};
        }

        if (my $checksum = $find->('hash')) {
            $hash{hash} = {
                checksum  => $checksum->{'#text'},
                algorithm => $checksum->{'-algo'} || 'md5',
            };
        }

        if (my $player = $find->('player')) {
            $hash{player} = $make_hash->(
                $player, ['url'], [qw(width height)]
            );
        }

        CREDIT: for my $credit ($find->('credit')) {
            my $scheme = $credit->{'-scheme'} || 'urn:ebu';
            my $role   = $credit->{'-role'};
            my $entity = $credit->{'#text'};
            my $list   = $hash{credit}{$scheme}{$role} ||= [];
            for my $e (@$list) {
                next CREDIT if $entity eq $e;
            }
            push(@$list, $entity);
        }

        if (my $copyright = $find->('copyright')) {
            $hash{copyright}{text} = $copyright->{'#text'};
            my $url = $copyright->{'-url'};
            $hash{copyright}{url} = $url if $url;
        }

        for my $text ($find->('text')) {
            my $t = $hash{text} = $make_hash->(
                $text, [], [qw(lang start end type)]
            );
            $t->{type} ||= 'plain';
            $t->{text} = $text->{'#text'};
        }


        if (my $restriction = $find->('restriction')) {
            my %r = (allow => $restriction->{'-relationship'} eq 'allow');
            my @list;
            if (my $unparsed = $restriction->{'#text'}) {
                @list = split /\s+/, $unparsed;
            }

            if (grep { $_ eq 'all' } @list) {
                $r{list} = 'all';
            }
            elsif (@list < 1 || grep { $_ eq 'none' } @list) {
                $r{list} = 'none';
            }
            else {
                $r{list} = \@list;
            }
            $r{type} = $restriction->{'-type'};
            $hash{restriction} = \%r;
        }


        if (my $community = $find->('community')) {
            my %c;
            if (my $starRating = $community->{'media:starRating'}) {
                $c{starRating} = $make_hash->(
                    $starRating, [], [qw(average min max count)]
                );
            }
            if (my $stats = $community->{'media:statistics'}) {
                $c{statistics} = $make_hash->(
                    $stats, [], [qw(views favorites)]
                );
            }
            if (my $tags = $community->{'media:tags'}) {
                for (split /,\s*/, $tags) {
                    s/^\s+//;
                    s/\s+$//;
                    s/:\s+/:/g;
                    my ($key, $val) = split /:/;
                    $c{tags}{$key} = $val;
                }
            }
            $hash{community} = \%c;
        }

        my $simple_list = sub {
            my ($singular, $plural) = @_;
            for my $thing ($find->($plural)) {
                my $things = _force_array($thing, "media:$singular");
                push @{$hash{$plural}}, @$things;
            }
        };

        $simple_list->(qw(comment comments));


        for my $embed ($find->('embed')) {
            for my $param (@{ _force_array($embed, 'media:param') }) {
                $hash{embed}{$param->{'-name'}} = $param->{'#text'};
            }
        }

        $simple_list->(qw(response responses));

        $simple_list->(qw(backLink backLinks));


        if (my $status = $find->('status')) {
            $hash{status} = $make_hash->($status, ['state'], ['reason']);
        }


        for my $price ($find->('price')) {
            my $p = $make_hash->($price, [], [qw(price info currency type)]);
            push (@{ $hash{price} }, $p) if keys %$p;
        }

        if (my $license = $find->('license')) {
            my $l = $hash{license} = $make_hash->(
                $license, [], [qw(type href)]
            );
            $l->{name} = $license->{'#text'};
        }


        for my $st ($find->('subTitle')) {
            my $s = $make_hash->($st, [qw(lang href type)], []);
            my $l = delete $s->{lang};
            $hash{subTitle}{$l} = $s;
        }

        if (my $peerLink = $find->('peerLink')) {
            $hash{peerLink} = $make_hash->($peerLink, [qw(type href)], []);
        }

        if (my $r = $find->('rights')) {
            $hash{rights} = $r->{'-status'};
        }

        if (my $sl = $find->('scenes')) {
            for my $scene (@{ _force_array($sl, 'media:scene') }) {
                push @{$hash{scenes}}, {
                    title       => $scene->{sceneTitle},
                    description => $scene->{sceneDescription},
                    start_time  => $scene->{sceneStartTime},
                    end_time    => $scene->{sceneEndTime},
                };
            }
        }

        bless \%hash, 'XML::FeedPP::MediaRSS::Content';
    } @$contents;
}


sub for_item {
    my ($self, $item) = @_;
    my $contents = _force_array($item, 'media:content');
    my $groups   = _force_array($item, 'media:group');

    return (
        (map { $self->_process_group($item, $_) } @$groups),
        $self->_process_group($item, { 'media:content' => $contents }),
    );
}

1;



=pod

=head1 NAME

XML::FeedPP::MediaRSS - MediaRSS support for XML::FeedPP

=head1 VERSION

version 0.02

=head1 SYNOPSIS

    use XML::FeedPP;

    my $feed  = XML::FeedPP->new('http://a.media.rss/source');
    my $media = XML::FeedPP::MediaRSS->new($feed);
    for my $i ( $feed->get_item ) {
        for my $content ( $media->for_item($i) ) {
            die "18 or over" if $content->{adult};
        }
    }

=head1 DESCRIPTION

XML::FeedPP does not support Yahoo's MediaRSS extension, and it shouldn't.
It's only supported in some formats, and XML::FeedPP is a
lowest-common-denominator kind of module. That said, sometimes you need to
consume feeds with MediaRSS in them.

=head1 METHODS

=head2 new ( feed )

You have to pass in an L<XML::FeedPP> object. C<XML::FeedPP::MediaRSS> isn't a
subclass of L<XML::FeedPP> - it has one, and inspects its dirty innards (which
is somewhat safe since they're produced by L<XML::TreePP>) to find media
content.

=head2 for_item ( item )

Pass in a feed item (the things returned by C<< $feed->get_item >>) and get
back a list of L</XML::FeedPP::MediaRSS::Content> objects.

=head1 KEYS

=head2 adult

1 or ''

=head2 rating

A hash of all the ratings found, schema => rating.

=head2 title

A hash of all titles found, type => value.

=head2 keywords

An arrayref of all the keywords found. The comma-delimiting is undone and
duplicates are removed.

=head2 thumbnails

All thumnails found, from most specific (deepest) to least specific. This
means that if the channel has a thumbnail and the item has a thumbnail, you'll
get the item first, then the channel. If there are multiple thumbnails at the
same level, you'll get them in document order. Time coding is not considered.
They look like this:

    {   url => '...', width => 400, height => 300, time => 'timecode'   }

=head2 category

Hash of scheme => plain contents of tag

=head2 hash

Deepest only.

    {
        algorithm => 'md5',
        checksum  => 'dfdec888b72151965a34b4b59031290a',
    }

=head2 player

Deepest only.

    {
        url => '...',
        height => 300,
        width => 400
    }

=head2 credit

Hash of scheme to role-hash, like this:

    {
        'urn:ebu' => {
            actor => [
                'Julia Roberts',
                'Tom Hanks',
            ],
            director => [
                'Stevan Spielberg',
            ]
        }
    }

=head2 copyright

Deepest only.

{ url => '...', text => '2005 Foobar Media' }

=head2 text

A list of text objects in document order, like this:

    [
        {
            type  => 'plain',
            lang  => 'en',
            start => 'timecode',
            end   => 'timecode',
            text  => 'The actual value',
        },
    ]

=head2 restriction

    {
        allow => (1|0),
        type  => (country|uri|sharing)
        list  => [ ... ] | 'all' | 'none'
    }

If allow is false, that means deny.

=head2 community

Deepest only.

    {
        starRating => {
            average => 3.5,
            count   => 20,
            min     => 1,
            max     => 10,
        },
        statistics => {
            views     => 5,
            favorites => 5,
        },
        tags       => {
            news => 5,
            abc  => 3,
            reuters => undef,
        },
    }

=head2 comments

Simple list of strings.

=head2 embed

Hash of key-value pairs. Deepest only.

=head2 responses

Simple list of strings

=head2 backlinks

Simple list of strings

=head2 status

Deepest only.

    { state => 'status', reason => 'reason' }

=head2 price

List of pricing structures, which are hashes with the keys C<currency>
(optional), C<info> (optional), C<type> (optional), and C<price> (optional).
If none of these is present for a given price tag, we're going to pretend it
doesn't exist.

=head2 license

Hash of type, href, and name. Deepest only.

=head2 subTitle

Only one per language as per the spec.

    {
        'en_us' => {
            href => 'http://www.example.org/subtitle.smil',
            type => 'application/smil',
        }
    }

=head2 peerLink

Deepest only, hash of type and href.

=head2 location

B<NOT SUPPORTED>, mostly cause I don't need it and I don't feel like reading
the geoRSS spec right now. Patches welcome!

=head2 rights

value of the status attribute for the deepest rights element.

=head2 scenes

Deepest only, list of hashes with keys title, description, start_time, and
end_time.

=head1 ALPHA

This software hasn't yet been tested beyond the examples provided in the mRSS
spec. Failing tests (even better, with patches that fix the failures) are
very welcome! Fork and send a pull request on L</GITHUB>.

=head1 XML::FeedPP::MediaRSS::Content

These are blessed hashes, but you're allowed to look inside them. In fact,
you're really supposed to. It's okay, don't be nervous.

The mapping from the MediaRSS spec (L<http://video.search.yahoo.com/mrss>) to
this hash is really straightforward.  See the L</KEYS> section for more
detail.  The shallowness-rules talked about in the spec are applied, e.g.
specifiers at higher levels are applied to lower level objects unless they
have a more specific rule.

=head1 LIMITATIONS

=head2 Groups

You don't have to (get to?) deal with media groups. All the content for an
item gets flattened into one list. Future versions of this module may add
support for media groups under a different method name (C<groups_for_item>) if
anyone ever sends me a patch or I can ever find an actual use for it.

=head2 Order

The MediaRSS spec says some things about order being dependent on document
order. We go by the order we get things from L<XML::FeedPP>'s hashes, which
will only be the same as document order if you C<< use_ixhash => 1 >> in the
feed. And even then, content in media:groups will come before content outside
them.

=head2 Read-Write

This module only supports reading MediaRSS information from a feed, not adding
it. I might add this someday, but of course patches are welcome in the
meantime.

=head1 GITHUB

This project is hosted on github at
L<http://github.com/frodwith/XML-FeedPP-MediaRSS>.

=head1 AUTHOR

Paul Driver <frodwith@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Paul Driver <frodwith@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

