package Win32::FileNotify;

use strict;
use warnings;

use Carp;
use File::Basename;
use File::stat;
use Win32::ChangeNotify;

our $VERSION = '0.31';

sub new{
    my ($class,$file) = @_;
    
    croak "file does not exist" unless -e $file;
    
    my $dir = dirname( $file );
       $dir ||= '.';
       
    my $stat = stat $file if -e $file;
    
    my $self = bless {},$class;
    $self->_modified( $stat );
    $self->_file( $file );
    $self->_obj( $dir );

    return $self;
}

sub wait{
    my ($self) = @_;
    my $return;
    
    while( 1 ){
        $self->_obj->wait or last;
        $self->_obj->reset;
        if( $self->_is_changed ){
            $return = 1;
            last;
        }
    }

    return $return;
}

sub _is_changed{
    my ($self) = @_;
    my $return = 0;
    
    my $stat = stat $self->_file;
    
    if( $stat->mtime != $self->_modified ){
        $return = 1;
        $self->_modified( $stat );
    }
    
    return $return;
}

sub _modified{
    my ($self,$stat) = @_;
    
    if( $stat ){
        $self->{__modified} = $stat->mtime;
    }

    return $self->{__modified};
}

sub _file{
    my ($self,$file) = @_;
    
    if( defined $file ){
        $self->{__file} = $file;
    }

    return $self->{__file};
}

sub _obj{
    my ($self,$dir) = @_;
    
    if( defined $dir ){
        $self->{__obj} = Win32::ChangeNotify->new( $dir, 0, 'LAST_WRITE' );
    }

    return $self->{__obj};
}

1;

__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Win32::FileNotify - Monitor file changes

=head1 SYNOPSIS

  use Win32::FileNotify;
  
  my $file = './test.txt';
  my $notify = Win32::FileNotify->new( $file );
  $notify->wait;
  
  print $file, " wurde veraendert\n";

=head1 DESCRIPTION

This is a wrapper around Win32::ChangeNotify. With Win32::FileNotify you can 
monitor one specific file and you get notified when the file has changed.

=head1 METHODS

=head2 new

  my $filename = '/path/to/file.txt';
  $notify = Win32::FileNotify->new( $filename );

creates a new object for the given file.

=head2 wait

  $notify->wait;

See L<Win32::IPC>

=head1 SEE ALSO

L<Win32::ChangeNotify>

=head1 AUTHOR

Renee Baecker, E<lt>module@renee-baecker.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 - 2008 by Renee Baecker

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
