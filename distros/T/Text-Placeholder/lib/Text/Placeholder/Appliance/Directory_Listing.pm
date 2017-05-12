package Text::Placeholder::Appliance::Directory_Listing;

use strict;
use warnings;
use Carp qw();
use parent qw(
	Object::By::Array);
use Text::Placeholder;

sub THIS() { 0 }

sub ATR_PLACEHOLDER() { 0 }
sub ATR_COUNTER() { 1 }
sub ATR_AGGREGATOR() { 2 }

sub P_NAME() { 0 }
sub fs_directory_list {
        unless (opendir(DIR, $_[P_NAME])) {
                Carp::confess("$_[P_NAME]: $!");
        }
        my @names = sort(readdir(DIR));
        close(DIR);

        return(\@names);
};

sub P_FORMAT() { 1 }
sub _init {
	my ($this) = @_;

	$this->[ATR_PLACEHOLDER] = Text::Placeholder->new(
		$this->[ATR_COUNTER] = '::Counter',
		$this->[ATR_AGGREGATOR] = '::Aggregator');
	$this->[ATR_AGGREGATOR]->add_group(
		my $file_name = '::OS::Unix::File::Name',
		my $file_properties = '::OS::Unix::File::Properties');

	$this->[ATR_PLACEHOLDER]->compile($_[P_FORMAT]);
	return;
}

sub P_DIRECTORY() { 1 }
sub generate {
	my ($this) = @_;

	my $file_names = fs_directory_list($_[P_DIRECTORY]);
	my @result = ();
	foreach my $file_name (@$file_names) {
		$this->[ATR_AGGREGATOR]->subject("$_[P_DIRECTORY]$file_name");
		push(@result, ${$this->[ATR_PLACEHOLDER]->execute()});;
	}
	return(\@result);
}

1;
