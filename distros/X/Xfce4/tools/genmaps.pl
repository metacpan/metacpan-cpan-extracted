#
# Copyright (C) 2003 by the gtk2-perl team (see the file AUTHORS for the full
# list)
# Modified for use with xfce4-perl by Brian Tarricone
# 
# This library is free software; you can redistribute it and/or modify it under
# the terms of the GNU Library General Public License as published by the Free
# Software Foundation; either version 2.1 of the License, or (at your option)
# any later version.
# 
# This library is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU Library General Public License for
# more details.
# 
# You should have received a copy of the GNU Library General Public License
# along with this library; if not, write to the Free Software Foundation, Inc.,
# 59 Temple Place - Suite 330, Boston, MA  02111-1307  USA.
#
# $Header: /cvsroot/gtk2-perl/gtk2-perl-xs/Gtk2/tools/genmaps.pl,v 1.1 2003/12/05 19:33:17 muppetman Exp $
#

my $includedir = '/opt/xfce4-svn/include';
my @dirs = (
    $includedir.'/xfce4/libxfce4util/',
    $includedir.'/xfce4/libxfcegui4/',
    $includedir.'/xfce4/libxfce4mcs/',
);

foreach $dir (@dirs) {
	@lines = `grep _TYPE_ $dir/*.h | grep get_type | grep -v G_TYPE`;
	foreach (@lines) {
		chomp;
		s/^.*\s([A-Z][A-Z0-9_]*_TYPE_[A-Z0-9_]*)\s.*$/$1/;
#		print "$1\n";
		push @types, $_;
	}
}

open FOO, "> foo.c";
select FOO;

print '#include <stdio.h>
#include <glib-object.h>
#include <libxfce4util/libxfce4util.h>
#include <libxfcegui4/libxfcegui4.h>
#include <libxfce4mcs/mcs-client.h>

const char * find_base (GType gtype)
{
	if (g_type_is_a (gtype, GTK_TYPE_OBJECT))
		return "GtkObject";
	if (g_type_is_a (gtype, G_TYPE_OBJECT))
		return "GObject";
	if (g_type_is_a (gtype, G_TYPE_BOXED))
		return "GBoxed";
	if (g_type_is_a (gtype, G_TYPE_FLAGS))
		return "GFlags";
	if (g_type_is_a (gtype, G_TYPE_ENUM))
		return "GEnum";
	if (g_type_is_a (gtype, G_TYPE_INTERFACE))
		return "GInterface";
	if (g_type_is_a (gtype, G_TYPE_STRING))
		return "GString";
	{
	GType parent = gtype;
	while (parent != 0) {
		gtype = parent;
		parent = g_type_parent (gtype);
	}
	return g_type_name (gtype);
	}
	return "-";
}

int main (int argc, char * argv [])
{
	g_type_init ();
';

foreach (@types) {
	print '#ifdef '.$_.'
{
        GType gtype = '.$_.';
        printf ("%s\t%s\t%s\n",
                "'.$_.'", 
		g_type_name (gtype),
		find_base (gtype));
}
#endif /* '.$_.' */
';
}

print '
	return 0;
}
';

close FOO;
select STDOUT;

system 'gcc -DXFCE_DISABLE_DEPRECATED -Wall -o foo foo.c `pkg-config libxfcegui4-1.0 libxfce4mcs-client-1.0 --cflags --libs`'
	and die "couldn't compile helper program";

%packagemap = (
	Xfce => 'Xfce4',
);

foreach (`./foo`) {
	chomp;
	my @p = split;
	(my $f = $p[0]) =~ s/_TYPE_.*$//;
	$f = ucfirst lc $f;
#	print "$f\n";
	my $pkg = $packagemap{$f} || $f;
	(my $fullname = $p[1]) =~ s/^$f/$pkg\::/;
	print join("\t", @p, $fullname), "\n";
}

#unlink('foo.c');
unlink('foo');
