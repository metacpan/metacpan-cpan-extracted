package Text::DSV;

use strict;
use warnings;

our $VERSION = 0.11;

# Constructor.
sub new {
	my ($class, @params) = @_;

	# Create object.
	my $self = bless {}, $class;

	# Object.
	return $self;
}

# Parse all data.
sub parse {
	my ($self, $data) = @_;
	my @data_lines;
	foreach my $line (split m/\n/ms, $data) {
		if ($line =~ m/^\s*$/ms || $line =~ m/^\s*#/) {
			next;
		}
		push @data_lines, [$self->parse_line($line)];
	}
	return @data_lines;
}

# Parse one line.
sub parse_line {
	my ($self, $line) = @_;
	my @data_line = split m/(?<!\\):/ms, $line;
	foreach my $data (@data_line) {
		$data =~ s/\\:/:/gms;
		$data =~ s/\\n/\n/gms;
	}
	return @data_line;
}

# Serialize all data.
sub serialize {
	my ($self, @data_lines) = @_;
	my $ret;
	foreach my $data_line_ar (@data_lines) {
		$ret .= $self->serialize_line(@{$data_line_ar})."\n";
	}
	return $ret;
}

# Serialize one line.
sub serialize_line {
	my ($self, @data_line) = @_;
	my @escape_data = @data_line;
	foreach my $data (@escape_data) {
		$data =~ s/:/\\:/gms;
		$data =~ s/\n/\\n/gms;
	}
	return join ':', @escape_data;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Text::DSV - DSV parser and serializer.

=head1 SYNOPSIS

 use Text::DSV;

 my $obj = Text::DSV->new;
 my @data_lines = $obj->parse($data);
 my @data_line = $obj->parse_line($line);
 my $string = $obj->serialize(@data_lines);
 my $line_string = $obj->serialize_line(@data_line);

=head1 METHODS

=head2 C<new>

 my $obj = Text::DSV->new;

Constructor.

Returns instance of object.

=head2 C<parse>

 my @data_lines = $obj->parse($data);

Parse all data.

Returns array of arrays of data.

=head2 C<parse_line>

 my @data_line = $obj->parse_line($line);

Parse one line.

Returns array of data.

=head2 C<serialize>

 my $string = $obj->serialize(@data_lines);

Serialize all data.

Returns string.

=head2 C<serialize_line>

 my $line_string = $obj->serialize_line(@data_line);

Serialize one line.

Returns line string.

=head1 EXAMPLE1

 use strict;
 use warnings;

 use Dumpvalue;
 use Text::DSV;

 # Object.
 my $dsv = Text::DSV->new;

 # Parse data.
 my @datas = $dsv->parse(<<'END');
 1:2:3
 # Comment
 
 4:5:6
 END

 # Dump data.
 my $dump = Dumpvalue->new;
 $dump->dumpValues(\@datas);

 # Output like this:
 # 0  ARRAY(0x8fcb6c8)
 #    0  ARRAY(0x8fd31a0)
 #       0  1
 #       1  2
 #       2  3
 #    1  ARRAY(0x8fd3170)
 #       0  4
 #       1  5
 #       2  6

=head1 EXAMPLE2

 use strict;
 use warnings;

 use Text::DSV;

 # Object.
 my $dsv = Text::DSV->new;

 # Serialize.
 print $dsv->serialize(
	[1, 2, 3],
	[4, 5, 6],
 );

 # Output:
 # 1:2:3
 # 4:5:6

=head1 SEE ALSO

=over

=item L<Text::CSV>

comma-separated values manipulator (using XS or PurePerl)

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Text-DSV>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2011-2021 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.11

=cut
