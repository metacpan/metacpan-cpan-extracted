package Test::Mojo::Role::Debug::JSON;
$Test::Mojo::Role::Debug::JSON::VERSION = '0.005';
# ABSTRACT: a JSON extension to Test::Mojo::Role::Debug

use Mojo::Base -role;

with 'Test::Mojo::Role::Debug';

use Carp qw/croak/;

use Mojo::JSON qw{from_json};
use Mojo::JSON::Pointer;
use Test::More ();

# VERSION

sub djson {
    my ( $self, $pointer ) = @_;
    return $self->success ? $self : $self->djsona( $pointer );
}

sub djsona {
    my ( $self, $pointer ) = @_;

    local $@;
    my $json = eval { from_json( $self->tx->res->content->asset->slurp ) };

    Test::More::diag( $@ ) && return $self if $@;
    Test::More::diag( "DEBUG JSON DUMPER:\n",
      Test::More::explain( Mojo::JSON::Pointer->new($json)->get($pointer || '') )
      ) if ref $json;

    return $self;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Mojo::Role::Debug::JSON - a JSON extension to Test::Mojo::Role::Debug

=head1 VERSION

version 0.005

=head1 SYNOPSIS

=head1 DESCRIPTION

When you chain up a bunch of tests and they fail, you really want an easy
way to dump up your markup at a specific point in that chain and see
what's what. This module comes to the rescue.

=head1 NAME

Test::Mojo::Role::Debug::JSON - Test::Mojo role to make debugging test failures easier

This is an extension of L<Test::Mojo::Role::Debug>.
Its usage and syntax are very similar.
Test::Mojo::Role::Debug provides the subs 'd' and 'da',
whereas Test::Mojo::Role::Debug::JSON provides the additional 'djson' and 'djsona'

=for pod_spiffy start code section

    use Test::More;
    
    use Test::Mojo::WithRoles 'Debug::JSON';
    
    my $t = Test::Mojo::WithRoles->new('MyApp');

    $t->get_ok('/')->status_is(200)
        ->d         # Does nothing, since test succeeded - on failure dump content
        ->djson     # Does nothing, since test succeeded - on failure dump content as json
        ->json_like( { status => 'ok' } )
        ->da        # Always dump reply content
        ->djsona    # Always dump the reply content as json
    ;

    done_testing;

=for pod_spiffy end code section

=head1 METHODS

You have all the methods provided by L<Test::Mojo>, L<Test::Mojo::Role::Debug>, plus these:

=head2 C<djson>

    $t->djson;            # print the answer as json
    $t->djson('/status'); # print specific node as json

B<Returns> its invocant.
On failure of previous tests (see L<Mojo::DOM/"success">),
dumps the content output as json. Optionally, takes a JSON pointer to aid subset
larger responses.

=head2 C<djsona>

    $t->djsona;
    $t->djsona('/status');

Same as L</djson>, except it always dumps, regardless of whether the previous
test failed or not.

=head1 SEE ALSO

L<Test::Mojo::Role::Debug::JSON>, L<Test::Mojo> (L<Test::Mojo/"or"> in particular), L<Mojo::DOM>

=for pod_spiffy hr

=head1 REPOSITORY

=for pod_spiffy start github section

Fork this module on GitHub:
L<https://github.com/atoomic/Test-Mojo-Role-Debug-JSON>

=for pod_spiffy end github section

=head1 BUGS

=for pod_spiffy start bugs section

To report bugs or request features, please use
L<https://github.com/atoomic/Test-Mojo-Role-Debug-JSON/issues>

Contrinuous integration coverage
L<https://travis-ci.org/atoomic/Test-Mojo-Role-Debug-JSON>

=for pod_spiffy end bugs section

=head1 AUTHOR

=for pod_spiffy start author section

=for pod_spiffy author atoomic

=for pod_spiffy end author section

=head1 CONTRIBUTORS

=for pod_spiffy start contributors section

=for pod_spiffy author ZOFFIX

=for pod_spiffy end contributors section

=head1 LICENSE

You can use and distribute this module under the same terms as Perl itself.
See the C<LICENSE> file included in this distribution for complete
details.

=head1 AUTHOR

Nicolas R <atoomic@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Nicolas R.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
