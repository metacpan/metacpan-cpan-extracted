package Valiant::Filter::HtmlEscape;

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

  $value =~ s/&(?!(amp|lt|gt|quot);)/&amp;/g;
  $value =~ s/</&lt;/g;
  $value =~ s/>/&gt;/g;
  $value =~ s/\"/&quot;/g;
  return $value;
}

1;

=head1 NAME

Valiant::Filter::HtmlEscape - HTML escaping on strings

=head1 SYNOPSIS

    package Local::Test::User;

    use Moo;
    use Valiant::Filters;

    has 'name' => (is=>'ro', required=>1);

    filters name => (
      html_escape =>  1,
    );


    my $user = Local::Test::User->new(name=>'<a>john</a>');

    print $user->name; # '&lt;a&gt;john&lt;/a&gt;'
  
=head1 DESCRIPTION

This is a very simple filter that takes no paramters and HTML escapes any incoming
strings. Useful to help with stuff like cross scripting attacks, etc.

Please be aware that the regexp for this might be too simple for truly hardening your code;
please review.

=head1 SEE ALSO
 
L<Valiant>, L<Valiant::Filter>, L<Valiant::Validator::Filter>.

=head1 AUTHOR
 
See L<Valiant>  
    
=head1 COPYRIGHT & LICENSE
 
See L<Valiant>

=cut
