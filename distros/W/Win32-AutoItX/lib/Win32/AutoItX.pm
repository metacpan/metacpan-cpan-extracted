package Win32::AutoItX;

=head1 NAME

Win32::AutoItX - Automate the Windows GUI using AutoItX

=head1 SYNOPSIS

    use Win32::AutoItX;

    my $a = Win32::AutoItX->new;

    ### AutoItX native methods ###

    my $pid = $a->Run('calc.exe');

    my $clipboard_text = $a->ClipGet;
    $a->ClipPut("Win32::AutoItX rulez!");
    
    my $color = $a->PixelGetColor(42, 42);

    ### Perlish methods ###

    my $window = $a->get_window('Calculator');
    $window->wait;
    for my $control ($window->find_controls) {
        local $\ = "\n";
        print "Control $control";
        print "\thandle: ", $control->handle;
        print "\ttext: ", $control->text;
        print "\tx: ", $control->x, "\ty: ", $control->y;
        print "\twidth: ", $control->width, "\theight: ", $control->height;
    }

    my $button_2 = $window->find_controls('2', class => 'Button');
    my $button_3 = $window->find_controls('3', class => 'Button');
    my $button_plus = $window->find_controls('+', class => 'Button');
    my $button_eq = $window->find_controls('=', class => 'Button');
    my $result = $window->find_controls('0', class => 'Static');

    $button_2->click;
    $button_3->click;
    $button_plus->click;
    $button_3->click;
    $button_2->click;
    $button_eq->click;

    print "23 + 32 = ", $result->text, "\n";



=head1 DESCRIPTION

Win32::AutoItX helps to automate the Windows GUI using the AutoItX COM
interface. To use this module you have to install AutoIt v3
(https://www.autoitscript.com/autoit3/) or register the AutoItX COM/ActiveX
component.

On the first constructor (L</new>) invoke it tries to initialize the COM
library. To avoid issues with the security context don't import L<Win32::OLE>
module in the same script using C<use>.

=cut

our $VERSION = '1.01';

use strict;
use warnings;

use Carp;
use Win32::AutoItX::Window;

my $initialized;

=head1 METHODS

=head2 new

    $obj = Win32::AutoItX->new(%options)

creates a new instance of Win32::AutoItX object.

Available options:

=over

=item debug

enables the debug mode (Win32::AutoItX will print additional information for
debugging).

=item ole_warn

determines the behavior of the L<Win32::OLE> module when an error happens.
Please see L<Win32::OLE/Warn>. Default is 3 (Carp::croak).

=item ole_cp

determines the codepage used by all translations between Perl strings and
Unicode strings used by the OLE interface. Please see L<Win32::OLE/CP>. Default
is CP_UTF8.

=back

=cut

sub new {
    my $class = shift;

    # Initialize COM and set Impersonation Level to RPC_C_IMP_LEVEL_DELEGATE
    if (not $initialized or $initialized != $$) {
        eval {
            require Win32::API;
            my $CoInit = Win32::API->new(
                "OLE32.DLL", "CoInitialize", "P", "N"
            ) or croak "Can't find CoInitialize";
            my $CoInitSec = Win32::API->new(
                "OLE32.DLL", "CoInitializeSecurity", "PNPPNNPNP", "N"
            ) or croak "Can't find CoInitializeSecurity";

            my $result = $CoInit->Call(0);
            croak "CoInitialize failed: $result"
                if not defined $result or $result != 0;
            $result = $CoInitSec->Call(0, -1, 0, 0, 0, 4, 0, 0, 0);
            croak "CoInitializeSecurity failed: $result"
                if not defined $result or $result != 0;
        };
        carp $@ if $@ and $ENV{AUTOITX_DEBUG};
        $initialized = $$;
    }

    require Win32::OLE;

    my %args = (
        debug    => $ENV{AUTOITX_DEBUG},
        ole_warn => 3,
        ole_cp   => Win32::OLE->CP_UTF8,
        @_
    );
    my $self = {
        debug => $args{debug} ? 1 : 0,
    };
    Win32::OLE->Option(Warn => $args{ole_warn});
    Win32::OLE->Option(CP   => $args{ole_cp});
    $self->{autoit} = Win32::OLE->new('AutoItX3.Control');
    print "AutoItX version ", $self->{autoit}->version, "\n",
          "Win32::AutoItX version $VERSION\n"
        if $self->{debug};

    return bless $self, $class;
}
#-------------------------------------------------------------------------------

=head2 debug

    $debug_is_enabled = $obj->debug
    $obj = $obj->debug($enable_debug)

if the argument is defined it enables or disables the debug mode and returns
the object reference. Otherwise it returns the current state of debug mode.

=cut

sub debug {
    my ($self, $value) = @_;
    if (defined $value) {
        $self->{debug} = $value ? 1 : 0;
        return $self;
    }
    return $self->{debug};
}
#-------------------------------------------------------------------------------

=head2 list_windows

    $hash_ref = $obj->list_windows($win_title)
    $hash_ref = $obj->list_windows($win_title, $win_text)

returns a hash reference with C<$handler =E<gt> $title> elements. Optionally
windows can be filtered by title and/or text.

=cut

sub list_windows {
    my $self = shift;
    my $list = $self->{autoit}->WinList(@_);
    return {} unless ref $list and ref $list eq 'ARRAY';
    my %result;
    for my $i (1 .. $#{$list->[0]}) {
        $result{$list->[1][$i]} = $list->[0][$i];
    }
    return \%result;
}
#-------------------------------------------------------------------------------

=head2 get_window

    $window = $a->get_window($title)
    $window = $a->get_window($title, $text)

returns a L<Win32::AutoItX::Window> object for the window with specified title
and text (optionally).

=cut

sub get_window {
    return Win32::AutoItX::Window->new(@_);
}
#-------------------------------------------------------------------------------

=head2 AutoItX methods

This module also autoloads all AutoItX methods. For example:

    $obj->WinActivate($win_title) unless $obj->WinActive($win_title);

Please see AutoItX Help file for documenation of all available methods.

=cut

sub AUTOLOAD {
    my $self = shift;
    my $method = our $AUTOLOAD;
    $method =~ s/.*:://;
    print "Call AutoItX method $method with params: @_\n"
        if $self->debug;
    $self->{autoit}->$method(@_);
}
#-------------------------------------------------------------------------------

=head1 ENVIRONMENT VARIABLES

=head2 AUTOITX_DEBUG

enables additional output to the STDOUT. Can be overwrited with C<debug> option
in the constructor (L</new>) or with method L</debug>.

=head1 SEE ALSO

=over

=item L<Win32::AutoItX::Window>

=item L<Win32::AutoItX::Control>

=item AutoItX Help

=item https://www.autoitscript.com/autoit3/docs/

=item L<Win32::OLE>

=back

=head1 AUTHOR

Mikhail Telnov E<lt>Mikhail.Telnov@gmail.comE<gt>

=head1 COPYRIGHT

This software is copyright (c) 2017 by Mikhail Telnov.

This library is free software; you may redistribute and/or modify it
under the same terms as Perl itself.

=cut

1;
