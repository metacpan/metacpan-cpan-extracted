package WWW::PlantUML;

use 5.006;
use strict;
use warnings;

use Carp;
use UML::PlantUML::Encoder qw(encode_p);

=head1 NAME

WWW::PlantUML - a simple Perl remote client interface to a plantuml server.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';
our $URL     = 'http://www.plantuml.com/plantuml';

=head1 SYNOPSIS

    use WWW::PlantUML;

    my $puml = WWW::PlantUML->new;
    my $url  = $puml->fetch_url(qq{
       Alice -> Bob : hello
    }, 'png');

    print $url; 
    # prints  http://www.plantuml.com/plantuml/png/69NZKb1moazIqBLJSCp9J4vLi5B8ICt9oUS204a_1dy0

=head1 DESCRIPTION

Plantuml is a library for generating UML diagrams from a simple text markup language.

This is a simple Perl remote client interface to a plantuml server using the same custom encoding used by most other plantuml clients. Perl was missing from the list.

There are other plantuml Perl libraries, like PlantUML::ClassDiagram::Parse, they provide only parsing capabilities for Class Diagrams. In contrast WWW::PlantUML module provides accessing any UML Diagram Type in various formats supported by any plantUML server via HTTP Protocol.

This client defaults to the public plantuml server, but can be used against any server.

=head1 SUBROUTINES/METHODS

=head2 new

Constructor.

Can be optionally passed a URL to the PlantUML Server. 

Defaults to http://www.plantuml.com/plantuml

=cut

sub new {
    my $class = shift;
    my $url   = shift;
    my %args  = (
        'baseurl'  => $url || $ENV{PLANTUML_BASE_URL} || $URL,
        'contexts' => ( 'png', 'svg', 'txt' ),
        @_,
    );

    return bless {%args}, $class;
}

=head2 fetch_url

First parameter is PlantUML Syntax as a String.

Optionally second parameter is the format of the generated diagram as a String.

Default is Text Format.

=cut

sub fetch_url {
    my $self = shift;
    my $base = $self->{'baseurl'};

    #my $path           = $self->{'infopath'};
    #my ( $type, $code ) = $self->_parse_args(@_);
    my $code = shift;
    my $type = shift;

    my $ncoded = encode_p($code);
    my $url    = defined $type ? "$base/$type/$ncoded" : "$base/txt/$ncoded";
    return $url;
}

=head1 AUTHOR

Rangana Sudesha Withanage, C<< <rwi at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-www-plantuml at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-PlantUML>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::PlantUML


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-PlantUML>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-PlantUML>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/WWW-PlantUML>

=item * Search CPAN

L<https://metacpan.org/release/WWW-PlantUML>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2019 by Rangana Sudesha Withanage.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=cut

1;    # End of WWW::PlantUML
