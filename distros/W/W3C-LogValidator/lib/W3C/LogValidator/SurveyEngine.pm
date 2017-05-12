# Copyright (c) 2004-2005 the World Wide Web Consortium :
#       Keio University,
#       European Research Consortium for Informatics and Mathematics 
#       Massachusetts Institute of Technology.
# written by Matthieu Faure <matthieu@faure.nom.fr> for W3C
# maintained by olivier Thereaux <ot@w3.org> and Matthieu Faure <matthieu@faure.nom.fr>
# $Id: SurveyEngine.pm,v 1.13 2006/04/12 02:42:46 ot Exp $

package W3C::LogValidator::SurveyEngine;
use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);
our %EXPORT_TAGS = ( 'all' => [ qw() ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw();
our $VERSION = sprintf "%d.%03d",q$Revision: 1.13 $ =~ /(\d+)\.(\d+)/;


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
	# internal stuff here
	# $self->{FOO} = undef;
	
	# don't change this
        if (@_) {%config =  %{(shift)};}
	if (exists $config{verbose}) {$verbose = $config{verbose}}
        if (exists $config{AuthorizedExtensions})
        {
                $self->{AUTH_EXT} =  $config{AuthorizedExtensions};
        }
        else # same as the formats supported by markup Validator
	# TODO add support for CSS too, at least
        {
		$self->{AUTH_EXT} = ".html .xhtml .phtml .htm .shtml .php .svg .xml /";
	}
	$config{ValidatorHost} = "validator.w3.org" if (! exists $config{ValidatorHost});
	$config{ValidatorPort} = "80" if (!exists $config{ValidatorPort});
	$config{ValidatorString} = "/check\?uri=" if (!exists $config{ValidatorString});
	$config{ValidatorVersion} = "0.7.0" if (!exists $config{ValidatorVersion});
	bless($self, $class);
        return $self;
}


sub uris
{
	my $self = shift;
	if (@_) { @{$self->{URIs}} = @_ }
	return @{$self->{URIs}};
}


sub auth_ext
{
	my $self=shift;
	if (@_) { $self->{AUTH_EXT} = shift}
	return $self->{AUTH_EXT};
}

sub trim_uris 
{
        my $self = shift;
        my @authorized_extensions = split(" ", $self->auth_ext);
        my @trimmed_uris;
        my $exclude_regexp = "";
        my @excluded_areas;
        $exclude_regexp = $config{ExcludeAreas};
        if ($exclude_regexp){
            $exclude_regexp =~ s/\//\\\//g ;
            @excluded_areas = split(" ", $exclude_regexp);
        }
        else { print "nothing to exclude\n" if ($verbose >2);}
        my $uri;
        while ($uri = shift)
        {
                my $uri_ext = "";
                my $match = 0;
                if ($uri =~ /(\.[0-9a-zA-Z]+)$/)
                {
                   $uri_ext = $1;
                }
                elsif ($uri =~ /\/$/) { $uri_ext = "/";}
                foreach my $ext (@authorized_extensions)
                {
                    if ($ext eq $uri_ext) { $match = 1; }
                }
                if ($match)
                {
                  foreach my $area (@excluded_areas)
                  {
                    if ($uri =~ /$area/)
                    {
                        my $slasharea = $area;
                        $slasharea =~ s/\\\//\//g;
                        $slasharea =~ s/\\././g;
                        print "Ignoring $uri matching $slasharea \n" if ($verbose > 2) ;
                        $match = 0;
                    }

                  }
                }

                push @trimmed_uris,$uri if ($match);
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
    if ( exists $config{MaxInvalid} ) { $max_invalid = $config{MaxInvalid}; }
    else {$max_invalid = 0;}
    if (exists $config{MaxDocuments}) {$max_documents = $config{MaxDocuments}; }
    else {$max_documents = 0;}
    # print "$max_documents max documents" if ($verbose > 2); # debug
    my $name = ""; 
    if (exists $config{ServerName}) {$name = $config{ServerName}}


    print "Now Using the SurveyEngine module...\n" if $verbose;
    my %hits;
    my @uris;
    use URI::Escape;
    use LWP::UserAgent;
    if (defined ($config{tmpfile}))
	{
		use DB_File; 
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
    @uris = sort { $hits{$b} <=> $hits{$a} } keys %hits;
					
    my @result_head;
    #push @result_head, "Hits";
    push @result_head, "Rank";
    push @result_head, "Hits";
    push @result_head, "URI";
    push @result_head, "Charset";
    push @result_head, "Doctype";
    push @result_head, "Valid (#err)";
	
    my @result;
    my $uri = undef;
    my $ua = new LWP::UserAgent;
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
    $year += 1900;
    $mon = sprintf ( "%02d", $mon);
    $mday = sprintf ("%02d", $mday);
    my $localDate = "$year-$mon-$mday" ;
    my $census = 0;

    @uris = $self->trim_uris(@uris);

    while ((@uris) and  (($census < $max_documents) or (!$max_documents)) )
    {
      # a few initializations
      $uri = shift (@uris);
      my $uri_orig = $uri;
      $uri = uri_escape($uri);
      my @result_tmp = ();
     $census = $census+1;
      print "	processing #$census $uri_orig..." if ($verbose > 1);
      # filling result table with "fixed" content
      push @result_tmp, $census;
      push @result_tmp, $hits{$uri_orig};
      push @result_tmp, $uri_orig;

      my $validatorUri = join ("", "http://",$config{ValidatorHost},":",$config{ValidatorPort}, $config{ValidatorString},$uri);
      print "$validatorUri \n" if ($verbose > 2); # debug info
	
      my $testStringCharset = undef;
      my $testStringDoctype = undef;
      my $testStringInvalid = undef;
      my $testStringValid = undef;
	  my $testStringErrorNum = undef;

	  if ( $config{ValidatorVersion} eq "0.6.1" ) {
		$testStringCharset = 'I was not able to extract a character encoding labeling from any of';
		$testStringDoctype = '<h2>Fatal Error: No DOCTYPE specified!</h2>';
		$testStringInvalid = '<h2 id="result" class="invalid">This page is <strong>not</strong> Valid';
		$testStringValid = '<h2 id="result" class="valid">This Page Is Valid';
		$testStringErrorNum = '<th>Errors: </th>.*?<td>(\d+)</td>';
      } elsif ( $config{ValidatorVersion} eq "0.6.5" ) {
		$testStringCharset = 'found are not valid values in the specified Character Encoding';
		$testStringDoctype = '<h3>No DOCTYPE Found!';
		$testStringInvalid = '<h2 class="invalid">This page is <strong>not</strong> Valid';
		$testStringValid = '<h2 id="result" class="valid">This Page Is Valid';
		$testStringErrorNum = '<th>Errors: </th>.*?<td>(\d+)</td>';
      } else { 
		# Default ValidatorVersion is 0.7.0 (current version as of August 2005)
		$testStringValid = '<h2 class="valid">This Page Is Valid';
		$testStringErrorNum = 'Failed validation, .* errors';
		$testStringDoctype = 'No <code>DOCTYPE</code> found!';
		$testStringInvalid = '<h2 id="results" class="invalid">This page is';
		$testStringCharset = 'found are not valid values in the specified Character Encoding';
      }

      my $request = new HTTP::Request("GET", $validatorUri );
      my $validatorResponse = new HTTP::Response;
      $validatorResponse = $ua->simple_request($request);

      if ( ! $validatorResponse->is_success ) {
		push @result_tmp, "N/A";
		push @result_tmp, "N/A";
		push @result_tmp, "can't connect";
      } else {
		# Actual tests
		if ( $validatorResponse->content =~ $testStringCharset ) {
		  push @result_tmp, "No";
		  push @result_tmp, "N/A";
		  push @result_tmp, "N/A";
		}
		elsif ( $validatorResponse->content =~ $testStringDoctype ) {
		  push @result_tmp, "Yes";
		  push @result_tmp, "No";
		  push @result_tmp, "N/A";
		}
		elsif ( $validatorResponse->content =~ $testStringInvalid ) 
		{
		   push @result_tmp, "Yes";
		   push @result_tmp, "Yes";
		   my $numErrors = $validatorResponse->header('X-W3C-Validator-Errors');
		   print "Invalid... $numErrors Errors" if ( $verbose > 1);
		   push @result_tmp, "No ($numErrors)";
		}
		elsif ( $validatorResponse->content =~ $testStringValid ) {
		  push @result_tmp, "Yes";
		  push @result_tmp, "Yes";
		  push @result_tmp, "Yes";
		} else {
		  push @result_tmp, "N/A";
		  push @result_tmp, "N/A";
		  push @result_tmp, "Could not validate";
		}
	 print "\n" if ($verbose > 1);
      }
      # store results for this URI in table of results
      push @result, [@result_tmp];
    }
    my $intro_str = "Here are the $census most popular documents surveyed for $name on .";
    print "Done!\n" if $verbose;
    #print "Result: @result \n" if $verbose;
    if (defined ($config{tmpfile}))
    {
	untie %hits;
    }
    # Here is what the module will return. The hash will be sent to 
    # the output module

    my %returnhash;
    # the name of the module
    $returnhash{"name"}="SurveyEngine";
    #intro
    $returnhash{"intro"}=$intro_str;
    #Headers for the result table
    @{$returnhash{"thead"}} = @result_head;
    # data for the results table
    @{$returnhash{"trows"}} = @result;
    #outro
    $returnhash{"outro"}="";
    return %returnhash;
}

package W3C::LogValidator::SurveyEngine;

1;

__END__

=head1 NAME

W3C::LogValidator::SurveyEngine - [W3C Log Validator] Generic Web site validity/quality survey engine

=head1 SYNOPSIS

  use  W3C::LogValidator::SurveyEngine;
  my %config = ("verbose" => 2);
  my $validator = W3C::LogValidator::SurveyEngine->new(\%config);
  $validator->uris('http://www.w3.org/Overview.html', 'http://www.yahoo.com/index.html');
  my %results = $validator->process_list;


=head1 DESCRIPTION

This module is part of the W3C::LogValidator suite, and processes a list of URIs in order
to produce a validity/quality survey.

This module is experimental.

=head1 API

=head2 Constructor

=over 2

=item $val = W3C::LogValidator::SurveyEngine->new

Constructs a new C<W3C::LogValidator::SurveyEngine> processor.  

You might pass it a configuration hash reference (see L<W3C::LogValidator/config_module> and L<W3C::LogValidator::Config>)

  $validator = W3C::LogValidator::SurveyEngine->new(\%config);  

=back

-head2 General methods

=over 4

=item $val->process_list

Processes a list of sorted URIs through different quality tools to produce a survey of their quality/validity

The list can be set C<uris>. If the $val was given a config has when constructed, and if the has has a "tmpfile" key, C<process_list> will try to read this file as a hash of URIs and "hits" (popularity) with L<DB_File>.

Returns a result hash. Keys for this hash are: 


  name (string): the name of the module, i.e "HTMLValidator"
  intro (string): introduction to the processing results
  thead (array): headers of the results table
  trows (array of arrays): rows of the results table
  outro (string): conclusion of the processing results


=item $val->trim_uris 

Given a list of URIs of documents to process, returns a subset of this list containing the URIs of documents the module supposedly can handle.
The decision is made based on file extensions (see C<auth_ext>) and the ExcludeAreas configuration setting.


=item $val->auth_ext

Returns the file extensions (space separated entries in a string) supported by the Module.
Public method accessing $self->{AUTH_EXT}, itself coming from either the AuthorizedExtensions configuration setting, or a default value

=back



=head1 AUTHOR

Matthieu Faure  <matthieu@faure.nom.fr>

Maintained by olivier Thereaux <ot@w3.org> for W3C

=head1 SEE ALSO

W3C::LogValidator::LogProcessor, perl(1).
Up-to-date complete info at http://www.w3.org/QA/Tools/LogValidator/

=cut
