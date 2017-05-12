package WWW::OpenSearch::Url;

use strict;
use warnings;

use base qw( Class::Accessor::Fast );

use URI::Template;

__PACKAGE__->mk_accessors( qw( type template method params ns ) );

=head1 NAME

WWW::OpenSearch::Url - Object to represent a target URL

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 CONSTRUCTOR

=head2 new( [%options] )

=head1 METHODS

=head2 prepare_query( [ \%params ] )

=head1 ACCESSORS

=over 4

=item * type

=item * template

=item * method

=item * params

=item * ns

=back

=head1 AUTHOR

=over 4

=item * Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

=item * Brian Cassidy E<lt>bricas@cpan.orgE<gt>

=back

=head1 COPYRIGHT AND LICENSE

Copyright 2005-2013 by Tatsuhiko Miyagawa and Brian Cassidy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

sub new {
    my ( $class, %options ) = @_;

    $options{ method } ||= 'GET';
    $options{ template } = URI::Template->new( $options{ template } );

    my $self = $class->SUPER::new( \%options );

    return $self;
}

sub prepare_query {
    my ( $self, $params ) = @_;
    my $tmpl = $self->template;

    for ( qw( startIndex startPage ) ) {
        $params->{ $_ } = 1 if !defined $params->{ $_ };
    }
    $params->{ language }       ||= '*';
    $params->{ outputEncoding } ||= 'UTF-8';
    $params->{ inputEncoding }  ||= 'UTF-8';

    # fill the uri template
    my $url = $tmpl->process( %$params );

    # attempt to handle POST
    if ( $self->method eq 'post' ) {
        my $post = $self->params;
        for my $key ( keys %$post ) {
            $post->{ $key } =~ s/{(.+)}/$params->{ $1 } || ''/eg;
        }

        return $url, [ %$post ];
    }

    return $url;
}

1;
