package tainting;

use strict;
use warnings;

use Taint::Runtime qw(taint_env taint_start taint_stop);

our $VERSION = '0.01'; # VERSION

my $env_tainted;

sub import {
    my $self = shift;

    taint_start();
    taint_env() unless $env_tainted++;
}

sub unimport {
    my $self = shift;

    taint_stop();
}

1;
#ABSTRACT: Enable taint mode lexically


__END__
=pod

=head1 NAME

tainting - Enable taint mode lexically

=head1 VERSION

version 0.01

=head1 SYNOPSIS

To enable tainting in a lexical block:

 {
     use tainting;
     # tainting is enabled
 }
 # tainting is disabled again

To disable tainting in a lexical block:

 use tainting;
 {
     no tainting;
     # tainting is disabled
 }
 # tainting is enabled again

=head1 DESCRIPTION

This module provides a simpler interface to L<Taint::Runtime>. The idea is so
that there is no functions or variables to import. Just C<use> or C<no>, like
L<warnings> or L<strict>. Tainting of C<%ENV> will be done one time
automatically the first time this module is used.

Please (PLEASE) read Taint::Runtime's documentation first about the pro's and
con's of enabling/disabling tainting at runtime. TL;DR: Use -T if you can.

=for Pod::Coverage ^(import|unimport)$

=head1 SEE ALSO

L<Taint::Runtime>

=head1 AUTHOR

Steven Haryanto <stevenharyanto@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Steven Haryanto.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

