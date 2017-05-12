package XT::Manager;

use 5.010;
use strict;
use utf8;

BEGIN {
	$XT::Manager::AUTHORITY = 'cpan:TOBYINK';
	$XT::Manager::VERSION   = '0.006';

	*allow_any_unambiguous_abbrev = sub { 1 };
}

use App::Cmd::Setup -app;

__PACKAGE__
__END__

=pod

=encoding utf-8

=head1 NAME

XT::Manager - manage a collection of author tests shared between multiple projects

=head1 SYNOPSIS

 perl-xt-manager pull --all

=head1 DESCRIPTION

XT::Manager is a tool for sharing author test cases between multiple Perl
projects. The command line tool C<< perl-xt-manager >> is the primary way
of using it.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=XT-Manager>.

=head1 SEE ALSO

L<XT::Manager::API>, L<XT::Util>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012-2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

