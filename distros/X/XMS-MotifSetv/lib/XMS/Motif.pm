package XMS::Motif;

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
use TFBS::Matrix::ICM;
use TFBS::Matrix::PFM;


sub new {

    my $class = shift;
    my $self = {};
    my($weightmatrix,$name,$threshold,%prop) = @_;
    $self->{name} = $name;
    $self->{weightmatrix} = $weightmatrix;
    $self->{threshold} = 0.0;
    %{$self->{annotations}} = %prop;
    
    $self->{xmlString} = "";
    $self->{output} =  XML::Writer::String->new();
    $self->{writer} = new XML::Writer(OUTPUT => $self->{output}, DATA_MODE => 'TRUE', DATA_INDENT=>3);

    $self->{rawstring} = "";

    bless($self,$class);
   
    return $self;

}


sub toXML {

    my $self = shift;
    my $useLocalXMLWriter = 1;
    my $xmlString = $self->{xmlString};

    my $writer = $self->{writer};
    my $output = $self->{output};

    my ($wr) = @_;
    if( @_ && (ref($wr) eq "XML::Writer")){
	$writer = $wr;
	$useLocalXMLWriter = 0;
    }

    my $motifname = $self->{name};
    my $threshold = $self->{threshold};

    ##### Begin motif element here #######
    
    $writer->startTag("motif");
    $writer->startTag("name");
    $writer->characters($motifname);
    $writer->endTag("name");

    ###### Begin writing weightmatrix #######
   
    $self->{weightmatrix}->toXML($writer);
    
    ###### Ends weightmatrix ###############
    
    $writer->startTag("threshold");
    $writer->characters($threshold);
    $writer->endTag("threshold");

    ###### Begin writing annotation property set ######
    my %annotations = %{$self->{annotations}};
    while ((my $key,my $value) = each(%annotations)){
	$writer->startTag("prop");
        $writer->startTag("key");
        $writer->characters($key);
        $writer->endTag("key");
        $writer->startTag("value");
        $writer->characters($value);
        $writer->endTag("value");
        $writer->endTag("prop");
    }
    ###### End writing annotation property set ###### 
    
    $writer->endTag("motif");

    if($useLocalXMLWriter == 1 ) {
	$writer->end();
	$xmlString = $self->{output}->value();
    }

    return $self->{output}->value();
}


sub toString {

    my $self = shift;
    my $name = $self->{name};
    my $rawstring = $name; 

    my %annotations = %{$self->{annotations}};
    while ((my $key,my $value) = each(%annotations)){
	
	if($key && $value){
	    $rawstring = $rawstring.";".$key.":".$value;
	}
    }

    $rawstring = $rawstring. "\n". $self->{weightmatrix}->toString();
    return $rawstring;
}

sub weblogo {

    my $self = shift;
    my $name = $self->{name};
    
    my $rawstring = $self->{weightmatrix}->toString();
    
    
    my @matrix=split("\n",$rawstring);
    
    
    my $matrixstring = "";
    
    for(my $count=0;$count<4;$count++){
    for(my $m=0; $m<@matrix;$m++){  
    
    my @M = split(" ",$matrix[$m]); 
    
    $matrixstring = $matrixstring." ".$M[$count];
    }
    
    
    $matrixstring = $matrixstring."\n";
    }
    
           
    
    my $pfm = TFBS::Matrix::PFM->new(-matrixstring => $matrixstring,
      -name => $name);


   my $icm_version = $pfm->to_ICM($matrixstring); # convert to information con
   my $file=$name.".png";   
   
      $icm_version->draw_logo(-file=>$file,
                       -full_scale=>2.25,
                       -xsize=>500,
                       -ysize =>250,
                       -graph_title=>$name,
                       -x_title=>"position",
                       -y_title=>"bits");
                       
                       
   return $icm_version;

     }



1;
__END__


=head1 NAME

XMS::Motif - Perl module for creating DNA motifs in XMS format

=head1 SYNOPSIS

use XMS::Motif;

my $motif = XMS::Motif->new($wm,$name,$threshold)   # $wm is weightmatrix, $name is name of the motif and $threshold is the threshold value.
$motif -> toXML()         # Create motifs in XMS format
$motif -> toString()      # Create motifs in string/xms format


=head1 DESCRIPTION

The XMS::Motif package can be used to create the XMS format for a given set of motifs, their asscoiated weightmatrices and threshold values.

=head1 METHODS
XMS::Motif provides four methods, C<new()>, C<toXML()>, C<toString()> and C<weblogo()>:

=over

=item C<$w = XMS::Motif->new([list]);>

new() returns a new String handle.

=item C<$x = $w->toXML();>

toXML() converts the weightmatrix into a XMS format.

=item C<$s = $w->toString();>

toString() converts the weightmatrix into a string.

=item C<$logo = $w->weblogo();>
weblogo() creates a graphic weblogo (png file) for a motif. It depends on the TFBS::Matrix perl module.

=back

=head1 DEPENDENCIES

This module has external dependencies on the following modules:
Exporter
XML::Writer, 
IO::File
XMS::WeightMatrix

=head2 EXPORT

Nothing.


=head1 SEE ALSO

perl(1), XML::Writer, XMS::WeightMatrix, XMS::MotifSet

=head1 AUTHOR

Harpreet Saini, hsaini@ebi.ac.uk

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by harpreet saini

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.9 or,
at your option, any later version of Perl 5 you may have available.


=cut
