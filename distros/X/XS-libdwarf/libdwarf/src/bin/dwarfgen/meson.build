
dwarfgen_src = [
  'createirepformfrombinary.cc',
  'createirepfrombinary.cc',
  'dg_getopt.cc',
  'dwarfgen.cc',
  'irepattrtodbg.cc',
  'ireptodbg.cc'
]

dg_args = []
if (lib_type == 'static')
  dg_args += ['-DLIBDWARF_STATIC']
endif

libdwarfp_dir = include_directories('../../lib/libdwarfp')

executable('dwarfgen', dwarfgen_src,
  cpp_args : [ dev_cppflags, libdwarf_args,dg_args ],
  dependencies : [ libdwarf, libdwarfp ],
  include_directories : [ config_dir, libdwarfp_dir ],
  install : true
)
