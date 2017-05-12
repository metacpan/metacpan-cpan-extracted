package WWW::Connpass::Event::Participants;
use strict;
use warnings;

use WWW::Connpass::Event::Participant;

sub new {
    my $class = shift;
    bless {@_} => $class;
}

sub label {
    my ($self, $key) = @_;
    return $self->{label}->{$key};
}

sub all {
    my $self = shift;
    return map { WWW::Connpass::Event::Participant->new(%$_) } @{ $self->{rows} };
}

1;
__END__

=pod

=encoding utf-8

=head1 NAME

WWW::Connpass::Event::Participants - TODO

=head1 SYNOPSIS

    use WWW::Connpass::Event::Participants;

=head1 DESCRIPTION

TODO

=head1 SEE ALSO

L<perl>

=head1 LICENSE

Copyright (C) karupanerura.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

karupanerura E<lt>karupa@cpan.orgE<gt>

=cut
