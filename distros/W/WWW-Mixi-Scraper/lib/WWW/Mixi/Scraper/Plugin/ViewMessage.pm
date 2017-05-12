package WWW::Mixi::Scraper::Plugin::ViewMessage;

use strict;
use warnings;
use WWW::Mixi::Scraper::Plugin;

validator {qw(
  id   is_anything
  box  is_anything
)};

sub scrape {
  my ($self, $html) = @_;

  my %scraper;
  $scraper{message} = scraper {
    process 'div#messageDetail>div.thumb>a',
      'link' => '@href';
    process 'div#messageDetail>div.thumb>a>img',
      'image' => '@src',
      'name'  => '@alt';
    process 'div#messageDetail>div.messageDetailHead>h3',
      'subject' => 'TEXT';
    process 'div#messageDetail>div.messageDetailHead>dl>dd',
      'heads[]' => 'TEXT';
    process 'div#message_body',
      'description' => $self->html_or_text;
    result qw( subject name link image description heads );
  };

  my $stash = $scraper{message}->scrape(\$html);
  my $time = $stash->{heads}->[0];
     $time =~ s/^.*(\d{4})\D+(\d{2})\D+(\d{2})\D+(\d{2})\D+(\d{2}).*$/$1\-$2\-$3 $4:$5/;

  $stash->{time} = $time;
  delete $stash->{heads};

  return $self->post_process( $stash )->[0];
}

1;

__END__

=head1 NAME

WWW::Mixi::Scraper::Plugin::ViewMessage

=head1 DESCRIPTION

This is equivalent to WWW::Mixi->parse_view_message().

=head1 METHOD

=head2 scrape

returns a hash reference such as

  {
    subject => 'title of the message',
    image => 'http://img.mixi.jp/photo/member/xx/xx/xxx_xxx.jpg',
    link => 'http://mixi.jp/show_friend.pl?id=xxx',
    name => 'someone',
    time => 'yyyy-mm-dd hh:mm',
    description => 'message body',
  }

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki at cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
