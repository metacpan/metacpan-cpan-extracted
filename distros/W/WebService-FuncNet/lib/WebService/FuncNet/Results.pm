package WebService::FuncNet::Results;

use strict;
use warnings;

use Math::BigFloat;
use XML::Simple;
use Text::CSV;
use Carp;

our $VERSION = '0.2';

=head1 NAME

WebService::FuncNet::Results - object encapsulating results

=head1 FUNCTIONS

=head2 new

Creates a new instance of the results object. 

Do not use this function directly.

=cut

sub new {
   my $class    = shift;
   my $rah_data = shift;
   my $self     = { };
   
   bless $self, $class;
   $self->{'data'} = $rah_data;
   
   return $self;
}

=head2 prepare_data

Internal function used by all output format-specific functions in order to 
prepare the data. Essentially, it sorts the output the service returns on
the raw pairwise score in descending order.

Do not use this function directly.

=cut

sub prepare_data {
   my $self     = shift;
   my $rah_raw  = shift;
   
   return
      unless ( $rah_raw && ref $rah_raw eq 'ARRAY' );
   
   my $rah_unsorted = [ ];

     foreach my $rh ( @$rah_raw ) {
        my $p1 = $rh->{p1};                                ## query protein
        my $p2 = $rh->{p2};                                ## reference protein
        my $rs_mbfo = Math::BigFloat->new( $rh->{'rs'} );  ## raw score 
        my $pv_mbfo = Math::BigFloat->new( $rh->{'pv'} );  ## p-value

        my $rh = {
           p1 => $p1,
           p2 => $p2,
           rs => $rs_mbfo->bstr,
           pv => $pv_mbfo->bstr,
        };

        push ( @$rah_unsorted, $rh );
     }
   
   ## sort by rs value descending
   my @sorted = sort { $b->{rs} <=> $a->{rs} } @$rah_unsorted ;

   return \@sorted;
}


=head2 as_csv

Formats and returns the data in CSV format. The data is returned as a reference
to an array where each line is a comma separated string. The elements are:
query protein, reference protein, raw score, p-value. The data is sorted by raw score
in descending order.

   my $ra_data = $R->as_csv;

More information on the output of the function can be found at 
L<http://funcnet.eu/wsdls/example-queries/>

This function returns I<undef> on error.

=cut

sub as_csv {
   my $self     = shift;
   my $rah_data = $self->{'data'};
   
   return 
      unless ( defined $rah_data && ref $rah_data eq 'ARRAY' );
   
   my $rah_sorted_data = 
      $self->prepare_data( $rah_data );
   
   my $csv = Text::CSV->new();
   my $ra_output = [ ];
   
   foreach my $rh ( @$rah_sorted_data ) {
      my $ra     = [ $rh->{p1}, $rh->{p2}, $rh->{rs}, $rh->{pv} ];
      my $status = $csv->combine( @$ra );
      if ( $status ) {
         push (@$ra_output, $csv->string );
      } else {
         carp 'Failed to create CSV output';
         return;
      }
   }

   return $ra_output;
}

=head2 as_tsv

Formats and returns the data in TSV format. The data is returned as a reference
to an array where each line is a tab separated string. The elements are:
query protein, reference protein, raw score, p-value. The data is sorted by raw score
in descending order.

   my $ra_data = $R->as_tsv;

More information on the output of the function can be found at 
L<http://funcnet.eu/wsdls/example-queries/>

This function returns I<undef> on error.

=cut

sub as_tsv {
   my $self     = shift;
   my $rah_data = $self->{'data'};
   
   return 
      unless ( defined $rah_data && ref $rah_data eq 'ARRAY' );
   
   my $rah_sorted_data = 
      $self->prepare_data( $rah_data );
   
   my $tsv = Text::CSV->new({ sep_char => "\t"  });
   my $ra_output = [ ];
   
   foreach my $rh ( @$rah_sorted_data ) {
      my $ra     = [ $rh->{p1}, $rh->{p2}, $rh->{rs}, $rh->{pv} ];
      my $status = $tsv->combine( @$ra );
      if ( $status ) {
         push (@$ra_output, $tsv->string );
      } else {
         carp 'Failed to create TSV output';
         return;
      }
   }

   return $ra_output;
}

=head2 as_xml

Formats and returns the data in CSV format. Returns a scalar which contains the 
XML markup. The root node is named 'results'. 

B<Tip>: each pairwise result is stored
under an XML element named 'anon'. This way, you can use XMLin from XML::Simple
and reconstruct a reference to a array of anonymos hashes easily.

   my $xml = $R->as_xml;
   
More information on the output of the function can be found at 
L<http://funcnet.eu/wsdls/example-queries/>

Example output:

   <results>
      <anon>
         <p1>Q9H8H3</p1>
         <p2>O75865</p2>
         <pv>0.8059660198021762</pv>
         <rs>1.615708908613666</rs>
      </anon>
      <anon>
         <p1>P22676</p1>
         <p2>A3EXL0</p2>
         <pv>0.9246652723089276</pv>
         <rs>0.8992717754263188</rs>
      </anon>
      <anon>
         <p1>Q5SR05</p1>
         <p2>A3EXL0</p2>
         <pv>0.9739920871688543</pv>
         <rs>0.49493596412217056</rs>
      </anon>
  </results>

This function returns I<undef> on error.

=cut

sub as_xml {
   my $self     = shift;
   my $rah_data = $self->{'data'};
   
   return 
        unless ( defined $rah_data && ref $rah_data eq 'ARRAY' );

   my $rah_sorted_data = 
     $self->prepare_data( $rah_data );
   
   my $xml = 
      XML::Simple::XMLout( 
         $rah_sorted_data, 
         'AttrIndent' => 1, 
         'NoAttr'     => 1,
         'RootName'   => 'results' );
   
   if ( $xml ) {
      return $xml;
   } else {
      carp 'Failed to create XML output';
      return;
   }
}

1;

=head1 REVISION INFO

  Revision:      $Rev: 64 $
  Last editor:   $Author: andrew_b_clegg $
  Last updated:  $Date: 2009-07-06 16:12:20 +0100 (Mon, 06 Jul 2009) $

The latest source code for this project can be checked out from:

  https://funcnet.svn.sf.net/svnroot/funcnet/trunk

=cut
