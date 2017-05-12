use strict;

use lib ('./blib','../blib', './lib', '../lib');

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Text-FixEOL.t'

#########################
# change 'tests => 3' to 'tests => last_test_to_print';


use Test::More (tests => 22);

#########################
# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

#########
# Test 1
BEGIN {
    use_ok('Text::FixEOL');
}

#########
# Test 2
require_ok ('Text::FixEOL');

#########
# Test 3
ok (test_unix_eol());

#########
# Test 4
ok (test_dos_eol());

#########
# Test 5
ok (test_mac_eol());

#########
# Test 6
ok (test_network_eol());

#########
# Test 7
ok (test_crlf_eol());

#########
# Test 8
ok (test_literal_eol());

#########
# Test 9
ok (test_default_modes());

#########
# Test 10
ok (test_crlf_modes());

#########
# Test 11
ok (test_dos_modes());

#########
# Test 12
ok (test_unix_modes());

#########
# Test 13
ok (test_mac_modes());

#########
# Test 14
ok (test_network_modes());

#########
# Test 15
ok (test_constructor_as_hash());

#########
# Test 16
ok (test_constructor_as_list());

#########
# Test 17
ok (test_constructor_modes());

#########
# Test 18
ok (test_fix_eol());

#########
# Test 19
ok (test_eof_handling());

#########
# Test 20
ok (test_asis_eol());

#########
# Test 21
ok (test_invalid_platform_property());

#########
# Test 22
ok (test_invalid_object_property());

exit;

#####################################################################
#####################################################################

sub test_constructor_modes {
    {
        my $result = eval {
            my $fixer = Text::FixEOL->new;
            return $fixer;
        };
        if ($@ or not $result) {
            diag("Direct mode constructor failed");
            return 0;
        }
    }

    {
        my $result = eval {
            my $fixer_proto = Text::FixEOL->new;
            my $fixer       = $fixer_proto->new;
            return $fixer;
        };
        if ($@ or not $result) {
            diag("Instance mode constructor failed");
            return 0;
        }
    }

    {
        my $result = eval {
            my $fixer = Text::FixEOL::new;
            return $fixer;
        };
        if ($@ or not $result) {
            diag("Static mode constructor failed");
            return 0;
        }
    }

    {
        my $result = eval {
            my $fixer = new Text::FixEOL;
            return $fixer;
        };
        if ($@ or not $result) {
            diag("Indirect mode constructor failed");
            return 0;
        }
    }
    return 1;
}

sub test_constructor_as_list {
    eval { my $fixer = Text::FixEOL->new( BadDog => 1 ); };
    unless ($@) {
        diag("Constructor failed to catch invalid parameter names as a list");
    }

    eval { my $fixer = Text::FixEOL->new('BadDog'); };
    unless ($@) {
        diag("Constructor failed to catch invalid parameter typing as a last");
    }

    {
        my $fixer = Text::FixEOL->new( 'eol' => 'mac', 'eof' => 'dos', 'fixlast' => 'network' );
        unless ($fixer->eol_handling eq 'mac') {
            diag("Constructor set EOL handling as list was NOT 'mac'");
            return 0;
        }
        unless ($fixer->eof_handling eq 'dos') {
            diag("Constructor set EOL handling as list was NOT 'dos'");
            return 0;
        }
        unless ($fixer->fix_last_handling eq 'network') {
            diag("Constructor set 'fix last' handling as list was NOT 'network'");
            return 0;
        }
    }
}

sub test_constructor_as_hash {
    eval { my $fixer = Text::FixEOL->new({ BadDog => 1 }); };
    unless ($@) {
        diag("Constructor failed to catch invalid parameter names as a hash");
    }
    {
        my $fixer = Text::FixEOL->new({ 'eol' => 'mac', 'eof' => 'dos', 'fixlast' => 'network' });
        unless ($fixer->eol_handling eq 'mac') {
            diag("Constructor set EOL handling as hash was NOT 'mac'");
            return 0;
        }
        unless ($fixer->eof_handling eq 'dos') {
            diag("Constructor set EOL handling as hash was NOT 'dos'");
            return 0;
        }
        unless ($fixer->fix_last_handling eq 'network') {
            diag("Constructor set 'fix last' handling as hash was NOT 'network'");
            return 0;
        }
    }
}

sub test_default_modes {
        my $fixer = Text::FixEOL->new;

        unless ($fixer->eol_handling eq 'platform') {
            diag("Default EOL handling was NOT 'platform'");
            return 0;
        }
        unless ($fixer->eof_handling eq 'platform') {
            diag("Default EOL handling was NOT 'platform'");
            return 0;
        }
        unless ($fixer->fix_last_handling eq 'platform') {
            diag("Default 'fix last' handling was NOT 'platform'");
            return 0;
        }
        return 1;
}

sub test_crlf_modes {
        my $fixer = Text::FixEOL->new;

        $fixer->eol_handling('crlf');
        unless ($fixer->eol_handling eq 'crlf') {
            diag("EOL handling was NOT 'crlf' after setting");
            return 0;
        }
        $fixer->eof_handling('crlf');
        unless ($fixer->eof_handling eq 'crlf') {
            diag("EOL handling was NOT 'crlf' after setting");
            return 0;
        }
        $fixer->fix_last_handling('crlf');
        unless ($fixer->fix_last_handling eq 'crlf') {
            diag("'fix last' handling was NOT 'crlf' after setting");
            return 0;
        }
        return 1;
}

sub test_dos_modes {
        my $fixer = Text::FixEOL->new;

        $fixer->eol_handling('dos');
        unless ($fixer->eol_handling eq 'dos') {
            diag("Setting of eol_handling failed. Expected 'dos', got '" . $fixer->eol_handling . "'");
            return 0;
        }
        unless ($fixer->eol_mode eq "\015\012") {
            diag("eol mode incorrect for DOS");
            return 0;
        }
        $fixer->fix_last_handling('dos');
        unless ($fixer->fix_last_handling eq 'dos') {
            diag("Default 'fix last' handling was NOT 'dos'");
            return 0;
        }

        return 1;
}

sub test_unix_modes {
        my $fixer = Text::FixEOL->new;
        $fixer->eol_handling('unix');
        unless ($fixer->eol_handling eq 'unix') {
            diag("Setting of eol_handling failed. Expected 'unix', got '" . $fixer->eol_handling . "'");
            return 0;
        }
        unless ($fixer->eol_mode eq "\012") {
            diag("eol mode incorrect for Unix");
            return 0;
        }
        $fixer->fix_last_handling('unix');
        unless ($fixer->fix_last_handling eq 'unix') {
            diag("Default 'fix last' handling was NOT 'unix'");
            return 0;
        }
        return 1;
}

sub test_mac_modes {
        my $fixer = Text::FixEOL->new;

        $fixer->eol_handling('mac');
        unless ($fixer->eol_handling eq 'mac') {
            diag("Setting of eol_handling failed. Expected 'mac', got '" . $fixer->eol_handling . "'");
            return 0;
        }
        unless ($fixer->eol_mode eq "\015") {
            diag("eol mode incorrect for Mac");
            return 0;
        }
        $fixer->fix_last_handling('mac');
        unless ($fixer->fix_last_handling eq 'mac') {
            diag("Default 'fix last' handling was NOT 'mac'");
            return 0;
        }
        return 1;
}

sub test_network_modes {
        my $fixer = Text::FixEOL->new;
        $fixer->eol_handling('network');
        unless ($fixer->eol_handling eq 'network') {
            diag("Setting of eol_handling failed. Expected 'network', got '" . $fixer->eol_handling . "'");
            return 0;
        }
        unless ($fixer->eol_mode eq "\015\012") {
            diag("eol mode incorrect for network");
            return 0;
        }
        $fixer->fix_last_handling('network');
        unless ($fixer->fix_last_handling eq 'network') {
            diag("Default 'fix last' handling was NOT 'network'");
            return 0;
        }
        return 1;
}

#########################

sub test_unix_eol {
    my $map_list = map_list();
    my $fixer    = Text::FixEOL->new;
    my $counter  = 0;
    foreach my $map_pair (@$map_list) {
        my ($source_string, $target_string) = @$map_pair;
        my $fixed_string = $fixer->eol_to_unix($source_string);
        if ($fixed_string ne $target_string) {
            $source_string = url_escape($source_string);
            $fixed_string  = url_escape($fixed_string);
            $target_string = url_escape($target_string);
            diag("unix data line $counter: did not convert '$source_string' correctly. Expected '$target_string', got '$fixed_string'");
            return 0;
        }
        $counter++;
    }
    return 1;
}

#########################

sub test_dos_eol {
    my $map_list = map_list();
    my $fixer    = Text::FixEOL->new;
    my $counter  = 0;
    foreach my $map_pair (@$map_list) {
        my ($source_string, $target_string) = @$map_pair;
        $target_string =~ s/\012/\015\012/gs;
        my $fixed_string = $fixer->eol_to_dos($source_string);
        if ($fixed_string ne $target_string) {
            $source_string = url_escape($source_string);
            $fixed_string  = url_escape($fixed_string);
            $target_string = url_escape($target_string);
            diag("dos data line $counter: did not convert '$source_string' correctly. Expected '$target_string', got '$fixed_string'");
            return 0;
        }
        $counter++;
    }
    return 1;
}

#########################

sub test_mac_eol {
    my $map_list = map_list();
    my $fixer    = Text::FixEOL->new;
    my $counter  = 0;
    foreach my $map_pair (@$map_list) {
        my ($source_string, $target_string) = @$map_pair;
        $target_string =~ s/\012/\015/gs;
        my $fixed_string = $fixer->eol_to_mac($source_string);
        if ($fixed_string ne $target_string) {
            $source_string = url_escape($source_string);
            $fixed_string  = url_escape($fixed_string);
            $target_string = url_escape($target_string);
            diag("mac data line $counter: did not convert '$source_string' correctly. Expected '$target_string', got '$fixed_string'");
            return 0;
        }
        $counter++;
    }
    return 1;
}

#########################

sub test_network_eol {
    my $map_list = map_list();
    my $fixer    = Text::FixEOL->new;
    my $counter  = 0;
    foreach my $map_pair (@$map_list) {
        my ($source_string, $target_string) = @$map_pair;
        $target_string =~ s/\012/\015\012/gs;
        my $fixed_string = $fixer->eol_to_network($source_string);
        if ($fixed_string ne $target_string) {
            $source_string = url_escape($source_string);
            $fixed_string  = url_escape($fixed_string);
            $target_string = url_escape($target_string);
            diag("network data line $counter: did not convert '$source_string' correctly. Expected '$target_string', got '$fixed_string'");
            return 0;
        }
        $counter++;
    }
    return 1;
}

#########################

sub test_invalid_object_property {
    my $fixer    = Text::FixEOL->new({ 'eol' => 'asis' });

    eval {my $test = $fixer->_property('unix','no such property','too many parms');};
    unless ($@) {
        diag("Failed to catch invalid object property request");
        return 0;
    }
    return 1;
}

#########################

sub test_invalid_platform_property {
    my $fixer    = Text::FixEOL->new({ 'eol' => 'asis' });

    eval {my $test = $fixer->_platform_defaults('unix','no such property');};
    unless ($@) {
        diag("Failed to catch invalid platform default property request");
        return 0;
    }
    return 1;
}

#########################

sub test_asis_eol {
    my $map_list = map_list();
    my $fixer    = Text::FixEOL->new({ 'eol' => 'asis' });
    my $counter  = 0;
    foreach my $map_pair (@$map_list) {
        my ($source_string, $target_string) = @$map_pair;
        $target_string = $source_string;
        my $fixed_string = $fixer->fix_eol($source_string);
        if ($fixed_string ne $target_string) {
            $source_string = url_escape($source_string);
            $fixed_string  = url_escape($fixed_string);
            $target_string = url_escape($target_string);
            diag("asis data line $counter: did not convert '$source_string' correctly. Expected '$target_string', got '$fixed_string'");
            return 0;
        }
        $counter++;
    }
    return 1;
}

#########################

sub test_crlf_eol {
    my $map_list = map_list();
    my $fixer    = Text::FixEOL->new;
    my $counter  = 0;
    foreach my $map_pair (@$map_list) {
        my ($source_string, $target_string) = @$map_pair;
        $target_string =~ s/\012/\015\012/gs;
        my $fixed_string = $fixer->eol_to_crlf($source_string);
        if ($fixed_string ne $target_string) {
            $source_string = url_escape($source_string);
            $fixed_string  = url_escape($fixed_string);
            $target_string = url_escape($target_string);
            diag("crlf data line $counter: did not convert '$source_string' correctly. Expected '$target_string', got '$fixed_string'");
            return 0;
        }
        $counter++;
    }
    return 1;
}

#########################

sub test_literal_eol {
    my $map_list = map_list();
    my $fixer    = Text::FixEOL->new( 'eol' => "literal:\010" );
    my $counter  = 0;
    foreach my $map_pair (@$map_list) {
        my ($source_string, $target_string) = @$map_pair;
        $target_string =~ s/\012/\010/gs;
        my $fixed_string = $fixer->fix_eol($source_string);
        if ($fixed_string ne $target_string) {
            $source_string = url_escape($source_string);
            $fixed_string  = url_escape($fixed_string);
            $target_string = url_escape($target_string);
            diag("crlf data line $counter: did not convert '$source_string' correctly. Expected '$target_string', got '$fixed_string'");
            return 0;
        }
        $counter++;
    }
    return 1;
}

#########################

sub test_fix_eol {
    my $fixer = Text::FixEOL->new('eol' => 'crlf', 'fixlast' => 'no', 'eof' => 'remove');
    my $null_string = $fixer->fix_eol(undef);
    unless (defined($null_string) and ($null_string eq '')) {
        diag("Failed to autoupgrade an undef value to empty string");
        return 0;
    }
    eval {
        my $result = $fixer->fix_eol();
    };
    unless ($@) {
        diag("Failed to catch mis-call without parameters to fix_eol");
        return 0;
    }
    eval {
        my $result = $fixer->fix_eol('s','d');
    };
    unless ($@) {
        diag("Failed to catch mis-call with extra parameters to fix_eol");
        return 0;
    }
    return 1;
}

sub test_eof_handling {
    my $fixer = Text::FixEOL->new;

    $fixer->eol_handling('crlf');
    $fixer->fix_last_handling('yes');
    $fixer->eof_handling('remove');

    my $test_string = "a\032";
    unless ($fixer->fix_eol($test_string) eq "a\015\012") {
        diag("Failed to remove EOF");
        return 0;
    }

    $fixer->eof_handling('asis');
    unless ($fixer->fix_eol($test_string) eq "a\015\012\032") {
        diag("Failed to leave EOF 'asis' correctly");
        return 0;
    }

    $fixer->eof_handling('add');
    unless ($fixer->fix_eol($test_string) eq "a\015\012\032") {
        diag("Failed to handle 'add' with pre-existing EOF correctly");
        return 0;
    }

    $test_string = 'a';
    $fixer->eof_handling('add');
    unless ($fixer->fix_eol($test_string) eq "a\015\012\032") {
        diag("Failed to add EOF when none present");
        return 0;
    }

    $test_string = "\032";
    $fixer->eof_handling('remove');
    unless ($fixer->fix_eol($test_string) eq "\015\012") {
        diag("Failed to remove EOF on blank string. Expected " . url_escape("\015\012") . " got " . url_escape($fixer->fix_eol($test_string)));
        return 0;
    }

    $fixer->eof_handling('asis');
    unless ($fixer->fix_eol($test_string) eq "\015\012\032") {
        diag("Failed to leave EOF 'asis' correctly on blank string");
        return 0;
    }

    $fixer->eof_handling('add');
    unless ($fixer->fix_eol($test_string) eq "\015\012\032") {
        diag("Failed to handle 'add' with pre-existing EOF correctly on blank string");
        return 0;
    }

    $test_string = '';
    $fixer->eof_handling('add');
    unless ($fixer->fix_eol($test_string) eq "\015\012\032") {
        diag("Failed to add EOF when none present on blank string");
        return 0;
    }

    return 1;
}

#########################
sub url_escape {
    my ($s)=@_;
    return '' unless defined ($s);
    $s=~s/([\000-\377])/"\%".unpack("H",$1).unpack("h",$1)/egs;
    $s;
}

#########################

sub map_list {
    my $map_list = [
    ["\012" => "\012"],
    ["\015" => "\012"],

    ["\012\015" => "\012"],
    ["\015\012" => "\012"],
    ["\015\012\015" => "\012\012"],
    ["\012\015\012" => "\012\012"],

    ["\012a\012b\012" => "\012a\012b\012"],
    ["\012a\012b\015" => "\012a\012b\012"],
    ["\012a\015b\012" => "\012a\012b\012"],
    ["\012a\015b\015" => "\012a\012b\012"],
    ["\015a\012b\012" => "\012a\012b\012"],
    ["\015a\012b\015" => "\012a\012b\012"],
    ["\015a\015b\012" => "\012a\012b\012"],
    ["\015a\015b\015" => "\012a\012b\012"],

    ["\012\015a\012\015b\012\015" => "\012a\012b\012"],
    ["\012\015a\012\015b\015"     => "\012a\012b\012"],
    ["\012\015a\015b\012\015"     => "\012a\012b\012"],
    ["\012\015a\015b\015"         => "\012a\012b\012"],
    ["\015a\012\015b\012\015"     => "\012a\012b\012"],
    ["\015a\012\015b\015"         => "\012a\012b\012"],
    ["\015a\015b\012\015"         => "\012a\012b\012"],

    ["\015\012a\015\012b\015\012" => "\012a\012b\012"],
    ["\015\012a\015\012b\015"     => "\012a\012b\012"],
    ["\015\012a\015b\015\012"     => "\012a\012b\012"],
    ["\015\012a\015b\015"         => "\012a\012b\012"],
    ["\015a\015\012b\015\012"     => "\012a\012b\012"],
    ["\015a\015\012b\015"         => "\012a\012b\012"],
    ["\015a\015b\015\012"         => "\012a\012b\012"],
    ["\015\012\015a\015\012\015b\015\012\015" => "\012\012a\012\012b\012\012"],
    ["\015\012\015a\015\012\015b\015"         => "\012\012a\012\012b\012"],
    ["\015\012\015a\015b\015\012\015"         => "\012\012a\012b\012\012"],
    ["\015\012\015a\015b\015"                 => "\012\012a\012b\012"],
    ["\015a\015\012\015b\015\012\015"         => "\012a\012\012b\012\012"],
    ["\015a\015\012\015b\015"                 => "\012a\012\012b\012"],
    ["\015a\015b\015\012\015"                 => "\012a\012b\012\012"],

    ["\012\012\012a\012\012\012b\012\012\012" => "\012\012\012a\012\012\012b\012\012\012"],
    ["\012\012\015a\012\012\015b\012\012\015" => "\012\012a\012\012b\012\012"],
    ["\012\015\012a\012\015\012b\012\015\012" => "\012\012a\012\012b\012\012"],
    ["\012\015\015a\012\015\015b\012\015\015" => "\012\012a\012\012b\012\012"],
    ["\015\012\012a\015\012\012b\015\012\012" => "\012\012a\012\012b\012\012"],
    ["\015\012\015a\015\012\015b\015\012\015" => "\012\012a\012\012b\012\012"],
    ["\015\015\012a\015\015\012b\015\015\012" => "\012\012a\012\012b\012\012"],
    ["\015\015\015a\015\015\015b\015\015\015" => "\012\012\012a\012\012\012b\012\012\012"],

  ["\012\012\012\012a\012\012\012\012b\012\012\012\012" => "\012\012\012\012a\012\012\012\012b\012\012\012\012"],
  ["\012\012\012\015a\012\012\012\015b\012\012\012\015" => "\012\012\012a\012\012\012b\012\012\012"],
  ["\012\012\015\012a\012\012\015\012b\012\012\015\012" => "\012\012\012a\012\012\012b\012\012\012"],
  ["\012\012\015\015a\012\012\015\015b\012\012\015\015" => "\012\012\012a\012\012\012b\012\012\012"],
  ["\012\015\012\012a\012\015\012\012b\012\015\012\012" => "\012\012\012a\012\012\012b\012\012\012"],
  ["\012\015\012\015a\012\015\012\015b\012\015\012\015" => "\012\012a\012\012b\012\012"],
  ["\012\015\015\012a\012\015\015\012b\012\015\015\012" => "\012\012a\012\012b\012\012"],
  ["\012\015\015\015a\012\015\015\015b\012\015\015\015" => "\012\012\012a\012\012\012b\012\012\012"],
  ["\015\012\012\012a\015\012\012\012b\015\012\012\012" => "\012\012\012a\012\012\012b\012\012\012"],
  ["\015\012\012\015a\015\012\012\015b\015\012\012\015" => "\012\012a\012\012b\012\012"],
  ["\015\012\015\012a\015\012\015\012b\015\012\015\012" => "\012\012a\012\012b\012\012"],
  ["\015\012\015\015a\015\012\015\015b\015\012\015\015" => "\012\012\012a\012\012\012b\012\012\012"],
  ["\015\015\012\012a\015\015\012\012b\015\015\012\012" => "\012\012\012a\012\012\012b\012\012\012"],
  ["\015\015\012\015a\015\015\012\015b\015\015\012\015" => "\012\012\012a\012\012\012b\012\012\012"],
  ["\015\015\015\012a\015\015\015\012b\015\015\015\012" => "\012\012\012a\012\012\012b\012\012\012"],
  ["\015\015\015\015a\015\015\015\015b\015\015\015\015" => "\012\012\012\012a\012\012\012\012b\012\012\012\012"],
    ];
    return $map_list;
}
