package WWW::FMyLife::Item;

use Moose;
use Moose::Util::TypeConstraints;

our $VERSION = '0.05';

subtype 'FMLAuthor'
    => as 'HashRef'
    => where { exists shift->{'content'} };

subtype 'FMLVote'
    => as 'HashRef'
    => where {
        my $ref = shift;
        ( exists $ref->{'deserved'}     && exists $ref->{'agree'}     ) &&
        ( $ref->{'deserved'} =~ /^\d+$/ && $ref->{'agree'} =~ /^\d+$/ )
    };

subtype 'EmptyComment'
    => as 'HashRef'
    => where {
        my $ref = shift;
        scalar keys %{$ref} == 0;
    };

has 'id'            => ( is => 'rw', isa => 'Int'              );
has 'author'        => ( is => 'rw', isa => 'FMLAuthor'        );
has 'date'          => ( is => 'rw', isa => 'Str'              );
has 'category'      => ( is => 'rw', isa => 'Str'              );
has 'text'          => ( is => 'rw', isa => 'Str'              );
has 'vote'          => ( is => 'rw', isa => 'HashRef'          );
has 'deserved'      => ( is => 'rw', isa => 'Int'              );
has 'agree'         => ( is => 'rw', isa => 'Int'              );
has 'comments'      => ( is => 'rw', isa => 'Int|EmptyComment' );
has 'comments_flag' => ( is => 'rw', isa => 'Bool'             );

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

WWW::FMyLife::Item - Represents a single FMyLife.com Item

=head1 VERSION

Version 0.04

=head1 SYNOPSIS

    my $fml = WWW::FMyLife::Item->new( {
        author => 'me',
        text   => 'Stuff',
    } );

    ...

=head1 EXPORT

Nothing.

=head1 METHODS

=head2 new

Create a new item which can be submitted to FML.

=head1 AUTHORS

Sawyer X (XSAWYERX), C<< <xsawyerx at cpan.org> >>
Tamir Lousky (TLOUSKY), C<< <tlousky at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-www-fmylife at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-FMyLife>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::FMyLife

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-FMyLife>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-FMyLife>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-FMyLife>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-FMyLife/>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2010 Sawyer X, Tamir Lousky.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

