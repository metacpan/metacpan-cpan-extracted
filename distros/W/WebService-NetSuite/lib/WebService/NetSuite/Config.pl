#!/usr/bin/perl

use strict;
use warnings;
use Data::Dumper;
use Template;
use XML::Tiny;
use XML::Parser;
use XML::Parser::EasyTree;
$XML::Parser::EasyTree::Noempty=1;

use Cwd;
my $pwd = &Cwd::cwd();
my $tmp = "$pwd/Config.tmpl";
my $fil = "./Config.pm";

unlink $fil;

use File::Util;
my $f = File::Util->new();

use LWP::UserAgent;
my $ua = LWP::UserAgent->new;
$ua->timeout(10);
$ua->env_proxy;

my $debug = 1;
our $version='2013_2';
my $wsdl = 'https://webservices.netsuite.com/wsdl/v2013_2_0/netsuite.wsdl';
my $searchCommon = 'https://webservices.netsuite.com/xsd/platform/v2013_2_0/common.xsd';

# return full namespace for core, messages, common (all are in .platform)
sub namespace {
    my ($ns) = @_;
    return $ns . '_' . $version . '.platform';
}


undef my $hash_ref;
my $getSearchCommon = $ua->get($searchCommon);
print "Accessing $searchCommon\n";
if ($getSearchCommon->is_success) {
    
    my $p = new XML::Parser( Style=>'EasyTree' );
    my $tree = $p->parse($getSearchCommon->content);
    
    undef my @searchFieldTypes;
    for my $node (@{ $tree->[0]->{content} }) {
        if ($node->{name} eq 'complexType') {
            print "Examining node " . $node->{attrib}->{name} . "\n";
            undef my @searchFields;
            for my $element (@{ $node->{content}->[0]->{content}->[0]->{content}->[0]->{content} }) {
                $element->{attrib}->{type} =~ s/^(.*):(.*)$/$2/g;
                print "\tArchiving attribute " . $element->{attrib}->{name} . "\n";
                push @searchFields, { name => $element->{attrib}->{name}, type => $element->{attrib}->{type} };
            }
            push @searchFieldTypes, { name => $node->{attrib}->{name}, fields => \@searchFields };
        }
    }
    
    $hash_ref->{searchFieldTypes} = \@searchFieldTypes;
    
} else { die $getSearchCommon->status_line; }

my $getWsdl = $ua->get($wsdl);
print "Accessing $wsdl\n";
if ($getWsdl->is_success) {
    
    undef my @recordFields;
    undef my @recordNamespaces;
    undef my @searchNamespaces;
    undef my @searchRecordTypes;
    
    my $p = new XML::Parser( Style=>'EasyTree' );
    my $wsdl = $p->parse($getWsdl->content);
    
    undef my $systemNamespaces;
    for my $node (@{ $wsdl->[0]->{content}->[0]->{content}->[0]->{content} }) {
        my $namespace = $node->{attrib}->{namespace};
        print "Accessing namespace $namespace\n";
        #my ($mapping) = ($node->{attrib}->{namespace} =~ /^urn:(.*)_(\d+)_(\d+).*$/);
        my $mapping = $namespace;
        $mapping =~ s/urn://;
        $mapping =~ s/types\.//;
        $mapping =~ s/\.webservices\.netsuite\.com//;
        #print "mapping= $mapping\n";
        #if ($mapping =~ /^types.(.*)/) { $mapping = $1 . 'Types'; }
        print "Parsed namespaces to $mapping\n";
        $systemNamespaces->{$mapping} = $namespace if !defined $systemNamespaces->{$mapping};
        
        my $getSchema = $ua->get($node->{attrib}->{schemaLocation});
        print "Deeper Accessing " . $node->{attrib}->{schemaLocation} . "\n";
        if ($getSchema->is_success) {
            my $schema = $p->parse($getSchema->content);
            for my $element (@{ $schema->[0]->{content} }) {
                if ($element->{name} eq 'xsd:import' or $element->{name} eq 'import') {
                    my $namespace = $element->{attrib}->{namespace};
                    print "Accessing namespace $namespace\n";
                    $mapping =~ s/urn://;
                    $mapping =~ s/types\.//;
                    $mapping =~ s/\.webservices\.netsuite\.com//;
                    #my ($mapping) = ($element->{attrib}->{namespace} =~ /^urn:(.*)_(\d+)_(\d+).*$/);
                    #if ($mapping =~ /^types.(.*)/) { $mapping = $1 . 'Types'; }
                    print "Parsed namespaces to $mapping\n";
                    $systemNamespaces->{$mapping} = $namespace if !defined $systemNamespaces->{$mapping};
                }
            }
        } else { die $getSchema->status_line; } 
    }
    
    undef my @systemNamespaces;
    for my $mapping (keys %{ $systemNamespaces }) {
        print "Namespace $mapping ($systemNamespaces->{$mapping}) logged.\n";
        push @systemNamespaces, {
            namespace => $systemNamespaces->{$mapping},
            mapping => $mapping
        };
    }
    
    undef my %recNamespace;

    for my $node (@{ $wsdl->[0]->{content}->[0]->{content}->[0]->{content} }) {
        #$node->{attrib}->{namespace} =~ s/^urn:(.*)_(\d+)_(\d+).*$/$1/g;
        $node->{attrib}->{namespace} =~ s/urn://;
        next if $node->{attrib}->{namespace} =~ /^types/;
        $node->{attrib}->{namespace} =~ s/types\.//;
        $node->{attrib}->{namespace} =~ s/\.webservices\.netsuite\.com//;
        #next if grep $_ eq $node->{attrib}->{namespace}, qw(core faults messages common);
        next if grep $node->{attrib}->{namespace} =~ $_, qw(core_ faults_ messages_ common_);
        #print "Processing ".$node->{attrib}->{namespace}."\n";
        
        my $getSchema = $ua->get($node->{attrib}->{schemaLocation});
        if ($getSchema->is_success) {
            my $schema = $p->parse($getSchema->content);
            for my $element (@{ $schema->[0]->{content} }) {
                if ($element->{name} eq 'complexType') {

                    # determine which types of JOINS can be done with a search
                    # for example: can I do I customerJoin with a task search?
                    if ($element->{attrib}->{name} =~ /Search$/) {
                        
                        print "Found a search complexType " . $element->{attrib}->{name} . "\n"; 
                        undef my @searchTypes;
                        for my $field (@{ $element->{content}->[0]->{content}->[0]->{content}->[0]->{content} }) {
                            $field->{attrib}->{type} =~ s/^(.*):(.*)$/$2/g;
                            print "\tFound search name " . $field->{attrib}->{name} . "\n";
                            push @searchTypes, {
                                name => $field->{attrib}->{name},
                                type => $field->{attrib}->{type},
                            };
                        }
                        
                        push @searchRecordTypes, {
                            name => $element->{attrib}->{name},
                            types => \@searchTypes
                        };
                        
                    }
                    # if it is a record type, it will have a complexContent container
                    elsif ($element->{content}->[0]->{name} eq 'complexContent') {
                        print "Found a content complexType " . $element->{attrib}->{name} . "\n"; 
                        
                        undef my @fieldTypes;
                        for my $field (@{ $element->{content}->[0]->{content}->[0]->{content}->[0]->{content} }) {
                            print '$field->{attrib}=' . Dumper($field->{attrib});
                            if ($field->{attrib}->{type} =~ m/^xsd:(.*)$/) {
                                ; # leave xsd type as is
                            }
                            elsif ($field->{attrib}->{type} =~ m/^platform(.*)Typ:(.*)$/) {
                                $field->{attrib}->{type} = namespace(lcfirst($1)) . 'Types' . ':' . $2;
                            }
                            elsif ($field->{attrib}->{type} =~ m/^platform(.*):(.*)$/) {
                                $field->{attrib}->{type} = namespace(lcfirst($1)) . ':' . $2;
                            }
                            elsif ($field->{attrib}->{type} =~ m/^.*Typ:(.*)$/) {
                                $field->{attrib}->{type} = $node->{attrib}->{namespace} . 'Types' . ':' . $1;
                            }
                            elsif ($field->{attrib}->{type} =~ m/^.*:(.*)$/) {
                                $field->{attrib}->{type} = $node->{attrib}->{namespace} . ':' . $1;
                            }
                            print "\tFound content name " . $field->{attrib}->{name} . "\n";
                            push @fieldTypes, {
                                name => $field->{attrib}->{name},
                                type => $field->{attrib}->{type},
                            };
                        }
                        
                        push @recordFields, {
                            name => $element->{attrib}->{name},
                            types => \@fieldTypes
                        };
                    }
                    elsif ($element->{content}->[0]->{name} eq 'sequence') {
                        print "Found a sequence complexType " . $element->{attrib}->{name} . "\n"; 
                        
                        undef my @fieldTypes;
                        for my $field (@{ $element->{content}->[0]->{content} }) {
                            if ($field->{attrib}->{type} =~ m/^xsd:(.*)$/) {
                                ; # leave xsd type as is
                            }
                            elsif ($field->{attrib}->{type} =~ m/^platform(.*)Typ:(.*)$/) {
                                $field->{attrib}->{type} = namespace(lcfirst($1)) . 'Types' . ':' . $2;
                            }
                            elsif ($field->{attrib}->{type} =~ m/^platform(.*):(.*)$/) {
                                $field->{attrib}->{type} = namespace(lcfirst($1)) . ':' . $2;
                            }
                            elsif ($field->{attrib}->{type} =~ m/^.*Typ:(.*)$/) {
                                $field->{attrib}->{type} = $node->{attrib}->{namespace} . 'Types' . ':' . $1;
                            }
                            elsif ($field->{attrib}->{type} =~ m/^.*:(.*)$/) {
                                $field->{attrib}->{type} = $node->{attrib}->{namespace} . ':' . $1;
                            }
                            print "\tFound sequence name " . $field->{attrib}->{name} . "\n";
                            push @fieldTypes, {
                                name => $field->{attrib}->{name},
                                type => $field->{attrib}->{type},
                            };
                        }
                        
                        push @recordFields, {
                            name => $element->{attrib}->{name},
                            types => \@fieldTypes
                        };
                        
                    }
                }
                if (defined($element->{attrib}->{name})) {
                    my $eleName = lcfirst($element->{attrib}->{name});
                    if (($element->{name} eq 'element') ||
                        (($element->{name} eq 'complexType')
                         && defined($element->{content}->[0]->{content}->[0]->{attrib}->{base})
                         && $element->{content}->[0]->{content}->[0]->{attrib}->{base} eq 'platformCore:Record')) {
                        if ($element->{attrib}->{name} =~ /Search$/) {
                            push @searchNamespaces, {
                                type => ucfirst($element->{attrib}->{name}),
                                namespace => $node->{attrib}->{namespace},
                            };
                        } elsif (!defined($recNamespace{$eleName})) {
                            push @recordNamespaces, {
                                type => $eleName,
                                namespace => $node->{attrib}->{namespace},
                            };
                            $recNamespace{$eleName} = $node->{attrib}->{namespace};
                        }
                    }
                }
            }
        }
        else { die $getSchema->status_line; } 
    }
    
    #print "recordFields\n" . Dumper(@recordFields);
    $hash_ref->{recordFields} = \@recordFields;
    $hash_ref->{searchNamespaces} = \@searchNamespaces;
    $hash_ref->{recordNamespaces} = \@recordNamespaces;
    $hash_ref->{systemNamespaces} = \@systemNamespaces;
    $hash_ref->{searchRecordTypes} = \@searchRecordTypes;
    
} else { die $getWsdl->status_line; }

undef my $output;
my $tt = Template->new({ ABSOLUTE => 1 }) or die "$Template::ERROR\n";
$tt->process($tmp, $hash_ref, \$output) or die $tt->error(), "\n";
$f->write_file('file' => $fil, 'content' => $output);


__END__

=head1 NAME

Config.pl - A perl script that created the configuration file for the NetSuite module.

=head1 SYNOPSIS

    bash> ./Config.pl

=head1 DESCRIPTION

This module reads the WSDL file for NetSuite and produces a configuration file that is used by 
the NetSuite module to ensure fields are being properly mapped to their respective values.  It 
should only need to be run everytime there is an upgrade.

=head1 USAGE

This script accepts a total of __two__ variables:

    $wsdl; # the URL to the WSDL file to parse
    $searchCommon; # the URL to the common xsd file

=head1 HOW IT WORKS

This module begins by traversing the common XSD file looking for ComplexTypes.  Where there 
is a ComplexType there is a different type of __search__.  Because the common XSD file contains 
a mapping of all potential search values, we want to make sure we know everything we can search 
for.  When run you will see each search it reviews and the fields it processes.

After reviewing the common XSD file the module downloads the WSDL file and begins parsing the 
various namespaces.  Each namespace is converted to a common name.  For example:

    Namespace: urn:accounting_2008_1.lists.webservices.netsuite.com
    Converts to: accounting
    Namespace: urn:types.accounting_2008_1.lists.webservices.netsuite.com
    Converts to: accountingTypes

This namespace conversion and cataloging is two-tiered.  Meaning it reviews each of the namespaces
in the WSDL file, then follows the schema locations to the individual XSD files, and then once 
again looks for namespaces it hasn't yet included in the mapping.  When run, you will see each
namespace and then its conversion to a proper name. 

After compiling a list of schemas the module traverses each XSD file (excluding core, faults, 
messages, and commmon) and assembles a list of names and types for each value in a record.  
In essence, it stores the schema of each NetSuite record to the configuration file.  
This way we know what values __should__ be associated with each record type.

=head1 AUTHOR

Jonathan Lloyd, L<mailto:webmaster@lifegames.org>

=cut
