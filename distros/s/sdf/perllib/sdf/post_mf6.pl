# $Id$
$VERSION{''.__FILE__} = '$Revision$';
#
# >>Title::     mf6 Post Processing Filter
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
# {{mf6_PostFilter}} post filters plain text format to generate
# MIMS F6 Help format.
#

sub mf6_PostFilter {
    local(*text) = @_;
    local(@result);
    local($_);
    local($client_sw, $header_sw, $idx_k, $idx_s, $key_sw, $part1, $part2, 
          $print_sw, $screen_sw, $subtopic_sw);
    
    $ADD_SW    = $SPLIT_SW  = 0;
    $idx_k     = $idx_s     = -1;
    $CONT_TEXT = '';

    for (@text) {
        $_        =~ s/\n//;
        $line     = $_;
        $print_sw = 1;

        # If '&CLIENT' is found, it is the start of a new file
        if ( $_ =~ /^&CLIENT +/i ) {
            ( $part1 = $& ) =~ s/ +$//;

            if ( $client_sw ) {
                &End_File($subtopic_sw); 
                $header_sw   = 0;
                $key_sw      = 0;
                $screen_sw   = 0;
                $subtopic_sw = 0;
                $idx_k       = -1;
                $idx_s       = -1;
            }
            else {
                push(@result, "\\001\\001\n");
            }

            push(@result, " &BEGIN_TEXT_FILE\n");

            &Get_Client_Dets unless ( $client_sw );
            $client_sw++;
            $line = sprintf(" %-19s%-60s",$part1,$CLIENT);
        }
        # If client name, format line
        elsif ( $_ =~ /^&(CLIENT-NAME) +/i ) {
            ( $part1 = $& ) =~ s/ +$//;
            $line = sprintf(" %-19s%-60s",$part1,$CLIENT_NAME);
        }
        # If machine , format line
        elsif ( $_ =~ /^&MACHINE +/i ) {
            ( $part1 = $& ) =~ s/ +$//;
            $line = sprintf(" %-19s%-60s",$part1,$MACHINE);
        }
        # If you reach '&SUBTOPICS' and 1st one, it is the end of text area
        elsif ( $_ =~ /^&SUBTOPICS +/i ) {
            push(@result, " &END_TEXT\n") unless $subtopic_sw;
            $subtopic_sw++;
            ( $line = $_ ) =~ s/\n$//;
            $line = " $line";
        }
        # Format line for list of variables
        elsif ( $_ =~ /^&(MODULE|MODULE-NAME|TOPIC|TOPIC-GROUP|VERSION) +/ ||
               $_ =~ /^&(ENQUIRY|SAMPLE) */ ) {
            $part1 = $& ;
            ( $part2 = $' ) =~ s/^ +| *$//;
            $part1 =~ s/&//;
            $part1 =~ s/ +//;
            $line = sprintf(" &%-18s%-60s",$part1, $part2);
            $VARIABLES{"$part1"} = $part2;
            $header_sw++;
        }
        # If 'KEYWORD' save keyword to be processed after end of text
        elsif ( $_ =~ /^&KEYWORDS +/i ) {
            $KEYWORDS[++$idx_k] = $';

            # If a keyword continues onto more than one line
            if ( $KEYWORDS[$idx_k] =~ / >> *$/ ) {
                $key_sw++;
            }
            else {
                $key_sw = 0;
            }
            $print_sw = 0;
        }
        # There is a continuation of the KEYWORD over multiple lines
        elsif ( $key_sw ) {
            $KEYWORDS[$idx_k] .= $_;
            if ( $_ =~ / >> *$/ ) {
                $key_sw++;
            }
            else {
                $key_sw = 0;
            }
            $print_sw = 0;
        }           
        # Else TEXT
        else {
            # Start of text area if header_sw is set
            if ( $header_sw > 0 ) {
                if ( $line =~ /^ *$/ || $line eq '' ) {
                    $line = " &BEGIN_TEXT";
                }
                elsif ( $line =~ /^ +\d+(\.\d+)* *\w+/ ) {
                    $line = " &BEGIN_TEXT\n$line";
                }
                $header_sw = 0;
            }
            # If line defines a screen, replace line and set switch to store screen in array
            elsif ( $line =~ /^\d+(\.\d+)*\W+Screen MSM[0-9A-Z]+/ ) {
                if ( $line =~ /^\d+(\.\d+)*\W+Screen / ) {
                    ( $part2 = $' )  =~ s/ *$//;
                }
                else {
                    &AppMsg("warning", "can not file correct screen layout");
                }
                $line = " .INSERT_SCREEN $part2";
                $SCREEN[++$idx_s] = "                               Screen Layout - $part2";
                $screen_sw++;
            }
            elsif ( $line =~ /^\d+(\.\d+)* / ) { # Header line
                $line = sprintf(" %-83s",$line) if ( $client_sw );
                $print_sw = 1;
            }
            # If line is less than 80 and a normal text line and screen, set flag not to print
            else {
                $line = sprintf(" %-80s",$line) if ( $client_sw && length($line) < 75 );
                if ( $screen_sw ) {
                    $SCREEN[++$idx_s] = "$line";
                    $print_sw = 0;
                }
            }
        }
        # If we are printing this line, format it to 83 characters wide
        if ( $print_sw ) {
            $line = &Format_Line($line);
            push(@result, "$line\n");
        }
    }

    &End_File($subtopic_sw); 

    # Return result
    return @result;
}
# 
# Get_Client_Dets: Will ask for a client ID and get client name and machine
#
sub Get_Client_Dets {
    local( @client_array, $client_dir, $client_list, $found_sw);

    # Get the client code
    $CLIENT = $SDF_USER'var{'MIMS_CLIENT_CODE'};
    if ( $CLIENT eq '') {
        &AppExit('fatal', "MIMS_CLIENT_CODE variable must be specified");
    }

    $client_dir  = "/usr/m3conv/client/";
    $client_list = "${client_dir}client.codes";
    unless ( -d "$client_dir") {
        &AppExit('fatal', "Could not locate client directory '$client_dir'");
    }
    unless ( -r "$client_list") {
        &AppExit('fatal', "Could not locate client list '$client_list'");
    }

    open(CLIENT_FH, $client_list) ||
      &AppExit('fatal', "Could not open client list '$client_list'");
    while ( <CLIENT_FH> ) {
        @client_array = split(/,/,$_,4);
        if ( $client_array[0] eq $CLIENT) {
            $found_sw++;
            last;
        }
    }
    close ( CLIENT_FH );

    &AppExit('fatal', "$CLIENT is not a valid client code") unless $found_sw;
    
    $CLIENT_NAME = $client_array[$#client_array]; # Client name is last in array
    $CLIENT_NAME =~ s/^ *//;
    $CLIENT_NAME =~ s/\n//;
    $MACHINE     = $client_array[2]; # Client machine is always the 3rd array element
    $CLIENT      = 'MIMS';
    $CLIENT_NAME = 'MIMS';
    $MACHINE     = 'UNIX';
}

#
# End_File: Manipulates the EOF processing within the MIMS Online Help Generation
#
sub End_File {
    local( $end_sw, *result) = @_;
    local( $keyword);

    push(@result, " &END_TEXT\n") unless ( $end_sw );
    foreach $keyword (@KEYWORDS) {
        $keyword =~ s/ *$//;
        $line = sprintf (" %-19s%-62s",'&KEYWORDS',$keyword);
        push(@result, "$line\n");
    }
    undef(@KEYWORDS);
    push(@result, " &END_TEXT_FILE\n");

    if ( $SCREEN[0] ne '' ) {   # If a screen has been specified
        push(@result, " &BEGIN_TEXT_FILE\n");
        push(@result, sprintf(" %-19s%-62s\n",'&CLIENT',$CLIENT));
        push(@result, sprintf(" %-19s%-62s\n",'&CLIENT_NAME',$CLIENT_NAME));
        push(@result, sprintf(" %-19s%-62s\n",'&MACHINE',$MACHINE));
        foreach $key (keys (%VARIABLES)) {
            $VARIABLES{$key} = 'SCREEN' if ( $key eq 'TOPIC' ) ;
            push(@result, sprintf(" &%-18s%-63s\n",$key,$VARIABLES{"$key"}));
        }

        push(@result, "&BEGIN_SCREEN\n");
        foreach $line (@SCREEN) {
            push(@result, "$line\n");
        }
        push(@result, " &END_SCREEN\n");
        push(@result, " &END_TEXT_FILE\n\n");
        undef(@SCREEN);
    }

    $ADD_SW    = 0;
    $CONT_TEXT = '';
}

#
# Format_Line: This will ensure the line is 83 characters long no matter what and
#              will wrap the lines if it is more than 83 chracters long.
#              Used for the MIMS Online Help generation
#
sub Format_Line {
    local( $line, *result) = @_;
    local( $idx, $text);

    $line =~ s/\t/    /g;       # Convert all tabs to 4 spaces
    $line =~ s/ +$//;           # Strip trailing spaces

  LINE: { 
      last LINE unless ( length($line) > 75 || $ADD_SW > 0 ); # 

      # If there is leftover text from previous line
      if ( $ADD_SW ) {
          $ADD_SW = 0;          # Initialise ADD_SW
          # If line is empty or full of spaces, print previous line 
          if ( $line =~ /^ *$/ ) {
              $CONT_TEXT = " $CONT_TEXT" if ( $CONT_TEXT !~ /^ / ) ; # Add leading space if line does not have one
              push(@result, "$CONT_TEXT\n");
              $CONT_TEXT = '';  # Del CONT_TEXT as it has been added to line
              last LINE;
          } 
          else {                # Else add the previous line to the current line
              $CONT_TEXT =~ s/^ +//;
              $CONT_TEXT =~ s/ +$//;

              if ( $line =~ /^ +/ && $SPLIT_SW ) {
                  $line = "${&}${CONT_TEXT}${'}";
                  $SPLIT_SW = 0;
              }
              elsif ( $CONT_TEXT =~ /^\w+/ ) {
                  $line = "${CONT_TEXT} $line";
              }
              else {
                  $line = "${CONT_TEXT}${line}";
              }

          }
      }                         # End ADD_SW

      $CONT_TEXT = '';  # Del CONT_TEXT as it has been added to line      

      # IF line ended in a split word ie thorough-
      if ( $line =~ /\w+\-$/ ) {
          $line = $`;
          ($text = $&) =~ s/\-$//;
          $ADD_SW++;
          $SPLIT_SW++;
      }
      else {
          $SPLIT_SW = 0;
      }

      
      @characters = split(//,$line);
      $idx        = $#characters;
      for (local($i)=($#characters); $i > 0 ; $i-- ) {
          if ( $characters[$i] =~ /\W/ && $i < 75 ) {
              $idx = $i;  
              last;
          }
      }
      for ( local($i)=++$idx; $i <= $#characters; $i++) {
          $CONT_TEXT = "${CONT_TEXT}${characters[$i]}";
      }
      $CONT_TEXT = "${CONT_TEXT}${text}" if ( $text ne '' );

      $#characters = --$idx if ( $idx != $#characters );
      $line        = '';        # Reset line to nothing
      foreach $char (@characters) { $line = "$line$char"};
      $ADD_SW++;      
  }

    $line = " $line" if ( $line !~ /^ / ) ; # Add leading space if line does not have one
    return("$line");
}

# package return value
1;
