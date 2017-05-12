#! /usr/bin/perl
#---------------------------------------------------------------------
# 10.credentials.t
# Copyright 2008 Christopher J. Madsen
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either the
# GNU General Public License or the Artistic License for more details.
#
# Test the different ways to call the WebService::NFSN constructor
#---------------------------------------------------------------------

use Test::More;

use strict;
use warnings;
use File::Spec ();
use FindBin qw($Bin);

BEGIN {
  # RECOMMEND PREREQ: File::Temp
  eval "use File::Temp qw(tempdir)";
  plan skip_all => "File::Temp required" if $@;

  plan tests => 28;
}

use WebService::NFSN ();

#---------------------------------------------------------------------
# Create temporary "home" and current directories:

my $homeDir = tempdir(CLEANUP => 1);
my $curDir  = tempdir(CLEANUP => 1);

my $homeApi = File::Spec->catfile($homeDir, '.nfsn-api');

$ENV{HOME} = $homeDir;

chdir $curDir or die "Unable to cd $curDir";

#---------------------------------------------------------------------
# Capture warning messages:

my @warnings;

$SIG{__WARN__} = sub { push @warnings, $_[0] };

#---------------------------------------------------------------------
# Test with no credentials file:

my $nfsn = eval { WebService::NFSN->new };

like($@, qr/^You must supply a login/, 'No credentials error');
is($nfsn, undef, 'No credentials');
is(scalar @warnings, 1, 'No credentials 1 warning');
like($warnings[0], qr/^Unable to locate .*\.nfsn-api/, 'No credentials warning');

#---------------------------------------------------------------------
# Test with bad credentials file in home directory:

# This defines "user" instead of "login":
open(my $out, '>', $homeApi) or die "Can't write $homeApi: $!";
print $out qq'{ "user": "USER",  "api-key": "APIKEY" }\n';
close $out;

@warnings = ();
$nfsn = eval { WebService::NFSN->new };

like($@, qr/\.nfsn-api did not define "login"/, 'Bad credentials error');
is($nfsn, undef, 'Bad credentials');
is(scalar @warnings, 0, 'Bad credentials no warnings');

#---------------------------------------------------------------------
# Test with invalid credentials file in home directory:

# This is not valid JSON (no quotes around user):
open($out, '>', $homeApi) or die "Can't write $homeApi: $!";
print $out qq'{ user: USER,  "api-key": "APIKEY" }\n';
close $out;

@warnings = ();
$nfsn = eval { WebService::NFSN->new };

like($@, qr/^Error parsing .*\.nfsn-api:/, 'Invalid credentials error');
is($nfsn, undef, 'Invalid credentials');
is(scalar @warnings, 0, 'Invalid credentials no warnings');

#---------------------------------------------------------------------
# Test with credentials file in home directory:

open($out, '>', $homeApi) or die "Can't write $homeApi: $!";
print $out qq'{ "login": "USER",  "api-key": "APIKEY" }\n';
close $out;

@warnings = ();
$nfsn = eval { WebService::NFSN->new };

is($@, '', 'Home credentials no error');
isa_ok($nfsn, 'WebService::NFSN', 'Home credentials');
is(scalar @warnings, 0, 'Home credentials no warnings');
is($nfsn->{login}, 'USER', 'Home credentials login');
is($nfsn->{apiKey}, 'APIKEY', 'Home credentials apiKey');

#---------------------------------------------------------------------
# Test with credentials file in home directory and current directory:

open($out, '>', '.nfsn-api') or die "Can't write .nfsn-api: $!";
print $out qq'{ "login": "CURUSER",  "api-key": "CURAPIKEY" }\n';
close $out;

@warnings = ();
$nfsn = eval { WebService::NFSN->new };

is($@, '', 'Current credentials no error');
isa_ok($nfsn, 'WebService::NFSN', 'Current credentials');
is(scalar @warnings, 0, 'Current credentials no warnings');
is($nfsn->{login}, 'CURUSER', 'Current credentials login');
is($nfsn->{apiKey}, 'CURAPIKEY', 'Current credentials apiKey');

#---------------------------------------------------------------------
# Test with credentials as parameters:

@warnings = ();
$nfsn = eval { WebService::NFSN->new(qw(LOGIN MYKEY)) };

is($@, '', 'Parameter credentials no error');
isa_ok($nfsn, 'WebService::NFSN', 'Parameter credentials');
is(scalar @warnings, 0, 'Parameter credentials no warnings');
is($nfsn->{login}, 'LOGIN', 'Parameter credentials login');
is($nfsn->{apiKey}, 'MYKEY', 'Parameter credentials apiKey');

#---------------------------------------------------------------------
# Test with only login:

@warnings = ();
$nfsn = eval { WebService::NFSN->new('LOGIN') };

like($@, qr/^You must supply an API key/, 'Login only error');
is($nfsn, undef, 'Login only');
is(scalar @warnings, 0, 'Login only no warnings');

#---------------------------------------------------------------------
chdir $Bin;
