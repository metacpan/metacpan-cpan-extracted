package WWW::EZTV::Link;
$WWW::EZTV::Link::VERSION = '0.07';
use Moose;
with 'WWW::EZTV::UA';

# ABSTRACT: Episode link

has url => is => 'ro', isa => 'Str', required => 1;


has type => is => 'ro', lazy => 1, builder => '_guess_type';

sub _guess_type {
    my $self = shift;

    if ( $self->url =~ /magnet:/ ) {
        return 'magnet';
    }
    elsif ( $self->url =~ /\.torrent$/ ) {
        return 'torrent';
    }
    elsif ( $self->url =~ /bt-chat.com/ ) {
        return 'torrent-redirect';
    }

    return 'direct';
}
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::EZTV::Link - Episode link

=head1 VERSION

version 0.07

=head1 ATTRIBUTES

=head2 url

Link address

=head2 type

Link type. It can be:

 - magnet
 - torrent
 - torrent-redirect (URL that do html/js redirect to a torrent file)
 - direct

=head1 AUTHOR

Diego Kuperman <diego@freekeylabs.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Diego Kuperman.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
