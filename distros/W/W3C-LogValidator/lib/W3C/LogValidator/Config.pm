# Copyright (c) 2002-2005 the World Wide Web Consortium :
#	Keio University,
#	European Research Consortium for Informatics and Mathematics
#	Massachusetts Institute of Technology.
# written by Olivier Thereaux <ot@w3.org> for W3C
#
# $Id: Config.pm,v 1.13 2008/11/14 15:17:20 ot Exp $

package W3C::LogValidator::Config;
use strict;

require Exporter;
our @ISA = qw(Exporter);
our %EXPORT_TAGS = ( 'all' => [ qw() ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw();
our $VERSION = sprintf "%d.%03d",q$Revision: 1.13 $ =~ /(\d+)\.(\d+)/;

our $config_filename;
our %conf;

###########################
# usual package interface #
###########################
sub new
{
        my $self  = {};
        my $proto = shift;
        my $class = ref($proto) || $proto;
        $self->{NAME}   = undef;
        $self->{SERVERADMIN}    = undef;
        $self->{DOCUMENTROOT}   = undef;
        $self->{LOGFILES}       = undef;
        $self->{LOGFORMAT}      = undef;
        $self->{LOGTYPE}        = undef;
        $self->{MODULES}        = undef;
        $self->{MAX_INVALID}    = undef;
	$self->{DIRECTORYINDEX}	= undef;
        bless($self, $class);
	# default values

	# did we get a config file as an argument?
	if (@_)
	{
		$config_filename = shift;
		$self->config_file;
	}
	else
	{
		$self->config_default;
	}
#	$self->give_config;	# debug
        return $self;
}

sub configure
{
	return %conf;
}

sub config_default
{
	use Sys::Hostname qw(hostname);
	my $self = shift;
	# setting default values for LogProcessor
	if (!exists $conf{LogProcessor}{DirectoryIndex})
	{	
		$conf{LogProcessor}{DirectoryIndex}=("index.html index.htm index");
	}
	if (!exists $conf{LogProcessor}{MaxInvalid})
	{
		$conf{LogProcessor}{MaxInvalid}=10;
	}
	if (!exists $conf{LogProcessor}{ServerName})
	{
		$conf{LogProcessor}{ServerName}=hostname();
	}
	if (!exists $conf{LogProcessor}{DocumentRoot})
	{
		$conf{LogProcessor}{DocumentRoot}="/var/www/";
	}
	if (!exists $conf{LogProcessor}{LogFiles})
	{	
		push @{$conf{LogProcessor}{LogFiles}}, "/var/log/apache/access.log";
		$conf{LogProcessor}{LogType}{"/var/log/apache/access.log"}="common";
	}
	if (!exists $conf{LogProcessor}{RefererMatch})
	{	
		$conf{LogProcessor}{RefererMatch} =".*";
	}

	if (!exists $conf{LogProcessor}{UseValidationModule})
	{
		#adding modules and options for the modules
		push @{$conf{LogProcessor}{UseValidationModule}}, "W3C::LogValidator::HTMLValidator";
		push @{$conf{LogProcessor}{UseValidationModule}}, "W3C::LogValidator::Basic";
		$conf{"W3C::LogValidator::HTMLValidator"}{max_invalid}=10;
	}
	# adding default limit  - useful for very (too) big logfiles
	if (!exists $conf{LogProcessor}{EntriesPerLogfile})
	{
		$conf{LogProcessor}{EntriesPerLogfile}=100000; 
	}
	# adding default handling of URIs with query strings
	if (!exists $conf{LogProcessor}{ExcludeCGI})
	{
		$conf{LogProcessor}{ExcludeCGI}=1; 
	}	
	# parameter muting the final report if nothing interesting to say
	if (!exists $conf{LogProcessor}{QuietIfNoReport})
	{
		$conf{LogProcessor}{QuietIfNoReport}=0; # not muted by default
	}
}



sub config_file
{
	my $self = shift;
	use Config::General;
	my $config_read = new Config::General(-ConfigFile => "$config_filename")
	|| die "could not load config $config_filename : $!";
	# using C::General to read logfile
	my %tmpconf = $config_read->getall;
	# extracting modules config
	# Config::General will give the hash this structure

	# HASH {
	# foo -> valfoo
	# bar -> valbar
	# Module {
	#	module1 {
	#			ga -> valga
	#		}
	#	}
	# }

	# 	and we want 

	
	# HASH {
	# LogProcessor {
	#	foo -> valfoo
	#	bar -> valbar
	#	}
	# module1 {
	#	ga -> valga
	#	}
	# }

	
	# so First we extract what's in the Module subhash
	if (exists($tmpconf{Module}))
	{
		%conf = %{$tmpconf{Module}};
	}
	# remove it
	delete $tmpconf{Module};
	# and merging with the global values we put in the LogProcessor subhash
	%{$conf{LogProcessor}} = %tmpconf;

	# specific action is needed for "CustomLog"
	if (exists($tmpconf{CustomLog}))
	{
		# if there are several log files, $tmpconf{CustomLog} is an array
    if (ref($tmpconf{CustomLog}) eq 'ARRAY')
		{ 
		   foreach my $customlog (@{ $tmpconf{CustomLog} })
		   {
			$_ = $customlog;
			if (/^(.*) (.*)$/) 
			{
				# only supported (so far) is the syntax:
				# CustomLog path/file nickname
				push @{$conf{LogProcessor}{LogFiles}}, $1;
				$conf{LogProcessor}{LogType}{$1}=$2;
			}
		   }

		}
		else # one log file, $tmpconf{CustomLog} is not an array
		{ 
			$_ = $tmpconf{CustomLog};
			if (/^(.*) (.*)$/) 
			{
				push @{$conf{LogProcessor}{LogFiles}}, $1;
				$conf{LogProcessor}{LogType}{$1}=$2;			
			}
		}
		delete $conf{LogProcessor}{CustomLog};
	}
	
	# add default values for variables not included in the config file
	$self->config_default();	
}

package W3C::LogValidator::Config;
1;

__END__

=head1 NAME

W3C::LogValidator::Config - [W3C Log Validator] Configuration parser

=head1 SYNOPSIS

    use W3C::LogValidator::Config;
    if ($config_filename)
    { # parse configuration file and populate config hash
        %config = W3C::LogValidator::Config->new($config_filename)->configure();
    }
    else
    { # populate config hash with "default" values
        %config = W3C::LogValidator::Config->new()->configure();
    }

=head1 DESCRIPTION

C<W3C::LogValidator::Config> parses configuration files or directives for the Log Validator


=head1 API

=head2 Constructor

=over 2

=item $c = W3C::LogValidator::Config->new

Constructs a new C<W3C::LogValidator::Config> configuration processor.
A file name may be passed as a variable, as follows:

  $c = W3C::LogValidator::Config->new("path/to/file.conf")

=back

=head2 General methods

=over 4

=item $c->configure

Returns a hash containing configuration variables for the main module and for each processing module.

Hash structure as follows:
$conf{LogProcessor} is a hash containing configuration info for the main Log Validator process
e.g : 

    $conf{LogProcessor}{MaxInvalid} is an int with the general setting for MaxInvalid, 
    $conf{LogProcessor}{UseValidationModule} is an array with all processing modules used

for each processing module, $conf{ProcessingModuleX} is a hash containing configuration info specific to that processing module.
Typically this is used to override general setting.

=item $c->config_default

Populates the configuration hash (which will then be returned by C<$c-E<gt>configure>) with reasonable default values

=item $c->config_file

Populates the configuration hash by parsing the configuration file given while constructing C<W3C::LogValidator::Config>
Does not work if that parameter was not passed during construction

The configuration file uses a syntax very similar to the one used by the Apache Web server.
Both syntax and vocabulary are documented in the sample configuration file (F<samples/logprocess.conf>) 
distributed with the module.

=back

=head1 BUGS

Public bug-tracking interface at http://www.w3.org/Bugs/Public/

=head1 AUTHOR

Olivier Thereaux <ot@w3.org> for The World Wide Web Consortium


=head1 SEE ALSO

perl(1).
Up-to-date information on this tool at http://www.w3.org/QA/Tools/LogValidator/

=cut

