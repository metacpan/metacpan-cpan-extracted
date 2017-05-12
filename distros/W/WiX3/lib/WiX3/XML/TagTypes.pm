package                                # Hide from PAUSE.
  WiX3::XML::TagTypes;

use 5.008003;
use MooseX::Types -declare => [ qw(
	  ComponentTag ComponentRefTag CreateFolderTag CustomTag CustomActionTag
	  DirectoryTag DirectoryRefTag EnvironmentTag FeatureTag FeatureRefTag
	  FileTag FragmentTag IconTag InstallExecuteSequenceTag MergeTag
	  MergeRefTag PropertyTag RegistryKeyTag RegistryValueTag
	  RemoveFolderTag ShortcutTag WixVariableTag

	  ComponentChildTag DirectoryChildTag DirectoryRefChildTag FeatureChildTag
	  FeatureRefChildTag
	  ) ];

our $VERSION = '0.011';

# Define valid tags.

subtype ComponentTag,    as class_type 'WiX3::XML::Component';
subtype ComponentRefTag, as class_type 'WiX3::XML::ComponentRef';
subtype CreateFolderTag, as class_type 'WiX3::XML::CreateFolder';
subtype CustomTag,       as class_type 'WiX3::XML::Custom';
subtype CustomActionTag, as class_type 'WiX3::XML::CustomAction';
subtype DirectoryTag,    as class_type 'WiX3::XML::Directory';
subtype DirectoryRefTag, as class_type 'WiX3::XML::DirectoryRef';
subtype EnvironmentTag,  as class_type 'WiX3::XML::Environment';
subtype FeatureTag,      as class_type 'WiX3::XML::Feature';
subtype FeatureRefTag,   as class_type 'WiX3::XML::FeatureRef';
subtype FileTag,         as class_type 'WiX3::XML::File';
subtype FragmentTag,     as class_type 'WiX3::XML::Fragment';
subtype IconTag,         as class_type 'WiX3::XML::Icon';
subtype InstallExecuteSequenceTag,
  as class_type 'WiX3::XML::InstallExecuteSequence';
subtype MergeTag,         as class_type 'WiX3::XML::Merge';
subtype MergeRefTag,      as class_type 'WiX3::XML::MergeRef';
subtype PropertyTag,      as class_type 'WiX3::XML::Property';
subtype RegistryKeyTag,   as class_type 'WiX3::XML::RegistryKey';
subtype RegistryValueTag, as class_type 'WiX3::XML::RegistryValue';
subtype RemoveFolderTag,  as class_type 'WiX3::XML::RemoveFolder';
subtype ShortcutTag,      as class_type 'WiX3::XML::Shortcut';
subtype WixVariableTag,   as class_type 'WiX3::XML::WixVariable';

# Define valid child tags.

subtype ComponentChildTag,
  as EnvironmentTag | FileTag | RegistryKeyTag | RegistryValueTag |
  RemoveFolderTag | ShortcutTag | CreateFolderTag;
subtype DirectoryChildTag,    as ComponentTag | DirectoryTag | MergeTag;
subtype DirectoryRefChildTag, as ComponentTag | DirectoryTag | MergeTag;
subtype FeatureChildTag,
  as ComponentTag | ComponentRefTag | FeatureTag | FeatureRefTag |
  MergeRefTag;
subtype FeatureRefChildTag,
  as ComponentTag | ComponentRefTag | FeatureTag | FeatureRefTag |
  MergeRefTag;

1;                                     # Magic true value required at end of module
