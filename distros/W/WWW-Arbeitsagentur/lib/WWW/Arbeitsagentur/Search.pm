package WWW::Arbeitsagentur::Search;

=head1 NAME

WWW::Arbeitsagentur::Search - Search for Jobs & Applicants via Arbeitsagentur.de

=head1 SYNOPSIS

 package MySearch;
 use WWW::Arbeitsagentur::Search;

 my $search = MySearch->new('job'  => 'Perl Job',
			    'user' => 'username@arbeitsagentur'
			    'pw'   => 'mypassword@arbeitsagentur',
			    'mech' => WWW::Mechanize->new(),
			   );
 $search->search_my_way;

 sub search_my_way{
     my $self = shift;
     $self->connect();
     # do other stuff
     $self->collect_result_pages;
     return $self->count_results;
 }

=head1 DESCRIPTION

This module is the base class for all search classes. It inherits from WWW::Arbeitsagentur and provides methods to collect search results and save them to disk.

=head1 METHODS

=head2 $search->save_results()

Saves the result pages in the directory determined by $search->path.
Returns the number of errors(!).

 Usage:
	# After successful search:
	$search->collect_result_pages();
	$search->path( 'download/' );	# where to save the files.
	$search->save_results();

=head2 $search->save_page( $page_id )

Save a page from the result list to $search->path.

Parameter: index number of the page to be saved from array $self->results.

Return 0 on failure, 1 on success.

 Usage:
	# primitive filtering:
	my $page = $search->result(5);       
	if ($page =~ m/Perl Coder/){
		$search->save_page(5);
	}

=head2 $search->collect_result_pages()

If our search was successful, this method collects all jobs / applicants found on the result pages.
Data is stored in the array $search->results.

Returns the number of pages found.

=head2 $search->select_job()

Selects a job description in a search form on http://www.arbeitsargentur.de.

 Usage:
	# After navigating the mech to the search form:
	$search->beruf('Perl Coder');
	$search->select_job();

Returns 1 if a matching job-description was found.
Returns 0 on failure.

=head1 SEE ALSO

http://arbeitssuche.sourceforge.net

=head1 AUTHOR

Ingo Wiarda dewarim@users.sourceforce.net

=head1 ACKNOWLEDGMENTS

This module is based upon http://arbeitssuche.sourceforge.net,
written by Ingo Wiarda and Stefan Rother.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Ingo Wiarda

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

our $VERSION = "0.0.1";

@ISA = qw/WWW::Arbeitsagentur/;

use Digest::SHA qw(sha256_hex);
use WWW::Arbeitsagentur::Arbeitnehmer;
use WWW::Arbeitsagentur::Applicant;
use WWW::Arbeitsagentur::Search::FastSearchForWork;
use WWW::Arbeitsagentur;

use strict;
use warnings;

sub save_results{
    my ($self) = @_;
    my $errors = 0;
    
    for ( my $x = 0; $x < $self->results_count() ;$x++){
	my $result = $self->save_page( $x );

	if ($result == 0){
	    $errors++;
	    warn("save_page failed. $!\n") unless $result;
	}
    }
    return $errors;
}

sub collect_result_pages{
    my ($self) = @_;
    my $mech = $self->mech();
    $mech->dump_content();

    my @results = $mech->find_all_links('url_regex'
					=> qr!anzeigeDetails\?redirect_id=\d+!);

    my $result_url = 0;
    my $pages_found = 0;

    $result_url = $results[0]->url() if $results[0];
    return 0 unless $result_url;
    
    while($result_url){

	$mech->get($result_url);
	
	$mech->dump_content('job.html');

	if (! $mech->success()){
	    warn( "Could not fetch ". $result_url.".\n" );
	    return $pages_found;
	    # Todo: better error handling - fetch next, retry etc.?
	}

	$self->results_push( $mech->content );
	$pages_found++;

	# find the URL of the next applicant / job:
	@results = $mech->find_all_links("text_regex" => qr/(?:chstes Stellenangebot|chster Bewerber)/);
	$result_url = @results ? $results[0]->url() : 0;
	warn "next URL: ".$result_url."\n";
	$mech->dump_content();
	
	last if $self->_module_test;
    }
    return $pages_found;
}

sub select_job {
    my ($self) = @_;
    my $mech = $self->mech();
    my ($berufsbezeichnung) = $self->beruf();

    # The method should be more talkative why it returns 0...
    return 0 unless $berufsbezeichnung;
    return 0 unless $self->job_typ();

    $mech->dump_content();
    warn "Sende Formular Berufswahl.\n";
    $mech->submit_form('form_number' => 3,
		       'fields' =>{
			   'art' => $self->job_typ(),
			   'berufsbezeichnung' => $berufsbezeichnung,
		       },
		       'button'	=> 'cmd#starteBerufswahl##true'
		       );
    $mech->dump_content('job_type_selected.html');

    if ($mech->content() =~ m/Ergebnis der Suche nach Berufen/){
	# es gibt mehrere Berufe dieses Namens -> nehmen wir den, der am ehesten passt:
	warn "Job-Title $berufsbezeichnung is not correct. Will try anaway.\n";

	# The following should be refactored into a "Test job_list"-Type Funktion.
	#if ( $self->module_test == 0){
	#    open(JOBS, ">>oddjobs.txt");
	#    print JOBS $berufsbezeichnung."\n";
	#    close(JOBS);
	#}

	eval{ $mech->follow_link('text_regex' => qr/$berufsbezeichnung/i)};
	if ( $@ ) {
	    warn "Could find nothing that matches $berufsbezeichnung. $@\n";
	    $mech->dump_content('job_not_found.html');
	    return 0;
	}
	else{
	    $mech->dump_content('job_found.html');
	    return 1;
	}
    }
    
    # correct job was found:
    if ($mech->content() =~ m/name="beruf" value="[.\d]+"/){
	return 1;
    }
    else{
	# we found nothing:
	return 0;
    }
}

sub save_page{

    my ($self, $page_id) = @_;

    my $data = $self->results_index( $page_id );

    # Do not save zero-length files:
    if ( length($data) == 0 ){
      warn("Page is 0 Bytes long - may be a download problem.\n");
      return 0;
    }
    
    my ($ref) = WWW::Arbeitsagentur::extract_refnumber(\$data);
    if ($ref){
	warn "save_page: found reference number: $ref.\n";
    }
    else{
	warn "Could not find a reference number. Will use hash-value as filename.\n";
	$ref = sha256_hex($data)."_sha";
    }

    my $path = $self->path();
    # CSS-Links anpassen:
    $data =~ s!<link type="text/css" href="/vam/css/!<link type="text/css" href="!;

    # Seite anpassen:
    # Damit bei Stellenangeboten die gewünschten Fähigkeiten nicht
    # in einem großen Block stehen, werden Zeilenumbrüche eingefügt.
    $data =~ s/\);/\);<br \/>/g;
    $data =~ s/<body.*?Seiteninhalt<\/h2/<body><h2>Seiteninhalt<\/h2/sm;

    open(HTML, ">$path$ref.html") or die("Could not open file for writing!\n$!\n");
    print HTML $data;
    close(HTML) or die("Could not close file\n$!\n");
    return 1;
}

1;

__END__


