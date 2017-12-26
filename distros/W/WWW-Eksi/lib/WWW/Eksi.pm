package WWW::Eksi;
$WWW::Eksi::VERSION = '0.28';
=head1 NAME

WWW::Eksi - Interface for Eksisozluk.com

=head1 DESCRIPTION

An interface for Eksisozluk, a Turkish social network.
Provides easy access to entries and lists of entries.

=head1 SYNOPSIS

  use WWW::Eksi;
  my $e = WWW::Eksi->new;

  # Last week's most popular entries
  my @ghebe_fast = $e->ghebe;    # might get rate limited
  my @ghebe_slow = $e->ghebe(5); # add a politeness delay

  # Yesterday's most popular entries
  my @doludolu   = $e->doludolu(5);

  # Single entry
  my $entry   = $e->download_entry(1);

=cut

use warnings;
use strict;
use Carp;
use List::Util qw/any/;

use URI;
use Furl;
use Mojo::DOM;
use WWW::Lengthen;
use IO::Socket::SSL;

use DateTime;
use DateTime::Format::Strptime;

=head1 METHODS

=head2 new

Returns a new WWW::Eksi object.

=cut

sub new{
  my $class = shift;
  my $today = DateTime->now->ymd;

  my $eksi = {
    base     => 'https://eksisozluk.com',
    entry    => 'https://eksisozluk.com/entry/',
    ghebe    => 'https://eksisozluk.com/istatistik/gecen-haftanin-en-begenilen-entryleri',
    strp_dt  => DateTime::Format::Strptime->new( pattern => '%d.%m.%Y%H:%M'),
    strp_d   => DateTime::Format::Strptime->new( pattern => '%d.%m.%Y'),
    doludolu => 'https://eksisozluk.com/basliklar/ara?SearchForm.When.From='.$today.'T00:00:00&SearchForm.When.To='.$today.'T23:59:59&SearchForm.SortOrder=Count',
  };

  return bless $eksi, $class;
}

=head2 download_entry($id)

Takes entry id as argument, returns its data (if available) as follows.

  {
    entry_url      => Str
    topic_url      => Str
    topic_title    => Str
    topic_channels => [Str]

    author_name    => Str
    author_url     => Str
    author_id      => Int

    body_raw       => Str
    body_text      => Str (html tags removed)
    body_processed => Str (html tags processed)
    fav_count      => Int
    create_time    => DateTime
    update_time    => DateTime
  }

=cut

sub download_entry{
  my ($self,$id) = @_;
  my $data = $self->_download($self->{entry}.$id) if ($id && $id=~/^\d{1,}$/);
  return unless $data;
  return $self->_parse_entry($data,$id);
}

sub _parse_entry{
  my ($self,$data, $id) = @_;
  return unless $data;

  my $e = {};
  my $dom = Mojo::DOM->new($data);

  unless ($id){
    $id = $dom->at('a[class~=entry-date]')->{href};
    $id =~ s/[^\d]//g;
    return unless ($id && $id=~/^\d{1,}$/);
  }

  # entry_url
  $e->{entry_url}      = $self->{entry}.$id;

  # body_raw, body_text, body_processed
  $e->{body_raw}       = $dom->at('div[class=content]')->content;
  $e->{body_text}      = $dom->at('div[class=content]')->text;
  $e->{body_processed} = $self->_process_entry($e->{body_raw});


  # time_as_seen, create_time, update_time
  my $time_as_seen   = $dom->at('a[class~=entry-date]')->text;
  $e->{time_as_seen} = $time_as_seen;

  $time_as_seen =~/
    ^
    \s*
    (?<date_posted>\d\d\.\d\d\.\d{4})
    \s*
    (?<time_posted>\d\d:\d\d)? #old entries lack time
    ( # update block
      \s*
      ~
      \s*
      (?<date_updated>\d\d\.\d\d\.\d{4})?
      # date won't be shown if updated on the same day
      \s*
      (?<time_updated>\d\d:\d\d)?
    )? # will not exist if not updated
    \s*
    $
    /x;

  my $date_posted  = $+{date_posted}  // '';
  my $time_posted  = $+{time_posted}  // '';
  my $date_updated = $+{date_updated} // '';
  my $time_updated = $+{time_updated} // '';

  Carp::croak "Entry date could not be found" unless $date_posted;

  $e->{create_time} = $time_posted
                    ? $self->{strp_dt}->parse_datetime($date_posted.$time_posted)
                    : $self->{strp_d}->parse_datetime($date_posted);
  $e->{update_time} = $time_updated
                    ? $self->{strp_dt}->parse_datetime(
                      ($date_updated || $date_posted).$time_updated)
                    : '';


  # author_name, author_url, author_id, fav_count
  my $li_data_id_entry = $dom->at("li[data-id=$id]");
  my $a_entry_author   = $dom->at('a[class=entry-author]');
  $e->{author_name}    = $li_data_id_entry->{"data-author"}
                         // $a_entry_author->text;
  $e->{author_url}     = $self->{base}.$a_entry_author->{href};
  $e->{author_id}      = $li_data_id_entry->{"data-author-id"} // 0;
  $e->{fav_count}      = $li_data_id_entry->{"data-favorite-count"} // 0;


  # topic_channels
  my $channels_text = $dom->at('section[id=hidden-channels]')->text // 0;
  $channels_text    =~s/^\s*//;
  $channels_text    =~s/\s*$//;
  my @channels      = split ',',$channels_text;
  $e->{topic_channels} = \@channels;


  # topic_title, topic_url
  my $h1_id_title   = $dom->at('h1[id=title]');
  $e->{topic_title} = $h1_id_title->{'data-title'};
  $e->{topic_url}   = $self->{base}.$h1_id_title->at('a')->{href};

  return $e;
}

=head2 ghebe($politeness_delay)

Returns an array of entries for top posts of last week.
Ordered from more popular to less popular.

=cut

sub ghebe{
  my $self      = shift;
  my $sleep_sec = shift // 0;
  my $data      = $self->_download($self->{ghebe});
  return unless $data;

  my $dom   = Mojo::DOM->new($data);
  my $links = $dom->at('ol[class~=stats]')->find('a');
  my $ids   = $links->map(sub{$_->{href}=~m/%23(\d+)$/})->to_array;
  my @ghebe = ();

  foreach my $id (@$ids){
    my $entry = $self->download_entry($id);
    push @ghebe, $entry;
    sleep $sleep_sec;
  }

  return @ghebe;
}

=head2 doludolu($politeness_delay)

Returns an array of entries for top posts of yesterday.
Ordered from more popular to less popular.
This is an alternative list to DEBE, which is discontinued.

=cut

sub doludolu{
  my $self      = shift;
  my $sleep_sec = shift // 0;
  my $data      = $self->_download($self->{doludolu});
  my @doludolu  = ();
  return unless $data;

  my $dom   = Mojo::DOM->new($data);
  my $links = $dom
            ->at('ul[class=topic-list]')
            ->find('a')
            ->map(sub{$_->{href}=~m/^(.*)\?/})
            ->to_array;

  foreach my $link (@$links){
    my $entry_html = $self->_download($self->{base}.$link.'?a=dailynice');
    my $entry_hash = $self->_parse_entry($entry_html);
    push @doludolu, $entry_hash;
    sleep $sleep_sec;
  }

  return @doludolu;
}

sub _download{
  my ($self,$url) = @_;

  my $u = URI->new($url) if $url;
  return 0 unless ($url && $u && (any {$u->scheme eq $_} qw/http https/));

  my $response = Furl->new->get($u);

  return ($response && $response->is_success)
    ? $response->content
    : 0;
}

sub _lengthen{
  my ($self, $url) = @_;

  my $u = URI->new($url) if $url;
  return 0 unless ($url && $u && (any {$u->scheme eq $_} qw/http https/));

  my $lengthener = WWW::Lenghten->new;

  return (any {$u->host eq $_} qw/is.gd goo.gl/)
         ? $lengthener->try($u)
         : $u;
}

sub _process_entry{
  my ($self,$e) = @_;
  return unless $e;

  # Expand goo.gl and is.gd links
  $e=~s/href="(https?:\/\/(goo\.gl|is\.gd)[^"]*)"/"href=\""._lengthen($1)."\""/ieg;

  # Make hidden references (akıllı bkz) visible
  $e=~s/(<sup class="ab"><a data-query=")([^"]*)("[^<>]*>)\*/$1$2$3* ($2)/g;

  # Make local links global
  $e=~s/href="\//target="_blank" href="https:\/\/eksisozluk.com\//g;

  # Force no decoration to disable underline in Gmail
  $e=~s/href="/style="text-decoration:none;" href="/g;

  # Add JPG to imgur images with no extension
  $e=~s/(href="https?:\/\/[^.]*\.?imgur.com\/\w{7})"/$1\.jpg"/g;

  # Make JPG/PNG images visible
  $e=~s/(href="([^"]*\.(jpe?g|png)(:large)?)"[^<]*<\/a>)/$1<br><br><img src="$2"><br><br>/g;

  # Add NW arrow to external links
  $e=~s/(https?:\/\/(?!eksisozluk.com)([^\/<]*\.[^\/<]*)[^<]*<\/a>)/$1 \($2 &#8599;\)/g;

  return $e;

}

sub _entry_not_found{

  return {
    topic_title    => '?',
    topic_url      => '?',
    topic_channels => [],
    author_name    => '?',
    author_id      => 0,
    body_raw       => "<i>bu entry silinmi&#351;.</i>",
    body_text      => "bu entry silinmi&#351;.",
    body_processed => "<i>bu entry silinmi&#351;.</i>",
    fav_count      => '?',
    create_time    => 0,
    update_time    => 0,
  };
}

1;

__END__

=head1 AUTHOR

Kivanc Yazan C<< <kyzn at cpan.org> >>

=head1 CONTRIBUTORS

Mohammad S Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kivanc Yazan.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Content you reach by using this module might be subject to copyright
terms of Eksisozluk. See eksisozluk.com for details.

=cut
