package WWW::Connpass::Event;
use strict;
use warnings;

use WWW::Connpass::Event::Waitlist;

sub new {
    my ($class, %args) = @_;
    return bless {
        %args,
        waitlist_count => [],
    } => $class;
}

sub edit {
    my ($self, %diff) = @_;
    $self->{session}->update_event($self, \%diff);
}

sub raw_data { shift->{event} }

# getter
sub cancel_policy                     { shift->{event}->{cancel_policy}                     }
sub cancelled_count                   { shift->{event}->{cancelled_count}                   }
sub contact_details                   { shift->{event}->{contact_details}                   }
sub description                       { shift->{event}->{description}                       }
sub description_input                 { shift->{event}->{description_input}                 }
sub end_datetime                      { shift->{event}->{end_datetime}                      }
sub event_type                        { shift->{event}->{event_type}                        }
sub hashtag                           { shift->{event}->{hashtag}                           }
sub id                                { shift->{event}->{id}                                }
sub image                             { shift->{event}->{image}                             }
sub issue_ticket                      { shift->{event}->{issue_ticket}                      }
sub lottery_publish_date              { shift->{event}->{lottery_publish_date}              }
sub lottery_publish_notification_sent { shift->{event}->{lottery_publish_notification_sent} }
sub max_num                           { shift->{event}->{max_num}                           }
sub open_end_datetime                 { shift->{event}->{open_end_datetime}                 }
sub open_start_datetime               { shift->{event}->{open_start_datetime}               }
sub owner_text                        { shift->{event}->{owner_text}                        }
sub participants_count                { shift->{event}->{participants_count}                }
sub participation_types               { shift->{event}->{participation_types}               }
sub paypal_email                      { shift->{event}->{paypal_email}                      }
sub place                             { shift->{event}->{place}                             }
sub presenter_title                   { shift->{event}->{presenter_title}                   }
sub public_url                        { shift->{event}->{public_url}                        }
sub publish_datetime                  { shift->{event}->{publish_datetime}                  }
sub series                            { shift->{event}->{series}                            }
sub start_datetime                    { shift->{event}->{start_datetime}                    }
sub status                            { shift->{event}->{status}                            }
sub sub_title                         { shift->{event}->{sub_title}                         }
sub title                             { shift->{event}->{title}                             }

sub waitlist_count {
    my $self = shift;
    my $waitlist_count = $self->{waitlist_count} ||= [
        map { WWW::Connpass::Event::Waitlist->new($_) } @{ $self->{event}->{waitlist_count} }
    ];
    return @$waitlist_count;
}

sub owners {
    my $self = shift;
    my $owners = $self->{owners} ||= [ $self->{session}->fetch_event_owners($self) ];
    return @$owners;
}

sub update_waitlist_count {
    my $self = shift;
    $self->{session}->update_waitlist_count($self, @_);
}

sub set_place {
    my ($self, $place) = @_;
    $self->edit(place => $place->id);
}

sub set_group {
    my ($self, $group) = @_;
    $self->edit(series => $group->id);
}

sub add_owner {
    my ($self, $user) = @_;
    $self->{session}->add_owner_to_event($self, $user);
}

sub questionnaire {
    my $self = shift;
    return $self->{questionnaire} ||= $self->{session}->fetch_questionnaire_by_event($self);
}

sub participants {
    my $self = shift;
    return $self->{participants} ||= $self->{session}->fetch_participants_info($self);
}

sub refetch {
    my $self = shift;
    $self->{session}->refetch_event($self);
}

1;
__END__

=pod

=encoding utf-8

=head1 NAME

WWW::Connpass::Event - TODO

=head1 SYNOPSIS

    use WWW::Connpass::Event;

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
