package Win32::TieRegistry::PMVersionInfo;
use strict;
our $VERSION = 0.2;
our $CHAT;

=head1 NAME

Win32::TieRegistry::PMVersionInfo - store in Win32 Registry PM $VERSION info

=head1 SYNOPSIS

	use Win32::TieRegistry::PMVersionInfo 0.2;

	my $reg = new Win32::TieRegistry::PMVersionInfo (
		file_root	=> "D:/src/pl/spc2xml/version5/",
		ignore_dirs => ["Commercial/bin/",
						"Commercial/SPC/XSLT/SourceForge",
						"Commercial/SPC/XSLT/CSS",
						"Commercial/SPC/XSLT/imgs",],
		reg_root	=> 'LMachine/Software/LittleBits/',
		strip_path	=> $strip_path,
		chat=>1,
	);
	$reg->get;
	$reg->store;

	exit;

=head1 DESCRIPTION

This module mirrors to the Win32 registry version information from a perl module's heirachy.

It offers no support for reading the information - for that use the C<Win32::TieRegistry> module
on which this module is based.

Version information is ascertained using the same method as in C<ExtUtils::MakeMaker> version 5.45.
To quote that module's manpage:

	The first line in the file that contains the regular expression

		/([\$*])(([\w\:\']*)\bVERSION)\b.*\=/

	will be evaluated with eval() and the value of the named variable
	after the eval() will be assigned to the VERSION attribute of the
	MakeMaker object. The following lines will be parsed o.k.:

		$VERSION = '1.00';
		*VERSION = \'1.01';
		( $VERSION ) = '$Revision: 1.222 $ ' =~ /\$Revision:\s+([^\s]+)/;
		$FOO::VERSION = '1.10';
		*FOO::VERSION = \'1.11';
		our $VERSION = 1.2.3;       # new for perl5.6.0

	but these will fail:

		my $VERSION = '1.01';
		local $VERSION = '1.02';
		local $FOO::VERSION = '1.30';

	(Putting "my" or "local" on the preceding line will work o.k.)

=head1 DEPENDENCIES

	Win32::TieRegistry.

=cut

use Win32::TieRegistry ( Delimiter=>"/" );
use Carp;

=head1 CONSTRUCTOR

Expects a class name, and optionally a list of arguments in a hash-like structure, a hash or pointer to a hash.
Options are keys in a the blessed hash reference that is the object, and as such may be directly accessed anytime.

Options are:

=over 4

=item file_root

The root at which to be begin parsing files.

=item ignore_dirs

An array of directories above the C<file_root> not to process.
If any directory encountered matches at the beginning of one of
these strings, it will not be processed.

=item strip_path

The text to strip from left-hand side of paths when storing in the registry.

=item reg_root

The branch at which to root the mirror of the directory structure.

=item dirname_pattern

A positve regular expressions used when reading a directory, which the module
encloses within the bracket 'grouping' operator and anchors to the begining and
end of the string being matched. The C<.> and C<..> directories are excluded.

=item filename_pattern

As C<dirname_pattern> above, but applies to filenames, and defaults to C<.*>.

=item extension

Set to anything to retain the file extension when mapping to the registry (the default);
expilcitly set to C<undef> to strip from the filename everything after the last full-stop.

=back

=cut

sub new { my ($class) = (shift);
    unless (defined $class) {
    	warn "Usage: $class->new( {key=>value} )";
    	return undef;
	}
	my %args;
	# Take parameters and place in object slots/set as instance variables
	if (ref $_[0] eq 'HASH'){	%args = %{$_[0]} }
	elsif (not ref $_[0]){		%args = @_ }
	else {
		warn "Usage: $class->new( { key=>values, } )";
		return undef;
	}
    my $self = bless {},$class;
	# Set default options that may be over-ridden
	$self->{tree} = ();
	$self->{file_root} = '';
	$self->{ignore_dirs} = [];
	$self->{reg_root} = '';
	$self->{strip_path} = '';
	$self->{filename_pattern} = '.*';
	$self->{dirname_pattern} = '.*';
	$self->{extension}		= 1;
	# Set/overwrite public slots with user's values
	foreach (keys %args) {	$self->{lc $_} = $args{$_} }
	if (exists $self->{chat} and defined $self->{chat}){
		$CHAT = 1;
	}
	if (ref $self->{ignore_dirs} ne 'ARRAY'){
		carp "Not an array ref";
	}
	# Try to create the root key if it doesn't exist
	$_ = $Registry->{ $self->{reg_root} };
	$Registry->{ $self->{reg_root} } = {} if not defined $_;
	$_ = $Registry->{ $self->{reg_root} };
	return $self;
}

=head2 METHOD get

Accepts an object reference, and optionally a directory to parse. Stores the names of all the files
in the passed directory (or the calling object's C<file_root> slot),
and recurses (calls itself) on all sub-directories. Incidentally returns the path to the
directory operated upon.

Will return without reiterating if the directory passed matches at the beginning of
any string in the C<ignore_dirs> list (ie. the value in the object's C<file_root>
plus C<@{$self->{ignore_dirs}}> slot).

See L</CONSTRUCTOR> for details of how to effect exclusion of file and directory names.

See also L</DESCRIPTION> above for details of how the version is ascertained.

=cut

sub get { my ($self,$dir) = (shift,shift);
	local *DIR;
	$dir = $self->{file_root} if not defined $dir;
	croak "No \$self->{file_root} or passed dir to parse in method 'get'" if not defined $dir or $dir eq '';

	# See if our dir, $dir, is in the ignore list, @{$self->{ignore_dirs}}
	foreach (@{$self->{ignore_dirs}}){
		warn "Ignoring $_\n" and return undef if $dir =~ /$self->{file_root}\/?$_/;
	}

	opendir DIR,$dir
		or croak("Method get couldn't open process dir to get a file: <$dir>:\n $!.")
		and return undef;
	foreach my $fn (grep !-d && /^$self->{filename_pattern}$/,readdir DIR){
		push @{$self->{tree}}, {
			path => $dir.$fn,
			version => &version_from($dir.$fn)
		};
	}
	closedir DIR;

	chdir  $dir 		or $self->croak("Method get couldn't cd to dir <$dir>: $!") and return undef;
	opendir DIR,$dir	or $self->croak("Method get couldn't open dir <$dir>: $!") and return undef;
	foreach my $next_dir (grep {-d && !/^\.\.?$/ && /^($self->{dirname_pattern})$/ } readdir DIR){
		$self->get($dir.$next_dir.'/');
	}
	closedir DIR;
	return $dir;
}

#
# PRIVATE SUBROUTINE version_from
#	accepts a path, returns the version of that file or undef.
#	Evals each line in the file until finding /([\$*])(([\w\:\']*)\bVERSION)\b.*\=/ and evaluating
#
sub version_from { my $path = shift;
	croak "version_from called without path argument" if not defined $path;
	local *IN;
	my $version = undef;
	open IN, $path;
	while (<IN>){
		my $VERSION;
		next if !/([\$*])(([\w\:\']*)\bVERSION)\b.*\=/;
		s/^\s*(local|our)\s+//;
		$_ = eval ("$_");	# Escape scoping?
		$version = $VERSION;
		last;
	}
	close IN;
	warn "$version in $path\n" if $CHAT and defined $version;
	return $version;
}

=head2 METHOD get_from_MANIFEST

As the C<get> method, but only gets information from files listed
in a C<MANIFEST> file, the path to which should be passed as the first argument.

Additionally, the name of a C<MANIFEST.SKIP> file may be passed as a further argument,
in which case no information will be garthered from files listed therein.

=cut

sub get_from_MANIFEST { my ($self,$manifest,$manifest_skip) = (@_);
	croak "No manifest file passed as argument" if not defined $manifest;
	croak "No such manifest file as $manifest" if not -e $manifest;
	local *IN;
	my %skip;
	if (defined $manifest_skip){
		croak "No such MANIFEST.SKIP file as $manifest_skip" if not -e $manifest_skip;
		open IN, $manifest_skip;
		while (<IN>){
			chomp;
			$skip{$_} = 1;
		}
		close IN;
	}
	open MANIFEST,$manifest or croak "Could not open $manifest";
	while (<IN>){
		chomp;
		next if exists $skip{$_};
		push @{$self->{tree}}, {
			path => $_,
			version => &version_from($_)
		};
	}
	close IN;
	return 1;
}

=head2 METHOD store

Accepts an object-reference and optionally a registry path to act as a root at which to secure
the C<$VERSION> info from every file in the object's C<tree> slot.  If no 'root' is supplied,
the calling object's C<reg_root> slot is used. Incidentally returns the root used after making
changes to the registry.

=cut

sub store { my ($self,$root) = (shift,shift);
	$root = $self->{reg_root} if not defined $root;
	foreach my $file (sort @{$self->{tree}}){
		if (exists $file->{version} and $file->{version} ne ''){
			# warn $file->{path},"\t",$file->{version},"\n";
			$file->{path} =~ s/^\Q$self->{strip_path}\E//i;
			$file->{path} =~ s/\.[^.]*$// if defined  $self->{extension};
			$file->{path} =~ s|\\|/|g;
			# Build the heirachy
			my $path = $root;
			foreach my $part (split m|/|,$file->{path}){
				$path .= $part.'/';
				$_ = $Registry->{ $path };
				$Registry->{ $path } = {} if not defined $_;
			}
			# Make the keys from all the values in %{$file}, except $path
			foreach (keys %{$file}){
				next if $_ eq 'path';
				$Registry->{ $root.$file->{path} } = {$_ => $file->{$_} };
			}
		} else {
			warn "No version in file '$file->{path}'\n" if $CHAT;
		}
	}
	return $root;
}




1;	# Moduel must return a true value

__END__

=head1 CAVEATS

=over4

=item *

Be sure to pass all directories with a trailing '/'.

=item *

On Win32, it seems the C<sub get> has problems with the C<-d> operator detecting
whether a file is not a directory.

=back

=head1 SEE ALSO

L<ExtUtils::MakeMaker>, L<Win32::TieRegistry>.

=head1 KEYWORDS

Windows registry, perl module, version information, versions,
recursion .

=head1 AUTHOR

Lee Goddard <lgoddard@cpan.org>

=head1 COPYRIGHT

Copyright 2001, Lee Goddard.  All rights reserved.

Available for public use under the same terms as Perl itself.
This was developed as part of a private project, and is made
available without promise of adding anything useful to it.