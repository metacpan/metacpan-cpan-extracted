package WWW::Mixi::Scraper::Plugin::ViewBBS;

use strict;
use warnings;
use WWW::Mixi::Scraper::Plugin;
use WWW::Mixi::Scraper::Utils qw( _datetime _uri );

validator {qw(
  id             is_number
  comm_id        is_number
  comment_count  is_number
  page           is_number_or_all
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

  $scraper{topic} = scraper {
    process 'dl[class="bbsList01 bbsDetail"]>dt>span.date',
      time => 'TEXT';
    process 'dl[class="bbsList01 bbsDetail"]>dt>span.titleSpan',
      subject => 'TEXT';
    process 'dd.bbsContent>dl>dt>a',
      name      => 'TEXT',
      name_link => '@href';
    process 'dd.bbsContent>dl>dd',
      description => $self->html_or_text;
    process 'dd.bbsContent>dl>dd>div.communityPhoto>table>tr>td',
      'images[]' => $scraper{images};
    result qw( time subject description name name_link images link );
  };

  # bbs topic is not an array
  my $stash = $self->post_process($scraper{topic}->scrape(\$html))->[0];

  # XXX: this fails when you test with local files.
  # However, this link cannot be extracted from the html,
  # at least as of writing this. ugh.
  $stash->{link} = $self->{uri};

  $scraper{comments} = scraper {
    process 'dt>a',
      link => '@href',
      name => 'TEXT';
    process 'dd',
      description => $self->html_or_text;
    result qw( link name description );
  };

  $scraper{list} = scraper {
    process 'dl.commentList01>dt[class="commentDate clearfix"]>span.date',
      'times[]' => 'TEXT';
    process 'dl.commentList01>dt[class="commentDate clearfix"]>span.senderId',
      'sender_ids[]' => 'TEXT';
    process 'dl.commentList01>dd>dl.commentContent01',
      'comments[]' => $scraper{comments};
    result qw( times sender_ids comments );
  };

  my $stash_c = $self->post_process($scraper{list}->scrape(\$html))->[0];

  my @comments   = @{ $stash_c->{comments} || [] };
  my @times      = @{ $stash_c->{times} || [] };
  my @sender_ids = @{ $stash_c->{sender_ids} || [] };
  foreach my $comment ( @comments ) {
    $comment->{time}      = _datetime( shift @times );
    $comment->{subject}   = shift @sender_ids;

    # incompatible with WWW::Mixi to let comment links
    # look more 'permanent' to make plagger/rss readers happier
    $comment->{name_link} = _uri( $comment->{link} );
    $comment->{link}      = $stash->{link}
      ? _uri( $stash->{link} . '#' . $comment->{subject} )
      : undef;
  }
  $stash->{comments} = \@comments;

  return $stash;
}

1;

__END__

=head1 NAME

WWW::Mixi::Scraper::Plugin::ViewBBS

=head1 DESCRIPTION

This is almost equivalent to WWW::Mixi->parse_view_bbs().

=head1 METHOD

=head2 scrape

returns a hash reference such as

  {
    subject => 'title of the topic',
    link => 'http://mixi.jp/view_bbs.pl?id=xxxx',
    time => 'yyyy-mm-dd hh:mm',
    name => 'originator of the topic',
    name_link => 'http://mixi.jp/show_friend.pl?id=xxxx',
    description => 'topic',
    images => [
      {
        link => 'show_picture.pl?img_src=http://img1.mixi.jp/photo/xx/xx.jpg',
        thumb_link => 'http://img1.mixi.jp/photo/xx/xx.jpg',
      },
    ],
    comments => [
      {
        subject   => 1,
        name      => 'commenter',
        name_link => 'http://mixi.jp/show_friend.pl?id=xxxx',
        link      => 'http://mixi.jp/view_bbs.pl?id=xxxx#1',
        time      => 'yyyy-mm-dd hh:mm',
        description => 'comment body',
      },
    ]
  }

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki at cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
