# Internal use only
package XML::TinyXML::Selector::XPath::Functions;

use strict;
use warnings;
use POSIX qw(:sys_types_h);

our $VERSION = "0.34";

# NODE FUNCTIONS

sub last {
    my ($class, $context) = @_;
    return scalar(@{$context->items})
        if ($context);
}

sub position {
    my ($class, $context) = @_;
    my $cnt = 0;
    return map { ++$cnt => $_ } @{$context->items};
}

sub count {
    my ($class, $context, $items) = @_;
    return scalar(@{$items});
}

sub id {
    my ($class, $context, $id, $cnode) = @_;
    foreach my $child ($cnode?$cnode->children:$context->{xml}->rootNodes) {
        my @selection;
        if ($child->attributes->{id} and $child->attributes->{id} eq $id) {
            return $child;
        }
        return id($class, $context, $child);
    }
}

sub local_name {
    my ($class, $context, $items) = @_;
    return map { $_->name } $items?@$items:@{$context->items};
}

sub name {
    # XXX - out of spe
    return local_name(@_);
}

# STRING FUNCTIONS

sub string {
    my ($class, $context, $items) = @_;
    return map { $_->value } $items?@$items:@{$context->items};
}

sub concat {
    my ($class, $context, $str1, $str2) = @_;
    return $str1.$str2;
}

sub starts_with {
    my ($class, $context, $str1, $str2) = @_;
    return ($str1 =~ /^$str2/)?1:0;
}

sub contains {
    my ($class, $context, $str1, $str2) = @_;
    return ($str1 =~ /$str2/)?1:0;
}

sub substring_before {
    my ($class, $context, $str1, $str2) = @_;
    my ($match) = $str1 =~ /(.*?)$str2/;
    return $match;
}

sub substring_after {
    my ($class, $context, $str1, $str2) = @_;
    my ($match) = $str1 =~ /$str2(.*)/;
    return $match;
}

sub substring {
    my ($class, $context, $str, $offset, $length) = @_;
    # handle edge cases as defined in XPath spec
    # [ http://www.w3.org/TR/xpath ]
    if ($length and $length =~ /(\S+)\s+(\S+)\s+(\S+)/) {
        $length = $context->operators->{$2}->($1, $3);
        return "" if(!defined($length) and $offset !~ /^-[0-9]+$/);
    } else {      
        $length = round($class, $context, $length) 
            if ($length and $length =~ /\./);
    }
    if ($offset and $offset =~ /(\S+)\s+(\S+)\s+(\S+)/) {
        $offset = $context->operators->{$2}->($1, $3);
        return "" unless(defined($offset));
    } else {
        $offset = round($class, $context, $offset) 
            if ($offset =~ /\./);
        $length-- if ($length and $offset == 0);
    }
    $offset-- if ($offset > 0);
    return defined($length)
            ? substr($str, $offset, $length)
            : substr($str, $offset);
}

sub string_length {
    my ($class, $context, $str) = @_;
    return length($str);
}

sub normalize_space {
    my ($class, $context, $str) = @_;
    $str =~ s/(^\s+|\s+$)//g;
    return $str;
}

sub translate {
    my ($class, $context, $str, $tfrom, $tto) = @_;

    my @from = split(//, $tfrom);
    my @to = split(//, $tto);
    foreach my $i (0..$#from) {
        if ($to[$i]) {
            $str =~ s/$from[$i]/$to[$i]/g;
        } else {
            $str =~ s/$from[$i]//g;
        }
    }
    return $str;
}

# BOOLEAN FUNCTIONS

sub boolean {
    my ($class, $context, $item) = @_;
    return $item?1:0;
}

sub not {
    my ($class, $context, $item) = @_;
    return !$item?1:0;
}

sub true {
    return 1;
}

sub falce {
    return 0;
}

sub lang {
    my ($class, $context, $lang) = @_;
    # TODO - implement;
    warn __PACKAGE__."::lang() unimplemented";
}

# NUMBER FUNCTIONS

sub number {
    my ($class, $context, $item) = @_;
    return 0+$item; # force numeric context
}

sub sum {
    my ($class, $context, $items) = @_;
    my $res = 0;
    if ($items) {
        $res += $_->value for (@$items);
    }
    return $res;
}

sub floor {
    my ($class, $context, $number) = @_;
    return POSIX::floor($number);
}

sub ceil {
    my ($class, $context, $number) = @_;
    return POSIX::ceil($number);
}

sub round {
    my ($class, $context, $number) = @_;
    return int($number + .5 * ($number <=> 0));
}

1;
