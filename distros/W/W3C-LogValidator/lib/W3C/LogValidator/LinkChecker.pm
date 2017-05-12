# Copyright (c) 2005 the World Wide Web Consortium :
#       Keio University,
#       European Research Consortium for Informatics and Mathematics 
#       Massachusetts Institute of Technology.
# written by olivier Thereaux <ot@w3.org> for W3C
#
# $Id: LinkChecker.pm,v 1.7 2006/01/18 04:35:35 ot Exp $

package W3C::LogValidator::LinkChecker;
use strict;
use warnings;
use Config;


require Exporter;
our @ISA = qw(Exporter);
our %EXPORT_TAGS = ( 'all' => [ qw() ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw();
our $VERSION = sprintf "%d.%03d",q$Revision: 1.7 $ =~ /(\d+)\.(\d+)/;


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
	bless($self, $class);
        return $self;
}


sub uris
{
	my $self = shift;
	if (@_) { @{$self->{URIs}} = @_ }
	return @{$self->{URIs}};
}


# internal routines
#sub foobar
#{
#	my $self = shift;
#	...
#}


sub path_checklink
{
    my $self = shift;
    my $cl_path;

    my $found = 0;
    if (exists $config{checklink}){
        $cl_path = $config{checklink};
    
        if ( (-e $cl_path) && (-r $cl_path) && (-x $cl_path)) {
            $found = 1;
            return $cl_path; 
    }
    }
    if ($found == 0) {
        foreach ("$Config{scriptdirexp}/checklink", "$Config{binexp}/checklink",
		 '/usr/bin/checklink', '/bin/checklink', '/usr/local/bin/checklink', './checklink'){
             $cl_path = $_;
             print "looking for checklink at: $cl_path..." if ($verbose >1);
             
             if ((-e $cl_path) && (-r $cl_path) && (-x $cl_path)) {
                $found = 1;
                print "found!\n" if ($verbose >1);
                return $cl_path;
            }
            else {
                print "\n" if ($verbose >1);
            }
        }
    }
    if ($found == 0) { die("checklink not found") }
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
	print "Now Using the Link Checker module :\n" if $verbose;
	my $name = ""; 
	if (exists $config{ServerName}) {$name = $config{ServerName}}
	
	my @uris = undef;
	my $uri;
	my $checklink;
   $checklink = $self->path_checklink();

	my %hits;
	# Opening the file with the hits and URIs data
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

	print "\n (This may take a long time if you have many files to validate)\n" if ($verbose eq 1);
	print "\n" if ($verbose > 2); # trying to breathe in the debug volume...

    # require W3C::LinkChecker; # TODO when the link checker is nicely modularized
	my @result;
		my @result_head;

		push @result_head, "Rank";
	push @result_head, "Hits";
	push @result_head, "#Error(s)";
	push @result_head, "Address";
    my $total_census = 0;
    my $invalid_census = 0;
    my $last_invalid_position = 0;
    
    while ( (@uris) and  (($invalid_census < $max_invalid) or (!$max_invalid)) and (($total_census < $max_documents) or (!$max_documents)) )
	{
		$uri = shift (@uris);
#		$self->new_doc();
		my $uri_orig = $uri;
		$total_census++;
		print "	processing #$total_census $uri..." if ($verbose > 1);

        # FIXME at some point we will use the library instead of running the script
        #open(LINK, "$checklink $uri 2>/dev/null |");
	open LINK, "-|" or do {
		require File::Spec;
		open STDERR, "> " . File::Spec->devnull or die $!;
		exec $checklink, $uri;
		die "Can't execute $checklink: $!";
	};
        my $num_errs = 0;
        print "\n" if ($verbose > 2);
        while (<LINK>) {
            my $line = $_;
            
             if (($line =~ /To do: The link is broken/) or ($line =~  /To do: There are broken fragments/) or ($line =~ /To do: The hostname could not be resolved. This link needs to be fixed/)){
                $num_errs += 1;
            print $line if ($verbose > 2);
                 } 
            
        }
            print "          " if ($verbose > 2);

        if ($num_errs > 0) {
        print " $num_errs broken link(s)\n" if ($verbose > 1); 
            my @result_tmp;
            push @result_tmp, $total_census;
            push @result_tmp, $hits{$uri_orig};
            push @result_tmp, $num_errs;
            push @result_tmp, $uri_orig;
	        push @result, [@result_tmp];
            $invalid_census++;
            $last_invalid_position = $total_census;
        }
        else {
            print " OK.\n" if ($verbose > 1); 
        }


    }
    
	print "Done!\n" if $verbose;



	print "invalid_census $invalid_census \n" if ($verbose > 2 );
    my $intro = "Here are the <census> most popular document(s) with broken links \nthat I could find in the logs for $name.";
    my $outro;
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
I had to check $last_invalid_position document(s) in order to find $invalid_census HTML documents with broken links.
This means that about $ratio\% of your most popular documents needs fixing.";
		}
		else
		# we didn't find as many invalid docs as requested
        {
		        if ($max_invalid) {

		 $outro= "Conclusion :
You asked for $max_invalid   document with broken links but I could only find $invalid_census 
by processing (all the) $total_census document(s) in your logs. 
This means that about $ratio\% of your most popular documents needs fixing.";}
        else # max_invalid set to 0, user asked for all invalid docs
   		{ $outro= "Conclusion :
I found $invalid_census documents with broken links
by processing (all the) $total_census document(s) in your logs. 
This means that about $ratio\% of your most popular documents needs fixing.";}     
        }
	}
	elsif (!$total_census)
	{
		$intro="There was nothing to check in this log.";
		$outro="";
	}
	else # everything was actually OK!
	{
		$intro=~s/<census> //;
		$outro="I couldn't find any document with broken links in this log. Congratulations!";
	}
	if (($total_census == $max_documents) and ($total_census)) # we stopped because of max_documents
	{
		$outro=$outro."\nNOTE: I stopped after processing $max_documents documents:\n     Maybe you could set MaxDocuments to a higher value?";
	}

	if (defined ($config{tmpfile}))
        {
		untie %hits;                                                                  
	}
	# Here is what the module will return. The hash will be sent to 
	# the output module

	my %returnhash;
	# the name of the module
	$returnhash{"name"}="Link Checker";                                                  
	#intro
	$returnhash{"intro"}=$intro;
	#Headers for the result table
        @{$returnhash{"thead"}}=@result_head;
	# data for the results table
	@{$returnhash{"trows"}}= @result;
	#outro
	$returnhash{"outro"}=$outro;
	return %returnhash;
}

package W3C::LogValidator::LinkChecker;

1;

__END__

=head1 NAME

W3C::LogValidator::LinkChecker - [W3C Log Validator] finds the most popular documents with broken links in a Web server log.

=head1 DESCRIPTION

This module is part of the W3C::LogValidator suite, and combines the W3C link checker (see L<http://validator.w3.org/checklink>, and L<W3C::LinkChecker>) with a Web server log analysis tool, providing a way to fix documents with broken links little by little while focusing first on the ones that should have priority.


=head1 AUTHOR

olivier Thereaux <ot@w3.org> for W3C


=head1 SEE ALSO

W3C::LogValidator::LogProcessor, perl(1).
Up-to-date complete info at http://www.w3.org/QA/Tools/LogValidator/

=cut
