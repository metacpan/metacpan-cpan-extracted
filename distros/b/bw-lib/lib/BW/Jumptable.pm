# BW::Jumptable.pm
# Jump table support for BW::*
# 
# by Bill Weinman - http://bw.org/
# Copyright (c) 1995-2010 The BearHeart Group, LLC
#
# See POD for History

package BW::Jumptable;
use strict;
use warnings;

use base qw( BW::Base );
use BW::Constants;

our $VERSION = "1.3.1";

sub _init
{
    my $self = shift;
    $self->SUPER::_init(@_);

    return FAILURE unless $self->{jumptable};

    return SUCCESS;
}

# _setter_getter entry points
sub jumptable { BW::Base::_setter_getter(@_); }

sub jump
{
    my $sn     = 'jump';
    my $self   = shift;
    my $action = shift;

    return $self->_error("$sn: no action") unless $action;

    foreach my $j ( keys %{ $self->{jumptable} } ) {
        if ( $j eq $action ) {
            &{ $self->{jumptable}{$j} }();
            return SUCCESS;
        }
    }

    return $self->_error("$sn: action not found ($action)");
}

1;

__END__

=head1 NAME

BW::Jumptable - Jump table support for BW::*

=head1 SYNOPSIS

  use BW::Jumptable;
  my $errstr;
  my $jumptable = {
    create => \&create,
    retrieve => \&retrieve,
    update => \&update,
    delete => \&delete
  }
  my $jt = BW::Jumptable->new( jumptable => $jumptable );
  $jt->jump($q->{action});
  error($errstr) if (($errstr = $jt->error));

=head1 METHODS

=over 4

=item B<new>( jumptable => $hashref )

Creates a new BW::Jumptable object and initializes the jump table. The 
jumptable property is required. Returns the blessed object handle, or 
undef if it cannot properly initialize. 

=item B<jump>( $action )

Execute a jump. Calls the function referenced in jumptable by the key 
that matches $action. Returns the value returned by the function, or 
FAILURE for an error condition. Sets the object error message (see 
the error() method) for error conditions.

=item B<error>

Returns and clears the object error message. 

=back

=head1 AUTHOR

Written by Bill Weinman E<lt>http://bw.org/E<gt>.

=head1 COPYRIGHT

Copyright (c) 1995-2010 The BearHeart Group, LLC

=head1 HISTORY

    2010-02-02 bw 1.3.1 -- first CPAN version - some cleanup and documenting
    2007-07-16 bw       -- bugfix - method jump() assumed that the target 
                           never returned. 
    2007-02-22 bw       -- initial release.

=cut

