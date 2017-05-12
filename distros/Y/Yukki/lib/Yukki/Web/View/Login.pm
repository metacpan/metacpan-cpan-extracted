package Yukki::Web::View::Login;
{
  $Yukki::Web::View::Login::VERSION = '0.140290';
}
use Moose;

extends 'Yukki::Web::View';

# ABSTRACT: show a login form


sub page {
    my ($self, $ctx) = @_;

    return $self->render_page(
        template   => 'login/page.html', 
        context    => $ctx,
        vars       => {
            'form@action' => $ctx->rebase_url('login/submit'),
        },
    );
}

1;

__END__

=pod

=head1 NAME

Yukki::Web::View::Login - show a login form

=head1 VERSION

version 0.140290

=head1 DESCRIPTION

Renders the login form.

=head1 METHODS

=head2 page

Renders the login page.

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
