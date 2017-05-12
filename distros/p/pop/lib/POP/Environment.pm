package POP::Environment;

$VERSION = do{my(@r)=q$Revision: 1.2 $=~/\d+/g;sprintf '%d.'.'%02d'x$#r,@r};

use Carp;
require Exporter;
use vars qw/$VERSION @BAD @ISA @EXPORT @EXPORT_OK $ENV_TEMPLATE/;
@ISA = qw/Exporter/;

$ENV_TEMPLATE = $ENV{'ENV_TEMPLATE'};
unless ($ENV_TEMPLATE && -e $ENV_TEMPLATE) {
  croak "Environment template [$ENV_TEMPLATE] not found.\n".
	"Perhaps you need to run the environment script?";
}
unless (open(ENV_TEMPLATE)) {
  croak "Couldn't open [$ENV_TEMPLATE]: $!";
}
while (<ENV_TEMPLATE>) {
  if (/^([^#].*)=/) {
    if ($ENV{$1}) {
      ${$1} = $ENV{$1};
      push(@EXPORT,'$'.$1);
    } else {
      push(@BAD,$1);
    }
  }
}
if (@BAD == 1) {
  croak "The environment variable [@BAD] was not set";
} elsif (@BAD) {
  croak "The following environment variables were not set:\n".
	join ("\n",@BAD);
}

foreach (grep /_VERSION$/, keys %ENV) {
  ${$_} = $ENV{$_};
  push(@EXPORT, '$'.$_);
}
@EXPORT_OK=@EXPORT;
$VERSION = $VERSION;
