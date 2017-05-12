package Yukki::Error;
{
  $Yukki::Error::VERSION = '0.140290';
}
use Moose;

with qw( Throwable StackTrace::Auto HTTP::Throwable MooseX::Traits );

use Sub::Exporter -setup => {
    exports => {
        http_throw     => \&http_throw,
        http_exception => \&http_exception,
    },
};

use Yukki::Web::View;

# ABSTRACT: Yukki's exception class


{
    package Yukki::Error::Fixup;
{
  $Yukki::Error::Fixup::VERSION = '0.140290';
}
    use Moose::Role;

    around as_psgi => sub {
        my $next = shift; # not used
        my ($self, $env) = @_;
        my $body    = $self->body($env);
        my $headers = $self->build_headers($body, $env);
        [ $self->status_code, $headers, [ defined $body ? $body : () ] ];
    };
}


sub http_exception {
    my ($class, $name, $args) = @_;

    return sub {
        my ($message, $params) = @_;
        $params //= {};

        my $status = 'InternalServerError';
           $status = $params->{status} if defined $params->{status};

        return $class->with_traits(
            "HTTP::Throwable::Role::Status::$status",
            'Yukki::Error::Fixup',
        )->new($message, $params);
    };
}


sub http_throw {
    my ($class, $name, $args) = @_;

    my $new_exception = http_exception($class, $name, $args);

    return sub {
        my $self = $new_exception->(@_);
        $self->throw;
    };
}


has status => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
    default     => 'InternalServerError',
);


has '+status_code' => ( lazy => 1 );
has '+reason'      => ( lazy => 1 );


sub BUILDARGS {
    my ($class, $message, $args) = @_;
    $args //= {};

    return {
        %$args,
        message => $message,
    };
}


sub body {
    my ($self, $env) = @_;

    my $app  = $env->{'yukki.app'};
    my $view = Yukki::Web::View->new(app => $app);
    my $ctx  = Yukki::Web::Context->new(env => $env);

    $ctx->response->page_title($self->reason);

    return $view->render_page(
        template => 'error.html',
        context  => $ctx,
        vars     => {
            '#error-page' => $self->message,
        },
    );
}


sub body_headers {
    my ($self, $body) = @_;

    return [
        'Content-type'   => 'text/html',
        'Content-length' => length $body,
    ];
}


sub as_string {
    my $self = shift;
    return $self->message;
}

1;

__END__

=pod

=head1 NAME

Yukki::Error - Yukki's exception class

=head1 VERSION

version 0.140290

=head1 SYNOPSIS

  Yukki::Error->throw("Something really bad.", { ... });

=head1 DESCRIPTION

If you look at L<Throwable::Error>, you know what this is. Same thing, different
name.

=head1 EXPORTS

=head2 http_exception

  my $error = http_exception('message', {
      status           => 'InternalServerError',
      show_stask_trace => 0,
  });

Creates a new exception object. Calls the constructor for L<Yukki:Error> and applied the L<HTTP::Throwable> status role needed (prior to construction actually).

=head2 http_throw

  http_throw('message', {
      status           => 'InternalServerError',
      show_stask_trace => 0,
  });

Constructs the exception (via L</http_exception>) and throws it.

=head1 ATTRIBUTES

=head2 status

This is the name of the status role from L<HTTP::Throwable> that will be applied
to the exception when it is thrown.

=head2 +status_code

=head2 +reason

These are lazy.

=for Pod::Coverage   default_status_code
  default_reason

sub default_status_code { 500 }
sub default_reason { 'Internal Server Error' }

=head1 METHODS

=head2 BUILDARGS

Sets it up so that the constructor will take the message as the first argument.

=head2 body

Renders the HTML body for the error.

=head2 body_headers

Setup the HTTP headers.

=head2 as_string

Returns the message.

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
