# ABSTRACT: use perl *my* way

=head1 SYNOPSIS

just 

    use Eirotic::514;

to have

    use strict;
    use warnings qw< FATAL all >;
    use 5.14.0; # because given is fixed there
    use Perlude;
    use Method::Signatures;
    use File::Slurp qw< :all >;

=head1 MORE to come

is utf8::all a good idea ? use C<use> instead of my own import?

=head1 please help to make my mind up

=head2 About signatures

I have to read again those docs but if someone can explain the motivation
behind Kavorka?  (i never tested it as i'm perfectly happy about
Method::Signatures). 

        https://metacpan.org/pod/Method::Signatures
        https://metacpan.org/pod/Method::Signatures#THANKS
        https://metacpan.org/pod/Function::Parameters
        https://metacpan.org/pod/MooseX::Method::Signatures
        https://metacpan.org/pod/signatures
        https://metacpan.org/pod/Attribute::Signature
        https://metacpan.org/pod/Kavorka

=head2 About IO::All

Should i import IO::All and how to import operator overloading? my guess is i
just have to import C<&io>  but i never tested it. 

=head2 About List::AllUtils

temptation is strong but i don't want to conflict with perlude, even in the
user's brain.

what about the idea from C<Book> (used in Perlude): use a very short NS. like
C<A> for C<Array> and C<S> for stream? 

=head2 About Mouse and Moo

Why so serioo? Mouse seems to be faster even in PP. is this about memory consumption ?

=head2 About autodie and fatal warnings

seems to be nice but maybe i should read
L<http://blogs.perl.org/users/peter_rabbitson/2014/01/fatal-warnings-are-a-ticking-time-bomb-via-chromatic.html>

=head1 CREDITS

    Author: Marc Chantreux <marcc@cpan.org>

=cut

package Eirotic::514;
use base 'Exporter';
use feature  ':5.14';
use strict   ();
use warnings ();
# require List::AllUtils;
require Method::Signatures;
require Perlude;
require File::Slurp;
use YAML;
# use IO::All;
use Import::Into;
our $VERSION = '0.0';

sub import {
    my $caller = caller;

    strict->import;
    # warnings->import(FATAL => 'all');
    warnings->import;
    feature->import( ':5.14' );

    Method::Signatures -> import( {into => $caller} );
    File::Slurp        -> import::into($caller, ':all');
    Perlude            -> import::into($caller);
    # List::AllUtils     -> import::into($caller, qw< first any all >);

    # IO::All->import::intro($caller);
}

1;

