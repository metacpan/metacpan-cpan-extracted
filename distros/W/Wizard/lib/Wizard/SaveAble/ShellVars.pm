# -*- perl -*-
#
#   Wizard - A Perl package for implementing system administration
#            applications in the style of Windows wizards.
#
#
#   This module is
#
#           Copyright (C) 1999     Jochen Wiedmann
#                                  Am Eisteich 9
#                                  72555 Metzingen
#                                  Germany
#
#                                  Email: joe@ispsoft.de
#                                  Phone: +49 7123 14887
#
#                          and     Amarendran R. Subramanian
#                                  Grundstr. 32
#                                  72810 Gomaringen
#                                  Germany
#
#                                  Email: amar@ispsoft.de
#                                  Phone: +49 7072 920696
#
#   All Rights Reserved.
#
#   You may distribute under the terms of either the GNU General Public
#   License or the Artistic License, as specified in the Perl README file.
#
#   $Id$
#

use strict;

use Symbol ();
use Data::Dumper ();
use IO::AtomicFile ();
use File::Basename ();
use File::Path ();

package Wizard::SaveAble::ShellVars;

@Wizard::SaveAble::ShellVars::ISA = qw(Wizard::SaveAble);
$Wizard::SaveAble::VERSION = '0.01';


sub _load {
    my $proto = shift; my $file = shift; my $prefix = shift;
    my $self = { 'prefix' => $prefix };
    my $line;
    my $fh = Symbol::gensym;
    open($fh, $file) or die "Failed to open file $file: $!";
    while($line=<$fh>) {
	chop($line);
	if($line =~ /^([^\=]+)\=\"?(.*[^\"])\"?/) {
	    $self->{$prefix . $1} = $2 ;
	}
    }
    close(FH);
    bless($self, (ref($proto) || $proto));

    $self->Modified(0);
    $self->File($file);
    $self;
}

sub new {
    my $proto = shift;
    my $self = { @_ };
    my $file = delete $self->{'file'} if (exists($self->{'file'}));
    my $prefix = $self->{'prefix'};
    if (exists($self->{'load'})  and  delete $self->{'load'}) {
	return $proto->_load($file, $prefix) if $file and -f $file;
    }
    bless($self, (ref($proto) || $proto));
    $self->Modified(1);
    $self->File($file);
    $self->CreateMe($file);
    $self;
}

sub File {
    my $self = shift;
    $self->{'_wizard_saveable_file'} = shift if @_;
    $self->{'_wizard_saveable_file'};
}


sub Store {
    my $self = shift;
    my $prefix = $self->{'prefix'};

    return unless $self->{'_wizard_saveable_modified'};

    my $file = $self->{'_wizard_saveable_file'};
    my $dir = File::Basename::dirname($file);
    die "Failed to create directory $dir: $!"
	unless -d $dir  ||  File::Path::mkpath([$dir], 0, 0644);

    my $tow = '';
    foreach my $key (keys %$self) {
	if($key =~ /^$prefix(.*)$/) {
	    $tow .= "$1=" . '"' . $self->{$key} . '"' . "\n";
	}
    }

    my $fh = IO::AtomicFile->open($file, "w")
	or die "Failed to create file $file: $!";
    if (!$fh->print($tow)  ||  !$fh->close()) {
	my $msg = $!;
	$fh->delete();
	die "Failed to write file $file: $msg";
    }
    $self->Modified(0);
}


=pod

=head1 AUTHORS AND COPYRIGHT

This module is

  Copyright (C) 1999     Jochen Wiedmann
                         Am Eisteich 9
                         72555 Metzingen
                         Germany

                         Email: joe@ispsoft.de
                         Phone: +49 7123 14887

                 and     Amarendran R. Subramanian
                         Grundstr. 32
                         72810 Gomaringen
                         Germany

                         Email: amar@ispsoft.de
                         Phone: +49 7072 920696

All Rights Reserved.

You may distribute under the terms of either the GNU General Public
License or the Artistic License, as specified in the Perl README file.


=head1 SEE ALSO

L<Wizard(3)>, L<Wizard::State(3)>

=cut

