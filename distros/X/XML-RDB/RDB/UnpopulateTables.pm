#####
#
# $Id: UnpopulateTables.pm,v 1.2 2003/04/19 04:17:48 trostler Exp $
#
# COPYRIGHT AND LICENSE
# Copyright (c) 2001, 2003, Juniper Networks, Inc.  
# All rights reserved.
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
# 	1.	Redistributions of source code must retain the above
# copyright notice, this list of conditions and the following
# disclaimer. 
# 	2.	Redistributions in binary form must reproduce the above
# copyright notice, this list of conditions and the following disclaimer
# in the documentation and/or other materials provided with the
# distribution. 
# 	3.	The name of the copyright owner may not be used to 
# endorse or promote products derived from this software without specific 
# prior written permission. 
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT,
# INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
# STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING
# IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
#
#####

package XML::RDB::UnpopulateTables;
use vars qw($VERSION);
$VERSION = '1.2';

#####
#
# 'Unpopulate' DB tables back into XML
#
#####

use strict;
use URI::Escape;
use DBIx::Recordset;

sub new {
  my ($class, $rdb, $outfile) = @_;

  # set up FH
  my $fh = new IO::File;
  if ($outfile) {
    $fh->open("> $outfile") || die "$!";
  } else {
    $fh->fdopen(fileno(STDOUT), 'w') || die "$!";
  }

  my $self = bless { 
    rdb => $rdb,
    nodes => {},  # Hash for in-memory traversal of DB
    fh => $fh,
  }, $class;

  $self;
}

sub DESTROY { my $self = shift; $self->{fh}->close };

sub go {
  my ($self,$root_table, $pkey) = @_;
  my $one_to_n = $self->{rdb}->get_one_to_n_db;
  $self->{_element_names} = $self->{rdb}->get_real_element_names_db;

  # Create in-memory structure of what's in the DB for eventual output
  $self->{rdb}->un_populate_table($one_to_n, $root_table, $pkey, 
                                    $self->{nodes});

  # Okay - the whole enchilada is now in memory in %nodes
  #   dump that bad boy into XML... output goes to STDOUT
  $self->_dump_xml_node($root_table, $self->{nodes}, 0);
  return $self;
}

##
# Now we've got the in-memory data structure - output it in XML
##
sub _dump_xml_node {
    # NOTE : Replaced the recursive sub loop with goto's & lifo @stack,
    my($self, $head_name, $head, $tab) = @_;
    my (@stack, $keys, $key, $printed_value, $real_name, $head_keys );
    my $rdb = $self->{rdb};
    my $fh = $self->{fh};

    TOP_XML:
    ( $keys, $key, $printed_value, $real_name, $head_keys ) = 
        ( [ keys %$head ], undef,  0, $self->{_element_names}{$head_name}, undef );
    
    # Make it pretty
    print $fh $rdb->{TAB} x $tab, '<', $real_name;

    # Dump attributes if there are any of 'em
    # Just blow thru 'em all & dump 'em in 'key="value"' form
    if (my $attr_ref = $head->{attribute}) {
      foreach my $attr_key (keys %{$attr_ref}) {
        my $real_attr_name = $self->{_element_names}{$attr_key};
        print $fh " $real_attr_name=\"",$attr_ref->{$attr_key},"\"";
      }
    }
    print $fh '>';

    # Keep track if we printed any text in this element
    
    # Go thru each sub-element...
    while (scalar(@{$keys})) {
      $key = shift @{$keys};

      # Already did these
      next if ($key eq 'attribute');

      if ($key eq 'value') {
        my $val = $head->{$key} if (defined $head->{$key});
        if (defined $val && $val ne 'present') {
            # Escape delicate values - text within tags
            print $fh uri_escape($val, "&<>");
            $printed_value++;
        }
        next;
      }

      print $fh "\n";

      if ($key =~ /^\d+$/o) {
        # 1:N relationship
        $head_keys = [ keys %{$head->{$key}} ];

        # We need to 'skip' over the number & dump the references within...
        while (scalar(@{$head_keys})) { 
          my $multiple_node = shift @{$head_keys};
#          $self->_dump_xml_node($multiple_node, $head->{$key}{$multiple_node}, $tab+1);

          push(@stack, [ $head_name, $head, $keys, $key, 
                         $tab, $printed_value, $real_name, $head_keys ]);
          ($head_name, $head, $tab ) = ($multiple_node, 
                                        $head->{$key}{$multiple_node}, 
                                        $tab+1);
          goto TOP_XML;
          TOPLESS_XML_Multi:
        }
      }
      else {
        # Plain ond 1:N relationship
#        $self->_dump_xml_node($key, $head->{$key}, $tab+1);

        push(@stack, [ $head_name, $head, $keys, $key, $tab, 
                       $printed_value, $real_name, $head_keys  ]);
        ($head_name, $head, $tab ) = ($key, $head->{$key}, $tab+1);
        goto TOP_XML;
        TOPLESS_XML_Relate:
      }
    }

    # Output closing tag
    print $fh $rdb->{TAB} x $tab unless ($printed_value);
    print $fh "</$real_name>\n";

  if (scalar(@stack) > 0) {
    ($head_name, $head, $keys, $key, $tab, $printed_value, 
     $real_name, $head_keys ) = @{pop(@stack)};

    if (ref $head_keys) {  goto TOPLESS_XML_Multi;  }
                   else {  goto TOPLESS_XML_Relate; }
  }
    
}


# sub _dump_xml_node {
#     my($self, $head_name, $head, $tab) = @_;
#     my $rdb = $self->{rdb};
#     my $fh = $self->{fh};
# 
#     
#     my $real_name = $self->{_element_names}{$head_name};
# 
#     # Make it pretty
#     print $fh $rdb->{TAB} x $tab;
# 
#     # Element name
#     print $fh "<$real_name";
# 
#     # Dump attributes if there are any of 'em
#     # Just blow thru 'em all & dump 'em in 'key="value"' form
#     if (my $attr_ref = $head->{attribute}) {
#       foreach my $attr_key (keys %{$attr_ref}) {
#         my $real_attr_name = $self->{_element_names}{$attr_key};
#         print $fh " $real_attr_name=\"",$attr_ref->{$attr_key},"\"";
#       }
#     }
# 
#     print $fh ">";
# 
#     # Keep track if we printed any text in this element
#     my $printed_value = 0;
# 
#     # Go thru each sub-element...
#     foreach my $key (keys %$head) {
#       # Already did these
#       next if ($key eq 'attribute');
# 
#       if ($key eq 'value') {
#         my $val = $head->{$key} if (defined $head->{$key});
#         if (defined $val && $val ne 'present') {
#             # Escape delicate values - text within tags
#             print $fh uri_escape($val, "&<>");
#             $printed_value++;
#         }
#         next;
#       }
# 
#       print $fh "\n";
# 
#       if ($key =~ /^\d+$/) {
#         # 1:N relationship
#         # We need to 'skip' over the number & dump the references within...
#         foreach my $multiple_node (keys %{$head->{$key}}) {
#           $self->_dump_xml_node($multiple_node, $head->{$key}{$multiple_node}, $tab+1);
#         }
#       }
#       else {
#         # Plain ond 1:N relationship
#         $self->_dump_xml_node($key, $head->{$key}, $tab+1);
#       }
#     }
# 
#     # Output closing tag
#     print $fh $rdb->{TAB} x $tab unless ($printed_value);
#     print $fh "</$real_name>\n";
# }

1;
