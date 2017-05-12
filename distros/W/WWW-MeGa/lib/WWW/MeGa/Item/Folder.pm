# $Id: Folder.pm 193 2009-01-16 13:42:25Z fish $
package WWW::MeGa::Item::Folder;
use strict;
use warnings;

=head1 NAME

WWW::MeGa::Item::Folder - Representing a folder / album in L<WWW::MeGa>

=head1 DESCRIPTION

See L<WWW::MeGa::Item>

=head1 CHANGED METHODS

=cut


use base 'WWW::MeGa::Item';

our $VERSION = '0.11';


=head2 thumbnail_source

looks for a file named by the C<album_thumb> config parameter, defaults
to C<THUMBNAIL> in this folder and return it if found.

If not, select the first item of the directory as thumbnail.

=cut

sub thumbnail_source
{
	my $self = shift;
	my $thumb = File::Spec->catdir($self->{path}, $self->{config}->param('album_thumb'));

	return $thumb if -e $thumb;
	warn "$thumb not found, autoselecting" if $self->{config}->param('debug');
	my $first = $self->first or return;
	my $item = WWW::MeGa::Item->new($first,$self->{config},$self->{cache});
	return $item->thumbnail_source;
}


=head2 list

returns a list of all files in the directory.

=cut

sub list
{
	my $self = shift;
	my $thumb = $self->{config}->param('album_thumb');
	my @dir;
	opendir my $dh, $self->{path};
	while (my $file = readdir $dh)
	{
		next if $file eq '.' or $file eq '..';
		next if $file eq $thumb;
		push @dir, File::Spec->catdir($self->{path_rel},$file);
	}
	closedir $dh;
	return sort @dir
}

=head2 first

returns the first file of the directory.

=cut

sub first
{
	my $self = shift;
	opendir my $dh, $self->{path};
	while(my $file = readdir $dh)
	{
		next if $file eq '.' or $file eq '..';
		close $dh;
		return File::Spec->catdir($self->{path_rel},$file);
	}
	return;
}

=head2 neighbours($path)

return the item before and after the item specified by $path in the represented directory.

=cut

sub neighbours
{
	my $self = shift;
	my $path = shift;
	my @files = $self->list;
	my $i;
	my %index = map { $_ => $i++ } @files;

	my $idx = $index{$path};

	return $files[$idx-1], $files[$idx+1];
}
1;
