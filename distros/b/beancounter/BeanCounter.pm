#
#  BeanCounter.pm --- A stock portfolio performance monitoring toolkit
#
#  Copyright (C) 1998 - 2010  Dirk Eddelbuettel <edd@debian.org>
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

#  $Id: BeanCounter.pm,v 1.107 2010/06/13 22:13:09 edd Exp $

package Finance::BeanCounter;

require strict;
require Exporter;

#use Carp;			# die with info on caller
use Data::Dumper;		# debugging aid
use Date::Manip;		# for date parsing
use DBI;			# for the Perl interface to the database
use English;			# friendlier variable names
use Finance::YahooQuote;	# fetch quotes from Yahoo!
use POSIX qw(strftime);		# for date formatting
use Statistics::Descriptive;	# simple statistical functions
use Text::ParseWords;		# parse .csv data more reliably

@ISA = qw(Exporter);		# make these symbols known
@EXPORT = qw(BeanCounterVersion
	     CloseDB
	     ConnectToDb
	     TestInsufficientDatabaseSchema
	     DatabaseDailyData
	     DatabaseHistoricalData
	     DatabaseHistoricalFXData
	     DatabaseHistoricalUBCFX
	     DatabaseHistoricalOandAFX
	     DatabaseInfoData
	     ExistsDailyData
	     ExistsFXDailyData
	     GetTodaysAndPreviousDates
	     GetCashData
	     GetConfig
	     GetDate
	     GetDailyData
	     GetFXData
	     GetFXDatum
             GetOandAFXData
	     GetUBCFXData
	     GetUBCFXHash
	     GetYahooCurrency
	     GetIsoCurrency
	     GetHistoricalData
	     GetPortfolioData
	     GetPriceData
	     GetRetracementData
	     GetRiskData
	     ParseDailyData
	     ParseNumeric
	     PrintHistoricalData
	     ReportDailyData
	     Sign
	     UpdateDatabase
	     UpdateFXDatabase
	     UpdateFXviaUBC 
	     UpdateTimestamp
	    );
@EXPORT_OK = qw( );
%EXPORT_TAGS = (all => [@EXPORT_OK]);

my $VERSION = sprintf("%d.%d", q$Revision: 1.107 $ =~ /(\d+)\.(\d+)/); 

my %Config;			# local copy of configuration hash


sub BeanCounterVersion {
  return $VERSION;
}


sub ConnectToDb {		# log us into the database (PostgreSQL)
  my $hoststr = '';
  $hoststr = "host=$Config{host}"
	unless (grep(/^$Config{host}$/, ('localhost','127.0.0.1','::1/128')));
  my $dsn = 'dbi:';
  if ($Config{odbc}) {
      $dsn .= "ODBC:$Config{dsn}";
  } elsif (lc $Config{dbsystem} eq "postgresql") {
      $dsn .= "Pg:dbname=$Config{dbname};${hoststr}";
  } elsif (lc $Config{dbsystem} eq "mysql") {
      $dsn .= "mysql:dbname=$Config{dbname};${hoststr}";
  } elsif (lc $Config{dbsystem} eq "sqlite") {
      $dsn .= "SQLite:dbname=$Config{dbname}";
      $Config{user} = '';
      $Config{passwd} = '';
  } elsif (lc $Config{dbsystem} eq "sqlite2") {
      $dsn .= "SQLite2:dbname=$Config{dbname}";
      $Config{user} = '';
      $Config{passwd} = '';
  } else {
    die "Database system $Config{dbsystem} is not supported\n";
  }
  my $dbh = DBI->connect($dsn, $Config{user}, $Config{passwd}, 
			 { PrintError => $Config{debug}, 
			   Warn => $Config{verbose}, 
			   AutoCommit => 0 });
  
  die "No luck with database connection\n" unless ($dbh);

  return $dbh;
}


sub CloseDB {
  my $dbh = shift;
  $dbh->disconnect or warn $dbh->errstr;
}


sub ConvertVersionToLargeInteger($) {
  my ($txt) = @_;
  my ($major,$minor,$revision) = ($txt =~ m/^([0-9]+)\.([0-9]+)\.([0-9]+)$/);
  my $numeric = $major * 1e6 + $minor * 1e3 + $revision;
  #print "[$txt] -> [$major] [$minor] [$revision] -> $numeric\n";
  return($numeric);
}


sub TestInsufficientDatabaseSchema($$) {
  my ($dbh, $required) = @_;
  my @tables = $dbh->tables();
  die "Database does not contain table beancounter. " .
    "Please run 'update_beancounter'.\n" unless grep /beancounter/, @tables;
  my $sql = q{select version from beancounter};
  my @res = $dbh->selectrow_array($sql) or die $dbh->errstr;
  my $dbschema = $res[0];
  my $num_required = ConvertVersionToLargeInteger($required);
  my $num_schema = ConvertVersionToLargeInteger($dbschema);
  print "Database has schema $dbschema, we require version $required\n" 
    if $Config{debug};
  return ($num_schema < $num_required); # extensive testing was required =:-)
}


sub GetTodaysAndPreviousDates {
  my ($date, $prev_date);
  my $today = DateCalc(ParseDate("today"), "- 8 hours");

  # Depending on whether today is a working day, use today 
  # or the most recent preceding working day
  if (Date_IsWorkDay($today)) {
    $date = UnixDate($today, "%Y%m%d");
    $prev_date = UnixDate(DateCalc($today, "- 1 business days"), "%Y%m%d");
  } else {
    $date = UnixDate(DateCalc($today, "- 1 business days"), "%Y%m%d");
    $prev_date = UnixDate(DateCalc($today, "- 2 business days"), "%Y%m%d");
  }
  # override with optional dates, if supplied
  $date      = UnixDate(ParseDate($main::datearg),    "%Y%m%d") 
    if ($main::datearg); 
  $prev_date = UnixDate(ParseDate($main::prevdatearg),"%Y%m%d") 
    if ($main::prevdatearg); 

  # and create 'prettier' non-ISO 8601 form
  my $pretty_date = UnixDate(ParseDate($date), "%d %b %Y");
  my $pretty_prev_date = UnixDate(ParseDate($prev_date), "%d %b %Y");

  return ($date, $prev_date, $pretty_date, $pretty_prev_date);
}


sub GetConfig {
  my ($file, $debug, $verbose, $fx, $extrafx, $updatedate,
      $dbsystem, $dbname, $fxupdate, $commit, $equityupdate, 
      $ubcfx, $hostarg, $command) = @_;

  %Config = ();			# reset hash

  $Config{debug} = $debug;	# no debugging as default
  $Config{verbose} = $verbose;	# silent == non-verbose as default

  $Config{odbc} = 0;		# if 1, use DBI-ODBC, else use DBI-Pg

  $Config{currency} = "USD";	# default to US dollars as domestic currency

  $Config{user} = $ENV{USER};	# default user is current user
  $Config{passwd} = undef;	# default password is no password

  $Config{dbsystem} = "PostgreSQL";
  $Config{dbname} = "beancounter";

  $Config{today} = strftime("%Y%m%d", localtime);
  ($Config{lastbizday}, $Config{prevbizday}) = GetTodaysAndPreviousDates;

  # DSN name for ODBC
  $Config{dsn} = "beancounter";	# default ODBC data source name

  # default to updating FX
  if ($fxupdate) {
    $Config{fxupdate} = 1;
  } else {
    $Config{fxupdate} = 0;
  }

  # default to committing to db
  if ($commit) {
    $Config{commit} = 1;
  } else {
    $Config{commit} = 0;
  }

  # default to updateing stocks too
  if ($equityupdate) {
    $Config{equityupdate} = 1;
  } else {
    $Config{equityupdate} = 0;
  }

  # default to updateing stocks too
  if ($ubcfx) {
    $Config{ubcfx} = 1;
  } else {
    $Config{ubcfx} = 0;
  }
  # pre-load a default host argument
  $Config{host} = $hostarg if defined($hostarg);

  unless ( -f $file ) {
    warn "Config file $file not found, ignored.\n";
  } else {
    open (FILE, "<$file") or die "Cannot open $file: $!\n";
    while (<FILE>) {
      next if (m/(\#|%)/);	# ignore comments, if any
      next if (m/^\s*$/);	# ignore empty lines, if any
      if (m/^\s*(\w+)\s*=\s*(.+)\s*$/) {
	$Config{$1} = "$2";
      }
    }
    close(FILE);
  }

  $Config{currency} = $fx if defined($fx);

  $Config{dbname} = $dbname if defined($dbname);
  $Config{dbsystem} = $dbsystem if defined($dbsystem);
  $Config{odbc} = 1 if defined($dbsystem) and lc $dbsystem eq "odbc";

  # but allow command-line argument to override 
  $Config{host} = $hostarg 	
      if defined($hostarg) and $hostarg ne "localhost";	


  if (defined($extrafx)) {
    unless ($command =~ /^(update|dailyjob)$/) {
      warn "Warning: --extrafx ignored as not updating db\n";
    } else {
      $Config{extrafx} = $extrafx if defined($extrafx);
    }
  }

  if (defined($updatedate)) {	# test the updatedate argument 
    unless ($command =~ /^(update|dailyjob)$/) {
      warn "Warning: --updatedate ignored as not updating db\n";
    } else {
      die "Error: Invalid date $updatedate for --forceupdate\n"
	unless (ParseDate($updatedate));
      $Config{updatedate} =  UnixDate(ParseDate($updatedate),"%Y%m%d");
    }
  }

  print Dumper(\%Config) if $Config{debug};
  return %Config;
}


sub GetCashData {
  my ($dbh, $date, $res) = @_;
  my ($stmt, $sth, $rv, $ary_ref, $sym_ref, %cash);
  my ($name, $value, $fx, $cost);
  # get the symbols
  $stmt  = "select name, value, currency, cost from cash ";
  $stmt .= "where value > 0 ";
  $stmt .= "and $res " if ( defined($res)
			    and $res =~ m/(name|value|currency|cost|owner)/i
			    and not $res =~ m/(symbol|shares|exchange|day)/i
			  );
  $stmt .= "order by name";
  print "GetCashData():\n\$stmt = $stmt\n" if $Config{debug};

  $sth = $dbh->prepare($stmt);
  $rv = $sth->execute(); 	# run query for report end date
  while (($name, $value, $fx, $cost) = $sth->fetchrow_array) {
    $cash{$name}{value} += $value; # adds if there are several
    $cash{$name}{fx} = $fx;
    $cash{$name}{cost} = $cost;
  }
  $sth->finish();
  return(\%cash);
}


sub GetDailyData {		# use Finance::YahooQuote::getquote
  # This uses the 'return an entire array' approach of Finance::YahooQuote.
  my @Args = @_;

  if (defined($Config{proxy})) {
    $Finance::YahooQuote::PROXY = $Config{proxy};
  }
  if (defined($Config{firewall}) and
      $Config{firewall} ne "" and 
      $Config{firewall} =~ m/.*:.*/) {
    my @q = split(':', $Config{firewall}, 2);
    $Finance::YahooQuote::PROXYUSER = $q[0];
    $Finance::YahooQuote::PROXYPASSWD = $q[1];
  }
  if (defined($Config{timeout})) {
    $Finance::YahooQuote::TIMEOUT = $Config{timeout} if $Config{timeout};
  }

  #my $url = "http://quote.yahoo.com/d" .
  #  "?f=snl1d1t1c1p2va2bapomwerr1dyj1x&s=";
  #my $array = GetQuote($url,@NA); # get all North American quotes
  my $array = getquote(@Args);	# get North American quotes
  my @Res;
  push @Res, (@$array);	# and store the entire array of arrays 
  print Dumper(\@Res) if $Config{debug};
  return @Res;
}


## Simple routine to get quotes for an array of arguments
BEGIN { use HTTP::Request::Common; }
sub GetUBCFXData {
  my ($symbolsref, $from, $to) = @_;

  my @symbols = @$symbolsref;
  my $nsym = $#symbols + 1;

  my $base = $Config{currency};	# instead of unconditionally requesting USD

  ## we need the dates as yyyy, mm and dd
  my ($fy,$fm,$fd,$ty,$tm,$td);	
  ($fy,$fm,$fd) = ($from =~ m/(\d\d\d\d)(\d\d)(\d\d)/);
  ($ty,$tm,$td) = ($to =~ m/(\d\d\d\d)(\d\d)(\d\d)/);

  ## build the query URL
  my $url = "http://fx.sauder.ubc.ca/cgi/fxdata?b=$base&";
  $url .= "ld=$td&lm=$tm&ly=$ty&fd=$fd&fm=$fm&fy=$fy&";
  $url .= "daily&q=volume&f=csv&o=T.C";
  $url .= "&c=" . join("&c=", @symbols);
  print "Url is $url\n" if $Config{debug};

  my @qr;			# results will be collected here
  my $ua = RequestAgent->new;
  $ua->env_proxy;		# proxy settings from *_proxy env. variables.
  $ua->proxy('http', $PROXY) if defined $PROXY;
  $ua->timeout($TIMEOUT) if defined $TIMEOUT;

  foreach (split('\015?\012',$ua->request(GET $url)->content)) {
    ## skip the commercials / copyrights / attributions
    next if $_ =~ m/(PACIFIC|Prof\. Werner Antweiler)/;
    print "--> $_\n" if $Config{debug};
    ## split the csv stream with quotewords() from Text::ParseWords
    my @q = quotewords(',', 0, $_);
    my @fx = splice(@q, -$nsym); # last $nsym are the quotes
    push (@qr, [$q[1], @fx]);
    print $q[1], " ", join(" ", @fx), "\n" if $Config{debug};
  }

  return \@qr;
}


## wrapper for single-day hash of currencies
sub GetUBCFXHash {
  my ($symref, $date) = @_;

  my $res = GetUBCFXData($symref, $date, $date);

  my @symbols = @$symref;
  my $nsym = $#symbols + 1;
  
  ## format is like
  ##   YYYY/MM/DD CAD/USD GBP/USD
  ##   2005/01/31 1.2380 0.53087
  ## so loop over all columns but first
  my %res;
  for (my $i=0; $i<$nsym; $i++) { 
    ## the currency comes as, e.g., CAD/USD so split the CAD part of
    my $cur = (split(/\//, $res->[0]->[$i+1]))[0];
    print $cur, "\t" , $res->[1]->[$i+1], "\n" if $Config{debug};
    ## and value is matching entry in second row
    $res{$cur} = $res->[1]->[$i+1];
  }
  return \%res;			# return the new hash
}


## get FX data from OandA.com
sub GetOandAFXData {
  my ($symbol, $from, $to) = @_;

  my $base = $Config{currency};	# instead of unconditionally requesting USD

  ## we need the dates as yyyy, mm and dd
  my ($fy,$fm,$fd,$ty,$tm,$td);	
  ($fy,$fm,$fd) = ($from =~ m/(\d\d\d\d)(\d\d)(\d\d)/);
  ($ty,$tm,$td) = ($to =~ m/(\d\d\d\d)(\d\d)(\d\d)/);

  ## build the query URL
  my $url = "http://www.oanda.com/convert/fxhistory?lang=en&";
  $url .= "date1=$fm%2F$fd%2F$fy&";
  $url .= "date=$tm%2F$td%2F$ty&date_fmt=us&";
  $url .= "exch=$symbol&exch2=&expr=$Config{currency}&expr2=";
  $url .= "&margin_fixed=0&SUBMIT=Get+Table&format=CSV&redirected=1";
  print "Url is $url\n" if $Config{debug};

  my @qr;			# results will be collected here
  my $ua = RequestAgent->new;
  $ua->env_proxy;		# proxy settings from *_proxy env. variables.
  $ua->proxy('http', $PROXY) if defined $PROXY;
  $ua->timeout($TIMEOUT) if defined $TIMEOUT;

  my $state = 0;
  foreach (split('\015?\012',$ua->request(GET $url)->content)) {
    my $line = $_;
    if ($state == 0) {
      if ($_ =~ m|<PRE>|) {
	$state += 1;
	$line =~ s|<PRE>||;
      }	    
      #next;
    }
    if ($state == 1) {
      $state += 1 if $_ =~ m|</PRE>|;
      #next;
    }
    next unless $state == 1;
    #print "--> $_\n" if $Config{debug};
    #$state = $_ !~ m|</PRE>|;
    ## split the csv stream with quotewords() from Text::ParseWords
    #my @q = quotewords(',', 0, $_);
    #my @fx = splice(@q, -$nsym); # last $nsym are the quotes
    #push (@qr, [$q[1], @fx]);
    #print $q[1], " ", join(" ", @fx), "\n" if $Config{debug};

    push (@qr, $line);
    print $line, "\n" if $Config{debug};
  }

  return \@qr;

}

sub getIso2YahooCurrencyHashRef() {
    # map between ISO country codes and Yahoo symbols for the Philly exchange
    return {"AUD" => "^XAY", # was "^XAD", "AUDUSD=X",
	    "CAD" => "^XCV", # was "^XCD", "CADUSD=X",
	    "CHF" => "^XSY", # was "^XSF", "CHFUSD=X",
	    "EUR" => "^XEU", # was "EURUSD=X",
	    "GBP" => "^XBX", # was "^XBP", "GBPUSD=X",
	    "JPY" => "^XJZ", # was "^XJY", "JPYUSD=X",
	    "USD" => "----"};
}


sub GetYahooCurrency($) {
    my ($isoCurrency) = @_;
    my $ref = getIso2YahooCurrencyHashRef();
    return $ref->{$isoCurrency};
}


sub GetIsoCurrency($) {
    my ($yahooCurrency) = @_;
    my $ref = getIso2YahooCurrencyHashRef();
    # Reverse the hash table, ie. yahoo => iso:
    my %yahoo2isoHash = map { $ref->{$_} => $_ } keys(%$ref);
    return $yahoo2isoHash{$yahooCurrency};
}


sub GetHistoricalData {		# get a batch of historical quotes from Yahoo!
  my ($symbol,$from,$to) = @_;
  my $ua = RequestAgent->new;
  $ua->env_proxy;		# proxy settings from *_proxy env. variables.
  $ua->proxy('http', $Config{proxy}) if $Config{proxy};  # or config vars
  my ($a,$b,$c,$d,$e,$f);	# we need the date as yyyy, mm and dd
  ($c,$a,$b) = ($from =~ m/(\d\d\d\d)(\d\d)(\d\d)/);
  ($f,$d,$e) = ($to =~ m/(\d\d\d\d)(\d\d)(\d\d)/);
  --$a; --$d; # month is zero-based
  my $req = new HTTP::Request GET => "http://table.finance.yahoo.com/" .
    "table.csv?a=$a&b=$b&c=$c&d=$d&e=$e&f=$f&s=$symbol&y=0&g=d&ignore=.csv";
  my $res = $ua->request($req);  # Pass request to user agent and get response
  if ($res->is_success) {	# Check the outcome of the response
    return split(/\n/, $res->content);
  } else {
    warn "No luck with symbol $symbol\n";
  }
}


sub GetPortfolioData {
  my ($dbh, $res) = @_;
  my ($stmt, $sth);

  # get the portfolio data
  $stmt  = "select symbol, shares, currency, type, owner, cost, date ";
  $stmt .= "from portfolio ";
  $stmt .= "where $res" if (defined($res));
  print "GetPortfolioData():\n\$stmt = $stmt\n" if $Config{debug};

  $sth = $dbh->prepare($stmt);
  $sth->execute();
  my $data_ref = $sth->fetchall_arrayref({});
  return $data_ref;
}


sub GetPriceData {
  my ($dbh, $date, $res) = @_;
  my ($stmt, $sth, $rv, $ary_ref, @symbols, %dates);
  my ($ra, $symbol, $name, $shares, $currency, $price, $prevprice,
      %prices, %prev_prices, %shares, %fx, %name, %purchdate, %cost,
      $cost,$pdate,%pricedate);

  # get the symbols
  $stmt  = "select distinct p.symbol from portfolio p, stockinfo s ";
  $stmt .= "where s.symbol = p.symbol and s.active ";
  $stmt .= qq{and p.symbol in
	      (select distinct symbol from portfolio where $res)
	     }   if (defined($res));
  $stmt .= "order by p.symbol";
  print "GetPriceData():\n\$stmt = $stmt\n" if $Config{debug};

  # get symbols
  @symbols = @{ $dbh->selectcol_arrayref($stmt) };

  # for each symbol, get most recent date subject to supplied date
  $stmt  = qq{select max(date)
	      from stockprices 
	      where symbol = ? 
	      and day_close > 0
	      and date <= ?
	     };
  print "GetPriceData():\n\$stmt = $stmt\n" if $Config{debug};

  # for each symbol, get most recent date subject to supplied date:\n";
  foreach $ra (@symbols) {	
    if (!defined($sth)) {
      $sth = $dbh->prepare($stmt);
    }
    $rv = $sth->execute($ra, $date); # run query for report end date
    my $res = $sth->fetchrow_array;
    $dates{$ra} = $res;
    $sth->finish() if $Config{odbc};
  }

#sum(p.shares*p.cost)/sum(p.shares) as p.cost, 
  # now get closing price etc at date
  $stmt =    qq{select i.symbol, i.name, p.shares, p.currency,
		       d.day_close, 
		       p.cost, 
		       p.date, 
		       d.previous_close
		from stockinfo i, portfolio p, stockprices d
		where d.symbol = p.symbol
		and i.symbol = d.symbol
		and d.date = ?
		and d.symbol = ?
	       };

  #### TWA, 2003-12-04
  ## According to the original code, here the restriction applies to the 
  ## portfolio table only. But _note_:
  ##   the same restriction is used in GetRiskData() !!!!
  ##   the same restriction is used in GetRetracementData() !!!!
  ## But it is not enough to restrict the symbols used by the sub-select 
  ## command. One has to restrict the main selection with the same 
  ## restriction rules.
  ## Thus, make a copy of the restriction and replace the column names 
  ## to a syntax to use the portfolio table only.
  if (defined($res)) {
    ## avoid name space pollution
    my $portfolio_restriction = $res;

    $portfolio_restriction =~ s/\bsymbol\b/p\.symbol/g;
    $portfolio_restriction =~ s/\bshares\b/p\.shares/g;
    $portfolio_restriction =~ s/\bcurrency\b/p\.currency/g;
    $portfolio_restriction =~ s/\btype\b/p\.type/g;
    $portfolio_restriction =~ s/\bowner\b/p\.owner/g;
    $portfolio_restriction =~ s/\bcost\b/p\.cost/g;
    $portfolio_restriction =~ s/\bdate\b/p\.date/g;

    $stmt .= qq{ and $portfolio_restriction }
  }				# end if (defined($res))

  $stmt .= qq{ and d.symbol in
	      (select distinct symbol from portfolio where $res)
	     }   if (defined($res));
##  $stmt .= qq{ group by 	      i.symbol,i.name,p.shares,p.currency,d.day_close,p.date,d.previous_close };

#select symbol, avg('today'-date) as days, sum(shares*cost)/sum(shares) as cost, sum(shares) as size, sum(shares*cost) as pos from portfolio where owner!='peter' group by symbol order by days desc;
  print "GetPriceData():\n\$stmt = $stmt\n" if $Config{debug};

  # now get closing price etc at date
  $sth = undef;
  my $i = 0;
  foreach $ra (@symbols) {		
    if (!defined($sth)) {
      $sth = $dbh->prepare($stmt);
    }
    $rv = $sth->execute($dates{$ra}, $ra);
    while (($symbol, $name, $shares, $currency, $price, 
	    $cost, $pdate, $prevprice) = $sth->fetchrow_array) {
      print join " ", ($symbol, $name, $shares, 
		       $currency, $price, 
		       $cost||"NA", $pdate||"NA", 
		       $prevprice||"NA"), "\n" if $Config{debug};
      $fx{$name} = $currency;	
      $prices{$name} = $price;
      $pricedate{$name} = $dates{$symbol};
      $cost{$name} = $cost;
      $purchdate{$name} = $pdate;
      $prev_prices{$name} = $prevprice;
      $name .= ":$i";
      $i++;
      $shares{$name} = $shares;
      $purchdate{$name} = $pdate; # also store purchuse date on non-aggregate entry
      $cost{$name} = $cost;	  # also store purchuse cost on non-aggregate entry
    }
    $sth->finish;
  }

  print Dumper(\%prices) if $Config{debug};
  print Dumper(\%prev_prices)  if $Config{debug};
  print Dumper(\%shares) if $Config{debug};

  return (\%fx, \%prices, \%prev_prices, \%shares, \%pricedate, 
	  \%cost, \%purchdate);
}


sub GetFXData {
  my ($dbh, $date, $fx) = @_;
  ## find FX data from closest date smaller or equal to the requested date

  # for each symbol, get most recent date subject to supplied date
  my $stmt  = qq{select max(date)
	      from fxprices
	      where currency = ?
	      and date <= ?
	     };
  print "GetFXData():\n\$stmt = $stmt\n" if $Config{debug};

  # get most recent date subject to supplied date
  my %fxdates;
  my $sth;
  foreach my $fxval (sort values %$fx) {
    next if $fxval eq $Config{currency};# skip user's default currency
    if (!defined($sth)) {
      $sth = $dbh->prepare($stmt);
    }
    $rv = $sth->execute($fxval, $date); # run query for report end date
    my $res = $sth->fetchrow_array;
    $fxdates{$fxval} = $res;
    $sth->finish() if $Config{odbc};
  }

  $stmt = qq{ select day_close, previous_close from fxprices 
	      where date = ?
	      and currency = ?
	    };
  print "GetFXData():\n\$stmt = $stmt\n" if $Config{debug};

  $sth = undef;
  my (%fx_prices,%prev_fx_prices);
  foreach my $fxval (sort values %$fx) {
    if ($fxval eq $Config{currency}) {	
      $fx_prices{$fxval} = 1.0;
      $prev_fx_prices{$fxval} = 1.0;
    } else {
      if (!defined($sth)) {
        $sth = $dbh->prepare($stmt);
      }
      $sth->execute($fxdates{$fxval}, $fxval);	# run query for FX cross
      my ($val, $prevval) = $sth->fetchrow_array
	or die "Found no $fxval for $date in the beancounter database.\n " .
	  "Use the --date and/or --prevdate options to pick another date.\n";
      $fx_prices{$fxval} = $val;
      $prev_fx_prices{$fxval} = $prevval;
      if (Date_Cmp(ParseDate($fxdates{$fxval}), ParseDate($date)) !=0) {
	print "Used FX date $fxdates{$fxval} instead of $date\n" 
	  if $Config{verbose};
      }
      my $ary_ref = $sth->fetchall_arrayref;
    }
  }
  return (\%fx_prices, \%prev_fx_prices);
}

## simple wrapper for GetFXDate for single currency + date
sub GetFXDatum {		
  my ($dbh, $date, $fx) = @_;

  my %fxhash; 
  $fxhash{foo} = $fx;
  my ($fxcurrent) = GetFXData($dbh, $date, \%fxhash); 
  return $fxcurrent->{$fx};
}

## NB no longer used as we employ Finance::YahooQuote directly
sub GetQuote {			# taken from Dj's Finance::YahooQuote
  my ($URL,@symbols) = @_;	# and modified to allow for different URL
  my ($x,@q,@qr,$ua,$url);	# and the simple filtering below as well
				# the firewall code below
  if (defined($Config{proxy})) {
    $Finance::YahooQuote::PROXY = $Config{proxy};
  }
  if (defined($Config{firewall}) and
      $Config{firewall} ne "" and 
      $Config{firewall} =~ m/.*:.*/) {
    my @q = split(':', $Config{firewall}, 2);
    $Finance::YahooQuote::PROXYUSER = $q[0];
    $Finance::YahooQuote::PROXYPASSWD = $q[1];
  }
  if (defined($Config{timeout})) {
    $Finance::YahooQuote::TIMEOUT = $Config{timeout} if $Config{timeout};
  }

  undef @qr;			# reset result structure
  while (scalar(@symbols) > 0) {# while we have symbols to query
    my (@symbols_100);		# Peter Kim's patch to batch 100 at a time
    if (scalar(@symbols)>=100) {# if more than hundred symbols left
      @symbols_100 = splice(@symbols,0,100); # then skim the first 100 off
    } else {			# otherwise
      @symbols_100 = @symbols;	# take what's left
      @symbols = ();		# and show we're done
    }

    my $array = getquote(@symbols_100);	# get quotes using Finance::YahooQ.
    push(@qr,[@array]);		# and store result as anon array

  }
  return \@qr;			# return a pointer to the results array
}


sub GetRetracementData {
  my ($dbh,$date,$prevdate,$res,$fx_prices) = @_;

  my (%high52, %highprev, %low52, %lowprev);

  # get the symbols
  my $stmt  = qq{select distinct p.symbol, i.name, p.shares, p.date
		 from portfolio p, stockinfo i
		 where p.symbol = i.symbol
		 and i.active };

  #### TWA, 2003-12-07
  ## According to the original code, here the restriction applies to the 
  ## portfolio table only. But _note_:
  ##   the same restriction is used in GetPriceData() !!!!
  ## But it is not enough to restrict the symbols used by the sub-select 
  ## command. One has to restrict the main selection with the same 
  ## restriction rules.
  ## Thus, make a copy of the restriction and replace the column names 
  ## to a syntax to use the portfolio table only.
  if (defined($res)) {
    ## avoid name space pollution
    my $portfolio_restriction = $res;

    $portfolio_restriction =~ s/\bsymbol\b/p\.symbol/g;
    $portfolio_restriction =~ s/\bshares\b/p\.shares/g;
    $portfolio_restriction =~ s/\bcurrency\b/p\.currency/g;
    $portfolio_restriction =~ s/\btype\b/p\.type/g;
    $portfolio_restriction =~ s/\bowner\b/p\.owner/g;
    $portfolio_restriction =~ s/\bcost\b/p\.cost/g;
    $portfolio_restriction =~ s/\bdate\b/p\.date/g;

    $stmt .= qq{ and $portfolio_restriction }
  }				# end if (defined($res))

  $stmt .= qq{and p.symbol in
	      (select distinct symbol from portfolio where $res)
	     }   if (defined($res));
  $stmt .= "order by p.symbol";

  print "GetRetracementData():\n\$stmt = $stmt\n" if $Config{debug};

  my $sth = $dbh->prepare($stmt);
  my $rv = $sth->execute(); 	# run query for report end date
  my $sref = $sth->fetchall_arrayref;

#   # get static 52max from stockinfo
#   $stmt  = qq{select high_52weeks, low_52weeks 
# 	      from stockinfo where symbol = ?};
#   $sth = $dbh->prepare($stmt);
#   foreach my $ra (@$sref) {
#     $rv = $sth->execute($ra->[0]);
#     my @res = $sth->fetchrow_array; 	# get data
#     $high52{$ra->[1]} = $res[0];
#     $low52{$ra->[1]} = $res[1];
#   }

  # get max/min over prevate .. date period
  $stmt  = qq{select day_close 
	      from stockprices 
	      where symbol = ? 
	      and date <= ? 
	      and date >= ?
	      and day_close > 0
	      order by date
	     };

  print "GetRetracementData():\n\$stmt = $stmt\n" if $Config{debug};

  $sth = $dbh->prepare($stmt);
  foreach my $ra (@$sref) {
    my $refdate = $prevdate;	# start from previous date
    if (defined($ra->[3])) {	# if startdate in DB
      ## then use it is later then the $prevdate
      $refdate = $ra->[3] if (Date_Cmp($prevdate, $ra->[3]) < 0)
    }
    $rv = $sth->execute($ra->[0], $date, $refdate);
    my $dref = $sth->fetchall_arrayref;	# get data
    my $x = Statistics::Descriptive::Full->new();
    for (my $i=0; $i<scalar(@{$dref}); $i++) { 
      $x->add_data($dref->[$i][0]); # add prices
    }
    $highprev{$ra->[1]} = $x->max();
    $lowprev{$ra->[1]} = $x->min();
  }

#  return (\%high52, \%highprev, \%low52, \%lowprev);
  return (\%highprev, \%lowprev);
}


sub GetRiskData {
  my ($dbh,$date,$prevdate,$res,$fx_prices,$crit) = @_;

  # get the symbols
  my $stmt  = qq{select distinct p.symbol, i.name
		 from portfolio p, stockinfo i
		 where p.symbol = i.symbol
		 and i.active };

  #### TWA, 2003-12-07
  ## According to the original code, here the restriction applies to the 
  ## portfolio table only. But _note_:
  ##   the same restriction is used in GetPriceData() !!!!
  ## But it is not enough to restrict the symbols used by the sub-select 
  ## command. One has to restrict the main selection with the same 
  ## restriction rules.
  ## Thus, make a copy of the restriction and replace the column names 
  ## to a syntax to use the portfolio table only.
  if (defined($res)) {
    ## avoid name space pollution
    my $portfolio_restriction = $res;

    $portfolio_restriction =~ s/\bsymbol\b/p\.symbol/g;
    $portfolio_restriction =~ s/\bshares\b/p\.shares/g;
    $portfolio_restriction =~ s/\bcurrency\b/p\.currency/g;
    $portfolio_restriction =~ s/\btype\b/p\.type/g;
    $portfolio_restriction =~ s/\bowner\b/p\.owner/g;
    $portfolio_restriction =~ s/\bcost\b/p\.cost/g;
    $portfolio_restriction =~ s/\bdate\b/p\.date/g;

    $stmt .= qq{ and $portfolio_restriction }
  }				# end if (defined($res))

  $stmt .= qq{and p.symbol in
	      (select distinct symbol from portfolio where $res)
	     }   if (defined($res));
  $stmt .= "order by p.symbol";

  print "GetRiskData():\n\$stmt = $stmt\n" if $Config{debug};

  my $sth = $dbh->prepare($stmt);
  my $rv = $sth->execute(); 	# run query for report end date
  my $sref = $sth->fetchall_arrayref;

  # compute volatility
  $stmt  = qq{select day_close 
	      from stockprices 
	      where symbol = ? 
	      and date <= ? 
	      and date >= ?
	      and day_close > 0
	      order by date
	     };

  print "GetRiskData():\n\$stmt = $stmt\n" if $Config{debug};

  $sth = $dbh->prepare($stmt);
  my (%vol, %quintile);
  foreach my $ra (@$sref) {
    $rv = $sth->execute($ra->[0], $date, $prevdate);
    my $dref = $sth->fetchall_arrayref;	# get data
    my $x = Statistics::Descriptive::Full->new();
    for (my $i=1; $i<scalar(@{$dref}); $i++) { # add returns
      $x->add_data($dref->[$i][0]/$dref->[$i-1][0] - 1);
    }
    printf("%16s: stdev %6.2f min %6.2f max %6.2f\n",
	   $ra->[1], $x->standard_deviation, $x->min, $x->max)
      if $Config{debug};
    $vol{$ra->[1]} = $x->standard_deviation;
    if ($x->count() < 100) {
      print "$ra->[1]: Only ", $x->count(), " data points, ",
      	"need at least 100 for percentile calculation\n" if $Config{debug};
      $quintile{$ra->[1]} = undef;
    } else {
      $quintile{$ra->[1]} = $x->percentile(1);
    }
  }

  # compute correlations via OLS regression
  $stmt  = qq{select a.day_close, b.day_close 
	      from stockprices a, stockprices b
	      where a.symbol = ? and b.symbol = ? 
	      and a.date <= ? and a.date >= ?
	      and a.date = b.date
	      and a.day_close != 0 
	      and b.day_close != 0 
	      order by a.date
	     };

  print "GetRiskData():\n\$stmt = $stmt\n" if $Config{debug};

  $sth = $dbh->prepare($stmt);
  my %cor;
  foreach my $ra (@$sref) {		
    foreach my $rb (@$sref) {
      my $res = $ra->[0] cmp $rb->[0];
      if ($res < 0) {
	$rv = $sth->execute($ra->[0], $rb->[0], $date, $prevdate);
	my $dref = $sth->fetchall_arrayref;	# get data
	my $x = Statistics::Descriptive::Full->new();
	my $y = Statistics::Descriptive::Full->new();
	for (my $i=1; $i<scalar(@{$dref}); $i++) { # add returns
	  $x->add_data($dref->[$i][0]/$dref->[$i-1][0] - 1);
	  $y->add_data($dref->[$i][1]/$dref->[$i-1][1] - 1);
	}
	my @arr = $x->least_squares_fit($y->get_data());
	my $rho = $arr[2];
	unless (defined($rho)) {
	  warn "No computable correlation between $ra->[1] and $rb->[1];"
	    . " set to 0\n";
	  $rho = 0.0;
	}
	$cor{$ra->[1]}{$rb->[1]} = $rho;
	printf("%6s %6s correlation %6.4f\n", 
	       $ra->[1], $rb->[1], $arr[2]) if $Config{debug}; 
      } elsif ($res > 0) {
	$cor{$ra->[1]}{$rb->[1]} = $cor{$rb->[1]}{$ra->[1]};
      } else {
	$cor{$ra->[1]}{$rb->[1]} = 1;
      }
    }
  }

  # for each symbol, get most recent date subject to supplied date
  my %maxdate;
  $stmt  = qq{select max(date) 
	      from stockprices 
	      where symbol = ? 
	      and date <= ?
	     };

  print "GetRiskData():\n\$stmt = $stmt\n" if $Config{debug};

  $sth = $dbh->prepare($stmt);
  foreach my $ra (@$sref) {		
    $rv = $sth->execute($ra->[0], $date); # run query for report end date
    my $res = $sth->fetchrow_array;
    $maxdate{$ra->[1]} = $res;
    $sth->finish() if $Config{odbc};
  }

  # get position values
  my (%pos, $possum);
  $stmt =    qq{select p.shares, d.day_close, p.currency
 		from portfolio p, stockprices d, stockinfo i
 		where d.symbol = p.symbol 
 		and d.symbol = i.symbol 
 		and d.date = ?
 		and d.symbol = ?
 	       };
  $stmt .= qq{and d.symbol in
	      (select distinct symbol from portfolio where $res)
	     }   if (defined($res));

  print "GetRiskData():\n\$stmt = $stmt\n" if $Config{debug};

  $sth = $dbh->prepare($stmt);
  foreach my $ra (@$sref) {		
    $rv = $sth->execute($maxdate{$ra->[1]}, $ra->[0]); 
    while (my ($shares, $price, $fx) = $sth->fetchrow_array) {
      print "$ra->[1] $shares $price\n" if $Config{debug};
      my $amount = $shares * $price *
	$fx_prices->{$fx} / $fx_prices->{$Config{currency}};
      $pos{$ra->[1]} += $amount;
    }
  }

  # aggregate risk: 
  # VaR is z_crit * sqrt(horizon) * sqrt (X.transpose * Sigma * X)
  # where X is position value vector and Sigma the covariance matrix
  # given that Perl is not exactly a language for matrix calculus (as
  # eg GNU Octave), we flatten the computation into a double loop
  my $sum = 0;
  foreach my $pkey (keys %pos) {
    if (defined($pos{$pkey}) && defined($vol{$pkey})) {
      foreach my $vkey (keys %vol) { 
	if (defined($pos{$vkey}) && defined($vol{$vkey}) &&
	    defined($cor{$vkey}{$pkey})) {
	  $sum += $pos{$pkey} * $pos{$vkey} * $vol{$vkey} * $vol{$pkey} * 
	    $cor{$vkey}{$pkey};
        }
      }
    }
  }
  my $var = $crit * sqrt($sum);


  ## marginal var
  my %margvar;
  foreach my $outer (keys %pos) {
    my $saved = $pos{$outer};
    my $sum = 0;
    $pos{$outer} = 0;
    foreach my $pkey (keys %pos) {
      if (defined($pos{$pkey}) && defined($vol{$pkey})) {
        foreach my $vkey (keys %vol) { 
	  if (defined($pos{$vkey}) && defined($vol{$vkey}) &&
	      defined($cor{$vkey}{$pkey})) {
            $sum += $pos{$pkey} * $pos{$vkey} * $vol{$vkey} * $vol{$pkey} 
	            * $cor{$vkey}{$pkey};
	  }
	}
      }
    }
    $margvar{$outer} = $crit * sqrt($sum) - $var;
    $pos{$outer} = $saved;
  }

  return ($var, \%pos, \%vol, \%quintile, \%margvar);
}


sub DatabaseDailyData {		# a row to the dailydata table
  my ($dbh, %hash) = @_;
  my @cols = ('previous_close', 'day_open', 'day_high', 'day_low',
	      'day_close', 'day_change', 'bid', 'ask', 'volume');
  my @updTerms = ();
  foreach my $col (@cols) {
    push(@updTerms, "$col = ?");
  }
  my $updStmt = 'update stockprices set ' . join(', ', @updTerms) .
      ' where symbol = ? and date = ?';
  print "$updStmt\n" if $Config{debug};
  my $updSth;

  push(@cols, 'symbol', 'date');
  my @insTerms = ();
  foreach my $col (@cols) {
    push(@insTerms, '?');
  }
  my $insStmt = 'insert into stockprices (' . join(', ', @cols) .
      ') values (' . join(', ', @insTerms) . ')';
  print "$insStmt\n" if $Config{debug};
  my $insSth;
  
  foreach my $key (keys %hash) { # now split these into reference to the arrays
    print "$hash{$key}{symbol} " if $Config{verbose};

    if ($hash{$key}{date} eq "N/A") {
      warn "Not databasing $hash{$key}{symbol}\n" if $Config{debug};
      next;
    }

    if (ExistsDailyData($dbh, %{$hash{$key}})) {
      my @vals = ();
      foreach my $col (@cols) {
	  if ($hash{$key}{$col} =~ m/^\s*N\/A\s*$/) {
	      push(@vals, undef);
	  } else {
	      push(@vals, $hash{$key}{$col});
	  }
      }
      if ($Config{commit}) {
          if (!defined($updSth)) {
              $updSth = $dbh->prepare($updStmt) or die $dbh->errstr;
          }
          $updSth->execute(@vals)
              and $updSth->finish()
              or warn $dbh->errstr . "Update failed for " .
	      	"$hash{$key}{symbol} with [$updStmt]\n";
      }
    }
    else {
      my @vals = ();
      foreach my $col (@cols) {
	  if ($hash{$key}{$col} =~ m/^\s*N\/A\s*$/) {
	      push(@vals, undef);
	  } else {
	      push(@vals, $hash{$key}{$col});
	  }
      }
      if ($Config{commit}) {
          if (!defined($insSth)) {
              $insSth = $dbh->prepare($insStmt) or die $dbh->errstr;
          }
          $insSth->execute(@vals)
              and $insSth->finish()
              or warn $dbh->errstr . "Insert failed for " .
	      	"$hash{$key}{symbol} with [$insStmt]\n";
      }
    }
  }
  $dbh->commit() if $Config{commit};
}


sub DatabaseFXDailyData {
  my ($dbh, %hash) = @_;
  foreach my $key (keys %hash) { # now split these into reference to the arrays
    if ($key eq "") {
 	print "Empty key in DatabaseFXDailyData, skipping\n" if $Config{debug};
	next;
    }
    my $fx = GetIsoCurrency($hash{$key}{symbol});
    print "$fx ($hash{$key}{symbol})  " if $Config{debug};
    if (ExistsFXDailyData($dbh, $fx, %{$hash{$key}})) {
      # different sequence of parameters, see SQL statement above!
      my $stmt = qq{update fxprices
                    set previous_close = ?,
                        day_open       = ?,
                        day_low        = ?,
                        day_high       = ?,
                        day_close      = ?,
                        day_change     = ?
                  where currency       = ?
                    and date           = ?
                };

      print "DatabaseFXDailyData():\n\$stmt = $stmt\n" if $Config{debug};
      print "DatabaseFXDailyData(): $hash{$key}{previous_close},
	 $hash{$key}{day_open}, $hash{$key}{day_low}, $hash{$key}{day_high}, 
         $hash{$key}{day_close}, $hash{$key}{day_change}, 
         $fx, $hash{$key}{date} \n" if $Config{debug};

      if ($Config{commit}) {
	$dbh->do($stmt, undef, $hash{$key}{previous_close},
		 $hash{$key}{day_open},
		 $hash{$key}{day_low},
		 $hash{$key}{day_high},
		 $hash{$key}{day_close},
		 $hash{$key}{day_change},
		 $fx,
		 $hash{$key}{date}
		)
	  or warn "Failed for $fx at $hash{$key}{date}\n";
      }

      ## Alternate FX using the EURUSD=X quotes which don;t have history
#       my $stmt = qq{update fxprices
#                     set day_close      = ?
#                   where currency       = ?
#                     and date           = ?
#                 };

#       print "DatabaseFXDailyData():\n\$stmt = $stmt\n" if $Config{debug};
#       print "DatabaseFXDailyData(): ",
#	 "$hash{$key}{day_close}, $fx, $hash{$key}{date} \n" if $Config{debug};

#      if ($Config{commit}) {
#	$dbh->do($stmt, undef,
#		 $hash{$key}{day_close},
#		 $fx,
#		 $hash{$key}{date}
#		)
#	  or warn "Failed for $fx at $hash{$key}{date}\n";
#      }
    } else {
      my $stmt = qq{insert into fxprices values (?, ?, ?, ?, ?, ?, ?, ?);};

      print "DatabaseFXDailyData():\n\$stmt = $stmt\n" if $Config{debug};
      print "DatabaseFXDailyData(): $fx, $hash{$key}{date},
         $hash{$key}{previous_close},
	 $hash{$key}{day_open}, $hash{$key}{day_low}, $hash{$key}{day_high}, 
         $hash{$key}{day_close}, $hash{$key}{day_change},
           \n" if $Config{debug};

      if ($Config{commit}) {
	my $sth = $dbh->prepare($stmt);
	$sth->execute($fx,
		      $hash{$key}{date},
		      $hash{$key}{previous_close},
		      $hash{$key}{day_open},
		      $hash{$key}{day_low},
		      $hash{$key}{day_high},
		      $hash{$key}{day_close},
		      $hash{$key}{day_change}
		     )
	  or warn "Failed for $fx at $hash{$key}{date}\n";
      }

      ## Alternate FX using the EURUSD=X quotes which don;t have history
#       my $stmt = qq{insert into fxprices values (?, ?, ?, ?, ?, ?, ?, ?);};

#       print "DatabaseFXDailyData():\n\$stmt = $stmt\n" if $Config{debug};
#       print "DatabaseFXDailyData(): $fx, $hash{$key}{date},", 
# 	"$hash{$key}{day_close}\n" if $Config{debug};

#       if ($Config{commit}) {
# 	my $sth = $dbh->prepare($stmt);
# 	$sth->execute($fx, $hash{$key}{date},
# 		      undef, undef, undef, undef,
# 		      $hash{$key}{day_close}, undef
# 		     )
# 	  or warn "Failed for $fx at $hash{$key}{date}\n";
#       }
    }
    if ($Config{commit}) {
      $dbh->commit();
    }
  }
}


sub DatabaseHistoricalData {
  my ($dbh, $symbol, @res) = @_;
  $symbol = uc $symbol;		# make sure symbols are uppercase'd

  my %data = (symbol    => $symbol,
	      date      => undef,
	      day_open  => undef, 
	      day_high  => undef,
	      day_low   => undef, 
	      day_close => undef,
	      volume    => undef);

  my @colNames = sort(keys(%data));
  my @colRepl = ();
  my @updTerms = ();
  foreach my $col (@colNames) {
      push(@colRepl, '?');
      next if ($col eq 'symbol' || $col eq 'date');
      push(@updTerms, "$col = ?");
  }

  my $insStmt = 'insert into stockprices (' . join(', ', @colNames) .
      ') values (' . join(', ', @colRepl) . ')';
  my $insSth;
  my $updStmt = 'update stockprices set ' . join(', ', @updTerms) .
      ' where symbol = ? and date = ?';
  my $updSth;
  print "DatabaseHistoricalData: insStmt is \"$insStmt\"\n" if $Config{debug};
  print "DatabaseHistoricalData: updStmt is \"$updStmt\"\n" if $Config{debug};
  
  foreach my $line (@res) {		# loop over all supplied symbols
    next if !defined($line);
    ($data{date}, $data{day_open}, $data{day_high},
     $data{day_low}, $data{day_close}, $data{volume},
     $data{adjclose}) = split(/\,/, $line);
    $data{date} = GetDate($data{date});
    if (defined($data{date})) {
      # If close was not supplied, we assume a mutual fund.
      # So let close be open.
      if (!defined($data{day_close})) {
	$data{day_close} = $data{day_open};
	$data{day_open} = undef;
      }
      elsif (defined($data{adjclose}) &&
	     $data{adjclose} != $data{day_close} &&
	     $data{day_close} != 0) { # process split adjustment factor
	my $split_adj = $data{adjclose} / $data{day_close};
	$data{day_open} *= $split_adj;
	$data{day_high} *= $split_adj;
	$data{day_low}  *= $split_adj;
	$data{day_close} = $data{adjclose};
      }

      if (ExistsDailyData($dbh, %data)) {
	my @colVals = ();
	foreach my $col (@colNames) {
	  next if ($col eq 'symbol' || $col eq 'date');
	  $data{$col} = 'NULL' if !defined($data{$col});
	  push(@colVals, $data{$col});
        }
	push(@colVals, $data{symbol}, $data{date});
	if (!defined($updSth)) {
	    $updSth = $dbh->prepare($updStmt) or die $dbh->errstr;
	}
	$updSth->execute(@colVals) or die $updSth->errstr;
	$updSth->finish();
      }
      else {
	my @colVals = ();
	foreach my $col (@colNames) {
	  $data{$col} = 'NULL' if !defined($data{$col});
	  push(@colVals, $data{$col});
        }
	if (!defined($insSth)) {
	    $insSth = $dbh->prepare($insStmt) or die $dbh->errstr;
	}
	$insSth->execute(@colVals) or die $insSth->errstr;
	$insSth->finish();
      }
    }
  }
  $dbh->commit() if $Config{commit};
  print "Done with $symbol\n" if $Config{verbose};
}


sub DatabaseHistoricalFXData {
  my ($dbh, $symbol, @res) = @_;
  my $checked = 0;		# flag to ensure not nonsensical or errors
  my %data;			# hash to store data of various completenesses

  my $cut = UnixDate(ParseDate("30-Dec-2003"), "%Y%m%d");

  my $fx = GetIsoCurrency($symbol);
  foreach $ARG (@res) {		# loop over all supplied symbols
    next if m/^<\!-- .*-->/;    # skip lines with html comments (April 2004)
    # make sure the first line of data is correct so we don't insert garbage
    if ($checked==0 and m/Date(,Open,High,Low)?,Close(,Volume)?/) {
      $checked = tr/,//;
      print "Checked now $checked\n" if $Config{verbose};
    } elsif ($checked) {
      my ($date, $open, $high, $low, $close, $volume, $cmd);
      # based on the number of elements, ie columns, we split the parsing
      if ($checked eq 5 or $checked eq 6) {
	($date, $open, $high, $low, $close, $volume) = split(/\,/, $ARG);
	$date = UnixDate(ParseDate($date), "%Y%m%d");
	%data = (symbol    => $fx,
		 date	   => $date,
		 day_open  => $open,
		 day_high  => $high,
		 day_low   => $low,
		 day_close => $close,
		 volume    => undef); # never any volume info for FX
      } else {			# no volume for indices
	print "Unknown currency format: $ARG\n";
      }

      if (Date_Cmp($date,$cut) >= 0) { # if date if on or after cutoff date
	$data{day_open}  /= 100.0;     # then scale by a hundred to match the
	$data{day_low}   /= 100.0;     # old level "in dollars" rather than the
	$data{day_high}  /= 100.0;     # new one "in cents"
	$data{day_close} /= 100.0;
      }

      # now given the data, decide whether we add new data or update old data
      if (ExistsFXDailyData($dbh,$fx,%data)) { # update data if it exists
	$cmd = "update fxprices set ";
	##$cmd .= "volume    = $data{volume},"    if defined($data{volume});
	$cmd .= "day_open  = $data{day_open},"  if defined($data{day_open});
	$cmd .= "day_low   = $data{day_low},"   if defined($data{day_low});
	$cmd .= "day_high  = $data{day_high},"  if defined($data{day_high});
	$cmd .= "day_close = $data{day_close} "   .
	        "where currency = '$data{symbol}' " .
		"and date     = '$data{date}'";
      } else {			# insert
	$cmd = "insert into fxprices (currency, date,";
	$cmd .= "day_open," if defined($data{day_open});
	$cmd .= "day_high," if defined($data{day_high});
	$cmd .= "day_low,"  if defined($data{day_low});
	$cmd .= "day_close";
	##$cmd .= ",volume"  if defined($data{volume});
	$cmd .= ") values ('$data{symbol}', '$data{date}', ";
	$cmd .= "$data{day_open},"   if defined($data{day_open});
	$cmd .= "$data{day_high},"   if defined($data{day_high});
	$cmd .= "$data{day_low},"    if defined($data{day_low});
	$cmd .= "$data{day_close}"; 
	##$cmd .= ",$data{volume} "    if defined($data{volume});
        $cmd .= ");";
      }
      if ($Config{commit}) {
	print "$cmd\n" if $Config{debug};
	$dbh->do($cmd) or die $dbh->errstr;
	$dbh->commit();
      }
    } else {
      ;				# do nothing with bad data
    }
  }
  print "Done with $fx (using $symbol)\n" if $Config{verbose};
}

sub DatabaseHistoricalUBCFX {
  my ($dbh, $aref, @arg) = @_;

  my ($cmd, %data);

  foreach my $lref (@$aref) {	# loop over all retrieved data
    next if $lref->[0] eq "YYYY/MM/DD";
    $data{date} = UnixDate(ParseDate($lref->[0]), "%Y%m%d");
    my $i = 1;
    foreach my $fx (@arg) {
      if (ExistsFXDailyData($dbh,$fx,%data)) { # update data if it exists
	$cmd = "update fxprices set ";
	$cmd .= "day_close = " . 1.0/$lref->[$i] . " "  .
   	    "where currency = '$fx' and date  = '$data{date}'";
      } else {
	$cmd  = "insert into fxprices (currency, date, day_close) ";
        $cmd .= "values ('$fx', '$data{date}', 1.0/$lref->[$i] )";
      }
      $i++;
      if ($Config{commit}) {
	print "$cmd\n" if $Config{debug};
	$dbh->do($cmd) or die $dbh->errstr;
      }
    }
    #print "Done with $fx (using $symbol)\n" if $Config{verbose};
  }
  if ($Config{commit}) {
    $dbh->commit();
  }
}

sub DatabaseHistoricalOandAFX {
  my ($dbh, $aref, @arg) = @_;

  my ($cmd, %data);
  foreach my $line (@$aref) {	# loop over all retrieved data
    ## split the csv stream with quotewords() from Text::ParseWords
    my @q = quotewords(',', 0, $line);
    $data{date} = UnixDate(ParseDate($q[0]), "%Y%m%d");
    my $i = 1;
    foreach my $fx (@arg) {
      if (ExistsFXDailyData($dbh,$fx,%data)) { # update data if it exists
	$cmd = "update fxprices set ";
	$cmd .= "day_close = " . $q[1] . " "  .
   	    "where currency = '$fx' and date  = '$data{date}'";
      } else {
	$cmd  = "insert into fxprices (currency, date, day_close) ";
        $cmd .= "values ('$fx', '$data{date}', $q[1] )";
      }
      $i++;
      if ($Config{commit}) {
	print "$cmd\n" if $Config{debug};
	$dbh->do($cmd) or die $dbh->errstr;
      }
    }
    #print "Done with $fx (using $symbol)\n" if $Config{verbose};
  }
  if ($Config{commit}) {
    $dbh->commit();
  }
}

sub DatabaseInfoData {		# initialise a row in the info table
  my ($dbh, %hash) = @_;
  foreach my $key (keys %hash) { # now split these into reference to the arrays

    # check stockinfo for $key
    if ( ExistsInfoSymbol($dbh, %{$hash{$key}}) ) {
      warn "DatabaseInfoData(): Symbol $key already in stockinfo table\n"
	if ( $Config{verbose} );
      next;
    }

    my $cmd = "insert into stockinfo (symbol, name, exchange, " .
	      "  capitalisation, low_52weeks, high_52weeks, earnings, " .
	      "  dividend, p_e_ratio, avg_volume, active) " .
	      "values('$hash{$key}{symbol}'," .
	         $dbh->quote($hash{$key}{name}) . ", " .
	      "  '$hash{$key}{exchange}', " .
              "  $hash{$key}{market_capitalisation}," .
              "  $hash{$key}{'52_week_low'}," .
  	      "  $hash{$key}{'52_week_high'}," .
	      "  $hash{$key}{earnings_per_share}," .
	      "  $hash{$key}{dividend_per_share}," .
	      "  $hash{$key}{price_earnings_ratio}," .
	      "  $hash{$key}{average_volume}," .
              "  '1')";
    $cmd =~ s|'?N/A'?|null|g;	# convert (textual) "N/A" into (database) null 
    print "$cmd\n" if $Config{debug};
    print "$hash{$key}{symbol} " if $Config{verbose};
    if ($Config{commit}) {
      $dbh->do($cmd) or die $dbh->errstr;
      $dbh->commit();
    }
  }
}


sub ExistsInfoSymbol {
  my ($dbh, %hash) = @_;
  if (!defined($_symExistsInfoSymbolSth)) {
      $_symExistsInfoSymbolSth = $dbh->prepare(qq{select symbol from stockinfo
						  where symbol = ?})
	  or die $dbh->errstr;
  }
  $_symExistsInfoSymbolSth->execute($hash{symbol})
      or die $_symExistsInfoSymbolSth->errstr;
  my @rows = $_symExistsInfoSymbolSth->fetchrow_array();
  $_symExistsInfoSymbolSth->finish();

  # plausibility tests here
  # someone might care to extend this to consider the 'active' tuple
  # maybe if it's false that fact should be noted since
  # the user has apparently seen fit to add it to the database (again)
  return (@rows > 0);
}


sub ExistsDailyData($%) {
  my ($dbh, %hash) = @_;
  if (!defined($_symExistsDailyDataSth)) {
      $_symExistsDailyDataSth = $dbh->prepare(qq{select symbol from stockprices
					where symbol = ? and date = ?})
	  or die $dbh->errstr;
  }
  $_symExistsDailyDataSth->execute($hash{symbol}, $hash{date})
      or die $_symExistsDailyDataSth->errstr;
  my @rows = $_symExistsDailyDataSth->fetchrow_array();
  $_symExistsDailyDataSth->finish();
  return (@rows > 0);
}


sub ExistsFXDailyData {
  my ($dbh,$fx,%hash) = @_;
  my $stmt = qq{select previous_close, day_open, day_low, day_high,
                       day_close, day_change
                from fxprices
                where currency = ?
                  and date     = ?
              };

  print "ExistsFXDailyData():\n\$stmt = $stmt\n" if $Config{debug};

  my $sth = $dbh->prepare($stmt);
  $sth->execute($fx,$hash{date});
  my @row = $sth->fetchrow_array();
  $sth->finish();
  return (@row > 0);
}


sub GetDate {			# date can be "4:01PM" (same day) or "Jan 15"
  my ($value) = @_;		# Date::Manip knows how to deal with them...
  return UnixDate(ParseDate($value), "%Y%m%d");
}


sub ParseDailyData {		# stuff the output into the hash
  my @rra = @_;			# we receive an array with references to arrays
  my %hash;			# we return a hash of hashes

  foreach my $ra (@rra) {	# now split these into reference to the arrays
    my $key = $ra->[0];
    $hash{$key}{symbol}         = uc $ra->[0];
    $hash{$key}{name}           = RemoveTrailingSpace($ra->[1]);
    $hash{$key}{day_close}      = ParseNumeric($ra->[2]);
    unless ($hash{$key}{date} = GetDate($ra->[3])) {
      $hash{$key}{date} = "N/A";
      warn "Ignoring symbol $key with unparseable date\n";
    }
    $hash{$key}{time}           = $ra->[4];
    $hash{$key}{day_change}	= ParseNumeric($ra->[5]);
    $hash{$key}{percent_change} = $ra->[6];
    $hash{$key}{volume}         = $ra->[7];
    $hash{$key}{average_volume} = $ra->[8];
    $hash{$key}{bid}            = ParseNumeric($ra->[9]);
    $hash{$key}{ask}            = ParseNumeric($ra->[10]);
    $hash{$key}{previous_close} = ParseNumeric($ra->[11]);
    $hash{$key}{day_open}       = ParseNumeric($ra->[12]);
    my (@tmp) = split / - /, $ra->[13];
    $hash{$key}{day_low}        = ParseNumeric($tmp[0]);
    $hash{$key}{day_high}       = ParseNumeric($tmp[1]);
    (@tmp) = split / - /, $ra->[14];
    $hash{$key}{'52_week_low'}  = ParseNumeric($tmp[0]);
    $hash{$key}{'52_week_high'} = ParseNumeric($tmp[1]);
    $hash{$key}{earnings_per_share} = $ra->[15];
    $hash{$key}{price_earnings_ratio} = $ra->[16];
    $hash{$key}{dividend_date}  = $ra->[17]; 
    $hash{$key}{dividend_per_share} = $ra->[18];
    $hash{$key}{yield} = $ra->[19];
    if ($ra->[20] =~ m/(\S*)B$/) {
      # convert to millions from billions
      $hash{$key}{market_capitalisation} = $1*(1e3);
    } elsif ($ra->[20] =~ m/(\S*)T$/) {
      # reported in trillions -- convert to millions
      $hash{$key}{market_capitalisation} = $1*(1e6);
    } elsif ($ra->[20] =~ m/(\S*)M$/) {
      # keep it in millions
      $hash{$key}{market_capitalisation} = $1;
    } elsif ($ra->[20] =~ m/(\S*)K$/) {      
      # reported in thousands -- convert to millions
      $hash{$key}{market_capitalisation} = $1*(1e-3);
    } else {
      # it's not likely a number at all -- pass it on
      $hash{$key}{market_capitalisation} = $ra->[20];
    }
    $hash{$key}{exchange}  	= RemoveTrailingSpace($ra->[21]);
  }
  return %hash
}


sub ParseNumeric {		# parse numeric fields which could be fractions
  my $v = shift;		# expect one argument
  $v =~ s/\s*$//;		# kill trailing whitespace
  $v =~ s/\+//;			# kill leading plus sign
  if ($v =~ m|(.*) (.*)/(.*)|) {# if it is a fraction
    return $1 + $2/$3;		#   return the decimal value
  } else {			# else
    return $v;			#   return the value itself
  }
}


sub PrintHistoricalData {	# simple display routine for hist. data
  my (@res) = @_;
  my $i=1;
  foreach $ARG (@res) {
    next if m/^<\!-- .*-->/;    # skip lines with html comments (April 2004)
    print $i++, ": $ARG\n";
  }
}


sub RemoveTrailingSpace {
  my $txt = shift;
  $txt =~ s/\s*$//;
  return $txt;
}


sub ReportDailyData {		# detailed display / debugging routine
  my (%hash) = @_;
  foreach my $key (keys %hash) { # now split these into reference to the arrays
    printf "Name               %25s\n", $hash{$key}{name};
    printf "Symbol             %25s\n", $hash{$key}{symbol};
    printf "Exchange           %25s\n", $hash{$key}{exchange};
    printf "Date               %25s\n", $hash{$key}{date};
    printf "Time               %25s\n", $hash{$key}{time};
    printf "Previous Close     %25s\n", $hash{$key}{previous_close};
    printf "Open               %25s\n", $hash{$key}{day_open};
    printf "Day low            %25s\n", $hash{$key}{day_low};
    printf "Day high           %25s\n", $hash{$key}{day_high};
    printf "Close              %25s\n", $hash{$key}{day_close};
    printf "Change             %25s\n", $hash{$key}{day_change};
    printf "Percent Change     %25s\n", $hash{$key}{percent_change};
    printf "Bid                %25s\n", $hash{$key}{bid};
    printf "Ask                %25s\n", $hash{$key}{ask};
    printf "52-week low        %25s\n", $hash{$key}{'52_week_low'};
    printf "52-week high       %25s\n", $hash{$key}{'52_week_high'};
    printf "Volume             %25s\n", $hash{$key}{volume};
    printf "Average Volume     %25s\n", $hash{$key}{average_volume};
    printf "Dividend date      %25s\n", $hash{$key}{dividend_date};
    printf "Dividend / share   %25s\n", $hash{$key}{dividend_per_share};
    printf "Dividend yield     %25s\n", $hash{$key}{yield};
    printf "Earnings_per_share %25s\n", $hash{$key}{earnings_per_share};
    printf "P/E ratio          %25s\n", $hash{$key}{price_earnings_ratio};
    printf "Market Capital     %25s\n", $hash{$key}{market_capitalisation};
  }
}


sub ScrubDailyData {          # stuff the output into the hash
  my %hash = @_;              # we receive

  ## Check the date supplied from Yahoo!
  ##
  ## The first approach was to count all dates for a given market
  ## This works well when you have, say, 3 Amex and 5 NYSE stock, and
  ## Yahoo just gets one date wrong -- we can then compare the one "off-date"
  ## against, say, four "good" dates and override
  ## Unfortunately, this doesn't work so well for currencies where you
  ## typically only get one, or maybe two, and have nothing to compare against
  ##
  ## my %date;                   # date comparison hash
  ## foreach my $key (keys %hash) {# store all dates for market
  ##   $date{$hash{$key}{exchange}}{$hash{$key}{date}}++; # and count'em
  ## }
  ## -- and later 
  ##    if ($date{$hash{$key}{exchange}}{$hash{$key}{date}} # and outnumbered
  ##	  < $date{$hash{$key}{exchange}}{$Config{today}}) {
  ##	warn("Override: $hash{$key}{name}: $hash{$key}{date} has only " .
  ##	     "$date{$hash{$key}{exchange}}{$hash{$key}{date}} votes,\n\tbut " .
  ##	     "$hash{$key}{exchange} has " .
  ##	     "$date{$hash{$key}{exchange}}{$Config{today}} " .
  ##	     "votes for $Config{today}");
  ##	$hash{$key}{date} = $Config{today};
  ##      } else {
  ##	warn("$hash{$key}{name} has date $hash{$key}{date}, " .
  ##	     "not $Config{today} but no voting certainty");
  ##      }
  ##
  ##    $date{$hash{$key}{exchange}}{$Config{today}} = 0 
  ##	  unless defined($date{$hash{$key}{exchange}}{$Config{today}});
  ##
  ## So now we simply override if (and only if) the --forceupdate
  ## argument is used. This is still suboptimal if eg you are running this
  ## on public holidays. We will have to find a way to filter this
  ##
  foreach my $key (keys %hash) {# now check the date
    if ($hash{$key}{date} eq "N/A") { # if Yahoo! gave us no data
      if ($hash{$key}{symbol} =~ /^\^X/) { # and it was currency
	my $retry = GetIsoCurrency($hash{$key}{symbol}) . "USD=X";
	my @retrysymbols;
	push @retrysymbols, $retry;	
	my (@newarr) = GetDailyData(@retrysymbols);
	print "Retrying $retry:\n", Dumper(@newarr) if $Config{debug};

	foreach my $ra (@newarr) {	# split these into ref. to the arrays
	  #print "$ra->[0]\n";
	  #$hash{$key}{symbol}         = uc $ra->[0];
	  $hash{$key}{name}      = RemoveTrailingSpace($ra->[1]);
	  $hash{$key}{day_close} = ParseNumeric($ra->[2]);
	  $hash{$key}{day_open} = $hash{$key}{day_low} =
	    $hash{$key}{day_high} = 
	    $hash{$key}{previous_close} = $hash{$key}{day_change} = -1.2345;
	  $hash{$key}{date}      = GetDate($ra->[3]);
	  $hash{$key}{time}      = $ra->[4];
	}
      } else {
	warn "Not scrubbing $hash{$key}{symbol}\n" if $Config{debug};
	next;
      }
    }

    if ($hash{$key}{date} ne $Config{today}) {   # if date is not today

      my $age = Delta_Format(DateCalc($hash{$key}{date}, $Config{lastbizday},
				      undef, 2), "approx", 0, "%dt");
      if ($age > 5) {
        warn "Ignoring $hash{$key}{symbol} ($hash{$key}{name}) " .
	  "with old date $hash{$key}{date}\n";
        #warn "Ignoring $hash{$key}{name} with old date $hash{$key}{date}\n";
	#if $Config{debug};
	$hash{$key}{date} = "N/A";
	next;
      }

      if (defined($Config{updatedate})) {        # and if we have an override
	$hash{$key}{date} = $Config{updatedate}; # use it
        warn "Overriding date for $hash{$key}{symbol} ($hash{$key}{name}) " .
	  "to $Config{updatedate}\n";
        #warn "Overriding date for $hash{$key}{name} to $Config{updatedate}\n";
       } else {
        warn "$hash{$key}{symbol} ($hash{$key}{name}) " .
	  "has date $hash{$key}{date}\n";
        #warn "$hash{$key}{name} has date $hash{$key}{date}\n";
      }
    }

    if ($hash{$key}{previous_close} ne "N/A" and
	($hash{$key}{day_close} == $hash{$key}{previous_close}) 
	and ($hash{$key}{day_change} != 0)) {
      $hash{$key}{previous_close} = $hash{$key}{day_close} 
	- $hash{$key}{day_change};
      warn "Adjusting previous close for $key from close and change\n";
    }

    # Yahoo! decided, on 2004-02-26, to change the ^X indices from
    # US Dollar to US Cent, apparently.
    if ($hash{$key}{symbol} =~ /^\^X/) {
      if (Date_Cmp(ParseDate($hash{$key}{date}), ParseDate("20040226")) > 0
	  and not
	  Date_Cmp(ParseDate($hash{$key}{date}), ParseDate("20050117")) > 0) {
	warn "Scaling $key data from dollars to pennies\n" if $Config{debug};
        $hash{$key}{previous_close} /= 100;
        $hash{$key}{day_open} /= 100;
        $hash{$key}{day_low} /= 100;
        $hash{$key}{day_high} /= 100;
        $hash{$key}{day_close} /= 100;
        $hash{$key}{day_change} /= 100;
      }
    }
  }
  return %hash;
}


sub Sign {
  my $x = shift;
  if ($x > 0) {
    return 1;
  } elsif ($x < 0){
    return -1;
  } else {
    return 0;
  }
}

sub UpdateDatabase {		# update content in the db at end of day
  my ($dbh, $res) = @_;
  my ($stmt, $sth, $rv, $ra, @symbols);

  $stmt = qq{  select distinct symbol
	       from stockinfo
	       where symbol != '' 
	       and active };
  $stmt .= qq{   and symbol in (select distinct symbol 
			        from portfolio where $res)
	     } if defined($res);
  $stmt .= " order by symbol;";

  print "UpdateDatabase():\n\$stmt = $stmt\n" if $Config{debug};

  @symbols = @{ $dbh->selectcol_arrayref($stmt) };
  print join " ", @symbols, "\n" if $Config{verbose};

  my @arr = GetDailyData(@symbols);# retrieve _all_ the data
  my %data = ParseDailyData(@arr); # put it into a hash
  %data = ScrubDailyData(%data);   # and "clean" it      
  ReportDailyData(%data) if $Config{verbose};
  UpdateInfoData($dbh, %data);
  DatabaseDailyData($dbh, %data);
  UpdateTimestamp($dbh);
}


sub UpdateFXDatabase {
  my ($dbh, $res) = @_;

  # get all non-USD symbols (no USD as we don't need a USD/USD rate)
  my $stmt = qq{  select distinct currency
		  from portfolio 
		  where symbol != '' 
		  and currency != 'USD'
	    };
  $stmt .= "   and $res " if (defined($res));

  print "UpdateFXDatabase():\n\$stmt = $stmt\n" if $Config{debug};

  my @symbols = map { GetYahooCurrency($ARG) } @{ $dbh->selectcol_arrayref($stmt)};
  print "UpdateFXDatabase(): Symbols are ", join(" ", @symbols), "\n" 
      if $Config{debug};
  if ($Config{extrafx}) {
    foreach my $arg (split /,/, $Config{extrafx}) {
      push @symbols, GetYahooCurrency($arg);	
    }
  }
  if (scalar(@symbols) > 0) {	# if there are FX symbols
    my @arr = GetDailyData(@symbols); # retrieve _all_ the data
    my %data = ParseDailyData(@arr);
    %data = ScrubDailyData(%data);   # and "clean" it 
    ReportDailyData(%data) if $Config{verbose};
    DatabaseFXDailyData($dbh, %data);
  }
  UpdateTimestamp($dbh);
}

## use alternate FX data supply from the PACIFIC / Sauder School / UBC
sub UpdateFXviaUBC {
  my ($dbh, $res) = @_;

  # get all non-USD symbols (no USD as we don't need a USD/USD rate)
  my $stmt = qq{  select distinct currency
		  from portfolio 
		  where symbol != '' 
		  and currency != 'USD'
	    };
  $stmt .= "   and $res " if (defined($res));
  print "UpdateFXviaUBC():\n\$stmt = $stmt\n" if $Config{debug};

  my @symbols = @{ $dbh->selectcol_arrayref($stmt) };
  print "UpdateFXviaUBC() -- symbols=" . 
      join(" ", @symbols) . "\n" if $Config{debug};

  my %data;
  $data{date} = $Config{lastbizday};
  $data{date} = $Config{updatedate} if exists($Config{updatedate});

  ## also fetch data via the PACIFIC server at Sauder / UBC
  my $ubcfx = GetUBCFXHash(\@symbols, $data{date}, $data{date});
  print "UBC server results\n", Dumper($ubcfx) if $Config{debug};

  foreach my $key (keys %{$ubcfx}) { # split these into reference to the arrays
    my $fx = $key; #$yahoo2iso->{$hash{$key}{symbol}};
    print "Looking at $fx\n" if $Config{debug};
    if (ExistsFXDailyData($dbh, $fx, %data)) {
      my $stmt = qq{update fxprices
                    set day_close      = ?
                    where currency     = ?
                    and date           = ?
                };

      print "DatabaseFXDailyData():\n\$stmt = $stmt\n" if $Config{debug};
      print "DatabaseFXDailyData(): 1/$ubcfx->{$fx}, $fx, $data{date} \n" 
	  if $Config{debug};

      if ($Config{commit}) {
	  $dbh->do($stmt, undef, 1/$ubcfx->{$fx}, $fx, $data{date})
	    or warn "Failed for $fx at $data{date}\n";
      }

    } else {
      my $stmt = qq{insert into fxprices (currency, date, day_close) values (?, ?, ?);};

      print "DatabaseFXDailyData():\n\$stmt = $stmt\n" if $Config{debug};
      print "DatabaseFXDailyData(): 1/$ubcfx->{$fx}, $fx, $data{date} \n" 
	  if $Config{debug};

      if ($Config{commit}) {
	my $sth = $dbh->prepare($stmt);
	$sth->execute($fx, $data{date}, 1/$ubcfx->{$fx})
	  or warn "Failed for $fx at $data{date}\n";
	$sth->finish();
      }
    }
    if ($Config{commit}) {
      $dbh->commit();
    }
  }
}

sub UpdateInfoData {		# update a row in the info table
  my ($dbh, %hash) = @_;
  foreach my $key (keys %hash) { # now split these into reference to the arrays
    my $cmd = "update stockinfo " .
              "set capitalisation = $hash{$key}{market_capitalisation}, " .
              "low_52weeks = $hash{$key}{'52_week_low'}, " .
  	      "high_52weeks = $hash{$key}{'52_week_high'}, " .
	      "earnings = $hash{$key}{earnings_per_share}, " .
	      "dividend = $hash{$key}{dividend_per_share}, " .
	      "p_e_ratio = $hash{$key}{price_earnings_ratio}, " .
	      "avg_volume = $hash{$key}{average_volume} " .
	      "where symbol = '$hash{$key}{symbol}';";
    $cmd =~ s|'?N/A'?|null|g;	# convert (textual) "N/A" into (database) null 
    print "$cmd\n" if $Config{debug};
    print "$hash{$key}{symbol} " if $Config{verbose};
    if ($Config{commit}) {
      $dbh->do($cmd) or warn "Failed for $hash{$key}{symbol} with $cmd\n";
    }
  }
}

sub UpdateTimestamp {
  my $dbh = shift;
  my $cmd = q{update beancounter set data_last_updated='now'};
  print "$cmd\n" if $Config{debug};
  if ($Config{commit}) {
    $dbh->do($cmd) or warn "UpdateTimestamp failed\n";
    $dbh->commit();
  }
}


1;				# required for a package file

__END__

=head1 NAME

Finance::BeanCounter - Module for stock portfolio performance functions.

=head1 SYNOPSIS

 use Finance::BeanCounter;

=head1 DESCRIPTION

B<Finance::BeanCounter> provides functions to I<download>, I<store> and
I<analyse> stock market data.

I<Downloads> are available of current (or rather: 15 or 20
minute-delayed) price and company data as well as of historical price
data.  Both forms can be stored in an SQL database (for which we
currently default to B<PostgreSQL> though B<MySQL> is supported as
well; furthermore any database reachable by means of an B<ODBC>
connection should work).

I<Analysis> currently consists of performance and risk
analysis. Performance reports comprise a profit-and-loss (or 'p/l' in
the lingo) report which can be run over arbitrary time intervals such
as C<--prevdate 'friday six months ago' --date 'yesterday'> -- in
essence, whatever the wonderful B<Date::Manip> module understands --
as well as dayendreport which defaults to changes in the last trading
day. A risk report show parametric and non-parametric value-at-risk
(VaR) estimates.

Most available functionality is also provided in the reference
implementation B<beancounter>, a convenient command-line script.

The API might change and evolve over time. The low version number
really means to say that the code is not in its final form yet, but it
has been in use for well over four years.

More documentation is in the Perl source code.

=head1 DATABASE LAYOUT

The easiest way to see the table design is to look at the content of
the B<setup_beancounter> script. It creates the five tables
I<stockinfo>, I<stockprices>, I<fxprices>, I<portfolio> and
I<indices>. Note also that is supports the creation of database for
both B<PostgreSQL> and B<MySQL>.

=head2 THE STOCKINFO TABLE

The I<stockinfo> table contains general (non-price) information and is
index by I<symbol>:


	    symbol   		varchar(12) not null,
	    name     		varchar(64) not null,
	    exchange 		varchar(16) not null,
	    capitalisation  	float4,
	    low_52weeks		float4,
	    high_52weeks	float4,
	    earnings		float4,
	    dividend		float4,
	    p_e_ratio		float4,
	    avg_volume		int4

This table is updated by overwriting the previous content.

=head2 THE STOCKPRICES TABLE

The I<stockprices> table contains (daily) price and volume
information. It is indexed by both I<date> and I<symbol>:

	    symbol   		varchar(12) not null,
	    date		date,
	    previous_close	float4,
	    day_open		float4,
	    day_low		float4,
	    day_high		float4,
	    day_close		float4,
	    day_change		float4,
	    bid			float4,
	    ask			float4,
	    volume		int4

During updates, information is appended to this table.

=head2 THE FXPRICES TABLE

The I<fxprices> table contains (daily) foreign exchange rates. It can be used to calculate home market values of foreign stocks:

	    currency   		varchar(12) not null,
	    date		date,
	    previous_close	float4,
	    day_open		float4,
	    day_low		float4,
	    day_high		float4,
	    day_close		float4,
	    day_change		float4

Similar to the I<stockprices> table, it is index on I<date> and I<symbol>.

=head2 THE STOCKPORTFOLIO TABLE

The I<portfolio> table contains contains the holdings information:

	    symbol   		varchar(16) not null,
	    shares		float4,
	    currency		varchar(12),
	    type		varchar(16),
	    owner		varchar(16),
	    cost		float(4),
	    date		date

It is indexed on I<symbol,owner,date>.

=head2 THE INDICES TABLE

The I<indices> table links a stock I<symbol> with one or several
market indices:

	    symbol   		varchar(12) not null,
	    stockindex		varchar(12) not null

=head1 BUGS

B<Finance::BeanCounter> and B<beancounter> are so fresh that there are
only missing features :)

On a more serious note, this code (or its earlier predecessors) have
been in use since the fall of 1998.

Known bugs or limitations are documented in TODO file in the source
package.

=head1 SEE ALSO

F<beancounter.1>, F<smtm.1>, F<Finance::YahooQuote.3pm>,
F<LWP.3pm>, F<Date::Manip.3pm>

=head1 COPYRIGHT

Finance::BeanCounter.pm  (c) 2000 -- 2006 by Dirk Eddelbuettel <edd@debian.org>

Updates to this program might appear at 
F<http://eddelbuettel.com/dirk/code/beancounter.html>.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.  There is NO warranty whatsoever.

The information that you obtain with this program may be copyrighted
by Yahoo! Inc., and is governed by their usage license.  See
F<http://www.yahoo.com/docs/info/gen_disclaimer.html> for more
information.

=head1 ACKNOWLEDGEMENTS

The Finance::YahooQuote module by Dj Padzensky (on the web at
F<http://www.padz.net/~djpadz/YahooQuote/>) served as the backbone for
data retrieval, and a guideline for the extension to the non-North
American quotes which was already very useful for the real-time ticker 
F<http://eddelbuettel.com/dirk/code/smtm.html>.

=cut

