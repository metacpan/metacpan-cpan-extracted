package Variable::OnDestruct;

use strict;
use warnings FATAL => 'all';
use Exporter 5.57 'import';
use XSLoader;

##no critic (ProhibitAutomaticExportation)
our @EXPORT = qw/on_destruct/;

our $VERSION = '0.03';

XSLoader::load('Variable::OnDestruct', $VERSION);

1;    # End of Variable::OnDestruct

__END__

=head1 NAME

Variable::OnDestruct - Call a subroutine on destruction of a variable.

=head1 VERSION

Version 0.03

=cut

=head1 SYNOPSIS

    use Variable::OnDestruct;

	on_destruct $var, sub { do_something() };
	on_destruct @array, sub { do_something_else() };
	on_destruct %array, sub { hashes_work_too() };
	on_destruct &$sub, sub { so_do_closures($but_not_normal_subs) };
	on_destruct *$glob, sub { and_even_globs($similar_caveats_as_subs_though) };

=head1 DESCRIPTION

This module allows you to let a function be called when a variable gets destroyed. The destructor will work not only on scalars but also on arrays, hashes, subs and globs. For the latter two you should realize that most of them aren't scoped like normal variables. Subs for example will only work like you expect them to when they are closures.

=head1 FUNCTIONS

This module contains one function, which is exported by default.

=head2 on_destruct $variable, \&sub;

This function adds a destructor to a variable. 

=head1 AUTHOR

Leon Timmermans, C<< <leont at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-devel-ondestruct at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Variable-OnDestruct>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Variable::OnDestruct


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Variable-OnDestruct>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Variable-OnDestruct>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Variable-OnDestruct>

=item * Search CPAN

L<http://search.cpan.org/dist/Variable-OnDestruct>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2009,2010 Leon Timmermans, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
