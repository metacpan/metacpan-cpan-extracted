#!/usr/bin/perl

use strict;
use warnings;

use Win32::Service;

# -----------------

Win32::Service::StopService('', 'XMail');
