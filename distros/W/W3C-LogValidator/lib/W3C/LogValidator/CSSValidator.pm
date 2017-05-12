# Copyright (c) 2004-2005 the World Wide Web Consortium :
#       Keio University,
#       European Research Consortium for Informatics and Mathematics 
#       Massachusetts Institute of Technology.
# written by olivier Thereaux <ot@w3.org> for W3C
#
# $Id: CSSValidator.pm,v 1.23 2008/11/18 16:48:56 ot Exp $

package W3C::LogValidator::CSSValidator;
use strict;
use warnings;
use DB_File; 



require Exporter;
our @ISA = qw(Exporter);
our %EXPORT_TAGS = ( 'all' => [ qw() ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw();
our $VERSION = sprintf "%d.%03d",q$Revision: 1.23 $ =~ /(\d+)\.(\d+)/;


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
	# don't change this
        if (@_) {%config =  %{(shift)};}
	if (exists $config{verbose}) {$verbose = $config{verbose}}
	if (exists $config{AuthorizedExtensions})
	{
		$self->{AUTH_EXT} =  $config{AuthorizedExtensions};
	}
	else
	{
		$self->{AUTH_EXT} = ".css";
	}
  $config{ValidatorMethod} = "HEAD" ;
  $config{ValidatorHost} = "jigsaw.w3.org" if (! exists $config{ValidatorHost});
  $config{ValidatorPort} = "80" if (!exists $config{ValidatorPort});
  $config{ValidatorString} = "/css-validator/validator" if (!exists $config{ValidatorString});
  $config{ValidatorString} .= "?uri="; 
  # by default, report invalid documents
  $config{ShowInvalid} = "Yes" if (!exists $config{ShowInvalid});
  $config{ShowAborted} = "No" if (!exists $config{ShowAborted});
  $config{ShowValid} = "No" if (!exists $config{ShowValid});
  $config{CheckExtensionlessURIs} = "No" if (!exists $config{CheckExtensionlessURIs});
  bless($self, $class);
  return $self;
}


# internal routines

sub new_doc{
        my $self=shift;
	$self->{VALID} = undef;
        $self->{VALID_ERR_NUM} = undef;
        $self->{VALID_SUCCESS} = undef;
}

sub auth_ext
{
        my $self=shift;
        if (@_) { $self->{AUTH_EXT} = shift}
        return $self->{AUTH_EXT};
}

sub valid
{
        my $self = shift;
        if (@_) { $self->{VALID} = shift }
                return $self->{VALID};
}

sub valid_err_num
{
        my $self = shift;
        if (@_) { $self->{VALID_ERR_NUM} = shift }
                return $self->{VALID_ERR_NUM};
}

sub valid_success
{
        my $self = shift;
        if (@_) { $self->{VALID_SUCCESS} = shift }
                return $self->{VALID_SUCCESS};
}
sub valid_head
{
        my $self = shift;
        if (@_) { $self->{VALID_HEAD} = shift }
                return $self->{VALID_HEAD};
}


sub HEAD_check {
## Checking whether a document with no extension is actually a CSS file
## causes a lot of requests, but internal - should be OK?
        my $self = shift;
        my $check_uri;
        use LWP::UserAgent;
        if (@_) { $check_uri = shift }
        my $ua = new LWP::UserAgent;
        my $method = "HEAD";
        my $request = new HTTP::Request("$method", "$check_uri");
        my $response = new HTTP::Response;
        $response = $ua->simple_request($request);
        my $is_css = 0;
        if ($response->is_success) # not an error, we could contact the server
        {
                my $type = $response->header('Content-Type');
                if ($type =~ /text\/css/) 
                {
                        $is_css = 1;
                        print "URI with no extension $check_uri has content-type $type\n" if ($verbose > 2); # debug
                }
        }
        return $is_css;
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
      	my %HTTPcodes;
      	if (defined ($config{tmpfile_HTTP_codes}))
      	{
      		my $tmp_file_HTTP_codes = $config{tmpfile_HTTP_codes};
      		tie (%HTTPcodes, 'DB_File', "$tmp_file_HTTP_codes", O_RDONLY) || 
      		    die ("Cannot create or open $tmp_file_HTTP_codes");
      	}

        while ($uri = shift)
        {
                my $uri_ext = "";
                my $match = 0;
                if ($uri =~ /(\.[0-9a-zA-Z]+)(\?.*)?$/)
                {
                   $uri_ext = $1;
                }
                elsif ($uri =~ /\/$/) { $uri_ext = "/";}
                elsif (($uri_ext eq "") and $config{CheckExtensionlessURIs}) {$match = 1; } 
                # we keep URIs without extension, if asked to
                # otherwise, we check their mime type through the wire
                elsif ( $self->HEAD_check($uri) ) { $match = 1; }
                foreach my $ext (@authorized_extensions)
                {
                    if (($ext eq $uri_ext) or ($ext eq "*")) { $match = 1; }
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

                if (defined $HTTPcodes{$uri}) 
                { 
                  if (($HTTPcodes{$uri} ne "200")  and ($HTTPcodes{$uri} =~ /\d+/))
                  {
                    $match = 0;
                		if ($verbose > 2) { 
                		    print "$uri returned code $HTTPcodes{$uri}, ignoring \n"; 
                		}
                  }
                }
                push @trimmed_uris,$uri if ($match);
        }
        return @trimmed_uris;
}

sub uris
{
	my $self = shift;
	if (@_) { @{$self->{URIs}} = @_ }
	return @{$self->{URIs}};
}

#########################################
# Actual subroutine to check the list of uris #
#########################################


sub process_list
{
	my $self = shift;
	my $max_invalid = undef;
	if (exists $config{MaxInvalid}) {$max_invalid = $config{MaxInvalid}}
	else {$max_invalid = 0}
        my $max_documents = undef;                                                                      
        if (exists $config{MaxDocuments}) {$max_documents = $config{MaxDocuments}}                      
        else {$max_documents = 0}
	print "Now Using the CSS Validation module...\n" if $verbose;
	use LWP::UserAgent;
	use URI::Escape;
	my @uris = undef;
	my %hits;
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
	my $name = "";
	if (exists $config{ServerName}) {$name = $config{ServerName}}
       	my @result;
        my @result_head;
        push @result_head, "Rank";
        push @result_head, "Hits";
        push @result_head, "#Error(s)";
        push @result_head, "Address";

        my @whatweshow;
        my $whatweshow_str = "";

        push @whatweshow, "valid" if ($config{ShowValid} eq "Yes");
        push @whatweshow, "invalid" if ($config{ShowInvalid} eq "Yes");
        push @whatweshow, "non-validable"  if ($config{ShowAborted} eq "Yes");
        if (@whatweshow eq 3) {
          $whatweshow_str = "$whatweshow[0], $whatweshow[1] or $whatweshow[2]";
        }
        elsif (@whatweshow eq 2) {
          $whatweshow_str = "$whatweshow[0] or $whatweshow[1]";
        }
        elsif (@whatweshow eq 1) {
          $whatweshow_str = "$whatweshow[0]";
        }


        my $intro="Here are the <census> most popular $whatweshow_str document(s) that I could find in the 
logs for $name.";
        my $outro;
    	my $ua = new LWP::UserAgent;

        @uris = $self->trim_uris(@uris);
	my $invalid_census = 0; # number of invalid docs
	my $last_invalid_position = 0; # latest position at which we found an invalid doc
	my $total_census = 0; # number of documents checked

        my $uri = undef;
	# bulk of validation
        while ( (@uris) and  (($invalid_census < $max_invalid) or (!$max_invalid)) and (($total_census < $max_documents) or (!$max_documents)) )
	{
		$uri = shift (@uris);
		my $uri_orig = $uri;
		$self->new_doc();
		$total_census++;
        print "	processing #$total_census $uri... " if ($verbose > 1);
		$uri = uri_escape($uri);
		# creating the HTTP query string with all parameters
		my $string=join ("", "http://",$config{ValidatorHost},":",$config{ValidatorPort}, $config{ValidatorString},$uri);
		my $method = $config{ValidatorMethod};
		my $request = new HTTP::Request("$method", "$string");
		my $response = new HTTP::Response;
		$response = $ua->simple_request($request);
		if ($response->is_success) {
		 # not an error, we could contact the server 
			# set both valid and error number according to response
			$self->valid($response->header('X-W3C-Validator-Status'));
			$self->{VALID_ERR_NUM} = $response->header('X-W3C-Validator-Errors');
			# we know the validator has been able to (in)validate if $self->valid is not NULL
			if ( ($self->valid)) # we got an answer about validation (valid, invalid or abort)
			{
			    if ( 
			      (($self->valid =~ /Invalid/i) and ($config{ShowInvalid} eq "Yes")) 
			      or (($self->valid =~ /Valid/i) and ($config{ShowValid} eq "Yes")) 
			      or (($self->valid =~ /Abort/i) and ($config{ShowAborted} eq "Yes"))
			      )  {
				      my @result_tmp;
    			      push @result_tmp, $total_census;
    			      push @result_tmp, $hits{$uri_orig};
        			  if ($self->valid =~ /Abort/i) { push @result_tmp, "Abort"; }
				      else { push @result_tmp, $self->valid_err_num; }
				      push @result_tmp, $uri_orig;
				      push @result, [@result_tmp];
				      $invalid_census++;
				      $last_invalid_position = $total_census;
			    }
			}
    		printf (" %s!", $self->valid) if ( ($verbose > 1) and (defined ($self->valid)));
    		print " Could not validate (validation failed)!" if (($verbose > 1) and(!defined ($self->valid)));

    		if (($verbose > 1) and ($self->valid_err_num)) # verbose or debug
    				{printf ", %s errors!",$self->valid_err_num}
    		}
    		else { 
    		  print " Could not validate (no response from validator)!" if ($verbose > 1) ;
    		  if ($config{ShowAborted} eq "Yes") {
    			  my @result_tmp;
    				push @result_tmp, $total_census;
    				push @result_tmp, $hits{$uri_orig};
    				push @result_tmp, "Abort";
    				push @result_tmp, $uri_orig;
    				push @result, [@result_tmp];
    				$invalid_census++;
    				$last_invalid_position = $total_census;
    			}
    		  }
    		print "\n" if ($verbose > 1);

    		$self->valid_head($response->as_string); # for debug
    		if ($verbose > 2) {printf "%s :\n%s", $string, $self->valid_head;} # debug
    		sleep(1); # do not kill the validator

	}
	print "Done!\n" if $verbose;

#	print "invalid_census $invalid_census \n" if ($verbose > 2 );
	if ($invalid_census) # we found invalid docs
	{
	                if ($invalid_census eq 1)  # let's repect grammar here
                {
                        $intro=~ s/are/is/;
                        $intro=~ s/<census> //;
                        $intro=~ s/document\(s\)/document/;
                }
                $intro =~s/<census>/$invalid_census/;
                my $ratio = 10000*$invalid_census/$total_census;
                $ratio = int($ratio)/100;
                if ($last_invalid_position eq $total_census )
                # usual case
                {
                	$outro="Conclusion :
I had to check $last_invalid_position document(s) in order to find $invalid_census $whatweshow_str CSS documents or documents with stylesheets.
This means that about $ratio\% of your most popular documents were $whatweshow_str.";
                }
                else
		# we didn't find as many invalid docs as requested
		{
                        $outro="Conclusion :
You asked for $max_invalid $whatweshow_str stylesheet document(s) but I could only find $invalid_census 
by processing (all the) $total_census document(s) in your logs. 
This means that about $ratio\% of your most popular documents were $whatweshow_str.";
                }
        }
        elsif (!$total_census)
        {
                $intro="There was nothing to validate in this log.";
                $outro="";
        }
        else # everything was actually valid!
        {
                $intro=~s/<census> //;
                $outro="I couldn't find any $whatweshow_str document in this log.";
        }
        if (($total_census == $max_documents) and ($total_census)) # we stopped because of max_documents
        {
                $outro=$outro."\nNOTE: I stopped after processing $max_documents documents:\n      Maybe you could set MaxDocuments to a higher value?";
        }
	
	if (defined ($config{tmpfile}))
        {
		untie %hits;                                                                  
	}
	# Here is what the module will return. The hash will be sent to 
	# the output module

	my %returnhash;
	# the name of the module
	$returnhash{"name"}="CSSValidator";                                                  
	#intro
	$returnhash{"intro"}=$intro;
	#Headers for the result table
	@{$returnhash{"thead"}}= @result_head;
	# data for the results table
	@{$returnhash{"trows"}}= @result;
#	#outro
	$returnhash{"outro"}=$outro;
	return %returnhash;
}

package W3C::LogValidator::CSSValidator;

1;

__END__

=head1 NAME

W3C::LogValidator::CSSValidator - [W3C Log Validator] Batch validation of CSS style sheets (using the W3C CSS validator)

=head1 SYNOPSIS

  use  W3C::LogValidator::CSSValidator;
  my %config = ("verbose" => 2);
  my $validator = W3C::LogValidator::CSSValidator->new(\%config);
  $validator->uris('http://www.w3.org/StyleSheets/home.css', 'http://yoda.zoy.org/mt-static/styles.css');
  my %result= $validator->process_list;

=head1 DESCRIPTION

This module is part of the W3C::LogValidator suite, and is used as an interface to the W3C CSS validation service.

=over 2

=item $val = W3C::LogValidator::CSSValidator->new

Constructs a new C<W3C::LogValidator:CSSValidator> processor.  

You might pass it a configuration hash reference (see L<W3C::LogValidator/config_module> and L<W3C::LogValidator::Config>)

  $validator = W3C::LogValidator::CSSValidator->new(\%config);  

=back

=over 4

=item $val->process_list

Processes a list of sorted URIs through the W3C Markup Validator.

The list can be set C<uris>. If the $val was given a config has when constructed, and if the has has a "tmpfile" key, C<process_list> will try to read this file as a hash of URIs and "hits" (popularity) with L<DB_File>.

Returns a result hash. Keys for this hash are: 


  name (string): the name of the module, i.e "CSSValidator"
  intro (string): introduction to the processing results
  thead (array): headers of the results table
  trows (array of arrays): rows of the results table
  outro (string): conclusion of the processing results


=item $val->trim_uris 

Given a list of URIs of documents to process, returns a subset of this list containing the URIs of documents the module supposedly can handle.
The decision is made based on file extensions (see C<auth_ext>) and content-type (see C<HEAD_check>) 

=item $val->HEAD_check

Checks whether a document with no extension is actually a CSS document through an HTTP HEAD request
returns 1 if the URI is of an expected content-type, 0 otherwise

=item $val->auth_ext

Returns the file extensions (space separated entries in a string) supported by the Module.
Public method accessing $self->{AUTH_EXT}, itself coming from either the AuthorizedExtensions configuration setting, or a default value

=item $val->valid

Sets / Returns whether the document being processed has been found to be valid or not.
If an argument is given, sets the variable, otherwise returns the current variable.

=item $val->valid_err_num

Sets / Returns the number of validation errors for the document being processed.
If an argument is given, sets the variable, otherwise returns the current variable.

=item $val->valid_success

Sets / Returns whether the module was able to process validation of the current document successfully (regardless of valid/invalid result)
If an argument is given, sets the variable, otherwise returns the current variable.

=item $val->valid_head

Sets / Returns all HTTP headers returned by the markup validator when attempting to validate the current document.
If an argument is given, sets the variable, otherwise returns the current variable.

=item $val->new_doc

Resets all validation variables to 'undef'. In effect, prepares the processing module to the handling of a new document.

=back

=head1 BUGS

Public bug-tracking interface at http://www.w3.org/Bugs/Public/





=head1 AUTHOR

Olivier Thereaux <ot@w3.org>

=head1 SEE ALSO

W3C::LogValidator::LogProcessor, perl(1).
Up-to-date complete info at http://www.w3.org/QA/Tools/LogValidator/

=cut
