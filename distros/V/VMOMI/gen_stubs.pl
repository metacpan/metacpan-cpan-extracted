#!/usr/bin/env perl

use strict;
use warnings;

use XML::LibXML;
use Getopt::Long;

my ($src, $dst, $ns, %complex_types, %simple_types, %operations, %requests, %responses, $stub_definition);

GetOptions(
    "src:s" => \$src,
    "dst:s" => \$dst,
    "namespace:s" => \$ns,
);

$src = "SDK/vsphere-ws/wsdl/vim25/" unless $src;
$dst = "lib/VMOMI/" unless $dst;
$ns  = "VMOMI" unless $ns;

## Object Types (SimpleType|ComplexType) ##
foreach ('core-types.xsd', 'query-types.xsd', 'vim-types.xsd') {
    my ($xml, @nodes);
    
    $xml = XML::LibXML->load_xml(location => $src . "/$_") || die $!;

    ## ComplexTypes
    @nodes = $xml->getElementsByTagName('complexType');
    foreach my $node (@nodes) {
        my $name = $node->getAttribute('name');

        # Ignore ManagedObjectReference
        next if $name eq 'ManagedObjectReference';

        $complex_types{$name} = ComplexTypeDef->new($name, $node);
    }

    ## SimpleTypes
    @nodes = $xml->getElementsByTagName('simpleType');
    foreach my $node (@nodes) {
        my $name = $node->getAttribute('name');
        $simple_types{$name} = SimpleTypeDef->new($name, $node);
    }
}

## Generate ancestors list for ComplexTypes
foreach (keys %complex_types) {
    my ($typedef, $parent, @ancestors);

    $typedef = $complex_types{$_};
    $parent  = $typedef->{'parent'};

    # Implicit understanding of ComplexType as the final ancestor
    next if $parent eq 'ComplexType';

    while (defined $parent) {
        my ($parent_typedef);

        $parent_typedef = $complex_types{$parent};
        push @ancestors, $parent;
        $parent = $parent_typedef->{'parent'};

        $parent = undef if $parent eq 'ComplexType';
    }
    $complex_types{$_}->{'ancestors'} = \@ancestors;
}

## Request Messages ##
foreach ('query-messagetypes.xsd', 'vim-messagetypes.xsd') {
    my ($xml, @nodes);

    $xml = XML::LibXML->load_xml(location => $src . "/$_") || die $!;
    @nodes = $xml->getElementsByTagName('complexType');
    foreach my $node (@nodes) {
        my $name = $node->getAttribute('name');
        $requests{$name} = RequestTypeDef->new($name, $node);
    }

}

## Response Messages ##
foreach ('vim.wsdl') {
    my ($xml, $root, $schema, @nodes);

    $xml    = XML::LibXML->load_xml(location => $src . "/$_") || die $!;
    $root   = $xml->documentElement();
    $schema = $root->getChildrenByTagName('types')->shift->getChildrenByTagName('schema')->shift;
    @nodes = $xml->getElementsByTagName('element');
    foreach my $node (@nodes) {
        my $name = $node->getAttribute('name');

        # Fault responses are handled generically in the SDK logic
        next if $name !~ m/Response$/;
        
        $responses{$name} = ResponseTypeDef->new($name, $node);
    }
}

## Operations ##
foreach ('vim.wsdl') {
    my ($xml, $root, $schema, @nodes);

    $xml    = XML::LibXML->load_xml(location => $src . "/$_") || die $!;
    $root   = $xml->documentElement();
    $schema = $root->getChildrenByTagName('types')->shift->getChildrenByTagName('schema')->shift;
    
    
    @nodes = $schema->getChildrenByTagName('element');
    foreach my $node (@nodes) {
        my ($name, $operation, $res_name, $res_type, $req_name, $req_type);
        
        $name = $node->getAttribute('name');
        next if $name =~ m/(Response$|versionURI|Fault$)/;

        $operation = OperationTypeDef->new($name, $node);
        
        $req_name = $operation->{'req_type'};
        $req_type = $requests{$req_name};
        $operation->set_xargs($req_type);

        $res_name = $operation->{'res_type'};
        $res_type = $responses{$res_name};
        $operation->set_returnval($res_type);

        $operations{$name} = $operation;
    }
}

## Write class files
foreach ( (values %simple_types, values %complex_types) ) {
    $_->write_file($ns, $dst);
}

## Write SoapStub.pm
open FILE, ">$dst/SoapStub.pm" or die "failed to open '$dst/SoapStub.pm: $!'";

$stub_definition .= "package $ns" . "::SoapStub;\n";
$stub_definition .= "use parent '$ns" . "::SoapBase';\n\n";
$stub_definition .= "use strict;\nuse warnings;\n\n";

foreach ( sort keys %operations ) {
    my ($operation, $name, $xargs, $returnval, $ret_type, $ret_array);

    $operation = $operations{$_};
    $name = $operation->{'name'};
    $xargs = $operation->{'xargs'};
    $returnval = $operation->{'returnval'};

    $ret_type  = defined $returnval->[0] ? "'" . $returnval->[0] . "'" : 'undef';
    $ret_array = defined $returnval->[1] ? $returnval->[1] : 0;

    $stub_definition .= "sub $name {\n";
    $stub_definition .= "    my (\$self, \%args) = \@_;\n";
    $stub_definition .= "    my \$x_args = [ ";

    # operation xargs
    if (scalar @$xargs > 0) {
        $stub_definition .= "\n";
        foreach my $x (@{ $operation->{'xargs'} || [ ] }) {
            my ($x_name, $x_type, $is_array, $is_mandatory) = @$x;
            
            $x_type = defined $x_type ? "'$x_type'" : 'undef';
            $stub_definition .= "      ['$x_name', $x_type],\n";
        }
    }
    $stub_definition .= "    ];\n";
    $stub_definition .= "    return \$self->soap_call('$name', $ret_type, $ret_array, \$x_args, \\%args);\n";
    $stub_definition .= "}\n\n";
}

$stub_definition .= "1;\n";

print FILE $stub_definition;
close FILE;


package OperationTypeDef;

sub new {
    my ($class, $cname, $node) = @_;
    my ($self, $type);

    $self = {
        name => $cname,
        xargs => [ ],
        returnval => [undef, 0],
        req_type => undef,
        res_type => undef,
    };

    $type = $node->getAttribute('type');
    $type =~ s/^vim25://;
    if ($type =~ m/^xsd:boolean/) {
        $type = 'boolean';
    } 
    if ($type =~ m/^xsd:anyType/) {
        $type = 'anyType';
    }
    if ($type =~ m/^xsd:/) {
        $type = undef;
    }

    $self->{'req_type'} = $type;
    $self->{'res_type'} = $cname . "Response";

    return bless $self, $class;
}

sub set_returnval {
    my ($self, $res_type) = @_;
    my ($type, $is_array);
    
    $type       = $res_type->{'type'};
    $is_array   = $res_type->{'is_array'};
    
    $self->{'returnval'} = [$type, $is_array];
    return;
}

sub set_xargs {
    my ($self, $req_type) = @_;
    my ($members);

    $members = $req_type->{'members'};
    foreach (@{ $members || [ ] }) {
        my ($name, $type, $min, $max, $is_array, $is_mandatory);

        $name = $_->[0];
        $type = $_->[1];
        $min  = $_->[2];
        $max  = $_->[3];

        # mandatory?
        $is_mandatory = (defined $min and $min eq "0") ? 0 : 1;

        # array?
        $is_array = defined $max ? 1 : 0;

        push @{$self->{'xargs'}}, [$name, $type, $is_array, $is_mandatory];
    }

    return;
}


1;

package ResponseTypeDef;

sub new {
    my ($class, $cname, $node) = @_;
    my ($self, $return_node, $type, $min, $max, $is_array, $is_mandatory);

    $self = {
        name => $cname,
        type => undef,
        is_array => 0,
    };

    $return_node = $node->getElementsByTagName('element')->shift;
    if (defined $return_node) {
        $type = $return_node->getAttribute('type');
        $min  = $return_node->getAttribute('minOccurs');
        $max  = $return_node->getAttribute('maxOccurs');

        $type =~ s/^vim25://;
        if ($type =~ m/^xsd:boolean/) {
            $type = 'boolean';
        } 
        if ($type =~ m/^xsd:anyType/) {
            $type = 'anyType';
        }
        if ($type =~ m/^xsd:/) {
            $type = undef;
        }
        
        $self->{'type'} = $type;
        $self->{'is_array'} = defined $max ? 1 : 0;
    }

    return bless $self, $class;
}


1;

package RequestTypeDef;

sub new {
    my ($class, $cname, $node) = @_;

    my $self = {
        name => $cname,
        members => [ ],
    };
    foreach my $member_node ( $node->getElementsByLocalName('element') ) {
        my ($name, $type, $min, $max);

        $name = $member_node->getAttribute('name');
        $type = $member_node->getAttribute('type');
        $min  = $member_node->getAttribute('minOccurs');
        $max  = $member_node->getAttribute('maxOccurs');

        $type =~ s/^vim25://;
        if ($type =~ m/^xsd:boolean/) {
            $type = 'boolean';
        } 
        if ($type =~ m/^xsd:anyType/) {
            $type = 'anyType';
        }
        if ($type =~ m/^xsd:/) {
            $type = undef;
        }

        push @{ $self->{'members'} }, [$name, $type, $min, $max];
    }

    return bless $self, $class;
}

1;

package SimpleTypeDef;

sub new {
    my ($class, $cname, $node) = @_;
    my ($self, $restriction);
    
    $self = {
        name        => $cname,
        parent      => 'SimpleType',
        ancestors   => [ ],
        members     => [ ],
    };

    $restriction = $node->getElementsByLocalName('restriction')->shift;
    if ($restriction->getAttribute('base') !~ m/^xsd:string/) {
        die "unexpected base type: " . $restriction->getAttribute('base') . " in SimpleType '$cname'";
    }
    # TODO: Parse restriction nodes as enum values for SimpleType for validation and/or constructor
    
    return bless $self, $class;
}

sub write_file {
    my ($self, $namespace, $path) = @_;
    my ($class_name, $super_name, $fname, $class_definition);

    $fname = $path . "/" . $self->{'name'} . ".pm";
    open FILE, ">$fname" or die "failed to open $fname: $!";

    $class_name = $self->{'name'};
    $super_name = $self->{'parent'};

    $class_definition .= "package $ns::$class_name;\n";
    $class_definition .= "use parent '$ns::$super_name';\n\n";
    $class_definition .= "use strict;\nuse warnings;\n\n";
    $class_definition .= "1;\n";

    print FILE $class_definition;
    close FILE;
}

1;

package ComplexTypeDef;

sub new {
    my ($class, $cname, $node) = @_;
    my ($self, $super_node, $super_name);

    $self = { 
        name        => $cname, 
        parent      => 'ComplexType',
        ancestors   => [ ],
        members     => [ ] 
    };    
    
    # Determine class parent
    $super_node = $node->getElementsByLocalName('extension')->shift;
    if (defined $super_node) {
        $super_name = $super_node->getAttribute('base');
        $super_name =~ s/^vim25://;
    }
    $self->{'parent'} = $super_name if defined $super_name;

    # Iterate class members
    foreach my $member_node ( $node->getElementsByLocalName('element') ) {
        my ($name, $type, $min, $max, $is_array, $is_mandatory);
        $name = $member_node->getAttribute('name');
        $type = $member_node->getAttribute('type');
        $min  = $member_node->getAttribute('minOccurs');
        $max  = $member_node->getAttribute('maxOccurs');

        # type
        $type =~ s/^vim25://;
        if ($type =~ m/^xsd:boolean/) {
            $type = 'boolean';
        } 
        if ($type =~ m/^xsd:anyType/) {
            $type = 'anyType';
        }
        if ($type =~ m/^xsd:/) {
            $type = undef;
        }

        # array?
        $is_array = defined $max ? 1 : 0;

        # mandatory?
        $is_mandatory = defined $min and $min eq "0" ? 0 : 1;

        push @{ $self->{'members'} }, [$name, $type, $is_array, $is_mandatory];
    }

    return bless $self, $class;
}

sub write_file {
    my ($self, $namespace, $path) = @_;
    my ($class_name, $super_name, $fname, $class_definition, @ancestors, @members);

    $fname = $path . "/" . $self->{'name'} . ".pm";
    open FILE, ">$fname" or die "failed to open $fname: $!"; 

    $class_name = $self->{'name'};
    $super_name = $self->{'parent'};

    $class_definition .= "package $ns::$class_name;\n";
    $class_definition .= "use parent '$ns::$super_name';\n\n";
    $class_definition .= "use strict;\nuse warnings;\n\n";

    # Bug with OptionDef, present in 5.5 and possibly older versions?  Current VMODL doesn't define DynamicData
    # and will raise runtime errors when interfacing with vSphere prior to 6.0
    # https://kb.vmware.com/selfservice/microsites/search.do?language=en_US&cmd=displayKC&externalId=2101118
    if ($class_name eq 'DynamicData') {
        push @{ $self->{'members'} }, ['dynamicProperty', 'DynamicProperty', 1, 0];
        push @{ $self->{'members'} }, ['dynamicType', undef, 0, 0];
    }

    # class ancestors
    @ancestors = @{ $self->{'ancestors'} };
    $class_definition .= "our \@class_ancestors = ( ";
    if (scalar @ancestors > 0) {
        $class_definition .= "\n";
        foreach my $ancestor (@ancestors) {
            $class_definition .= "    '$ancestor',\n";
        }
    }
    $class_definition .= ");\n\n";

    # class members
    @members = @{ $self->{'members'} };
    $class_definition .= "our \@class_members = ( ";
    if (scalar @members > 0) {
        $class_definition .= "\n";
        foreach my $member (@members) {
            my ($name, $type, $is_array, $is_mandatory) = @$member;
            
            $type = defined $type ? "'$type'" : 'undef';
            $class_definition .= "    ['$name', $type, $is_array, $is_mandatory],\n";       
        }
    }

    $class_definition .= ");\n\n";
    $class_definition .= "sub get_class_ancestors {\n";
    $class_definition .= "    return \@class_ancestors;\n";
    $class_definition .= "}\n\n";
    $class_definition .= "sub get_class_members {\n";
    $class_definition .= "    my \$class = shift;\n";
    $class_definition .= "    my \@super_members = \$class->SUPER::get_class_members();\n";
    $class_definition .= "    return (\@super_members, \@class_members);\n";
    $class_definition .= "}\n\n1;\n";

    print FILE $class_definition;
    close FILE;
}

1;