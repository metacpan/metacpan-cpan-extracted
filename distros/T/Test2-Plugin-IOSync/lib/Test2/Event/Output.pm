package Test2::Event::Output;
use strict;
use warnings;

our $VERSION = '0.000005';

use Carp qw/croak/;

BEGIN { require Test2::Event; our @ISA = qw(Test2::Event) }
use Test2::Util::HashBase qw/-stream_name -message -diagnostics/;

sub init {
    croak "'stream_name' is required"
        unless $_[0]->{+STREAM_NAME};

    $_[0]->{+MESSAGE} = 'undef' unless defined $_[0]->{+MESSAGE};
}

sub summary { $_[0]->{+MESSAGE} }

# This will automatically be used when Facets are made stable.
sub facet_data {
    my $self = shift;

    my $out = $self->common_facet_data;

    $out->{info} = [
        {
            tag     => $self->{+STREAM_NAME},
            details => $self->{+MESSAGE},
            debug   => $self->{+DIAGNOSTICS} || 0,
        }
    ];

    return $out;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test2::Event::Output - Event to represent a line of STDOUT or STDERR output.

=head1 DESCRIPTION

This event is used to represent a line of output to either STDERR or STDOUT.

=head1 SOURCE

The source code repository for Test2-Plugin-IOSync can be found at
F<http://github.com/Test-More/Test2-Plugin-IOSync/>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 COPYRIGHT

Copyright 2017 Chad Granum E<lt>exodist@cpan.orgE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See F<http://dev.perl.org/licenses/>

=cut
