package Eirotic; 

#ABSTRACT: Eirotic - a module to load and use Perl my may 

=encoding utf8
=head1 NAME

Eirotic - a module to load and use Perl my may

=head1 VERSION

0.3

=cut
our $VERSION = '0.3';

=head1 SYNOPSIS

writting

    use Eirotic;

replaces this boilerplate

    use 5.20.0;
    use strict;
    use warnings qw( FATAL all );
    use experimental 'signatures'; 
    use Perlude;
    use curry;
    use Path::Tiny;
    require YAML;

=head1 CHANGES

=head1 v0.1 (2015)

=over 4

=item * 

C<Eirotic> moved to C<Eirotic::514>.

=item *  

C<IO::All> replaced by C<Path::Tiny>.

=item * 

L<https://metacpan.org/pod/Method::Signatures> replaced by CORE experimental ones.  

=back

=head1 YET EXPERIMENTING

=head2 Unicode everywhere

is utf8::all a good idea ? use C<use> instead of my own import? 

=head2 List::AllUtils ? 

temptation is strong but i don't want to conflict with perlude, even in the
user's brain.

what about the idea from L<https://metacpan.org/author/BOOK> (used in Perlude): use a very short NS. like
C<A> for C<Array> and C<S> for stream? 

=head2 About autodie and fatal warnings

seems to be nice but maybe i should read L<http://blogs.perl.org/users/peter_rabbitson/2014/01/fatal-warnings-are-a-ticking-time-bomb-via-chromatic.html>

=head1 AUTHOR

Marc Chantreux <marcc@cpan.org>  

=head1 BUGS
 
Please report any bugs or feature requests to C<bug-eirotic at rt.cpan.org>, or through
the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Eirotic>.  I will be
notified, and then you'll automatically be notified of progress on your bug as
I make changes.
 
=head1 SUPPORT
 
You can find documentation for this module with the perldoc command.
 
    perldoc Eirotic
 
You can also look for information at:
 
=over 4
 
=item * RT: CPAN's request tracker
 
L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Eirotic>
 
=item * AnnoCPAN: Annotated CPAN documentation
 
L<http://annocpan.org/dist/Eirotic>
 
=item * CPAN Ratings
 
L<http://cpanratings.perl.org/d/Eirotic>
 
=item * CPAN
 
L<https://metacpan.org/release/eirotic>
 
=back
 
=head1 COPYRIGHT
 
Copyright 2013-2015 Marc Chantreux (eiro). 

=head1 LICENSE
 
This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.
 
See L<http://dev.perl.org/licenses/> for more information.

=cut

use strict ();
use warnings ();
use feature ();
use autodie ();
require Perlude;
require YAML;
use curry;
require Path::Tiny;
require Import::Into;

sub import {

    my ( $what ) = pop;
    my ( $caller ) = caller; 

    feature->import(':5.20');          # use 5.20.0;
    strict->import;                    # use strict;
    warnings->import;  # use warnings qw( FATAL all );
    # warnings->import(qw( FATAL all )); # use warnings qw( FATAL all );

    #use experimental 'signatures';

    feature->import('signatures');
    warnings->unimport("experimental::signatures"); 

    use Perlude;
    use Path::Tiny;
    
    #return unless $what eq "-full";
    Perlude->import::into($caller);
    Path::Tiny->import::into($caller); 

}

1;

