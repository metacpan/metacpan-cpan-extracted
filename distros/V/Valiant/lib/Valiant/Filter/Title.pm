package Valiant::Filter::Title;

use Moo;
use Text::Autoformat;

with 'Valiant::Filter::Each';

sub normalize_shortcut {
  my ($class, $arg) = @_;
  return +{ };
}

sub filter_each {
  my ($self, $class, $attrs, $attribute_name) = @_;  
  my $value = $attrs->{$attribute_name};
  return unless defined $value;

  my $title = autoformat $value, { case => 'title' };

  $title =~s/[\n]//g; # Is this a bug in Text::Autoformat???

  return $title;
}

1;

=head1 NAME

Valiant::Filter::Title - title case a string

=head1 SYNOPSIS

  package Local::Test::User;

  use Moo;
  use Valiant::Filters;

  has 'name' => (is=>'ro', required=>1);

  filters name => (
    title => 1,
  );

  my $user = Local::Test::User->new(name=>'john napiorkowski');

  print $user->name; # 'John Napiorkowski'
  
=head1 DESCRIPTION

This is a very simple filter that takes no paramters and just does title case (that is
the first letter of each word becomes upper case) on the
value of the attribute.

=head1 SEE ALSO
 
L<Valiant>, L<Valiant::Filter>, L<Valiant::Validator::Filter>.

=head1 AUTHOR
 
See L<Valiant>  
    
=head1 COPYRIGHT & LICENSE
 
See L<Valiant>

=cut
