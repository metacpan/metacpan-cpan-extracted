package Test::Sweet::Exception;
BEGIN {
  $Test::Sweet::Exception::VERSION = '0.03';
}
# ABSTRACT: role representing exceptions thrown by tests
use Moose::Role;
use namespace::autoclean;

has 'error' => (
    is       => 'ro',
    isa      => 'Any',
    required => 1,
);

has [qw/class method/] => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

1;


__END__
=pod

=head1 NAME

Test::Sweet::Exception - role representing exceptions thrown by tests

=head1 VERSION

version 0.03

=head1 AUTHOR

Jonathan Rockway <jrockway@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Jonathan Rockway.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

