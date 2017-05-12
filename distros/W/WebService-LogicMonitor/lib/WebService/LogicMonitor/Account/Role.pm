package WebService::LogicMonitor::Account::Role;

# ABSTRACT: An account role

use v5.16.3;
use Moo;

has id          => (is => 'ro');
has description => (is => 'ro');
has name        => (is => 'ro');
has privileges  => (is => 'ro');

sub TO_JSON {
    my $self = shift;

    my %hash = %{$self};

    return \%hash;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::LogicMonitor::Account::Role - An account role

=head1 VERSION

version 0.153170

=head1 AUTHOR

Ioan Rogers <ioan.rogers@sophos.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Sophos Ltd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
