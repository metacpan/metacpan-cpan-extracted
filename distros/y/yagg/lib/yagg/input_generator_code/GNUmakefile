PROJECTNAME = generate_dfts

VERSION = 0.20

# Installation prefix
PREFIX = /usr

LIBRARY_NAME = generator

# Any other files you want to distribute when the tarball is created with
# "make dist"
EXTRA_DIST_FILES = CHANGES todo.txt

# The extensions for C++ code, C code, YACC grammars, and LEX scanners
CCFILEEXT = cc
CFILEEXT = c
FFILEEXT = f
YACCFILEEXT = y
LEXFILEEXT = lex
SCRIPTFILEEXT = sh

# Typical flags for GNU compilers:
#  -g, -DDEBUG (debugging information), -pg (profiling), -Wall (all warnings)
#  -O2 (optimization), -Idir (extra include directory)

#CFLAGS		= -Wall -g -DRULE_LIST_DEBUG \
#                  -DTERMINAL_RULE_DEBUG -DNONTERMINAL_RULE_DEBUG -DRULE_DEBUG \
#                  -DSHORT_RULE_TRACE -DACTION_TRACE \
#                  -DDEBUG_FAULT_TREE_CONSTRAINTS \
#                  -DDISABLE_PRODUCTION_LENGTH_OPTIMIZATION \
#                  -DDISABLE_ALLOCATION_CACHING_OPTIMIZATION \
#                  -DDISABLE_GENERATED_STRING_CACHING_OPTIMIZATION \
#                  -DDISABLE_INCREMENT_TO_TOUCHED_VARIABLE_OPTIMIZATION
CFLAGS		= -Wall -pedantic -O3
FFLAGS		= -g -C

# Linker flags. Use -lg2c if you're calling Fortran from C/C++
LDFLAGS		=

# Appear on the end of the link line
LIB_FLAGS :=

# You should really leave this as GNUmakefile since this makefile uses GNU
# extensions
MAKEFILE_NAME := GNUmakefile

# Add additional -d <module name> <source dir> <object dir> <build dir> for
# any libraries that have also been instrumented that you wish to include in
# coverage reporting.
COVERAGE_DIRECTORIES = -d $(PROJECTNAME) $(SRCDIR) $(BUILDDIR) .

# -----------------------------------------------------------------------------

# Programs
LN          = '/usr/local/opt/coreutils/libexec/gnubin/ln'
CP          = '/usr/local/opt/coreutils/libexec/gnubin/cp'
RM          = '/usr/local/opt/coreutils/libexec/gnubin/rm'
MV          = '/usr/local/opt/coreutils/libexec/gnubin/mv'
BASH        = bash
FIND        = '/usr/local/bin/find'
GREP        = '/usr/bin/grep'
CHMOD	    = '/usr/local/opt/coreutils/libexec/gnubin/chmod'
CC          = gcc
CXX         = '/usr/bin/c++'
FC          = g77
LD          = '/usr/bin/c++'
AR          = '/usr/bin/ar'
LEX         = flex
UNIX2DOS    = unix2dos
YACC        = yacc
MKDIR       = '/usr/local/opt/coreutils/libexec/gnubin/mkdir'
TAR         = tar
GZIP        = gzip
ZIP         = zip
DIFF        = diff
MKDIRHIER   = $(PERL) $(UTILSDIR)/mkdirhier.pl
DATE        = '/usr/local/opt/coreutils/libexec/gnubin/date'
PERL        = '/Users/coppit/perl5/perlbrew/perls/perl-5.8.8/bin/perl'
MAKEDEPEND  = $(PERL) $(UTILSDIR)/makedependgcc
COLORS      = $(PERL) $(UTILSDIR)/colors
DIRNAME     = '/usr/local/opt/coreutils/libexec/gnubin/dirname'
EXPR        = '/usr/local/opt/coreutils/libexec/gnubin/expr'

# -----------------------------------------------------------------------------

# Set to "true" to disable colors
DISABLE_COLORS = true

# Color preferences
DEFAULT_FOREGROUND = white
DEFAULT_BACKGROUND = black
MAIN_STEP_FOREGROUND = green
MAIN_STEP_BACKGROUND = black
SUB_STEP_FOREGROUND = cyan
SUB_STEP_BACKGROUND = black
WARNING_FOREGROUND = red
WARNING_BACKGROUND = black
ERROR_FOREGROUND = black
ERROR_BACKGROUND = red

# -----------------------------------------------------------------------------

# Sometimes a compiled test will go into an infinite loop. Set these values to
# limit the amount of time or output that a compiled test can generate before
# it is killed. Use 0 for no limit.

COMPILED_TESTS_TIME_LIMIT = 10
COMPILED_TESTS_BYTE_LIMIT = 0

# -----------------------------------------------------------------------------

# Set to true to store files in another location and create symbolic links to
# the current directory. This is useful for systems with slow NFS performance,
# or systems with limited user disk space. (i.e. we can store things in /tmp
# as specified by the STORAGE_DIRECTORY variable.)
STORE_FILES_ELSEWHERE = false

# NOTE: This directory will be created if necessary. It will NOT be deleted
# during make clean.
STORAGE_DIRECTORY = /tmp/$(USER)/$(PROJECTNAME)

###############################################################################

all : progs compiled_tests noncompiled_tests

# Custom dependencies, if any, go here

############################# END OF CONFIGURATION ############################
###############################################################################

# Directories
SRCDIR = src
TESTDIR = tests
COVERAGEDIR = coverage
PROGDIR = progs
BUILDDIR = build
LIBDIR = lib
ETCDIR = etc
UTILSDIR = util
DOCUMENTDIR = doc

# Add $(BUILDDIR) because there may be generated .h files from yacc.
CFLAGS          := -I$(SRCDIR) -I$(BUILDDIR) -I$(SRCDIR)/model $(CFLAGS)
LDFLAGS         := -L$(LIBDIR) $(LDFLAGS)

# -----------------------------------------------------------------------------

PROGRAMS    = $(CP) $(RM) $(MV) $(FIND) $(GREP) $(CXX) $(LD) $(FC) \
              $(AR) $(LEX) $(UNIX2DOS) $(YACC) $(MKDIR) $(TAR) $(GZIP) \
              $(ZIP) $(DIFF) $(MKDIRHIER) $(DATE) $(PERL) $(MAKEDEPEND) \
              $(CHMOD) $(BASH) $(LN) $(DIRNAME) $(EXPR)

# -----------------------------------------------------------------------------

# We use a simple assignment to prevent re-evaluation of the shell command
# (resulting in different PIDs and random numbers)
TEMPDIR := $(shell $(DATE) +tempdir-%H-%M-%S-$$$$-$$RANDOM)
DISTFILE = $(shell $(DATE) +$(PROJECTNAME)-$(VERSION)-%Y-%m-%d)

# -----------------------------------------------------------------------------

# Libraries
LIB_FLAGS := -l$(LIBRARY_NAME) $(LIB_FLAGS)

EMPTY =
SPACE = $(EMPTY) $(EMPTY)
COMMA = ,
make_pattern = \($(subst $(SPACE),\|,$(1))\)

SRC_FILE_EXTS = \
  $(CFILEEXT) $(CCFILEEXT) $(FFILEEXT) $(LEXFILEEXT) $(YACCFILEEXT)

GENERATED_SRC_FILE_EXTS = $(LEXFILEEXT) $(YACCFILEEXT)

# A couple patterns for easier searching commands
SRC_FILE_EXTS_PATTERN = \
  $(call make_pattern,$(SRC_FILE_EXTS))

GENERATED_SRC_FILE_EXTS_PATTERN = \
  $(call make_pattern,$(GENERATED_SRC_FILE_EXTS))

SRC_DIRS_PATTERN = $(call make_pattern,$(call compute_subdirs_with_sources))

# Some subroutines to find source files and compute their corresponding object
# files
find_source_files = \
  $(shell $(FIND) $(SRCDIR) -regex '$(SRCDIR)/$(1)/.*\.$(SRC_FILE_EXTS_PATTERN)')

find_shell_scripts = \
  $(shell $(FIND) $(SRCDIR) -regex '$(SRCDIR)/$(1)/.*\.$(SCRIPTFILEEXT)')

# In case we need this later
#find_nonsource_files = \
#  $(filter-out \
#    $(shell $(FIND) $(SRCDIR) -regex '$(SRCDIR)/$(1)/.*\.$(SRC_FILE_EXTS_PATTERN)'), \
#    $(shell $(FIND) $(SRCDIR) -regex '$(SRCDIR)/$(1)/.*'))

find_gen_source_files = \
  $(shell $(FIND) $(SRCDIR) -regex '$(SRCDIR)/$(1)/.*\.$(GENERATED_SRC_FILE_EXTS_PATTERN)')

compute_subdirs_with_sources = $(filter-out progs tests progs/% tests/%, \
  $(sort $(subst $(SRCDIR)/,, \
  $(patsubst %/,%,$(dir $(call find_source_files,*))))))

compute_ofiles = $(patsubst $(SRCDIR)/%,$(BUILDDIR)/%.o, \
  $(basename $(call find_source_files,$1)))

compute_ofile = $(patsubst $(firstword \
  $(subst /,$(SPACE),$(1)))/%,$(BUILDDIR)/%.o,$(basename $(1)))

# Source files generated from lex or yacc
GENERATED_SRC_FILES = $(patsubst $(SRCDIR)/%, \
  $(BUILDDIR)/%.$(CCFILEEXT), \
  $(basename $(call find_gen_source_files,$(SRC_DIRS_PATTERN))))

# Object files. Just used for dependency analysis
OBJFILES = $(call compute_ofiles,$(SRC_DIRS_PATTERN)) \
  $(call compute_ofiles,tests) $(call compute_ofiles,progs)

# Test cases and test binaries
COMPILED_TESTS = $(patsubst $(SRCDIR)/tests/%,$(TESTDIR)/%, \
  $(basename $(call find_source_files,tests)))

NONCOMPILED_TESTS = $(patsubst $(SRCDIR)/tests/%,$(TESTDIR)/%, \
  $(call find_shell_scripts,tests))

TESTS = $(COMPILED_TESTS) $(NONCOMPILED_TESTS)

ifneq ($(filter coverage%, $(MAKECMDGOALS)),)
ifeq ($(filter -fprofile-arcs, $(CFLAGS)),)
$(warning Be sure to compile with -fprofile-arcs for coverage measurements)
endif
ifeq ($(filter -ftest-coverage, $(CFLAGS)),)
$(warning Be sure to compile with -ftest-coverage for coverage measurements)
endif
ifneq ($(filter -O%, $(CFLAGS) $(FFLAGS)),)
$(warning Be sure to compile with -g rather than -O for coverage measurements)
endif
endif

# Programs
PROGS = $(patsubst $(SRCDIR)/progs/%,$(PROGDIR)/%, \
  $(basename $(call find_source_files,progs)))

.SUFFIXES : $(patsubst %,.%,$(SRC_FILE_EXTS)) .o .a .t .$(YACCFILEEXT) .$(LEXFILEEXT)

# To prevent gnu make from deleting the intermediate parser-related
# implementation files
.SECONDARY : 

.PHONY: progs lib tests

################################# MAIN TARGETS ################################
###############################################################################

install : install_progs install_lib

install_progs : progs
	install $(PROGS) $(PREFIX)/bin

install_lib: lib
	install $(LIBDIR)/lib$(LIBRARY_NAME).a ${PREFIX}/lib

lib : lib_message $(LIBDIR)/lib$(LIBRARY_NAME).a

# Check build environment
check : check_message check_programs check_colors

# Run tests
test : run_compiled_tests run_noncompiled_tests
	@$(call main_step_msg,Tests completed)
	@echo '   Compiled' tests: `cat $(TESTDIR)/COMPILED_TESTS_PASS` passed, `cat $(TESTDIR)/COMPILED_TESTS_FAIL` failed
	@echo Noncompiled tests: `cat $(TESTDIR)/NONCOMPILED_TESTS_PASS` passed, `cat $(TESTDIR)/NONCOMPILED_TESTS_FAIL` failed
	@$(RM) $(TESTDIR)/COMPILED_TESTS_PASS $(TESTDIR)/COMPILED_TESTS_FAIL \
	   $(TESTDIR)/NONCOMPILED_TESTS_PASS $(TESTDIR)/NONCOMPILED_TESTS_FAIL

# Make the libraries and programs
progs : lib progs_message $(PROGS) 

clean : clean_message 
	$(RM) -rf $(BUILDDIR) $(LIBDIR) $(TESTDIR) $(PROGDIR)
	@# The echo is just so the user can see what's happening
	@if test $(STORE_FILES_ELSEWHERE) = 'true'; then \
	  echo $(RM) -rf $(STORAGE_DIRECTORY)/$(BUILDDIR) \
	    $(STORAGE_DIRECTORY)/$(LIBDIR) \
	    $(STORAGE_DIRECTORY)/$(TESTDIR) $(STORAGE_DIRECTORY)/$(PROGDIR); \
	  $(RM) -rf $(STORAGE_DIRECTORY)/$(BUILDDIR) $(STORAGE_DIRECTORY)/$(LIBDIR) \
	    $(STORAGE_DIRECTORY)/$(TESTDIR) $(STORAGE_DIRECTORY)/$(PROGDIR); \
  fi

dist : dist_message distdir
	@$(call sub_step_msg,Making distribution file...)
	$(MV) $(TEMPDIR) $(DISTFILE)
	$(TAR) cf $(DISTFILE).tar $(DISTFILE)
	$(RM) -f $(DISTFILE).tar.gz
	$(GZIP) -9 $(DISTFILE).tar
	$(RM) -rf $(DISTFILE)

windist : windist_message windistdir
	@$(call sub_step_msg,Making distribution file...)
	$(MV) $(TEMPDIR) $(DISTFILE)
	$(ZIP) $(DISTFILE)-win.zip $(DISTFILE)/*
	$(RM) -rf $(DISTFILE)

coverage : coverage_message $(COVERAGEDIR)/all
	@$(call main_step_msg,Coverage completed)

coverage_individual : coverage_message $(addprefix $(COVERAGEDIR)/individual/,$(subst /,\#,$(TESTS)))
	@$(call main_step_msg,Coverage completed)

coverage_manual : coverage_message $(COVERAGEDIR)/manual
	@$(call main_step_msg,Coverage completed)

################################### MESSAGES ##################################
###############################################################################

check_programs_message :
	@$(call sub_step_msg,Checking that programs exist...)

compiled_tests_message :
	@$(call sub_step_msg,Building compiled test cases into tests directory)

noncompiled_tests_message :
	@$(call sub_step_msg,Copying noncompiled test cases to tests directory)

lib_message :
	@$(call main_step_msg,Making library $(LIBRARY_NAME))

check_message :
	@$(call main_step_msg,Checking build environment...)

progs_message :
	@$(call main_step_msg,Making programs)

coverage_message :
	@$(call main_step_msg,Computing coverage)

clean_message :
	@$(call main_step_msg,Making clean)

dist_message :
	@$(call main_step_msg,Making $(DISTFILE).tar.gz)

windist_message :
	@$(call main_step_msg,Making $(DISTFILE).zip)

################################# SUBROUTINES #################################
###############################################################################

# A subroutine to make a directory
make_directory = @ \
	if test ! -d $(1); then \
	  if test $(STORE_FILES_ELSEWHERE) = 'true'; then \
	    echo '--' Creating directory $(STORAGE_DIRECTORY)/$(1)...; \
	    echo $(MKDIRHIER) $(STORAGE_DIRECTORY)/$(1); \
	    $(MKDIRHIER) $(STORAGE_DIRECTORY)/$(1); \
	    if test ! -e `$(DIRNAME) $(1)`; then \
	      echo '--' Making symbolic link from $(STORAGE_DIRECTORY)/`$(DIRNAME) $(1)` to `$(DIRNAME) $(1)`...; \
	      echo $(LN) -s $(STORAGE_DIRECTORY)/`$(DIRNAME) $(1)` `$(DIRNAME) $(1)`; \
	      $(LN) -s $(STORAGE_DIRECTORY)/`$(DIRNAME) $(1)` `$(DIRNAME) $(1)`; \
	    fi; \
	  else \
	    echo '--' Creating directory $(1)...; \
	    echo $(MKDIRHIER) $(1); \
	    $(MKDIRHIER) $(1); \
	  fi; \
	fi

# Subroutines to issue colored alerts
main_step_msg = \
  if test $(DISABLE_COLORS) = 'false'; then \
    $(COLORS) $(MAIN_STEP_FOREGROUND) $(MAIN_STEP_BACKGROUND); \
  fi; \
  echo -n '===> $(1)'; \
  if test $(DISABLE_COLORS) = 'false'; then \
    $(COLORS) $(DEFAULT_FOREGROUND) $(DEFAULT_BACKGROUND); \
  fi; \
  echo

sub_step_msg = \
  if test $(DISABLE_COLORS) = 'false'; then \
    $(COLORS) $(SUB_STEP_FOREGROUND) $(SUB_STEP_BACKGROUND); \
  fi; \
  echo -n '> $(1)'; \
  if test $(DISABLE_COLORS) = 'false'; then \
    $(COLORS) $(DEFAULT_FOREGROUND) $(DEFAULT_BACKGROUND); \
  fi; \
  echo

warning_msg = \
  if test $(DISABLE_COLORS) = 'false'; then \
    $(COLORS) $(WARNING_FOREGROUND) $(WARNING_BACKGROUND); \
  fi; \
  echo -n '> $(1)'; \
  if test $(DISABLE_COLORS) = 'false'; then \
    $(COLORS) $(DEFAULT_FOREGROUND) $(DEFAULT_BACKGROUND); \
  fi; \
  echo

error_msg = \
  if test $(DISABLE_COLORS) = 'false'; then \
    $(COLORS) $(ERROR_FOREGROUND) $(ERROR_BACKGROUND); \
  fi; \
  echo -n '\#\#\#> $(1)'; \
  if test $(DISABLE_COLORS) = 'false'; then \
    $(COLORS) $(DEFAULT_FOREGROUND) $(DEFAULT_BACKGROUND); \
  fi; \
  echo

############################# SUPPORTING TARGETS ##############################
###############################################################################

check_programs : check_programs_message $(patsubst %,%.checkprogram,$(PROGRAMS))

expr.checkprogram:
	@if (expr 0 '&' 1 2>&1 > /dev/null); then \
	  $(call warning_msg,Could not execute program expr. You may not need it--check the makefile.); \
	fi

%.checkprogram:
	@if !($* --help 2>&1 | $(GREP) -i '\(usage\|option\|invalid\)' > /dev/null); then \
	  $(call warning_msg,Could not execute program $*. You may not need it--check the makefile.); \
	fi

# -----------------------------------------------------------------------------

check_colors:
	@echo Now checking colors. You may want to set DISABLE_COLORS to true.
	@$(call main_step_msg,This is a main step message.)
	@$(call sub_step_msg,This is a sub-step message.)
	@$(call warning_msg,This is a warning!)
	@$(call error_msg,This is an error!)

########################### DEPENDENCY GENERATION #############################
###############################################################################

# Cancel the normal implicit rules to make sure we get our own ones
%.c : %.$(YACCFILEEXT)
%.c : %.$(LEXFILEEXT)

# Dependency generation for object files

# Rule to make .o.d files from .$(CCFILEEXT) files
$(BUILDDIR)/%.o.d : $(SRCDIR)/%.$(CCFILEEXT)
	$(call make_directory,$(shell $(DIRNAME) $@))
	@$(call sub_step_msg,Making dependencies file $@)
	@set -e; rm -f $@; \
	 $(MAKEDEPEND) -- $(CXX) -MM $(CFLAGS) $< -o $(call compute_ofile,$<) > $@.$$$$; \
	 sed 's,\($(call compute_ofile,$<)\)[ :]*,\1 $@: ,g' < $@.$$$$ > $@; \
	 rm -f $@.$$$$

# Rule to make .o.d files from .$(CFILEEXT) files
$(BUILDDIR)/%.o.d : $(SRCDIR)/%.$(CFILEEXT)
	$(call make_directory,$(shell $(DIRNAME) $@))
	@$(call sub_step_msg,Making dependencies file $@)
	@set -e; rm -f $@; \
	 $(MAKEDEPEND) -- $(CC) -MM $(CFLAGS) $< -o $(call compute_ofile,$<) > $@.$$$$; \
	 sed 's,\($(call compute_ofile,$<)\)[ :]*,\1 $@: ,g' < $@.$$$$ > $@; \
	 rm -f $@.$$$$

# Rule to make .o.d files from generated .$(CCFILEEXT) files
# This is pretty yucky. We pass -MG to tell the GNU compiler to treat missing
# headers as generated. Then we have to patch up the paths so that the
# dependencies will refer to files in the build directory
$(BUILDDIR)/%.o.d : $(BUILDDIR)/%.$(CCFILEEXT)
	$(call make_directory,$(shell $(DIRNAME) $@))
	@$(call sub_step_msg,Making dependencies file $@)
	@set -e; rm -f $@; \
	 $(MAKEDEPEND) -- $(CXX) -MM -MG $(CFLAGS) $< -o $(call compute_ofile,$<) > $@.$$$$; \
	 sed 's,\($(call compute_ofile,$<)\)[ :]*,\1 $@: ,g' < $@.$$$$ > $@; \
	 rm -f $@.$$$$; \
	 mv $@ $@.$$$$; \
	 sed 's, \($(shell $(DIRNAME) $*)\), $(BUILDDIR)/\1,g' < $@.$$$$ > $@; \
	 rm -f $@.$$$$

# Dependency generation for library files

format_files=$(subst $(SPACE),$(SPACE)\\\\\\n$(SPACE)$(SPACE),$1)

$(BUILDDIR)/$(LIBDIR)/%.a.d :
	$(call make_directory,$(shell $(DIRNAME) $@))
	@$(call sub_step_msg,Making dependencies file $@)
	@set -e; rm -f $@; \
	 echo -e '$(LIBDIR)/$*.a: \\'"\\n  $(call format_files,$(call compute_ofiles,$(patsubst lib%,%,$*)))\\n" > $@

# Dependency generation for generated files

$(BUILDDIR)/%.$(CCFILEEXT).d : $(SRCDIR)/%.$(LEXFILEEXT)
	$(call make_directory,$(shell $(DIRNAME) $@))
	@$(call sub_step_msg,Making dependencies file $@)
	@set -e; rm -f $@; \
	 echo -e '$(BUILDDIR)/$*.$(CCFILEEXT) $@: \\'"\\n  $<\\n" > $@

$(BUILDDIR)/%.$(CCFILEEXT).d : $(SRCDIR)/%.$(YACCFILEEXT)
	$(call make_directory,$(shell $(DIRNAME) $@))
	@$(call sub_step_msg,Making dependencies file $@)
	@set -e; rm -f $@; \
	 echo -e '$(BUILDDIR)/$*.$(CCFILEEXT) $(BUILDDIR)/$*.h $@: \\'"\\n  $<\\n" > $@

# -----------------------------------------------------------------------------

# Include the dependencies (will automatically generate them). We guard this
# so that you can always run "make clean" without having to worry about
# generating dependencies

ifneq ($(filter clean,$(MAKECMDGOALS)),clean)
-include $(addsuffix .d,$(GENERATED_SRC_FILES)) \
        $(BUILDDIR)/$(LIBDIR)/lib$(LIBRARY_NAME).a.d \
        $(addsuffix .d,$(OBJFILES))
endif

########################### DISTRIBUTION TARGETS ##############################
###############################################################################

distdir:
	@$(call sub_step_msg,Copying files to temporary directory...)
	rm -rf $(TEMPDIR)
	$(MKDIR) $(TEMPDIR)
	$(CP) $(MAKEFILE_NAME) $(EXTRA_DIST_FILES) $(TEMPDIR)
	$(CP) -r $(SRCDIR) $(ETCDIR) $(UTILSDIR) $(DOCUMENTDIR) $(TEMPDIR)

windistdir: $(patsubst $(SRCDIR)/%.$(YACCFILEEXT),$(BUILDDIR)/%.$(CCFILEEXT),$(wildcard $(SRCDIR)/*/*.$(YACCFILEEXT))) \
            $(patsubst $(SRCDIR)/%.$(LEXFILEEXT),$(BUILDDIR)/%.$(CCFILEEXT),$(wildcard $(SRCDIR)/*/*.$(LEXFILEEXT))) \
            $(patsubst $(SRCDIR)/%.$(YACCFILEEXT),$(BUILDDIR)/%.h,$(wildcard $(SRCDIR)/*/*.$(YACCFILEEXT)))
	@$(call sub_step_msg,Copying files to temporary directory...)
	rm -rf $(TEMPDIR)
	$(MKDIR) $(TEMPDIR)
	$(CP) $(MAKEFILE_NAME) $(EXTRA_DIST_FILES) $(TEMPDIR)
	$(CP) -r $(SRCDIR) $(ETCDIR) $(UTILSDIR) $(DOCUMENTDIR) $(TEMPDIR)
	$(MKDIR) $(TEMPDIR)/$(BUILDDIR)
	$(CP) $^ $(TEMPDIR)/$(BUILDDIR)
	@$(call sub_step_msg,Converting files to DOS format...)
	@for file in `$(FIND) $(TEMPDIR) -type f`; do \
	  $(UNIX2DOS) $$file 2>/dev/null; \
	done

############################## TESTING TARGETS ################################
###############################################################################

compiled_tests : lib compiled_tests_message $(COMPILED_TESTS) 

run_compiled_tests : compiled_tests
	@$(call main_step_msg,Running compiled tests)
	@export COMPILED_TESTS_PASS="0"; \
	 export COMPILED_TESTS_FAIL="0"; \
	 for test in $(COMPILED_TESTS); do \
	   echo -n $(BACKGROUND); echo -n $(FOREGROUND); echo -n $(CYAN)'> Running test '"$$test... "$(TEXTCOLOR); \
	   if ./util/ensure_progress $(COMPILED_TESTS_TIME_LIMIT) $(COMPILED_TESTS_BYTE_LIMIT) $$test 1> $$test.stdout 2>$$test.stderr ; then \
	     COMPILED_TESTS_PASS=`$(EXPR) $$COMPILED_TESTS_PASS + 1`; \
	     echo PASS; \
	     $(RM) $$test.stdout $$test.stderr; \
	   else \
	     COMPILED_TESTS_FAIL=`$(EXPR) $$COMPILED_TESTS_FAIL + 1`; \
	     echo "FAIL (See $$test.stdout and $$test.stderr)"; \
	   fi; \
	 done; \
         echo $$COMPILED_TESTS_PASS > $(TESTDIR)/COMPILED_TESTS_PASS; \
         echo $$COMPILED_TESTS_FAIL > $(TESTDIR)/COMPILED_TESTS_FAIL

noncompiled_tests : progs noncompiled_tests_message $(NONCOMPILED_TESTS)

run_noncompiled_tests : noncompiled_tests
	@$(call main_step_msg,Running noncompiled tests)
	@export NONCOMPILED_TESTS_PASS="0"; \
	 export NONCOMPILED_TESTS_FAIL="0"; \
	 for test in $(NONCOMPILED_TESTS); do \
	   echo -n $(BACKGROUND); echo -n $(FOREGROUND); echo -n $(CYAN)'> Running test '"$$test... "$(TEXTCOLOR); \
	   if $$test 1>$$test.stdout 2>$$test.stderr ; then \
	     NONCOMPILED_TESTS_PASS=`$(EXPR) $$NONCOMPILED_TESTS_PASS + 1`; \
	     echo PASS; \
	     $(RM) $$test.stdout $$test.stderr; \
	   else \
	     NONCOMPILED_TESTS_FAIL=`$(EXPR) $$NONCOMPILED_TESTS_FAIL + 1`; \
	     echo "FAIL (See $$test.stdout and $$test.stderr)"; \
	   fi; \
	 done; \
         echo $$NONCOMPILED_TESTS_PASS > $(TESTDIR)/NONCOMPILED_TESTS_PASS; \
         echo $$NONCOMPILED_TESTS_FAIL > $(TESTDIR)/NONCOMPILED_TESTS_FAIL

############################## COMPILE TARGETS ################################
###############################################################################

# Cancel the normal implicit rules to make sure we get our own ones
%.o : %.$(CCFILEEXT)
%.o : %.$(CFILEEXT)
%.o : %.$(FFILEEXT)

# Rules to compile .$(CCFILEEXT) files into .o files.
$(BUILDDIR)/%.o : $(SRCDIR)/%.$(CCFILEEXT)
	$(call make_directory,$(shell $(DIRNAME) $@))
	$(CXX) $(CFLAGS) -c $< -o $@

# In case we have .$(CCFILEXT) files generated by other source. (e.g. from lex
# and yacc)
$(BUILDDIR)/%.o : $(BUILDDIR)/%.$(CCFILEEXT)
	$(call make_directory,$(shell $(DIRNAME) $@))
	$(CXX) $(CFLAGS) -c $< -o $@

# Rules to compile .$(CFILEEXT) files into .o files.
$(BUILDDIR)/%.o : $(SRCDIR)/%.$(CFILEEXT)
	$(call make_directory,$(shell $(DIRNAME) $@))
	$(CC) $(CFLAGS) -c $< -o $@

# In case we have .$(CFILEXT) files generated by other source. (e.g. from lex
# and yacc)
$(BUILDDIR)/%.o : $(BUILDDIR)/%.$(CFILEEXT)
	$(call make_directory,$(shell $(DIRNAME) $@))
	$(CC) $(CFLAGS) -c $< -o $@

# Rule to compile .f files into .o files.
$(BUILDDIR)/%.o : $(SRCDIR)/%.f
	$(call make_directory,$(shell $(DIRNAME) $@))
	$(FC) $(FFLAGS) -c $< -o $@

# Rule to compile .$(LEXFILEEXT) files into .$(CCFILEEXT) files.
$(BUILDDIR)/%.$(CCFILEEXT) : $(SRCDIR)/%.$(LEXFILEEXT)
	$(call make_directory,$(shell $(DIRNAME) $@))
	$(LEX) -o$@ $<

# Rule to compile test binaries
$(TESTDIR)/% : $(LIBDIR)/lib$(LIBRARY_NAME).a $(BUILDDIR)/tests/%.o
	$(call make_directory,$(shell $(DIRNAME) $@))
	@$(call sub_step_msg,Making test case $@)
	$(LD) $(LDFLAGS) $(CFLAGS) $(BUILDDIR)/tests/$*.o $(LIB_FLAGS) -o $@

# Rule to copy tests which are scripts
$(TESTDIR)/%.$(SCRIPTFILEEXT) : $(PROGS) $(SRCDIR)/$(TESTDIR)/%.$(SCRIPTFILEEXT)
	$(call make_directory,$(shell $(DIRNAME) $@))
	@$(call sub_step_msg,Copying test case $@)
	$(CP) $(SRCDIR)/$(TESTDIR)/$*.$(SCRIPTFILEEXT) $@
	@$(CHMOD) a+x $@

# Rule to run all coverage tests
$(COVERAGEDIR)/all : $(TESTS)
	@$(PERL) util/compute_coverage.pl -C $(COVERAGE_DIRECTORIES) -o $@ $(TESTS)

# Rule to run manual coverage tests
$(COVERAGEDIR)/manual :
	@$(PERL) util/compute_coverage.pl -C $(COVERAGE_DIRECTORIES) -o $@

# Rule to run individual coverage tests. Really this should depend on
# $(subst #,/,%) but make doesn't allow functions in the dependency list.
# Instead I depend on all $(TESTS)
$(COVERAGEDIR)/individual/% : $(TESTS)
	@$(PERL) util/compute_coverage.pl -C $(COVERAGE_DIRECTORIES) -o $@ $(subst #,/,$(subst $(COVERAGEDIR)/individual/,,$@))

# Rule to compile non-test binaries
$(PROGDIR)/% : $(LIBDIR)/lib$(LIBRARY_NAME).a $(BUILDDIR)/progs/%.o
	$(call make_directory,$(shell $(DIRNAME) $@))
	@$(call sub_step_msg,Making program $@)
	$(LD) $(LDFLAGS) $(CFLAGS) $(BUILDDIR)/progs/$*.o $(LIB_FLAGS) -o $@

# Rule to create the library
$(LIBDIR)/lib$(LIBRARY_NAME).a : $(call compute_ofiles,$(SRC_DIRS_PATTERN))
	@$(call sub_step_msg,Making library $@)
	@$(call make_directory,$(shell $(DIRNAME) $@))
	@if test '$^' != ''; then \
	   $(AR) rv $@ $^ 2>&1; \
	   ranlib $@; \
	 fi

# Rule to generate parser .$(CCFILEEXT) files from .$(YACCFILEEXT) files
$(BUILDDIR)/%.$(CCFILEEXT) $(BUILDDIR)/%.h : $(SRCDIR)/%.$(YACCFILEEXT)
	$(call make_directory,$(shell $(DIRNAME) $@))
	$(YACC) -p $(notdir $*)_ -d -o $(basename $@).$(CCFILEEXT) $<
	if test -e $(basename $@).$(CCFILEEXT).h ; then \
	  $(MV) $(basename $@).$(CCFILEEXT).h $(basename $@).h; \
	else if test -e $(basename $@).hpp ; then \
	  $(MV) $(basename $@).hpp $(basename $@).h; \
	fi; fi
