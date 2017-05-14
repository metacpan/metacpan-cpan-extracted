use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
  'NAME'  => 'Win32::ASP::DB',
  'VERSION_FROM' => 'Win32/ASP/DB.pm', # finds $VERSION
  'PM' => {
    'Win32/ASP/Action.pm' =>		'$(INST_LIBDIR)/Action.pm',
    'Win32/ASP/DB.pm' =>		'$(INST_LIBDIR)/DB.pm',
    'Win32/ASP/DBRecord.pm' =>		'$(INST_LIBDIR)/DBRecord.pm',
    'Win32/ASP/DBRecordGroup.pm' =>	'$(INST_LIBDIR)/DBRecordGroup.pm',
    'Win32/ASP/Error.pm' =>		'$(INST_LIBDIR)/Error.pm',
    'Win32/ASP/Field.pm' =>		'$(INST_LIBDIR)/Field.pm',
    'Win32/ASP/Field/bit.pm' =>		'$(INST_LIBDIR)/Field/bit.pm',
    'Win32/ASP/Field/boolean.pm' =>	'$(INST_LIBDIR)/Field/boolean.pm',
    'Win32/ASP/Field/datetime.pm' =>	'$(INST_LIBDIR)/Field/datetime.pm',
    'Win32/ASP/Field/dispmeta.pm' =>	'$(INST_LIBDIR)/Field/dispmeta.pm',
    'Win32/ASP/Field/int.pm' =>		'$(INST_LIBDIR)/Field/int.pm',
    'Win32/ASP/Field/text.pm' =>	'$(INST_LIBDIR)/Field/text.pm',
    'Win32/ASP/Field/timestamp.pm' =>	'$(INST_LIBDIR)/Field/timestamp.pm',
    'Win32/ASP/Field/varchar.pm' =>	'$(INST_LIBDIR)/Field/varchar.pm',
    'Win32/ASP/Profile.pm' =>		'$(INST_LIBDIR)/Profile.pm',
  },
);
