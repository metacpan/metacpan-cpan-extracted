package Video::Delay::Func;

# Pragmas.
use strict;
use warnings;

# Modules.
use Class::Utils qw(set_params);
use English qw(-no_match_vars);
use Error::Pure qw(err);

# Version.
our $VERSION = 0.06;

# Constructor.
sub new {
	my ($class, @params) = @_;

	# Create object.
	my $self = bless {}, $class;

	# Math function.
	$self->{'func'} = sub {
		my $t = shift;
		return 1000 * sin($t);
	};

	# Counter increment.
	$self->{'incr'} = 0.1;

	# Process params.
	set_params($self, @params);

	# Counter.
	$self->{'counter'} = 0;

	# Check 'func' parameters.
	if (ref $self->{'func'} ne '' && ref $self->{'func'} ne 'CODE') {
		err "Parameter 'func' must be scalar or code.";
	}

	# Object.
	return $self;
}

# Get delay.
sub delay {
	my $self = shift;

	# Counter.
	$self->{'counter'} += $self->{'incr'};

	# Function string.
	my $ret;
	if (ref $self->{'func'} eq '') {
		my $input = $self->{'func'};
		my $c = $self->{'counter'};
		$input =~ s/t/$c/g;

		# Eval.
		$ret = eval $input;
		if ($EVAL_ERROR) {
			err 'Error in function.',
				'Error', $EVAL_ERROR;
		}

	# Callback.
	} else {
		$ret = $self->{'func'}->($self->{'counter'});
	}

	return $ret;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Video::Delay::Func - Video::Delay class for delays defined by math function.

=head1 SYNOPSIS

 use Video::Delay::Func;
 my $obj = Video::Delay::Func->new(%parameters);
 my $delay = $obj->delay;

=head1 METHODS

=over 8

=item C<new(%parameters)>

 Constructor

=over 8

=item * C<func>

 Math function in string with 't' time variable.
 Or callback with one input argument as time variable.
 Default value is reference to subroutine:
   sub {
     my $t = shift;
     return 1000 * sin($t);
   };

=item * C<incr>

 Counter increment.
 Default value is 0.1.

=back

=item C<delay()>

 Returns delay defined by function in miliseconds.
 Time si affected by 'incr' increment parameter.

=back

=head1 ERRORS

 new():
         Parameter 'func' must be scalar or code.
         From Class::Utils::set_params():
                 Unknown parameter '%s'.

 delay():
         Error in function.
                 Error, %s

=head1 EXAMPLE1

 # Pragmas.
 use strict;
 use warnings;

 # Modules.
 use Video::Delay::Func;

 # Object.
 my $obj = Video::Delay::Func->new(
         'func' => sub {
                 my $t = shift;
                 return 1000 * sin($t);
         },
         'incr' => 0.1,
 );

 # Print delay.
 print $obj->delay."\n";
 print $obj->delay."\n";
 print $obj->delay."\n";

 # Output:
 # 99.8334166468282
 # 198.669330795061
 # 295.52020666134

=head1 EXAMPLE2

 # Pragmas.
 use strict;
 use warnings;

 # Modules.
 use Video::Delay::Func;

 # Object.
 my $obj = Video::Delay::Func->new(
         'func' => '1000 * sin(t)',
         'incr' => 0.1,
 );

 # Print delay.
 print $obj->delay."\n";
 print $obj->delay."\n";
 print $obj->delay."\n";

 # Output:
 # 99.8334166468282
 # 198.669330795061
 # 295.52020666134

=head1 DEPENDENCIES

L<Class::Utils>,
L<English>,
L<Error::Pure>.

=head1 SEE ALSO

=over

=item L<Video::Delay>

Perl classes for delays between frames generation.

=back

=head1 REPOSITORY

L<https://github.com/tupinek/Video-Delay>

=head1 AUTHOR

Michal Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

 © 2012-2015 Michal Špaček
 BSD 2-Clause License

=head1 VERSION

0.06

=cut
