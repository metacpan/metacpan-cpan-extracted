package WWW::Mixi::Scraper::Plugin::ShowSchedule;

use strict;
use warnings;
use WWW::Mixi::Scraper::Plugin;
use utf8;

my %Subjects = (
  'isJoinedSchedule' => '予定',
  'birthday'  => '誕生日',
  'isCommunityJoined' => '参加イベント',
  'community' => 'イベント',
  'isFriendSchedule' => 'マイミクの予定',
);

validator {(
  year    => 'number',
  month   => 'number',
  pref_id => 'number',
)};

sub scrape {
  my ($self, $html) = @_;

  my %scraper;
  $scraper{ym} = scraper {
    process 'div.calendarBody>div.pageNavi>h3',
      ym => 'TEXT';
    result qw( ym );
  };
  my $ym = $scraper{ym}->scrape(\$html);

  my ($year, $month) = $ym =~ /^(\d{4})\D+(\d{1,2})/;

  $scraper{day} = scraper {
    process 'span.date',
      day => sub { $_->content and $_->content->[0] };
    process 'ul>li',
      'types[]' => sub { (split /\s/, $_->attr('class'))[-1] };
    process 'ul>li>a',
      'texts[]' => 'TEXT',
      'links[]' => '@href';
    result qw( day icons links texts types );
  };

  $scraper{list} = scraper {
    process 'div.contents>table.calendarTable>tbody>tr>td', 
      'string[]' => $scraper{day};
    result qw( string );
  };

  my @items;
  foreach my $day ( @{ $scraper{list}->scrape(\$html) } ) {
    next if $day->{day} =~ m{\d+/\d+};
    my $date = sprintf '%04d/%02d/%02d', $year, $month, $day->{day};

    my @texts = @{ $day->{texts} || [] };
    my @links = @{ $day->{links} || [] };
    my @types = @{ $day->{types} || [] };

    next unless @texts && @links;

    my $max = @texts;
    for(my $ct = 0; $ct < $max; $ct++) {
      next if $types[$ct] eq 'member';
      my $icon = $types[$ct] eq 'birthday'
         ? 'http://img.mixi.jp/img/calendaricon2/i_bd.gif'
         : 'http://img.mixi.jp/img/basic/icon/calendar_event001.gif';

      push @items, {
        subject => ($Subjects{$types[$ct]} || '不明'),
        name => $texts[$ct],
        link => $links[$ct],
        icon => $icon,
        time => $date,
      };
    }
  }

  return $self->post_process( \@items );
}

1;

__END__

=head1 NAME

WWW::Mixi::Scraper::Plugin::ShowSchedule

=head1 DESCRIPTION

This is almost equivalent to WWW::Mixi->parse_show_calendar().

=head1 METHOD

=head2 scrape

returns an array reference of

  {
    subject => 'item title',
    name    => 'someone',
    link    => 'http://mixi.jp/view_event.pl?id=xxxx',
    time    => 'yyyy-mm-dd'
    icon    => 'http://mixi.jp/img/i_bd.gif',
  }

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki at cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
