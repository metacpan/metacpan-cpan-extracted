package WWW::Connpass;
use 5.012000;
use strict;
use warnings;

our $VERSION = "0.04";

use WWW::Connpass::Session;

sub new {
    my $class = shift;

    my $user_agent = "$class/".$class->VERSION;
    return bless {
        user_agent => $user_agent,
        interval   => 1,
        @_,
    } => $class;
}

sub login {
    my ($self, $user, $pass) = @_;
    return WWW::Connpass::Session->new($user, $pass, $self);
}

1;
__END__

=encoding utf-8

=for stopwords connpass(R)

=head1 NAME

WWW::Connpass - browser for connpass(R)

=head1 SYNOPSIS

    use WWW::Connpass;

    my $client = WWW::Connpass->new;
    my $session = $client->login('username', 'password');
    my @events = $session->fetch_organized_events();
    for my $event (@events) {
        # ...
    }

    my $event = $session->new_event(title => '');
    $event = $event->edit(
        ...
    );

=head1 DESCRIPTION

WWW::Connpass is browser for L<http://connpass.com/>.

=head1 LICENSE

Copyright (C) karupanerura.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

karupanerura E<lt>karupa@cpan.orgE<gt>

=cut

