#   xisofs v1.3 Perl/Tk Interface to mkisofs / cdwrite
#   Copyright (c) 1997 Steve Sherwood (pariah@netcomuk.co.uk)
#
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 2 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software
#   Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

package defaults;

sub load
{
	my ($name,$passwd,$uid,$gid,$quota,$comment,$gcos,$home) = getpwuid($>);

	undef %defaults::item;

	if (-e "$home/.xisofsrc")
	{
		if (open(IN,"$home/.xisofsrc"))
		{
			while (<IN>)
			{
				chomp;
				my ($key,$val) = /(\w+)\s*\=\s*(.*)/;
	
				$defaults::item{$key} = $val;
			}
			close(IN);
		}
		else
		{
			print "$home/.xisofsrc : $!\n";
		}
	}
}

sub save
{
	my ($name,$passwd,$uid,$gid,$quota,$comment,$gcos,$home) = getpwuid($>);

	if (open(OUT,">$home/.xisofsrc"))
	{
		while (($key,$val) = each %defaults::item)
		{
			print OUT "$key = $val\n";
		}
		close(OUT);
	}
	else
	{
		print "$home/.xisofsrc : $!\n";
	}
}

1;
