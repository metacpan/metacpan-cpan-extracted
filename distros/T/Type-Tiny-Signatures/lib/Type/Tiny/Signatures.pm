# ABSTRACT: Method/Function Signatures w/Type::Tiny Constraints
package Type::Tiny::Signatures;

use 5.14.0;
use strict;
use warnings;

require Function::Parameters;
require Type::Registry;
require Type::Tiny;

our $CALLER   = caller;
our @DEFAULTS = 'Types::Standard';

our $VERSION = '0.06'; # VERSION

unshift @Function::Parameters::type_reifiers => sub {
    Type::Registry->for_class($CALLER)->lookup($_[0]);
};

sub import {
    my (@ARGUMENTS, @LIBRARIES);

    for (map 'ARRAY' eq ref $_ ? @$_ : $_, splice @_, 1) {
        push @LIBRARIES => $_ and next if !ref && !/^:/;
        push @ARGUMENTS => $_;
    }

    Type::Registry->for_class($CALLER)->add_types($_) for @DEFAULTS, @LIBRARIES;
    Function::Parameters->import(@ARGUMENTS);

    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Type::Tiny::Signatures - Method/Function Signatures w/Type::Tiny Constraints

=head1 VERSION

version 0.06

=head1 SYNOPSIS

    use Type::Tiny;
    use Type::Tiny::Signatures;

    method hello (Str $greeting, Str $fullname) {
        print "$greeting, $fullname\n";
    }

=head1 DESCRIPTION

This module uses L<Function::Parameters> to extends Perl with keywords that
let you define methods and functions with parameter lists which can be validated
using L<Type::Tiny> type constraints. The type constraints can be provided by
the Type::Tiny standard library, L<Types::Standard>, or any supported
user-defined type library which can be a L<Moose>, L<MooseX::Type>,
L<MouseX::Type>, or L<Type::Library> library.

    use Type::Tiny;
    use Type::Tiny::Signatures qw(MyApp::Types);

    method identify (Str $name, SSN $number) {
        print "identifying $name using SSN $number\n";
    }

The method and function signatures can be configured to validate user-defined
type constraints by passing the user-defined type library package name as an
argument to the Type::Tiny::Signatures usage declaration. The default behavior
configures the Function::Parameters pragma using its defaults, i.e. strict-mode
disabled. Please note, you can pass all the acceptable Function::Parameters
import options to the Type::Tiny::Signatures usage declaration to configure the
underlying Function::Parameters pragma to suit your needs.

    use Type::Tiny;
    use Type::Tiny::Signatures ':strict' => qw(MyApp::Types);

    method identify (Str $name, SSN $number) {
        print "identifying $name using SSN $number\n";
    }

=head1 AUTHOR

Al Newkirk <anewkirk@ana.io>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Al Newkirk.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
