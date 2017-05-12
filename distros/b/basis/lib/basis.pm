  package basis
; our $base
; BEGIN 
    { unless($base)
        { for my $realbase (qw(parent base))
            { eval "require $realbase"
            ; unless($@)
                { $base = $realbase
                ; last
                }
            }
        ; unless($base)
            { die "Perl pragma parent or base not loadable."
            } 
        }  
    };

use Sub::Uplevel 0.12; 
our $VERSION='0.05003';

; sub import
    { shift()
    ; return unless @_
    ; my @basis=@_

    # filter argument arrays
    ; my %args
    ; for ($i=0; $i<=$#basis; $i++)
        { if(ref $basis[$i+1] eq 'ARRAY')
	    { $args{$basis[$i]}=splice(@basis,$i+1,1)
	    }
	  else
	    { $args{$basis[$i]}=[]
	    }
	}
    ; my $builder = $base->can('import')
    ; my $return = uplevel(1, $builder, $base, @basis)
    ; shift @basis if $basis[0] eq '-norequire'
    # this checks if the above works, which is not the case
    # if Sub::Uplevel was loaded to late
    # it is better to die if this not works
    ; my $inheritor=caller(0)
    ; foreach ( @basis )
        { next if $inheritor->isa($_) 
        ; require Carp;
        ; Carp::croak(<<ERROR)
'basis' via '$base' was not able to setup the base class '$_' for '$inheritor'.
Maybe Sub::Uplevel was load to late for your script.   
ERROR
        }
    ; foreach my $m ( @basis )
        { my $import = $m->can('import') 
        ; uplevel( 1, $import , $m , @{$args{$m}} ) if $import 
        }
    ; $return
    }

; 1

__END__

=head1 NAME

basis - use base with import call

=head1 VERSION

Version 0.05003

=head1 SYNOPSIS

Usage is similar to L<base> or L<parent>:
    
    package Baz;
    use basis qw/Foo bar/;

Or with arguments for import:

    package Foo;
    use basis Bary => [go => "away"];

=head1 DESCRIPTION

It uses Sub::Uplevel to do the construct

  BEGIN {
	  use base qw/Foo bal/;
	  Foo->import;
	  bal->import('tor');
  };

transparently for the parent and child class.

If the classname is followed by a array reference, than
the dereferenced array is used in the import call as argument.

Now it uses the C<import> method from the class named in the
global variable C<$basis::base>. When not set from outside, this
variable will be set during the first load of this module. It
defaults to C<parent> and as second alternative to C<base>.

=head1 IMPORTANT NOTE

The call of Sub::Uplevel might come to late, so C<uplevel> 
will not work as expected. If you use this module, the same rule 
as for Sub::Uplevel applies:

Use Sub::Uplevel as early as possible in your program.

Now this module croaks when Sub::Uplevel is not used earlier enough.
	
=head1 AUTHOR

Sebastian Knapp, C<< <rock@ccls-online.de> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-basis at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=basis>.
I will be notified, and then you will automatically be notified 
of progress on your bug as I make changes.

=head1 ACKNOWLEDGMENT

Thank you Michael G. Schwern for base and Sub::Uplevel. I hope this tiny 
add-on finds your blessing. Thank you David A Golden for maintenance and
improvement of Sub::Uplevel.
	
=head1 SEE ALSO

L<Sub::Uplevel>

L<base>

L<parent>

=head1 COPYRIGHT & LICENSE

Copyright 2006-2012 Computer-Leipzig, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

