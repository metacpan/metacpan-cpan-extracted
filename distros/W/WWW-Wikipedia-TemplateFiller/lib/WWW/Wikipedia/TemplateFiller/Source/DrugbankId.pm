package WWW::Wikipedia::TemplateFiller::Source::DrugbankId;
use base 'WWW::Wikipedia::TemplateFiller::Source';

use warnings;
use strict;

use Tie::IxHash;

sub search_class { 'DrugBank' }

sub get {
  my( $self, $drugbank_id ) = @_;
  my $drug = $self->_search($drugbank_id);
  return undef unless $drug;

  return $self->__source_obj( {
    __source_url => $drug->{_url},
    %$drug
  } );
}

sub template_name { 'drugbox' }
sub template_ref_name { 'drug'.shift->{accession_number} }
sub template_basic_fields {
  my $self = shift;

  my $cat = $self->{category};

  my @atc_codes = map {
    /^(...)(....)$/;
    { prefix => $1, suffix => $2 };
  } map {
    $_->{code};
  } grep {
    length $_->{code} == 7
  } @{ $cat && $cat->{atc} || [] };

  my $first_atc = shift @atc_codes;
  my $supplemental_atc = join ', ', map { sprintf '{{ATC|%s|%s}}', $_->{prefix}, $_->{suffix} } @atc_codes;

  ( my $chemical_formula_html = $self->{chemical_formula} )=~ s~(\d+)~<sub>$1</sub>~g;

  my $melting_point;
  if( $self->{melting_point} ) {
    $self->{melting_point} =~ /(\d+\.\d+)/;
    $melting_point = $1;
  }

  tie( my %fields, 'Tie::IxHash' );
  %fields = (
    IUPAC_name => { value => $self->{chemical_iupac_name} },
    image      => { value => '{{PAGENAME}}.png' },
    width      => { value => undef, show => 'if-filled' },
    image2     => { value => undef, show => 'if-filled' },
    CAS_number => { value => $self->{cas_registry_number} },
    CAS_supplemental => { value => undef, show => 'if-filled' },
    ATC_prefix => { value => $first_atc->{prefix} },
    ATC_suffix => { value => $first_atc->{suffix} },
    ATC_supplemental => { value => $supplemental_atc, show => 'if-filled' },
    PubChem    => { value => $self->{pubchem_id}->{compound} },
    DrugBank   => { value => $self->{accession_number} },
    chemical_formula => { value => $chemical_formula_html },
    molecular_weight => { value => $self->{molecular_weight} },
    smiles     => { value => $self->{smiles_string}, show => 'if-extended' },
    density    => { value => undef, show => 'if-filled' },
    melting_point => { value => $self->{melting_point}, show => 'if-extended' },
    boiling_point => { value => undef, show => 'if-filled' },
    solubility => { value => $self->{h2o_solubility}, show => 'if-filled' },
    specific_rotation => { value => undef, show => 'if-filled' },
    sec_combustion => { value => undef, show => 'if-filled' },
    bioavailability => { value => undef },
    protein_bound => { value => $self->{protein_binding} },
    metabolism => { value => undef },
    'elimination_half-life' => { value => $self->{half_life} },
    excretion => { value => undef },
    dependency_liability => { value => undef, show => 'if-filled' },

    # New field from David Ruben
    pregnancy_AU => { value => '<!-- A / B1 / B2 / B3 / C / D / X -->' },
    pregnancy_US => { value => '<!-- A / B / C / D / X -->' },
    pregnancy_category => { value => undef },
    legal_AU => { value => '<!-- Unscheduled / S2 / S4 / S8 -->' },
    legal_UK => { value => '<!-- GSL / P / POM / CD -->' },
    legal_US => { value => '<!-- OTC / Rx-only -->' },
    legal_status => { value => undef },

    routes_of_administration => { value => undef },
  );

  return \%fields;
}

1;
