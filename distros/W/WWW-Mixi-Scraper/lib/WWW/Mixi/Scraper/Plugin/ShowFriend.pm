package WWW::Mixi::Scraper::Plugin::ShowFriend;

use strict;
use warnings;
use WWW::Mixi::Scraper::Plugin;
use WWW::Mixi::Scraper::Utils qw( _uri );
use utf8;

validator {qw( id is_number )};

sub scrape {
  my ($self, $html) = @_;

  return {
    profile => $self->_scrape_profile($html),
    outline => $self->_scrape_outline($html),
  };
}

sub _scrape_profile {
  my ($self, $html) = @_;

  my %scraper;
  $scraper{items} = scraper {
    process 'th',
      key => 'TEXT';
    process 'td',
      value => $self->html_or_text;
    result qw( key value );
  };

  $scraper{profile} = scraper {
    process 'div.profileListTable>div>table>tr',
      'items[]' => $scraper{items};
    result qw( items );
  };

  my $stash = $self->post_process($scraper{profile}->scrape(\$html));

  my $profile = {};
  foreach my $item ( @{ $stash } ) {
    next unless $item->{key};
    $profile->{$item->{key}} = $item->{value};
  }

  return $profile;
}

sub _scrape_outline {
  my ($self, $html) = @_;

  my %scraper;
  $scraper{outline} = scraper {
    process 'div#myArea>div.profilePhoto>div.contents>p.name',
      'string' => 'TEXT';
    process 'div#myArea>div.profilePhoto>div.contents>p.name>span.loginTime',
      'description' => 'TEXT';
    process 'div#myArea>div.profilePhoto>div.contents>p.photo>a>img',
      image => '@src';
    process 'div.personalNavigation>ul>li.profile>a',
      link  => '@href';
    result qw( image string description link );
  };

  my $stash = $self->post_process($scraper{outline}->scrape(\$html))->[0];

  my $string = delete $stash->{string} || '';
  if ( $string =~ s/さん\((\d+)\)\s.+// ) {
    $stash->{name}  = $string;
    $stash->{count} = $1;
  }
  if ( $stash->{description} ) {
    $stash->{description} =~ s/^（//;
    $stash->{description} =~ s/）$//;
  }

  return $stash;
}

1;

__END__

=head1 NAME

WWW::Mixi::Scraper::Plugin::ShowFriend

=head1 DESCRIPTION

This is almost equivalent to WWW::Mixi->parse_show_friend_profile() and WWW::Mixi->parse_show_friend_outline(), though you need one more step to get the hash reference(s) you want.

=head1 METHOD

=head2 scrape

returns a hash reference of the person's profile.

  {
    profile => { 'profile' => 'hash' },
    outline => {
      name => 'name',
      link => 'http://mixi.jp/show_friend.pl?id=xxx',
      image => 'http://img.mixi.jp/photo/member/xx/xx/xxx.jpg',
      description => 'last login time',
      count => 20,
    },
  }

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki at cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
