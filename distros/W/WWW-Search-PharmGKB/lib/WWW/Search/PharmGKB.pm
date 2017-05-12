package WWW::Search::PharmGKB;

use SOAP::Lite;
import SOAP::Data 'type';
use English;
use Carp;
use vars qw($VERSION);
use Data::Dumper;

$VERSION = '2.04';

sub new {
    my $class = shift;
    my $self = bless {
        proxy => 'http://www.pharmgkb.org/services/PharmGKBItem',
        uri => 'PharmGKBItem',
        readable => 1,
    },
    $class;
    return $self;
}

sub gene_search {

    my $self = shift;
    my($gene) = @_;
    my $result_obj = {};
    my $pharm_ids = $self->_search($gene, 'Gene');
    if($pharm_ids) {

        foreach my $gene_id(@{$pharm_ids}) {
            my $local_hash = {};
            my $soap_service = SOAP::Lite
		-> readable ($self->{readable})
		-> uri($self->{uri})
		-> proxy($self->{proxy})
		-> searchGene ($gene_id);
	    my $search_result = $soap_service->result;
	    $local_hash->{'alternate_names'} = '';
	    $local_hash->{'drugs'} = '';
	    $local_hash->{'diseases'} = '';
	    $local_hash->{'phenotypes'} = '';
	    $local_hash->{'pathways'} = '';
	    $local_hash->{'alternate_symbols'} = '';
	    $local_hash->{'name'} = '';
	    $local_hash->{symbol} = '';

            my @pathways = ();
	    if($search_result->{'geneRelatedPathways'}) {
		my $pathway_result = $search_result->{'geneRelatedPathways'};

		for(my $i = 0; $i <scalar(@{$pathway_result}); $i+= 2) {
		    push(@pathways, {$pathway_result->[$i] => $pathway_result->[$i+1]});
		}
	    }
            $local_hash->{'pathways'} = \@pathways;
	    if($search_result->{geneName}) {
		$local_hash->{name} = $search_result->{geneName};
	    }
	    if($search_result->{geneSymbol}) {
		$local_hash->{symbol} = $search_result->{geneSymbol};
	    }
            if($search_result->{'geneAlternateNames'}) {
		$local_hash->{'alternate_names'} = $search_result->{'geneAlternateNames'};
	    }
	    if($search_result->{'geneRelatedDrugs'}) {
		$local_hash->{'drugs'} = $search_result->{'geneRelatedDrugs'};
	    }
	    if($search_result->{'geneRelatedDiseases'}) {
		$local_hash->{'diseases'} = $search_result->{'geneRelatedDiseases'};
	    }
	    if($search_result->{'geneAlternateSymbols'}) {
		$local_hash->{'alternate_symbols'} = $search_result->{'geneAlternateSymbols'};
	    }
	    if($search_result->{'geneRelatedPhenotypeDatasets'}) {
		$local_hash->{'phenotypes'} = $search_result->{'geneRelatedPhenotypeDatasets'};
	    }

            $result_obj->{$gene_id} = $local_hash;
        }
    }
    else {
        print "Gene $gene was not found in PharmGKB!\n";
    }
    return $result_obj;
}

sub disease_search {

    my $self = shift;
    my($disease) = @_;
    my $result_obj = {};
    my $pharm_ids;
    if($disease) {
        $pharm_ids = $self->_search($disease, 'Disease');
    }
    else {
        print "\'$disease\' is weird. I can't search that\n";
        return 0;
    }

    if($pharm_ids) {

        foreach my $disease_id(@{$pharm_ids}) {
            my $local_hash = {};
            my $soap_service = SOAP::Lite
		-> readable (1)
		-> uri($self->{uri})
		-> proxy($self->{proxy})
		-> searchDisease ($disease_id);
	    
	    	
	    my $search_result = $soap_service->result;
	    $local_hash->{'names'} = '';
	    $local_hash->{'drugs'} = '';
	    $local_hash->{'genes'} = '';
	    $local_hash->{'phenotypes'} = '';
	    $local_hash->{'pathways'} = '';

	    my @pathways = ();
	    if($search_result->{'diseaseRelatedPathways'}) {
		my $pathway_result = $search_result->{'diseaseRelatedPathways'};

		for(my $i = 0; $i <scalar(@{$pathway_result}); $i+= 2) {
		    push(@pathways, {$pathway_result->[$i] => $pathway_result->[$i+1]});
		}
	    }
            $local_hash->{'pathways'} = \@pathways;
	    if($search_result->{'diseaseAlternateNames'}) {
		$local_hash->{'names'} = $search_result->{'diseaseAlternateNames'};
	    }
	    if($search_result->{'diseaseRelatedDrugs'}) {
		$local_hash->{'drugs'} = $search_result->{'diseaseRelatedDrugs'};
	    }
	    if($search_result->{'diseaseRelatedGenes'}) {
		$local_hash->{'genes'} = $search_result->{'diseaseRelatedGenes'};
	    }
	    if($search_result->{'diseaseRelatedPhenotypeDatasets'}) {
		$local_hash->{'phenotypes'} = $search_result->{'diseaseRelatedPhenotypeDatasets'};
	    }

            $result_obj->{$disease_id} = $local_hash;
        }
    }
    else {
        print "Disease $disease was not found in PharmGKB!\n";
    }
    return $result_obj;
}

sub drug_search {
    my $self = shift;
    my($drug) = @_;
    my $result_obj = {};
    my $pharm_ids;
    if($drug) {
        $pharm_ids = $self->_search($drug, 'Drug');
    }
    else {
        print "\'$drug\' is weird. I can't search that\n";
        return 0;
    }
    if($pharm_ids) {
        foreach my $drug_id(@{$pharm_ids}) {
            my $local_hash = {};
            my $soap_service = SOAP::Lite
		-> readable (1)
		-> uri($self->{uri})
		-> proxy($self->{proxy})
		-> searchDrug ($drug_id);
		
	    my $search_result = $soap_service->result;
	    $local_hash->{'generic_names'} = '';
	    $local_hash->{'trade_names'} = '';
	    $local_hash->{'category'} = '';
	    $local_hash->{'classification'} = '';
	    $local_hash->{'genes'} = '';
	    $local_hash->{'diseases'} = '';
	    $local_hash->{'phenotypes'} = '';
	    $local_hash->{'pathways'} = '';
	    $local_hash->{'name'} = '';
            my @pathways = ();
	    if($search_result->{'drugRelatedPathways'}) {
		my $pathway_result = $search_result->{'drugRelatedPathways'};

		for(my $i = 0; $i < scalar(@{$pathway_result}); $i+= 2) {
		    push(@pathways, {$pathway_result->[$i] => $pathway_result->[$i+1]});
		}
	    }
            $local_hash->{'pathways'} = \@pathways;
	    if($search_result->{'drugName'}) {
		$local_hash->{'name'} = $search_result->{'drugName'};
	    }
	    if($search_result->{'drugGenericNames'}) {
		$local_hash->{'generic_names'} = $search_result->{'drugGenericNames'};
	    }
	    if($search_result->{'drugTradeNames'}) {
		$local_hash->{'trade_names'} = $search_result->{'drugTradeNames'};
	    }
	    if($search_result->{'drugCategory'}) {
		$local_hash->{'category'} = $search_result->{'drugCategory'};
	    }
	    if($search_result->{'drugVaClassifications'}){
		$local_hash->{'classification'} = $search_result->{'drugVaClassifications'};
	    }
	    if($search_result->{'drugRelatedGenes'}) {
		$local_hash->{'genes'} = $search_result->{'drugRelatedGenes'};
	    }
	    if($search_result->{'drugRelatedDiseases'}) {
		$local_hash->{'diseases'} = $search_result->{'drugRelatedDiseases'};
	    }
	    if($search_result->{'drugRelatedPhenotypeDatasets'}) {
		$local_hash->{'phenotypes'} = $search_result->{'drugRelatedPhenotypeDatasets'};
	    }

            $result_obj->{$drug_id} = $local_hash;
        }
    }
    else {
        print "Drug $drug was not found in PharmGKB!\n";
    }
    return $result_obj;
}

sub publication_search {

    my $self = shift;
    my($search_term) = @_;
    my $pharm_ids;
    my $result_obj = {};
    if($search_term) {
	$pharm_ids = $self->_search($search_term, 'Publication');
    }
    else {
	print "\'$search_term\' is weird. I can't search that\n";
	return 0;
    }
    if($pharm_ids) {
	foreach my $id(@{$pharm_ids}) {
	    my $local_hash = {};
	    my $soap_service = SOAP::Lite
		-> readable ($self->{readable})
		-> uri($self->{uri})
		-> proxy($self->{proxy})
		-> searchPublication ($id);

	    my $search_result = $soap_service->result;
	    $local_hash->{'grant_id'} = '';
	    $local_hash->{'journal'} = '';
	    $local_hash->{'title'} = '';
	    $local_hash->{'month'} = '';
	    $local_hash->{'abstract'} = '';
	    $local_hash->{'authors'} = '';
	    $local_hash->{'volume'} = '';
	    $local_hash->{'page'} = '';
	    $local_hash->{'cross_reference'} = '';
	    $local_hash->{'year'} = '';
	    if($search_result) {
		if($search_result->{publicationGrantIds}) {
		    $local_hash->{'grants_id'} = $search_result->{publicationGrantIds};
		}
		if($search_result->{publicationJournal}) {
		    $local_hash->{journal} = $search_result->{publicationJournal};
		}
		if($search_result->{publicationName}) {
		    $local_hash->{title} = $search_result->{publicationName};
		}
		if($search_result->{publicationMonth}) {
		    $local_hash->{month} = $search_result->{publicationMonth};
		}
		if($search_result->{publicationAbstract}) {
		    $local_hash->{'abstract'} = $search_result->{publicationAbstract};
		}
		if($search_result->{publicationAuthors}) {
		    $local_hash->{authors} = $search_result->{publicationAuthors};
		}
		if($search_result->{publicationVolume}) {
		    $local_hash->{volume} = $search_result->{publicationVolume};
		}
		if($search_result->{publicationPage}) {
		    $local_hash->{page} = $search_result->{publicationPage};
		}
		if($search_result->{publicationAnnotationCrossReference}) {
		    my $references = $search_result->{publicationAnnotationCrossReference};
		    my @references_array = ();
		    for(my $i=0; $i < scalar(@{$references});$i+=2) {
			push(@references_array, {$references->[$i] => $references->[$i+1]});
		    }
		    $local_hash->{'cross_reference'} = \@references_array;
		}
		if($search_result->{publicationYear}) {
		    $local_hash->{year} = $search_result->{publicationYear};
		}
	    }
	    $result_obj->{$id} = $local_hash;
	}
    }
    else {
	print "No results found for $search_term\n";
    }
    return $result_obj;
}


sub _search {
    my $self = shift;
    my($search_term, $key) = @_;
    my @pharm_id = ();

    my $soap_service = SOAP::Lite
        -> readable ($self->{readable})
	-> uri('SearchService')
	-> proxy('http://www.pharmgkb.org/services/SearchService')
        -> search ($search_term);
    my $search_result = $soap_service->result;  
    foreach my $search_obj(@{$search_result}) {
	if($search_obj->[1] =~ m/$key/ig) {
	    push(@pharm_id, $search_obj->[0]);
	}
    }
    return \@pharm_id;

}

1;


=head1 NAME

WWW::Search::PharmGKB - Search and retrieve information from the PharmGKB database

=head1 VERSION

Version 2.02

=cut

=head1 SYNOPSIS

This module will not work. The PharmGKB API doesn't exist anymore. PLEASE DO NOT USE.

=cut

=head1 AUTHOR

Arun Venkataraman, C<< <arvktr at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-www-search-pharmgkb at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Search-PharmGKB>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::Search::PharmGKB

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-Search-PharmGKB>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-Search-PharmGKB>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-Search-PharmGKB>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-Search-PharmGKB>

=back

You can contact the author for any issues or suggestions you come accross using this module.

=head1 ACKNOWLEDGEMENTS

This module is based on the perl client written by Andrew MacBride (andrew@helix.stanford.edu) for PharmGKB's web services.

=head1 COPYRIGHT & LICENSE

Copyright 2010 Arun Venkataraman C<arvktr@cpan.org>, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut
