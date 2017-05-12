package WWW::Baseball::NPB::Game;

use strict;
use vars qw($VERSION);
$VERSION = 0.03;

sub new {
    my($class, %p) = @_;
    bless {%p}, $class;
}

sub score {
    my($self, $name) = @_;
    return $self->{score}->{$name};
}

no strict 'refs';
for my $meth (qw(home visitor league status stadium)) {
    *$meth = sub { shift->{$meth} };
}

1;
__END__

=head1 NAME

WWW::Baseball::NPB::Game - Japanese baseball game class

=head1 SYNOPSIS

See L<WWW::Baseball::NPB>.

=head1 DESCRIPTION

WWW::Baseball::NPB::Game is a class which rerpresents the actual game
information of Japanese baseball.

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<WWW::Baseball::NPB>

=cut
