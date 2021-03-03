package Valiant::Filter::Trim;

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

  $value =~ s/^\s+|\s+$//g;
  return $value;
}

1;

=head1 NAME

Valiant::Validator::With - Validate using a coderef or method

=head1 SYNOPSIS

    package Local::Test::User;

    use Moo;
    use Valiant::Filters;

    has 'name' => (is=>'ro', required=>1);

    filters name => (
      trim =>  1;
    );

    my $user = Local::Test::User->new(name=>'  john    ');

    print $user->name; # 'john'


=head1 DESCRIPTION

Trims whitespace from the start and end of a string value.

=head1 SEE ALSO
 
L<Valiant>, L<Valiant::Filter>, L<Valiant::Filter::Each>.

=head1 AUTHOR
 
See L<Valiant>  
    
=head1 COPYRIGHT & LICENSE
 
See L<Valiant>

=cut
