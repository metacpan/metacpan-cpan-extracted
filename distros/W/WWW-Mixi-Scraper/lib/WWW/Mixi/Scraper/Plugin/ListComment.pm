package WWW::Mixi::Scraper::Plugin::ListComment;

use strict;
use warnings;
use WWW::Mixi::Scraper::Plugin;

validator {qw( id is_number )};

sub scrape {
  my ($self, $html) = @_;

  my %scraper;
  $scraper{comments} = scraper {
    process 'dl>dd',
      string => 'TEXT';
    process 'dl>dd>a',
      link => '@href',
      subject => 'TEXT';
    process 'dl>dt',
      time => 'TEXT';
    result qw( string time link subject );
  };

  $scraper{list} = scraper {
    process 'div.listCommentArea>ul.entryList01>li',
      'comments[]' => $scraper{comments};
    result qw( comments );
  };

  return $self->post_process(
    $scraper{list}->scrape(\$html) => \&_extract_name
  );
}

1;

__END__

=head1 NAME

WWW::Mixi::Scraper::Plugin::ListComment

=head1 DESCRIPTION

This is equivalent to WWW::Mixi->parse_list_comment().

=head1 METHOD

=head2 scrape

returns an array reference of

  {
    subject => 'comment extract',
    name    => 'someone',
    link    => 'http://mixi.jp/view_diary.pl?id=xxxx',
    time    => 'yyyy-mm-dd hh:mm'
  }

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki at cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
