package dtRdr::Traits::Class;
$VERSION = eval{require version}?version::qv($_):$_ for(0.10.1);

use warnings;
use strict;
use Carp;


# XXX Class::Trait not ready for prime-time?
# a: "too late to run INIT" -- show stopper
# b: caller() is one more level removed => not according to docs
# c: how to cherry-pick methods?

#      for elsewhere: use Class::Trait qw( dtRdr::Traits::Class );

#use Class::Trait 'base';

# ANSWER: just be stupid for now:
BEGIN { # naive traits implementation
  use Exporter;
  *{import} = \&Exporter::import;
  our @EXPORT_OK = qw(
    NOT_IMPLEMENTED
    WARN_NOT_IMPLEMENTED
    claim
  );
}


=head1 NAME

dtRdr::Traits::Class - shared OO stuff

=head1 SYNOPSIS

=cut


=head1 Methods to Break Things

=head2 NOT_IMPLEMENTED

Imported into base class.  Gives a nicer message than the standard
"Can't locate method...", indicating that you did not typo the method
name, but instead forgot to override it.

  sub virtual_method {my $self = shift; $self->NOT_IMPLEMENTED(@_);}

Is the shorter, less readable version worthwhile?

  sub virtual_method { $_[0]->NOT_IMPLEMENTED(@_[1..$#_]);}

This should be safe for subclasses to override and/or call as ->SUPER::.
This gives you something like an AUTOLOAD (though you would have to get
(caller(1))[3] yourself) without having to also do can(), but that's
untested...

=cut

sub NOT_IMPLEMENTED {
  my $self = shift;
  my $method;
  for(my $i = 1;; $i++) {
    $method = (caller($i))[3];
    $method =~ m/::NOT_IMPLEMENTED$/ or last;
  }
  $method =~ s/.*:://;
  die "FATAL: required method '$method' not implemented for class '",
    ref($self) || $self, "'";
} # end subroutine NOT_IMPLEMENTED definition
########################################################################

=head2 WARN_NOT_IMPLEMENTED

Same as NOT_IMPLEMENTED(), but just a warning.  Returns undef.

  $self->WARN_NOT_IMPLEMENTED;

=cut

sub WARN_NOT_IMPLEMENTED {
  my $self = shift;
  my $method;
  for(my $i = 1;; $i++) {
    $method = (caller($i))[3];
    $method =~ m/::WARN_NOT_IMPLEMENTED$/ or last;
  }
  $method =~ s/.*:://;
  0 and warn "WARNING: method '$method' not implemented for class '",
    ref($self) || $self, "'";
  return(undef);
} # end subroutine WARN_NOT_IMPLEMENTED definition
########################################################################

=head1 Class Hopping

=head2 claim

Assumes a hash-based object.  Creates a copy (with only one level of
dereference) and blesses it into Package.

  $object = Package->claim($object);

=cut

sub claim {
  my $package = shift;
  my ($orphan) = @_;
  $package->isa(ref($orphan)) or
    croak("'$package' cannot claim what it does not inherit: '",
      ref($orphan), "'");
  my $object = {%$orphan};
  bless($object, $package);
  return($object);
} # end subroutine claim definition
########################################################################


=head1 AUTHOR

Eric Wilhelm <ewilhelm at cpan dot org>

http://scratchcomputing.com/

=head1 COPYRIGHT

Copyright (C) 2006 Eric L. Wilhelm and OSoft, All Rights Reserved.

=head1 NO WARRANTY

Absolutely, positively NO WARRANTY, neither express or implied, is
offered with this software.  You use this software at your own risk.  In
case of loss, no person or entity owes you anything whatsoever.  You
have been warned.

=head1 LICENSE

The dotReader(TM) is OSI Certified Open Source Software licensed under
the GNU General Public License (GPL) Version 2, June 1991. Non-encrypted
and encrypted packages are usable in connection with the dotReader(TM).
The ability to create, edit, or otherwise modify content of such
encrypted packages is self-contained within the packages, and NOT
provided by the dotReader(TM), and is addressed in a separate commercial
license.

You should have received a copy of the GNU General Public License along
with this program; if not, write to the Free Software Foundation, Inc.,
51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

=cut

# vi:ts=2:sw=2:et:sta
1;
