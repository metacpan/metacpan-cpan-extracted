# -*- perl -*-
#
#   HTML::EP::Wizard	- A Perl based HTML extension with supporting
#                         the Wizard Module
#
#
#   Copyright (C) 1998    Jochen Wiedmann
#                         Am Eisteich 9
#                         72555 Metzingen
#                         Germany
#
#                         Phone: +49 7123 14887
#                         Email: joe@ispsoft.de
#
#                         and
#
#                         Amarendran R. Subramanian
#                         Grundstr. 32
#                         72810 Gomaringen
#                         Germany
#
#                         Phone: +49 7072 920696
#                         Email: amar@ispsoft.
#
#   All rights reserved.
#
#   You may distribute this module under the terms of either
#   the GNU General Public License or the Artistic License, as
#   specified in the Perl README file.
#
############################################################################

require 5.004;
use strict;

use HTML::EP ();
use HTML::EP::Session ();
use Wizard::HTML ();

use vars ();

package HTML::EP::Wizard;

$HTML::EP::Wizard::VERSION = '0.1127';
@HTML::EP::Wizard::ISA = qw(HTML::EP HTML::EP::Session);

sub init {
    my $self = shift;
    $self->SUPER::init(@_);
}

sub _ep_wizard {
    my($self, $attr, $func) = @_;
    my $class = $attr->{'class'} || die "Missing class definition";

    my $cl = "$class.pm";
    $cl =~ s/\:\:/\//g;
    require $cl;

    my $cgi = $self->{'cgi'};
    my $wiz = Wizard::HTML->new({'ep' => $self}); 
    my $session = $self->{'session'};
    my $state = (ref($session->{'state'}) ?
		 $session->{'state'} : $class->new({}));
    $state = $wiz->Run($state);
    $self->{'htmlbody'} = $wiz->{'form'}->{'html-body'};
    $self->{'htmltitle'} = $wiz->{'form'}->{'html-title'};

    $self->_ep_session_store({}) if($self->{'state_modified'});
    '';
}

sub _ep_form_object {
    my $self = shift; my $attr = shift; my $func = shift;
    my $debug = $self->{'debug'};
    my $template;
    if (!defined($template = delete $attr->{template})) {
	$func->{'default'} ||= 'template';
        return undef;
    }
    my $output = '';

    my $wiz = $self->{'_ep_wizard'};
    my $form = $self->{'_ep_wizard_form'};
    die "Error cannot use ep_form_object without having a wizard " unless($wiz && $form);
    my $item = delete $attr->{item} or die "Missing item name";
    my $obj = $form->object($attr->{'name'}) || die "No such object " 
	                                           . $attr->{'name'};
    my($key, $val);
    while (($key, $val)= each %$attr) {
	$obj->{$key} = $val;
    }
    $self->{$item} = $obj;
    $output .= $self->ParseVars($template);
    $output;
}



