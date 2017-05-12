
=head1 NAME

Test::WWW::Mechanize::Driver::MagicValues - Define Magic Value classes

=head1 Magic Classes

=cut

=head2 FileContents

Stringification of a scalar reference in this class will slurp the file
whose name was stored in the reference.

 my $file = "Foo.txt";
 print bless(\$file, "FileContents");  # prints contents of Foo.txt

=cut

package FileContents;
use strict; use warnings;
our $VERSION = 1.0;

use overload '""' => sub {
  my $x = shift;
  open my $F, "<", $$x or die "Can't open $$x for reading: $!";
  local $/;
  return scalar <$F>;
};


=head2 ApplyTemplate

Stringification of a scalar reference in this class will pass the text of
the reference through Template.pm. Some useful variables will be defined.

 my $tmpl = "[% now.strftime('%Y-%m-%d') %]";
 print bless(\$tmpl, "ApplyTemplate");  # prints current date

=over 4

=item t

The value of C<$Test::WWW::Mechanize::Driver::CURRENT_GROUP>

=item now

The current date as a DateTime object.

=back

=cut

package ApplyTemplate;
use strict; use warnings;
our $VERSION = 1.0;

use overload '""' => sub {
  my $x = shift;
  require Template;
  require DateTime;
  my $template = Template->new();
  my $input = $$x;
  my $output;
  $template->process( \$input, {
    t => $Test::WWW::Mechanize::Driver::CURRENT_GROUP,
    now => DateTime->now,
  },
  \$output );
  return $output;
};


=head2 Stacked

Stringification of a scalar reference in this class will slurp the file
whose name was stored in the reference.

 my @stack = ( "Foo.txt", "FileContents", "ApplyTemplate" );
 print bless(\@stack, "Stacked");  # fills in and prints template in Foo.txt

=cut

package Stacked;
use strict; use warnings;
our $VERSION = 1.0;

use overload '""' => sub {
  my $x = shift;
  my $value = $$x[0];
  for my $pkg (@$x[1..$#{$x}]) {
    my $blessed = bless \$value, $pkg;
    $value = "$blessed";
  }
  return $value;
};



1;

__END__

=head1 AUTHOR

 Dean Serenevy
 dean@serenevy.net
 http://dean.serenevy.net/

=head1 COPYRIGHT

This software is hereby placed into the public domain. If you use this
code, a simple comment in your code giving credit and an email letting
me know that you find it useful would be courteous but is not required.

The software is provided "as is" without warranty of any kind, either
expressed or implied including, but not limited to, the implied warranties
of merchantability and fitness for a particular purpose. In no event shall
the authors or copyright holders be liable for any claim, damages or other
liability, whether in an action of contract, tort or otherwise, arising
from, out of or in connection with the software or the use or other
dealings in the software.

=head1 SEE ALSO

perl(1).
