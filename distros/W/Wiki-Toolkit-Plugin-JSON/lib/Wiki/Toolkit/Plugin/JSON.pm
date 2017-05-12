package Wiki::Toolkit::Plugin::JSON;

use strict;

use vars qw( $VERSION );
$VERSION = '0.05';

use JSON;
use POSIX 'strftime';
use Time::Piece;
use URI::Escape;
use Carp qw( croak );

sub new {
    my $class = shift;
    my $self  = {@_};
    bless $self, $class;

    unless ( $self->{wiki} && UNIVERSAL::isa( $self->{wiki}, 'Wiki::Toolkit' ) )
    {
        croak 'No Wiki::Toolkit object supplied';
    }

    # Mandatory arguments.
    foreach my $arg (qw/site_name site_url make_node_url recent_changes_link/) {
        croak "No $arg supplied" unless $self->{$arg};
    }

    $self->{timestamp_fmt} = $Wiki::Toolkit::Store::Database::timestamp_fmt;
    $self->{utc_offset} = strftime "%z", localtime;
    $self->{utc_offset} =~ s/(..)(..)$/$1:$2/;

    return $self;
}

sub recent_changes {
    my ( $self, %args ) = @_;
    my $wiki = $self->{wiki};

# If we're not passed any parameters to limit the items returned, default to 15.

    my %criteria = ( ignore_case => 1, );

    if ( $args{days} ) {
        $criteria{days} = $args{days};
    }
    else {
        $criteria{last_n_changes} = $args{items} || 15;
    }

    if ( $args{ignore_minor_edits} ) {
        $criteria{metadata_wasnt} = { major_change => 0 };
    }

    if ( $args{filter_on_metadata} ) {
        $criteria{metadata_was} = $args{filter_on_metadata};
    }

    my @changes = $wiki->list_recent_changes(%criteria);

    foreach my $change (@changes) {

        $change->{timestamp} = $change->{last_modified};

        # Make a Time::Piece object.
        my $time =
          Time::Piece->strptime( $change->{timestamp}, $self->{timestamp_fmt} );

        my $utc_offset = $self->{utc_offset};

        $change->{timestamp} = $time->strftime("%Y-%m-%dT%H:%M:%S$utc_offset");

        $change->{author} = $change->{metadata}{username}[0]
          || $change->{metadata}{host}[0]
          || '';
        $change->{description} = $change->{metadata}{comment}[0] || '';

        $change->{status} = ( 1 == $change->{version} ) ? 'new' : 'updated';

        $change->{major_change} = $change->{metadata}{major_change}[0];
        $change->{major_change} = 1 unless defined $change->{major_change};
        $change->{importance}   = $change->{major_change} ? 'major' : 'minor';

        $change->{url} =
          $self->{make_node_url}->( $change->{name}, $change->{version} );

        if ( $self->{make_diff_url} ) {
            $change->{diff_url} = $self->{make_diff_url}->( $change->{name} );
        }

        if ( $self->{make_history_url} ) {
            $change->{history_url} =
              $self->{make_history_url}->( $change->{name} );
        }

        $change->{node_url} = $self->{make_node_url}->( $change->{name} );

        my $rdf_url = $change->{node_url};
        $rdf_url =~ s/\?/\?id=/;
        $rdf_url .= ';format=rdf';
        $change->{rdf_url} = $rdf_url;

        # make XML-clean
        my $title = $change->{name};
        $title =~ s/&/&amp;/g;
        $title =~ s/</&lt;/g;
        $title =~ s/>/&gt;/g;
        $change->{title} = $title;
    }
    return $self->make_json( \@changes );
}

sub make_json {
    my ( $self, $data ) = @_;
    return JSON::to_json( $data );
}

1;

__END__

=head1 NAME

  Wiki::Toolkit::Plugin::JSON - A Wiki::Toolkit plugin to output RecentChanges JSON.

=head1 DESCRIPTION

This is an alternative access to the recent changes of a Wiki::Toolkit
wiki. It outputs JSON.

=head1 SYNOPSIS

  use Wiki::Toolkit;
  use Wiki::Toolkit::Plugin::JSON;

  my $wiki = Wiki::Toolkit->new( ... );  # See perldoc Wiki::Toolkit

  # Set up the JSON feeder with the mandatory arguments - see
  # C<new()> below for more, optional, arguments.
  my $json = Wiki::Toolkit::Plugin::JSON->new(
    wiki                => $wiki,
    site_name           => 'My Wiki',
    site_url            => 'http://example.com/',
    make_node_url       => sub
                           {
                             my ($node_name, $version) = @_;
                             return 'http://example.com/?id=' . uri_escape($node_name) . ';version=' . uri_escape($version);
                           },
    recent_changes_link => 'http://example.com/?RecentChanges',
  );

  print "Content-type: application/xml\n\n";
  print $json->recent_changes;

=head1 METHODS

=head2 C<new()>

  my $json = Wiki::Toolkit::Plugin::JSON->new(
    # Mandatory arguments:
    wiki                 => $wiki,
    site_name            => 'My Wiki',
    site_url             => 'http://example.com/',
    make_node_url        => sub
                            {
                              my ($node_name, $version) = @_;
                              return 'http://example.com/?id=' . uri_escape($node_name) . ';version=' . uri_escape($version);
                            },
    recent_changes_link  => 'http://example.com/?RecentChanges',

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
  );

C<wiki> must be a L<Wiki::Toolkit> object. C<make_node_url>, and
C<make_diff_url> and C<make_history_url>, if supplied, must be coderefs.

The mandatory arguments are:

=over 4

=item * wiki

=item * site_name

=item * site_url

=item * make_node_url

=item * recent_changes_link

=back

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
  print $json->recent_changes;

  # Or get something other than the default of the latest 15 changes.
  print $json->recent_changes( items => 50 );
  print $json->recent_changes( days => 7 );

  # Or ignore minor edits.
  print $json->recent_changes( ignore_minor_edits => 1 );

  # Personalise your feed further - consider only changes
  # made by Fred to pages about bookshops.
  print $json->recent_changes(
             filter_on_metadata => {
                         username => 'Fred',
                         category => 'Bookshops',
                       },
              );

If using C<filter_on_metadata>, note that only changes satisfying
I<all> criteria will be returned.

B<Note:> Many of the fields emitted by the JSON generator are taken
from the node metadata. The form of this metadata is I<not> mandated
by L<Wiki::Toolkit>. Your wiki application should make sure to store some or
all of the following metadata when calling C<write_node>:

=over 4

=item B<comment> - a brief comment summarising the edit that has just been made.  Defaults to the empty string.

=item B<username> - an identifier for the person who made the edit; will be used as the Dublin Core contributor for this item.  Defaults to the empty string.

=item B<host> - the hostname or IP address of the computer used to make the edit; if no username is supplied then this will be used as the Dublin Core contributor for this item.  Defaults to the empty string.

=item B<major_change> - true if the edit was a major edit and false if it was a minor edit; used for the importance of the item.  Defaults to true (ie if C<major_change> was not defined or was explicitly stored as C<undef>).

=back

=head2 C<rss_timestamp()>

  print $json->rss_timestamp();

Returns the timestamp of the feed in POSIX::strftime style ("Tue, 29 Feb 2000 
12:34:56 GMT"), which is equivalent to the timestamp of the most recent item 
in the feed. Takes the same arguments as recent_changes(). You will most likely
need this to print a Last-Modified HTTP header so user-agents can determine
whether they need to reload the feed or not.
  
=head1 SEE ALSO

=over 4

=item * L<Wiki::Toolkit>

=item * L<http://web.resource.org/rss/1.0/spec>

=item * L<http://www.usemod.com/cgi-bin/mb.pl?ModWiki>

=back

=head1 MAINTAINER

Earle Martin <EMARTIN@cpan.org>. Originally by Kake Pugh <kake@earth.li>.

=head1 COPYRIGHT AND LICENSE

Copyright 2003-4 Kake Pugh. Subsequent modifications copyright 2005 
Earle Martin.

Copyright 2008 the Wiki::Toolkit team

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 THANKS

The members of the Semantic Web Interest Group channel on irc.freenode.net,
#swig, were very useful in the development of this module.

=cut
