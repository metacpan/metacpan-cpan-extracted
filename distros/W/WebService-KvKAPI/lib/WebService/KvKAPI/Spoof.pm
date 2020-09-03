package WebService::KvKAPI::Spoof;
our $VERSION = '0.011';
use Moo;

# ABSTRACT: Enable spoof mode on the KvK API

extends 'WebService::KvKAPI';

around '_search' =>  sub {
    my ($orig, $self, $params) = @_;
    return $self->api_call('CompaniesTest_GetCompaniesBasicV2', $params);
};

around '_profile' =>  sub {
    my ($orig, $self, $params) = @_;
    return $self->api_call('CompaniesTest_GetCompaniesExtendedV2', $params);
};

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::KvKAPI::Spoof - Enable spoof mode on the KvK API

=head1 VERSION

version 0.011

=head1 SYNOPSIS

    use WebService::KvKAPI::Spoof;
    my $api = WebService::KvKAPI::Spoof->new(
        api_key => 'foo',
    );

    $api->search();
    $api->search_all();
    $api->search_max();

=head1 DESCRIPTION

Implements the spoof mode by the KvK API.

=head1 METHODS

See all the methods provided by L<WebService::KvKAPI>.

=head1 SEE ALSO

L<WebService::KvKAPI>

=head1 AUTHOR

Wesley Schwengle <wesley@mintlab.nl>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Mintlab / Zaaksysteem.nl.

This is free software, licensed under:

  The European Union Public License (EUPL) v1.1

=cut
