package WWW::Arbeitsagentur::Search::FastSearchForWork;

@ISA = qw/WWW::Arbeitsagentur::Arbeitnehmer WWW::Arbeitsagentur::Search/;
our $VERSION = "0.0.1";

use strict;
use WWW::Arbeitsagentur::Search;
use WWW::Arbeitsagentur::Arbeitnehmer;
use WWW::Mechanize;
use HTTP::Cookies;

use Class::MethodMaker
    get_set	=> [ qw/ mech pw user path plz plz_radius plz_filter job_typ beruf _module_test/ ],
    list	=> [ qw/ results / ],
    new_hash_init => [ qw/ new / ];

sub search {
    my ( $self ) = @_;
    
    ### append "/" to download path.
    my $path = $self->path();
    $path .= "/" unless $path =~ m/\/$/;
    $self->path($path);

    my $cookie_jar = HTTP::Cookies->new( 'hide_cookie2' => 1 );
    $self->mech(
        WWW::Mechanize->new(
			    agent => 'Mozilla/5.0 - Firefox 1.0.7',
			    cookie_jar => $cookie_jar )
    ) unless $self->mech();

    my $mech = $self->mech();
    $mech->add_header("accept" => "text/html, application/xhtml+xml, text/plain" );

    # Establish connection to BA
    $self->connect() or die "Konnte keine Verbindung zur BA aufbauen.\n";

    # Choose job search page
    $mech->follow_link( 'text_regex' => qr/Stellenangebote suchen/ );
    $mech->success() or die "Konnte die Seite mit der Schnellsuche für Arbeitnehmer nicht finden.\n";

#    warn "Seite mit Schnellsuche wurde aufgerufen.\n";
    $mech->dump_content('schnellsuche.html');

    # Enter job name
    $self->select_job() or die "Konnte keinen Beruf auswählen. Bitte Eingabe überprüfen.\n";
    
    # Start search for job
#    warn "Sende Formular zur Schnellsuche ab.\n";
    $mech->form_number(3);

    my $berufswahl = $mech->value('berufsbezeichnung');

    $mech->untick( 'spezialstea'	=> 1 ); # deactivate obnoxious field for soccer-Jobs
    $mech->submit_form(
		       'form_number' => 3,
		       'fields'      => {
			   'art'               => $self->job_typ(),
			   'plz'               => $self->plz(),
			   'berufsbezeichnung' => $berufswahl,
		       },
		       'button' => 'cmd#starteSchnellsuche',
		       );

    $mech->dump_content('schnellsuche_results.html');
    $mech->success() or die "Die Schnellsuche konnte nicht durchgeführt werden.\n";
    ### Todo: test if we got the result page instead of _successfully_ retrieving something else.

#    warn "Schnellsuche war erfolgreich.\n";
    $self->collect_result_pages();
    
    return $self->results_count();
}


1;

__END__

=head1 NAME

WWW::Arbeitsagentur::Search::FastSearchForWork - Use quick-search on arbeitsagentur.de

=head1 DESCRIPTION

WWW::Arbeitsagentur::Search::FastSearchForWork searches for job-offers on Arbeitsagentur.de, the website of the federal job office of Germany. It saves the results to disk for later filtering and examination.

=head1 SYNOPSIS

    my $search = WWW::Arbeitsagentur::Search::FastSearchForWork->new(
	path		=> "download/",	# where to save your files.
	job_typ		=> 1,		# search for a normal job (instead of temp/contract work etc.)
	plz_filter	=> qr/.+/,	# only save jobs whose postal code matches this regex
	beruf		=> 'Fachinformatiker/in - Anwendungsentwicklung', # job title
    );

    my $result = $search->search();

=head1 METHODS

=head2 new( %parameters )

my $search = WWW::Arbeitsagentur::Search::FastSearchForWork->new() will create a new search object.


=head2 search()

Searches using the fast search for work at http://www.arbeitsagentur.de


=head1 SEE ALSO

The base classes for this class
L<WWW::Arbeitsagentur::Search>,

http://arbeitssuche.sourceforge.net


=head1 AUTHORS

Ingo Wiarda
dewarim@users.sourceforce.net

Stefan Rother
bendana@users.sourceforce.net


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004-2006 by Ingo Wiarda, Stefan Rother

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.
