package WebService::Bonusly::Service;
$WebService::Bonusly::Service::VERSION = '1.001';
use v5.14;
use Moose;
use JSON;
use Try::Tiny;
use URI::Escape;

# ABSTRACT: A utility class for WebService::Bonusly services


has ws => (
    is          => 'ro',
    isa         => 'WebService::Bonusly',
    required    => 1,
    weak_ref    => 1,
    handles     => [ qw( token base_url ua _json_flags print_debug ) ],
);

sub _perform_action {
    my ($self, $method, $path_info, $params, $tokenless) = @_;
    my %clean = %$params;

    my $res;

    my $path = $self->base_url . $path_info;
    $path =~ s/:(\w+)/delete $clean{$1}/ge;
    if ($method eq 'GET' || $method eq 'DELETE') {
        $path .= '?';
        $path .= 'access_token=' . $self->token unless $tokenless;
        for my $k (sort keys %clean) {
            my $v = $clean{$k};
            $path .= '&' . uri_escape($k) . '=' . uri_escape($v);
        }

        $self->print_debug("SEND>> $method $path");
        if ($method eq 'GET') {
            $res = $self->ua->get($path);
        }
        else {
            $res = $self->ua->delete($path);
        }
    }
    elsif ($method eq 'POST' || $method eq 'PUT') {
        $path .= '?access_token=' . $self->token unless $tokenless;
        my $content = to_json(\%clean, $self->_json_flags);

        $self->print_debug("SEND>> $method $path");
        $self->print_debug("SEND>> Content-Type: application/json");
        $self->print_debug("SEND>> $content");
        if ($method eq 'POST') {
            $res = $self->ua->post($path, 'Content-Type' => 'application/json', Content => $content);
        }
        else {
            $res = $self->ua->put($path, 'Content-Type' => 'application/json', Content => $content);
        }
    }
    else {
        die "Bad Method " . $method;
    }

    $self->print_debug("RECV>> ", $res->content);

    try {
        from_json($res->content);
    } catch {
        +{
            success => JSON::false,
            message => $res->message,
            content => $res->content,
            status => $res->code,
            response_object => $res,
        }
    };
}

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::Bonusly::Service - A utility class for WebService::Bonusly services

=head1 VERSION

version 1.001

=head1 DESCRIPTION

This is a utility class used by the Bonus.ly service classes.

See L<WebService::Bonusly>.

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
