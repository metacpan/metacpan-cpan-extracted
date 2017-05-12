package WWW::Connpass::Event::Questionnaire;
use strict;
use warnings;

sub new {
    my $class = shift;
    bless {@_} => $class;
}

sub raw_data { +{%{shift->{questionnaire}}} }

sub is_new { not defined shift->id }

sub id    { shift->{questionnaire}->{id}    }
sub event { shift->{questionnaire}->{event} }
sub questions {
    my $self = shift;
    my $questions = $self->{questions} ||= [
        map { WWW::Connpass::Event::Question->inflate(%$_) }
        @{ $self->{questionnaire}->{questions} }
    ];
    return @$questions;
}

sub add_questions {
    my $self = shift;
    $self->update_questions($self->questions, @_);
}

sub update_questions {
    my $self = shift;
    $self->{session}->update_questionnaire($self, @_);
}

1;
__END__

=pod

=encoding utf-8

=head1 NAME

WWW::Connpass::Event::Questionnaire - TODO

=head1 SYNOPSIS

    use WWW::Connpass::Event::Questionnaire;

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
