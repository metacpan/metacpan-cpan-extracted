package Text::FileTree;
# Copyright (c) 2012 - Olof Johansson <olof@cpan.org>
# All rights reserved.
#
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

use warnings FATAL => 'all';
use strict;
our $VERSION = 0.24;

use Carp;
use File::Slurp;
use File::Spec;
use File::Basename;
use Module::Load;

use Data::Dumper;

=head1 NAME

Text::FileTree - convert a list of files with full paths to a tree

=head1 DESCRIPTION

A file list can be organized in a number of ways. The two that
most probably comes to mind is a "state free" way, where each
file is listed with full path and doesn't depend on its context.
The C<find> command outputs files in this way. 

There is also the "stateful" way of display file lists, where
each file is sorted by its common parents. E.g., instead of

 foo/bar
 foo/baz

you might have the following structure instead:

 foo/
   bar
   baz

This module does just that, converts a "plain" file listing in to
the "stateful", directory sorted, way.

=head1 CONSTRUCTOR

 my $ft     = Text::FileTree->new( );
 my $ft_w32 = Text::FileTree->new( platform => 'Win32' );

Create a FileTree parser object. By default, it assume the files
are in the platform native format, but this can be overriden.
Internally, L<File::Spec> is used, but by specifiying a platform
parameter C<File::Spec::<platform>> is used instead.

=cut

sub new {
	my $class = shift;
	my $self = bless {
		fs => "File::Spec",
		@_,
		data => {},
	}, $class;

	if($self->{platform}) {
		load "File::Spec::$self->{platform}";
		$self->{fs} = "File::Spec::$self->{platform}";
	}

	return $self;
}

=head1 METHODS

=head2 parse

=cut

sub parse {
	my $self = shift;

	for my $str (@_) {
		$self->__parse_file($_) for split /\n/, $str;
	}

	return $self->{data};
}

sub __parse_file {
	my $self = shift;
	my $file = shift;
	my $fs = $self->{fs};

	return unless $file =~ /\S/;

	my $prnt = $self->{data};

	for($fs->splitdir($file)) {
		$prnt = $prnt->{$_} = defined $prnt->{$_} ? $prnt->{$_} : {};
	}
}

=head2 from_file

Load the file list from a file.

=cut

sub from_file {
	my $self = shift;
	my $filename = shift;
	return $self->parse(read_file($filename, err_mode => 'carp'));
}

=head2 from_fh

Load the file list from a filehandle (or a filename). Examples:

 open(my $pipe, '-|', 'find', '/');
 Text::FileTree->new->from_fh($pipe);

=cut

sub from_fh {
	my $self = shift;
	my $fh = shift;
	return $self->parse(join '', <$fh>)
}

=head1 AVAILABILITY AND BUG REPORTING

Latest released version is available through CPAN. Latest
development version is available on github:

=over

=item * L<https://metacpan.org/pod/Text::FileTree>

=item * L<https://github.com/olof/Text-FileTree>

=back

We use Github for issue tracking and pull requests.

=over

=item * L<https://github.com/olof/Text-FileTree/issues>

=back

If you don't have an account on Github (or for other reason don't
want to use Github), we are ok with bugs filed on rt.cpan.org as
well.

=head1 KNOWN BUGS AND LIMITATIONS

This module does not separate between a file and a directory.
This only affects leaf nodes, as you can deduce that a file with
children is indeed a directory. This is unlikely to be fixed, as
there is really no way of distinguish them in, say, the output
from find. Often, you should be able to determine this by
context: e.g. by giving C<find> the C<-type f> flag --- now all
leaf nodes are regular files.

=head1 COPYRIGHT

Copyright (c) 2012 - Olof Johansson <olof@cpan.org>
All rights reserved.

This program is free software; you can redistribute it and/or 
modify it under the same terms as Perl itself.

=cut

1;
