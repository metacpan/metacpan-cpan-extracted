package Module::Install::PRIVATE::Fix_Sort_Versions;

use strict;
use warnings;
use File::Slurp;

use vars qw( @ISA $VERSION );

use Module::Install::Base;
@ISA = qw( Module::Install::Base );

$VERSION = sprintf "%d.%02d%02d", q/0.1.0/ =~ /(\d+)/g;

# ---------------------------------------------------------------------------

sub fix_sort_versions {
  my ($self, $file) = @_;

  $self->configure_requires('File::Slurp', 0);

  print "Fixing POD in $file\n";

  my $code = read_file($file);
  $code =~ s|^=encoding.*||m;
  write_file($file, $code);
}

1;
