# $Id: Poster.pm 14 2006-03-25 20:21:45Z grantg $

package WWW::Myspace::MyBase;

use Spiffy -Base;
use Carp;
use Params::Validate;
use Config::General;
use YAML qw'LoadFile DumpFile';
use warnings;
use strict;

=head1 NAME

WWW::Myspace::MyBase - Base class for WWW::Myspace modules

=head1 VERSION

Version 0.3

=cut

our $VERSION = '0.3';

=head1 SYNOPSIS

This is a base class that can be used for all WWW::Myspace modules.
It provides basic, standardized options parsing in several formats.
It validates data using Params::Validate.

To use this in your new module, you simply subclass this module, add
the "default_options" method to define your data, and write your methods.

 package WWW::Myspace::MyModule;
 use WWW::Myspace::MyBase -Base;

 const default_options => { happiness => 1, # Required
 		count => { default => 50 }, # Not required, defaults to 50
 	};

 field 'happiness';
 field 'count';

 sub mymethod {
 	if ( $self->happiness ) { print "I'm happy" }
 }


 People can then call your method with:
 $object = new WWW::Myspace::MyModule( happiness => 5 );
 
 or
 
 $object = new WWW::Myspace::MyModule( { happiness => 5 } );

See Params::Validate for more info on the format of, and available
parsing stunts available in, default_options.
 
=cut

#
######################################################################
# Setup

######################################################################
# Libraries we use

######################################################################
# new

=head1 METHODS

=head2 default_options

This method returns a hashref of the available options and their default
values.  The format is such that it can be passed to Params::Validate
(and, well it is :).

You MUST override this method to return your default options.
Fortunately we use Spiffy, so you just have
to do this:

 const default_options => {
 		option => { default => value },
 		option => { default => value },
 };
 

=cut

stub 'default_options';

=head2 positional_parameters

If you need to use positional paramteres, define a
"positional_parameters" method that returns a reference to a list of the
parameter names in order, like this:

 const positional_parameters => [ "username", "password" ];

=cut

stub 'positional_parameters';

=head2 new

Initialize and return a new object.
$myspace is a WWW::Myspace object.

 We accept the following formats:

 new - Just creates and returns the new object.
 new( $myspace ) - Where $myspace is a WWW::Myspace object.
 new( $myspace, $options_hashref ) - Myspace object followed by a hashref 
                   of option => value pairs
 new( $options_hashref )
 new( %options );
 new( @options ); - Each option passed is assigned in order to the keys
 					of the "DEFAULT_OPTIONS" hash.
 new( 'config_file' => "/path/to/file", 'config_file_format' => 'YAML' );
 	- File format can be "YAML" (see YAML.pm) or "CFG" (see Config::General).
 	- Defaults to "YAML" if not specified.

If you specify options and a config file, the config file will be read,
and any options you explicitly passed will override the options read from
the config file.

=cut

sub new() {

	# Set up the basic object
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self  = {};

    bless( $self, $class );

	# Unless they passed some options, we're done.
	return $self unless ( @_ );
	
	# Set the options they passed.
	$self->set_options( @_ );

	# Done
	return $self;

}

=head2 set_options

Allows you to set additional options. This is called by the "new" method
to parse, validate, and set options into the object.  You can call it
yourself if you want to, either to set the options, or to change them later.

 # Set up the object
 $object->new( myspace => $myspace );
 
 # Read in a config file later.
 $object->set_options( config_file => $user_config );

This also lets you override options you supply directly with, say, a
user-supplied config file.  Otherwise, the options passed to "new" would
override the config file.

=cut

sub set_options {

	# Figure out the paramter format and return a hash of option=>value pairs
	my %options = $self->parse_options( @_ );

	# Validate the options
	my @options = ();
	foreach my $key ( keys %options ) {
		push ( @options, $key, $options{$key} );
	}

	%options = validate( @options, $self->default_options );

	# Copy them into $self
	foreach my $key ( keys( %options ) ) {
		$self->{"$key"} = $options{"$key"}
	}
	
}

=head2 get_options

General accessor method for all options.
Takes a list of options and returns their values.

If called with one option, returns just the value.
If called with more than one option, returns a list of option => value
pairs (not necessarily in the order of your original list).
If called with no arguments, returns a list of all options and
their values (as option => value pairs).

This is basically a "catch all" accessor method that allows you to be
lazy ad not create accessors for your options.

=cut

sub get_options {

	my ( @options ) = @_;

	# If no options were specified, return them all
	unless ( @options ) {
		@options = keys( %{ $self->default_options } );
	}

	# If there's only one value requested, return just it
	return $self->{$options[0]} if ( @options == 1 );
	
	# Otherwise return a hash of option => value pairs.
	my %ret_options = ();
	
	foreach my $option ( @options ) {
		if ( $self->{ $option } ) {
			$ret_options{ $option } = $self->{ $option };
	    } else {
			croak "Invalid option passed to get_options";
		}
	}
	
	return ( %ret_options );

}

=head2 parse_options

This method is called by set_options to determine the format of the options
passed and return a hash of option=>value pairs.  If needed, you can
call it yourself using the same formats described in "new" above.

 $object->new;
 $object->parse_options( 'username' => $username,
 	'config_file' => "/path/to/file" );

=cut

sub parse_options {

	my %options = ();
	
	# figure out the format
	# - new( $myspace )?
	if ( ( @_ == 1 ) && ( ref $_[0] eq 'WWW::Myspace' ) ) {
		%options = ( 'myspace' => $_[0] );
	# - new( $myspace, $options_hashref )
	} elsif ( ( @_ == 2 ) && ( ref $_[0] eq 'WWW::Myspace') &&
			( ref $_[1] eq 'HASH' ) ) {
		%options = ( 'myspace' => $_[0], %{ $_[1] } );
	# - new( $options_hashref )
	} elsif ( ( @_ == 1 ) && ( ref $_[0] eq 'HASH') ) {
		%options = %{ $_[0] };
	# - new( %options )
	#   If more than 1 argument, and an even number of arguments, and
	#   the first argument is one of our known options.
	} elsif ( ( @_ > 1 ) && ( @_ % 2 == 0 ) &&
		( defined( $self->default_options->{$_[0]} ) ) ) {
		%options = ( @_ );
	# - new( @options )
	#   We just assign them in order.
	} else {
		foreach my $option ( @{ $self->positional_parameters } ) {
			$options{"$option"} = shift;
		}
	}
	
	# If they passed a config file, read it
	if ( exists $options{'config_file'} ) {
		%options = $self->read_config_file( %options );
	}
	
	return %options;

}

=head2 read_config_file

This method is called by parse_options.  If a "config_file" argument is
passed, this method is used to read options from it. Currently supports
CFG and YAML formats.

=cut

sub read_config_file {

	my ( %options ) = @_;
	
	my %config;

	# XXX CFG reads into a hash, YAML reads into a hashref.
	# This is a bit unstable, but YAML's file looks weird if you
	# just dump a hash to it, and hashrefs are better anyway.
	if ( ( defined $options{'config_file_format'} ) &&
		( $options{'config_file_format'} eq "CFG" ) ) {
		# Read CFG-file format
		my $conf = new Config::General( $options{'config_file'} );
		%config = $conf->getall;
	} else {
		# Default to YAML format
		my $config = LoadFile( $options{'config_file'} );
		%config = %{ $config };
	}
	
	# Copy the config file into the options hashref.
	# Existing params override the config file
	foreach my $key ( keys %config ) {
		unless ( exists $options{"$key"} ) {
			$options{"$key"} = $config{"$key"};
		}
	}

	return %options;
		
}


=head2 myspace

Sets/retreives the myspace object with which we're logged in. You
probably don't need to use this as you'll pass it to the new method
instead.

=cut

field 'myspace';

=head2 save( filename )

Saves the object to the file specified by "filename".
Saved every field specified in the default_options method except
the myspace object.

=cut

sub save {

	my $data = {};

	# For each field listed as persistent, store it in the
	# hash of data that's going to be saved.
	foreach my $key ( ( keys( %{ $self->default_options } ),
			@{ $self->positional_parameters } ) ) {
		unless ( $key eq 'myspace' ) {
			# IMPORTANT: Only save what's defined or we'll
			# break defaults.
			if ( exists $self->{$key} ) {
				${$data}{$key} = $self->{$key}
			}
		}
	}

	DumpFile( $data );

}

=head2 load( filename )

Loads a message in YAML format (i.e. as saved by the save method)
from the file specified by filename.

=cut

sub load {

	my ( $file ) = @_;
	my $data = {};
	
	( $data ) = LoadFile( $file );

	# For security we only loop through fields we know are
	# persistent. If there's a stored value for that field, we
	# load it in.
	foreach my $key ( ( keys( %{ $self->default_options } ),
			@{ $self->positional_parameters } ) ) {
		if ( exists ${$data}{$key} ) {
			$self->{$key} = ${$data}{$key}
		}
	}
	
}

=pod

=head1 AUTHOR

Grant Grueninger, C<< <grantg at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-www-myspace at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Myspace>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 NOTES

You currently have to both specify the options in default_options and
create accessor methods for those you want accessor methods for
(i.e. all of them).  This should be made less redundant.

We probably want to include cache_dir and possibile cache_file methods here.

=head1 TO DO

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::Myspace::MyBase

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-Myspace>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-Myspace>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-Myspace>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-Myspace>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2005 Grant Grueninger, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of WWW::Myspace::Comment
