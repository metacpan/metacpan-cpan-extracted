package WWW::Rafb;

=pod

=head1 NAME

WWW::Rafb - Perl interface for rafb pasting site ( rafb.net/paste ) 

=head1 SYNOPSIS
		
	# create object with the paste information
	my $paste = WWW::Rafb->new( 'language' => 'perl',
                                'nickname' => 'Di42lo',
                                'description' => 'my first script in perl',
                                'tabs' => 'No',
                                'file' => "~/first.pl");
								
	# do the http request ( the paste itself )
	$paste->paste();

	# print the url
	print "You can get $paste->{file} at url: $paste->{URL}\n";

=head1 DESCRIPTION

"WWW::Rafb" provides object interface for pasting any text file/source file
into the the rafb site with the needed information.

This module requires B<LWP::UserAgent> and B<use URI::Escape>.

=head1 INTERFACE

=cut

#use strict;

use vars qw/$VERSION/;
$VERSION = "0.02";

use LWP::UserAgent;
use URI::Escape;

sub _agent {
	my $self = shift;

	# creates LWP::UserAgent object
	my $agent = LWP::UserAgent->new;
	$agent->timeout(10);
	
	$agent->agent('Mozilla/5.0'); # fake agent
	$agent->default_header('Keep-Alive' => 300);
	$agent->default_header('Connection' => 'keep-alive');

	$self->{AGENT} = $agent;

return $self;
}

=pod

	new( [ARGS] )

		Used to set the pasting information about the file and create a new 
		Object of the WWW::Rafb module. 

		Arguments:

		language - The file type. One of this types:
		note: you should write the value (in the () ) and not the full name.

			C89 (c89)
    		C99 (c)
    		C++ (c++) 
 			C#	(c#)
 			Java (java)
			Pascal (pascal)
			Perl (perl)
			PHP	(php)
			PL/I (pl/i)
			Python (python)
			Ruby (ruby)
			SQL	(sql)
			Visual Basic (vb)
			Plain Text (plain text)
	
        nickname - the nickname of the script/file publisher
        description' => 'my first script in perl',
        tabs - values: No/2/4/6/8
        file - path of the file we want to upload.

		NOTES: 	Returns a blessed object with the information.

=cut

my %types = (
			"C89" 			=>		"c89",
    		"C99" 			=>		"c",
    		"C++" 			=>		"c++", 
 			"C#"			=>		"c#",
 			"Java" 			=>		"java",
			"Pascal"		=>		"pascal",
			"Perl"			=>		"perl",
			"PHP"			=>		"php",
			"PL/I"			=>		"pl/i",
			"Python"		=>		"python",
			"Ruby"			=>		"ruby)",
			"SQL"			=>		"sql",
			"Visual Basic" 	=>		"vb",
			"Plain Text"	=>		"plain text"
			);
			
sub new {
my $class = shift;
my %args = @_;
my $self;

	# inserts args into class
	foreach (keys %args) {
		$self->{uc($_)} = $args{$_};
	}

	# check args
	$self->{LANGUAGE} = "C++" unless ($self->{LANGUAGE} && $types{"$self->{LANGUAGE}"});
	
	$self->{TABS} = "No" if ($self->{TABS} < 2 || $self->{TABS} > 8); 
	
	open(FH, "< $self->{FILE}") || die ("Cant open file for pasting!\n");
	
	# escape our form values
	$self->{SOURCE} .= $_ while (<FH>);
	close (FH);

	$self->{SOURCE} =~ s/ /+/g;
	$self->{SOURCE} = URI::Escape::uri_escape_utf8($self->{SOURCE});
	$self->{SOURCE} =~ s/%2B/+/g;
	
	$self->{NICKNAME} =~ s/ /+/g;
	$self->{NICKNAME} = URI::Escape::uri_escape_utf8($self->{NICKNAME});
	$self->{NICKNAME} =~ s/%2B/+/g;
	
	$self->{DESCRIPTION} =~ s/ /+/g;
	$self->{DESCRIPTION} = URI::Escape::uri_escape_utf8($self->{DESCRIPTION});
	$self->{DESCRIPTION} =~ s/%2B/+/g;
	
	$self->{SITE} = "http://www.rafb.net/paste";
	# return the object
	return bless $self, $class;
		
}

=pod

	paste() 

		Returns the object with the URL of the file in the 
		rafb.net/paste site and the other informations.

		No Arguments.

=cut

sub paste {
	my $self = shift;
	
	$self->_agent();
	
	# Create and send the request
	my $req = HTTP::Request->new( POST => $self->{SITE} ."/paste.php");
	$req->content_type('application/x-www-form-urlencoded');
	$req->content(	"lang=" . $self->{LANGUAGE} . "&".
					"nick=" . $self->{NICKNAME} . "&" . 
					"desc=" . $self->{DESCRIPTION} . "&" .
					"cvt_tabs=" . $self->{TABS} . "&" .
					"text=" . $self->{SOURCE});
		
	my $res = $self->{AGENT}->request($req);
	
	$self->{URL} = "http://www.rafb.net/" . $res->header("Location");
	return $self;

}

=pod

=head1 LINKS

http://www.rafb.net/paste

=head1 NOTES

Don't run this script too much times, the site has protection from that.
to solve that - sleep(10) between the pastes.

=head1 AUTHOR

This module was written by
Amit Sides C<< <amit.sides@gmail.com> >>

=head1 Copyright

Copyright (c) 2006 Amit Sides. All rights reserved. 

=head1 LICENSE

This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=cut

1;
