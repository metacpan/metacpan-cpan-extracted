#! /usr/bin/perl

use strict;
use warnings;

use Test::More tests => 21;
use WWW::Analytics::MultiTouch;
use DateTime;
use DateTime::Duration;
use Test::Deep;

my $channel1 = 'src1!med1!';
my $channel2 = 'src2!med2!';
my $channel3 = 'src1!med1!sub3';

my $now = DateTime->now;
my $hour = DateTime::Duration->new(hours => 1);
my $day = DateTime::Duration->new(days => 1);
my $week = DateTime::Duration->new(days => 7);

my $t3 = _epoch_of($now);
my $t2 = _epoch_of($now - $hour);
my $t1 = _epoch_of($now - $day);
my $t0 = _epoch_of($now - $week);

my @events = (
    "__ORD!5!10.0!$t3*$channel1!$t2*$channel2!$t1",    
    "__ORD!4!8.0!$t3*$channel1!$t2*$channel3!$t0",
    "__ORD!3!6.0!$t3*$channel1!$t2*$channel1!$t0",
    "__ORD!2!4.0!$t3*$channel1!$t2*__ORD!1!2.0!$t1*$channel3!$t0",
    "__ORD!1!2.0!$t1*$channel3!$t0",
    );

# formatted times and channels
my %ft = map { $_ => eval "DateTime->from_epoch(epoch => \$t$_ )->strftime('%Y-%m-%d %H:%M:%S')" } ( 0 .. 3 );
my %fchannel = map { $_ => eval "my \$c = \$channel$_; \$c =~ s/!\$/-(none)/; \$c =~ s/!/-/g; \$c" } ( 1 .. 3 );

test1();
test2();
test3();
test4();
test5();

sub _epoch_of {
    return shift->epoch;
}

sub _text_of {
    my $cell = shift;
    $cell = $cell->[0] if ref($cell) eq 'ARRAY';
    return defined $cell ? $cell : '';
}

sub _simplify {
    my $src = shift;

    my @data = map { my $row = $_; [ map { _text_of($_) } @$row ] } @$src;

    return \@data;
}

sub test1 {
    my $mt =  WWW::Analytics::MultiTouch->new(id => 1, refresh_token => 2, auth_token => 3);
    my @event_data = map { [ $mt->split_events($_) ] } @events;
    my %data = map { 'TID' . $_->[0][1] => [ DateTime->from_epoch(epoch => $_->[0][3])->ymd('-'),
					     @$_ ] } @event_data;

    $mt->{current_data} = { start_date => DateTime->from_epoch(epoch => $t0),
			    end_date => DateTime->from_epoch(epoch => $t3),
			    transactions => \%data,
    };

    $mt->summarise();
    my $all_touches_report = $mt->all_touches_report();
;
    cmp_bag(_simplify($all_touches_report->{data}), [
		  [ 'src1-med1-(none)', 5, 4, 28, '80.00', '93.33' ],
		  [ 'src1-med1-sub3', 3, 3, 14, '60.00', '46.67' ],
		  [ 'src2-med2-(none)', 1, 1, 10, '20.00', '33.33' ],
		  [ 'ACTUAL TOTALS', 9, 5, 30, '', '' ],
	      ], "All touches");
    my $even_touches_report =  $mt->even_touches_report();
    cmp_bag(_simplify($even_touches_report->{data}), [
		  [ 'src1-med1-(none)', 5, 2.5, 17, '50.00', '56.67' ],
		  [ 'src1-med1-sub3', 3, 2, 8, '40.00', '26.67' ],
		  [ 'src2-med2-(none)', 1, 0.5, 5, '10.00', '16.67' ],
		  [ 'TOTAL', 9, 5, 30, 100, 100 ],
	      ], "Even touches");
    my $distr_touches_report =  $mt->distributed_touches_report();
    cmp_bag(_simplify($distr_touches_report->{data}), [
		  [ 'src1-med1-(none)', 5, 2.5, 17, '50.00', '56.67' ],
		  [ 'src1-med1-sub3', 3, 2, 8, '40.00', '26.67' ],
		  [ 'src2-med2-(none)', 1, 0.5, 5, '10.00', '16.67' ],
		  [ 'TOTAL', 9, 5, 30, 100, 100 ],
	      ], "Distributed touches");
    my $first_touch_report =  $mt->first_touch_report();
    cmp_bag(_simplify($first_touch_report->{data}), [
		  [ 'src1-med1-sub3', 3, 3, 14, '60.00', '46.67' ],
		  [ 'src2-med2-(none)', 1, 1, 10, '20.00', '33.33' ],
		  [ 'src1-med1-(none)', 1, 1, 6, '20.00', '20.00' ],
		  [ 'TOTAL', 5, 5, 30, 100, 100 ],
	      ], "First touch");
    my $last_touch_report =  $mt->last_touch_report();
    cmp_bag(_simplify($last_touch_report->{data}), [
		  [ 'src1-med1-(none)', 4, 4, 28, '80.00', '93.33' ],
		  [ 'src1-med1-sub3', 1, 1, 2, '20.00', '6.67' ],
		  [ 'TOTAL', 5, 5, 30, 100, 100 ],
		  [ '' ],
	      ], "Last touch");
    my $fifty_fifty_report =  $mt->fifty_fifty_report();
    cmp_bag(_simplify($fifty_fifty_report->{data}), [
		  [ 'src1-med1-(none)', 5, 2.5, 17, '50.00', '56.67' ],
		  [ 'src1-med1-sub3', 3, 2, 8, '40.00', '26.67' ],
		  [ 'src2-med2-(none)', 1, 0.5, 5, '10.00', '16.67' ],
		  [ 'TOTAL', 9, 5, 30, 100, 100 ],
	      ], "Fifty-fifty");
    my $trans_report = $mt->transactions_report();
    #splice off date field
    splice(@$_, 1, 1) for @{$trans_report->{data}};
    cmp_bag(_simplify($trans_report->{data}), 
	      [['','Touches','Transactions','Revenue','Touches','Transactions','Revenue','Touches','Transactions','Revenue'],
	       ['1','','','',1,1,2,'','',''],
	       ['2',1,'0.5',2,1,'0.5',2,'','',''],
	       ['3',2,1,6,'','','','','',''],
	       ['4',1,'0.5',4,1,'0.5',4,'','',''],
	       ['5',1,'0.5',5,'','','',1,'0.5',5]], "Transactions");

    my $touchlist_report = $mt->touchlist_report();
    cmp_bag(_simplify($touchlist_report->{data}), [
	      [ 1, $ft{1}, '2.0', $fchannel{3}, $ft{0}, "ORDER(1)", $ft{1} ],
	      [ 2, $ft{3}, '4.0', $fchannel{3}, $ft{0}, "ORDER(1)", $ft{1}, $fchannel{1}, $ft{2}, "ORDER(2)", $ft{3} ],
	      [ 3, $ft{3}, '6.0', $fchannel{1}, $ft{0}, $fchannel{1}, $ft{2}, "ORDER(3)", $ft{3} ],
	      [ 4, $ft{3}, '8.0', $fchannel{3}, $ft{0}, $fchannel{1}, $ft{2}, "ORDER(4)", $ft{3} ],
	      [ 5, $ft{3}, '10.0', $fchannel{2}, $ft{1}, $fchannel{1}, $ft{2}, "ORDER(5)", $ft{3} ],
	      ], "Touchlist");
    my $trans_dist_report = $mt->transaction_distribution_report();
    cmp_bag(_simplify($trans_dist_report->{data}), [
		  [ 'src1-med1-(none)', 3, 1 ],
		  [ 'src1-med1-sub3', 3, 0 ],
		  [ 'src2-med2-(none)', 1, 0 ],
		  [ 'OVERALL', 1, 4 ],
	      ], "Transaction Distribution");
    my $channel_overlap_report =  $mt->channel_overlap_report();
    cmp_bag(_simplify($channel_overlap_report->{data}), [
		  [ 'Channel Count', 'Touches', 'Transactions', 'Revenue', '% Transactions', '% Revenue', 'Efficiency' ],
		  [ 1, 3, 2, 8, '40.00', '26.67', '0.67' ],
		  [ 2, 6, 3, 22, '60.00', '73.33', '0.50' ],
		  [ ' ' ],
		  [ 'Channel Combination', 'Touches', 'Transactions', 'Revenue', '% Transactions', '% Revenue', 'Efficiency' ],
		  [ 'src1-med1-sub3', 1, 1, 2, '20.00', '6.67', '1.00' ],
		  [ 'src1-med1-(none)+src2-med2-(none)', 2, 1, 10, '20.00', '33.33', '0.50' ],
		  [ 'src1-med1-(none)', 2, 1, 6, '20.00', '20.00', '0.50' ],
		  [ 'src1-med1-(none)+src1-med1-sub3', 4, 2, 12, '40.00', '40.00', '0.50' ],
	      ], "Channel Overlap");
}

sub test2 {
    my $mt =  WWW::Analytics::MultiTouch->new(id => 1, refresh_token => 2, auth_token => 3);
    my @event_data = map { [ $mt->split_events($_) ] } @events;
    my %data = map { 'TID' . $_->[0][1] => [ DateTime->from_epoch(epoch => $_->[0][3])->ymd('-'),
					     @$_ ] } @event_data;

    $mt->{current_data} = { start_date => DateTime->from_epoch(epoch => $t0),
			    end_date => DateTime->from_epoch(epoch => $t3),
			    transactions => \%data,
    };

    $mt->summarise(single_order_model => 1);
    my $all_touches_report = $mt->all_touches_report();
    cmp_bag(_simplify($all_touches_report->{data}), [
		  [ 'src1-med1-(none)', 5, 4, 28, '80.00', '93.33' ],
		  [ 'src1-med1-sub3', 2, 2, 10, '40.00', '33.33' ],
		  [ 'src2-med2-(none)', 1, 1, 10, '20.00', '33.33' ],
		  [ 'ACTUAL TOTALS', 8, 5, 30, '', '' ],
	      ], "All touches single order");
    my $distr_touches_report =  $mt->distributed_touches_report();
    cmp_bag(_simplify($distr_touches_report->{data}), [
		  [ 'src1-med1-(none)', 5, 3, 19, '60.00', '63.33' ],
		  [ 'src1-med1-sub3', 2, 1.5, 6, '30.00', '20.00' ],
		  [ 'src2-med2-(none)', 1, 0.5, 5, '10.00', '16.67' ],
		  [ 'TOTAL', 8, 5, 30, 100, 100 ],
	      ], "Distributed touches single order");
    my $trans_report = $mt->transactions_report();
    #splice off date field
    splice(@$_, 1, 1) for @{$trans_report->{data}};
    cmp_bag(_simplify($trans_report->{data}), 
	      [['','Touches','Transactions','Revenue','Touches','Transactions','Revenue','Touches','Transactions','Revenue'],
	       ['1','','','',1,1,2,'','',''],
	       ['2',1,1,4,'','','','','',''],
	       ['3',2,1,6,'','','','','',''],
	       ['4',1,'0.5',4,1,'0.5',4,'','',''],
	       ['5',1,'0.5',5,'','','',1,'0.5',5]], "Transactions single order");

    my $touchlist_report = $mt->touchlist_report();
    cmp_bag(_simplify($touchlist_report->{data}), [
	      [ 1, $ft{1}, '2.0', $fchannel{3}, $ft{0}, "ORDER(1)", $ft{1} ],
	      [ 2, $ft{3}, '4.0', $fchannel{1}, $ft{2}, "ORDER(2)", $ft{3} ],
	      [ 3, $ft{3}, '6.0', $fchannel{1}, $ft{0}, $fchannel{1}, $ft{2}, "ORDER(3)", $ft{3} ],
	      [ 4, $ft{3}, '8.0', $fchannel{3}, $ft{0}, $fchannel{1}, $ft{2}, "ORDER(4)", $ft{3} ],
	      [ 5, $ft{3}, '10.0', $fchannel{2}, $ft{1}, $fchannel{1}, $ft{2}, "ORDER(5)", $ft{3} ],
	      ], "Touchlist single order");
}

			    
sub test3 {
    my $mt =  WWW::Analytics::MultiTouch->new(id => 1, refresh_token => 2, auth_token => 3);
    my @event_data = map { [ $mt->split_events($_) ] } @events;
    my %data = map { 'TID' . $_->[0][1] => [ DateTime->from_epoch(epoch => $_->[0][3])->ymd('-'),
					     @$_ ] } @event_data;

    $mt->{current_data} = { start_date => DateTime->from_epoch(epoch => $t0),
			    end_date => DateTime->from_epoch(epoch => $t3),
			    transactions => \%data,
    };

    $mt->summarise(window_length => 6);
    my $all_touches_report = $mt->all_touches_report();
    cmp_bag(_simplify($all_touches_report->{data}), [
		  [ 'src1-med1-(none)', 4, 4, 28, '80.00', '93.33' ],
		  [ 'src2-med2-(none)', 1, 1, 10, '20.00', '33.33' ],
		  [ 'src1-med1-sub3', 1, 1, 2, '20.00', '6.67' ],
		  [ 'ACTUAL TOTALS', 6, 5, 30, '', '' ],
	      ], "All touches short window");

    my $distr_touches_report =  $mt->distributed_touches_report();
    cmp_bag(_simplify($distr_touches_report->{data}), [
		  [ 'src1-med1-(none)', 4, 3.5, 23, '70.00', '76.67' ],
		  [ 'src2-med2-(none)', 1, 0.5, 5, '10.00', '16.67' ],
		  [ 'src1-med1-sub3', 1, 1, 2, '20.00', '6.67' ],
		  [ 'TOTAL', 6, 5, 30, 100, 100 ],
	      ], "Distributed touches short window");

    my $trans_report = $mt->transactions_report();
    #splice off date field
    splice(@$_, 1, 1) for @{$trans_report->{data}};
    cmp_bag(_simplify($trans_report->{data}), 
	      [['','Touches','Transactions','Revenue','Touches','Transactions','Revenue','Touches','Transactions','Revenue'],
	       ['1','','','','','','',1,1,2],
	       ['2',1,1,4,'','','','','',''],
	       ['3',1,1,6,'','','','','',''],
	       ['4',1,1,8,'','','','','',''],
	       ['5',1,'0.5',5,1,'0.5',5,'','','']], "Transactions short window");

    my $touchlist_report = $mt->touchlist_report();
    cmp_bag(_simplify($touchlist_report->{data}), [
	      [ 1, $ft{1}, '2.0', $fchannel{3}, $ft{0}, "ORDER(1)", $ft{1} ],
	      [ 2, $ft{3}, '4.0', "ORDER(1)", $ft{1}, $fchannel{1}, $ft{2}, "ORDER(2)", $ft{3} ],
	      [ 3, $ft{3}, '6.0',  $fchannel{1}, $ft{2}, "ORDER(3)", $ft{3} ],
	      [ 4, $ft{3}, '8.0',  $fchannel{1}, $ft{2}, "ORDER(4)", $ft{3} ],
	      [ 5, $ft{3}, '10.0', $fchannel{2}, $ft{1}, $fchannel{1}, $ft{2}, "ORDER(5)", $ft{3} ],
	      ], "Touchlist short window");
}

			    
    
    
sub test4 {
    my $mt =  WWW::Analytics::MultiTouch->new(id => 1, refresh_token => 2, auth_token => 3);
    my @event_data = map { [ $mt->split_events($_) ] } @events;
    my %data = map { 'TID' . $_->[0][1] => [ DateTime->from_epoch(epoch => $_->[0][3])->ymd('-'),
					     @$_ ] } @event_data;

    $mt->set_data( start_date => DateTime->from_epoch(epoch => $t0),
		   end_date => DateTime->from_epoch(epoch => $t3),
		   transactions => \%data,
	);

    # Apply adjustment to day of $t1 (order 1, channel 3)
    $mt->summarise(adjustments => 
		   {
		       DateTime->from_epoch(epoch => $t1)->ymd('-') => 
		       {
			   revenue => 2,
			   transactions => 3,
		       }
		   }
		   );
    my $all_touches_report = $mt->all_touches_report();
;
    cmp_bag(_simplify($all_touches_report->{data}), [
		  [ 'src1-med1-(none)', 5, 4, 28, '57.14', '87.50' ],
		  [ 'src1-med1-sub3', 5, 5, 16, '71.43', '50.00' ],
		  [ 'src2-med2-(none)', 1, 1, 10, '14.29', '31.25' ],
		  [ 'ACTUAL TOTALS', 11, 7, 32, '', '' ],
	      ], "All touches");
    my $even_touches_report =  $mt->even_touches_report();
    cmp_bag(_simplify($even_touches_report->{data}), [
		  [ 'src1-med1-(none)', 5, 2.5, 17, '35.71', sprintf("%.2f", 17/32 * 100) ],
		  [ 'src1-med1-sub3', 5, 4, 10, '57.14', '31.25' ],
		  [ 'src2-med2-(none)', 1, 0.5, 5, '7.14', sprintf("%.2f", 5/32 * 100) ],
		  [ 'TOTAL', 11, 7, 32, 100, 100 ],
	      ], "Even touches");
}

sub test5 {
    my $mt =  WWW::Analytics::MultiTouch->new(id => 1, refresh_token => 2, auth_token => 3);
    my @event_data = map { [ $mt->split_events($_) ] } @events;
    my %data = map { 'TID' . $_->[0][1] => [ DateTime->from_epoch(epoch => $_->[0][3])->ymd('-'),
					     @$_ ] } @event_data;

    $mt->{current_data} = { start_date => DateTime->from_epoch(epoch => $t0),
			    end_date => DateTime->from_epoch(epoch => $t3),
			    transactions => \%data,
    };

    $mt->summarise();

    my $fifty_fifty_report =  $mt->fifty_fifty_report(strict_integer_values => 1);
    cmp_bag(_simplify($fifty_fifty_report->{data}), [
		  [ 'src1-med1-(none)', 5, 2, 17, '50.00', '56.67' ],
		  [ 'src1-med1-sub3', 3, 2, 8, '40.00', '26.67' ],
		  [ 'src2-med2-(none)', 1, 0, 5, '10.00', '16.67' ],
		  [ 'TOTAL', 9, 5, 30, 100, 100 ],
	      ], "Fifty-fifty");
}
