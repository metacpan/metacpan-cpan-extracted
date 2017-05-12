#!/usr/bin/perl
use warnings;
use strict;

print "call with option '0' .. '3' \n";

my $selectmode = 'browse';

if(@ARGV)
	{
	my $index = $ARGV[0];
	my @modes = ('browse', 'single', 'extended', 'multiple');
	if($index =~/^[0-9]+$/)
		{
		$index = $index % scalar(@modes);
		print "index is $index \n";
		$selectmode = $modes[$index];
		}
	}

print "selectmode is $selectmode \n";

        use Tk;
        use Tk::ListboxDnD;
        my $top = MainWindow->new();
        my $listbox = $top->ListboxDnD(selectmode=>$selectmode)->pack();

	$listbox->configure( -dragformat=>"[[%s]]");
	$listbox->configure( -dragformat=>"<%s>");

       $listbox->insert('end', qw/alpha bravo charlie delta echo fox/);
        MainLoop();
