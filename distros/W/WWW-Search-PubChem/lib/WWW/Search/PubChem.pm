package WWW::Search::PubChem;
use base 'WWW::Search';

use warnings;
use strict;

our $VERSION = '0.01';

use WWW::SearchResult;
use XML::LibXML;

=head1 NAME

WWW::Search::PubChem - Access PubChem's database of chemicals

=head1 SYNOPSIS

  use WWW::Search;
  my $search = new WWW::Search('PubChem');

  my @ids = qw/ 126941 3253 77231 /;
  $search->native_query( \@ids );

  while( my $chem = $search->next_result ) {
    printf "PubChem ID: %s\n", $chem->{pubchemid};
    printf "IUPAC name: %s\n", $chem->{iupac_name};
    printf "SMILES string: %s\n", $chem->{smiles};
    printf "Molecular formula: %s\n", $chem->{molecular_formula};
    printf "Molecular weight: %s\n", $chem->{molecular_weight};
    printf "Exact mass: %s\n", $chem->{exact_mass};
    printf "# H-bond acceptors: %d\n", $chem->{nhacceptors};
    printf "# H-bond donors: %d\n", $chem->{nhdonors};
    printf "# Rotatable bonds: %d\n", $chem->{nrotbonds};
    printf "Fingerprint: %s\n", $chem->{fingerprint};
    printf "InChI string: %s\n", $chem->{inchi};
    printf "XLogP2: %s\n", $chem->{xlogp2};
    printf "Polar surface area: %s\n", $chem->{tpsa};
    printf "Monoisotopic weight: %s\n", $chem->{monoisotopic_weight};
  }

=head1 METHODS

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

  my $xml = $self->_fetch_data($url) or return;
  my $parser = new XML::LibXML();
  my $doc = $parser->parse_string($xml) or return;
  
  my %data = ( );
  my $fields = $self->_fields;

  foreach my $field ( @$fields ) {
    my @field_list = @{ $field->{fields} };
    my $val = $self->_field_value( $doc, $field->{type}, $field->{key} );
    $data{$_} = $val foreach @field_list;
  }
  $data{pubchemid} = $id;

  my $hit = new WWW::SearchResult();
  $hit->{$_} = $data{$_} for keys %data;
  $hit->url($url);
  
  push @{$self->{cache}}, $hit;

  $self->{_current_url} = undef;
  return 1;
}

sub _fields { [
  { type => 'implementation', key => 'E_EXACT_MASS',      fields => [ 'mass_exact', 'exact_mass' ] },
  { type => 'name',           key => 'CAS-like Style',    fields => [ 'iupac_name' ] },
  { type => 'label',          key => 'Molecular Formula', fields => [ 'molecular_formula' ] },
  { type => 'label',          key => 'SMILES',            fields => [ 'smiles' ] },
  { type => 'label',          key => 'Molecular Weight',  fields => [ 'molecular_weight' ] },
  { type => 'implementation', key => 'E_NHACCEPTORS',     fields => [ 'hydrogen_bond_acceptor_count', 'nhacceptors' ] },
  { type => 'implementation', key => 'E_NHDONORS',        fields => [ 'hydrogen_bond_donor_count', 'nhdonors' ] },
  { type => 'implementation', key => 'E_NROTBONDS',       fields => [ 'rotatable_bond_count', 'nrotbonds' ] },
  { type => 'implementation', key => 'E_SCREEN',          fields => [ 'fingerprint', 'screen' ] },
  { type => 'implementation', key => 'E_INCHI',           fields => [ 'inchi' ] },
  { type => 'implementation', key => 'E_XLOGP2',          fields => [ 'xlogp2' ] },
  { type => 'implementation', key => 'E_TPSA',            fields => [ 'polar_surface_area', 'tpsa' ] },
  { type => 'name',           key => 'MonoIsotopic',      fields => [ 'monoisotopic_weight' ] },
] }

sub _url {
  my( $self, $id ) = @_;
  return sprintf 'http://pubchem.ncbi.nlm.nih.gov/summary/summary.cgi?cid=%d&disopt=DisplayXML', $id;
}

sub _fetch_data {
  my( $self, $url ) = @_;
  $self->user_agent->timeout(10);
  my $res = $self->user_agent->get($url);
  return unless $res->is_success;
  return $res->content;
}

sub _field_value {
  my( $self, $doc, $type, $key ) = @_;

  my $xpath = sprintf '//*[name()="PC-InfoData"]/*[name()="PC-InfoData_urn"]/*[name()="PC-Urn"]/*[name()="PC-Urn_%s"][.="%s"]/../../../*[name()="PC-InfoData_value"]/*[starts-with(name(),"PC-InfoData_value_")]', $type, $key;
  #die $doc->findnodes($xpath);

  my $node = ($doc->findnodes($xpath))[0];
  return undef unless $node;

  my $value = $node->to_literal;
  return $value;
}

=head1 AUTHOR

David J. Iberri, C<< <diberri at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-www-search-pubchem at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Search-PubChem>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::Search::PubChem

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-Search-PubChem>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-Search-PubChem>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-Search-PubChem>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-Search-PubChem>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2007 David J. Iberri, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of WWW::Search::PubChem
