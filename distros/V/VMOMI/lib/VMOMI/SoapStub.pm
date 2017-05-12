package VMOMI::SoapStub;
use parent 'VMOMI::SoapBase';

use strict;
use warnings;

sub AbdicateDomOwnership {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['uuids', undef],
    ];
    return $self->soap_call('AbdicateDomOwnership', undef, 1, $x_args, \%args);
}

sub AcknowledgeAlarm {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['alarm', 'ManagedObjectReference'],
      ['entity', 'ManagedObjectReference'],
    ];
    return $self->soap_call('AcknowledgeAlarm', undef, 0, $x_args, \%args);
}

sub AcquireCimServicesTicket {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('AcquireCimServicesTicket', 'HostServiceTicket', 0, $x_args, \%args);
}

sub AcquireCloneTicket {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('AcquireCloneTicket', undef, 0, $x_args, \%args);
}

sub AcquireCredentialsInGuest {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['vm', 'ManagedObjectReference'],
      ['requestedAuth', 'GuestAuthentication'],
      ['sessionID', undef],
    ];
    return $self->soap_call('AcquireCredentialsInGuest', 'GuestAuthentication', 0, $x_args, \%args);
}

sub AcquireGenericServiceTicket {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['spec', 'SessionManagerServiceRequestSpec'],
    ];
    return $self->soap_call('AcquireGenericServiceTicket', 'SessionManagerGenericServiceTicket', 0, $x_args, \%args);
}

sub AcquireLocalTicket {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['userName', undef],
    ];
    return $self->soap_call('AcquireLocalTicket', 'SessionManagerLocalTicket', 0, $x_args, \%args);
}

sub AcquireMksTicket {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('AcquireMksTicket', 'VirtualMachineMksTicket', 0, $x_args, \%args);
}

sub AcquireTicket {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['ticketType', undef],
    ];
    return $self->soap_call('AcquireTicket', 'VirtualMachineTicket', 0, $x_args, \%args);
}

sub AddAuthorizationRole {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['name', undef],
      ['privIds', undef],
    ];
    return $self->soap_call('AddAuthorizationRole', undef, 0, $x_args, \%args);
}

sub AddCustomFieldDef {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['name', undef],
      ['moType', undef],
      ['fieldDefPolicy', 'PrivilegePolicyDef'],
      ['fieldPolicy', 'PrivilegePolicyDef'],
    ];
    return $self->soap_call('AddCustomFieldDef', 'CustomFieldDef', 0, $x_args, \%args);
}

sub AddDVPortgroup_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['spec', 'DVPortgroupConfigSpec'],
    ];
    return $self->soap_call('AddDVPortgroup_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub AddDisks_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['disk', 'HostScsiDisk'],
    ];
    return $self->soap_call('AddDisks_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub AddFilter {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['providerId', undef],
      ['filterName', undef],
      ['infoIds', undef],
    ];
    return $self->soap_call('AddFilter', undef, 0, $x_args, \%args);
}

sub AddFilterEntities {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['filterId', undef],
      ['entities', 'ManagedObjectReference'],
    ];
    return $self->soap_call('AddFilterEntities', undef, 0, $x_args, \%args);
}

sub AddGuestAlias {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['vm', 'ManagedObjectReference'],
      ['auth', 'GuestAuthentication'],
      ['username', undef],
      ['mapCert', 'boolean'],
      ['base64Cert', undef],
      ['aliasInfo', 'GuestAuthAliasInfo'],
    ];
    return $self->soap_call('AddGuestAlias', undef, 0, $x_args, \%args);
}

sub AddHost_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['spec', 'HostConnectSpec'],
      ['asConnected', 'boolean'],
      ['resourcePool', 'ManagedObjectReference'],
      ['license', undef],
    ];
    return $self->soap_call('AddHost_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub AddInternetScsiSendTargets {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['iScsiHbaDevice', undef],
      ['targets', 'HostInternetScsiHbaSendTarget'],
    ];
    return $self->soap_call('AddInternetScsiSendTargets', undef, 0, $x_args, \%args);
}

sub AddInternetScsiStaticTargets {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['iScsiHbaDevice', undef],
      ['targets', 'HostInternetScsiHbaStaticTarget'],
    ];
    return $self->soap_call('AddInternetScsiStaticTargets', undef, 0, $x_args, \%args);
}

sub AddKey {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['key', 'CryptoKeyPlain'],
    ];
    return $self->soap_call('AddKey', undef, 0, $x_args, \%args);
}

sub AddKeys {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['keys', 'CryptoKeyPlain'],
    ];
    return $self->soap_call('AddKeys', 'CryptoKeyResult', 1, $x_args, \%args);
}

sub AddLicense {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['licenseKey', undef],
      ['labels', 'KeyValue'],
    ];
    return $self->soap_call('AddLicense', 'LicenseManagerLicenseInfo', 0, $x_args, \%args);
}

sub AddMonitoredEntities {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['providerId', undef],
      ['entities', 'ManagedObjectReference'],
    ];
    return $self->soap_call('AddMonitoredEntities', undef, 0, $x_args, \%args);
}

sub AddNetworkResourcePool {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['configSpec', 'DVSNetworkResourcePoolConfigSpec'],
    ];
    return $self->soap_call('AddNetworkResourcePool', undef, 0, $x_args, \%args);
}

sub AddPortGroup {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['portgrp', 'HostPortGroupSpec'],
    ];
    return $self->soap_call('AddPortGroup', undef, 0, $x_args, \%args);
}

sub AddServiceConsoleVirtualNic {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['portgroup', undef],
      ['nic', 'HostVirtualNicSpec'],
    ];
    return $self->soap_call('AddServiceConsoleVirtualNic', undef, 0, $x_args, \%args);
}

sub AddStandaloneHost_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['spec', 'HostConnectSpec'],
      ['compResSpec', 'ComputeResourceConfigSpec'],
      ['addConnected', 'boolean'],
      ['license', undef],
    ];
    return $self->soap_call('AddStandaloneHost_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub AddVirtualNic {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['portgroup', undef],
      ['nic', 'HostVirtualNicSpec'],
    ];
    return $self->soap_call('AddVirtualNic', undef, 0, $x_args, \%args);
}

sub AddVirtualSwitch {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['vswitchName', undef],
      ['spec', 'HostVirtualSwitchSpec'],
    ];
    return $self->soap_call('AddVirtualSwitch', undef, 0, $x_args, \%args);
}

sub AllocateIpv4Address {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['dc', 'ManagedObjectReference'],
      ['poolId', undef],
      ['allocationId', undef],
    ];
    return $self->soap_call('AllocateIpv4Address', undef, 0, $x_args, \%args);
}

sub AllocateIpv6Address {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['dc', 'ManagedObjectReference'],
      ['poolId', undef],
      ['allocationId', undef],
    ];
    return $self->soap_call('AllocateIpv6Address', undef, 0, $x_args, \%args);
}

sub AnswerVM {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['questionId', undef],
      ['answerChoice', undef],
    ];
    return $self->soap_call('AnswerVM', undef, 0, $x_args, \%args);
}

sub ApplyEntitiesConfig_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['applyConfigSpecs', 'ApplyHostProfileConfigurationSpec'],
    ];
    return $self->soap_call('ApplyEntitiesConfig_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub ApplyHostConfig_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['host', 'ManagedObjectReference'],
      ['configSpec', 'HostConfigSpec'],
      ['userInput', 'ProfileDeferredPolicyOptionParameter'],
    ];
    return $self->soap_call('ApplyHostConfig_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub ApplyRecommendation {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['key', undef],
    ];
    return $self->soap_call('ApplyRecommendation', undef, 0, $x_args, \%args);
}

sub ApplyStorageDrsRecommendationToPod_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['pod', 'ManagedObjectReference'],
      ['key', undef],
    ];
    return $self->soap_call('ApplyStorageDrsRecommendationToPod_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub ApplyStorageDrsRecommendation_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['key', undef],
    ];
    return $self->soap_call('ApplyStorageDrsRecommendation_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub AreAlarmActionsEnabled {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['entity', 'ManagedObjectReference'],
    ];
    return $self->soap_call('AreAlarmActionsEnabled', 'boolean', 0, $x_args, \%args);
}

sub AssignUserToGroup {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['user', undef],
      ['group', undef],
    ];
    return $self->soap_call('AssignUserToGroup', undef, 0, $x_args, \%args);
}

sub AssociateProfile {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['entity', 'ManagedObjectReference'],
    ];
    return $self->soap_call('AssociateProfile', undef, 0, $x_args, \%args);
}

sub AttachDisk_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['diskId', 'ID'],
      ['datastore', 'ManagedObjectReference'],
      ['controllerKey', undef],
      ['unitNumber', undef],
    ];
    return $self->soap_call('AttachDisk_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub AttachScsiLun {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['lunUuid', undef],
    ];
    return $self->soap_call('AttachScsiLun', undef, 0, $x_args, \%args);
}

sub AttachScsiLunEx_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['lunUuid', undef],
    ];
    return $self->soap_call('AttachScsiLunEx_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub AttachTagToVStorageObject {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['id', 'ID'],
      ['category', undef],
      ['tag', undef],
    ];
    return $self->soap_call('AttachTagToVStorageObject', undef, 0, $x_args, \%args);
}

sub AttachVmfsExtent {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['vmfsPath', undef],
      ['extent', 'HostScsiDiskPartition'],
    ];
    return $self->soap_call('AttachVmfsExtent', undef, 0, $x_args, \%args);
}

sub AutoStartPowerOff {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('AutoStartPowerOff', undef, 0, $x_args, \%args);
}

sub AutoStartPowerOn {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('AutoStartPowerOn', undef, 0, $x_args, \%args);
}

sub BackupFirmwareConfiguration {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('BackupFirmwareConfiguration', undef, 0, $x_args, \%args);
}

sub BindVnic {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['iScsiHbaName', undef],
      ['vnicDevice', undef],
    ];
    return $self->soap_call('BindVnic', undef, 0, $x_args, \%args);
}

sub BrowseDiagnosticLog {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['host', 'ManagedObjectReference'],
      ['key', undef],
      ['start', undef],
      ['lines', undef],
    ];
    return $self->soap_call('BrowseDiagnosticLog', 'DiagnosticManagerLogHeader', 0, $x_args, \%args);
}

sub CanProvisionObjects {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['npbs', 'VsanNewPolicyBatch'],
      ['ignoreSatisfiability', 'boolean'],
    ];
    return $self->soap_call('CanProvisionObjects', 'VsanPolicySatisfiability', 1, $x_args, \%args);
}

sub CancelRecommendation {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['key', undef],
    ];
    return $self->soap_call('CancelRecommendation', undef, 0, $x_args, \%args);
}

sub CancelRetrievePropertiesEx {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['token', undef],
    ];
    return $self->soap_call('CancelRetrievePropertiesEx', undef, 0, $x_args, \%args);
}

sub CancelStorageDrsRecommendation {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['key', undef],
    ];
    return $self->soap_call('CancelStorageDrsRecommendation', undef, 0, $x_args, \%args);
}

sub CancelTask {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('CancelTask', undef, 0, $x_args, \%args);
}

sub CancelWaitForUpdates {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('CancelWaitForUpdates', undef, 0, $x_args, \%args);
}

sub CertMgrRefreshCACertificatesAndCRLs_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['host', 'ManagedObjectReference'],
    ];
    return $self->soap_call('CertMgrRefreshCACertificatesAndCRLs_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub CertMgrRefreshCertificates_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['host', 'ManagedObjectReference'],
    ];
    return $self->soap_call('CertMgrRefreshCertificates_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub CertMgrRevokeCertificates_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['host', 'ManagedObjectReference'],
    ];
    return $self->soap_call('CertMgrRevokeCertificates_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub ChangeAccessMode {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['principal', undef],
      ['isGroup', 'boolean'],
      ['accessMode', 'HostAccessMode'],
    ];
    return $self->soap_call('ChangeAccessMode', undef, 0, $x_args, \%args);
}

sub ChangeFileAttributesInGuest {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['vm', 'ManagedObjectReference'],
      ['auth', 'GuestAuthentication'],
      ['guestFilePath', undef],
      ['fileAttributes', 'GuestFileAttributes'],
    ];
    return $self->soap_call('ChangeFileAttributesInGuest', undef, 0, $x_args, \%args);
}

sub ChangeLockdownMode {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['mode', 'HostLockdownMode'],
    ];
    return $self->soap_call('ChangeLockdownMode', undef, 0, $x_args, \%args);
}

sub ChangeNFSUserPassword {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['password', undef],
    ];
    return $self->soap_call('ChangeNFSUserPassword', undef, 0, $x_args, \%args);
}

sub ChangeOwner {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['name', undef],
      ['datacenter', 'ManagedObjectReference'],
      ['owner', undef],
    ];
    return $self->soap_call('ChangeOwner', undef, 0, $x_args, \%args);
}

sub CheckAddHostEvc_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['cnxSpec', 'HostConnectSpec'],
    ];
    return $self->soap_call('CheckAddHostEvc_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub CheckAnswerFileStatus_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['host', 'ManagedObjectReference'],
    ];
    return $self->soap_call('CheckAnswerFileStatus_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub CheckCompatibility_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['vm', 'ManagedObjectReference'],
      ['host', 'ManagedObjectReference'],
      ['pool', 'ManagedObjectReference'],
      ['testType', undef],
    ];
    return $self->soap_call('CheckCompatibility_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub CheckCompliance_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['profile', 'ManagedObjectReference'],
      ['entity', 'ManagedObjectReference'],
    ];
    return $self->soap_call('CheckCompliance_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub CheckConfigureEvcMode_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['evcModeKey', undef],
    ];
    return $self->soap_call('CheckConfigureEvcMode_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub CheckCustomizationResources {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['guestOs', undef],
    ];
    return $self->soap_call('CheckCustomizationResources', undef, 0, $x_args, \%args);
}

sub CheckCustomizationSpec {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['spec', 'CustomizationSpec'],
    ];
    return $self->soap_call('CheckCustomizationSpec', undef, 0, $x_args, \%args);
}

sub CheckForUpdates {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['version', undef],
    ];
    return $self->soap_call('CheckForUpdates', 'UpdateSet', 0, $x_args, \%args);
}

sub CheckHostPatch_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['metaUrls', undef],
      ['bundleUrls', undef],
      ['spec', 'HostPatchManagerPatchManagerOperationSpec'],
    ];
    return $self->soap_call('CheckHostPatch_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub CheckLicenseFeature {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['host', 'ManagedObjectReference'],
      ['featureKey', undef],
    ];
    return $self->soap_call('CheckLicenseFeature', 'boolean', 0, $x_args, \%args);
}

sub CheckMigrate_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['vm', 'ManagedObjectReference'],
      ['host', 'ManagedObjectReference'],
      ['pool', 'ManagedObjectReference'],
      ['state', 'VirtualMachinePowerState'],
      ['testType', undef],
    ];
    return $self->soap_call('CheckMigrate_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub CheckProfileCompliance_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['entity', 'ManagedObjectReference'],
    ];
    return $self->soap_call('CheckProfileCompliance_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub CheckRelocate_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['vm', 'ManagedObjectReference'],
      ['spec', 'VirtualMachineRelocateSpec'],
      ['testType', undef],
    ];
    return $self->soap_call('CheckRelocate_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub ClearComplianceStatus {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['profile', 'ManagedObjectReference'],
      ['entity', 'ManagedObjectReference'],
    ];
    return $self->soap_call('ClearComplianceStatus', undef, 0, $x_args, \%args);
}

sub ClearNFSUser {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('ClearNFSUser', undef, 0, $x_args, \%args);
}

sub ClearSystemEventLog {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('ClearSystemEventLog', undef, 0, $x_args, \%args);
}

sub CloneSession {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['cloneTicket', undef],
    ];
    return $self->soap_call('CloneSession', 'UserSession', 0, $x_args, \%args);
}

sub CloneVApp_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['name', undef],
      ['target', 'ManagedObjectReference'],
      ['spec', 'VAppCloneSpec'],
    ];
    return $self->soap_call('CloneVApp_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub CloneVM_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['folder', 'ManagedObjectReference'],
      ['name', undef],
      ['spec', 'VirtualMachineCloneSpec'],
    ];
    return $self->soap_call('CloneVM_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub CloneVStorageObject_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['id', 'ID'],
      ['datastore', 'ManagedObjectReference'],
      ['spec', 'VslmCloneSpec'],
    ];
    return $self->soap_call('CloneVStorageObject_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub CloseInventoryViewFolder {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['entity', 'ManagedObjectReference'],
    ];
    return $self->soap_call('CloseInventoryViewFolder', 'ManagedObjectReference', 1, $x_args, \%args);
}

sub ClusterEnterMaintenanceMode {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['host', 'ManagedObjectReference'],
      ['option', 'OptionValue'],
    ];
    return $self->soap_call('ClusterEnterMaintenanceMode', 'ClusterEnterMaintenanceResult', 0, $x_args, \%args);
}

sub ComputeDiskPartitionInfo {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['devicePath', undef],
      ['layout', 'HostDiskPartitionLayout'],
      ['partitionFormat', undef],
    ];
    return $self->soap_call('ComputeDiskPartitionInfo', 'HostDiskPartitionInfo', 0, $x_args, \%args);
}

sub ComputeDiskPartitionInfoForResize {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['partition', 'HostScsiDiskPartition'],
      ['blockRange', 'HostDiskPartitionBlockRange'],
      ['partitionFormat', undef],
    ];
    return $self->soap_call('ComputeDiskPartitionInfoForResize', 'HostDiskPartitionInfo', 0, $x_args, \%args);
}

sub ConfigureCryptoKey {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['keyId', 'CryptoKeyId'],
    ];
    return $self->soap_call('ConfigureCryptoKey', undef, 0, $x_args, \%args);
}

sub ConfigureDatastoreIORM_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['datastore', 'ManagedObjectReference'],
      ['spec', 'StorageIORMConfigSpec'],
    ];
    return $self->soap_call('ConfigureDatastoreIORM_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub ConfigureDatastorePrincipal {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['userName', undef],
      ['password', undef],
    ];
    return $self->soap_call('ConfigureDatastorePrincipal', undef, 0, $x_args, \%args);
}

sub ConfigureEvcMode_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['evcModeKey', undef],
    ];
    return $self->soap_call('ConfigureEvcMode_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub ConfigureHostCache_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['spec', 'HostCacheConfigurationSpec'],
    ];
    return $self->soap_call('ConfigureHostCache_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub ConfigureLicenseSource {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['host', 'ManagedObjectReference'],
      ['licenseSource', 'LicenseSource'],
    ];
    return $self->soap_call('ConfigureLicenseSource', undef, 0, $x_args, \%args);
}

sub ConfigurePowerPolicy {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['key', undef],
    ];
    return $self->soap_call('ConfigurePowerPolicy', undef, 0, $x_args, \%args);
}

sub ConfigureStorageDrsForPod_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['pod', 'ManagedObjectReference'],
      ['spec', 'StorageDrsConfigSpec'],
      ['modify', 'boolean'],
    ];
    return $self->soap_call('ConfigureStorageDrsForPod_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub ConfigureVFlashResourceEx_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['devicePath', undef],
    ];
    return $self->soap_call('ConfigureVFlashResourceEx_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub ConsolidateVMDisks_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('ConsolidateVMDisks_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub ContinueRetrievePropertiesEx {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['token', undef],
    ];
    return $self->soap_call('ContinueRetrievePropertiesEx', 'RetrieveResult', 0, $x_args, \%args);
}

sub ConvertNamespacePathToUuidPath {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['datacenter', 'ManagedObjectReference'],
      ['namespaceUrl', undef],
    ];
    return $self->soap_call('ConvertNamespacePathToUuidPath', undef, 0, $x_args, \%args);
}

sub CopyDatastoreFile_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['sourceName', undef],
      ['sourceDatacenter', 'ManagedObjectReference'],
      ['destinationName', undef],
      ['destinationDatacenter', 'ManagedObjectReference'],
      ['force', 'boolean'],
    ];
    return $self->soap_call('CopyDatastoreFile_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub CopyVirtualDisk_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['sourceName', undef],
      ['sourceDatacenter', 'ManagedObjectReference'],
      ['destName', undef],
      ['destDatacenter', 'ManagedObjectReference'],
      ['destSpec', 'VirtualDiskSpec'],
      ['force', 'boolean'],
    ];
    return $self->soap_call('CopyVirtualDisk_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub CreateAlarm {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['entity', 'ManagedObjectReference'],
      ['spec', 'AlarmSpec'],
    ];
    return $self->soap_call('CreateAlarm', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub CreateChildVM_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['config', 'VirtualMachineConfigSpec'],
      ['host', 'ManagedObjectReference'],
    ];
    return $self->soap_call('CreateChildVM_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub CreateCluster {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['name', undef],
      ['spec', 'ClusterConfigSpec'],
    ];
    return $self->soap_call('CreateCluster', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub CreateClusterEx {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['name', undef],
      ['spec', 'ClusterConfigSpecEx'],
    ];
    return $self->soap_call('CreateClusterEx', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub CreateCollectorForEvents {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['filter', 'EventFilterSpec'],
    ];
    return $self->soap_call('CreateCollectorForEvents', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub CreateCollectorForTasks {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['filter', 'TaskFilterSpec'],
    ];
    return $self->soap_call('CreateCollectorForTasks', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub CreateContainerView {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['container', 'ManagedObjectReference'],
      ['type', undef],
      ['recursive', 'boolean'],
    ];
    return $self->soap_call('CreateContainerView', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub CreateCustomizationSpec {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['item', 'CustomizationSpecItem'],
    ];
    return $self->soap_call('CreateCustomizationSpec', undef, 0, $x_args, \%args);
}

sub CreateDVPortgroup_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['spec', 'DVPortgroupConfigSpec'],
    ];
    return $self->soap_call('CreateDVPortgroup_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub CreateDVS_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['spec', 'DVSCreateSpec'],
    ];
    return $self->soap_call('CreateDVS_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub CreateDatacenter {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['name', undef],
    ];
    return $self->soap_call('CreateDatacenter', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub CreateDefaultProfile {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['profileType', undef],
      ['profileTypeName', undef],
      ['profile', 'ManagedObjectReference'],
    ];
    return $self->soap_call('CreateDefaultProfile', 'ApplyProfile', 0, $x_args, \%args);
}

sub CreateDescriptor {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['obj', 'ManagedObjectReference'],
      ['cdp', 'OvfCreateDescriptorParams'],
    ];
    return $self->soap_call('CreateDescriptor', 'OvfCreateDescriptorResult', 0, $x_args, \%args);
}

sub CreateDiagnosticPartition {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['spec', 'HostDiagnosticPartitionCreateSpec'],
    ];
    return $self->soap_call('CreateDiagnosticPartition', undef, 0, $x_args, \%args);
}

sub CreateDirectory {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['datastore', 'ManagedObjectReference'],
      ['displayName', undef],
      ['policy', undef],
    ];
    return $self->soap_call('CreateDirectory', undef, 0, $x_args, \%args);
}

sub CreateDisk_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['spec', 'VslmCreateSpec'],
    ];
    return $self->soap_call('CreateDisk_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub CreateFilter {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['spec', 'PropertyFilterSpec'],
      ['partialUpdates', 'boolean'],
    ];
    return $self->soap_call('CreateFilter', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub CreateFolder {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['name', undef],
    ];
    return $self->soap_call('CreateFolder', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub CreateGroup {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['group', 'HostAccountSpec'],
    ];
    return $self->soap_call('CreateGroup', undef, 0, $x_args, \%args);
}

sub CreateImportSpec {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['ovfDescriptor', undef],
      ['resourcePool', 'ManagedObjectReference'],
      ['datastore', 'ManagedObjectReference'],
      ['cisp', 'OvfCreateImportSpecParams'],
    ];
    return $self->soap_call('CreateImportSpec', 'OvfCreateImportSpecResult', 0, $x_args, \%args);
}

sub CreateInventoryView {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('CreateInventoryView', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub CreateIpPool {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['dc', 'ManagedObjectReference'],
      ['pool', 'IpPool'],
    ];
    return $self->soap_call('CreateIpPool', undef, 0, $x_args, \%args);
}

sub CreateListView {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['obj', 'ManagedObjectReference'],
    ];
    return $self->soap_call('CreateListView', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub CreateListViewFromView {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['view', 'ManagedObjectReference'],
    ];
    return $self->soap_call('CreateListViewFromView', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub CreateLocalDatastore {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['name', undef],
      ['path', undef],
    ];
    return $self->soap_call('CreateLocalDatastore', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub CreateNasDatastore {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['spec', 'HostNasVolumeSpec'],
    ];
    return $self->soap_call('CreateNasDatastore', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub CreateObjectScheduledTask {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['obj', 'ManagedObjectReference'],
      ['spec', 'ScheduledTaskSpec'],
    ];
    return $self->soap_call('CreateObjectScheduledTask', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub CreatePerfInterval {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['intervalId', 'PerfInterval'],
    ];
    return $self->soap_call('CreatePerfInterval', undef, 0, $x_args, \%args);
}

sub CreateProfile {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['createSpec', 'ProfileCreateSpec'],
    ];
    return $self->soap_call('CreateProfile', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub CreatePropertyCollector {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('CreatePropertyCollector', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub CreateRegistryKeyInGuest {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['vm', 'ManagedObjectReference'],
      ['auth', 'GuestAuthentication'],
      ['keyName', 'GuestRegKeyNameSpec'],
      ['isVolatile', 'boolean'],
      ['classType', undef],
    ];
    return $self->soap_call('CreateRegistryKeyInGuest', undef, 0, $x_args, \%args);
}

sub CreateResourcePool {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['name', undef],
      ['spec', 'ResourceConfigSpec'],
    ];
    return $self->soap_call('CreateResourcePool', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub CreateScheduledTask {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['entity', 'ManagedObjectReference'],
      ['spec', 'ScheduledTaskSpec'],
    ];
    return $self->soap_call('CreateScheduledTask', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub CreateScreenshot_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('CreateScreenshot_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub CreateSecondaryVMEx_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['host', 'ManagedObjectReference'],
      ['spec', 'FaultToleranceConfigSpec'],
    ];
    return $self->soap_call('CreateSecondaryVMEx_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub CreateSecondaryVM_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['host', 'ManagedObjectReference'],
    ];
    return $self->soap_call('CreateSecondaryVM_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub CreateSnapshotEx_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['name', undef],
      ['description', undef],
      ['memory', 'boolean'],
      ['quiesceSpec', 'VirtualMachineGuestQuiesceSpec'],
    ];
    return $self->soap_call('CreateSnapshotEx_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub CreateSnapshot_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['name', undef],
      ['description', undef],
      ['memory', 'boolean'],
      ['quiesce', 'boolean'],
    ];
    return $self->soap_call('CreateSnapshot_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub CreateStoragePod {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['name', undef],
    ];
    return $self->soap_call('CreateStoragePod', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub CreateTask {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['obj', 'ManagedObjectReference'],
      ['taskTypeId', undef],
      ['initiatedBy', undef],
      ['cancelable', 'boolean'],
      ['parentTaskKey', undef],
      ['activationId', undef],
    ];
    return $self->soap_call('CreateTask', 'TaskInfo', 0, $x_args, \%args);
}

sub CreateTemporaryDirectoryInGuest {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['vm', 'ManagedObjectReference'],
      ['auth', 'GuestAuthentication'],
      ['prefix', undef],
      ['suffix', undef],
      ['directoryPath', undef],
    ];
    return $self->soap_call('CreateTemporaryDirectoryInGuest', undef, 0, $x_args, \%args);
}

sub CreateTemporaryFileInGuest {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['vm', 'ManagedObjectReference'],
      ['auth', 'GuestAuthentication'],
      ['prefix', undef],
      ['suffix', undef],
      ['directoryPath', undef],
    ];
    return $self->soap_call('CreateTemporaryFileInGuest', undef, 0, $x_args, \%args);
}

sub CreateUser {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['user', 'HostAccountSpec'],
    ];
    return $self->soap_call('CreateUser', undef, 0, $x_args, \%args);
}

sub CreateVApp {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['name', undef],
      ['resSpec', 'ResourceConfigSpec'],
      ['configSpec', 'VAppConfigSpec'],
      ['vmFolder', 'ManagedObjectReference'],
    ];
    return $self->soap_call('CreateVApp', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub CreateVM_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['config', 'VirtualMachineConfigSpec'],
      ['pool', 'ManagedObjectReference'],
      ['host', 'ManagedObjectReference'],
    ];
    return $self->soap_call('CreateVM_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub CreateVirtualDisk_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['name', undef],
      ['datacenter', 'ManagedObjectReference'],
      ['spec', 'VirtualDiskSpec'],
    ];
    return $self->soap_call('CreateVirtualDisk_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub CreateVmfsDatastore {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['spec', 'VmfsDatastoreCreateSpec'],
    ];
    return $self->soap_call('CreateVmfsDatastore', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub CreateVvolDatastore {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['spec', 'HostDatastoreSystemVvolDatastoreSpec'],
    ];
    return $self->soap_call('CreateVvolDatastore', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub CurrentTime {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('CurrentTime', undef, 0, $x_args, \%args);
}

sub CustomizationSpecItemToXml {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['item', 'CustomizationSpecItem'],
    ];
    return $self->soap_call('CustomizationSpecItemToXml', undef, 0, $x_args, \%args);
}

sub CustomizeVM_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['spec', 'CustomizationSpec'],
    ];
    return $self->soap_call('CustomizeVM_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub DVPortgroupRollback_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['entityBackup', 'EntityBackupConfig'],
    ];
    return $self->soap_call('DVPortgroupRollback_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub DVSManagerExportEntity_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['selectionSet', 'SelectionSet'],
    ];
    return $self->soap_call('DVSManagerExportEntity_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub DVSManagerImportEntity_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['entityBackup', 'EntityBackupConfig'],
      ['importType', undef],
    ];
    return $self->soap_call('DVSManagerImportEntity_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub DVSManagerLookupDvPortGroup {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['switchUuid', undef],
      ['portgroupKey', undef],
    ];
    return $self->soap_call('DVSManagerLookupDvPortGroup', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub DVSRollback_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['entityBackup', 'EntityBackupConfig'],
    ];
    return $self->soap_call('DVSRollback_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub DatastoreEnterMaintenanceMode {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('DatastoreEnterMaintenanceMode', 'StoragePlacementResult', 0, $x_args, \%args);
}

sub DatastoreExitMaintenanceMode_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('DatastoreExitMaintenanceMode_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub DecodeLicense {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['licenseKey', undef],
    ];
    return $self->soap_call('DecodeLicense', 'LicenseManagerLicenseInfo', 0, $x_args, \%args);
}

sub DefragmentAllDisks {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('DefragmentAllDisks', undef, 0, $x_args, \%args);
}

sub DefragmentVirtualDisk_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['name', undef],
      ['datacenter', 'ManagedObjectReference'],
    ];
    return $self->soap_call('DefragmentVirtualDisk_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub DeleteCustomizationSpec {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['name', undef],
    ];
    return $self->soap_call('DeleteCustomizationSpec', undef, 0, $x_args, \%args);
}

sub DeleteDatastoreFile_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['name', undef],
      ['datacenter', 'ManagedObjectReference'],
    ];
    return $self->soap_call('DeleteDatastoreFile_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub DeleteDirectory {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['datacenter', 'ManagedObjectReference'],
      ['datastorePath', undef],
    ];
    return $self->soap_call('DeleteDirectory', undef, 0, $x_args, \%args);
}

sub DeleteDirectoryInGuest {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['vm', 'ManagedObjectReference'],
      ['auth', 'GuestAuthentication'],
      ['directoryPath', undef],
      ['recursive', 'boolean'],
    ];
    return $self->soap_call('DeleteDirectoryInGuest', undef, 0, $x_args, \%args);
}

sub DeleteFile {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['datastorePath', undef],
    ];
    return $self->soap_call('DeleteFile', undef, 0, $x_args, \%args);
}

sub DeleteFileInGuest {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['vm', 'ManagedObjectReference'],
      ['auth', 'GuestAuthentication'],
      ['filePath', undef],
    ];
    return $self->soap_call('DeleteFileInGuest', undef, 0, $x_args, \%args);
}

sub DeleteHostSpecification {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['host', 'ManagedObjectReference'],
    ];
    return $self->soap_call('DeleteHostSpecification', undef, 0, $x_args, \%args);
}

sub DeleteHostSubSpecification {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['host', 'ManagedObjectReference'],
      ['subSpecName', undef],
    ];
    return $self->soap_call('DeleteHostSubSpecification', undef, 0, $x_args, \%args);
}

sub DeleteRegistryKeyInGuest {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['vm', 'ManagedObjectReference'],
      ['auth', 'GuestAuthentication'],
      ['keyName', 'GuestRegKeyNameSpec'],
      ['recursive', 'boolean'],
    ];
    return $self->soap_call('DeleteRegistryKeyInGuest', undef, 0, $x_args, \%args);
}

sub DeleteRegistryValueInGuest {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['vm', 'ManagedObjectReference'],
      ['auth', 'GuestAuthentication'],
      ['valueName', 'GuestRegValueNameSpec'],
    ];
    return $self->soap_call('DeleteRegistryValueInGuest', undef, 0, $x_args, \%args);
}

sub DeleteScsiLunState {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['lunCanonicalName', undef],
    ];
    return $self->soap_call('DeleteScsiLunState', undef, 0, $x_args, \%args);
}

sub DeleteVStorageObject_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['id', 'ID'],
      ['datastore', 'ManagedObjectReference'],
    ];
    return $self->soap_call('DeleteVStorageObject_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub DeleteVffsVolumeState {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['vffsUuid', undef],
    ];
    return $self->soap_call('DeleteVffsVolumeState', undef, 0, $x_args, \%args);
}

sub DeleteVirtualDisk_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['name', undef],
      ['datacenter', 'ManagedObjectReference'],
    ];
    return $self->soap_call('DeleteVirtualDisk_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub DeleteVmfsVolumeState {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['vmfsUuid', undef],
    ];
    return $self->soap_call('DeleteVmfsVolumeState', undef, 0, $x_args, \%args);
}

sub DeleteVsanObjects {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['uuids', undef],
      ['force', 'boolean'],
    ];
    return $self->soap_call('DeleteVsanObjects', 'HostVsanInternalSystemDeleteVsanObjectsResult', 1, $x_args, \%args);
}

sub DeselectVnic {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('DeselectVnic', undef, 0, $x_args, \%args);
}

sub DeselectVnicForNicType {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['nicType', undef],
      ['device', undef],
    ];
    return $self->soap_call('DeselectVnicForNicType', undef, 0, $x_args, \%args);
}

sub DestroyChildren {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('DestroyChildren', undef, 0, $x_args, \%args);
}

sub DestroyCollector {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('DestroyCollector', undef, 0, $x_args, \%args);
}

sub DestroyDatastore {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('DestroyDatastore', undef, 0, $x_args, \%args);
}

sub DestroyIpPool {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['dc', 'ManagedObjectReference'],
      ['id', undef],
      ['force', 'boolean'],
    ];
    return $self->soap_call('DestroyIpPool', undef, 0, $x_args, \%args);
}

sub DestroyNetwork {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('DestroyNetwork', undef, 0, $x_args, \%args);
}

sub DestroyProfile {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('DestroyProfile', undef, 0, $x_args, \%args);
}

sub DestroyPropertyCollector {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('DestroyPropertyCollector', undef, 0, $x_args, \%args);
}

sub DestroyPropertyFilter {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('DestroyPropertyFilter', undef, 0, $x_args, \%args);
}

sub DestroyVffs {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['vffsPath', undef],
    ];
    return $self->soap_call('DestroyVffs', undef, 0, $x_args, \%args);
}

sub DestroyView {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('DestroyView', undef, 0, $x_args, \%args);
}

sub Destroy_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('Destroy_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub DetachDisk_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['diskId', 'ID'],
    ];
    return $self->soap_call('DetachDisk_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub DetachScsiLun {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['lunUuid', undef],
    ];
    return $self->soap_call('DetachScsiLun', undef, 0, $x_args, \%args);
}

sub DetachScsiLunEx_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['lunUuid', undef],
    ];
    return $self->soap_call('DetachScsiLunEx_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub DetachTagFromVStorageObject {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['id', 'ID'],
      ['category', undef],
      ['tag', undef],
    ];
    return $self->soap_call('DetachTagFromVStorageObject', undef, 0, $x_args, \%args);
}

sub DisableEvcMode_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('DisableEvcMode_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub DisableFeature {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['host', 'ManagedObjectReference'],
      ['featureKey', undef],
    ];
    return $self->soap_call('DisableFeature', 'boolean', 0, $x_args, \%args);
}

sub DisableHyperThreading {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('DisableHyperThreading', undef, 0, $x_args, \%args);
}

sub DisableMultipathPath {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['pathName', undef],
    ];
    return $self->soap_call('DisableMultipathPath', undef, 0, $x_args, \%args);
}

sub DisableRuleset {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['id', undef],
    ];
    return $self->soap_call('DisableRuleset', undef, 0, $x_args, \%args);
}

sub DisableSecondaryVM_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['vm', 'ManagedObjectReference'],
    ];
    return $self->soap_call('DisableSecondaryVM_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub DisableSmartCardAuthentication {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('DisableSmartCardAuthentication', undef, 0, $x_args, \%args);
}

sub DisconnectHost_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('DisconnectHost_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub DiscoverFcoeHbas {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['fcoeSpec', 'FcoeConfigFcoeSpecification'],
    ];
    return $self->soap_call('DiscoverFcoeHbas', undef, 0, $x_args, \%args);
}

sub DissociateProfile {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['entity', 'ManagedObjectReference'],
    ];
    return $self->soap_call('DissociateProfile', undef, 0, $x_args, \%args);
}

sub DoesCustomizationSpecExist {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['name', undef],
    ];
    return $self->soap_call('DoesCustomizationSpecExist', 'boolean', 0, $x_args, \%args);
}

sub DuplicateCustomizationSpec {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['name', undef],
      ['newName', undef],
    ];
    return $self->soap_call('DuplicateCustomizationSpec', undef, 0, $x_args, \%args);
}

sub DvsReconfigureVmVnicNetworkResourcePool_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['configSpec', 'DvsVmVnicResourcePoolConfigSpec'],
    ];
    return $self->soap_call('DvsReconfigureVmVnicNetworkResourcePool_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub EagerZeroVirtualDisk_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['name', undef],
      ['datacenter', 'ManagedObjectReference'],
    ];
    return $self->soap_call('EagerZeroVirtualDisk_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub EnableAlarmActions {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['entity', 'ManagedObjectReference'],
      ['enabled', 'boolean'],
    ];
    return $self->soap_call('EnableAlarmActions', undef, 0, $x_args, \%args);
}

sub EnableCrypto {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['keyPlain', 'CryptoKeyPlain'],
    ];
    return $self->soap_call('EnableCrypto', undef, 0, $x_args, \%args);
}

sub EnableFeature {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['host', 'ManagedObjectReference'],
      ['featureKey', undef],
    ];
    return $self->soap_call('EnableFeature', 'boolean', 0, $x_args, \%args);
}

sub EnableHyperThreading {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('EnableHyperThreading', undef, 0, $x_args, \%args);
}

sub EnableMultipathPath {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['pathName', undef],
    ];
    return $self->soap_call('EnableMultipathPath', undef, 0, $x_args, \%args);
}

sub EnableNetworkResourceManagement {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['enable', 'boolean'],
    ];
    return $self->soap_call('EnableNetworkResourceManagement', undef, 0, $x_args, \%args);
}

sub EnableRuleset {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['id', undef],
    ];
    return $self->soap_call('EnableRuleset', undef, 0, $x_args, \%args);
}

sub EnableSecondaryVM_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['vm', 'ManagedObjectReference'],
      ['host', 'ManagedObjectReference'],
    ];
    return $self->soap_call('EnableSecondaryVM_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub EnableSmartCardAuthentication {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('EnableSmartCardAuthentication', undef, 0, $x_args, \%args);
}

sub EnterLockdownMode {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('EnterLockdownMode', undef, 0, $x_args, \%args);
}

sub EnterMaintenanceMode_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['timeout', undef],
      ['evacuatePoweredOffVms', 'boolean'],
      ['maintenanceSpec', 'HostMaintenanceSpec'],
    ];
    return $self->soap_call('EnterMaintenanceMode_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub EstimateDatabaseSize {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['dbSizeParam', 'DatabaseSizeParam'],
    ];
    return $self->soap_call('EstimateDatabaseSize', 'DatabaseSizeEstimate', 0, $x_args, \%args);
}

sub EstimateStorageForConsolidateSnapshots_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('EstimateStorageForConsolidateSnapshots_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub EsxAgentHostManagerUpdateConfig {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['configInfo', 'HostEsxAgentHostManagerConfigInfo'],
    ];
    return $self->soap_call('EsxAgentHostManagerUpdateConfig', undef, 0, $x_args, \%args);
}

sub EvacuateVsanNode_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['maintenanceSpec', 'HostMaintenanceSpec'],
      ['timeout', undef],
    ];
    return $self->soap_call('EvacuateVsanNode_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub EvcManager {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('EvcManager', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub ExecuteHostProfile {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['host', 'ManagedObjectReference'],
      ['deferredParam', 'ProfileDeferredPolicyOptionParameter'],
    ];
    return $self->soap_call('ExecuteHostProfile', 'ProfileExecuteResult', 0, $x_args, \%args);
}

sub ExecuteSimpleCommand {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['arguments', undef],
    ];
    return $self->soap_call('ExecuteSimpleCommand', undef, 0, $x_args, \%args);
}

sub ExitLockdownMode {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('ExitLockdownMode', undef, 0, $x_args, \%args);
}

sub ExitMaintenanceMode_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['timeout', undef],
    ];
    return $self->soap_call('ExitMaintenanceMode_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub ExpandVmfsDatastore {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['datastore', 'ManagedObjectReference'],
      ['spec', 'VmfsDatastoreExpandSpec'],
    ];
    return $self->soap_call('ExpandVmfsDatastore', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub ExpandVmfsExtent {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['vmfsPath', undef],
      ['extent', 'HostScsiDiskPartition'],
    ];
    return $self->soap_call('ExpandVmfsExtent', undef, 0, $x_args, \%args);
}

sub ExportAnswerFile_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['host', 'ManagedObjectReference'],
    ];
    return $self->soap_call('ExportAnswerFile_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub ExportProfile {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('ExportProfile', undef, 0, $x_args, \%args);
}

sub ExportSnapshot {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('ExportSnapshot', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub ExportVApp {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('ExportVApp', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub ExportVm {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('ExportVm', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub ExtendDisk_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['id', 'ID'],
      ['datastore', 'ManagedObjectReference'],
      ['newCapacityInMB', undef],
    ];
    return $self->soap_call('ExtendDisk_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub ExtendVffs {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['vffsPath', undef],
      ['devicePath', undef],
      ['spec', 'HostDiskPartitionSpec'],
    ];
    return $self->soap_call('ExtendVffs', undef, 0, $x_args, \%args);
}

sub ExtendVirtualDisk_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['name', undef],
      ['datacenter', 'ManagedObjectReference'],
      ['newCapacityKb', undef],
      ['eagerZero', 'boolean'],
    ];
    return $self->soap_call('ExtendVirtualDisk_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub ExtendVmfsDatastore {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['datastore', 'ManagedObjectReference'],
      ['spec', 'VmfsDatastoreExtendSpec'],
    ];
    return $self->soap_call('ExtendVmfsDatastore', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub ExtractOvfEnvironment {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('ExtractOvfEnvironment', undef, 0, $x_args, \%args);
}

sub FetchDVPortKeys {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['criteria', 'DistributedVirtualSwitchPortCriteria'],
    ];
    return $self->soap_call('FetchDVPortKeys', undef, 1, $x_args, \%args);
}

sub FetchDVPorts {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['criteria', 'DistributedVirtualSwitchPortCriteria'],
    ];
    return $self->soap_call('FetchDVPorts', 'DistributedVirtualPort', 1, $x_args, \%args);
}

sub FetchSystemEventLog {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('FetchSystemEventLog', 'SystemEventInfo', 1, $x_args, \%args);
}

sub FetchUserPrivilegeOnEntities {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['entities', 'ManagedObjectReference'],
      ['userName', undef],
    ];
    return $self->soap_call('FetchUserPrivilegeOnEntities', 'UserPrivilegeResult', 1, $x_args, \%args);
}

sub FindAllByDnsName {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['datacenter', 'ManagedObjectReference'],
      ['dnsName', undef],
      ['vmSearch', 'boolean'],
    ];
    return $self->soap_call('FindAllByDnsName', 'ManagedObjectReference', 1, $x_args, \%args);
}

sub FindAllByIp {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['datacenter', 'ManagedObjectReference'],
      ['ip', undef],
      ['vmSearch', 'boolean'],
    ];
    return $self->soap_call('FindAllByIp', 'ManagedObjectReference', 1, $x_args, \%args);
}

sub FindAllByUuid {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['datacenter', 'ManagedObjectReference'],
      ['uuid', undef],
      ['vmSearch', 'boolean'],
      ['instanceUuid', 'boolean'],
    ];
    return $self->soap_call('FindAllByUuid', 'ManagedObjectReference', 1, $x_args, \%args);
}

sub FindAssociatedProfile {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['entity', 'ManagedObjectReference'],
    ];
    return $self->soap_call('FindAssociatedProfile', 'ManagedObjectReference', 1, $x_args, \%args);
}

sub FindByDatastorePath {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['datacenter', 'ManagedObjectReference'],
      ['path', undef],
    ];
    return $self->soap_call('FindByDatastorePath', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub FindByDnsName {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['datacenter', 'ManagedObjectReference'],
      ['dnsName', undef],
      ['vmSearch', 'boolean'],
    ];
    return $self->soap_call('FindByDnsName', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub FindByInventoryPath {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['inventoryPath', undef],
    ];
    return $self->soap_call('FindByInventoryPath', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub FindByIp {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['datacenter', 'ManagedObjectReference'],
      ['ip', undef],
      ['vmSearch', 'boolean'],
    ];
    return $self->soap_call('FindByIp', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub FindByUuid {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['datacenter', 'ManagedObjectReference'],
      ['uuid', undef],
      ['vmSearch', 'boolean'],
      ['instanceUuid', 'boolean'],
    ];
    return $self->soap_call('FindByUuid', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub FindChild {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['entity', 'ManagedObjectReference'],
      ['name', undef],
    ];
    return $self->soap_call('FindChild', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub FindExtension {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['extensionKey', undef],
    ];
    return $self->soap_call('FindExtension', 'Extension', 0, $x_args, \%args);
}

sub FindRulesForVm {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['vm', 'ManagedObjectReference'],
    ];
    return $self->soap_call('FindRulesForVm', 'ClusterRuleInfo', 1, $x_args, \%args);
}

sub FormatVffs {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['createSpec', 'HostVffsSpec'],
    ];
    return $self->soap_call('FormatVffs', 'HostVffsVolume', 0, $x_args, \%args);
}

sub FormatVmfs {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['createSpec', 'HostVmfsSpec'],
    ];
    return $self->soap_call('FormatVmfs', 'HostVmfsVolume', 0, $x_args, \%args);
}

sub GenerateCertificateSigningRequest {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['useIpAddressAsCommonName', 'boolean'],
    ];
    return $self->soap_call('GenerateCertificateSigningRequest', undef, 0, $x_args, \%args);
}

sub GenerateCertificateSigningRequestByDn {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['distinguishedName', undef],
    ];
    return $self->soap_call('GenerateCertificateSigningRequestByDn', undef, 0, $x_args, \%args);
}

sub GenerateClientCsr {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['cluster', 'KeyProviderId'],
    ];
    return $self->soap_call('GenerateClientCsr', undef, 0, $x_args, \%args);
}

sub GenerateConfigTaskList {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['configSpec', 'HostConfigSpec'],
      ['host', 'ManagedObjectReference'],
    ];
    return $self->soap_call('GenerateConfigTaskList', 'HostProfileManagerConfigTaskList', 0, $x_args, \%args);
}

sub GenerateHostConfigTaskSpec_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['hostsInfo', 'StructuredCustomizations'],
    ];
    return $self->soap_call('GenerateHostConfigTaskSpec_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub GenerateHostProfileTaskList_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['configSpec', 'HostConfigSpec'],
      ['host', 'ManagedObjectReference'],
    ];
    return $self->soap_call('GenerateHostProfileTaskList_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub GenerateKey {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['keyProvider', 'KeyProviderId'],
    ];
    return $self->soap_call('GenerateKey', 'CryptoKeyResult', 0, $x_args, \%args);
}

sub GenerateLogBundles_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['includeDefault', 'boolean'],
      ['host', 'ManagedObjectReference'],
    ];
    return $self->soap_call('GenerateLogBundles_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub GenerateSelfSignedClientCert {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['cluster', 'KeyProviderId'],
    ];
    return $self->soap_call('GenerateSelfSignedClientCert', undef, 0, $x_args, \%args);
}

sub GetAlarm {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['entity', 'ManagedObjectReference'],
    ];
    return $self->soap_call('GetAlarm', 'ManagedObjectReference', 1, $x_args, \%args);
}

sub GetAlarmState {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['entity', 'ManagedObjectReference'],
    ];
    return $self->soap_call('GetAlarmState', 'AlarmState', 1, $x_args, \%args);
}

sub GetCustomizationSpec {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['name', undef],
    ];
    return $self->soap_call('GetCustomizationSpec', 'CustomizationSpecItem', 0, $x_args, \%args);
}

sub GetPublicKey {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('GetPublicKey', undef, 0, $x_args, \%args);
}

sub GetResourceUsage {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('GetResourceUsage', 'ClusterResourceUsageSummary', 0, $x_args, \%args);
}

sub GetVchaClusterHealth {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('GetVchaClusterHealth', 'VchaClusterHealth', 0, $x_args, \%args);
}

sub GetVsanObjExtAttrs {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['uuids', undef],
    ];
    return $self->soap_call('GetVsanObjExtAttrs', undef, 0, $x_args, \%args);
}

sub HasMonitoredEntity {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['providerId', undef],
      ['entity', 'ManagedObjectReference'],
    ];
    return $self->soap_call('HasMonitoredEntity', 'boolean', 0, $x_args, \%args);
}

sub HasPrivilegeOnEntities {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['entity', 'ManagedObjectReference'],
      ['sessionId', undef],
      ['privId', undef],
    ];
    return $self->soap_call('HasPrivilegeOnEntities', 'EntityPrivilege', 1, $x_args, \%args);
}

sub HasPrivilegeOnEntity {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['entity', 'ManagedObjectReference'],
      ['sessionId', undef],
      ['privId', undef],
    ];
    return $self->soap_call('HasPrivilegeOnEntity', 'boolean', 1, $x_args, \%args);
}

sub HasProvider {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['id', undef],
    ];
    return $self->soap_call('HasProvider', 'boolean', 0, $x_args, \%args);
}

sub HasUserPrivilegeOnEntities {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['entities', 'ManagedObjectReference'],
      ['userName', undef],
      ['privId', undef],
    ];
    return $self->soap_call('HasUserPrivilegeOnEntities', 'EntityPrivilege', 1, $x_args, \%args);
}

sub HostCloneVStorageObject_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['id', 'ID'],
      ['datastore', 'ManagedObjectReference'],
      ['spec', 'VslmCloneSpec'],
    ];
    return $self->soap_call('HostCloneVStorageObject_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub HostConfigVFlashCache {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['spec', 'HostVFlashManagerVFlashCacheConfigSpec'],
    ];
    return $self->soap_call('HostConfigVFlashCache', undef, 0, $x_args, \%args);
}

sub HostConfigureVFlashResource {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['spec', 'HostVFlashManagerVFlashResourceConfigSpec'],
    ];
    return $self->soap_call('HostConfigureVFlashResource', undef, 0, $x_args, \%args);
}

sub HostCreateDisk_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['spec', 'VslmCreateSpec'],
    ];
    return $self->soap_call('HostCreateDisk_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub HostDeleteVStorageObject_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['id', 'ID'],
      ['datastore', 'ManagedObjectReference'],
    ];
    return $self->soap_call('HostDeleteVStorageObject_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub HostExtendDisk_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['id', 'ID'],
      ['datastore', 'ManagedObjectReference'],
      ['newCapacityInMB', undef],
    ];
    return $self->soap_call('HostExtendDisk_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub HostGetVFlashModuleDefaultConfig {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['vFlashModule', undef],
    ];
    return $self->soap_call('HostGetVFlashModuleDefaultConfig', 'VirtualDiskVFlashCacheConfigInfo', 0, $x_args, \%args);
}

sub HostImageConfigGetAcceptance {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('HostImageConfigGetAcceptance', undef, 0, $x_args, \%args);
}

sub HostImageConfigGetProfile {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('HostImageConfigGetProfile', 'HostImageProfileSummary', 0, $x_args, \%args);
}

sub HostInflateDisk_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['id', 'ID'],
      ['datastore', 'ManagedObjectReference'],
    ];
    return $self->soap_call('HostInflateDisk_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub HostListVStorageObject {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['datastore', 'ManagedObjectReference'],
    ];
    return $self->soap_call('HostListVStorageObject', 'ID', 1, $x_args, \%args);
}

sub HostReconcileDatastoreInventory_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['datastore', 'ManagedObjectReference'],
    ];
    return $self->soap_call('HostReconcileDatastoreInventory_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub HostRegisterDisk {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['path', undef],
      ['name', undef],
    ];
    return $self->soap_call('HostRegisterDisk', 'VStorageObject', 0, $x_args, \%args);
}

sub HostRelocateVStorageObject_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['id', 'ID'],
      ['datastore', 'ManagedObjectReference'],
      ['spec', 'VslmRelocateSpec'],
    ];
    return $self->soap_call('HostRelocateVStorageObject_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub HostRemoveVFlashResource {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('HostRemoveVFlashResource', undef, 0, $x_args, \%args);
}

sub HostRenameVStorageObject {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['id', 'ID'],
      ['datastore', 'ManagedObjectReference'],
      ['name', undef],
    ];
    return $self->soap_call('HostRenameVStorageObject', undef, 0, $x_args, \%args);
}

sub HostRetrieveVStorageObject {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['id', 'ID'],
      ['datastore', 'ManagedObjectReference'],
    ];
    return $self->soap_call('HostRetrieveVStorageObject', 'VStorageObject', 0, $x_args, \%args);
}

sub HostRetrieveVStorageObjectState {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['id', 'ID'],
      ['datastore', 'ManagedObjectReference'],
    ];
    return $self->soap_call('HostRetrieveVStorageObjectState', 'VStorageObjectStateInfo', 0, $x_args, \%args);
}

sub HostScheduleReconcileDatastoreInventory {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['datastore', 'ManagedObjectReference'],
    ];
    return $self->soap_call('HostScheduleReconcileDatastoreInventory', undef, 0, $x_args, \%args);
}

sub HostSpecGetUpdatedHosts {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['startChangeID', undef],
      ['endChangeID', undef],
    ];
    return $self->soap_call('HostSpecGetUpdatedHosts', 'ManagedObjectReference', 1, $x_args, \%args);
}

sub HttpNfcLeaseAbort {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['fault', 'LocalizedMethodFault'],
    ];
    return $self->soap_call('HttpNfcLeaseAbort', undef, 0, $x_args, \%args);
}

sub HttpNfcLeaseComplete {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('HttpNfcLeaseComplete', undef, 0, $x_args, \%args);
}

sub HttpNfcLeaseGetManifest {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('HttpNfcLeaseGetManifest', 'HttpNfcLeaseManifestEntry', 1, $x_args, \%args);
}

sub HttpNfcLeaseProgress {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['percent', undef],
    ];
    return $self->soap_call('HttpNfcLeaseProgress', undef, 0, $x_args, \%args);
}

sub ImpersonateUser {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['userName', undef],
      ['locale', undef],
    ];
    return $self->soap_call('ImpersonateUser', 'UserSession', 0, $x_args, \%args);
}

sub ImportCertificateForCAM_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['certPath', undef],
      ['camServer', undef],
    ];
    return $self->soap_call('ImportCertificateForCAM_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub ImportUnmanagedSnapshot {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['vdisk', undef],
      ['datacenter', 'ManagedObjectReference'],
      ['vvolId', undef],
    ];
    return $self->soap_call('ImportUnmanagedSnapshot', undef, 0, $x_args, \%args);
}

sub ImportVApp {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['spec', 'ImportSpec'],
      ['folder', 'ManagedObjectReference'],
      ['host', 'ManagedObjectReference'],
    ];
    return $self->soap_call('ImportVApp', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub InflateDisk_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['id', 'ID'],
      ['datastore', 'ManagedObjectReference'],
    ];
    return $self->soap_call('InflateDisk_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub InflateVirtualDisk_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['name', undef],
      ['datacenter', 'ManagedObjectReference'],
    ];
    return $self->soap_call('InflateVirtualDisk_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub InitializeDisks_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['mapping', 'VsanHostDiskMapping'],
    ];
    return $self->soap_call('InitializeDisks_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub InitiateFileTransferFromGuest {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['vm', 'ManagedObjectReference'],
      ['auth', 'GuestAuthentication'],
      ['guestFilePath', undef],
    ];
    return $self->soap_call('InitiateFileTransferFromGuest', 'FileTransferInformation', 0, $x_args, \%args);
}

sub InitiateFileTransferToGuest {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['vm', 'ManagedObjectReference'],
      ['auth', 'GuestAuthentication'],
      ['guestFilePath', undef],
      ['fileAttributes', 'GuestFileAttributes'],
      ['fileSize', undef],
      ['overwrite', 'boolean'],
    ];
    return $self->soap_call('InitiateFileTransferToGuest', undef, 0, $x_args, \%args);
}

sub InstallHostPatchV2_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['metaUrls', undef],
      ['bundleUrls', undef],
      ['vibUrls', undef],
      ['spec', 'HostPatchManagerPatchManagerOperationSpec'],
    ];
    return $self->soap_call('InstallHostPatchV2_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub InstallHostPatch_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['repository', 'HostPatchManagerLocator'],
      ['updateID', undef],
      ['force', 'boolean'],
    ];
    return $self->soap_call('InstallHostPatch_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub InstallIoFilter_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['vibUrl', undef],
      ['compRes', 'ManagedObjectReference'],
    ];
    return $self->soap_call('InstallIoFilter_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub InstallServerCertificate {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['cert', undef],
    ];
    return $self->soap_call('InstallServerCertificate', undef, 0, $x_args, \%args);
}

sub InstallSmartCardTrustAnchor {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['cert', undef],
    ];
    return $self->soap_call('InstallSmartCardTrustAnchor', undef, 0, $x_args, \%args);
}

sub IsSharedGraphicsActive {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('IsSharedGraphicsActive', 'boolean', 0, $x_args, \%args);
}

sub JoinDomainWithCAM_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['domainName', undef],
      ['camServer', undef],
    ];
    return $self->soap_call('JoinDomainWithCAM_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub JoinDomain_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['domainName', undef],
      ['userName', undef],
      ['password', undef],
    ];
    return $self->soap_call('JoinDomain_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub LeaveCurrentDomain_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['force', 'boolean'],
    ];
    return $self->soap_call('LeaveCurrentDomain_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub ListCACertificateRevocationLists {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('ListCACertificateRevocationLists', undef, 1, $x_args, \%args);
}

sub ListCACertificates {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('ListCACertificates', undef, 1, $x_args, \%args);
}

sub ListFilesInGuest {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['vm', 'ManagedObjectReference'],
      ['auth', 'GuestAuthentication'],
      ['filePath', undef],
      ['index', undef],
      ['maxResults', undef],
      ['matchPattern', undef],
    ];
    return $self->soap_call('ListFilesInGuest', 'GuestListFileInfo', 0, $x_args, \%args);
}

sub ListGuestAliases {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['vm', 'ManagedObjectReference'],
      ['auth', 'GuestAuthentication'],
      ['username', undef],
    ];
    return $self->soap_call('ListGuestAliases', 'GuestAliases', 1, $x_args, \%args);
}

sub ListGuestMappedAliases {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['vm', 'ManagedObjectReference'],
      ['auth', 'GuestAuthentication'],
    ];
    return $self->soap_call('ListGuestMappedAliases', 'GuestMappedAliases', 1, $x_args, \%args);
}

sub ListKeys {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['limit', undef],
    ];
    return $self->soap_call('ListKeys', 'CryptoKeyId', 1, $x_args, \%args);
}

sub ListKmipServers {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['limit', undef],
    ];
    return $self->soap_call('ListKmipServers', 'KmipClusterInfo', 1, $x_args, \%args);
}

sub ListProcessesInGuest {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['vm', 'ManagedObjectReference'],
      ['auth', 'GuestAuthentication'],
      ['pids', undef],
    ];
    return $self->soap_call('ListProcessesInGuest', 'GuestProcessInfo', 1, $x_args, \%args);
}

sub ListRegistryKeysInGuest {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['vm', 'ManagedObjectReference'],
      ['auth', 'GuestAuthentication'],
      ['keyName', 'GuestRegKeyNameSpec'],
      ['recursive', 'boolean'],
      ['matchPattern', undef],
    ];
    return $self->soap_call('ListRegistryKeysInGuest', 'GuestRegKeyRecordSpec', 1, $x_args, \%args);
}

sub ListRegistryValuesInGuest {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['vm', 'ManagedObjectReference'],
      ['auth', 'GuestAuthentication'],
      ['keyName', 'GuestRegKeyNameSpec'],
      ['expandStrings', 'boolean'],
      ['matchPattern', undef],
    ];
    return $self->soap_call('ListRegistryValuesInGuest', 'GuestRegValueSpec', 1, $x_args, \%args);
}

sub ListSmartCardTrustAnchors {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('ListSmartCardTrustAnchors', undef, 1, $x_args, \%args);
}

sub ListTagsAttachedToVStorageObject {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['id', 'ID'],
    ];
    return $self->soap_call('ListTagsAttachedToVStorageObject', 'VslmTagEntry', 1, $x_args, \%args);
}

sub ListVStorageObject {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['datastore', 'ManagedObjectReference'],
    ];
    return $self->soap_call('ListVStorageObject', 'ID', 1, $x_args, \%args);
}

sub ListVStorageObjectsAttachedToTag {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['category', undef],
      ['tag', undef],
    ];
    return $self->soap_call('ListVStorageObjectsAttachedToTag', 'ID', 1, $x_args, \%args);
}

sub LogUserEvent {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['entity', 'ManagedObjectReference'],
      ['msg', undef],
    ];
    return $self->soap_call('LogUserEvent', undef, 0, $x_args, \%args);
}

sub Login {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['userName', undef],
      ['password', undef],
      ['locale', undef],
    ];
    return $self->soap_call('Login', 'UserSession', 0, $x_args, \%args);
}

sub LoginBySSPI {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['base64Token', undef],
      ['locale', undef],
    ];
    return $self->soap_call('LoginBySSPI', 'UserSession', 0, $x_args, \%args);
}

sub LoginByToken {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['locale', undef],
    ];
    return $self->soap_call('LoginByToken', 'UserSession', 0, $x_args, \%args);
}

sub LoginExtensionByCertificate {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['extensionKey', undef],
      ['locale', undef],
    ];
    return $self->soap_call('LoginExtensionByCertificate', 'UserSession', 0, $x_args, \%args);
}

sub LoginExtensionBySubjectName {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['extensionKey', undef],
      ['locale', undef],
    ];
    return $self->soap_call('LoginExtensionBySubjectName', 'UserSession', 0, $x_args, \%args);
}

sub Logout {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('Logout', undef, 0, $x_args, \%args);
}

sub LookupDvPortGroup {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['portgroupKey', undef],
    ];
    return $self->soap_call('LookupDvPortGroup', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub LookupVmOverheadMemory {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['vm', 'ManagedObjectReference'],
      ['host', 'ManagedObjectReference'],
    ];
    return $self->soap_call('LookupVmOverheadMemory', undef, 0, $x_args, \%args);
}

sub MakeDirectory {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['name', undef],
      ['datacenter', 'ManagedObjectReference'],
      ['createParentDirectories', 'boolean'],
    ];
    return $self->soap_call('MakeDirectory', undef, 0, $x_args, \%args);
}

sub MakeDirectoryInGuest {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['vm', 'ManagedObjectReference'],
      ['auth', 'GuestAuthentication'],
      ['directoryPath', undef],
      ['createParentDirectories', 'boolean'],
    ];
    return $self->soap_call('MakeDirectoryInGuest', undef, 0, $x_args, \%args);
}

sub MakePrimaryVM_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['vm', 'ManagedObjectReference'],
    ];
    return $self->soap_call('MakePrimaryVM_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub MarkAsLocal_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['scsiDiskUuid', undef],
    ];
    return $self->soap_call('MarkAsLocal_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub MarkAsNonLocal_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['scsiDiskUuid', undef],
    ];
    return $self->soap_call('MarkAsNonLocal_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub MarkAsNonSsd_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['scsiDiskUuid', undef],
    ];
    return $self->soap_call('MarkAsNonSsd_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub MarkAsSsd_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['scsiDiskUuid', undef],
    ];
    return $self->soap_call('MarkAsSsd_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub MarkAsTemplate {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('MarkAsTemplate', undef, 0, $x_args, \%args);
}

sub MarkAsVirtualMachine {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['pool', 'ManagedObjectReference'],
      ['host', 'ManagedObjectReference'],
    ];
    return $self->soap_call('MarkAsVirtualMachine', undef, 0, $x_args, \%args);
}

sub MarkDefault {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['clusterId', 'KeyProviderId'],
    ];
    return $self->soap_call('MarkDefault', undef, 0, $x_args, \%args);
}

sub MarkForRemoval {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['hbaName', undef],
      ['remove', 'boolean'],
    ];
    return $self->soap_call('MarkForRemoval', undef, 0, $x_args, \%args);
}

sub MergeDvs_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['dvs', 'ManagedObjectReference'],
    ];
    return $self->soap_call('MergeDvs_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub MergePermissions {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['srcRoleId', undef],
      ['dstRoleId', undef],
    ];
    return $self->soap_call('MergePermissions', undef, 0, $x_args, \%args);
}

sub MigrateVM_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['pool', 'ManagedObjectReference'],
      ['host', 'ManagedObjectReference'],
      ['priority', 'VirtualMachineMovePriority'],
      ['state', 'VirtualMachinePowerState'],
    ];
    return $self->soap_call('MigrateVM_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub ModifyListView {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['add', 'ManagedObjectReference'],
      ['remove', 'ManagedObjectReference'],
    ];
    return $self->soap_call('ModifyListView', 'ManagedObjectReference', 1, $x_args, \%args);
}

sub MountToolsInstaller {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('MountToolsInstaller', undef, 0, $x_args, \%args);
}

sub MountVffsVolume {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['vffsUuid', undef],
    ];
    return $self->soap_call('MountVffsVolume', undef, 0, $x_args, \%args);
}

sub MountVmfsVolume {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['vmfsUuid', undef],
    ];
    return $self->soap_call('MountVmfsVolume', undef, 0, $x_args, \%args);
}

sub MountVmfsVolumeEx_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['vmfsUuid', undef],
    ];
    return $self->soap_call('MountVmfsVolumeEx_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub MoveDVPort_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['portKey', undef],
      ['destinationPortgroupKey', undef],
    ];
    return $self->soap_call('MoveDVPort_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub MoveDatastoreFile_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['sourceName', undef],
      ['sourceDatacenter', 'ManagedObjectReference'],
      ['destinationName', undef],
      ['destinationDatacenter', 'ManagedObjectReference'],
      ['force', 'boolean'],
    ];
    return $self->soap_call('MoveDatastoreFile_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub MoveDirectoryInGuest {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['vm', 'ManagedObjectReference'],
      ['auth', 'GuestAuthentication'],
      ['srcDirectoryPath', undef],
      ['dstDirectoryPath', undef],
    ];
    return $self->soap_call('MoveDirectoryInGuest', undef, 0, $x_args, \%args);
}

sub MoveFileInGuest {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['vm', 'ManagedObjectReference'],
      ['auth', 'GuestAuthentication'],
      ['srcFilePath', undef],
      ['dstFilePath', undef],
      ['overwrite', 'boolean'],
    ];
    return $self->soap_call('MoveFileInGuest', undef, 0, $x_args, \%args);
}

sub MoveHostInto_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['host', 'ManagedObjectReference'],
      ['resourcePool', 'ManagedObjectReference'],
    ];
    return $self->soap_call('MoveHostInto_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub MoveIntoFolder_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['list', 'ManagedObjectReference'],
    ];
    return $self->soap_call('MoveIntoFolder_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub MoveIntoResourcePool {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['list', 'ManagedObjectReference'],
    ];
    return $self->soap_call('MoveIntoResourcePool', undef, 0, $x_args, \%args);
}

sub MoveInto_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['host', 'ManagedObjectReference'],
    ];
    return $self->soap_call('MoveInto_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub MoveVirtualDisk_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['sourceName', undef],
      ['sourceDatacenter', 'ManagedObjectReference'],
      ['destName', undef],
      ['destDatacenter', 'ManagedObjectReference'],
      ['force', 'boolean'],
      ['profile', 'VirtualMachineProfileSpec'],
    ];
    return $self->soap_call('MoveVirtualDisk_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub OpenInventoryViewFolder {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['entity', 'ManagedObjectReference'],
    ];
    return $self->soap_call('OpenInventoryViewFolder', 'ManagedObjectReference', 1, $x_args, \%args);
}

sub OverwriteCustomizationSpec {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['item', 'CustomizationSpecItem'],
    ];
    return $self->soap_call('OverwriteCustomizationSpec', undef, 0, $x_args, \%args);
}

sub ParseDescriptor {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['ovfDescriptor', undef],
      ['pdp', 'OvfParseDescriptorParams'],
    ];
    return $self->soap_call('ParseDescriptor', 'OvfParseDescriptorResult', 0, $x_args, \%args);
}

sub PerformDvsProductSpecOperation_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['operation', undef],
      ['productSpec', 'DistributedVirtualSwitchProductSpec'],
    ];
    return $self->soap_call('PerformDvsProductSpecOperation_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub PerformVsanUpgradePreflightCheck {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['cluster', 'ManagedObjectReference'],
      ['downgradeFormat', 'boolean'],
    ];
    return $self->soap_call('PerformVsanUpgradePreflightCheck', 'VsanUpgradeSystemPreflightCheckResult', 0, $x_args, \%args);
}

sub PerformVsanUpgrade_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['cluster', 'ManagedObjectReference'],
      ['performObjectUpgrade', 'boolean'],
      ['downgradeFormat', 'boolean'],
      ['allowReducedRedundancy', 'boolean'],
      ['excludeHosts', 'ManagedObjectReference'],
    ];
    return $self->soap_call('PerformVsanUpgrade_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub PlaceVm {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['placementSpec', 'PlacementSpec'],
    ];
    return $self->soap_call('PlaceVm', 'PlacementResult', 0, $x_args, \%args);
}

sub PostEvent {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['eventToPost', 'Event'],
      ['taskInfo', 'TaskInfo'],
    ];
    return $self->soap_call('PostEvent', undef, 0, $x_args, \%args);
}

sub PostHealthUpdates {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['providerId', undef],
      ['updates', 'HealthUpdate'],
    ];
    return $self->soap_call('PostHealthUpdates', undef, 0, $x_args, \%args);
}

sub PowerDownHostToStandBy_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['timeoutSec', undef],
      ['evacuatePoweredOffVms', 'boolean'],
    ];
    return $self->soap_call('PowerDownHostToStandBy_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub PowerOffVApp_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['force', 'boolean'],
    ];
    return $self->soap_call('PowerOffVApp_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub PowerOffVM_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('PowerOffVM_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub PowerOnMultiVM_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['vm', 'ManagedObjectReference'],
      ['option', 'OptionValue'],
    ];
    return $self->soap_call('PowerOnMultiVM_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub PowerOnVApp_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('PowerOnVApp_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub PowerOnVM_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['host', 'ManagedObjectReference'],
    ];
    return $self->soap_call('PowerOnVM_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub PowerUpHostFromStandBy_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['timeoutSec', undef],
    ];
    return $self->soap_call('PowerUpHostFromStandBy_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub PrepareCrypto {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('PrepareCrypto', undef, 0, $x_args, \%args);
}

sub PromoteDisks_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['unlink', 'boolean'],
      ['disks', 'VirtualDisk'],
    ];
    return $self->soap_call('PromoteDisks_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub PutUsbScanCodes {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['spec', 'UsbScanCodeSpec'],
    ];
    return $self->soap_call('PutUsbScanCodes', undef, 0, $x_args, \%args);
}

sub QueryAnswerFileStatus {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['host', 'ManagedObjectReference'],
    ];
    return $self->soap_call('QueryAnswerFileStatus', 'AnswerFileStatusResult', 1, $x_args, \%args);
}

sub QueryAssignedLicenses {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['entityId', undef],
    ];
    return $self->soap_call('QueryAssignedLicenses', 'LicenseAssignmentManagerLicenseAssignment', 1, $x_args, \%args);
}

sub QueryAvailableDisksForVmfs {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['datastore', 'ManagedObjectReference'],
    ];
    return $self->soap_call('QueryAvailableDisksForVmfs', 'HostScsiDisk', 1, $x_args, \%args);
}

sub QueryAvailableDvsSpec {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['recommended', 'boolean'],
    ];
    return $self->soap_call('QueryAvailableDvsSpec', 'DistributedVirtualSwitchProductSpec', 1, $x_args, \%args);
}

sub QueryAvailablePartition {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('QueryAvailablePartition', 'HostDiagnosticPartition', 1, $x_args, \%args);
}

sub QueryAvailablePerfMetric {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['entity', 'ManagedObjectReference'],
      ['beginTime', undef],
      ['endTime', undef],
      ['intervalId', undef],
    ];
    return $self->soap_call('QueryAvailablePerfMetric', 'PerfMetricId', 1, $x_args, \%args);
}

sub QueryAvailableSsds {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['vffsPath', undef],
    ];
    return $self->soap_call('QueryAvailableSsds', 'HostScsiDisk', 1, $x_args, \%args);
}

sub QueryAvailableTimeZones {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('QueryAvailableTimeZones', 'HostDateTimeSystemTimeZone', 1, $x_args, \%args);
}

sub QueryBootDevices {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('QueryBootDevices', 'HostBootDeviceInfo', 0, $x_args, \%args);
}

sub QueryBoundVnics {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['iScsiHbaName', undef],
    ];
    return $self->soap_call('QueryBoundVnics', 'IscsiPortInfo', 1, $x_args, \%args);
}

sub QueryCandidateNics {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['iScsiHbaName', undef],
    ];
    return $self->soap_call('QueryCandidateNics', 'IscsiPortInfo', 1, $x_args, \%args);
}

sub QueryChangedDiskAreas {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['snapshot', 'ManagedObjectReference'],
      ['deviceKey', undef],
      ['startOffset', undef],
      ['changeId', undef],
    ];
    return $self->soap_call('QueryChangedDiskAreas', 'DiskChangeInfo', 0, $x_args, \%args);
}

sub QueryCmmds {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['queries', 'HostVsanInternalSystemCmmdsQuery'],
    ];
    return $self->soap_call('QueryCmmds', undef, 0, $x_args, \%args);
}

sub QueryCompatibleHostForExistingDvs {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['container', 'ManagedObjectReference'],
      ['recursive', 'boolean'],
      ['dvs', 'ManagedObjectReference'],
    ];
    return $self->soap_call('QueryCompatibleHostForExistingDvs', 'ManagedObjectReference', 1, $x_args, \%args);
}

sub QueryCompatibleHostForNewDvs {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['container', 'ManagedObjectReference'],
      ['recursive', 'boolean'],
      ['switchProductSpec', 'DistributedVirtualSwitchProductSpec'],
    ];
    return $self->soap_call('QueryCompatibleHostForNewDvs', 'ManagedObjectReference', 1, $x_args, \%args);
}

sub QueryComplianceStatus {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['profile', 'ManagedObjectReference'],
      ['entity', 'ManagedObjectReference'],
    ];
    return $self->soap_call('QueryComplianceStatus', 'ComplianceResult', 1, $x_args, \%args);
}

sub QueryConfigOption {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['key', undef],
      ['host', 'ManagedObjectReference'],
    ];
    return $self->soap_call('QueryConfigOption', 'VirtualMachineConfigOption', 0, $x_args, \%args);
}

sub QueryConfigOptionDescriptor {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('QueryConfigOptionDescriptor', 'VirtualMachineConfigOptionDescriptor', 1, $x_args, \%args);
}

sub QueryConfigOptionEx {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['spec', 'EnvironmentBrowserConfigOptionQuerySpec'],
    ];
    return $self->soap_call('QueryConfigOptionEx', 'VirtualMachineConfigOption', 0, $x_args, \%args);
}

sub QueryConfigTarget {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['host', 'ManagedObjectReference'],
    ];
    return $self->soap_call('QueryConfigTarget', 'ConfigTarget', 0, $x_args, \%args);
}

sub QueryConfiguredModuleOptionString {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['name', undef],
    ];
    return $self->soap_call('QueryConfiguredModuleOptionString', undef, 0, $x_args, \%args);
}

sub QueryConnectionInfo {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['hostname', undef],
      ['port', undef],
      ['username', undef],
      ['password', undef],
      ['sslThumbprint', undef],
    ];
    return $self->soap_call('QueryConnectionInfo', 'HostConnectInfo', 0, $x_args, \%args);
}

sub QueryConnectionInfoViaSpec {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['spec', 'HostConnectSpec'],
    ];
    return $self->soap_call('QueryConnectionInfoViaSpec', 'HostConnectInfo', 0, $x_args, \%args);
}

sub QueryDatastorePerformanceSummary {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['datastore', 'ManagedObjectReference'],
    ];
    return $self->soap_call('QueryDatastorePerformanceSummary', 'StoragePerformanceSummary', 1, $x_args, \%args);
}

sub QueryDateTime {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('QueryDateTime', undef, 0, $x_args, \%args);
}

sub QueryDescriptions {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['host', 'ManagedObjectReference'],
    ];
    return $self->soap_call('QueryDescriptions', 'DiagnosticManagerLogDescriptor', 1, $x_args, \%args);
}

sub QueryDisksForVsan {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['canonicalName', undef],
    ];
    return $self->soap_call('QueryDisksForVsan', 'VsanHostDiskResult', 1, $x_args, \%args);
}

sub QueryDisksUsingFilter {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['filterId', undef],
      ['compRes', 'ManagedObjectReference'],
    ];
    return $self->soap_call('QueryDisksUsingFilter', 'VirtualDiskId', 1, $x_args, \%args);
}

sub QueryDvsByUuid {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['uuid', undef],
    ];
    return $self->soap_call('QueryDvsByUuid', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub QueryDvsCheckCompatibility {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['hostContainer', 'DistributedVirtualSwitchManagerHostContainer'],
      ['dvsProductSpec', 'DistributedVirtualSwitchManagerDvsProductSpec'],
      ['hostFilterSpec', 'DistributedVirtualSwitchManagerHostDvsFilterSpec'],
    ];
    return $self->soap_call('QueryDvsCheckCompatibility', 'DistributedVirtualSwitchManagerCompatibilityResult', 1, $x_args, \%args);
}

sub QueryDvsCompatibleHostSpec {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['switchProductSpec', 'DistributedVirtualSwitchProductSpec'],
    ];
    return $self->soap_call('QueryDvsCompatibleHostSpec', 'DistributedVirtualSwitchHostProductSpec', 1, $x_args, \%args);
}

sub QueryDvsConfigTarget {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['host', 'ManagedObjectReference'],
      ['dvs', 'ManagedObjectReference'],
    ];
    return $self->soap_call('QueryDvsConfigTarget', 'DVSManagerDvsConfigTarget', 0, $x_args, \%args);
}

sub QueryDvsFeatureCapability {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['switchProductSpec', 'DistributedVirtualSwitchProductSpec'],
    ];
    return $self->soap_call('QueryDvsFeatureCapability', 'DVSFeatureCapability', 0, $x_args, \%args);
}

sub QueryEvents {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['filter', 'EventFilterSpec'],
    ];
    return $self->soap_call('QueryEvents', 'Event', 1, $x_args, \%args);
}

sub QueryExpressionMetadata {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['expressionName', undef],
      ['profile', 'ManagedObjectReference'],
    ];
    return $self->soap_call('QueryExpressionMetadata', 'ProfileExpressionMetadata', 1, $x_args, \%args);
}

sub QueryExtensionIpAllocationUsage {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['extensionKeys', undef],
    ];
    return $self->soap_call('QueryExtensionIpAllocationUsage', 'ExtensionManagerIpAllocationUsage', 1, $x_args, \%args);
}

sub QueryFaultToleranceCompatibility {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('QueryFaultToleranceCompatibility', 'LocalizedMethodFault', 1, $x_args, \%args);
}

sub QueryFaultToleranceCompatibilityEx {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['forLegacyFt', 'boolean'],
    ];
    return $self->soap_call('QueryFaultToleranceCompatibilityEx', 'LocalizedMethodFault', 1, $x_args, \%args);
}

sub QueryFilterEntities {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['filterId', undef],
    ];
    return $self->soap_call('QueryFilterEntities', 'ManagedObjectReference', 1, $x_args, \%args);
}

sub QueryFilterInfoIds {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['filterId', undef],
    ];
    return $self->soap_call('QueryFilterInfoIds', undef, 1, $x_args, \%args);
}

sub QueryFilterList {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['providerId', undef],
    ];
    return $self->soap_call('QueryFilterList', undef, 1, $x_args, \%args);
}

sub QueryFilterName {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['filterId', undef],
    ];
    return $self->soap_call('QueryFilterName', undef, 0, $x_args, \%args);
}

sub QueryFirmwareConfigUploadURL {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('QueryFirmwareConfigUploadURL', undef, 0, $x_args, \%args);
}

sub QueryHealthUpdateInfos {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['providerId', undef],
    ];
    return $self->soap_call('QueryHealthUpdateInfos', 'HealthUpdateInfo', 1, $x_args, \%args);
}

sub QueryHealthUpdates {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['providerId', undef],
    ];
    return $self->soap_call('QueryHealthUpdates', 'HealthUpdate', 1, $x_args, \%args);
}

sub QueryHostConnectionInfo {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('QueryHostConnectionInfo', 'HostConnectInfo', 0, $x_args, \%args);
}

sub QueryHostPatch_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['spec', 'HostPatchManagerPatchManagerOperationSpec'],
    ];
    return $self->soap_call('QueryHostPatch_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub QueryHostProfileMetadata {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['profileName', undef],
      ['profile', 'ManagedObjectReference'],
    ];
    return $self->soap_call('QueryHostProfileMetadata', 'ProfileMetadata', 1, $x_args, \%args);
}

sub QueryHostStatus {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('QueryHostStatus', 'VsanHostClusterStatus', 0, $x_args, \%args);
}

sub QueryIORMConfigOption {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['host', 'ManagedObjectReference'],
    ];
    return $self->soap_call('QueryIORMConfigOption', 'StorageIORMConfigOption', 0, $x_args, \%args);
}

sub QueryIPAllocations {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['dc', 'ManagedObjectReference'],
      ['poolId', undef],
      ['extensionKey', undef],
    ];
    return $self->soap_call('QueryIPAllocations', 'IpPoolManagerIpAllocation', 1, $x_args, \%args);
}

sub QueryIoFilterInfo {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['compRes', 'ManagedObjectReference'],
    ];
    return $self->soap_call('QueryIoFilterInfo', 'ClusterIoFilterInfo', 1, $x_args, \%args);
}

sub QueryIoFilterIssues {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['filterId', undef],
      ['compRes', 'ManagedObjectReference'],
    ];
    return $self->soap_call('QueryIoFilterIssues', 'IoFilterQueryIssueResult', 0, $x_args, \%args);
}

sub QueryIpPools {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['dc', 'ManagedObjectReference'],
    ];
    return $self->soap_call('QueryIpPools', 'IpPool', 1, $x_args, \%args);
}

sub QueryLicenseSourceAvailability {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['host', 'ManagedObjectReference'],
    ];
    return $self->soap_call('QueryLicenseSourceAvailability', 'LicenseAvailabilityInfo', 1, $x_args, \%args);
}

sub QueryLicenseUsage {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['host', 'ManagedObjectReference'],
    ];
    return $self->soap_call('QueryLicenseUsage', 'LicenseUsageInfo', 0, $x_args, \%args);
}

sub QueryLockdownExceptions {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('QueryLockdownExceptions', undef, 1, $x_args, \%args);
}

sub QueryManagedBy {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['extensionKey', undef],
    ];
    return $self->soap_call('QueryManagedBy', 'ManagedObjectReference', 1, $x_args, \%args);
}

sub QueryMemoryOverhead {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['memorySize', undef],
      ['videoRamSize', undef],
      ['numVcpus', undef],
    ];
    return $self->soap_call('QueryMemoryOverhead', undef, 0, $x_args, \%args);
}

sub QueryMemoryOverheadEx {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['vmConfigInfo', 'VirtualMachineConfigInfo'],
    ];
    return $self->soap_call('QueryMemoryOverheadEx', undef, 0, $x_args, \%args);
}

sub QueryMigrationDependencies {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['pnicDevice', undef],
    ];
    return $self->soap_call('QueryMigrationDependencies', 'IscsiMigrationDependency', 0, $x_args, \%args);
}

sub QueryModules {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('QueryModules', 'KernelModuleInfo', 1, $x_args, \%args);
}

sub QueryMonitoredEntities {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['providerId', undef],
    ];
    return $self->soap_call('QueryMonitoredEntities', 'ManagedObjectReference', 1, $x_args, \%args);
}

sub QueryNFSUser {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('QueryNFSUser', 'HostNasVolumeUserInfo', 0, $x_args, \%args);
}

sub QueryNetConfig {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['nicType', undef],
    ];
    return $self->soap_call('QueryNetConfig', 'VirtualNicManagerNetConfig', 0, $x_args, \%args);
}

sub QueryNetworkHint {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['device', undef],
    ];
    return $self->soap_call('QueryNetworkHint', 'PhysicalNicHintInfo', 1, $x_args, \%args);
}

sub QueryObjectsOnPhysicalVsanDisk {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['disks', undef],
    ];
    return $self->soap_call('QueryObjectsOnPhysicalVsanDisk', undef, 0, $x_args, \%args);
}

sub QueryOptions {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['name', undef],
    ];
    return $self->soap_call('QueryOptions', 'OptionValue', 1, $x_args, \%args);
}

sub QueryPartitionCreateDesc {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['diskUuid', undef],
      ['diagnosticType', undef],
    ];
    return $self->soap_call('QueryPartitionCreateDesc', 'HostDiagnosticPartitionCreateDescription', 0, $x_args, \%args);
}

sub QueryPartitionCreateOptions {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['storageType', undef],
      ['diagnosticType', undef],
    ];
    return $self->soap_call('QueryPartitionCreateOptions', 'HostDiagnosticPartitionCreateOption', 1, $x_args, \%args);
}

sub QueryPathSelectionPolicyOptions {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('QueryPathSelectionPolicyOptions', 'HostPathSelectionPolicyOption', 1, $x_args, \%args);
}

sub QueryPerf {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['querySpec', 'PerfQuerySpec'],
    ];
    return $self->soap_call('QueryPerf', 'PerfEntityMetricBase', 1, $x_args, \%args);
}

sub QueryPerfComposite {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['querySpec', 'PerfQuerySpec'],
    ];
    return $self->soap_call('QueryPerfComposite', 'PerfCompositeMetric', 0, $x_args, \%args);
}

sub QueryPerfCounter {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['counterId', undef],
    ];
    return $self->soap_call('QueryPerfCounter', 'PerfCounterInfo', 1, $x_args, \%args);
}

sub QueryPerfCounterByLevel {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['level', undef],
    ];
    return $self->soap_call('QueryPerfCounterByLevel', 'PerfCounterInfo', 1, $x_args, \%args);
}

sub QueryPerfProviderSummary {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['entity', 'ManagedObjectReference'],
    ];
    return $self->soap_call('QueryPerfProviderSummary', 'PerfProviderSummary', 0, $x_args, \%args);
}

sub QueryPhysicalVsanDisks {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['props', undef],
    ];
    return $self->soap_call('QueryPhysicalVsanDisks', undef, 0, $x_args, \%args);
}

sub QueryPnicStatus {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['pnicDevice', undef],
    ];
    return $self->soap_call('QueryPnicStatus', 'IscsiStatus', 0, $x_args, \%args);
}

sub QueryPolicyMetadata {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['policyName', undef],
      ['profile', 'ManagedObjectReference'],
    ];
    return $self->soap_call('QueryPolicyMetadata', 'ProfilePolicyMetadata', 1, $x_args, \%args);
}

sub QueryProfileStructure {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['profile', 'ManagedObjectReference'],
    ];
    return $self->soap_call('QueryProfileStructure', 'ProfileProfileStructure', 0, $x_args, \%args);
}

sub QueryProviderList {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('QueryProviderList', undef, 1, $x_args, \%args);
}

sub QueryProviderName {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['id', undef],
    ];
    return $self->soap_call('QueryProviderName', undef, 0, $x_args, \%args);
}

sub QueryResourceConfigOption {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('QueryResourceConfigOption', 'ResourceConfigOption', 0, $x_args, \%args);
}

sub QueryServiceList {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['serviceName', undef],
      ['location', undef],
    ];
    return $self->soap_call('QueryServiceList', 'ServiceManagerServiceInfo', 1, $x_args, \%args);
}

sub QueryStorageArrayTypePolicyOptions {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('QueryStorageArrayTypePolicyOptions', 'HostStorageArrayTypePolicyOption', 1, $x_args, \%args);
}

sub QuerySupportedFeatures {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['host', 'ManagedObjectReference'],
    ];
    return $self->soap_call('QuerySupportedFeatures', 'LicenseFeatureInfo', 1, $x_args, \%args);
}

sub QuerySyncingVsanObjects {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['uuids', undef],
    ];
    return $self->soap_call('QuerySyncingVsanObjects', undef, 0, $x_args, \%args);
}

sub QuerySystemUsers {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('QuerySystemUsers', undef, 1, $x_args, \%args);
}

sub QueryTargetCapabilities {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['host', 'ManagedObjectReference'],
    ];
    return $self->soap_call('QueryTargetCapabilities', 'HostCapability', 0, $x_args, \%args);
}

sub QueryTpmAttestationReport {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('QueryTpmAttestationReport', 'HostTpmAttestationReport', 0, $x_args, \%args);
}

sub QueryUnmonitoredHosts {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['providerId', undef],
      ['cluster', 'ManagedObjectReference'],
    ];
    return $self->soap_call('QueryUnmonitoredHosts', 'ManagedObjectReference', 1, $x_args, \%args);
}

sub QueryUnownedFiles {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('QueryUnownedFiles', undef, 1, $x_args, \%args);
}

sub QueryUnresolvedVmfsVolume {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('QueryUnresolvedVmfsVolume', 'HostUnresolvedVmfsVolume', 1, $x_args, \%args);
}

sub QueryUnresolvedVmfsVolumes {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('QueryUnresolvedVmfsVolumes', 'HostUnresolvedVmfsVolume', 1, $x_args, \%args);
}

sub QueryUsedVlanIdInDvs {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('QueryUsedVlanIdInDvs', undef, 1, $x_args, \%args);
}

sub QueryVMotionCompatibility {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['vm', 'ManagedObjectReference'],
      ['host', 'ManagedObjectReference'],
      ['compatibility', undef],
    ];
    return $self->soap_call('QueryVMotionCompatibility', 'HostVMotionCompatibility', 1, $x_args, \%args);
}

sub QueryVMotionCompatibilityEx_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['vm', 'ManagedObjectReference'],
      ['host', 'ManagedObjectReference'],
    ];
    return $self->soap_call('QueryVMotionCompatibilityEx_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub QueryVirtualDiskFragmentation {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['name', undef],
      ['datacenter', 'ManagedObjectReference'],
    ];
    return $self->soap_call('QueryVirtualDiskFragmentation', undef, 0, $x_args, \%args);
}

sub QueryVirtualDiskGeometry {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['name', undef],
      ['datacenter', 'ManagedObjectReference'],
    ];
    return $self->soap_call('QueryVirtualDiskGeometry', 'HostDiskDimensionsChs', 0, $x_args, \%args);
}

sub QueryVirtualDiskUuid {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['name', undef],
      ['datacenter', 'ManagedObjectReference'],
    ];
    return $self->soap_call('QueryVirtualDiskUuid', undef, 0, $x_args, \%args);
}

sub QueryVmfsConfigOption {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('QueryVmfsConfigOption', 'VmfsConfigOption', 1, $x_args, \%args);
}

sub QueryVmfsDatastoreCreateOptions {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['devicePath', undef],
      ['vmfsMajorVersion', undef],
    ];
    return $self->soap_call('QueryVmfsDatastoreCreateOptions', 'VmfsDatastoreOption', 1, $x_args, \%args);
}

sub QueryVmfsDatastoreExpandOptions {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['datastore', 'ManagedObjectReference'],
    ];
    return $self->soap_call('QueryVmfsDatastoreExpandOptions', 'VmfsDatastoreOption', 1, $x_args, \%args);
}

sub QueryVmfsDatastoreExtendOptions {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['datastore', 'ManagedObjectReference'],
      ['devicePath', undef],
      ['suppressExpandCandidates', 'boolean'],
    ];
    return $self->soap_call('QueryVmfsDatastoreExtendOptions', 'VmfsDatastoreOption', 1, $x_args, \%args);
}

sub QueryVnicStatus {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['vnicDevice', undef],
    ];
    return $self->soap_call('QueryVnicStatus', 'IscsiStatus', 0, $x_args, \%args);
}

sub QueryVsanObjectUuidsByFilter {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['uuids', undef],
      ['limit', undef],
      ['version', undef],
    ];
    return $self->soap_call('QueryVsanObjectUuidsByFilter', undef, 1, $x_args, \%args);
}

sub QueryVsanObjects {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['uuids', undef],
    ];
    return $self->soap_call('QueryVsanObjects', undef, 0, $x_args, \%args);
}

sub QueryVsanStatistics {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['labels', undef],
    ];
    return $self->soap_call('QueryVsanStatistics', undef, 0, $x_args, \%args);
}

sub QueryVsanUpgradeStatus {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['cluster', 'ManagedObjectReference'],
    ];
    return $self->soap_call('QueryVsanUpgradeStatus', 'VsanUpgradeSystemUpgradeStatus', 0, $x_args, \%args);
}

sub ReadEnvironmentVariableInGuest {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['vm', 'ManagedObjectReference'],
      ['auth', 'GuestAuthentication'],
      ['names', undef],
    ];
    return $self->soap_call('ReadEnvironmentVariableInGuest', undef, 1, $x_args, \%args);
}

sub ReadNextEvents {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['maxCount', undef],
    ];
    return $self->soap_call('ReadNextEvents', 'Event', 1, $x_args, \%args);
}

sub ReadNextTasks {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['maxCount', undef],
    ];
    return $self->soap_call('ReadNextTasks', 'TaskInfo', 1, $x_args, \%args);
}

sub ReadPreviousEvents {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['maxCount', undef],
    ];
    return $self->soap_call('ReadPreviousEvents', 'Event', 1, $x_args, \%args);
}

sub ReadPreviousTasks {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['maxCount', undef],
    ];
    return $self->soap_call('ReadPreviousTasks', 'TaskInfo', 1, $x_args, \%args);
}

sub RebootGuest {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('RebootGuest', undef, 0, $x_args, \%args);
}

sub RebootHost_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['force', 'boolean'],
    ];
    return $self->soap_call('RebootHost_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub RecommendDatastores {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['storageSpec', 'StoragePlacementSpec'],
    ];
    return $self->soap_call('RecommendDatastores', 'StoragePlacementResult', 0, $x_args, \%args);
}

sub RecommendHostsForVm {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['vm', 'ManagedObjectReference'],
      ['pool', 'ManagedObjectReference'],
    ];
    return $self->soap_call('RecommendHostsForVm', 'ClusterHostRecommendation', 1, $x_args, \%args);
}

sub RecommissionVsanNode_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('RecommissionVsanNode_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub ReconcileDatastoreInventory_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['datastore', 'ManagedObjectReference'],
    ];
    return $self->soap_call('ReconcileDatastoreInventory_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub ReconfigVM_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['spec', 'VirtualMachineConfigSpec'],
    ];
    return $self->soap_call('ReconfigVM_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub ReconfigurationSatisfiable {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['pcbs', 'VsanPolicyChangeBatch'],
      ['ignoreSatisfiability', 'boolean'],
    ];
    return $self->soap_call('ReconfigurationSatisfiable', 'VsanPolicySatisfiability', 1, $x_args, \%args);
}

sub ReconfigureAlarm {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['spec', 'AlarmSpec'],
    ];
    return $self->soap_call('ReconfigureAlarm', undef, 0, $x_args, \%args);
}

sub ReconfigureAutostart {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['spec', 'HostAutoStartManagerConfig'],
    ];
    return $self->soap_call('ReconfigureAutostart', undef, 0, $x_args, \%args);
}

sub ReconfigureCluster_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['spec', 'ClusterConfigSpec'],
      ['modify', 'boolean'],
    ];
    return $self->soap_call('ReconfigureCluster_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub ReconfigureComputeResource_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['spec', 'ComputeResourceConfigSpec'],
      ['modify', 'boolean'],
    ];
    return $self->soap_call('ReconfigureComputeResource_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub ReconfigureDVPort_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['port', 'DVPortConfigSpec'],
    ];
    return $self->soap_call('ReconfigureDVPort_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub ReconfigureDVPortgroup_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['spec', 'DVPortgroupConfigSpec'],
    ];
    return $self->soap_call('ReconfigureDVPortgroup_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub ReconfigureDatacenter_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['spec', 'DatacenterConfigSpec'],
      ['modify', 'boolean'],
    ];
    return $self->soap_call('ReconfigureDatacenter_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub ReconfigureDomObject {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['uuid', undef],
      ['policy', undef],
    ];
    return $self->soap_call('ReconfigureDomObject', undef, 0, $x_args, \%args);
}

sub ReconfigureDvs_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['spec', 'DVSConfigSpec'],
    ];
    return $self->soap_call('ReconfigureDvs_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub ReconfigureHostForDAS_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('ReconfigureHostForDAS_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub ReconfigureScheduledTask {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['spec', 'ScheduledTaskSpec'],
    ];
    return $self->soap_call('ReconfigureScheduledTask', undef, 0, $x_args, \%args);
}

sub ReconfigureServiceConsoleReservation {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['cfgBytes', undef],
    ];
    return $self->soap_call('ReconfigureServiceConsoleReservation', undef, 0, $x_args, \%args);
}

sub ReconfigureSnmpAgent {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['spec', 'HostSnmpConfigSpec'],
    ];
    return $self->soap_call('ReconfigureSnmpAgent', undef, 0, $x_args, \%args);
}

sub ReconfigureVirtualMachineReservation {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['spec', 'VirtualMachineMemoryReservationSpec'],
    ];
    return $self->soap_call('ReconfigureVirtualMachineReservation', undef, 0, $x_args, \%args);
}

sub ReconnectHost_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['cnxSpec', 'HostConnectSpec'],
      ['reconnectSpec', 'HostSystemReconnectSpec'],
    ];
    return $self->soap_call('ReconnectHost_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub RectifyDvsHost_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['hosts', 'ManagedObjectReference'],
    ];
    return $self->soap_call('RectifyDvsHost_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub RectifyDvsOnHost_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['hosts', 'ManagedObjectReference'],
    ];
    return $self->soap_call('RectifyDvsOnHost_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub Refresh {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('Refresh', undef, 0, $x_args, \%args);
}

sub RefreshDVPortState {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['portKeys', undef],
    ];
    return $self->soap_call('RefreshDVPortState', undef, 0, $x_args, \%args);
}

sub RefreshDatastore {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('RefreshDatastore', undef, 0, $x_args, \%args);
}

sub RefreshDatastoreStorageInfo {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('RefreshDatastoreStorageInfo', undef, 0, $x_args, \%args);
}

sub RefreshDateTimeSystem {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('RefreshDateTimeSystem', undef, 0, $x_args, \%args);
}

sub RefreshFirewall {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('RefreshFirewall', undef, 0, $x_args, \%args);
}

sub RefreshGraphicsManager {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('RefreshGraphicsManager', undef, 0, $x_args, \%args);
}

sub RefreshHealthStatusSystem {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('RefreshHealthStatusSystem', undef, 0, $x_args, \%args);
}

sub RefreshNetworkSystem {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('RefreshNetworkSystem', undef, 0, $x_args, \%args);
}

sub RefreshRecommendation {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('RefreshRecommendation', undef, 0, $x_args, \%args);
}

sub RefreshRuntime {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('RefreshRuntime', undef, 0, $x_args, \%args);
}

sub RefreshServices {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('RefreshServices', undef, 0, $x_args, \%args);
}

sub RefreshStorageDrsRecommendation {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['pod', 'ManagedObjectReference'],
    ];
    return $self->soap_call('RefreshStorageDrsRecommendation', undef, 0, $x_args, \%args);
}

sub RefreshStorageInfo {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('RefreshStorageInfo', undef, 0, $x_args, \%args);
}

sub RefreshStorageSystem {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('RefreshStorageSystem', undef, 0, $x_args, \%args);
}

sub RegisterChildVM_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['path', undef],
      ['name', undef],
      ['host', 'ManagedObjectReference'],
    ];
    return $self->soap_call('RegisterChildVM_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub RegisterDisk {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['path', undef],
      ['name', undef],
    ];
    return $self->soap_call('RegisterDisk', 'VStorageObject', 0, $x_args, \%args);
}

sub RegisterExtension {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['extension', 'Extension'],
    ];
    return $self->soap_call('RegisterExtension', undef, 0, $x_args, \%args);
}

sub RegisterHealthUpdateProvider {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['name', undef],
      ['healthUpdateInfo', 'HealthUpdateInfo'],
    ];
    return $self->soap_call('RegisterHealthUpdateProvider', undef, 0, $x_args, \%args);
}

sub RegisterKmipServer {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['server', 'KmipServerSpec'],
    ];
    return $self->soap_call('RegisterKmipServer', undef, 0, $x_args, \%args);
}

sub RegisterVM_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['path', undef],
      ['name', undef],
      ['asTemplate', 'boolean'],
      ['pool', 'ManagedObjectReference'],
      ['host', 'ManagedObjectReference'],
    ];
    return $self->soap_call('RegisterVM_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub ReleaseCredentialsInGuest {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['vm', 'ManagedObjectReference'],
      ['auth', 'GuestAuthentication'],
    ];
    return $self->soap_call('ReleaseCredentialsInGuest', undef, 0, $x_args, \%args);
}

sub ReleaseIpAllocation {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['dc', 'ManagedObjectReference'],
      ['poolId', undef],
      ['allocationId', undef],
    ];
    return $self->soap_call('ReleaseIpAllocation', undef, 0, $x_args, \%args);
}

sub ReleaseManagedSnapshot {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['vdisk', undef],
      ['datacenter', 'ManagedObjectReference'],
    ];
    return $self->soap_call('ReleaseManagedSnapshot', undef, 0, $x_args, \%args);
}

sub Reload {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('Reload', undef, 0, $x_args, \%args);
}

sub RelocateVM_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['spec', 'VirtualMachineRelocateSpec'],
      ['priority', 'VirtualMachineMovePriority'],
    ];
    return $self->soap_call('RelocateVM_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub RelocateVStorageObject_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['id', 'ID'],
      ['datastore', 'ManagedObjectReference'],
      ['spec', 'VslmRelocateSpec'],
    ];
    return $self->soap_call('RelocateVStorageObject_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub RemoveAlarm {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('RemoveAlarm', undef, 0, $x_args, \%args);
}

sub RemoveAllSnapshots_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['consolidate', 'boolean'],
    ];
    return $self->soap_call('RemoveAllSnapshots_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub RemoveAssignedLicense {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['entityId', undef],
    ];
    return $self->soap_call('RemoveAssignedLicense', undef, 0, $x_args, \%args);
}

sub RemoveAuthorizationRole {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['roleId', undef],
      ['failIfUsed', 'boolean'],
    ];
    return $self->soap_call('RemoveAuthorizationRole', undef, 0, $x_args, \%args);
}

sub RemoveCustomFieldDef {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['key', undef],
    ];
    return $self->soap_call('RemoveCustomFieldDef', undef, 0, $x_args, \%args);
}

sub RemoveDatastore {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['datastore', 'ManagedObjectReference'],
    ];
    return $self->soap_call('RemoveDatastore', undef, 0, $x_args, \%args);
}

sub RemoveDatastoreEx_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['datastore', 'ManagedObjectReference'],
    ];
    return $self->soap_call('RemoveDatastoreEx_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub RemoveDiskMapping_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['mapping', 'VsanHostDiskMapping'],
      ['maintenanceSpec', 'HostMaintenanceSpec'],
      ['timeout', undef],
    ];
    return $self->soap_call('RemoveDiskMapping_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub RemoveDisk_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['disk', 'HostScsiDisk'],
      ['maintenanceSpec', 'HostMaintenanceSpec'],
      ['timeout', undef],
    ];
    return $self->soap_call('RemoveDisk_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub RemoveEntityPermission {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['entity', 'ManagedObjectReference'],
      ['user', undef],
      ['isGroup', 'boolean'],
    ];
    return $self->soap_call('RemoveEntityPermission', undef, 0, $x_args, \%args);
}

sub RemoveFilter {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['filterId', undef],
    ];
    return $self->soap_call('RemoveFilter', undef, 0, $x_args, \%args);
}

sub RemoveFilterEntities {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['filterId', undef],
      ['entities', 'ManagedObjectReference'],
    ];
    return $self->soap_call('RemoveFilterEntities', undef, 0, $x_args, \%args);
}

sub RemoveGroup {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['groupName', undef],
    ];
    return $self->soap_call('RemoveGroup', undef, 0, $x_args, \%args);
}

sub RemoveGuestAlias {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['vm', 'ManagedObjectReference'],
      ['auth', 'GuestAuthentication'],
      ['username', undef],
      ['base64Cert', undef],
      ['subject', 'GuestAuthSubject'],
    ];
    return $self->soap_call('RemoveGuestAlias', undef, 0, $x_args, \%args);
}

sub RemoveGuestAliasByCert {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['vm', 'ManagedObjectReference'],
      ['auth', 'GuestAuthentication'],
      ['username', undef],
      ['base64Cert', undef],
    ];
    return $self->soap_call('RemoveGuestAliasByCert', undef, 0, $x_args, \%args);
}

sub RemoveInternetScsiSendTargets {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['iScsiHbaDevice', undef],
      ['targets', 'HostInternetScsiHbaSendTarget'],
    ];
    return $self->soap_call('RemoveInternetScsiSendTargets', undef, 0, $x_args, \%args);
}

sub RemoveInternetScsiStaticTargets {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['iScsiHbaDevice', undef],
      ['targets', 'HostInternetScsiHbaStaticTarget'],
    ];
    return $self->soap_call('RemoveInternetScsiStaticTargets', undef, 0, $x_args, \%args);
}

sub RemoveKey {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['key', 'CryptoKeyId'],
      ['force', 'boolean'],
    ];
    return $self->soap_call('RemoveKey', undef, 0, $x_args, \%args);
}

sub RemoveKeys {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['keys', 'CryptoKeyId'],
      ['force', 'boolean'],
    ];
    return $self->soap_call('RemoveKeys', 'CryptoKeyResult', 1, $x_args, \%args);
}

sub RemoveKmipServer {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['clusterId', 'KeyProviderId'],
      ['serverName', undef],
    ];
    return $self->soap_call('RemoveKmipServer', undef, 0, $x_args, \%args);
}

sub RemoveLicense {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['licenseKey', undef],
    ];
    return $self->soap_call('RemoveLicense', undef, 0, $x_args, \%args);
}

sub RemoveLicenseLabel {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['licenseKey', undef],
      ['labelKey', undef],
    ];
    return $self->soap_call('RemoveLicenseLabel', undef, 0, $x_args, \%args);
}

sub RemoveMonitoredEntities {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['providerId', undef],
      ['entities', 'ManagedObjectReference'],
    ];
    return $self->soap_call('RemoveMonitoredEntities', undef, 0, $x_args, \%args);
}

sub RemoveNetworkResourcePool {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['key', undef],
    ];
    return $self->soap_call('RemoveNetworkResourcePool', undef, 0, $x_args, \%args);
}

sub RemovePerfInterval {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['samplePeriod', undef],
    ];
    return $self->soap_call('RemovePerfInterval', undef, 0, $x_args, \%args);
}

sub RemovePortGroup {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['pgName', undef],
    ];
    return $self->soap_call('RemovePortGroup', undef, 0, $x_args, \%args);
}

sub RemoveScheduledTask {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('RemoveScheduledTask', undef, 0, $x_args, \%args);
}

sub RemoveServiceConsoleVirtualNic {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['device', undef],
    ];
    return $self->soap_call('RemoveServiceConsoleVirtualNic', undef, 0, $x_args, \%args);
}

sub RemoveSmartCardTrustAnchor {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['issuer', undef],
      ['serial', undef],
    ];
    return $self->soap_call('RemoveSmartCardTrustAnchor', undef, 0, $x_args, \%args);
}

sub RemoveSmartCardTrustAnchorByFingerprint {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['fingerprint', undef],
      ['digest', undef],
    ];
    return $self->soap_call('RemoveSmartCardTrustAnchorByFingerprint', undef, 0, $x_args, \%args);
}

sub RemoveSnapshot_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['removeChildren', 'boolean'],
      ['consolidate', 'boolean'],
    ];
    return $self->soap_call('RemoveSnapshot_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub RemoveUser {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['userName', undef],
    ];
    return $self->soap_call('RemoveUser', undef, 0, $x_args, \%args);
}

sub RemoveVirtualNic {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['device', undef],
    ];
    return $self->soap_call('RemoveVirtualNic', undef, 0, $x_args, \%args);
}

sub RemoveVirtualSwitch {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['vswitchName', undef],
    ];
    return $self->soap_call('RemoveVirtualSwitch', undef, 0, $x_args, \%args);
}

sub RenameCustomFieldDef {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['key', undef],
      ['name', undef],
    ];
    return $self->soap_call('RenameCustomFieldDef', undef, 0, $x_args, \%args);
}

sub RenameCustomizationSpec {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['name', undef],
      ['newName', undef],
    ];
    return $self->soap_call('RenameCustomizationSpec', undef, 0, $x_args, \%args);
}

sub RenameDatastore {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['newName', undef],
    ];
    return $self->soap_call('RenameDatastore', undef, 0, $x_args, \%args);
}

sub RenameSnapshot {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['name', undef],
      ['description', undef],
    ];
    return $self->soap_call('RenameSnapshot', undef, 0, $x_args, \%args);
}

sub RenameVStorageObject {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['id', 'ID'],
      ['datastore', 'ManagedObjectReference'],
      ['name', undef],
    ];
    return $self->soap_call('RenameVStorageObject', undef, 0, $x_args, \%args);
}

sub Rename_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['newName', undef],
    ];
    return $self->soap_call('Rename_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub ReplaceCACertificatesAndCRLs {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['caCert', undef],
      ['caCrl', undef],
    ];
    return $self->soap_call('ReplaceCACertificatesAndCRLs', undef, 0, $x_args, \%args);
}

sub ReplaceSmartCardTrustAnchors {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['certs', undef],
    ];
    return $self->soap_call('ReplaceSmartCardTrustAnchors', undef, 0, $x_args, \%args);
}

sub RescanAllHba {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('RescanAllHba', undef, 0, $x_args, \%args);
}

sub RescanHba {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['hbaDevice', undef],
    ];
    return $self->soap_call('RescanHba', undef, 0, $x_args, \%args);
}

sub RescanVffs {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('RescanVffs', undef, 0, $x_args, \%args);
}

sub RescanVmfs {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('RescanVmfs', undef, 0, $x_args, \%args);
}

sub ResetCollector {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('ResetCollector', undef, 0, $x_args, \%args);
}

sub ResetCounterLevelMapping {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['counters', undef],
    ];
    return $self->soap_call('ResetCounterLevelMapping', undef, 0, $x_args, \%args);
}

sub ResetEntityPermissions {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['entity', 'ManagedObjectReference'],
      ['permission', 'Permission'],
    ];
    return $self->soap_call('ResetEntityPermissions', undef, 0, $x_args, \%args);
}

sub ResetFirmwareToFactoryDefaults {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('ResetFirmwareToFactoryDefaults', undef, 0, $x_args, \%args);
}

sub ResetGuestInformation {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('ResetGuestInformation', undef, 0, $x_args, \%args);
}

sub ResetListView {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['obj', 'ManagedObjectReference'],
    ];
    return $self->soap_call('ResetListView', 'ManagedObjectReference', 1, $x_args, \%args);
}

sub ResetListViewFromView {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['view', 'ManagedObjectReference'],
    ];
    return $self->soap_call('ResetListViewFromView', undef, 0, $x_args, \%args);
}

sub ResetSystemHealthInfo {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('ResetSystemHealthInfo', undef, 0, $x_args, \%args);
}

sub ResetVM_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('ResetVM_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub ResignatureUnresolvedVmfsVolume_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['resolutionSpec', 'HostUnresolvedVmfsResignatureSpec'],
    ];
    return $self->soap_call('ResignatureUnresolvedVmfsVolume_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub ResolveInstallationErrorsOnCluster_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['filterId', undef],
      ['cluster', 'ManagedObjectReference'],
    ];
    return $self->soap_call('ResolveInstallationErrorsOnCluster_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub ResolveInstallationErrorsOnHost_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['filterId', undef],
      ['host', 'ManagedObjectReference'],
    ];
    return $self->soap_call('ResolveInstallationErrorsOnHost_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub ResolveMultipleUnresolvedVmfsVolumes {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['resolutionSpec', 'HostUnresolvedVmfsResolutionSpec'],
    ];
    return $self->soap_call('ResolveMultipleUnresolvedVmfsVolumes', 'HostUnresolvedVmfsResolutionResult', 1, $x_args, \%args);
}

sub ResolveMultipleUnresolvedVmfsVolumesEx_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['resolutionSpec', 'HostUnresolvedVmfsResolutionSpec'],
    ];
    return $self->soap_call('ResolveMultipleUnresolvedVmfsVolumesEx_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub RestartService {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['id', undef],
    ];
    return $self->soap_call('RestartService', undef, 0, $x_args, \%args);
}

sub RestartServiceConsoleVirtualNic {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['device', undef],
    ];
    return $self->soap_call('RestartServiceConsoleVirtualNic', undef, 0, $x_args, \%args);
}

sub RestoreFirmwareConfiguration {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['force', 'boolean'],
    ];
    return $self->soap_call('RestoreFirmwareConfiguration', undef, 0, $x_args, \%args);
}

sub RetrieveAllPermissions {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('RetrieveAllPermissions', 'Permission', 1, $x_args, \%args);
}

sub RetrieveAnswerFile {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['host', 'ManagedObjectReference'],
    ];
    return $self->soap_call('RetrieveAnswerFile', 'AnswerFile', 0, $x_args, \%args);
}

sub RetrieveAnswerFileForProfile {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['host', 'ManagedObjectReference'],
      ['applyProfile', 'HostApplyProfile'],
    ];
    return $self->soap_call('RetrieveAnswerFileForProfile', 'AnswerFile', 0, $x_args, \%args);
}

sub RetrieveArgumentDescription {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['eventTypeId', undef],
    ];
    return $self->soap_call('RetrieveArgumentDescription', 'EventArgDesc', 1, $x_args, \%args);
}

sub RetrieveClientCert {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['cluster', 'KeyProviderId'],
    ];
    return $self->soap_call('RetrieveClientCert', undef, 0, $x_args, \%args);
}

sub RetrieveClientCsr {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['cluster', 'KeyProviderId'],
    ];
    return $self->soap_call('RetrieveClientCsr', undef, 0, $x_args, \%args);
}

sub RetrieveDasAdvancedRuntimeInfo {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('RetrieveDasAdvancedRuntimeInfo', 'ClusterDasAdvancedRuntimeInfo', 0, $x_args, \%args);
}

sub RetrieveDescription {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('RetrieveDescription', 'ProfileDescription', 0, $x_args, \%args);
}

sub RetrieveDiskPartitionInfo {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['devicePath', undef],
    ];
    return $self->soap_call('RetrieveDiskPartitionInfo', 'HostDiskPartitionInfo', 1, $x_args, \%args);
}

sub RetrieveEntityPermissions {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['entity', 'ManagedObjectReference'],
      ['inherited', 'boolean'],
    ];
    return $self->soap_call('RetrieveEntityPermissions', 'Permission', 1, $x_args, \%args);
}

sub RetrieveEntityScheduledTask {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['entity', 'ManagedObjectReference'],
    ];
    return $self->soap_call('RetrieveEntityScheduledTask', 'ManagedObjectReference', 1, $x_args, \%args);
}

sub RetrieveHardwareUptime {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('RetrieveHardwareUptime', undef, 0, $x_args, \%args);
}

sub RetrieveHostAccessControlEntries {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('RetrieveHostAccessControlEntries', 'HostAccessControlEntry', 1, $x_args, \%args);
}

sub RetrieveHostCustomizations {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['hosts', 'ManagedObjectReference'],
    ];
    return $self->soap_call('RetrieveHostCustomizations', 'StructuredCustomizations', 1, $x_args, \%args);
}

sub RetrieveHostCustomizationsForProfile {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['hosts', 'ManagedObjectReference'],
      ['applyProfile', 'HostApplyProfile'],
    ];
    return $self->soap_call('RetrieveHostCustomizationsForProfile', 'StructuredCustomizations', 1, $x_args, \%args);
}

sub RetrieveHostSpecification {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['host', 'ManagedObjectReference'],
      ['fromHost', 'boolean'],
    ];
    return $self->soap_call('RetrieveHostSpecification', 'HostSpecification', 0, $x_args, \%args);
}

sub RetrieveKmipServerCert {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['keyProvider', 'KeyProviderId'],
      ['server', 'KmipServerInfo'],
    ];
    return $self->soap_call('RetrieveKmipServerCert', 'CryptoManagerKmipServerCertInfo', 0, $x_args, \%args);
}

sub RetrieveKmipServersStatus_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['clusters', 'KmipClusterInfo'],
    ];
    return $self->soap_call('RetrieveKmipServersStatus_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub RetrieveObjectScheduledTask {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['obj', 'ManagedObjectReference'],
    ];
    return $self->soap_call('RetrieveObjectScheduledTask', 'ManagedObjectReference', 1, $x_args, \%args);
}

sub RetrieveProductComponents {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('RetrieveProductComponents', 'ProductComponentInfo', 1, $x_args, \%args);
}

sub RetrieveProperties {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['specSet', 'PropertyFilterSpec'],
    ];
    return $self->soap_call('RetrieveProperties', 'ObjectContent', 1, $x_args, \%args);
}

sub RetrievePropertiesEx {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['specSet', 'PropertyFilterSpec'],
      ['options', 'RetrieveOptions'],
    ];
    return $self->soap_call('RetrievePropertiesEx', 'RetrieveResult', 0, $x_args, \%args);
}

sub RetrieveRolePermissions {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['roleId', undef],
    ];
    return $self->soap_call('RetrieveRolePermissions', 'Permission', 1, $x_args, \%args);
}

sub RetrieveSelfSignedClientCert {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['cluster', 'KeyProviderId'],
    ];
    return $self->soap_call('RetrieveSelfSignedClientCert', undef, 0, $x_args, \%args);
}

sub RetrieveServiceContent {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('RetrieveServiceContent', 'ServiceContent', 0, $x_args, \%args);
}

sub RetrieveUserGroups {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['domain', undef],
      ['searchStr', undef],
      ['belongsToGroup', undef],
      ['belongsToUser', undef],
      ['exactMatch', 'boolean'],
      ['findUsers', 'boolean'],
      ['findGroups', 'boolean'],
    ];
    return $self->soap_call('RetrieveUserGroups', 'UserSearchResult', 1, $x_args, \%args);
}

sub RetrieveVStorageObject {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['id', 'ID'],
      ['datastore', 'ManagedObjectReference'],
    ];
    return $self->soap_call('RetrieveVStorageObject', 'VStorageObject', 0, $x_args, \%args);
}

sub RetrieveVStorageObjectState {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['id', 'ID'],
      ['datastore', 'ManagedObjectReference'],
    ];
    return $self->soap_call('RetrieveVStorageObjectState', 'VStorageObjectStateInfo', 0, $x_args, \%args);
}

sub RevertToCurrentSnapshot_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['host', 'ManagedObjectReference'],
      ['suppressPowerOn', 'boolean'],
    ];
    return $self->soap_call('RevertToCurrentSnapshot_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub RevertToSnapshot_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['host', 'ManagedObjectReference'],
      ['suppressPowerOn', 'boolean'],
    ];
    return $self->soap_call('RevertToSnapshot_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub RewindCollector {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('RewindCollector', undef, 0, $x_args, \%args);
}

sub RunScheduledTask {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('RunScheduledTask', undef, 0, $x_args, \%args);
}

sub RunVsanPhysicalDiskDiagnostics {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['disks', undef],
    ];
    return $self->soap_call('RunVsanPhysicalDiskDiagnostics', 'HostVsanInternalSystemVsanPhysicalDiskDiagnosticsResult', 1, $x_args, \%args);
}

sub ScanHostPatchV2_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['metaUrls', undef],
      ['bundleUrls', undef],
      ['spec', 'HostPatchManagerPatchManagerOperationSpec'],
    ];
    return $self->soap_call('ScanHostPatchV2_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub ScanHostPatch_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['repository', 'HostPatchManagerLocator'],
      ['updateID', undef],
    ];
    return $self->soap_call('ScanHostPatch_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub ScheduleReconcileDatastoreInventory {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['datastore', 'ManagedObjectReference'],
    ];
    return $self->soap_call('ScheduleReconcileDatastoreInventory', undef, 0, $x_args, \%args);
}

sub SearchDatastoreSubFolders_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['datastorePath', undef],
      ['searchSpec', 'HostDatastoreBrowserSearchSpec'],
    ];
    return $self->soap_call('SearchDatastoreSubFolders_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub SearchDatastore_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['datastorePath', undef],
      ['searchSpec', 'HostDatastoreBrowserSearchSpec'],
    ];
    return $self->soap_call('SearchDatastore_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub SelectActivePartition {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['partition', 'HostScsiDiskPartition'],
    ];
    return $self->soap_call('SelectActivePartition', undef, 0, $x_args, \%args);
}

sub SelectVnic {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['device', undef],
    ];
    return $self->soap_call('SelectVnic', undef, 0, $x_args, \%args);
}

sub SelectVnicForNicType {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['nicType', undef],
      ['device', undef],
    ];
    return $self->soap_call('SelectVnicForNicType', undef, 0, $x_args, \%args);
}

sub SendNMI {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('SendNMI', undef, 0, $x_args, \%args);
}

sub SendTestNotification {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('SendTestNotification', undef, 0, $x_args, \%args);
}

sub SessionIsActive {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['sessionID', undef],
      ['userName', undef],
    ];
    return $self->soap_call('SessionIsActive', 'boolean', 0, $x_args, \%args);
}

sub SetCollectorPageSize {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['maxCount', undef],
    ];
    return $self->soap_call('SetCollectorPageSize', undef, 0, $x_args, \%args);
}

sub SetDisplayTopology {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['displays', 'VirtualMachineDisplayTopology'],
    ];
    return $self->soap_call('SetDisplayTopology', undef, 0, $x_args, \%args);
}

sub SetEntityPermissions {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['entity', 'ManagedObjectReference'],
      ['permission', 'Permission'],
    ];
    return $self->soap_call('SetEntityPermissions', undef, 0, $x_args, \%args);
}

sub SetExtensionCertificate {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['extensionKey', undef],
      ['certificatePem', undef],
    ];
    return $self->soap_call('SetExtensionCertificate', undef, 0, $x_args, \%args);
}

sub SetField {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['entity', 'ManagedObjectReference'],
      ['key', undef],
      ['value', undef],
    ];
    return $self->soap_call('SetField', undef, 0, $x_args, \%args);
}

sub SetLicenseEdition {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['host', 'ManagedObjectReference'],
      ['featureKey', undef],
    ];
    return $self->soap_call('SetLicenseEdition', undef, 0, $x_args, \%args);
}

sub SetLocale {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['locale', undef],
    ];
    return $self->soap_call('SetLocale', undef, 0, $x_args, \%args);
}

sub SetMultipathLunPolicy {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['lunId', undef],
      ['policy', 'HostMultipathInfoLogicalUnitPolicy'],
    ];
    return $self->soap_call('SetMultipathLunPolicy', undef, 0, $x_args, \%args);
}

sub SetNFSUser {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['user', undef],
      ['password', undef],
    ];
    return $self->soap_call('SetNFSUser', undef, 0, $x_args, \%args);
}

sub SetPublicKey {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['extensionKey', undef],
      ['publicKey', undef],
    ];
    return $self->soap_call('SetPublicKey', undef, 0, $x_args, \%args);
}

sub SetRegistryValueInGuest {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['vm', 'ManagedObjectReference'],
      ['auth', 'GuestAuthentication'],
      ['value', 'GuestRegValueSpec'],
    ];
    return $self->soap_call('SetRegistryValueInGuest', undef, 0, $x_args, \%args);
}

sub SetScreenResolution {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['width', undef],
      ['height', undef],
    ];
    return $self->soap_call('SetScreenResolution', undef, 0, $x_args, \%args);
}

sub SetTaskDescription {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['description', 'LocalizableMessage'],
    ];
    return $self->soap_call('SetTaskDescription', undef, 0, $x_args, \%args);
}

sub SetTaskState {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['state', 'TaskInfoState'],
      ['result', 'anyType'],
      ['fault', 'LocalizedMethodFault'],
    ];
    return $self->soap_call('SetTaskState', undef, 0, $x_args, \%args);
}

sub SetVirtualDiskUuid {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['name', undef],
      ['datacenter', 'ManagedObjectReference'],
      ['uuid', undef],
    ];
    return $self->soap_call('SetVirtualDiskUuid', undef, 0, $x_args, \%args);
}

sub ShrinkVirtualDisk_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['name', undef],
      ['datacenter', 'ManagedObjectReference'],
      ['copy', 'boolean'],
    ];
    return $self->soap_call('ShrinkVirtualDisk_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub ShutdownGuest {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('ShutdownGuest', undef, 0, $x_args, \%args);
}

sub ShutdownHost_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['force', 'boolean'],
    ];
    return $self->soap_call('ShutdownHost_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub StageHostPatch_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['metaUrls', undef],
      ['bundleUrls', undef],
      ['vibUrls', undef],
      ['spec', 'HostPatchManagerPatchManagerOperationSpec'],
    ];
    return $self->soap_call('StageHostPatch_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub StampAllRulesWithUuid_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('StampAllRulesWithUuid_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub StandbyGuest {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('StandbyGuest', undef, 0, $x_args, \%args);
}

sub StartProgramInGuest {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['vm', 'ManagedObjectReference'],
      ['auth', 'GuestAuthentication'],
      ['spec', 'GuestProgramSpec'],
    ];
    return $self->soap_call('StartProgramInGuest', undef, 0, $x_args, \%args);
}

sub StartRecording_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['name', undef],
      ['description', undef],
    ];
    return $self->soap_call('StartRecording_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub StartReplaying_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['replaySnapshot', 'ManagedObjectReference'],
    ];
    return $self->soap_call('StartReplaying_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub StartService {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['id', undef],
    ];
    return $self->soap_call('StartService', undef, 0, $x_args, \%args);
}

sub StopRecording_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('StopRecording_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub StopReplaying_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('StopReplaying_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub StopService {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['id', undef],
    ];
    return $self->soap_call('StopService', undef, 0, $x_args, \%args);
}

sub SuspendVApp_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('SuspendVApp_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub SuspendVM_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('SuspendVM_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub TerminateFaultTolerantVM_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['vm', 'ManagedObjectReference'],
    ];
    return $self->soap_call('TerminateFaultTolerantVM_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub TerminateProcessInGuest {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['vm', 'ManagedObjectReference'],
      ['auth', 'GuestAuthentication'],
      ['pid', undef],
    ];
    return $self->soap_call('TerminateProcessInGuest', undef, 0, $x_args, \%args);
}

sub TerminateSession {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['sessionId', undef],
    ];
    return $self->soap_call('TerminateSession', undef, 0, $x_args, \%args);
}

sub TerminateVM {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('TerminateVM', undef, 0, $x_args, \%args);
}

sub TurnDiskLocatorLedOff_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['scsiDiskUuids', undef],
    ];
    return $self->soap_call('TurnDiskLocatorLedOff_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub TurnDiskLocatorLedOn_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['scsiDiskUuids', undef],
    ];
    return $self->soap_call('TurnDiskLocatorLedOn_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub TurnOffFaultToleranceForVM_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('TurnOffFaultToleranceForVM_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub UnassignUserFromGroup {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['user', undef],
      ['group', undef],
    ];
    return $self->soap_call('UnassignUserFromGroup', undef, 0, $x_args, \%args);
}

sub UnbindVnic {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['iScsiHbaName', undef],
      ['vnicDevice', undef],
      ['force', 'boolean'],
    ];
    return $self->soap_call('UnbindVnic', undef, 0, $x_args, \%args);
}

sub UninstallHostPatch_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['bulletinIds', undef],
      ['spec', 'HostPatchManagerPatchManagerOperationSpec'],
    ];
    return $self->soap_call('UninstallHostPatch_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub UninstallIoFilter_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['filterId', undef],
      ['compRes', 'ManagedObjectReference'],
    ];
    return $self->soap_call('UninstallIoFilter_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub UninstallService {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['id', undef],
    ];
    return $self->soap_call('UninstallService', undef, 0, $x_args, \%args);
}

sub UnmapVmfsVolumeEx_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['vmfsUuid', undef],
    ];
    return $self->soap_call('UnmapVmfsVolumeEx_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub UnmountDiskMapping_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['mapping', 'VsanHostDiskMapping'],
    ];
    return $self->soap_call('UnmountDiskMapping_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub UnmountForceMountedVmfsVolume {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['vmfsUuid', undef],
    ];
    return $self->soap_call('UnmountForceMountedVmfsVolume', undef, 0, $x_args, \%args);
}

sub UnmountToolsInstaller {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('UnmountToolsInstaller', undef, 0, $x_args, \%args);
}

sub UnmountVffsVolume {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['vffsUuid', undef],
    ];
    return $self->soap_call('UnmountVffsVolume', undef, 0, $x_args, \%args);
}

sub UnmountVmfsVolume {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['vmfsUuid', undef],
    ];
    return $self->soap_call('UnmountVmfsVolume', undef, 0, $x_args, \%args);
}

sub UnmountVmfsVolumeEx_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['vmfsUuid', undef],
    ];
    return $self->soap_call('UnmountVmfsVolumeEx_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub UnregisterAndDestroy_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('UnregisterAndDestroy_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub UnregisterExtension {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['extensionKey', undef],
    ];
    return $self->soap_call('UnregisterExtension', undef, 0, $x_args, \%args);
}

sub UnregisterHealthUpdateProvider {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['providerId', undef],
    ];
    return $self->soap_call('UnregisterHealthUpdateProvider', undef, 0, $x_args, \%args);
}

sub UnregisterVM {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('UnregisterVM', undef, 0, $x_args, \%args);
}

sub UpdateAnswerFile_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['host', 'ManagedObjectReference'],
      ['configSpec', 'AnswerFileCreateSpec'],
    ];
    return $self->soap_call('UpdateAnswerFile_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub UpdateAssignedLicense {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['entity', undef],
      ['licenseKey', undef],
      ['entityDisplayName', undef],
    ];
    return $self->soap_call('UpdateAssignedLicense', 'LicenseManagerLicenseInfo', 0, $x_args, \%args);
}

sub UpdateAuthorizationRole {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['roleId', undef],
      ['newName', undef],
      ['privIds', undef],
    ];
    return $self->soap_call('UpdateAuthorizationRole', undef, 0, $x_args, \%args);
}

sub UpdateBootDevice {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['key', undef],
    ];
    return $self->soap_call('UpdateBootDevice', undef, 0, $x_args, \%args);
}

sub UpdateChildResourceConfiguration {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['spec', 'ResourceConfigSpec'],
    ];
    return $self->soap_call('UpdateChildResourceConfiguration', undef, 0, $x_args, \%args);
}

sub UpdateClusterProfile {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['config', 'ClusterProfileConfigSpec'],
    ];
    return $self->soap_call('UpdateClusterProfile', undef, 0, $x_args, \%args);
}

sub UpdateConfig {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['name', undef],
      ['config', 'ResourceConfigSpec'],
    ];
    return $self->soap_call('UpdateConfig', undef, 0, $x_args, \%args);
}

sub UpdateConsoleIpRouteConfig {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['config', 'HostIpRouteConfig'],
    ];
    return $self->soap_call('UpdateConsoleIpRouteConfig', undef, 0, $x_args, \%args);
}

sub UpdateCounterLevelMapping {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['counterLevelMap', 'PerformanceManagerCounterLevelMapping'],
    ];
    return $self->soap_call('UpdateCounterLevelMapping', undef, 0, $x_args, \%args);
}

sub UpdateDVSHealthCheckConfig_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['healthCheckConfig', 'DVSHealthCheckConfig'],
    ];
    return $self->soap_call('UpdateDVSHealthCheckConfig_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub UpdateDVSLacpGroupConfig_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['lacpGroupSpec', 'VMwareDvsLacpGroupSpec'],
    ];
    return $self->soap_call('UpdateDVSLacpGroupConfig_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub UpdateDateTime {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['dateTime', undef],
    ];
    return $self->soap_call('UpdateDateTime', undef, 0, $x_args, \%args);
}

sub UpdateDateTimeConfig {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['config', 'HostDateTimeConfig'],
    ];
    return $self->soap_call('UpdateDateTimeConfig', undef, 0, $x_args, \%args);
}

sub UpdateDefaultPolicy {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['defaultPolicy', 'HostFirewallDefaultPolicy'],
    ];
    return $self->soap_call('UpdateDefaultPolicy', undef, 0, $x_args, \%args);
}

sub UpdateDiskPartitions {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['devicePath', undef],
      ['spec', 'HostDiskPartitionSpec'],
    ];
    return $self->soap_call('UpdateDiskPartitions', undef, 0, $x_args, \%args);
}

sub UpdateDnsConfig {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['config', 'HostDnsConfig'],
    ];
    return $self->soap_call('UpdateDnsConfig', undef, 0, $x_args, \%args);
}

sub UpdateDvsCapability {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['capability', 'DVSCapability'],
    ];
    return $self->soap_call('UpdateDvsCapability', undef, 0, $x_args, \%args);
}

sub UpdateExtension {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['extension', 'Extension'],
    ];
    return $self->soap_call('UpdateExtension', undef, 0, $x_args, \%args);
}

sub UpdateFlags {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['flagInfo', 'HostFlagInfo'],
    ];
    return $self->soap_call('UpdateFlags', undef, 0, $x_args, \%args);
}

sub UpdateGraphicsConfig {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['config', 'HostGraphicsConfig'],
    ];
    return $self->soap_call('UpdateGraphicsConfig', undef, 0, $x_args, \%args);
}

sub UpdateHostCustomizations_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['hostToConfigSpecMap', 'HostProfileManagerHostToConfigSpecMap'],
    ];
    return $self->soap_call('UpdateHostCustomizations_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub UpdateHostImageAcceptanceLevel {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['newAcceptanceLevel', undef],
    ];
    return $self->soap_call('UpdateHostImageAcceptanceLevel', undef, 0, $x_args, \%args);
}

sub UpdateHostProfile {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['config', 'HostProfileConfigSpec'],
    ];
    return $self->soap_call('UpdateHostProfile', undef, 0, $x_args, \%args);
}

sub UpdateHostSpecification {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['host', 'ManagedObjectReference'],
      ['hostSpec', 'HostSpecification'],
    ];
    return $self->soap_call('UpdateHostSpecification', undef, 0, $x_args, \%args);
}

sub UpdateHostSubSpecification {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['host', 'ManagedObjectReference'],
      ['hostSubSpec', 'HostSubSpecification'],
    ];
    return $self->soap_call('UpdateHostSubSpecification', undef, 0, $x_args, \%args);
}

sub UpdateInternetScsiAdvancedOptions {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['iScsiHbaDevice', undef],
      ['targetSet', 'HostInternetScsiHbaTargetSet'],
      ['options', 'HostInternetScsiHbaParamValue'],
    ];
    return $self->soap_call('UpdateInternetScsiAdvancedOptions', undef, 0, $x_args, \%args);
}

sub UpdateInternetScsiAlias {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['iScsiHbaDevice', undef],
      ['iScsiAlias', undef],
    ];
    return $self->soap_call('UpdateInternetScsiAlias', undef, 0, $x_args, \%args);
}

sub UpdateInternetScsiAuthenticationProperties {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['iScsiHbaDevice', undef],
      ['authenticationProperties', 'HostInternetScsiHbaAuthenticationProperties'],
      ['targetSet', 'HostInternetScsiHbaTargetSet'],
    ];
    return $self->soap_call('UpdateInternetScsiAuthenticationProperties', undef, 0, $x_args, \%args);
}

sub UpdateInternetScsiDigestProperties {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['iScsiHbaDevice', undef],
      ['targetSet', 'HostInternetScsiHbaTargetSet'],
      ['digestProperties', 'HostInternetScsiHbaDigestProperties'],
    ];
    return $self->soap_call('UpdateInternetScsiDigestProperties', undef, 0, $x_args, \%args);
}

sub UpdateInternetScsiDiscoveryProperties {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['iScsiHbaDevice', undef],
      ['discoveryProperties', 'HostInternetScsiHbaDiscoveryProperties'],
    ];
    return $self->soap_call('UpdateInternetScsiDiscoveryProperties', undef, 0, $x_args, \%args);
}

sub UpdateInternetScsiIPProperties {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['iScsiHbaDevice', undef],
      ['ipProperties', 'HostInternetScsiHbaIPProperties'],
    ];
    return $self->soap_call('UpdateInternetScsiIPProperties', undef, 0, $x_args, \%args);
}

sub UpdateInternetScsiName {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['iScsiHbaDevice', undef],
      ['iScsiName', undef],
    ];
    return $self->soap_call('UpdateInternetScsiName', undef, 0, $x_args, \%args);
}

sub UpdateIpConfig {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['ipConfig', 'HostIpConfig'],
    ];
    return $self->soap_call('UpdateIpConfig', undef, 0, $x_args, \%args);
}

sub UpdateIpPool {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['dc', 'ManagedObjectReference'],
      ['pool', 'IpPool'],
    ];
    return $self->soap_call('UpdateIpPool', undef, 0, $x_args, \%args);
}

sub UpdateIpRouteConfig {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['config', 'HostIpRouteConfig'],
    ];
    return $self->soap_call('UpdateIpRouteConfig', undef, 0, $x_args, \%args);
}

sub UpdateIpRouteTableConfig {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['config', 'HostIpRouteTableConfig'],
    ];
    return $self->soap_call('UpdateIpRouteTableConfig', undef, 0, $x_args, \%args);
}

sub UpdateIpmi {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['ipmiInfo', 'HostIpmiInfo'],
    ];
    return $self->soap_call('UpdateIpmi', undef, 0, $x_args, \%args);
}

sub UpdateKmipServer {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['server', 'KmipServerSpec'],
    ];
    return $self->soap_call('UpdateKmipServer', undef, 0, $x_args, \%args);
}

sub UpdateKmsSignedCsrClientCert {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['cluster', 'KeyProviderId'],
      ['certificate', undef],
    ];
    return $self->soap_call('UpdateKmsSignedCsrClientCert', undef, 0, $x_args, \%args);
}

sub UpdateLicense {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['licenseKey', undef],
      ['labels', 'KeyValue'],
    ];
    return $self->soap_call('UpdateLicense', 'LicenseManagerLicenseInfo', 0, $x_args, \%args);
}

sub UpdateLicenseLabel {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['licenseKey', undef],
      ['labelKey', undef],
      ['labelValue', undef],
    ];
    return $self->soap_call('UpdateLicenseLabel', undef, 0, $x_args, \%args);
}

sub UpdateLinkedChildren {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['addChangeSet', 'VirtualAppLinkInfo'],
      ['removeSet', 'ManagedObjectReference'],
    ];
    return $self->soap_call('UpdateLinkedChildren', undef, 0, $x_args, \%args);
}

sub UpdateLocalSwapDatastore {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['datastore', 'ManagedObjectReference'],
    ];
    return $self->soap_call('UpdateLocalSwapDatastore', undef, 0, $x_args, \%args);
}

sub UpdateLockdownExceptions {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['users', undef],
    ];
    return $self->soap_call('UpdateLockdownExceptions', undef, 0, $x_args, \%args);
}

sub UpdateModuleOptionString {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['name', undef],
      ['options', undef],
    ];
    return $self->soap_call('UpdateModuleOptionString', undef, 0, $x_args, \%args);
}

sub UpdateNetworkConfig {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['config', 'HostNetworkConfig'],
      ['changeMode', undef],
    ];
    return $self->soap_call('UpdateNetworkConfig', 'HostNetworkConfigResult', 0, $x_args, \%args);
}

sub UpdateNetworkResourcePool {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['configSpec', 'DVSNetworkResourcePoolConfigSpec'],
    ];
    return $self->soap_call('UpdateNetworkResourcePool', undef, 0, $x_args, \%args);
}

sub UpdateOptions {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['changedValue', 'OptionValue'],
    ];
    return $self->soap_call('UpdateOptions', undef, 0, $x_args, \%args);
}

sub UpdatePassthruConfig {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['config', 'HostPciPassthruConfig'],
    ];
    return $self->soap_call('UpdatePassthruConfig', undef, 0, $x_args, \%args);
}

sub UpdatePerfInterval {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['interval', 'PerfInterval'],
    ];
    return $self->soap_call('UpdatePerfInterval', undef, 0, $x_args, \%args);
}

sub UpdatePhysicalNicLinkSpeed {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['device', undef],
      ['linkSpeed', 'PhysicalNicLinkInfo'],
    ];
    return $self->soap_call('UpdatePhysicalNicLinkSpeed', undef, 0, $x_args, \%args);
}

sub UpdatePortGroup {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['pgName', undef],
      ['portgrp', 'HostPortGroupSpec'],
    ];
    return $self->soap_call('UpdatePortGroup', undef, 0, $x_args, \%args);
}

sub UpdateProgress {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['percentDone', undef],
    ];
    return $self->soap_call('UpdateProgress', undef, 0, $x_args, \%args);
}

sub UpdateReferenceHost {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['host', 'ManagedObjectReference'],
    ];
    return $self->soap_call('UpdateReferenceHost', undef, 0, $x_args, \%args);
}

sub UpdateRuleset {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['id', undef],
      ['spec', 'HostFirewallRulesetRulesetSpec'],
    ];
    return $self->soap_call('UpdateRuleset', undef, 0, $x_args, \%args);
}

sub UpdateScsiLunDisplayName {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['lunUuid', undef],
      ['displayName', undef],
    ];
    return $self->soap_call('UpdateScsiLunDisplayName', undef, 0, $x_args, \%args);
}

sub UpdateSelfSignedClientCert {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['cluster', 'KeyProviderId'],
      ['certificate', undef],
    ];
    return $self->soap_call('UpdateSelfSignedClientCert', undef, 0, $x_args, \%args);
}

sub UpdateServiceConsoleVirtualNic {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['device', undef],
      ['nic', 'HostVirtualNicSpec'],
    ];
    return $self->soap_call('UpdateServiceConsoleVirtualNic', undef, 0, $x_args, \%args);
}

sub UpdateServiceMessage {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['message', undef],
    ];
    return $self->soap_call('UpdateServiceMessage', undef, 0, $x_args, \%args);
}

sub UpdateServicePolicy {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['id', undef],
      ['policy', undef],
    ];
    return $self->soap_call('UpdateServicePolicy', undef, 0, $x_args, \%args);
}

sub UpdateSoftwareInternetScsiEnabled {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['enabled', 'boolean'],
    ];
    return $self->soap_call('UpdateSoftwareInternetScsiEnabled', undef, 0, $x_args, \%args);
}

sub UpdateSystemResources {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['resourceInfo', 'HostSystemResourceInfo'],
    ];
    return $self->soap_call('UpdateSystemResources', undef, 0, $x_args, \%args);
}

sub UpdateSystemSwapConfiguration {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['sysSwapConfig', 'HostSystemSwapConfiguration'],
    ];
    return $self->soap_call('UpdateSystemSwapConfiguration', undef, 0, $x_args, \%args);
}

sub UpdateSystemUsers {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['users', undef],
    ];
    return $self->soap_call('UpdateSystemUsers', undef, 0, $x_args, \%args);
}

sub UpdateUser {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['user', 'HostAccountSpec'],
    ];
    return $self->soap_call('UpdateUser', undef, 0, $x_args, \%args);
}

sub UpdateVAppConfig {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['spec', 'VAppConfigSpec'],
    ];
    return $self->soap_call('UpdateVAppConfig', undef, 0, $x_args, \%args);
}

sub UpdateVVolVirtualMachineFiles_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['failoverPair', 'DatastoreVVolContainerFailoverPair'],
    ];
    return $self->soap_call('UpdateVVolVirtualMachineFiles_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub UpdateVirtualMachineFiles_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['mountPathDatastoreMapping', 'DatastoreMountPathDatastorePair'],
    ];
    return $self->soap_call('UpdateVirtualMachineFiles_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub UpdateVirtualNic {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['device', undef],
      ['nic', 'HostVirtualNicSpec'],
    ];
    return $self->soap_call('UpdateVirtualNic', undef, 0, $x_args, \%args);
}

sub UpdateVirtualSwitch {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['vswitchName', undef],
      ['spec', 'HostVirtualSwitchSpec'],
    ];
    return $self->soap_call('UpdateVirtualSwitch', undef, 0, $x_args, \%args);
}

sub UpdateVmfsUnmapPriority {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['vmfsUuid', undef],
      ['unmapPriority', undef],
    ];
    return $self->soap_call('UpdateVmfsUnmapPriority', undef, 0, $x_args, \%args);
}

sub UpdateVsan_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['config', 'VsanHostConfigInfo'],
    ];
    return $self->soap_call('UpdateVsan_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub UpgradeIoFilter_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['filterId', undef],
      ['compRes', 'ManagedObjectReference'],
      ['vibUrl', undef],
    ];
    return $self->soap_call('UpgradeIoFilter_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub UpgradeTools_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['installerOptions', undef],
    ];
    return $self->soap_call('UpgradeTools_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub UpgradeVM_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['version', undef],
    ];
    return $self->soap_call('UpgradeVM_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub UpgradeVmLayout {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('UpgradeVmLayout', undef, 0, $x_args, \%args);
}

sub UpgradeVmfs {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['vmfsPath', undef],
    ];
    return $self->soap_call('UpgradeVmfs', undef, 0, $x_args, \%args);
}

sub UpgradeVsanObjects {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['uuids', undef],
      ['newVersion', undef],
    ];
    return $self->soap_call('UpgradeVsanObjects', 'HostVsanInternalSystemVsanObjectOperationResult', 1, $x_args, \%args);
}

sub UploadClientCert {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['cluster', 'KeyProviderId'],
      ['certificate', undef],
      ['privateKey', undef],
    ];
    return $self->soap_call('UploadClientCert', undef, 0, $x_args, \%args);
}

sub UploadKmipServerCert {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['cluster', 'KeyProviderId'],
      ['certificate', undef],
    ];
    return $self->soap_call('UploadKmipServerCert', undef, 0, $x_args, \%args);
}

sub ValidateCredentialsInGuest {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['vm', 'ManagedObjectReference'],
      ['auth', 'GuestAuthentication'],
    ];
    return $self->soap_call('ValidateCredentialsInGuest', undef, 0, $x_args, \%args);
}

sub ValidateHost {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['ovfDescriptor', undef],
      ['host', 'ManagedObjectReference'],
      ['vhp', 'OvfValidateHostParams'],
    ];
    return $self->soap_call('ValidateHost', 'OvfValidateHostResult', 0, $x_args, \%args);
}

sub ValidateMigration {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['vm', 'ManagedObjectReference'],
      ['state', 'VirtualMachinePowerState'],
      ['testType', undef],
      ['pool', 'ManagedObjectReference'],
      ['host', 'ManagedObjectReference'],
    ];
    return $self->soap_call('ValidateMigration', 'Event', 1, $x_args, \%args);
}

sub WaitForUpdates {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['version', undef],
    ];
    return $self->soap_call('WaitForUpdates', 'UpdateSet', 0, $x_args, \%args);
}

sub WaitForUpdatesEx {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['version', undef],
      ['options', 'WaitOptions'],
    ];
    return $self->soap_call('WaitForUpdatesEx', 'UpdateSet', 0, $x_args, \%args);
}

sub XmlToCustomizationSpecItem {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['specItemXml', undef],
    ];
    return $self->soap_call('XmlToCustomizationSpecItem', 'CustomizationSpecItem', 0, $x_args, \%args);
}

sub ZeroFillVirtualDisk_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['name', undef],
      ['datacenter', 'ManagedObjectReference'],
    ];
    return $self->soap_call('ZeroFillVirtualDisk_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub configureVcha_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['configSpec', 'VchaClusterConfigSpec'],
    ];
    return $self->soap_call('configureVcha_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub createPassiveNode_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['passiveDeploymentSpec', 'PassiveNodeDeploymentSpec'],
      ['sourceVcSpec', 'SourceNodeSpec'],
    ];
    return $self->soap_call('createPassiveNode_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub createWitnessNode_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['witnessDeploymentSpec', 'NodeDeploymentSpec'],
      ['sourceVcSpec', 'SourceNodeSpec'],
    ];
    return $self->soap_call('createWitnessNode_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub deployVcha_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['deploymentSpec', 'VchaClusterDeploymentSpec'],
    ];
    return $self->soap_call('deployVcha_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub destroyVcha_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('destroyVcha_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub fetchSoftwarePackages {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('fetchSoftwarePackages', 'SoftwarePackage', 1, $x_args, \%args);
}

sub getClusterMode {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('getClusterMode', undef, 0, $x_args, \%args);
}

sub getVchaConfig {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('getVchaConfig', 'VchaClusterConfigInfo', 0, $x_args, \%args);
}

sub initiateFailover_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['planned', 'boolean'],
    ];
    return $self->soap_call('initiateFailover_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub installDate {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('installDate', undef, 0, $x_args, \%args);
}

sub prepareVcha_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['networkSpec', 'VchaClusterNetworkSpec'],
    ];
    return $self->soap_call('prepareVcha_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub queryDatacenterConfigOptionDescriptor {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('queryDatacenterConfigOptionDescriptor', 'VirtualMachineConfigOptionDescriptor', 1, $x_args, \%args);
}

sub reloadVirtualMachineFromPath_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['configurationPath', undef],
    ];
    return $self->soap_call('reloadVirtualMachineFromPath_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub setClusterMode_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['mode', undef],
    ];
    return $self->soap_call('setClusterMode_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

sub setCustomValue {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
      ['key', undef],
      ['value', undef],
    ];
    return $self->soap_call('setCustomValue', undef, 0, $x_args, \%args);
}

sub unregisterVApp_Task {
    my ($self, %args) = @_;
    my $x_args = [ 
      ['_this', 'ManagedObjectReference'],
    ];
    return $self->soap_call('unregisterVApp_Task', 'ManagedObjectReference', 0, $x_args, \%args);
}

1;
