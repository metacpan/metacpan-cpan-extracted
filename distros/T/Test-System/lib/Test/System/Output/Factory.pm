#
# Test::System::Output::Factory
#
# Author(s): Pablo Fischer (pfischer@cpan.org)
# Created: 11/08/2009 15:20:11 PST 15:20:11
package Test::System::Output::Factory;

=head1 NAME

Test::System::Output::Factory - Factory class for building TAP formatters

=head1 DESCRIPTION

This module is part of L<Test::System> and is used as a factory class for
the TAP formats.

Usually this module gets called directly by L<Test::System> but if you want
to create the instance, modify it and then pass it to L<Test::System>.

=head1 SYNOPSIS

    use Test::System::Output::Factory;

    my $formatter = Test::System::Output::Factory->new('html');
    $formatter->do_your_stuff();

=head1 Available formatters

=over 4

=item * C<html>

Returns a L<TAP::Formatter::HTML> instance

=item * C<console>

Returns a L<TAP::Formatter::Console> instance

=back

=cut

use strict;
use warnings;
use Class::Factory;
use base qw(Class::Factory);

our $VERSION = '0.03';

sub new {
    my ($pkg, $type, @params) = @_;
    my $class = $pkg->get_factory_class($type);
    return undef unless ($class);
    my $self = "$class"->new(@params);
    return $self;
}

__PACKAGE__->register_factory_type(html => 'TAP::Formatter::HTML');
__PACKAGE__->register_factory_type(console => 'TAP::Formatter::Console');

=head1 AUTHOR
 
Pablo Fischer, pablo@pablo.com.mx.
 

=head1 COPYRIGHT
 
Copyright (C) 2009 by Pablo Fischer
 
This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;

