package XML::Toolkit::Cmd;
{
  $XML::Toolkit::Cmd::VERSION = '0.15';
}
use Moose;
use namespace::autoclean;
extends qw(MooseX::App::Cmd);

__PACKAGE__->meta->make_immutable;
1;
__END__
