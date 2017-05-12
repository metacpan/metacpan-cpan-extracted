#!/usr/bin/perl -I .
#
use Tk::Application::dbfdump;

$APP=Tk::Application::dbfdump->new('xdbfdump','pTk - dbfdump '.$^O) || die "can't init";

$APP->SETUP || die "can't setup";
$APP->RUN;

undef $APP;

__END__
