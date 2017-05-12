package Tkx::WinIco;
use strict;
use warnings;

use Carp;
use Tkx;

=head1 NAME

Tkx::WinIco - The taskbar extension for Tkx on Win.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Quick summary of what the module does.
Perhaps a little code snippet.

    use Tkx;
    use Tkx::WinIco;
    
    # Some Tk Stuff.
    Tkx::option_add('*Menu.tearOff', 0);
    
    # Get reference to "." and create context menu.
    my $mw   = Tkx::widget->new('.');
    my $menu = $mw->new_menu();
    
    $menu->add_command(
        -label   => 'Quit',
        -command => sub {
            $mw->g_destroy();
        },
    );
    
    # Create icon resource.
    my $icon = Tkx::WinIco->new('./icons/1.ico');
    
    # Add icon to taskbar.
    $icon->taskbar_add(text => 'Tooltip');
    
    # Change tooltip.
    $icon->taskbar_modify(-text => 'New tooltip');
    
    # Hide icon.
    $icon->taskbar_delete();
    
    # Restore icon.
    $icon->taskbar_add();
    
    # Bind events.
    $icon->bind('WM_RBUTTONUP' => sub {
        my ($ico, $message, $x, $y) = @_;
        $menu->g_tk___popup($x, $y);
    });
    
    # Main loop.
    Tkx::MainLoop();
    1;



=head1 INSTALLATION

Install Tkx::WinIco as usual perl package.

Download winico06.zip module from L<http://sourceforge.net/projects/tktable/files/winico/0.6/>
then extract Winico06.dll from archive and put it into same directory as a script.

However, you can specify any other path using

    use Tkx::WinIco {dll => './libs/winico.dll'};



=head1 METHODS

=cut

BEGIN {
    die "Tkx::WinIco is only for Win platform"
        if $^O !~ /^MSWin/;
}

sub import {
    my ($class, @fields) = @_;
    
    my $winico_dll = 'Winico06.dll';
    
    foreach my $field (@fields) {
        if (ref($field) eq 'HASH') {
            if (defined $field->{dll}) {
                $winico_dll = $field->{dll};
            }
        }
    }
    if (!Tkx::info_commands('winico')) {
        eval {Tkx::load($winico_dll)};
        if ($@) {
            croak "cannot load winico extension ($winico_dll)";
        }
    }    
}

=head2 new

=cut

sub new {
    my $class = shift  @_;
    my %param = scalar @_ == 1 ? (-createfrom => shift @_) : @_;
    
    my $self  = bless {}, $class;
    
    # Set default parameters.
    $self->{pos}       = 0;
    $self->{text}      = '',
    $self->{callbacks} = {};

    # Load icon resource.
    $self->{resource} = Tkx::winico_createfrom($param{-createfrom})
        if defined $param{-createfrom};
        
    $self->{resource} = Tkx::winico_load($param{-load})
        if defined $param{-load};
    
    # Return object.
    return $self;
}

=head2 bind

=cut

sub bind {
    my ($self, $ev, $cb) = @_;
    return if @_ < 2;
    
    if (defined $cb) {
        $self->{callbacks}->{$ev} = $cb;
    }
    else {
        return $self->{callbacks}->{$ev};
    }
}

=head2 taskbar_add

=cut

sub taskbar_add {
    my ($self, %args) = @_;
    
    $self->{pos}  = $args{-pos}  if defined $args{-pos};
    $self->{text} = $args{-text} if defined $args{-text};
    
    return Tkx::winico_taskbar_add(
        $self->{resource} => (
            -pos      => $self->{pos},
            -text     => $self->{text},
            -callback => [
                sub {
                    if (defined(my $m = shift)) {
                        $self->_call($self->{callbacks}->{$m}, $self, $m, @_);
                    }
                    
                },
                Tkx::Ev(qw[%m %x %y %X %Y]),            
            ],
        ),
    );
}

=head2 taskbar_modify

=cut

sub taskbar_modify {
    my ($self, %args) = @_;
    
    $self->{pos}  = $args{-pos}  if defined $args{-pos};
    $self->{text} = $args{-text} if defined $args{-text};
    
    return Tkx::winico_taskbar_modify(
        $self->{resource} => (
            -pos      => $self->{pos},
            -text     => $self->{text},    
        ),
    );    
}

=head2 taskbar_delete

=cut

sub taskbar_delete {
    return Tkx::winico_taskbar_delete(shift->{resource});
}

=head2 info

=cut

sub info {
    return Tkx::winico_info(shift->{resource});
}


sub _call {
    my($self, $callback, @args) = @_;
    return unless $callback;
    
    if (ref($callback) eq 'ARRAY') {
        my $cb_arrayref = shift @{$callback};
        
        if (ref($cb_arrayref) eq 'CODE') {
            return $cb_arrayref->(@{$callback}, @args);           
        }        
    }
    
    if (ref($callback) eq 'CODE') {
        return $callback->(@args);
    }
}


sub DESTROY {
    my ($self) = @_;
    
    if (defined $self->{resource}) {
        Tkx::winico_delete($self->{resource});
    }
}

=head1 AUTHOR

Alexander Nusov, C<< <alexander.nusov+cpan at gmail.com> >>


=head1 BUGS

Please report any bugs or feature requests to C<bug-tkx-winico at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Tkx-WinIco>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Tkx::WinIco


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Tkx-WinIco>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Tkx-WinIco>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Tkx-WinIco>

=item * Search CPAN

L<http://search.cpan.org/dist/Tkx-WinIco/>

=back


=head1 ACKNOWLEDGEMENTS

Leo Schubert, Brueckner&Jarosch Ing.-GmbH

Pat Thoyts.


=head1 LICENSE AND COPYRIGHT

Copyright 2010 Alexander Nusov.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut
1;
