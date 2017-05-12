#!/usr/bin/perl -I . 
#
use Tk::Application::Stadaf;

$AQ=Tk::Application::Stadaf->new('stadaf','Stadaf Viewer') || die "can't init";

$AQ->SETUP || die "can't Setup";
$AQ->RUN;

undef $AQ;

__END__

