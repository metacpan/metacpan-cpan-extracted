package encoding::stdio;
use strict;
require encoding;
our $VERSION = '0.02';
our @ISA = ('encoding');

sub DEBUG () { 0 }

sub import {
    my $class = shift;
    my ($name, %arg) = @_;
    local ${^ENCODING};
    if ($arg{Filter}) {
        local $INC{"Filter/Util/Call.pm"} = "dummy";
        local *Filter::Util::Call::import = sub { 
            DEBUG && warn "F'U'C->i faked";
        };
        local *encoding::filter_add = sub {
            DEBUG && warn "filter_add faked";
        };
        $class->SUPER::import(@_);
    } else {
        $class->SUPER::import(@_);
    }
}

sub unimport {
    my $class = shift;
    local $INC{"Filter/Util/Call.pm"} = 0;  # pretend it's not there
    local ${^ENCODING};
    $class->SUPER::unimport(@_);
}

1;
__END__

=head1 NAME

encoding::stdio - Provides an easy way to set encoding layers on STDOUT and STDIN

=head1 SYNOPSIS

    use encoding::stdio "utf8";
    use encoding::stdio ":locale";

=head1 DESCRIPTION

The C<encoding> pragma assumes that the development environment and the
environment in which the program will run, use the same character encoding.
Typically, they will be different, but unfortunately, it's too late to change
C<encoding> now.

We can add new modules, though.

C<encoding::stdio> only installs the PerlIO C<:encoding> layers on STDOUT and
STDIN, without installing a source filter.

See C<encoding::source> by Rafael Garcia-Suarez for handling source encoding
without touching stdio encodings.

See L<encoding> for usage information.

=head1 AUTHOR

Juerd Waalboer <juerd@cpan.org>

=head1 SEE ALSO

L<encoding::source>, L<encoding>
