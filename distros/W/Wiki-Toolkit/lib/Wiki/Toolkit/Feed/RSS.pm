package Wiki::Toolkit::Feed::RSS;

use strict;

use vars qw( @ISA $VERSION );
$VERSION = '0.11';

use POSIX 'strftime';
use Time::Piece;
use URI::Escape;
use Carp qw( croak );

use Wiki::Toolkit::Feed::Listing;
@ISA = qw( Wiki::Toolkit::Feed::Listing );

=head1 NAME

  Wiki::Toolkit::Feed::RSS - Output RecentChanges RSS for Wiki::Toolkit.

=head1 DESCRIPTION

This is an alternative access to the recent changes of a Wiki::Toolkit
wiki. It outputs RSS as described by the ModWiki proposal at
L<http://www.usemod.com/cgi-bin/mb.pl?ModWiki>

=head1 SYNOPSIS

  use Wiki::Toolkit;
  use Wiki::Toolkit::Feed::RSS;

  my $wiki = CGI::Wiki->new( ... );  # See perldoc Wiki::Toolkit

  # Set up the RSS feeder with the mandatory arguments - see
  # C<new()> below for more, optional, arguments.
  my $rss = Wiki::Toolkit::Feed::RSS->new(
    wiki                => $wiki,
    site_name           => 'My Wiki',
    site_url            => 'http://example.com/',
    make_node_url       => sub
                           {
                             my ($node_name, $version) = @_;
                             return 'http://example.com/?id=' . uri_escape($node_name) . ';version=' . uri_escape($version);
                           },
    html_equiv_link     => 'http://example.com/?RecentChanges',
    encoding            => 'UTF-8'
  );

  print "Content-type: application/xml\n\n";
  print $rss->recent_changes;

=head1 METHODS

=head2 C<new()>

  my $rss = Wiki::Toolkit::Feed::RSS->new(
    # Mandatory arguments:
    wiki                 => $wiki,
    site_name            => 'My Wiki',
    site_url             => 'http://example.com/',
    make_node_url        => sub
                            {
                              my ($node_name, $version) = @_;
                              return 'http://example.com/?id=' . uri_escape($node_name) . ';version=' . uri_escape($version);
                            },
    html_equiv_link  => 'http://example.com/?RecentChanges',

    # Optional arguments:
    site_description     => 'My wiki about my stuff',
    interwiki_identifier => 'MyWiki',
    make_diff_url        => sub
                            {
                              my $node_name = shift;
                              return 'http://example.com/?diff=' . uri_escape($node_name)
                            },
    make_history_url     => sub
                            {
                              my $node_name = shift;
                              return 'http://example.com/?hist=' . uri_escape($node_name)
                            },
    software_name        => $your_software_name,     # e.g. "CGI::Wiki"
    software_version     => $your_software_version,  # e.g. "0.73"
    software_homepage    => $your_software_homepage, # e.g. "http://search.cpan.org/dist/Wiki-Toolkit/"
  );

C<wiki> must be a L<Wiki::Toolkit> object. C<make_node_url>, and
C<make_diff_url> and C<make_history_url>, if supplied, must be coderefs.

The mandatory arguments are:

=over 4

=item * wiki

=item * site_name

=item * site_url

=item * make_node_url

=item * html_equiv_link or recent_changes_link

=back

The three optional arguments

=over 4

=item * software_name

=item * software_version

=item * software_homepage

=back

are used to generate DOAP (Description Of A Project - see L<http://usefulinc.com/doap>) metadata
for the feed to show what generated it.

The optional argument

=over 4

=item * encoding

=back

will be used to specify the character encoding in the feed. If not set,
will default to the wiki store's encoding.

=head2 C<recent_changes()>

  $wiki->write_node(
                     'About This Wiki',
                     'blah blah blah',
                         $checksum,
                         {
                           comment  => 'Stub page, please update!',
                           username => 'Fred',
                         }
  );

  print "Content-type: application/xml\n\n";
  print $rss->recent_changes;

  # Or get something other than the default of the latest 15 changes.
  print $rss->recent_changes( items => 50 );
  print $rss->recent_changes( days => 7 );

  # Or ignore minor edits.
  print $rss->recent_changes( ignore_minor_edits => 1 );

  # Personalise your feed further - consider only changes
  # made by Fred to pages about bookshops.
  print $rss->recent_changes(
             filter_on_metadata => {
                         username => 'Fred',
                         category => 'Bookshops',
                       },
              );

If using C<filter_on_metadata>, note that only changes satisfying
I<all> criteria will be returned.

B<Note:> Many of the fields emitted by the RSS generator are taken
from the node metadata. The form of this metadata is I<not> mandated
by L<Wiki::Toolkit>. Your wiki application should make sure to store some or
all of the following metadata when calling C<write_node>:

=over 4

=item B<comment> - a brief comment summarising the edit that has just been made; will be used in the RDF description for this item.  Defaults to the empty string.

=item B<username> - an identifier for the person who made the edit; will be used as the Dublin Core contributor for this item, and also in the RDF description.  Defaults to the empty string.

=item B<host> - the hostname or IP address of the computer used to make the edit; if no username is supplied then this will be used as the Dublin Core contributor for this item.  Defaults to the empty string.

=item B<major_change> - true if the edit was a major edit and false if it was a minor edit; used for the importance of the item.  Defaults to true (ie if C<major_change> was not defined or was explicitly stored as C<undef>).

=back

=head2 C<feed_timestamp()>

  print $rss->feed_timestamp();

Returns the timestamp of the feed in POSIX::strftime style ("Tue, 29 Feb 2000 
12:34:56 GMT"), which is equivalent to the timestamp of the most recent item 
in the feed. Takes the same arguments as recent_changes(). You will most likely
need this to print a Last-Modified HTTP header so user-agents can determine
whether they need to reload the feed or not.

=cut

sub new {
    my $class = shift;
    my $self  = {};
    bless $self, $class;

    my %args = @_;
    my $wiki = $args{wiki};

    unless ($wiki && UNIVERSAL::isa($wiki, 'Wiki::Toolkit')) {
        croak 'No Wiki::Toolkit object supplied';
    }
  
    $self->{wiki} = $wiki;
  
    # Mandatory arguments.
    foreach my $arg (qw/site_name site_url make_node_url/) {
        croak "No $arg supplied" unless $args{$arg};
        $self->{$arg} = $args{$arg};
    }

    # Must-supply-one-of arguments
    my %mustoneof = ( 'html_equiv_link' => ['html_equiv_link','recent_changes_link'] );
    $self->handle_supply_one_of(\%mustoneof,\%args);
  
    # Optional arguments.
    foreach my $arg (qw/site_description interwiki_identifier make_diff_url make_history_url encoding software_name software_version software_homepage/) {
        $self->{$arg} = $args{$arg} || '';
    }

    # Supply some defaults, if a blank string isn't what we want
    unless($self->{encoding}) {
        $self->{encoding} = $self->{wiki}->store->{_charset};
    }

    $self->{timestamp_fmt} = $Wiki::Toolkit::Store::Database::timestamp_fmt;
    $self->{utc_offset} = strftime "%z", localtime;
    $self->{utc_offset} =~ s/(..)(..)$/$1:$2/;

    $self;
}

# Internal method, to build all the stuff that will go at the start of a feed.
# Generally will output namespaces, headers and so on.

sub build_feed_start {
    my ($self,$feed_timestamp) = @_;

    #"http://purl.org/rss/1.0/modules/wiki/"
    return qq{<?xml version="1.0" encoding="}. $self->{encoding} .qq{"?>

<rdf:RDF
 xmlns         = "http://purl.org/rss/1.0/"
 xmlns:dc      = "http://purl.org/dc/elements/1.1/"
 xmlns:doap    = "http://usefulinc.com/ns/doap#"
 xmlns:foaf    = "http://xmlns.com/foaf/0.1/"
 xmlns:rdf     = "http://www.w3.org/1999/02/22-rdf-syntax-ns#"
 xmlns:rdfs    = "http://www.w3.org/2000/01/rdf-schema#"
 xmlns:modwiki = "http://www.usemod.com/cgi-bin/mb.pl?ModWiki"
 xmlns:geo     = "http://www.w3.org/2003/01/geo/wgs84_pos#"
 xmlns:space   = "http://frot.org/space/0.1/"
>
};
}

# Internal method, to build all the stuff (except items) to go inside the channel

sub build_feed_mid {
    my ($self,$feed_timestamp) = @_;

    my $rss .= qq{<dc:publisher>} . $self->{site_url} . qq{</dc:publisher>\n};

    if ($self->{software_name}) {
        $rss .= qq{<foaf:maker>
        <doap:Project>
        <doap:name>} . $self->{software_name} . qq{</doap:name>\n};
    }

    if ($self->{software_name} && $self->{software_homepage}) {
        $rss .= qq{    <doap:homepage rdf:resource="} . $self->{software_homepage} . qq{" />\n};
    }

    if ($self->{software_name} && $self->{software_version}) {
        $rss .= qq{    <doap:release>
      <doap:Version>
      <doap:revision>} . $self->{software_version} . qq{</doap:revision>
      </doap:Version>
    </doap:release>\n};
    }

    if ($self->{software_name}) {
        $rss .= qq{  </doap:Project>
</foaf:maker>\n};
    }

    $feed_timestamp ||= '';

    $rss .= qq{<title>}   . $self->{site_name}             . qq{</title>
<link>}               . $self->{html_equiv_link}       . qq{</link>
<description>}        . $self->{site_description}      . qq{</description>
<dc:date>}            . $feed_timestamp                . qq{</dc:date>
<modwiki:interwiki>}     . $self->{interwiki_identifier} . qq{</modwiki:interwiki>};

   return $rss;
}

# Internal method, to build all the stuff that will go at the end of a feed

sub build_feed_end {
    my ($self,$feed_timestamp) = @_;

    return "</rdf:RDF>\n";
}


=head2 C<generate_node_list_feed>

Generate and return an RSS feed for a list of nodes

=cut

sub generate_node_list_feed {
    my ($self,$feed_timestamp,@nodes) = @_;

    # Start our feed
    my $rss = $self->build_feed_start($feed_timestamp);
    $rss .= qq{

<channel rdf:about="">

};
    $rss .= $self->build_feed_mid($feed_timestamp);

    # Generate the items list, and the individiual item entries
    my (@urls, @items);
    foreach my $node (@nodes) {
        my $node_name = $node->{name};

        my $timestamp = $node->{last_modified};
    
        # Make a Time::Piece object.
        my $time = Time::Piece->strptime($timestamp, $self->{timestamp_fmt});

        my $utc_offset = $self->{utc_offset};
    
        $timestamp = $time->strftime( "%Y-%m-%dT%H:%M:%S$utc_offset" );

        my $author      = $node->{metadata}{username}[0] || $node->{metadata}{host}[0] || '';
        my $description = $node->{metadata}{comment}[0]  || '';

        $description .= " [$author]" if $author;

        my $version = $node->{version};
        my $status  = (1 == $version) ? 'new' : 'updated';

        my $major_change = $node->{metadata}{major_change}[0];
        $major_change = 1 unless defined $major_change;
        my $importance = $major_change ? 'major' : 'minor';

        my $url = $self->{make_node_url}->($node_name, $version);

        push @urls, qq{    <rdf:li rdf:resource="$url" />\n};

        my $diff_url = '';
    
        if ($self->{make_diff_url}) {
            $diff_url = $self->{make_diff_url}->($node_name);
        }

        my $history_url = '';
    
        if ($self->{make_history_url}) {
            $history_url = $self->{make_history_url}->($node_name);
        }

        my $node_url = $self->{make_node_url}->($node_name);

        my $rdf_url =  $node_url;
        $rdf_url =~ s/\?/\?id=/;
        $rdf_url .= ';format=rdf';

        # make XML-clean
        my $title =  $node_name;
        $title =~ s/&/&amp;/g;
        $title =~ s/</&lt;/g;
        $title =~ s/>/&gt;/g;

        # Pop the categories into dublin core subject elements
        #  (http://dublincore.org/usage/terms/history/#subject-004)
        # TODO: Decide if we should include the "all categories listing" url
        #        as the scheme (URI) attribute?
        my $category_rss = "";
        if($node->{metadata}->{category}) {
            foreach my $cat (@{ $node->{metadata}->{category} }) {
                $category_rss .= "  <dc:subject>$cat</dc:subject>\n";
            }
        }

        # Include geospacial data, if we have it
        my $geo_rss = $self->format_geo($node->{metadata});

        push @items, qq{
<item rdf:about="$url">
  <title>$title</title>
  <link>$url</link>
  <description>$description</description>
  <dc:date>$timestamp</dc:date>
  <dc:contributor>$author</dc:contributor>
  <modwiki:status>$status</modwiki:status>
  <modwiki:importance>$importance</modwiki:importance>
  <modwiki:diff>$diff_url</modwiki:diff>
  <modwiki:version>$version</modwiki:version>
  <modwiki:history>$history_url</modwiki:history>
  <rdfs:seeAlso rdf:resource="$rdf_url" />
$category_rss
$geo_rss
</item>
};
    }
  
    # Output the items list
    $rss .= qq{

<items>
  <rdf:Seq>
} . join('', @urls) . qq{  </rdf:Seq>
</items>

</channel>
};

    # Output the individual item entries
    $rss .= join('', @items) . "\n";

    # Finish up
    $rss .= $self->build_feed_end($feed_timestamp);
 
    return $rss;   
}


=head2 C<generate_node_name_distance_feed>

Generate a very cut down rss feed, based just on the nodes, their locations
(if given), and their distance from a reference location (if given). 

Typically used on search feeds.

=cut

sub generate_node_name_distance_feed {
    my ($self,$feed_timestamp,@nodes) = @_;

    # Start our feed
    my $rss = $self->build_feed_start($feed_timestamp);
    $rss .= qq{

<channel rdf:about="">

};
    $rss .= $self->build_feed_mid($feed_timestamp);

    # Generate the items list, and the individiual item entries
    my (@urls, @items);
    foreach my $node (@nodes) {
        my $node_name = $node->{name};

        my $url = $self->{make_node_url}->($node_name);

        push @urls, qq{    <rdf:li rdf:resource="$url" />\n};

        my $rdf_url =  $url;
        $rdf_url =~ s/\?/\?id=/;
        $rdf_url .= ';format=rdf';

        # make XML-clean
        my $title =  $node_name;
        $title =~ s/&/&amp;/g;
        $title =~ s/</&lt;/g;
        $title =~ s/>/&gt;/g;

        # What location stuff do we have?
        my $geo_rss = $self->format_geo($node);

        push @items, qq{
<item rdf:about="$url">
  <title>$title</title>
  <link>$url</link>
  <rdfs:seeAlso rdf:resource="$rdf_url" />
$geo_rss
</item>
};
    }
  
    # Output the items list
    $rss .= qq{

<items>
  <rdf:Seq>
} . join('', @urls) . qq{  </rdf:Seq>
</items>

</channel>
};

    # Output the individual item entries
    $rss .= join('', @items) . "\n";

    # Finish up
    $rss .= $self->build_feed_end($feed_timestamp);
 
    return $rss;   
}

=head2 C<feed_timestamp>

Generate the timestamp for the RSS, based on the newest node (if available).
Will return a timestamp for now if no node dates are available

=cut

sub feed_timestamp {
    my ($self, $newest_node) = @_;

    my $time;
    if ($newest_node->{last_modified}) {
        $time = Time::Piece->strptime( $newest_node->{last_modified}, $self->{timestamp_fmt} );
    } else {
        $time = localtime;
    }

    my $utc_offset = $self->{utc_offset};

    return $time->strftime( "%Y-%m-%dT%H:%M:%S$utc_offset" );
}

# Compatibility method - use feed_timestamp with a node instead
sub rss_timestamp {
    my ($self, %args) = @_;

    warn("Old style method used - please convert to calling feed_timestamp with a node!");
    my $feed_timestamp = $self->feed_timestamp(
                              $self->fetch_newest_for_recently_changed(%args)
    );
    return $feed_timestamp;
}

=head2 C<parse_feed_timestamp>

Take a feed_timestamp and return a Time::Piece object. 

=cut

sub parse_feed_timestamp {
    my ($self, $feed_timestamp) = @_;
   
    $feed_timestamp = substr($feed_timestamp, 0, -length( $self->{utc_offset}));
    return Time::Piece->strptime( $feed_timestamp, '%Y-%m-%dT%H:%M:%S' );
}

1;

__END__


=head1 SEE ALSO

=over 4

=item * L<Wiki::Toolkit>

=item * L<http://web.resource.org/rss/1.0/spec>

=item * L<http://www.usemod.com/cgi-bin/mb.pl?ModWiki>

=back

=head1 MAINTAINER

The Wiki::Toolkit project. Originally by Kake Pugh <kake@earth.li>.

=head1 COPYRIGHT AND LICENSE

Copyright 2003-4 Kake Pugh.
Copyright 2005 Earle Martin.
Copyright 2006-2009 the Wiki::Toolkit team

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 THANKS

The members of the Semantic Web Interest Group channel on irc.freenode.net,
#swig, were very useful in the development of this module.

=cut
