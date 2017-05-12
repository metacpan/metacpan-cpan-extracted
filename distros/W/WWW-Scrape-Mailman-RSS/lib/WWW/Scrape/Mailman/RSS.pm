package WWW::Scrape::Mailman::RSS;

use warnings;
use strict;
use WWW::Mechanize;
use HTML::TableExtract;
use XML::Twig;
use XML::RSS;
use HTML::TokeParser::Simple;
use Data::Dumper;

=head1 NAME

WWW::Scrape::Mailman::RSS - Parse mailman listserve archives, format as an rss feed

=head1 VERSION

Version 0.12

=cut

our $VERSION = '0.12';

=head1 SYNOPSIS

On some convenient server to host your rss feeds, schedule
the following script as a cron job at some appropriate interval:

    #!/usr/bin/perl
    use strict;
    use warnings;
    use WWW::Scrape::Mailman::RSS;
    my $feed = WWW::Scrape::Mailman::RSS->new(
       'rss_version' => '0.91',
             'debug' => 0, # try values from 1 to 5 for noisier output
       );

    my %args = (
         'info_url' => 'http://ga.greens.org/mailman/listinfo/gpga-news',
         'base_url' => 'http://ga.greens.org/pipermail/gpga-news',
        'list_name' => 'gpga-news',
         'audience' => 'Greens',
      'description' => 'News by, about and for Greens',
           'cycles' => 2,
      'output_file' => '/home/hesco/sites/news.tns.campaignfoundations.com/gpga_news_feed.html',
       'rss_output' => '/home/hesco/sites/news.tns.campaignfoundations.com/gpga_news_feed.rss',
      );

    $feed->render_feed(\%args);

    # create additional feeds for other lists here

    1;

Then on your site, set your feed aggregator to point to:
	http://news.tns.campaignfoundations.com/gpga_news_feed.rss

=head1 METHODS 

=head2 WWW::Scrape::Mailman::RSS->new( \%defaults )

Given a hashref of defaults which includes the key
'rss_version', construct and returns a $feed object, including
embedded objects for WWW::Mechanize, HTML::TableExtract,
XML::Twig and XML::RSS.  If $defaults->{'debug'} is set, you
can see debugging output; with the noise level increasing as
you increment it from 1 to 5.

=cut

sub new {
  my $class = shift;
  my $defaults = shift;
  my $self = {};

  if(!defined($defaults->{'debug'})){
    $defaults->{'debug'} = 0;
  }
  if(!defined($defaults->{'rss_version'})){
    $defaults->{'rss_version'} = '0.91';
  }
  if(!defined($defaults->{'feed_format'})){
    $defaults->{'feed_format'} = 'html';
  }
  if(!defined($defaults->{'audience'})){
    $defaults->{'audience'} = 'readers';
  }
  if(!defined($defaults->{'feed_type'})){
    $defaults->{'feed_type'} = 'updates';
  }
  if(!defined($defaults->{'server'})){
    $defaults->{'server'} = 'default';
  }

  foreach my $key (keys %{$defaults}){
    $self->{$key} = $defaults->{$key};
  }

  $self->{'agent'} = WWW::Mechanize->new();
  $self->{'te'} = HTML::TableExtract->new( headers => [ 'Archive', 'View by:', 'Downloadable version'] );
  $self->{'twig'} = XML::Twig->new( );
  $self->{'rss'} = XML::RSS->new( version => $defaults->{'rss_version'} );

  bless $self, $class;
  return $self;
}

=head2 $self->render_feed ( \%args )

Given a $feed object and a hashref of arguments, including
list_name, info_url, description, base_url, cycles and
rss_output, download, process and render as an rss feed the
most recent $args->{'cycles'} cycles of a mailman list's
public archives.

=cut

sub render_feed {
  my $self = shift;
  my $args = shift;
  print STDERR Dumper($self) if($self->{'debug'} > 4);
  print STDERR Dumper($args) if($self->{'debug'} > 3);

  $self->{'rss'}->channel(
          'title' => $args->{'list_name'},
           'link' => $args->{'info_url'},
    'description' => $args->{'description'}
  );

  my $url = $args->{'base_url'}; 
  $self->{'agent'}->get( $url );
  my $html = $self->{'agent'}->content();
  print STDERR Dumper($html) if($self->{'debug'} > 4);

  my $feed;
  $self->{'te'}->parse($html);
  my($month);
  foreach my $ts ($self->{'te'}->tables){
    my $month_count = 0;
    foreach my $row ($ts->rows){
      print STDERR 'Next row: ' . Dumper($row) if($self->{'debug'} > 2);
      push @{$self->{'cycles'}},$row->[0];
      $feed .= $self->_parse_mm_archive_cycle($args,$row->[0]);
      $month_count++;
      if($month_count >= $args->{'cycles'}){ last; }
    }
  }

  $self->{'rss'}->save( $args->{'rss_output'} );

  print "rss: $args->{'rss_output'}\n" if($self->{'debug'} > 0);
  return $feed;
}

=head2 $self->_parse_mm_archive_cycle ( \%args, '2010-September' );

Given the arguments passed to ->render_feed, plus the cycle
name (month has been tested, week and quarter have not yet
been tested), get the appropriate date.html page from a mailman
list serve's archives, parse it and use the data collected to
add items to an rss feed of the data.

=cut

sub _parse_mm_archive_cycle {
  my $self = shift;
  my $args = shift;
  my $base_url = $args->{'base_url'};
  my $cycle = shift;
  $cycle =~ s/:$//;

  my $feed;
  my $url = "$base_url/$cycle/date.html"; 
  print STDERR $url, "\n" if($self->{'debug'} > 0);
  $self->{'agent'}->get( $url );
  my $html = $self->{'agent'}->content();

  my $p = HTML::TokeParser::Simple->new( \$html );

  my @feed;
  my $list_name = $args->{'list_name'};
  my $count = 0;
  STORY: while (my $token = $p->get_tag("li")) {
    $count++;
    my $a_tag = $p->get_tag("a");
    print STDERR Dumper( \$a_tag ) if($self->{'debug'} > 3);
    my $link = $a_tag->[3];
    my $link_url = "$base_url/$cycle/" . $a_tag->[1]->{'href'};
    my $text = $p->get_trimmed_text("a");
    my $desc = '';
    if($count == 2 && $self->{'debug'} > 3){ print STDERR Dumper( \$link, \$text ); }
    if($text =~ m/Messages sorted by:/){ next STORY; }
    if($text =~ m/More info on this list/){ next STORY; }
    if($text =~ m/Archived on:/){ next STORY; }
    if($text eq '[ thread ]'){ next STORY; }
    $text =~ s,\[$list_name\] ,,;
    print STDERR "$count : $text \n" if($self->{'debug'} > 2);
    $link =~ s,HREF=",HREF="$base_url/$cycle/,;
    $feed .= $link . "$text</a>\n";
    push @feed, ({ 'title' => $text, 'link' => $link_url, 'description' => $desc });
  }

  my @feed_reversed = reverse @feed;
  print STDERR Dumper( \@feed, \@feed_reversed ) if($self->{'debug'} > 3);
  foreach my $item (@feed_reversed){
    print STDERR Dumper( $item ) if($self->{'debug'} > 3);;
    $self->{'rss'}->add_item(
          'title' => $item->{'title'},
           'link' => $item->{'link'},
    'description' => $item->{'description'}
    );
  }

  $self->{'rss'}->save($args->{'rss_output'});
  print "rss: $args->{rss_output}\n" if($self->{'debug'} > 0);

  return $feed;
}

=head1 AUTHOR

Hugh Esco, C<< <hesco at campaignfoundations.com> >>

=head1 BUGS

* First item from each cycle is missing from feed.

Please report any bugs or feature
requests to C<bug-www-scrape-mailman-rss at
rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Scrape-Mailman-RSS>.
I will be notified, and then you'll automatically be notified
of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::Scrape::Mailman::RSS 

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-Scrape-Mailman-RSS>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-Scrape-Mailman-RSS>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-Scrape-Mailman-RSS>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-Scrape-Mailman-RSS/>

=back


=head1 ACKNOWLEDGEMENTS

With appreciation to Adam Shand <adam@spack.org>, whose
mm2rss.pl script served as inspiration for refactoring a
private module CF::mmFeedParser which I wrote years ago.
His code also introduced me to XML::RSS with which I had not
previously been familiar.

=head1 COPYRIGHT & LICENSE

Copyright 2010-2011 Hugh Esco.

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; version 2 dated
June, 1991 or at your option any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

A copy of the GNU General Public License is available in the
source tree; if not, write to the Free Software Foundation,
Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.


=cut

1; # End of WWW::Scrape::Mailman::RSS 
