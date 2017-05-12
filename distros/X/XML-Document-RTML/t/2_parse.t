# XML::Document::RTML test harness

# strict
use strict;

#load test
use Test::More tests => 12;

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

my $xml = "";
foreach my $i ( 0 ... $#buffer ) {
   $xml = $xml . $buffer[$i];
}   

my $object;
ok ( $object = new XML::Document::RTML( XML => $xml ), 
     "Created the object okay" );

# <RTML type="?">
my $role = $object->role( );
is( $role, "observation", "Comparing type of document via tha role() method" );
my $type = $object->type( );
is( $type, "observation", "Comparing type of document via tha type() method" );

# <RTML version="?">
my $version = $object->version( );
is( $version, "2.2", "Comparing the RTML specification version used" );

# group count
my $groupcount = $object->group_count( );
is( $groupcount, 3, "Group Count" );

# series count
my $seriescount = $object->series_count( );
is( $seriescount, undef, "Series Count" );

# priority
my $priority = $object->priority( );
is( $priority, 3, "Schedule priority" );

# exposure
my $exposure_type = $object->exposure_type();
is( $exposure_type, "time", "Exposure type" );
my $exposure = $object->exposure_time();
cmp_ok($exposure, '==', 30.0, "Exposure time" );

# project
my $project = $object->project();
is( $project, "PL04B17", "Project ID" );

#print Dumper( $object );

# T I M E   A T   T H E   B A R ---------------------------------------------

exit;  

# D A T A   B L O C K --------------------------------------------------------

__DATA__
<?xml version="1.0" encoding="ISO-8859-1"?>
<!DOCTYPE RTML SYSTEM "http://www.estar.org.uk/documents/rtml2.2.dtd">
<RTML version="2.2" type="observation">
  <Contact>
    <Name>Alasdair Allan</Name>
    <User>PATT/keith.horne</User>
    <Institution>eSTAR Project</Institution>
    <Email>aa@astro.ex.ac.uk</Email>
  </Contact>
  <Project>PL04B17</Project>
  <Telescope/>
  <IntelligentAgent host="144.173.229.22" port="2048">001147:UA:v1-24:run#6:user#aa</IntelligentAgent>
  <Observation>
    <Target type="normal" ident="ExoPlanetMonitor">
      <TargetName>OB06515</TargetName>
      <Coordinates>
        <RightAscension units="hms" format="hh mm ss.ss">18 11 48.20</RightAscension>
        <Declination units="dms" format="sdd mm ss.ss">-28 18 59.10</Declination>
        <Equinox>J2000</Equinox>
      </Coordinates>
    </Target>
    <Device type="camera">
      <Filter>
        <FilterType>R</FilterType>
      </Filter>
    </Device>
    <Schedule priority="3">
      <Exposure type="time" units="seconds">
        <Count>3</Count>30.0</Exposure>
      <TimeConstraint>
        <StartDateTime>2006-09-10T11:12:51+0100</StartDateTime>
        <EndDateTime>2006-09-12T00:12:51+0100</EndDateTime>
      </TimeConstraint>
    </Schedule>
    <ImageData type="FITS16" delivery="url" reduced="true">
      <FITSHeader type="all">SIMPLE  =                    T / A valid FITS file                              
BITPIX  =                   16 / Comment                                        
NAXIS   =                    2 / Number of axes                                 
NAXIS1  =                 1024 / Comment                                        
NAXIS2  =                 1024 / Comment                                        
BZERO   =         3.146004E+04 / Comment                                        
BSCALE  =         9.534854E-01 / Comment                                        
ORIGIN  = 'Liverpool JMU'                                                       
OBSTYPE = 'EXPOSE  '           / What type of observation has been taken        
RUNNUM  =                   36 / Number of Multrun                              
EXPNUM  =                    1 / Number of exposure within Multrun              
EXPTOTAL=                    3 / Total number of exposures within Multrun       
DATE    = '2006-09-10'         / [UTC] The start date of the observation        
DATE-OBS= '2006-09-10T22:05:32.463' / [UTC] The start time of the observation   
UTSTART = '22:05:32.463'       / [UTC] The start time of the observation        
MJD     =         53988.920515 / [days] Modified Julian Days.                   
EXPTIME =           30.0000000 / [Seconds] Exposure length.                     
FILTER1 = 'SDSS-R  '           / The first filter wheel filter type.            
FILTERI1= 'SDSS-R-01'          / The first filter wheel filter id.              
FILTER2 = 'clear   '           / The second filter wheel filter type.           
FILTERI2= 'Clear-01'           / The second filter wheel filter id.             
INSTRUME= 'RATCam  '           / Instrument used.                               
INSTATUS= 'Nominal '           / The instrument status.                         
CONFIGID=                52296 / Unique configuration ID.                       
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
CCDATEMP=                  167 / [Kelvin] Actual temperature.                   
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
GROUPID = '001147:UA:v1-24:run#6:user#aa' / Group Id                            
OBSID   = 'ExoPlanetMonitor'   / Observation Id                                 
GRPTIMNG= 'FLEXIBLE'           / Group timing constraint class                  
GRPUID  =                22693 / Group unique ID                                
GRPMONP =            0.0000000 / [secs] Group monitor period                    
GRPNUMOB=                    1 / Number of observations in group                
GRPEDATE= '2006-09-11 T 23:12:51 UTC' / [date] Group expiry date                
GRPNOMEX=          130.0000000 / [secs] Group nominal exec time                 
GRPLUNCO= 'BRIGHT  '           / Maximum lunar brightness                       
GRPSEECO= 'POOR    '           / Minimum seeing                                 
COMPRESS= 'PROFESSIONAL'       / [{PLANETARIUM, PROFESSIONAL, AMATEUR}] Compress
LATITUDE=           28.7624000 / [degrees] Observatory Latitude                 
LONGITUD=          -17.8792000 / [degrees West] Observatory Longitude           
RA      = ' 18:11:48.20'       / [HH:MM:SS.ss] Currently same as CAT_RA         
DEC     = '-28:18:59.10'       / [DD:MM:SS.ss] Currently same as CAT_DEC        
RADECSYS= 'FK5     '           / [{FK4, FK5}] Fundamental coordinate system of c
LST     = ' 20:13:9.00'        / [HH:MM:SS] Local sidereal time at start of curr
EQUINOX =         2000.0000000 / [Years] Date of the coordinate system for curre
CAT-RA  = ' 18:11:48.20'       / [HH:MM:SS.sss] Catalog RA of the current observ
CAT-DEC = '-28:18:59.10'       / [DD:MM:SS.sss] Catalog declination of the curre
CAT-EQUI=         2000.0000000 / [Year] Catalog date of the coordinate system fo
CAT-EPOC=         2000.0000000 / [Year] Catalog date of the epoch               
CAT-NAME= 'OB06515 '           / Catalog name of the current observation source 
OBJECT  = 'OB06515 '           / Actual name of the current observation source  
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
AZDMD   =         -146.9544000 / [degrees] Azimuth demand                       
AZIMUTH =         -146.9547000 / [degrees] Azimuth axis position                
AZSTAT  = 'TRACKING'           / Azimuth axis state                             
ALTDMD  =           26.3643000 / [degrees] Altitude axis demand                 
ALTITUDE=           26.3645000 / [degrees] Altitude axis position               
ALTSTAT = 'TRACKING'           / Altitude axis state                            
AIRMASS =            2.2700000 / [n/a] Airmass                                  
ROTDMD  =           38.7505000 / Rotator axis demand                            
ROTMODE = 'SKY     '           / [{SKY, MOUNT, VFLOAT, VERTICAL, FLOAT}] Cassegr
ROTSKYPA=            0.0001000 / [degrees] Rotator position angle               
ROTANGLE=           38.7510000 / [degrees] Rotator mount angle                  
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
FOCDMD  =           27.2870000 / [mm] Focus demand                              
TELFOCUS=           27.2870000 / [mm] Focus position                            
DFOCUS  =            0.0000000 / [mm] Focus offset                              
FOCSTAT = 'WARNING '           / Focus state                                    
MIRSYSST= 'UNKNOWN '           / Primary mirror support state                   
WMSHUMID=           32.0000000 / [0.00% - 100.00%] Current percentage humidity  
WMSTEMP =          289.6500000 / [Kelvin] Current (external) temperature        
WMSPRES =          782.0000000 / [mbar] Current pressure                        
WINDSPEE=            0.6000000 / [m/s] Windspeed                                
WINDDIR =           37.0000000 / [degrees E of N] Wind direction                
TEMPTUBE=           15.7000000 / [degrees C] Temperature of the telescope tube  
WMSSTATE= 'OKAY    '           / WMS system state                               
WMSRAIN = 'SET     '           / Rain alert                                     
WMSMOIST=            0.0300000 / Moisture level                                 
WMOILTMP=           12.0000000 / Oil temperature                                
WMSPMT  =            0.0000000 / Primary mirror temperature                     
WMFOCTMP=            0.0000000 / Focus temperature                              
WMAGBTMP=            0.0000000 / AG Box temperature                             
WMSDEWPT=           -0.1000000 / Dewpoint                                       
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
MOONFRAC=            0.8538515 / [(0 - 1)] Lunar illuminated fraction           
MOONDIST=          120.3451065 / [(degs)] Lunar Distance from Target            
MOONALT =           10.0533342 / [(degs)] Lunar altitude                        
SCHEDSEE=            0.8437761 / [(arcsec)] Predicted seeing when group schedule
SCHEDPHT=            1.0000000 / [(0-1)] Predicted photom when group scheduled  
ESTSEE  =            1.4040330 / [(arcsec)] Estimated seeing at start of observa
L1MEDIAN=         4.663974E+02 / [counts] median of frame background in counts  
L1MEAN  =         4.667105E+02 / [counts] mean of frame background in counts    
L1STATOV=                   23 / Status flag for DP(RT) overscan correction     
L1STATZE=                   -1 / Status flag for DP(RT) bias frame (zero) correc
L1STATZM=                    1 / Status flag for DP(RT) bias frame subtraction m
L1STATDA=                   -1 / Status flag for DP(RT) dark frame correction   
L1STATTR=                    1 / Status flag for DP(RT) overscan trimming       
L1STATFL=                    1 / Status flag for DP(RT) flatfield correction    
L1XPIX  =         1.301265E+02 / Coordinate of brightest object in frame after t
L1YPIX  =         1.970421E+02 / Coordinate of brightest object in frame after t
L1COUNTS=         1.821113E+06 / [counts] Counts in brightest object (sky subtra
L1SKYBRT=         9.990000E+01 / [mag/arcsec^2] Estimated sky brightness        
L1PHOTOM=        -9.990000E+02 / [mag] Estimated extinction for standards images
L1SAT   =                    F / [logical] TRUE if brightest object is saturated
BACKGRD =         4.663974E+02 / [counts] frame background level in counts      
STDDEV  =         2.904599E+01 / [counts] Standard deviation of Backgrd in count
L1SEEING=         3.341742E+00 / [pixels] frame seeing in pixels                
SEEING  =         3.341742E+00 / [pixels] frame seeing in pixels                
</FITSHeader>
      <ObjectList type="votable-url">http://161.72.57.3/~estar/data/c_e_20060910_36_1_1_1.votable</ObjectList>http://161.72.57.3/~estar/data/c_e_20060910_36_1_1_2.fits</ImageData>
    <ImageData type="FITS16" delivery="url" reduced="true">
      <FITSHeader type="all">SIMPLE  =                    T / A valid FITS file                              
BITPIX  =                   16 / Comment                                        
NAXIS   =                    2 / Number of axes                                 
NAXIS1  =                 1024 / Comment                                        
NAXIS2  =                 1024 / Comment                                        
BZERO   =         3.149694E+04 / Comment                                        
BSCALE  =         9.549181E-01 / Comment                                        
ORIGIN  = 'Liverpool JMU'                                                       
OBSTYPE = 'EXPOSE  '           / What type of observation has been taken        
RUNNUM  =                   36 / Number of Multrun                              
EXPNUM  =                    2 / Number of exposure within Multrun              
EXPTOTAL=                    3 / Total number of exposures within Multrun       
DATE    = '2006-09-10'         / [UTC] The start date of the observation        
DATE-OBS= '2006-09-10T22:06:16.458' / [UTC] The start time of the observation   
UTSTART = '22:06:16.458'       / [UTC] The start time of the observation        
MJD     =         53988.921024 / [days] Modified Julian Days.                   
EXPTIME =           30.0000000 / [Seconds] Exposure length.                     
FILTER1 = 'SDSS-R  '           / The first filter wheel filter type.            
FILTERI1= 'SDSS-R-01'          / The first filter wheel filter id.              
FILTER2 = 'clear   '           / The second filter wheel filter type.           
FILTERI2= 'Clear-01'           / The second filter wheel filter id.             
INSTRUME= 'RATCam  '           / Instrument used.                               
INSTATUS= 'Nominal '           / The instrument status.                         
CONFIGID=                52296 / Unique configuration ID.                       
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
CCDATEMP=                  167 / [Kelvin] Actual temperature.                   
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
GROUPID = '001147:UA:v1-24:run#6:user#aa' / Group Id                            
OBSID   = 'ExoPlanetMonitor'   / Observation Id                                 
GRPTIMNG= 'FLEXIBLE'           / Group timing constraint class                  
GRPUID  =                22693 / Group unique ID                                
GRPMONP =            0.0000000 / [secs] Group monitor period                    
GRPNUMOB=                    1 / Number of observations in group                
GRPEDATE= '2006-09-11 T 23:12:51 UTC' / [date] Group expiry date                
GRPNOMEX=          130.0000000 / [secs] Group nominal exec time                 
GRPLUNCO= 'BRIGHT  '           / Maximum lunar brightness                       
GRPSEECO= 'POOR    '           / Minimum seeing                                 
COMPRESS= 'PROFESSIONAL'       / [{PLANETARIUM, PROFESSIONAL, AMATEUR}] Compress
LATITUDE=           28.7624000 / [degrees] Observatory Latitude                 
LONGITUD=          -17.8792000 / [degrees West] Observatory Longitude           
RA      = ' 18:11:48.20'       / [HH:MM:SS.ss] Currently same as CAT_RA         
DEC     = '-28:18:59.10'       / [DD:MM:SS.ss] Currently same as CAT_DEC        
RADECSYS= 'FK5     '           / [{FK4, FK5}] Fundamental coordinate system of c
LST     = ' 20:13:53.00'       / [HH:MM:SS] Local sidereal time at start of curr
EQUINOX =         2000.0000000 / [Years] Date of the coordinate system for curre
CAT-RA  = ' 18:11:48.20'       / [HH:MM:SS.sss] Catalog RA of the current observ
CAT-DEC = '-28:18:59.10'       / [DD:MM:SS.sss] Catalog declination of the curre
CAT-EQUI=         2000.0000000 / [Year] Catalog date of the coordinate system fo
CAT-EPOC=         2000.0000000 / [Year] Catalog date of the epoch               
CAT-NAME= 'OB06515 '           / Catalog name of the current observation source 
OBJECT  = 'OB06515 '           / Actual name of the current observation source  
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
AZDMD   =         -146.7985000 / [degrees] Azimuth demand                       
AZIMUTH =         -146.7988000 / [degrees] Azimuth axis position                
AZSTAT  = 'TRACKING'           / Azimuth axis state                             
ALTDMD  =           26.2854000 / [degrees] Altitude axis demand                 
ALTITUDE=           26.2855000 / [degrees] Altitude axis position               
ALTSTAT = 'TRACKING'           / Altitude axis state                            
AIRMASS =            2.2800000 / [n/a] Airmass                                  
ROTDMD  =           38.6000000 / Rotator axis demand                            
ROTMODE = 'SKY     '           / [{SKY, MOUNT, VFLOAT, VERTICAL, FLOAT}] Cassegr
ROTSKYPA=            0.0001000 / [degrees] Rotator position angle               
ROTANGLE=           38.6005000 / [degrees] Rotator mount angle                  
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
FOCDMD  =           27.2870000 / [mm] Focus demand                              
TELFOCUS=           27.2870000 / [mm] Focus position                            
DFOCUS  =            0.0000000 / [mm] Focus offset                              
FOCSTAT = 'WARNING '           / Focus state                                    
MIRSYSST= 'UNKNOWN '           / Primary mirror support state                   
WMSHUMID=           33.0000000 / [0.00% - 100.00%] Current percentage humidity  
WMSTEMP =          289.6500000 / [Kelvin] Current (external) temperature        
WMSPRES =          782.0000000 / [mbar] Current pressure                        
WINDSPEE=            2.7000000 / [m/s] Windspeed                                
WINDDIR =           32.0000000 / [degrees E of N] Wind direction                
TEMPTUBE=           15.6900000 / [degrees C] Temperature of the telescope tube  
WMSSTATE= 'OKAY    '           / WMS system state                               
WMSRAIN = 'SET     '           / Rain alert                                     
WMSMOIST=            0.0300000 / Moisture level                                 
WMOILTMP=           12.3000000 / Oil temperature                                
WMSPMT  =            0.0000000 / Primary mirror temperature                     
WMFOCTMP=            0.0000000 / Focus temperature                              
WMAGBTMP=            0.0000000 / AG Box temperature                             
WMSDEWPT=            0.0000000 / Dewpoint                                       
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
MOONFRAC=            0.8538077 / [(0 - 1)] Lunar illuminated fraction           
MOONDIST=          120.3527352 / [(degs)] Lunar Distance from Target            
MOONALT =           10.2075473 / [(degs)] Lunar altitude                        
SCHEDSEE=            0.8437761 / [(arcsec)] Predicted seeing when group schedule
SCHEDPHT=            1.0000000 / [(0-1)] Predicted photom when group scheduled  
ESTSEE  =            1.4040330 / [(arcsec)] Estimated seeing at start of observa
L1MEDIAN=         4.683572E+02 / [counts] median of frame background in counts  
L1MEAN  =         4.686501E+02 / [counts] mean of frame background in counts    
L1STATOV=                   23 / Status flag for DP(RT) overscan correction     
L1STATZE=                   -1 / Status flag for DP(RT) bias frame (zero) correc
L1STATZM=                    1 / Status flag for DP(RT) bias frame subtraction m
L1STATDA=                   -1 / Status flag for DP(RT) dark frame correction   
L1STATTR=                    1 / Status flag for DP(RT) overscan trimming       
L1STATFL=                    1 / Status flag for DP(RT) flatfield correction    
L1XPIX  =         1.294871E+02 / Coordinate of brightest object in frame after t
L1YPIX  =         1.984779E+02 / Coordinate of brightest object in frame after t
L1COUNTS=         1.806546E+06 / [counts] Counts in brightest object (sky subtra
L1SKYBRT=         9.990000E+01 / [mag/arcsec^2] Estimated sky brightness        
L1PHOTOM=        -9.990000E+02 / [mag] Estimated extinction for standards images
L1SAT   =                    F / [logical] TRUE if brightest object is saturated
BACKGRD =         4.683572E+02 / [counts] frame background level in counts      
STDDEV  =         2.913453E+01 / [counts] Standard deviation of Backgrd in count
L1SEEING=         3.241979E+00 / [pixels] frame seeing in pixels                
SEEING  =         3.241979E+00 / [pixels] frame seeing in pixels                
</FITSHeader>
      <ObjectList type="votable-url">http://161.72.57.3/~estar/data/c_e_20060910_36_2_1_1.votable</ObjectList>http://161.72.57.3/~estar/data/c_e_20060910_36_2_1_2.fits</ImageData>
    <ImageData type="FITS16" delivery="url" reduced="true">
      <FITSHeader type="all">SIMPLE  =                    T / A valid FITS file                              
BITPIX  =                   16 / Comment                                        
NAXIS   =                    2 / Number of axes                                 
NAXIS1  =                 1024 / Comment                                        
NAXIS2  =                 1024 / Comment                                        
BZERO   =         2.660922E+04 / Comment                                        
BSCALE  =         8.059768E-01 / Comment                                        
ORIGIN  = 'Liverpool JMU'                                                       
OBSTYPE = 'EXPOSE  '           / What type of observation has been taken        
RUNNUM  =                   36 / Number of Multrun                              
EXPNUM  =                    3 / Number of exposure within Multrun              
EXPTOTAL=                    3 / Total number of exposures within Multrun       
DATE    = '2006-09-10'         / [UTC] The start date of the observation        
DATE-OBS= '2006-09-10T22:07:00.006' / [UTC] The start time of the observation   
UTSTART = '22:07:00.006'       / [UTC] The start time of the observation        
MJD     =         53988.921528 / [days] Modified Julian Days.                   
EXPTIME =           30.0000000 / [Seconds] Exposure length.                     
FILTER1 = 'SDSS-R  '           / The first filter wheel filter type.            
FILTERI1= 'SDSS-R-01'          / The first filter wheel filter id.              
FILTER2 = 'clear   '           / The second filter wheel filter type.           
FILTERI2= 'Clear-01'           / The second filter wheel filter id.             
INSTRUME= 'RATCam  '           / Instrument used.                               
INSTATUS= 'Nominal '           / The instrument status.                         
CONFIGID=                52296 / Unique configuration ID.                       
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
CCDATEMP=                  167 / [Kelvin] Actual temperature.                   
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
GROUPID = '001147:UA:v1-24:run#6:user#aa' / Group Id                            
OBSID   = 'ExoPlanetMonitor'   / Observation Id                                 
GRPTIMNG= 'FLEXIBLE'           / Group timing constraint class                  
GRPUID  =                22693 / Group unique ID                                
GRPMONP =            0.0000000 / [secs] Group monitor period                    
GRPNUMOB=                    1 / Number of observations in group                
GRPEDATE= '2006-09-11 T 23:12:51 UTC' / [date] Group expiry date                
GRPNOMEX=          130.0000000 / [secs] Group nominal exec time                 
GRPLUNCO= 'BRIGHT  '           / Maximum lunar brightness                       
GRPSEECO= 'POOR    '           / Minimum seeing                                 
COMPRESS= 'PROFESSIONAL'       / [{PLANETARIUM, PROFESSIONAL, AMATEUR}] Compress
LATITUDE=           28.7624000 / [degrees] Observatory Latitude                 
LONGITUD=          -17.8792000 / [degrees West] Observatory Longitude           
RA      = ' 18:11:48.20'       / [HH:MM:SS.ss] Currently same as CAT_RA         
DEC     = '-28:18:59.10'       / [DD:MM:SS.ss] Currently same as CAT_DEC        
RADECSYS= 'FK5     '           / [{FK4, FK5}] Fundamental coordinate system of c
LST     = ' 20:14:36.00'       / [HH:MM:SS] Local sidereal time at start of curr
EQUINOX =         2000.0000000 / [Years] Date of the coordinate system for curre
CAT-RA  = ' 18:11:48.20'       / [HH:MM:SS.sss] Catalog RA of the current observ
CAT-DEC = '-28:18:59.10'       / [DD:MM:SS.sss] Catalog declination of the curre
CAT-EQUI=         2000.0000000 / [Year] Catalog date of the coordinate system fo
CAT-EPOC=         2000.0000000 / [Year] Catalog date of the epoch               
CAT-NAME= 'OB06515 '           / Catalog name of the current observation source 
OBJECT  = 'OB06515 '           / Actual name of the current observation source  
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
AZDMD   =         -146.6436000 / [degrees] Azimuth demand                       
AZIMUTH =         -146.6439000 / [degrees] Azimuth axis position                
AZSTAT  = 'TRACKING'           / Azimuth axis state                             
ALTDMD  =           26.2064000 / [degrees] Altitude axis demand                 
ALTITUDE=           26.2065000 / [degrees] Altitude axis position               
ALTSTAT = 'TRACKING'           / Altitude axis state                            
AIRMASS =            2.2800000 / [n/a] Airmass                                  
ROTDMD  =           38.4505000 / Rotator axis demand                            
ROTMODE = 'SKY     '           / [{SKY, MOUNT, VFLOAT, VERTICAL, FLOAT}] Cassegr
ROTSKYPA=           -0.0002000 / [degrees] Rotator position angle               
ROTANGLE=           38.4506000 / [degrees] Rotator mount angle                  
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
FOCDMD  =           27.2870000 / [mm] Focus demand                              
TELFOCUS=           27.2870000 / [mm] Focus position                            
DFOCUS  =            0.0000000 / [mm] Focus offset                              
FOCSTAT = 'TRACKING'           / Focus state                                    
MIRSYSST= 'UNKNOWN '           / Primary mirror support state                   
WMSHUMID=           33.0000000 / [0.00% - 100.00%] Current percentage humidity  
WMSTEMP =          289.6500000 / [Kelvin] Current (external) temperature        
WMSPRES =          782.0000000 / [mbar] Current pressure                        
WINDSPEE=            3.6000000 / [m/s] Windspeed                                
WINDDIR =           46.0000000 / [degrees E of N] Wind direction                
TEMPTUBE=           15.6700000 / [degrees C] Temperature of the telescope tube  
WMSSTATE= 'OKAY    '           / WMS system state                               
WMSRAIN = 'SET     '           / Rain alert                                     
WMSMOIST=            0.0300000 / Moisture level                                 
WMOILTMP=           12.2000000 / Oil temperature                                
WMSPMT  =            0.0000000 / Primary mirror temperature                     
WMFOCTMP=            0.0000000 / Focus temperature                              
WMAGBTMP=            0.0000000 / AG Box temperature                             
WMSDEWPT=            0.1000000 / Dewpoint                                       
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
AGMIRST = 'IN POSN '           / Autoguider mirror state                        
AGFOCDMD=            2.7990000 / [mm] Autoguider focus demand                   
AGFOCUS =            2.7980000 / [mm] Autoguider focus position                 
AGFOCST = 'IN POSN '           / Autoguider focus state                         
AGFILDMD= 'UNKNOWN '           / Autoguider filter demand                       
AGFILPOS= 'UNKNOWN '           / Autoguider filter position                     
AGFILST = 'OVERRIDE'           / Autoguider filter state                        
MOONSTAT= 'UP      '           / [{UP, DOWN}] Moon position at start of current 
MOONFRAC=            0.8537645 / [(0 - 1)] Lunar illuminated fraction           
MOONDIST=          120.3602467 / [(degs)] Lunar Distance from Target            
MOONALT =           10.3595925 / [(degs)] Lunar altitude                        
SCHEDSEE=            0.8437761 / [(arcsec)] Predicted seeing when group schedule
SCHEDPHT=            1.0000000 / [(0-1)] Predicted photom when group scheduled  
ESTSEE  =            1.4040330 / [(arcsec)] Estimated seeing at start of observa
L1MEDIAN=         4.745339E+02 / [counts] median of frame background in counts  
L1MEAN  =         4.745729E+02 / [counts] mean of frame background in counts    
L1STATOV=                   23 / Status flag for DP(RT) overscan correction     
L1STATZE=                   -1 / Status flag for DP(RT) bias frame (zero) correc
L1STATZM=                    1 / Status flag for DP(RT) bias frame subtraction m
L1STATDA=                   -1 / Status flag for DP(RT) dark frame correction   
L1STATTR=                    1 / Status flag for DP(RT) overscan trimming       
L1STATFL=                    1 / Status flag for DP(RT) flatfield correction    
L1XPIX  =         1.286700E+02 / Coordinate of brightest object in frame after t
L1YPIX  =         1.995975E+02 / Coordinate of brightest object in frame after t
L1COUNTS=         1.802759E+06 / [counts] Counts in brightest object (sky subtra
L1SKYBRT=         9.990000E+01 / [mag/arcsec^2] Estimated sky brightness        
L1PHOTOM=        -9.990000E+02 / [mag] Estimated extinction for standards images
L1SAT   =                    F / [logical] TRUE if brightest object is saturated
BACKGRD =         4.745339E+02 / [counts] frame background level in counts      
STDDEV  =         2.893255E+01 / [counts] Standard deviation of Backgrd in count
L1SEEING=         3.548828E+00 / [pixels] frame seeing in pixels                
SEEING  =         3.548828E+00 / [pixels] frame seeing in pixels                
</FITSHeader>
      <ObjectList type="votable-url">http://161.72.57.3/~estar/data/c_e_20060910_36_3_1_1.votable</ObjectList>http://161.72.57.3/~estar/data/c_e_20060910_36_3_1_2.fits</ImageData>
  </Observation>
  <Score>0.10720720720720721</Score>
  <CompletionTime>2006-09-12T00:12:51+0100</CompletionTime>
</RTML>
