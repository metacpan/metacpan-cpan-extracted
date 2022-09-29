package Unidexer;

use 5.006; use strict; use warnings; our $VERSION = '0.01';

our $CHARS = 149186;

sub new {
	my ($class, @words) = @_;
	if (ref $words[1]) {
		$CHARS = shift @words;
		@words = @{ $words[0] };
	}
	my $self = bless [_build_default()], __PACKAGE__;
	$self->index($_) for (@words);
	return $self;
}

sub _build_default {
	return map { [ ] } 0 .. $CHARS
}

sub index {
	my ($self, $word) = @_;
	my $current = $self;
	for (split "|", ref $word ? $word->{index} : $word) {
		my $ord = ord($_);
		$ord -= 97 if ($CHARS == 26);
		unshift @{ $current }, _build_default() if ( scalar @{$current} < $CHARS );
		$current = $current->[$ord];
	}
	push @{$current}, $word;
}

sub search {
	my ($self, $search) = @_;
	my $word = $self;
	for (split "|", $search) {
		my $ord = ord($_);
		$ord -= 97 if ($CHARS == 26);
		$word = $word->[$ord];
		last if !$word;
	}
	return ref $word && ref $word->[-1] ne 'ARRAY' ? $word->[-1] : die "Index cannot be found: ${search}";
}

1;

__END__

=head1 NAME

Unidexer - ...

=head1 VERSION

Version 0.01

=cut

=head1 SYNOPSIS

	use Unidexer;

	my $indexed = Unidexer->new(
		26, # limit to only use alpha chars which is much faster than supporting all unicode 
		[
			'greece',
			'thailand',
			'vietnam',
			...
		]
	);

	$indexed->search('thailand'); # thailand

	...

	my $indexed = Unidexer->new(
		'รัก',
		'เกลียด',
		{ index => 'โลก', description => 'โลกพร้อมกับประเทศ ประชาชน และลักษณะทางธรรมชาติทั้งหมด' }
	);

	$indexed->search('โลก'); # { index => 'โลก', description => 'โลกพร้อมกับประเทศ ประชาชน และลักษณะทางธรรมชาติทั้งหมด' }

I had this idea after a question on fb, it probably has a name but i'm not a computer scientist :).

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-unidexer at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Unidexer>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Unidexer

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Unidexer>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Unidexer>

=item * Search CPAN

L<https://metacpan.org/release/Unidexer>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2022 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

1; # End of Unidexer
