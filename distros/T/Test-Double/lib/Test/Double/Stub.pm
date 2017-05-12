package Test::Double::Stub;

use strict;
use warnings;
use Class::Monadic ();

our $AUTOLOAD;
sub AUTOLOAD {
    my $name = [ split /::/, $AUTOLOAD ]->[-1];
    return if $name eq 'DESTROY';

    my $self = shift;
    my $stub = shift || sub {};
    my $func = ref($stub) eq 'CODE' ? $stub : sub { $stub };
    Class::Monadic->initialize($$self)->add_methods($name => $func);

    return $self;
}

1;
__END__

=encoding utf-8

=for stopwords

=head1 NAME

Test::Double::Stub - Stub object

=head1 AUTHOR

NAKAGAWA Masaki E<lt>masaki@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Test::Double>

=cut
