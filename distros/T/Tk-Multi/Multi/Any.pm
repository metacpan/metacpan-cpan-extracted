package Tk::Multi::Any ;

use strict;

use vars qw($VERSION);

$VERSION = sprintf "%d.%03d", q$Revision: 2.2 $ =~ /(\d+)\.(\d+)/;

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.


sub print
  {
    my $cw= shift ;

    my $popup = $cw -> Toplevel ;
    $popup -> title ($cw->{'title'}.' print query') ;
    $popup -> grab ;
    $popup -> Label(-text => 'modify print command as needed :') -> pack ;
    my $pentry = $popup -> Entry(-textvariable => $cw->{_printCmdRef}) 
      -> pack(-fill => 'x') ;
    $popup -> Label(-text => 'print on file :') -> pack ;
    my $fentry = $popup -> Entry(-textvariable => \$cw->{_printFile},
				 -state => 'disabled' ) ;

    $popup -> Checkbutton
      (
       -text => 'print to file',
       -variable => \$cw->{_printToFile},
       -command => sub 
       {
         if ($cw->{_printToFile})
           {
             $fentry->configure(-state => 'normal');
             $pentry->configure(-state => 'disabled');
           }
         else
           {
             $pentry->configure(-state => 'normal');
             $fentry->configure(-state => 'disabled');
           }
       }
      ) -> pack ;

    $fentry -> pack(-fill => 'x') ;

    my $f = $popup -> Frame -> pack(-fill => 'x') ;
    $f -> Button (-text => 'print', 
                  -command => sub {
                    $cw -> doPrint(); 
                    $popup -> destroy ;
                  })
      -> pack (-side => 'left') ;
    $f -> Button (-text => 'default', 
                  -command => sub {$cw->resetPrintCmd();})
      -> pack (-side => 'left') ;
    $f -> Button (-text => 'cancel', -command => sub {$popup -> destroy ;})
      -> pack (-side => 'right') ;
  }

sub doPrint
  {
    my $cw= shift ;

    if ($cw->{_printToFile})
      {
        open(POUT,'>'.$cw->{_printFile}) 
          or die "Can't open file $cw->{_printFile}$!\n";
        print POUT $cw->printableDump() ;
        close POUT or die "print command failed: $!\n";
      }
    else
      {
        my $ref = $cw->{_printCmdRef};
        open(POUT,'|'.$$ref) or die "Can't open print pipe $!\n";
        print POUT $cw->printableDump() ;
        close POUT or die "print command failed: $!\n";
      }
  }


sub setPrintCmd
  {
    my $cw= shift ;
    my $ref = $cw->{_printCmdRef} ;
    $$ref = shift ;
  }

sub normalize
  {
    my ($cw) = shift;

    my $href ;
    if (@_ == 1 ) 
      {
	$href = shift;
      }
    else
      {
	my %h = @_ ;
	$href = \%h ;
      }

    # add '-' to keys if necessary
    map { $href->{'-'.$_} = delete $href->{$_} unless /^-/ } keys %$href ;

    return %$href ;
  }



1;
__END__


# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

Tk::Multi::Any - Do not use

=head1 SYNOPSIS


=head1 DESCRIPTION

This class contains a Print dialog box. Do not use it. This class will
be removed on the next version. The other Multi widget will use the
soon to be released PrintDialog widget.

=head1 AUTHOR

Dominique Dumont, domi@komarr.grenoble.hp.com

Copyright (c) 1997-1998,2004 Dominique Dumont. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

perl(1), Tk(3), Tk::Multi(3), Tk::Multi::Manager(3)

=cut
