package WWW::Connpass::Group;
use strict;
use warnings;

sub new {
    my ($class, %args) = @_;
    return bless {
        %args,
    } => $class;
}

sub raw_data { shift->{group} }

# getter
sub id    { shift->{group}->{id}    }
sub title { shift->{group}->{title} }
sub url   { shift->{group}->{url}   }
sub name  { shift->{group}->{name}  }

1;
__END__

=pod

=encoding utf-8

=head1 NAME

WWW::Connpass::Group - TODO

=head1 SYNOPSIS

    use WWW::Connpass::Group;

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
