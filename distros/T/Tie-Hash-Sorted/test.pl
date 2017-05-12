#!/usr/bin/perl -w
use strict;
use Test;

BEGIN { plan tests => 18 };
use Tie::Hash::Sorted;

ok( test_01() );    # Test 01 - Verify keys/values in each loop, hash is built before tie()
ok( test_02() );    # Test 02 - Verify keys/values in each loop, hash is built after tie()

ok( test_03() );    # Test 03 - Verify die and correct error if incorrect # args in tie()
ok( test_04() );    # Test 04 - Verify die and correct error if Sort_Routine isn't code ref
ok( test_05() );    # Test 05 - Verify die and correct error if Optimization isn't valid

ok( test_06() );    # Test 06 - Verify Sort_Routine method
ok( test_07() );    # Test 07 - Verify Optimization method
ok( test_08() );    # Test 08 - Verify Count method works
ok( test_09() );    # Test 09 - Verify Resort method works

ok( test_10() );    # Test 10 - Verify optimization type 'default' works
ok( test_11() );    # Test 11 - Verify optimization type 'none' works
ok( test_12() );    # Test 12 - Verify optimization type 'keys' works
ok( test_13() );    # Test 13 - Verify optimization type 'values' works

ok( test_14() );    # Test 14 - Verify deleting last key visited in each loop works per docs
ok( test_15() );    # Test 15 - Verify delete returns value per docs
ok( test_16() );    # Test 16 - Verify iterator is properly reset per docs
ok( test_17() );    # Test 17 - Verify exists/defined work correctly per docs

ok( test_18() );    # Test 18 - Verify using anon hash works in tie()






############################   TEST 01   ##############################
#
#----------------------------------------------------------------------
#    Verify keys/values in each loop, hash is built before tie()
#----------------------------------------------------------------------
#
#######################################################################

sub test_01 {
    my %data = ( a=>1, b=>2, c=>3, d=>4 );
    tie my %sorted_data, 'Tie::Hash::Sorted', 'Hash' => \%data;
    my @keys;
    my @vals;
    while (my ($key, $value) = each %sorted_data) {
        push @keys, $key;
        push @vals, $value;
    }
    my $serial_key = join ' ', @keys;
    my $serial_val = join ' ', @vals;
    return 1 if $serial_key eq 'a b c d' && $serial_val eq '1 2 3 4';
    return 0;
}



############################   TEST 02   ##############################
#
#----------------------------------------------------------------------
#     Verify keys/values in each loop, hash is built after tie()
#----------------------------------------------------------------------
#
#######################################################################

sub test_02 {
    tie my %sorted_data, 'Tie::Hash::Sorted';
    %sorted_data = ( a=>1, b=>2, c=>3, d=>4 );
    my @keys;
    my @vals;
    while (my ($key, $value) = each %sorted_data) {
        push @keys, $key;
        push @vals, $value;
    }
    my $serial_key = join ' ', @keys;
    my $serial_val = join ' ', @vals;
    return 1 if $serial_key eq 'a b c d' && $serial_val eq '1 2 3 4';
    return 0;
}



############################   TEST 03   ##############################
#
#----------------------------------------------------------------------
#      Verify die and correct error if incorrect # args in tie()
#----------------------------------------------------------------------
#
#######################################################################

sub test_03 {    
    eval {tie my %sorted_data, 'Tie::Hash::Sorted', 'Hash'};
    return 1 if $@ && $@ =~ /Incorrect number of parameters/;
    return 0;
}



############################   TEST 04   ##############################
#
#----------------------------------------------------------------------
#     Verify die and correct error if Sort_Routine isn't code ref
#----------------------------------------------------------------------
#
#######################################################################

sub test_04 {
    eval {tie my %sorted_data, 'Tie::Hash::Sorted', 'Sort_Routine' => 'foo'};
    return 1 if $@ && $@ =~ /Not a code ref/;
    return 0;
}



############################   TEST 05   ##############################
#
#----------------------------------------------------------------------
#       Verify die and correct error if Optimization isn't valid
#----------------------------------------------------------------------
#
#######################################################################

sub test_05 {
    eval {tie my %sorted_data, 'Tie::Hash::Sorted', 'Optimization' => 42};
    return 1 if $@ && $@ =~ /Invalid optimization type/;
    return 0;
}




############################   TEST 06   ##############################
#
#----------------------------------------------------------------------
#                    Verify Sort_Routine method
#----------------------------------------------------------------------
#
#######################################################################

sub test_06 {
    my %data = ( a=>1, b=>2, c=>3, d=>4 );
    tie my %sorted_data, 'Tie::Hash::Sorted', 'Hash' => \%data;

    my $sort = sub {
        my $hash = shift;
        [ sort { $hash->{$b} <=> $hash->{$a} } keys %$hash ];
    };

    (tied %sorted_data)->Sort_Routine($sort);

    my $serial = join ' ', keys %sorted_data;
    return 1 if $serial eq 'd c b a';
    return 0;
}



############################   TEST 07   ##############################
#
#----------------------------------------------------------------------
#                     Verify Optimization method
#----------------------------------------------------------------------
#
#######################################################################

sub test_07 {
    my @months = qw(Jan Mar Apr Jun Aug Dec);
    my (%data, %order);

    @data{@months} = (33, 29, 15, 48, 23, 87);
    @order{@months} = (1, 3, 4, 6, 8, 12);

    my $sort = sub {
        my $hash = shift;    
        [ sort {$order{$a} <=> $order{$b}} keys %$hash ];
    };

    my $tied_ref = tie my %sorted_data, 'Tie::Hash::Sorted', 
        'Hash' => \%data, 'Sort_Routine' => $sort;

    my $Original_Serial = join ' ', keys %sorted_data;
    
    @order{@months} = (12, 8, 6, 4, 3, 1);
    my $After_Change_Serial = join ' ', keys %sorted_data;

    $tied_ref->Optimization('none');
    my $After_Update_Serial = join ' ', keys %sorted_data;    

    return 1 if $Original_Serial eq $After_Change_Serial &&
                $After_Update_Serial eq 'Dec Aug Jun Apr Mar Jan';
    return 0;
}



############################   TEST 08   ##############################
#
#----------------------------------------------------------------------
#                   Verify Count method works
#----------------------------------------------------------------------
#
#######################################################################

sub test_08 {
    my %data = ( a=>1, b=>2, c=>3, d=>4 );
    tie my %sorted_data, 'Tie::Hash::Sorted', 'Hash' => \%data;

    my $results;

    $results++ if (tied %sorted_data)->Count == 4;
    undef %sorted_data;
    $results++ if (tied %sorted_data)->Count == 0;

    return 1 if $results == 2;
    return 0;
}



############################   TEST 09   ##############################
#
#----------------------------------------------------------------------
#                   Verify Resort method works
#----------------------------------------------------------------------
#
#######################################################################

sub test_09 {
    my @months = qw(Jan Mar Apr Jun Aug Dec);
    my (%data, %order);

    @data{@months} = (33, 29, 15, 48, 23, 87);
    @order{@months} = (1, 3, 4, 6, 8, 12);

    my $sort = sub {
        my $hash = shift;    
        [ sort {$order{$a} <=> $order{$b}} keys %$hash ];
    };

    my $tied_ref = tie my %sorted_data, 'Tie::Hash::Sorted', 
        'Hash' => \%data, 'Sort_Routine' => $sort;

    my $Original_Serial = join ' ', keys %sorted_data;
    
    @order{@months} = (12, 8, 6, 4, 3, 1);
    my $After_Change_Serial = join ' ', keys %sorted_data;

    $tied_ref->Resort;
    my $After_Update_Serial = join ' ', keys %sorted_data;    

    return 1 if $Original_Serial eq $After_Change_Serial &&
                $After_Update_Serial eq 'Dec Aug Jun Apr Mar Jan';
    return 0;
}



############################   TEST 10   ##############################
#
#----------------------------------------------------------------------
#              Verify optimization type 'default' works
#----------------------------------------------------------------------
#
#######################################################################

sub test_10 {
    my %data = (
        one   => { a=>1 },
        two   => { a=>1, b=>2 },
        three => { a=>1, b=>2, c=>3 },
        four  => { a=>1, b=>2, c=>3, d=>4 },
        five  => { a=>1, b=>2, c=>3, d=>4, e=>5 }
    );
    my $sort = sub {
        my $h = shift;
        [ sort { keys %{$h->{$b}} <=> keys %{$h->{$a}} } keys %$h ];
    };
    tie my %sorted_data, 'Tie::Hash::Sorted', 
        'Hash' => \%data, 'Sort_Routine' => $sort;
    
    my $serial = join ' ', keys %sorted_data;

    $sorted_data{one}{b} = 2;
    $sorted_data{one}{c} = 3;
    $sorted_data{one}{d} = 4;
    $sorted_data{one}{e} = 5;
    $sorted_data{one}{f} = 6;

    my $updated_serial = join ' ', keys %sorted_data;

    (tied %sorted_data)->Resort;
    my $final_serial = join ' ', keys %sorted_data;
    return 1 if $serial eq $updated_serial && 
        $final_serial eq 'one five four three two';
    return 0;
}



############################   TEST 11   ##############################
#
#----------------------------------------------------------------------
#               Verify optimization type 'none' works
#----------------------------------------------------------------------
#
#######################################################################

sub test_11 {
    my %data = (
        one   => { a=>1 },
        two   => { a=>1, b=>2 },
        three => { a=>1, b=>2, c=>3 }
    );
    my $sort = sub {
        my $h = shift;
        [ sort { keys %{$h->{$b}} <=> keys %{$h->{$a}} } keys %$h ];
    };
    tie my %sorted_data, 'Tie::Hash::Sorted', 
        'Hash' => \%data, 'Sort_Routine' => $sort, 'Optimization' => 'none';
    
    my $serial = join ' ', keys %sorted_data;

    $sorted_data{one}{b} = 2;
    $sorted_data{one}{c} = 3;
    $sorted_data{one}{d} = 4;

    my $new_serial = join ' ', keys %sorted_data;
    
    return 1 if $serial ne $new_serial && $new_serial eq 'one three two';
    return 0;
}



############################   TEST 12   ##############################
#
#----------------------------------------------------------------------
#             Verify optimization type 'keys' works
#----------------------------------------------------------------------
#
#######################################################################

sub test_12 {
    my $sort = sub {
        my $hash = shift;
        [ sort { $hash->{$a} <=> $hash->{$b} } keys %$hash ];
    };
    tie my %sorted_data, 'Tie::Hash::Sorted', 
        'Sort_Routine' => $sort, 'Optimization' => 'keys';
    %sorted_data = ( a=>1, b=>2, c=>3, d=>4 );

    my $serial = join ' ', keys %sorted_data;
    $sorted_data{c} = 15;
    my $updated_serial = join ' ', keys %sorted_data;
  
    (tied %sorted_data)->Resort;
    my $new_serial = join ' ', keys %sorted_data;

    return 1 if $serial eq $updated_serial && $new_serial eq 'a b d c';
    return 0;
}



############################   TEST 13   ##############################
#
#----------------------------------------------------------------------
#              Verify optimization type 'values' works
#----------------------------------------------------------------------
#
#######################################################################

sub test_13 {
    my %one = ( a=>1 );
    my %two = ( a=>1, b=>2 );
    my %three = ( a=>1, b=>2, c=>3 );

    my %data = (
        one   => \%one,
        two   => \%two,
        three => \%three
    );
    my $sort = sub {
        my $h = shift;
        [ sort { keys %{$h->{$b}} <=> keys %{$h->{$a}} } keys %$h ];
    };
    tie my %sorted_data, 'Tie::Hash::Sorted', 
        'Hash' => \%data, 'Sort_Routine' => $sort, 'Optimization' => 'values'; 

    my $serial = join ' ', keys %sorted_data;

    %one = ( a=>1, b=>2, c=>3, d=>4 );
    $sorted_data{one} = \%one;

    my $updated_serial = join ' ', keys %sorted_data;

    (tied %sorted_data)->Resort;
    my $new_serial = join ' ', keys %sorted_data; 
    return 1 if $serial eq $updated_serial && $new_serial eq 'one three two';
    return 0;
}



############################   TEST 14   ##############################
#
#----------------------------------------------------------------------
#   Verify deleting last key visited in each loop works per docs
#----------------------------------------------------------------------
#
#######################################################################

sub test_14 {
    tie my %sorted_data, 'Tie::Hash::Sorted';
    %sorted_data = ( a=>1, b=>2, c=>3, d=>4 );
    my @keys;
    while (my ($key, $value) = each %sorted_data) {
        push @keys, $key;
        delete $sorted_data{$key}
    }
    my $serial = join ' ', @keys;
    return 1 if keys %sorted_data == 0 && $serial eq 'a b c d';
    return 0;
}



############################   TEST 15   ##############################
#
#----------------------------------------------------------------------
#                Verify delete returns value per docs
#----------------------------------------------------------------------
#
#######################################################################

sub test_15 {
    tie my %sorted_data, 'Tie::Hash::Sorted';
    %sorted_data = ( a=>1, b=>2, c=>3, d=>4 );
    my $value = delete $sorted_data{c};
    my $undef = delete $sorted_data{j};
    return 1 if ! defined $undef && $value == 3;
    return 0;
}



############################   TEST 16   ##############################
#
#----------------------------------------------------------------------
#             Verify iterator is properly reset per docs
#----------------------------------------------------------------------
#
#######################################################################

sub test_16 {
    tie my %sorted_data, 'Tie::Hash::Sorted';
    %sorted_data = ( a=>1, b=>2, c=>3 );
    my @keys;
    for my $level1 (keys %sorted_data) {
        push @keys, $level1;
        for my $level2 (keys %sorted_data) {
            push @keys, $level2;
        }
    }
    my $serial = join '', @keys;
    my $valid = 'aabcbabccabc';
    return 1 if $serial eq $valid;
    return 0;
}




############################   TEST 17   ##############################
#
#----------------------------------------------------------------------
#           Verify exists/defined work correctly per docs
#----------------------------------------------------------------------
#
#######################################################################

sub test_17 {
    my %data = ( a=>1, b=>2, c=>3, d=>4 );
    tie my %sorted_data, 'Tie::Hash::Sorted', 'Hash' => \%data;
    my @results;

    push @results, exists $sorted_data{a} ? 1 : 0;;
    delete $sorted_data{a};
    push @results, exists $sorted_data{a} ? 1 : 0;
    $sorted_data{e} = undef;
    push @results, exists $sorted_data{e} ? 1 : 0;;
    push @results, defined $sorted_data{e} ? 1 : 0;;
    $sorted_data{e} = 5;
    push @results, defined $sorted_data{e} ? 1 : 0;

    my $serial = join ' ', @results;
    return 1 if $serial eq '1 0 1 0 1';
    return 0;
}



############################   TEST 18   ##############################
#
#----------------------------------------------------------------------
#               Verify using anon hash works in tie()
#----------------------------------------------------------------------
#
#######################################################################

sub test_18 {
    tie my %sorted_data, 'Tie::Hash::Sorted', 'Hash'=>{a=>1, b=>2, c=>3};
    my @letters = qw(d e f);
    @sorted_data{@letters} = (4, 5, 6);
    my $serial = join '', values %sorted_data;    
    return 1 if $serial eq '123456';
    return 0;
}
