use 5.006;
use strict;
use warnings;
use Test::More;

unless ( $ENV{RELEASE_TESTING} ) {
    plan( skip_all => "Author tests not required for installation" );
}

# Ensure a recent version of Test::Pod::Coverage
my $min_tpc = 1.08;
eval "use Test::Pod::Coverage $min_tpc";
plan skip_all => "Test::Pod::Coverage $min_tpc required for testing POD coverage"
    if $@;

# Test::Pod::Coverage doesn't require a minimum Pod::Coverage version,
# but older versions don't recognize some common documentation styles
my $min_pc = 0.18;
eval "use Pod::Coverage $min_pc";
plan skip_all => "Pod::Coverage $min_pc required for testing POD coverage"
    if $@;

# Subs that wrap the underlying WiringPi C library and don't yet have their
# own POD. Remove a name from this list as you document it; when the list is
# empty, drop the trustme arg (or revert to all_pod_coverage_ok()).
my @undocumented = qw(
    ads1115Setup analogRead analogWrite
    bmp180Pressure bmp180Setup bmp180Temp
    delayMicroseconds digitalRead digitalReadByte digitalReadByte2
    digitalWrite digitalWriteByte digitalWriteByte2
    getAlt getPinModeAlt gpioClockSet
    lcdCharDef lcdClear lcdCursor lcdCursorBlink lcdDisplay lcdHome
    lcdInit lcdPosition lcdPutchar lcdPuts lcdSendCommand
    physPinToGpio physPinToWpi
    piBoard40Pin piBoardId piGpioLayout piHiPri piLock piMicros64
    piRP1Model piUnlock pinMode pullUpDnControl
    pwmSetClock pwmSetMode pwmSetRange pwmToneWrite pwmWrite
    serialClose serialDataAvail serialFlush serialGetchar serialGets
    serialOpen serialPutchar serialPuts
    setPadDrive setPadDrivePin
    softPwmCreate softPwmStop softPwmWrite
    softToneCreate softToneStop softToneWrite
    spiDataRW sr595Setup
    wiringPiGlobalMemoryAccess wiringPiGpioDeviceGetFd
    wiringPiI2CRawRead wiringPiI2CRawWrite wiringPiI2CRead
    wiringPiI2CReadBlockData wiringPiI2CReadReg16 wiringPiI2CReadReg8
    wiringPiI2CSetup wiringPiI2CSetupInterface wiringPiI2CWrite
    wiringPiI2CWriteBlockData wiringPiI2CWriteReg16 wiringPiI2CWriteReg8
    wiringPiISRStop
    wiringPiSPIClose wiringPiSPIGetFd wiringPiSPISetup wiringPiSPISetupMode
    wiringPiSetup wiringPiSetupGpio wiringPiSetupGpioDevice
    wiringPiSetupPinType wiringPiUserLevelAccess wiringPiVersion
    wpiPinToGpio
);

pod_coverage_ok(
    'WiringPi::API',
    { trustme => [ map { qr/^\Q$_\E\z/ } @undocumented ] },
    'Pod coverage on WiringPi::API (undocumented C wrappers whitelisted)',
);

done_testing();
