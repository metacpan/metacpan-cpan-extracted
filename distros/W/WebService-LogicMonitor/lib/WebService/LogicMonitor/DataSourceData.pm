package WebService::LogicMonitor::DataSourceData;

# ABSTRACT: Data from LogicMonitor DataSource

use v5.16.3;
use Log::Any '$log';
use Moo;

sub BUILDARGS {
    my ($class, $args) = @_;

    my %transform = (
        dataPoints => 'datapoints',
        values     => '_values',
    );

    for my $key (keys %transform) {
        $args->{$transform{$key}} = delete $args->{$key}
          if exists $args->{$key};
    }

    return $args;
}

has datapoints => (is => 'ro');    # array

has tzoffset   => (is => 'ro');
has _values => (is => 'ro');

has values => (is => 'lazy');

# TODO examine various statistics and charting modules to determine the most
# useful format for this data. e.g. instead of an array use a hash with the
# epoch as keys so they can be sorted by date
sub _build_values {
    my $self = shift;

    require DateTime;

    my %values;
    for my $instance (keys %{$self->_values}) {
        for my $v (@{$self->_values->{$instance}}) {
            my $dt = DateTime->from_epoch(epoch => shift @$v);

            shift @$v;    # get rid of string timestamp

            my %data;
            @data{@{$self->datapoints}} = @$v;
            $values{$instance}->{$dt} = \%data;
        }
    }
    return \%values;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::LogicMonitor::DataSourceData - Data from LogicMonitor DataSource

=head1 VERSION

version 0.153170

=head1 AUTHOR

Ioan Rogers <ioan.rogers@sophos.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Sophos Ltd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
