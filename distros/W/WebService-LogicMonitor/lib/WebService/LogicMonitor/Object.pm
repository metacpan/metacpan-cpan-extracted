package WebService::LogicMonitor::Object;

use Moo::Role;

has _lm => (
    is       => 'ro',
    weak_ref => 1,
    default  => sub {

        # this is really a singleton
        WebService::LogicMonitor->new;
    },
);

sub _transform_incoming_keys {
    my ($transform, $args) = @_;

    for my $key (keys %$transform) {
        $args->{$transform->{$key}} = delete $args->{$key}
          if exists $args->{$key};
    }

    return;
}

sub _clean_empty_keys {

    my ($keys, $args) = @_;

    for my $k (@$keys) {
        if (exists $args->{$k} && !$args->{$k}) {
            delete $args->{$k};
        }
    }

    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::LogicMonitor::Object

=head1 VERSION

version 0.211560

=head1 AUTHOR

Ioan Rogers <ioan.rogers@sophos.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Sophos Ltd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
