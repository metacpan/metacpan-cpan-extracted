package Valiant::Filter::Collapse;

use Moo;
use Valiant::Util 'throw_exception';

with 'Valiant::Filter::Each';

sub normalize_shortcut {
  my ($class, $arg) = @_;
  return +{ };
}

sub filter_each {
  my ($self, $class, $attrs, $attribute_name) = @_;  
  my $value = $attrs->{$attribute_name};
  return unless defined $value;
  $value =~ s/[\h\v]+/ /g;
  return $value;
}

1;

=head1 NAME

Valiant::Filter::Collapse - collapse whitespace

=head1 SYNOPSIS

  package Local::Test::User;

  use Moo;
  use Valiant::Filters;

  has 'name' => (is=>'ro', required=>1);

  filters name => (
    collapse => 1,
  );

  my $user = Local::Test::User->new(name=>'john     james       napiorkowski');

  print $user->name; # 'john james napiorkowski'
  
=head1 DESCRIPTION

Given a string collapse all whitespace to a space 'space'.  This will not remove
whitespace at the start/end of a string, merely collapse it to a single space (
see L<Valiant::Filter::Trim>)
=head1 SEE ALSO
 
L<Valiant>, L<Valiant::Filter>, L<Valiant::Validator::Filter>.

=head1 AUTHOR
 
See L<Valiant>  
    
=head1 COPYRIGHT & LICENSE
 
See L<Valiant>

=cut
