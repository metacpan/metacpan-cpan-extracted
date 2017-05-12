package WWW::Wikipedia::TemplateFiller::Source::HgncId;
use base 'WWW::Wikipedia::TemplateFiller::Source';

use warnings;
use strict;

use Carp;

sub search_class { 'HGNC' }

sub get {
  my( $self, $hgnc_id ) = @_;
  $hgnc_id =~ s/\D//g;
  my $prot = $self->_search($hgnc_id);

  croak "No protein for $hgnc_id found" unless $prot;

  return $self->__source_obj( {
    __source_url => $prot->{urls}->[0],
    %$prot,
  } );
}

sub template_name { 'protein' }
sub template_ref_name { 'protein'.shift->{hgnc_id} }
sub template_basic_fields {
  my $self = shift;

  $self->{hgnc_id} =~ s/^HGNC://;
  $self->{previous_symbols} = join(', ', @{ $self->{previous_symbols} } ),

  my( $chromosome, $arm, $band );
  if( $self->{chromosome} ) {
    if( $self->{chromosome} =~ /^(\d+)([pq])(\d+\.?\d*)$/ ) {
      ( $chromosome, $arm, $band ) = ( $1, $2, $3 );
    } elsif( $self->{chromosome} =~ /^(\d+)([pq])(\d+\.\d*)\-\2(\d+\.\d*)$/ ) {
      ( $chromosome, $arm, $band ) = ( $1, $2, "$3-$4" );
    }
  }

  tie( my %fields, 'Tie::IxHash' );
  %fields = (
    name    => { value => $self->{approved_name} },
    caption => { value => '' },
    image   => { value => '' },
    width   => { value => '' },

    HGNCid => { value => $self->{hgnc_id} },
    Symbol => { value => $self->{approved_symbol} },
    AltSymbols => { value => $self->{previous_symbols} },

    EntrezGene => { value => $self->{entrez_gene_ids}->[0] || $self->{mapped_entrez_gene_id} },
  
    OMIM => { value => $self->{omim_id} },
    RefSeq => { value => $self->{refseq_ids}->[0] || $self->{mapped_refseq_id} },
    UniProt => { value => $self->{uniprot_id} || $self->{mapped_uniprot_id} },
    PDB => { value => '' },
    ECnumber => { value => $self->{enzyme_ids}->[0] },
  
    Chromosome => { value => $chromosome },
    Arm => { value => $arm },
    Band => { value => $band },
    LocusSupplementaryData => { value => '' },
  );

  return \%fields;
}

1;
