package t::lib::Test;

# Testing stuff for TinyAuth

use strict;
use vars qw{@ISA @EXPORT};
BEGIN {
	require Exporter;
	@ISA    = qw{ Exporter };
	@EXPORT = qw{ default_config cgi_cmp };
}

use File::Spec::Functions ':ALL';
use File::Copy       ();
use File::Remove     ();
use YAML::Tiny       ();
#use Test::LongString ();

my $prototype_file = rel2abs( catfile( 't', 'data', 'htpasswd'      ) );
my $config_file    = rel2abs( catfile( 't', 'data', 'htpasswd_copy' ) );
END { File::Remove::remove( $config_file ) if -f $config_file; }

sub default_config {
	File::Remove::remove( $config_file ) if -f $config_file;
	File::Copy::copy( $prototype_file => $config_file );
	Test::More::ok( -f $config_file, 'Testing config file exists' );

	my $config = YAML::Tiny->new;
	$config->[0]->{htpasswd}     = $config_file;
	$config->[0]->{email_from}   = 'adamk@cpan.org';
	$config->[0]->{email_driver} = 'Test';
	Test::More::isa_ok( $config, 'YAML::Tiny' );

	return $config;
}






# Test that two HTML files match
sub cgi_cmp {
	my $left  = shift;
	my $right = shift;

	# Clean up the two sides
	$left  =~ s/^\s+//is;
	$left  =~ s/\s+$//is;
	$left  =~ s/(?:\015{1,2}\012|\015|\012)/\n/sg;
	$right =~ s/^\s+//is;
	$right =~ s/\s+$//is;
	$right =~ s/(?:\015{1,2}\012|\015|\012)/\n/sg;

        Test::More::is( $left, $right, $_[0] );
#	Test::LongString::is_string( $left, $right, $_[0] );
}

1;
