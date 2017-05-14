package YAML::Accessor;

use 5.10.0;

use feature qw{ state };
use base qw{ Class::Accessor };

# hi, mst.
use strictures 1;

use YAML::XS;
use Params::Validate qw{ :types validate };
use Scalar::Util qw{ blessed };

sub new {
	my $package = shift;
	state $spec = {
		file => {
			optional => 0,
			type     => SCALAR | HANDLE,
		},
		autocommit => {
			optional => 1,
			default  => 0,
			type     => SCALAR,
		},
		readonly   => {
			optional => 1,
			default  => 1,
			type     => SCALAR,
		},
		damian     => {
			optional => 1,
			default  => 1,
			type     => SCALAR,
		}
	};
	
	my %params = validate( @_, $spec );
		
	if ($params{readonly} and $params{autocommit}) {
		$! = "Failed by having readonly and autocommit set.";
		return undef;
	}
	
	# Uri made it safe for us to slurp files by name or by handle,
	# but Ingy does it just fine in YAML::Accessor:
	# return YAML::XS::LibYAML::Load(do { local $/; <$IN> });
	# XXX: don't change this, Ingy.
	my $yaml = YAML::XS::LoadFile( $params{file} );
	
	# There's recursion here, so we have to use Class::Accessor instead
	# of our own package.
	my $object_params = bless \%params, 'Class::Accessor';

	# the choice to damian here is mine.
	$object_params->follow_best_practice();
	$object_params->mk_ro_accessors( keys %{ $object_params } );
	my $damian = $object_params->get_damian();

	my $obj = bless { 
		yaml => $yaml,
		params => $object_params,
	}, $package;

	$obj->mk_ro_accessors( qw{ params } );

	if ($obj->{params}->get_damian()) {
		$package->follow_best_practice();
	}

	# Both accessors and mutators need local get/set methods
	# because we don't want to just access the values of the
	# YAML::Accessor object, we want to access the sub-accessors, too.
	if ($obj->{params}->get_readonly()) {
		foreach my $key ( %{ $yaml } ) {
			$obj->mk_ro_accessors( keys %{ $yaml } );
		}
		return $obj;
	}
	else {
		$obj->mk_accessors( keys %{ $yaml } );
		return $obj;
	}
}

sub set { # {{{
	my $self = shift;
	my ($key, @values) = (@_);
	
	return undef if $self->{params}->get_readonly();
	
	# Note to the user: you may be creating a new YAML key here.
	# XXX: NOTE: Class::Accessor tells us we might actually have more than one
	# value here. That seems like hogwash. So, the below line is commented. If
	# this is actually broken, tell me how to fix it.
	# 
	# $self->{yaml}->{$key} = (scalar @values > 1 ) ? shift @values : \@values;
	$self->{yaml}->{$key} = shift @values;
	
	# Since the object has set the values, we can push to the file if that's
	# what the user asked for. We don't need to run the constructor again
	# since the object is updated and intact.
	if ($self->{params}->get_autocommit()) {
		$self->commit();
		return $self->{yaml}->{$key};
	}
	
	return @values;
} # }}} 

sub get { # {{{
	my $self = shift;
	my $child_package  = 'YAML::Accessor';

	my (@keys) = (@_);

	# Hashrefslice again because they have asked for multiple keys.
	# Class::Accessor says this can happen. I'm not sure how that's
	# possible.
	if ( scalar @keys > 1 ) {
		return [ @{ $self->{yaml} }{ @keys } ]
	}

	my $key = shift @keys;

	if (exists $self->{yaml}) { # {{{ top-most object
		# we are the parent object
		if (not blessed $self->{yaml}->{$key} and 
			ref $self->{yaml}->{$key} eq 'HASH') { 
			my $new_accessor = bless $self->{yaml}->{$key}, $child_package;
			# Ensure our parameters propagate
			$new_accessor->{params} = $self->{params};
			if ($self->{params}->get_damian()) {
				$new_accessor->follow_best_practice();
			}
			my @sub_accessors = keys %{ $self->{yaml}->{$key} };
			$new_accessor->mk_ro_accessors( @sub_accessors );
			$self->{$key} = $new_accessor;
			return $new_accessor;
		}
		else {
			# This isn't a hashref and/or the object is already blessed. So just
			# return it.
			return $self->{yaml}->{$key};
		}
	} # }}}
	else { # {{{ sub-object
		# We are a sub-object, so check for blessedness, bless as appropriate
		# and move on
		if (blessed $self->{$key}) {
			return $self->{$key};
		}
		else {
			if (ref $self->{$key} eq 'HASH') {
				my $new_accessor = bless $self->{$key}, $child_package;
				if ($self->{params}->get_damian()) {
					$new_accessor->follow_best_practice();
				}
				# Ensure our parameters propagate
				$new_accessor->{params} = $self->{params};
				$new_accessor->mk_ro_accessors( keys %{ $new_accessor } );
				return $new_accessor;
			}
			else {
				# This isn't a hashref, just return the value
				return $self->{$key};
			}
		}
	} # }}}
} # }}}

# In case you're not using autocommit and want to force a write to the disk.
sub commit { # {{{
	my $self = shift;
	my $yaml = $self->{yaml};
	my $fn   = $self->{params}->{file};
	# arg 1 is a filename, everything afterwards gets written to the specified
	# file.
	return YAML::XS::DumpFile( $fn, $yaml ); # ingy, does this set $! ?
} # }}}

# In the event that your yaml changes while you're running, we can re-read
# the file. This is useful for tools that poll their config files for
# changes.
sub refresh {
	my ($self) = shift;
	return $self unless $self->{params}->{file};
	my $refreshed_self = new( __PACKAGE__, %{ $self->{params} } );
	return $refreshed_self;
}

22/7;

=pod

=head1 NAME

YAML::Accessor

=head1 ABSTRACT

Syntactic sugar for YAML::XS using Class::Accessor with sub-accessors.

=head1 SYNOPSIS

  package YConfig;
  use base qw{ YAML::Accessor };
  
  # Load by filename
  my $yc = YConfig->new(
    file => 'config.yml',  # Can be a filehandle.
    readonly   => 1,       # This is a default. Can be 1 (true).
    damian     => 1,       # See below. Can be 0 (false).

    # Implemented, but probably buggy and not tested.
    autocommit => 0,       # This is a default. Can be 1 (true).
  )
  or die "failed to load 'config.yml' [$!]";

=head1 DESCRIPTION

C<YAML::Accessor> aims to create a "gettr/settr" interface for YAML
objects/files and allow the user to both manipulate their structure
and to read and write from the (specified) file(s).

It doesn't use the simple C<YAML::XS> call C<LoadFile> and this may
seem unituitive for users of YAML::XS. The point is not to reinvent
L<YAML::XS>, but rather to create intuitive, easily-constructed objects
with proper accessor/mutator methods.

There are lots of things one could do with this; the obvious use case
is a config file.

=head1 PARAMETERS

C<file> is not optional. It's got to be a filehandle or a scalar that
(hopefully) refers to a file you can read. If not, C<new()> barfs and
properly sets C<$!> for you.

C<autocommit> is optional. If you set this to true, your file will be
written to each time a mutator is called.

C<readonly> is optional. It defaults to true. This means you get no
mutators ("settrs") and you won't munge your file accidentally. If you
set C<readonly> and C<autocommit> both to true, C<new> explodes and you
deserve what you get. But you still get C<$!>.

C<damian> refers to the L<Class::Accessor> method "follow_best_practice",
which is defined in Damian Conway's book on "Perl Best Practices" on ORA.
If you set this to true, your methods will be
  
  $obj->get_foo();     # gets the value of foo
  $obj->set_foo(100);  # sets foo to 100 

If you don't like this, set damian to false (that is, 0 or undef or ''),
and your methods will be:
  
  $foo = $obj->foo();  # returns value of foo
  $obj->foo(100);      # sets foo to 100

C<damian> defaults to true.

=head1 ACCESSORS

C<get_foo()> accessors will return whatever the value of C<foo> is (note
use of "Damianized" accessor here). In the event there's a list of things,
you need to read the code to the C<get()> method in this module.

C<set_foo()> mutators will set the value of whatever field is specified
(in this case, "foo" -- noting again the "Damianized" mutator). Mutators
return one of two things. If you've set C<autocommit> to true, the mutator
will return the value of the latest attempt to "commit" (write) your file.
In the event you have not turned on C<autocommit> during the constructor,
the mutator will simply return the value(s) supplied. For more detail,
have a look at the code. But really, it's not too complicated.

=head1 METHODS

C<commit()> allows you to force the current yaml to be flushed to disk.
Note that YAML::Accessor calls this method internally when you use 
mutators.

=head1 SUB-ACCESSORS

When calling an accessor method, the object will try to determine whether
the value you are requesting is itself an accessor (or rather, should be
made an accessor). Therefore you may use a construct such as:

  $obj->get_foo()->get_bar();

and it should Just Work. Note that this only works for hash values. If you
request an accessor that has an array or scalar (or anything else), you'll
simply get what you asked for.

Note that this is not standard L<Class::Accessor> behavior. The reason for
this is that YAML allows us to have deeply-nested structures, and having to
refer to their hash keys after a single layer of accessors, like such:

  $obj->get_foo()->{bar};

is tedious and misses the point of this package.

=head1 SEE ALSO

  YAML::XS
  Class::Accessor

  Perl Best Practices
  Damian Conway
  O'Reilly & Associates
  ISBN-13: 978-0596001735
  ASIN: 0596001738

=head1 BUGS

The implementation actually doesn't allow this module to internally use 
L<Class::Accessor> and instead overrides its C<get()> and C<set()> functions
to refer to your shiny YAML object. That's kind of inconsistent, but you
wanted YAML, not an object that referred to YAML. If you can come up with
a way to fix it, awesome. This way is simpler.

Also, it looks like doing something like

  use base qw{ Class::Accessor };
  use base qw{ YAML::Accessor  };

is fraught with peril. Don't do that.

While not exactly a bug, this package uses L<YAML::XS> instead of L<YAML>
in the interest of speed and ingy's preference.

=head1 AUTHOR

Jane A. Avriette, E<lt>jane@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Jane A. Avriette

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
