=head1 NAME

WWW::Arbeitsagentur::Applicant - A container for an applicants data


=head1 SYNOPSIS

	use WWW::Arbeitsagentur::Applicant;

	my $bewerber = new Dewarim::Arbeit::Bewerber();
	$bewerber->parse_file('applicant.html');
	print 'Name: ' . $bewerber->Name() . "\n";


=head1 DESCRIPTION

=head2 Overview

This class is a container for data of applicants.
An applicants file obtained from http://www.arbeitsagentur.de can be parsed
using L<< parse_file()|/$bewerber->parse_file( $file ) >>.

=cut


package WWW::Arbeitsagentur::Applicant;

$VERSION = "0.3";

use File::Copy;
#use HTML::TableExtract;
use WWW::Arbeitsagentur::Search;
use Unicode::String qw(utf8 latin1);

use strict;
use warnings;


=head1 METHODS

=cut

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self  = {
	Berufsbezeichnung 	=> undef,
	Berufsbezeichnung_utf 	=> undef,
	Stellenbeschreibung 	=> undef,
	Ort 	=> undef,
	Refnummer 	=> undef,
	Filename 	=> undef,
	Alter 	=> undef,
	Email 	=> undef,
	Name 	=> undef,
	Arbeitsamt 	=> undef,
	Anschreiben 	=> undef,
	Subject 	=> undef,
	test_mode 	=> undef,
	plz_list	=> []   ,
    };
    bless ($self, $class);
    return $self;
}

sub Berufsbezeichnung {
    my ($self, $berufsbezeichnung) = @_;
    $self->{Berufsbezeichnung} = $berufsbezeichnung if defined $berufsbezeichnung;
    return $self->{Berufsbezeichnung};
}

sub Berufsbezeichnung_utf {
    my ($self, $berufsbezeichnung_utf) = @_;
    $self->{Berufsbezeichnung_utf} = $berufsbezeichnung_utf if defined $berufsbezeichnung_utf;
    return $self->{Berufsbezeichnung_utf};
}


sub Stellenbeschreibung {
    my ($self, $stellenbeschreibung) = @_;
    $self->{Stellenbeschreibung} = $stellenbeschreibung if defined $stellenbeschreibung;
    return $self->{Stellenbeschreibung};
}

sub Ort {
    my ($self, $ort) = @_;
    $self->{Ort} = $ort if defined $ort;
    return $self->{Ort};
}

sub Refnummer {
    my ($self, $refnummer) = @_;
    $self->{Refnummer} = $refnummer if defined $refnummer;
    return $self->{Refnummer};
}

sub Filename {
    my ($self, $filename) = @_;
    $self->{Filename} = $filename if defined $filename;
    return $self->{Filename};
}

sub Alter {
    my ($self, $alter) = @_;
    $self->{Alter} = $alter if defined $alter;
    return $self->{Alter};
}

sub Email {
    my ($self, $email) = @_;
    $self->{Email} = $email if defined $email;
    return $self->{Email};
}

sub Name {
    my ($self, $name) = @_;
    $self->{Name} = $name if defined $name;
    return $self->{Name};
}

sub Arbeitsamt {
    my ($self, $arbeitsamt) = @_;
    $self->{Arbeitsamt} = $arbeitsamt if defined $arbeitsamt;
    return $self->{Arbeitsamt};
}

sub Anschreiben {
    my ($self, $anschreiben) = @_;
    $self->{Anschreiben} = $anschreiben if defined $anschreiben;
    return $self->{Anschreiben};
}

sub Subject {
    my ($self, $subject) = @_;
    $self->{Subject} = $subject if defined $subject;
    return $self->{Subject};
}

sub Test_Mode {
    my ($self, $test_mode) = @_;
    $self->{Test_Mode} = $test_mode if defined $test_mode;
    return $self->{Test_Mode};
}


sub plz_list {
    my ($self, @list) = @_;
    if ($#list > -1){
	$self->{'plz_list'} = \@list;
    }
    return $self->{'plz_list'};
}

sub plz_list_shift{
    my ($self) = @_;
    return shift (@{$self->{'plz_list'}});
}


sub push_plz_list {
    my $self = shift;
    return push @{$self->{plz_list}}, shift;
}

sub pop_plz_list {
    my $self = shift;
    return pop @{$self->{plz_list}};
}


=head2 $bewerber->parse_file( $file )

Parses a file containing the data of an applicant from http://www.arbeitsagentur.de

I<Parameter:>
C<$file> - file name

=cut

sub parse_file {
    my ($self, $file) = @_;
    #print STDERR "Working on $file\n".("x" x 20)."\n";
    #
    # Read file
    #
    my $separator = $/;
    undef $/;
    open(JOB, "<$file");
    my $html = <JOB>;
    close(JOB);
    $/ = $separator;

    #
    # Extract the job description and ref number
    #
    my ($job_name)	= $html =~ m/Details zum Bewerberprofil - (.+?)<br\/>Referenznummer:/;
    my ($refnummer)	= $html =~ m/Referenznummer: ([^<]+)</;
    $self->Berufsbezeichnung($job_name || "-- (unbekannter Beruf) --");
    $self->Refnummer($refnummer || 0);

    #
    # Original-Job-Bezeichnung für die E-Mail-Liste:
    #
    my $job_utf = $job_name;
    $job_utf =~ s/\n//g if $job_utf; # prevent warning if $job_name is empty.
    $self->Berufsbezeichnung_utf($job_utf || "-");

    #
    # Extract job descriptions
    #
    print STDERR "Working on: $file\n";
 
    
    my ($job_description) = $html =~ m/(<table id="bewerberdetailansicht_werdegang_table_id".*?<\/table>)/sm;
    $job_description =~ s/<colgroup.*?<\/tr>//sm;
    $job_description =~ s/<img[^>]+>//g;

    $self->Stellenbeschreibung($job_description || "-");
    
    # Where do you want to work tomorrow?
    # Note: it would be cleaner to extract such info via something 
    # like HTML::Parser
    # The job_site & plz-code has been copied to Suche.pm::test_plz
    my $job_site = &Dewarim::Arbeit::Suche::get_locations($html);
    $self->Ort($job_site);
#    warn("job_site: $job_site");
    $self->plz_list( &Dewarim::Arbeit::Suche::get_plz_list($job_site) );
    
    #
    # Extract the age of the applicant
    #
    my ($alter) = $html =~ m/Alter\D+(\d+)/sm;
    $self->Alter($alter || "?");

    #
    # Extract email address
    #
    $self->Email($html =~ m/>([^\@><\s]+\@[-_.a-zA-Z0-9]+)/);

    my ($name) = $html =~ m!Name\s+
	des\s+
	Bewerbers\s+
	</span><br\s*/>\s+
        ([^<&]+)(?:&|<)!xsm;
    if (! $name){
	# Namen aus Druckansichten extrahieren:
	$name = $html =~ m!<b>\s+([^<]+)<!sm;
	# Ein richtiger Name sollte Vor- und Nachnamen enthalten.
	# Bei dieser einfachen Regex haben die Leute Pech, die komplexere
	# Namen als Jörg-Max Mustermann-Schulze haben.
	$name = $name || "";
	$name = "Bewerber/in" unless $name =~ m/^[-\w]+\s+[-\w]+$/;
    }
    #print STDERR $name."\n";
    $self->Name($name);

    #
    # Extract the filename
    #
    my ($filename) = $file =~ m/.*\/(.+)$/;
    $self->Filename($filename);

    return 1;

}


1;

__END__

=head1 SEE ALSO

L<Dewarim::Arbeit::Bewerberliste> - A container for Bewerber objects

http://arbeitssuche.sourceforge.net


=head1 AUTHORS

Ingo Wiarda
dewarim@users.sourceforce.net

Stefan Rother
bendana@users.sourceforce.net


=head1        COPYRIGHT

Copyright (c) 2004,2005, I. Wiarda, S. Rother. All Rights Reserved.
This module is free software. It may be used, redistributed
and/or modified under the same terms as Perl itself.
