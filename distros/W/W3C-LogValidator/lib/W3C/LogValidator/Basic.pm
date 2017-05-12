# Copyright (c) 2002-2005 the World Wide Web Consortium :
#       Keio University,
#       European Research Consortium for Informatics and Mathematics
#       Massachusetts Institute of Technology.
# written by Olivier Thereaux <ot@w3.org> for W3C
#
# $Id: Basic.pm,v 1.18 2008/11/18 16:48:56 ot Exp $

package W3C::LogValidator::Basic;
use strict;
use warnings;


require Exporter;
our @ISA = qw(Exporter);
our %EXPORT_TAGS = ( 'all' => [ qw() ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw();
our $VERSION = sprintf "%d.%03d",q$Revision: 1.18 $ =~ /(\d+)\.(\d+)/;


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

	print "Now Using the Basic module... \n" if $verbose;
	my %hits;
	my %HTTPcodes;
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


	my $intro="Here are the <census> most popular documents overall for $name.";
	my @result;
	my @result_head;
	push @result_head, "Rank";
	push @result_head, "Hits";
	push @result_head, "Address";
	my $census = 0;
	while ( (@uris) and  (($census < $max_documents) or (!$max_documents)) )
	{
		my $uri = shift (@uris);
		chomp ($uri);
		my @result_tmp;
		if (!defined $HTTPcodes{$uri})
		{ # if no HTTP code present, assume it's a 200
		    $census++;
		    push @result_tmp, "$census";
		    push @result_tmp, "$hits{$uri}";
		    push @result_tmp, "$uri";
		    push @result, [@result_tmp];
		}
		elsif (($HTTPcodes{$uri} eq "200")  or (!$HTTPcodes{$uri} =~ /\d+/))
		# should perhaps make a subroutine for that instead of DUPing code
		{
		    $census++;
		    push @result_tmp, "$census";
		    push @result_tmp, "$hits{$uri}";
		    push @result_tmp, "$uri";
		    push @result, [@result_tmp];
		}
		elsif ((defined $HTTPcodes{$uri}) and ($verbose > 2)) { 
		    print "$uri returned code $HTTPcodes{$uri}, ignoring \n"; 
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
	my $outro="";
	my %returnhash;
	$returnhash{"name"}="basic";
	$returnhash{"intro"}=$intro;
	$returnhash{"outro"}=$outro;
	@{$returnhash{"thead"}}=@result_head;
	@{$returnhash{"trows"}}=@result;
	return %returnhash;
}

package W3C::LogValidator::Basic;

1;

__END__

=head1 NAME

W3C::LogValidator::Basic - [W3C Log Validator] Sort Web server log entries by popularity (hits)

=head1 SYNOPSIS

  use  W3C::LogValidator::Basic;
  my $b = new W3C::LogValidator::Basic;
  $b->uris('http://www.w3.org/Overview.html', 'http://www.yahoo.com/index.html');
  my $result_string= $b->process_list();

=head1 DESCRIPTION


This module is part of the W3C::LogValidator suite, and simply gives back pages
sorted by popularity. This is an example of simple module for LogValidator.

=head1 API 

=head2 Constructor

=over 2

=item $b = W3C::LogValidator::Basic->new

Constructs a new C<W3C::LogValidator:HTMLBasic> processor.  

You might pass it a configuration hash reference (see L<W3C::LogValidator/config_module> and L<W3C::LogValidator::Config>)
Particularly relevant for this module are the "verbose", "MaxDocuments" and obviously "tmpfile" (see C<process_list>).
Pass the configuration hash ref as follows:

  $b = W3C::LogValidator::HTMLValidator->new(\%config);

=back

=head2 General Methods

=over 4

=item b->uris 

Returns a  list of URIs to be processed (unless the configuration gives the location for the hash of URI/hits berkeley file, see C<process_list> 
If an array is given as a parameter, also sets the list of URIs and returns it.
Note: while this method is useful in other modules of L<W3C::LogValidator>, this basic module is here to sort URIs extracted from Log Files by popularity, this method is hence rather useless for L<W3C::LogValidator::Basic>.

=item b->trim_uris 

Given a list of URIs of documents to process, returns a subset of this list containing the URIs of documents the module supposedly can handle.
For this module, the decision is made based on the setting for ExcludedAreas only


=item b->process_list

Formats the list of URIs sorted by popularity.

Returns a result hash. Keys for this hash are: 

  name (string): the name of the module, i.e "Basic"
  intro (string): introduction to the processing results
  thead (array): headers of the results table
  trows (array of arrays): rows of the results table
  outro (string): conclusion of the processing results

=back

=head1 BUGS

Public bug-tracking interface at http://www.w3.org/Bugs/Public/


=head1 AUTHOR

Olivier Thereaux <ot@w3.org> for W3C

=head1 SEE ALSO

W3C::LogValidator, perl(1).
Up-to-date complete info at http://www.w3.org/QA/Tools/LogValidator/

=cut
