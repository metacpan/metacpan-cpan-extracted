package WWW::Arbeitsagentur;
$VERSION = '0.02';

use Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw(extract_refnumber);

use strict;
use warnings;

sub extract_refnumber{
    my ($text_ref) = @_;

    if (${$text_ref} =~ m/Referenznummer\D+?([\d]+[-\w]+)/){
	return $1;
    }
    else{
	return 0;
    }
}

sub connect{
    my ($self) = @_;
    my $mech = $self->mech();

#    warn "Versuche, Verbindung zur Arbeitsagentur aufzubauen.\n";
    $mech->get("http://www.arbeitsagentur.de");
    $mech->dump_content('connect.html');
    $mech->success() and $mech->title() eq 'arbeitsagentur.de'
    	or die "Could not connect to www.arbeitsagentur.de\n$!";

    unless (eval{
	
	$self->choose_my_side();
	$mech->dump_content('startpage.html');
	
#	die "Konnte nicht zur Seite für ".$self->type()." wechseln.\n" unless $self->mech->success();
	$mech->success() or die "Could not switch to page for ".($self->isa('Dewarim::Arbeit::Arbeitnehmer') ? 'Arbeitnehmer' : 'Arbeitgeber').".\n";
	
	1;
    }) {
	print STDERR $@;
	return 0;	
    }

    return 1;
}

sub logout{
    my ($self) = @_;
    my $mech = $self->mech;

    $mech->submit_form('form_number' => 1,
		       'button' => 'abmelden',
		       );
    $mech->dump_content('logout_page.html');
    return $mech->success();
}

sub login{
    my ($self) = @_;
    $self->connect();

    warn "Folge Link zur Anmeldung.\n";
    my $mech = $self->mech();
    $mech->dump_content();
    
    $mech->follow_link('text_regex' 
			     => qr!Zur\sAnmeldung!);
        
    $mech->dump_content('login_page.html');
    unless ($mech->success()) {
        print STDERR "Login failed - could not find Login form.<br>\n";
        return 0;
    }
    
    warn "Submitting login form.\n";
    $mech->submit_form("form_number" => 3,
			     "fields" => {
				 "j_username" => $self->user,
				 "j_password" => $self->pw,
			     },
			     "button" => "send"
			     );
    

    $mech->dump_content('login_result.html');

    if ($mech->content() =~ m/Sie sind angemeldet als/){
	warn("Login was successful.\n");
	return 1;
    }
    else{
	warn("*** Warning: Login failed! ***");
	warn("Please check if your login name and password are ok and\n".
	     "if you can connect via browser to arbeitsagentur.de.\n");
	sleep(120);
	return 0;
    }
}

1;

=head1 NAME

WWW::Arbeitsagentur - Search for jobs via arbeitsagentur.de

=head1 SYNOPSIS
 # example for using the quick-search module:
 use WWW::Arbeitsagentur::Search::FastSearchForWork;
 my $search = WWW::Arbeitsagentur::Search::FastSearchForWork->new(
        # where to save your files (optional)
	path		=> "download/",
	# search for a normal job (instead of temp/contract work etc.)
	job_typ		=> 1,
	# only save jobs whose postal code matches this regex
	plz_filter	=> qr/.+/,
        # job title
	beruf		=> 'Fachinformatiker/in - Anwendungsentwicklung', 
    );

 # how many pages were found?
 my $result = $search->search();

 # Access the results:
 my @pages  = $search->results();
 
=head1 DESCRIPTION

WWW::Arbeitsagentur provides access to the search engine of the federal job agency of Germany. You may search either for jobs or applicants, if you have an account. Search results are collected and may be filtered and stored for offline-use. 

=head1 METHODS

=head2 $search->connect(Z<>)

Builds up a connection to http://www.arbeitsagentur.de

I<Returns:>

B<0> - an error occurred

B<1> - success

Dies if attempt to connect fails completely.

=head2 $search->login(Z<>)

After establishing a connection, you can login with your account data, either as an applicant or as a recruiter. Your Perl setup has be SSL-capable, ie. Crypt::SSLeay and (on Windows) the corresponding dlls have to be installed.

I<Returns:>

B<0> - an error occurred

B<1> - success

=head2 $search->logout(Z<>)

Logout from the Arbeitsagentur. Otherwise, you will get a warning the next time you log in via the web interface.

I<Returns:>

B<0> - an error occurred

B<1> - success

=head1 MOTIVATIONS

If you use the search engine on Arbeitsagentur (which is the largest one in Germany for searching jobs or applicants), you may wish to filter certain job offers or applicants permanently, either because you already know them or they are not what you seek. Normally, you will receive the same results if you search again the next day and so you need to step through all the result pages again.
WWW::Arbeitsagentur allows you to build a script which searches for jobs/applicants automatically, filtering and displaying results in a more user friendly way than the current web interface of the Arbeitsagentur.

This module is a rewrite of an existing project of mine. The new version will include tests, more documentation and a better interface, as well as an easy way to install via CPAN / Module::Build.

=head1 TODO

The module stands incomplete, as some parts will have to be rewritten and ported over from http://arbeitssuche.sf.net. So, if you need a working solution _now_, try the SourceForge version.

=head1 AUTHOR

Ingo Wiarda; E-Mail: Ingo_Wiarda@web.de

=head1 COPYRIGHT AND LICENSE

WWW::Arbeitsagentur is written and mantained by Ingo Wiarda.
It is based upon "Projekt Arbeit" on arbeitssuche.sf.net,
Copyright (C) 2004-2006 by Ingo Wiarda, Stefan Rother

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
