#
# $Id: Log.pm 3 2014-04-08 11:43:16Z gomor $
#
package vFeed::Log;
use strict;
use warnings;

use base qw(Class::Gomor::Array);
our @AS = qw(
   level
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

sub new {
   my $self = shift->SUPER::new(
      level => 0,
      @_,
   );

   return $self;
}

sub warning {
   my $self = shift;
   my ($msg) = @_;
   print("[!] $msg\n");
}

sub error {
   my $self = shift;
   my ($msg) = @_;
   print("[-] $msg\n");
}

sub fatal {
   my $self = shift;
   my ($msg) = @_;
   my ($package) = caller();
   die("[-] FATAL: $package: $msg\n");
}

sub info {
   my $self = shift;
   my ($msg) = @_;
   return unless $self->level > 0;
   print("[+] $msg\n");
}

sub verbose {
   my $self = shift;
   my ($msg) = @_;
   return unless $self->level > 1;
   print("[*] $msg\n");
}

sub debug {
   my $self = shift;
   my ($msg) = @_;
   return unless $self->level > 2;
   my ($package) = caller();
   print("[DEBUG] $package: $msg\n");
}

1;

__END__

=head1 NAME

vFeed::Log - logging directly on the console

=head1 SYNOPSIS

   use vFeed::Log;

   my $log = vFeed::Log->new(
      level => 1,
   );

=head1 DESCRIPTION

=head1 METHODS

=over 4

=item B<new>

=item B<info>

=item B<warning>

=item B<error>

=item B<fatal>

=item B<verbose>

=item B<debug>

=back

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=cut
