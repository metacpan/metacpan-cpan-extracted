# Copyright (c) 2002-2005 the World Wide Web Consortium :
#       Keio University,
#       European Research Consortium for Informatics and Mathematics
#       Massachusetts Institute of Technology.
# written by Olivier Thereaux <ot@w3.org> for W3C
#
# $Id: LogValidator.pm,v 1.25 2008/11/18 16:49:57 ot Exp $

package W3C::LogValidator;
use strict;
no strict "refs";
require Exporter;
our @ISA = qw(Exporter);
our %EXPORT_TAGS = ( 'all' => [ qw() ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw();
our $VERSION = sprintf "%d.%03d",q$Revision: 1.25 $ =~ /(\d+)\.(\d+)/;

our %config;
our $output="";
our $config_filename = undef;
our $verbose;
our %cmdline_conf;
our %hits; # hash URI->hits
our %referers;
our %mimetypes;
our %HTTPcodes;
our $output_proc;

###########################
# usual package interface #
###########################
sub new
{
	my $self  = {};
        my $proto = shift;
        my $class = ref($proto) || $proto;

	# server config is imported from the config module
        use W3C::LogValidator::Config;
	if (@_)
	{
		$config_filename = shift;
#		print "using config filename  $config_filename \n"; #debug
		if ($config_filename)
		{
	        	%config = W3C::LogValidator::Config->new($config_filename)->configure();
		}
		else
		{
			%config = W3C::LogValidator::Config->new()->configure();
		}
	}
	else
	{ %config = W3C::LogValidator::Config->new()->configure(); }

	# processing other options given at the command line
	if (@_)
	{
	%cmdline_conf= %{(shift)};
	}
	# verbosity : overriding config if given at command line
	if (defined($cmdline_conf{verbose}))
	{
		($config{LogProcessor}{verbose}) = $cmdline_conf{verbose};
		$verbose = $cmdline_conf{verbose};
	}
	# setting default verbosity if not given
	elsif (! defined($config{LogProcessor}{verbose}) )
	{
		($config{LogProcessor}{verbose}) = 1;
		$verbose = 1;
	}
	# output : overriding config if given at command line
	if ( defined($cmdline_conf{"UseOutputModule"}) )
	{
		$config{LogProcessor}{UseOutputModule} = $cmdline_conf{UseOutputModule};
	}
	elsif (! defined($config{LogProcessor}{UseOutputModule}))
	{
		$config{LogProcessor}{UseOutputModule} = "W3C::LogValidator::Output::Raw";
	}
	
	# output to file 
	# no "default value, will output to console if not set!
	if ( defined($cmdline_conf{"OutputTo"} ) )
	{
		$config{LogProcessor}{OutputTo} = $cmdline_conf{"OutputTo"};
	}

	# same for e-mail address to send to 
	# overrding conf file info with cmdline info
	if ( defined($cmdline_conf{"ServerAdmin"}) )	
	{
		$config{LogProcessor}{"ServerAdmin"} = $cmdline_conf{"ServerAdmin"};
	}

	use File::Temp qw/ /;
	my $tmpdir = File::Spec->tmpdir;
	$config{LogProcessor}{tmpfile} = File::Temp::tempnam( $tmpdir, "LogValidator-" );
	$config{LogProcessor}{tmpfile_HTTP_codes} = File::Temp::tempnam( $tmpdir, "LogValidator-" );
	$config{LogProcessor}{tmpfile_mime_types} = File::Temp::tempnam( $tmpdir, "LogValidator-" );
	$config{LogProcessor}{tmpfile_referers} = File::Temp::tempnam( $tmpdir, "LogValidator-" );
	bless($self, $class);
	return $self;
}


sub sorted_uris
{
	my $self = shift;
	print "sorting logs: " if $verbose; # non-quiet mode
	my @uris = sort { $hits{$b} <=> $hits{$a} }
		keys %hits;

	my $theuri;
	my  $theuri_hit;
	my @theuriarry;
	@theuriarry = @uris;
	while ( (@theuriarry) and ($verbose > 1))
	{
		$theuri = shift (@theuriarry);
		$theuri_hit = $hits{$theuri};
		print "	$theuri $theuri_hit\n";
	}


	print "Done!\n" if $verbose; # non-quiet mode
	return @uris;
}

###################
# Server routines #
###################

sub add_uri
# usage $self->add_uri('http://foobar')
{
	my $self = shift;
	if (@_)
	{
		my $uri = shift;
		next unless defined($uri);
		if ( exists($hits{$uri}) )
		{
			$hits{$uri} = $hits{$uri}+1;
		}
		else
		{ $hits{$uri} = 1 }
	}
}

sub add_referer
# usage $self->add_referer($uri, $referer)
{
	my $self = shift;
	if (@_)
	{
	    my $uri = shift;
	    my $referer = shift;
	    $referer =~ s/^"(.*)"$/$1/;
	    my $preferedref = $config{LogProcessor}{RefererMatch};
	    if (($referer ne "-") and ( $referer =~ /$preferedref/))
	    {
	   
	        if (exists $referers{"$uri : $referer"})
	        # nth time this referer is mentioned for $uri, incrementing
	        {
		    $referers{"$uri : $referer"} += 1;
	        }
	        else
	        # first time this referer is mentioned for $uri
	        {
		    $referers{"$uri : $referer"} = 1;
	        }
	    }
	}
}

sub add_mime_type
# record the mime type known for a given logged resource
# usage $self->add_mime_type('http://foobar', "text/html")
{
	my $self = shift;
	if (@_)
	{
		my $uri = shift;
		my $mime_type = shift;
		next unless defined($uri);
		if (! exists($mimetypes{$uri}) )
		{ $mimetypes{$uri} = $mime_type; }
	}
}

sub add_HTTP_code
# record the returned HTTP Code for a given logged resource
# usage $self->add_HTTP_code('http://foobar', "200")
# NOTE: doesn't cover if that code changes throughout the log file - TODO fix that?
{
	my $self = shift;
	if (@_)
	{
		my $uri = shift;
		my $HTTP_code = shift;
		next unless defined($uri);
		if (! exists($HTTPcodes{$uri}) )
		{ 
		    $HTTPcodes{$uri} = $HTTP_code; 
		}
	}
}

sub read_logfiles
# just looping
{
	my $self = shift;
	my $current_logfile;
	use DB_File;
	my $tmp_file = $config{LogProcessor}{tmpfile};
	tie (%hits, 'DB_File', "$tmp_file") ||
	die ("Cannot create or open $tmp_file");

	# TODO this should probably be triggered (on or off) by an option rather than always on
	
	my $tmp_file_referers = $config{LogProcessor}{tmpfile_referers};
	tie (%referers, 'DB_File', "$tmp_file_referers") ||
	die ("Cannot create or open $tmp_file_referers");
	
	my $tmp_file_mime_types = $config{LogProcessor}{tmpfile_mime_types};
	tie (%mimetypes, 'DB_File', "$tmp_file_mime_types") ||
	die ("Cannot create or open $tmp_file_mime_types");
	
	my $tmp_file_HTTP_codes = $config{LogProcessor}{tmpfile_HTTP_codes};
	tie (%HTTPcodes, 'DB_File', "$tmp_file_HTTP_codes") ||
	die ("Cannot create or open $tmp_file_HTTP_codes");
	
	print "Reading logfiles: " if ($verbose); #non-quiet mode
	print "\n" if ($verbose >1); # verbose or above, we'll have details so linebreak
	my @logfiles = @{$config{LogProcessor}{LogFiles}};
	foreach $current_logfile (@logfiles)
	{
		$self->read_logfile($current_logfile);
	}

	untie %hits;
	untie %HTTPcodes;
	untie %mimetypes;
	untie %referers;

	print "Done! \n" if ($verbose); #non-quiet mode

}



sub read_logfile
#read logfile, push uris  one by one with the appropriate sub
{
	my $self = shift;
	my $tmp_record;
	my $entriesperlogfile = $config{LogProcessor}{EntriesPerLogfile};
	my $allskiphosts = ($config{LogProcessor}{ExcludeHosts}) ? $config{LogProcessor}{ExcludeHosts} : ""; # default to none
	my @skiphostsregex = split(" ", $allskiphosts);
	my $entriescounter=0;
	my $skip_thishost = 0;
	if (@_)
	{
		my $logfile = shift;
		if (open (LOGFILE, "$logfile")) {
			print "	$logfile...\n" if ($verbose > 1); # verbose or above
			$entriescounter=0;
			while ( (($entriescounter < $entriesperlogfile ) or (!$entriesperlogfile)) # limit number of entries
			and ($tmp_record = <LOGFILE>)) 
			      
	 		{
				$tmp_record =~ chomp;
				my $logtype = $config{LogProcessor}{LogType}{$logfile};
				if ($tmp_record) # not a blank line
				{
					my $tmp_record_remote_addr = $self->find_remote_addr($tmp_record, $logtype);
					if ($tmp_record_remote_addr) # not a blank remote host or address
					{
					        $skip_thishost = 0;
						foreach my $skipexpression (@skiphostsregex)
						{
						     if( $tmp_record_remote_addr =~ /$skipexpression/ )
						     {
							print " Skipping " . $tmp_record_remote_addr . " because it matches the ExcludeHosts pattern " . $skipexpression. "\n" if ($verbose > 2);
							$skip_thishost = 1;
						     }
						}
					}

					my $tmp_record_uri = $self->find_uri($tmp_record, $logtype);
					my $tmp_record_HTTP_method = $self->find_HTTP_Method($tmp_record, $logtype);
					my $tmp_record_mime_type = $self->find_mime_type($tmp_record, $logtype);
					my $tmp_record_HTTP_code = $self->find_HTTP_code($tmp_record, $logtype);
					my $tmp_record_referer = $self->find_referer($tmp_record, $logtype);
					if (
					  ($skip_thishost == 0) 
					and
					  ($tmp_record_HTTP_method eq "GET") 
					and 
					  ($self->no_cgi($tmp_record) or ($config{LogProcessor}{ExcludeCGI} eq 0))
					) {
						$self->add_uri($tmp_record_uri);
						$self->add_mime_type($tmp_record_uri, $tmp_record_mime_type);
						$self->add_HTTP_code($tmp_record_uri,$tmp_record_HTTP_code);
						$self->add_referer($tmp_record_uri,$tmp_record_referer);
					}
				}
				$entriescounter++;
			}
			print "	  added $entriescounter URIs.\n" if ($verbose > 2);
			close LOGFILE;
		} elsif ($logfile) {
			die "could not open log file $logfile : $!";
		}
	}
}

sub no_cgi
{
	my $self = shift;
	if (@_)
	{
		my $tmp_uri = shift;
		if (defined $tmp_uri) {
		return (!($tmp_uri =~ /\?/))
		}
	}
}


sub find_uri
# finds the "real" URI from a log record
{
	my $self = shift;
	if (@_)
	{
		my $tmprecord = shift;
		my @record_arry;
		@record_arry = split(" ", $tmprecord);
		# hardcoded to most apache log formats, included common and combined
		# for the moment... TODO
		my $logtype = shift;
		# print "log type $logtype" if ($verbose > 2);
		if ($logtype eq "plain")
		{
			$tmprecord = $record_arry[0];
			$tmprecord = $self->remove_duplicates($tmprecord);
		}
		else #common combined or full or w3c
		{
			$tmprecord = $record_arry[6];
			$tmprecord = $self->remove_duplicates($tmprecord);
			if( !( $tmprecord =~ m/^https?\:/ ) ) {
				$tmprecord = join ("",'http://',$config{LogProcessor}{ServerName},$tmprecord);
sub find_remote_addr
# finds the returned HTTP code from a log record, if available
{
        my $self = shift;
        if (@_)
        {
                my $tmprecord = shift;
                my @record_arry;
                @record_arry = split(" ", $tmprecord);
                # hardcoded to most apache log formats, included common and combined
                # for the moment... TODO
                my $logtype = shift;
                # print "log type $logtype" if ($verbose > 2);
                if ($logtype eq "plain")
                {
                        $tmprecord = "";
                }
                else #common combined full or w3c
                {
                        $tmprecord = $record_arry[0];
                }
        #print "Remote Addr $tmprecord \n" if (($verbose > 2) and ($tmprecord ne ""));
        return $tmprecord;
        }
}

			}
		}
	#print "$tmprecord \n" if ($verbose > 2);
	return $tmprecord;
	}
}

sub find_HTTP_Method
# finds the returned HTTP Method from a log record, if available
{
	my $self = shift;
	if (@_)
	{
		my $tmprecord = shift;
		my @record_arry;
		@record_arry = split(" ", $tmprecord);
		# hardcoded to most apache log formats, included common and combined
		# for the moment... TODO
		my $logtype = shift;
		# print "log type $logtype" if ($verbose > 2);
		if ($logtype eq "plain") 
		{
		  # we consider each of those GETs
			$tmprecord = "GET";
		}
		else #common combined full or w3c
		{
			$tmprecord = $record_arry[5];
			$tmprecord =~ s/^"//;
		}
	#print "HTTP Code $tmprecord \n" if (($verbose > 2) and ($tmprecord ne ""));
	return $tmprecord;
	}
}


sub find_HTTP_code
# finds the returned HTTP code from a log record, if available
{
	my $self = shift;
	if (@_)
	{
		my $tmprecord = shift;
		my @record_arry;
		@record_arry = split(" ", $tmprecord);
		# hardcoded to most apache log formats, included common and combined
		# for the moment... TODO
		my $logtype = shift;
		# print "log type $logtype" if ($verbose > 2);
		if ($logtype eq "plain") 
		{
			$tmprecord = "";
		}
		else #common combined full or w3c
		{
			$tmprecord = $record_arry[8];
		}
	#print "HTTP Code $tmprecord \n" if (($verbose > 2) and ($tmprecord ne ""));
	return $tmprecord;
	}
}

sub find_referer
# finds the referrer info from a log record, if available
{
	my $self = shift;
	if (@_)
	{
		my $tmprecord = shift;
		my @record_arry;
		@record_arry = split(" ", $tmprecord);
		# hardcoded to most apache log formats, included common and combined
		# for the moment... TODO
		my $logtype = shift;
		# print "log type $logtype" if ($verbose > 2);
		if ( ($logtype eq "plain") or ($logtype eq "common"))
		{
			$tmprecord = "";
		}
		else #combined or full or w3c
		{
			$tmprecord = $record_arry[10];
		}
	#print "referrer $tmprecord \n" if (($verbose > 2) and ($tmprecord ne ""));
	return $tmprecord;
	}
}

sub find_mime_type 
# only for W3c extended log format - find the mime type for the resource
{
	my $self = shift;
	if (@_)
	{
		my $tmprecord = shift;
		my @record_arry;
		@record_arry = split(' ', $tmprecord);
		# hardcoded to most apache log formats, included common and combined
		# for the moment... TODO
		my $logtype = shift;
		# print "log type $logtype" if ($verbose > 2);
		if ($logtype eq "w3c") 
		{
			
			$tmprecord = pop @record_arry;
		}
		else # all other formats
		{
			$tmprecord = "";
		}
	#print "mime type $tmprecord \n" if (($verbose > 2) and ($tmprecord ne ""));
	return $tmprecord;
	}
}



sub remove_duplicates
# removes "directory index" suffixes such as index.html, etc
# so that http://foobar/ and http://foobar/index.html be counted as one resource
# also removes URI fragments
{
	my $self = shift;
	my $tmprecord;
	if (@_) { $tmprecord = shift;}
	
	# remove frags
	$tmprecord =~ s/\#.*$// if ($tmprecord);

	# remove indexes
	my $index_file;
	foreach $index_file (split (" ",$config{LogProcessor}{DirectoryIndex}))
	{
		$tmprecord =~ s/$index_file$// if ($tmprecord);
	}
	return $tmprecord;
}


sub hit
{
	my $self = shift;
	my $uri=undef;
	if (@_) {$uri=shift}
	return $hits{$uri};
}

sub config_module
{
	my $self = shift;
	my $module_used; #= undef;
	if (@_)
	{ 	
		$module_used = shift;
	}
	my %tmpconfig = %{$config{LogProcessor}};
	#add module specific variables, override if necessary.
	if ( ($module_used) and (defined ($config{$module_used})))
	{	
		foreach my $modkey (keys %{$config{$module_used}})
		{
			if ( $config{$module_used}{$modkey} ) 
			{
				$tmpconfig{$modkey} = $config{$module_used}{$modkey}
			}
		}
	}
	return %tmpconfig;
}
	

sub use_modules
{
	my $self = shift;
	my @modules;
	# the value of the hash may be an array or a single value, 
	# we have to check this
	if (defined @{ $config{LogProcessor}{UseValidationModule} }) 
	{
		@modules = @{$config{LogProcessor}{UseValidationModule}} 	
	} 
	else # single entry that we push in an array
	{
		push @modules, $config{LogProcessor}{UseValidationModule};
	}
	foreach my $module_to_use (@modules)
	{	
		my $output_tmp = "";
		eval "use $module_to_use";
		my $process_module;
		my %mod_config=$self->config_module($module_to_use);
		$process_module = $module_to_use->new(\%mod_config);
	#	$process_module->uris($self->sorted_uris); # not used anymore
		my %results = $process_module->process_list;
		my $shut_up = 0;
		if ( exists $config{LogProcessor}{QuietIfNoReport} )
		{
			$shut_up = $config{LogProcessor}{QuietIfNoReport};
		}
		# We're applying the output module and getting its (potential) output 
		if ($shut_up and int(@{$results{"trows"}}) == 0)
		{
			print "nothing interesting to report - skipping\n" if ($verbose >1)
		}
		else {
			$output_tmp = $output_proc->output(\%results);
			$output = $output.$output_tmp;
		}
		# TODO maybe make this a hash, one output string per output module used
		# that would allow us to have several output modules at the time... 
		# is this very useful?
	}
}


sub process
# this is the main routine
# processes the logfile, sorts the uris, and uses the chosen modules
{
	my $self = shift;
	if ($verbose > 2) #debug
	{
		print "showing general config : \n";
		foreach my $key ( keys %config)
		{
			my %modname = %{$config{$key}};
			print "Module	$key\n";
			foreach my $modkey (keys %{$config{$key}})
			{
				my $value = $config{$key}{$modkey};
				print " $modkey $value\n";
			}
		}
		print "End of config\n\n"
	}
	

	$self->read_logfiles;
	my $outputmodule = $config{LogProcessor}{UseOutputModule};
	eval "use $outputmodule";
	$output_proc = $outputmodule->new(\%{$config{LogProcessor}});
	$self->use_modules;
	$output_proc->finish($output);
	
}

package W3C::LogValidator;
1;

__END__

=head1 NAME

W3C::LogValidator - The W3C Log Validator - Quality-focused Web Server log processing engine 

Checks quality/validity of most popular content on a Web server

=head1 DESCRIPTION

C<W3C::LogValidator> is the main module for the W3C Log Validator, a combination of Web Server log analysis and statistics tool and Web Content quality checker.

The C<W3C::LogValidator> can batch-process a number of documents through a number of quality focus checks, such as HTML or CSS validation, or checking for broken links. It can take a number of different inputs, ranging from a simple list of URIs to log files from various Web servers. And since it orders the result depending on the number of times a document appears in the file or logs, it is, in practice, a useful way to spot the most popular documents that need work.

the perl script logprocess.pl, bundled in the W3C::LogValidator distribution, is a simple way to use the features of C<W3C::LogValidator>. Developers can also use C<W3C::LogValidator> can be used as a perl module to build applications.

The homepage for the Log Validator is at: http://www.w3.org/QA/Tools/LogValidator/

=head1 SYNOPSIS

The simple way to use is to edit the sample configuration file (samples/logprocess.conf) and to run the bundled logprocess.pl script with this configuration file, a la:

    logprocess.pl -f /path/to/logprocess.conf

The basic task of the C<W3C::LogValidator> module is to parse a configuration file and process relevant logs, passed through a configuration file argument: 

    use W3C::LogValidator;
    my $logprocessor = W3C::LogValidator->new("sample.conf");
    $logprocessor->process;

Alternatively, it will use default a default config and try to process Web server logs in "well known locations":

    my $logprocessor = W3C::LogValidator->new;
    $logprocessor->process;

=head1 API

=head2 Constructor

=over 2 

=item $processor = W3C::LogValidator->new

Constructs a new C<W3C::LogValidator> processor.  You might pass a configuration file name, 
as well as a hash of attribute-value pairs as parameters to the constructor.  


I<e.g.> for mail output:

  %conf = (
    "UseOutputModule" => "W3C::LogValidator::Output::Mail",
    "ServerAdmin" => 'webmaster@example.com',
    "verbose" => "3"
    );
  $processor = W3C::LogValidator->new("path/to/config.conf", \%conf);

Or I<e.g.> for HTML output:

  %conf = (
    "UseOutputModule" => "W3C::LogValidator::Output::HTML",
    "OutputTo" => 'path/to/file.html',
    "verbose" => "0"
    );
  $processor = W3C::LogValidator->new("path/to/config.conf", \%conf);

If given the path to a configuration file, C<new()> will call the L<W3C::LogValidator::Config> module to get its configuration variables. 
Otherwise, a default set of values is used.

=back

=head2 Main processing method

=over 4

=item $processor->process
=item $processor->find_remote_addr

Given a log record and the type of the log (common log format, flat list of URIs, etc), extracts the remote host or ip


Do-it-all method:
Read configuration file (if any), parse log files, run them through processing modules, send result to output module.

=back

=head2 Modules methods

=over 4

=item $processor->config_module

Creates a configuration hash for a specific module, adding module-specific configuration variables, overriding if necessary

=item $processor->use_modules

Run the data parsed off the log files through the various processing (validation) modules specified by UseValidationModule in the configuration.

=back

=head2 Log parsing and URI methods

=over 4 

=item $processor->read_logfiles

Loops through and parses all log files specified in the configuration

=item $processor->read_logfile('path/to.file')

Extracts URIs and number of hits from a given log file, and feeds it to the processor's URI/Hits table

=item $processor->find_uri

Given a log record and the type of the log (common log format, flat list of URIs, etc), extracts the URI

=item $processor->remove_duplicates

Given a URI, removes "directory index" suffixes such as index.html, etc so that http://foobar/ and http://foobar/index.html be counted as one resource

=item $processor->add_uri

Add a URI to the processor's URI/Hits table

=item $processor->sorted_uris

Returns the list of URIs in the processor's table, sorted by popularity (hits)

=item $processor->no_cgi

Tests whether a given URI contains a CGI query string

=item $processor->hit

Returns the number of hits for a given URI. 
Basically a "public" method accessing $hits{$uri};

=back

=head1 BUGS

Public bug-tracking interface at http://www.w3.org/Bugs/Public/

=head1 AUTHOR

Olivier Thereaux <ot@w3.org> for The World Wide Web Consortium

=head1 SEE ALSO

Up-to-date information on the Log Validator at: 

 http://www.w3.org/QA/Tools/LogValidator/

=head2 Articles and Tutorials

Several articles have been written within the W3C Quality Assurance Interest Group on the topic of improving the quality of Web sites, notably by using a step-by-step approach and relying upon the Log Validator to help find the areas to fix in priority.

=over 2

=item My Web site is standard! And yours?

Available at http://www.w3.org/QA/2002/04/Web-Quality

=item Web Standards Switch

or I<how to improve your Web site easily>. 

Available in several languages at: http://www.w3.org/QA/2003/03/web-kit

=item Making your website valid: a step by step guide.

Available at http://www.w3.org/QA/2002/09/Step-by-step

=back

=cut

