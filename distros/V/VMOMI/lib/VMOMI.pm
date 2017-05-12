package VMOMI;

use 5.006;
use strict;
use warnings;

our $VERSION = 0.02;

use Class::Autouse;
use Exception::Class(
    'Exception',
    'Exception::SoapFault' => {
        isa     => 'Exception',
        fields  => [ 'faultcode', 'detail', 'faultstring' ] },
    'Exception::Autoload' => {
        isa     => 'Exception' },
    'Exception::Deserialize' => {
        isa     => 'Exception' },
    'Exception::Serialize' => {
        isa     => 'Exception' },
    'Exception::Protocol' => {
        isa     => 'Exception' },
);

Class::Autouse->autouse_recursive("VMOMI");

# TODO: Add support for multiple entity types in single call, e.g. 'HostSystem', 'VirtualMachine' & 'Folder'
sub find_entities {
    my ($content, $type, $match, $begin, %args) = @_;
    my (@properties, $spec, $view, $filter_spec, $result, @objects, @matched);

    $begin = $content->rootFolder unless defined $begin;
    @properties = keys %$match if defined $match;

    # PropertySpec
    $spec = new VMOMI::PropertySpec(type => $type, all => 0);
    if (defined $match) {
        $spec->pathSet(\@properties);
    }

    $view = $content->viewManager->CreateContainerView(
        type => [$type],
        recursive => 1,
        container => $begin->moref,
    );


    $filter_spec = new VMOMI::PropertyFilterSpec(
        reportMissingInResults => 0,
        propSet => [ new VMOMI::PropertySpec(
            all => 0,
            type => $type,
            pathSet => \@properties,
        )],
        objectSet => [ new VMOMI::ObjectSpec(
            obj => $view,
            skip => 0,
            selectSet => [ new VMOMI::TraversalSpec(
                path => "view",
                type => $view->{type},
            )],
        )],
    );

    $result = $content->propertyCollector->RetrievePropertiesEx(
        specSet => [$filter_spec],
        options => new VMOMI::RetrieveOptions(),
    );

    push @objects, @{ $result->objects || [ ] };
    while (defined $result->token) {
        $result = $content->propertyCollector->ContinueRetrievePropertiesEx(token => $result->token);
        push @objects, @{ $result->objects || [ ] };
    }


    unless (defined $match) {
        @matched = map { $_->obj } @objects;
        return @matched;
    }

    foreach my $object (@objects) {
        my (%pset);
        
        %pset = map { $_->name => $_->val } @{ $object->{propSet} || [ ] };
        foreach (@properties) {
            my $re = $match->{$_};

            if (not defined $re and not defined $pset{$_}) {
                push @matched, $object->obj;
            } # check if $re or $pset{$_} are undef to avoid compare errors

            if ($pset{$_} =~ /$re/) {
                push @matched, $object->obj;
            }
        }
    }
    return @matched;

}

1;

=encoding UTF-8

=head1 NAME

VMOMI - VMware vSphere API Perl Bindings

=head1 SYNOPSIS

    use VMOMI;

    stub = new VMOMI::SoapStub(host => $host) || die "Failed to initialize VMOMI::SoapStub";
    $instance = new VMOMI::ServiceInstance(
        $stub, 
        new VMOMI::ManagedObjectReference(
            type  => 'ServiceInstance',
            value => 'ServiceInstance',
        ),
    );

    # Login
    $content = $instance->RetrieveServiceContent;
    $session = $content->sessionManager->Login(userName => $user, password => $pass);

    @vms = VMOMI::find_entities($content, 'VirtualMachine');
    foreach (@vms) {
        print $_->name . ", " . $_->config->guestFullName . "\n";
    }

    # Logout
    $content->sessionManager->Logout();

=head1 INSTALLATION
    
    apk add openssl-dev libxml2-dev
    cpanm install VMOMI

=head1 DESCRIPTION

VMOMI provides an alternative to the VMware Perl SDK for vSphere and was created to address
some limitations with the offical VMware Perl SDK.

=over 8

=item * Preserve main:: namespace by avoid globals and the import of all API classes

=item * Reduce memory footprint through L<Class::Autouse|https://metacpan.org/pod/Class::Autouse>

=item * Enable installation through CPAN

=back

=head2 Finding ManagedEntities

Managed entities in the VMware vSphere Web Service inventory, e.g. VirtualMachine or HostSystem, can be
fetched with the utilty function B<VMOMI::find_entities()>:

    @vms = VMOMI::find_entities($content, 'VirtualMachine', { 'config.guestFullName' => qr/Linux/ });
    @hosts = VMOMI::find_entities($content, 'HostSystem');

B<$content> should be an authenticated instance of VMOMI::ServiceContent:

    $stub = new VMOMI::SoapStub(host => $host);
    $instance = new VMOMI::ServiceInstance(
        $stub, 
        new VMOMI::ManagedObjectReference(
            type  => 'ServiceInstance',
            value => 'ServiceInstance',
        ),
    );
    $content = $instance->RetrieveServiceContent;
    $session = $content->sessionManager->Login(userName => $user, password => $pass);

=head2 Working with ManagedObjectReferences

The VMware vSphere Web Service API primarily works through ManagedObjectReferences (moref). Most SDKs
therefore generate "view classes" of the common objects managed through the API, e.g. VirtualMachine,
HostSystem, Folder, Datacenter, ClusterComputeResource, etc.

VMOMI provides similar, manually generated classes for these managed objects.  During deserialization
of the vSphere Web Service API, ManagedObjectReferences are automatically instantiated to corresponding
"view classes". The underlying ManagedObjectReference can be accessed through the B<moref> property.
ManagedObjectReference consists of two properties B<type> and B<value>:

    $vm = VMOMI::find_entities($content, 'VirtualMachine', { name => qr/TestVM2/ })->shift;
    $moref = $vm->moref;
    print $moref->type . ":" . $moref->value . "\n"; # 'VirtualMachine:vm-12'

"View" classes can instantiated using known, valid ManagedObjectReference type and value properties along
with a current, authenticated connection stub:

    $vm = new VMOMI::VirtualMachine(
        $stub, 
        new VMOMI::ManagedObjectReference
            type => 'VirtualMachine', 
            value => 'vm-12'),
    );
    print $vm->name . "\n"; # TestVM2

=head2 JSON

Support for L<JSON::XS|https://metacpan.org/pod/JSON::XS> object serialization is available through the 
TO_JSON method on the SDK classes, which may be of benefit for storing objects or integration with NoSQL
databases.

    $coder = JSON::XS->new->convert_blessed->pretty;
    $encoded_json = $coder->encode($session);
    
    print $encoded_json;
    {
       "lastActiveTime" : "2017-05-03T13:17:03.152908Z",
       "extensionSession" : 0,
       "key" : "52956fcc-bab5-ad78-9ca8-8a773192c2d1",
       "locale" : "en",
       "ipAddress" : "172.16.1.6",
       "fullName" : "Administrator vlab.local",
       "userName" : "VLAB.LOCAL\\Administrator",
       "loginTime" : "2017-05-03T13:17:03.152908Z",
       "messageLocale" : "en",
       "userAgent" : "Perl/VMOMI",
       "_ancestors" : [
          "DynamicData"
       ],
       "callCount" : "0",
       "_class" : "UserSession"
    }

Two additional properties are added to the JSON encoded string, B<_class> and B<_ancestors>.  B<_class> is the
object's class name and B<_ancestors> provides the class inheritance in descending order.

=head2 Performance Considerations

Properties are only retrieved from the vSphere Web Services API on access through AUTOLOAD, and as such,
can impact performance in iterations. The following logic will invoke three API calls to vSphere for each 
virtual machine:

    @vms = VMOMI::find_entities($content, 'VirtualMachine');
    foreach (@vms) {
        print $_->name . ": " . $_->runtime->powerState . "\n"; # three API invocations
    }

As future enhancement, preserving values previously fetched from the API to avoid reptitive calls would
improve performance. As a work around, pulling requested properties in bulk through 
B<PropertyCollector.RetrievePropertiesEx> or B<PropertyCollector.WaitForUpdatesEx> and parsing them into 
a data structure will provide the best performance.

=head1 AUTHOR

Reuben M. Stump

reuben.stump@gmail.com

=head1 SEE ALSO

L<VMware vSphere Web Services SDK Documentation|https://www.vmware.com/support/developer/vc-sdk/>

L<vSphere SDK for Perl Documentation|https://www.vmware.com/support/developer/viperltoolkit/>

=head1 LICENSE

This code is distributed under the Apache 2 License. The full text of the license can be found in the 
LICENSE file included with this module.

=head1 COPYRIGHT

Copyright (c) 2015 by Reuben M. Stump

=cut
