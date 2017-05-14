#%%

start:      day_opt date time ;
day_opt:    $DAY ',' | ;
date:       day $MONTH      { print "mon $months{$_[0]} "; }
            year ;
day:        $DIGIT1         { print "day $_[0] "; }
          | $DIGIT2         { print "day $_[0] "; } ;
year:       $DIGIT2         { print "year ", 1900 + $_[0], " "; }
          | $DIGIT4         { print "year $_[0] "; } ;
time:       hour zone ;
hour:       $DIGIT2         { print "hour $_[0] "; }
            ':' $DIGIT2  { print "min $_[0] "; }
            sec_opt ;
sec_opt:    ':' $DIGIT2  { print "sec $_[0] "; } | ;
zone:       $ZONE | $ALPHA1 | prefix $DIGIT4 ;
prefix:     '+' | '-' ;
