package Unexpected::TraitFor::ErrorLeader;

use namespace::autoclean;

use List::Util        qw( first );
use Unexpected::Types qw( NonZeroPositiveInt SimpleStr );
use Moo::Role;

requires qw( as_string clone frames );

my $Ignore = [ 'Try::Tiny' ];

# Private functions
my $_is_member = sub {
   my $wanted = shift; return (first { $_ eq $wanted } @{ $_[ 0 ] }) ? 1 : 0;
};

my $_build_leader = sub {
   my $self = shift; my $level = $self->level; my $leader = q();

   my @frames = $self->frames; my ($line, $package);

   $level >= scalar @frames and $level = scalar @frames - 1;

   do {
      # uncoverable condition right
      if ($frames[ $level ] and $package = $frames[ $level ]->package) {
         $line    = $frames[ $level ]->line;
         $leader  = $package; $leader =~ s{ :: }{-}gmx;
         $leader .= "[${line}/${level}]: "; $level++;
      }
      else { $leader = $package = q() }
   }
   while ($package and $_is_member->( $package, $self->ignore ));

   return $leader;
};

# Object attributes (public)
has 'leader' => is => 'lazy', isa => SimpleStr, builder => $_build_leader;

has 'level'  => is => 'ro',   isa => NonZeroPositiveInt, default => 1;

# Construction
around 'as_string' => sub {
   my ($orig, $self, @args) = @_; my $str = $orig->( $self, @args );

   return $str ? $self->leader.$str : $str;
};

before 'clone' => sub {
   my $self = shift; $self->leader; return;
};

# Public methods
sub ignore {
   return $Ignore;
}

sub ignore_class {
   shift; return push @{ $Ignore }, @_;
}

1;

__END__

=pod

=encoding utf-8

=head1 Name

Unexpected::TraitFor::ErrorLeader - Prepends a leader to the exception

=head1 Synopsis

   package MyException;

   use Moo;

   extends 'Unexpected';
   with    'Unexpected::TraitFor::ErrorLeader';

=head1 Description

Prepends a one line stack summary to the exception error message

=head1 Configuration and Environment

Requires the C<as_string> method in the consuming class, the C<clone> method
from the C<Throwing> role, as well as C<frames> from the stack trace role

Defines the following attributes;

=over 3

=item C<leader>

Set to the package and line number where the error should be reported

=item C<level>

A positive integer which defaults to one. How many additional stack frames
to pop before calculating the C<leader> attribute

=back

Modifies C<as_string> in the consuming class. Prepends the C<leader>
attribute to the return value

=head1 Subroutines/Methods

=head2 ignore

   $array_ref = $self->ignore;

Read only accessor for the C<$Ignore> package scoped
variable. Defaults to an empty array ref

=head2 ignore_class

   Unexpected->ignore_class( $classname );

The C<$Ignore> package scoped variable is an array ref of methods
whose presence should be ignored by the error message leader. This
method pushes C<$classname> onto that array ref

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<namespace::autoclean>

=item L<Moo::Role>

=item L<Unexpected::Types>

=back

=head1 Incompatibilities

There are no known incompatibilities in this module

=head1 Bugs and Limitations

There are no known bugs in this module.
Please report problems to the address below.
Patches are welcome

=head1 Acknowledgements

Larry Wall - For the Perl programming language

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
