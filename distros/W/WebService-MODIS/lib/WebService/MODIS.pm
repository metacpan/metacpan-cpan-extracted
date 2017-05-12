package WebService::MODIS;

use strict;
use warnings;
use Carp;
use LWP::UserAgent;
use File::Basename;
use File::HomeDir;
use File::Path qw(make_path);
use Date::Simple;
use List::Util qw(any max min none);

require Exporter;
our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(initCache readCache writeCache getCacheState getVersions getModisProducts getModisDates getModisGlobal) ] );
our @EXPORT_OK   = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT      = qw(initCache readCache writeCache getCacheState getVersions isGlobal);

our $VERSION = '1.6';

my %modisProducts     = ();
my %modisDates        = ();
my %modisGlobal       = ();
my $modisProductsFile = "ModisProducts.pl";
my $modisDatesFile    = "ModisDates.pl";
my $modisGlobalFile   = "ModisGlobal.pl";
my $cacheDir;

my $cacheState = '';

my $BASE_URL = "http://e4ftl01.cr.usgs.gov";
my @DATA_DIR = ("MOLA", "MOLT", "MOTA");

if (lc($^O) =~ /mswin/) {
    $cacheDir = File::HomeDir->my_home()."/AppData/Local/WebService-MODIS";
} else {
    $cacheDir = File::HomeDir->my_home()."/.cache/WebService-MODIS";
}

sub new {
    my $class = shift;
    my %options = @_;
    my $self = {
        product      => '',
        version      => '',
        dates        => [],
        h            => [],
        v            => [],
        ifExactDates => 0,
        ifExactHV    => 0,
        targetDir    => ".",
        forceReload  => 0,
        %options,
        url          => [],
    };
    bless($self, $class);

    # User input error checks
    $self->product($self->{product}) if ($self->{product} ne '');
    $self->version($self->{version}) if ($self->{version} ne '');
    $self->dates($self->{dates}) if (@{$self->{dates}} != 0);
    $self->h($self->{h}) if (@{$self->{h}} != 0);
    $self->v($self->{v}) if (@{$self->{v}} != 0);
    $self->ifExactDates($self->{ifExactDates}) if ($self->{ifExactDates} != 0);
    $self->ifExactHV($self->{ifExactHV}) if ($self->{ifExactHV} != 0);

    return($self);
}

#######################################################################
### For debuging and informations

# returns the cached products data hash
sub getModisProducts() {
  return(%modisProducts);
}

#returns the reference to the dates array
sub getModisDates($) {
  my $product = shift;
  return($modisDates{$product});
}

# returns the cached global grid check hash
sub getModisGlobal() {
  return(%modisGlobal);
}

########################################################################
### Cache not related to object. Need to create own object, which gets
### part of WebService::MODIS

### retrieve the directory structure from the server
sub initCache {
#    my $self = shift;
    %modisProducts = getAvailProducts();
    %modisDates    = getAvailDates(\%modisProducts);
    for (keys %modisProducts) {
        my $check = isGlobal($_);
        $modisGlobal{$_} = $check;
    }
    $cacheState = "mem";
}

### load the previously saved server side directory structure from
### local files
sub readCache {
    #    my $self = shift;
    my $arg   = shift;
    $cacheDir = $arg if ($arg);
    croak "Cache directory '$cacheDir' does not exist. Use 'writeCache' create it first or check your parameter!" if (!-d $cacheDir);

    if (-s "$cacheDir/$modisProductsFile") {
        %modisProducts = do "$cacheDir/$modisProductsFile";
        if (-s "$cacheDir/$modisDatesFile") {
            %modisDates = do "$cacheDir/$modisDatesFile";
            if (-s "$cacheDir/$modisGlobalFile") {
                %modisGlobal = do "$cacheDir/$modisGlobalFile";
                $cacheState = "file";
                return;
            } else {
                croak "Cache file '$cacheDir/$modisGlobalFile' is empty. Use 'writeCache' to recreate it.";
            }
        } else {
            croak "Cache file '$cacheDir/$modisDatesFile' is empty. Use 'writeCache' to recreate it.";
        }
    } else {
        croak "Cache file '$cacheDir/$modisProductsFile' is empty. Use 'writeCache' to recreate it.";
    }
    return(99);
}

### write the server side directory structure to local files
sub writeCache {
    #    my $self = shift;
    my $arg   = shift;
    $cacheDir = $arg if ($arg);

    croak "Nothing cached yet!" if ($cacheState eq '');
    carp "Rewriting old cache to file" if ($cacheState eq 'file'); 

    if ( ! -d $cacheDir ) {
        make_path($cacheDir) or croak "Could not create cache dir ('$cacheDir'): $!";
    }

    my $fhd;

    open($fhd, ">", "$cacheDir/$modisProductsFile") or 
        croak "cannot open '$cacheDir/$modisProductsFile' for writing: $!\n";
    for (keys %modisProducts) {
        print  $fhd "'$_' => '$modisProducts{$_}',\n";
    }
    close($fhd) or carp "close '$cacheDir/$modisProductsFile' failed: $!";

    open($fhd, ">", "$cacheDir/$modisDatesFile") or
        croak "cannot open '$cacheDir/$modisDatesFile' for writing: $!\n";
    for (keys %modisDates) {
        print  $fhd "'$_' => ['".join("', '", @{$modisDates{$_}})."'],\n";
    }
    close($fhd) or carp "close '$cacheDir/$modisDatesFile' failed: $!";

    open($fhd, ">", "$cacheDir/$modisGlobalFile") or
        croak "cannot open '$cacheDir/$modisGlobalFile' for writing: $!\n";
    for (keys %modisGlobal) {
        print $fhd "'$_' => $modisGlobal{$_},\n";
    }

    $cacheState = "file";
}

sub getCacheState {
#    my $self = shift;
    return $cacheState;
}

### return a list of available version for a given product
sub getVersions($) {
    my $product  = shift;
    my @versions = ();
    foreach (keys %modisProducts) {
        next if (! /$product/);
        s/$product.//;
        push(@versions, $_);
    }
    return(@versions);
}

### check is Product is global or on sinusoidal grid (with h??v?? in name)
sub isGlobal($) {
    my $product = shift;
    my $global  = 1;

    croak "'$product' is not in the MODIS product list: Check name or refresh the cache." if (! any { /$product/ } keys %modisProducts);

    my @flist = getDateFullURLs($product, ${$modisDates{$product}}[0]);
    my $teststr = $flist[0];
    $teststr =~ s/.*\///;
    $global = 0 if ($teststr =~ /h[0-9]{2}v[0-9]{2}/);
    return($global);
}

##################################################
### methods for returning object informations
### or setting them

sub product {
    my $self = shift;

    if (@_) {
        if ($cacheState eq '') {
            carp "Cache not initialized or loaded, cannot check availability of '$_[0]'.";
        } else {
            my $failed=1;
            $failed = 0 if any { /$_[0]\.[0-9]{3}/ } (keys %modisProducts);
            croak "Product '$_[0]' not available!" if $failed;
        }
        $self->{product} = shift;
        $self->{version} = '';
        $self->{url} =[];
        return;
    }
    return $self->{product};
}

sub version {
    my $self = shift;
    if (@_) {
        $self->{version} = shift;
        if ($self->{product} eq '') {
            carp "No product specified yet, so specifying the version does not make sense.";
        } else {
            my @vers = getVersions($self->{product});
            if (none {/$self->{version}/} @vers) {
                carp "Version ".$self->{version}." does not exist! Resetting it to ''.";
                $self->{version} = ''
            }
        }
        $self->{url} = [];
        return;
    }
    return $self->{version};
}

sub dates {
    my $self = shift;
    if (@_) {
        my $refDates = shift;
        if ($self->{product} eq '') {
            carp "No product specified yet, No availability check possible.";
        } else {
            # check availability 
        }
        $self->{dates} = $refDates;
        $self->{url} = [];
        return;
    }
    return @{$self->{dates}};
}

sub h {
    my $self = shift;
    if (@_) {
        my $refH = shift;
        if (any {$_ < 0 or $_ > 35} @$refH) {
            croak "Invalid h values supplied. Valid range: 0-35.";
        }
        $self->{h} = $refH;
        $self->{url} = [];
        return;
    }
    return @{$self->{h}};
}

sub v {
    my $self = shift;
    if (@_) {
        my $refV = shift;
        if (any {$_ < 0 or $_ > 17} @$refV) {
            croak "Invalid v values supplied. Valid range: 0-17.";
        }
        $self->{v} = $refV;
        $self->{url} = [];
        return;
    }
    return @{$self->{v}};
}

sub ifExactDates {
    my $self = shift;
    if (@_) {
        my $nDates = @{$self->{dates}};
        carp "Sure you want to set this before setting the dates!" if ($nDates==0);
        $self->{ifExactDates} = shift;
        $self->{url} = [];
        return;
    }
    return $self->{ifExactDates};
}

sub ifExactHV {
    my $self = shift;
    if (@_) {
        # include error checks
        my $nH = @{$self->{h}};
        my $nV = @{$self->{v}};
        carp "You are setting 'ifExactHV' before setting 'h' and/or 'v'!" if ($nH==0 or $nV==0);
        $self->{ifExactHV} = shift;
        $self->{url} = [];
        return;
    }
    if ($self->{ifExactHV}) {
        my $nH = @{$self->{h}};
        my $nV = @{$self->{v}};
        carp "You set 'ifExactHV' before setting 'h' and/or 'v'!" if ($nH==0 or $nV==0);
        carp "If ifExactHV is set, 'h' and 'v' should have equal length!" if ($nH != $nV);
    }
    return $self->{ifExactHV};
}

sub url {
    my $self = shift;
    return @{$self->{url}};
}

########################################################################
### method initializing the URL list
### does not need to be done by hand, is called from within download method.
### This method also checks for all invalid combinations.

sub createUrl {
    my $self    = shift;
    my $product = $self->{product};

    croak "Product '$product' unknown!" if (! any { /$product/ } (keys %modisProducts));

    my $version = $self->{version};
    my @availVersions = getVersions($product);

    ### check the MODIS product version
    if ($version ne '') {
        if (any { /$version/ } @availVersions) {
            $product = "${product}.${version}";
        } else {
            croak "Version $version not available for $product (available: ".join(" ,", @availVersions).").\n";
        }
    } else {
        $version='000';
        foreach (@availVersions) {
            $version = $_ if (int($_) > int($version));
        }
        $product = "${product}.${version}";
    }
    $self->{version} = $version;

    ### check the product date availability and reset the $self->{dates} array 
    if ($self->{ifExactDates}) {
        my @dates = @{$self->{dates}};
        my @cleanedDates = @dates;
        foreach (@dates) {
            my $failed = 0;
            $failed=1 if none { /$_/ } @{$modisDates{$product}};
            if ($failed) {
                @cleanedDates = grep { $_ != $_ } @cleanedDates;
                carp "Date '$_' not available! Removing it from list";
            }
        }
        @dates = ();
        foreach (@cleanedDates) {
            s/\./\-/g;
            push(@dates, Date::Simple->new($_));
        }
        $self->{dates} = \@dates;
    } else {
        my @dates = @{$self->{dates}};
        my @newDates = ();
        foreach (@dates) {
            s/\./\-/g;
            push(@newDates, Date::Simple->new($_));
        }
        my @cleanedDates = ();
        foreach (@{$modisDates{$product}}) {
            s/\./\-/g;
            my $modisDate = Date::Simple->new($_);
            next if ($modisDate - min(@newDates) < 0);
            next if ($modisDate - max(@newDates) > 0);
            push(@cleanedDates, $modisDate);
        }
        $self->{dates} = \@cleanedDates;
    }

    ### check the h and v availability, but only if necessary
    if (!$modisGlobal{$product}) {
        my @h = @{$self->{h}};
        my @v = @{$self->{v}};
        if ($self->{ifExactHV}) {
            my $nH = @{$self->{h}};
            my $nV = @{$self->{v}};
            if ($nH != $nV) {
                carp "If ifExactHV is set, 'h' and 'v' should have equal length!" if ($nH != $nV);
                @h = splice(@h, 0, min($nH, $nV));
                @v = splice(@v, 0, min($nH, $nV));
            }
        } else {
            my @newH = ();
            my @newV = ();
            foreach my $h (min(@h)..max(@h)) {
                foreach my $v (min(@v)..max(@v)) {
                    push(@newH, $h);
                    push(@newV, $v);
                }
            }
            $self->{h} = \@newH;
            $self->{v} = \@newV;
        }
    }

    my @url = ();
    foreach (@{$self->{dates}}) {
        my @fullUrl = getDateFullURLs($product, $_->format("%Y.%m.%d"));
        if (!$modisGlobal{$product}) {
            my $nHV = @{$self->{h}};
            for (my $i=0; $i < $nHV; $i++) {
                my $pat = sprintf("h%02iv%02i", ${$self->{h}}[$i], ${$self->{v}}[$i]);
                my @newUrl;
                foreach (@fullUrl) {
                    if (/$pat/) {
                        push(@newUrl, $_);
                    }
                }
                my $nNewUrl = @newUrl;
                if ($nNewUrl == 1) {
                    push(@url, $newUrl[0]);
                } elsif ($nNewUrl < 1) {
                    carp(sprintf("$product: Missing file for %s @ %s.\n", $pat, $_->format("%Y.%m.%d")));
                } else { 
                    # check for duplicate files here and choose the latest one
                    carp(sprintf("$product: %i files for %s @ %s, choosing the newest.\n", $nNewUrl, $pat, $_->format("%Y.%m.%d")));
                    my $createDate = $newUrl[0];
                    $createDate =~ s/\.hdf$//;
                    $createDate =~ s/^.*\.//g;
                    $createDate = int($createDate);
                    my $newest = 0;
                    for (my $k=0; $k < $nNewUrl; $k++) {
                        s/\.hdf$//;
                        s/^.*\.//g;
                        if (int($_) > $createDate) {
                            $newest = $k;
                            $createDate = int($_);
                        }  
                    }
                    push(@url, $newUrl[$newest]);
                }
            }
        } else {
           my $nUrl = @fullUrl;
            if ($nUrl == 1) {
                push(@url, $fullUrl[0]);
            } elsif ($nUrl < 1) {
                carp(sprintf("$product: Missing file @ %s.\n", $_->format("%Y.%m.%d")));
            } else { 
                # check for duplicate files here and choose the latest one
                warn(sprintf("$product: %i files @ %s, choosing the newest.\n", $nUrl, $_->format("%Y.%m.%d")));
                my $createDate = $fullUrl[0];
                $createDate =~ s/\.hdf$//;
                $createDate =~ s/^.*\.//g;
                $createDate = int($createDate);
                my $newest = 0;
                for (my $k=0; $k < $nUrl; $k++) {
                    s/\.hdf$//;
                    s/^.*\.//g;
                    if (int($_) > $createDate) {
                        $newest = $k;
                        $createDate = int($_);
                    }  
                }
                push(@url, $fullUrl[$newest]);
            }
        }
    }
    $self->{url} = \@url;
}

########################################################################
### method for download

sub download {
    my $self = shift;
    my $arg  = shift;
    $self->{targetDir} = $arg if ($arg);
    $arg = shift;
    $self->{forceReload} = $arg if ($arg);

    my $nUrl = @{$self->{url}};

    $self->createUrl if ($nUrl == 0);
    $nUrl = @{$self->{url}};

    if (! -d $self->{targetDir}) {
      my $failed = 1;
      make_path($self->targetDir) and $failed = 0;
      if ($failed) {
          croak "Cannot create directory '$self->{targetDir}': $!\n";
      }
    }

    # adjusted from http://stackoverflow.com/questions/6813726/continue-getting-a-partially-downloaded-file
    my $ua = LWP::UserAgent->new();

    for (my $i=0; $i < $nUrl; $i++) {
        my $file = $self->{targetDir}."/".basename(@{$self->{url}}[$i]);
        unlink($file) if ($self->{forceReload} && -f $file);
        my $failed = 1;
        open(my $fh, '>>:raw', $file) and $failed = 0;
        if ($failed) {
            croak "Cannot open '$file': $!\n";
        }
        my $bytes = -s $file;
        my $res;
        if ( $bytes && ! $self->{forceReload}) {
            #print "resume ${$self->{url}}[$i] -> $file ($bytes) " if ($verbose);
            $res = $ua->get(
                ${$self->{url}}[$i],
                'Range' => "bytes=$bytes-",
                ':content_cb' => sub { my ( $chunk ) = @_; print $fh $chunk; }
                );
        } else {
            #print "$URL[$i] -> $destination[$i] " if ($verbose);
            $res = $ua->get(
                ${$self->{url}}[$i],
                ':content_cb' => sub { my ( $chunk ) = @_; print $fh $chunk; }
                );
        }
        close $fh;

        my $status = $res->status_line;
        if ( $status =~ /^(200|206|416)/ ) {
            #print "OK\n" if ($verbose && $status =~ /^20[06]/);
            #print "already complete\n" if ($verbose && $status =~ /^416/);
        } else {
            print "DEBUG: $status what happend?";
        }
    }
}

###################################################
###################################################
### Internal functions 

### retrieve a list of available MODIS Products
### and return a hash with the name of the first subdirectory 
sub getAvailProducts () {
    my $caller = (caller)[0];
    carp "This is an internal WebService::MODIS function. You should know what you are doing." if ($caller ne "WebService::MODIS");

    my %lookupTable = ();
    my $ua = new LWP::UserAgent;
    foreach my $subdir (@DATA_DIR) {
        my $response = $ua->get("${BASE_URL}/${subdir}");

        unless ($response->is_success) {
            die $response->status_line;
        }

        my $content = $response->decoded_content();
        my @content = split("\n", $content);
        foreach (@content) {
            next if (!/href="M/);
            s/.*href="//;
            s/\/.*//;

            print "Key already exists\n" if exists $lookupTable{$_};
            print "Key already defined\n" if defined $lookupTable{$_};
            print "True\n" if $lookupTable{$_};

            $lookupTable{$_} = $subdir;
        }
    }
    return %lookupTable;
}

### get the available second level directories, named by date
### (YYYY.MM.DD) under which the hdf files reside. This does
### not ensure that the files are really there.
sub getAvailDates() {
    my $caller = (caller)[0];
    carp "This is an internal WebService::MODIS function. You should know what you are doing." if ($caller ne "WebService::MODIS");

    my %lookupTable = ();

    my $ua = new LWP::UserAgent;
    foreach my $key (keys %modisProducts) {
        my @dates=();
        my $response = $ua->get("${BASE_URL}/$modisProducts{$key}/$key");

        unless ($response->is_success) {
            die $response->status_line;
        }

        my $content = $response->decoded_content();
        my @content = split("\n", $content);
        foreach (@content) {
            next if (!/href="20[0-9]{2}\.[0-9]{2}\.[0-9]{2}/);
            s/.*href="//;
            s/\/.*//;
            push(@dates, $_);
        }
        my $datesString = "['".join("', '", @dates)."']";
        $lookupTable{$key} = eval $datesString;
    }
    return %lookupTable;
}

### return a file list for one product and date on the server
sub getDateFullURLs($$) {
    my $caller = (caller)[0];
    carp "This is an internal WebService::MODIS function. You should know what you are doing." if ($caller ne "WebService::MODIS");

    my $product = shift;
    my $date = shift;

    my @flist = ();

    my $ua = new LWP::UserAgent;

    my $response = $ua->get("${BASE_URL}/$modisProducts{$product}/$product/$date");
  
    unless ($response->is_success) {
        die $response->status_line;
    }

    my $content = $response->decoded_content();
    my @content = split("\n", $content);
    foreach (@content) {
        next if (!/href="M/);
        next if (/hdf.xml/);
        s/.*href="//;
        s/".*//;
        push(@flist, "${BASE_URL}/$modisProducts{$product}/$product/$date/$_");
    }
    return(@flist);
}

1;

__END__

=head1 NAME

WebService::MODIS - Perl extension for downloading MODIS satellite data

=head1 SYNOPSIS
  use WebService::MODIS;

  ### to initalize or reload the cached server side directory structure
  initCache;
  ### write the cache to configuration files.
  ### A different directory can be passed as parameter.
  writeCache;
  ### load the cache from a previous writeCache.
  ### A different directory can be passed as parameter.
  readCache;

  ### Only available with use WebService::MODIS qw(:all);
  # my %ret = getModisProducts;
  # print "$_ : $ret{$_}\n" foreach (keys %ret);
  # %ret = getModisGlobal;
  # print "$_ : $ret{$_}\n" foreach (keys %ret);

  ### print available versions of a certain product
  print "Versions of MCD12Q1:";
  print " $_" foreach (getVersions("MCD12Q1"));
  print "\n";

  ### new object of land cover type in Rondonia, Brazil for 2001 and 2010
  my $lct = WebService::MODIS->new(product => "MCD12Q1", 
              dates => ['2001-01-01', '2010-01-01'], ifExactDates => 1,
              h => [11,12], v=> [9,10]);
  $lct->createUrl;
  ### print the list of URLs for usage with e.g. wget
  print "$_\n" foreach $lct->url;
  ### download the data to the current working directory (>700MB!)
  # $lct->download;
  ### test partial download
  # system("mv MCD12Q1.A2001001.h11v09.051.2014287162321.hdf MCD12Q1.A2001001.h11v09.051.2014287162321.hdf.bak");
  # system("head -c 72268718 MCD12Q1.A2001001.h11v09.051.2014287162321.hdf.bak >MCD12Q1.A2001001.h11v09.051.2014287162321.hdf"); 
  # $lct->download;

  ### intialize an empty object and populate it with NDVI/EVI data 
  ### for one tile of Europe for 3 years
  my $phen = WebService::MODIS->new();
  $phen->product("MYD13A2");
  $phen->version('005');
  $phen->h([18]);
  $phen->v([4]);
  $phen->dates(["2002.01.01", "2004.12.31"]);
  $phen->createUrl;
  print "$_\n" foreach $phen->url;
  # $phen->download("$ENV{HOME}/tmp/test_modisdownload");

=head1 DESCRIPTION

This module can dowload a MODIS satellite product in standard hdf format.
It loads metadata of all available products and their respective versions
and can save this metadata for future use to configuration files.
You can either print a list of desired files or download them directly
with this module. The module supports continuous download.

You need the following information

=over 1

=item product ID: which product do you want

=item [version]: not necessarily, but better so you know what you get. If not set, the highest version number is choosen.

=item dates: for which time frame do you want the data

=item h, v: values of desired MODIS sinusoidal grid (if not a global product is choosen)

=back

=head1 FUNCTIONS

=head2 initCache

=for intialize metadata of the server

=for usage

initCache;

This function retrieves the directory structure of the server

=head2 writeCache

=for save the metadata to files

=for usage

writeCache(directory);

Writes the saved metadata to perl parsable configuration files.
If no argument is supplied the files will be saved to a standard
directory otherwise to the given directory.

=head2 readCache

=for read metadata from files

=for usage

readCache(directory);

Loads the server metadata from local configuration files.
If no argument is supplied the files are read from a standard
directory otherwise from the given one.

=head2 getCacheState

=for returns the status of the cache

=for usage

$ret = getCacheState;

returns either '', 'mem or 'file', if nothing is cached, cache data
was initialized from the server to memory or read from (or already written to ) 
local configuration files, respectively.

=head2 getVersions

=for list the available versions of a certain product

=for usage

@ver = getVersions($product);

Lists the available versions of a certain MODIS product, which
must be supplied as argument.

=head2 isGlobal

=for check whether a certain product is global or sinusoidal

=for usage

$ret = isGlobal($product)

returns either 1(global) or 0 (sinusoidal) for a certain MODIS product

=head2 new

=for initilize a new instance of a WebService::MODIS object

=for usage

$x = WebService::MODIS->new();
$x = WebService::MODIS->new(product => "$product", ...);

Either an empty object can be created and the properties are filled
later on. Available options are:

=over 1

=item product: MODIS product ID as string

=item version: desired version of MODIS product as string of three digits

=item dates: anonymous string array of form YYYY-MM-DD or YYYY.MM.DD

=item ifexactDates: either 1, then the URL for the exact dates in the
dates option is checked or 0 (default) then all possible data between
the minimum und maximum dates is checked.

=item h: the horizontal ID of the MODIS sinusoidal grid

=item v: the vertical ID of the MODIS sinusoidal grid

=item ifExactHV: either 1, then the exact combination of option h and v
are checked or 0 (default), then all combinations between min and max
h and v are checked. Setting it to 1 makes it possible to download
several tiles far away from each other (p.e. Alaska and Australia).

=item targetDir: where to save the data. Can be modified via method "download"

=item forceReload: if set to 1 already files existing will be reloaded from
the server and overwritten.

=back



=head1 METHODS for WebService::MODIS objects

=head2 product

=for setting or retrieving the desired MODIS product

=for usage

$prod = $x->prod($newprod);
$prod = $x->product;

With parameter it checks whether the supplied string is a valid MODIS
product and resets the version to '' and the url list to [];

Without parameter it return the currently set MODIS product.

=head2 version

=for setting or retrieving the version of the desired MODIS product.

=for usage

With parameter it checks if the version is available and sets it. And
resets the url list to []. It makes no sense to set it before the product
is set.

Without parameter it return the currently set version of the MODIS product.

=head2 dates

=for setting or retrieving the dates for which the URLs are prepared

=for usage

$x->dates(["2002-01-01", "2002-12-31"]);
@dates = $x->dates;

Either an anonymous array of date strings (YYYY-MM-DD or YYYY.MM.DD) for
the desired period (resets the url list to []) or no parameter, then the
already set dates are return as array reference.

=head2 h

=for setting or retrieving the horizontal ID of the sinusoidal grid

=for usage

$x->h([1,5]);
@h = $x->h;

Either anonymous array of desired horizontal grid ID of the sinusoidal grid
(resets the url list to []) or nothing, then the already set values are returned.

=head2 v

=for setting or retrieving the vertical ID of the sinusoidal grid

=for usage

$x->v([1,5]);
@v = $x->v;

Either anonymous array of desired vertical grid ID of the sinusoidal grid
(resets the url list to []) or nothing, then the already set values are returned.

=head2 ifExactDates

=for if dates are exact or range

=for usage

$x->ifExactDates(1);
$ret = $x->ifExactDates;

Whether the data between min and max of dates should be retrieved (0, default) or
the data for the exact dates is to be used (all other values). Without parameter
just return the value.

=head2 ifExactHV

=for if h and v pairs  are exact or range

=for usage

$x->ifExactHV(1);
$ret = $x->ifExactHV;

Whether the data between and max of h and v IDs should be retrieved (0, default) or
the data for the exact h and v pairs is to be used (all other values). Without parameter
just return the value.

=head2 createUrl

=for create the URL list for the above initialize instance.

=for usage

$x->createUrl;

Product, dates, h and v values need to be set before this method works.
version, ifExactDates, ifExactHV parameters are optional and set to
reasonable defaults.

=head2 url

=for return the url list for the initialized object

=for usage

@url = $x->url;

return the list of URLs created by createUrl.

=head2 download

=for downloadind the desired hdf files

=for usage

$x->download;
$x->download($targetDirectory);
$x->download($targetDirectory, $force);

Downloads the hdf files to the current working directory or a supplied one.
If the given directory does not exist it will be created if possible. If
any second parameter is given already existing files will be overwritten,
otherwise (default) a already existing files will be checked against the
file size on the server and missing data will be appended if necessary.
createUrl is called from within here if 'url' is unset.

=head1 TODO

=over 4

=item Wrinting a test.pl file

=item Test the module on other operating systems.

=item make_path dies if the path can not be created, catch it or use something else 
for error handling

=back

=head1 SEE ALSO

Description of terrestrial MODIS products can be found on https://lpdaac.usgs.gov/.
The work was inspired by ModisDownload.R (http://r-gis.net/?q=ModisDownload), which
sadly did so far not support continued download if the connection was interrupted,
which happened quiet often for me.

=head1 AUTHOR

Joerg Steinkamp, joergsteinkamp@yahoo.de

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 by Joerg Steinkamp

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.20.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
