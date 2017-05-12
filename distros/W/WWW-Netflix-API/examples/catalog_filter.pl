#!/usr/bin/perl

####################################
# Example usage of XML::Twig to filter a full catalog.xml file
####################################

use strict;
use warnings;
use XML::Twig;
$|=1;
use Data::Dumper;

my $t = XML::Twig->new(
#  twig_handlers => {
#	title_index_item => \&title_index_item,
#  },
  keep_spaces => 1,
  twig_print_outside_roots => 1,
  twig_roots => {
	title_index_item => \&title_index_item,
  },
);
$t->parsefile( '../catalog.xml');
$t->purge;

sub url2id {
  $_[0] =~ m#/(\d+)# ? $1 : undef
}

sub title_index_item {
  my( $t, $x)= @_;
  my $formats = $x->first_child('delivery_formats');
  foreach my $avail ( $formats->children('availability') ){
    no warnings 'uninitialized';
    my $instant = scalar grep { $_->atts->{term} eq 'instant' && $_->atts->{status} ne 'deprecated' } $avail->children('category');
    next unless $instant;

#    print Dumper {
#	( map { $_ => $x->first_child_text($_) } qw/ release_year title updated / ),
#	href => $x->first_child_text('id'),
#	id => url2id( $x->first_child_text('id') ),
#	%{$avail->atts},
#    };
    $x->print;
    return;
  }
  $x->purge;
}

__END__

<id>http://api.netflix.com/catalog/titles/movies/512381</id>
<delivery_formats>
  <availability available_from="1257494400" available_until="1268208000">
  <category scheme="http://api.netflix.com/catalog/titles/formats" label="instant" term="instant" status="deprecated"></category>
  <category scheme="http://api.netflix.com/categories/title_formats" label="instant" term="instant"></category>
  </availability>
</delivery_formats>

