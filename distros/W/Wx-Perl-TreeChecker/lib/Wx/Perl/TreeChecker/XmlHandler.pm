#############################################################################
## Name:        Wx::Perl::TreeChecker::XmlHandler
## Purpose:     XRC handler for Wx::Perl::TreeChecker
## Author:      Simon Flack
## Modified by: $Author: simonflack $ on $Date: 2004/04/17 22:17:13 $
## Created:     28/11/2002
## RCS-ID:      $Id: XmlHandler.pm,v 1.1 2004/04/17 22:17:13 simonflack Exp $
#############################################################################

package Wx::Perl::TreeChecker::XmlHandler;

use strict;
use vars qw/@ISA $VERSION/;
use Wx qw(:misc :treectrl);

@ISA = 'Wx::PlXmlResourceHandler';
$VERSION = sprintf'%d.%02d', q$Revision: 1.1 $ =~ /: (\d+)\.(\d+)/;


sub new {
    my $class = shift;
    my $self = $class -> SUPER::new(@_);
    no strict 'refs';
    for (grep /^wxTR_/, @{$Wx::EXPORT_TAGS{'treectrl'}}) {
        $self -> AddStyle ($_, &$_);
    }
    $self -> AddWindowStyles;
    return $self;
}

sub CanHandle {
    my $self = shift;
    my ($xmlnode) = @_;
    return $self -> IsOfClass ($xmlnode, 'Wx::Perl::TreeChecker');
}

sub DoCreateResource {
    my $self = shift;

    my @args = (
         $self -> GetID,
         $self -> GetPosition()         || wxDefaultPosition,
         $self -> GetSize()             || wxDefaultSize,
         $self -> GetStyle ('style', 0) || wxTR_HAS_BUTTONS,
         wxDefaultValidator,
         $self -> GetName ()            || 'treeChecker'
    );
    my $ctrl;
    my $parent = $self -> GetInstance() || $self -> GetParentAsWindow();
    if ($self -> GetInstance()) {
        $ctrl = Wx::Perl::TreeChecker -> Create ($parent, @args);
    } else {
        $ctrl = Wx::Perl::TreeChecker -> new    ($parent, @args);
    }

    $self -> SetupWindow    ($ctrl);
    $self -> CreateChildren ($ctrl);

    return $ctrl;
}


1;

=pod

=head1 NAME

Wx::Perl::TreeChecker::XmlHandler - XRC handler for Wx::Perl::TreeChecker

=head1 SYNOPSIS

  use Wx::Perl::TreeChecker::XmlHandler;
  $xrc->AddHandler (new Wx::Perl::TreeChecker::XmlHandler);

=head1 DESCRIPTION

An Wx::XmlHandler for Wx::Perl::TreeChecker objects. Allows you to define tree
checkers in your xml resource files.

=head1 EXAMPLE

   <object class="Wx::Perl::TreeChecker" name="my_treechecker"/>

=head1 AUTHOR

Simon Flack E<lt>simonflk _AT_ cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2003 Simon Flack E<lt>simonflk _AT_ cpan.orgE<gt>.
All rights reserved

You may distribute under the terms of either the GNU General Public License or
the Artistic License, as specified in the Perl README file.

=cut
