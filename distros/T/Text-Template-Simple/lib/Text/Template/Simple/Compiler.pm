package Text::Template::Simple::Compiler;
$Text::Template::Simple::Compiler::VERSION = '0.91';
# the "normal" compiler
use strict;
use warnings;
use Text::Template::Simple::Dummy;

sub compile {
    shift;
    my $code = eval shift;
    return $code;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Text::Template::Simple::Compiler

=head1 VERSION

version 0.91

=head1 SYNOPSIS

Private module.

=head1 DESCRIPTION

Template compiler.

=head1 NAME

Text::Template::Simple::Compiler - Compiler

=head1 METHODS

=head2 compile STRING

=head1 AUTHOR

Burak Gursoy <burak@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2004 by Burak Gursoy.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
