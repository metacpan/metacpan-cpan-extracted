package WWW::Connpass::Event::Waitlist;
use strict;
use warnings;

sub _method { die 'this is abstruct method' }

sub new {
    my ($class, %args) = @_;
    die "$class is abstract class" if $class eq __PACKAGE__;

    # assertion
    if (exists $args{method}) {
        $args{method} eq $class->_method
            or die "Invalid method: $args{method}";
    }
    else {
        $args{method} = $class->_method;
    }

    return bless \%args => $class;
}

sub inflate {
    my ($class, %args) = @_;
    $class .= '::'.ucfirst $args{method};
    Module::Load::load($class);
    return $class->new(%args);
}

sub raw_data { +{%{$_[0]}} }

sub is_new { not exists shift->{id} }

sub cancelled_count          { shift->{cancelled_count}           }
sub id                       { shift->{id}                        }
sub join_fee                 { shift->{join_fee}                  }
sub lottery_count            { shift->{lottery_count}             }
sub max_participants         { shift->{max_participants}          }
sub method                   { shift->{method}                    }
sub name                     { shift->{name}                      }
sub participants_count       { shift->{participants_count}        }
sub place_fee                { shift->{place_fee}                 }
sub total_participants_count { shift->{total_participants_count}  }
sub waitlist_count           { shift->{waitlist_count}            }

1;
__END__

=pod

=encoding utf-8

=head1 NAME

WWW::Connpass::Event::Waitlist - TODO

=head1 SYNOPSIS

    use WWW::Connpass::Event::Waitlist;

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
