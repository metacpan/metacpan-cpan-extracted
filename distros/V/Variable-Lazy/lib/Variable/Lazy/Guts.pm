package Variable::Lazy::Guts;

use strict;
use warnings FATAL => 'all';

our $VERSION = '0.03';

use XSLoader;
use Exporter 5.57 qw/import/;
XSLoader::load(__PACKAGE__, $VERSION);

our @EXPORT_OK = qw/lazy/;

1;    # End of Variable::Lazy

__END__

=head1 NAME

Variable::Lazy::Guts - Variables that lazily initialize themselves

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

 lazy $self->{foo}, [], sub { return life_universe_everything(); };
 ...do something else
 $self->{foo}->bar();

This is the module implementing the magic of Variable::Lazy. You should probably not be using this yourselves. No kind of API stability is guaranteed.

=head1 FUNCTIONS

=head2 lazy($variable, $arguments, $subroutine)

Adds lazy magic to a variable. You don't want to assign this immidiately to a new variable, as this will trigger reification. $arguments is a arrayref to the arguments for $subroutine. 

=head1 AUTHOR

Leon Timmermans, C<< <leont at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-variable-lazy at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Variable-Lazy>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Variable::Lazy

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Variable-Lazy>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Variable-Lazy>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Variable-Lazy>

=item * Search CPAN

L<http://search.cpan.org/dist/Variable-Lazy>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2009, 2010 Leon Timmermans, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
