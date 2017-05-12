package Weather::Com::Object;

use 5.006;
use strict;
use warnings;
use Carp;

#--------------------------------------------------------------------
# Define some globals
#--------------------------------------------------------------------
our $VERSION = sprintf "%d.%03d", q$Revision: 1.3 $ =~ /(\d+)/g;
my %LH = ();  # our language handles

#------------------------------------------------------------------------
# Constructor
#------------------------------------------------------------------------
sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self  = {};
	my %parameters;

	# parameters provided by new method
	if ( ref( $_[0] ) eq "HASH" ) {
		%parameters = %{ $_[0] };
	} else {
		%parameters = @_;
	}

	$self = bless( $self, $class );

	# creating the SUPER instance
	$self->{ARGS} = \%parameters;
	if ( $parameters{lang} ) {
		$self->{LANGUAGE} = $parameters{lang};
	} else {
		$self->{LANGUAGE} = 'en_US';
	}

	
	return $self;
}    # end new()

#------------------------------------------------------------------------
# update barometric data
#------------------------------------------------------------------------
sub update {
	my $self = shift;
	return 1;
}

#------------------------------------------------------------------------
# Get a language handle
#------------------------------------------------------------------------
sub get_language_handle {
	my $self = shift;
	my $lang = shift || $self->{LANGUAGE};
	
	# check if we already have an open handle
	unless (defined($LH{$lang})) {
		$LH{$lang} = Weather::Com::L10N->get_handle($lang) 
			or croak ("Language?");
	}
	
	# return language handle
	return $LH{$lang};
}


1;
