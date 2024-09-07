package Zleep;

use 5.006;
use strict;
use warnings;
our $VERSION = '0.01';
use base 'Import::Export';

our %EX = (
	zleep => [qw/all/]
);

sub zleep {
	my ($cb, $ms) = @_;
	my $pid = fork() and return;
	select(undef, undef, undef, $ms / 1000);
	$cb->();
	exit;
}

1;

__END__

=head1 NAME

Zleep - zleep

=head1 VERSION

Version 0.01

=cut

=head1 SYNOPSIS

	use Zleep qw/zleep/;
	
	my $param = 'abc';

	zleep(sub {
		print "me after $param\n";
	}, 500);

	print "me first\n";


=head1 EXPORT

=head2 zleep

Fork a new process, sleep for the number of ms and then execute the codeblock.

	zleep(sub {
		...
	}, 1000);

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-zleep at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Zleep>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Zleep

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Zleep>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Zleep>

=item * Search CPAN

L<https://metacpan.org/release/Zleep>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2024 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

1; # End of Zleep
