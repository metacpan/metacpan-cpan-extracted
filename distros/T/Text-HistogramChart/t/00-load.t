#!perl -T

use 5.006_001;
use strict;
use warnings;

use Test::More tests => 92;

BEGIN {
	use lib qw{lib}; # add directory lib to search path.
    require_ok( 'Text::HistogramChart' ) || print "Bail out!\n"; # Attn. use require_ok, not use_ok! This is a pure OO module.
}

diag( "Testing Text::HistogramChart $Text::HistogramChart::VERSION, Perl $], $^X" );

use lib qw{lib}; # add directory lib to search path. (again)

#use Data::Dumper;
my $chart = Text::HistogramChart->new();

my @values;
my @legend_values;
my $expected_chart_picture;
my @expected_chart;
my @got_chart;
my $rval = 0;
my $chart_name = '';

$chart_name = "First Chart";
@values = (1, 2, 3, 4, 5, 6, 0, 7, 8, 9, 10, 9, 1);
$expected_chart_picture = '
                                                    |            
                                               |    |    |       
                                          |    |    |    |       
                                     |    |    |    |    |       
                           |         |    |    |    |    |       
                      |    |         |    |    |    |    |       
                 |    |    |         |    |    |    |    |       
            |    |    |    |         |    |    |    |    |       
       |    |    |    |    |         |    |    |    |    |       
  |    |    |    |    |    |         |    |    |    |    |    |  
';
@expected_chart = split "\n", $expected_chart_picture;
shift @expected_chart; # Remove the top empty row.
$chart->{'values'} = \@values;
#$chart->{'legend_values'} = \@legend_values;
$rval = $chart->chart();
ok($rval >= 1, "$chart_name creation");
@got_chart = @{$chart->{'screen'}};
#diag(Dumper(\@got_chart));
for(my $i = 0; $i < @expected_chart; $i++) {
	is($got_chart[$i], $expected_chart[$i], "$chart_name row $i match");
}



$chart_name = "Second Chart";
$chart_name = "Second Chart";
@values = (1, 2, 3, 4, 5, 6, 0, 7, 8, 9, 10, 9, 1);
#@legend_values = (1, 2, 3, 4, 5, 6, 7, 8, 9, 10);
$expected_chart_picture = '
10                                                       |            
9                                                   |    |    |       
8                                              |    |    |    |       
7                                         |    |    |    |    |       
6                               |         |    |    |    |    |       
5                          |    |         |    |    |    |    |       
4                     |    |    |         |    |    |    |    |       
3                |    |    |    |         |    |    |    |    |       
2           |    |    |    |    |         |    |    |    |    |       
1      |    |    |    |    |    |         |    |    |    |    |    |  
';
@expected_chart = split "\n", $expected_chart_picture;
shift @expected_chart; # Remove the top empty row.
$chart->{'values'} = \@values;
#$chart->{'legend_values'} = \@legend_values;
#$chart->{'screen_height'} = 10;              # (height reserved for the graph.)
#$chart->{'roof_value'} = 1;                  # (active if != 0), # Arbitrarily squeeze or extend the size (height) of bars (not screen)
#$chart->{'bottom_value'} = 1;                # (below floor, active if != 0), # Not yet implemented.
#$chart->{'floor_value'} = 1;                 # (the "floor" of the chart, default: 0)
#$chart->{'write_floor'} = 1;                 # (make floor visible)
#$chart->{'use_floor'} = 1;                   # (use the floor value)
#$chart->{'write_floor_value'} = 1;           # If value == floor_value, then write value (mostly "0").
$chart->{'write_legend'} = 1;                # (Prepend legend to each row.)
#$chart->{'legend_horizontal_width'} = 5;     # width of the space left for legend (left edge of chart)
#$chart->{'horizontal_width'} = 1;            # Horizontal width of one bar. This parameter directly influences the width of the screen (i.e. chart).
#$chart->{'write_value'} = 1;                 # (YES = 1, NO = 0, default: no; write the value on the end of the bar),
#$chart->{'write_always_over_value'} = 1;     # (YES = 1, NO = 0, default: yes; write the value only if it is too high for the graph),
#$chart->{'write_always_under_value'} = 1;    # (YES = 1, NO = 0, default: yes; write the value only if it is too low for the graph),
#$chart->{'bar_char'} = 1;                    # (default: '|')
#$chart->{'floor_char'} = 1;                  # (default '-' )
#$chart->{'over_value_char'} = 1;             # (default: '+')
#$chart->{'under_value_char'} = 1;            # (default: '-' )
$rval = $chart->chart();
ok($rval >= 1, "$chart_name creation");
@got_chart = @{$chart->{'screen'}};
for(my $i = 0; $i < @expected_chart; $i++) {
	is($got_chart[$i], $expected_chart[$i], "$chart_name row $i match");
}



$chart_name = "Third Chart";
@values = (1, 2, 3, 4, 5, 6, 0, 7, 8, 9, 10, 9, 1);
@legend_values = (2, 4, 6, 8, 10, 12, 14, 16, 18, 20);
$expected_chart_picture = '
20                                                                    
18                                                                    
16                                                                    
14                                                                    
12                                                                    
10                                                       |            
8                                              |    |    |    |       
6                               |         |    |    |    |    |       
4                     |    |    |         |    |    |    |    |       
2           |    |    |    |    |         |    |    |    |    |       
';
@expected_chart = split "\n", $expected_chart_picture;
shift @expected_chart; # Remove the top empty row.
$chart->{'values'} = \@values;
$chart->{'legend_values'} = \@legend_values;
#$chart->{'screen_height'} = 10;              # (height reserved for the graph.)
#$chart->{'roof_value'} = 1;                  # (active if != 0), # Arbitrarily squeeze or extend the size (height) of bars (not screen)
#$chart->{'bottom_value'} = 1;                # (below floor, active if != 0), # Not yet implemented.
#$chart->{'floor_value'} = 1;                 # (the "floor" of the chart, default: 0)
#$chart->{'write_floor'} = 1;                 # (make floor visible)
#$chart->{'use_floor'} = 1;                   # (use the floor value)
#$chart->{'write_floor_value'} = 1;           # If value == floor_value, then write value (mostly "0").
$chart->{'write_legend'} = 1;                # (Prepend legend to each row.)
#$chart->{'legend_horizontal_width'} = 5;     # width of the space left for legend (left edge of chart)
#$chart->{'horizontal_width'} = 1;            # Horizontal width of one bar. This parameter directly influences the width of the screen (i.e. chart).
#$chart->{'write_value'} = 1;                 # (YES = 1, NO = 0, default: no; write the value on the end of the bar),
#$chart->{'write_always_over_value'} = 1;     # (YES = 1, NO = 0, default: yes; write the value only if it is too high for the graph),
#$chart->{'write_always_under_value'} = 1;    # (YES = 1, NO = 0, default: yes; write the value only if it is too low for the graph),
#$chart->{'bar_char'} = 1;                    # (default: '|')
#$chart->{'floor_char'} = 1;                  # (default '-' )
#$chart->{'over_value_char'} = 1;             # (default: '+')
#$chart->{'under_value_char'} = 1;            # (default: '-' )
$rval = $chart->chart();
ok($rval >= 1, "$chart_name creation");
@got_chart = @{$chart->{'screen'}};
for(my $i = 0; $i < @expected_chart; $i++) {
	is($got_chart[$i], $expected_chart[$i], "$chart_name row $i match");
}



#$chart_name = "Fourth Chart";
#@values = (1, 2, 3, 4, 5, 6, 0, 7, 8, 9, 10, 9, 1);
#@legend_values = (1, 2, 3, 4, 5, 6, 7, 8, 9, 10);
#$expected_chart_picture = '
#10                                                       |            
#9                                                   |    |    |       
#8                                              |    |    |    |       
#7                                         |    |    |    |    |       
#6                               |         |    |    |    |    |       
#5    -----------------------------------------------------------------
#4                     |    |    |         |    |    |    |    |       
#3                |    |    |    |         |    |    |    |    |       
#2           |    |    |    |    |         |    |    |    |    |       
#1      |    |    |    |    |    |         |    |    |    |    |    |  
#';
#@expected_chart = split "\n", $expected_chart_picture;
#shift @expected_chart; # Remove the top empty row.
#$chart->{'values'} = \@values;
#$chart->{'legend_values'} = \@legend_values;
#$chart->{'screen_height'} = 10;               # (height reserved for the graph.)
##$chart->{'roof_value'} = 1;                  # (active if != 0), # Arbitrarily squeeze or extend the size (height) of bars (not screen)
##$chart->{'bottom_value'} = 1;                # (below floor, active if != 0), # Not yet implemented.
#$chart->{'floor_value'} = 5;                  # (the "floor" of the chart, default: 0)
#$chart->{'write_floor'} = 1;                  # (make floor visible)
#$chart->{'use_floor'} = 1;                    # (use the floor value)
##$chart->{'write_floor_value'} = 1;           # If value == floor_value, then write value (mostly "0").
#$chart->{'write_legend'} = 1;                 # (Prepend legend to each row.)
#$chart->{'legend_horizontal_width'} = 5;      # width of the space left for legend (left edge of chart)
##$chart->{'horizontal_width'} = 1;            # Horizontal width of one bar. This parameter directly influences the width of the screen (i.e. chart).
##$chart->{'write_value'} = 1;                 # (YES = 1, NO = 0, default: no; write the value on the end of the bar),
##$chart->{'write_always_over_value'} = 1;     # (YES = 1, NO = 0, default: yes; write the value only if it is too high for the graph),
##$chart->{'write_always_under_value'} = 1;    # (YES = 1, NO = 0, default: yes; write the value only if it is too low for the graph),
##$chart->{'bar_char'} = 1;                    # (default: '|')
#$chart->{'floor_char'} = 1;                   # (default '-' )
##$chart->{'over_value_char'} = 1;             # (default: '+')
##$chart->{'under_value_char'} = 1;            # (default: '-' )
#$rval = $chart->chart();
#ok($rval >= 1, "$chart_name creation");
#@got_chart = @{$chart->{'screen'}};
#for(my $i = 0; $i < @expected_chart; $i++) {
#	is($got_chart[$i], $expected_chart[$i], "$chart_name row $i match");
#}
#
#
$chart_name = "Fourth Chart";
@values = (1, 2, 3, 4, 5, 4, 3, 2, 1, 0, -1, -2, -3, -4, -5, -4, -3, -2, -1, 0);
@legend_values = (5, 4, 3, 2, 1, 0, -1, -2, -3, -4, -5);
$expected_chart_picture = '
5           |                               
4         | | |                             
3       | | | | |                           
2     | | | | | | |                         
1   | | | | | | | | |                       
0   ------------------0 ------------------0 
-1                      | | | | | | | | |   
-2                        | | | | | | |     
-3                          | | | | |       
-4                            | | |         
-5                              |           
';
@expected_chart = split "\n", $expected_chart_picture;
shift @expected_chart; # Remove the top empty row.
$chart->{'values'} = \@values;
$chart->{'legend_values'} = \@legend_values;
$chart->{'screen_height'} = 11;               # (height reserved for the graph.)
#$chart->{'roof_value'} = 0;                  # (active if != 0), # Arbitrarily squeeze or extend the size (height) of bars (not screen)
#$chart->{'bottom_value'} = 1;                # (below floor, active if != 0), # Not yet implemented.
$chart->{'floor_value'} = 0;                  # (the "floor" of the chart, default: 0)
$chart->{'write_floor'} = 1;                  # (make floor visible)
$chart->{'use_floor'} = 1;                    # (use the floor value)
$chart->{'write_floor_value'} = 1;            # If value == floor_value, then write value (mostly "0").
$chart->{'write_legend'} = 1;                 # (Prepend legend to each row.)
$chart->{'legend_horizontal_width'} = 4;      # width of the space left for legend (left edge of chart)
$chart->{'horizontal_width'} = 2;             # Horizontal width of one bar. This parameter directly influences the width of the screen (i.e. chart).
$chart->{'write_value'} = 0;                  # (YES = 1, NO = 0, default: no; write the value on the end of the bar),
$chart->{'write_always_over_value'} = 0;      # (YES = 1, NO = 0, default: yes; write the value only if it is too high for the graph),
$chart->{'write_always_under_value'} = 0;     # (YES = 1, NO = 0, default: yes; write the value only if it is too low for the graph),
$chart->{'bar_char'} = '|';                   # (default: '|')
$chart->{'floor_char'} = '-';                 # (default '-' )
$chart->{'over_value_char'} = '+';            # (default: '+')
$chart->{'under_value_char'} = '-';           # (default: '-' )
$rval = $chart->chart();
ok($rval >= 1, "$chart_name creation");
@got_chart = @{$chart->{'screen'}};
for(my $i = 0; $i < @expected_chart; $i++) {
	is($got_chart[$i], $expected_chart[$i], "$chart_name row $i match");
}



$chart_name = "Fifth Chart";
@values = (1, 2, 3, 4, 5, 4, 3, 2, 1, 0, -1, -2, -3, -4, -5, -4, -3, -2, -1, 0);
@legend_values = (4, 3, 2, 1, 0, -1, -2, -3, -4);
$expected_chart_picture = '
4         4 5 4                             
3       3 | | | 3                           
2     2 | | | | | 2                         
1   1 | | | | | | | 1                       
0   ------------------0 ------------------0 
-1                      -1| | | | | | | -1  
-2                        -2| | | | | -2    
-3                          -3| | | -3      
-4                            -4-5-4        
';
@expected_chart = split "\n", $expected_chart_picture;
shift @expected_chart; # Remove the top empty row.
$chart->{'values'} = \@values;
$chart->{'legend_values'} = \@legend_values;
$chart->{'screen_height'} = 9;               # (height reserved for the graph.)
#$chart->{'roof_value'} = 0;                  # (active if != 0), # Arbitrarily squeeze or extend the size (height) of bars (not screen)
#$chart->{'bottom_value'} = 1;                # (below floor, active if != 0), # Not yet implemented.
$chart->{'floor_value'} = 0;                  # (the "floor" of the chart, default: 0)
$chart->{'write_floor'} = 1;                  # (make floor visible)
$chart->{'use_floor'} = 1;                    # (use the floor value)
$chart->{'write_floor_value'} = 1;            # If value == floor_value, then write value (mostly "0").
$chart->{'write_legend'} = 1;                 # (Prepend legend to each row.)
$chart->{'legend_horizontal_width'} = 4;      # width of the space left for legend (left edge of chart)
$chart->{'horizontal_width'} = 2;             # Horizontal width of one bar. This parameter directly influences the width of the screen (i.e. chart).
$chart->{'write_value'} = 1;                  # (YES = 1, NO = 0, default: no; write the value on the end of the bar),
$chart->{'write_always_over_value'} = 0;      # (YES = 1, NO = 0, default: yes; write the value only if it is too high for the graph),
$chart->{'write_always_under_value'} = 0;     # (YES = 1, NO = 0, default: yes; write the value only if it is too low for the graph),
$chart->{'bar_char'} = '|';                   # (default: '|')
$chart->{'floor_char'} = '-';                 # (default '-' )
$chart->{'over_value_char'} = '+';            # (default: '+')
$chart->{'under_value_char'} = '_';           # (default: '-' )
$rval = $chart->chart();
ok($rval >= 1, "$chart_name creation");
@got_chart = @{$chart->{'screen'}};
for(my $i = 0; $i < @expected_chart; $i++) {
	is($got_chart[$i], $expected_chart[$i], "$chart_name row $i match");
}



$chart_name = "Sixth Chart";
@values = (1.2, 2.4, 3, 4.8, -1.7, -2, -3, 0, 0.1, -4.6, -5.8, -7.9);
@legend_values = (5, 4, 3, 2, 1, 0, -1, -2, -3, -4, -5, -6, -7, -8);
#@legend_values = ();
$expected_chart_picture = '
5                                                   
4               4.8                                 
3            3   |                                  
2       2.4  |   |                                  
1   1.2  |   |   |                                  
0   ---------------------------- 0  ----------------
-1                  -1.7 |   |           |   |   |  
-2                       -2  |           |   |   |  
-3                           -3          |   |   |  
-4                                      -4.6 |   |  
-5                                          -5.8 |  
-6                                               |  
-7                                              -7.9
-8                                                  
';
@expected_chart = split "\n", $expected_chart_picture;
shift @expected_chart; # Remove the top empty row.
$chart->{'values'} = \@values;
$chart->{'legend_values'} = \@legend_values;
$chart->{'screen_height'} = 14;               # (height reserved for the graph.)
$chart->{'roof_value'} = 5;                  # (active if != 0), # Arbitrarily squeeze or extend the size (height) of bars (not screen)
$chart->{'bottom_value'} = -8;                # (below floor, active if != 0), # Not yet implemented.
$chart->{'floor_value'} = 0;                  # (the "floor" of the chart, default: 0)
$chart->{'write_floor'} = 1;                  # (make floor visible)
$chart->{'use_floor'} = 1;                    # (use the floor value)
$chart->{'write_floor_value'} = 1;            # If value == floor_value, then write value (mostly "0").
$chart->{'write_legend'} = 1;                 # (Prepend legend to each row.)
$chart->{'legend_horizontal_width'} = 4;      # width of the space left for legend (left edge of chart)
$chart->{'horizontal_width'} = 4;             # Horizontal width of one bar. This parameter directly influences the width of the screen (i.e. chart).
$chart->{'write_value'} = 1;                  # (YES = 1, NO = 0, default: no; write the value on the end of the bar),
$chart->{'write_always_over_value'} = 0;      # (YES = 1, NO = 0, default: yes; write the value only if it is too high for the graph),
$chart->{'write_always_under_value'} = 0;     # (YES = 1, NO = 0, default: yes; write the value only if it is too low for the graph),
$chart->{'bar_char'} = '|';                   # (default: '|')
$chart->{'floor_char'} = '-';                 # (default '-' )
$chart->{'over_value_char'} = '+';            # (default: '+')
$chart->{'under_value_char'} = '_';           # (default: '-' )
$rval = $chart->chart();
ok($rval >= 1, "$chart_name creation");
@got_chart = @{$chart->{'screen'}};
#diag(Dumper(\@got_chart));
for(my $i = 0; $i < @expected_chart; $i++) {
	is($got_chart[$i], $expected_chart[$i], "$chart_name row $i match");
}



$chart_name = "Seventh Chart";
@values = (1.2, 2.4, 3, 4.8, 1.7, 2, 3, 0, 0.1, 4.6, 5.8, 7.9, 3.1, 3.3, 3.5, 3.6, 3.9);
#@legend_values = (5, 4, 3, 2, 1, 0, -1, -2, -3, -4, -5, -6, -7, -8);
@legend_values = ();
$expected_chart_picture = '
8                                                                       
8                                                                       
7                                               7.9                     
7                                                |                      
6                                                |                      
6                                                |                      
6                                                |                      
5                                           5.8  |                      
5                                            |   |                      
4               4.8                     4.6  |   |                      
4                |                       |   |   |                      
4                |                       |   |   |                      
3            3   |           3           |   |   |  3.1 3.3 3.5 3.6 3.9 
3            |   |           |           |   |   |   |   |   |   |   |  
2       2.4  |   |       2   |           |   |   |   |   |   |   |   |  
2        |   |   |       |   |           |   |   |   |   |   |   |   |  
2        |   |   |       |   |           |   |   |   |   |   |   |   |  
1   1.2  |   |   |  1.7  |   |           |   |   |   |   |   |   |   |  
1    |   |   |   |   |   |   |           |   |   |   |   |   |   |   |  
0    |   |   |   |   |   |   |   0  0.1  |   |   |   |   |   |   |   |  
';
@expected_chart = split "\n", $expected_chart_picture;
shift @expected_chart; # Remove the top empty row.
$chart->{'values'} = \@values;
$chart->{'legend_values'} = \@legend_values;
$chart->{'screen_height'} = 20;               # (height reserved for the graph.)
$chart->{'roof_value'} = 0;                   # (active if != 0), # Arbitrarily squeeze or extend the size (height) of bars (not screen)
$chart->{'bottom_value'} = 0;                 # (below floor, active if != 0), # Not yet implemented.
$chart->{'floor_value'} = 0;                  # (the "floor" of the chart, default: 0)
$chart->{'write_floor'} = 1;                  # (make floor visible)
$chart->{'use_floor'} = 0;                    # (use the floor value)
$chart->{'write_floor_value'} = 1;            # If value == floor_value, then write value (mostly "0").
$chart->{'write_legend'} = 1;                 # (Prepend legend to each row.)
$chart->{'legend_horizontal_width'} = 4;      # width of the space left for legend (left edge of chart)
$chart->{'horizontal_width'} = 4;             # Horizontal width of one bar. This parameter directly influences the width of the screen (i.e. chart).
$chart->{'write_value'} = 1;                  # (YES = 1, NO = 0, default: no; write the value on the end of the bar),
$chart->{'write_always_over_value'} = 0;      # (YES = 1, NO = 0, default: yes; write the value only if it is too high for the graph),
$chart->{'write_always_under_value'} = 0;     # (YES = 1, NO = 0, default: yes; write the value only if it is too low for the graph),
$chart->{'bar_char'} = '|';                   # (default: '|')
$chart->{'floor_char'} = '-';                 # (default '-' )
$chart->{'over_value_char'} = '+';            # (default: '+')
$chart->{'under_value_char'} = '_';           # (default: '-' )
$rval = $chart->chart();
ok($rval >= 1, "$chart_name creation");
@got_chart = @{$chart->{'screen'}};
#diag(Dumper(\@got_chart));
for(my $i = 0; $i < @expected_chart; $i++) {
	is($got_chart[$i], $expected_chart[$i], "$chart_name row $i match");
}



# //TODO
# Not yet implemented.
#$chart_name = "Eighth Chart";
#@values = (3, 4, 5, 4, 3, 5, 7, 11, 14, 8, 1, 6);
#@legend_values = ();
#$expected_chart_picture = '
#11                ||^^      
#10                ||||      
#9                 ||||      
#8                 ||||||    
#7               ||||||||    
#6               ||||||||  ||
#5       ||    ||||||||||  ||
#4     ||||||  ||||||||||  ||
#3   ||||||||||||||||||||__||
#';
#@expected_chart = split "\n", $expected_chart_picture;
#shift @expected_chart; # Remove the top empty row.
#$chart->{'values'} = \@values;
#$chart->{'legend_values'} = \@legend_values;
#$chart->{'screen_height'} = 9;                # (height reserved for the graph.)
#$chart->{'roof_value'} = 11;                  # (active if != 0), # Arbitrarily squeeze or extend the size (height) of bars (not screen)
#$chart->{'bottom_value'} = 3;                 # (below floor, active if != 0), # Not yet implemented.
#$chart->{'floor_value'} = 3;                  # (the "floor" of the chart, default: 0)
#$chart->{'write_floor'} = 0;                  # (make floor visible)
#$chart->{'use_floor'} = 0;                    # (use the floor value)
#$chart->{'write_floor_value'} = 0;            # If value == floor_value, then write value (mostly "0").
#$chart->{'write_legend'} = 1;                 # (Prepend legend to each row.)
#$chart->{'legend_horizontal_width'} = 4;      # width of the space left for legend (left edge of chart)
#$chart->{'horizontal_width'} = 2;             # Horizontal width of one bar. This parameter directly influences the width of the screen (i.e. chart).
#$chart->{'write_value'} = 0;                  # (YES = 1, NO = 0, default: no; write the value on the end of the bar),
#$chart->{'write_always_over_value'} = 1;      # (YES = 1, NO = 0, default: yes; write the value only if it is too high for the graph),
#$chart->{'write_always_under_value'} = 1;     # (YES = 1, NO = 0, default: yes; write the value only if it is too low for the graph),
#$chart->{'bar_char'} = '||';                  # (default: '|')
#$chart->{'floor_char'} = '-';                 # (default '-' )
#$chart->{'over_value_char'} = '^^';            # (default: '+')
#$chart->{'under_value_char'} = '_';           # (default: '-' )
#$rval = $chart->chart();
#ok($rval >= 1, "$chart_name creation");
#@got_chart = @{$chart->{'screen'}};
#diag(Dumper(\@got_chart));
#for(my $i = 0; $i < @expected_chart; $i++) {
#	is($got_chart[$i], $expected_chart[$i], "$chart_name row $i match");
#}



done_testing();

__END__

=encoding utf8

=head1 VERSION

Version 0.001

$Revision$
$Date$
$LastChangedBy$
$HeadURL$


=cut
