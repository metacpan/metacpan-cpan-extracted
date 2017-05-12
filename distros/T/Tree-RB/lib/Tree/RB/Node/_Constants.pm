package Tree::RB::Node::_Constants;

use strict;
use Carp;
use vars qw( $VERSION @EXPORT );

$VERSION = '0.3';

require Exporter;
*import = \&Exporter::import;

my @Node_slots;
my @Node_colors;

BEGIN { 
    @Node_slots  = qw(PARENT LEFT RIGHT COLOR KEY VAL); 
    @Node_colors = qw(RED BLACK);
}

@EXPORT = (@Node_colors, map {"_$_"} @Node_slots);

use enum @Node_colors;
use enum @Node_slots;

# enum doesn't allow symbols to start with "_", but we want them 
foreach my $s (@Node_slots) {
    no strict 'refs';
    *{"_$s"} = \&$s;
    delete $Tree::RB::Node::_Constants::{$s};
} 

1; # Magic true value required at end of module
__END__

=head1 NAME

Tree::RB::Node::_Constants - Tree::RB guts


=head1 VERSION

This document describes Tree::RB::Node::_Constants version 0.1


=head1 SYNOPSIS

(internal use only)


=head1 DESCRIPTION

This module exists solely to provide contants for use by Tree::RB and Tree::RB::Node.


=head1 DEPENDENCIES

L<enum>


=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to
C<bug-tree-rb-node-_fields@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Arun Prasad  C<< <arunbear@cpan.org> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007, Arun Prasad C<< <arunbear@cpan.org> >>. All rights reserved.

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
