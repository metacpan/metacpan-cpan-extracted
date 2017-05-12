#!/usr/bin/perl
# $File: //member/autrijus/WWW-SherlockSearch/Makefile.PL $ 
# $Revision: #6 $ $Change: 10623 $ $DateTime: 2004/05/22 08:07:29 $

use inc::Module::Install;

name        ('WWW-SherlockSearch');
version_from('lib/WWW/SherlockSearch.pm');
license     ('perl');
recommends  ('XML::Atom' => '0.07');
recommends  ('XML::RSS' => '0.90');
recommends  ('Encode::compat' => '0.05') if $] < 5.007001;
requires    (
    'LWP'                   => '5.60',
    'HTTP::Cookies'         => '1.00',
    'HTTP::Request::Common' => '1.00',
    'HTML::Entities'        => '0.00',
);

&WriteAll( sign => 1 );
