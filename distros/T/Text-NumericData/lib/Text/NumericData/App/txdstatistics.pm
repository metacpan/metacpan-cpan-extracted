package Text::NumericData::App::txdstatistics;

use Text::NumericData::Stat;
use Text::NumericData::App;

# This is just a placeholder because of a past build system bug.
# The one and only version for Text::NumericData is kept in
# the Text::NumericData module itself.
our $VERSION = '1';
$VERSION = eval $VERSION;

#the infostring says it all
my $infostring = "do basic statistics on textual data files

	$0 < data.dat
would yield in some statistics about the columns in the file being printed.

This is designed as an enhancement over txdmean, giving info like standard error in a more extensible format (to later add more measures).";

our @ISA = ('Text::NumericData::App');

sub new
{
	my $class = shift;

	return $class->SUPER::new
	({
		parconf=>
		{
			 info=>$infostring # default version
			# default author
			# default copyright
		},
		 filemode=>1
		,pipemode=>1
		,pipe_file=>\&process_file
	});
}

sub process_file
{
	my $self = shift;
	my $out = Text::NumericData::Stat::generate($self->{txd});
	$out->write_all($self->{out});
}

1;
