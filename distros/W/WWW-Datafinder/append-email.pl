use strict;
use warnings;

use lib (
      $ENV{'DATAFINDER_HOME'}
    ? $ENV{'DATAFINDER_HOME'}
    : $FindBin::Bin
);

use WWW::Datafinder;
use Data::Dumper;
use Carp qw(croak cluck confess);
use Config::IniFiles;
use Getopt::Long;
use Storable qw(nstore retrieve dclone);
use Try::Tiny;
use POSIX;
use Search::Elasticsearch;
use DateTime::Format::ISO8601;
use MCE;
use Scalar::Util qw(reftype);
use Text::CSV_XS;


my %mws2datafiner = (
    'd_zip' => sub { my ($x) = @_; unless ($x->{PostalCode}) { return undef; } my ($z) = split('-', $x->{PostalCode}); return $z; },
    'd_fulladdr' => sub { my ($x) = @_;
                          return undef unless defined($x->{AddressLine1});
                          return $x->{AddressLine1} .
                            ($x->{AddressLine2} ? ' '.$x->{AddressLine2} : ''); },
    'd_state' => sub { my ($x) = @_; return $x->{StateOrRegion}; },
    'd_city' =>  sub { my ($x) = @_; return $x->{City}; },
    'd_first' =>  sub { my ($x) = @_; return first_name($x->{BuyerName}); },
    'd_last' =>  sub { my ($x) = @_; return last_name($x->{BuyerName}); },
);
my $df  = WWW::Datafinder->new( {
#    api_key   => 'gmnglsc3koi5yzmtte5sss6i',
    api_key   => 'XXX',
    cache_time => 0
#    cache_time => 3600*1000
   }) or die 'Cannot create Datafinder object';


use Readonly;
Readonly my $ORDERS_CACHE => '../mws/orders.cache2';

Readonly my $CONFIG_ELASTIC_SECTION    => 'Elastic';

use vars qw($config_file $conf_obj $debug %orders $interval);

if (@ARGV == 0) {
    print_usage();
    exit(1);
}

GetOptions(
    'c|config=s'   => \$config_file,
    'd|debug'      => \$debug
);

$config_file //= "$FindBin::Bin/etc/update-usage.conf";
$conf_obj = Config::IniFiles->new( -file => $config_file )
  || croak( "Config file error:\n" . join( "\n", @Config::IniFiles::errors ) );

my $nodelist = $conf_obj->val( $CONFIG_ELASTIC_SECTION, 'Nodes' );
unless ($nodelist) {
    confess('No elastic node list is provided');
}
my $index = $conf_obj->val( $CONFIG_ELASTIC_SECTION, 'Index', 'amazon_mws' );
my $elastic_type = $conf_obj->val( $CONFIG_ELASTIC_SECTION, 'Type', 'order_item' );

my $es = Search::Elasticsearch->new(
     {
                cxn_pool => 'Static',
                nodes    => [ split q{,}, $nodelist ],
                # trace_to => [ 'File', $self->config->val( 'Global', 'Log_File' ) ],
                # log_to   => [ 'File', $self->config->val( 'Global', 'Log_File' ) ],
            }
    );

my $params = {
    query => {
        match_all => {}
       },
#    filter => [
#        
#        ]
#       }
   };

my $scroll = $es->scroll_helper(
            scroll      => '120m',
            search_type => 'scan',
            size        => 1000,
            index       => $index,
            type        => $elastic_type,
            body        => $params
        );
my $count = 0;
my $x;

my %asin = (
'B01CV7HLO2' => 1,
'B00L3QWJBI' => 1,
'B00PUX0A52' => 1,
'B00HFD0QTK' => 1,
'B01HQFTW00' => 1,
'B012UKTVTS' => 1,
'B01CUZ8J3C' => 1,
'B01L7EZ048' => 1,
'B01L7L3HKU' => 1
);
my $c = 0;
my @result;

my $bulk = $es->bulk_helper(
        max_count  => 100,
        max_size   => 0,
        index => $index,
        type => $elastic_type,
         on_error   => sub {
            my ($action, $response, $i) = @_;
            print STDERR "Error in elastic $action ". Dumper($response)."\n";
        }
    );

 my $mce = eval {
        MCE->new(
            max_workers => 10,
            chunk_size => 1,
            input_data  => \&get_data,
            user_func   => \&lookup_email,
            user_end    => \&flush,
            gather => \&reindex_order
        )
    };

if ($@) {
    print STDERR "Cannot create parallel workers: $@";
    exit;
}

eval { $mce->run(); };
print "Error $@" if $@;
print "Flushing buffer\n";
$bulk->flush;

print "$count total records\n";

my $csv = Text::CSV_XS->new ({ binary => 1, auto_diag => 1 });
open my $fh, ">:encoding(utf8)", "res2.csv" or die "new.csv: $!";
foreach my $z (@result) {
    $csv->print($fh, $z);
    print $fh "\r\n";
}
close($fh);
exit;


sub get_data {
    return undef if $c > 5;
    while (my $x = get_next($scroll)) {
        #print Dumper($x);
        my $asin = $x->{Item}->{ASIN};
        unless ($asin && exists($asin{$asin})) {
            #print "Skipping - wrong product\n";
            next;
        }
        unless ($x->{PurchaseDate} gt '2016-10-01T00:00:00') {
            #print "Skipping - too old order\n";
            next;
        }
        unless ($x->{ShippingAddress} && $x->{ShippingAddress}->{AddressLine1}) {
            #print "Skipping - no address\n";
            next;
        }
        if ($x->{AppendedData} || $x->{NoAppendMatch}) {
            next;
        }
        $x->{ShippingAddress}->{BuyerName} = $x->{BuyerName}; # it seems to be cleaner
        print "Returning ".$x->{SellerOrderId}."\n";
        $c++;
        return $x;
    }
    return undef;
}

sub lookup_email {
    my ( $mce, $chunk_ref, $chunk_id ) = @_;

    my $worker_id = 'worker #' . MCE->wid;
    #print "worker $worker_id\n";
    my $x = $chunk_ref->[0];
    print "$worker_id got ".Dumper($x);

    return unless reftype($x) eq 'HASH';
    if ($x->{AppendedData} || $x->{NoAppendMatch}) {
        MCE->gather( $chunk_id, 1, $x );
        return 0;
    }

    my $data = {};
    while ( my ($field, $code) = each %mws2datafiner) {
        my $val = &{$code}($x->{ShippingAddress});
        $data->{$field} = $val if $val;
    }
    #print Dumper($data);
    my $d = $df->append_email($data);
    my $status = 0;
    if ($d) {
        $d = $d->{datafinder} if $d->{datafinder};
        #print "$worker_id got email append result ".Dumper($d);  
        $status = 1;

        if ($d->{'num-results'}) {
              $x->{AppendedData} = $d;
              print "$worker_id appended email to ".$x->{SellerOrderId}."\n";
        } else {
            $x->{NoAppendMatch} = 'Y';
            print "$worker_id  could not find email for ".$x->{SellerOrderId}."\n";
        }
    }
 
    MCE->gather( $chunk_id, $status, $x );
}

sub reindex_order {
    my ( $chunk_id, $status, $x ) = @_;

    return unless reftype($x) eq 'HASH';

    if ($status) {
        $count++;
        my $id = $x->{_id};
        delete($x->{_id});
        #$bulk->index( { index => $index, id => $id, source => $x } );
        print "Reindexing $id ".$x->{AmazonOrderId}." $count\n";
        if ($x->{AppendedData}) {
            foreach my $ap (@{$x->{AppendedData}->{results}}) {
                push @result, [
                    $x->{AmazonOrderId},
                    $x->{BuyerName},
                    first_name($x->{BuyerName}),
                    last_name($x->{BuyerName}),
                    $x->{PurchaseDate},
                    $x->{OrderStatus},
                    $x->{Item}->{ASIN},
                    $x->{Item}->{SellerSKU},
                    $x->{Item}->{ItemPrice}->{Amount},
                    $x->{Item}->{ItemPrice}->{FinalAmount},
                    $x->{Item}->{QuantityOrdered},
                    $ap->{FirstName},
                    $ap->{LastName},
                    $ap->{Address},
                    $ap->{City},
                    $ap->{State},
                    $ap->{Zip} . ($ap->{Zip4} ? '-'.$ap->{Zip4} : ''),
                    $ap->{EmailAddr},
                    $ap->{EmailAddrUsable}
                   ];
            }
        }
    }

    return 1;
}

sub flush {

}

sub get_next {
    my ($scroll) = @_;

    my ( $data, $error );
    try {
        $data = $scroll->next();
    }
    catch {
        $error = $_;
    };

    if ( defined $error ) {
        my $last_scroll_id = $scroll->_scroll_id;
        # prevents 'finish' call for missed scroll_id
        $scroll->_set_is_finished(1);

        if ( ref($error) && $error->is('Missing') ) {
            print qq{[elastic]: Renewing expired scroll $last_scroll_id\n};
            return get_next($scroll);
        } else {
            print qq{Elastic error: $error\n};
        }
    }
    if ($data) {
        my $x = $data->{_source};
        $x->{_id} = $data->{_id};
        return $x;
    }
    return undef;
}

sub first_name {
    my ($x) = @_;
    if ($x =~ m/^(\w+)\,\s*([\w\-]+)/) {
        # lastname, first
        return $2;
    }
    my ($n) = split(/\s+/, $x);
    return $n;
}

sub last_name {
    my ($x) = @_;
    if ($x =~ m/^(\w+)\,\s*([\w\-]+)/) {
        # lastname, first
        return $1;
    }
    my @n = split(/\s+/, $x);
    return $n[-1];
}
