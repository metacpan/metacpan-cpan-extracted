package WWW::Mixi::Scraper::Plugin::NewVideo;
use strict;
use warnings;
use WWW::Mixi::Scraper::Plugin;
use base qw( WWW::Mixi::Scraper::Plugin::NewFriendDiary );

validator {};

1;

__END__

=head1 NAME

WWW::Mixi::Scraper::Plugin::NewVideo

=head1 DESCRIPTION

This would be equivalent to WWW::Mixi->parse_new_video().
(though the latter is not implemented yet as of writing this)

=head1 METHOD

=head2 scrape

returns an array reference of

  {
    subject  => 'video title',
    name     => 'someone',
    link     => 'http://video.mixi.jp/view_video.pl?video_id=xxxx&box=xxx',
    time     => 'mm-dd',
    envelope => 'http://video.mixi.jp/img/xxxx.gif'
  }

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Tatsuhiko Miyagawa.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
