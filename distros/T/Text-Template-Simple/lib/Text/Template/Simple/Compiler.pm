package Text::Template::Simple::Compiler;
# the "normal" compiler
use strict;
use warnings;
use Text::Template::Simple::Dummy;

our $VERSION = '0.90';

sub compile {
    shift;
    my $code = eval shift;
    return $code;
}

1;

__END__

=head1 NAME

Text::Template::Simple::Compiler - Compiler

=head1 SYNOPSIS

Private module.

=head1 METHODS

=head2 compile STRING

=head1 DESCRIPTION

This document describes version C<0.90> of C<Text::Template::Simple::Compiler>
released on C<5 July 2016>.

Template compiler.

=head1 AUTHOR

Burak Gursoy <burak@cpan.org>.

=head1 COPYRIGHT

Copyright 2004 - 2016 Burak Gursoy. All rights reserved.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.24.0 or,
at your option, any later version of Perl 5 you may have available.
=cut
