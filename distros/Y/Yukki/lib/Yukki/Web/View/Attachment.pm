package Yukki::Web::View::Attachment;
{
  $Yukki::Web::View::Attachment::VERSION = '0.140290';
}
use 5.12.1;
use Moose;

extends 'Yukki::Web::View';

# ABSTRACT: View for attachment forms


sub rename {
    my ($self, $ctx, $vars) = @_;
    my $file = $vars->{file};

    $ctx->response->page_title($vars->{title});

    return $self->render_page(
        template => 'attachment/rename.html',
        context  => $ctx,
        vars     => {
            '#yukkiname'           => $vars->{page},
            '#yukkiname_new@value' => $vars->{page},
        },
    );
}


sub remove {
    my ($self, $ctx, $vars) = @_;
    my $file = $vars->{file};

    $ctx->response->page_title($vars->{title});

    return $self->render_page(
        template => 'attachment/remove.html',
        context  => $ctx,
        vars     => {
            '.yukkiname'          => $vars->{page},
            '#cancel_remove@href' => $vars->{return_link},
        },
    );
}

__END__

=pod

=head1 NAME

Yukki::Web::View::Attachment - View for attachment forms

=head1 VERSION

version 0.140290

=head1 DESCRIPTION

Handles the display of attachment forms.

=head1 METHODS

=head2 rename

Show the rename form for attachments.

=head2 remove

Show the remove form for attachmensts.

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
