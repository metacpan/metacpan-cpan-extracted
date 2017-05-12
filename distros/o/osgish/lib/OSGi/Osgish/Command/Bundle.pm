#!/usr/bin/perl

package OSGi::Osgish::Command::Bundle;
use strict;
use vars qw(@ISA);
use Term::ANSIColor qw(:constants);
use OSGi::Osgish::Command;
use Data::Dumper;

@ISA = qw(OSGi::Osgish::Command);

my %BUNDLE_STATE_COLOR = (
                          "installed" => "bundle_installed",
                          "resolved" => "bundle_resolved",
                          "active" => "bundle_active"
                         );

=head1 NAME 

OSGi::Osgish::Command::Bundle - Bundle related commands

=head1 DESCRIPTION

This collection of shell commands provided access to bundle related
operations. I.e. these are

=over

=item * 

List of bundles ('ls')

=item * 

Start and Stopping of bundles ('start'/'stop')

=back

=cut

=head1 COMMANDS

=over

=cut 


# Name of this command
sub name { "bundle" }

# We hook into as top-level commands
sub top_commands {
    my $self = shift;
    return $self->agent ? $self->sub_commands : {};
}

# Context command "bundle"
sub commands {
    my $self = shift;
    my $cmds = $self->sub_commands; 
    return  {
             "bundle" => { 
                          desc => "Bundles related operations",
                          proc => $self->push_on_stack("bundle",$cmds),
                          cmds => $cmds
                         },
             "b" => { alias => "bundle", exclude_from_completion => 1},
            };
}

# The 'real' commands
sub sub_commands {
    my $self = shift;
    return {
            "ls" => { 
                     desc => "List bundles",
                     proc => $self->cmd_list,
                     args => $self->complete->bundles(no_ids => 1),
                     doc => <<EOT,

ls [-s -e -i] [<bnd>]

List one or more bundles.

Options:
  -i    Show wired imports (single bundle)
  -e    Show wired exports (single bundle)
  -s    Show symbolic name (single bundle)
  -h    Show headers (single bundle)
  <bnd> Bundle id or symbolic name, conditionally 
        with wildcards ('*' and '?') 
EOT
                    },
            "start" => { 
                        desc => "Start bundles",
                        proc => $self->cmd_start,
                        args => $self->complete->bundles,
                        doc => <<EOT,

start <bnd1> <bnd2> ...

Start one or more bundles. Bundles can be given
as ids or symbolic names (or mixed). Wildcards
('*' and '?') are supported on symbolic names.
EOT
                       },
            "stop" => { 
                       desc => "Stop bundles",
                       proc => $self->cmd_stop,
                       args => $self->complete->bundles,
                       doc => <<EOT,

stop <bnd1> <bnd2> ...

Stop one or more bundles. Bundles can be given
as ids or symbolic names (or mixed). Wildcards
('*' and '?') are supported on symbolic names.
EOT
                      },
            "resolve" => {
                          desc => "Resolve bundles",
                          proc => $self->cmd_resolve,
                          args => $self->complete->bundles,
                          doc => <<EOT

resolve <bnd1> <bnd2> ...

Resolve one or more bundles. Bundles can be given
as ids or symbolic names (or mixed). Wildcards
('*' and '?') are supported on symbolic names.
EOT

                         },
            "update" => {
                         desc => "Update a bundle optionally from a new location",
                         proc => $self->cmd_update,
                         args => $self->complete->bundles,
                         doc => <<EOT

update <bnd1> <bnd2> ...
update -l <url> <bnd>

Update one or more bundles. Bundles can be given
as ids or symbolic names (or mixed). Wildcards
('*' and '?') are supported on symbolic names.

With '-l' a single bundle can be updated from the 
given location URL.
EOT
  
                        },
            "install" => {
                          desc => "Install a bundle",
                          proc => $self->cmd_install,
                          # Todo: Complete on file names if no schema is given
                          # and the server is a local host
                          args => $self->complete->bundles,
                          doc => <<EOT

install <url>

Install a single bundle from the given URL.
EOT

                           },
            "uninstall" => {
                            desc => "Uninstall bundles",
                            proc => $self->cmd_uninstall,
                            args => $self->complete->bundles,
                            doc => <<EOT

uninstall <bnd1> <bnd2> ...

Uninstall one or more bundles. Bundles can be given
as ids or symbolic names (or mixed). Wildcards
('*' and '?') are supported on symbolic names.
EOT
                           },
            "refresh" => {
                          desc => "Refresh bundles",
                          proc => $self->cmd_refresh,
                          args => $self->complete->bundles,
                          doc => <<EOT

Refresh <bnd1> <bnd2> ...

Refresh one or more bundles. Bundles can be given
as ids or symbolic names (or mixed). Wildcards
('*' and '?') are supported on symbolic names.
EOT
                          
                         }
           };
}

# =================================================================================================== 


=item cmd_list

List commands which can filter bundles by wildcard and knows about the
following options:

=over

=item -s

Show symbolic names instead of descriptive names

=item -i 


=item -e 

=item -h

=back

If a single bundle is given as argument its details are shown.

=cut

sub cmd_list {
    my $self = shift; 
    
    return sub {
        my $osgish = $self->osgish;
        my $agent = $osgish->agent;
        print "Not connected to a server\n" and return unless $agent;
        my ($opts,@filters) = $self->extract_command_options(["s!","i!","e!","h!"],@_);
        my $bundles = $agent->bundles;
        my $text = sprintf("%4.4s   %-11.11s  %3s %s\n","Id","State","Lev","Name");
        $text .= "-" x 87 . "\n";
        my $nr = 0;
        
        my $filtered_bundles = $self->_filter_bundles($bundles,@filters);
        return unless @$filtered_bundles;

        if (@$filtered_bundles == 1) {
            # Print single info for bundle
            $self->print_bundle_info($filtered_bundles->[0],$opts);
        } else {
            for my $b (sort { $a->{Identifier} <=> $b->{Identifier} } @$filtered_bundles) {
                my $id = $b->{Identifier};
                my ($c_frag,$reset) = $osgish->color("bundle_fragment",RESET);
                my $state = lc $b->{State};
                my $color = $self->_bundle_state_color($b);
                my $state = $self->_state_info($b);
                my $level = $b->{StartLevel};
                my $fragment = $b->{Fragment} eq "true" ?  $c_frag . "F" . $reset : " ";
                my $name = $b->{Headers}->{'[Bundle-Name]'}->{Value};
                my $sym_name = $b->{SymbolicName};
                my $version = $b->{Version};
                my $location = $b->{Location};
                my $desc = $opts->{s} ? 
                  $sym_name || $location :
                    $name || $sym_name || $location;
                $desc .= " ($version)" if $version && $version ne "0.0.0";
                
                $text .= sprintf "%s%4d   %-11s%s %s%3d %s%s%s\n",$color,$id,$state,$reset,$fragment,$level,$desc; 
                $nr++;
            }
            $self->print_paged($text,$nr);
        }
        #print $text;
        #print Dumper($bundles);
    }
}


=item cmd_start

Resolve one or more bundles by its id or symbolicname

=cut 

sub cmd_resolve {
    my $self = shift;
    return sub { 
        my @args = @_;
        my $filters = $self->_filter_symbolic_names(@args);
        $self->agent->resolve_bundle(@$filters);
        
    }
}


=item cmd_start

Start one or more bundles by its id or symbolicname

=cut 

sub cmd_start {
    my $self = shift;
    return sub { 
        my $filters = $self->_filter_symbolic_names(@_);
        my $ret;
        eval { 
            $ret = $self->agent->start_bundle(@$filters);
        };
        $self->_print_operation_result("Start",$ret,$filters,$@);
    }
}

=item cmd_stop

Stop one or more bundles by its id or symbolicname

=cut 

sub cmd_stop {
    my $self = shift;
    return sub { 
        my $filters = $self->_filter_symbolic_names(@_);
        my $ret;
        eval { 
            $ret = $self->agent->stop_bundle(@$filters);
        };
        $self->_print_operation_result("Stop",$ret,$filters,$@);
    }
}

=item cmd_update

Update a bundle from its current location

=cut

sub cmd_update {
    my $self = shift;
    return sub {
        my ($opts,@filters) = $self->extract_command_options(["l=s"],@_);
        my $agent = $self->osgish->agent;
        my $filtered_bundles = $self->_filter_symbolic_names(@filters);
        #print Dumper($filtered_bundles);
        my $ret;
        eval { 
            if ($opts->{l} || @$filtered_bundles == 1) {
                die "Can only update a single bundle with -l. Given : ",join(",",@$filtered_bundles),"\n"
                  if @$filtered_bundles > 1;
                $ret = $self->agent->update_bundle($filtered_bundles->[0],$opts->{l});
            } else {
                $ret = $self->agent->update_bundles(@$filtered_bundles);
            }
        };
        $self->_print_operation_result("Updat",$ret,$filtered_bundles,$@);
    }
}

=item cmd_install

Install one or more bundles

=cut

sub cmd_install {
    my $self = shift;
    my $osgish = $self->osgish;
    return sub {
        my @args = @_;
        
        my $ret;
        eval {
            $ret = $self->agent->install_bundle(@args);
        };
        $self->_print_operation_result("Install",$ret,\@args,$@,1);
    }
}

=item cmd_uninstall

Uninstall one or more bundles

=cut

sub cmd_uninstall {
    my $self = shift;
    return sub {
        my $filters = $self->_filter_symbolic_names(@_);
        my $ret;
        eval { 
            $ret = $self->agent->uninstall_bundle(@$filters);
        };
        $self->_print_operation_result("Uninstall",$ret,$filters,$@);
    }
}

=item cmd_refresh

Refresh one or more bundles

=cut

sub cmd_refresh {
    my $self = shift;
    return sub {
        my $filters = $self->_filter_symbolic_names(@_);
        my $ret;
        eval { 
            $ret = $self->agent->refresh_bundle(@$filters);
        };
        $self->_print_operation_result("Refresh",$ret,$filters,$@);
    }
}


# Print a single bundle's info
sub print_bundle_info {
    my $self = shift;
    my $osgish = $self->osgish;
    my $agent = $self->agent;

    my $bu = shift;
    my $opts = shift;
    my $txt = "";

    $self->_dump_main_info(\$txt,$bu,$opts);
    $txt .= "\n";


    my $imports = $self->_extract_imports($bu->{ImportedPackages},$bu->{Headers},$opts->{i});
    $self->_dump_imports(\$txt,$imports,$opts);

    my $exports = $self->_extract_exports($bu->{ExportedPackages},$opts->{e});
    $self->_dump_exports(\$txt,$exports,$opts);

    $self->_dump_services(\$txt,$bu,$opts);
    $self->_dump_required(\$txt,$bu,$opts);
    $self->_dump_headers(\$txt,$bu->{Headers}) if ($opts->{h});

    $self->print_paged($txt);

    #print Dumper($bu);
}

sub _print_operation_result {
    my $self = shift;
    my $label = shift;
    my $ret = shift;
    my $bundles = shift;
    my $error = shift;
    my $no_cache = shift;    
    my $agent = $self->agent;
    # Update cache if required
    $agent->bundles() if $no_cache;
    my ($c_bid,$c_bname,$c_r) = $self->color("bundle_id","bundle_name",RESET);
    if ($error) {
        print $label . "ing failed for " . join(",",map { $c_bname . $_ . $c_r } @$bundles) . ":\n";
        print $error;
    } elsif (ref($ret) eq "HASH") {
        if (lc $ret->{Success} eq "false") {       
            my $id = $ret->{BundleInError};
            my $name = $agent->bundle_name($id,use_cached => 1);  
            print $label . "ing failed for bundle " . $c_bname . $name . $c_r . " (" . $c_bid . $id . $c_r . "): \n";
            print $ret->{Error} . "\n\n";
        }
        if ($ret->{Completed} && @{$ret->{Completed}}) {
            print $label . "ed Bundles:\n";
            for my $c (sort { $a <=> $b } @{$ret->{Completed}}) {
                my $name = $agent->bundle_name($c,use_cached => 1);  
                print "    " . $c_bname . $name . $c_r . " (". $c_bid . $c . $c_r . ")\n";
            }
        }
        if ($ret->{Remaining} && @{$ret->{Remaining}}) {
            print "Remaining Bundles:\n";
            for my $c (sort { $a <=> $b } @{$ret->{Remaining}}) {
                my $name = $agent->bundle_name($c,use_cached => 1);  
                print "    " . $c_bname . $name . $c_r . " (". $c_bid . $c . $c_r . ")\n";
            }
        }
    } else {
        my $name = $agent->bundle_name($ret,use_cached => 1);
        print $label . "ed bundle " . $c_bname . $name . $c_r . " (" . $c_bid . $ret . $c_r . ")\n";
    }
}


sub _extract_services {
    my $self = shift;
    my $ids = shift;
    my $agent = $self->agent;
    my $ret = {};
    for my $id (@$ids) {
        my $service = $agent->service($id);
        $ret->{$id} = { 
                       id => $id,
                       class => $service->{classes}->[0],
                       bundle => $service->{bundle},
                       using => $service->{using}
                      };
    }
    return $ret;
}

sub _dump_services {
    my $self = shift;
    my $ret = shift;
    my $bu = shift;
    my $opts = shift;
    my $osgish = $self->osgish;
    my $agent = $self->agent;

    my $s = "";
    my $services = $agent->services; # Update if necessary
    my $services = $self->_extract_services($bu->{RegisteredServices});
    my ($c_bid,$c_bname,$c_using,$c_registered,$c_reset) = $osgish->color("bundle_id","bundle_name","service_using","service_registered",RESET);
    my $label = " Registered:";
    for my $id (keys %{$services}) {
        #print Dumper($services->{$id});
        my @bundles = @{$services->{$id}->{using} || []};
        my $class = $services->{$id}->{class};
        $s .= $self->_dump_bundle_using($class,$services->{$id}->{using},
                                          {label => $label, use_sym => $opts->{s},color => $c_using,
                                           prefix => sprintf("%3.3s: ",$id)});
        $label = "";
    }
    $services = $self->_extract_services($bu->{ServicesInUse});
    $label = " Using:";
    for my $id (keys %{$services}) {
        my $bundle = $services->{$id}->{bundle};
        if ($opts->{s}) {
            $bundle = $c_bname . $agent->bundle_name($bundle,use_cached => 1) . $c_reset; 
        } else {
            $bundle = $c_bid . $bundle . $c_reset;
        }
        $s .= sprintf("%-14.14s %3.3s: %s <- %s\n",$label,$id,$c_using . $services->{$id}->{class} . $c_reset,$bundle);
        $label = "";
    }

    $$ret .= "\nServices:\n" . $s if length $s;
}

sub _dump_required {
    my $self = shift;
    my $ret = shift;
    my $bu = shift;
    my $opts = shift;
    my $osgish = $self->osgish;
    my $agent = $self->agent;
    
    my $s = "";
    my ($c_bid,$c_bname,$c_reset) = 
      $osgish->color("bundle_id","bundle_name",RESET);
    for my $e ([ "RequiredBundles","Required" ],[ "RequiringBundles", "Required by" ]) {
        my $bundles = $bu->{$e->[0]};
        if (@$bundles) {
            my $label = $e->[1];
            for my $id (@$bundles) {
                my $id_c = $c_bid . $id . $c_reset;
                my $bundle = $opts->{s} ? $c_bname . $agent->bundle_name($id,use_cached => 1) . $c_reset . " (" . $id_c . ")" : $id_c;
                $s .= sprintf("%-14.14s %s\n",$label,$bundle);
                $label = "";
            }
        }
    }
    $$ret .= "\n" .  $s  if length($s);
}

sub _dump_bundle_using {
    my $self = shift;
    my $main = shift;
    my $bundles = shift;
    my $args = shift;
    my $agent = $self->agent;
    my ($c_bid,$c_bname,$c_reset) = $self->osgish->color("bundle_id","bundle_name",RESET);
    my $ret = "";
    my $prefix = $args->{prefix} || "";
    my $len = $args->{length} || length($main . $prefix);
    my $main_c = $args->{color} ? $args->{color} . $main . $c_reset : $main;
    if ($args->{use_sym}) {
        if ($bundles && @$bundles) {
            my @names = map { $agent->bundle_name($_,use_cached => 1) } @$bundles;
            $ret .= sprintf("%-14.14s %s -> %s\n",$args->{label},$prefix . $main_c,
                            $c_bname . shift(@names) . $c_reset);
            my $indent = " " x (19 + $len);
            while (@names) {
                $ret .= $indent . $c_bname . (shift @names) . $c_reset . "\n";
            }               
        } else {
            $ret .= sprintf("%-14.14s %s\n",$args->{label},$prefix . $main);
        }
    } else {
        #my @bundles = map { $c_ps . $_->{id} . $c_re } @{$val->{using}};
        my $src = "";
        my $c = $main;
        if ($bundles && @$bundles) {
            my $txt = join ", ", map { $c_bid . $_ . $c_reset } @$bundles;
            $src = " -> " . $txt;
        }
        $ret .= sprintf("%-14.14s %s%s\n",$args->{label},$prefix . $main_c,$src);
    }
    return $ret;
}
    
sub _dump_main_info {
    my $self = shift;
    my $ret = shift;
    my $bu = shift;
    my $opts = shift;
    my $osgish = $self->osgish;
    my $agent = $self->agent;
    #print Dumper($bu);
    my $name = $bu->{Headers}->{'Bundle-Name'}->{Value};
    my ($c_bid,$c_bname,$c_version,$c_fragment,$c_reset) = $osgish->color("bundle_id","bundle_name","bundle_version","bundle_fragment",RESET);    
    my $sym = $bu->{SymbolicName} || $bu->{Location};
    my $version = $bu->{Version} ? $c_version . $bu->{Version} . $c_reset : "";
    my $fragment = $bu->{Fragment} eq "true" ? "(" . $c_fragment . "Fragment" . $c_reset . ")" : "";
    my $rest = join(" ",$version,$fragment);
    my $state_color = $self->_bundle_state_color($bu);
    my $state = "[" . $state_color . $self->_state_info($bu) . $c_reset . "]";
    $sym = $c_bname . $sym . $c_reset;
    $$ret .= sprintf("%-14.14s %s %s\n","Name:",$c_bid.$bu->{Identifier}.$c_reset,$name ? $name : $sym) if $name;
    $$ret .= sprintf("%-14.14s %s %s %s\n","",$name ? $sym : "",$state,$rest);
    $$ret .= sprintf("%-14.14s %s\n","Location:",$bu->{Location});
    $$ret .= sprintf("%-14.14s %s\n","Modified:",$self->format_date($bu->{LastModified}/1000));
    $self->_add_fragment($ret,$bu->{Hosts},"Hosts:");
    $self->_add_fragment($ret,$bu->{Fragments},"Fragments:");

    my @flags = ();
    for my $flag ("RemovalPending", "PersistentlyStarted", "Required") {
        push @flags,$flag if $bu->{$flag} eq "true";
    } 
    if (@flags) {
        $$ret .= sprintf("%-14.14s %s\n","Flags:",join ", ",@flags);
    }
    if (length($bu->{StartLevel})) {
        $$ret .= sprintf("%-14.14s %s\n","Start-Level:",$bu->{StartLevel});
    }
    #print Dumper($bu);
}

sub _add_fragment {
    my $self = shift;
    my $ret = shift;
    my $list = shift;
    my $label = shift;
    my $osgish = $self->osgish;
    my $agent = $self->agent;
    my ($c_bid,$c_bname,$c_fragment,$c_reset) = $osgish->color("bundle_id","bundle_name","bundle_fragment",RESET);    
    
    if ($list && @{$list}) {
        # Host can occur multiple times
        my %uniq = map { $_ => 1 } @$list;
        for my $f (keys %uniq ) {
            my $name = $c_fragment . $agent->bundle_name($f,use_cached => 1) . $c_reset . " (${c_bid}${f}${c_reset})";
            $$ret .= sprintf("%-14.14s %s\n",$label,$name);
            $label = "";
        }
    }
}

sub _header {
    my $self = shift;
    my $bu = shift;
    my $key = shift;
    my $headers = $bu->{Headers};
    my @prop  = grep { $_->{Key} eq $key } values %$headers;
    return "" unless @prop;
    return (shift @prop)->{Value};
}

sub _dump_imports {
    my $self = shift;
    my $ret = shift;
    my $imports = shift;
    my $opts = shift;
    my $osgish = $self->osgish;

    #print Dumper($imports);
    my $label = "Imports:";
    my ($c_pr,$c_pv,$c_po,$c_ps,$c_re) = $osgish->color("package_resolved","package_version","package_optional","package_imported_from",RESET);
    for my $k (sort { $a cmp $b } keys %$imports) {
        my $val = $imports->{$k};
        my $version = $val->{version};
        if ($val->{version}) {
            $version = $c_pv . $version . $c_re;
            $version .= " " . $val->{version_spec} if $val->{version_spec};
        } else {
            $version = $val->{version_spec} if $val->{version_spec};
        }
        my $optional = $val->{optional} ? $c_po . " * " . $c_re : "";
        my $package = $k;
        $package = $c_pr . $package . $c_re if ($val->{resolved});
        my $src = "";
        if (defined($val->{source})) {
            my $b = $val->{source};
            $src = " <- " . join ", ", map { $c_ps . ($opts->{s} ? $_->{name} : $_->{id}) . $c_re } @{$val->{source}};
        }
        $$ret .= sprintf("%-14.14s %s %s%s%s\n",$label,$package,$version,$optional,$src);
        $label = "";
    }
}

sub _dump_exports {
    my $self = shift;
    my $ret = shift;
    my $exports = shift;
    my $opts = shift;
    my $osgish = $self->osgish;

    my $label = "Exports:";
    my ($c_pv,$c_pr,$c_ps,$c_re) = $osgish->color("package_version","package_resolved","package_exported_to",RESET);
    for my $k (sort { $a cmp $b } keys %$exports) {
        my $val = $exports->{$k};
        my $version = $val->{version};
        $version = $c_pv . $version . $c_re if ($val->{version});
        my $len = length($k . " " . $val->{version});
        my $package = $k;
        $package = $c_pr . $package . $c_re if ($val->{using} && @{$val->{using}});
        if ($val->{using}) {
#            print Dumper($val->{using});
            $$ret .= $self->_dump_bundle_using($package . " " . $version,[map { $_->{id} } @{$val->{using}} ],
                                                 {length => $len,label => $label, use_sym => $opts->{s}});
            $label = "";
        } else {
            $$ret .= sprintf("%-14.14s %s %s\n",$label,$package,$version);
        }
        $label = "";
    }
}

sub _dump_headers {
    my $self = shift;
    my $ret = shift;
    my $headers = shift;
    my $osgish = $self->osgish;
    my $label = "Headers:";
    #print Dumper($headers);
    my ($c_h,$c_v,$c_r) = $osgish->color("header_name","header_value",RESET);
    for my $h (sort { $headers->{$a}->{Key} cmp $headers->{$b}->{Key} } keys %$headers) {
        my $val = $headers->{$h}->{Value};
        my $key = $headers->{$h}->{Key};
        if ($key =~ /^(Export|Import)-Package$/ || ($val =~ /[,;]\s*version=/)) {
            my $prop = $val;
            my @props;
            while ($prop) {
                $prop =~ s/([^,]*?(".*?")*)(,|$)//;
                push @props,$1;
            }
            my $l = length $key;
            $key = $c_h . $key . $c_r;
            $$ret .= sprintf("%-14.14s %s = %s%s%s,\n",$label,$key,$c_v,shift @props,$c_r);
            $label = "";
            while (@props) {
                $$ret .= sprintf("%-14.14s %${l}.${l}s   %s%s%s%s\n",$label,"",$c_v,shift @props,$c_r,@props ? "," : "");
            }
        } else {
            $key = $c_h . $key . $c_r;
            $$ret .= sprintf("%-14.14s %s = %s%s%s\n",$label,$key,$c_v,$val,$c_r);
            $label = "";
        }
    }
}

sub _extract_imports {
    my $self = shift;
    my $agent = $self->agent;
    my ($imp,$headers,$lookup_sources) = @_;
    my $imp_headers = {};
    for my $i (grep { $_->{Key} eq 'Import-Package' } values %{$headers}) {
        my $val = $i->{Value};
        $imp_headers = { %$imp_headers, %{$self->_split_property($val)} };
    }
    my $imports = {};
    my $first = 1;
    for my $i (@$imp) {
        my ($package,$version) = $self->_split_package($i);
        my $e = {};
        $e->{version} = $version;
        $e->{resolved} = 1;
        if ($imp_headers->{$package}) {
            $self->_add_imp_header_info($e,$imp_headers->{$package});
        }
        if ($lookup_sources) {
            $e->{source} = $agent->exporting_bundles($package,$version,use_cached => !$first);
            $first = 0;
        }
        $imports->{$package} = $e;
    }

    # Add unresolved imports mentioned in the header
    for my $k (keys %$imp_headers) {
        if (!$imports->{$k}) {
            my $e = $self->_add_imp_header_info({},$imp_headers->{$k});
            $e->{resolved} = 0;
            $imports->{$k} = $e;
        }
    }
    return $imports;
}

sub _extract_exports {
    my $self = shift;
    my $agent = $self->agent;
    my ($exp,$lookup_sources) = @_;
    my $exports = {};
    my $first = 1;
    for my $e (@$exp) {
        my ($package,$version) = $self->_split_package($e);
        my $e = {};
        $e->{version} = $version;
        if ($lookup_sources) {
            $e->{using} = $agent->importing_bundles($package,$version,use_cached => $first ? undef : 1);
            $first = 0;
        }
        $exports->{$package} = $e;
    }
    return $exports;
}

sub _add_imp_header_info {
    my $self = shift;
    my $e = shift;
    my $imp = shift;
    my $attrs = $imp->{attributes};
    my $dirs = $imp->{directives};
    ($e->{optional} = 1) && delete $dirs->{resolution} if $dirs->{resolution} eq "optional";
    $e->{version_spec} = delete $attrs->{version} if $attrs->{version};
    $e->{directives} = $dirs if %{$dirs};
    $e->{attributes} = $attrs if %{$dirs};
    return $e;
}

sub _bundle_state_color {
    my $self = shift;
    my $bu = shift;
    my $osgish = $self->osgish;
    my $c_name = $BUNDLE_STATE_COLOR{lc($bu->{State})};
    return "" unless $c_name;
    return ($osgish->color($c_name))[0];
}

sub _state_info {
    my $self = shift;
    my $bu = shift;
    my $state = lc $bu->{State};
    return uc(substr($state,0,1)) . substr($state,1);
}

sub _split_package {
    my $self = shift;
    return split /;/,shift,2;
}

sub _split_property {
    my $self = shift;
    my $prop = shift;
    my $l = $prop;
    my $ret = {};
    while ($l) {
        $l =~ s/([^,]*?("[^"]+"[^,]*)*)(\s*,\s*|$)//;
        my $part = $1;
        my @targets = ();
        my $attrs = {};
        my $directives = {};
        while ($part) {
            $part =~ s/([^;]*?("[^"]+"[^;]*)*)(\s*;\s*|$)//;
            my $sub = $1;
            if ($sub =~ /^(.*):=\"?(.*?)\"?$/) {
                $directives->{$1} = $2;
            } elsif ($sub =~ /^(.*)=\"?(.*?)\"?$/) {
                $attrs->{$1} = $2;
            } else {
                push @targets,$sub;
            }
            for my $t (@targets) {
                $ret->{$t} = { }; 
                $ret->{$t}->{attributes} = $attrs if $attrs;
                $ret->{$t}->{directives} = $directives if $directives;
            }            
        }
    }
    return $ret;
}

# Filter bundles according to some criteria
sub _filter_symbolic_names {
    my $self = shift;
    my $agent = $self->agent;
    my $filtered_bundles = [map { $_->{SymbolicName} || $_->{Identifier} } @{$self->_filter_bundles($agent->bundles,@_)} ];
    die "No bundle given\n" unless @$filtered_bundles;    
    return $filtered_bundles;
}


sub _filter_bundles {
    my $self = shift;
    my ($bundles,@filters) = @_;

    if (@filters) {
        my %filtered_bundles;
        for my $f (@filters) {
            my $regexp = $self->convert_wildcard_pattern_to_regexp($f);
            for my $b (values %$bundles) {
                if ($b->{SymbolicName} =~ $regexp || ($f =~ /^\d+$/ && $b->{Identifier} == $f)) {
                    $filtered_bundles{$b->{Identifier}} = $b;
                }
            }
        }
        return [values %filtered_bundles];
    } else {
        return [values %$bundles];
    }
}

=back

=cut


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

