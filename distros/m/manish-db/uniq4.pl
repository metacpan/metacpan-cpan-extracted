#!/usr/bin/perl -w

# open and read the file containing the data into an array called "lines"
open (TXTFILE, "test");
@lines = <TXTFILE>;
close(TXTFILE);

# variable to hold the information to print
$print_this = "";

# variable to check whether we should be printing
$printing = 0;

# an array holding starting/ending points to check we do not duplicate things
@points = "";

# a variable to say whether we should output the information or not
$should_output = 0;

# variables to hold the starting and ending points
$start_point = "";
$end_point = "";

# loop through the text file and process the data
foreach $newline (@lines) {
  # if the line is a starting point then...
  if ($newline =~ m/^$/) {
    # remember what is found in the text file until $printing is changed
    $printing = 1;
    # the start point is
    $start_point = $newline;
  }

  # if the line is a ending point then...
  $end_point = $newline if ($newline =~ m/^$/);

  # if we have seen the start and end point then process them
  if ( ( $start_point ne "" ) && ( $end_point ne "" ) ) {
    # join the start and end points
    $start_point = $start_point . " " . $end_point;
    # if we have not seen this start/end point before...
    if ( grep(/$start_point/, @points) == 0 ) {
      # remember it by adding it to our points array
      push @points, $start_point;
      # indicate that the information should be printed out
      $should_output = 1;
    }
  }

  # if the line begins with "slack" and the info should be printed...
  if ( ($newline =~ m/^ram/) && ($should_output == 1) ) {
    # print it out!
    print $print_this . $newline . "\n";
  };

  # if the line begins with "slack" then reset the variables
  if ( $newline =~ m/^ram/ ) {
    $printing = 0;
    $print_this = "";
    $should_output = 0;
    $start_point = "";
    $end_point = "";
  };

  # if the endpoint has not been reached but we are printing
  if ( $printing == 1 ) {
    # add the new line to the data that could be printed out
    $print_this .= $newline;
  };

}; # end loop through text file

# end the script
exit(0);

