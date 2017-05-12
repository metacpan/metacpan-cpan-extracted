package XML::Toolkit::Config;
{
  $XML::Toolkit::Config::VERSION = '0.15';
}
use Moose::Role;
use namespace::autoclean;

requires qw(
  builder
  loader
  generator
);

1
__END__

