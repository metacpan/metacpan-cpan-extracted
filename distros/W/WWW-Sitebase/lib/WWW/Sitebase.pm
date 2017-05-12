package WWW::Sitebase;

use Spiffy -Base;
use Carp;
use Params::Validate;
use Config::General;
use YAML qw'LoadFile DumpFile';

=head1 NAME

WWW::Sitebase - Base class for Perl modules

=head1 VERSION

Version 0.15

=cut

our $VERSION = '0.15';

=head1 SYNOPSIS

This is a base class that can be used for all Perl modules.
I could probably call it "Base" or somesuch, but that's a bit
too presumptious for my taste, so I just included it here.
You'll probably just use WWW::Sitebase::Navigator or WWW::Sitebase::Poster
instead, which subclass WWW::Sitebase.
WWW::Sitebase provides basic, standardized options parsing
in several formats. It validates data using Params::Validate, provides clean
OO programming using Spiffy, and reads config files using Config::General.
It gives your module a powerful "new" method that automatically
takes any fields your module supports as arguments or reads them from a
config file.  It also provides your module with "save" and "load" methods.


To use this to write your new module, you simply subclass this module, add
the "default_options" method to define your data, and write your methods.

 package WWW::MySite::MyModule;
 use WWW::Sitebase -Base;

 const default_options => {
 		happiness => 1, # Required
 		count => { default => 50 }, # Not required, defaults to 50
 	};

 field 'happiness';
 field 'count';

 sub mymethod {
 	if ( $self->happiness ) { print "I'm happy" }
 }


 People can then call your method with:
 $object = new WWW::MySite::MyModule( happiness => 5 );
 
 or
 
 $object = new WWW::MySite::MyModule( { happiness => 5 } );
 
 They can save their object to disk:
 $object->save( $filename );
 
 And read it back:
 $object = new WWW::MySite::MyModule();
 $object->load( $filename );
 
 or since "save" writes a YAML file:
 $object = new WWW::MySite::MyModule(
    'config_file' => $filename, 'config_file_format' => 'YAML' );

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
Basically, you just have to do this:

 sub default_options {
 
    $self->{default_options}={
 		option => { default => value },
 		option => { default => value },
    };
    
    return $self->{default_options};

 }

The approach above lets your subclasses add more options if they need to.
it also sets the default_options parameter, and returns it so that
you can call $self->default_options instead of $self->{default_options}.

=cut

stub 'default_options';

=head2 positional_parameters

If you need to use positional paramteres, define a
"positional_parameters" method that returns a reference to a list of the
parameter names in order, like this:

 const positional_parameters => [ "username", "password" ];

If the first argument to the "new" method is not a recognized option,
positional parameters will be used instead. So to have someone pass
a browser object followed by a hashref of options, you could do:

 const positional_parameters => [ 'browser', 'options' ];

=cut

stub 'positional_parameters';

=head2 new

Initialize and return a new object.

 We accept the following formats:

 new - Just creates and returns the new object.
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
 $object->new( browser => $browser );
 
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
lazy and not create accessors for your options.

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
	# - new( $options_hashref )
    if ( ( @_ == 1 ) && ( ref $_[0] eq 'HASH') ) {
		%options = %{ $_[0] };
	# - new( %options )
	#   If more than 1 argument, and an even number of arguments, and
	#   the first argument is one of our known options.
	} elsif ( ( @_ > 1 ) && ( @_ % 2 == 0 ) &&
		( defined( $self->default_options->{ "$_[0]" } ) ) ) {
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

=head2 save( filename )

Saves the object to the file specified by "filename".
Saves every field specified in the default_options and
positional_parameters methods.

=cut

sub save {

    my $filename = shift;
	my $data = {};

	# For each field listed as persistent, store it in the
	# hash of data that's going to be saved.
	foreach my $key ( ( keys( %{ $self->default_options } ),
			@{ $self->positional_parameters } ) ) {
		unless ( $self->_nosave( $key ) ) {
			# IMPORTANT: Only save what's defined or we'll
			# break defaults.
			if ( exists $self->{$key} ) {
				${$data}{$key} = $self->{$key}
			}
		}
	}

	DumpFile( $filename, $data );

}

=head2 _nosave( fieldname )

Override this method in your base class if there are fields you
don't want the save command to save.  Otherwise, all fields specified in
your default_options and postitional_parameters will be saved.

_nosave is passed a field name.  Return 1 if you don't want it saved.
Return 0 if you want it saved.  The stub method just returns 0.

 Sample _nosave method:
 sub _nosave {

    my ( $key ) = @_;

    # List only fields you don't want saved
    my %fields = ( fieldname => 1, fieldname2 => 1 );

    if ( $key && ( $fields{"$key"} ) ) { return 1 } else { return 0 }

 }

=cut

sub _nosave { return 0 }

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
C<bug-www-Sitebase at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Sitebase>.
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

    perldoc WWW::Sitebase

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-Sitebase>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-Sitebase>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-Sitebase>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-Sitebase>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2005, 2014 Grant Grueninger, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of WWW::Sitebase
