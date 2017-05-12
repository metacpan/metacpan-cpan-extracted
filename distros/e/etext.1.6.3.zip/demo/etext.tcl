#!../wish
# $Id: etext.tcl,v 1.3 1996/01/14 23:13:34 ilya Exp $

set prefix "Control-Meta-"
if [info exists env(kprefix)] {set prefix $env(kprefix)}

proc putss args {
  puts $args
}
proc stdLayout args {
  puts $args
  set y 0
  set w 0
  set ww 0
  set h 0
  set b 0
  foreach row [lrange $args 2 end] {
    if {$w < [lindex $row 2]} {set w [lindex $row 2]}
    if {$ww < [lindex $row 3]} {set ww [lindex $row 3]}
    set h [expr $h+[lindex $row 4]]
    set b [expr $b+[lindex $row 5]]
  }
  set b [expr ($h + $b/([llength $args] - 2))/2 ]
  set out [list [list -1 0 $y $w $ww $h $b]]
  foreach row [lrange $args 2 end] {
    set row [lrange $row 0 5]
    lappend out [linsert [lreplace $row 3 3 $ww] 1 0]
  }
  puts $out
  puts -nonewline X
  return $out
}

# We put super- and sub-scripts satisfying following relations:
#    The bottom of super is not lower that half of the standard ascent;
#    The top of sub is not higher than half of the standard ascent;
#    The baseline of sub is not higher than the standard descent.
#
# In fact we need to take baseline of topmost line in the above
# description. This is not available with the standard...

set stdAscent 15
set stdAscentHalf [expr int($stdAscent/2)]
set stdDescent 5

proc layoutSubSuper {block x super sub} {
  #puts [list $block $x $super $sub]
  global stdAscentHalf stdDescent
  set super [lrange $super 0 5]
  set sub [lrange $sub 0 5]
  set w [lindex $super 2]
  if {$w < [lindex $sub 2]} {set w [lindex $sub 2]}
  set ww [lindex $super 3]
  if {$ww < [lindex $sub 3]} {set ww [lindex $sub 3]}
  set b [expr $stdAscentHalf + [lindex $super 4]]
  set d 0
  set y1 0
  if [lindex $sub 4] {
    # There is a subscript
    set d [expr $stdDescent + [lindex $sub 4] - [lindex $sub 5]]
    if {$d < [expr [lindex $sub 4] - $stdAscentHalf ]} {
      set d [expr [lindex $sub 4] - $stdAscentHalf ]
      set y1 [lindex $super 4]
    } else {
      set y1 [expr $b + $stdAscentHalf - [lindex $sub 5]]
    }
  }
  set h [expr $b + $d]
  set out [list \
	   [list -1 0 0 $w $ww $h $b] \
	   [linsert [lreplace $super 3 3 $ww] 1 0] \
	   [linsert [lreplace [lreplace $sub 3 3 $ww] 1 1 $y1] 1 0] \
	  ]
  #puts $out
  #puts -nonewline X
  return $out
}

set fractionWidth 2
set fractionWidthHalf [expr ($fractionWidth+1)/2]

proc layoutFraction {block x super sub} {
  #puts [list $block $x $super $sub]
  global stdAscentHalf fractionWidth fractionWidthHalf blackLine
  set super [lrange $super 0 5]
  set sub [lrange $sub 0 5]
  set w [lindex $super 2]
  if {$w < [lindex $sub 2]} {set w [lindex $sub 2]}
  set w [expr $w + 2]
  #set ww [lindex $super 3]
  #if {$ww < [lindex $sub 3]} {set ww [lindex $sub 3]}
  set x0 [expr ($w - [lindex $super 2])/2]
  set x1 [expr ($w - [lindex $sub 2])/2]
  set b [expr $stdAscentHalf + [lindex $super 4] + $fractionWidthHalf]
  set y0 [lindex $super 4]
  set y1 [expr [lindex $super 4] + $fractionWidth]
  set h [expr [lindex $super 4] + $fractionWidth + [lindex $sub 4]]
  if {$h < $b} {set h $b}
  set out [list \
	   [list -1 0 0 $w $w $h $b] \
	   [linsert [lreplace $super 3 3 [lindex $super 2]] 1 $x0] \
	   [linsert \
		[lreplace [lreplace $sub 3 3 [lindex $sub 2]] 1 1 $y1] 1 $x1] \
	   [list $blackLine 0 $y0 $w $w 2 1] \
	  ]
  #puts $out
  #puts -nonewline X
  return $out
}

#set eqWidth 300
set eqGap 15

proc layoutEquation {block x super sub} {
  #puts [list $block $x $super $sub]
  global eqGap
  set eqw [winfo width [lindex $block 1]]
  set super [lrange $super 0 5]
  set sub [lrange $sub 0 5]
  set w [lindex $super 2]
  if {$w < [lindex $sub 2]} {set w [lindex $sub 2]}
  set tw [expr [lindex $super 2] + [lindex $sub 2] + $eqGap]
  if {$eqw < $tw} {set eqw $tw}
  set gap [expr [lindex $super 2] + $eqGap + int(($eqw-$tw)/2)]
  set h [lindex $super 4]
  if {$h < [lindex $sub 4]} {set h [lindex $sub 4]}
  set y0 0
  if {$h > [lindex $super 4]} {set y0 [expr int(($h - [lindex $super 4])/2)]}
  set y1 0
  set b [expr [lindex $sub 5] + $y1]
  return [list \
	      [list -1 0 0 $eqw $eqw $h $b] \
	      [lreplace $super 1 1 0 $y0] \
	      [lreplace $sub   1 1 $gap $y1] \
	     ]
}

proc layoutRadical {block x row} {
  #puts [list $block $x $super $sub]
  global stdAscentHalf blackLine radicalCheck
  set row [lrange $row 0 5]
  set h [lindex $row 4]
  set vlx 9
  set hlw 2
  set vlw 1
  set addxoff 1
  set rcYoff 1
  set xoff [expr $vlx + $hlw + $addxoff]
  set checkH 20
  set checkB 15
  set addHeight 3
  if {$h < $checkB} {set addHeight [expr $checkB - $h + $addHeight - 1]}
  set vlH 0
  set vrow ""
  if {$h > $checkB} {
    set vlH [expr $h - $checkB]
    set vrow [list $blackLine $vlx 0 $vlw $vlw $vlH 0]
  }
  set b [expr [lindex $row 5] + $addHeight]
  set h [expr $h + $addHeight]
  set wtot [expr [lindex $row 2] + $xoff]
  set hll [expr [lindex $row 2] + $vlw + $addxoff]
  set row [lreplace $row 1 1 $xoff $addHeight]
  set hrow [list $blackLine $vlx 0 $hll $hll $hlw $hlw]
  set totblock [list -1 0 0 $wtot $wtot $h $b]
  set check [list $radicalCheck 0 [expr $vlH + $rcYoff] 0 0 $checkH $checkB]
  #puts [list $totblock $row $hrow $vrow $check]
  if {$vrow==""} {
    return [list $totblock $row $hrow $check]
  } {
    return [list $totblock $row $hrow $vrow $check]
  }
}

proc layoutTab {min mult block x} {
  global backgrId1 backgrId2
  #puts [list $block $x $super $sub]
  set w [expr $min + $mult - ($x + $min - 1) % $mult - 1]
  set totblock [list $backgrId2 0 0 $w $w 5 3]
  #puts $w
  return [list $totblock $totblock]
}

proc insBlock {txt {block std} {string ""}} {
  set sel [$txt tag nextrange sel 0.0]
  if {$sel == ""} {
    $txt block insert $block insert
    $txt mark set insert insert-1c
    if {$string != ""} {$txt insert insert $string}
  } else {
    $txt block insert $block [lindex $sel 0] [lindex $sel 1]
  }
}

proc insTag {txt tag {on 1}} {
  set sel [$txt tag nextrange sel 0.0]
  if {$sel == ""} {return} {
    if $on {
      $txt tag add $tag [lindex $sel 0] [lindex $sel 1]
    } else {
      $txt tag delete $tag [lindex $sel 0] [lindex $sel 1]
    }
  }
}

proc sample1 {txt {str aaaaa\nbbbbb\nccccc\nddddd\neeeee}} {
  set s [string length $str]
  $txt insert insert $str
  $txt block insert std "insert -$s  c" insert
  # Block of size 31 by default
}
proc sample2 txt {
  sample1 $txt iiiii\njjjjj\nkkkkk\nlllll\nmmmmm
  # After second "k"
  $txt mark set insert "insert - 22c"
  sample1 $txt
  # Size 38 by default
}
proc sample3 txt {
  set i [$txt index insert]
  $txt insert insert sssttt
  $txt mark set insert $i+3c
  sample1 $txt uuuuu\nvvvvv\nwwwww\nxxxxx\nyyyyy\nzzzzz
  # After second "v"
  $txt mark set insert $i+12c
  # After second "x"
  $txt mark set another $i+30c
  sample2 $txt
  $txt mark set insert another
  sample2 $txt
}

proc sample4 txt {
  set i [$txt index insert]
  $txt insert insert aabbb\ncc\ndeee
  $txt block insert superSub $i+2c $i+10c
  $txt block split $i+5c 1
}

proc sample5 {{txt .t}} {
  set i [$txt index insert]
  $txt insert insert aabb\nbcceee
  $txt block insert superSub $i+2c $i+8c
  $txt block split $i+7c 1
  $txt tag add small $i+8c $i+11c
}

proc bbox {text start end} {
  set start [$text index $start]
  while {[$text compare $start < $end]} {
    puts "$start [$text bbox $start]"
    set start [$text index $start+1c]
  }
}

catch {text .t}
catch {pack .t -fill both -expand yes}
.t debug on
.t config -insertbac Gray -insertbo 2 -insertw 6 -hei 25 -wid 35
catch {.t config -font 10x20}
.t tag config red -foreground red
# blue since green is urgly ;-)
.t tag config blue -background lightblue -bord 2 -reli raised
catch {.t tag config small -font 6x10}
.t tag config black -background black
catch {.t tag config symbol -font -*-symbol-*-*-*-*-20-*-*-*-*-*-*-*}
#.t insert insert as\nbs\nkdjfdfaasdfja\nkj
.t block configure std
.t block configure superSub -layoutcmd layoutSubSuper -layoutdepth 1 \
    -layoutwidths 2
.t block configure Fraction -layoutcmd layoutFraction -layoutdepth 1 \
    -layoutwidths 2
.t block configure Equation -layoutcmd layoutEquation -layoutdepth 1 \
    -layoutwidths 2
.t block configure Radical -layoutcmd layoutRadical -layoutdepth 1 \
    -layoutwidths 1
.t block configure Tab -empty on -layoutcmd {layoutTab 5 35}
bind .t <F1>  {sample1  %W}
bind .t <F2>  {sample2  %W}
bind .t <F3>  {sample3  %W}
bind .t <F4>  {sample4  %W}
bind .t <F5>  {sample5  %W}
bind .t <F10> {insBlock %W}
bind .t <${prefix}r> {insTag %W red; break}
bind .t <${prefix}b> {insTag %W blue; break}
bind .t <${prefix}s> {insTag %W small; break}
bind .t <${prefix}Shift-r> {insTag %W red 0; break}
bind .t <${prefix}Shift-b> {insTag %W blue 0; break}
bind .t <${prefix}Shift-s> {insTag %W small 0; break}
bind .t <${prefix}Return> {%W block split insert 1; break}
bind .t <${prefix}Return> {%W block split insert 2; break}
bind .t <${prefix}BackSpace> {%W block trim insert; break}
bind .t <${prefix}t> {%W block insert Tab insert; break}
bind .t <${prefix}l> {puts [%W block list 0.0 end]; break}
bind .t <${prefix}f> {
  insBlock %W Fraction
  break
}
bind .t <${prefix}c> {
  insBlock %W superSub
  break
}
bind .t <${prefix}d> {
  insBlock %W Radical
  break
}
bind .t <${prefix}e> {
  insBlock %W Equation ()\n
  break
}
set script [info script]

bind .t <${prefix}n> {source $script; break}
bind .t <${prefix}q> {exit}
bindtags .t {.t Text . all}

set script [info script]

.t block deletelines
.t insert 1.0 v\n {blue red}
set fractionLine [.t block addline 1.0]
.t delete 1.0 1.0+2c
.t insert 1.0 \326\n {symbol}
set radicalCheck [.t block addline 1.0]
.t delete 1.0 1.0+2c
.t insert 1.0 \n {black}
set blackLine [.t block addline 1.0]
.t delete 1.0 1.0+1c
  .t tag configure backgr1 -background blue -border 2 -relief raised
  .t tag configure backgr2 -background gray90 -border 2 -relief raised
  .t insert 1.0 \n backgr1
  set backgrId1 [.t block addline 1.0]
  .t delete 1.0 1.0+1c
  .t insert 1.0 \n backgr2
  set backgrId2 [.t block addline 1.0]
  .t delete 1.0 1.0+1c
  .t block config myBlock -layoutdepth 1 \
	-layoutwidths 1 -layoutcmd myLayoutCmd
  proc myLayoutCmd {block x row} {
    global backgrId1 backgrId2
    set c [lindex $row 0]
    set w [lindex $row 3]
    set h [lindex $row 4]
    set b [lindex $row 5]
    set tw [expr $w+10]
    set tw2 [expr $w+14]
    set tw1 [expr $w+20]
    set row [list $c 5 5 $w $tw $h $b]
    set addrow1 [list $backgrId1 0 0 $tw1 $tw1 [expr $h+10] [expr $b+5]]
    set addrow2 [list $backgrId2 3 3 $tw2 $tw2 [expr $h+4] [expr $b+2]]
    return [list $addrow1 $row $addrow1 $addrow2]
  }
  proc myLayoutCmd {block x row} {
    global backgrId1 backgrId2
    set c [lindex $row 0]
    set w [lindex $row 2]
    set tw [lindex $row 3]
    set h [lindex $row 4]
    set b [lindex $row 5]
    set tw [expr $tw+10]
    set tw2 [expr $tw+4]
    set tw1 [expr $tw+10]
    set h2 [expr $h+4]
    set h1 [expr $h+10]
    set b2 [expr $b+2]
    set b1 [expr $b+5]
    set addrow1 [list $backgrId1 0 0 $tw1 $tw1 $h1 $b1]
    set addrow2 [list $backgrId2 3 3 $tw2 $tw2 $h2 $b2]
    set row [list $c 5 5 $w $tw $h $b]
    return [list $addrow1 $row $addrow1 $addrow2]
  }
  bind .t <${prefix}m> {
    %W block insert myBlock insert
    %W mark set index insert-1c
    break
  }
