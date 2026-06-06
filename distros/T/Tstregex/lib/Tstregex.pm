#!/usr/bin/env perl

###############################################
# Author:        Olivier Delouya - 2026
# File:          Tstregex.pm (Hybrid Modulino)
# Content:       Regex longest match diagnostic
# indent:        Whitesmith (perltidy -bl -bli)
###############################################

use strict;
use warnings;

=head1 NAME

Tstregex - A Hybrid Regex Diagnostic Tool (single file Library module and command tool)

 shows the longest Regular Expression match / highlight the rejected part
 
 Example:
 
 $ perl lib/Tstregex.pm '/^[a-z]*\d{3}$/' 'abc123' 'abc12a'
 abc123
 abc12a (^[a-z]*\d{3}$)
    ^^^         ^^^^^^ (actually rendered in bold on terminal)
 
 # Above, the normal parts are the longuest matching substring when bold parts highlights the rejected substring
 #(idem with regexp lexical groups between parenthesis)

=cut
 
=head1 SYNOPSIS

C<$tstregex 'regex' string1 string2 ...   stringN>

=head1 OPTIONS (CLI)

=head2 -h --help

show that help..

=head2 -v --verbose

shows key info on (un)matching..

=head2 -d --diag

=over

=item Triggers the Enriched Diagnostic View. It displays:

=item - The string with the failing part highlighted.

=item - The exact token in the regex that caused the break.

=item - A visual pointer (C<^--- HERE>) aligned with the regex syntax.

=item - Execution time (useful for spotting ReDoS/Exponential backtracking).

=back

=head2 -a --assert

Misc: performs a huge test suite various a large collection of regexp tests with Tstregex..

=head1 Perl Module SYNOPSIS

  use Tstregex;
  my $ctx = tstregex_init_desc('/^\d{3}/');
  tstregex($ctx, '12a');
  if (!tstregex_is_full_match($res))
      {
      my $token = tstregex_get_fail_token($res);
      my $pos   = tstregex_get_match_len($res);
      print "Failure on token '$token' at column $pos\n";
      }

=head1 API

=head2 tstregex_init_desc($raw_re)

Pre-parses the regex, handles delimiters (m!!, //, etc.), extracts modifiers (i, s, m, x), and prepares the nibbling steps. Returns a context hash.

=head2 tstregex($ctx, $string)

Executes the diagnostic. Updates the context.

=head2 tstregex_is_full_match

Returns match status of input string (BOOL 0 OR 1)

=head2 tstregex_get_match_portion

Returns the matching portion in case of full match
(might be smaller than input string, depending on anchors..)

=head2 tstregex_get_match_len

Returns the matching substring length

=head2 tstregex_get_fail_token

Returns the failing token in the regexp

=head2 tstregex_get_re_clean

Returns the matching regexp subpart

=head2 tstregex_get_re_raw

Returns the internal representation of the regexp

=head2 tstregex_get_prefix_offset

Returns the offset of the original regexp in the raw regexp

=head1 DESCRIPTION

=over

=item B<tstregex> is designed to solve the "Black Box" problem of Regular Expressions.

=item When a complex regex fails, Perl usually just says "No Match".

=item This tool identifies exactly B<where> and B<why> it failed by finding the longest possible partial match.

=back 

=head1 EXAMPLE

=over

=item $ perl lib/Tstregex.pm '/^[a-z]*\d{3}$/' 'abc123' 'abc12a'

=item abc123

=item abcB<12a> (^[a-z]*B<\d{3}$>)

=back

I<The tool highlights the part of the string where the match failed.>

=head2 The "Nibbling" Engine

The diagnostic logic uses a "Nibbling" (grignotage) strategy:

=over 4

=item 1. Decomposition

The engine breaks down your regex into a hierarchy of valid sub-patterns (lexical groups, atoms, and quantifiers) from longest to shortest.

=item 2. Longest Match Search

=back

=over 4

It iteratively tests these sub-patterns against the input string. 

It's not just checking if the start matches, but what is the I<maximum> sequence of instructions the engine could follow before hitting a wall.

=back

=over 4

=item 3. Failure Point Identification

Once the longest matching sub-pattern is found, the tool identifies the very next token in your regex syntax. This is your "Point of Failure".

=back

=head1 AUTHOR

Olivier Delouya - 2026

=head1 LICENSE

Artistic Version 2

=cut


package main;
    {
    use strict;
    use warnings;
    use Carp qw(confess);
    $SIG{__WARN__} = 'confess';
    $SIG{__DIE__ } = 'confess';

    use Term::ANSIColor qw(:constants);
    use Time::HiRes qw(gettimeofday tv_interval);
    use utf8;

    # --- Constants & ASCII Codes ---
    use constant
        {
        C_m      => 109, C_g      => 103, C_i      => 105, C_s      => 115,
        C_x      => 120, C_SLASH  => 47,  C_SPACE  => 32,  C_ZERO   => 48,
        C_NINE   => 57,  C_UP_A   => 65,  C_UP_Z   => 90,  C_LOW_A  => 97,
        C_LOW_Z  => 122, C_UNDSC  => 95,
        OP_PAR   => 40,  CL_PAR   => 41,  OP_BRK   => 91,  CL_BRK   => 93,
        OP_BRC   => 123, CL_BRC   => 125, OP_ANG   => 60,  CL_ANG   => 62,
        ESC      => "\e",
        CUU      => "\e[A", # Cursor Up
        UI_OFFSET=> 11,     # Alignment offset for "  Syntax: "
        };

# --- ENCAPSULATED DEBUG ALIAS ---
    BEGIN
        {
        if ($INC{'perl5db.pl'})
            {
            require Data::Dumper;
            require Term::ANSIColor;
            no strict 'refs';
            no warnings 'once';

            my $debug_sub = sub
                {
                my @args = @_;

                # Automatically detect flattened hashes:
                # If even number of arguments and the first one isn't a reference
                if (scalar @args > 1 && scalar @args % 2 == 0 && !ref($args[0]))
                    {
                    # Wrap the flattened list into a temporary hashref
                    my %tmp_hash = @args;
                    @args = (\%tmp_hash);
                    }

                print "\n", Term::ANSIColor::BOLD(), Term::ANSIColor::BLUE(),
                      'DEBUG (tstregex): ', Term::ANSIColor::RESET(),
                      Data::Dumper::Dumper(@args);
                };

            # Force injection into all relevant namespaces
            foreach my $pkg ('main', 'Tstregex', 'DB')
                {
                *{"${pkg}::d"} = $debug_sub;
                }

            my $cuu = defined &main::CUU ? main::CUU() : "\e[A";
            print $cuu, Term::ANSIColor::BOLD(), Term::ANSIColor::CYAN(),
                  'INFO: ', Term::ANSIColor::RESET(),
                  "Alias 'd' ready (Auto-hash detection enabled)\n\n";
            }
        }
        
    exit(main(scalar(@ARGV), \@ARGV)) if(!caller);

    sub main
        {
        my ($argc, $argv) = @_;
        if(!$argc || ($argc && $$argv[0] =~ /^-h|--help$/)) { help(); exit(0); }

        binmode STDOUT, ':utf8';
        my ($mode_diag, $verbose, $assert) = (0)x2;
        for(my $i=0; $i<$argc; $i++)
            {
            do { $mode_diag = 1; undef $$argv[$i]; next } if (!$mode_diag && $$argv[$i] =~ /^-d|--diag$/);
            do { $verbose   = 1; undef $$argv[$i]; next } if (!$verbose   && $$argv[$i] =~ /^-v|--verbose$/);
            do { $assert    = 1; undef $$argv[$i]; next } if (!$assert    && $$argv[$i] =~ /^-a|--assert$/);
            }
        
        if ($assert)
            {
            print BOLD, BLUE, "--- Internal Test Suite (DATA Section) ---\n", RESET;
            _run_internal_tests($mode_diag, $verbose);
            exit(0);
            }

        my @new_argv;
        foreach(@$argv)
            {
            push @new_argv, $_ if(defined($_));
            }
        $argv = \@new_argv;
        $argc = scalar @$argv;
        
        my $re_raw = shift @{$argv};
        my $ctx = Tstregex::tstregex_init_desc($re_raw);
        my $global_result = 0; # success! BE POSITIVE !!
        foreach my $pattern (@{$argv})
            {
            my $t0 = [gettimeofday] if $mode_diag;
            my $result = Tstregex::tstregex($ctx, $pattern);
            $global_result = 1 if($result);
            $mode_diag ? _display_enriched($pattern, $ctx, tv_interval($t0))
                       : _display_standard($pattern, $ctx);
            if($verbose)
                {
                print $result?  'Match':'UNmatch', '! Match length: ', Tstregex::tstregex_get_match_len($ctx), '; ';
                print $result? ('Match portion: ', Term::ANSIColor::UNDERLINE(), Tstregex::tstregex_get_match_portion($ctx))
                             : ('Fail token: ', Tstregex::tstregex_get_fail_token($ctx));
                print Term::ANSIColor::RESET(), "\n";
                print $ctx->{warning} if($verbose && $ctx->{warning} ne '');
                }
            }
        return $global_result;
        }

    sub _run_internal_tests
        {
        my ($mode_diag, $verbose) = @_;
        my $fh = \*main::DATA;
        seek($fh, 0, 0);
        
        my $found_data_token = 0;
    
        while (<$fh>)
            {
            chomp;
            # PHASE 1: Skip everything until we hit the __DATA__ or __END__ marker
            # This prevents the script from parsing its own source code
            if (!$found_data_token)
                {
                $found_data_token = 1 if /^__(DATA|END)__/;
                next;
                }
            else
                {
                last if /^__(DATA|END)__/;
                }  
            next if /^\s*$/ || /^#/;
            my ($re, @rest) = split(/\s+|:::\s*/, $_);
            next unless $re;
            my @strings = grep { $_ ne '0' && $_ ne '1' } @rest;

            print BOLD, YELLOW, 'Testing Regex: ', RESET, "$re\n";
            my $ctx = Tstregex::tstregex_init_desc($re);
            print 'Warning ', $ctx->{warning}, "\n" if($verbose && $ctx->{warning} ne '');
            foreach my $s (@strings)
                {
                my $t0;
                $t0 = [gettimeofday] if $mode_diag;
                Tstregex::tstregex($ctx, $s);
                $mode_diag ? _display_enriched($s, $ctx, tv_interval($t0))
                           : _display_standard($s, $ctx);
                }
            print '-' x 40, "\n";
            }
        }
        
    sub _get_re_val
        {
        return (
                Tstregex::tstregex_get_match_len ($_[0]), 
                Tstregex::tstregex_get_fail_token($_[0]), 
                Tstregex::tstregex_get_re_clean  ($_[0])
               );
        }

    sub _display_standard
        {
        my ($pattern, $ctx) = @_;
        if (Tstregex::tstregex_is_full_match($ctx))
            {
            print "$pattern\n";
            return undef;
            }
        my ($match_len, $fail_token, $re_clean ) = _get_re_val($ctx);
        print substr($pattern, 0, $match_len), BOLD, substr($pattern, $match_len), RESET;
        my $off = length($re_clean) - length($fail_token);
        print ' (', substr($re_clean, 0, $off), BOLD, $fail_token, RESET, ")\n";
        undef;
        }

    sub _display_enriched
        {
        my ($pattern, $ctx, $elapsed) = @_;
        print BOLD, MAGENTA, '--- Diagnostic View ---', RESET, "\n";

        if (Tstregex::tstregex_is_full_match($ctx))
            {
            print GREEN, '  Result: ', RESET, "$pattern (FULL MATCH)\n";
            return undef;
            }
        my ($match_len, $fail_token, $re_clean ) = _get_re_val($ctx);
        my $prefix_off = Tstregex::tstregex_get_prefix_offset($ctx);
        my $re_raw     = Tstregex::tstregex_get_re_raw        ($ctx);

        print YELLOW, '  Result: ', RESET, substr($pattern, 0, $match_len),
              BOLD, WHITE, substr($pattern, $match_len), RESET;
        print ' (at ', CYAN, $fail_token, RESET, ")\n";

        my $err_pos_in_clean = length($re_clean) - length($fail_token);
        my $final_pointer_pos = $prefix_off + $err_pos_in_clean;

        print '  Syntax: ', WHITE, $re_raw, RESET, "\n";
        print '            ', ' ' x $final_pointer_pos, BOLD, RED, '^--- HERE', RESET, "\n";
        printf "  Time:    %.4fs\n\n", $elapsed;
        undef;
        }

    sub help
        {
        print BOLD, WHITE, "Tstregex.pm - Longest match Regular Expression Diagnostic Tool (2026 - PerlOD)\n", RESET;
        print "Usage:\n";
        print "  perl Tstregex.pm [options] 'regex' 'string1' ['string2' ...]\n\n";
        print "Examples:\n";
        print "  perl Tstregex.pm '([0-3][0-9])/[0-1][0-9]/\\d{4}' '21/72/1985'\n";
        print '  21/', BOLD, '72/1985', RESET, ' ([0-3][0-9]/', BOLD, '[0-1][0-9]/\d{4}', RESET, ")\n\n";
        print BOLD, 'DELIMITERS ', RESET, "are optional\n";
        print "  Supported: /.../, m!...!, m{...}. Modifiers (/i, /x, /s...) and captures are supported.\n\n";
        print "Options:\n";
        print "-h --help            Shows that help\n";
        print "-v --verbose         Shows keys info on match/unmatch\n";
        print "-d --diag            Enriched diagnostic with timing and syntax pointers\n";
        print "-a --assert          Misc: shows a large test of regexp against tstregex..\n";
        }

    }

1;

package Tstregex;
    {
    our $VERSION = '1.10';
    use Exporter qw(import);

    our @EXPORT  = qw(
        tstregex
        tstregex_init_desc
        tstregex_get_match_len
        tstregex_get_fail_token
        tstregex_is_full_match
        tstregex_get_re_clean
        tstregex_get_prefix_offset
        tstregex_get_re_raw
        tstregex_get_match_portion
        tstregex_get_info
    );

    # --- PUBLIC API (The Getters) ---

    sub tstregex_get_match_len     { return $_[0]->{match_len};     }
    sub tstregex_get_fail_token    { return $_[0]->{fail_token};    }
    sub tstregex_is_full_match     { return $_[0]->{full_match};    }
    sub tstregex_get_re_clean      { return $_[0]->{re_clean};      }
    sub tstregex_get_prefix_offset { return $_[0]->{prefix_offset}; }
    sub tstregex_get_re_raw        { return $_[0]->{re_raw};        }
    sub tstregex_get_captures      { return $_[0]->{captures} // [];}
    sub tstregex_get_match_portion { return $_[0]->{match_portion}; }
    sub tstregex_get_info          { return $_[0]->{warning};       }

    # Main diagnostic function
    use constant;
    use constant 
        { 
        C_EMPTY      =>       '',
        RE_EMPTY     =>   qr/\0/,
        ASCII_LPAREN => ord('('),  # 40
        ASCII_RPAREN => ord(')'),  # 41
        ASCII_LBRACE => ord('{'),  # 123
        ASCII_RBRACE => ord('}'),  # 125
        ASCII_LBRACK => ord('['),  # 91
        ASCII_RBRACK => ord(']'),  # 93
        ASCII_LT     => ord('<'),  # 60
        ASCII_GT     => ord('>'),  # 62
        };
    
    sub tstregex
        {
        my ($ctx, $pattern) = @_;
        # FIX: re init start-state fields in case of multiple test patterns  
        $ctx -> {'fail_token'}      = Tstregex::C_EMPTY; 
        $ctx -> {'match_portion'}   = undef;
        $ctx -> {'right_unmatch'}   = undef;
        $ctx -> {'match_len'}       = 0;
        $ctx -> {'full_match'}      = 0;
        $ctx -> {'left_unmatch'}    = undef;
        my $re_raw  = $ctx->{re_raw};
        my $org_pat = $pattern;
        my $internal_offset = 0;

        # Handle prefix offset if pattern is wrapped like the RE
        if ($ctx->{prefix_offset} > 0 && length($pattern) >= $ctx->{prefix_offset} + 1)
            {
            my $re_delim_char  = _stringat($re_raw, $ctx->{prefix_offset} - 1);
            my $pat_first_char = _stringat($pattern, 0);
            if ($pat_first_char == $re_delim_char)
                {
                $pattern = substr($org_pat, $ctx->{prefix_offset});
                chop $pattern;
                $internal_offset = $ctx->{prefix_offset};
                }
            }

        # Fast track: check if it matches globally first
        if ($pattern =~ $ctx->{re_compiled})
            {
            $ctx->{full_match}    = 1;
            $ctx->{match_len}     = length($org_pat);
            $ctx->{match_portion} = $&; # the exact sub portion that matched
            $ctx->{left_unmatch}  = $`; # the left  part of matching sub part
            $ctx->{right_unmatch} = $'; # the right part of matching sub part

            # --- Capture Groups Extraction ---
            # We populate the captures array only on a successful global match
            my @caps;

            # The special variable $#- contains the number of capture groups
            # We start at 1 because $0 is the whole match
            for my $i (1 .. $#-)
                {
                if (defined $-[$i])
                    {
                    # Extracting the substring using offsets from @- and @+
                    push @caps, substr($pattern, $-[$i], $+[$i] - $-[$i]);
                    }
                else
                    {
                    # Optional group that participated but didn't catch text
                    push @caps, undef;
                    }
                }
            $ctx->{captures} = \@caps;

            return 1;
            }

        # Nibbling phase: find the longest matching lexical group
        my $match_reg = Tstregex::C_EMPTY;
        foreach my $step (@{$ctx->{steps}})
            {
            if ($pattern =~ qr/$step/)
                {
                $match_reg = $step;
                last;
                }
            }

        # ** SENSITIVE **
        # Fine-tune the match length character by character
        # Append a \z to avoid Perl to skip final \n
        # if Nibbling failed ($match_reg empty), get the full regex for fine-tuning.
        my $target_re = ($match_reg ne Tstregex::C_EMPTY) ? $match_reg : $ctx->{re_clean};
        # critical! add starting anchor (\A) to force coherency check from the first char..
        my ($match_work, $warn) = _safe_qr("\\A$target_re\\z"); # (qr/\A$target_re\z/, undef); #;
        for (my $i = length($pattern); $i >= 0; $i--)
            {
            # check if current prefix is valid according to the target
            last if ($pattern =~ $match_work);
            chop $pattern;
            }
        $ctx->{match_len}  = length($pattern) + $internal_offset;

        # Identify the failing token for display
        my $tail_re = (scalar @{$ctx->{steps}}) ? $ctx->{steps}->[0] : $ctx->{re_clean};
        my $remaining_re = substr($tail_re, length($match_reg));

        if ($remaining_re ne Tstregex::C_EMPTY)
            {
            # get the first token for analyse
            my $next_tokens = _get_lex_groups($remaining_re);
            my $first_token = $next_tokens->[0] // Tstregex::C_EMPTY;
            $ctx->{fail_token} = $remaining_re;
            $ctx->{fail_token} = $first_token if ($first_token =~ /^(\\b|\^|\$)$/); # Anchor case (0 width): want detail (just \b, ^ or $)
            }
        else
            {
            $ctx->{fail_token} = Tstregex::C_EMPTY;
            }

        # Ensure captures is empty/undef on failure
        $ctx->{captures} = [];
        return $ctx->{match_undef}? undef:0;
        }

    # Context initialization and RE peeling
    sub tstregex_init_desc
        {
        my ($re_raw) = @_;
        # The Shield: Catching the 5.28 deprecation warnings and fatal errors
        # We use a localized __WARN__ handler to catch the "Unescaped left brace"
        # even if it's not a fatal error yet in 5.28
        
        my ($re_compiled, $re_clean, $prefix_off, $last_warning) = _unwrap_regex($re_raw);
        my $match_undef = $re_compiled eq RE_EMPTY ? 1:0;
            
        my $steps = _parse_lex_groups($re_clean);
#            {
#             no warnings 'experimental::re_strict';
#             use re 'strict';
#            $steps = _parse_lex_groups($re_clean);
#            };
        return
            {
            re_raw => $re_raw, re_compiled => $re_compiled, re_clean => $re_clean,
            steps => $steps, prefix_offset => $prefix_off, match_len => 0, 
            fail_token => Tstregex::C_EMPTY, full_match => 0,match_portion => undef,
            match_undef => $match_undef, left_unmatch => undef, right_unmatch => undef, 
            warning => $last_warning,
            };
        }

    # Helper: get char code at position
    sub _stringat($$) { return vec($_[0], $_[1], 8); }

    sub _unwrap_regex
        {
        my ($raw) = @_;
        return (qr//, Tstregex::C_EMPTY, 0) if !defined $raw || $raw eq Tstregex::C_EMPTY;
        
        my $raw_org = $raw;
        my $options = Tstregex::C_EMPTY;
    
        # 1. Extract trailing options (ismxg)
        while ($raw =~ s/([ismxg])$//) 
            { 
            $options = $1 . $options; 
            }
    
        # 2. Delegate peeling to _strop
        my $clean = _strop($raw);
    
        # 3. Automatic offset calculation (locate the "juice" within the original string)
        my $off = index($raw_org, $clean);
        $off = 0 if $off < 0;
    
        # 4. Secure Forge (Remove 'g' as it is irrelevant for qr//)
        $options =~ tr/g//d;
        my $re_str = $options ? "(?$options)$clean" : $clean;
        
        my ($re_ret, $warn) = _safe_qr($re_str);
    
        return ($re_ret, $clean, $off, $warn);
        }
                
    sub _safe_qr 
        {
        my ($re_str) = @_;
        my ($re, $err);
            {
            local $@;
            local $SIG{__DIE__}  = local $SIG{__WARN__}  = sub { }; 
            # dont catch the warning there, let the eval fail instead and get the message back in $@
            $re = eval { qr/$re_str/ };
            $err = $@ // ''; 
            }
        return ($re // RE_EMPTY, $err);
        }
        
    # _strop: strip operators
    # Peels Perl operators (m!!, m{}, //) by checking extremities.
    # It ensures only the core regex juice is returned.
    sub _strop 
        {
        my ($raw) = @_;
        return $raw if !defined $raw || $raw eq Tstregex::C_EMPTY;
        
        # Remove leading/trailing whitespace
        $raw =~ s/^\s+|\s+$//g; 
    
        # Identify opening delimiter (after an optional 'm')
        if ($raw =~ /^((?:m\s*)?)([^\w\s])(.*)$/s) 
            {
            my $prefix = $1;
            my $open   = $2;
            my $body   = $3;
    
            # Map symmetric pairs using ASCII constants
            my %sym_or_eq = 
                (
                chr(ASCII_LBRACE) => chr(ASCII_RBRACE),
                chr(ASCII_LBRACK) => chr(ASCII_RBRACK),
                chr(ASCII_LPAREN) => chr(ASCII_RPAREN),
                chr(ASCII_LT)     => chr(ASCII_GT),
                );
            
            # Expected close is either the matching pair or the same character (e.g., m!!)
            my $expected_close = $sym_or_eq{$open} || $open;

            # PROTECT CAPTURE GROUPS:
            # If the delimiter is a parenthesis but there is no 'm' prefix,
            # it is a capturing group, NOT an operator. Do not peel!
            if ($open eq chr(ASCII_LPAREN) && !$prefix)
                {
                return $raw;
                }

            # Check if the very last character matches our expected closing delimiter
            if (substr($body, -1) eq $expected_close) 
                {
                return substr($body, 0, -1); 
                }
               
            # If 'm' was present but closing failed, return body (best effort)
            return $body if $prefix;
            }
    
        return $raw;
        }
    
    sub _parse_lex_groups
        {
        my ($regex) = @_;
        my $tokens = _get_lex_groups($regex);
        my @results;
        my $current = join(Tstregex::C_EMPTY, @$tokens);

        while (@$tokens)
            {
            my $opens  = () = $current =~ /(?<!\\)\(/g;
            my $closes = () = $current =~ /(?<!\\)\)/g;
            if ($opens >= $closes)
                {
                my $v = $current . (')' x ($opens - $closes));
                $v =~ s/(?<!\\)\|+$//;
                if (eval { qr/$v/ }) { push @results, $v; }
                }
            my $last = pop @$tokens;
            substr($current, -length($last)) = Tstregex::C_EMPTY if defined $last;
            }
        return \@results;
        }

    # Lexical tokenizer for Perl Regex
    sub _get_lex_groups
        {
        my ($regex) = @_;
        my @groups;

        # --- START: class mismatch support (Added [.*?] to tokenizer) ---
#       my $re = qr/(\(\?\#.*?\))|(\(\?[:=!<>]+)|(\{\d+,?\d*\})|(\[.*?\])|(\\.)|([\(\)\|^\$\+\*\?])|(.)/x;
        # --- ENHANCED: Atomic Lookaround & Recursive Group Support ---
        # Group 1: Comments (?#...)
        # Group 2: Assertions and Groups (?=, (?:, (?<, etc. including nested parens
        # Group 3: Quantifiers {n,m}
        # Group 4: Character classes [...]
        # Group 5: Escaped characters \.
        # Group 6: Metacharacters ( ) | ^ $ + * ?
        # Group 7: Any other character
        # --- END: class mismatch support ---
        my $re = qr/
              (\(\?\#.*?\))
            | (                       # START GROUP 2
                \(\?[:=!<>]+          # Assertion header
                (?:                   # Content
                    (?> [^()]+ )      # Non-paren characters (atomic)
                    |
                    (?2)              # Recursive call to Group 2
                )*
                \)                    # Matching closing paren
              )                       # END GROUP 2
            | (\{\d+,?\d*\})
            | (\[.*?\])
            | (\\.)
            | ([\(\)\|^\$\+\*\?])
            | (.)
        /x;

        while ($regex =~ /$re/g)
            {
            my $t = $1 // $2 // $3 // $4 // $5 // $6 // $7;
            if (defined $t && $t =~ /^[\+\*\?]$|^\{\d/ && @groups && $groups[-1] !~ /^[\(\)\|]$/)
                {
                $groups[-1] .= $t;
                }
            else { push @groups, $t; }
            }
            
#         TODO: test that optimized code fragment instead; Much time spent here, but sensitive part..
#         my $quantifiers = '+*?{';
#         while ($regex =~ /$re/g) 
#             {
#             my $t = $1 // $2 // $3 // $4 // $5 // $6 // $7;
#             if (defined $t && @groups) 
#                 {
#                 my $char = substr($t, 0, 1);
#                 if (index($quantifiers, $char) != -1 && $groups[-1] !~ /^[\(\)\|]$/) 
#                     {
#                     $groups[-1] .= $t;
#                     next;
#                     }
#                 }
#             push @groups, $t;
#             }
                                  
        return \@groups;
        }

    }
    
1;

package main;

__DATA__
# The Final Data Set here - Batteries Included
^\d{3}$                 123  12a  45
m{^abc$}                abc  abd

# --- DELIMITERS & OFFSETS TESTS ---
m!^\d{3}! ::: 12a ::: 0
/^\d{3}/ ::: 12a ::: 0
m{^\d{3}} ::: 12a ::: 0

# --- OPTIONS TESTS ---
/abc/i ::: ABC ::: 1
m!abc!i ::: ABd ::: 0

# --- COMPLEX TESTS ---
/^(A|B|C)\d/ ::: Z9 ::: 0
/^\d{2,4}$/ ::: 12345 ::: 0

# --- INITIAL DATA SET ---
^\d{2}/\d{2}/\d{4}$ ::: 12/08/2026 ::: 1
^\d{2}/\d{2}/\d{4}$ ::: 12/08/2k26 ::: 0
^(GET|POST|PUT)$ ::: DELETE ::: 0
m#^https?://[\w\.-]+# ::: https://google.com ::: 1

# Date Validation
^\d{2}/\d{2}/\d{4}$ ::: 12/08/2026 ::: 1
^\d{2}/\d{2}/\d{4}$ ::: 12/08/2k26 ::: 0

# IP Addresses
^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$ ::: 192.168.1.1 ::: 1
^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$ ::: 192.168.1    ::: 0

# Alternation (The test that used to fail)
^(GET|POST|PUT)$ ::: DELETE ::: 0
^(GET|POST|PUT)$ ::: POST   ::: 1

# --- DATES & TIMES ---
/^\d{2}\/\d{2}\/\d{4}$/ ::: 12/08/2026 ::: 1
m!^\d{2}-\d{2}-\d{4}$! ::: 12-08-2026 ::: 1
m{^\d{4}-\d{2}-\d{2}$} ::: 2026-02-10 ::: 1
/^(0[0-9]|1[0-9]|2[0-3]):[0-5][0-9]$/ ::: 23:59 ::: 1
/^([01]?[0-9]|2[0-3])h[0-5][0-9]$/i ::: 14H30 ::: 1

# --- NETWORK & WEB ---
/^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/ ::: 192.168.1.1 ::: 1
m#^https?://[\w\.-]+# ::: https://google.com ::: 1
/^[\w\.-]+@[\w\.-]+\.[a-z]{2,4}$/i ::: support@perl.org ::: 1
m!^localhost(:\d+)?$! ::: localhost:8080 ::: 1
/^[a-f0-9]{32}$/i ::: a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6 ::: 1

# --- IDENTIFIERS & CODES ---
/^\d{5}$/ ::: 75001 ::: 1
/^[A-Z]{2}-\d{3}-[A-Z]{2}$/ ::: AB-123-CD ::: 1
m{^[A-Z]{3}\d{4}$} ::: ABC1234 ::: 1
/^[0-9a-fA-F]{8}$/ ::: DEADbeef ::: 1
/^\d{13}$/ ::: 9780201616224 ::: 1

# --- PERL SYNTAX & TEXT ---
m(^\s*#) :::   # A comment ::: 1
/word/i ::: WORD ::: 1
m!foo\s+bar!x ::: foo    bar ::: 1
/^[a-z_][a-z0-9_]*$/i ::: My_Variable_2 ::: 1
/^(true|false)$/ ::: maybe ::: 0

# --- "NIBBLING" TESTS (Syntax Pointers) ---

# Failure in the middle of a fixed group
/^(GET|POST|PUT)$/ ::: PONT ::: 0
# ^--- HERE should point to 'O' in PONT because 'P' doesn't match (GET|POST|PUT)

# Failure on a strict quantifier (4 digits expected)
/^\d{4}$/ ::: 12a4 ::: 0
# ^--- HERE points to 'a'

# Failure on a character class (Hexadecimal)
/^[0-9a-fA-F]+$/ ::: 12g45 ::: 0
# ^--- HERE points to 'g'

# --- DELIMITERS & OFFSETS TESTS (Cursor Verification) ---

# Offset of 2 (m!) + match of 3 (^\d{3}) -> error at 6th character (2+3+1)
m!^\d{3}/! ::: 123- ::: 0

# Offset of 1 (/) + match of 3 -> error at 5th character (1+3+1)
/^\d{3}\./ ::: 123: ::: 0

# --- FAILURES ON COMPLEX STRUCTURES ---

# IPv4: Failure on the 3rd octet
/^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/ ::: 192.168.alpha.1 ::: 0

# Email: Failure on the domain (forbidden special character)
/^[\w\.-]+@[\w\.-]+\.[a-z]{2,4}$/i ::: john.doe@work#place.com ::: 0

# ISO Date: Failure on the separator (space instead of dash)
/^\d{4}-\d{2}-\d{2}$/ ::: 2026 02-10 ::: 0

# Unix Path: Failure on unauthorized character
/^\/([\w.-]+\/)*[\w.-]+$/ ::: /home/user/my file.txt ::: 0
# ^--- HERE should point to the space after 'my'

# --- EDGE CASES ---

# End anchor ($) not respected
/^abc$/ ::: abcd ::: 0

# Lookahead (if supported by step parser)
/^(?=.*[A-Z])(?=.*[0-9]).{8,}$/ ::: password123 ::: 0
# ^--- HERE should point to the beginning as [A-Z] requirement is missing

# --- EXOTIC DELIMITERS & ERRORS ---
m{^\d{3}} ::: 123 ::: 1
m(^\d{3}) ::: 123 ::: 1
m<^\d{3}> ::: 123 ::: 1
# Separator ignored because it's not paired (final '/' does not close '!')
# In this case, unwrap_regex treats '^\d{3}/' as raw regex
m!^\d{3}/ ::: 123/ ::: 1
# Separator not identical to start (treated as raw text)
/abc! ::: abc! ::: 1

# --- ADVANCED OPTIONS TESTS ---
/abc/ix ::: A B C ::: 1
/abc/ims ::: abc ::: 1
# 'g' option (must be cleaned by unwrap_regex to avoid breaking qr//)
/abc/ig ::: ABC ::: 1

# --- "FALSE" DELIMITERS (Alphanumeric characters) ---
# Starting with 'a' is not a delimiter, it's the pattern start
abc ::: abc ::: 1
# But m + alpha (m!) is a delimiter. m + 'a' is NOT without space.
ma ::: ma ::: 1

# --- REGRESSION TESTS: SYMMETRY AND OFFSETS (2026) ---

# Case 1: Raw RE vs Raw Pattern (The basics)
^[0-3][0-9]/[0-1][0-9]/\d{4}$ ::: 21/02/198l ::: 0

# Case 2: Wrapped RE vs Wrapped Pattern (Source code copy-paste)
# Must ignore '!' and point to 'l'
m!^[0-3][0-9]/[0-1][0-9]/\d{4}$! ::: !21/02/198l! ::: 0

# Case 3: Wrapped RE vs Raw Pattern (The corrected glitch!)
# Tool must NOT peel the pattern because it lacks '/'
/^[0-3][0-9]/[0-1][0-9]/\d{4}$/ ::: 21/02/198l ::: 0

# Case 4: Mismatched Delimiters (Safety)
# Pattern has '!' but RE has '/'. Must not peel.
/^\d+$/ ::: !123! ::: 0

# Case 5: Spaces and m (Classic traps)
m !^\d+$! ::: !123! ::: 0
m{^\d+$} ::: {123} ::: 0

# --- CLASSIC NIBBLING TESTS ---
# Verifies that the breaking point is correctly identified
^\d{3}\w{2}$ ::: 12 ::: 0
^\d{3}\w{2}$ ::: 1234 ::: 0
^\d{3}\w{2}$ ::: 123ab ::: 1

# --- EXOTIC DELIMITERS ---
# Verifies behavior with pairs (brackets, curlies)
m(^\d+$) ::: (123) ::: 1
m[^\d+$] ::: [123] ::: 1
m{^\d+$} ::: {123} ::: 1
m<^\d+$> ::: <123> ::: 1

# --- ROBUSTNESS TESTS (EMPTY, SINGLE CHAR) ---
^a$ ::: b ::: 0
/^a$/ ::: /a/ ::: 1
m!! ::: !! ::: 1

# --- PERFORMANCE TESTS ---
# Healthy Regex
^\d+$ ::: 12345678901234567890 ::: 1
# Potentially catastrophic regex
^(a+)+$ ::: aaaaaaaaaaaaaaaaaaaaaab ::: 0

# --- TESTS OF DEATH (EXPLOSIVE BACKTRACKING) ---
# This (a+)+$ pattern doubles calculation time with each added 'a'
# if it fails on the last character.
(a+)+$ ::: aaaaaaaaaaaaaaaaaaaaaab ::: 0

# Nested alternations trap
^([a-zA-Z0-9]+\s?)*$ ::: This is a phrase that looks normal but will freeze if an invalid symbol is added at the end @ ::: 0

# Classic "Evil Regex" (Domain detection)
^([a-zA-Z0-9](([-a-zA-Z0-9]*[a-zA-Z0-9])?)\.)+[a-zA-Z]{2,6}$ ::: a-domain-name-that-is-way-too-long-and-invalid-at-the-end-because-it-ends-with-a-digit-1 ::: 0

# --- THE "DEATH THAT KILLS" TESTS (EXTREME RE-DOS) ---

# 1. Fatal Nesting (The classic server-melter)
# Every additional 'a' multiplies time by 2.
# At 30 'a's, get a coffee; at 40, retire.
^(a+)+$ ::: aaaaaaaaaaaaaaaaaaaaaaaaaaaaaab ::: 0

# 2. Overlapping Alternation (The parser's nightmare)
# Engine hesitates between (a+), (a*) and (b) at each iteration.
^([a-zA-Z]+)*$ ::: aaaaaaaaaaaaaaaaaaaaaaaaaaaaaa! ::: 0

# 3. The Vacuum Pump
# Three quantifiers fighting for the same letter.
(a|a?)+$ ::: aaaaaaaaaaaaaaaaaaaaaaaaaaaaaab ::: 0

# 4. The Final Dot Trap
# Very common in poorly written URL or Email validations.
^(.+)+!$ ::: This_is_a_very_long_string_that_will_never_match_the_exclamation_mark_at_the_end_but_it_will_try_every_single_combination_possible_before_giving_up ::: 0

# The Triple Threat: Three levels of indecision
# On 25 chars, Perl will explore millions of branches.
^(([a-z]+)*[a-z]+)*$ ::: aaaaaaaaaaaaaaaaaaaaaaaaaab ::: 0

# --- TESTS OF DEATH (TRUE BACKTRACKING) ---

# 1. Class Overlap (The Sluggish Matcher)
# Perl can't decide if 'a' goes into \w+ or [a-z]+
^(\w+[a-z]+)*$ ::: aaaaaaaaaaaaaaaaaaaaaaaaaab ::: 0

# 2. "Evil" Alternation
# (a|aa)* seems simple, but if it doesn't end with 'b',
# combinations follow the Fibonacci sequence.
^ (a|aa)*b $ ::: aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa ::: 0

# 3. Nested Overlap (The most violent)
# ".*" and "(.+)*" fight over every single character.
^ (.* (.+)*) + ! $ ::: this_phrase_is_just_long_enough_to_break_everything_right_here ::: 0

# --- APOCALYPSE TESTS (VERIFIED RE-DOS) ---
warning: Test with timeout or few characters first!
^(([a-z]+)*[a-z]+)*$ ::: aaaaaaaaaaaaaaaaaaaaaaaaaab ::: 0
^(\w+\s*)*$ ::: This sentence is a trap because it ends with a slash / ::: 0
^(a|aa)*b$ ::: aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa ::: 0

# CRASH TEST (Check your timeout first!)
^(([0-9]+)*\d+)*$ ::: 11111111111111111111111111111111X ::: 0

# The Real Apocalypse.
# Engine tests every combination of 1 or more digits recursively.
^(\d+)*\d$ ::: 111111111111111111111111111111 ::: 0

# Engine must choose between 'a' or 'aa' at each step.
# For 30 'a's, there are millions of combinations.
^(a|aa)*$ ::: aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaab ::: 0

# Engine tries to distribute string between two .* in every possible way.
# Exponential complexity O(n^2) or O(n^3).
^ (.* .*) + $ ::: aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa! ::: 0

# Positive lookahead containing a repetition.
# For every 'a', the engine checks if the rest can be divided into (a+)+
(?=(a+)+)a*b ::: aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa ::: 0

# Test 1 : L'Euro bloque le chiffre (ton cas actuel)
(?=€)\d+ ::: €100 ::: 0

# Test 2 : On consomme l'Euro, puis on cherche le chiffre
€\d+ ::: €100 ::: 0

# Test 3 : L'assertion sur l'Euro, mais on commence APRES l'Euro
\d+ ::: €100 ::: 3

# === t/01-engine.t (Core Logic) ===
abc ::: abc ::: 1
abc ::: abd ::: 0
^abc ::: abc ::: 1
^abc ::: xabc ::: 0
abc$ ::: abc ::: 1
abc$ ::: abcd ::: 0
a.c ::: abc ::: 1
a.c ::: abbc ::: 0
a* ::: aaaa ::: 1
a* ::: b ::: 1
a+ ::: aaaa ::: 1
a+ ::: b ::: 0

# === t/02-captures.t & t/03-stress.t (Quantifiers & Anchors) ===
^\d{3}$ ::: 12a ::: 0
\d{2} ::: 12 ::: 1
a+b ::: aaax ::: 0
^abc$ :::  ::: 0
^abc$ ::: abd ::: 0
(abc|def)\d+ ::: abcd ::: 0
xyz ::: abc ::: 0
\[\d\] ::: [a] ::: 0
abc$ ::: ab ::: 0
a.c.e ::: abcx ::: 0
^a ::: b ::: 0
abc ::: ABX ::: 0
a(b)c ::: abc ::: 1

# === t/07-boundary.t (Word Boundaries) ===
\bcat ::: cat ::: 1
cat\b ::: cat ::: 1
ca\bt ::: cat ::: 0
cat\b  ::: cat  ::: 1
\bcat ::: !cat ::: 1
\bcat\b ::: the cat sits ::: 1

# === t/08-alternations.t (OR Branches & Backtracking) ===
a|b ::: a ::: 1
a|b ::: b ::: 1
a|b ::: c ::: 0
(a|b)c ::: ac ::: 1
(a|b)c ::: bc ::: 1
(a|b)c ::: cc ::: 0
((a|b)c)d ::: acd ::: 1
(az|b)c ::: bc ::: 1
(a|ab)c ::: abc ::: 1
(?=a)a ::: a ::: 1

# === t/09-lazy.t (Non-greedy Quantifiers) ===
a+? ::: aaaa ::: 1
a+?b ::: aaab ::: 1
a*? ::: aaaa ::: 1
a?? ::: aaaa ::: 1
.*?b ::: aaabcccb ::: 1

# === t/10-backref.t (Backreferences) ===
(a)x\1 ::: axa ::: 1
(a|b)x\1 ::: axa ::: 1
(a|b)x\1 ::: bxb ::: 1
(a|b)x\1 ::: axb ::: 0
(a)(b)\1\2 ::: abab ::: 1
((a)b)\2 ::: aba ::: 1

# === t/11 & t/13 (Fixed & Range Quantifiers) ===
a{3} ::: aaaaa ::: 1
a{3} ::: aa ::: 0
a{2,4} ::: aaaaa ::: 1
a{2,} ::: aaaaa ::: 1
a{3,5} ::: aa ::: 0
a{2,4}? ::: aaaaa ::: 1
a{2,3}b ::: aab ::: 1
a{x} ::: a{x} ::: 1

# === t/12-modifiers.t (Flags ?i, ?s) ===
(?i)abc ::: ABC ::: 1
(?i)abc ::: ABD ::: 0
(?i)a(?-i)B ::: ab ::: 0
(?s)a.b ::: a\nb ::: 1
(?is)A.b ::: a\nB ::: 1

# === t/14-look-around.t (Lookahead) ===
A(?=B) ::: AC ::: 0
prix(?=\x{20ac}) ::: prix$ ::: 0

# === t/15-anchors.t (Final Stabilized Anchors) ===
^A ::: A ::: 1
^A ::: BA ::: 0
A$ ::: A ::: 1
A$ ::: AB ::: 0
^AB$ ::: AB ::: 1
^AB$ ::: ABC ::: 0

# The "Test de la Mort qui Tue" (nested and complex)
^(abc|def)\d{2,4}(x|y)$ ::: abc123x  abc12  def9999z

# --- THE LEGENDARY EXPONENTIAL TEST (10-20s Range) ---
# 2^25 combinations. Long enough to show the stress,
# short enough to prove the script finishes.
^(a?){25}a{25}$ ::: aaaaaaaaaaaaaaaaaaaaaaaaaa ::: 1

__DATA__
1;