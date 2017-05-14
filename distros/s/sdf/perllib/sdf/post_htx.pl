# $Id$
$VERSION{''.__FILE__} = '$Revision$';
#
# >>Title::     htx Post Processing Filter
#
# >>Copyright::
# Copyright (c) 1992-1997, Ian Clatworthy (ianc@mincom.com).
# You may distribute under the terms specified in the LICENSE file.
#
# >>History::
# -----------------------------------------------------------------------
# Date      Who     Change
# 08-Sep-97 ianc    Ported Craig Willis' stuff from gendoc
# -----------------------------------------------------------------------
#
# >>Purpose::
# {{htx_PostFilter}} post filters plain text format to generate
# HTX format for MIMS SmartGUI applications.
#

sub htx_PostFilter {
    local(*text) = @_;
    local(@result);
    local($_);
    local( $htx_line, $mod_name_sw, $mod_line, $mod_name,
          $nomove_sw, $write_sw );
    
    for (@text) {
        local($htx_sw, $line, $tmp_line);
        chop($line = $_);
        
        # Check if module & module_name has been defined
        if ( $line =~ /^&HTX&MODULE(_NAME)?/ ) {
        
            if ( $line =~ /&MODULE_NAME/ ) {
                $mod_name_sw++;
            }
            $line =~ s/^&HTX&MODULE(_NAME)?($|[\t ]+)//;
            $mod_name = $line if ( $mod_name_sw);
            $mod_line = $line unless ( $mod_name_sw);
            
        }
        # Setup when to start writing to file and stop
        if ( $line =~ /$HTX_FIRST_HDR$/ || $HTX_FIRST_HDR eq '' ) {
            $write_sw++;
        }
        elsif ( $line =~ /$HTX_LAST_HDR$/ && $HTX_LAST_HDR ne '' ) {
            $write_sw = 0;
        }
        
        # Check for HTX lines
        if ( $line =~ /^&HTX +/ ) {
            ($htx_line = $line) =~ s/^\&HTX +//;
            $htx_sw++;
        }
        elsif ( $htx_line ne '' && !$htx_sw && $line ne '' ) {
            $line .= " $htx_line";
            $htx_line = '';
        }
        
        if ( $write_sw ) {
            push(@result, "$line\n") unless $htx_sw;
        }
    }

    # Need to print the terminating characters for a HTX file
    ($htx_line = $DOCO) =~ s/^(tmp_)?\d+_|(\.sdf$)//g;
    $htx_line =~ tr/a-z/A-Z/;
    push(@result, "$htx_line\n");
    push(@result, "$mod_line $mod_name\n");

    # Return result
    return @result;
}

# package return value
1;
