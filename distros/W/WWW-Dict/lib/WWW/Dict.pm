package WWW::Dict;
use v5.8.0;
use warnings;
use strict;
our $VERSION = '0.0.1';

use UNIVERSAL::require;


sub new {
    my $class  = shift;
    if ($class eq __PACKAGE__) {
        my $driver = shift;
        my $subclass = __PACKAGE__ . "::$driver";
        $subclass->require or die $@;
        return bless { }, $subclass;
    }

    return bless { }, $class;
}

sub define {
    die ("Sub-class of WWW::Dict must override 'define' method!");
}

1; # Magic true value required at end of module
__END__

=head1 NAME

WWW::Dict - Base class for WWW::Dict::* modules.


=head1 VERSION

This document describes WWW::Dict version 0.0.1

=head1 SYNOPSIS

    use WWW::Dict;
    my $dict = WWW::Dict->new('Zdic');
    my $definition = $dict->define( $word );
    print YAML::Dump( $definition )

=head1 DESCRIPTION

This module is the base class for WWW::Dict::* modules, also a loder
class for them. It doesn't query to any dictionary website itself, but
only dispatch request to a proper subclass.

=head1 INTERFACE

=over 4

=item new( dict_site )

Contructor, as usual, also a loader. You have to pass a string
representing the dict site you want to load. It should be the same as
one of the names under WWW::Dict::* namespace. For example, "Zdic" is
a proper value.

=item define( word )

Query the dictionary website for the definition of word. Return a
hashref with various keys depending on the acutal underlying module.
Please see the document of those modules for it's keys.

(Note: this might be changed to adapt a proper super-set of keys, or
return the definition as an object. However, so far it's still unclear
how complicated it could be, so I just keep it simple for now.)

=back

=head1 DIAGNOSTICS



=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-www-dict@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Kang-min Liu  C<< <gugod@gugod.org> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2006, Kang-min Liu C<< <gugod@gugod.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
