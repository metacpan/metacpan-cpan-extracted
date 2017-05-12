#! /usr/bin/env perl

use strict;
use 5.012;
use Text::ResusciAnneparser;

my $parser = Text::ResusciAnneparser->new(infile => 'certs.xml');

# PODNAME: basic.pl
# ABSTRACT: First test script for the Text::ResusciAnne parser module

__END__

=pod

=head1 NAME

basic.pl - First test script for the Text::ResusciAnne parser module

=head1 VERSION

version 0.03

=head1 AUTHOR

Lieven Hollevoet <hollie@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Lieven Hollevoet.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
