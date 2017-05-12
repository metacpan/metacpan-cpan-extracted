package WWW::Connpass::Place;
use strict;
use warnings;

sub new {
    my $class = shift;
    bless {@_} => $class;
}

sub raw_data { +{%{ shift->{place} }} }

sub edit {
    my $self = shift;
    return $self->{session}->update_place($self, @_);
}

sub id        { shift->{place}->{id} }
sub name      { shift->{place}->{name} }
sub url       { shift->{place}->{url} }
sub address   { shift->{place}->{address} }
sub lat       { shift->{place}->{lat} }
sub lng       { shift->{place}->{lng} }
sub map_image { shift->{place}->{map_image} }

sub refetch {
    my $self = shift;
    return $self->{session}->refetch_place($self);
}

1;
__END__

=pod

=encoding utf-8

=head1 NAME

WWW::Connpass::Place - TODO

=head1 SYNOPSIS

    use WWW::Connpass::Place;

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
