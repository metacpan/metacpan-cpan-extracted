#!/bin/perl

# $Id: zz_dump_config.t,v 1.1.1.1 2005/11/13 06:16:19 bryce Exp $

my $ok; # global, true if the last call to version found the module, false otherwise
use Config;

warn "\n\nConfiguration:\n\n";

# required
warn "perl: $]\n";
warn "OS: $Config{'osname'} - $Config{'myarchname'}\n";
warn version( File::Copy );
warn version( File::Path );
warn version( File::Spec );

# See XML-Twig for more detailed example of a zz_dump_config.t

warn "\n\nPlease add this information to bug reports (you can run t/zz_dump_config.t to get it)\n\n";

print "1..1\nok 1\n";
exit 0;

sub version
  { my $module= shift;
    my $version;
    if( eval "require $module")
      { $ok=1;
        import $module;
        $version= ${"$module\::VERSION"};
      }
    else
      { $ok=0;
        $version= '<not available>';
      }
    return format_warn( $module, $version);
  }

sub format_warn
  { return  sprintf( "%-25s: %s\n", @_); }


