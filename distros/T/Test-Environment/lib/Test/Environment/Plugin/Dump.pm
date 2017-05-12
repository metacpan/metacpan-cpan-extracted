package Test::Environment::Plugin::Dump;

=head1 NAME

Test::Environment::Plugin::Dump - Dump files reader plugin

=head1 SYNOPSIS

	use Test::Environment qw{
		Dump
	};
	
	dump_with_name('some_file.txt');

	set_dumps_folder($FindBin::Bin.'/dumps2');
	dump_with_name('some_other_file.txt');

=head1 DESCRIPTION

This plugin will export 'dump_with_name' and 'set_dumps_folder' functions.

set_dumps_folder($path) will set the root path where dump files will be looked
up.

dump_with_name($file_name) will return

	File::Slurp::read_file($dump_folder.'/'.$file_name)  

Default $dump_folder is $FindBin::Bin.'/dumps'.

=cut


use strict;
use warnings;

our $VERSION = "0.07";

use base qw{ Exporter };
our @EXPORT = qw{
	dump_with_name
	set_dumps_folder
};

use Carp::Clan;
use File::Slurp;
use FindBin;


=head1 FUNCTIONS

=head2 import

All functions are exported 2 levels up. That is to the use Test::Environment caller.

=cut

sub import {
	my $package = shift;

	# export symbols two levels up - to the Test::Environment caller
	__PACKAGE__->export_to_level(2, $package, @EXPORT);
}


=head2 dump_with_name($name)

Returns read_file($dumps_folder.'/'.$name). 

=cut

our $dumps_folder = $FindBin::Bin.'/dumps';
sub dump_with_name {
	my $name = shift;
	
	croak 'please set dump name' if not defined $name;
	
	$name = $dumps_folder.'/'.$name;
	croak 'file not found "'.$name.'"' if not -f $name;
	
	return read_file($name);
}


=head2 set_dumps_folder($folder_name)

Set dumps root folder to $folder_name.

=cut

sub set_dumps_folder {
	my $folder_name = shift;
	
	croak 'pass folder name' if not defined $folder_name;
	croak 'folder not found' if not -d $folder_name;
	
	$dumps_folder = $folder_name;
}

1;


=head1 SEE ALSO

Test::Environment L<http://search.cpan.org/perldoc?Test::Environment>

=head1 AUTHOR

Jozef Kutej - E<lt>jozef@kutej.netE<gt>

=cut

