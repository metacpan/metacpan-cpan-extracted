#line 1 "inc/Module/Install/PERSONAL/only.pm - /Users/ingy/lib/Module/Install/PERSONAL/only.pm"
package Module::Install::PERSONAL::only;
use Module::Install::Base; @ISA = qw(Module::Install::Base);

use strict;
use lib 't'; 
use Config;
use File::Spec;
use File::Path;
use ExtUtils::MakeMaker qw(prompt);

my $versionlib = '';
my $old_versionlib = '';
my $suggested_versionlib = '';
my $old_differs = '';

sub create_config_module {
    my $a;
    _heuristics();
    $old_differs = 
      ($old_versionlib and $old_versionlib ne $suggested_versionlib);
    _intro();

    my $default = $old_differs ? 'n' : 'y';
    while (1) {
        $a = prompt('Do you want to use the "suggested" directory (y/n)?', 
                    $default
                   );
        last if $a =~ /^[yn]$/i;
    }
    if ($a =~ /^y$/) {
        $versionlib = $suggested_versionlib;
    }
    elsif ($old_differs) {
        while (1) {
            $a = prompt('Do you want to use the "old" directory (y/n)?', 
                        'y'
                       );
            last if $a =~ /^[yn]$/i;
        }
        if ($a =~ /^y$/) {
            $versionlib = $old_versionlib;
        }
    }

    _ask() if $a =~ /^n$/i;

    _write_template('config.pm.template', 
                   'lib/only/config.pm',
                   {VERSIONLIB => $versionlib},
                  );
}

sub _heuristics {
    eval q{ require only::config };
    unless ($@ or defined $only::config::versionarch) {
        $old_versionlib = &only::config::versionlib;
    }
    my ($vol, $dir) = File::Spec->splitpath( $Config{sitelib}, 1 );
    my @dir = File::Spec->splitdir($dir);

    if (grep /^site/i, @dir) {
        s/^site.*/version/i for @dir;
        $suggested_versionlib =
          File::Spec->catpath(
              $vol, 
              File::Spec->catdir(@dir),
          );
    }
    else {
        $suggested_versionlib = 
          File::Spec->catpath(
              $vol, 
              File::Spec->catdir(@dir, 'version-lib'),
          );
    }
}

sub _intro {
    print <<END;

"only.pm" has special functionality that allows you to install multiple
versions of any Perl module. In order to do this, it installs the
modules in a separate directory than the rest of your modules.

You need to decide which directory the modules will be installed in.
This value will be stored in only::config so that only.pm will know
where to look in order to load special versions of a module.

The suggested place to install special versions of Perl modules is:

  $suggested_versionlib

END

    print <<END if $old_differs;

But in a previous install you choose this directory:

  $old_versionlib

END
}

sub _ask {
    print <<END;

OK. Please enter a directory where special versions of Perl modules will
be installed. The directory must be an absolute path and must already
exist to be accepted.

END

    while (1) {
        $a = prompt("Version lib?", $versionlib);
        last if -d $a and File::Spec->file_name_is_absolute($a);
    }
    $versionlib = $a;
}

sub _write_template {
    my ($template_path, $target_path, $lookup) = @_;
    open TEMPLATE, $template_path
      or die "Can't open $template_path for input:\n$!\n";
    my $template = do {local $/;<TEMPLATE>};
    $template =~ s/<%(\w+)%>/$lookup->{$1}/g;
    close TEMPLATE;

    my @parts = split '/', $target_path;
    my $file = pop @parts;
    mkpath(File::Spec->catdir(@parts));
    my $target = File::Spec->catfile(@parts, $file);

    open CONFIG, "> $target"
      or die "Can't open $target for output:\n$!\n";
    print CONFIG $template;
    close CONFIG;
}

1;
