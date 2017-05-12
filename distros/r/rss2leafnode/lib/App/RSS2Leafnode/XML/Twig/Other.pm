# Copyright 2007, 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015 Kevin Ryde
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

package App::RSS2Leafnode::XML::Twig::Other;
use 5.004;
use strict;
use Exporter;
use vars '$VERSION', '@ISA', '@EXPORT_OK';

$VERSION = 79;
@ISA = ('Exporter');
@EXPORT_OK = (qw(elt_is_empty
                 elt_tree_strip_prefix
               ));

# XML::Twig 

sub elt_is_empty {
  my ($elt) = @_;
  return ($elt->has_no_atts
          && ! $elt->has_child
          && $elt->text_only =~ /^\s*$/);
}

sub elt_tree_strip_prefix {
  my ($elt, $prefix) = @_;
  foreach my $child ($elt->descendants_or_self(qr/^\Q$prefix\E:/)) {
    $child->set_tag ($child->local_name);
  }
}

# Return a URI object for string $url.
# If $url is relative then it's resolved against xml:base, if available, to
# make it absolute.
# If $url is undef then return undef, which is handy if passing a possibly
# attribute like $elt->att('href').
# The feed toplevel has an xml:base set to the feed location if no other
# value, so elt_xml_based_uri() ends up relative to the feed location if no
# other xml:base.
#
sub elt_xml_based_uri {
  my ($elt, $url_str) = @_;
  if (! defined $url_str) { return undef; }
  require URI;
  my $uri = URI->new ($url_str);
  if (my $base = elt_xml_base ($elt)) {
    return $uri->abs ($base);
  } else {
    return $uri;
  }
}

# Return a URI object for the xml:base applying to $elt, or undef.
sub elt_xml_base {
  my ($elt) = @_;
  my @relative;
  for ( ; $elt; $elt = $elt->parent) {
    next if ! defined (my $base = $elt->att('xml:base'));
    $base = URI->new($base);
    if (defined $base->scheme) {
      # an absolute URL
      while (@relative) {
        $base = (pop @relative)->abs($base);
      }
      return $base;
    } else {
      # a relative path
      push @relative, $base;
    }
  }
  # oops, no base, only relative paths
  return undef;
}


1;
__END__
