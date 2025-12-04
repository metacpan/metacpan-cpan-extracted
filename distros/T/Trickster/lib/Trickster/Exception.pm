package Trickster::Exception;

use strict;
use warnings;
use v5.14;

use overload '""' => 'as_string', fallback => 1;

sub new {
    my ($class, %args) = @_;
    
    return bless {
        message => $args{message} || 'An error occurred',
        status => $args{status} || 500,
        details => $args{details},
        stack_trace => $args{stack_trace} || _get_stack_trace(),
        timestamp => time,
    }, $class;
}

sub throw {
    my ($class, @args) = @_;
    die $class->new(@args);
}

sub message { shift->{message} }
sub status { shift->{status} }
sub details { shift->{details} }
sub stack_trace { shift->{stack_trace} }
sub timestamp { shift->{timestamp} }

sub as_string {
    my ($self) = @_;
    return $self->{message};
}

sub as_hash {
    my ($self) = @_;
    
    return {
        error => $self->{message},
        status => $self->{status},
        ($self->{details} ? (details => $self->{details}) : ()),
    };
}

sub _get_stack_trace {
    my @trace;
    my $i = 1;
    
    while (my @caller = caller($i++)) {
        push @trace, {
            package => $caller[0],
            filename => $caller[1],
            line => $caller[2],
            subroutine => $caller[3],
        };
        last if $i > 20; # Limit stack depth
    }
    
    return \@trace;
}

# Predefined exception types
package Trickster::Exception::NotFound;
use parent 'Trickster::Exception';
sub new {
    my ($class, %args) = @_;
    $args{message} ||= 'Resource not found';
    $args{status} = 404;
    return $class->SUPER::new(%args);
}

package Trickster::Exception::BadRequest;
use parent 'Trickster::Exception';
sub new {
    my ($class, %args) = @_;
    $args{message} ||= 'Bad request';
    $args{status} = 400;
    return $class->SUPER::new(%args);
}

package Trickster::Exception::Unauthorized;
use parent 'Trickster::Exception';
sub new {
    my ($class, %args) = @_;
    $args{message} ||= 'Unauthorized';
    $args{status} = 401;
    return $class->SUPER::new(%args);
}

package Trickster::Exception::Forbidden;
use parent 'Trickster::Exception';
sub new {
    my ($class, %args) = @_;
    $args{message} ||= 'Forbidden';
    $args{status} = 403;
    return $class->SUPER::new(%args);
}

package Trickster::Exception::MethodNotAllowed;
use parent 'Trickster::Exception';
sub new {
    my ($class, %args) = @_;
    $args{message} ||= 'Method not allowed';
    $args{status} = 405;
    return $class->SUPER::new(%args);
}

package Trickster::Exception::InternalServerError;
use parent 'Trickster::Exception';
sub new {
    my ($class, %args) = @_;
    $args{message} ||= 'Internal server error';
    $args{status} = 500;
    return $class->SUPER::new(%args);
}

1;

__END__

=head1 NAME

Trickster::Exception - Exception handling for Trickster

=head1 SYNOPSIS

    use Trickster::Exception;
    
    # Throw an exception
    Trickster::Exception::NotFound->throw(message => 'User not found');
    
    # Catch and handle
    eval {
        # ... code that might throw
    };
    if (my $e = $@) {
        if (ref($e) && $e->isa('Trickster::Exception')) {
            return $res->json($e->as_hash, $e->status);
        }
    }

=head1 DESCRIPTION

Trickster::Exception provides structured exception handling with
HTTP status codes and detailed error information.

=head1 EXCEPTION TYPES

=over 4

=item * Trickster::Exception::NotFound (404)

=item * Trickster::Exception::BadRequest (400)

=item * Trickster::Exception::Unauthorized (401)

=item * Trickster::Exception::Forbidden (403)

=item * Trickster::Exception::MethodNotAllowed (405)

=item * Trickster::Exception::InternalServerError (500)

=back

=cut
