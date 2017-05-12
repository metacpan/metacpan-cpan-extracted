package threads::variables::reap::attr;

use strict;
use warnings;

use 5.008;

use Attribute::Lexical ();
use threads::variables::reap;

our $VERSION = '0.06';

sub import
{
    Attribute::Lexical->import("SCALAR:reap" => \&reap);
    Attribute::Lexical->import("ARRAY:reap" => \&reap);
    Attribute::Lexical->import("HASH:reap" => \&reap);
}

=pod

=head1 NAME

threads::variables::reap::attr - reap variables in new threads by attribute

=head1 SYNOPSIS

    use threads::variables::reap::attr;

    # force database handle being reaped in each new thread
    my $dbh : reap = DBI->connect(...);

    # force array being emptied in each new thread
    my @connections : reap = map { DBI->connect( @{$_} ) } @dsnlist;

=head1 DESCRIPTION

C<threads::variables::reap::attr> provides an attribute C<reap> by lexical
scoping using L<Attribute::Lexical> to mark variables to get reaped in new
threads or child processes at compile time.

=head1 AUTHOR

Jens Rehsack, C<< <rehsack at cpan.org> >>

=head1 BUGS

This module provides an attribute C<reap> analogous to L<threads::shared>
provides the C<shared> attribute. Entirely lower cased attribute names are
reserved for future features, so a warning will occure when
C<threads::variables::reap::attr> is used. Attributes should be avoided
where ever possible, so I decided it's not to bad if an additional warning
occures. Use

  BEGIN { $^W = 0; }

if the warning bothers you.

Further you should recognize, that in perl before 5.9.4 the lexical state of
attribute declarations is not available at runtime. See L<Attribute::Lexical/BUGS>
for details.

Please report any bugs or feature requests to C<bug-threads-variables-reap at rt.cpan.org>,
or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=threads-variables-reap>.
I will be notified, and then you'll automatically be notified of progress
on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc threads::variables::reap::attr

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=threads-variables-reap>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/threads-variables-reap>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/threads-variables-reap>

=item * Search CPAN

L<http://search.cpan.org/dist/threads-variables-reap/>

=back

=head1 ACKNOWLEDGEMENTS

Larry Wall for giving us Perl - all our modules provide on his work.
David Golden for his great contribution about Perl and threads on PerlMonks
(see http://www.perlmonks.org/?node_id=483162).
Steffen Mueller for Attribute::Handlers and the helpful explanantion about
attributes there.
Andrew Main, Adam Kennedy and Joshua ben Jore helping me pointing my problem
I'm going to solve with this module.

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Jens Rehsack.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
