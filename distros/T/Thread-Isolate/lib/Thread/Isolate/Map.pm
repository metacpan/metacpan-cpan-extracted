#############################################################################
## Name:        Map.pm
## Purpose:     Thread::Isolate::Map
## Author:      Graciliano M. P. 
## Modified by:
## Created:     2005-01-29
## RCS-ID:      
## Copyright:   (c) 2005 Graciliano M. P. 
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

package Thread::Isolate::Map ;

use strict qw(vars) ;
no warnings ;

#######
# NEW #
#######

sub new {
  my $this = shift ;
  return( $this ) if ref($this) ;
  my $class = $this || __PACKAGE__ ;
  
  my $local_pack = shift ;
  my ( $target_pack , $thi ) ;
  
  $target_pack = !ref($_[0]) ? shift(@_) : $local_pack ;
  $thi = shift ;
  
  return if !ref($thi) ;

  my $this = bless({} , $class) ;
  
  $this->{local_pack} = $local_pack ;
  $this->{target_pack} = $target_pack ;
  $this->{thi} = $thi ;

  $this->map ;

  return $this ;
}

#######
# MAP #
#######

sub map {
  my $this = shift ;

  my $thi_entries = $this->scan_pack_entries( $this->{thi} , $this->{target_pack} , 1 ) ;
  
  no strict "refs" ;
  no warnings ;
  
  foreach my $entry ( sort @$thi_entries ) {
    #print "> $entry\n" ;
    eval {
      if ( $entry =~ /^\$(.*)/ ) {
        require Thread::Isolate::Map::Scalar ;
        tie( ${$1} , 'Thread::Isolate::Map::Scalar' , $this->{thi} , $entry ) ;
      }
      elsif ( $entry =~ /^\@(.*)/ ) {
        require Thread::Isolate::Map::Array ;
        tie( @{$1} , 'Thread::Isolate::Map::Array' , $this->{thi} , $entry , $1 ) ;
      }
      elsif ( $entry =~ /^\%(.*)/ ) {
        require Thread::Isolate::Map::Hash ;
        tie( %{$1} , 'Thread::Isolate::Map::Hash' , $this->{thi} , $entry , $1 ) ;
      }
      elsif ( $entry =~ /^\*(.*)/ ) {
        require Thread::Isolate::Map::Handle ;
        tie( *{$1} , 'Thread::Isolate::Map::Handle' , $this->{thi} , $entry , $1 ) ;
      }
      elsif ( $entry =~ /^\&(.*)/ ) {
        my $sub = $1 ;
        my $thi = $this->{thi} ;
        *$sub = sub { $thi->call($sub,@_) ;}
      }
    };
    #print "$@\n" if $@ ;
  }

}

#####################
# SCAN_PACK_ENTRIES #
#####################

sub scan_pack_entries {
  my $this = shift ;
  my $thi = ref $_[0] ? shift(@_) : undef ;
  my ( $packname , $recursive ) = @_ ;
  
  if ( $thi ) {
    my $thi_entries = $thi->eval(q`
      use Thread::Isolate::Map ;
      return Thread::Isolate::Map->scan_pack_entries(@_) ;
    ` , $packname , $recursive ) ;
    warn( $thi->err ) if $thi->err ;
    return $thi_entries ;
  }

  $packname .= '::' if $packname !~ /::$/ ;
  
  return if $packname =~ /^(?:main::)?(?:Thread::Isolate|threads|UNIVERSAL|Exporter|AutoLoader|CORE|Carp|Config|DynaLoader|Errno|Win32|XSLoader|attributes|overload|strict|utf8|vars|warnings|Storable|Fcntl|Internals|PerlIO|Symbol)(?:::|$)/ ;
  
  no strict "refs" ;
  my $package = *{$packname}{HASH} ;

  return if !defined %$package || $this->{scan_pack_entries}{$package} ;
  
  $this->{scan_pack_entries}{$package} = 1 ;
  
  my @entries ;
  
  foreach my $symb ( keys %$package ) {
    my $fullname = "$packname$symb" ;
    
    next if $symb =~ /[^\w:]/ || $symb =~ /^[1-9\.]/ ;
    
    if ($symb =~ /::$/ ) {
      push(@entries , $fullname) ;
      push(@entries , @{$this->scan_pack_entries($fullname , $recursive)} ) if $recursive ;
    }
    else {
      eval {
        if (defined &$fullname) { push(@entries , "\&$fullname") ;}
        
        if ( tied *{$fullname} || *{$fullname}{IO} ) { push(@entries , "\*$fullname") ;}
  
        if (defined *{$fullname}{ARRAY}) { push(@entries , "\@$fullname") ;}
        
        if (defined *{$fullname}{HASH}) { push(@entries , "\%$fullname") ;}
        
        push(@entries , "\$$fullname") ;
      };
    }

  }
  
  delete $this->{scan_pack_entries}{$package} ;
  
  return \@entries ;
}

########################
# LOAD THREAD::ISOLATE #  Need to load here or the Mother Thread won't have the subs of this package:
########################

use Thread::Isolate ;

#######
# END #
#######

1;


__END__

=head1 NAME

Thread::Isolate::Map - Map/link packages of one thread to many other threads.

=head1 DESCRIPTION

The idea of this module is to map a package of one thread to many other threads,
saving memory through many threads.

I<Thread::Isolate::Map> supports map for SCALAR, ARRAY, HASH, HANDLE (IO) and CODE symbols.

=head1 USAGE

  use Thread::Isolate ; ## Is recomended to load it before to save memory.
  use Thread::Isolate::Map ;
  
  my $thi = Thread::Isolate->new() ;
  
  $thi->eval(q`
    package Foo ;
      $FOOVAL = 0 ;
  `) ;

  my $thi1 = Thread::Isolate->new() ;
  my $thi2 = Thread::Isolate->new() ;
  
  $thi1->map_package('Foo',$thi) ;
  $thi2->map_package('Foo',$thi) ;
  
  $thi1->eval('$Foo::FOOVAL = 10 ;');  ## $FOOVAL is 10 now. (thi1)

  $thi2->eval('$Foo::FOOVAL += 10 ;'); ## $FOOVAL is 20 now. (thi2)
  
  $thi->eval('return $Foo::FOOVAL'); ## returns 20. (thi)


As you can see in the code above all the 3 threads share the same package, and
the package symbols like I<$FOOVAL>.

=head1 METHODS

=head2 new (PACKAGE , THREAD)

Maps a local package to a thread package.

=over 4

=item PACKAGE

The package to map.

=item THREAD

The L<Thread::Isolate> object that has the real package.

=back

=head2 scan_pack_entries ( THREAD? , PACKAGE , RECURSIVE )

Scan the symbol table entries of a package.

=over 4

=item THREAD?

If defined will scan the package inside the thread.

=item PACKAGE

The package to scan.

=item RECURSIVE

If TRUE will do a recursive scan, getting symbols of sub-packages.

=back

=head1 Mapping HANDLEs (IO)

All the mapped HANDLEs (IO) will be automatically flushed (I<$| = 1>), since
is not possible to flush from an external thread, also will avoid lose of
output data when the HANDLE is not closed explicity when the process goes out.

=head1 SEE ALSO

L<Thread::Isolate>, L<Thread::Isolate::Pool>.

=head1 AUTHOR

Graciliano M. P. <gmpassos@cpan.org>

I will appreciate any type of feedback (include your opinions and/or suggestions). ;-P

=head1 COPYRIGHT

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

