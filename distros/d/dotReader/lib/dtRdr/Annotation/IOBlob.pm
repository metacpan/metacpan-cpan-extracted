package dtRdr::Annotation::IOBlob;
$VERSION = eval{require version}?version::qv($_):$_ for(0.10.1);

use warnings;
use strict;
use Carp;

{ # XXX rw copy of Meta::Public :-(
  package dtRdr::Annotation::IOBlob::Public;
  use Class::Accessor::Classy;
  with 'new';
  rw 'server';
  rw 'owner';
  rw 'rev';
  no  Class::Accessor::Classy;
}

=head1 NAME

dtRdr::Annotation::IOBlob - hash reference scrubber

=head1 SYNOPSIS

=cut

my %def_keys = map({$_ => undef} qw(
  id
  book
  node
  title
  mod_time
  create_time
  revision
));
my %range_keys = map({$_ => undef} qw(
  start
  end
  context
  selected
));
my @also = qw(
  references
  content
);
use Class::Accessor::Classy;
rw (keys(%def_keys), keys(%range_keys), @also);
rw 'public';
ro 'type';
no  Class::Accessor::Classy;

=head2 new

  my $blob = dtRdr::Annotation::IOBlob->new;

=cut

sub new {
  my $class = shift;
  ref($class) and croak("class method");
  my $self = {};
  bless($self, $class);
  return($self);
} # end subroutine new definition
########################################################################

=head2 clone

  $also_blob = $blob->clone;

=cut

sub clone {
  my $self = shift;
  my $class = ref($self);

  my $new = $class->new;
  foreach my $key (keys(%$self)) {
    if(my $c = ref($self->{$key})) {
      if($c eq 'ARRAY') {
        $new->{$key} = [@{$self->{$key}}];
      }
      else {
        my $obj = $c->new(%{$self->{$key}});
        $new->{$key} = $obj;
      }
    }
    else {
      $new->{$key} = $self->{$key};
    }
  }
  return($new);
} # end subroutine clone definition
########################################################################

=head2 outgoing

  $blob = dtRdr::Annotation::IOBlob->outgoing(%values);

=cut

sub outgoing {
  my $package = shift;
  my $self = $package->new;
  my %data = @_;

  $self->_kmap({%data});
  if($data{public}) {
    if(defined(my $rev = $data{public}{rev})) {
      $self->{public}{rev} = $data{public}{rev};
    }
    $self->{public}{server} = $data{public}{server};
  }

  return($self);
} # end subroutine outgoing definition
########################################################################

=head2 incoming

  $blob = dtRdr::Annotation::IOBlob->incoming(%values);

=cut

sub incoming {
  my $package = shift;
  my $self = $package->new;

  $self->_kmap({@_});

  return($self);
} # end subroutine incoming definition
########################################################################

=head2 _kmap

  $self = $self->_kmap($data);

=cut

sub _kmap {
  my $self = shift;
  my ($data, $also) = @_;
  $also ||= {};

  foreach my $key (qw(id book)) {
    defined($data->{$key}) or croak("IOBlob must have key '$key'");
  }

  %$self = ( 
    %def_keys,
    %$also,
    map({exists($def_keys{$_}) ? ($_ => $data->{$_}) : ()} keys %$data),
    type => $data->{type},
  );
  # TODO ANNOTATION_TYPE, can(), isa(), etc
  if($self->{type} eq 'dtRdr::Note') {
    $self->{content} = $data->{content};
    $self->{references} = [@{$data->{references}}]
      if(exists($data->{references}));
  }

  if(exists($data->{start})) {
    foreach my $k (keys(%range_keys)) {
      $self->{$k} = $data->{$k};
    }
  }

  if($data->{public}) {
    # NOTE: we don't want to allow any other keys for public
    $self->set_public(dtRdr::Annotation::IOBlob::Public->new(
      owner => $data->{public}{owner}
    ));
  }

  return($self);
} # end subroutine _kmap definition
########################################################################

=head2 deref

Transform back into a plain hashref.

  $hashref = $blob->deref;

=cut

sub deref {
  my $self = shift;

  my $hr = {%$self};
  $hr->{public} = {%{$hr->{public}}} if(exists($hr->{public}));
  return($hr);
} # end subroutine deref definition
########################################################################


=head1 AUTHOR

Eric Wilhelm <ewilhelm at cpan dot org>

http://scratchcomputing.com/

=head1 COPYRIGHT

Copyright (C) 2007 Eric L. Wilhelm and OSoft, All Rights Reserved.

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
