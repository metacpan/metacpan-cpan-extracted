#!/usr/bin/python

VERSION = '0.1.9'
APPNAME = 'ux'

top = '.'
out = 'build'

def options(ctx):
  ctx.load('compiler_cxx')
  ctx.load('unittest_gtest')

def configure(ctx):
  ctx.load('compiler_cxx')
  ctx.load('unittest_gtest')	
  ctx.env.CXXFLAGS += ['-O2', '-W', '-Wall', '-g']

def build(bld):
  bld(source = 'ux.pc.in',
      prefix = bld.env['PREFIX'],
      exec_prefix = '${prefix}',
      libdir = '${exec_prefix}/lib',
      includedir = '${prefix}/include',
      PACKAGE = APPNAME,
      VERSION = VERSION)
  bld.install_files('${PREFIX}/lib/pkgconfig', 'ux.pc')
  bld.recurse('src')

def dist_hook():
  import os
  os.remove('upload.sh')
  os.remove('googlecode_upload.py')
