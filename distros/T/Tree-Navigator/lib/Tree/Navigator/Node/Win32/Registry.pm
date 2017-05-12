package Tree::Navigator::Node::Win32::Registry;
use Moose;
use namespace::autoclean;
extends 'Tree::Navigator::Node';

use Win32API::Registry qw/:HKEY_ :Func :KEY_/;
use Params::Validate   qw/validate SCALAR SCALARREF/;

my %root_key = (
  'HKEY_CLASSES_ROOT'     => HKEY_CLASSES_ROOT,
  'HKEY_CURRENT_CONFIG'   => HKEY_CURRENT_CONFIG,
  'HKEY_CURRENT_USER'     => HKEY_CURRENT_USER,
  'HKEY_DYN_DATA'         => HKEY_DYN_DATA,
  'HKEY_LOCAL_MACHINE'    => HKEY_LOCAL_MACHINE,
  'HKEY_PERFORMANCE_DATA' => HKEY_PERFORMANCE_DATA,
  'HKEY_USERS'            => HKEY_USERS,
);

$root_key{'HKLM'} = $root_key{'HKEY_LOCAL_MACHINE'};
$root_key{'HKCU'} = $root_key{'HKEY_CURRENT_USER'};


sub MOUNT {
  my ($class, $mount_args) = @_;
  my @mount_point = %{$mount_args->{mount_point} || {}};
  $mount_args->{mount_point} = validate(@mount_point , {
    key     => {type => SCALAR},
    exclude => {type => SCALARREF, isa => 'Regexp', optional => 1},
   });

  my $key_name = $mount_args->{mount_point}{key};
  my $reg_key  = $root_key{$key_name}
    or die "no such root key: $key_name";
  $mount_args->{mount_point}{root_key} = $reg_key;
}



sub _root_key {
  my $self  = shift;
  return $self->mount_point->{_key};
}


sub _key {
  my $self  = shift;
  my $root_key = $self->mount_point->{root_key};

  my $path = $self->path || '';
  $path =~ tr[/][\\];
  my $key;
  RegOpenKeyEx($root_key, $path, 0, KEY_READ, $key)
    or die $^E;
  return $key;
}


sub _children {
  my $self  = shift;

  my $key = $self->_key;
  my $i = 0;
  my @children;
  while (1) {
    my $child_name;
    RegEnumKeyEx($key, $i++, $child_name, [], [], [], [], [])
      or last;
    push @children, $child_name;
  }
  return \@children;
}

sub _child {
  my ($self, $child_path) = @_;
  my $class = ref $self;

  # TODO? should check for existence of subkey ?

  return $class->new(
    mount_point => $self->mount_point,
    path        => $self->_join_path($self->path, $child_path),
   );
}


sub _attributes {
  my $self  = shift;

  my $key = $self->_key;
  my $i = 0;
  my %attrs;
  while (1) {
    my $attr_name;
    my $attr_value;
    RegEnumValue($key, $i++, $attr_name, [], [], [], $attr_value, [])
      or last;
    $attrs{$attr_name} = $attr_value;
  }
  return \%attrs;
}

__PACKAGE__->meta->make_immutable;


1; # End of Tree::Navigator::Node::Win32::Registry;

__END__


=head1 NAME

Tree::Navigator::Node::Win32::Registry -- Node for Win32 Registry keys

=cut


