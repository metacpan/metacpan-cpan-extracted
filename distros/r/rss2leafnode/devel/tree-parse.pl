# Copyright 2012 Kevin Ryde
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


# re-parse on error
# rss_newest_only must look at all dates




sub rss_process_str {
  my ($self, $xml) = @_;
  ### rss_process_str() ...

  # default "discard_spaces" chucks leading and trailing space on content,
  # which is usually a good thing
  #
  require XML::Twig;
  XML::Twig->VERSION('3.34'); # for att_exists()
  my $twig = XML::Twig->new (map_xmlns => $map_xmlns,
                             pretty_print => 'wrapped',
                             twig_handlers => { item => sub { $self->process_item(\&_process_item,
);
  $twig->safe_parse ($xml);
  my $err = $@;
  ### $err

  # Try to fix bad non-ascii chars by putting it through Encode::from_to().
  # Encode::FB_DEFAULT substitutes U+FFFD when going to unicode, or question
  # mark "?" going to non-unicode.  Mozilla does some sort of similar
  # liberal byte interpretation so as to at least display something from a
  # dodgy feed.
  #
  if ($err && $err =~ /not well-formed \(invalid token\) at (line \d+, column \d+, byte (\d+))/) {
    my $where = $1;
    my $byte = ord(substr($xml,$2,1));
    if ($byte >= 128) {
      my $charset = $twig->encoding // 'utf-8';
      $self->verbose (1, sprintf ("parse error, attempt re-code $charset for byte 0x%02X\n", $byte));
      require Encode;
      my $recoded_xml = $xml;
      Encode::from_to($recoded_xml, $charset, $charset, Encode::FB_DEFAULT());

      $twig = XML::Twig->new (map_xmlns => $map_xmlns);
      if ($twig->safe_parse ($recoded_xml)) {
        $twig->root->set_att('rss2leafnode:fixup',
                             "Recoded bad bytes to charset $charset");
        print __x("Feed {url}\n  recoded {charset} to parse, expect substitutions for bad non-ascii\n  ({where})\n",
                  url     => $self->{'uri'},
                  charset => $charset,
                  where   => $where);
        undef $err;
      }
    }
  }

  # Or attempt to put it through XML::Liberal, if available.
  #
  if ($err) {
    my $liberal_xml = $self->xml_liberal_correction($xml);
    if (defined $liberal_xml) {
      ### reparse xml liberal fixup with twig ...
      $twig = XML::Twig->new (map_xmlns => $map_xmlns);
      if ($twig->safe_parse ($liberal_xml)) {
        ### now ok ...
        $err = Text::Trim::trim($err);
        $twig->root->set_att('rss2leafnode:fixup',
                             "XML::Liberal fixed: {error}",
                             error => $err);
        print __x("Feed {url}\n  parse error: {error}\n  continuing with repairs by XML::Liberal\n",
                  url   => $self->{'uri'},
                  error => $err);
        undef $err;
      }
    }
    ### now err: $err
  }

  if ($err) {
    # XML::Parser seems to stick some spurious leading whitespace on the error
    $err = Text::Trim::trim($err);

    $self->verbose (1, __x("Parse error on URL {url}\n{error}",
                           url   => $self->{'uri'},
                           error => $err));
    return (undef, $err);
  }

  # Strip any explicit "rss:" or "atom:" namespace down to bare part.
  # Should be unambiguous and is easier than giving tag names both with and
  # without the namespace.  Undocumented set_ns_as_default() might do this
  # ... or might not.
  #
  my $root = $twig->root;
  App::RSS2Leafnode::XML::Twig::Other::elt_tree_strip_prefix ($root, 'atom');
  App::RSS2Leafnode::XML::Twig::Other::elt_tree_strip_prefix ($root, 'rss');

  # somehow map_xmlns mangles default attributes like "decimals=...", prefer
  # to see them without rss: or atom: -- maybe
  #   foreach my $child ($root->descendants_or_self) {
  #     foreach my $attname ($child->att_names) {
  #       if ($attname =~ /^(atom|rss):(.*)/) {
  #         $child->change_att_name($attname, $2);
  #       }
  #     }
  #   }

  ### add xml base
  if (defined $self->{'uri'} && ! $root->att_exists('xml:base')) {
    $root->set_att ('xml:base', $self->{'uri'});
  }

  ### success
  return ($twig, undef);
}




