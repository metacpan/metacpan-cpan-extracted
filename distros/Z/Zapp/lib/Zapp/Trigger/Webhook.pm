package Zapp::Trigger::Webhook;
# ABSTRACT: Trigger a plan from a web request

#pod =head1 SYNOPSIS
#pod
#pod =head1 DESCRIPTION
#pod
#pod =head1 CONFIG
#pod
#pod =head1 OUTPUT
#pod
#pod =head1 SEE ALSO
#pod
#pod =cut

use Mojo::Base 'Zapp::Trigger', -signatures;
use Mojo::JSON qw( decode_json );
use Scalar::Util qw( blessed );
use Yancy::Util qw( currym );

sub install( $self, $app, $config={} ) {
    $self->SUPER::install( $app, $config );
    # Set up base webhook handler
    $app->routes->any( '/webhook/:slug' )->to( cb => currym( $self, '_handle_webhook' ) );
}

sub _handle_webhook( $self, $c ) {
    # Find webhook from slug
    my $slug = $c->param( 'slug' );
    my $hook;
    # XXX: Yancy has no JSON query capability...
    for my $h ( $c->yancy->list( zapp_triggers => { type => $self->moniker } ) ) {
        # XXX: Auto-decode JSON fields in Yancy
        my $config = $h->{config} = decode_json( $h->{config} );
        if ( $config->{slug} eq $slug ) {
            $hook = $h;
            last;
        }
    }

    if ( !$hook ) {
        $c->log->warn( sprintf 'No webhook for slug %s', $slug );
        return $c->reply->not_found;
    }

    # Map params to plan input
    my $context = {
        params => $c->req->params->to_hash,
        # XXX: Configure parameter names and types and run them through
        # Type class's process_input
    };

    # Enqueue job
    # XXX: Config for synchronous runs: Run the entire plan before
    # sending the response. Include data from plan in response.
    my $run = $self->enqueue( $hook->{trigger_id}, $context );

    # XXX: Configure response
    $c->rendered( 204 );
}

1;

=pod

=head1 NAME

Zapp::Trigger::Webhook - Trigger a plan from a web request

=head1 VERSION

version 0.005

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 CONFIG

=head1 OUTPUT

=head1 SEE ALSO

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__
@@ config.html.ep
<%
    my $input = stash( 'config' ) // { method => 'POST' };
    $input->{method} //= 'GET';
%>

<div class="form-row">
    <div class="col-auto">
        <label for="method">Method</label>
        <%= select_field method =>
            [ map { $input->{method} eq $_ ? [ $_, $_, selected => 'selected' ] : $_ } qw( GET POST PUT DELETE PATCH ) ],
            class => 'form-control',
        %>
    </div>
    <div class="col">
        <label for="url">Slug</label>
        %= text_field 'slug', value => $input->{slug}, class => 'form-control'
    </div>
</div>

