WWW::PagerDuty
===================

This is a perl client for the Pager Duty public API.

     use WWW::PagerDuty
     my $pager_duty = new WWW::PagerDuty({ service_key => 'e93facc04764012d7bfb002500d5d1a6', incident_key => 'srv01/HTTP'});
     $result = $pager_duty->trigger({ description => 'required input', details => { 'optional' => 'optional' } });
     $result = $pager_duty->resolve({ description => 'required input', details => { 'optional' => 'optional' } });
    


## Install

To install this module, make sure you have `LWP::UserAgent` and `JSON` available, then run the following commands

    perl Makefile.PL
    make
    sudo make install

