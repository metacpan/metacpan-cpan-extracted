package XMS::MotifSet;

use 5.008008;
use strict;
use warnings;
use Carp;
require Exporter;

our @ISA = qw(Exporter);


# This allows declaration	use XMS ':all';


our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.01';

use XML::Writer;
use XML::Writer::String;
use IO::File;
use XMS::WeightMatrix;
use XMS::Motif;
use XML::DOM;



sub new {

    my $class = shift;
    my $self = {};
    my(@motifs) = @_;
    my ($temp) = @motifs;

    if(ref($temp) eq "XMS::Motif"){
	@{$self->{motifs}} = @motifs;

    }else{
	
	my $parser = new XML::DOM::Parser;
	my $doc = $parser->parsefile($temp);
	my $root = $doc->getDocumentElement();
	
	my @motifnodes = $root->getElementsByTagName("motif");
	
	if (scalar @motifnodes == 0){
	    die "Corrupt input XMS file";
	}
	
	my $m=0;
	my @motifarray=();

	foreach my $motif (@motifnodes){
	    
    
	    my $motifname = $motif->getElementsByTagName("name")->item(0)->getFirstChild()->getData;
	    	    
	    my $threshold = $motif->getElementsByTagName("threshold")->item(0)->getFirstChild->getData;
	    
	    my @props = $motif->getElementsByTagName("prop");
	 
	    ####### Begin reading annotation key value pairs ##########
	    
	    my %annotations;
	    foreach my $prop (@props){
		my ($keynode) = $prop->getElementsByTagName("key");
		my $key="";
		if ( $keynode->getFirstChild() ) {
		    $key = $keynode->getFirstChild()->getData;
		}
		my ($valuenode) = $prop->getElementsByTagName("value");
	 	my $value="";
		if ( $valuenode->getFirstChild() ) {
		    $value = $valuenode->getFirstChild()->getData;
		}
		if ( $key ne "" ){
		    $annotations{$key} = $value;
		}
	    }

	    ####### End reading annotation key value pairs ########## 

	    my @wmnodes = $motif->getElementsByTagName("weightmatrix");
	    my @columnsarray=();
	    foreach my $wmnode (@wmnodes) {

		my @columns=$motif->getElementsByTagName("column");

		my %columnhash;
		foreach my $column (@columns){
        
		   my @weights=$column->getElementsByTagName("weight");

		    foreach my $weight (@weights){
        
			my $weightsymbol = $weight->getAttributeNode("symbol");
			my $symbolvalue = $weightsymbol->getValue;
        
			my $weightvalue=$weight->getFirstChild->getData;

			$columnhash{$symbolvalue} = $weightvalue;
		    }
		   my $count=0;
		   my @wmvalues=();
		   foreach my $key (sort keys %columnhash){
		       $wmvalues[$count]=$columnhash{$key};
		       $count++;
		   }
		   push(@columnsarray,[@wmvalues]);
		}
	    }

	    my $wmobj = XMS::WeightMatrix->new(@columnsarray);
	    my $motifobj = XMS::Motif->new($wmobj,$motifname,$threshold,%annotations);
	    $motifarray[$m] = $motifobj;
	    $m++;
	}
	@{$self->{motifs}} = @motifarray;
    }

    $self->{output} =  XML::Writer::String->new();
    $self->{writer} = new XML::Writer(OUTPUT => $self->{output}, DATA_MODE => 'TRUE', DATA_INDENT=>3);

    bless($self,$class);
    return $self;
	    
}


sub toXML {

    my $self = shift;
    my $writer = $self->{writer};
    my $output = $self->{output};

    my @motifs = @{$self->{motifs}};


    $writer->startTag("motifset");
    for(my $m=0;$m<@motifs;$m++){    
	$self->{motifs}[$m]->toXML($writer);
    }

    $writer->endTag("motifset");

    $writer->end();
    return $self->{output}->value();
}


sub toString {

    my $self = shift;
    my @motifs = @{$self->{motifs}};

    my $rawstring = "";
   
    for(my $m=0;$m<@motifs;$m++){                                               
        $rawstring = $rawstring.$self->{motifs}[$m]->toString();
        if ($m<(@motifs-1)){
	    $rawstring = $rawstring."\n";
	}                            
    }
    return $rawstring;
}


1;
__END__


=head1 NAME

XMS::MotifSet - Perl module for creating XMS Motifset from a given array of motifs

=head1 SYNOPSIS

  use XMS::MotifSet;

  my $motifset = XMS::MotifSet->new(@motif);   # @motif is an array of motifs
  $motifset->toXML();       # Creating motifset in xms format
  $motifset->toString();    # Creatin motifset in string format
  

=head1 DESCRIPTION

The XMS::MotifSet package is used to create motifset in XMS and string format from a given array of motifs.

=head1 METHODS
XMS::MotifSet provides three methods, C<new()>, C<toXML()> and C<toString()>:

=over

=item C<$m = XMS::MotifSet->new([array]);>

new() returns a new String handle.

=item C<$x = $m->toXML();>

toXML() converts an array of motifs into a XMS format motifset.

= item C<$s = $m->toString();>

toString() converts an array of motifs into a string motifset.

=back

=head1 DEPENDENCIES

This module has external dependencies on the following modules:
Exporter
XML::Writer, 
IO::File
XML::DOM
XMS::Motif
XMS::WeightMatrix

=head2 EXPORT

Nothing

=head1 SEE ALSO
perl(1), XML::Writer, XML::DOM, XMS::WeightMatrix, XMS::Motif

=head1 AUTHOR

Harpreet Saini, hsaini@ebi.ac.uk

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by harpreet saini

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.9 or,
at your option, any later version of Perl 5 you may have available.


=cut
