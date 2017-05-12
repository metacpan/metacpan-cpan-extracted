package WWW::Connpass::User;
use strict;
use warnings;

sub new {
    my ($class, %args) = @_;
    return bless {
        %args,
    } => $class;
}

sub raw_data { shift->{user} }

# getter
sub id             { shift->{user}->{id}             }
sub username       { shift->{user}->{username}       }
sub display_name   { shift->{user}->{display_name}   }
sub avatar         { shift->{user}->{avatar}         }
sub is_deactivated { shift->{user}->{is_deactivated} }
sub profile_url    { shift->{user}->{profile_url}    }

1;
__END__

=pod

=encoding utf-8

=head1 NAME

WWW::Connpass::User - TODO

=head1 SYNOPSIS

    use WWW::Connpass::User;

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
