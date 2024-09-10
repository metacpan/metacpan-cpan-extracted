package Tree::Navigator::Node::Filesys;
use utf8;
use Moose;
extends 'Tree::Navigator::Node';

use Plack::MIME;
use Plack::Util;
use HTTP::Date;
use List::MoreUtils  qw/part/;
use Params::Validate qw/validate SCALAR SCALARREF/;
use namespace::autoclean;

sub MOUNT {
  my ($class, $mount_args) = @_;
  my @mount_point = %{$mount_args->{mount_point} || {}};
  $mount_args->{mount_point} = validate(@mount_point , {
    root    => {type => SCALAR},
    exclude => {type => SCALARREF, isa => 'Regexp', default => qr/^\./},
   });
}


sub file_path {
  my $self  = shift;
  return $self->_join_path($self->mount_point->{root}, $self->path);
}


sub is_parent {
  my $self  = shift;
  return -d $self->file_path;
}


sub _children {
  my $self  = shift;
  my $file_path = $self->file_path;
  if (-d $file_path) {
    # read and filter entries from the directory
    opendir my $dh, $file_path or die $!;
    my $regex = $self->mount_point->{exclude};
    my @entries = grep {$_ !~ $regex} readdir $dh;

    # case-insensitive sort, first for dirs, then for files
    my ($dirs, $files) = part {-d "$file_path/$_" ? 0 : 1} @entries;
    $_ ||= [] for $dirs, $files;
    return [ (sort {lc($a) cmp lc($b)} @$dirs),
             (sort {lc($a) cmp lc($b)} @$files) ];
  }
  else {
    # non-directories have no children
    return [];
  }
}


sub _child {
  my ($self, $child_path) = @_;
  my $class = ref $self;
  my $file_path = $self->file_path;
  -e "$file_path/$child_path" or die "$file_path has no child '$child_path'";
  return $class->new(
    mount_point => $self->mount_point,
    path        => $self->_join_path($self->path, $child_path),
   );
}





sub _attributes {
  my $self = shift;
  my $file = $self->file_path;
  my @stats = stat $file;
  my %attrs;
  $attrs{modified} = HTTP::Date::time2str($stats[9]);
  if (-f $file) {
    $attrs{size}     = $stats[7];
  }
  return \%attrs;
}

sub _content {
  my $self = shift;
  my $file = $self->file_path;
  return undef if ! -f $file;

  open my $fh, "<:raw", $file or die $!;
  return $fh;
}




override 'response' => sub {
  my $self = shift;
  my $file = $self->file_path;

  return -d $file ? super() : $self->file_response;

};


# code mostly borrowed from Plack::App::File
sub file_response {
  my $self = shift;
  my $fh   = $self->_content;
  my $file = $self->file_path;
  my $content_type = Plack::MIME->mime_type($file) || 'text/plain';
  Plack::Util::set_io_path($fh, Cwd::realpath($file));

 # TODO : SUPPORT CONDITIONAL GET

  return [
    200,
    [
      'Content-Type'   => $content_type,
      'Content-Length' => $self->attributes->{size},
      'Last-Modified'  => $self->attributes->{modified},
     ],
    $fh,
   ];
}


__PACKAGE__->meta->make_immutable;


1; # End of Tree::Navigator::Node::Filesys

__END__

=encoding utf8

=head1 NAME

Tree::Navigator::Node::Filesys - navigating in a filesystem

=head1 TODO

   - default file view : frameset (title+attributes, file content)
   - dir view : distinct subnodes for directories and files



