##############################################################################
#
#  Copyright (c) 2001-2002 Jan 'Kozo' Vajda <Jan.Vajda@pobox.sk>
#  All rights reserved.
#
##############################################################################

package Tie::Config;

use Exporter;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;
use IO::File;
use Tie::Hash;
use Fcntl;
use Data::Dumper;

@ISA = qw(Tie::StdHash);

$VERSION = '0.04';

# Items to export into callers namespace by default
@EXPORT =	qw();

# Other items we are prepared to export if requested
@EXPORT_OK =	qw();

=head1 NAME

Tie::Config - class definitions for tied hashes config file reading

=head1 SYNOPSIS

  use Tie::Config;
  
  tie %hash, 'Tie::Config', ".foo_rc", O_RDWR;
  
  
=head1 DESCRIPTION

Tied config file reader

=head1 USE

  use Tie::Config;
    
  tie %hash, 'Tie::Config', ".foo_rc", O_RDWR;
        
    print $hash{'key'};
    $hash{'key'} = "newvalue";
    
  untie %hash;

Comments is handled internal and is wroted at the top of the file.
If ommited access mode default is O_RDONLY ( read only access ).
Currently supported mode is only  O_RDONLY and  O_RDWR.

If config file is changed between tie and untie by other proces, any changes
will be lost.
                
=cut

sub TIEHASH {
  my $class = shift;
  my $file = shift;
  my $access = shift || O_RDONLY ;

  my $hash = {};
  bless $hash, $class;

  $hash->{_internal_filename} = $file;
  $hash->{_internal_accessmode} = $access;
  
  carp("File ".$hash->{_internal_filename}." does not exist.") unless ( -f $hash->{_internal_filename});

  my $rc = IO::File->new($hash->{_internal_filename}, O_RDONLY) if ( -f $hash->{_internal_filename} );
  if ( defined $rc ) {

  my $separator = '\s*=\s*';
  
  ### pre istotu vymazem komentare
  $hash->{_internal_comments} = '';

  while (<$rc>) {
    chomp;
    #### Skip blank text entry fields 
     next if ( /^\s*$/o );
    ### get comments
    if ( /^\s*#/o || /^\s*\;/o) {
      ### pridam do pola komentarov
      $hash->{_internal_comments} .= $_ . "\n";
      next;
    }
    ### Skip unless contain separator
    next unless ( /${separator}/o );

    my ($key,$value) = /\s*(.*?)${separator}(.*?)\s*$/o;
    my $length = length($value);

    ### skip empty keys
    next if ( !$length || !$key );
    
    $hash->{$key} = $value;
  }

  $rc->close;

  } else {
    carp("Canot open file ".$hash->{_internal_filename});
  }

  $hash;
}

sub STORE {
  my ($self, $key, $val) = @_;

#  print STDERR "$self, $key, $val\n";
 
  if ( $key =~ /^_internal/o ) {
    carp "invalid key [$key] in hash";
    return;
  }

  if (  !$self->{_internal_accessmode} ) {
    carp "hash is read only";
    return;
  }
  
  return($val) if ( defined $self->{$key} && $self->{$key} eq $val);
  $self->{_internal_changed} = '1';
  
#  print STDERR "hash content changed\n";
  
  $self->{$key} = $val;
}

sub DESTROY {
  my $self = shift;
  my ($key,$value);
  
#  print STDERR "Destroyed\n";
#  print STDERR Data::Dumper->Dump([$self],[qw(*destroyed)]);

  ### is read only 
  return() unless ($self->{_internal_accessmode});

  ### is changed 
  return() unless ($self->{_internal_changed});
  
#  print STDERR "untied\n";

  my $rc = new IO::File $self->{_internal_filename}, O_CREAT|O_WRONLY|O_TRUNC;
  if ( defined $rc ) {
  
    ### zapiseme komentare ak existuju
    print $rc $self->{_internal_comments} if  $self->{_internal_comments};
    
    my $separator = ' = ';

      while (($key,$value) = each %{$self}) {
        print $rc "$key${separator}$value\n" unless ($key =~ /^_internal/o);
      }
    $rc->close;
    carp "Can't close file ".$self->{_internal_filename} .": $1" if $?;  
  } else {
    carp "Can't open ".$self->{_internal_filename};
  }
}

sub CLEAR {
  my $self = shift;
  my ($key,$value);

#  print STDERR "CLEAR !!\n";

  while (($key,$value) = each %{$self}) {
    delete $self->{$key} unless ($key =~ /^_internal/o);
  }
  delete $self->{_internal_comments} if $self->{_internal_comments};
}

#sub AUTOLOAD {
#  my $self = shift;
#  my $value = shift;
#  my ($name) = $AUTOLOAD;
#
#  ($name) = ( $name =~ /^.*::(.*)/);
#
#  $self->{$name} = $value if ( defined $value );
#
#  return($self->{$name});
# 
#}

### set True
3.14;

__END__


=head1 AUTHOR INFORMATION

Copyright 2000 Jan 'Kozo' Vajda <Jan.Vajda@pobox.sk>.  All rights
reserved.  It may be used and modified freely, but I do request that this
copyright notice remain attached to the file.  You may modify this module as
you wish, but if you redistribute a modified version, please attach a note
listing the modifications you have made.

Address bug reports, patches and comments to:
Jan.Vajda@pobox.sk

=head1 CREDITS

Thanks very much to:

=over 4

=item my wife Erika

for neverending patience

=item koleso ( tibor@pobox.sk )

for permanent discontent

=item Alert Security Group ( alert@alert.sk )

for some suggestions & solutions

=item O'Reilly and Associates, Inc

for my perl book :-{))

=item ...and many many more...

for many suggestions and bug fixes.

=back

=head1 SEE ALSO

L<perl(1)>, L<perltie(1)>, L<Tie::Hash(3)>

=cut
