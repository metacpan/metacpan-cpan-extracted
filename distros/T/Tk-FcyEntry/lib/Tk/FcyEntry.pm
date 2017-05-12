package Tk::FcyEntry;

use 5.008000;
use strict;
use warnings;

use Tk;
use Tk::Widget;
use Tk::Derived;
use Tk::Entry;

use base qw/ Tk::Derived Tk::Entry /;

{
    local($^W)=0;  # suppress Entry overriden warning
    Construct Tk::Widget 'Entry';
}

our $VERSION = '1.8';

=head1 NAME

Tk::FcyEntry - Entry that reflects its state in the background color

=head1 SYNOPSIS

  use Tk;
  use Tk::FcyEntry;	# replaces the standard Entry widget
  ...
  $fcye = $w->Entry( ... everything as usual ... );
  ...

=head1 DESCRIPTION

This module is deprecated. Use L<Tk::Entry> instead, it does the same thing.

B<FcyEntry> is like a normal L<Entry|Tk::Entry> widget except:

=over 4

=item *

default background color is 'white'

=item *

if the state of the widget is disabled the background color is set
to be the same as the normal background and the foreground used is
the same as the disabledForeground of a button. (xxx: still not true,
values hardcoded)

=back

=cut

sub Populate
  {
    my ($w,$args) = @_;

    $w->ConfigSpecs(
        '-state',     => ['METHOD',  'state',       'State',      'normal'],
        '-editcolor'  => ['PASSIVE', 'editColor',   'EditColor',  Tk::WHITE()],
        '-background' => ['PASSIVE', 'background',  'Background', Tk::NORMAL_BG()],
        '-foreground' => ['PASSIVE', 'foreground*,  *Foreground', Tk::BLACK()],
        'DEFAULT'     => ['SELF'],
	);
    $w;
};

sub state {
    my ($w) = shift;
    if (@_) {
        my $state = shift;
        if ($state eq 'normal') {
            $w->Tk::Entry::configure(-background => $w->{Configure}{-editcolor} || Tk::NORMAL_BG());
            $w->Tk::Entry::configure(-foreground => $w->{Configure}{-foreground} || Tk::BLACK());
        } else {
            $w->Tk::Entry::configure(-background => $w->{Configure}{-background} );
            $w->Tk::Entry::configure(-foreground => Tk::DISABLED());
        }
    	$w->Tk::Entry::configure(-state => $state);
    } else {
        $w->Tk::Entry::cget('-state');
    }
};

=head1 BUGS

background configuration honoured after next state change.


=head1 SEE ALSO

L<Tk|Tk>
L<Tk::Entry|Tk::Entry>

=head1 AUTHOR

Written by Achim Bohnet <F<ach@mpe.mpg.de>>. 
Maintained by Alexander Becker, E<lt>asb@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016 by Alexander Becker,
Copyright (c) 1997-1998 Achim Bohnet.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.16.3 or,
at your option, any later version of Perl 5 you may have available.


=cut


1; # /Tk::FcyEntry