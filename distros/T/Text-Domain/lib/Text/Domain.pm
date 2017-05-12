package Text::Domain;

use Locale::gettext;
use Exporter;
use vars qw: $VERSION @ISA @EXPORT_OK :;

$VERSION = '0.9';
# $Id: Domain.pm,v 1.1 2001/12/13 21:46:17 jgsmith Exp $

@ISA = qw: Exporter :;

@EXPORT_OK = qw: pushtextdomain poptextdomain :;

{
    my @textdomainstack;

    sub pushtextdomain($) {
        push @textdomainstack, textdomain(shift);
    }

    sub poptextdomain() {
        return textdomain(pop @textdomainstack);
    }
}

sub new {
    bless textdomain $_[1], ref $_[0] ? ref $_[0] : $_[0];
}

sub DESTROY { textdomain $_[0]; }

1;
__END__

=head1 NAME

Text::Domain - Localization of gettext domain settings

=head1 SYNOPSIS

 use Text::Domain;

 {
    my $domain = new Text::Domain 'xyz';
    # do stuff here
 } # restore old textdomain on exit of block

OR

 use Text::Domain qw: pushtextdomain poptextdomain :;

 pushtextdomain 'xyz';
 # do stuff here
 poptextdomain   # restore old textdomain

=head1 DESCRIPTION

Text::Domain provides an easy way to temporarily change text domains with
C<Locale::gettext|Locale::gettext> without forgetting the previous one.
Two methods are provided -- a functional, stack-based method, and an
object-oriented method.

The two ways of managing domain changes are not inter-operable.  They must
be properly nested or the gettext functions might have a different notion
of what the domain is than your program does.

For example, the following is allowable:

 {
    my $domain = new Text::Domain 'my_program';

    # do stuff

    pushtextdomain 'your_program';

    # do some more stuff

    poptextdomain

    # finish up
 }

The above results in the following calls to C<textdomain>:

 $t1 = textdomain('my_program');
 $t2 = textdomain('your_program');
 textdomain($t2) # restoring 'my_program'
 textdomain($t1) # restoring original state

But the following will probably lead to some confusion somewhere:

 {
    my $domain = new Text::Domain 'my_program';

    # do stuff

    pushtextdomain 'your_program';

    # finish up
 }

 # do some more stuff

 poptextdomain

This results in the following calls to C<textdomain>:

 $t1 = textdomain('my_program');
 $t2 = textdomain('your_program');
 textdomain($t1) # restoring original state
 textdomain($t2) # restoring 'my_program'

=head1 SEE ALSO

L<Locale::gettext>.

=head1 AUTHOR

James G. Smith <jsmith@cpan.org>

=head1 COPYRIGHT

Copyright (C) 2001 Texas A&M University.  All Rights Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

