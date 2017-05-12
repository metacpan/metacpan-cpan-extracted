#####
# Copyright (c) 2011-2012, NVIDIA Corporation.  All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# 
#    * Redistributions of source code must retain the above copyright notice,
#      this list of conditions and the following disclaimer.
#    * Redistributions in binary form must reproduce the above copyright
#      notice, this list of conditions and the following disclaimer in the
#      documentation and/or other materials provided with the distribution.
#    * Neither the name of the NVIDIA Corporation nor the names of its
#      contributors may be used to endorse or promote products derived from
#      this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF 
# THE POSSIBILITY OF SUCH DAMAGE.
#####

#
# Perl NVML bindings
#
package nvidia::ml;

use warnings;
use strict;
use nvidia::ml::bindings;
require Exporter;

our @ISA = qw(Exporter);

our $VERSION = "4.304.0";

our @EXPORT_OK =
    qw(
     nvmlDeviceClearEccErrorCounts
     nvmlDeviceGetClockInfo
     nvmlDeviceGetApplicationsClock
     nvmlDeviceResetApplicationsClocks
     nvmlDeviceGetComputeMode
     nvmlDeviceGetComputeRunningProcesses
     nvmlDeviceGetCount
     nvmlDeviceGetCurrPcieLinkGeneration
     nvmlDeviceGetCurrPcieLinkWidth
     nvmlDeviceGetCurrentClocksThrottleReasons
     nvmlDeviceGetDetailedEccErrors
     nvmlDeviceGetDisplayMode
     nvmlDeviceGetDriverModel
     nvmlDeviceGetEccMode
     nvmlDeviceGetFanSpeed
     nvmlDeviceGetHandleByIndex
     nvmlDeviceGetHandleByPciBusId
     nvmlDeviceGetHandleBySerial
     nvmlDeviceGetHandleByUUID
     nvmlDeviceGetInforomConfigurationChecksum
     nvmlDeviceGetInforomImageVersion
     nvmlDeviceGetInforomVersion
     nvmlDeviceGetMaxClockInfo
     nvmlDeviceGetMaxPcieLinkGeneration
     nvmlDeviceGetMaxPcieLinkWidth
     nvmlDeviceGetMemoryInfo
     nvmlDeviceGetName
     nvmlDeviceGetPciInfo
     nvmlDeviceGetPciInfo_v2
     nvmlDeviceGetPerformanceState
     nvmlDeviceGetPersistenceMode
     nvmlDeviceGetGpuOperationMode
     nvmlDeviceGetPowerManagementDefaultLimit
     nvmlDeviceGetPowerManagementLimit
     nvmlDeviceGetPowerManagementLimitConstraints
     nvmlDeviceGetPowerManagementMode
     nvmlDeviceGetPowerState
     nvmlDeviceGetPowerUsage
     nvmlDeviceGetSerial
     nvmlDeviceGetSupportedEventTypes
     nvmlDeviceGetSupportedGraphicsClocks
     nvmlDeviceGetSupportedMemoryClocks
     nvmlDeviceGetSupportedClocksThrottleReasons
     nvmlDeviceGetTemperature
     nvmlDeviceGetTotalEccErrors
     nvmlDeviceGetMemoryErrorCounter
     nvmlDeviceGetUUID
     nvmlDeviceGetUtilizationRates
     nvmlDeviceGetVbiosVersion
     nvmlDeviceOnSameBoard
     nvmlDeviceRegisterEvents
     nvmlDeviceSetApplicationsClocks
     nvmlDeviceSetComputeMode
     nvmlDeviceSetDriverModel
     nvmlDeviceSetEccMode
     nvmlDeviceSetPersistenceMode
     nvmlDeviceSetGpuOperationMode
     nvmlDeviceSetPowerManagementLimit
     nvmlDeviceValidateInforom
     nvmlErrorString
     nvmlEventSetCreate
     nvmlEventSetFree
     nvmlEventSetWait
     nvmlInit
     nvmlInternalGetExportTable
     nvmlShutdown
     nvmlSystemGetDriverVersion
     nvmlSystemGetHicVersion
     nvmlSystemGetNVMLVersion
     nvmlSystemGetProcessName
     nvmlUnitGetCount
     nvmlUnitGetDevices
     nvmlUnitGetFanSpeedInfo
     nvmlUnitGetHandleByIndex
     nvmlUnitGetLedState
     nvmlUnitGetPsuInfo
     nvmlUnitGetTemperature
     nvmlUnitGetUnitInfo
     nvmlUnitSetLedState
     
     $NVML_FEATURE_DISABLED
     $NVML_FEATURE_ENABLED
     $nvmlFlagDefault
     $nvmlFlagForce
     $NVML_TEMPERATURE_GPU
     $NVML_COMPUTEMODE_DEFAULT
     $NVML_COMPUTEMODE_EXCLUSIVE_THREAD
     $NVML_COMPUTEMODE_PROHIBITED
     $NVML_COMPUTEMODE_EXCLUSIVE_PROCESS
     $NVML_SINGLE_BIT_ECC
     $NVML_DOUBLE_BIT_ECC
     $NVML_MEMORY_ERROR_TYPE_CORRECTED
     $NVML_MEMORY_ERROR_TYPE_UNCORRECTED
     $NVML_MEMORY_ERROR_TYPE_COUNT
     $NVML_VOLATILE_ECC
     $NVML_AGGREGATE_ECC
     $NVML_MEMORY_LOCATION_L1_CACHE
     $NVML_MEMORY_LOCATION_L2_CACHE
     $NVML_MEMORY_LOCATION_DEVICE_MEMORY
     $NVML_MEMORY_LOCATION_REGISTER_FILE
     $NVML_MEMORY_LOCATION_TEXTURE_MEMORY
     $NVML_MEMORY_LOCATION_COUNT
     $NVML_CLOCK_GRAPHICS
     $NVML_CLOCK_SM
     $NVML_CLOCK_MEM
     $NVML_CLOCK_COUNT
     $NVML_DRIVER_WDDM
     $NVML_DRIVER_WDM
     $NVML_PSTATE_0
     $NVML_PSTATE_1
     $NVML_PSTATE_2
     $NVML_PSTATE_3
     $NVML_PSTATE_4
     $NVML_PSTATE_5
     $NVML_PSTATE_6
     $NVML_PSTATE_7
     $NVML_PSTATE_8
     $NVML_PSTATE_9
     $NVML_PSTATE_10
     $NVML_PSTATE_11
     $NVML_PSTATE_12
     $NVML_PSTATE_13
     $NVML_PSTATE_14
     $NVML_PSTATE_15
     $NVML_PSTATE_UNKNOWN
     $NVML_INFOROM_OEM
     $NVML_INFOROM_ECC
     $NVML_INFOROM_POWER
     $NVML_INFOROM_COUNT
     $NVML_SUCCESS
     $NVML_ERROR_UNINITIALIZED
     $NVML_ERROR_INVALID_ARGUMENT
     $NVML_ERROR_NOT_SUPPORTED
     $NVML_ERROR_NO_PERMISSION
     $NVML_ERROR_ALREADY_INITIALIZED
     $NVML_ERROR_NOT_FOUND
     $NVML_ERROR_INSUFFICIENT_SIZE
     $NVML_ERROR_INSUFFICIENT_POWER
     $NVML_ERROR_DRIVER_NOT_LOADED
     $NVML_ERROR_TIMEOUT
     $NVML_ERROR_IRQ_ISSUE
     $NVML_ERROR_LIBRARY_NOT_FOUND
     $NVML_ERROR_FUNCTION_NOT_FOUND
     $NVML_ERROR_CORRUPTED_INFOROM
     $NVML_ERROR_UNKNOWN
     $NVML_FAN_NORMAL
     $NVML_FAN_FAILED
     $NVML_LED_COLOR_GREEN
     $NVML_LED_COLOR_AMBER
     $nvmlEventTypeSingleBitEccError
     $nvmlEventTypeDoubleBitEccError
     $nvmlEventTypePState
     $nvmlEventTypeClock
     $nvmlEventTypeXidCriticalError
     $nvmlEventTypeNone
     $nvmlEventTypeAll
     $NVML_DEVICE_INFOROM_VERSION_BUFFER_SIZE
     $NVML_DEVICE_UUID_BUFFER_SIZE
     $NVML_SYSTEM_DRIVER_VERSION_BUFFER_SIZE
     $NVML_SYSTEM_NVML_VERSION_BUFFER_SIZE
     $NVML_DEVICE_NAME_BUFFER_SIZE
     $NVML_DEVICE_SERIAL_BUFFER_SIZE
     $NVML_DEVICE_VBIOS_VERSION_BUFFER_SIZE
     $NVML_GOM_ALL_ON
     $NVML_GOM_COMPUTE
     $NVML_GOM_LOW_DP
     $nvmlClocksThrottleReasonGpuIdle
     $nvmlClocksThrottleReasonUserDefinedClocks
     $nvmlClocksThrottleReasonSwPowerCap
     $nvmlClocksThrottleReasonHwSlowdown
     $nvmlClocksThrottleReasonUnknown
     $nvmlClocksThrottleReasonNone
     $nvmlClocksThrottleReasonAll
    );

# use nvidia::ml qw(:all);
our %EXPORT_TAGS = (all => [@EXPORT_OK]);
Exporter::export_ok_tags('all');

## Enums, constants, variables
foreach my $export (@EXPORT_OK)
{
    if ($export =~ /^\$(.+)$/)
    {
        # Map all variables to be exported to the swig produced bindings
        # New enums, constants and variables must be added to @EXPORT to be mapped
        my $MapExpr = "*" . $1 . " = *nvidia::ml::bindings::" . $1 . ";";
        eval $MapExpr;
    }
}


## Method definitions
*nvmlInit                   = *nvidia::ml::bindings::nvmlInit;
*nvmlShutdown               = *nvidia::ml::bindings::nvmlShutdown;
*nvmlErrorString            = *nvidia::ml::bindings::nvmlErrorString;

sub nvmlSystemGetDriverVersion
{
    return nvidia::ml::bindings::nvmlSystemGetDriverVersion($nvidia::ml::bindings::NVML_SYSTEM_DRIVER_VERSION_BUFFER_SIZE);
}

# Added to API
sub nvmlSystemGetHicVersionCount
{
    my $ret;
    my $count = 0;
    $ret = nvidia::ml::bindings::nvmlSystemGetHicVersion(\$count, undef);
    if ($ret == $nvidia::ml::bindings::NVML_ERROR_INSUFFICIENT_SIZE)
    {
        $ret = $nvidia::ml::bindings::NVML_SUCCESS;
    }
    return ($ret, $count);
}

sub nvmlSystemGetHicVersion
{
    my $ret;
    my $count;
    my $hics;
    my @hicArr;
    my $i = 0;
    
    # get the count
    ($ret, $count) = nvmlSystemGetHicVersionCount();
    if ($ret != $nvidia::ml::bindings::NVML_SUCCESS or $count == 0)
    {
        return ($ret, \())
    }
    
    $hics = nvidia::ml::bindings::new_nvmlHwbcEntry($count);
    
    $ret = nvidia::ml::bindings::nvmlSystemGetHicVersion(\$count, $hics);
    
    if ($ret != $nvidia::ml::bindings::NVML_SUCCESS)
    {
        return ($ret, \())
    }
    
    @hicArr = ();
    foreach $i (0..$count-1)
    {
        my %infohash = ();
        my $item = nvidia::ml::bindings::nvmlHwbcEntry_getitem($hics, $i);
        bless $item, 'nvidia::ml::bindings::nvmlHwbcEntry_t';
        $infohash{'hwbcId'} = $item->swig_hwbcId_get();
        $infohash{'firmwareVersion'} = $item->swig_firmwareVersion_get();
        push @hicArr, \%infohash;
    }
    return ($ret, \@hicArr);
}

sub nvmlSystemGetProcessName
{
    my $pid = shift;
    return nvidia::ml::bindings::nvmlSystemGetProcessName($pid, 1024);
}

sub nvmlSystemGetNVMLVersion
{
    return nvidia::ml::bindings::nvmlSystemGetNVMLVersion($nvidia::ml::bindings::NVML_SYSTEM_NVML_VERSION_BUFFER_SIZE);
}

*nvmlUnitGetCount            = *nvidia::ml::bindings::nvmlUnitGetCount;
*nvmlUnitGetHandleByIndex    = *nvidia::ml::bindings::nvmlUnitGetHandleByIndex;

sub nvmlUnitGetUnitInfo
{
    my $handle = shift;
    my $info = new nvidia::ml::bindings::nvmlUnitInfo_t();
    my $ret = nvidia::ml::bindings::nvmlUnitGetUnitInfo($handle, $info);
    
    my %infohash = ();
    if ($ret == $nvidia::ml::bindings::NVML_SUCCESS)
    {
        $infohash{'name'} = $info->swig_name_get();
        $infohash{'id'} = $info->swig_id_get();
        $infohash{'serial'} = $info->swig_serial_get();
        $infohash{'firmwareVersion'} = $info->swig_firmwareVersion_get();
    }
    
    # C free
    $info->DESTROY();
    
    return ($ret, \%infohash);
}
sub nvmlUnitGetLedState
{
    my $handle = shift;
    my $state = new nvidia::ml::bindings::nvmlLedState_t();
    my $ret = nvidia::ml::bindings::nvmlUnitGetLedState($handle, $state);
    
    my %infohash = ();
    if ($ret == $nvidia::ml::bindings::NVML_SUCCESS)
    {
        $infohash{'cause'} = $state->swig_cause_get();
        $infohash{'color'} = $state->swig_color_get();
    }
    
    # C free
    $state->DESTROY();
    
    return ($ret, \%infohash);
}
sub nvmlUnitGetPsuInfo
{
    my $handle = shift;
    my $info = new nvidia::ml::bindings::nvmlPSUInfo_t();
    my $ret = nvidia::ml::bindings::nvmlUnitGetPsuInfo($handle, $info);
    
    my %infohash = ();
    if ($ret == $nvidia::ml::bindings::NVML_SUCCESS)
    {
        $infohash{'state'} = $info->swig_state_get();
        $infohash{'current'} = $info->swig_current_get();
        $infohash{'voltage'} = $info->swig_voltage_get();
        $infohash{'power'} = $info->swig_power_get();
    }
    
    # C free
    $info->DESTROY();
    
    return ($ret, \%infohash);
}

*nvmlUnitGetTemperature        = *nvidia::ml::bindings::nvmlUnitGetTemperature;

sub nvmlUnitGetFanSpeedInfo
{
    my $handle = shift;

    # C malloc
    my $info = new nvidia::ml::bindings::nvmlUnitFanSpeeds_t();

    my $ret = nvidia::ml::bindings::nvmlUnitGetFanSpeedInfo($handle, $info);
    
    my @fanInfo = ();
    if ($ret == $nvidia::ml::bindings::NVML_SUCCESS)
    {
        my $fans = $info->swig_fans_get();
        my $count = $info->swig_count_get();
        
        
        foreach my $i (0..$count-1)
        {
            my %infohash = ();
            my $fan = nvidia::ml::bindings::_getFanInfoByIndex($fans, $i);
            bless $fan, 'nvidia::ml::bindings::nvmlUnitFanInfo_t';
            $infohash{'state'} = $fan->swig_state_get();
            $infohash{'speed'} = $fan->swig_speed_get();
            push @fanInfo, \%infohash;
        }
    }
   
    # C free
    $info->DESTROY();
    
    return ($ret, \@fanInfo);
}

sub nvmlUnitGetDevices
{
    my $handle = shift;
    my $count;
    my $ret;
    my $devices;
    
    # first get the count
    ($ret, $count) = nvidia::ml::bindings::_nvmlUnitGetDevices($handle, 0, undef);
    if ($ret != $nvidia::ml::bindings::NVML_SUCCESS &&
        $ret != $nvidia::ml::bindings::NVML_ERROR_INSUFFICIENT_SIZE)
    {
        return ($ret, -1, undef);
    }
    
    # create an array of the needed size
    $devices = nvidia::ml::bindings::_createDeviceArray($count);
    
    # get the devices
    ($ret, $count) = nvidia::ml::bindings::_nvmlUnitGetDevices($handle, $count, $devices);
    
    my @devs = ();
    
    if ($ret == $nvidia::ml::bindings::NVML_SUCCESS)
    {
        foreach my $i (0..$count-1)
        {
            my $dev = nvidia::ml::bindings::_getDeviceByIndex($devices, $i);
            bless $dev, 'nvidia::ml::bindings::nvmlDevice_t';
            push @devs, $dev;
        }
    }
    
    nvidia::ml::bindings::_freeDeviceArray($devices);
    
    return ($ret, $count, \@devs);
}

*nvmlDeviceGetCount          = *nvidia::ml::bindings::nvmlDeviceGetCount;
*nvmlDeviceGetHandleByIndex  = *nvidia::ml::bindings::nvmlDeviceGetHandleByIndex;
*nvmlDeviceGetHandleBySerial = *nvidia::ml::bindings::nvmlDeviceGetHandleBySerial;
*nvmlDeviceGetHandleByPciBusId = *nvidia::ml::bindings::nvmlDeviceGetHandleByPciBusId;
*nvmlDeviceGetHandleByUUID   = *nvidia::ml::bindings::nvmlDeviceGetHandleByUUID;

sub nvmlDeviceGetName
{
    my $handle = shift;
    return nvidia::ml::bindings::nvmlDeviceGetName($handle, $nvidia::ml::bindings::NVML_DEVICE_NAME_BUFFER_SIZE);
}
sub nvmlDeviceGetSerial
{
    my $handle = shift;
    return nvidia::ml::bindings::nvmlDeviceGetSerial($handle, $nvidia::ml::bindings::NVML_DEVICE_SERIAL_BUFFER_SIZE);
}
sub nvmlDeviceGetUUID
{
    my $handle = shift;
    return nvidia::ml::bindings::nvmlDeviceGetUUID($handle, $nvidia::ml::bindings::NVML_DEVICE_UUID_BUFFER_SIZE);
}
sub nvmlDeviceGetInforomVersion
{
    my $handle = shift;
    my $object = shift;
    return nvidia::ml::bindings::nvmlDeviceGetInforomVersion($handle, $object, $nvidia::ml::bindings::NVML_DEVICE_INFOROM_VERSION_BUFFER_SIZE);
}
sub nvmlDeviceGetInforomImageVersion
{
    my $handle = shift;
    return nvidia::ml::bindings::nvmlDeviceGetInforomImageVersion($handle, $nvidia::ml::bindings::NVML_DEVICE_INFOROM_VERSION_BUFFER_SIZE);
}

*nvmlDeviceGetInforomConfigurationChecksum = *nvidia::ml::bindings::nvmlDeviceGetInforomConfigurationChecksum;
*nvmlDeviceGetDisplayMode     = *nvidia::ml::bindings::nvmlDeviceGetDisplayMode;
*nvmlDeviceGetPersistenceMode = *nvidia::ml::bindings::nvmlDeviceGetPersistenceMode;

sub nvmlDeviceGetPciInfo
{
    my $handle = shift;
    my $info = new nvidia::ml::bindings::nvmlPciInfo_t();
    my $ret = nvidia::ml::bindings::nvmlDeviceGetPciInfo_v2($handle, $info);
    
    my %infohash = ();
    if ($ret == $nvidia::ml::bindings::NVML_SUCCESS)
    {
        $infohash{'busId'} = $info->swig_busId_get();
        $infohash{'domain'} = $info->swig_domain_get();
        $infohash{'bus'} = $info->swig_bus_get();
        $infohash{'device'} = $info->swig_device_get();
        $infohash{'pciDeviceId'} = $info->swig_pciDeviceId_get();
        
        # added in 2.0 API
        $infohash{'pciSubSystemId'} = $info->swig_pciSubSystemId_get();
        $infohash{'reserved0'} = $info->swig_reserved0_get();
        $infohash{'reserved1'} = $info->swig_reserved1_get();
        $infohash{'reserved2'} = $info->swig_reserved2_get();
        $infohash{'reserved3'} = $info->swig_reserved3_get();
    }
    
    # C free
    $info->DESTROY();
    
    return ($ret, \%infohash);
}

*nvmlDeviceGetClockInfo            = *nvidia::ml::bindings::nvmlDeviceGetClockInfo;
*nvmlDeviceGetMaxClockInfo         = *nvidia::ml::bindings::nvmlDeviceGetMaxClockInfo;
*nvmlDeviceGetApplicationsClock    = *nvidia::ml::bindings::nvmlDeviceGetApplicationsClock;
*nvmlDeviceResetApplicationsClocks = *nvidia::ml::bindings::nvmlDeviceResetApplicationsClocks;
*nvmlDeviceGetFanSpeed             = *nvidia::ml::bindings::nvmlDeviceGetFanSpeed;
*nvmlDeviceGetTemperature          = *nvidia::ml::bindings::nvmlDeviceGetTemperature;

# DEPRECATED Use nvmlDeviceGetPerformanceState instead
*nvmlDeviceGetPowerState           = *nvidia::ml::bindings::nvmlDeviceGetPowerState;

*nvmlDeviceGetPerformanceState     = *nvidia::ml::bindings::nvmlDeviceGetPerformanceState;

*nvmlDeviceGetGpuOperationMode = *nvidia::ml::bindings::nvmlDeviceGetGpuOperationMode;

*nvmlDeviceGetPowerManagementMode  = *nvidia::ml::bindings::nvmlDeviceGetPowerManagementMode;
*nvmlDeviceGetPowerManagementLimit = *nvidia::ml::bindings::nvmlDeviceGetPowerManagementLimit;
*nvmlDeviceGetPowerManagementLimitConstraints = *nvidia::ml::bindings::nvmlDeviceGetPowerManagementLimitConstraints;
*nvmlDeviceGetPowerManagementDefaultLimit     = *nvidia::ml::bindings::nvmlDeviceGetPowerManagementDefaultLimit;
*nvmlDeviceGetPowerUsage           = *nvidia::ml::bindings::nvmlDeviceGetPowerUsage;

sub nvmlDeviceGetMemoryInfo
{
    my $handle = shift;
    my $info = new nvidia::ml::bindings::nvmlMemory_t();
    my $ret = nvidia::ml::bindings::nvmlDeviceGetMemoryInfo($handle, $info);
    
    my %infohash = ();
    if ($ret == $nvidia::ml::bindings::NVML_SUCCESS)
    {
        $infohash{'total'} = int($info->swig_total_get());
        $infohash{'free'}  = int($info->swig_free_get());
        $infohash{'used'}  = int($info->swig_used_get());
    }
    
    # C free
    $info->DESTROY();
    
    return ($ret, \%infohash);
}

*nvmlDeviceGetComputeMode        = *nvidia::ml::bindings::nvmlDeviceGetComputeMode;
*nvmlDeviceGetEccMode            = *nvidia::ml::bindings::nvmlDeviceGetEccMode;

sub nvmlDeviceGetTotalEccErrors
{
    my $handle = shift;
    my $errorType = shift;
    my $counterType = shift;
    my ($ret, $count) = nvidia::ml::bindings::nvmlDeviceGetTotalEccErrors($handle, $errorType, $counterType);
    if ($ret == $nvidia::ml::bindings::NVML_SUCCESS)
    {
        $count = int($count);
    }
    return ($ret, $count);
}

sub nvmlDeviceGetMemoryErrorCounter
{
    my $handle = shift;
    my $errorType = shift;
    my $counterType = shift;
    my $locationType = shift;
    
    my ($ret, $count) = nvidia::ml::bindings::nvmlDeviceGetMemoryErrorCounter($handle, $errorType,
        $counterType, $locationType);
    if ($ret == $nvidia::ml::bindings::NVML_SUCCESS)
    {
        $count = int($count);
    }
    return ($ret, $count);
}

# This is deprecated, instead use nvmlDeviceGetMemoryErrorCounter
sub nvmlDeviceGetDetailedEccErrors
{
    my $handle = shift;
    my $bitType = shift;
    my $counterType = shift;
    my $info = new nvidia::ml::bindings::nvmlEccErrorCounts_t();
    my $ret = nvidia::ml::bindings::nvmlDeviceGetDetailedEccErrors($handle, $bitType, $counterType, $info);
    
    my %infohash = ();
    if ($ret == $nvidia::ml::bindings::NVML_SUCCESS)
    {
        $infohash{'l1Cache'}      = int($info->swig_l1Cache_get());
        $infohash{'l2Cache'}      = int($info->swig_l2Cache_get());
        $infohash{'deviceMemory'} = int($info->swig_deviceMemory_get());
        $infohash{'registerFile'} = int($info->swig_registerFile_get());
    }
    
    # C free
    $info->DESTROY();
    
    return ($ret, \%infohash);
}
sub nvmlDeviceGetUtilizationRates
{
    my $handle = shift;
    my $info = new nvidia::ml::bindings::nvmlUtilization_t();
    my $ret = nvidia::ml::bindings::nvmlDeviceGetUtilizationRates($handle, $info);
    
    my %infohash = ();
    if ($ret == $nvidia::ml::bindings::NVML_SUCCESS)
    {
        $infohash{'gpu'}    = $info->swig_gpu_get();
        $infohash{'memory'} = $info->swig_memory_get();
    }
    
    # C free
    $info->DESTROY();
    
    return ($ret, \%infohash);
}

*nvmlDeviceGetDriverModel      = *nvidia::ml::bindings::nvmlDeviceGetDriverModel;

sub nvmlDeviceGetVbiosVersion
{
    my $handle = shift;
    return nvidia::ml::bindings::nvmlDeviceGetVbiosVersion($handle, $nvidia::ml::bindings::NVML_DEVICE_VBIOS_VERSION_BUFFER_SIZE);
}

sub nvmlDeviceGetComputeRunningProcesses
{
    my $handle = shift;
    my $infoCount;
    my $infos;
    my $ret;
    
    ($ret, $infoCount) = nvidia::ml::bindings::_nvmlDeviceGetComputeRunningProcesses($handle, 0, undef);
    if ($ret == $nvidia::ml::bindings::NVML_SUCCESS)
    {
        # empty set
        my @set = ();
        return ($ret, \@set);
    }
    
    if ($ret != $nvidia::ml::bindings::NVML_ERROR_INSUFFICIENT_SIZE)
    {
        # error
        my @set = ();
        return ($ret, \@set);
    }
    
    # oversize the array incase processes are created
    $infoCount = $infoCount * 2 + 5;
    
    # create an array of the needed size
    my $procs = nvidia::ml::bindings::_createProcessArray($infoCount);
    
    # get the devices
    ($ret, $infoCount) = nvidia::ml::bindings::_nvmlDeviceGetComputeRunningProcesses($handle, $infoCount, $procs);
    
    my @pl_procs = ();
    if ($ret == $nvidia::ml::bindings::NVML_SUCCESS)
    {
        foreach my $i (0..$infoCount-1)
        {
            my $proc = nvidia::ml::bindings::_getProcessByIndex($procs, $i);
            bless $proc, 'nvidia::ml::bindings::nvmlProcessInfo_t';
            
            my %infohash = ();
            $infohash{'pid'}           = $proc->swig_pid_get();
            $infohash{'usedGpuMemory'} = int($proc->swig_usedGpuMemory_get());
            
            if ($infohash{'usedGpuMemory'} == int(nvidia::ml::bindings::_nvmlGetValueNotAvailable_ulonglong()))
            {
                # set to undef instead
                $infohash{'usedGpuMemory'} = undef;
            }
            push @pl_procs, \%infohash;
        }
    }
    nvidia::ml::bindings::_freeProcessArray($procs);
    
    return ($ret, \@pl_procs);
}

sub nvmlDeviceGetSupportedMemoryClocks
{
    my $handle = shift;
    my $clockCount;
    my $ret;
    
    ($ret, $clockCount) = nvidia::ml::bindings::_nvmlDeviceGetSupportedMemoryClocks($handle, 0, undef);
    if ($ret == $nvidia::ml::bindings::NVML_SUCCESS)
    {
        # empty set
        my @set = ();
        return ($ret, \@set);
    }
    
    if ($ret != $nvidia::ml::bindings::NVML_ERROR_INSUFFICIENT_SIZE)
    {
        # error
        my @set = ();
        return ($ret, \@set);
    }
    
    # create an array of the needed size
    my $clocks = nvidia::ml::bindings::_createUIntArray($clockCount);
    
    # get the clocks
    ($ret, $clockCount) = nvidia::ml::bindings::_nvmlDeviceGetSupportedMemoryClocks($handle, $clockCount, $clocks);
    
    my @pl_clocks = ();
    if ($ret == $nvidia::ml::bindings::NVML_SUCCESS)
    {
        foreach my $i (0..$clockCount-1)
        {
            my $clock = nvidia::ml::bindings::_getUIntByIndex($clocks, $i);
            push @pl_clocks, $clock;
        }
    }
    nvidia::ml::bindings::_freeUIntArray($clocks);
    
    return ($ret, \@pl_clocks);
}

sub nvmlDeviceGetSupportedGraphicsClocks
{
    my $handle = shift;
    my $memoryClockMHz = shift;
    my $clockCount;
    my $ret;
    
    ($ret, $clockCount) = nvidia::ml::bindings::_nvmlDeviceGetSupportedGraphicsClocks($handle, $memoryClockMHz, 0, undef);
    if ($ret == $nvidia::ml::bindings::NVML_SUCCESS)
    {
        # empty set
        my @set = ();
        return ($ret, \@set);
    }
    
    if ($ret != $nvidia::ml::bindings::NVML_ERROR_INSUFFICIENT_SIZE)
    {
        # error
        my @set = ();
        return ($ret, \@set);
    }
    
    # create an array of the needed size
    my $clocks = nvidia::ml::bindings::_createUIntArray($clockCount);
    
    # get the clocks
    ($ret, $clockCount) = nvidia::ml::bindings::_nvmlDeviceGetSupportedGraphicsClocks($handle, $memoryClockMHz, $clockCount, $clocks);
    
    my @pl_clocks = ();
    if ($ret == $nvidia::ml::bindings::NVML_SUCCESS)
    {
        foreach my $i (0..$clockCount-1)
        {
            my $clock = nvidia::ml::bindings::_getUIntByIndex($clocks, $i);
            push @pl_clocks, $clock;
        }
    }
    nvidia::ml::bindings::_freeUIntArray($clocks);
    
    return ($ret, \@pl_clocks);
}

*nvmlUnitSetLedState           = *nvidia::ml::bindings::nvmlUnitSetLedState;
*nvmlDeviceSetPersistenceMode  = *nvidia::ml::bindings::nvmlDeviceSetPersistenceMode;
*nvmlDeviceSetComputeMode      = *nvidia::ml::bindings::nvmlDeviceSetComputeMode;
*nvmlDeviceSetEccMode          = *nvidia::ml::bindings::nvmlDeviceSetEccMode;
*nvmlDeviceClearEccErrorCounts = *nvidia::ml::bindings::nvmlDeviceClearEccErrorCounts;
*nvmlDeviceSetDriverModel      = *nvidia::ml::bindings::nvmlDeviceSetDriverModel;
*nvmlDeviceSetApplicationsClocks      = *nvidia::ml::bindings::nvmlDeviceSetApplicationsClocks;
*nvmlDeviceSetGpuOperationMode = *nvidia::ml::bindings::nvmlDeviceSetGpuOperationMode;
*nvmlDeviceSetPowerManagementLimit = *nvidia::ml::bindings::nvmlDeviceSetPowerManagementLimit;

*nvmlDeviceValidateInforom     = *nvidia::ml::bindings::nvmlDeviceValidateInforom;

# events
*nvmlEventSetCreate               = *nvidia::ml::bindings::nvmlEventSetCreate;
*nvmlDeviceRegisterEvents         = *nvidia::ml::bindings::nvmlDeviceRegisterEvents;
sub nvmlDeviceGetSupportedEventTypes
{
    my $handle = shift;
    my ($ret, $types) = nvidia::ml::bindings::nvmlDeviceGetSupportedEventTypes($handle);
    if ($ret == $nvidia::ml::bindings::NVML_SUCCESS)
    {
        $types = int($types);
    }
    return ($ret, $types);
}

sub nvmlEventSetWait
{
    my $set = shift;
    my $timeoutms = shift;
    my $data = new nvidia::ml::bindings::nvmlEventData_t();
    my $ret;
    
    $ret = nvidia::ml::bindings::nvmlEventSetWait($set, $data, $timeoutms);
    
    my $retVal = undef;
    if ($ret == $nvidia::ml::bindings::NVML_SUCCESS)
    {
        my %infohash = ();
        $infohash{'device'}           = $data->swig_device_get();
        $infohash{'eventType'}        = int($data->swig_eventType_get());
        $infohash{'reserved'}         = int($data->swig_reserved_get());
        $retVal = \%infohash;
    }
    $data->DESTROY();
    return ($ret, $retVal);
}

*nvmlEventSetFree                 = *nvidia::ml::bindings::nvmlEventSetFree;
*nvmlDeviceOnSameBoard                  = *nvidia::ml::bindings::nvmlDeviceOnSameBoard;

*nvmlDeviceGetMaxPcieLinkGeneration     = *nvidia::ml::bindings::nvmlDeviceGetMaxPcieLinkGeneration;
*nvmlDeviceGetCurrPcieLinkGeneration    = *nvidia::ml::bindings::nvmlDeviceGetCurrPcieLinkGeneration;
*nvmlDeviceGetMaxPcieLinkWidth          = *nvidia::ml::bindings::nvmlDeviceGetMaxPcieLinkWidth;
*nvmlDeviceGetCurrPcieLinkWidth         = *nvidia::ml::bindings::nvmlDeviceGetCurrPcieLinkWidth;

sub nvmlDeviceGetSupportedClocksThrottleReasons
{
    my $handle = shift;
    my ($ret, $reasons) = nvidia::ml::bindings::nvmlDeviceGetSupportedClocksThrottleReasons($handle);
    if ($ret == $nvidia::ml::bindings::NVML_SUCCESS)
    {
        $reasons = int($reasons);
    }
    return ($ret, $reasons);
}

sub nvmlDeviceGetCurrentClocksThrottleReasons
{
    my $handle = shift;
    my ($ret, $reasons) = nvidia::ml::bindings::nvmlDeviceGetCurrentClocksThrottleReasons($handle);
    if ($ret == $nvidia::ml::bindings::NVML_SUCCESS)
    {
        $reasons = int($reasons);
    }
    return ($ret, $reasons);
}

1;

__END__

=head1 NAME

nvidia::ml - Perl bindings to NVML, the NVIDIA Management Library

=head1 SYNOPSIS

    use nvidia::ml qw(:all);
 
    nvmlInit();
 
    ($ret, $version) = nvmlSystemGetDriverVersion();
    die nvmlErrorString($ret) unless $ret == $nvidia::ml::bindings::NVML_SUCCESS;
    print "Driver version: " . $version . "\n";
 
    ($ret, $count) = nvmlDeviceGetCount();
    die nvmlErrorString($ret) unless $ret == $nvidia::ml::bindings::NVML_SUCCESS;
 
    for ($i=0; $i<$count; $i++)
    {
        ($ret, $handle) = nvmlDeviceGetHandleByIndex($i);
        next if $ret != $nvidia::ml::bindings::NVML_SUCCESS;
     
        ($ret, $speed) = nvmlDeviceGetFanSpeed($handle);
        next if $ret != $nvidia::ml::bindings::NVML_SUCCESS;
        print "Device " . $i . " fan speed: " . $speed . "%\n";
     
        ($ret, $info) = nvmlDeviceGetMemoryInfo($handle);
        next if $ret != $nvidia::ml::bindings::NVML_SUCCESS;
        $total = ($info->{"total"} / 1024 / 1024);
        print "Device " . $i . " total memory: " . $total . " MB\n";
    }
 
    nvmlShutdown();

=head1 DESCRIPTION

Provides a Perl interface to GPU management and monitoring functions.

This is a wrapper around the NVML library.  For information about the NVML library, see the NVML documentation.

=head1 REQUIRES

Exporter

=head1 EXPORTS

This module has no exports.  To add functions and constants to your namespace use:
use nvidia::ml qw(:all);

=head1 METHODS

See EXPORTS and NVML documentation.  Perl methods wrap NVML functions, implemented in a C shared library.  The functions use is the same with the following exceptions:

=over 4

=item Perl methods accept the input arguments of the C function it wraps only.  All C function output parameters are returned after the return code, left to right

 C:
 nvmlReturn_t nvmlDeviceGetEccMode(nvmlDevice_t device,
                                   nvmlEnableState_t *current,
                                   nvmlEnableState_t *pending);
 Perl:
 ($ret, $current, $pending) = nvmlDeviceGetEccMode($device); 

=item Perl handles string buffer creation

 C:
 nvmlReturn_t nvmlSystemGetDriverVersion(char* version,
                                         unsigned int length);
 Perl:
 ($ret, $version) = nvmlSystemGetDriverVersion();

=item C structs are converted to Perl hashes, nested as needed

 C:
 nvmlReturn_t DECLDIR nvmlDeviceGetMemoryInfo(nvmlDevice_t device,
                                              nvmlMemory_t *memory);
 typedef struct nvmlMemory_st {
     unsigned long long total;
     unsigned long long free;
     unsigned long long used;
 } nvmlMemory_t;
 Perl:
 ($ret, $memory) = nvmlDeviceGetMemoryInfo($device);
 print "Total memory " . $memory->{"total"} . "\n";
 print "Used memory " . $memory->{"used"} . "\n";
 print "Free memory " . $memory->{"free"} . "\n";

=back

=head1 VARIABLES

See EXPORTS and NVML documentation.  All NVML constants and enums are exposed.

=head1 COPYRIGHT

Copyright (c) 2011-2012, NVIDIA Corporation.  All rights reserved.

=head1 LICENSE

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

=over 4

=item *
Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

=item *
Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

=item *
Neither the name of the NVIDIA Corporation nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

=back

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

