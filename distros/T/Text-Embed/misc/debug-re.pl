#!/usr/bin/perl

BEGIN{ unshift @INC, '../lib'; }

use Text::Embed ':define';



foreach(keys %DATA)
{
    my $string = $DATA{$_};

    if($_ eq "trim")
    {
        Text::Embed::trim(\$string);
    }
    elsif($_ eq "block-preserve")
    {
        Text::Embed::block(\$string);
    }
    elsif($_ eq "block-ignore")
    {
        Text::Embed::block(\$string, 1);
    }
    elsif($_ eq "compress")
    {
        Text::Embed::compress(\$string);
    }

    print "$_ [$string]\n\n"; 
}


__DATA__


#define trim AAAAAAAAAA AAAAAAAAA AAAAAAAAA



#define block-preserve



    BBBBBBB BBBBBB BBBBBB

    BB BBB
        BB BB

    BBB BB




#define block-ignore



    CCCCC CCCCCC CCCCCCCC

    CCC CC
        C CCC
    
    CCC CC




#define compress



    DDDD DDDDDDDDDDDDDD

    DDDDDDDDDDD DDDDDDD

    DDDDDD  DDDDDDDDD D



