package Zed::Config;

=head1 NAME

Zed::Config - config base module.

=head1 SYNOPSIS

  Foo->load;
  Foo->config;
  Foo->dump;

  package Foo;
  use base Zed::Config;
  our $NAME = "Foo";


=cut

use File::Spec;
use YAML::XS;

use Zed::Output;

my %all_config;

sub load
{
    my ($class, $conf, $name ) = shift;
    $name = ${"$class\::NAME"};
    debug("config name: $name");
    $conf = _conf($name);

    debug("config file: $conf");
    $conf = eval{YAML::XS::LoadFile $conf} || {};
    debug("config hash:", $conf);
    $all_config{ $class } = $conf;
}

sub dump
{
    my ($class, $name) = shift;
    $name = ${"$class\::NAME"};
    YAML::XS::DumpFile( _conf($name), $all_config{$class} );
}
sub _conf{ File::Spec->join( $ENV{ZED_HOME}, shift ) }

sub config { $all_config{ $_[0] }; }
1;

