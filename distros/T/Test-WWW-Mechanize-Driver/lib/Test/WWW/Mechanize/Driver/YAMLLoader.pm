package Test::WWW::Mechanize::Driver::YAMLLoader;
use strict; use warnings;
our $VERSION = 1.0;

=pod

=head1 NAME

Test::WWW::Mechanize::Driver::YAMLLoader - Load Test::WWW::Mechanize tests from YAML files

=head1 SYNOPSIS

 my $loader = Test::WWW::Mechanize::Driver::YAMLLoader->new;
 my @documents = $loader->load( $file );

This module is used by Test::WWW::Mechanize::Driver to load YAML files.

=cut

sub new {
  my $class = shift;
  require YAML;
  return $class;
}

sub load {
  YAML::LoadFile( $_[1] );
}



1;

__END__

=head1 AUTHOR

 Dean Serenevy
 dean@serenevy.net
 https://serenevy.net/

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
