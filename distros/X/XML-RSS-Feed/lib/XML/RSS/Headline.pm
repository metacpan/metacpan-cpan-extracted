package XML::RSS::Headline;
use strict;
use warnings;
use Digest::MD5 qw(md5_base64);
use Encode qw(encode_utf8);
use URI;
use Time::HiRes;
use HTML::Entities qw(decode_entities);
use Carp qw(carp);

# length of headline when from description
use constant DESCRIPTION_HEADLINE => 45;

our $VERSION = 2.32;

sub new {
    my ( $class, %args ) = @_;
    my $self           = bless {}, $class;
    my $first_seen     = $args{first_seen};
    my $headline_as_id = $args{headline_as_id} || 0;
    delete $args{first_seen}     if exists $args{first_seen};
    delete $args{headline_as_id} if exists $args{headline_as_id};

    if ( $args{item} ) {
        unless ( ( $args{item}->{title} || $args{item}->{description} )
            && $args{item}->{link} )
        {
            carp 'item must contain either title/link or description/link';
            return;
        }
    }
    else {
        unless ( $args{url} && ( $args{headline} || $args{description} ) ) {
            carp 'Either item, url/headline. or url/description are required';
            return;
        }
    }

    $self->headline_as_id($headline_as_id);

    for my $method ( keys %args ) {
        if ( $self->can($method) ) {
            $self->$method( $args{$method} );
        }
        else {
            carp "Invalid argument: '$method'";
        }
    }

    unless ( $self->headline ) {
        carp 'Failed to set headline';
        return;
    }

    $self->set_first_seen($first_seen);
    return $self;
}

sub id {
    my ($self) = @_;
    return $self->{_rss_headline_id} if $self->headline_as_id;
    return $self->guid || $self->url;
}

sub guid {
    my ( $self, $guid ) = @_;
    $self->{guid} = $guid if $guid;
    return $self->{guid};
}

sub _cache_id {
    my ($self) = @_;
    $self->{_rss_headline_id}
        = md5_base64( encode_utf8( $self->{safe_headline} ) )
        if $self->{safe_headline};
    return;
}

sub multiline_headline {
    my ($self) = @_;
    my @multiline_headline = split /\n/, $self->headline;
    return wantarray ? @multiline_headline : \@multiline_headline;
}

sub item {
    my ( $self, $item ) = @_;
    return unless $item;
    $self->url( $item->{link} );
    $self->headline( $item->{title} );
    $self->description( $item->{description} );
    $self->guid( $item->{guid} );
    return;
}

sub set_first_seen {
    my ( $self, $hires_time ) = @_;
    $self->{hires_timestamp} = $hires_time;
    $self->{hires_timestamp} = Time::HiRes::time() unless $hires_time;
    return 1;
}

sub first_seen {
    my ($self) = @_;
    return int $self->{hires_timestamp};
}

sub first_seen_hires {
    my ($self) = @_;
    return $self->{hires_timestamp};
}

sub headline {
    my ( $self, $headline ) = @_;
    if ($headline) {
        $self->{headline} = decode_entities $headline;
        if ( $self->{headline_as_id} ) {
            $self->{safe_headline} = $headline;
            $self->_cache_id;
        }
    }
    return $self->{headline};
}

sub url {
    my ( $self, $url ) = @_;

    # clean the URL up a bit
    $self->{url} = URI->new($url)->canonical if $url;
    return $self->{url};
}

sub description {
    my ( $self, $description ) = @_;
    if ($description) {
        $self->{description} = decode_entities $description;
        $self->_description_headline unless $self->headline;
    }
    return $self->{description};
}

sub _description_headline {
    my ($self) = @_;
    my $punctuation = qr/[.,?!:;]+/s;

    my $description = $self->{description};
    $description =~ s/<br *\/*>/\n/g;    # turn br into newline
    $description =~ s/<.+?>/ /g;

    my $headline = ( split $punctuation, $description )[0] || '';
    $headline =~ s/^\s+//;
    $headline =~ s/\s+$//;

    my $build_headline = '';
    for my $word ( split /\s+/, $headline ) {
        $build_headline .= ' ' if $build_headline;
        $build_headline .= $word;
        last if length $build_headline > DESCRIPTION_HEADLINE;
    }

    return unless $build_headline;
    $self->headline( $build_headline .= '...' );
    return;
}

sub headline_as_id {
    my ( $self, $bool ) = @_;
    if ( defined $bool ) {
        $self->{headline_as_id} = $bool;
        $self->_cache_id;
    }
    return $self->{headline_as_id};
}

sub timestamp {
    my ( $self, $timestamp ) = @_;
    $self->{timestamp} = $timestamp if $timestamp;
    return $self->{timestamp};
}

1;

__END__
=head1 NAME

XML::RSS::Headline - Persistant XML RSS Encapsulation

=head1 VERSION

2.32

=head1 SYNOPSIS

Headline object to encapsulate the headline/URL combination of a RSS feed.
It provides a unique id either by way of the URL or by doing an MD5 
checksum on the headline (when URL uniqueness fails).

=head1 CONSTRUCTOR

=head2 XML::RSS::Headline->new( headline =E<gt> $headline, url =E<gt> $url )

=head2 XML::RSS::Headline->new( item =E<gt> $item )

A XML::RSS::Headline object can be initialized either with headline/url or 
with a parse XML::RSS item structure.  The argument 'headline_as_id' is 
optional and takes a boolean as its value.

=head1 METHODS

=head2 $headline->id

The id is our unique identifier for a headline/url combination.  Its how we 
can keep track of which headlines we have seen before and which ones are new.
The id is either the guid from rss, the URL or a MD5 checksum generated from 
the headline text (if B<$headline-E<gt>headline_as_id> is true);

=head2 $headline->guid

The unique id used by RSS, set if its available.  The 'id' method return guid
or url if guid is not available.

=head2 $headline->multiline_headline

This method returns the headline as either an array or array 
reference based on context.  It splits headline on newline characters 
into the array.

=head2 $headline->item( $item )

Init the object for a parsed RSS item returned by L<XML::RSS>.

=head2 $headline->set_first_seen

=head2 $headline->set_first_seen( Time::HiRes::time() )

Set the time of when the headline was first seen.  If you pass in a value
it will be used otherwise calls Time::HiRes::time().

=head2 $headline->first_seen

The time (in epoch seconds) of when the headline was first seen.

=head2 $headline->first_seen_hires

The time (in epoch seconds and milliseconds) of when the headline was 
first seen.

=head1 GET/SET ACCESSOR METHODS

=head2 $headline->headline

=head2 $headline->headline( $headline )

The rss headline/title.  HTML::Entities::decode_entities is used when the
headline is set.  (not sure why XML::RSS doesn't do this)

=head2 $headline->url

=head2 $headline->url( $url )

The rss link/url.  URI->canonical is called to attempt to normalize the URL

=head2 $headline-E<gt>description

=head2 $headline-E<gt>description( $description )

The description of the RSS headline.

=head2 $headline->headline_as_id

=head2 $headline->headline_as_id( $bool )

A bool value that determines whether the URL will be the unique identifier or 
the if an MD5 checksum of the RSS title will be used instead.  (when the URL
doesn't provide absolute uniqueness or changes within the RSS feed) 

This is used in extreme cases when URLs aren't always unique to new healines
(Use Perl Journals) and when URLs change within a RSS feed 
(www.debianplanet.org / debianplanet.org / search.cpan.org,search.cpan.org:80)

=head2 $headline->timestamp

=head2 $headline->timestamp( Time::HiRes::time() )

A high resolution timestamp that is set using Time::HiRes::time() when the 
object is created.

=head1 AUTHOR

Jeff Bisbee, C<< <jbisbee at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-xml-rss-feed at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=XML-RSS-Feed>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc XML::RSS::Headline

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/XML-RSS-Feed>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/XML-RSS-Feed>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=XML-RSS-Feed>

=item * Search CPAN

L<http://search.cpan.org/dist/XML-RSS-Feed>

=back

=head1 ACKNOWLEDGEMENTS

Special thanks to Rocco Caputo, Martijn van Beers, Sean Burke, Prakash Kailasa
and Randal Schwartz for their help, guidance, patience, and bug reports. Guys 
thanks for actually taking time to use the code and give good, honest feedback.

Thanks to Aaron Krowne for patch to use guid as the unique id instead of url 
if its available.

=head1 COPYRIGHT & LICENSE

Copyright 2006 Jeff Bisbee, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

L<XML::RSS::Feed>, L<XML::RSS::Headline::PerlJobs>, L<XML::RSS::Headline::Fark>, L<XML::RSS::Headline::UsePerlJournals>, L<POE::Component::RSSAggregator>

