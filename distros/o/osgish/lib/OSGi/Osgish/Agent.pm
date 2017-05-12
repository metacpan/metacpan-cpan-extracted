#!/usr/bin/perl

=head1 NAME 

OSGi::Osgish::Agent - Access to the OSGi agent bundle

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut
package OSGi::Osgish::Agent;

use strict;
use JMX::Jmx4Perl;
use JMX::Jmx4Perl::Request;
use OSGi::Osgish::Agent::Upload;
use Data::Dumper;

# Osgi EEG MBeans
my $MBEANS_MAP = 
    { 
     "framework" => { key => "type", version => "1.5", domain => "osgi.core" },
     "bundleState" => { key => "type", version => "1.5", domain => "osgi.core" },
     "serviceState" => { key => "type", version => "1.5", domain => "osgi.core" },
     "packageState" => { key => "type", version => "1.5", domain => "osgi.core" },
     "permissionadmin" => { key => "service", version => "1.2", domain => "osgi.core" },
     "cm" => { key => "service", version => "1.3", domain => "osgi.compendium" },
     "provisioning" => { key => "service", version => "1.2", domain => "osgi.compendium" },
     "useradmin" => { key => "service", version => "1.1", domain => "osgi.compendium" }
    };

# Our own MBean for certain state checks
my $OSGISH_SERVICE_NAME = "osgish:type=Service";

sub new { 
    my $class = shift;
    my $cfg = ref($_[0]) eq "HASH" ? $_[0] : {  @_ };
    
    my $jmx4perl = new JMX::Jmx4Perl($cfg);
    my $upload = new OSGi::Osgish::Agent::Upload($jmx4perl);
    my $self = { 
                j4p => $jmx4perl,
                upload => $upload,
                cfg => $cfg,
               };
    bless $self,(ref($class) || $class);
    return $self;
}

sub cfg {
    my $self = shift;
    my $key = shift || return $self->{cfg};
    my $val = shift;
    my $ret = $self->{cfg}->{$key};
    if (defined $val) {
        $self->{cfg}->{$key} = $val;
    }
    return $ret;
}

sub upload {
    return shift->{upload};
}

sub url { 
    my $self = shift;
    my $j4p = $self->{j4p};
    return $j4p->url;
}

sub init {
    my $self = shift;
    my $old_bundle = delete $self->{bundle};
    my $old_service = delete $self->{service};
    eval {
        $self->_fetch_bundles;
        $self->_fetch_services;
    };
    if ($@) {
        $self->{bundle} = $old_bundle;
        $self->{service} = $old_service;
        die $@;
    }
}

sub bundles {
    my $self = shift;
    $self->_update_bundles(@_);
    return $self->{bundle}->{list};
}

sub services { 
    my $self = shift;
    $self->_update_services(@_);
    return $self->{service}->{list};
}

sub packages {
    my $self = shift;
    $self->_update_packages(@_);
    return $self->{package}->{list};
}

# Return a hashref with symbolic names as keys 
# and the ids as values
sub bundle_symbolic_names { 
    my $self = shift;
    $self->_update_bundles(@_);
    return $self->{bundle}->{symbolic_names};
}

sub bundle_ids {
    my $self = shift;
    $self->_update_bundles(@_);
    return [ sort keys %{$self->{bundle}->{ids}} ];
}

sub bundle_name {
    my $self = shift;
    my $id = shift;
    $self->_update_bundles(@_);
    return $self->{bundle}->{ids}->{$id};
}

sub service_object_classes {
    my $self = shift;
    $self->_update_services(@_);
    return $self->{service}->{object_classes};
}

sub service_ids {
    my $self = shift;
    $self->_update_services(@_);
    return [sort keys %{$self->{service}->{ids}}];
}

sub service { 
    my $self = shift;
    my $id = shift;
    $self->_update_services(@_);
    return $self->{service}->{ids}->{$id};
}

sub resolve_bundle {
    my $self = shift;
    $self->_update_bundles();
    $self->_bulk_bundle_cmd("resolveBundle","resolveBundles",@_);
}


sub start_bundle {
    my $self = shift;
    $self->_update_bundles();
    $self->_bulk_bundle_cmd("startBundle","startBundles",@_);
}

sub stop_bundle {
    my $self = shift;
    $self->_update_bundles();
    $self->_bulk_bundle_cmd("stopBundle","stopBundles",@_);
}

sub uninstall_bundle {
    my $self = shift;
    $self->_update_bundles();
    $self->_bulk_bundle_cmd("uninstallBundle","uninstallBundles",@_);
}

sub refresh_bundle {
    my $self = shift;
    $self->_update_bundles();
    $self->_bulk_bundle_cmd("refreshBundle","refreshBundles",@_);
}

sub _bulk_bundle_cmd {
    my $self = shift;
    my $what_single = shift || die "Internal: No single type give\n";
    my $what_multi = shift || die "Internal: No multi type give\n";
    my @ids = ();
    for my $i (@_) {    
        push @ids,$self->_id_or_symbolic_name($i);
    }
    die "No id given\n" unless @ids;
    if (@ids > 1) {
        return $self->execute($self->_mbean_name("framework"),$what_multi,\@ids);
    } else {
        $self->execute($self->_mbean_name("framework"),$what_single,$ids[0]);
        return $ids[0];
    }
}

sub install_bundle {
    my $self = shift;
    my @locations = @_;
    my $mbean = $self->_mbean_name("framework");
    if (@locations > 1) {
        # Must be posted due to the ";" sign, which, even when escaped,
        # confuses e.g. Glassfish when part of an GET Url
        $self->execute_post($mbean,"installBundles([Ljava.lang.String;)",\@locations);
    } else {
        $self->execute($mbean,"installBundle(java.lang.String)",$locations[0]);
    }
}


sub update_bundle {
    my $self = shift;
    my $id = $self->_id_or_symbolic_name(shift);
    my $location = shift;
    if ($location) {
        $self->execute($self->_mbean_name("framework"),"updateBundle(long,java.lang.String)",$id,$location);    
    } else {
        $self->execute($self->_mbean_name("framework"),"updateBundle(long)",$id);
    }
    return $id;
}

# Return values
sub update_bundles {
    my $self = shift;
    my @ids;
    for my $i (@_) {    
        push @ids,$self->_id_or_symbolic_name($i);
    }
    if (@ids > 1) {
        return $self->execute($self->_mbean_name("framework"),"updateBundles([J)",\@ids);    
    } else {
        return $self->execute($self->_mbean_name("framework"),"updateBundle(long)",$ids[0]);
    }
}

sub _id_or_symbolic_name {
    my $self = shift;
    my $id = shift;
    my $ret = $id =~ /^\d+$/ ? $id : $self->{bundle}->{symbolic_names}->{$id};
    die "Cannot find bundle '$id': Not an id nor a symbolic name\n"  unless ($ret);
    die "No bundle with id $id\n" unless $self->{bundle}->{ids}->{$ret};
    return $ret;
}

sub shutdown {
    my $self = shift;
    $self->execute($self->_mbean_name("framework"),"shutdownFramework");
}

sub restart {
    my $self = shift;
    $self->execute($self->_mbean_name("framework"),"restartFramework");
}


sub execute {
    my $self = shift;
    my $mbean = shift || die "No MBean name given";
    my $operation = shift || die "No operation given for MBean $mbean";
    my @args = @_;

    return $self->_do_execute(new JMX::Jmx4Perl::Request(EXEC,$mbean,$operation,@args));
}

sub execute_post {
    my $self = shift;
    my $mbean = shift || die "No MBean name given";
    my $operation = shift || die "No operation given for MBean $mbean";
    my @args = @_;

    return $self->_do_execute(new JMX::Jmx4Perl::Request(EXEC,$mbean,$operation,@args,{method => "POST"}));
}

sub _do_execute {
    my $self = shift;
    my $request = shift;

    my $j4p = $self->{j4p};

    my $response = $j4p->request($request);
    if ($response->is_error) {
        #print Dumper($response);
        if ($response->status == 404) {
            die "No agent running [Not found: ",$request->{mbean},",",$request->{operation},"].\n"
        } else {
            $self->{last_error} = $response->{error} . 
              ($response->stacktrace ? "\nStacktrace:\n" . $response->stacktrace : "");
            die $self->_prepare_error_message($response) . ".\n";
        }
    }
    return $response->value;
}

sub _prepare_error_message {
    my $self = shift;
    my $resp = shift;
    my $st = $resp->stacktrace;
    return "Connection refused" if $resp->{error} =~ /Connection\s+refused/i;

    if ($st) {
        if ($st =~ /BundleException:\s*([^\n]+)\.?/s) {
            my $txt = $1;
            chop $txt while $txt =~ /\.$/;
            return $txt;
        }
    }
    if ($resp->{error} =~ /^(\d{3} [^\n]+)\n/m) {
        return $1;
    }
    return "Server Error: " . $resp->{error};
}

sub last_error {
    my $self = shift;
    return $self->{last_error};
}

sub _mbean_name {
    my $self = shift;
    my $short_name = shift;
    
    my $d = $MBEANS_MAP->{$short_name} || die "No MBean defined for shortname $short_name";
    return $d->{domain} . ":" . $d->{key} . "=$short_name,version=" . $d->{version};
}

sub _update_services {
    my $self = shift;
    my $args = shift;
    $args = { $args, @_ } unless ref($args) eq "HASH";
    return if ($self->{service} && $args->{use_cached});

    # TODO: Update policy

    # Cache bundle list
    if ($self->_server_state_changed("services",$self->{service}->{timestamp})) {
        $self->_fetch_services;
    }    
}

sub _update_bundles {
    my $self = shift;
    my $args = shift;
    
    $args = { $args, @_ } unless ref($args) eq "HASH";
    
    return if ($self->{bundle} && $args->{use_cached});
    # TODO: Update policy

    # Cache bundle list
    if ($self->_server_state_changed("bundles",$self->{bundle}->{timestamp})) {
        $self->_fetch_bundles;
    }
}

sub _update_packages {
    my $self = shift;
    my $args = shift;
    
    $args = { $args, @_ } unless ref($args) eq "HASH";
    return if ($self->{package} && $args->{use_cached});
    # TODO: Update policy
    # Cache bundle list
    if (!$self->{package} || $self->_server_state_changed("packages",$self->{bundle}->{timestamp})) {
        #print "FETCH PKG\n";
        $self->_fetch_packages;
    }
}


sub _fetch_bundles {
    my $self = shift;
    my $bundle = $self->_fetch_list("bundleState","listBundles");
    my $names = {};
    my $ids = {};
    my $bundles =  $bundle->{list};
    for my $e (keys %{$bundles}) {
        my $b = $bundles->{$e};
        my $sym = $b->{SymbolicName};
        my $id = $b->{Identifier};
        $names->{$sym} = $id if $sym;
        $ids->{$id} = $sym || $b->{Name} || $b->{Location};
    }
    ($bundle->{symbolic_names},$bundle->{ids}) =  ($names,$ids);
    $self->{bundle} = $bundle;    
}

sub _fetch_services {
    my $self = shift;
    my $service = $self->_fetch_list("serviceState","listServices");
    ($service->{object_classes},$service->{ids}) = $self->_extract_object_classes($service->{list});
    $self->{service} = $service;
}

sub _fetch_packages {
    my $self = shift;
    my $package = $self->_fetch_list("packageState","listPackages");
    #print Dumper($package);
    $package->{import_export} = $self->_extract_import_export($package->{list});
    $self->{package} = $package;

}

sub exporting_bundles {
    return shift->_exporting_importing_bundle("exporting",@_);
}

sub importing_bundles {
    return shift->_exporting_importing_bundle("importing",@_);
}

sub _exporting_importing_bundle {
    my $self = shift;
    my $what = shift;
    my $package = shift || die "No package given\n";    
    my $version = shift || die "No version given for $package\n";
    $self->_update_packages(@_);
    #print Dumper($self->{package}->{import_export});
    return $self->{package}->{import_export}->{$package}->{$version}->{$what};
}

sub _extract_import_export {
    my $self = shift;
    my $plist = shift;
    
    my $ret = {};
    #print Dumper($plist);
    for my $e (values %{$plist}) {
        for my $b (values %$e) {
            for my $v (values %$b) {
                die "Internal: No version found for ",$v->{Name},"\n" unless $v->{Version};
                # We are using the chached bundle names here. Should be ok.
                $ret->{$v->{Name}}->{$v->{Version}} = 
                    {              
                     importing => $self->_extract_unique_bundles($v->{ImportingBundles}),
                     exporting => $self->_extract_unique_bundles($v->{ExportingBundles})
                    };                
            }            
        }
    }
    return $ret;
}

sub _extract_unique_bundles {
    my $self = shift;
    my $bundles = shift;
    my $ret = {};
    map { 
        $ret->{$_} = { 
                      id => $_,
                      name => $self->{bundle}->{ids}->{$_}
                     }
    } @$bundles;
    return [ sort { $a->{id} <=> $b->{id} } values %$ret ];
}

sub _fetch_list {
    my $self = shift;
    my ($mbean,$operation) = @_;
    my $ret = {};
    $ret->{list} = $self->execute($self->_mbean_name($mbean),$operation);
    $ret->{timestamp} = time;
    return $ret;
}

sub _server_state_changed {
    my $self = shift;
    my $type = shift;
    my $timestamp = shift;
    my $state = $self->execute($OSGISH_SERVICE_NAME,"hasStateChanged",$type,$timestamp);
    return $state eq "true" ? 1 : 0;
}

sub _extract_object_classes {
    my $self = shift;
    my $services = shift;
    my $cl = {};
    my $ids = {};
    for my $s (values %$services) {
        my $classes = $s->{objectClass};
        next unless $classes;
        $classes = [ $classes ] unless ref($classes) eq "ARRAY";
        my $id = $s->{Identifier};
        map { $cl->{$_} = $id } @$classes;
        $ids->{$id} = { 
                       classes => $classes, 
                       bundle => $s->{BundleIdentifier},
                       using => $s->{UsingBundles}
                      };
    }
    return ($cl,$ids);
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

