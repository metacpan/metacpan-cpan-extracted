package Trac::RPC::Exception;
{
  $Trac::RPC::Exception::VERSION = '1.0.0';
}



use strict;
use warnings;

use Exception::Class (
    'TracException',
    'TracExceptionConnectionRefused' => { isa => 'TracException' },
    'TracExceptionNotFound' => { isa => 'TracException' },
    'TracExceptionAuthProblem' => { isa => 'TracException' },
    'TracExceptionUnknownMethod' => { isa => 'TracException' },
    'TracExceptionNoWikiPage' => { isa => 'TracException' },
);

1;

__END__

=pod

=head1 NAME

Trac::RPC::Exception

=head1 VERSION

version 1.0.0

=head1 SYNOPSIS

=head1 DESCRIPTION

=encoding UTF-8

=head1 NAME

Trac::RPC::Exception - exceptions for Trac::RPC classes

=head1 AUTHOR

Ivan Bessarabov <ivan@bessarabov.ru>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Ivan Bessarabov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
