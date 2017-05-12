package arXiv;
use strict;
our $VERSION = '1.01';
1;
__END__

=head1 NAME

arXiv - Components from the arXiv.org repository

=head1 VERSION

Version 1.01

=head1 SYNOPSIS

Modules in the L<arXiv> (pronouced I<archive> as if the X were a greek I<chi>)
namespace and included in the arXiv CPAN module are components of the 
arXiv.org (L<http://arxiv.org/>) e-print repository which has been written
mostly in Perl since the early 90's (before the web!). 
We offer these components in the hope that they may be useful to others, 
especially those writing software to interact with arXiv. The arXiv codebase 
has evolved over many years, through many versions of Perl (from Perl 3), 
and other system components. It has been refactored in various ways but you 
may find that the factoring and idioms are not always the most up-to-date.

We expect release of components to be a gradual process and they will not 
always be closely related. See the L</DESCRIPTION> section below for details.

This particular module does nothing except provide $VERSION:

 use arXiv;
 print "We have version ".$arXiv::VERSION." of the arXiv modules.\n";

=head1 DESCRIPTION

=head2 L<arXiv::FileGuess>

This is arXiv's central file type detection code. It is used when processing
incoming submissions to determine how to handle an incoming source package and
by the access system when reprocessing for different formats is requests. It 
is used by the L<TeX::AutoTeX> automatic TeX processing engine which will be 
released separately. 
(For anything except arXiv specific handling it is likely better that the 
Unix C<file(1)> command with detailed and regularly updated magic sequences 
be used. Such updates have problems in an archival environment however.

=head1 AUTHOR

Developers at arXiv.org, C<< <simeon at cpan.org> >>

=head1 BUGS

Please report any bugs to C<bug-arxiv at rt.cpan.org>, or through the 
web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=arXiv>. 
We will be notified, and then you will automatically be notified of 
any progress.

=head1 SUPPORT

These modules are released from our production system without any 
commitment to provide support. You can find documentation for this 
module and sub-modules with the perldoc command, e.g.:

 perldoc arXiv

You can also look for information at CPAN's request tracker:

 L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=arXiv>

=head1 ACKNOWLEDGEMENTS

The code for arXiv is the work of many developers and has benefited from
the input of many collaborators and contributors over the years.

=head1 LICENSE AND COPYRIGHT

Copyright 1992-2010 arXiv.org.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
