# Localized date widgets.

use strict;
use vars qw($MW);

use File::Basename qw(basename);
use File::Glob qw(bsd_glob);
use POSIX;
use Tk;
use Tk::Date;
use Tk::Pane;

sub localized_date {
    my($demo) = @_;
    my $demo_widget = $MW->WidgetDemo
      (
       -name             => $demo,
       -text             => 'Localized date widgets.',
       -title            => 'Localized date widgets',
       -iconname         => 'Loc. date widgets',
      );
    $demo_widget->geometry("640x400+10+10");

    my $mw = $demo_widget->Top;   # get geometry master

    my $p = $mw->Scrolled("Pane",
			  -scrollbars => "osoe",
			  -sticky => "ne",
			  -gridded => 'y',
			 )->pack(qw(-fill both -expand 1));

    my $msg = $mw->Message(-text => "Loading locales.\n\nThis may take some time for computing locales and rendering fonts.")
	->place(-x => 0, -y => 0, -relwidth => 1, -relheight => 1);
    $msg->update;

    my $row = 0;
    my @locales;
    if (WidgetDemo::localized_date::is_in_path("locale")) {
	chomp(@locales = `locale -a`); # -a is understood by Debian and FreeBSD
    }
    if (!@locales) {
	@locales = ('C');
	for my $localedir ('/usr/share/locale') {
	    my $locale_dir = grep { -d } bsd_glob("$localedir/*");
	    push @locales, basename $locale_dir;
	}
    }
    for my $locale (@locales) {
	POSIX::setlocale(POSIX::LC_TIME(), $locale);
	my $got_locale = POSIX::setlocale(POSIX::LC_TIME());
	if ($locale ne $got_locale) {
	    warn "skip $locale (got $got_locale)...\n";
	    next;
	}
	undef $Tk::Date::weekdays;
	undef $Tk::Date::monthnames;
	$p->Label(-text => $got_locale)->grid(-row => $row, -column => 0, -sticky => 'e');
	$p->Date(-datefmt => "%A, %4y-%m-%2d",
		 -fields  => 'date',
		 -monthmenu => 1,
		 -value   => 'now',
		)->grid(-row => $row, -column => 1, -sticky => 'e');
	$row++;
	#our $x;last if $x++>10;
    }

    $msg->destroy;
}

package WidgetDemo::localized_date;

# REPO BEGIN
# REPO NAME is_in_path /home/slavenr/work2/srezic-repository 
# REPO MD5 e18e6687a056e4a3cbcea4496aaaa1db

=head2 is_in_path($prog)

=for category File

Return the pathname of $prog, if the program is in the PATH, or undef
otherwise.

DEPENDENCY: file_name_is_absolute

=cut

sub is_in_path {
    my($prog) = @_;
    if (file_name_is_absolute($prog)) {
	if ($^O eq 'MSWin32') {
	    return $prog       if (-f $prog && -x $prog);
	    return "$prog.bat" if (-f "$prog.bat" && -x "$prog.bat");
	    return "$prog.com" if (-f "$prog.com" && -x "$prog.com");
	    return "$prog.exe" if (-f "$prog.exe" && -x "$prog.exe");
	    return "$prog.cmd" if (-f "$prog.cmd" && -x "$prog.cmd");
	} else {
	    return $prog if -f $prog and -x $prog;
	}
    }
    require Config;
    %Config::Config = %Config::Config if 0; # cease -w
    my $sep = $Config::Config{'path_sep'} || ':';
    foreach (split(/$sep/o, $ENV{PATH})) {
	if ($^O eq 'MSWin32') {
	    # maybe use $ENV{PATHEXT} like maybe_command in ExtUtils/MM_Win32.pm?
	    return "$_\\$prog"     if (-f "$_\\$prog" && -x "$_\\$prog");
	    return "$_\\$prog.bat" if (-f "$_\\$prog.bat" && -x "$_\\$prog.bat");
	    return "$_\\$prog.com" if (-f "$_\\$prog.com" && -x "$_\\$prog.com");
	    return "$_\\$prog.exe" if (-f "$_\\$prog.exe" && -x "$_\\$prog.exe");
	    return "$_\\$prog.cmd" if (-f "$_\\$prog.cmd" && -x "$_\\$prog.cmd");
	} else {
	    return "$_/$prog" if (-x "$_/$prog" && !-d "$_/$prog");
	}
    }
    undef;
}
# REPO END

# REPO BEGIN
# REPO NAME file_name_is_absolute /home/slavenr/work2/srezic-repository 
# REPO MD5 89d0fdf16d11771f0f6e82c7d0ebf3a8

=head2 file_name_is_absolute($file)

=for category File

Return true, if supplied file name is absolute. This is only necessary
for older perls where File::Spec is not part of the system.

=cut

BEGIN {
    if (eval { require File::Spec; defined &File::Spec::file_name_is_absolute }) {
	*file_name_is_absolute = \&File::Spec::file_name_is_absolute;
    } else {
	*file_name_is_absolute = sub {
	    my $file = shift;
	    my $r;
	    if ($^O eq 'MSWin32') {
		$r = ($file =~ m;^([a-z]:(/|\\)|\\\\|//);i);
	    } else {
		$r = ($file =~ m|^/|);
	    }
	    $r;
	};
    }
}
# REPO END

return 1 if caller();

package main;
require WidgetDemo;

$MW = new MainWindow;
$MW->geometry("+0+0");
$MW->Button(-text => 'Close',
	    -command => sub { $MW->destroy })->pack;
local $Tk::Date::DEBUG = 1;
localized_date('localized_date');
MainLoop;

__END__
