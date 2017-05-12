package Test::More::Strict;

use warnings;
use strict;
use Carp;

{
    # Nasty hack: install ourself in Test::Builder's ISA chain.
    my $builder = Test::More->builder;
    our @ISA = ref $builder;

    # Bless builder into our package.
    bless Test::More->builder, __PACKAGE__;
}

my @OK_EVENT = qw( description );
my %Handler  = ();

=head1 NAME

Test::More::Strict - Enforce policies on test results

=head1 VERSION

This document describes Test::More::Strict version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

    # Enforce non-blank test description
    use Test::More::Strict description => sub {
        my $desc = shift;
        return defined $desc and $desc =~ /\S/;
    };
  
=head1 DESCRIPTION

C<Test::More::Strict> allows policies for test results to be enforced.
For example you may require that all tests have a non-blank description.
You could achieve that like this:

    # Enforce non-blank test description
    use Test::More::Strict description => sub {
        my $desc = shift;
        return defined $desc and $desc =~ /\S/;
    };

In general you pass a number of key => coderef pairs on the use line.
Currently the only recognised key is C<description>. The coderef is
called with the test description as its first argument. It should return
a true value if the description is OK otherwise false.

=head1 INTERFACE 

=head2 C<< caller >>

Overridden from Test::Builder. Adjusts the stack depth to account for
our intercept.

=cut

# Fix up caller
sub caller {
    my ( $self, $height ) = @_;
    $height ||= 0;
    return $self->SUPER::caller( $height + 2 );
}

=head2 C<< ok >>

Overridden from Test::Builder.

=cut

sub ok {
    my ( $self, $test, $description ) = @_;
    return $self->SUPER::ok(
        _and_with_handlers( 'description', $test, $description ),
        $description );
}

sub _and_with_handlers {
    my ( $event, $ok, @args ) = @_;
    return $ok unless $ok;
    for my $handler ( @{ $Handler{$event} || [] } ) {
        return 0 unless $handler->( @args );
    }
    return $ok;
}

{
    my %OK_EVENT = map { $_ => 1 } @OK_EVENT;

    sub import {
        my $class = shift;

        croak "Please supply a number of key => value pairs"
          if @_ & 1;

        while ( my ( $event, $validator ) = splice @_, 0, 2 ) {
            croak "$event is not a valid event name"
              unless $OK_EVENT{$event};
            croak "Validator must be a code reference"
              unless 'CODE' eq ref $validator;
            push @{ $Handler{$event} }, $validator;
        }
    }
}
1;
__END__

=head1 CONFIGURATION AND ENVIRONMENT
  
Test::More::Strict requires no configuration files or environment variables.

=head1 DEPENDENCIES

None.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-test-more-strict@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Andy Armstrong  C<< <andy.armstrong@messagesystems.com> >>

=head1 LICENCE AND COPYRIGHT

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

Copyright (c) 2005-2008, Message Systems, Inc.
All rights reserved.

Redistribution and use in source and binary forms, with or
without modification, are permitted provided that the following
conditions are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in
      the documentation and/or other materials provided with the
      distribution.
    * Neither the name Message Systems, Inc. nor the names of its
      contributors may be used to endorse or promote products derived
      from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER
OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
