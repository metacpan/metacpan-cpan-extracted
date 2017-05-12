package WWW::Scraper::Delicious;

use strict;
use warnings;

use LWP::UserAgent;

our $VERSION = '0.10';

sub new {
    my ($class, %args) = @_;
    my $self = {};
    limit($self, $args{limit}) if $args{limit};
    ua($self, $args{ua}) if $args{ua};
    $self->{ua} = LWP::UserAgent->new() unless $self->{ua};
    bless($self, $class);
    return $self;
}

sub getlinks {
    my ($self, $path) = @_;
    return unless $path;
    my $url = ($path =~ /^htt/ ? $path
      : ( $path =~ /^\// ? "http://del.icio.us$path"
            : "http://del.icio.us/$path" ) );
    my $limit = $self->{limit} || 0;
    my %linkset = _scrape($self->{ua}, $url, $limit);
    return %linkset;
}

sub getlinksarray {
    my ($self, $path) = @_;
    my %linkset = getlinks($self, $path);
    return unless keys %linkset;
    my @table = sort { $b->[5] cmp $a->[5] }
      map { [ $linkset{$_}{id},
              $linkset{$_}{url},
              $linkset{$_}{desc},
              $linkset{$_}{notes},
              $linkset{$_}{pop},
              $linkset{$_}{date},
              $linkset{$_}{tag}, $linkset{$_}  ]
      } keys %linkset;
    return @table;
}

sub ua {
    my ($self, $ua) = @_;
    $self->{ua} = $ua if defined $ua
      && ref($ua) eq 'LWP::UserAgent';
    return $self->{ua};
}

sub limit {                     # limit of 0 is default (unlimited)
    my ($self, $limit) = @_;
    $self->{limit} = $limit if defined $limit && $limit =~ /^\d+$/;
    return $self->{limit};
}

sub dumplink {
    my ($self, $linkref) = @_;
    return unless $linkref;
    $linkref = $linkref->[7] if ref($linkref) eq 'ARRAY';
    return unless $linkref->{id};
    my $str = "   id = ".$linkref->{id}."\n";
    $str   .= "  url = ".$linkref->{url}."\n";
    $str   .= " desc = ".$linkref->{desc}."\n"  if $linkref->{desc};
    $str   .= "notes = ".$linkref->{notes}."\n" if $linkref->{notes};
    $str   .= "  pop = ".$linkref->{pop}."\n"   if $linkref->{pop};
    $str   .= " date = ".$linkref->{date}."\n"  if $linkref->{date};
    $str   .= " tags = ".join(', ', sort keys %{$linkref->{tag}})."\n"
                                                if $linkref->{tag};
    return $str;
}

sub _scrape {
    my ($ua, $url, $limit) = @_;
    my (%linkset, $page);
    my $num = 0;

    while (1) {

        my $url = "$url?setcount=100" . ($page ? "&page=$page" : '');
        my $rs = $ua->get($url);
        return unless $rs->is_success;
        my $html = $rs->content;

        my @tmp = split /<li class="post" key="/si, $html;
        for my $scrap (@tmp[1..$#tmp]) {
            $scrap =~ s/\s*<\/li>.*$//si;

            next unless (my ($id, $url, $desc) = $scrap =~
              /^(.*?)".*?a href="(.*?)".*?>(.*?)<\/a>/si) == 3;
            $linkset{$id} = { id => $id, url => $url, desc => $desc };

            my ($notes) = $scrap =~ /class="notes">(.*?)<\/p>/si;
            $linkset{$id}{notes} = $notes if $notes;

            for my $str (split /<a class="tag" /, $scrap) {
                next unless my($tag) = $str =~ /^href=.*?>(.*?)<\/a>/;
                $linkset{$id}{tag}{$tag}++;
            }
            delete $linkset{$id}{tag} unless keys %{$linkset{$id}{tag}};

            my ($pop) = $scrap =~ /a class="pop".*?>.*?by (\d+) /si;
            $linkset{$id}{pop} = $pop if $pop;
          
            my ($date) = $scrap =~ / class="date" title="(.*?)"/si;
            $linkset{$id}{date} = $date if $date;

            last if ++$num == $limit;
        }
             
        last unless my($page0,$page1) = $html =~ / page (\d+) of (\d+)/si;
        last if $page0 == $page1;
        $page = $page ? $page + 1 : 2;
    }

    return %linkset;
}

1;
__END__

=head1 NAME

WWW::Scraper::Delicious - Retrieve links from del.icio.us

=head1 SYNOPSIS

    use WWW::Scraper::Delicious;
    my $delicious = WWW::Scraper::Delicious->new();
    my %linkset = $delicious->getlinks('blahuser');

    map { print "\n".$delicious->dumplink($linkset{$_}) } keys %linkset;

=head1 REQUIRED MODULES

L<LWP::UserAgent>

=head1 EXPORT

None.

=head1 DESCRIPTION

This module implements a very simple and effective way to scrape links
from the http://del.icio.us/ site without the requirement of using the
del.icio.us API, authentication, or RSS. Although links can be scraped
from any valid del.icio.us URL, the intended use of this module is to
provide users a simple way to backup and/or mirror their own links.
There is no hard limit for the number of user links that can be
returned, but a limit of 100 is respected for other types of link
queries.

=head1 METHODS

=head2 C<new()>

    $delicious = WWW::Scraper::Delicious->new();
    $delicious = WWW::Scraper::Delicious->new( limit => 5, ua => $ua );

The constructor method returns a B<WWW::Scraper::Delicious> object.
The C<limit> and C<ua> arguments are optional. The C<limit> option
allows you to restrict the number of results returned (default of 0 is
unlimited). You may also pass a custom B<LWP::UserAgent> object
handle.

=head2 C<getlinks()>

    my %linkset = $delicious->getlinks('blahuser');
    my %linkset = $delicious->getlinks('/blahuser');
    my %linkset = $delicious->getlinks('/blahuser/tag');
    my %linkset = $delicious->getlinks('http://del.icio.us/blahuser/tag');
    my %linkset = $delicious->getlinks('http://del.icio.us/blahuser/tag+tag2');
    my %linkset = $delicious->getlinks('tag/security');

The only argument accepted by the C<getlinks()> method is the
del.icio.us URL string of interest. The leading http://del.icio.us/
portion of the URL parameter is optional.

=head2 C<getlinksarray()>

    my @links = $delicious->getlinksarray('blahuser');

The argument is the same as with C<getlinks>, but this method returns
the link results in the form of a reverse chronologically-ordered array.

=head2 C<ua()>

    $delicious->ua($myCustomUA);

This method can be invoked without an argument to obtain the current
B<LWP::UserAgent> object handle. Invoking with an argument will
establish the new setting.

=head2 C<limit()>

    $delicious->limit(9);

This method can be invoked without an argument to obtain the current
limit setting (default 0 is unlimited). Invoking with an argument
will establish the new setting.

=head2 C<dumplink()>

    $delicious->dumplink($linkref);

Returns a text-formatted rendition of a referenced link.

=head1 AUTHOR

Adam Foust, <agf@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006, Adam Foust. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
