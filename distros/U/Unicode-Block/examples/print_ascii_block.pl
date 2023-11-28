#!/usr/bin/env perl

use strict;
use warnings;

use Unicode::Block;
use Unicode::UTF8 qw(encode_utf8);

# Object.
my $obj = Unicode::Block->new;

# Print all.
my $num = 0;
while (my $char = $obj->next) {
       if ($num != 0) {
               if ($num % 16 == 0) {
                       print "\n";
               } else {
                       print " ";
               }
       }
       print encode_utf8($char->char);
       $num++;
}
print "\n";

# Output.
#                                
#                                
#   ! " # $ % & ' ( ) * + , - . /
# 0 1 2 3 4 5 6 7 8 9 : ; < = > ?
# @ A B C D E F G H I J K L M N O
# P Q R S T U V W X Y Z [ \ ] ^ _
# ` a b c d e f g h i j k l m n o
# p q r s t u v w x y z { | } ~  