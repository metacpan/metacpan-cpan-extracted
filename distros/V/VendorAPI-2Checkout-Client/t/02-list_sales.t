#!perl -T

use strict;
use warnings;

use lib 't';

use Test::More ;
use List::MoreUtils qw(all pairwise);
use FormatTests::Factory;

BEGIN {
    use_ok( 'VendorAPI::2Checkout::Client' ) || print "Bail out!\n";
}


sub test_parameter {
   my ($ua, $param, $value, $tests) = @_;
   my $r = $ua->list_sales($param => $value);
   ok($r->is_success(), 'http 200');
   my $list = $tests->to_hash($r->content());
   my $num_sales = $tests->num_sales($list);
   ok( $num_sales > 0, "$param: got $num_sales for $value");
}

sub test_sort {
   my ($tco, $sort_col, $sort_dir, $tests) = @_;
   my $r = $tco->list_sales(sort_col => $sort_col, sort_dir => $sort_dir);
   ok($r->is_success(), 'http 200');
   my $list = $tests->to_hash($r->content());
   my $num_sales = $tests->num_sales($list);
   ok( $num_sales > 0, "$sort_col: got $num_sales sales");

   my $sales = $list->{sale_summary};
   my @raw_columns =  map { $tests->get_col($_, $sort_col) } @$sales;
   my @sort_columns = sort { lc $a cmp lc $b } map { $tests->get_col($_, $sort_col) } @$sales;
   if ($sort_dir eq 'DESC') {
       @sort_columns = reverse @sort_columns;
   }

   my @comparisons ;
   if ( $sort_col eq 'recurring_declined' && ( (ref $tests) =~ qr/XML$/ ) ) {
      @comparisons = pairwise { my %a = %{$a}; my %b = %{$b}; %a == %b } @sort_columns, @raw_columns;
   }
   else {
      @comparisons = pairwise { no warnings 'once'; lc $a eq lc $b } @sort_columns, @raw_columns;
   }

   my $sorted_correctly = all { $_ } @comparisons;
   ok( $sorted_correctly, "$sort_col: $sort_dir sorts as expected");
}

sub test_list_sales {
   my $tco = shift;
   my $format_tests = shift;
   my $r = $tco->list_sales();
   ok($r->is_success(), 'http 200');

   my $list = $format_tests->to_hash($r->content());
   my $num_all_sales = $format_tests->num_all_sales($list);

   if (defined $ENV{VAPI_HAS_SALES} && $ENV{VAPI_HAS_SALES} > 0 ) {
      ok($num_all_sales > 0 , "got $num_all_sales sales");
   }

   return $num_all_sales;
}


sub test_input_parameters {
   my $tco = shift;
   my $num_all_sales = shift;
   my $format_tests = shift;

   my @sort_columns = qw/sale_id date_placed customer_name recurring recurring_declined usd_total/;
   foreach my $col ( @sort_columns ) {
      foreach my $dir ( qw/ ASC DESC / ) {
         test_sort($tco, $col, $dir, $format_tests);
      }
   }

   my %param_test_data = (
       customer_name => 'carp',
       customer_email => 'carp',
       customer_phone => 614,
       vendor_product_id => 'Coffee',
       ccard_first6 => '443220',
       ccard_last2 => '38',
       date_sale_begin => '2010-12-15',
       date_sale_end => '2015-10-15',
   );

   # input parameters
   foreach my $param ( keys %param_test_data ) {
      my $rv = test_parameter($tco, $param => $param_test_data{$param}, $format_tests);
   }

   my @test_data = (
       [ 'refunded' , 0],
       [ 'active_recurrings' , 0],
       [ 'declined_recurrings' , 0],
   );

   foreach my $test ( @test_data ) {
      my ($param, $value) = @$test;
      my $rv = test_parameter($tco, $param => $value, $format_tests);
   }

   # pagination
   for (my $pagesize = 1; $pagesize <= $num_all_sales; $pagesize++) {
      my $num_full_pages = int($num_all_sales / $pagesize);
      my $partial_page = ( $num_full_pages * $pagesize != $num_all_sales);
      my $expected_pages = $num_full_pages + $partial_page;

      for (my $page_num = 1;$page_num <= $expected_pages; $page_num++) {
         my $r = $tco->list_sales(cur_page => $page_num, pagesize => $pagesize);
         ok($r->is_success(), 'http 200');
         my $list = $format_tests->to_hash($r->content);
         my $num_sales = $format_tests->num_sales($list);

         if ( $page_num < $expected_pages || !$partial_page ) {
            is($num_sales, $pagesize, "got page $page_num of $expected_pages - $pagesize sales per page");
            next;
         }

         my $partial_size = $num_all_sales - ( $num_full_pages * $pagesize );
         is($num_sales, $partial_size, "got page $page_num of $expected_pages - $partial_size sales on this page");
      }
   }
}


SKIP: {
    foreach my $moosage ( 0..1 ) {
      foreach my $format ( 'XML', 'JSON'  ) {
        skip "VAPI_2CO_UID && VAPI_2CO_PWD not set in environment" , 5 unless $ENV{VAPI_2CO_UID} && $ENV{VAPI_2CO_PWD};
        my $tco = VendorAPI::2Checkout::Client->get_client( $ENV{VAPI_2CO_UID}, $ENV{VAPI_2CO_PWD}, $format, $moosage );
        my $format_tests = FormatTests::Factory->get_format_tests($format);

        ok(defined $tco, "get_client: got object");
        #isa_ok($tco,'VendorAPI::2Checkout::Client');

        my $num_all_sales = test_list_sales($tco, $format_tests);

        # now try out some input parameters
        SKIP: {
          skip "list_sales input param tests require a vendor account with at leat 2 sales", $num_all_sales unless $num_all_sales >= 2;
          test_input_parameters($tco, $num_all_sales, $format_tests);
        }  # SKIP
      }
    }
}   # SKIP

done_testing();
