# $Id$
$VERSION{''.__FILE__} = '$Revision$';
#
# >>Title::     Calculation Library
#
# >>Copyright::
# Copyright (c) 1996, Tim Hudson (tjh@mincom.com)
# You may distribute under the terms specified in the LICENSE file.
#
# >>History::
# -----------------------------------------------------------------------
# Date      Who     Change
# 19-Feb-97 tjh     worked around a perl4 bug with complex substitution
# ................. expressions with escaped double quotes
# 18-Feb-97 tjh     handle money (i.e. $1,250.75 is okay now) and
# ................. FORMAT("money",EXPR) is supported too
# 17-Feb-97 tjh     FORMAT and PRECISION added along with ROWPRODUCT
# ................. ROWAVERAGE, COLUMNPRODUCT, COLUMNAVERAGE
# 17-Feb-97 tjh     report errors with AppMsg so we get line numbers
# ................. so we can actually debug things without poking into
# ................. the code when things go wrong
# 03-Jan-97 tjh     added recursion support and extra functions
# 03-Jan-97 tjh     expanded prototype into new format for SDF2beta8
# 02-Jan-97 tjh     original coding
# -----------------------------------------------------------------------
# 
# >>Purpose::
# This library provides basically a mini-spreadsheet for using in tables
# inside SDF
#
# >>Description::
# This requires SDF verion 2beta8 or above (which adds in a few new things
# so that we have a nice syntax for calculations)
# 
# This can be made to work in SDF2beta7c but it is worth upgrading to
# a supported release :-)
#
# Calculation support for a table is activated by adding in an attribute
# of calc (which triggers keeping track of the table contents in a cell
# grid for later processing).
# 
# A simple example:
#
# !block comment
# !block table; format="10,20,70"; style="box"
# Count         Price        Total
# 10            5            \[\[=ROWPROD\]\]
# 15            5.23         \[\[=ROWPROD\]\]
# \[\[=COLSUM]]   \[\[=COLSUM\]\]  \[\[=COLSUM\]\]
# !endblock
# !endblock
#
# NB: 
# values are available until the next table is processed so
# you can refer to data inside "normal" paragraphs after the table
# NE:
#
# >>Limitations::
#
# >>Resources::
#
# >>Implementation::
#


# (Yes Ian ... I did mean to add in the stanard SDF-like header stuff
# above so it actually looks more like part of SDF but I've still got
# a lot more documenting to do so that this is generally usable by
# people that don't know how to read perl code :-) --tjh
#
#   - check the value of the cell being used and if it is being used
#     inside a multiplication and is a text value then use 1 and if
#     inside an addition and is a text value then use 0 so that we can
#     use operations over cells with "random" text it them safely without
#     having to think too hard
#   - document how to use this sufficiently so that I don't get asked 
#     questions about it
#   - implement a recursive decent parser so that we don't get confused
#     with really complex things (it works fine for my requirements at the
#     moment so I've not bothered)
#

package SDF_USER;

sub chr {
  local($ascii)=@_;

  return sprintf("%c",$ascii);
}

# ----------------------------------------------------------------------------
# This requires SDF verion 2beta8 or above (which adds in a few new things
# so that we have a nice syntax for calculations)
# 
# This can be made to work in SDF2beta7c but it is worth upgrading to
# a supported release :-)
#
# Calculation support for a table is activated by adding in an attribute
# of calc (which triggers keeping track of the table contents in a cell
# grid for later processing).
# 
# A simple example:
#
# !block table; format="10,20,70"; style="box"
# Count         Price        Total
# 10            5            [[=ROWPROD]]
# 15            5.23         [[=ROWPROD]]
# [[=COLSUM]]   [[=COLSUM]]  [[=COLSUM]]
# !endblock
#
# Note: values are available until the next table is processed so
#       you can refer to data inside "normal" paragraphs after the table
#
# ----------------------------------------------------------------------------



# The following are the target list of things that will be eventually
# implemented (those starting with * have not yet been done):
# (this is modelled off the standard things that I use in Excel)
#   + - * /
#   AVERAGE
#   SUM
#   MIN
#   MAX
#  *ROUND
#   COUNT
#   PRODUCT
#  *SUMPRODUCT
#   ROW         ROW() is current row number
#   COLUMN      COLUMN() is current column number
#  *IF          IF(EXPR,TRUESTMT,FALSESTMT)
#
# Columns are named A-Z ... and rows are numbered sequentially starting
# at 1 from the first non-header row ... 
#
# Cells are labeled [A-Z][1-9]+ (I call these labels cellids)
# 
# Ranges are done via cellid:cellid ... e.g. A1:C2
#
# Example valid things ... that should be handled when I get around
# to doing the general stuff later
# 
# A1+A3-A2*B1
#
# SUM(A1:A10,B1:B10,1,25)
# SUMPRODUCT(A1:B3,D1:E3)
# SUM(A1:B3*D1:E3)
# 
# SDF usage is as follows:
#       [[=EXPRESSION]]
#
# [[=B1+B2+B3]]
# [[=SUM(B1:B3)]]
# [[=SUM(B1:B3,A1:A3)]]
# [[=A1]]
# 
# (it used to be !CALC EXPRESSION which was enhanced to be terser)
#
# Extra non-standard things that I've added that mean you can add
# rows and columns into tables without having to play with the
# calc values which by default require cellids
# (yes I know ... I cannot help myself "extending" things)
#
#   ROWSUM -> sum values of current row
#   COLSUM -> sum values of current column
#   ROWPROD -> multiply values of current row
#   COLPROD -> multiply values of current column
#

# multiplier for specifying precision
# 100 = two decimal places (default)
$_calc_restrict_precision=1;
$calc_precision=2;
$calc_strip_zeros=0;
$_calc_last_strip_zeros=$calc_strip_zeros;
$_calc_default_format='%.2f';

$_calc_default_units="numbers";

$_calc_test=0;

$_calc_debug=0;
$_calc_eval_debug=0;

# data about the current table being processed is held here
@_calc_data=();
$_calc_rows=0;
$_calc_cols=0;

# maximum depth we will recurse ... to stop infinite loops
$_calc_max_recurse=10;

# current depth of recursion
$_calc_cur_recurse=0;

$_calc_last_warning='';		# we only bitch once about each error
$_calc_cur_warning='';		# we only bitch once about each error

$_calc_row_offset=0;

$_calc_last_group=0;
@_calc_group_total='';

# calc_table ... activated during oncell processing to take a copy of
#                the data that is required by the calc function to implement
#                the spreadsheet-style calc stuff
sub calc_table {
  # initialise if we are on the header roo
  if ($row == 0) {
    if ($col == 0) {
      @_calc_data=();
      $_calc_rows=$last_row+1; # IGC to fix so +1 isn't needed 
      $_calc_cols=$last_col;

      if ($_calc_debug) {
        print STDERR "NEWTABLE $_calc_rows,$_calc_cols\n";
      }

      # grab any SDF vars that have been set that control
      # things on a global basis ... we do this at the start
      # of each table so we can change settings if needed
      if (defined $var{"CALC_PRECISION"}) {
        $ret=$var{"CALC_PRECISION"};
        $calc_precision=$ret;
      }
      if (defined $var{"CALC_STRIP_ZEROS"}) {
        $var{"CALC_STRIP_ZEROES"}=$var{"CALC_STRIP_ZEROS"};
      }
      if (defined $var{"CALC_STRIP_ZEROES"}) {
        $ret=$var{"CALC_STRIP_ZEROES"};
        $calc_strip_zeros=$ret;
	$_calc_last_strip_zeros=$calc_strip_zeros;
      }
      if (defined $var{"CALC_UNITS"}) {
        $ret=$var{"CALC_UNITS"};
	if ($ret eq "money") {
	    $_calc_default_units="money";
	    $_calc_last_strip_zeros=$calc_strip_zeros;
	    $calc_strip_zeros=0;
	}
	if ($ret eq "numbers" || $ret eq "digits") {
	    $_calc_default_units="numbers";
	    $calc_strip_zeros=$_calc_last_strip_zeros;
	}
      }
      if (defined $var{"CALC_DEFAULT_FORMAT"}) {
      	$_calc_default_format=$var{"CALC_DEFAULT_FORMAT"};
      }

    }

    $_calc_row_offset=$body_start;
    # we are out by one ...
    if ($body_start>0) {
	$_calc_row_offset--;
    }

    # initialise things that need to be set on a per-table basis
    $_calc_cur_warning='';
    $_calc_last_warning='';
    $_calc_cur_recurse=0;
    $_calc_group_total{"$col"}="";
    $_calc_last_group=0;

    #@_calc_group_total=();

    return;
  }

  #print STDERR "[$row,$col] $row_type \"$cell\"\n";
  if ( ($col == 0) && ($row_type eq "Group")) {
      #print STDERR "GROUP RANGE: " . &_calc_var_current_cell() . " " . &_calc_var_group_col_range() . "\n";
      $_calc_last_group=$row;
  }

  # now hack things into submission that need to know about the
  # current row and col as this is the only chance we have of
  # getting that right
  #
  # we have to catch two forms [[=EXPR]] and [[&Calc("EXPR")]] which
  # is why we have the dogs breakfast below 
  #

  $cell =~ s/\[\[([=+]|&Calc)([^\]]*)ROWPRODUCT([^\]]*)]]/"[[$1$2PRODUCT(" . &_calc_var_row_range() . ")$3]]"/ge;
  $cell =~ s/\[\[([=+]|&Calc)([^\]]*)COLPRODUCT([^\]]*)]]/"[[$1$2PRODUCT(" . &_calc_var_col_range() . ")$3]]"/ge;
  $cell =~ s/\[\[([=+]|&Calc)([^\]]*)ROWAVERAGE([^\]]*)]]/"[[$1$2AVERAGE(" . &_calc_var_row_range() . ")$3]]"/ge;
  $cell =~ s/\[\[([=+]|&Calc)([^\]]*)COLAVERAGE([^\]]*)]]/"[[$1$2AVERAGE(" . &_calc_var_col_range() . ")$3]]"/ge;
  $cell =~ s/\[\[([=+]|&Calc)([^\]]*)COLUMNAVERAGE([^\]]*)]]/"[[$1$2AVERAGE(" . &_calc_var_col_range() . ")$3]]"/ge;
  $cell =~ s/\[\[([=+]|&Calc)([^\]]*)COLUMNSUM([^\]]*)]]/"[[$1$2SUM(" . &_calc_var_col_range() . ")$3]]"/ge;
  $cell =~ s/\[\[([=+]|&Calc)([^\]]*)COLUMNPRODUCT([^\]]*)]]/"[[$1$2PRODUCT(" . &_calc_var_col_range() . ")$3]]"/ge;

  $cell =~ s/\[\[([=+]|&Calc)([^\]]*)ROWSUM([^\]]*)]]/"[[$1$2SUM(" . &_calc_var_row_range() . ")$3]]"/ge;
  $cell =~ s/\[\[([=+]|&Calc)([^\]]*)COLSUM([^\]]*)]]/"[[$1$2SUM(" . &_calc_var_col_range() . ")$3]]"/ge;
  $cell =~ s/\[\[([=+]|&Calc)([^\]]*)ROWPROD([^\]]*)]]/"[[$1$2PRODUCT(" . &_calc_var_row_range() . ")$3]]"/ge;
  $cell =~ s/\[\[([=+]|&Calc)([^\]]*)COLPROD([^\]]*)]]/"[[$1$2PRODUCT(" . &_calc_var_col_range() . ")$3]]"/ge;
  $cell =~ s/\[\[([=+]|&Calc)([^\]]*)ROWAVG([^\]]*)]]/"[[$1$2AVERAGE(" . &_calc_var_row_range() . ")$3]]"/ge;
  $cell =~ s/\[\[([=+]|&Calc)([^\]]*)COLAVG([^\]]*)]]/"[[$1$2AVERAGE(" . &_calc_var_col_range() . ")$3]]"/ge;

  # group things ...
  if ( $cell =~ m/\[\[([=+]|&Calc)([^\]]*)GROUPSUBTOTAL([^\]]*)]]/ ) {
      if ($_calc_group_total{"$col"}) {
        $_calc_group_total{"$col"} .= "+";
      }
      $_calc_group_total{"$col"} .= &_calc_var_current_cell();

      #print STDERR "GROUPTOTAL $col = " . $_calc_group_total{"$col"} . "\n";

      $cell =~ s/\[\[([=+]|&Calc)([^\]]*)GROUPSUBTOTAL([^\]]*)]]/"[[$1$2SUM(" . &_calc_var_group_col_range() . ")$3]]"/ge;
  }
  $cell =~ s/\[\[([=+]|&Calc)([^\]]*)GROUPTOTAL([^\]]*)]]/"[[$1$2" . $_calc_group_total{"$col"} . "$3]]"/ge;

  # take reference to cell data which will remain valid 
  # until the next table overwrites it
  $_calc_data{"$row","$col"}="$cell";

  if ($_calc_debug) {
    print STDERR "DATA($row,$col)=" . $_calc_data{"$row","$col"} . " ($cell)\n";
  }

  return;
}

sub _calc_min {
  local($args)=@_;
  local($ret,$x,@words);

  (@words)=split(/,/,$args);
  $ret=$words[0];

  for($x=0;$x<=$#words;$x++) {
    $ret=$words[$x] if ($words[$x]<$ret);
  }
  return $ret;
}

sub _calc_max {
  local($args)=@_;
  local($ret,$x,@words);

  (@words)=split(/,/,$args);
  $ret=$words[0];

  for($x=0;$x<=$#words;$x++) {
    $ret=$words[$x] if ($words[$x]>$ret);
  }
  return $ret;
}

sub _calc_format {
  local($fmt,$args)=@_;
  local($prec);

  # pull off the outer quotes which will have
  # come throught the single quoting we use to 
  # survive the eval
  $fmt =~ s/^\"(.*)"$/$1/g;

  # we could have &_calc_safe_strings here for recursive things
  # that we have to eval too before going on as we have 
  # got in the way of the normal eval by stealing its args
  #$args = eval &Calc("$args");
  if ($_calc_eval_debug) {
    print STDERR "calc EVAL3: &Calc(\"$args\")\n";
  }
  $args = eval &Calc("$args");

  if ($_calc_debug) {
    print STDERR "_calc_format IN \"$fmt\",\"$args\"\n";
  }

  # shortcut ... will round up to the nearest whole dollar
  if ( $fmt eq "dollars" ) {
    $fmt="money";
    $prec="%.0f";
  } else {
    $prec="%.2f";
  }

  if ( ($fmt eq "\$") || ($fmt eq "money") || ($fmt eq "currency") ) {
      if ($_calc_debug) {
	  print STDERR "_calc_format MONEY\n";
      }
      # money is two decimal places always ... without zeros removed
      $args=sprintf($prec,"$args");
      $ret = &_calc_format_money("$args");
      $ret =~ s/\$/_DOLLAR_/g;
      $ret =~ s/,/_COMMA_/g;
      $ret =~ s/\./_DOT_/g;
      if ($_calc_debug) {
	  print STDERR "_calc_format MONEY OUT \"$ret\"\n";
      }
  } else {
      $ret=sprintf("$fmt",$args);
  }

  if ($_calc_debug) {
    print STDERR "_calc_format OUT \"$ret\"\n";
  }

  return "$ret";
}

# simple operator conversion ... with a few funny things that just
# get ranges to become parameter lists to function calls
%_calc_ops=( "SUM", "+", "PRODUCT", "*", "COUNT", "," ,"MIN", ",", 
             "MAX", ",", "CALL", ",");

sub _calc_expand_range {
  local($op,$start_range,$end_range)=@_;
  local($result);
  
  if ($_calc_debug) {
    print STDERR "calc_expand_range: \"OP=$op START=$start_range END=$end_range\"\n";
  }

  $scell=substr($start_range,0,1);
  $srow=substr($start_range,1);
  $ecell=substr($end_range,0,1);
  $erow=substr($end_range,1);

  $result='';
  for($x=ord($scell);$x<=ord($ecell);$x++) {
    for($y=$srow;$y<=$erow;$y++) {
      if ($result) {
        if ($_calc_ops{"$op"}) {
          $result .= $_calc_ops{"$op"} 
        } else {
	  &'AppMsg('error', "unknown operator '$op'");
          #print STDERR "calc_expand_range:Unknown operator $op\n";
          $result .= ",";
        }
      }
      $result .= &chr($x) . "$y";
    }
  }

  if ($_calc_debug) {
    print STDERR "calc_expand_range: RESULT=$result\n";
  }

  return $result;

}

# calc_var_row_range - range for entire row 
sub _calc_var_row_range {
  local($ret,$x,$y);

  $x = &chr(ord("A")+0);
  $y = &chr(ord("A")+$col-1);
  $ret = "$x" . "$row:" . "$y" . "$row";

  return $ret;
}

# calc_var_group_row_range - range for entire group column
sub _calc_var_group_col_range {
  local($ret,$x,$y,$z);

  $x = &chr(ord("A")+$col); 
  $y = $row-1;
  $z = $_calc_last_group;
  $ret = "$x" . "$z:" . "$x" . "$y";

  return $ret;
}

# calc_var_col_range - range for entire column
sub _calc_var_col_range {
  local($ret,$x,$y);

  $x = &chr(ord("A")+$col); 
  $y = $row-1;
  $ret = "$x" . "1:" . "$x" . "$y";

  return $ret;
}

# calc_var_col_range - range for entire column
sub _calc_var_current_cell {
  local($ret,$x,$y);

  $x = &chr(ord("A")+$col); 
  $y = $row;
  $ret = "$x" . "$y";

  return $ret;
}

sub _calc_safe_string {
  local($var,$val,$op)=@_;

  if ($_calc_debug) {
      print STDERR "SAFE_STRING IN $var,$val\n";
  }

  # remove financial tokens ... $ and comma
  $val =~ s/\$([0-9,\.]+)/&_calc_unformat_money("$1")/ge;

  # return straight away if no op defined
  if ($op eq "" ) {
    if ($_calc_debug) {
	print STDERR "SAFE_STRING OUT1 $val\n";
    }
    return "$val";
  }

  # ignore things that are references to other bits
  # as we only want *plain* strings to be effected
  if ($val =~ m|^[&\[]| ) {
    if ($_calc_debug) {
	print STDERR "SAFE_STRING OUT2 $val\n";
    }
    return "$val";
  }

  # if it is a string then we handle it differently if we
  # are in the process of doing a multiply as we don't
  # want messy things just to skip string values in a 
  # table
  if ( $val =~ m|[^0-9\. ]+| ) {
      if ($op eq "PRODUCT") {
	  if ($_calc_debug) {
	      print STDERR "STRING $var=>$val REWRITTEN to 1\n";
	  }
	  $val = "1";
      } else {
	if ($_calc_debug) {
	    print STDERR "STRING $var=>$val\n";
	}
      }
  }
  if ($_calc_debug) {
      print STDERR "SAFE_STRING OUT3 $val\n";
  }
  return "$val";
}

sub _calc_unformat_money {
  local($str)=@_;
  local($ret);

  $ret=$str;

  # remove commas
  $ret =~ s/,//g;

  if ($_calc_debug) {
      print STDERR "unformat_money($str)=$ret " . "formatted = " . &_calc_format_money($ret) . "\n";
  }

  return $ret;
}

sub _calc_format_money {
  local($str)=@_;
  local($ret,$body);
  local($i,$len);

  $ret=$str;

  # drop off trailing decimal stuff until later
  $rest='';

  # we do it this way as it works ... 
  $len=length($ret);
  for($i=0;$i<=$len;$i++) {
    if (substr($ret,$len-$i,1) eq ".") {
      $rest=substr($ret,$len-$i);
      $ret=substr($ret,0,$len-$i);
      break;
    }
  }

  # now put in the commas in the right place ... there
  # is probably a nice routine somewhere that already does
  # this but I don't know it offhand
  $len=length($ret);
  $body='';
  for($i=0;$i<=$len;$i++) {
    $body=substr($ret,$len-$i,1) . "$body";
    if ($i != $len) {
	$body = "," . "$body" if ( (($i % 3) == 0) && ($i != 0));
    }
  }

  $ret = "\$" . "$body$rest";

  if ($_calc_debug) {
      print STDERR "format_money($str)=$ret body=$body rest=$rest\n";
  }

  return "$ret";
}


# calc_var_name - given a cell ID return the variable name that holds
#                 the value for that cell
sub _calc_var_name {
  local($cellid,$op)=@_;
  local($let,$num,$ret,$x,$y,$val);

  $let=substr($cellid,0,1);
  $num=substr($cellid,1);

  # offset numbers to skip headers ... 
  $num += $_calc_row_offset;

  # we have to do things in two parts to keep perl happy 
  $x = $num;
  $y = (ord("$let")-ord("A"));
  $ret = "&_calc_safe_string(\'DATA[$x,$y]\',\$_calc_data\{$x,$y\},$op)";

  # short circuit out of bound lookups ... otherwise we
  # often end up recursing on ourself ...
  if ($y >= $_calc_rows) {
    return "";
  }

  ## remove financial tokens ... $ and comma
  #$val =~ s/\$([0-9,.]*)/&_calc_unformat_money($1)/ge;

  if ($_calc_eval_debug) {
    print STDERR "calc EVAL4: $ret\n";
  }
  $val=eval "$ret";

  if ($_calc_debug) {
    print STDERR "calc_var_name($cellid\[$let,$num\])=$ret : x=$x y=$y val=$val\n";
  }

  # match standard SDF expressions for string lookups
  if ( $val =~ m/\[\[([^=+&][^\]]*)\]\]/ ) {
    $val=$1;
    $ret=&Var("$val");
    ##print STDERR "CALC SDF EXPR \"$val\"->\"$ret\"" . $var{"$val"} . "\n";
    return &_calc_safe_string($val,$ret,$op);
  }


  # check to see if the variable points to a cell that contains a 
  # formula ... if so then we need to evaluate that now ... which is
  # fine as long as some smart person doesn't setup a recursive
  # requirement between cells
  if (($val =~ m/\[\[[=+]([^\]]*)\]\]/) || ($val =~ m/\[\[&Calc([^\]]*)\]\]/)) {
      if ($_calc_debug) {
        print STDERR "CALC recursion required on $1\n";
      }

      if ( $_calc_cur_recurse == 0) {
      	$_calc_cur_warning = "$1";
      }

      $_calc_cur_recurse++;

      if ($_calc_cur_recurse > $_calc_max_recurse) {
	if ("$_calc_last_warning" ne "$_calc_cur_warning") {
	    &'AppMsg('warning', "CALC recursion limit reached '$_calc_cur_warning'");
	    $_calc_last_warning="$_calc_cur_warning";
	}
        $ret="CALCERROR";
      } else {
	if ($_calc_debug) {
	    print STDERR "RECURSE START ON $1\n";
	}
        $ret = &Calc($1);
	if ($_calc_debug) {
	    print STDERR "RECURSE FINISH ON $1 => $ret\n";
	}
      }

      $_calc_cur_recurse--;

      if ($_calc_debug) {
        print STDERR "calc_var_name($cellid\[$let,$num\])=$ret (recursion)\n";
      }
  }

  return &_calc_safe_string($val,$ret,$op);
}

sub _head {
  local($arg)=@_;

  return "\"&_calc_format(\'$1\',\"";
}

sub _tail {
  local($arg)=@_;

  return "\")\"";
}

sub _calc_expr {
  local($op,$expr)=@_;
  local($_);
  local($have_format)=0;
  local($in_expr);

  if ($_calc_debug) {
    print STDERR "calc_expr: \"OP=$op EXPR=$expr\"\n";
  }

  $in_expr="$expr";

  # convert some of the operations into expressions involving
  # other operations ... which makes things easier to implement
  $expr =~ s/AVERAGE\((.*)\)/"(SUM($1)\/COUNT($1))"/g;
  $expr =~ s/MIN\((.*)\)/"&_calc_min(\"$1\")"/g;
  $expr =~ s/MAX\((.*)\)/"&_calc_max(\"$1\")"/g;

  print STDERR "calc_expr ALIVE1 expr=\"$expr\"\n" if ($_calc_debug);

  if ( $expr =~ m|FORMAT\((.*)\)| ) {
      #$expr =~ s/FORMAT\(([^,]*),(.*)\)/"\"&_calc_format(\'$1\',\"" . &Calc("$2") . "\")\""/ge;
      $expr =~ s/FORMAT\(([^,]*),(.*)\)/&_head($1) . &Calc("$2") . &_tail()/ge;
      $have_format=1;
  }
  if ( $expr =~ m|PRECISION\((.*)\)| ) {
      #$expr =~ s/PRECISION\(([^,]*),(.*)\)/"\"&_calc_format(\'\"%.$1f\"\',\"" . &Calc($2) . "\")\""/ge;
      $expr =~ s/PRECISION\(([^,]*),(.*)\)/&_head("%.$1f") . &Calc($2) . &_tail()/ge;
      $have_format=1;
  }

  print STDERR "calc_expr ALIVE2 expr=\"$expr\"\n" if ($_calc_debug);

  # if expression contains non-matching brackets we bail now 
  # as it must be something that has slipped through that has
  # been expanded and then partially matched ... we really should
  # have a recursive decent parser here but I cannot be bothered
  # to do that as this does a good enough job as is 
  $_ = "$expr";
  if ( m|^[^\(\)]*\)| ) {
    if ($_calc_debug) {
      print STDERR "calc_expr: BAILING ON \"$expr\"\n";
    }
    return "$expr";
  }

  print STDERR "calc_expr ALIVE3 expr=\"$expr\"\n" if ($_calc_debug);

  # handle subroutine calls ... which we escape into
  # the form CALL &sub#<args#>" which is undone later
  $expr =~ s/(&[a-z_]*)\(([^\(\)]*)\)/"(" . &_calc_expr("CALL","$1#<$2>#") . ")"/ge;
  $expr =~ s/(&[a-z_]*)\((.*)\)/"(" . &_calc_expr("CALL","$1#<$2>#") . ")"/ge;

  print STDERR "calc_expr ALIVE4 expr=\"$expr\"\n" if ($_calc_debug);

  # handle any nested operations first ...
  #$expr =~ m/([A-Z]*)\(([^\(\)]*)\)/;
  #print STDERR "*****EXPR $in_expr => $expr inner = \"$1\",\"$2\"\n";

  #$expr =~ s/([A-Z]*)\(([^\(\)]*)\)(\)|$)/"(" . &_calc_expr($1,$2) . ")"/ge;
  $expr =~ s/([A-Z]*)\(([^\(\)]*)\)/"(" . &_calc_expr($1,$2) . ")"/ge;

  # handle other ops now ... having gotten rid of series
  $expr =~ s/([A-Z]*)\((.*)\)/"(" . &_calc_expr($1,$2) . ")"/ge;

  # expand ranges into full variable requests with expanded ops
  $expr =~ s/([A-Z][0-9]+):([A-Z][0-9]+)/&_calc_expand_range($op,$1,$2)/ge;

  print STDERR "calc_expr ALIVE5 expr=\"$expr\"\n" if ($_calc_debug);

  # now handle individual expressions 
  if ( $op eq "COUNT" ) {
    @words = split(/,/,$expr);
    $expr = $#words+1;
  } elsif ($_calc_ops{"$op"}) {
    if ($_calc_ops{"$op"} eq "*" ) {
	$expr =~ s/,/$_calc_ops{"$op"}/g;
    } else {
	$expr =~ s/,/$_calc_ops{"$op"}/g;
    }
  } else {
  }

  # now convert the cell references into perl variable names
  $expr =~ s/([A-Z][0-9]+)/&_calc_var_name($1,$op)/ge;

  # convert any escaped subroutine calls back to the real thing
  $expr =~ s/(\&[a-zA-Z_]*)#<([^>]*)>#/$1($2)/g;

  # undo any mucky things we have stuffed up and left double 
  # brackets ... ikcy!
  $expr =~ s/\)\)([+*-\/])\(/)$1(/g;

  $pre_expr = "$expr";
  # fix up quote things
  $expr =~ s/^"([^"]*)"$/$1/;
  $expr =~ s/^"([^"]*)$/$1/;
  $expr =~ s/([^"]*)"$/$1/;

  if ($_calc_eval_debug) {
    print STDERR "calc EVAL1: $pre_expr --> $expr\n";
  }

  # and finally evaluate the expression using perl logic
  $ret = eval "$expr";

  # second eval removes any rubbish outer brackets ... otherwise
  # we get tangled on them later :-(
  if ($_calc_eval_debug) {
    print STDERR "calc EVAL2: $ret\n";
  }
  $ret = eval "$ret";

  # then trim to two decimal places ... I don't care for more
  # than that by default in the result thought I'm sure that will
  # change in future
  if (!$have_format) {
    if ($_calc_restrict_precision) {
      if ($_calc_debug) {
	print STDERR "ret $ret => ";
      }
      if ($calc_precision) {
	  $in=$ret;
	  $ret =~ s/(\d*\.\d*)/sprintf("%.".$calc_precision."f",$1)/ge;
	  $ret =~ s/(-\d*\.\d*)/sprintf("%.".$calc_precision."f",$1)/ge;
	  $mid=$ret;
	  # remove trailing zeros ... othewise things look really icky
	  if ($calc_strip_zeros && !($ret =~ m|\$|) ) {
	      $ret =~ s/(\.[1-9]*)(0+\s*)/$1/g;
	  }
	  if ($in!=$ret) {
	      if ($_calc_debug) {
		  print STDERR "PREC: $in->$mid->$ret\n";
	      }
	  }
      }
      if ($_calc_debug) {
	print STDERR "$ret\n";
      }
    }
  }

  # strip any brackets that are left as a side effect of having
  # done other calculations to get the result that added in
  # backets that eval doesn't seem to want to strip off
  $ret =~ s/^\((.*)\)$/$1/;

  return "$ret";
}

sub Calc {
  local($in_expr)=@_;
  local($expr,$result);

  $expr=$in_expr;

  # handle all the control setting stuff ... 
  $cell=$expr;
  if ( $cell =~ m/UNITS=(.*)/ ) {
        $cell = "MONEY" if ($1 eq "money");
        $cell = "NUMBERS" if ($1 eq "numbers");
  }
  if ( $cell eq "MONEY" ) {
	$_calc_default_units="money";
	$_calc_last_strip_zeros=$calc_strip_zeros;
	$calc_strip_zeros=0;
  	$cell = "";
  }
  if ( $cell eq "NUMBERS" ) {
	$_calc_default_units="numbers";
	$calc_strip_zeros=$_calc_last_strip_zeros;
  	$cell = "";
  }
  if ( $cell eq "DEBUG" ) {
	$_calc_debug=1;
	$cell = "";
  }
  if ( $cell eq "NOSTRIPZEROS" || $cell eq "NOSTRIPZEROES" ) {
	$calc_strip_zeros=0;
	$cell = "";
  }
  if ( $cell eq "STRIPZEROS" || $cell eq "STRIPZEROES" ) {
	$calc_strip_zeros=1;
	$cell = "";
  }
  if ( $cell =~ m/PRECISION=(\d+)/ ) {
	$calc_precision=$1;
  	$cell = "";
  }

  # quick exit!
  if ($cell eq "") {
        return "";
  }

  if ($_calc_debug) {
    print STDERR "calc: IN \"$expr\"\n";
  }

  $result=&_calc_expr("","$expr");

  # undo our escaping ... only at the top level 
  $result =~ s/_DOLLAR_/\$/g;
  $result =~ s/_COMMA_/,/g;
  $result =~ s/_DOT_/./g;

  # handle overall formatting options
  if ($_calc_default_format) {
      $result=sprintf("$_calc_default_format","$result");
  }

  # handle defaulting to money formatted output
  if ($_calc_default_units eq "money") {
      $result = &_calc_format_money("$result");
  }

  if ($_calc_debug) {
    print STDERR "calc: \"$expr\" => $result\n";
  }

  return $result;
}

# testing engine ... we really need some test case data here
if ($_calc_test) {
  while(<STDIN>) {
          chop;
          print &Calc("$_");
  }
}

1;

