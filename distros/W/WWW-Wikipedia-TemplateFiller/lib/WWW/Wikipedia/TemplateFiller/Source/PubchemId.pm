package WWW::Wikipedia::TemplateFiller::Source::PubchemId;
use base 'WWW::Wikipedia::TemplateFiller::Source';

use warnings;
use strict;

use Tie::IxHash;

# Terrible hack to enable more elegant solution to bug #41005
my $EscapedPipe = '98lkdfb832nbueh92x0jngfk';

sub search_class { 'PubChem' }

sub get {
  my( $self, $pubchem_id ) = @_;
  my $chem = $self->_search($pubchem_id);

  return $self->__source_obj( {
    __source_url => $chem->url,
    pubchem_id => $pubchem_id,
    %$chem
  } );
}

sub output {
  my( $self, %args ) = @_;
  $args{vertical} = 1;

  my $output = $self->SUPER::output(%args);
     $output =~ s/$EscapedPipe/\|/g;

  return $output;
}

sub template_name { 'chembox' }
sub template_ref_name { 'chem'.shift->{pubchem_id} }
sub template_basic_fields {
  my( $self, %opts ) = @_;

  ( my $formula_html = $self->{molecular_formula} ) =~ s{(\d+)}{<sub>$1</sub>}g;

  tie( my %fields, 'Tie::IxHash' );
  %fields = (
    ImageFile => { value => '' },
    ImageSize => { value => '' },
    IUPACName => { value => '' },
    OtherNames => { value => '' },
    Section1 => { value => "{{Chembox Identifiers\n$EscapedPipe  CASNo=\n$EscapedPipe  PubChem=$self->{pubchem_id}\n$EscapedPipe  SMILES=$self->{smiles}\n  }}" },
    Section2 => { value => "{{Chembox Properties\n$EscapedPipe  Formula=$formula_html\n$EscapedPipe  MolarMass=$self->{molecular_weight}\n$EscapedPipe  Appearance=\n$EscapedPipe  Density=\n$EscapedPipe  MeltingPt=\n$EscapedPipe  BoilingPt=\n$EscapedPipe  Solubility=\n  }}" },
    Section3 => { value => "{{Chembox Hazards\n$EscapedPipe  MainHazards=\n$EscapedPipe  FlashPt=\n$EscapedPipe  Autoignition=\n  }}" },
  );

  $fields{IUPACName} = { value => $self->{iupac_name} } if $opts{add_iupac_name};

  return \%fields;
}

1;
