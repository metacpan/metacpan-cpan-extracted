package WWW::Mixi::Scraper::Plugin::ViewEvent;

use strict;
use warnings;
use WWW::Mixi::Scraper::Plugin;
use WWW::Mixi::Scraper::Utils qw( _uri _datetime );
use utf8;

validator {qw(
  id       is_number
  comm_id  is_number
  page     is_number_or_all
)};

sub scrape {
  my ($self, $html) = @_;

  my %scraper;
  $scraper{images} = scraper {
    process 'a',
      link => '@onClick';
    process 'a>img',
      thumb_link => '@src';
    result qw( link thumb_link );
  };

  $scraper{infos} = scraper {
    process 'dt',
      name => 'TEXT';
    process 'dd',
      string => 'TEXT';
    process 'dd>a',
      link    => '@href',
      subject => 'TEXT';
    result qw( name string link subject );
  };

  $scraper{topic} = scraper {
    process 'dl.bbsList01>dt>span.date',
      'time' => 'TEXT';
    process 'dl.bbsList01>dt[class="bbsTitle clearfix"]>span.titleSpan',
      'subject' => 'TEXT';
    process 'dd.bbsContent>dl>dt>a',
      'name'      => 'TEXT',
      'name_link' => '@href';
    process 'dd.bbsContent>dl>dt',
      'name_string' => 'TEXT',
    process 'dd.bbsContent>dl>dd',
      'description' => $self->html_or_text;
    process 'div.communityPhoto>table>tr>td',
      'images[]' => $scraper{images};
    process 'dl.bbsList01>dd.bbsInfo>dl',
      'infos[]' => $scraper{infos};
    result qw( time subject name_string name name_link images infos description );
  };

  $scraper{comment_body} = scraper {
    process 'dl.commentContent01>dt>a',
      'name_link' => '@href',
      'name'      => 'TEXT';
    process 'dl.commentContent01>dt',
      'name_string' => 'TEXT';
    process 'dl.commentContent01>dd',
      'description' => $self->html_or_text;
    process 'dl.commentContent01>dd>table>tr>td',
      'images[]' => $scraper{images};
    result qw( name_link name description images );
  };

  $scraper{comment} = scraper {
    process 'dl.commentList01>dt>span.date',
      'dates[]' => 'TEXT';
    process 'dl.commentList01>dt>span.senderId',
      'sender_ids[]' => 'TEXT';
    process 'dl.commentList01>dd',
      'comments[]' => $scraper{comment_body};
    result qw( dates comments sender_ids );
  };

  my $stash = $self->post_process($scraper{topic}->scrape(\$html))->[0];

  if ($stash->{name_string} && !$stash->{name}) {
    $stash->{name} = $stash->{name_string};
  }

  foreach my $item (@{ $stash->{infos} || [] }) {
    if ( $item->{name} eq '開催日時' ) {
      $stash->{date} = $item->{string};
    }
    if ( $item->{name} eq '募集期限' ) {
      $stash->{deadline} = $item->{string};
    }
    if ( $item->{name} eq '開催場所' ) {
      $stash->{location} = $item->{string};
    }
    if ( $item->{name} eq '参加者' ) {
      $stash->{list}->{count}   = $item->{string};
      $stash->{list}->{link}    = _uri( $item->{link} );
      $stash->{list}->{subject} = $item->{subject};
    }
  }

  # XXX: this fails when you test with local files.
  # However, this link cannot be extracted from the html,
  # at least as of writing this. ugh.
  $stash->{link} = $self->{uri};

  my $stash_c = $self->post_process($scraper{comment}->scrape(\$html))->[0];

  my @dates      = @{ $stash_c->{dates} || [] };
  my @sender_ids = @{ $stash_c->{sender_ids} || [] };
  my @comments   = @{ $stash_c->{comments} || [] };
  foreach my $comment ( @comments ) {
    $comment->{time}      = _datetime( shift @dates );
    $comment->{subject}   = shift @sender_ids;

    if (!$comment->{name}) {
      $comment->{name} = $comment->{name_string} || ' ';
    }

    # incompatible with WWW::Mixi to let comment links
    # look more 'permanent' to make plagger/rss readers happier
    $comment->{name_link} = _uri( $comment->{name_link} );
    $comment->{link}      = $stash->{link}
      ? _uri( $stash->{link} . '#' . $comment->{subject} )
      : undef;

    if ( $comment->{images} ) {
      foreach my $image ( @{ $comment->{images} || [] } ) {
        $image->{link}       = _uri( $image->{link} );
        $image->{thumb_link} = _uri( $image->{thumb_link} );
      }
    }
  }

  $stash->{comments} = \@comments;

  return $stash;
}

1;

__END__

=head1 NAME

WWW::Mixi::Scraper::Plugin::ViewEvent

=head1 DESCRIPTION

This is almost equivalent to WWW::Mixi->parse_view_event().

=head1 METHOD

=head2 scrape

returns a hash reference such as

  {
    subject => 'title of the event',
    link => 'http://mixi.jp/view_event.pl?id=xxx',
    time => 'yyyy-mm-dd hh:mm',
    date => 'yyyy-mm-dd',
    deadline => 'sometime soon',
    location => 'somewhere',
    description => 'event description',
    name => 'who plans',
    name_link => 'http://mixi.jp/show_friend.pl?id=xxx',
    list => {
      count => '8人',
      link => 'http://mixi.jp/list_event_member.pl?id=xxx&comm_id=xxx',
      subject => '参加者一覧を見る',
    },
    comments => [
      {
        subject     => 1,
        name        => 'commenter',
        name_link   => 'http://mixi.jp/show_friend.pl?id=xxxx',
        link        => 'http://mixi.jp/view_event.pl?id=xxxx#1',
        time        => 'yyyy-mm-dd hh:mm',
        description => 'comment body',
      }
    ]
  }

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki at cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
