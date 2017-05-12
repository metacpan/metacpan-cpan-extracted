package XML::FeedWriter::RSS20;

use strict;
use warnings;
use Carp;
use base qw( XML::FeedWriter::Base );

__PACKAGE__->_alias({
  creator        => 'dc:creator',
  pubdate        => 'pubDate',
  published      => 'pubDate',
  lastbuilddate  => 'lastBuildDate',
  updated        => 'lastBuildDate',
  webmaster      => 'webMaster',
  managingeditor => 'managingEditor',
  editor         => 'managingEditor',
  content        => 'content:encoded',
  summary        => 'description',
});

__PACKAGE__->_requires({
  channel   => [qw( description link title )],
  cloud     => [qw( domain path port protocol registerProcedure )],
  image     => [qw( link title url )],
  textinput => [qw( description link name title )],
  enclosure => [qw( length type url )],
});

__PACKAGE__->_sort_order({
  title       => 10,
  link        => 9,
  description => 8,
  creator     => 7,
  author      => 7,
  pubDate     => 6,
  guid        => 5,
});

sub _extra_options {
  my ($self, $options) = @_;

  my $no_cdata = delete $options->{no_cdata};

  $self->{_use_cdata} = !$no_cdata;
}

sub _root_element {
  my ($self, $modules) = @_;

  $self->xml->startTag( rss =>
    version         => '2.0',
    'xmlns:dc'      => 'http://purl.org/dc/elements/1.1/',
    'xmlns:content' => 'http://purl.org/rss/1.0/modules/content/',
    %{ $modules },
  );
}

sub _channel {
  my ($self, $channel) = @_;

  $channel->{lastBuildDate} ||= $self->dtx->for_rss20;

  $self->xml->startTag('channel');

  foreach my $key ( $self->_sort_keys( $channel ) ) {

    if ( $key eq 'category' ) {
      $self->_duplicable_elements( $key => $channel->{$key} );
    }

    elsif ( $key eq 'cloud' ) {
      $self->_empty_element( $key => $channel->{$key} );
    }

    elsif ( $key =~ /image|textinput/ ) {
      $self->_element_with_children( $key => $channel->{$key} );
    }

    elsif ( $key =~ /lastBuildDate|pubDate/ ) {
      $self->_datetime_element( $key => $channel->{$key} );
    }

    elsif ( my ($type) = $key =~ /skip(Day|Hour)s/ ) {
      $self->_element_with_duplicable_children(
        $key => $channel->{$key}, lc $type
      );
    }

    else {
      $self->_data_element( $key => $channel->{$key} );
    }
  }
}

sub add_items {
  my ($self, @items) = @_;

  croak "can't add items any longer" if $self->_closed;

  foreach my $i ( @items ) {
    my %item = $self->_canonize( $i );

    $self->xml->startTag('item');
    foreach my $key ( $self->_sort_keys( \%item ) ) {

      if ( $key eq 'pubDate' ) {
        $self->_datetime_element( $key => $item{$key} );
      }

      elsif ( $key eq 'description' ) {
        $self->_cdata_element( $key => $item{$key} );
      }

      elsif ( $key eq 'enclosure' ) {
        $self->_empty_element( $key => $item{$key} );
      }

      elsif ( $key eq 'category' ) {
        $self->_duplicable_elements( $key => $item{$key} );
      }

      else {
        $self->_data_element( $key => $item{$key} );
      }
    }
    $self->xml->endTag('item');
  }
}

sub close {
  my $self = shift;

  return if $self->_closed;

  $self->xml->endTag('channel');
  $self->xml->endTag('rss');
  $self->xml->end;

  $self->_closed(1);
}

1;

__END__

=head1 NAME

XML::FeedWriter::RSS20

=head1 SYNOPSIS

    use XML::FeedWriter;

    # let's create a writer.

    my $writer = XML::FeedWriter->new(

      # specify type/version; RSS 2.0 by default
      version     => '2.0',

      # and channel info
      title       => 'feed title',
      link        => 'http://example.com',
      description => 'blah blah blah',
    );

    # add as many items as you wish (and spec permits).

    $writer->add_items(
      # each item should be a hash reference
      {
        title       => 'first post',
        description => 'plain text of the first post',
        link        => 'http://example.com/first_post',
        updated     => time(),  # will be converted to a pubDate
        creator     => 'me',  # alias for "dc:creator"
      },
      {
        title       => 'second post',
        description => '<p>html of the second post</p>',
        link        => 'http://example.com/second_post',
        pubdate     => DateTime->now, # will be formatted properly
        creator     => 'someone',
      },
    );

    # this will close several tags such as root 'rss'.

    $writer->close;

    # then, if you want to save the feed to a file

    $writer->save('path_to_file.xml');

    # or just use it as an xml string.

    my $string = $writer->as_string;

=head1 DESCRIPTION

This is an RSS 2.0 feed writer. You usually don't need to use this directly, but if you insist, replace XML::FeedWriter with XML::FeedWriter::RSS20 and it works fine.

=head1 METHODS

See L<XML::FeedWriter> for usage.

=head2 new

=head2 add_items

=head2 close

=head2 save

=head2 as_string

=head1 SEE ALSO

L<http://www.rssboard.org/rss-profile>

L<XML::FeedWriter>

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
