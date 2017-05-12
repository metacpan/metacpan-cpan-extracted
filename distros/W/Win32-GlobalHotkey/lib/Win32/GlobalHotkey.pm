package Win32::GlobalHotkey;

use strict;
use warnings;
use threads;
use threads::shared;
use Thread::Cancel;
use Carp;

=head1 NAME

Win32::GlobalHotkey - Use System-wide Hotkeys independently

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

require XSLoader;
XSLoader::load( 'Win32::GlobalHotkey', $VERSION );


# Look at (msdn RegisterHotkey)
# http://msdn.microsoft.com/en-us/library/windows/desktop/ms646309%28v=vs.85%29.aspx
use constant {
	MOD_ALT      => 0x0001,
	MOD_CONTROL  => 0x0002,
	MOD_NOREPEAT => 0x4000, # only OS-version >= 6.1 (Win7)
	MOD_SHIFT    => 0x0004,
	MOD_WIN      => 0x0008,
};

=head1 SYNOPSIS

    use Win32::GlobalHotkey;

    my $hk = Win32::GlobalHotkey->new;
    
    $hk->PrepareHotkey( 
        vkey     => 'B', 
        modifier => Win32::GlobalHotkey::MOD_ALT, 
        callback => sub { print "Hotkey pressed!\n" }, # Beware! - You are in another thread.
     );
    
    $hk->StartEventLoop;
    
    #...
    
    $hk->StopEventLoop;

=head1 DESCRIPTION

This module let you create system wide hotkeys. Prepare your Hotkeys with the C<PrepareHotkey> method.
C<StartEventLoop> will initialize a new thread, register all hotkeys and start the Message Loop for event receiving. 

B<The stored callback is executed in the context of the thread.>

=head1 METHODS

=head2 new

Constructs a new object.

You can pass a parameter C<warn> with your own callback method to the constuctor. Defaults to:

    Win32::GlobalHotkey->new( 
        warn => sub {
            carp $_[0];
        }
    );

B<Beware!> The callback is executed in thread context at the time the EventLoop is running.

=cut


sub new {
	my ( $class, %p ) = @_;
	
	my $this = bless {}, $class;
	
	$this->{warn} = $p{warn} // sub { carp $_[0] };
	
	$this->{Hotkey}    = {};
	$this->{EventLoop} = undef;
	
	return $this;
}


=head2 PrepareHotkey( parameter => value, ... )

Prepares the registration of an hotkey. Can be called multiple times (with different values). Can not be called after C<StartEventLoop>.

The following parameters are required:

=over 4

=item C<vkey>

The pressed key. Currently only the letter keys (a-z) are supported.

=item C<modifier>

=over 8

The Keyboard modifier (ALT, CTRL, SHIFT, WINDOWS). Use the following. Can be combinated with a Bitwise OR ("|").

=item C<Win32::GlobalHotkey::MOD_ALT>

=item C<Win32::GlobalHotkey::MOD_CONTROL>

=item C<Win32::GlobalHotkey::MOD_SHIFT>

=item C<Win32::GlobalHotkey::MOD_WIN>

=back

=item C<callback>

A subroutine reference which is called if the hotkey is pressed.

=back

=cut

# Hotkey Hash Format:
# vkey     => the virtuell (normal) key like a 'b'
# modifier => one of the modifiers above
# cb       => sub { ... }
# keycode  => ord uc vkey => the ascii (ansi?) keycode
#
# saved in the Hash Hotkey as keycode . modifier 

sub PrepareHotkey {
	my ( $this, %p ) = @_;
	
	if ( $this->{EventLoop} && $this->{EventLoop}->is_running ) {
		$this->{warn}->( 'EventLoop already running. Stop it to register another Hotkey' );
		return 0;
	}
	
	if ( not $p{vkey} =~ /^[A-Za-z]$/ ) {
		$this->{warn}->( 'vkey is not a letter key' );
		return 0;
	}
	
	my $keycode = ord uc $p{vkey}; # calculate ascii - use only upper case letters

	if ( exists $this->{Hotkey}{ $p{vkey} . $p{modifier} } ) {
		$this->{warn}->( 'Hotkey already prepared for registering' );
		return 0;
	}

	$this->{Hotkey}{ $p{vkey} . $p{modifier} } = 
		{ keycode => $keycode, vkey => $p{vkey}, modifier => $p{modifier}, cb => $p{cb} };
	
	return 1;
}

=head2 StartEventLoop

This method starts the MessageLoop for the (new) hotkey thread. You must stop it to change registered hotkeys
    
=cut

sub StartEventLoop {
	my $this = shift;
	
		
	$this->{EventLoop} = threads->create(  
		sub {
			
			my %atoms;
			
			for my $hotkey ( values %{ $this->{Hotkey} } ) {
				my $atom = XSRegisterHotkey( 
					$hotkey->{modifier}, 
					$hotkey->{keycode}, 
					'perl_Win32_GlobalHotkey_' . $hotkey->{vkey} . '_' . $hotkey->{modifier} 
				);

				if ( not $atom  ) {
					$this->{warn}->( "can not register Hotkey - already registered?" );
				} else {
					$atoms{ $atom } = $hotkey->{cb};
				}
			}
									
			while ( my $atom = XSGetMessage( ) ) {
				&{ $atoms{ $atom } };
			}
		}
	);
}

=head2 StopEventLoop

Stops the MessageLoop. Currently, it only detachs and kill the hotkey thread.

=cut

sub StopEventLoop {
	my $this = shift;
	
	#TODO: Unregister / Delete / correct join
	
	#sleep 2;
	$this->{EventLoop}->cancel;
	#$this->{EventLoop}->kill('KILL');
	#$this->{EventLoop}->join;
	#sleep 1;
	
	
	
#	$this->{EventLoop}->join;
}

=head2 GetConstant( name )

Static utility method to return the appropriate constant value for the given string.

=cut

sub GetConstant {
	no strict 'refs';
	return &{ $_[1] };	
}

=head1 AUTHOR

Tarek Unger, C<< <tu2 at gmx.net> >>

=head1 BUGS

Sure.

Please report any bugs or feature requests to C<bug-win32-globalhotkey at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Win32-GlobalHotkey>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 TODO


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Win32::GlobalHotkey

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Win32-GlobalHotkey>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Win32-GlobalHotkey>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Win32-GlobalHotkey>

=item * Search CPAN

L<http://search.cpan.org/dist/Win32-GlobalHotkey/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Tarek Unger.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1;

