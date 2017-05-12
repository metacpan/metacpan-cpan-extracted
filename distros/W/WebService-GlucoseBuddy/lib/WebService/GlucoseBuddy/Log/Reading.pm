package WebService::GlucoseBuddy::Log::Reading;
{
  $WebService::GlucoseBuddy::Log::Reading::VERSION = '1.113540';
}
# ABSTRACT: A reading from a glucosebuddy log

use Moose 1.24;
use namespace::autoclean 0.13;


has type => (
    is  => 'ro',
    isa => 'Str',
);


has value => (
    is  => 'ro',
    isa => 'Num',
);


has unit => (
    is  => 'ro',
    isa => 'Str',
);

__PACKAGE__->meta->make_immutable;

1;


__END__
=pod

=head1 NAME

WebService::GlucoseBuddy::Log::Reading - A reading from a glucosebuddy log

=head1 VERSION

version 1.113540

=head1 ATTRIBUTES

=head2 type

The type of reading

=head2 value

Teh value of the reading

=head2 unit

The units used for the reading

=head1 AUTHOR

Pete Smith <pete@cubabit.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Pete Smith.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

