#!/usr/bin/perl

package OSGi::Osgish::Command::Service;
use strict;
use vars qw(@ISA);
use Term::ANSIColor qw(:constants);
use Data::Dumper;

@ISA = qw(OSGi::Osgish::Command);

=head1 NAME 

OSGi::Osgish::Command::Service - Service related commands

=head1 DESCRIPTION

=head1 COMMANDS

=over

=cut 



sub name { "service" }

sub top_commands {
    my $self = shift;
    return $self->agent ? $self->commands : {};
}

# Commands in context "service"
sub commands {
    my $self = shift;
    my $cmds = $self->sub_commands;
    return {
            "service" => { 
                          desc => "Service related operations",
                          proc => $self->push_on_stack("service",$cmds),
                          cmds => $cmds,
                          doc => <<EOT
Enter the service menu.
EOT
                         },
            "s" => { alias => "service", exclude_from_completion => 1},
            "serv" => { alias => "service", exclude_from_completion => 1}
           };
}

sub sub_commands {
    my $self = shift;
    return 
        { 
         "ls" => { 
                  desc => "List all services",
                  proc => $self->cmd_list,
                  args => $self->complete->services(no_ids => 1),
                  doc => <<EOT

ls [-u <using>] [-b <bundle>] [<service id>|<object class>]

List all services or, when a single service id is given, print
details of this service. As argument a object class can be given
as well (with optional wildcards).

Options:

  -u <using>  : List all services which are used by bundle <using>
  -b <bundle> : List all services provided by bundle <bundle>
EOT
                 },
#         "bls" => { 
#                   desc => "List bundles",
#                   proc => \&cmd_bundle_list,
#                   args => sub { &complete_bundles(@_,no_ids => 1) }                      
#                  },
        };    
}


# =================================================================================================== 

sub cmd_list { 
    my $self = shift;
    return sub {
        my $osgish = $self->osgish;
        my $osgi = $osgish->agent;
        print "Not connected to a server\n" and return unless $osgi;
        my $services = $osgi->services;
        my ($opts,@filters) = $self->extract_command_options(["u=s","b=s"],@_);
        
        my $filtered_services = $self->_filter_services($services,$opts,@filters);
        return unless @$filtered_services;
        if (@$filtered_services == 1) {
            $self->print_service_info($filtered_services->[0],$opts);
            return;
        }
        my $text = sprintf("%4.4s  %-62.62s  %5.5s | %s\n","Id","Classes","Bd-Id","Using bundles");
        $text .= "-" x 76 . "+" . "-" x 24 . "\n";
        my $nr = 0;
        for my $s (sort { $a->{Identifier} <=> $b->{Identifier} } @{$filtered_services}) {
            my $id = $s->{Identifier};
            my ($c_id,$c_interf,$c_using,$r) = $osgish->color("service_id","service_interface","bundle_id",RESET);
            my $using_bundles = $s->{UsingBundles} || [];
            my $using = $using_bundles ? join (", ",sort { $a <=> $b } @$using_bundles) : "";
            my $bundle_id = $s->{BundleIdentifier};
            my $classes = $s->{objectClass};
            $text .= sprintf "%s%4d%s  %s%-65.65s%s %s%3d%s | %s\n",$c_id,$id,$r,$c_interf,$self->trim_string($classes->[0],65),$r,$c_using,$bundle_id,$r,$using;
            for my $i (1 .. $#$classes) {
                $text .= sprintf "      %s%-69.69s%s |\n",$c_interf,$self->trim_string($classes->[$i],69),$r;
            }
            $nr++;
        }
        $self->print_paged($text,$nr);
    }
}

sub print_service_info {
    my $self = shift;
    my $service = shift;
    my $opts = shift;
    my $agent = $self->agent;
    my $osgish = $self->osgish;

    my $id = $service->{Identifier};
    my $bundle_id = $service->{BundleIdentifier};
    my $bundle_using = $service->{UsingBundles};
    my $classes = $service->{objectClass};
    
    my ($c_id,$c_class,$c_bid,$c_bversion,$c_prop_val,$c_prop_key,$c_reset) = 
      $osgish->color("service_id","service_interface","bundle_id","bundle_version","header_value","header_name",RESET);    

    my %props = 
      map { $_->{Key} => { val => $_->{Value}, type => $_->{Type} }  }
        grep { $_->{Key} !~ /^(objectClass|service\.id)$/ }
          values %{$service->{Properties}};
    my $ret = "";
    #$ret .= sprintf("%-14.14s %s\n","Id:",$c_id . $id . $c_reset);
    $ret .= sprintf("%-14.14s %s (%s)\n","Bundle:",$c_bid . $agent->bundle_name($bundle_id,use_cached => 1) . $c_reset,$bundle_id);
    if ($bundle_using && @$bundle_using) {
        my $label = "Used by:";
        for my $u (@$bundle_using) {
            $ret .= sprintf("%-14.14s %s (%s)\n",$label,$c_bid . $agent->bundle_name($u,use_cached => 1) . $c_reset,$u);
            $label = "";
        }
    }
    if ($classes && @$classes) {
        my $label = "Classes:";
        for my $c (sort @$classes) {
            $ret .= sprintf("%-14.14s %s\n",$label,$c_class . $c . $c_reset);
            $label = "";
        }
    }
    if (%props) {
        my $label = "Properties:";
        for my $k (sort keys %props) {
            $ret .= sprintf("%-14.14s %s = %s\n",$label,$c_prop_key . $k . $c_reset,$c_prop_val . $props{$k}->{val} . $c_reset);
            $label = "";
        }
    }
    $self->print_paged($ret);
}

# Filter services according to one or more criteria
sub _filter_services {
    my $self = shift;
    my ($services,$opts,@filters) = @_;
    my %found = ();
    my $rest = [values %$services];
    my $filtered = undef;
    if (defined($opts->{u})) {
        die "No numeric bundle-id ",$opts->{u} unless $opts->{u} =~ /^\d+$/;
        for my $s (@$rest) {
            if (grep { $_ == $opts->{u} } @{$s->{UsingBundles}}) {
                $found{$s->{Identifier}} = $s;
            } 
        }
        $filtered = 1;
        $rest = [values %found];
    } 
    if ($opts->{b}) {
        die "No numeric bundle-id ",$opts->{b} unless $opts->{b} =~ /^\d+$/;
        for my $s (@$rest) {
            if ($s->{BundleIdentifier} == $opts->{b}) {
                $found{$s->{Identifier}} = $s;
            } elsif ($filtered) {
                delete $found{$s->{Identifier}};
            }
        }
        $filtered = 1;
        $rest = [values %found];
    }
    if (@filters) {
        for my $f (@filters) {
            my $regexp = $self->convert_wildcard_pattern_to_regexp($f);
            for my $s (@$rest) {
                if ( (grep { $_ =~ $regexp } @{$s->{objectClass}}) || 
                    ($f =~ /^\d+$/ && $s->{Identifier} == $f)) {
                    $found{$s->{Identifier}} = $s;
                } elsif ($filtered) {
                    delete $found{$s->{Identifier}};
                }
            }
        }
        $filtered = 1;
        $rest = [values %found];
    }
    return $rest;
}

=head1 LICENSE

This file is part of osgish.

Osgish is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 2 of the License, or
(at your option) any later version.

osgish is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with osgish.  If not, see <http://www.gnu.org/licenses/>.

A commercial license is available as well. Please contact roland@cpan.org for
further details.

=head1 PROFESSIONAL SERVICES

Just in case you need professional support for this module (or JMX or OSGi in
general), you might want to have a look at www.consol.com Contact
roland.huss@consol.de for further information (or use the contact form at
http://www.consol.com/contact/)

=head1 AUTHOR

roland@cpan.org

=cut

1;

