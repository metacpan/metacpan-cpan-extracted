#!/usr/bin/env python3

from setuptools import setup, Extension
from distutils.command.install import install
from distutils.command.build import build
import sysconfig
import os

DEBUG = 0
perl = 'perl'

import os
import sys
import subprocess
MULTI_PERL = os.path.isfile("MULTI_PERL")
BOOT_FROM_PERL = os.path.isfile("BOOT_FROM_PERL")

p = os.popen("perl -MExtUtils::Embed -e 'ccopts();print \"\n\"; ldopts()'")
perl_ccopts = p.readline().strip()
perl_ldopts = p.readline().strip()
p.close()

ext_name     = "perl"
include_dirs = []
macros       = []
cc_extra     = []
cc_extra.append(perl_ccopts)

for x in perl_ccopts.split():
    if x[:2] == '-I':
        include_dirs.append(x[2:])

    # XXX This is disabled since distutils does not yet implement
    # define_macros.  Aarghhh!!  So much time wasted on debugging
    # because of this.
    elif 0 and x[:2] == '-D':
        m = x[2:].split('=', 2)
        if len(m) == 1:
            m.append(None)
        macros.append(tuple(m))
    else:
        cc_extra.append(x)

lib_dirs  = []
libs      = []
ld_extra  = []
o_extra   = []
sym_extra   = []

extra_ext = []

ld_extra.extend(perl_ldopts.split())

# Hack name to get it to compile as C++ file on Windows
svrv_object_c_name = "svrv_object.c"
if sys.platform[:3] == "win":
    import shutil
    svrv_object_c_name = "svrv_object.cpp"
    if os.path.exists(svrv_object_c_name):
        os.chmod(svrv_object_c_name, 777)
        os.unlink(svrv_object_c_name)
    shutil.copy("svrv_object.c", svrv_object_c_name)

sources = ['perlmodule.c',
        'lang_lock.c',
        'lang_map.c',
        svrv_object_c_name,
        'pyo.c',
        'try_perlapi.c',
        ]

if BOOT_FROM_PERL:
    cc_extra.append("-DBOOT_FROM_PERL")
else:
    for x in perl_ldopts.split():
        if x[:2] == '-L':
            lib_dirs.append(x[2:])
        elif x[:2] == '-l' and sys.platform != 'win32':
            libs.append(x[2:])
        elif x[:1] != '-' and (x[-3:] == '.so' or
                x[-2:] == '.o'  or
                x[-2:] == '.a'
                ):
            o_extra.append(x)
        else:
            ld_extra.append(x)

    if not os.path.isfile("perlxsi.c"):
        os.system(perl + " -MExtUtils::Embed -e xsinit")
    sources.append('perlxsi.c');

    # Try to figure out if we use dlopen on this platform
    p = os.popen(perl + ' -V:dlsrc')
    dlsrc = p.readline()
    p.close()
    if dlsrc == "dlsrc='dl_dlopen.xs';\n":
        ext_name = "perl2"
        cc_extra.append('-DDL_HACK')
        cc_extra.append('-DEXT_SUFFIX="' + sysconfig.get_config_vars().get("EXT_SUFFIX", ".so") + '"')
        extra_ext.append(Extension(name = "perl",
            extra_compile_args = cc_extra,
            sources = ["dlhack.c"],
            libraries= ["dl"],
            ))


if MULTI_PERL:
    cc_extra.append("-DMULTI_PERL")
    sources.append('thrd_ctx.c')

if not os.path.isfile("try_perlapi.c") or \
        os.path.getmtime("try_perlapi.c") < os.path.getmtime("try_perlapi.pl"):
            os.system(perl + " try_perlapi.pl")

if sys.argv[1] == "test" or sys.argv[1] == "build" or sys.argv[1] == "install":
    cwd=os.getcwd()
    ldpath = '%s/Python-Object/blib/arch/auto/Python/Object' % cwd
    perllib = '%s/Python-Object/blib/lib' % cwd
    perlarchlib = '%s/Python-Object/blib/arch' % cwd
    os.environ["PERL5LIB"] = "%s:%s" % (perllib,perlarchlib)
    os.environ["LD_LIBRARY_PATH"] = ldpath
    os.environ["PYTHON"] = sys.executable


if sys.platform == 'win32':
    libs.append('perl56')
    for x in ['15','16','20']:
        if os.access(os.path.join(sys.prefix, 'libs', 'python'+x+'.lib'), os.F_OK):
            libs.append('python'+x)
    sym_extra.append('get_thread_ctx')
    sym_extra.append('sv2pyo')
    sym_extra.append('pyo2sv')
    sym_extra.append('newPerlPyObject_noinc')
    sym_extra.append('newPerlPyObject_inc')
    sym_extra.append('PerlPyObject_pyo')
    sym_extra.append('PerlPyObject_pyo_or_null')
    sym_extra.append('vtbl_free_pyo')

if DEBUG:
    print(("Macros:", macros))
    print(("Include: ", include_dirs))
    print(("Extra CC: ", cc_extra))
    print(("Obj: ", o_extra))
    print(("Libs:", libs))
    print(("Lib dirs:",  lib_dirs))
    print(("Extra LD: ", ld_extra))

ext_modules = []
ext_modules.append(Extension(name = ext_name,
    sources = sources,
    define_macros = macros,
    include_dirs = include_dirs,
    extra_compile_args = cc_extra,
    extra_objects =  o_extra,
    libraries = libs,
    library_dirs = lib_dirs,
    extra_link_args = ld_extra,
    export_symbols = sym_extra,
    ))
ext_modules.extend(extra_ext)

class build_perl(build):
    def run(self):
        os.chdir('Python-Object')
        build.spawn(self, ['perl','Makefile.PL', 'INSTALLDIRS=vendor'], 'Python-Object')
        build.spawn(self, ['make'])
        os.chdir('..')
        build.run(self)

class my_install(install):

    def run(self):
        cur_dir = os.getcwd()
        multi_perl = os.path.join(cur_dir, 'MULTI_PERL')
        if os.access(multi_perl, os.F_OK):
            os.unlink(multi_perl)
        if self.root is None:
            self.root = ''

        os.chdir('Python-Object')
        install.spawn(self, ["make", "DESTDIR=%s" % self.root, "install"])
        os.chdir('..')
        if "-DMULTI_PERL" in cc_extra:
            cc_extra.pop(cc_extra.index("-DMULTI_PERL"))
            sources.pop(sources.index('thrd_ctx.c'))
        # Run actual install
        install.run(self)

setup (name        = "pyperl",
        version     = "1.0.1",
        description = "Embed a Perl interpreter",
        url         = "http://www.ActiveState.com",
        author      = "ActiveState",
        author_email= "gisle@ActiveState.com",
        py_modules  = ['dbi', 'dbi2', 'perlpickle', 'perlmod'],
        ext_modules = ext_modules,
        cmdclass    = { 'install': my_install, 'build': build_perl},
        test_suite  = "tests"
        )

# vim:ts=4:sw=4:et
