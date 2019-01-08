package Test::Mojo::Role::StopOnFail;
# ABSTRACT: Stop Mojolicious tests after first failure.

use Mojo::Base -role;
use Test::More;

my @methods = qw(
    content_is
    content_isnt
    content_like
    content_type_is
    content_type_isnt
    content_type_like
    content_type_unlike
    content_unlike
    delete_ok
    element_count_is
    element_exists
    element_exists_not
    finish_ok
    finished_ok
    get_ok
    head_ok
    header_is
    header_isnt
    header_like
    header_unlike
    json_has
    json_hasnt
    json_is
    json_like
    json_message_has
    json_message_hasnt
    json_message_is
    json_message_like
    json_message_unlike
    json_unlike
    message_is
    message_isnt
    message_like
    message_ok
    message_unlike
    options_ok
    patch_ok
    post_ok
    put_ok
    request_ok
    send_ok
    status_is
    status_isnt
    text_is
    text_isnt
    text_like
    text_unlike
    websocket_ok
);

around @methods => sub {
    my $orig = shift;

    my $t = $orig->(@_);
    $t->success or Test::More::BAIL_OUT("Test failed.  BAIL OUT!.\n");
    return $t;
};

1;

__END__

=pod

=encoding utf8

=head1 NAME

Test::Mojo::Role::StopOnFail - Stop Mojolicious tests after first failure

=head1 VERSION

v0.001

=head1 SYNOPSIS

  my $t = Test::Mojo->with_roles('+StopOnFail')->new('MyApp');

  $t->get_ok('/')->status_is(200);

=head1 DESCRIPTION

When you have many tests, you may want to stop the test suite after the first failure. This modules does a
C<Test::More::BAIL_OUT>, like the C<die_on_fail> on L<Test::Most> behavior.

=head1 CAVEATS

The C<Test::Mojo::or()> function only run when C<$t-E<gt>success> is I<FALSE>. Unconsciously, this module removed the
purpose of this function, after all, a C<BAIL_OUT> would be threw before.

=head1 SEE ALSO

=over

=item * L<Mojolicious>

=item * L<Mojo::Role>

=item * L<Test::Mojo>

=item * L<Test::More>

=back

=head1 LICENSE

This software is copyright (c) 2019 by Junior Moraes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
