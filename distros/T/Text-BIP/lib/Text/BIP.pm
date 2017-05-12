# Copyright (c) 2003-4 Timothy Appnel
# http://www.timaoutloud.org/
# This code is released under the Artistic License.
#
# Text::BIP -- Blosxom Infrastructure Package. An object-oriented module for facilitating event-based file system indexing. 	
# 

package Text::BIP;

use DirHandle;
use File::Spec;
use vars qw( $VERSION );
$VERSION = '0.51';

my $path_delim=File::Spec->catfile('',''); # stupid hack, but it works. better way???

sub new { 
	my $class = shift;
	my $self = bless { }, $class;
	$self->init(@_);
	return $self;
}

sub init {
	$_[0]->{__index_depth} = 0;
	$_[0]->{__base} = $_[1] ->{base} || '.';
	$_[0]->{__depth} = $_[1]->{depth} || 0;
	$_[0]->{__stash} = undef;
}

sub depth { $_[0]->{__depth}=$_[1] if $_[1]; $_[0]->{__depth}; }
sub base { $_[0]->{__base}=$_[1] if $_[1]; $_[0]->{__base}; }
sub stash {
	$_[0]->{__stash}->{ $_[1] } = $_[2] if $_[2];
	$_[0]->{__stash}->{ $_[1] };
}

# handler methods
sub clear_handlers { $_[0]->{__handlers} = undef; } # wipes out handler hashes.
sub prerun { shift->{__handlers}->{prerun}=shift if @_; }
sub postrun {  shift->{__handlers}->{postrun}=shift if @_; }
sub file_handler { 
	my $self = shift;
	my $ref = shift;
	foreach my $ext ( @_ ) { $self->{__handlers}->{'file'}->{$ext}=$ref; }
}
sub index_handler { 
	my($self,$ref) = @_;
	$self->{__handlers}->{'index'}->{'*'}=$ref;
}
sub read_handler { 
	my $self = shift;
	my $ref = shift;
	foreach my $ext ( @_ ) { $self->{__handlers}->{'read'}->{$ext}=$ref; }
}

sub index { 
	my $self = shift;
	my $path = shift || $self->base() || '.';
	if ($path) {
		$self->{__handlers}->{prerun}->($self) 
			if ( defined($self->{__handlers}->{prerun}) );
		$self->{__index_depth}=1;
		_process_dir($self,$path);
		$self->{__index_depth}=0;
		$self->{__handlers}->{postrun}->($self) 
			if ( defined($self->{__handlers}->{postrun}) );
	} 
}

sub _process_dir {
	my $self = shift;
	my $path = shift;
	my $d = DirHandle->new($path);
	my $exts = $self->{exts};
	for my $file ($d->read()) {
		unless ($file=~/^\./) {
			my $path_file=File::Spec->catfile($path,$file);
			$file=~m/\.([^.]*)$/;
			my $ext = $1 || ''; 
			my %data = ( path=>$path, file=>$file, ext=>$ext );
			push(@{ $self->{__stack} }, \%data );
			if ( -f $path_file) { # all files hook?
				if ( defined( $self->{__handlers}->{file}->{ $ext } ) ) {
					$self->{__handlers}->{'file'}->{ $ext }->($self);
				} elsif ( defined( $self->{__handlers}->{file}->{'*'} ) ) {
					$self->{__handlers}->{'file'}->{'*'}->($self);
				}
			} elsif (-d $path_file) {
				$self->{__handlers}->{'index'}->{'*'}->($self) 
					if ( defined( $self->{__handlers}->{'index'}->{'*'} ) );
				$self->{__index_depth}++;
				_process_dir($self, $path_file) 
					if (! $self->depth || $self->{__index_depth} < $self->depth);
				$self->{__index_depth}--;
			}
			pop(@{ $self->{__stack} });
		}
	}
	1;
}

# accessors methods to current state while streaming.
sub dir { $_[0]->{__stack}->[-1]->{path} || $path_delim; }
sub relative_dir { 
	my $base = $_[1] || $_[0]->base; 
	$_[0]->{__stack}->[-1]->{path}=~m/^$base(.*)/ ? $1 : '';
}
sub file { $_[0]->{__stack}->[-1]->{file} || ''; }
sub ext { $_[0]->{__stack}->[-1]->{ext} || ''; }
sub name { 
	my $x=$_[0]->{__stack}->[-1]; 
	File::Spec->catfile( $x->{path}, $x->{file} );
}
sub relative_name {
	my $base = $_[1] || $_[0]->base; 
	$_[0]->name=~/^$base(.*)/;
	$1;
}
sub index_depth { $_[0]->{__index_depth}; }

# experimental convienence method for reading files automatically based on type.
# should this die silently or should a default handler be implemented?
sub read_file {
	my $self = shift;
	my $file = shift;
	(my $ext) = $file=~/\.([^.]*)$/;
	if ( my $hdlr = $self->{__handlers}->{'read'}->{$ext} ) {
		return $hdlr->($self, $file, @_);
	} elsif ( my $hdlr = $self->{__handlers}->{'read'}->{'*'} ) {
		return $hdlr->($self, $file, @_);
	} else { 
		warn "Undefined handler for file extension: $ext"; 
		return '';
	}
} 

1;

__END__

=head1 NAME

Text::BIP (Blosxom Infrastructure Package) -- an object-oriented module for facilitating 
event-based file system indexing.

=head1 SYNOPSIS

 #!/usr/bin/perl -w
 
 use Text::BIP;

 # create object and initialize
 my $bip = new Text::BIP;
 $bip->depth(1); # do no index subdirectories. default is 0 recurse through all. 
 $bip->base('/some/path/name');
 
 # ... or initialize in the constructor.
 my $bip = Text::BIP->new( { depth=>1, base=>'/some/path/name' } );

 # set a file handler for .txt files.
 $bip->file_handler(\&hdlr_file,'txt');
 $bip->index_handler(\&hdlr_index);
 
 # index a directory (base) and include all subdirectories
 $bip->index();

 # index again but using an alternate directory
 $bip->index('/some/other/path/name');

 # simple file handler that dumps the values for each file found to the screen 
 sub hdlr_file {
  print "Dir: ".$_[0]->dir."\n";
  print "Relative Dir: ".$_[0]->relative_dir."\n";
  print "Relative Dir (base overide): ".$_[0]->relative_dir('/some/other/path/name')."\n";
  print "File: ".$_[0]->file."\n";
  print "Extension: ".$_[0]->ext."\n";
  print "Name: ".$_[0]->name."\n";
  print "Relative Name: ".$_[0]->relative_name."\n";
  print "Relative Name (base overide): ".$_[0]->relative_name('/some/other/path/name')."\n";
  print "\n";
 }
 
 # simple index handler that prints the name of a subdirectory.
 sub hdlr_index { print "FOLDER\nName: ".$_[0]->name."\n\n"; }

=head1 DESCRIPTION

The purpose of this module is to provide a lightweight mechanism for facilitating event-based 
file system indexing. In many ways it's L<File::Find> with a slightly more specific and 
object-oriented interface.

When Rael Dornfest released blosxom, his lightweight yet feature-packed weblog application, I was 
intrigued by how much could be done with so little. The one feature that made the biggest impression 
on me is how blosxom used the file system as a simple hierarchical document database.  I began to 
apply this technique in a number of my scripts whose scope was outside of the realm of the 
traditional weblog uses blosxom was designed to handle. To better organize and reuse my code, I 
created a module that implemented an extensible framework that I could begin dropping into my 
scripts. The result became BIP.

BIP (Blosxom Infrastructure Package) an object-oriented module that delivers an event-based (callback)
framework for indexing a file system similarly to blosxom. While there are some similarities to blosxom, 
BIP implements extensibility differently because of its different goals. It places extensibility over 
all other things and, to a certain extent, turn's blosxom's plugin architecture inside out. BIP plugs 
into your code rather then you plugging code into it like with blosxom.

=head1 METHODS

=item BIP->new( [ { depth=>integer, base=>'/path/name' } ] ) 

The constructor method. Can optionally set depth and base values through a hash reference. 
Automatically calls the C<init> method.

=item $bip->init( [ {depth=>integer, base=>'/path/name' } ] ) 

Clears the stash and other internal variables include the base and depth. Can optionally set depth 
and base values through a hash reference while initializing. Is called by C<new>.

=item $bip->depth( [ $int ] )

Returns the maximum directory depth setting. The default is 0, no limit. A depth of 1 means do not 
index any subdirectories found. If an optional integer parameter is passed, it sets the traversal 
depth.

=item $bip->base('/path/name') 

Returns the path that BIP will begin indexing at unless overridden. This value is also used by 
"relative" L<Indexing Methods> unless overridden also.

=item $bip->stash( $key, [$value] ) 

A simple mechanism for setting and getting info. If the optional C<$value> parameter is passed it 
sets the value. This method useful for handlers to manipulate BIP's state and persist results after
indexing.
 
=item $bip->index( ['/some/path/name'] )

Launches the traversal of a directory structure and calls handlers during operation. Providing an 
optional path parameter overrides any value that was set in C<base>.

=head1 HANDLER METHODS

This group of methods are used to register callback handlers that BIP will call while indexing. 

are necessarily required, but BIP is rather worthless unless at least one handler and more specifically  either a file or index handler, has been set.

=item $bip->prerun( \&coderef ) 

Sets a reference to a routine that will be called when index is called, but before traversal.

=item $bip->postrun( \&coderef ) 

Sets a reference to a routine that will be called right before index returns control to its caller.

=item $bip->index_handler( \&coderef ) 

Sets a reference to a routine that will be called when a directory is encountered, but before traversing it.

=item $bip->file_handler( \&coderef, ext[, ext1, ext2... extn] ) 

Sets a reference to a routine that will be called when a file of a certain extension is encountered. 
You can register a handler for a multiple extensions with one call or set each extension individually.

 $bip->file_handler(\&foo,'htm','html','php');
 
 # OR
 
 $bip->file_handler(\&foo, 'htm');
 $bip->file_handler(\&foo, 'html');
 $bip->file_handler(\&foo, 'php');

Giving a handler an extension of * (asterisk) will cause the handler to be run on any files that 
are encountered and does not have a handler explicitly defined otherwise.

$bip->clear_handlers

Unregisters all handlers for all extensions including C<read_handlers>.

=head1 EXPERIMENTAL METHODS

I've been trying out two experimental methods I'm not sure are valuable or are done as they should. 
These methods facilitate what I think is a more elegant means of reading in or parsing files after 
traversal.

If you were to create something just like Blosxom (why you'd do that when you have blosxom is another
issue) you may have some code (in psuedo) like this:

Without them you may use BIP to traverse a path and the output their contents with some like the 
quasi-psuedo code below.

 foreach (@files) {
 	if $_ is $ext1
		print &read_file_ext1()."\n";
	elsif $_ is $ext2
		print &read_file_ext2()."\n";
	elsif $_ is $ext3 or $_ is $ext4 
		my %data = &parse_file_ext3_or_ext4()
		foreach keys %data {
			print "$_: ".$data{ $_ }."\n";
		}
	}
 }

With them you would do something like this: (More quasi-psuedo code.)

 $bip->read_handler(\&read_file_ext1,'ext1');
 $bip->read_handler(\&read_file_ext2,'ext2');
 $bip->read_handler(\&parse_file_ext3_or_ext4,'ext3','ext4');
 
 # Then later you would just have to do
 foreach (@files) {
 	print $bip->read_file($_);
 }
 
The details of these methods are as follows.

=item $bip->read_handler( \&coderef, ext[, ext1, ext2... extn]) 

Sets a handler for reading a specific file based on files extension. Like C<file_handler> you can 
register a handler routine to multiple extensions or set each individually. You can also pass an
extension of '*' (asterisk) will cause the handler to be run on any files that does not have a 
read_handler explicitly defined. The return type a handler is at the discretion of the handler 
routine's author. It is recommended that you B<do not> return a value of C<undef> unless an error
has occurred.

=item $bip->read_file( '/full/path/to/file' )

Calls the associated C<read_handler> and passes through the C<$file> parameter. The return type is 
at the discretion of the handler routine's author. It is recommended that you B<do not> return a 
value of C<undef> unless an error has occurred.

=head1 INDEXING METHODS

The following methods are for handler functions to get the current state of BIP while processing an
index call. They are only relevant during traversal.

=item $bip->index_depth

The current depth (levels of subdirectories) from the starting point of the index.

=item $bip->dir

The current directory.

=item $bip->relative_dir( [ /some/other/path ] )

The current directory relative to C<base> or the optional parameter passed in.

=item $bip->file

The current file name.

=item $bip->ext

The current file names extension.

=item $bip->name

The fully path qualified filename.

=item $bip->relative_name( [/some/other/path] )

The relative path and filename.

=head1 DEPENDENCIES

BIP makes use of the L<DirHandle> and L<File::Spec> packages which are part of the standard 
distribution of perl.

=head1 SEE ALSO

L<http://www.blosxom.com/> - Rael Dornfest's blosxom web site, L<File::Find>

=head1 TO DO 

These are some enhancements I thought of adding. Feedback to their implementation (or dropping 
them) is appreciated.

=over 4

=item * More explicit options for hidden (.*) files and symlinks? How?

=item * Default to wildcard (*) if no extension has been specified while registering file and
index handlers?

=item * Deletion of a specific handler.

=item * Ability to cancel the traversal of a directory from a handler.

=item * A method for mapping a file system path to a HTTP document root generating a URL.

=item * More usage examples and optional utility classes.

=back

=head1 LICENSE

The software is released under the Artistic License. The terms of the Artistic License are 
described at L<http://www.perl.com/language/misc/Artistic.html>.

=head1 AUTHOR & COPYRIGHT

Except where otherwise noted, Text::BIP is Copyright 2003-4, Timothy Appnel, cpan@timaoutloud.org. 
All rights reserved.

=cut
