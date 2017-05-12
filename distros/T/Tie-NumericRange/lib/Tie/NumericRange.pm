#
# Tie::NumericRange
# (c) 2008 Michael Gregorowicz
#          the mg2 organization
#

package Tie::NumericRange;

use 5.006001;
use strict;
no warnings; 

use Carp qw(croak);

our $VERSION = '0.01';

sub TIEHASH {
    my ($class) = @_;
    return bless {}, $class;
}

sub FETCH {
    my ($self, $key) = @_;
    # check the obvious first.
    if (exists($self->{$key})) {
        return $self->{$key};
    } else {
        # now check each precision of this key starting with the highest precision
        my $max_precision = (sort { $b <=> $a } keys %{$self->{_precision}})[0];
        for (my $precision = $max_precision; $precision > 0; $precision--) {
            my $k = sprintf("%.$precision" . "f", $key);
            if (exists($self->{$k})) {
                return $self->{$k};
            }
        }
        
        # ok one final one.  check and see if it collapses into an int that we have.
        my $k = sprintf('%d', $key);
        if (exists($self->{$k})) {
            return $self->{$k};
        }
    }
    return undef;
}

sub STORE {
    my ($self, $key, $value) = @_;
    
    my (@ranges) = split(/\s*,\s*/, $key);
    
    # blow up the range into a hash table, sorry memory, but i want fast lookups!
    foreach my $range (@ranges) {
        if ($range =~ /^(\-)?(\d+)\.?(\d*)\.\.(\-)?(\d+)\.?(\d*)$/) {
            my ($a_sign, $a_num, $a_dec) = ($1, $2, $3);
            my ($b_sign, $b_num, $b_dec) = ($4, $5, $6);
            
            my ($alpha, $beta, $precision);
            
            if ($a_dec || $b_dec) {
                # this is a fp load, lets get the precision.          
                $precision = length($a_dec) > length($b_dec) ? length($a_dec) : length($b_dec);
                $alpha = sprintf('%.' . $precision . 'f', "$a_sign$a_num.$a_dec");
                $beta = sprintf('%.' . $precision . 'f',"$b_sign$b_num.$b_dec");
            } else {
                $alpha = "$a_sign$a_num";
                $beta = "$b_sign$b_num";
            }
            
            if ($beta > $alpha) {
                if ($precision) {
                    # fp!
                    my $inc_by = "0." . "0" x ($precision - 1) . "1";
                    for (my $i = $alpha; $i <= $beta; $i += $inc_by) {
                        my $key = sprintf('%.' . $precision . 'f', $i);
                        $self->{$key} = $value;
                        $self->{0} = $value if sprintf("%d", $i) == 0;
                        $self->{_precision}->{$precision}++;
                    }
                } else {
                    # straight int load.
                    for ($alpha..$beta) {
                        $self->{$_} = $value;
                    }
                }
            } else {
                croak "$alpha is greater than $beta.. invalid range: $range\n";
            }
        } else {
            # just one!
            if ($range =~ /^(\-)?(\d+)\.?(\d*)/) {
                my $precision = length($3);
                $self->{$range} = $value;
                $self->{_precision}->{$precision}++;
            } else {
                # its not even numeric
                $self->{$range} = $value;
            }
        }
    }
}

sub CLEAR {
    my ($self) = @_;
    %$self = ();
}

sub DELETE {
    my ($self, $key) = @_;
    
    my (@ranges) = split(/\s*,\s*/, $key);
    
    # blow up the range into a hash table, sorry memory, but i want fast lookups!
    foreach my $range (@ranges) {
        if ($range =~ /^(\-)?(\d+)\.?(\d*)\.\.(\-)?(\d+)\.?(\d*)$/) {
            my ($a_sign, $a_num, $a_dec) = ($1, $2, $3);
            my ($b_sign, $b_num, $b_dec) = ($4, $5, $6);
            
            my ($alpha, $beta, $precision);
            
            if ($a_dec || $b_dec) {
                # this is a fp load, lets get the precision.          
                $precision = length($a_dec) > length($b_dec) ? length($a_dec) : length($b_dec);
                $alpha = sprintf('%.' . $precision . 'f', "$a_sign$a_num.$a_dec");
                $beta = sprintf('%.' . $precision . 'f',"$b_sign$b_num.$b_dec");
            } else {
                $alpha = "$a_sign$a_num";
                $beta = "$b_sign$b_num";
            }
            
            if ($beta > $alpha) {
                if ($precision) {
                    # fp!
                    my $inc_by = "0." . "0" x ($precision - 1) . "1";
                    for (my $i = $alpha; $i <= $beta; $i += $inc_by) {
                        my $key = sprintf('%.' . $precision . 'f', $i);
                        delete($self->{$key});
                        delete($self->{0}) if sprintf("%d", $i) == 0;
                        $self->{_precision}->{$precision}--;
                    }
                } else {
                    # straight int load.
                    for ($alpha..$beta) {
                        delete($self->{$_});
                    }
                }
            } else {
                croak "$alpha is greater than $beta.. invalid range.\n";
            }
        } else {
            # just one!
            if ($range =~ /^(\-)?(\d+)\.?(\d*)/) {
                my $precision = length($3);
                delete($self->{$range});
                $self->{_precision}->{$precision}--;
            } else {
                # not numeric, just delete
                delete($self->{$range});
            }
        }
    }
}

sub EXISTS {
    my ($self, $key) = @_;
    return defined($self->FETCH($key)) ? 1 : 0;
}

sub SCALAR {
    # return the object!
    return($_[0]);
}

sub FIRSTKEY {
    my ($self) = @_;
    my $a = keys %$self;
    my $key = each %$self;
    until ($key !~ /^_/o || !$key) {
        $key = each %$self;
    }
    return $key;
}

sub NEXTKEY {
    my ($self) = @_;
    my $key = each %$self;
    until ($key !~ /^_/o || !$key) {
        $key = each %$self;
    }
    return $key;
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it! NUH UH.

=head1 NAME

Tie::NumericRange - Perl extension that creates key / value pairs out of numeric ranges!

=head1 SYNOPSIS

  use Tie::NumericRange;
  my %h;
  tie (%h, Tie::NumericRange);
  
  $h{'2.90..9.65'} = "Some value for this fab range!";
  
  print $h{'3'} . "\n"; # prints "Some value for this fab range!\n"
  print $h{'4.621235'} . "\n"; # same
  print $h{'10.1235'} . "\n"; # prints undef . "\n"
  
  delete($h{'4'});
  print $h{'4'} . "\n"; # prints undef . "\n"
  print $h{'4.1'} . "\n"; # prints "Some value for this fab range!\n"
  
  keys(%h) #.. all the numbers in the ranges defined

=head1 DESCRIPTION

Tie::NumericRange creates a hash that takes numeric ranges as its keys.  You can then
reference the value assigned to the range using a member of that range.

=head1 SEE ALSO

Number::Range which does similar things, supports similar formats, but does not support
floats and uses an object / method interface instead of a hash interface.

=head1 AUTHOR

Michael Gregorowicz, E<lt>mike@mg2.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Michael Gregorowicz

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
