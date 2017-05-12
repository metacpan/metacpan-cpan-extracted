use 5.008001;
use strict;
use warnings;

package U;
# ABSTRACT: UNIVERSAL::new alias for the command line
our $VERSION = '0.001'; # VERSION

use UNIVERSAL::new;

1;


# vim: ts=4 sts=4 sw=4 et:

__END__

=pod

=encoding utf-8

=head1 NAME

U - UNIVERSAL::new alias for the command line

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  $ perl -MU -we 'HTTP::Tiny->new->mirror(...)'

=head1 DESCRIPTION

The L<U> module loads L<UNIVERSAL::new>.  That's it.

=for Pod::Coverage method_names_here

=head1 AUTHOR

David Golden <dagolden@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by David Golden.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
