package WWW::Search::DrugBank;
use base 'WWW::Search';

use warnings;
use strict;

our $VERSION = '0.03';

use WWW::SearchResult;

use XML::LibXML;
use HTML::TreeBuilder;
use HTML::Entities;
use URI;

=head1 NAME

WWW::Search::DrugBank - Access DrugBank's database of pharmaceuticals

=head1 SYNOPSIS

  use WWW::Search;

  my $search = new WWW::Search('DrugBank');

  my @ids = qw/ APRD00109 APRD00189 APRD00849 /;
  $search->native_query( \@ids );

  while( my $drug = $search->next_result ) {
    printf "Generic name: %s\n", $drug->{generic_name};
    printf "Melting point: %s\n", $drug->{melting_point};
    printf "CAS registry number: %s\n", $drug->{cas_registry_number};
    printf "PubChem compound ID: %s\n", $drug->{pubchem_id}->{compound};
    printf "PubChem substance ID: %s\n", $drug->{pubchem_id}->{substance};
    print "\n";
    # ... etc.
  }

=head1 DESCRIPTION

This module provides a programmatic way of scouring DrugBank
(L<http://redpoll.pharmacy.ualberta.ca/drugbank/>), the University of
Alberta project that maintains a database of a wide range of
pharmaceuticals.

If you are unfamiliar with the WWW::Search interface, see the synopsis
for an example of how you might use this module. As its first
argument, the "native_query" method accepts either a DrugBank
accession number or a reference to an array of such numbers. Results
returned by the "next_result" method (named C<$drug> above) are
WWW::SearchResult objects containing data about the target drug. Each
result contains the following fields.

=head1 RESULT FIELDS

=head2 drug_target_1_gene_sequence

  $value = $prot->{drug_target_1_gene_sequence};

Corresponds to the 'Drug Target 1 Gene Sequence' field.

=head2 drug_target_1_general_function

  $value = $prot->{drug_target_1_general_function};

Corresponds to the 'Drug Target 1 General Function' field.

=head2 drug_target_1_locus

  $value = $prot->{drug_target_1_locus};

Corresponds to the 'Drug Target 1 Locus' field.

=head2 drug_target_1_molecular_weight

  $value = $prot->{drug_target_1_molecular_weight};

Corresponds to the 'Drug Target 1 Molecular Weight' field.

=head2 drug_target_1_name

  $value = $prot->{drug_target_1_name};

Corresponds to the 'Drug Target 1 Name' field.

=head2 drug_target_1_number_of_residues

  $value = $prot->{drug_target_1_number_of_residues};

Corresponds to the 'Drug Target 1 Number of Residues' field.

=head2 drug_target_1_pdb_id

  $value = $prot->{drug_target_1_pdb_id};

Corresponds to the 'Drug Target 1 PDB ID' field.

=head2 drug_target_1_pathway

  $value = $prot->{drug_target_1_pathway};

Corresponds to the 'Drug Target 1 Pathway' field.

=head2 drug_target_1_pfam_domain_function

  $value = $prot->{drug_target_1_pfam_domain_function};

Corresponds to the 'Drug Target 1 Pfam Domain Function' field.

=head2 drug_target_1_protein_sequence

  $value = $prot->{drug_target_1_protein_sequence};

Corresponds to the 'Drug Target 1 Protein Sequence' field.

=head2 drug_target_1_reaction

  $value = $prot->{drug_target_1_reaction};

Corresponds to the 'Drug Target 1 Reaction' field.

=head2 drug_target_1_references

  $value = $prot->{drug_target_1_references};

Corresponds to the 'Drug Target 1 References' field.

=head2 drug_target_1_snps

  $value = $prot->{drug_target_1_snps};

Corresponds to the 'Drug Target 1 SNPs' field.

=head2 drug_target_1_signals

  $value = $prot->{drug_target_1_signals};

Corresponds to the 'Drug Target 1 Signals' field.

=head2 drug_target_1_specific_function

  $value = $prot->{drug_target_1_specific_function};

Corresponds to the 'Drug Target 1 Specific Function' field.

=head2 drug_target_1_swissprot_id

  $value = $prot->{drug_target_1_swissprot_id};

Corresponds to the 'Drug Target 1 SwissProt ID' field.

=head2 drug_target_1_synonyms

  $value = $prot->{drug_target_1_synonyms};

Corresponds to the 'Drug Target 1 Synonyms' field.

=head2 drug_target_1_theoretical_pi

  $value = $prot->{drug_target_1_theoretical_pi};

Corresponds to the 'Drug Target 1 Theoretical pI' field.

=head2 drug_target_1_transmembrane_regions

  $value = $prot->{drug_target_1_transmembrane_regions};

Corresponds to the 'Drug Target 1 Transmembrane Regions' field.

=head2 drug_target_2_3d_structure_image

  $value = $prot->{drug_target_2_3d_structure_image};

Corresponds to the 'Drug Target 2 3D Structure Image' field.

=head2 drug_target_2_3d_structure_text

  $value = $prot->{drug_target_2_3d_structure_text};

Corresponds to the 'Drug Target 2 3D Structure Text' field.

=head2 drug_target_2_cellular_location

  $value = $prot->{drug_target_2_cellular_location};

Corresponds to the 'Drug Target 2 Cellular Location' field.

=head2 drug_target_2_chromosome_location

  $value = $prot->{drug_target_2_chromosome_location};

Corresponds to the 'Drug Target 2 Chromosome Location' field.

=head2 drug_target_2_essentiality

  $value = $prot->{drug_target_2_essentiality};

Corresponds to the 'Drug Target 2 Essentiality' field.

=head2 drug_target_2_go_classification

  $value = $prot->{drug_target_2_go_classification};

Corresponds to the 'Drug Target 2 GO Classification' field.

=head2 drug_target_2_genbank_id_gene

  $value = $prot->{drug_target_2_genbank_id_gene};

Corresponds to the 'Drug Target 2 GenBank ID Gene' field.

=head2 drug_target_2_genbank_id_protein

  $value = $prot->{drug_target_2_genbank_id_protein};

Corresponds to the 'Drug Target 2 GenBank ID Protein' field.

=head2 drug_target_2_gene_name

  $value = $prot->{drug_target_2_gene_name};

Corresponds to the 'Drug Target 2 Gene Name' field.

=head2 drug_target_2_gene_sequence

  $value = $prot->{drug_target_2_gene_sequence};

Corresponds to the 'Drug Target 2 Gene Sequence' field.

=head2 drug_target_2_general_function

  $value = $prot->{drug_target_2_general_function};

Corresponds to the 'Drug Target 2 General Function' field.

=head2 drug_target_2_locus

  $value = $prot->{drug_target_2_locus};

Corresponds to the 'Drug Target 2 Locus' field.

=head2 drug_target_2_molecular_weight

  $value = $prot->{drug_target_2_molecular_weight};

Corresponds to the 'Drug Target 2 Molecular Weight' field.

=head2 drug_target_2_name

  $value = $prot->{drug_target_2_name};

Corresponds to the 'Drug Target 2 Name' field.

=head2 drug_target_2_number_of_residues

  $value = $prot->{drug_target_2_number_of_residues};

Corresponds to the 'Drug Target 2 Number of Residues' field.

=head2 drug_target_2_pdb_id

  $value = $prot->{drug_target_2_pdb_id};

Corresponds to the 'Drug Target 2 PDB ID' field.

=head2 drug_target_2_pathway

  $value = $prot->{drug_target_2_pathway};

Corresponds to the 'Drug Target 2 Pathway' field.

=head2 drug_target_2_pfam_domain_function

  $value = $prot->{drug_target_2_pfam_domain_function};

Corresponds to the 'Drug Target 2 Pfam Domain Function' field.

=head2 drug_target_2_protein_sequence

  $value = $prot->{drug_target_2_protein_sequence};

Corresponds to the 'Drug Target 2 Protein Sequence' field.

=head2 drug_target_2_reaction

  $value = $prot->{drug_target_2_reaction};

Corresponds to the 'Drug Target 2 Reaction' field.

=head2 drug_target_2_references

  $value = $prot->{drug_target_2_references};

Corresponds to the 'Drug Target 2 References' field.

=head2 drug_target_2_snps

  $value = $prot->{drug_target_2_snps};

Corresponds to the 'Drug Target 2 SNPs' field.

=head2 drug_target_2_signals

  $value = $prot->{drug_target_2_signals};

Corresponds to the 'Drug Target 2 Signals' field.

=head2 drug_target_2_specific_function

  $value = $prot->{drug_target_2_specific_function};

Corresponds to the 'Drug Target 2 Specific Function' field.

=head2 drug_target_2_swissprot_id

  $value = $prot->{drug_target_2_swissprot_id};

Corresponds to the 'Drug Target 2 SwissProt ID' field.

=head2 drug_target_2_synonyms

  $value = $prot->{drug_target_2_synonyms};

Corresponds to the 'Drug Target 2 Synonyms' field.

=head2 drug_target_2_theoretical_pi

  $value = $prot->{drug_target_2_theoretical_pi};

Corresponds to the 'Drug Target 2 Theoretical pI' field.

=head2 drug_target_2_transmembrane_regions

  $value = $prot->{drug_target_2_transmembrane_regions};

Corresponds to the 'Drug Target 2 Transmembrane Regions' field.

=head2 drug_type, type

  $value = $prot->{drug_type};
  $value = $prot->{type};

Corresponds to the 'Drug Type' field.

=head2 fda_label

  $value = $prot->{fda_label};

Corresponds to the 'FDA Label' field.

=head2 genbank_id

  $value = $prot->{genbank_id};

Corresponds to the 'GenBank ID' field.

=head2 generic_name, name

  $value = $prot->{generic_name};
  $value = $prot->{name};

Corresponds to the 'Generic Name' field.

=head2 h2o_solubility

  $value = $prot->{h2o_solubility};

Corresponds to the 'H2O Solubility' field.

=head2 het_id

  $value = $prot->{het_id};

Corresponds to the 'HET ID' field.

=head2 half_life

  $value = $prot->{half_life};

Corresponds to the 'Half Life' field.

=head2 inchi_identifier, inchi_id

  $value = $prot->{inchi_identifier};
  $value = $prot->{inchi_id};

Corresponds to the 'InChi Identifier' field.

=head2 indication

  $value = $prot->{indication};

Corresponds to the 'Indication' field.

=head2 interactions

  $value = $prot->{interactions};

Corresponds to the 'Interactions' field.

=head2 kegg_compound_id

  $value = $prot->{kegg_compound_id};

Corresponds to the 'KEGG Compound ID' field.

=head2 last_update

  $value = $prot->{last_update};

Corresponds to the 'Last Update' field.

=head2 logp, hydrophobicity

  $value = $prot->{logp};
  $value = $prot->{hydrophobicity};

Corresponds to the 'LogP/Hydrophobicity' field.

=head2 mol_file_image

  $value = $prot->{mol_file_image};

Corresponds to the 'MOL File Image' field.

=head2 mol_file_text

  $value = $prot->{mol_file_text};

Corresponds to the 'MOL File Text' field.

=head2 mass_spectrum

  $value = $prot->{mass_spectrum};

Corresponds to the 'Mass Spectrum' field.

=head2 material_safety_data_sheet, msds

  $value = $prot->{material_safety_data_sheet};
  $value = $prot->{msds};

Corresponds to the 'Material Safety Data Sheet (MSDS)' field.

=head2 mechanism_of_action

  $value = $prot->{mechanism_of_action};

Corresponds to the 'Mechanism of Action' field.

=head2 melting_point

  $value = $prot->{melting_point};

Corresponds to the 'Melting Point' field.

=head2 molecular_weight

  $value = $prot->{molecular_weight};

Corresponds to the 'Molecular Weight' field.

=head2 nmr_spectrum

  $value = $prot->{nmr_spectrum};

Corresponds to the 'NMR Spectrum' field.

=head2 organisms_affected

  $value = $prot->{organisms_affected};

Corresponds to the 'Organisms Affected' field.

=head2 pdb_experimental_id

  $value = $prot->{pdb_experimental_id};

Corresponds to the 'PDB Experimental ID' field.

=head2 pdb_file_calculated_image

  $value = $prot->{pdb_file_calculated_image};

Corresponds to the 'PDB File Calculated Image' field.

=head2 pdb_file_calculated_text

  $value = $prot->{pdb_file_calculated_text};

Corresponds to the 'PDB File Calculated Text' field.

=head2 pdb_file_experimental_image

  $value = $prot->{pdb_file_experimental_image};

Corresponds to the 'PDB File Experimental Image' field.

=head2 pdb_file_experimental_text

  $value = $prot->{pdb_file_experimental_text};

Corresponds to the 'PDB File Experimental Text' field.

=head2 patient_information

  $value = $prot->{patient_information};

Corresponds to the 'Patient Information' field.

=head2 pharmgkb_id

  $value = $prot->{pharmgkb_id};

Corresponds to the 'PharmGKB ID' field.

=head2 pharmacology

  $value = $prot->{pharmacology};

Corresponds to the 'Pharmacology' field.

=head2 phase_1_metabolizing_enzyme

  $value = $prot->{phase_1_metabolizing_enzyme};

Corresponds to the 'Phase 1 Metabolizing Enzyme' field.

=head2 phase_1_metabolizing_enzyme_sequence

  $value = $prot->{phase_1_metabolizing_enzyme_sequence};

Corresponds to the 'Phase 1 Metabolizing Enzyme Sequence' field.

=head2 phase_1_metabolizing_enzyme_swissprot_id

  $value = $prot->{phase_1_metabolizing_enzyme_swissprot_id};

Corresponds to the 'Phase 1 Metabolizing Enzyme SwissProt ID' field.

=head2 protein_binding, protein_bound

  $value = $prot->{protein_binding};
  $value = $prot->{protein_bound};

Corresponds to the 'Protein Binding' field.

=head2 pubchem_id

  $value = $prot->{pubchem_id};

Corresponds to the 'PubChem ID' field.

=head2 rxlist_link

  $value = $prot->{rxlist_link};

Corresponds to the 'RxList Link' field.

=head2 sdf_file

  $value = $prot->{sdf_file};

Corresponds to the 'SDF File' field.

=head2 smiles_string

  $value = $prot->{smiles_string};

Corresponds to the 'Smiles String' field.

=head2 state

  $value = $prot->{state};

Corresponds to the 'State' field.

=head2 swissprot_id

  $value = $prot->{swissprot_id};

Corresponds to the 'SwissProt ID' field.

=head2 synthesis_reference

  $value = $prot->{synthesis_reference};

Corresponds to the 'Synthesis Reference' field.

=head2 toxicity

  $value = $prot->{toxicity};

Corresponds to the 'Toxicity' field.

=head2 pka, isoelectric_point

  $value = $prot->{pka};
  $value = $prot->{isoelectric_point};

Corresponds to the 'pKa/Isoelectric Point' field.

=cut

sub native_setup_search {
  my( $self, $query ) = @_;
  my @ids = ref $query eq 'ARRAY' ? @$query : ( $query );
  $self->{_ids} = \@ids;
  $self->{_idx} = 0;
  $self->user_agent(1);
}

sub native_retrieve_some {
  my $self = shift;
  my $id = $self->{_ids}->[$self->{_idx}++] or return;

  my $url = $self->_url($id);
  $self->{_current_url} = $url;

  my $html = $self->_fetch_data($url) or return;
  my $parser = new XML::LibXML();
  my $doc = $parser->parse_html_string( $html ) or return;

  my %data = ( );
  my $fields = $self->_fields;
  while( my( $label, $field ) = each %$fields ) {
    my $value = $self->_field_value($doc, $label);
    $data{$_} = $value foreach @{ $field->{fields} };
  }

  return undef unless $data{accession_number};

  my $hit = new WWW::SearchResult();
  $hit->{$_} = $data{$_} for keys %data;
  $hit->url( $url );

  push @{$self->{cache}}, $hit;
  $self->{_current_url} = undef;
  return 1;
}

sub _field_value {
  my( $self, $doc, $field ) = @_;
  my $xpath = sprintf '//td[.="%s"]/following-sibling::td[position()=1]', $field;
  my $node = ($doc->findnodes($xpath))[0];
  return undef unless $node;

  my $value = $node->to_literal;
  $value = $self->_parse_pubchem_id($node) if $field eq 'PubChem ID';
  $value = $self->_parse_synonyms($node) if $field eq 'Brand Names/Synonyms';
  $value = $self->_parse_url($node) if $self->_fields->{$field}->{has_url};
  $value = $self->_parse_category($node) if $field eq 'Drug Category';
  $value = $self->_parse_reference($node) if $field eq 'Drug Reference';
  $value = $self->_parse_na($value);

  return $value;
}

sub _parse_reference {
  my( $self, $node ) = @_;
  return [ map { $self->_parse_url($_) } $node->findnodes('ul/li') ];
}

sub _parse_category {
  my( $self, $node ) = @_;
  my @cats = $node->findnodes('ul/li');

  my %categories = ( categories => [], atc => {} );

  my @atc = ( );
  foreach my $cat ( @cats ) {
    if( $cat->to_literal =~ /ATC\:(\w+)/ ) {
      my $atc_code = $1;
      my $atc_url = $self->_parse_url($cat);
      push @atc, { code => $atc_code, url => $atc_url };
    } else {
      push @{ $categories{categories} }, $self->_trim($cat->to_literal);
    }
  }

  $categories{atc} = \@atc;

  return \%categories;
}

sub _parse_url {
  my( $self, $node ) = @_;
  return URI->new($self->_trim( $node->findvalue('a/@href') ))->abs($self->{_current_url})->as_string;
}

sub _trim {
  my( $self, $text ) = @_;
  $text =~ s/^\s+//s;
  $text =~ s/\s+$//s;
  return $text;
}

sub _parse_synonyms {
  my( $self, $node ) = @_;
  my @synonyms = map { $self->_trim($_) } map { $_->to_literal } $node->findnodes('ol/li');
  return \@synonyms;
}

sub _parse_pubchem_id {
  my( $self, $node ) = @_;
  my @ids = map { $_->to_literal } $node->findnodes('a');
  return { substance => $ids[0], compound => $ids[1] };
}

sub _parse_na {
  my( $self, $value ) = @_;
  $value = $value ? $self->_trim($value) : '';
  return $value eq 'Not Available' ? undef : $value;
}

sub _fetch_data {
  my( $self, $url ) = @_;
  my $res = $self->user_agent->get($url);
  return unless $res->is_success;

  my $html = $res->content;
  my $tree = new HTML::TreeBuilder();
  $tree->parse($html);
  foreach my $node ( $tree->look_down( _tag => '~text' ) ) {
    my $text = defined $node->attr('text') ? $node->attr('text') : '';
    encode_entities($text);
    $node->attr( text => $text );
  }
  $html = $tree->as_HTML( undef, '', {} );
  $tree->delete();

  return $html;
}

sub _url {
  my( $self, $id ) = @_;
  return sprintf 'http://www.drugbank.ca/cgi-bin/getCard.cgi?CARD=%s.txt', $id;
}

sub _fields { {
  'Creation Date' => { fields => [ 'creation_date' ], has_url => 0 },
  'Last Update' => { fields => [ 'last_update' ], has_url => 0 },

  'Accession Number' => { fields => [ 'accession_number' ], has_url => 0 },
  'Secondary Accession Number' => { fields => ['accession_number', 'secondary_accession_number' ], has_url => 0 },
  'Primary Accession Number' => { fields => [ 'accession_number', 'primary_accession_number' ], has_url => 0 },

  'Name' => { fields => [ 'generic_name', 'name' ], has_url => 0 },
  'Brand Names/Synonyms' => { fields => [ 'brand_names', 'synonyms' ], has_url => 0 },
  'Brand Name Mixtures' => { fields => [ 'brand_name_mixtures' ], has_url => 0 },
  'Chemical IUPAC Name' => { fields => [ 'chemical_iupac_name', 'iupac_name' ], has_url => 0 },
  'Chemical Formula' => { fields => [ 'chemical_formula', 'formula' ], has_url => 0 },
  'Chemical Structure' => { fields => [ 'chemical_structure', 'structure' ], has_url => 0 },
  'CAS Registry Number' => { fields => [ 'cas_registry_number', 'cas_id' ], has_url => 0 },
  'InChi Identifier' => { fields => [ 'inchi_identifier', 'inchi_id' ], has_url => 0 },
  'KEGG Compound ID' => { fields => [ 'kegg_compound_id' ], has_url => 0 },
  'PubChem ID' => { fields => [ 'pubchem_id' ], has_url => 0 },
  'ChEBI ID' => { fields => [ 'chebi_id' ], has_url => 0 },
  'PharmGKB ID' => { fields => [ 'pharmgkb_id' ], has_url => 0 },
  'HET ID' => { fields => [ 'het_id' ], has_url => 0 },
  'SwissProt ID' => { fields => [ 'swissprot_id' ], has_url => 0 },
  'GenBank ID' => { fields => [ 'genbank_id' ], has_url => 0 },
  'Drug ID Number [DIN]' => { fields => [ 'drug_id_number', 'drug_id', 'din' ], has_url => 0 },
  'RxList Link' => { fields => [ 'rxlist_link' ], has_url => 0 },
  'FDA Label' => { fields => [ 'fda_label' ], has_url => 0 },
  'Material Safety Data Sheet (MSDS)' => { fields => [ 'material_safety_data_sheet', 'msds' ], has_url => 0 },
  'Synthesis Reference' => { fields => [ 'synthesis_reference' ], has_url => 0 },
  'Molecular Weight' => { fields => [ 'molecular_weight' ], has_url => 0 },
  'Melting Point' => { fields => [ 'melting_point' ], has_url => 0 },
  'H2O Solubility' => { fields => [ 'h2o_solubility' ], has_url => 0 },
  'State' => { fields => [ 'state' ], has_url => 0 },
  'LogP/Hydrophobicity' => { fields => [ 'logp', 'hydrophobicity' ], has_url => 0 },
  'pKa/Isoelectric Point' => { fields => [ 'pka', 'isoelectric_point' ], has_url => 0 },
  'NMR Spectrum' => { fields => [ 'nmr_spectrum' ], has_url => 0 },
  'Mass Spectrum' => { fields => [ 'mass_spectrum' ], has_url => 0 },
  'MOL File Image' => { fields => [ 'mol_file_image' ], has_url => 0 },
  'MOL File Text' => { fields => [ 'mol_file_text' ], has_url => 1 },
  'SDF File' => { fields => [ 'sdf_file' ], has_url => 1 },
  'PDB File Calculated Image' => { fields => [ 'pdb_file_calculated_image' ], has_url => 0 },
  'PDB File Calculated Text' => { fields => [ 'pdb_file_calculated_text' ], has_url => 1 },
  'PDB Experimental ID' => { fields => [ 'pdb_experimental_id' ], has_url => 0 },
  'PDB File Experimental Text' => { fields => [ 'pdb_file_experimental_text' ], has_url => 1 },
  'PDB File Experimental Image' => { fields => [ 'pdb_file_experimental_image' ], has_url => 0 },
  'Smiles String' => { fields => [ 'smiles_string' ], has_url => 0 },
  'Drug Type' => { fields => [ 'drug_type', 'type' ], has_url => 0 },
  'Drug Category' => { fields => [ 'drug_category', 'category' ], has_url => 0 },
  'Indication' => { fields => [ 'indication' ], has_url => 0 },
  'Pharmacology' => { fields => [ 'pharmacology' ], has_url => 0 },
  'Mechanism of Action' => { fields => [ 'mechanism_of_action' ], has_url => 0 },
  'Absorption' => { fields => [ 'absorption' ], has_url => 0 },
  'Toxicity' => { fields => [ 'toxicity' ], has_url => 0 },
  'Protein Binding' => { fields => [ 'protein_binding', 'protein_bound' ], has_url => 0 },
  'Biotransformation' => { fields => [ 'biotransformation' ], has_url => 0 },
  'Half Life' => { fields => [ 'half_life' ], has_url => 0 },
  'Dosage Forms' => { fields => [ 'dosage_forms' ], has_url => 0 },
  'Patient Information' => { fields => [ 'patient_information' ], has_url => 1 },
  'Interactions' => { fields => [ 'interactions' ], has_url => 1 },
  'Contraindications' => { fields => [ 'contraindications' ], has_url => 1 },
  'Drug Reference' => { fields => [ 'drug_reference' ], has_url => 0 },
  'Organisms Affected' => { fields => [ 'organisms_affected' ], has_url => 0 },
  'Phase 1 Metabolizing Enzyme' => { fields => [ 'phase_1_metabolizing_enzyme' ], has_url => 0 },
  'Phase 1 Metabolizing Enzyme Sequence' => { fields => [ 'phase_1_metabolizing_enzyme_sequence' ], has_url => 0 },
  'Phase 1 Metabolizing Enzyme SwissProt ID' => { fields => [ 'phase_1_metabolizing_enzyme_swissprot_id' ], has_url => 0 },
  'Drug Target 1 Name' => { fields => [ 'drug_target_1_name' ], has_url => 0 },
  'Drug Target 1 Gene Name' => { fields => [ 'drug_target_1_gene_name' ], has_url => 0 },
  'Drug Target 1 Synonyms' => { fields => [ 'drug_target_1_synonyms' ], has_url => 0 },
  'Drug Target 1 Protein Sequence' => { fields => [ 'drug_target_1_protein_sequence' ], has_url => 0 },
  'Drug Target 1 Number of Residues' => { fields => [ 'drug_target_1_number_of_residues' ], has_url => 0 },
  'Drug Target 1 Molecular Weight' => { fields => [ 'drug_target_1_molecular_weight' ], has_url => 0 },
  'Drug Target 1 Theoretical pI' => { fields => [ 'drug_target_1_theoretical_pi' ], has_url => 0 },
  'Drug Target 1 GO Classification' => { fields => [ 'drug_target_1_go_classification' ], has_url => 0 },
  'Drug Target 1 General Function' => { fields => [ 'drug_target_1_general_function' ], has_url => 0 },
  'Drug Target 1 Specific Function' => { fields => [ 'drug_target_1_specific_function' ], has_url => 0 },
  'Drug Target 1 Pathway' => { fields => [ 'drug_target_1_pathway' ], has_url => 0 },
  'Drug Target 1 Reaction' => { fields => [ 'drug_target_1_reaction' ], has_url => 0 },
  'Drug Target 1 Pfam Domain Function' => { fields => [ 'drug_target_1_pfam_domain_function' ], has_url => 0 },
  'Drug Target 1 Signals' => { fields => [ 'drug_target_1_signals' ], has_url => 0 },
  'Drug Target 1 Transmembrane Regions' => { fields => [ 'drug_target_1_transmembrane_regions' ], has_url => 0 },
  'Drug Target 1 Essentiality' => { fields => [ 'drug_target_1_essentiality' ], has_url => 0 },
  'Drug Target 1 GenBank ID Protein' => { fields => [ 'drug_target_1_genbank_id_protein' ], has_url => 0 },
  'Drug Target 1 SwissProt ID' => { fields => [ 'drug_target_1_swissprot_id' ], has_url => 0 },
  'Drug Target 1 PDB ID' => { fields => [ 'drug_target_1_pdb_id' ], has_url => 0 },
  'Drug Target 1 3D Structure Text' => { fields => [ 'drug_target_1_3d_structure_text' ], has_url => 0 },
  'Drug Target 1 3D Structure Image' => { fields => [ 'drug_target_1_3d_structure_image' ], has_url => 0 },
  'Drug Target 1 Cellular Location' => { fields => [ 'drug_target_1_cellular_location' ], has_url => 0 },
  'Drug Target 1 Gene Sequence' => { fields => [ 'drug_target_1_gene_sequence' ], has_url => 0 },
  'Drug Target 1 GenBank ID Gene' => { fields => [ 'drug_target_1_genbank_id_gene' ], has_url => 0 },
  'Drug Target 1 Chromosome Location' => { fields => [ 'drug_target_1_chromosome_location' ], has_url => 0 },
  'Drug Target 1 Locus' => { fields => [ 'drug_target_1_locus' ], has_url => 0 },
  'Drug Target 1 SNPs' => { fields => [ 'drug_target_1_snps' ], has_url => 0 },
  'Drug Target 1 References' => { fields => [ 'drug_target_1_references' ], has_url => 0 },
  'Drug Target 2 Name' => { fields => [ 'drug_target_2_name' ], has_url => 0 },
  'Drug Target 2 Gene Name' => { fields => [ 'drug_target_2_gene_name' ], has_url => 0 },
  'Drug Target 2 Synonyms' => { fields => [ 'drug_target_2_synonyms' ], has_url => 0 },
  'Drug Target 2 Protein Sequence' => { fields => [ 'drug_target_2_protein_sequence' ], has_url => 0 },
  'Drug Target 2 Number of Residues' => { fields => [ 'drug_target_2_number_of_residues' ], has_url => 0 },
  'Drug Target 2 Molecular Weight' => { fields => [ 'drug_target_2_molecular_weight' ], has_url => 0 },
  'Drug Target 2 Theoretical pI' => { fields => [ 'drug_target_2_theoretical_pi' ], has_url => 0 },
  'Drug Target 2 GO Classification' => { fields => [ 'drug_target_2_go_classification' ], has_url => 0 },
  'Drug Target 2 General Function' => { fields => [ 'drug_target_2_general_function' ], has_url => 0 },
  'Drug Target 2 Specific Function' => { fields => [ 'drug_target_2_specific_function' ], has_url => 0 },
  'Drug Target 2 Pathway' => { fields => [ 'drug_target_2_pathway' ], has_url => 0 },
  'Drug Target 2 Reaction' => { fields => [ 'drug_target_2_reaction' ], has_url => 0 },
  'Drug Target 2 Pfam Domain Function' => { fields => [ 'drug_target_2_pfam_domain_function' ], has_url => 0 },
  'Drug Target 2 Signals' => { fields => [ 'drug_target_2_signals' ], has_url => 0 },
  'Drug Target 2 Transmembrane Regions' => { fields => [ 'drug_target_2_transmembrane_regions' ], has_url => 0 },
  'Drug Target 2 Essentiality' => { fields => [ 'drug_target_2_essentiality' ], has_url => 0 },
  'Drug Target 2 GenBank ID Protein' => { fields => [ 'drug_target_2_genbank_id_protein' ], has_url => 0 },
  'Drug Target 2 SwissProt ID' => { fields => [ 'drug_target_2_swissprot_id' ], has_url => 0 },
  'Drug Target 2 PDB ID' => { fields => [ 'drug_target_2_pdb_id' ], has_url => 0 },
  'Drug Target 2 3D Structure Text' => { fields => [ 'drug_target_2_3d_structure_text' ], has_url => 0 },
  'Drug Target 2 3D Structure Image' => { fields => [ 'drug_target_2_3d_structure_image' ], has_url => 0 },
  'Drug Target 2 Cellular Location' => { fields => [ 'drug_target_2_cellular_location' ], has_url => 0 },
  'Drug Target 2 Gene Sequence' => { fields => [ 'drug_target_2_gene_sequence' ], has_url => 0 },
  'Drug Target 2 GenBank ID Gene' => { fields => [ 'drug_target_2_genbank_id_gene' ], has_url => 0 },
  'Drug Target 2 Chromosome Location' => { fields => [ 'drug_target_2_chromosome_location' ], has_url => 0 },
  'Drug Target 2 Locus' => { fields => [ 'drug_target_2_locus' ], has_url => 0 },
  'Drug Target 2 SNPs' => { fields => [ 'drug_target_2_snps' ], has_url => 0 },
  'Drug Target 2 References' => { fields => [ 'drug_target_2_references' ], has_url => 0 },
} }

=head1 AUTHOR

David Iberri, C<< <diberri at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-www-drugbank at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Search-DrugBank>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::Search::DrugBank

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-Search-DrugBank>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-Search-DrugBank>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-Search-DrugBank>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-Search-DrugBank>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2006 David Iberri, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
