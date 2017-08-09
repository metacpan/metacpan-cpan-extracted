package Unexpected;

use 5.010001;
use namespace::autoclean;
use overload '""'       => sub { $_[ 0 ]->as_string  },
             'bool'     => sub { $_[ 0 ]->as_boolean },
             'fallback' => 1;
use version; our $VERSION = qv( sprintf '1.0.%d', q$Rev: 1 $ =~ /\d+/gmx );

use Moo;

with q(Unexpected::TraitFor::StringifyingError);
with q(Unexpected::TraitFor::Throwing);
with q(Unexpected::TraitFor::TracingStacks);

sub BUILD {} # Modified by the applied roles

1;

__END__

=pod

=encoding utf-8

=begin html

<a href="https://travis-ci.org/pjfl/p5-unexpected"><img src="https://travis-ci.org/pjfl/p5-unexpected.png" alt="Travis CI Badge"></a>
<a href="https://roxsoft.co.uk/coverage/report/unexpected/latest"><img src="https://roxsoft.co.uk/coverage/badge/unexpected/latest" alt="Coverage Badge"></a>
<a href="http://badge.fury.io/pl/Unexpected"><img src="https://badge.fury.io/pl/Unexpected.svg" alt="CPAN Badge"></a>
<a href="http://cpants.cpanauthors.org/dist/Unexpected"><img src="http://cpants.cpanauthors.org/dist/Unexpected.png" alt="Kwalitee Badge"></a>

=end html

=head1 Name

Unexpected - Localised exception classes composed from roles

=head1 Synopsis

   package YourApp::Exception;

   use Moo;

   extends 'Unexpected';
   with    'Unexpected::TraitFor::ErrorLeader';

   __PACKAGE__->ignore_class( 'YourApp::IgnoreMe' );

   has '+class' => default => __PACKAGE__;

   package YourApp;

   use YourApp::Exception;
   use Try::Tiny;

   sub some_method {
      my $self = shift;

      try   { this_will_fail }
      catch { YourApp::Exception->throw $_ };
   }

   # OR

   sub some_method {
      my $self = shift;

      eval { this_will_fail };
      YourApp::Exception->throw_on_error;
   }

   # THEN
   try   { $self->some_method() }
   catch { warn $_->message };

=head1 Description

An exception class that supports error messages with placeholders, a
L<throw|Unexpected::TraitFor::Throwing/throw> method with automatic
re-throw upon detection of self, conditional throw if an exception was
caught and a simplified stack trace in addition to the error message
with full stack trace

=head1 Configuration and Environment

Applies exception roles to the exception base class L<Unexpected>. See
L</Dependencies> for the list of roles that are applied

The list of signatures recognised by the constructor method is implemented by
the L<signature parser|Unexpected::Functions/parse_arg_list>

Error objects are overloaded to stringify to the full error message plus a
leader if the optional L<Unexpected::TraitFor::ErrorLeader> role has been
applied

=head1 Subroutines/Methods

=head2 BUILD

Empty subroutine which is modified by the applied roles

=head2 BUILDARGS

Differentiates different constructor method signatures

=head1 Diagnostics

String overload is performed in this class as opposed to the stringify
error role since overloading is not supported in L<Moo::Role>

=head1 Dependencies

=over 3

=item L<namespace::autoclean>

=item L<overload>

=item L<Moo>

=item L<Unexpected::TraitFor::ExceptionClasses>

=item L<Unexpected::TraitFor::StringifyingError>

=item L<Unexpected::TraitFor::Throwing>

=item L<Unexpected::TraitFor::TracingStacks>

=back

=head1 Incompatibilities

There are no known incompatibilities in this module

=head1 Bugs and Limitations

L<Throwable> did not let me use the stack trace filter directly, it's wrapped
inside an attribute constructor. There was nothing else in L<Throwable>
that would not have been overridden

There are no known bugs in this module.  Please report problems to
http://rt.cpan.org/NoAuth/Bugs.html?Dist=Unexpected. Patches
are welcome

=head1 Acknowledgements

Larry Wall - For the Perl programming language

L<Throwable::Error> - Lifted the stack frame filter from here

John Sargent - Came up with the package name

=head1 Author

Peter Flanigan, C<< <pjfl@cpan.org> >>

=head1 License and Copyright

Copyright (c) 2017 Peter Flanigan. All rights reserved

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. See L<perlartistic>

This program is distributed in the hope that it will be useful,
but WITHOUT WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE

=cut

# Local Variables:
# mode: perl
# tab-width: 3
# End:
