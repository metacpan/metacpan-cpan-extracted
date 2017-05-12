#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010, 2013 Kevin Ryde
#
# This file is part of RSS2Leafnode.
#
# RSS2Leafnode is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# RSS2Leafnode is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with RSS2Leafnode.  If not, see <http://www.gnu.org/licenses/>.

use 5.010;
use strict;
use warnings;
use FindBin;
use Data::Dumper;

my $rdf = 'http://www.w3.org/1999/02/22-rdf-syntax-ns#';
my $atom = 'http://www.w3.org/2005/Atom';

#my $filename = "$FindBin::Bin/" . "../samp/adelaide";
#my $filename = "$FindBin::Bin/" . "../samp/1226789508";
#my $filename = "$FindBin::Bin/" . "../samp/atom03.xml";
#my $filename = "$FindBin::Bin/" . "../samp/fondantfancies.atom";
#my $filename = "$FindBin::Bin/" . "../samp/dwn.en.rdf.1";
#my $filename = "$FindBin::Bin/" . "../samp/dc-sample.rdf";
#my $filename = '/so/plagger/Plagger-0.7.17/t/samples/atom10-example.xml';
#my $filename = '/tmp/tv_epg.xml';
#my $filename = "$FindBin::Bin/" . "../samp/andrew-weil.rss";
# my $filename = "$FindBin::Bin/" . "../samp/cooperhewitt.rss";
#my $filename = "$FindBin::Bin/" . "../samp/abc-podcast-sci.xml";
my $filename = '/tmp/feed.php';

{
  require XML::FeedPP;
  my $feed = XML::FeedPP->new($filename);
  print "Title: ", $feed->title(), "\n";
  print "Date: ", $feed->pubDate(), "\n";
  foreach my $item ( $feed->get_item() ) {
    print "URL: ", $item->link(), "\n";
    print "Title: ", $item->title(), "\n";
  }
  exit 0;
}
{
  require XML::TreePP;
  my $tpp = XML::TreePP->new();
  my $tree = $tpp->parsefile($filename);
  print "Title: ", $tree->{"rdf:RDF"}->{item}->[0]->{title}, "\n";
  print "URL:   ", $tree->{"rdf:RDF"}->{item}->[0]->{link}, "\n";
  exit 0;
}

{
  require XML::Twig;
  sub elt_to_email {
    my ($elt) = @_;
    return unless defined $elt;
    my $email = $elt->first_child_text('email');
    my $ret = join (' ',
                    non_empty ($elt->text),
                    non_empty ($elt->first_child_text('name')),
                    (is_non_empty($email) ? "<$email>" : ()));
    return unless is_non_empty($ret);

    # eg.     "Rael Dornfest (mailto:rael@oreilly.com)"
    # becomes "Rael Dornfest <rael@oreilly.com>"
    $ret =~ s/\(mailto:(.*)\)/<$1>/;

    return $ret;
  }

  my $twig = XML::Twig->new
    (map_xmlns => {$rdf => 'myrdf',
                   'http://purl.org/dc/elements/1.1/' => 'dc',
                   'http://www.w3.org/2005/Atom' => 'atom',
                  });
  $twig->safe_parsefile($filename);

  # print $twig->base,"\n";
  # print $twig->root->base,"\n";


  my ($elem) = $twig->root->get_xpath('/rss/channel/item/image');
  print $elem->text;
  exit 0;

  ($elem) = $twig->root->get_xpath('/rss/channel/item/description');
  # $elem->print;
  $,= ' ';
  foreach ($elem->children) {
    print $_->tag," -- ", ($_->is_text ? $_->text : $_->sprint), "\n";
  }
  exit 0;

  my $err = $@;
  print "charset ", $twig->encoding//'unspec', "\n";
  if ($err) {
    print $err;
    exit 1;
  }

  my $toplevel = $twig->root;
  print "toplevel ",ref($toplevel)," ",$toplevel->tag,"\n";

  foreach my $elt ($toplevel->descendants) {
    if ($elt->tag =~ /^atom:(.*)/) {
      $elt->set_tag($1);
    }
  }

  { local $,=' ';
    print " ",(map {$_->tag} $toplevel->children),"\n";
  }

  my $ttl = $toplevel->first_descendant('ttl');
  print "ttl $ttl\n";

  my @items = ($toplevel->descendants('item'),   # RSS/RDF
               $toplevel->descendants('entry'),  # Atom
               $toplevel->descendants('myatom:entry'));
  print scalar(@items)," items\n";

  foreach my $item (@items) {
    print "item\n";

    my $channel = $item->parent;
    print "  channel $channel ",$channel->tag,"\n";

    my $title = (non_empty ($item->first_child_text('title'))
                 // non_empty ($item->first_child_text('dc:subject')));
    print "  title ",$title,"\n";

    my $author = (# from the item
                  elt_to_email ($item->first_child('author'))
                  // elt_to_email ($item   ->first_child('dc:creator'))
                  // elt_to_email ($channel->first_child('author'))

                  // elt_to_email ($channel->first_child('managingEditor'))
                  // elt_to_email ($item   ->first_child('dc:publisher'))
                  // elt_to_email ($channel->first_child('dc:publisher'))
                  // elt_to_email ($channel->first_child('webMaster'))
                  # scraping the bottom of the barrel ...
                  // non_empty($channel->first_child_text('title'))
                 );
    print "  author ",$author,"\n";

    my $guid = $item->first_child('guid');
    my $isPermaLink = ($guid
                       && lc($guid->att('isPermaLink') // 'true') eq 'true');
    $guid = ($guid && $guid->text);
    print "  guid ",$guid," $isPermaLink\n";

    my $link = $item->first_child('link');
    if ($link) {
      $link = ($link->att('href')  # Atom
               // $link->text);    # RSS
    }
    print "  link ",$link,"\n";

    my $body;
    my $body_type = 'text/html';
    if (my $content = $item->first_child('content')) { # Atom
      $body = $content->text;
      if (defined ($body_type = $content->att('type'))) {
        $body_type = "text/$body_type";
      } else {
        $body_type = "text/plain";
      }
    } else { # RSS
      #       sub first_child_string
      #         my ($elt, $tag) = @_;
      #         my $child = $elt->first_child($elt) // return;
      #         return $child->string;
      #       }
      # $body = (non_empty ($item->first_child_text ('description'))
      #                // non_empty ($item->first_child_text('dc:description')));
      $body = $item->first_child('description')->xml_string;

    }
    print "  body  $body_type $body\n";


    #   my @channels = ($toplevel->children('channel'),  # RSS
    #                   $twig->children('feed'));        # Atom
    #   print scalar(@channels)," channels\n";
    #   foreach my $channel (@channels) {

    #     my @others = $channel->children('!item');
    #     foreach my $other (@others) {
    #       print " other $other ",$other->tag,"\n";
    #     }

    #     if (my $items = $channel->first_child('items')) {
    #       push @items, $toplevel->children('item');
    #
    #       #       foreach my $under ($items->children) {
    #       #         print "  under $under ",$under->tag,"\n";
    #       #       }
    #       #       my $seq = $items->first_child('myrdf:Seq');
    #       #       foreach my $li ($seq->children('myrdf:li')) {
    #       #         print " li $li ",$li->tag," ",$li->{'att'}->{'myrdf:resource'},"\n";
    #       #         my $res = $li->{'att'}->{'myrdf:resource'};
    #       #         # $res =~ s/([#])/\\$1/g;
    #       #         my @items = $toplevel->children("item[\@myrdf:about=\"$res\"]");
    #       #         print "items ",@items,"\n";
    #       #         exit 0;
    #       #       }
    #     }

  }
  #$twig->print;
  exit 0;

}

{
  require URI;
  my $start = URI->new('http://foo.com/start/');
  my $uri = URI->new ('rela/tive/',$start);
  print $uri->scheme,"\n";
  print $uri,"\n";
  print URI->new_abs('subdir',$uri),"\n";
  exit 0;
}

{
  require URI;
  my $uri=URI->new('tag:freeke.org,2009:/tech/computers/os/linux/netbooking');
  print ref($uri),"\n";
  print "scheme ",$uri->scheme,"\n";
  print "host ",$uri->can('host'),"\n";
  print "authority ",$uri->authority,"\n";
  print $uri->path,"\n";
  print $uri->path_query,"\n";
  exit 0;
}

{
  require XML::LibXML;
  require XML::LibXML::XPathContext;


  my $parser = XML::LibXML->new;
  my $dom = XML::LibXML->load_xml (location => $filename);
  # print $dom->{'rss'}->toString;

  #   $dom->documentElement->setNamespace
  #     (dc => 'http://purl.org/dc/elements/1.1/');

  my $xc = XML::LibXML::XPathContext->new;
  $xc->registerNs(dc => 'http://purl.org/dc/elements/1.1/');
  $xc->registerNs(rdf => $rdf);
  $xc->registerNs(atom => $atom);

  my @toplevels = $dom->findnodes('feed');
  @toplevels = $dom->childNodes;
  print scalar(@toplevels)," toplevels\n";

  foreach my $toplevel (@toplevels) {
    print "top $toplevel ",$toplevel->nodeName,"\n";
    print ((map{$_->nodeName . ' '} $toplevel->childNodes),"\n");

    $xc->setContextNode($toplevel);
    my @items = ($xc->findnodes('//item|//atom:entry'),
                 # $xc->findnodes('.//entry')
                );
    #my @items = $xc->findnodes('/rdf:RDF/item',$toplevel);
    # my @items = $toplevel->findnodes('item');
    # $toplevel->childNodes
    #$xc->findnodes('/./item',$toplevel)
    # $xc->findnodes('item or entry or myrdf:item',$toplevel)

    print scalar(@items)," items\n";
    foreach my $item (@items) {
      print " item ",$item->nodeName,"\n";

      my $channel = $item->parentNode;
      print "  channel ",$channel->nodeName,"\n";

      my $datelist = $xc->find('dc:date',$toplevel);
      print "  dc:dates ", $datelist->size,
        " ", Data::Dumper->new([\$datelist],['datelist'])
          ->Indent(1)->Sortkeys(1)->Useqq(1)->Dump;
      #print "  dc:date ",$datelist->string_value,"\n";


      my $title = $xc->findnodes('title|atom:title',$item);
      #       print "   title ", Data::Dumper->new([\$title],['title'])
      #         ->Indent(0)->Sortkeys(1)->Useqq(1)->Dump,"\n";
      print "   title ",$title->string_value,"\n";

      my @links = $item->findnodes('link');
      foreach my $link (@links) {
        $link = ($link->getAttribute('href')  # Atom
                 // $link->textContent);      # RSS
        print "  link ",$link,"\n";
      }

      print "   desc  ",
        $item->find('xdescription')->string_value,
          "\n";

      my ($body, $body_type);
      if (my ($desc)
          = $xc->findnodes('description|dc:description|atom:content',$item)) {
        $body = $desc->textContent;
        $body_type = $desc->getAttribute('type');
        if (defined $body_type) { $body_type = "text/$body_type"; }
      }
      $body_type //= 'text/html';
      if ($body_type eq 'text/xhtml') { $body_type = 'text/html'; }
      print "  body  $body_type $body\n";



      #       foreach my $item ($xc->findnodes('rdf:item', $channel)
      #                         # 'item'
      #                        ) {      }

      #       my @nodes = $channel->findnodes('item');
      #       print "  items ", Data::Dumper->new([\@nodes],['nodes'])
      #         ->Indent(1)->Sortkeys(1)->Useqq(1)->Dump;
    }
  }

  exit 0;

  # XML::RSS::LibXML
  # XML::LibXML::NodeList
  #         $item->nodeName eq 'item' or next;
  #       $channel->nodeName eq 'channel' or next;
}

{
  {
    package MySAX;
    use base 'XML::SAX::Base';
    sub new {
      my ($class) = @_;
      return bless { channel_depth => -1,
                     item_depth => -1 }, $class;
    }
    sub start_element {
      my ($self, $elem) = @_;
      print Data::Dumper->new([$elem],['elem'])
        ->Indent(1)->Sortkeys(1)->Useqq(1)->Dump;

      my $depth = ++$self->{'depth'};
      my $name = $elem->{'Name'};
      if ($name eq 'channel') {
        $self->{'channel_depth'} = $depth;
        push @{$self->{"channel_array"}}, ($self->{'channel'} = {});

      } elsif ($name eq 'item') {
        $self->{'item_depth'} = $depth;
        push @{$self->{'channel'}->{"item_array"}}, ($self->{'item'} = {});

      } else {
        my $target = ($depth == $self->{'channel_depth'} ? $self->{'channel'}
                      : $depth == $self->{'item_depth'}  ? $self->{'item'}
                      : $self);
        push @{$target->{'element_array'}}, $elem;
      }
    }
    sub end_element {
      my ($self, $doc) = @_;
      my $depth = --$self->{'depth'};
      if ($depth == $self->{'item_depth'}) {
        delete $self->{'item'};
        $self->{'item_depth'} = -1;
      }
      if ($depth == $self->{'channel_depth'}) {
        delete $self->{'channel'};
        $self->{'channel_depth'} = -1;
      }
    }
    sub end_document {
      my ($self, $doc) = @_;
      print "done\n";
    }
  }

  require XML::SAX::ParserFactory;
  my $feed = MySAX->new;
  my $parser = XML::SAX::ParserFactory->parser (Handler => $feed);
  $parser->parse_file($filename);
  print Data::Dumper->new([$feed],['feed'])
    ->Indent(1)->Sortkeys(1)->Useqq(1)->Dump;
  exit 0;
}

{
  require XML::Parser;
  my $parser = XML::Parser->new (Style => 'Tree');
  my $tree = $parser->parsefile($filename);
  print Data::Dumper->new([$tree],['tree'])->Indent(1)->Sortkeys(1)->Useqq(1)->Dump;
  exit 0;
}


sub join_non_empty {
  my $sep = shift;
  return join ($sep, grep {is_non_empty($_)} @_);
}

sub is_non_empty {
  my ($str) = @_;
  return (defined $str && $str ne '');
}
sub non_empty {
  my ($str) = @_;
  return (is_non_empty($str) ? $str : ());
}
