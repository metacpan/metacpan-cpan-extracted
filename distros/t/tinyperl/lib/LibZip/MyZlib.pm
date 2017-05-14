########################
# SIMPLE COMPRESS:ZLIB #
########################

package Compress::Zlib;
#require DynaLoader;
@ISA = qw(DynaLoader);

$VERSION = "1.16" ;

DynaLoader::bootstrap Compress::Zlib $VERSION ;

sub ZLIB_VERSION { 1.1.4 }
sub DEF_WBITS { '' }
sub OS_CODE { '' }
sub MAX_MEM_LEVEL { 9 }
sub MAX_WBITS { 15 }
sub Z_ASCII { 1 }
sub Z_BEST_COMPRESSION { 9 }
sub Z_BEST_SPEED { 1 }
sub Z_BINARY { 0 }
sub Z_BUF_ERROR { -5 }
sub Z_DATA_ERROR { -3 }
sub Z_DEFAULT_COMPRESSION { -1 }
sub Z_DEFAULT_STRATEGY { 0 }
sub Z_DEFLATED { 8 }
sub Z_ERRNO { -1 }
sub Z_FILTERED { 1 }
sub Z_FINISH { 4 }
sub Z_FULL_FLUSH { 3 }
sub Z_HUFFMAN_ONLY { 2 }
sub Z_MEM_ERROR { -4 }
sub Z_NEED_DICT { 2 }
sub Z_NO_COMPRESSION { 0 }
sub Z_NO_FLUSH { 0 }
sub Z_NULL { 0 }
sub Z_OK { 0 }
sub Z_PARTIAL_FLUSH { 1 }
sub Z_STREAM_END { 1 }
sub Z_STREAM_ERROR { -2 }
sub Z_SYNC_FLUSH { 2 }
sub Z_UNKNOWN { 2 }
sub Z_VERSION_ERROR { -6 }


sub ParseParameters($@) {
    my ($default, @rest) = @_ ;
    my (%got) = %$default ;
    my (@Bad) ;
    my ($key, $value) ;
    my $sub = (caller(1))[3] ;
    my %options = () ;

    # allow the options to be passed as a hash reference or
    # as the complete hash.
    if (@rest == 1) {
        %options = %{ $rest[0] } ;
    }
    elsif (@rest >= 2) {
        %options = @rest ;
    }

    while (($key, $value) = each %options)
    {
	$key =~ s/^-// ;

        if (exists $default->{$key})
          { $got{$key} = $value }
        else
	  { push (@Bad, $key) }
    }
    
    if (@Bad) {
        my ($bad) = join(", ", @Bad) ;
    }

    return \%got ;
}

$deflateDefault = {
	'Level'	     =>	Z_DEFAULT_COMPRESSION(),
	'Method'     =>	Z_DEFLATED(),
	'WindowBits' =>	MAX_WBITS(),
	'MemLevel'   =>	MAX_MEM_LEVEL(),
	'Strategy'   =>	Z_DEFAULT_STRATEGY(),
	'Bufsize'    =>	4096,
	'Dictionary' =>	"",
	} ;
 
$deflateParamsDefault = {
	'Level'	     =>	Z_DEFAULT_COMPRESSION(),
	'Strategy'   =>	Z_DEFAULT_STRATEGY(),
	} ;
 
$inflateDefault = {
	'WindowBits' =>	MAX_WBITS(),
	'Bufsize'    =>	4096,
	'Dictionary' =>	"",
	} ;

sub deflateInit {
  my ($got) = ParseParameters($deflateDefault, @_) ;
  _deflateInit($got->{Level}, $got->{Method}, $got->{WindowBits}, 
  $got->{MemLevel}, $got->{Strategy}, $got->{Bufsize},
  $got->{Dictionary}) ;
		
}

sub inflateInit {
  my ($got) = ParseParameters($inflateDefault, @_) ;
  _inflateInit($got->{WindowBits}, $got->{Bufsize}, $got->{Dictionary}) ;
}

##############
# DYNALOADER #
##############
package DynaLoader;

#########
# BEGIN #
#########

sub BEGIN {
 $sep = $^O eq 'MSWin32' ? '\\' : '/';
 $dlext = $^O eq 'MSWin32' ? 'dll' : 'so';
}

sub dl_load_flags { 0x0 }

# cut'n' paste from DynaLoader
sub bootstrap_inherit {
    my $module = $_[0];
    local *isa = *{"$module\::ISA"};
    local @isa = (@isa, 'DynaLoader');
    # Cannot goto due to delocalization.  Will report errors on a wrong line?
    bootstrap(@_);
}


sub croak { die @_ }

# does not handle .bs files
sub bootstrap {
  boot_DynaLoader('DynaLoader') if defined(&boot_DynaLoader) &&
                                  !defined(&dl_error);
                                  
  my $module = $_[0];
  my @modparts = split(/::/,$module);

  my $path = join '/', 'auto', @modparts, $modparts[-1]; $path .= ".$dlext";

  my $file ;
  
  foreach my $INC_i (sort @INC ) {
    my $fl = "$INC_i/$path" ;
    #print "** $fl\n" ;
    if (-e $fl) { $file = $fl ; last ;}
  }
  
  my $bootname = "boot_$module"; $bootname =~ s/\W/_/g;
  @dl_require_symbols = ($bootname);
  my $boot_symbol_ref;
  
  if (!-e $file || $file eq '') { return( undef ) ;}
  
  my $libref = dl_load_file($file, $module->dl_load_flags) or
    croak("Can't load '$file' for module $module: ".dl_error());
  push(@dl_librefs,$libref);  # record loaded object

  $boot_symbol_ref = dl_find_symbol($libref, $bootname) or
    croak("Can't find '$bootname' symbol in $file\n");

  push(@dl_modules, $module); # record loaded module

 boot:
  my $xs = dl_install_xsub("${module}::bootstrap", $boot_symbol_ref, $file);

  # See comment block above
  &$xs(@args);  
}

package XSLoader;

sub load {
  DynaLoader::bootstrap_inherit(@_);
}

#$INC{'XSLoader.pm'} = 'internal';
#$INC{'DynaLoader.pm'} = 'internal';

#######
# END #
#######

1;

