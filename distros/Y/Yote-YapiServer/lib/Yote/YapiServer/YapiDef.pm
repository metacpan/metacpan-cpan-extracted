package Yote::YapiServer::YapiDef;

use strict;
use warnings;

#======================================================================
# Public API
#======================================================================

# Parse a .ydef file and return an arrayref of definition hashrefs,
# each matching the structure that YAML::LoadFile would produce.
sub parse_file {
    my ($filename) = @_;
    open my $fh, '<', $filename or die "Cannot open $filename: $!\n";
    my $text = do { local $/; <$fh> };
    close $fh;
    return parse_string($text, $filename);
}

sub parse_string {
    my ($text, $source) = @_;
    $source //= '<string>';

    my @lines = split /\n/, $text;
    my $pos = 0;
    my @defs;
    my $current_app;  # when inside an app block, nested objects attach here

    while ($pos <= $#lines) {
        my $line = $lines[$pos];

        # Skip blank lines and comments
        if ($line =~ /^\s*$/ || $line =~ /^\s*#/) {
            $pos++;
            next;
        }

        # app PACKAGE {
        if ($line =~ /^\s*app\s+(\S+)\s*\{/) {
            my $pkg = $1;
            my ($block, $new_pos) = parse_block(\@lines, $pos + 1);
            my $def = process_app_block($block, $pkg);
            push @defs, $def;
            $current_app = $def;
            $pos = $new_pos;
            next;
        }

        # object NAME { ... } — standalone or after app
        if ($line =~ /^\s*object\s+(\S+)\s*\{/) {
            my $name = $1;
            my ($block, $new_pos) = parse_block(\@lines, $pos + 1);
            if ($current_app && $name !~ /::/) {
                # Nested object — attach to the current app
                my $obj_def = process_object_block($block);
                $current_app->{objects}{$name} = $obj_def;
            } else {
                # Standalone object
                my $def = process_object_block($block);
                $def->{type} = 'object';
                $def->{package} = $name;
                push @defs, $def;
            }
            $pos = $new_pos;
            next;
        }

        # server PACKAGE {
        if ($line =~ /^\s*server\s+(\S+)\s*\{/) {
            my $pkg = $1;
            my ($block, $new_pos) = parse_block(\@lines, $pos + 1);
            my $def = process_server_block($block, $pkg);
            push @defs, $def;
            $current_app = undef;
            $pos = $new_pos;
            next;
        }

        # Anything else at top level is unexpected
        die "Parse error in $source at line " . ($pos + 1) . ": unexpected '$line'\n";
    }

    return \@defs;
}

#======================================================================
# Block parsing — read lines until matching closing brace
#======================================================================

# Returns (arrayref of lines inside the block, next position after closing brace)
sub parse_block {
    my ($lines, $pos) = @_;
    my @block;
    my $depth = 1;

    while ($pos <= $#$lines && $depth > 0) {
        my $line = $lines->[$pos];
        my $delta = brace_delta($line);
        $depth += $delta;

        if ($depth <= 0) {
            # The closing brace line — capture any content before the }
            my $before = $line;
            $before =~ s/\}\s*$//;
            push @block, $before if $before =~ /\S/;
            $pos++;
            last;
        }

        push @block, $line;
        $pos++;
    }

    return (\@block, $pos);
}

# Count net brace depth change on a line, skipping braces in strings and comments
sub brace_delta {
    my ($line) = @_;
    my $delta = 0;
    my ($in_sq, $in_dq) = (0, 0);

    for my $i (0 .. length($line) - 1) {
        my $ch = substr($line, $i, 1);
        my $prev = $i > 0 ? substr($line, $i - 1, 1) : '';

        # Comment — stop counting (but $# is Perl's array-last-index, not a comment)
        last if $ch eq '#' && !$in_sq && !$in_dq && $prev ne '$';

        if    ($ch eq "'" && !$in_dq && $prev ne '\\') { $in_sq = !$in_sq }
        elsif ($ch eq '"' && !$in_sq && $prev ne '\\') { $in_dq = !$in_dq }
        elsif (!$in_sq && !$in_dq) {
            $delta++ if $ch eq '{';
            $delta-- if $ch eq '}';
        }
    }

    return $delta;
}

#======================================================================
# Process top-level block types
#======================================================================

sub process_app_block {
    my ($block_lines, $pkg) = @_;
    my $def = {
        type    => 'app',
        package => $pkg,
    };
    parse_block_content($block_lines, $def);
    return $def;
}

sub process_object_block {
    my ($block_lines) = @_;
    my $def = {};
    parse_block_content($block_lines, $def);
    return $def;
}

sub process_server_block {
    my ($block_lines, $pkg) = @_;
    my $def = {
        type    => 'server',
        package => $pkg,
    };
    parse_server_content($block_lines, $def);
    return $def;
}

#======================================================================
# Parse block content (app or object interior)
#======================================================================

sub parse_block_content {
    my ($lines, $def) = @_;
    my $pos = 0;

    while ($pos <= $#$lines) {
        my $line = $lines->[$pos];

        # Skip blank lines and comments
        if ($line =~ /^\s*$/ || $line =~ /^\s*#/) {
            $pos++;
            next;
        }

        # cols { ... }
        if ($line =~ /^\s*cols\s*\{/) {
            my ($inner, $new_pos) = parse_block($lines, $pos + 1);
            $def->{cols} = parse_key_value_lines($inner);
            $pos = $new_pos;
            next;
        }

        # field_access { ... }
        if ($line =~ /^\s*field_access\s*\{/) {
            my ($inner, $new_pos) = parse_block($lines, $pos + 1);
            $def->{field_access} = parse_key_value_lines($inner);
            $pos = $new_pos;
            next;
        }

        # values { ... } → public_vars
        if ($line =~ /^\s*values\s*\{/) {
            my ($inner, $new_pos) = parse_block($lines, $pos + 1);
            $def->{public_vars} = parse_values_block($inner);
            $pos = $new_pos;
            next;
        }

        # vars { ... }
        if ($line =~ /^\s*vars\s*\{/) {
            my ($inner, $new_pos) = parse_block($lines, $pos + 1);
            $def->{vars} = parse_values_block($inner);
            $pos = $new_pos;
            next;
        }

        # uses { ... }
        if ($line =~ /^\s*uses\s*\{/) {
            my ($inner, $new_pos) = parse_block($lines, $pos + 1);
            $def->{uses} = parse_uses_block($inner);
            $pos = $new_pos;
            next;
        }

        # method ACCESS NAME { CODE }
        if ($line =~ /^\s*method\s+(\S+)\s+(\w+)\s*\{/) {
            my ($access_str, $name) = ($1, $2);
            my ($code_lines, $new_pos) = parse_code_block($lines, $pos);
            my $code = join("\n", @$code_lines);

            my $access = parse_access($access_str);

            $def->{methods}{$name} = {
                access => $access,
                code   => $code,
            };
            $pos = $new_pos;
            next;
        }

        # sub NAME { CODE }
        if ($line =~ /^\s*sub\s+(\w+)\s*\{/) {
            my $name = $1;
            my ($code_lines, $new_pos) = parse_code_block($lines, $pos);
            my $code = join("\n", @$code_lines);
            $def->{subs}{$name} = $code;
            $pos = $new_pos;
            next;
        }

        # base PACKAGE (single line, no braces)
        if ($line =~ /^\s*base\s+(\S+)\s*$/) {
            $def->{base} = $1;
            $pos++;
            next;
        }

        # Fallthrough — skip unrecognized content
        $pos++;
    }
}

#======================================================================
# Parse server content
#======================================================================

sub parse_server_content {
    my ($lines, $def) = @_;
    my $pos = 0;

    while ($pos <= $#$lines) {
        my $line = $lines->[$pos];

        if ($line =~ /^\s*$/ || $line =~ /^\s*#/) {
            $pos++;
            next;
        }

        # cols { ... }
        if ($line =~ /^\s*cols\s*\{/) {
            my ($inner, $new_pos) = parse_block($lines, $pos + 1);
            $def->{cols} = parse_key_value_lines($inner);
            $pos = $new_pos;
            next;
        }

        # apps { ... }
        if ($line =~ /^\s*apps\s*\{/) {
            my ($inner, $new_pos) = parse_block($lines, $pos + 1);
            $def->{apps} = parse_key_value_lines($inner);
            $pos = $new_pos;
            next;
        }

        # uses { ... }
        if ($line =~ /^\s*uses\s*\{/) {
            my ($inner, $new_pos) = parse_block($lines, $pos + 1);
            $def->{uses} = parse_uses_block($inner);
            $pos = $new_pos;
            next;
        }

        # base PACKAGE
        if ($line =~ /^\s*base\s+(\S+)\s*$/) {
            $def->{base} = $1;
            $pos++;
            next;
        }

        $pos++;
    }
}

#======================================================================
# Parse inner block formats
#======================================================================

# Simple key-value: "key rest_of_line"
sub parse_key_value_lines {
    my ($lines) = @_;
    my %kv;
    for my $line (@$lines) {
        next if $line =~ /^\s*$/ || $line =~ /^\s*#/;
        if ($line =~ /^\s*(\S+)\s+(.+?)\s*$/) {
            $kv{$1} = $2;
        }
    }
    return \%kv;
}

# Values block: key value, with support for multi-line quoted strings
sub parse_values_block {
    my ($lines) = @_;
    my %kv;
    my $pos = 0;

    while ($pos <= $#$lines) {
        my $line = $lines->[$pos];

        if ($line =~ /^\s*$/ || $line =~ /^\s*#/) {
            $pos++;
            next;
        }

        # key "multi-line value..."
        if ($line =~ /^\s*(\S+)\s+"(.*?)"\s*$/) {
            # Single-line quoted value (complete on one line)
            $kv{$1} = $2;
            $pos++;
            next;
        }

        if ($line =~ /^\s*(\S+)\s+"(.*)$/) {
            # Multi-line quoted value — opening quote without closing
            my $key = $1;
            my $val = $2;
            $pos++;
            while ($pos <= $#$lines) {
                my $next = $lines->[$pos];
                if ($next =~ /^(.*?)"\s*$/) {
                    $val .= "\n" . $1;
                    $pos++;
                    last;
                } else {
                    $val .= "\n" . $next;
                    $pos++;
                }
            }
            $kv{$key} = $val;
            next;
        }

        # Unquoted: key rest_of_line
        if ($line =~ /^\s*(\S+)\s+(.+?)\s*$/) {
            $kv{$1} = $2;
        }

        $pos++;
    }

    return \%kv;
}

# Uses block: one module per line
sub parse_uses_block {
    my ($lines) = @_;
    my @mods;
    for my $line (@$lines) {
        next if $line =~ /^\s*$/ || $line =~ /^\s*#/;
        if ($line =~ /^\s*(\S+)/) {
            push @mods, $1;
        }
    }
    return \@mods;
}

#======================================================================
# Parse code blocks (method/sub bodies) with brace counting
#======================================================================

# Given lines array and position of the opening line (e.g. "method public foo {"),
# return (code_lines_arrayref, next_position)
sub parse_code_block {
    my ($lines, $start_pos) = @_;

    my $opening_line = $lines->[$start_pos];
    my @code;
    my $depth = brace_delta($opening_line);  # Usually +1 from the opening {

    # Capture any code on the opening line after the {
    if ($opening_line =~ /\{\s*(.+)$/) {
        my $rest = $1;
        # Check if this rest doesn't just close the brace
        if ($rest =~ /\S/ && $rest !~ /^\s*\}\s*$/) {
            push @code, $rest;
        }
    }

    my $pos = $start_pos + 1;

    while ($pos <= $#$lines && $depth > 0) {
        my $line = $lines->[$pos];
        my $delta = brace_delta($line);
        $depth += $delta;

        if ($depth <= 0) {
            # Closing brace line — capture content before the }
            my $before = $line;
            $before =~ s/\}\s*$//;
            push @code, $before if $before =~ /\S/;
            $pos++;
            last;
        }

        push @code, $line;
        $pos++;
    }

    # Strip common leading whitespace from code lines
    my @trimmed = strip_indent(\@code);

    return (\@trimmed, $pos);
}

# Remove common leading whitespace
sub strip_indent {
    my ($lines) = @_;
    return () unless @$lines;

    # Find minimum indentation (ignoring blank lines)
    my $min_indent;
    for my $line (@$lines) {
        next unless $line =~ /\S/;
        my ($spaces) = $line =~ /^(\s*)/;
        my $len = length($spaces);
        $min_indent = $len if !defined $min_indent || $len < $min_indent;
    }
    $min_indent //= 0;

    return map {
        my $l = $_;
        if ($l =~ /\S/) {
            substr($l, 0, $min_indent) = '' if $min_indent > 0;
        }
        $l;
    } @$lines;
}

#======================================================================
# Parse access level string
#======================================================================

sub parse_access {
    my ($str) = @_;
    if ($str =~ /,/) {
        # Compound: "auth,owner_only" → { auth => 1, owner_only => 1 }
        my %access;
        for my $part (split /,/, $str) {
            $access{$part} = 1;
        }
        return \%access;
    }
    # Simple: "public", "auth", "admin_only"
    return $str;
}

1;
