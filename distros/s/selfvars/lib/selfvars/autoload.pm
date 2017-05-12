package selfvars::autoload;
use 5.005;
use strict;
use selfvars ();

sub import {
    no strict 'refs';
    my $pkg = caller;
    *{"$pkg\::AUTOLOAD"} = \&_autoload;
    shift; unshift @_, 'selfvars';
    goto &selfvars::import;
}

sub _autoload {
    no strict 'vars';
    my $method = $AUTOLOAD;

    my $self = do {
        package DB;
        my $i = 1;
        () = caller($i);
        $DB::args[0];
    } or do {
        require Carp;
        Carp::croak("Undefined subroutine &$AUTOLOAD called");
    };

    $method =~ s/.*:://;
    if (my $code = $self->can($method)) {
        unshift @_, $self;
        goto &$code;
    }
    $self->$method(@_); # ...and let it fail...
}

1;

__END__

=encoding utf8

=head1 NAME

selfvars::autoload - Turn missing_sub(...) into $_[0]->missing_sub(...) implicitly

=head1 SYNOPSIS

    use Mojolicious::Lite; # The raison d'être for this module...

    # Import $self, @args, %opts and %hopts into your package;
    # see "perldoc selfvars" for import options and usage.
    use selfvars::autoload;

    # Normal invocation with two "$self"s
    get '/' => sub {
        my $self = shift;
        $self->render(text => 'Hello World!');
    };

    # It's OK to omit "my $self = shift":
    get '/selfish' => sub {
        $self->render(text => 'Hello World!');
    };

    # It's OK to omit the "$self->" part too!
    get '/selfless' => sub {
        render(text => 'Hello World!');
    };

    # dance!
    app->start;

=head1 DESCRIPTION

This module exports four special variables: C<$self>, C<@args>, C<%opts> and C<%hopts>;
see L<selfvars> for the full description and import options.

In addition to that, this module sets up an C<AUTOLOAD> subroutine in the importing
package, so any calls to missing functions becomes a method call with C<$_[0]> as
the invocant.

If C<$_[0]> is not present, then we raise an C<Undefined subroutine> exception as usual.

The net effect is that we can start writing Mojolicious apps with Dancer syntax. :-)

=head1 DEPENDENCIES

None.

=head1 SEE ALSO

L<selfvars>, L<Mojolicious>, L<Dancer>

=head1 AUTHORS

唐鳳 E<lt>cpan@audreyt.orgE<gt>

=head1 CC0 1.0 Universal

To the extent possible under law, 唐鳳 has waived all copyright and related
or neighboring rights to selfvars.

This work is published from Taiwan.

L<http://creativecommons.org/publicdomain/zero/1.0>

=cut
