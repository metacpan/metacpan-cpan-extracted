package Test::Sweet::Types;
BEGIN {
  $Test::Sweet::Types::VERSION = '0.03';
}
# ABSTRACT: types used internally
use strict;
use warnings;

use MooseX::Types -declare => [qw/SuiteClass/];
use MooseX::Types::Moose qw(Object);
use Moose::Util qw(does_role);

subtype SuiteClass, as Object, where {
    return does_role($_->meta, 'Test::Sweet::Meta::Class');
};

1;

__END__
=pod

=head1 NAME

Test::Sweet::Types - types used internally

=head1 VERSION

version 0.03

=head1 AUTHOR

Jonathan Rockway <jrockway@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Jonathan Rockway.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

