package WordPress::CLIDeprecated;
use strict;


sub _abs_wppost {
   defined $ENV{HOME} or warn("cant seek .wppost, ENV HOME not set") and return;
   my $abs = "$ENV{HOME}/.wppost";
   -f $abs or return;
   return $abs;
}

sub _conf {
   my $abs = shift;
   $abs ||= _abs_wppost or return;
   require YAML;
   my $conf = YAML::LoadFile($abs);
   $conf->{username} = $conf->{U};
   $conf->{password} = $conf->{P};
   $conf->{proxy} = $conf->{p};
   return $conf;
}

1;

# DEPRECATED- see distro WordPress::CLI instead
