package Unicode::Block::Item;

use strict;
use warnings;

use Class::Utils qw(set_params);
use Error::Pure qw(err);
use Readonly;
use Text::CharWidth qw(mbwidth);
use Unicode::Char;

# Constants.
Readonly::Scalar our $EMPTY_STR => q{};
Readonly::Scalar our $SPACE => q{ };

our $VERSION = 0.08;

# Constructor.
sub new {
	my ($class, @params) = @_;

	# Create object.
	my $self = bless {}, $class;

	# Hexadecimal number.
	$self->{'hex'} = undef;

	# Length of hex number.
	$self->{'hex_length'} = 4;

	# Process parameters.
	set_params($self, @params);

	# Check hex number.
	if (! defined $self->{'hex'}) {
		err "Parameter 'hex' is required.";
	}
	if (! $self->_is_hex) {
		err "Parameter 'hex' isn't hexadecimal number.";
	}

	# Object.
	return $self;
}

# Get hex base number.
sub base {
	my $self = shift;
	my $base = substr $self->hex, 0, -1;
	return 'U+'.$base.'x';
}

# Get character.
sub char {
	my $self = shift;

	# Create object.
	if (! exists $self->{'u'}) {
		$self->{'u'} = Unicode::Char->new;
	}

	# Get char.
	my $char = $self->{'u'}->u($self->{'hex'});

	# 'Non-Spacing Mark' and 'Enclosing Mark'.
	if ($char =~ m/\p{Mn}/ms || $char =~ m/\p{Me}/ms) {
		$char = $SPACE.$char;

	# Control.
	} elsif ($char =~ m/\p{Cc}/ms) {
		$char = $SPACE;

	# Not Assigned.
	} elsif ($char =~ m/\p{Cn}/ms) {
		$char = $EMPTY_STR;
	}

	return $char;
}

# Get hex number.
sub hex {
	my $self = shift;
	return sprintf '%0'.$self->{'hex_length'}.'x',
		CORE::hex $self->{'hex'};
}

# Get last hex number.
sub last_hex {
	my $self = shift;
	return substr $self->{'hex'}, -1;
}

# Get character width.
sub width {
	my $self = shift;
	if (! exists $self->{'_width'}) {
		$self->{'_width'} = mbwidth($self->char);
		if ($self->{'_width'} == -1) {
			$self->{'_width'} = 1;
		}
	}
	return $self->{'_width'};
}

# Check for hex number.
sub _is_hex {
	my $self = shift;
	if ($self->{'hex'} !~ m/^[0-9a-fA-F]+$/ims) {
		return 0;
	}
	my $int = CORE::hex $self->{'hex'};
	if (! defined $int) {
		return 0;
	}
	my $hex = sprintf '%x', $int;
	my $value = lc $self->{'hex'};
	$value =~ s/^0*//ms;
	if ($value eq '') {
		$value = 0;
	}
	if ($hex ne $value) {
		return 0;
	}
	return 1;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Unicode::Block::Item - Class for unicode block character.

=head1 SYNOPSIS

 use Unicode::Block::Item;

 my $obj = Unicode::Block::Item->new(%parameters);
 my $base = $obj->base;
 my $char = $obj->char;
 my $hex = $obj->hex;
 my $last_hex = $obj->last_hex;
 my $width = $obj->width;

=head1 METHODS

=head2 C<new>

 my $obj = Unicode::Block::Item->new(%parameters);

Constructor.

=over 8

=item * C<hex>

Hexadecimal number.

It is required.

Default value is undef.

=item * C<hex_length>

Length of hex number.
It's used for formatting of hex() method output.

Default value is 4.

=back

Returns instance of object.

=head2 C<base>

 my $base = $obj->base;

Get hex base number in format 'U+???x'.
Example: 'hex' => 1234h; Returns 'U+123x'.

Returns string with hex base number.

=head2 C<char>

 my $char = $obj->char;

Get character.
Example: 'hex' => 1234h; Returns 'ሴ'.

Returns string with character.

=head2 C<hex>

 my $hex = $obj->hex;

Get hex number in 'hex_length' length.
Example: 'hex' => 1234h; Returns '0x1234'.

Returns string with hex number.

=head2 C<last_hex>

 my $last_hex = $obj->last_hex;

Get last hex number.
Example: 'hex' => 1234h; Returns '4'.

Returns string with last hex number.

=head2 C<width>

 my $width = $obj->width;

Get character width.

Returns string with width.

=head1 ERRORS

 new():
         Parameter 'hex' is required.
         Parameter 'hex' isn't hexadecimal number.
         From Class::Utils::set_params():
                 Unknown parameter '%s'.

=head1 EXAMPLE

=for comment filename=print_info_about_example_character.pl

 use strict;
 use warnings;

 use Unicode::Block::Item;
 use Unicode::UTF8 qw(encode_utf8);

 # Object.
 my $obj = Unicode::Block::Item->new(
        'hex' => 2505,
 );

 # Print out.
 print 'Character: '.encode_utf8($obj->char)."\n";
 print 'Hex: '.$obj->hex."\n";
 print 'Last hex character: '.$obj->last_hex."\n";
 print 'Base: '.$obj->base."\n";

 # Output.
 # Character: ┅
 # Hex: 2505
 # Last hex character: 5
 # Base: U+250x

=head1 DEPENDENCIES

L<Class::Utils>,
L<Error::Pure>,
L<Readonly>,
L<Text::CharWidth>,
L<Unicode::Char>.

=head1 SEE ALSO

=over

=item L<Unicode::Block>

Class for unicode block manipulation.

=back

=head1 REPOSITORY

L<https://github.com/tupinek/Unicode-Block>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2013-2023 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.08

=cut
