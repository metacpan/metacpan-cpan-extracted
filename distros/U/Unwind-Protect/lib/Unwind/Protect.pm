package Unwind::Protect;
our $VERSION = '0.01';

use strict;
use warnings;
use Sub::Uplevel;
use Sub::Exporter -setup => {
    exports => ['unwind_protect'],
    groups  => {
        default => ['unwind_protect'],
    },
};

sub unwind_protect (&@) {
    my $code = shift;
    my %args = @_;

    my $wantarray = wantarray;

    my @ret;

    eval {
        if ($wantarray) {
            @ret = uplevel 1, $code;
        }
        elsif (defined $wantarray) {
            $ret[0] = uplevel 1, $code;
        }
        else {
            uplevel 1, $code;
        }
    };

    my $exception = $@;

    $args{after}->() if $args{after};

    if ($exception) {
        local $SIG{__DIE__};
        die $exception;
    }

    return @ret if $wantarray;
    return $ret[0] if defined $wantarray;
    return 0;
}

1;

__END__

=head1 NAME

Unwind::Protect - Run code after other code, even with exceptions

=head1 VERSION

version 0.01

=head1 SYNOPSIS

    ++$depth;
    
    unwind_protect { unsafe_function() }
      after => sub { --$depth };

=head1 DESCRIPTION

Sometimes you need to run code after some other code. Two complications are
preserving list; scalar; or void context, and dealing with exceptions.
C<Unwind::Protect> handles both for you.

C<unwind-protect> exists in Common Lisp with nearly the same interface.

I strive to handle exceptions properly. It's not easy, because of all the tools
Perl provides. C<$SIG{__DIE__}> and C<caller> make this code somewhat hairy. If
you provide me a failing test where the C<unwind_protect> stack frame is
inadvertantly exposed, I will try to fix it.

=head1 FUNCTIONS

=head2 unwind_protect CODE, ARGS

C<unwind_protect> takes a code block (similar to C<grep>) then some named
arguments. Currently the only named argument that is accepted is C<after>
which is a coderef to run after the primary code.

=head1 AUTHOR

Shawn M Moore, C<sartak@bestpractical.com>

=head1 SEE ALSO

L<Context::Preserve>

=cut