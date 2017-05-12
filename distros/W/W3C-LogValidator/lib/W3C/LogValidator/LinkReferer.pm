# Copyright (c) 2002-2005 the World Wide Web Consortium :
#       Keio University,
#       European Research Consortium for Informatics and Mathematics
#       Massachusetts Institute of Technology.
# written by Olivier Thereaux <ot@w3.org> for W3C
#
# $Id: LinkReferer.pm,v 1.2 2006/08/08 05:39:34 ot Exp $

package W3C::LogValidator::LinkReferer;
use strict;
no strict "refs";
use warnings;


require Exporter;
our @ISA = qw(Exporter);
our %EXPORT_TAGS = ( 'all' => [ qw() ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw();
our $VERSION = sprintf "%d.%03d",q$Revision: 1.2 $ =~ /(\d+)\.(\d+)/;


###########################
# usual package interface #
###########################
our $verbose = 1;
our %config;

sub new
{
        my $self  = {};
        my $proto = shift;
        my $class = ref($proto) || $proto;
	# mandatory vars for the API
	@{$self->{URIs}} = undef;
	# don't change this
	if (@_) {%config =  %{(shift)};}
	if (exists $config{verbose}) {$verbose = $config{verbose}}
        bless($self, $class);
        return $self;
}

sub uris { 
	my $self = shift;
	if (@_) { @{$self->{URIs}} = @_ }
	return @{$self->{URIs}};
}


sub trim_uris 
{
        my $self = shift;
        my @trimmed_uris;
	my $exclude_regexp = "";
	my @exclude_areas;
	$exclude_regexp = $config{ExcludeAreas};
	if ($exclude_regexp){
		$exclude_regexp =~ s/\//\\\//g ;
		@exclude_areas = split(" ", $exclude_regexp);
	}
	else { print "nothing to exclude\n" if ($verbose >2);}
        my $uri;
        while ($uri = shift)
        {
	    my $acceptable = 1;
	    foreach my $area (@exclude_areas)
	    {
                if ($uri =~ /$area/)
                {	
			my $slasharea = $area;
			$slasharea =~ s/\\\//\//g;
			$slasharea =~ s/\\././g;
			print "Ignoring $uri matching $slasharea \n" if ($verbose > 2) ; 
			$acceptable = 0;		
                }
	    }	
	    push @trimmed_uris,$uri if ($acceptable);
        }
        return @trimmed_uris;
}


#########################################
# Actual subroutine to check the list of uris #
#########################################


sub process_list
{
	my $self = shift;
	my $max_invalid = undef;
	my $max_documents = undef;
	if (exists $config{MaxDocuments}) {$max_documents = $config{MaxDocuments}}
	else {$max_documents = 0}

# This basic module does not actually "validates"
# so MaxInvalid is not relevant... Keeping it anyway
	if (exists $config{MaxInvalid}) {$max_invalid = $config{MaxInvalid}}
	else {$max_invalid = 0}
	my $name = "";
	if (exists $config{ServerName}) {$name = $config{ServerName}}

	print "Now Using the Link Referer module... \n" if $verbose;
	my %hits;
	my %HTTPcodes;
	my %referers;
	my @uris = undef;
	use DB_File; 
	if (defined ($config{tmpfile}))
	{
		my $tmp_file = $config{tmpfile};
		tie (%hits, 'DB_File', "$tmp_file", O_RDONLY) || 
		    die ("Cannot create or open $tmp_file");
		@uris = sort { $hits{$b} <=> $hits{$a} } keys %hits;
	}

	elsif ($self->uris())
	{
		@uris = $self->uris();
		foreach my $uri (@uris) { $hits{$uri} = 0 }
	}

        @uris = $self->trim_uris(@uris);


	if (defined ($config{tmpfile_HTTP_codes}))
	{
		my $tmp_file_HTTP_codes = $config{tmpfile_HTTP_codes};
		tie (%HTTPcodes, 'DB_File', "$tmp_file_HTTP_codes", O_RDONLY) || 
		    die ("Cannot create or open $tmp_file_HTTP_codes");
	}

	if (defined ($config{tmpfile_referers}))
	{
		my $tmp_file_referers = $config{tmpfile_referers};
		tie (%referers, 'DB_File', "$tmp_file_referers", O_RDONLY) || 
		    die ("Cannot create or open $tmp_file_referers");
		    print "size of hash:  " . keys( %referers ) . ".\n";
	}


	my $intro="Here are the <census> most popular problematic documents (404 not found etc),";
	$intro .="along with their top referer, that I could find for $name.";
	if (exists $config{LogProcessor}{RefererMatch}) {
	    if ($config{LogProcessor}{RefererMatch} != ".*") {
	    my $intro .="\n\nOnly referers matching ".$config{LogProcessor}{RefererMatch}." were considered.";
		}
	}
	my @result;
	my @result_head;
	push @result_head, "Rank";
	push @result_head, "Hits";
	push @result_head, "Address";
	push @result_head, "Status Code";
	push @result_head, "Top Referer";
	my $census = 0;
	while ( (@uris) and  (($census < $max_documents) or (!$max_documents)) )
	{
		my $uri = shift (@uris);
		chomp ($uri);
		my @result_tmp;
		if (defined $HTTPcodes{$uri}) 
		{ if ( $HTTPcodes{$uri} =~ /(404|5..)/)
		 { # This module should ignore requests that resulted in success codes
		    $census++;
		    push @result_tmp, "$census";
		    push @result_tmp, "$hits{$uri}";
		    push @result_tmp, "$uri";
		    push @result_tmp, "$HTTPcodes{$uri}";
		    my %this_uri_referers;
		    my $referer_string = "";
		    foreach my $urireferer (keys %referers) 
		    {
			if ($urireferer =~ /$uri : (.*)/) { 
				$this_uri_referers{$1} = $referers{$urireferer};
			}
		    }
		    my @sorted_refs = sort { $this_uri_referers{$a} cmp $this_uri_referers{$b} } keys %this_uri_referers;
		    if (defined $sorted_refs[0]) {
		        my $top_referer = pop @sorted_refs;
		        $referer_string .= $top_referer." (".$this_uri_referers{$top_referer}.")";
 		    }
		    push @result_tmp, $referer_string;
		    if ($referer_string ne "") {
		        push @result, [@result_tmp];
		    }
		   else {
			$census--;
		   }
		 }
		}
	}
	print "Done!\n" if $verbose;
	if ($census eq 1) # let's repect grammar here
                {
                        $intro=~ s/are/is/;
                        $intro=~ s/<census> //;
                        $intro=~ s/document\(s\)/document/;
                }
	else
	{
		$intro=~ s/<census>/$census/;
	}
	if (defined ($config{tmpfile})) { 
		untie %hits;
	}
	if (defined ($config{tmpfile_HTTP_codes})) { untie %HTTPcodes; }
	if (defined ($config{tmpfile_referers})) { untie %referers; }
	my $outro="";
	my %returnhash;
	$returnhash{"name"}="Links referers";
	$returnhash{"intro"}=$intro;
	$returnhash{"outro"}=$outro;
	@{$returnhash{"thead"}}=@result_head;
	@{$returnhash{"trows"}}=@result;
	return %returnhash;
}

package W3C::LogValidator::LinkReferer;

1;

