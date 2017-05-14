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

package status;

use Tk;
use Fcntl;
use FileHandle;
use wcenter;

sub status_window
{
	my ($phase, $current, $max) = @_;

	if ($phase == 1)
	{
		$statusWindow = new MainWindow;
		$statusWindow->title('Status');

		wcenter::position($statusWindow,580,600);
		
		########
		# Title
		########
		
		$statusWindow->Label(-text => $current,
					  -font => '-adobe-helvetica-medium-r-*-*-18-*-*-*-*-*-*-*')
					  ->pack(-padx => 20,
						  -pady => 10);

		###############
		# Freeze scroll
		###############

		$status::FREEZE = 0;
		$freeze = $statusWindow->Checkbutton(
					-text => 'Freeze Scrolling',
					-variable => \$status::FREEZE,
					-relief => 'flat')->pack(-side => 'bottom',
											 -pady => 5);

		###############
		# Output Window
		###############

		$statusWindow->Label(-text => "Output Window",
					  -font => '-adobe-helvetica-medium-r-*-*-12-*-*-*-*-*-*-*')
					  ->pack(-padx => 20);

		my $statusFrame = $statusWindow->Frame;
		$statusFrame->pack(
						-padx => 20,
						-expand => 'yes',
						-fill => 'both');

		$statusOutput = $statusFrame->Text(
					-relief => 'sunken',
					-bd => 2,
					-background => 'AntiqueWhite');
					
		$statusScrollbar = $statusFrame->Scrollbar(
					-command => [$statusOutput => 'yview']);

		$statusOutput->configure(
					-yscrollcommand => [$statusScrollbar => 'set']);

		$statusScrollbar->pack(-side => 'right', -fill => 'y');
		$statusOutput->pack( -expand => 'yes',
							-fill => 'both');


		$statusWindow->update;

		$status::y = 1;

		return $statusWindow;
	}
	elsif ($phase == 3)
	{
		$_ = $current;
		my $ret = 0;
		$ret = 1 if (/\n/);

		$current =~ s/\n//g;

		if (/\r/)
		{
			my @rbits = split("\r", $current);
			
			my $z = $status::y . ".0";

			$_ = shift(@rbits);
			$statusOutput->insert($z, $_);

			foreach $txt (@rbits)
			{
				my $z2 = $status::y . "." . length($txt);
				$statusOutput->delete($z,$z2);
				$statusOutput->insert($z, $txt);
			}
		}
		else
		{	
			$statusOutput->insert('end', "$current");
		}

		if ($ret == 1)
		{
			$statusOutput->insert('end', "\n");
			$status::y++;
		}
		
		$statusOutput->yview('end') unless ($status::FREEZE == 1); 
		$statusWindow->update;
	}		
	elsif ($phase == 4)
	{
		$statusWindow->destroy;
	}
	elsif ($phase == 5)
	{
		$statusWindow->update;
	}
}

sub runCommand
{
	my ($command) = @_;

	open(IN, "$command 2>&1 |") || die "$command : $!";
	fcntl(IN, F_SETFL, O_NONBLOCK);

	while(1)
	{
		reset 'z';
	 	my $zrin = '';
            	vec($zrin, fileno(IN),1) = 1;

		($nfound) = select($zrin, undef, undef, 1.0);

		if ($nfound)
		{
			$result = <IN>;
			if ($result)
			{
				status_window(3,$result);
			}
			else
			{
				last;
			}
		}

		status_window(5);
	}
	close(IN);
}
1;
