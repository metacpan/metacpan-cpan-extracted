#####
#
# $Id: unpop_tables.pl,v 1.11 2001/07/25 00:31:14 trostler Exp $
#
# COPYRIGHT AND LICENSE
# Copyright (c) 2001, Juniper Networks, Inc.  
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

#####
#
# 'Unpopulate' DB tables back into XML
#
#####

use strict;
use URI::Escape;
use DBIx::Recordset;
use Data::Dumper;

use common;
use vars qw(*real_names);

# Set up DBIx::Recordset to ingore warnings about MySQL
$DBIx::Recordset::FetchsizeWarn = 0;

# Get root table name
my $top_table = shift;

# Get primary key value
my $pkey = shift;

# Get 'real' element names hash
&set_up_real_names_hash(DSN);

# Hash for in-memory traversal of DB
my %nodes;

# Create in-memory structure of what's in the DB for eventual output
&un_populate_table($top_table,$pkey,\%{$nodes{$top_table}});

# Okay - the whole enchilada is now in memory in %nodes
#   dump that bad boy into XML... output goes to STDOUT
&dump_xml_node($top_table,$nodes{$top_table},0);

##
# Now we've got the in-memory data structure - output it in XML
##
sub dump_xml_node {
    my($head_name,$head,$tab) = @_;

    my $real_name = &get_xml_name($real_names,$head_name);

    # Make it pretty
    print TAB x $tab;

    # Element name
    print "<$real_name";

    # Dump attributes if there are any of 'em
    # Just blow thru 'em all & dump 'em in 'key="value"' form
    if (my $attr_ref = $head->{attribute}) {
            foreach my $attr_key (keys %{$attr_ref}) {
                my $real_attr_name = &get_xml_name($real_names,$attr_key);
                print " $real_attr_name=\"",$attr_ref->{$attr_key},"\"";
            }
    }

    print ">";

    # Keep track if we printed any text in this element
    my $printed_value = 0;

    # Go thru each sub-element...
    foreach my $key (keys %$head) {
        # Already did these
        next if ($key eq 'attribute');

        if ($key eq 'value') {
            my $val = $head->{$key} if (defined $head->{$key});
            if (defined $val && $val ne 'present') {
                # Escape delicate values - text within tags
                print uri_escape($val,"&<>");
                $printed_value++;
            }
            next;
        }

        print "\n";

        if ($key =~ /^\d+$/) {
            # 1:N relationship
            # We need to 'skip' over the number & dump the references within...
            foreach my $multiple_node (keys %{$head->{$key}}) {
                &dump_xml_node($multiple_node,$head->{$key}{$multiple_node},$tab+1);
            }
        }
        else {
            # Plain ond 1:N relationship
            &dump_xml_node($key,$head->{$key},$tab+1);
        }
    }

    # Output closing tag
    print TAB x $tab unless ($printed_value);
    print "</$real_name>\n";
}
