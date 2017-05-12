package t::lib::TinyAuth;

# Testing subclass of TinyAuth that captures instead of prints
use strict;
BEGIN {
	local $ENV{TEST_TINYAUTH} = 1;
	my $script = File::Spec->catfile( 'script', 'tinyauth' );
	die("Failed to find $script") unless -f $script;
	require( $script );
}
use base 'TinyAuth';
use YAML::Tiny   ();
use t::lib::Test ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01';
}

sub new {
	my $class  = shift;

	# Load the CGI file if needed
	my %params = (@_ == 1) ? (cgi => [ 't', 'data', shift ]) : @_;
	unless ( defined $params{config} ) {
		$params{config} = t::lib::Test::default_config();
	}
	if ( defined $params{cgi} ) {
		if ( ref $params{cgi} eq 'ARRAY' ) {
			$params{cgi} = File::Spec->catfile( @{$params{cgi}} );
			Test::More::ok( -f $params{cgi}, "CGI file $params{cgi} exists" );
		}
		if ( ! ref $params{cgi} and length $params{cgi} ) {
			open( CGIFILE, $params{cgi} ) or die "open: $!";
			$params{cgi} = CGI->new(\*CGIFILE);
			close( CGIFILE );
			Test::More::isa_ok( $params{cgi}, 'CGI' );
		}
	}

	# Create the object
	my $self = $class->SUPER::new(%params);

	# Self-test
	Test::More::isa_ok( $self, 't::lib::TinyAuth' );
	Test::More::isa_ok( $self, 'TinyAuth'         );

	return $self;
}

sub stdout {
	$_[0]->{stdout} || '';
}

sub print {
	my $self = shift;
	unless ( defined $self->{stdout} ) {
		$self->{stdout} = '';
	}
	$self->{stdout} .= join '', @_;
	return 1;
}

1;
