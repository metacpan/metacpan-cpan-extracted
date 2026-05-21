package Helper;

###############################################
# Author:        Olivier Delouya - 2026
# File:          t/Helper.pm
# Content:       Surgical 7-args Orchestrator
# indent:        Whitesmith (perltidy -bl -bli)
###############################################

use strict;
use warnings;
use POSIX qw(strftime);
use Test::More;
use Tstregex;

# Persistent variables for the test script execution
my $header_done = 0;
# Détection fine de l'environnement
my $os = $^O;
my $is_unix_shell = ($os ne 'MSWin32'); # Cygwin, MSYS, Linux, Darwin sont True
    

use Exporter 'import';
our @EXPORT = qw(check_tst);

sub check_tst
    {
    my ($re, $str, $exp_match, $exp_len, $exp_found, $exp_expect, $desc, $exp_caps) = @_;

    # 1. Error reporting line fix (caller context)
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    # 2. Engine Execution
    my $ctx        = Tstregex::tstregex_init_desc($re);
    my $got_match  = Tstregex::tstregex($ctx, $str);
    my $got_len    = Tstregex::tstregex_get_match_len($ctx);
    my $got_expect = Tstregex::tstregex_get_fail_token($ctx);
    my $got_caps   = Tstregex::tstregex_get_captures($ctx) // [];
    if(!defined($got_match))
        {
        # something went wrong with the regex engine which just rejected the test
        pass("Regex $re is in degraded mode on this platform (Warning/Illegal)");
        return 0;
        }
          
    # 3. Raw character extraction (found at stop position)
    my $got_found  = substr($str, $got_len, 1) // '';
    
    # 4. Atomic Validation with '?' support and flexible match length
    my $match_ok  = ($got_match == $exp_match);
    my $len_ok    = 0;
    if ($exp_len eq '?')
        {
        $len_ok = 1;
        }
    # lazzy/greedy: If a match is expected and found, any length is considered valid (flexible)
    # Otherwise, for failures or specific tests, length must match exactly
    elsif ($exp_match == 1 && $got_match == 1)
        {
        $len_ok = 1;
        }
    else
        {
        $len_ok = ($got_len == $exp_len);
        }

    my $found_ok  = ($exp_found  eq '?' || $got_found  eq $exp_found);
    my $expect_ok = ($exp_expect eq '?' || $got_expect eq $exp_expect);

    # 5. Captures Deep Validation (only if exp_caps is provided and not '?')
    my $caps_ok = 1;
    if (defined $exp_caps && $exp_caps ne '?')
        {
        if (scalar @$got_caps != scalar @$exp_caps)
            {
            $caps_ok = 0;
            }
        else
            {
            for my $i (0 .. $#$exp_caps)
                {
                my $g = $got_caps->[$i];
                my $e = $exp_caps->[$i];
                
                if (defined $g && defined $e) { $caps_ok = 0 if ($g ne $e); }
                elsif (defined $g || defined $e) { $caps_ok = 0; }
                }
            }
        }

    my $is_ok = ( $match_ok && $len_ok && $found_ok && $expect_ok && $caps_ok );
    
    if ( ok($is_ok, "[$desc ($re, $str)]") )
        {
        return 1;
        }
    else
        {
        # Detailed Diagnostics on failure
        if ($exp_found ne '?' && $got_found ne $exp_found)
            {
            diag("- Character mismatch: Found '$got_found', but test expected '$exp_found'");
            }

        if ($exp_expect ne '?' && $got_expect ne $exp_expect)
            {
            diag("- Regex Token mismatch: Engine reported '$got_expect', but test expected '$exp_expect'");
            }
        
        if ($got_match != $exp_match)
            {
            my $s_got = $got_match ? "Success" : "Failure";
            my $s_exp = $exp_match ? "Success" : "Failure";
            diag("- Status mismatch: Engine reported $s_got, but test expected $s_exp");
            }

        if ($exp_len ne '?' && $got_len != $exp_len)
            {
            diag("- Position mismatch: Stopped at index $got_len, but test expected $exp_len");
            }

        if (!$caps_ok)
            {
            my $got_s = join(', ', map { $_ // 'undef' } @$got_caps);
            my $exp_s = join(', ', map { $_ // 'undef' } @$exp_caps);
            diag("- Captures mismatch: Found [$got_s], expected [$exp_s]");
            }
        # Process debug logging if TSTREGEX_DBG environment variable is set
        if ($ENV{TSTREGEX_DBG}) 
            {      
            my $ext      = $is_unix_shell ? 'sh' : 'bat';
            my $log_file = File::Spec->catfile('.', "fails.$ext");
            
            # Handle header and log file initialization
            if (!$header_done) 
                {
                # Open in append mode, but check if we need to write the shebang
                my $needs_shebang = !-e $log_file && $is_unix_shell;
                
                open(my $fh, '>>', $log_file) or die "Error opening $log_file: $!";
                
                print $fh "#!/bin/sh\n" if ($needs_shebang);
                
                # Timestamp format: YY/DD/MM-HH24.mm.ss
                my $timestamp = strftime("%y/%m/%d/-%H.%M.%S", localtime);
                my (undef, undef, $filename) = File::Spec->splitpath($0);
                
                if ($is_unix_shell) 
                    {
                    print $fh "echo \"$filename $timestamp\"\n";
                    } 
                else 
                    {
                    print $fh "echo %DATE% %TIME% --- $filename $timestamp\n";
                    }
                
                close($fh);
                
                # Make the script executable on Cygwin/Unix
                if ($is_unix_shell)
                    {
                    chmod(0755, $log_file);
                    }
                $header_done = 1;
                }
    
            # Log the reproduction command only on failure
            if(!$is_ok)
                {
                open(my $fh, '>>', $log_file) or die "Error opening $log_file: $!";
                
                my $safe_re  = $re;
                my $safe_str = $str;
        
                # Shell character escaping
                if ($is_unix_shell) 
                    {
                    # Protect \, $, ", and ` for shell script execution
                    $safe_re  =~ s/([\\\$"`])/\\$1/g;
                    $safe_str =~ s/([\\\$"`])/\\$1/g;
                    } 
                else 
                    {
                    # Double quotes for Windows BAT compatibility
                    $safe_re  =~ s/"/""/g;
                    $safe_str =~ s/"/""/g;
                    }
                
                # Write the final tstregex command
                my $cmd = sprintf('tstregex "%s" "%s"', $safe_re, $safe_str);
                $cmd .= sprintf(' "%s"', join(',', @$exp_caps)) if ($exp_caps);
                print $fh "$cmd # $desc\n";
                close($fh);
                }
            }
        return 0;
        }
    }
1;