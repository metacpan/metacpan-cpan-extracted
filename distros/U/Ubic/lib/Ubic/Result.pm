package Ubic::Result;
$Ubic::Result::VERSION = '1.60';
use strict;
use warnings;

# ABSTRACT: common return value for many ubic interfaces


use Ubic::Result::Class;
use Scalar::Util qw(blessed);
use parent qw(Exporter);

our @EXPORT_OK = qw(
    result
);
our %EXPORT_TAGS = (
    all => \@EXPORT_OK,
);

sub result {
    my ($str, $msg) = @_;
    if (blessed $str and $str->isa('Ubic::Result::Class')) {
        return $str;
    }
    return Ubic::Result::Class->new({ type => "$str", msg => $msg });
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Ubic::Result - common return value for many ubic interfaces

=head1 VERSION

version 1.60

=head1 SYNOPSIS

    use Ubic::Result qw(:all);

    sub start {
        ...
        return result('broken', 'permission denied');

        # or:
        return result('running');

        # or:
        return 'already running'; # will be automagically wrapped into result object by Ubic.pm
    }

=head1 FUNCTIONS

=over

=item C<result($type, $optional_message)>

Construct C<Ubic::Result::Class> instance.

=back

=head1 POSSIBLE RESULT TYPES

This is a full list of results which can be recognized by L<Ubic::Result::Class>.

Any other result will be interpreted as I<unknown>.

=over

=item I<running>

=item I<not running>

=item I<already running>

=item I<started>

=item I<already started>

=item I<restarted>

=item I<reloaded>

=item I<stopping>

=item I<not running>

=item I<stopped>

=item I<down>

=item I<starting>

=item I<broken>

=back

=head1 SEE ALSO

L<Ubic::Result::Class> - result instance.

=head1 AUTHOR

Vyacheslav Matyukhin <mmcleric@yandex-team.ru>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Yandex LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
