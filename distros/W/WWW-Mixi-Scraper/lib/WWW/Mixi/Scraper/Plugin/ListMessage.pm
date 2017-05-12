package WWW::Mixi::Scraper::Plugin::ListMessage;

use strict;
use warnings;
use WWW::Mixi::Scraper::Plugin;

validator {qw( page is_number box is_anything )};

sub scrape {
  my ($self, $html) = @_;

  my %scraper;
  $scraper{messages} = scraper {
    process 'td.subject',
      string => 'TEXT';
    process 'td.subject>a',
      link => '@href';
    process 'td.status>img',
      envelope => '@src';
    process 'td.date',
      date => 'TEXT';
    process 'td.sender',
      sender => 'TEXT';
    result qw( string envelope link date sender );
  };

  $scraper{list} = scraper {
    process 'div.messageListBody>table.tableBody>tr',
      'messages[]' => $scraper{messages};
    result qw( messages );
  };

  my $stash = $self->post_process( $scraper{list}->scrape(\$html) );

  my @messages;
  for my $msg (@{ $stash }) {
    $msg->{sender} =~ s/^\s+//;
    $msg->{sender} =~ s/\s+$//;
    push @messages, {
      subject  => $msg->{string},
      name     => $msg->{sender},
      link     => $msg->{link},
      envelope => $msg->{envelope},
      time     => $msg->{date},  #???
    };
  }

  return $self->post_process( \@messages );
}

1;

__END__

=head1 NAME

WWW::Mixi::Scraper::Plugin::ListMessage

=head1 DESCRIPTION

This is almost equivalent to WWW::Mixi->parse_list_message().

=head1 METHOD

=head2 scrape

returns an array reference of

  {
    subject  => 'message title',
    name     => 'someone',
    link     => 'http://mixi.jp/view_message.pl?id=xxxx&box=xxx',
    time     => 'mm-dd',
    envelope => 'http://mixi.jp/img/mail5.gif'
  }

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki at cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
