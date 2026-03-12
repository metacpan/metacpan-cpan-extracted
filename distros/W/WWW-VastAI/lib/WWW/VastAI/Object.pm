package WWW::VastAI::Object;
our $VERSION = '0.001';
# ABSTRACT: Base entity wrapper for Vast.ai API resources

use Moo;

has _client => (
    is       => 'ro',
    required => 1,
    weak_ref => 1,
    init_arg => 'client',
);

has data => (
    is       => 'rw',
    required => 1,
);

sub id  { shift->data->{id} }
sub raw { shift->data }

sub _replace_data {
    my ($self, $data) = @_;
    $self->data($data);
    return $self;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::VastAI::Object - Base entity wrapper for Vast.ai API resources

=head1 VERSION

version 0.001

=head1 DESCRIPTION

L<WWW::VastAI::Object> stores the raw decoded API payload for a resource object
and keeps a weak reference back to the owning L<WWW::VastAI> client. Resource
classes such as L<WWW::VastAI::Offer> and L<WWW::VastAI::Instance> inherit from
this class.

=head1 METHODS

=head2 id

    my $id = $object->id;

Returns the resource identifier from the underlying payload.

=head2 raw

    my $payload = $object->raw;

Returns the raw decoded payload hashref for the resource.

=head1 SEE ALSO

L<WWW::VastAI>, L<WWW::VastAI::Offer>, L<WWW::VastAI::Instance>

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-www-vastai/issues>.

=head2 IRC

Join C<#kubernetes> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
