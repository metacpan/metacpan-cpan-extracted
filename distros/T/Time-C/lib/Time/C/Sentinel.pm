use strict;
use warnings;
package Time::C::Sentinel;
$Time::C::Sentinel::VERSION = '0.024';
use Carp qw/ croak /;
use Exporter qw/ import /;

our @EXPORT = qw/ sentinel /;

sub sentinel :lvalue {
    my %args = @_;

    my $value = $args{value};
    my $set   = $args{set};

    croak "sentinel: no setter given" unless defined $set;

    tie my $ret, __PACKAGE__, $value, $set;

    return $ret;
}

sub TIESCALAR {
    my ($c, $val, $set) = @_;

    bless { value => $val, set => $set }, $c;
}

sub STORE {
    my ($o, $new) = @_;

    $o->{value} = $o->{set}->($new);
}

sub FETCH { shift->{value}; }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Time::C::Sentinel

=head1 VERSION

version 0.024

=head1 AUTHOR

Andreas Guldstrand <andreas.guldstrand@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Andreas Guldstrand.

This is free software, licensed under:

  The MIT (X11) License

=cut
