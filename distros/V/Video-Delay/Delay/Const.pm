package Video::Delay::Const;

use strict;
use warnings;

use Class::Utils qw(set_params);

our $VERSION = 0.07;

# Constructor.
sub new {
	my ($class, @params) = @_;

	# Create object.
	my $self = bless {}, $class;

	# Constant.
	$self->{'const'} = 1000;

	# Process params.
	set_params($self, @params);

	# Object.
	return $self;
}

# Get delay.
sub delay {
	my $self = shift;
	return $self->{'const'};
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Video::Delay::Const - Video::Delay class for constant delay.

=head1 SYNOPSIS

 use Video::Delay::Const;

 my $obj = Video::Delay::Const->new(%parameters);
 my $delay = $obj->delay;

=head1 METHODS

=over 8

=item C<new(%parameters)>

 Constructor

=over 8

=item * C<const>

 Constant delay in miliseconds.
 Default value is 1000.

=back

=item C<delay()>

 Returns constant delay defined by 'const' parameter in miliseconds.

=back

=head1 ERRORS

 new():
         From Class::Utils::set_params():
                 Unknown parameter '%s'.

=head1 EXAMPLE

 use strict;
 use warnings;

 use Video::Delay::Const;

 # Object.
 my $obj = Video::Delay::Const->new(
         'const' => 1000,
 );

 # Print delay.
 print $obj->delay."\n";
 print $obj->delay."\n";
 print $obj->delay."\n";

 # Output:
 # 1000
 # 1000
 # 1000

=head1 DEPENDENCIES

L<Class::Utils>.

=head1 SEE ALSO

=over

=item L<Video::Delay>

Perl classes for delays between frames generation.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Video-Delay>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

 © 2012-2020 Michal Josef Špaček
 BSD 2-Clause License

=head1 VERSION

0.07

=cut
