package WWW::Session::Serialization::JSON;

use 5.006;
use strict;
use warnings;

use JSON;

=head1 NAME

WWW::Session::Serialization::JSON - Serialization engine for WWW::Session with JSON backend

=head1 DESCRIPTION

JSON serialization engine for WWW::Session objects

=head1 VERSION

Version 0.12

=cut

our $VERSION = '0.12';


=head1 SYNOPSIS

This module handles serialization for WWW::Session objects

The object implements two main methods : serialize() and expand()

    use WWW::Session::Serialization::JSON;

    my $serializer = WWW::Session::Serialization::JSON->new();
    ...
    
    $string = $serializer->serialize($structure);
    
    ...
    $structure = $serializer->expand($string);

=head1 SUBROUTINES/METHODS

=head2 new

Creates a new WWW::Session::Serialization::JSON object

Usage :

    my $serializer = WWW::Session::Serialization::JSON->new();
    
No arguments required.

=cut

sub new {
    my $class = shift;
    
    my $self = {};
    
    bless $self,$class;
    
    return $self;
}

=head2 serialize

Serializes a structure and returns a string containing all the data

=cut

sub serialize {
    my ($self,$data) = @_;
    
    return to_json($data);
}


=head2 expand

Deserializes string and returns a structure containing all the data

=cut
sub expand {
    my ($self,$string) = @_;
    
    return from_json($string);
}

=head1 AUTHOR

Gligan Calin Horea, C<< <gliganh at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-www-session at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Session>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::Session::Serialization::JSON


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-Session>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-Session>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-Session>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-Session/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Gligan Calin Horea.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of WWW::Session::Serialization::JSON
