package WebService::Raygun::Message::Request::QueryString;
$WebService::Raygun::Message::Request::QueryString::VERSION = '0.030';
use Mouse;

=head1 NAME

WebService::Raygun::Message::Request::QueryString - Represent the I<QueryString> data in a raygun request.

=head1 SYNOPSIS

    use WebService::Raygun::Message::Request::QueryString;
    my $user = WebService::Raygun::Request::QueryString->new(
        params => { }
    );


=head1 DESCRIPTION

Encode a query string as a hash object.

=head1 INTERFACE

=cut


use Mouse::Util::TypeConstraints;

subtype 'RaygunQueryString' => as 'Object' => where {
    $_->isa('WebService::Raygun::Message::Request::QueryString');
};

coerce 'RaygunQueryString' => from 'Str' => via {
    my $params = {};
    my @pairs = split/&/, $_;
    foreach my $pair (@pairs) {
        my ($key, $value) = split/=/, $pair;
        $params->{$key} = $value;
    }
    return WebService::Raygun::Message::Request::QueryString->new(params => $params);
} =>  from 'HashRef' => via {
    return WebService::Raygun::Message::Request::QueryString->new(params => $_);
};
no Mouse::Util::TypeConstraints;

has params => (
    is	    => 'rw',
    isa 	=> 'HashRef',
    default => sub {
        return {};
    },
);



=head2 prepare_raygun

Return the data structure that will be sent to raygun.io

=cut

sub prepare_raygun {
    my $self = shift;
    return $self->params;
}

=head1 DEPENDENCIES


=head1 SEE ALSO

=cut

__PACKAGE__->meta->make_immutable();

1;

__END__
