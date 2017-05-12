SUBDIRS := pw common mem sched type table utest wrap app

.PHONY: all clean clobber cleandep mktest cleantest test qtest vtest all-subdirs $(SUBDIRS)

include Makefile.inc

OBJECTS := $(foreach dir, $(SUBDIRS), $(wildcard $(dir)/$(BUILDDIR)/*.o))

LIBRARIES := $(BUILDDIR)/$(SHLIB) $(BUILDDIR)/$(ARLIB)

# need to call make recursively, to reload $(OBJECTS) after they've been built
all: $(SUBDIRS)
	$(MAKE) libraries

libraries: $(LIBRARIES)

$(SUBDIRS):
	$(MAKE) -C $@

clean clobber::
	for i in $(SUBDIRS) ; do \
		$(MAKE) -C $$i $@ || exit 1; \
	done
	rm -f $(LIBRARIES)

clean::
	rm -rf $(BUILDDIR)
	
test qtest vtest:: mktest

cleandep mktest cleantest test qtest vtest::
	for i in $(SUBDIRS) ; do \
		$(MAKE) -C $$i $@ || exit 1; \
	done

$(LIBRARIES): | $(BUILDDIR)

$(BUILDDIR)/$(SHLIB): $(OBJECTS) 
	rm -f $@
	$(CXX) -shared -o $@ $^

$(BUILDDIR)/$(ARLIB): $(OBJECTS)
	rm -f $@
	$(AR) cr $@ $^
	$(RANLIB) $@
