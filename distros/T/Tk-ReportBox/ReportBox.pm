package ReportBox;

use strict;
use warnings;

our $VERSION = '1.02';
require Tk::Toplevel;
our @ISA = qw(Tk::Toplevel);

Tk::Widget->Construct('ReportBox');
sub Populate
{
	require Tk::Label;
	require Tk::Button;
	require Tk::Frame;
	require Tk::Entry;
	require Tk::Listbox;
	require Tk::FileSelect;
	my ($main, $args) = @_;
	my $text;
	my $file = $args->{'-file'};
	my $mode = $args->{'-mode'};
	my $headers = $args->{'-headers'};
	$headers = 2 unless $headers;
	my $startdir = $args->{'-startdir'};
	$startdir = './' unless $startdir;
	my $printstr = $args->{'-printstr'};
	$printstr = "lp $file" unless $printstr;
	$main->SUPER::Populate($args);
	open (F,$file);
	$mode = 0 unless $mode;
	if ($mode)
		{
		$text = $main->Scrolled("Listbox",
			-font => 'Courier',
			-width => '80',
			-height => '20')->pack();
		}
	else
		{
		$text = $main->Scrolled("Text",
			-font => 'Courier',
			-width => '80',
			-height => '20',
			)->pack();
		}
	while (<F>)
		{
		chomp if $mode;
		$text->insert('end',$_);
		}
	close (F);
	if ($mode == 0)
		{
		$text->configure(-state => 'disabled');
		}
	my $okbut = $main->Button
				(
				-text => 'OK',
				-command=>sub
			     		{
					$main->{'-button'} = 0;
					$main->withdraw;
					}
				)->pack(-side => 'left');
	if ($mode)
		{
		my $editbut = $main->Button
				(
				-text => 'Edit',
				-command=>sub
			     		{
					my $line;
					my @selected = $text->curselection();
					if (@selected and $selected[0] > ($headers - 1))
						{
						$main->{'-button'} = 1;
						$main->withdraw();
						}
					}
				)->pack(-side => 'left');
		}
	my $printbut = $main->Button
				(
				-text => 'Print',
				-command=>sub
			     		{
					system("$printstr");
					}
				)->pack(-side => 'left');

	my $savebut = $main->Button
				(
				-text => 'Save',
				-command=>sub
			     		{
					my $fref = $main->FileSelect(-directory => $startdir);
					my $newfile = $fref->Show;
					print "$newfile\n";
					if ($newfile)
						{
						open (F, "$file");
						open (F1, ">$newfile");
						while (<F>)
							{
							print (F1 $_);
							}
						close F;
						close F1;
						}
					}
				)->pack(-side => 'left');
	$main->ConfigSpecs(
			'-startdir' => ['PASSIVE'],
			'-printstr' => ['PASSIVE'],
			'-headers' => ['PASSIVE'],
			'-file' => ['PASSIVE'],
			'-button' => ['PASSIVE'],
			'-deliver' => ['METHOD'],
			'-mode' => ['PASSIVE'],
			DEFAULT => [$text]);
	$main->Advertise('list' => $text);
}#end of sub populate
sub deliver
	{
	my ($main,$temp) = @_;
	$main->waitVariable(\$main->{'-button'});
	if ($main->{'-button'})
		{
		my $list = $main->Subwidget('list');
		my @selected = $list->curselection();
		return($list->get($selected[0]));
		}
	else
		{
		return (0);
		}
	}


1;
__END__

=head1 NAME

Tk::ReportBox - Perl extension for Displaying Reports

=head1 SYNOPSIS

	use Tk::ReportBox;

	$reportbox = $main->ReportBox(
				-title => 'Head',
				-file => 'test.rp',
				-mode => 1,
				-headers => 2
				);

	my $result = $reportbox->deliver();
	
	The '-file' option is mandatory.

=head1 DESCRIPTION

This widget is meant for display of reports. In certain applications, programmers
create reports using formats and write them to temporary files, and then
read the files and display them. Typically, the user would want to
scroll through the report, print it or store it in some file of their
choice for future use. In accounting programs, a ledger may be displayed
as a scrollable list. On selecting an item on the list, the user can get
the subledger or voucher summarised on that line. ReportBox caters to both
these needs, creating either a static readonly text report, or a
scrollable list which can return a list item for further processing. The
file 'test.rp' in the distribution gives an example report of a series
of vouchers in an accounting package. 'example.pl' shows how it works.

Options:

******** The '-file' option is mandatory. *******************

-startdir: The start directory to be passed to FileSelect. Defaults to './'.

-printstr: The print command for your system. Defaults
to "lp $file". The print command would then be 'system ("lp $file")'.

-headers: For the listbox form of report, the number of header lines
at the top that are not list items and hence should not be editable.
Defaults to 2.

-file: the name of the temporary file from which to read the report.

-mode: this is 0 for static report and 1 for editable report. Defaults to 0.

-title: this is for the title of the ReportBox.


Methods:

There is only one method: 'deliver'. This returns the editable string
in the listbox report if the 'edit' button is pressed and '0' otherwise.

=head1 PREREQUISITES

1. Tk

=head1 INSTALLATION

Unpack the distribution

perl Makefile.PL

make

make install


=head1 AUTHOR

Kenneth Gonsalves.
 
I welcome all comments, suggestions and flames to 

lawgon@thenilgiris.com

=head1 LICENCE

Same as perl

=head1 BUGS

Must be any number crawling around - havent found any though.

=cut
