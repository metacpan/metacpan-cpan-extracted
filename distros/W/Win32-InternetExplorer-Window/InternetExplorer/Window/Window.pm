package Win32::InternetExplorer::Window;
use strict;
use vars qw($VERSION);
use Win32::OLE;


$VERSION = '0.01';

sub new {
    my $pkg = shift;
    if ( (scalar @_ % 2) != 0) {
        # invalid args
        die "new() : Invalid Arguments.\n";
    }

    # defaults
    my %ie_args = (
        'AddressBar' => '0',
        'MenuBar'    => '0',
        'Resizable'  => '0',
        'StatusBar'  => '0',
        'ToolBar'    => '0',
        'Silent'     => '0',
    );

    # overrides ?
    my %pkg_args = @_;
    if (exists $pkg_args{ole_args}) {
        # $pkg_args{ole_args} is a hash ref
        for (keys %{$pkg_args{ole_args}}) {
            $ie_args{$_} = ${$pkg_args{ole_args}}{$_};
        }
    }
    

    ## start browser
    my $ie = undef;
    if ($pkg_args{clobber}) {
        print "clbr...";
        $ie = Win32::OLE->GetActiveObject('InternetExplorer.Application','');
        if (! $ie) {
            print "not ";
            # none active, start one
            $ie = new Win32::OLE('InternetExplorer.Application','');
        }
        print "ok\n";
    } else {
        $ie = new Win32::OLE('InternetExplorer.Application','');
    }
    if (! $ie) {
        die "Could not Get/Launch Internet Explorer : $!\n";
    }

    ## Apply Defaults/Overrides
    foreach my $k (keys %ie_args) {
        #print "Set $k = $ie_args{$k}\n";
        $ie->{$k} = $ie_args{$k};
    }
    if ($pkg_args{height}) {
        $ie->{Height} = $pkg_args{height};
    }
    if ($pkg_args{width}) {
        $ie->{Width} = $pkg_args{width};
    }
    if ($pkg_args{pos}) {
        # array ref with X/Y
        $ie->{Top} = $pkg_args{pos}[1];
        $ie->{Left} = $pkg_args{pos}[0];
    }
    if ($pkg_args{no_popups}) {
        $ie->{Silent} = 1;
    }

    my $self = \%pkg_args;
    $self->{ole_obj} = $ie;

    # Catching clode of window ?
    #Win32::OLE->WithEvents($ie, 'IEvents');

    if ($self->{start_hidden}) {
        $self->{ole_obj}->{Visible} = 0;
    } else {
        $self->{ole_obj}->{Visible} = 1;
    }
    
    bless($self,$pkg);
}

sub hide {
    my ($self) = @_;
    $self->{ole_obj}->{Visible} = 0;
}

sub show {
    my ($self) = @_;
    $self->{ole_obj}->{Visible} = 1;
}

sub display {
    my ($self,$uri) = @_;
    $self->{ole_obj}->Navigate($uri);
}

sub display_wait {
    my ($self,$uri) = @_;
    $self->display($uri);
    while ($self->is_busy()) {
        sleep(1);
    }
}

sub is_busy {
    my ($self) = @_;
    return($self->{ole_obj}->{Busy});
}

sub is_closed {
    my ($self) = @_;
    if (! defined($self->{ole_obj})) {
        # no object
        return(1);
    } else {
        return(undef);
    }
}

sub current_url {
    my ($self) = @_;
    return($self->{ole_obj}->{LocationURL});
}

sub stop {
    my ($self) = @_;
    $self->{ole_obj}->Stop();
}

sub refresh {
    my ($self) = @_;
    $self->{ole_obj}->Refresh();
}

sub refresh_wait {
    my ($self) = @_;
    $self->{ole_obj}->Refresh();
    while ($self->is_busy()) {
        sleep(1);
    }
}

sub home {
    my ($self) = @_;
    $self->{ole_obj}->GoHome();
}

sub home_wait {
    my ($self) = @_;
    $self->{ole_obj}->GoHome();
    while ($self->is_busy()) {
        sleep(1);
    }
}

sub forward {
    my ($self) = @_;
    $self->{ole_obj}->GoForward();
}

sub backward {
    my ($self) = @_;
    $self->{ole_obj}->GoBack();
}

sub forward_wait {
    my ($self) = @_;
    $self->{ole_obj}->GoForward();
    while ($self->is_busy()) {
        sleep(1);
    }
}

sub backward_wait {
    my ($self) = @_;
    $self->{ole_obj}->GoBack();
    while ($self->is_busy()) {
        sleep(1);
    }
}

sub status {
    my ($self,$msg) = @_;
    $self->{ole_obj}->{StatusText} = $msg;
}

sub DESTROY {
    my ($self) = @_;
    $self->{ole_obj}->Quit();
}

1;



__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Win32::InternetExplorer::Window - Perl extension for using OLE to create controlable InternetExplorer windows

=head1 SYNOPSIS

  use Win32::InternetExplorer::Window;
  my $browser = Win32::InternetExplorer::Window->new(height => 210, 
                                                   width => 210,
                                                   pos => [10,0],
                                                   #no_popups => 1,
                                                   #start_hidden => 1
                                                   );
  $browser->display('http://www.aol.com');
  $browser->stop();
  sleep(2);
  $browser->refresh_wait();
  sleep(2);

  
=head1 DESCRIPTION

This module is for the creation of floating InternetExplorer windows with no tool bars. Also included is the control of that window.

As i get more work done, another name space will be added to allow embedding of IE rendering windows within Win32::GUI windows, i hope.

=head2 METHODS

=item $object = PKG->new([height => $pixels],[width => $pixels],[pos => [$x,$y]],[no_popups => 1],[start_hidden => 1])

This function creates a new object. In addition to the height, width, position and popups, arguments can be supplied to the OLE object using by passing a hashref to the ole_args argument. Like C<PKG-E<gt>new(ole_args =E<gt> {Visable =E<gt> 0})>

=item $object->display(URL)

display the given URL in the window. This method returns immediatly, and does not wait for the page to load. For a version that waits, see C<display_wait>

=item $object->display_wait(URL)

Same as display(), except that it sleeps as long as the browser is in a busy status.

=item $status = $object->is_busy()

Returns 1 if the browser is in a busy state, 0 otherwise

=item $status = $object->is_closed()

Returns 1 if the browser window has been closed by the user, 0 if it still exists.

=item $url = $object->current_url()

Returns the current URL.

=item $object->stop()

Stops loading of the current page when using C<$object-E<gt>display(URL)>

=item $object->refresh()

Refresh the display of the current page. Note that this returns immidiatly and does not wait for the page to load.

=item $object->refresh_wait()

Same as refresh, except this function waits for the page to load before returning.

=item $object->home()

Returns the browser to it's home page. This function does not wait for the page to load.

=item $object->home_wait()

same as CV<home> with the exception that this function waits until the page has loaded.

=item $object->forward()

Move forward one page. This function does not wait for the page to finish loading.

=item $object->forward_wait()

same as C<forward>, but does wait for page to finish loading.

=item $object->backward()

Move back one page. This function does not wait for the page to finish loading.

=item $object->backward_wait()

same as C<backward>, but does wait for page to finish loading.

=item $object->status(TEXT)

EXPERIMENTAL: if a status bar is displayed (using C<ole_args =E<gt> {StatusBar =E<gt> 1}> in the constuctor), this will set the text.



=head2 EXPORT

None.

=head2 TODO

=item *
Add better interface for including window decorations.


=head1 AUTHOR

MZSanford, E<lt>MZSanford@cpan.org<gt>

=head1 SEE ALSO

L<perl>.

=cut
