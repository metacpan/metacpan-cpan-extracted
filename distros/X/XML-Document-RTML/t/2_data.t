# XML::Document::RTML test harness

# strict
use strict;

#load test
use Test::More tests => 428;

# load modules
BEGIN {
   use_ok("XML::Document::RTML");
}

# debugging
use Data::Dumper;

# T E S T   H A R N E S S --------------------------------------------------

# test the test system
ok(1, "Testing the test harness");

# read from data block
my @buffer = <DATA>;
chomp @buffer;        

my $header = "SIMPLE  =                    T / A valid FITS file                              
BITPIX  =                   16 / Comment                                        
NAXIS   =                    2 / Number of axes                                 
NAXIS1  =                 1024 / Comment                                        
NAXIS2  =                 1024 / Comment                                        
BZERO   =         8.502683E+03 / Comment                                        
BSCALE  =         2.245839E-01 / Comment                                        
ORIGIN  = 'Liverpool JMU'                                                       
OBSTYPE = 'EXPOSE  '           / What type of observation has been taken        
RUNNUM  =                   34 / Number of Multrun                              
EXPNUM  =                    1 / Number of exposure within Multrun              
EXPTOTAL=                    2 / Total number of exposures within Multrun       
DATE    = '2006-10-03'         / [UTC] The start date of the observation        
DATE-OBS= '2006-10-03T20:03:59.229' / [UTC] The start time of the observation   
UTSTART = '20:03:59.229'       / [UTC] The start time of the observation        
MJD     =         54011.836102 / [days] Modified Julian Days.                   
EXPTIME =           99.5000000 / [Seconds] Exposure length.                     
FILTER1 = 'SDSS-R  '           / The first filter wheel filter type.            
FILTERI1= 'SDSS-R-01'          / The first filter wheel filter id.              
FILTER2 = 'clear   '           / The second filter wheel filter type.           
FILTERI2= 'Clear-01'           / The second filter wheel filter id.             
INSTRUME= 'RATCam  '           / Instrument used.                               
INSTATUS= 'Nominal '           / The instrument status.                         
CONFIGID=                56110 / Unique configuration ID.                       
CONFNAME= 'RATCam-SDSS-R-2'    / The instrument configuration used.             
DETECTOR= 'EEV CCD42-40 7041-10-5' / Science grade (1) chip.                    
PRESCAN =                   28 / [pixels] Number of pixels in left bias strip.  
POSTSCAN=                   28 / [pixels] Number of pixels in right bias strip. 
GAIN    =            2.7960000 / [electrons/count] calibrated leach 30/01/2000 1
READNOIS=            7.0000000 / [electrons/pixel] RJS 23/10/2004 (from bias)   
EPERDN  =            2.7960000 / [electrons/count] leach 30/01/2000 14:19.      
CCDXIMSI=                 1024 / [pixels] Imaging pixels                        
CCDYIMSI=                 1024 / [pixels] Imaging pixels                        
CCDXBIN =                    2 / [pixels] X binning factor                      
CCDYBIN =                    2 / [pixels] Y binning factor                      
CCDXPIXE=            0.0000135 / [m] Size of pixels, in X:13.5um                
CCDYPIXE=            0.0000135 / [m] Size of pixels, in Y:13.5um                
CCDSCALE=            0.2783700 / [arcsec/binned pixel] Scale of binned image on 
CCDRDOUT= 'LEFT    '           / Readout circuit used.                          
CCDSTEMP=                  166 / [Kelvin] Required temperature.                 
CCDATEMP=                  166 / [Kelvin] Actual temperature.                   
CCDWMODE=                    F / Using windows if TRUE, full image if FALSE     
CCDWXOFF=                    0 / [pixels] Offset of window in X, from the top co
CCDWYOFF=                    0 / [pixels] Offset of window in Y, from the top co
CCDWXSIZ=                 1024 / [pixels] Size of window in X.                  
CCDWYSIZ=                 1024 / [pixels] Size of window in Y.                  
CALBEFOR=                    F / Whether the calibrate before flag was set      
CALAFTER=                    F / Whether the calibrate after flag was set       
ROTCENTX=                  643 / [pixels] The rotator centre on the CCD, X pixel
ROTCENTY=                  393 / [pixels] The rotator centre on the CCD, Y pixel
TELESCOP= 'Liverpool Telescope' / The Name of the Telescope                     
TELMODE = 'ROBOTIC '           / [{PLANETARIUM, ROBOTIC, MANUAL, ENGINEERING}] T
TAGID   = 'PATT    '           / Telescope Allocation Committee ID              
USERID  = 'keith.horne'        / User login ID                                  
PROPID  = 'PL04B17 '           / Proposal ID                                    
GROUPID = '001518:UA:v1-24:run#10:user#aa' / Group Id                           
OBSID   = 'ExoPlanetMonitor'   / Observation Id                                 
GRPTIMNG= 'MONITOR '           / Group timing constraint class                  
GRPUID  =                24377 / Group unique ID                                
GRPMONP =         1200.0000000 / [secs] Group monitor period                    
GRPNUMOB=                    1 / Number of observations in group                
GRPEDATE= '2006-10-04 T 07:00:05 UTC' / [date] Group expiry date                
GRPNOMEX=          229.0000000 / [secs] Group nominal exec time                 
GRPLUNCO= 'BRIGHT  '           / Maximum lunar brightness                       
GRPSEECO= 'POOR    '           / Minimum seeing                                 
COMPRESS= 'PROFESSIONAL'       / [{PLANETARIUM, PROFESSIONAL, AMATEUR}] Compress
LATITUDE=           28.7624000 / [degrees] Observatory Latitude                 
LONGITUD=          -17.8792000 / [degrees West] Observatory Longitude           
RA      = ' 18:4:4.04'         / [HH:MM:SS.ss] Currently same as CAT_RA         
DEC     = '-28:38:38.70'       / [DD:MM:SS.ss] Currently same as CAT_DEC        
RADECSYS= 'FK5     '           / [{FK4, FK5}] Fundamental coordinate system of c
LST     = ' 19:41:55.00'       / [HH:MM:SS] Local sidereal time at start of curr
EQUINOX =         2000.0000000 / [Years] Date of the coordinate system for curre
CAT-RA  = ' 18:4:4.04'         / [HH:MM:SS.sss] Catalog RA of the current observ
CAT-DEC = '-28:38:38.70'       / [DD:MM:SS.sss] Catalog declination of the curre
CAT-EQUI=         2000.0000000 / [Year] Catalog date of the coordinate system fo
CAT-EPOC=         2000.0000000 / [Year] Catalog date of the epoch               
CAT-NAME= 'OB06251 '           / Catalog name of the current observation source 
OBJECT  = 'OB06251 '           / Actual name of the current observation source  
SRCTYPE = 'EXTRASOLAR'         / [{EXTRASOLAR, MAJORPLANET, MINORPLANET, COMET,]
PM-RA   =            0.0000000 / [sec/year] Proper motion in RA of the current o
PM-DEC  =            0.0000000 / [arcsec/year] Proper motion in declination  of 
PARALLAX=            0.0000000 / [arcsec] Parallax of the current observation so
RADVEL  =            0.0000000 / [km/s] Radial velocity of the current observati
RATRACK =            0.0000000 / [arcsec/sec] Non-sidereal tracking in RA of the
DECTRACK=            0.0000000 / [arcsec/sec] Non-sidereal tracking in declinati
TELSTAT = 'WARN    '           / [---] Current telescope status                 
NETSTATE= 'ENABLED '           / Network control state                          
ENGSTATE= 'DISABLED'           / Engineering override state                     
TCSSTATE= 'OKAY    '           / TCS state                                      
PWRESTRT=                    F / Power will be cycled imminently                
PWSHUTDN=                    F / Power will be shutdown imminently              
AZDMD   =          207.7049000 / [degrees] Azimuth demand                       
AZIMUTH =          207.7045000 / [degrees] Azimuth axis position                
AZSTAT  = 'TRACKING'           / Azimuth axis state                             
ALTDMD  =           28.3936000 / [degrees] Altitude axis demand                 
ALTITUDE=           28.3937000 / [degrees] Altitude axis position               
ALTSTAT = 'TRACKING'           / Altitude axis state                            
AIRMASS =            2.1200000 / [n/a] Airmass                                  
ROTDMD  =           43.8711000 / Rotator axis demand                            
ROTMODE = 'SKY     '           / [{SKY, MOUNT, VFLOAT, VERTICAL, FLOAT}] Cassegr
ROTSKYPA=            0.0000000 / [degrees] Rotator position angle               
ROTANGLE=           43.8715000 / [degrees] Rotator mount angle                  
ROTSTATE= 'TRACKING'           / Rotator axis state                             
ENC1DMD = 'OPEN    '           / Enc 1 demand                                   
ENC1POS = 'OPEN    '           / Enc 1 position                                 
ENC1STAT= 'IN POSN '           / Enc 1 state                                    
ENC2DMD = 'OPEN    '           / Enc 2 demand                                   
ENC2POS = 'OPEN    '           / Enc 2 position                                 
ENC2STAT= 'IN POSN '           / Enc 2 state                                    
FOLDDMD = 'PORT 3  '           / Fold mirror demand                             
FOLDPOS = 'PORT 3  '           / Fold mirror position                           
FOLDSTAT= 'OFF-LINE'           / Fold mirror state                              
PMCDMD  = 'OPEN    '           / Primary mirror cover demand                    
PMCPOS  = 'OPEN    '           / Primary mirror cover position                  
PMCSTAT = 'IN POSN '           / Primary mirror cover state                     
FOCDMD  =           27.3300000 / [mm] Focus demand                              
TELFOCUS=           27.3300000 / [mm] Focus position                            
DFOCUS  =            0.0000000 / [mm] Focus offset                              
FOCSTAT = 'WARNING '           / Focus state                                    
MIRSYSST= 'UNKNOWN '           / Primary mirror support state                   
WMSHUMID=           34.0000000 / [0.00% - 100.00%] Current percentage humidity  
WMSTEMP =          289.1500000 / [Kelvin] Current (external) temperature        
WMSPRES =          782.0000000 / [mbar] Current pressure                        
WINDSPEE=            4.7000000 / [m/s] Windspeed                                
WINDDIR =          119.0000000 / [degrees E of N] Wind direction                
TEMPTUBE=           15.6600000 / [degrees C] Temperature of the telescope tube  
WMSSTATE= 'OKAY    '           / WMS system state                               
WMSRAIN = 'SET     '           / Rain alert                                     
WMSMOIST=            0.0400000 / Moisture level                                 
WMOILTMP=           11.6000000 / Oil temperature                                
WMSPMT  =            0.0000000 / Primary mirror temperature                     
WMFOCTMP=            0.0000000 / Focus temperature                              
WMAGBTMP=            0.0000000 / AG Box temperature                             
WMSDEWPT=            0.3000000 / Dewpoint                                       
REFPRES =          770.0000000 / [mbar] Pressure used in refraction calculation 
REFTEMP =          283.1500000 / [Kelvin] Temperature used in refraction calcula
REFHUMID=           30.0000000 / [0.00% - 100.00%] Percentage humidity used in r
AUTOGUID= 'UNLOCKED'           / [{LOCKED, UNLOCKED SUSPENDED}] Autoguider lock 
AGSTATE = 'OKAY    '           / Autoguider sw state                            
AGMODE  = 'UNKNOWN '           / Autoguider mode                                
AGGMAG  =            0.0000000 / [mag] Autoguider guide star mag                
AGFWHM  =            0.0000000 / [arcsec] Autoguider FWHM                       
AGMIRDMD=            0.0000000 / [mm] Autoguider mirror demand                  
AGMIRPOS=            0.0000000 / [mm] Autoguider mirror position                
AGMIRST = 'WARNING '           / Autoguider mirror state                        
AGFOCDMD=            2.7990000 / [mm] Autoguider focus demand                   
AGFOCUS =            2.7980000 / [mm] Autoguider focus position                 
AGFOCST = 'WARNING '           / Autoguider focus state                         
AGFILDMD= 'UNKNOWN '           / Autoguider filter demand                       
AGFILPOS= 'UNKNOWN '           / Autoguider filter position                     
AGFILST = 'WARNING '           / Autoguider filter state                        
MOONSTAT= 'UP      '           / [{UP, DOWN}] Moon position at start of current 
MOONFRAC=            0.8468916 / [(0 - 1)] Lunar illuminated fraction           
MOONDIST=           53.3774525 / [(degs)] Lunar Distance from Target            
MOONALT =           34.7596645 / [(degs)] Lunar altitude                        
SCHEDSEE=            2.0858450 / [(arcsec)] Predicted seeing when group schedule
SCHEDPHT=            1.0000000 / [(0-1)] Predicted photom when group scheduled  
ESTSEE  =            3.3316001 / [(arcsec)] Estimated seeing at start of observa
L1MEDIAN=         7.023166E+03 / [counts] median of frame background in counts  
L1MEAN  =         7.021803E+03 / [counts] mean of frame background in counts    
L1STATOV=                   23 / Status flag for DP(RT) overscan correction     
L1STATZE=                   -1 / Status flag for DP(RT) bias frame (zero) correc
L1STATZM=                    1 / Status flag for DP(RT) bias frame subtraction m
L1STATDA=                   -1 / Status flag for DP(RT) dark frame correction   
L1STATTR=                    1 / Status flag for DP(RT) overscan trimming       
L1STATFL=                    1 / Status flag for DP(RT) flatfield correction    
L1XPIX  =         4.776160E+02 / Coordinate of brightest object in frame after t
L1YPIX  =         0.000000E+00 / Coordinate of brightest object in frame after t
L1COUNTS=         9.887205E+04 / [counts] Counts in brightest object (sky subtra
L1SKYBRT=         9.990000E+01 / [mag/arcsec^2] Estimated sky brightness        
L1PHOTOM=        -9.990000E+02 / [mag] Estimated extinction for standards images
L1SAT   =                    F / [logical] TRUE if brightest object is saturated
BACKGRD =         7.023166E+03 / [counts] frame background level in counts      
STDDEV  =         1.982379E+02 / [counts] Standard deviation of Backgrd in count
L1SEEING=         9.990000E+02 / [Dummy] Unable to calculate                    
SEEING  =         9.990000E+02 / [Dummy] Unable to calculate                    ";

my @array = ( { 
  Catalogue => 'http://161.72.57.3/~estar/data/c_e_20060910_36_1_1_1.votable',
  URL => 'http://161.72.57.3/~estar/data/c_e_20060910_36_1_1_2.fits',
  Header => $header }, {
  Catalogue => 'http://231.231.45.5/~estar/data/c_e_20060910_36_1_1_1.votable',
  URL => 'http://231.45.45.45/~estar/data/c_e_20060910_36_1_1_2.fits',
  Header => $header } );
   
my $object = new XML::Document::RTML( );
$object->data( @array );      

my $string = Dumper( $object->{DOCUMENT} );
#open FILE, ">file.txt";
#print FILE $string;
#close FILE; 

my @output = split "\n", $string;
foreach my $i  ( 0 ... $#output ) {
  is( $buffer[$i], $output[$i], "Comparing line $i of $#output" );
}

my @pulled = $object->data();
#print Dumper ( @pulled );

foreach my $j ( 0 ... $#pulled ) {
  my %array_hash = %{$array[$j]};
  my %pulled_hash = %{$pulled[$j]};
  cmp_ok( $array_hash{Catalogue}, "eq", $pulled_hash{Catalogue}, "Comparing \%hash{Catalogue}" );
  cmp_ok( $array_hash{URL}, "eq", $pulled_hash{URL}, "Comparing \%hash{URL}" );
  cmp_ok( $array_hash{Header}, "eq", $pulled_hash{Header}, "Comparing \%hash{Header}" );
}
 
#use Astro::FITS::Header;
#my $raw = $pulled[0]{Header};
#my @cards = split "\n", $header;
#my $header = new Astro::FITS::Header( Cards => \@cards );
#print Dumper( $header );
 
# T I M E   A T   T H E   B A R ---------------------------------------------

exit;  

# D A T A   B L O C K --------------------------------------------------------

__DATA__
$VAR1 = {
          'Observation' => {
                             'Device' => {
                                           'Filter' => {
                                                         'FilterType' => 'R'
                                                       },
                                           'type' => 'camera'
                                         },
                             'Target' => {
                                           'type' => 'normal',
                                           'ident' => 'SingleExposure',
                                           'Coordinates' => {
                                                              'RightAscension' => {
                                                                                    'format' => 'hh mm ss.ss',
                                                                                    'units' => 'hms'
                                                                                  },
                                                              'Equinox' => 'J2000',
                                                              'type' => 'equatorial',
                                                              'Declination' => {
                                                                                 'format' => 'dd mm ss.ss',
                                                                                 'units' => 'dms'
                                                                               }
                                                            }
                                         },
                             'ImageData' => [
                                              {
                                                'ObjectList' => {
                                                                  'content' => 'http://161.72.57.3/~estar/data/c_e_20060910_36_1_1_1.votable',
                                                                  'type' => 'votable-url'
                                                                },
                                                'FITSHeader' => {
                                                                  'content' => 'SIMPLE  =                    T / A valid FITS file                              
BITPIX  =                   16 / Comment                                        
NAXIS   =                    2 / Number of axes                                 
NAXIS1  =                 1024 / Comment                                        
NAXIS2  =                 1024 / Comment                                        
BZERO   =         8.502683E+03 / Comment                                        
BSCALE  =         2.245839E-01 / Comment                                        
ORIGIN  = \'Liverpool JMU\'                                                       
OBSTYPE = \'EXPOSE  \'           / What type of observation has been taken        
RUNNUM  =                   34 / Number of Multrun                              
EXPNUM  =                    1 / Number of exposure within Multrun              
EXPTOTAL=                    2 / Total number of exposures within Multrun       
DATE    = \'2006-10-03\'         / [UTC] The start date of the observation        
DATE-OBS= \'2006-10-03T20:03:59.229\' / [UTC] The start time of the observation   
UTSTART = \'20:03:59.229\'       / [UTC] The start time of the observation        
MJD     =         54011.836102 / [days] Modified Julian Days.                   
EXPTIME =           99.5000000 / [Seconds] Exposure length.                     
FILTER1 = \'SDSS-R  \'           / The first filter wheel filter type.            
FILTERI1= \'SDSS-R-01\'          / The first filter wheel filter id.              
FILTER2 = \'clear   \'           / The second filter wheel filter type.           
FILTERI2= \'Clear-01\'           / The second filter wheel filter id.             
INSTRUME= \'RATCam  \'           / Instrument used.                               
INSTATUS= \'Nominal \'           / The instrument status.                         
CONFIGID=                56110 / Unique configuration ID.                       
CONFNAME= \'RATCam-SDSS-R-2\'    / The instrument configuration used.             
DETECTOR= \'EEV CCD42-40 7041-10-5\' / Science grade (1) chip.                    
PRESCAN =                   28 / [pixels] Number of pixels in left bias strip.  
POSTSCAN=                   28 / [pixels] Number of pixels in right bias strip. 
GAIN    =            2.7960000 / [electrons/count] calibrated leach 30/01/2000 1
READNOIS=            7.0000000 / [electrons/pixel] RJS 23/10/2004 (from bias)   
EPERDN  =            2.7960000 / [electrons/count] leach 30/01/2000 14:19.      
CCDXIMSI=                 1024 / [pixels] Imaging pixels                        
CCDYIMSI=                 1024 / [pixels] Imaging pixels                        
CCDXBIN =                    2 / [pixels] X binning factor                      
CCDYBIN =                    2 / [pixels] Y binning factor                      
CCDXPIXE=            0.0000135 / [m] Size of pixels, in X:13.5um                
CCDYPIXE=            0.0000135 / [m] Size of pixels, in Y:13.5um                
CCDSCALE=            0.2783700 / [arcsec/binned pixel] Scale of binned image on 
CCDRDOUT= \'LEFT    \'           / Readout circuit used.                          
CCDSTEMP=                  166 / [Kelvin] Required temperature.                 
CCDATEMP=                  166 / [Kelvin] Actual temperature.                   
CCDWMODE=                    F / Using windows if TRUE, full image if FALSE     
CCDWXOFF=                    0 / [pixels] Offset of window in X, from the top co
CCDWYOFF=                    0 / [pixels] Offset of window in Y, from the top co
CCDWXSIZ=                 1024 / [pixels] Size of window in X.                  
CCDWYSIZ=                 1024 / [pixels] Size of window in Y.                  
CALBEFOR=                    F / Whether the calibrate before flag was set      
CALAFTER=                    F / Whether the calibrate after flag was set       
ROTCENTX=                  643 / [pixels] The rotator centre on the CCD, X pixel
ROTCENTY=                  393 / [pixels] The rotator centre on the CCD, Y pixel
TELESCOP= \'Liverpool Telescope\' / The Name of the Telescope                     
TELMODE = \'ROBOTIC \'           / [{PLANETARIUM, ROBOTIC, MANUAL, ENGINEERING}] T
TAGID   = \'PATT    \'           / Telescope Allocation Committee ID              
USERID  = \'keith.horne\'        / User login ID                                  
PROPID  = \'PL04B17 \'           / Proposal ID                                    
GROUPID = \'001518:UA:v1-24:run#10:user#aa\' / Group Id                           
OBSID   = \'ExoPlanetMonitor\'   / Observation Id                                 
GRPTIMNG= \'MONITOR \'           / Group timing constraint class                  
GRPUID  =                24377 / Group unique ID                                
GRPMONP =         1200.0000000 / [secs] Group monitor period                    
GRPNUMOB=                    1 / Number of observations in group                
GRPEDATE= \'2006-10-04 T 07:00:05 UTC\' / [date] Group expiry date                
GRPNOMEX=          229.0000000 / [secs] Group nominal exec time                 
GRPLUNCO= \'BRIGHT  \'           / Maximum lunar brightness                       
GRPSEECO= \'POOR    \'           / Minimum seeing                                 
COMPRESS= \'PROFESSIONAL\'       / [{PLANETARIUM, PROFESSIONAL, AMATEUR}] Compress
LATITUDE=           28.7624000 / [degrees] Observatory Latitude                 
LONGITUD=          -17.8792000 / [degrees West] Observatory Longitude           
RA      = \' 18:4:4.04\'         / [HH:MM:SS.ss] Currently same as CAT_RA         
DEC     = \'-28:38:38.70\'       / [DD:MM:SS.ss] Currently same as CAT_DEC        
RADECSYS= \'FK5     \'           / [{FK4, FK5}] Fundamental coordinate system of c
LST     = \' 19:41:55.00\'       / [HH:MM:SS] Local sidereal time at start of curr
EQUINOX =         2000.0000000 / [Years] Date of the coordinate system for curre
CAT-RA  = \' 18:4:4.04\'         / [HH:MM:SS.sss] Catalog RA of the current observ
CAT-DEC = \'-28:38:38.70\'       / [DD:MM:SS.sss] Catalog declination of the curre
CAT-EQUI=         2000.0000000 / [Year] Catalog date of the coordinate system fo
CAT-EPOC=         2000.0000000 / [Year] Catalog date of the epoch               
CAT-NAME= \'OB06251 \'           / Catalog name of the current observation source 
OBJECT  = \'OB06251 \'           / Actual name of the current observation source  
SRCTYPE = \'EXTRASOLAR\'         / [{EXTRASOLAR, MAJORPLANET, MINORPLANET, COMET,]
PM-RA   =            0.0000000 / [sec/year] Proper motion in RA of the current o
PM-DEC  =            0.0000000 / [arcsec/year] Proper motion in declination  of 
PARALLAX=            0.0000000 / [arcsec] Parallax of the current observation so
RADVEL  =            0.0000000 / [km/s] Radial velocity of the current observati
RATRACK =            0.0000000 / [arcsec/sec] Non-sidereal tracking in RA of the
DECTRACK=            0.0000000 / [arcsec/sec] Non-sidereal tracking in declinati
TELSTAT = \'WARN    \'           / [---] Current telescope status                 
NETSTATE= \'ENABLED \'           / Network control state                          
ENGSTATE= \'DISABLED\'           / Engineering override state                     
TCSSTATE= \'OKAY    \'           / TCS state                                      
PWRESTRT=                    F / Power will be cycled imminently                
PWSHUTDN=                    F / Power will be shutdown imminently              
AZDMD   =          207.7049000 / [degrees] Azimuth demand                       
AZIMUTH =          207.7045000 / [degrees] Azimuth axis position                
AZSTAT  = \'TRACKING\'           / Azimuth axis state                             
ALTDMD  =           28.3936000 / [degrees] Altitude axis demand                 
ALTITUDE=           28.3937000 / [degrees] Altitude axis position               
ALTSTAT = \'TRACKING\'           / Altitude axis state                            
AIRMASS =            2.1200000 / [n/a] Airmass                                  
ROTDMD  =           43.8711000 / Rotator axis demand                            
ROTMODE = \'SKY     \'           / [{SKY, MOUNT, VFLOAT, VERTICAL, FLOAT}] Cassegr
ROTSKYPA=            0.0000000 / [degrees] Rotator position angle               
ROTANGLE=           43.8715000 / [degrees] Rotator mount angle                  
ROTSTATE= \'TRACKING\'           / Rotator axis state                             
ENC1DMD = \'OPEN    \'           / Enc 1 demand                                   
ENC1POS = \'OPEN    \'           / Enc 1 position                                 
ENC1STAT= \'IN POSN \'           / Enc 1 state                                    
ENC2DMD = \'OPEN    \'           / Enc 2 demand                                   
ENC2POS = \'OPEN    \'           / Enc 2 position                                 
ENC2STAT= \'IN POSN \'           / Enc 2 state                                    
FOLDDMD = \'PORT 3  \'           / Fold mirror demand                             
FOLDPOS = \'PORT 3  \'           / Fold mirror position                           
FOLDSTAT= \'OFF-LINE\'           / Fold mirror state                              
PMCDMD  = \'OPEN    \'           / Primary mirror cover demand                    
PMCPOS  = \'OPEN    \'           / Primary mirror cover position                  
PMCSTAT = \'IN POSN \'           / Primary mirror cover state                     
FOCDMD  =           27.3300000 / [mm] Focus demand                              
TELFOCUS=           27.3300000 / [mm] Focus position                            
DFOCUS  =            0.0000000 / [mm] Focus offset                              
FOCSTAT = \'WARNING \'           / Focus state                                    
MIRSYSST= \'UNKNOWN \'           / Primary mirror support state                   
WMSHUMID=           34.0000000 / [0.00% - 100.00%] Current percentage humidity  
WMSTEMP =          289.1500000 / [Kelvin] Current (external) temperature        
WMSPRES =          782.0000000 / [mbar] Current pressure                        
WINDSPEE=            4.7000000 / [m/s] Windspeed                                
WINDDIR =          119.0000000 / [degrees E of N] Wind direction                
TEMPTUBE=           15.6600000 / [degrees C] Temperature of the telescope tube  
WMSSTATE= \'OKAY    \'           / WMS system state                               
WMSRAIN = \'SET     \'           / Rain alert                                     
WMSMOIST=            0.0400000 / Moisture level                                 
WMOILTMP=           11.6000000 / Oil temperature                                
WMSPMT  =            0.0000000 / Primary mirror temperature                     
WMFOCTMP=            0.0000000 / Focus temperature                              
WMAGBTMP=            0.0000000 / AG Box temperature                             
WMSDEWPT=            0.3000000 / Dewpoint                                       
REFPRES =          770.0000000 / [mbar] Pressure used in refraction calculation 
REFTEMP =          283.1500000 / [Kelvin] Temperature used in refraction calcula
REFHUMID=           30.0000000 / [0.00% - 100.00%] Percentage humidity used in r
AUTOGUID= \'UNLOCKED\'           / [{LOCKED, UNLOCKED SUSPENDED}] Autoguider lock 
AGSTATE = \'OKAY    \'           / Autoguider sw state                            
AGMODE  = \'UNKNOWN \'           / Autoguider mode                                
AGGMAG  =            0.0000000 / [mag] Autoguider guide star mag                
AGFWHM  =            0.0000000 / [arcsec] Autoguider FWHM                       
AGMIRDMD=            0.0000000 / [mm] Autoguider mirror demand                  
AGMIRPOS=            0.0000000 / [mm] Autoguider mirror position                
AGMIRST = \'WARNING \'           / Autoguider mirror state                        
AGFOCDMD=            2.7990000 / [mm] Autoguider focus demand                   
AGFOCUS =            2.7980000 / [mm] Autoguider focus position                 
AGFOCST = \'WARNING \'           / Autoguider focus state                         
AGFILDMD= \'UNKNOWN \'           / Autoguider filter demand                       
AGFILPOS= \'UNKNOWN \'           / Autoguider filter position                     
AGFILST = \'WARNING \'           / Autoguider filter state                        
MOONSTAT= \'UP      \'           / [{UP, DOWN}] Moon position at start of current 
MOONFRAC=            0.8468916 / [(0 - 1)] Lunar illuminated fraction           
MOONDIST=           53.3774525 / [(degs)] Lunar Distance from Target            
MOONALT =           34.7596645 / [(degs)] Lunar altitude                        
SCHEDSEE=            2.0858450 / [(arcsec)] Predicted seeing when group schedule
SCHEDPHT=            1.0000000 / [(0-1)] Predicted photom when group scheduled  
ESTSEE  =            3.3316001 / [(arcsec)] Estimated seeing at start of observa
L1MEDIAN=         7.023166E+03 / [counts] median of frame background in counts  
L1MEAN  =         7.021803E+03 / [counts] mean of frame background in counts    
L1STATOV=                   23 / Status flag for DP(RT) overscan correction     
L1STATZE=                   -1 / Status flag for DP(RT) bias frame (zero) correc
L1STATZM=                    1 / Status flag for DP(RT) bias frame subtraction m
L1STATDA=                   -1 / Status flag for DP(RT) dark frame correction   
L1STATTR=                    1 / Status flag for DP(RT) overscan trimming       
L1STATFL=                    1 / Status flag for DP(RT) flatfield correction    
L1XPIX  =         4.776160E+02 / Coordinate of brightest object in frame after t
L1YPIX  =         0.000000E+00 / Coordinate of brightest object in frame after t
L1COUNTS=         9.887205E+04 / [counts] Counts in brightest object (sky subtra
L1SKYBRT=         9.990000E+01 / [mag/arcsec^2] Estimated sky brightness        
L1PHOTOM=        -9.990000E+02 / [mag] Estimated extinction for standards images
L1SAT   =                    F / [logical] TRUE if brightest object is saturated
BACKGRD =         7.023166E+03 / [counts] frame background level in counts      
STDDEV  =         1.982379E+02 / [counts] Standard deviation of Backgrd in count
L1SEEING=         9.990000E+02 / [Dummy] Unable to calculate                    
SEEING  =         9.990000E+02 / [Dummy] Unable to calculate                    ',
                                                                  'type' => 'all'
                                                                },
                                                'delivery' => 'url',
                                                'content' => 'http://161.72.57.3/~estar/data/c_e_20060910_36_1_1_2.fits',
                                                'reduced' => 'true',
                                                'type' => 'FITS16'
                                              },
                                              {
                                                'ObjectList' => {
                                                                  'content' => 'http://231.231.45.5/~estar/data/c_e_20060910_36_1_1_1.votable',
                                                                  'type' => 'votable-url'
                                                                },
                                                'FITSHeader' => {
                                                                  'content' => 'SIMPLE  =                    T / A valid FITS file                              
BITPIX  =                   16 / Comment                                        
NAXIS   =                    2 / Number of axes                                 
NAXIS1  =                 1024 / Comment                                        
NAXIS2  =                 1024 / Comment                                        
BZERO   =         8.502683E+03 / Comment                                        
BSCALE  =         2.245839E-01 / Comment                                        
ORIGIN  = \'Liverpool JMU\'                                                       
OBSTYPE = \'EXPOSE  \'           / What type of observation has been taken        
RUNNUM  =                   34 / Number of Multrun                              
EXPNUM  =                    1 / Number of exposure within Multrun              
EXPTOTAL=                    2 / Total number of exposures within Multrun       
DATE    = \'2006-10-03\'         / [UTC] The start date of the observation        
DATE-OBS= \'2006-10-03T20:03:59.229\' / [UTC] The start time of the observation   
UTSTART = \'20:03:59.229\'       / [UTC] The start time of the observation        
MJD     =         54011.836102 / [days] Modified Julian Days.                   
EXPTIME =           99.5000000 / [Seconds] Exposure length.                     
FILTER1 = \'SDSS-R  \'           / The first filter wheel filter type.            
FILTERI1= \'SDSS-R-01\'          / The first filter wheel filter id.              
FILTER2 = \'clear   \'           / The second filter wheel filter type.           
FILTERI2= \'Clear-01\'           / The second filter wheel filter id.             
INSTRUME= \'RATCam  \'           / Instrument used.                               
INSTATUS= \'Nominal \'           / The instrument status.                         
CONFIGID=                56110 / Unique configuration ID.                       
CONFNAME= \'RATCam-SDSS-R-2\'    / The instrument configuration used.             
DETECTOR= \'EEV CCD42-40 7041-10-5\' / Science grade (1) chip.                    
PRESCAN =                   28 / [pixels] Number of pixels in left bias strip.  
POSTSCAN=                   28 / [pixels] Number of pixels in right bias strip. 
GAIN    =            2.7960000 / [electrons/count] calibrated leach 30/01/2000 1
READNOIS=            7.0000000 / [electrons/pixel] RJS 23/10/2004 (from bias)   
EPERDN  =            2.7960000 / [electrons/count] leach 30/01/2000 14:19.      
CCDXIMSI=                 1024 / [pixels] Imaging pixels                        
CCDYIMSI=                 1024 / [pixels] Imaging pixels                        
CCDXBIN =                    2 / [pixels] X binning factor                      
CCDYBIN =                    2 / [pixels] Y binning factor                      
CCDXPIXE=            0.0000135 / [m] Size of pixels, in X:13.5um                
CCDYPIXE=            0.0000135 / [m] Size of pixels, in Y:13.5um                
CCDSCALE=            0.2783700 / [arcsec/binned pixel] Scale of binned image on 
CCDRDOUT= \'LEFT    \'           / Readout circuit used.                          
CCDSTEMP=                  166 / [Kelvin] Required temperature.                 
CCDATEMP=                  166 / [Kelvin] Actual temperature.                   
CCDWMODE=                    F / Using windows if TRUE, full image if FALSE     
CCDWXOFF=                    0 / [pixels] Offset of window in X, from the top co
CCDWYOFF=                    0 / [pixels] Offset of window in Y, from the top co
CCDWXSIZ=                 1024 / [pixels] Size of window in X.                  
CCDWYSIZ=                 1024 / [pixels] Size of window in Y.                  
CALBEFOR=                    F / Whether the calibrate before flag was set      
CALAFTER=                    F / Whether the calibrate after flag was set       
ROTCENTX=                  643 / [pixels] The rotator centre on the CCD, X pixel
ROTCENTY=                  393 / [pixels] The rotator centre on the CCD, Y pixel
TELESCOP= \'Liverpool Telescope\' / The Name of the Telescope                     
TELMODE = \'ROBOTIC \'           / [{PLANETARIUM, ROBOTIC, MANUAL, ENGINEERING}] T
TAGID   = \'PATT    \'           / Telescope Allocation Committee ID              
USERID  = \'keith.horne\'        / User login ID                                  
PROPID  = \'PL04B17 \'           / Proposal ID                                    
GROUPID = \'001518:UA:v1-24:run#10:user#aa\' / Group Id                           
OBSID   = \'ExoPlanetMonitor\'   / Observation Id                                 
GRPTIMNG= \'MONITOR \'           / Group timing constraint class                  
GRPUID  =                24377 / Group unique ID                                
GRPMONP =         1200.0000000 / [secs] Group monitor period                    
GRPNUMOB=                    1 / Number of observations in group                
GRPEDATE= \'2006-10-04 T 07:00:05 UTC\' / [date] Group expiry date                
GRPNOMEX=          229.0000000 / [secs] Group nominal exec time                 
GRPLUNCO= \'BRIGHT  \'           / Maximum lunar brightness                       
GRPSEECO= \'POOR    \'           / Minimum seeing                                 
COMPRESS= \'PROFESSIONAL\'       / [{PLANETARIUM, PROFESSIONAL, AMATEUR}] Compress
LATITUDE=           28.7624000 / [degrees] Observatory Latitude                 
LONGITUD=          -17.8792000 / [degrees West] Observatory Longitude           
RA      = \' 18:4:4.04\'         / [HH:MM:SS.ss] Currently same as CAT_RA         
DEC     = \'-28:38:38.70\'       / [DD:MM:SS.ss] Currently same as CAT_DEC        
RADECSYS= \'FK5     \'           / [{FK4, FK5}] Fundamental coordinate system of c
LST     = \' 19:41:55.00\'       / [HH:MM:SS] Local sidereal time at start of curr
EQUINOX =         2000.0000000 / [Years] Date of the coordinate system for curre
CAT-RA  = \' 18:4:4.04\'         / [HH:MM:SS.sss] Catalog RA of the current observ
CAT-DEC = \'-28:38:38.70\'       / [DD:MM:SS.sss] Catalog declination of the curre
CAT-EQUI=         2000.0000000 / [Year] Catalog date of the coordinate system fo
CAT-EPOC=         2000.0000000 / [Year] Catalog date of the epoch               
CAT-NAME= \'OB06251 \'           / Catalog name of the current observation source 
OBJECT  = \'OB06251 \'           / Actual name of the current observation source  
SRCTYPE = \'EXTRASOLAR\'         / [{EXTRASOLAR, MAJORPLANET, MINORPLANET, COMET,]
PM-RA   =            0.0000000 / [sec/year] Proper motion in RA of the current o
PM-DEC  =            0.0000000 / [arcsec/year] Proper motion in declination  of 
PARALLAX=            0.0000000 / [arcsec] Parallax of the current observation so
RADVEL  =            0.0000000 / [km/s] Radial velocity of the current observati
RATRACK =            0.0000000 / [arcsec/sec] Non-sidereal tracking in RA of the
DECTRACK=            0.0000000 / [arcsec/sec] Non-sidereal tracking in declinati
TELSTAT = \'WARN    \'           / [---] Current telescope status                 
NETSTATE= \'ENABLED \'           / Network control state                          
ENGSTATE= \'DISABLED\'           / Engineering override state                     
TCSSTATE= \'OKAY    \'           / TCS state                                      
PWRESTRT=                    F / Power will be cycled imminently                
PWSHUTDN=                    F / Power will be shutdown imminently              
AZDMD   =          207.7049000 / [degrees] Azimuth demand                       
AZIMUTH =          207.7045000 / [degrees] Azimuth axis position                
AZSTAT  = \'TRACKING\'           / Azimuth axis state                             
ALTDMD  =           28.3936000 / [degrees] Altitude axis demand                 
ALTITUDE=           28.3937000 / [degrees] Altitude axis position               
ALTSTAT = \'TRACKING\'           / Altitude axis state                            
AIRMASS =            2.1200000 / [n/a] Airmass                                  
ROTDMD  =           43.8711000 / Rotator axis demand                            
ROTMODE = \'SKY     \'           / [{SKY, MOUNT, VFLOAT, VERTICAL, FLOAT}] Cassegr
ROTSKYPA=            0.0000000 / [degrees] Rotator position angle               
ROTANGLE=           43.8715000 / [degrees] Rotator mount angle                  
ROTSTATE= \'TRACKING\'           / Rotator axis state                             
ENC1DMD = \'OPEN    \'           / Enc 1 demand                                   
ENC1POS = \'OPEN    \'           / Enc 1 position                                 
ENC1STAT= \'IN POSN \'           / Enc 1 state                                    
ENC2DMD = \'OPEN    \'           / Enc 2 demand                                   
ENC2POS = \'OPEN    \'           / Enc 2 position                                 
ENC2STAT= \'IN POSN \'           / Enc 2 state                                    
FOLDDMD = \'PORT 3  \'           / Fold mirror demand                             
FOLDPOS = \'PORT 3  \'           / Fold mirror position                           
FOLDSTAT= \'OFF-LINE\'           / Fold mirror state                              
PMCDMD  = \'OPEN    \'           / Primary mirror cover demand                    
PMCPOS  = \'OPEN    \'           / Primary mirror cover position                  
PMCSTAT = \'IN POSN \'           / Primary mirror cover state                     
FOCDMD  =           27.3300000 / [mm] Focus demand                              
TELFOCUS=           27.3300000 / [mm] Focus position                            
DFOCUS  =            0.0000000 / [mm] Focus offset                              
FOCSTAT = \'WARNING \'           / Focus state                                    
MIRSYSST= \'UNKNOWN \'           / Primary mirror support state                   
WMSHUMID=           34.0000000 / [0.00% - 100.00%] Current percentage humidity  
WMSTEMP =          289.1500000 / [Kelvin] Current (external) temperature        
WMSPRES =          782.0000000 / [mbar] Current pressure                        
WINDSPEE=            4.7000000 / [m/s] Windspeed                                
WINDDIR =          119.0000000 / [degrees E of N] Wind direction                
TEMPTUBE=           15.6600000 / [degrees C] Temperature of the telescope tube  
WMSSTATE= \'OKAY    \'           / WMS system state                               
WMSRAIN = \'SET     \'           / Rain alert                                     
WMSMOIST=            0.0400000 / Moisture level                                 
WMOILTMP=           11.6000000 / Oil temperature                                
WMSPMT  =            0.0000000 / Primary mirror temperature                     
WMFOCTMP=            0.0000000 / Focus temperature                              
WMAGBTMP=            0.0000000 / AG Box temperature                             
WMSDEWPT=            0.3000000 / Dewpoint                                       
REFPRES =          770.0000000 / [mbar] Pressure used in refraction calculation 
REFTEMP =          283.1500000 / [Kelvin] Temperature used in refraction calcula
REFHUMID=           30.0000000 / [0.00% - 100.00%] Percentage humidity used in r
AUTOGUID= \'UNLOCKED\'           / [{LOCKED, UNLOCKED SUSPENDED}] Autoguider lock 
AGSTATE = \'OKAY    \'           / Autoguider sw state                            
AGMODE  = \'UNKNOWN \'           / Autoguider mode                                
AGGMAG  =            0.0000000 / [mag] Autoguider guide star mag                
AGFWHM  =            0.0000000 / [arcsec] Autoguider FWHM                       
AGMIRDMD=            0.0000000 / [mm] Autoguider mirror demand                  
AGMIRPOS=            0.0000000 / [mm] Autoguider mirror position                
AGMIRST = \'WARNING \'           / Autoguider mirror state                        
AGFOCDMD=            2.7990000 / [mm] Autoguider focus demand                   
AGFOCUS =            2.7980000 / [mm] Autoguider focus position                 
AGFOCST = \'WARNING \'           / Autoguider focus state                         
AGFILDMD= \'UNKNOWN \'           / Autoguider filter demand                       
AGFILPOS= \'UNKNOWN \'           / Autoguider filter position                     
AGFILST = \'WARNING \'           / Autoguider filter state                        
MOONSTAT= \'UP      \'           / [{UP, DOWN}] Moon position at start of current 
MOONFRAC=            0.8468916 / [(0 - 1)] Lunar illuminated fraction           
MOONDIST=           53.3774525 / [(degs)] Lunar Distance from Target            
MOONALT =           34.7596645 / [(degs)] Lunar altitude                        
SCHEDSEE=            2.0858450 / [(arcsec)] Predicted seeing when group schedule
SCHEDPHT=            1.0000000 / [(0-1)] Predicted photom when group scheduled  
ESTSEE  =            3.3316001 / [(arcsec)] Estimated seeing at start of observa
L1MEDIAN=         7.023166E+03 / [counts] median of frame background in counts  
L1MEAN  =         7.021803E+03 / [counts] mean of frame background in counts    
L1STATOV=                   23 / Status flag for DP(RT) overscan correction     
L1STATZE=                   -1 / Status flag for DP(RT) bias frame (zero) correc
L1STATZM=                    1 / Status flag for DP(RT) bias frame subtraction m
L1STATDA=                   -1 / Status flag for DP(RT) dark frame correction   
L1STATTR=                    1 / Status flag for DP(RT) overscan trimming       
L1STATFL=                    1 / Status flag for DP(RT) flatfield correction    
L1XPIX  =         4.776160E+02 / Coordinate of brightest object in frame after t
L1YPIX  =         0.000000E+00 / Coordinate of brightest object in frame after t
L1COUNTS=         9.887205E+04 / [counts] Counts in brightest object (sky subtra
L1SKYBRT=         9.990000E+01 / [mag/arcsec^2] Estimated sky brightness        
L1PHOTOM=        -9.990000E+02 / [mag] Estimated extinction for standards images
L1SAT   =                    F / [logical] TRUE if brightest object is saturated
BACKGRD =         7.023166E+03 / [counts] frame background level in counts      
STDDEV  =         1.982379E+02 / [counts] Standard deviation of Backgrd in count
L1SEEING=         9.990000E+02 / [Dummy] Unable to calculate                    
SEEING  =         9.990000E+02 / [Dummy] Unable to calculate                    ',
                                                                  'type' => 'all'
                                                                },
                                                'delivery' => 'url',
                                                'content' => 'http://231.45.45.45/~estar/data/c_e_20060910_36_1_1_2.fits',
                                                'reduced' => 'true',
                                                'type' => 'FITS16'
                                              }
                                            ],
                             'Schedule' => {
                                             'priority' => 3,
                                             'Exposure' => {
                                                             'type' => 'time',
                                                             'units' => 'seconds'
                                                           }
                                           }
                           },
          'version' => '2.2',
          'IntelligentAgent' => {
                                  'port' => 8000,
                                  'host' => '127.0.0.1'
                                }
        };
