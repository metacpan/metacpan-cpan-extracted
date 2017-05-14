($DAY, $MONTH, $ZONE, $DIGIT4, $DIGIT2, $DIGIT1, $ALPHA1 ) = (100 .. 110);

#%%

[A-Za-z]{3} {
    return $DAY   if $days{$_[1]};
    return $MONTH if $months{$_[1]};
    return $ZONE  if $zones{$_[1]};
    return 0;
}

[+:,-]      { $_[1]; }

[0-9]{4}    $DIGIT4
[0-9]{2}    $DIGIT2
[0-9]{1}    $DIGIT1
[A-Z]       $ALPHA1
