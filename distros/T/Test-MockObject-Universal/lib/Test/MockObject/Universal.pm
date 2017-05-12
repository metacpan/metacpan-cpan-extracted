package Test::MockObject::Universal;
{
  $Test::MockObject::Universal::VERSION = '0.11';
}
BEGIN {
  $Test::MockObject::Universal::AUTHORITY = 'cpan:TEX';
}
# ABSTRACT: a truly universal mock object

use strict;
use warnings;

sub new {
    my $that  = shift;
    my $class = ref($that) || $that;
    my $self  = {};
    bless $self, $class;
    return $self;
}

# DGR: the whole purpose of this class is to provide autoloading ...
## no critic (ProhibitAutoloading)
sub AUTOLOAD {
    my $self = shift;

    return ();
}
## use critic

sub isa {
    return 1;
}

sub can {
    return 1;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Test::MockObject::Universal - a truly universal mock object

=head1 SYNOPSIS

	my $Dummy = Test::MockObject::Universal::->new();
	$Dummy->can('whatever you want');

=head1 DESCRIPTION

This class provides a very simple mock object that does not inherit from Test::MockObject.

The goal of this module is to be as simple and fast as possible.

If you want more functionality you should probably look at Test::MockObject.

=head1 NAME

Test::MockObject::Universal - A universal MockObject

=head1 METHODS

=head2 isa

Always returns true.

=head2 can

Always returns true.

=head2 AUTOLOAD

AUTOLOAD is provided to always return a empty list.

=head2 new

Constructor. Takes no arguments.

=cut

=head1 AUTHOR

Dominik Schulz <dominik.schulz@gauner.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Dominik Schulz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
