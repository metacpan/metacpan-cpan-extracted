package Validator::Group;
use Validator::Var;

use 5.006;
use strict;
use warnings;

=head1 NAME

Validator::Group - The great new Validator::Group!

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';


=head1 SYNOPSIS

    use Validator::Group;

    my $foo = Validator::Group->new();
    ...

=head1 SUBROUTINES/METHODS

=head2 new

Creates new variables validation group

=cut

sub new
{
    my $class = shift;
    my $self = bless {}, $class;
    return $self;
}


=head2 exists( $entry_id )

Returns true if Validator::Var instance specified by I<entry_id>
exists in the group.

=cut

sub exists
{
    my ($self, $vv_id) = @_;
    return defined $self->{$vv_id} ? 1 : 0;
}


=head2 entry( $entry_id )

Returns Validator::Var instance specified by I<entry_id>.
If entry does not exist it will be created without any checker functions.

    my $entry = $validator->entry('entry_id');

=cut

sub entry
{
    my ($self, $vv_id) = @_;
    $self->{$vv_id} = Validator::Var->new unless defined $self->{$vv_id};
    return $self->{$vv_id};
}


=head1 AUTHOR

Fedor Semenov, C<< <fedor.v.semenov at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-validator-var at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Validator-Var>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Validator::Group


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Validator-Var>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Validator-Var>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Validator-Var>

=item * Search CPAN

L<http://search.cpan.org/dist/Validator-Var/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2011 Fedor Semenov.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Validator::Group
