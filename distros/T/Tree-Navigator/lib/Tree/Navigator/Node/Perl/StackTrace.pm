package Tree::Navigator::Node::Perl::StackTrace;
use Moose;
extends 'Tree::Navigator::Node';

use Devel::StackTrace::WithLexicals;
use Devel::StackTrace::AsHTML;
use namespace::autoclean;

sub MOUNT {
  my ($class, $mount_args) = @_;
  $mount_args->{mount_point}{stack_trace}
    = Devel::StackTrace::WithLexicals->new;
}

sub _stack {
  my $self = shift;
  return $self->mount_point->{stack_trace};
}

sub _children {
  my $self = shift;
  return [reverse(0 .. $self->_stack->frame_count-1)];
}

sub _child {
  my ($self, $child_path) = @_;

  return Tree::Navigator::Node::Perl::StackTrace::Frame->new(
    mount_point => $self->mount_point,
    path        => $self->_join_path($self->path, $child_path),
 );
}


sub _attributes {
  my $self = shift;
  return {}
}


sub _content {
  my $self = shift;
  my $html = $self->_stack->as_html;
  open my $fh, "<", \$html;
  return $fh;
}



__PACKAGE__->meta->make_immutable;


package Tree::Navigator::Node::Perl::StackTrace::Frame;
use Moose;
extends 'Tree::Navigator::Node';

use Tree::Navigator::Node::Perl::Ref;
use namespace::autoclean;

sub BUILD {
  my $self = shift;
  my $frame = $self->_frame;

  $self->mount(args => 'Perl::Ref' => 
                 {mount_point => {ref => [$frame->args]}});
  $self->mount(lexicals => 'Perl::Ref' => 
                 {mount_point => {ref => $frame->lexicals}});
}

sub _frame {
  my $self = shift;
  my $index = $self->last_path;

  return $self->mount_point->{stack_trace}->frame($index);
}

sub _is_parent {
  return 1;
}

sub _attributes {
  my $self = shift;
  my $frame = $self->_frame;
  my %attrs;
  $attrs{$_} = $frame->$_() foreach qw/package filename line subroutine 
                                       hasargs wantarray evaltext/;

  use Data::Dumper;
#  $attrs{args} = Dumper($frame->args);
  return \%attrs;
}


sub _content {
  my $self = shift;
  my $frame = $self->_frame;
  my $filename = $frame->filename;
  open(my $fh, $filename); # THINK: or die ? or ignore ? 
  return $fh;
}


sub content_text {
  my $self = shift;
  my $frame = $self->_frame;
  my $current_line = $frame->line;
  my $fh = $self->content;
  my @lines = <$fh>;
  $lines[$current_line-1] =~ s[(.*)][<span class='highlight'>$1</span>];
  return join "", @lines;
}



__PACKAGE__->meta->make_immutable;


1; # End of Tree::Navigator::Node::Perl::StackTrace


__END__


=head1 NAME

Tree::Navigator::Node::Perl::StackTrace

=cut


