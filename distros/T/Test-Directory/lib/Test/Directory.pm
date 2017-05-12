package Test::Directory;

use strict;
use warnings;

use Carp;
use Fcntl;
use File::Spec;
use File::Temp;
use Test::Builder::Module;

our $VERSION = '0.041';
our @ISA = 'Test::Builder::Module';

##############################
# Constructor / Destructor
##############################

my $template = 'test-directory-tmp-XXXXX';

sub new {
    my $class = shift;
    my $dir = shift;
    my %opts = @_;

    if (defined $dir) {
      $dir = File::Spec->join(split '/', $dir);
      mkdir $dir or croak "Failed to create '$dir': $!";
    } else {
      $dir = File::Temp->newdir( $template, CLEANUP=>0, DIR=>'.' )->dirname;
    };

    my %self = (dir => $dir);
    bless \%self, $class;
}

sub DESTROY {
    $_[0]->clean;
}

##############################
# Utility Functions
##############################

sub name {
    my ($self,$path) = @_;
    my @path = split /\//, $path;
    my $file = pop @path;
    return @path ? File::Spec->catfile(@path,$file) : $file;
};

sub path {
    my ($self,$file) = @_;
    return defined($file)?
      File::Spec->catfile($self->{dir}, $self->name($file)):
      $self->{dir};
};


sub touch {
  my $self = shift;
  foreach my $file (@_) {
    my $path = $self->path($file);
    sysopen my($fh), $path, O_WRONLY|O_CREAT|O_EXCL
      or croak "$path: $!";
    $self->{files}{$file} = 1;
  };
};

sub create {
  my ($self, $file, %opt) = @_;
  my $path = $self->path($file);
  
  sysopen my($fh), $path, O_WRONLY|O_CREAT|O_EXCL
    or croak "$path: $!";
  
  $self->{files}{$file} = 1;
  
  if (defined $opt{content}) {
    print $fh $opt{content};
  };
  if (defined $opt{time}) {
    utime $opt{time}, $opt{time}, $path;
  };
  return $path;
}

sub mkdir {
  my ($self, $dir) = @_;
  my $path = $self->path($dir);
  mkdir($path) or croak "$path: $!";
  $self->{directories}{$dir} = 1;
}

sub check_file {
    my ($self,$file) = @_;
    my $rv;
    if (-f $self->path($file)) {
      $rv = $self->{files}{$file} = 1;
    } else {
      $rv = $self->{files}{$file} = 0;
    }
    return $rv;
}

sub check_directory {
    my ($self,$dir) = @_;
    my $rv;
    if (-d $self->path($dir)) {
      $rv = $self->{directories}{$dir} = 1;
    } else {
      $rv = $self->{directories}{$dir} = 0;
    }
    return $rv;
}

sub clean {
    my $self = shift;
    foreach my $file ( keys %{$self->{files}} ) {
    	unlink $self->path($file);
    };
    foreach my $dir ( keys %{$self->{directories}} ) {
    	rmdir $self->path($dir);
    };
    rmdir $self->{dir};
}
    
sub _path_map {
    my $self = shift;
    my %path;
    while (my ($k,$v) = each %{$self->{files}}) {
	$path{ $self->name($k) } = $v;
    };
    while (my ($k,$v) = each %{$self->{directories}}) {
	$path{ $self->name($k) } = $v;
    };
    return \%path;
}

sub count_unknown {
    my $self = shift;
    my $path = $self->_path_map;
    opendir my($dh), $self->{dir} or croak "$self->{dir}: $!";

    my $count = 0;
    while (my $file = readdir($dh)) {
	next if $file eq '.';
	next if $file eq '..';
	next if $path->{$file};
	++ $count;
    }
    return $count;
};

sub count_missing {
    my $self = shift;

    my $count = 0;
    while (my($file,$has) = each %{$self->{files}}) {
	++ $count if ($has and not(-f $self->path($file)));
    }
    while (my($file,$has) = each %{$self->{directories}}) {
	++ $count if ($has and not(-d $self->path($file)));
    }
    return $count;
}


sub remove_files {
  my $self = shift;
  my $count = 0;
  foreach my $file (@_) {
    my $path = $self->path($file);
    $self->{files}{$file} = 0;
    $count += unlink($path);
  }
  return $count;
}

sub remove_directories {
  my $self = shift;
  my $count = 0;
  foreach my $file (@_) {
    my $path = $self->path($file);
    $self->{directories}{$file} = 0;
    $count ++ if rmdir($path);
  }
  return $count;
}

##############################
# Test Functions
##############################

sub has {
    my ($self,$file,$text) = @_;
    $text = "Has file $file." unless defined $text;
    $self->builder->ok( $self->check_file($file), $text );
}

sub hasnt {
    my ($self,$file,$text) = @_;
    $text = "Doesn't have file $file." unless defined $text;
    $self->builder->ok( not($self->check_file($file)), $text );
}

sub has_dir {
    my ($self,$file,$text) = @_;
    $text = "Has directory $file." unless defined $text;
    $self->builder->ok( $self->check_directory($file), $text );
}

sub hasnt_dir {
    my ($self,$file,$text) = @_;
    $text = "Doesn't have directory $file." unless defined $text;
    $self->builder->ok( not($self->check_directory($file)), $text );
}

sub clean_ok {
    my ($self,$text) = @_;
    $self->builder->ok($self->clean, $text);
}

sub _check_dir {
    my ($dir, $path, $unknown) = @_;
    opendir my($dh), $dir or croak "$dir: $!";

    while (my $file = readdir($dh)) {
	next if $file eq '.';
	next if $file eq '..';
	next if $path->{$file};
	push @$unknown, $file;
    }
};

sub _check_subdir {
    my ($self, $dir, $path, $unknown) = @_;
    opendir my($dh), $self->path($dir) or croak "$self->path(dir): $!";

    while (my $file = readdir($dh)) {
	next if $file eq '.';
	next if $file eq '..';
	my $name = $self->name("$dir/$file");
	next if $path->{ $name };
	push @$unknown, $name;
    }
};

sub is_ok {
    my $self = shift;
    my $name = shift;
    my $test = $self->builder;
    $name = "Directory is consistent" unless defined $name;

    my @miss;
    while (my($file,$has) = each %{$self->{files}}) {
	if ($has and not(-f $self->path($file))) {
	    push @miss, $file;
	}
    }
    my @miss_d;
    while (my($file,$has) = each %{$self->{directories}}) {
	if ($has and not(-d $self->path($file))) {
	    push @miss_d, $file;
	}
    }


    my $path = $self->_path_map;
    my @unknown;

    _check_dir($self->{dir}, $path, \@unknown);
    while (my($file,$has) = each %{$self->{directories}}) {
	my $dir = $self->path($file);
	if ($has and -d $dir) {
	    $self->_check_subdir($file, $path, \@unknown);
	}
    }

    my $rv = $test->ok((@miss+@unknown+@miss_d) == 0, $name);
    unless ($rv) {
	$test->diag("Missing file: $_") foreach @miss;
	$test->diag("Missing directory: $_") foreach @miss_d;
	$test->diag("Unknown file: $_") foreach @unknown;
    }
    return $rv;
}



1;
__END__

=head1 NAME

Test::Directory - Perl extension for maintaining test directories.

=head1 SYNOPSIS

 use Test::Directory
 use My::Module

 my $dir = Test::Directory->new($path);
 $dir->touch($src_file);
 My::Module::something( $dir->path($src_file), $dir->path($dst_file) );
 $dir->has_ok($dst_file);   #did my module create dst?
 $dir->hasnt_ok($src_file); #is source still there?

=head1 DESCRIPTION

Testing code can involve making sure that files are created and deleted as
expected.  Doing this manually can be error prone, as it's easy to forget a
file, or miss that some unexpected file was added. This module simplifies
maintaining test directories by tracking their status as they are modified
or tested with this API, making it simple to test both individual files, as
well as to verify that there are no missing or unknown files.

The idea is to use this API to create a temporary directory and
populate an initial set of files.  Then, whenever something in the directory
is changes, use the test methods to verify that the change happened as
expected.  At any time, it is simple to verify that the contents of the
directory are exactly as expected.

Test::Directory implements an object-oriented interface for managing test
directories.  It tracks which files it knows about (by creating or testing
them via its API), and can report if any files were missing or unexpectedly
added.

There are two flavors of methods for interacting with the directory.  I<Utility>
methods simply return a value (i.e. the number of files/errors) with no
output, while the I<Test> functions use L<Test::Builder> to produce the
approriate test results and diagnostics for the test harness.


The directory will be automatically cleaned up when the object goes out of
scope; see the I<clean> method below for details.

=head2 CONSTRUCTOR

=over

=item B<new>([I<$path>, I<$options>, ...])

Create a new instance pointing to the specified I<$path>. I<$options> is 
an optional hashref of options.

I<$path> will be created (or the constructor will die).  If I<$path> is
undefined, a unique path will be automatically generated; otherwise it is an
error for I<$path> to already exist.

=back


=head2 UTILITY METHODS

=over

=item B<touch>(I<$file> ...)

Create the specified I<$file>s and track their state.

=item B<create>(I<$file>,I<%options>) 

Create the specified I<$file> and track its state.  The I<%options> hash
supports the following:

=over 8

=item B<time> => I<$timestamp>

Passed to L<perlfunc/utime> to set the files access and modification times.

=item B<content> => I<$data>

Write I<$data> to the file.

=back

=item B<mkdir>(I<$directory>)

Create the specified I<$directory>; dies if I<mkdir> fails.

=item B<name>(I<$file>)

Returns the name of the I<$file>, relative to the directory; including any
seperator normalization.  I<$file> need not exist.  This method is used
internally by most other methods to translate file paths.

For portability, this method implicitly splits the path on UNIX-style /
seperators, and rejoins it with the local directory seperator.

Absent any seperator substitution, the returned value would be equivalent to
I<$file>.

=item B<path>(I<$file>)

Returns the path for the I<$file>, including the directory name and any
substitutions.  I<$file> need not exist.

=item B<check_file>(I<$file>)

Checks whether the specified I<$file> exists, and updates its state
accordingly.  Returns true if I<$file> exists, false otherwise.

This method is used internally by the corresponding test methods.

=item B<check_directory>(I<$directory>)

Checks whether the specified I<$directory> exists, and updates its state
accordingly.  Returns true if I<$directory> exists, false otherwise.

This method is used internally by the corresponding test methods.

Note that replacing a file with a directory, or vice versa, would require
calling both I<check_file> and I<check_directory> to update the state to
reflect both changes.

=item B<remove_files>(I<$file>...) 

Remove the specified $I<file>s; return the number of files removed.

=item B<remove_directories>(I<$directory>...) 

Remove the specified $I<directories>s; return the number of directories removed.

=item B<clean>

Remove all known files, then call I<rmdir> on the directory; returns the
status of the I<rmdir>.  The presence of any unknown files will cause the
rmdir to fail, leaving the directory with these unknown files.

This method is called automatically when the object goes out of scope.

=item B<count_unknown>

=item B<count_missing>

Returns a count of the unknown or missing files and directories.  Note that
files and directores are interchangeable when counting missing files, but
not when counting unknown files.

=back

=head2 TEST METHODS

The test methods validate the state of the test directory, calling
L<Test::Builder>'s I<ok> and I<diag> methods to generate output.

=over

=item B<has>  (I<$file>, I<$test_name>)

=item B<hasnt>(I<$file>, I<$test_name>)

Verify the status of I<$file>, and update its state.  The test will pass if
the state is expected.  If I<$test_name> is undefined, a default will be
generated.

=item B<has_dir>  (I<$directory>, I<$test_name>);

=item B<hasnt_dir>(I<$directory>, I<$test_name>);

Verify the status of I<$directory>, and update its state.  The test will
pass if the state is expected.  If I<$test_name> is undefined, a default will be
generated.

=item B<is_ok>(I<$test_name>)

Pass if the test directory has no missing or extra files.

=item B<clean_ok>([I<$test_name>])

Equivalent to ok(clean,I<$test_name>)

=back

=head2 EXAMPLES

=head3 Calling an external program to move a file

 $dir->touch('my-file.txt');
 system ('gzip', $dir->path('my-file.txt'));
 $dir->has  ('my-file.txt.gz', '.gz file is added');
 $dir->hasnt('my-file.txt',    '.txt file is removed');
 $dir->is_ok; #verify no other changes to $dir

=head1 SEE ALSO

L<Test::Builder>

=head1 AUTHOR

Steve Sanbeg, E<lt>sanbeg@cpan.org<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Steve Sanbeg

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
