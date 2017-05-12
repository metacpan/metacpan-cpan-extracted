# Copyright (c) YYYY the World Wide Web Consortium :
#       Keio University,
#       European Research Consortium for Informatics and Mathematics 
#       Massachusetts Institute of Technology.
# written by Firstname Lastname <your@email.address> for W3C
#
# $Id: NewModule.pm,v 1.11 2004/09/10 00:41:24 ot Exp $

package W3C::LogValidator::Changeme;
use strict;
use warnings;


require Exporter;
our @ISA = qw(Exporter);
our %EXPORT_TAGS = ( 'all' => [ qw() ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw();
our $VERSION = sprintf "%d.%03d",q$Revision: 1.11 $ =~ /(\d+)\.(\d+)/;


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


#########################################
# Actual subroutine to check the list of uris #
#########################################


sub process_list
{
	my $self = shift;
	my $max_invalid = undef;
	if (exists $config{MaxInvalid}) {$max_invalid = $config{MaxInvalid}
	print "Now Using the CHANGEME module :\n" if $verbose;

	my @uris = undef;
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


	# do what pleases you!
	print "Done!\n" if $verbose;


	if (defined ($config{tmpfile}))
        {
		untie %hits;                                                                  
	}
	# Here is what the module will return. The hash will be sent to 
	# the output module

	my %returnhash;
	# the name of the module
	$returnhash{"name"}="CHANGEME";                                                  
	#intro
	$returnhash{"intro"}="An intro string for the module's results";
	#Headers for the result table
	@{$returnhash{"thead"}}=["Header1", "Header2", "..."] ;
	# data for the results table
	@{$returnhash{"trows"}}=
	[
	 ["data1", "data2", "..."]
	 ["etc", "etc", "etc"]
	 ["etc", "etc", "etc"]
	 ["etc", "etc", "etc"]
	];
	#outro
	$returnhash{"outro"}="An outre string for the module's results. Usually the conclusion";
	return %returnhash;
}

package W3C::LogValidator::CHANGEME;

1;

__END__

=head1 NAME

W3C::LogValidator::NewModule - New processing module Template for the Log Validator

=head1 DESCRIPTION

Note: please change this description when using this module code and documentation as a template.

This module is a template for the creation of a new processing module for the W3C Log Validator


=head1 API

=head2 Constructor

=over 2

=item $proc = W3C::LogValidator::NewModule->new

Constructs a new C<W3C::LogValidator:NewModule> processor.  

You might pass it a configuration hash reference (see L<W3C::LogValidator/config_module> and L<W3C::LogValidator::Config>)

  $proc = W3C::LogValidator::NewModule->new(\%config);  

=back

=head2 Main processing method

=over 4

=item $proc->process_list

Processes a list of sorted URIs (through whatever you want your module to be useful for)

The list can be set C<uris>. If the $val was given a config has when constructed, and if the has has a "tmpfile" key, 
C<process_list> will try to read this file as a hash of URIs and "hits" (popularity) with L<DB_File>.

Returns a result hash. Keys for this hash are: 

  name (string): the name of the module
  intro (string): introduction to the processing results
  thead (array): headers of the results table
  trows (array of arrays): rows of the results table
  outro (string): conclusion of the processing results

=back

=head2 General methods

=over 4

=item $proc->uris

Returns a  list of URIs to be processed (unless the configuration gives the location for the hash of URI/hits berkeley file, see C<process_list> 
If an array is given as a parameter, also sets the list of URIs and returns it.


=back

Note: please document other methods here. 

See also L<W3c::LogValidator::HTMLValidator> for a few other interesting methods you could copy.


=head1 AUTHOR

Template created by olivier Thereaux <ot@w3.org> for W3C

Module created by You <your@address>

=head1 SEE ALSO

W3C::LogValidator::LogProcessor, perl(1).
Up-to-date complete info at http://www.w3.org/QA/Tools/LogValidator/

=cut
