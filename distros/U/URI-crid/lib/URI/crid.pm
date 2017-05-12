package URI::crid;

require URI;
our @ISA=qw(URI);

use warnings;
use strict;
use URI::Escape qw(uri_unescape);

=head1 NAME

URI::crid - URI scheme as defined in RFC 4078

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

Allows you to break down and/or build up URIs of the scheme CRID (as used
by the TV-Anytime standard to uniquely identify television and radio
programmes.

    use URI;

    my $doctor_who = URI->new("crid://bbc.co.uk/b0074fly");
	print "authority: " . $doctor_who->authority . $/;
	print "data: " . $doctor_who->data . $/;
    ...

=head1 METHODS

=head2 authority [AUTHORITY]

Returns (or sets) the organisation which owns this crid. This usually
corresponds to the organisation's domain name.

=cut

sub authority
{
    my $self = shift;
    my $old = $self->opaque;
    if (@_) {
		my $data = ($old =~ m|//[^/]+/(.*)$|)[0];
		my $new = shift;
		$new = "" unless defined $new;
		$self->opaque("//$new/$data");
		return $new;
    }
	$old = ($old =~ m|^//([^/]+)/?|)[0] || '';
    return undef unless defined $old;
    return uri_unescape($old);
}

=head2 data [DATA]

Returns (or sets) the unique identifier that this crid applies to.
The author of a crid may decide for themselves what form this data 
takes, to best suit the application.

=cut

sub data
{
	my $self = shift;
	my $old = $self->opaque;
    if (@_) {
    	my $tmp = $old;
    	$tmp = "/" unless defined $tmp;
		my $authority = ($old =~ m|^//([^/]+)/?|)[0] || '';
    	my $new = shift;
    	$new = "" unless defined $new;
    	$self->opaque("//$authority/$new");
		return $new;
    }
	$old = ($old =~ m|//[^/]+/(.*)$|)[0];
    return uri_unescape($old);
}

1;

=head1 AUTHOR

Ali Craigmile, C<< <ali at hodgers.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-uri-crid at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=URI-crid>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc URI::crid


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=URI-crid>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/URI-crid>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/URI-crid>

=item * Search CPAN

L<http://search.cpan.org/dist/URI-crid>

=back


=head1 ACKNOWLEDGEMENTS

Gisle Aas C<< gaas@cpan.org >> for writing the base class URI.

=head1 COPYRIGHT & LICENSE

Copyright 2007 Ali Craigmile, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of URI::crid
