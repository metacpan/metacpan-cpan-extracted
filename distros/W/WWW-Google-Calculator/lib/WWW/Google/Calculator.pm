package WWW::Google::Calculator;
use strict;
use warnings;
use base qw/Class::Accessor::Fast/;

use WWW::Mechanize;
use HTML::TokeParser;
use URI;

our $VERSION = '0.07';

__PACKAGE__->mk_accessors(qw/mech error/);

=head1 NAME

WWW::Google::Calculator - Perl interface for Google calculator

=head1 SYNOPSIS

    use WWW::Google::Calculator;
    
    my $calc = WWW::Google::Calculator->new;
    
    print $calc->calc('1+1'); # => 1 + 1 = 2
    print $calc->calc('300kbps in KB/s'); # => 300 kbps = 37.5 kilobytes / second

=head1 DESCRIPTION

This module provide simple interface for Google calculator.

=head1 SEE ALSO

http://www.google.com/help/calculator.html

=head1 METHODS

=head2 new

create new instance

=cut

sub new {
    my $self = shift->SUPER::new(@_);

    $self->mech(
        do {
            my $mech = WWW::Mechanize->new;
            $mech->agent_alias('Linux Mozilla');

            $mech;
        }
    );

    $self;
}

=head2 calc( $query )

calculate $query using by Google and return result.

return undef when something error occurred. (and use $self->error to get last error message)

=cut

sub calc {
    my ( $self, $query ) = @_;

    my $url = URI->new('http://www.google.com/search');
    $url->query_form( q => $query );

    $self->mech->get($url);
    if ($self->mech->success) {
        return $self->parse_html( $self->mech->content );
    }
    else {
        $self->error( 'Page fetching failed: ' . $self->mech->res->status_line );
        return;
    }
}

=head2 parse_html

=cut

sub parse_html {
    my ( $self, $html ) = @_;

    $html =~ s!<sup>(.*?)</sup>!^$1!g;
    $html =~ s!&#215;!*!g;

    my $res;
    my $p = HTML::TokeParser->new( \$html );
    while ( my $token = $p->get_token ) {
        next
          unless ( $token->[0] || '' ) eq 'S'
          && ( $token->[1]        || '' ) eq 'img'
          && ( $token->[2]->{src} || '' ) eq '/images/icons/onebox/calculator-40.gif';

        $p->get_tag('h2');
        $res = $p->get_trimmed_text('/h2');
        return $res; # stop searching here
    }

    $res;
}

=head2 error

return last error

=head1 AUTHOR

Daisuke Murase <typester@cpan.org>

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

1;
