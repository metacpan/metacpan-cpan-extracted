# -*- perl -*-

use ExtUtils::MakeMaker ();

use lib "lib";
use XML::EP::Install ();

my $cfg = XML::EP::Install->new(eval { require XML::EP::Config;
				       $XML::EP::Config::config } || ());
$cfg->Save("lib/XML/EP/Config.pm");

my %opts =
( 'ABSTRACT_FROM' => 'lib/XML/EP.pm',
  'AUTHOR'      => 'Jochen Wiedmann <joe@ispsoft.de>',
  'NAME'         => 'XML::EP',
  'VERSION_FROM' => 'lib/XML/EP.pm',
  'EXE_FILES'    => [ 'xmlep' ],
  'clean'        => { FILES => 'xmlep' },
  'PREREQ_PM'    => {
    'CGI'          => 0,
    'Data::Dumper' => 0,
    'XML::Parser'  => 0,
    'XML::DOM'     => 0,
    'IO::Scalar'   => 0
  }
);

ExtUtils::MakeMaker::WriteMakefile(%opts);

package MY;

sub libscan {
    my $self = shift;  my $path = shift;
    return undef if $path =~ /\~$/;
    $path;
}
