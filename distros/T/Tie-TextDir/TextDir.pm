package Tie::TextDir;

use strict;
use File::Spec;
use File::Temp;
use Symbol;
use Fcntl qw(:DEFAULT);
use Carp;
use constant HAVE_56 => $] >= 5.006;
use vars qw($VERSION);

$VERSION = '0.06';

sub TIEHASH {
  croak "usage: tie(%hash, 'Tie::TextDir', \$path, [mode], [perms])"
    unless 2 <= @_ and @_ <= 4;
  
  my ($package, $path, $mode, $perms) = @_;
  $mode ||= 'ro';
  $perms ||= 0775;
  my $self = bless {}, $package;
  
  # Can we make changes to the database?
  if ($mode eq 'rw') {
    $self->{MODE} = O_CREAT | O_RDWR;
  } elsif ($mode eq 'ro') {
    $self->{MODE} = O_RDONLY;
  } else {
    # Assume $mode is a bitmask of Fcntl flags
    $self->{MODE} = $mode;
  }

  # Nice-ify $path:
  $path =~ s#/$##;
  croak "$path is not a directory" if -e $path and not -d _;
  unless (-e $path) {
    croak "$path does not exist" unless $self->{MODE} & O_CREAT;
    mkdir $path, $perms or croak "Can't create $path: $!";
  }
  $self->{PATH} = $path;
  
  # Get a filehandle and open the directory:
  $self->{HANDLE} = HAVE_56 ? undef : gensym();
  opendir($self->{HANDLE}, $path) or croak("can't opendir $path: $!");		
  
  return $self;
}

sub FETCH {
  my ($self, $key) = @_;
  if ( !$self->_key_okay($key) ) {
    carp "Bad key '$key'" if $^W;
    return;
  }

  my $file = File::Spec->catfile($self->{PATH}, $key);
  return unless -e $file;

  local *FH;
  unless (open( FH, "< $file" )) {
    carp "Can't open $file for reading: $!";
    return;
  }
  my $value;
  sysread FH, $value, ( stat FH )[7];
  close FH;
  return $value;
}


sub STORE {
  my ($self, $key) = (shift, shift);
  my $file = File::Spec->catfile($self->{PATH}, $key);
  croak "No write access for '$file'" unless $self->{MODE} & O_RDWR;

  if ( !$self->_key_okay($key) ) {
    carp "Bad key '$key'" if $^W;
    return;
  }

  # Use temp file for writing, and then rename to make the update atomic
  my ($fh, $tmpname) = File::Temp::tempfile(DIR => $self->{PATH}, CLEANUP => 1);
  print $fh $_[0];
  close $fh;
  rename ($tmpname, $file) or croak ("can't rename temp file $tmpname to $file: $!");
}


sub DELETE {
  my ($self, $key) = @_;
  my $file = File::Spec->catfile($self->{PATH}, $key);
  croak "No write access for '$file'" unless $self->{MODE} & O_RDWR;
  
  if ( !$self->_key_okay($key) ) {
    carp "Bad key '$key'" if $^W;
    return;
  }
  
  return unless -e $file;
  
  my $return;
  $return = $self->FETCH($key) if defined wantarray;  # Don't bother in void context
  
  unlink $file or croak "Couldn't delete $file: $!";
  return $return;
}

sub CLEAR {
  my $self = shift;
  croak "No write access for '$self->{PATH}'" unless $self->{MODE} & O_RDWR;
  
  rewinddir($self->{HANDLE});
  my $entry;
  while (defined ($entry = readdir($self->{HANDLE}))) {
    next if $entry eq '.' or $entry eq '..';
    my $file = File::Spec->catfile($self->{PATH}, $entry);
    unlink $file or croak "can't remove $file: $!";
  }
}

sub EXISTS {
  my ($self, $key) = @_;
  if ( !$self->_key_okay($key) ) {
    carp "Bad key '$key'" if $^W;
    return;
  }
  return -e File::Spec->catfile($self->{PATH}, $key);
}


sub DESTROY {
  closedir shift()->{HANDLE};  # Probably not necessary
}


sub FIRSTKEY {
  my $self = shift;
  
  rewinddir $self->{HANDLE};
  my $entry;
  while (defined ($entry = readdir($self->{HANDLE}))) {
    return $entry unless ($entry eq '.' or $entry eq '..');
  }
  return;
}


sub NEXTKEY {
  return readdir shift()->{HANDLE};
}

sub _key_okay {
  return 0 if $_[1] =~ /^\.{0,2}$/;
  return 1;
}

1;

__END__

=head1 NAME

Tie::TextDir - interface to directory of files

=head1 SYNOPSIS

 use Tie::TextDir;
 tie %hash, 'Tie::TextDir', '/some_directory', 'rw';  # Open in read/write mode
 $hash{'one'} = "some text";         # Creates file /some_directory/one
                                     # with contents "some text"
 untie %hash;
 
 tie %hash, 'Tie::TextDir', '/etc';    # Defaults to read-only mode
 print $hash{'passwd'};  # Prints contents of /etc/passwd
 
 # Specify directory permissions explicitly
 tie %hash, 'Tie::TextDir', '/some_directory', 'rw', 0775;

=head1 DESCRIPTION

The Tie::TextDir module is a TIEHASH interface which lets you tie a
Perl hash to a directory on the filesystem.  Each entry in the hash
represents a file in the directory.

To use it, tie a hash to a directory:

 tie %hash, "/some_directory", 'rw';  # Open in read/write mode

If you pass 'rw' as the third parameter, you'll be in read/write mode,
and any changes you make to the hash will create, modify, or delete
files in the given directory.  If you pass 'ro' (or nothing) as the
third parameter, you'll be in read-only mode, and any changes you make
to the hash won't have any effect in the given directory.

The 'rw' and 'ro' modes are actually just shorthand for
C<O_RDWR|O_CREAT> and C<O_RDONLY>, respectively, as defined by the
C<Fcntl> module.  You may pass C<Fcntl> bitmasks instead of their
stringy names if you like that better.  The C<O_RDWR> flag means that
you may create or delete files in the directory, and the C<O_CREAT> flag
means that if the directory itself doesn't exist C<Tie::TextDir> will
create it (or die trying).

An optional fourth parameter specifies the permissions setting that
should be used when creating the tied directory.  It I<doesn't> have
any effect at this point on the permissions of the files inside the
directory, though.  If the directory already exists, the permissions
setting will have no effect.  The default permissions setting is
C<0775>.

=head1 ERROR CONDITIONS

If you try to create or delete a file (by storing or deleting an entry
in the tied hash) and the operation fails, a fatal error will be
triggered.  If you try to read a file and the operation fails, a
warning message will be issued if you have Perl's warning switch
turned on.

If these policies don't suit you, let me know and I can probably make
the behavior configurable.

=head1 LIMITATIONS

You may not use the empty string, '.', or '..' as a key in a hash,
because they would all cause integrity problems in the directory.
Other than that, C<Tie::TextDir> won't try to check for problematic
key names, so exercise some caution (see L<CAUTIONS>).  This is to be
construed as a feature - it's possible that you might want read-only
access to an entire multi-level tree of files (though this module
would be a pretty weird way to go about it), so I don't prevent it.

If you store a key like C<brown/puppies> and the C<brown/> directory
doesn't exist, C<Tie::TextDir> won't create it for you.  On most
platform this means the operation will fail.

This module has only been tested on the UNIX platform, and although it
should work just fine on other platforms there may be some issues I
haven't thought of.

=head1 CAUTIONS

Strange characters can cause problems when used as the keys in a hash.
For instance, if you accidentally store C<../../f> as a key, you'll
probably mess something up.  If you knew what you were doing, you're
probably okay.  I'd like to add an optional (by default on) "safe"
mode that URL-encodes keys or something similar (I've lost the name of
the person who suggested this, but thanks!), but I haven't done it yet.

=head1 AUTHOR

Ken Williams (ken@mathforum.org)

=head1 COPYRIGHT

Copyright (c) 1998-2001 Ken Williams.  All rights reserved.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

perl(1).

=cut
