package WWW::Connpass::Event::Participant;
use strict;
use warnings;

sub new {
    my $class = shift;
    bless {@_} => $class;
}

sub answer {
    my ($self, $index) = @_;
    return $self->{"answer_$index"};
}

sub waitlist_name { shift->{waitlist_name} }
sub username      { shift->{username}      }
sub nickname      { shift->{nickname}      }
sub comment       { shift->{comment}       }
sub registration  { shift->{registration}  }
sub attendance    { shift->{attendance}    }
sub updated_at    { shift->{updated_at}    }
sub receipt_id    { shift->{receipt_id}    }

1;
__END__

=pod

=encoding utf-8

=head1 NAME

WWW::Connpass::Event::Participant - TODO

=head1 SYNOPSIS

    use WWW::Connpass::Event::Participant;

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
