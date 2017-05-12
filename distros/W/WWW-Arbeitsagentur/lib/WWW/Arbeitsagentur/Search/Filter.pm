package WWW::Arbeitsagentur::Search::Filter;

use strict;
use warnings;


### This is currently the dumping ground for unused/filter-related code of Search.pm

    # um Test erweitert, ob der Parameter 'plz_filter' überhaupt definiert ist
    if ( $self->plz_filter &&
	 $self->test_plz( $self->plz_filter ) ){
      warn "PLZ-Filter: Angebot ist unerwünscht.\n";
      return 0;
    }



=head2 $search->save_results_detailsuche( $cgi )

Saves the results of the detailed search into the directory stored in the
C<$path> attribute if they match the search parameters.

I<Parameters:>
C<$cgi> - A L<CGI|CGI> object

C<$cgi> keys:

=over 4

=item min_alter/max_alter

Minimum/maximum age of the applicant.

=item plz_filter

Postal codes to restrict the search to.

=back

=cut

sub save_results_detailsuche {
  
  my ( $self, $cgi ) = @_;
  my $mech = $self->mech();
  my $path = $self->path;
  
  $mech->dump_content();
  
  warn "Verarbeite Ergebnisse.\n";
  
  my $ignore_list2 = load_new_ignore_list();
  
  
  ######################
  #file:/vam/vamController/ErgebnislisteAG/anzeigeDetails?redirect_id=-670634319248746634&rqc=6&ls=true&ut=2
  my @job_offers =
    $mech->find_all_links( "url_regex" => qr!anzeigeDetails\?redirect_id=! );
  
  if ($mech->content =~ m/Zu Ihrer Suchanfrage konnten keine Ergebnisse gefunden werden/){
    warn("Zu dieser Suchanfrage konnten keine Ergebnisse gefunden werden!");
    return 0;
  }
  
  my $job_url = $job_offers[0]->url();
  while ($job_url) {
    my $save_me = 0;
    
    # follow up on each job offer:
    warn "job_url: " . $job_url . "\n";
    if ( $visited_url{$job_url} ) {    # (wird mit 0 initialisiert)
      warn
	"Bewerber wurde heute schon bearbeitet.\nURL wird trotzdem geholt (workaround).\n";
      #next;
    }
    
    $mech->get($job_url);
    warn( "job_url $job_url holen: " . $mech->success() . "\n");
    $mech->dump_content('applicant.html');
    
    ### Bewerber-URL speichern.
    $visited_url{$job_url}++;
    
    #######################
    # nächste Seite mit Ergebnissen holen.
    
    my @links =
      $mech->find_all_links( "text_regex" => qr/chster Bewerber/ );
    if ( @links > 0 ) {
      $job_url = $links[0]->url();
      warn "nächste URL: " . $job_url . "\n";
    }
    else {
      # terminating the while-loop.
      $job_url = 0;
    }
    
    #######################
    
    my $data = $mech->content();    #->extract_info();
    
    if ( $data =~ m/Alter\D+(\d+)/sm ) {
      
      # Wenn gar keine Altersgrenzen angegeben sind,
      # müssen wir darauf auch nicht filtern:
      if (   $cgi->param("max_alter")
	     || $cgi->param("min_alter") )
	{
	  if (   $1 > $cgi->param('max_alter')
		 || $1 < $cgi->param('min_alter') )
	    {
	      warn "Kandidat ist zu alt ($1).\n";
	      next;
	    }
	  else {
	    warn "Bewerber ist $1 Jahre alt - ok.\n";
	  }
	}
    }
    
    $mech->dump_content();
    
    if ($1) {
      warn ("Zeitfilter: Bewerber arbeitet ohne Einschränkungen bis ");
      if (
	  $data =~ m!<span\s+class="feldname">\s+
		     Wochenstunden\s+
		     </span><br\s*/>\s+
		     (\d+)!xsm
	 )
	{
	  warn "$1 Stunden - ";
	  if ( $1 < 35 ) {
	    warn "zu wenig.\n";
	  }
	  else {
	    warn "ok.\n";
	  }
	}
      else {
	warn "??? Stunden.\n";
      }
    }
    else {
      
      #		print STDERR "Zeitfilter: Bewerber arbeitet nur mit Einschränkungen. Gefiltert.\n";
      #		last;
    }
    my $refnumber = extract_refnumber( \$data );
    
    if ($refnumber) {
      if ( $main::ignorelist->is_set($refnumber) ) {
	warn ("Bewerber $refnumber befindet sich im Filter - ignoriert.\n");
	next;
      }
      if ( $self->test_plz( $cgi->param('plz_filter') ) ) {
	warn ("Bewerber wohnt am falschen Ort => weiter.\n");
	next;
      }
      if ( -e "$path$refnumber.html" ) {
	warn ("Bewerber $refnumber wurde schon gespeichert.\n");
	$mech->dump_content();
	next;
	  }
      
      ### Email-Link vom Arbeitsamt aktivieren (anonyme Bewerber:)
      
      $data =~
	s/(Email.*?<\/span><br\s*\/>\s+)([\w\.]+\@arbeitsagentur\.de)/$1<a href="mailto:$2">$2<\/a>/sim;
      
      ### Diese Datei wird gespeichert.
      $save_me = 1;
    }
    
    if ( $save_me == 0 ){
      warn("Bewerber wird nicht gespeichert. Next.\n");
      next;
    }
    else{
      warn("Bewerber wird gespeichert.\n");
    }
    $mech->dump_content();
    $mech->update_html($data);
    eval { $self->save_page($cgi, $ignore_list2); };
    warn("In save_page ist ein Fehler aufgetreten: $@\n") if $@;
    print "+";
    
  }
  
  return 1;
}


=head2 $search->test_plz( $plz_regex )

Tests whether C<$plz_regex> matches one or more postal codes.

I<Parameters:>
C<$plz_regex> - A regex matching one or more postal codes.


I<Returns:>

B<0> - the regex does not match

B<1> - successful match

=cut

sub test_plz{
    my ($self, $plz_regex) = @_;
    my $str = $self->mech->content();
    $self->mech->dump_content('test_plz.html');
    my $locations = get_locations($str);

## m.k. error string no number    if ($locations == 0){
    if (!($locations)){
	warn "test_plz:Keine Postleitzahl in Stellenangebot gefunden!";
	return 0;
    }

    my @plz_list = get_plz_list($locations);
    defined $plz_list[0] ? 1 : push @plz_list, (" ");

    foreach my $plz (@plz_list){

	if ($plz =~ m/$plz_regex/ism){
	    warn "PLZ-Filter: $plz wird nicht gefiltert.\n";
	    return 0;
	}
    }
    
    warn "PLZ-Filter: keine (akzeptable) PLZ gefunden:\n".join(" ", @plz_list)." passen nicht.\n";
    return 1;
}


=head2 get_plz_list( $locations )

Returns an array of postal codes contained in C<$locations>.

I<Parameters:>
C<$locations> - a string containing a list of postal codes

I<Returns:>
an array of postal codes.

=cut

sub get_plz_list{
    my ($locations) = @_;
#    warn("Input: $locations");
    my @plz_list = $locations =~ m/(?:<li>|\s+)(\d{5})\s+/g;
#    warn("Output: ".join("\t", @plz_list));
    return @plz_list;
}


=head2 get_locations( $html )

Returns the locations of a job description.

I<Parameters:>
C<$html> - An HTML page containing a job offer or an applicants data obtained from
http://www.arbeitsagentur.de

I<Returns:>
a string containing the locations or 0 if there is none.

=cut

sub get_locations{
    my ($html) = @_;
    my ($job_site) = $html =~ m!bungsort.*?(<tr.*?)</tr>!sm;
    if ($job_site){
	$job_site =~ s!<li>\s*Deutschland\s*</li>!!;
	$job_site =~ s!Deutschland;?!\(D\) !g;
    }
    return $job_site || 0;
}


1;
