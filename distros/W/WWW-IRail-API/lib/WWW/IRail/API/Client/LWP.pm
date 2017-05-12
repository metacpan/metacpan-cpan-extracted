package WWW::IRail::API::Client::LWP;
BEGIN {
  $WWW::IRail::API::Client::LWP::AUTHORITY = 'cpan:ESSELENS';
}
BEGIN {
  $WWW::IRail::API::Client::LWP::VERSION = '0.003';
}
use parent 'Exporter';
use strict;
use Carp qw/croak/;
use LWP::UserAgent;

our $VERSION;

sub new {
    my ($proto) = @_;
    my $class = ref $proto || $proto;
    my %attr = ( _client => new LWP::UserAgent);
        
    $attr{_client}->timeout(10);
    $attr{_client}->agent("WWW::IRail::API::Client::LWP/$VERSION ");
                                       
    return bless {%attr}, $class;
}

sub process {
    my $self = shift;
    my $http_req = shift;

    my $response = $self->{_client}->request($http_req);
    $response->is_success or croak 'unable to process request: '.$response->status_line;

    return $response;
}

42;

__END__
=pod

=head1 VERSION

version 0.003

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Tim Esselens <tim.esselens@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Tim Esselens.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

