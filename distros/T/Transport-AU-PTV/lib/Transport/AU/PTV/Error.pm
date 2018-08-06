package Transport::AU::PTV::Error;
$Transport::AU::PTV::Error::VERSION = '0.03';
# VERSION
# PODNAME
# ABSTRACT: error object with AUTOLOAD method slurper.

use strict;
use warnings;
use 5.010;

use constant {
    PACKAGE     => 0,
    FILENAME    => 1, 
    LINE       => 2, 
    SUB        => 3, 
    HASARGS    => 4, 
};



# Autoload captures all non-defined subroutine calls.
# This allows for subroutine chaining to continue to work, finally returning
# the error.

sub AUTOLOAD { my $self = shift; return $self; };



sub message {
    my $self = shift;
    local $" = " - ";
    my $msg = "@_";
    return bless \$msg, $self;
}



sub error {
    my $self = shift;

    return (ref $self eq __PACKAGE__) ? 1 : 0;
}


sub error_string {
    my $self = shift;
    return "${$self}";
}


sub die {
    my $self = shift;
    return unless ref $self eq __PACKAGE__;

    say STDERR "${$self}";
    exit(1);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Transport::AU::PTV::Error - error object with AUTOLOAD method slurper.

=head1 VERSION

version 0.03

=head1 NAME

=head1 METHODS

=head2 new

=head2 message

    return Transport::AU::PTV::Error->message("Invalid response") if !$obj->some_sub;

Create the error object with an error message

=head2 error

Returns 1 if the object is a Transport::AU::PTV::Error object. Returns 0 if this has been inherited by any other object.

=head2 error_string

=head2 die

=head1 AUTHOR

Greg Foletta <greg@foletta.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Greg Foletta.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
