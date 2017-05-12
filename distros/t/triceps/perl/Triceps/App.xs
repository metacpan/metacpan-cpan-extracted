//
// (C) Copyright 2011-2014 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
// The wrapper for App.

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "TricepsPerl.h"
#include "PerlApp.h"
#include "app/App.h"

MODULE = Triceps::App		PACKAGE = Triceps::App
###################################################################################

int
CLONE_SKIP(...)
	CODE:
		RETVAL = 1;
	OUTPUT:
		RETVAL

void
DESTROY(WrapApp *self)
	CODE:
		App *app = self->get();
		// warn("App %s %p wrap %p destroyed!", app->getName().c_str(), app, self);
		delete self;


WrapApp *
make(char *name)
	CODE:
		// for casting of return value
		static char CLASS[] = "Triceps::App";

		clearErrMsg();
		RETVAL = NULL; // shut up the warning

		try { do {
			Autoref<App> app ;
			app = App::make(name);
			// warn("Created app %s %p wrap %p", name, app.get(), wa);
			RETVAL = new WrapApp(app);
		} while(0); } TRICEPS_CATCH_CROAK;

	OUTPUT:
		RETVAL

WrapApp *
find(char *name)
	CODE:
		// for casting of return value
		static char CLASS[] = "Triceps::App";

		clearErrMsg();
		RETVAL = NULL; // shut up the warning

		try { do {
			Autoref<App> app ;
			app = App::find(name);
			RETVAL = new WrapApp(app);
		} while(0); } TRICEPS_CATCH_CROAK;

	OUTPUT:
		RETVAL

#// This is very much like find() only it can accept an App
#// reference as an argument and will then return that reference
#// back; or if it's a string, will do the usual lookup.
#// Since many Perl functions accept the App argument either
#// way, this allows to translate from either way to App.
#// On the other hand, find() preserves the strict name-to-object
#// semantics and requires that the App must not be dropped.
#//
#// @param app - App name or reference taht will be translated to
#//        a reference
WrapApp *
resolve(SV *app)
	CODE:
		// for casting of return value
		static char funcName[] =  "Triceps::App::resolve";
		static char CLASS[] = "Triceps::App";
		clearErrMsg();
		RETVAL = NULL; // shut up the warning

		clearErrMsg();
		try { do {
			Autoref<App> appv;
			parseApp(funcName, "app", app, appv);
			RETVAL = new WrapApp(appv);
		} while(0); } TRICEPS_CATCH_CROAK;
	OUTPUT:
		RETVAL

#// This works both as an object method on an object, or as
#// a class method with an object or name argument
void
drop(SV *app)
	CODE:
		static char funcName[] =  "Triceps::App::drop";
		clearErrMsg();
		try { do {
			Autoref<App> appv;
			parseApp(funcName, "app", app, appv);
			App::drop(appv);
		} while(0); } TRICEPS_CATCH_CROAK;

SV *
listApps()
	PPCODE:
		// for casting of return value
		static char CLASS[] = "Triceps::App";

		clearErrMsg();
		App::Map m;
		App::listApps(m);
		for (App::Map::iterator it = m.begin(); it != m.end(); ++it) {
			XPUSHs(sv_2mortal(newSVpvn(it->first.c_str(), it->first.size())));

			SV *sub = newSV(0);
			sv_setref_pv( sub, CLASS, (void*)(new WrapApp(it->second)) );
			XPUSHs(sv_2mortal(sub));
		}

#// check whether both refs point to the same object
int
same(WrapApp *self, WrapApp *other)
	CODE:
		clearErrMsg();
		App *a1 = self->get();
		App *a2 = other->get();
		RETVAL = (a1 == a2);
	OUTPUT:
		RETVAL

char *
getName(WrapApp *self)
	CODE:
		clearErrMsg();
		App *a = self->get();
		RETVAL = (char *)a->getName().c_str();
	OUTPUT:
		RETVAL

int
isAborted(SV *app)
	CODE:
		static char funcName[] =  "Triceps::App::isAborted";
		clearErrMsg();
		RETVAL = 0;
		try { do {
			Autoref<App> appv;
			parseApp(funcName, "app", app, appv);
			RETVAL = appv->isAborted();
		} while(0); } TRICEPS_CATCH_CROAK;
	OUTPUT:
		RETVAL

#// returns a list of (triead name, message),
#// and if not aborted then both will be undef
SV *
getAborted(SV *app)
	PPCODE:
		// for casting of return value
		static char funcName[] =  "Triceps::App::getAborted";
		clearErrMsg();
		try { do {
			Autoref<App> appv;
			parseApp(funcName, "app", app, appv);

			if (!appv->isAborted()) {
				XPUSHs(sv_2mortal(newSV(0)));
				XPUSHs(sv_2mortal(newSV(0)));
			} else {
				string t = appv->getAbortedBy();
				string m = appv->getAbortedMsg();

				XPUSHs(sv_2mortal(newSVpvn(t.c_str(), t.size())));
				XPUSHs(sv_2mortal(newSVpvn(m.c_str(), m.size())));

				SV *sub = newSV(0); // undef by default
				XPUSHs(sv_2mortal(sub));
			}
		} while(0); } TRICEPS_CATCH_CROAK;

void
abortBy(SV *app, char *tname, char *msg)
	CODE:
		static char funcName[] =  "Triceps::App::abortBy";
		clearErrMsg();
		try { do {
			Autoref<App> appv;
			parseApp(funcName, "app", app, appv);
			appv->abortBy(tname, msg);
		} while(0); } TRICEPS_CATCH_CROAK;

#// the deadline is in seconds since Unix epoch
void
setDeadline(SV *app, int deadline)
	CODE:
		static char funcName[] =  "Triceps::App::setDeadline";
		clearErrMsg();
		try { do {
			Autoref<App> appv;
			parseApp(funcName, "app", app, appv);

			timespec dl;
			dl.tv_sec = deadline;
			dl.tv_nsec = 0;
			appv->setDeadline(dl);
		} while(0); } TRICEPS_CATCH_CROAK;

void
setTimeout(SV *app, int main_to, ...)
	CODE:
		static char funcName[] =  "Triceps::App::setTimeout";
		clearErrMsg();
		try { do {
			Autoref<App> appv;
			parseApp(funcName, "app", app, appv);

			if (items > 3) {
				throw Exception::f("Usage: %s(app, main_to, [frag_to]), too many arguments", funcName);
			}

			int frag_to = -1;
			if (items == 3) {
				frag_to = SvIV(ST(2));
			}

			appv->setTimeout(main_to, frag_to);
		} while(0); } TRICEPS_CATCH_CROAK;

void
refreshDeadline(SV *app)
	CODE:
		static char funcName[] =  "Triceps::App::refreshDeadline";
		clearErrMsg();
		try { do {
			Autoref<App> appv;
			parseApp(funcName, "app", app, appv);
			appv->refreshDeadline();
		} while(0); } TRICEPS_CATCH_CROAK;

#// the app can be used as a object or name
void
declareTriead(SV *app, char *tname)
	CODE:
		static char funcName[] =  "Triceps::App::declareTriead";
		clearErrMsg();
		try { do {
			Autoref<App> appv;
			parseApp(funcName, "app", app, appv);
			appv->declareTriead(tname);
		} while(0); } TRICEPS_CATCH_CROAK;

SV *
getTrieads(SV *app)
	PPCODE:
		// for casting of return value
		static char funcName[] =  "Triceps::App::getTrieads";
		static char CLASS[] = "Triceps::Triead";
		clearErrMsg();
		try { do {
			Autoref<App> appv;
			parseApp(funcName, "app", app, appv);

			App::TrieadMap m;
			appv->getTrieads(m);
			for (App::TrieadMap::iterator it = m.begin(); it != m.end(); ++it) {
				XPUSHs(sv_2mortal(newSVpvn(it->first.c_str(), it->first.size())));

				SV *sub = newSV(0); // undef by default
				if (!it->second.isNull())
					sv_setref_pv( sub, CLASS, (void*)(new WrapTriead(it->second)) );
				XPUSHs(sv_2mortal(sub));
			}
		} while(0); } TRICEPS_CATCH_CROAK;

#// The wrapper functions accept only the object to be more safe:
#// since the App gets normally dropped at the end of harvesting,
#// this safeguards from calling on another instance of an App
#// with the same name.
int
harvestOnce(WrapApp *self)
	CODE:
		clearErrMsg();
		App *a = self->get();
		RETVAL = 0;
		try { do {
			RETVAL = (int)a->harvestOnce();
		} while(0); } TRICEPS_CATCH_CROAK;
	OUTPUT:
		RETVAL

void
waitNeedHarvest(WrapApp *self)
	CODE:
		clearErrMsg();
		App *a = self->get();
		try { do {
			a->waitNeedHarvest();
		} while(0); } TRICEPS_CATCH_CROAK;

#// Options:
#//
#// die_on_abort => int
#// Flag: if the App abort has been detected, will die after it disposes
#// of the App. Analog of the C++ flag throwAbort. Default: 1.
#//
void
harvester(WrapApp *self, ...)
	CODE:
		static char funcName[] =  "Triceps::App::harvester";
		clearErrMsg();
		App *a = self->get();
		try { do {
			bool throwAbort = true;

			if (items % 2 != 1) {
				throw Exception::f("Usage: %s(app, optionName, optionValue, ...), option names and values must go in pairs", funcName);
			}
			for (int i = 1; i < items; i += 2) {
				const char *optname = (const char *)SvPV_nolen(ST(i));
				SV *arg = ST(i+1);
				if (!strcmp(optname, "die_on_abort")) {
					throwAbort = SvTRUE(arg);
				} else {
					throw Exception::f("%s: unknown option '%s'", funcName, optname);
				}
			}

			a->harvester(throwAbort);
		} while(0); } TRICEPS_CATCH_CROAK;

#// returns the constant value
int 
DEFAULT_TIMEOUT()
	CODE:
		RETVAL = App::DEFAULT_TIMEOUT;
	OUTPUT:
		RETVAL

int
isDead(SV *app)
	CODE:
		static char funcName[] =  "Triceps::App::isDead";
		clearErrMsg();
		RETVAL = 0;
		try { do {
			Autoref<App> appv;
			parseApp(funcName, "app", app, appv);
			RETVAL = appv->isDead();
		} while(0); } TRICEPS_CATCH_CROAK;
	OUTPUT:
		RETVAL

int
isShutdown(SV *app)
	CODE:
		static char funcName[] =  "Triceps::App::isShutdown";
		clearErrMsg();
		RETVAL = 0;
		try { do {
			Autoref<App> appv;
			parseApp(funcName, "app", app, appv);
			RETVAL = appv->isShutdown();
		} while(0); } TRICEPS_CATCH_CROAK;
	OUTPUT:
		RETVAL

#// by design works with a reference only, since the App
#// could be harvested and dropped
void
waitDead(WrapApp *self)
	CODE:
		clearErrMsg();
		try { do {
			self->get()->waitDead();
		} while(0); } TRICEPS_CATCH_CROAK;

void
shutdown(SV *app)
	CODE:
		static char funcName[] =  "Triceps::App::shutdown";
		clearErrMsg();
		try { do {
			Autoref<App> appv;
			parseApp(funcName, "app", app, appv);
			appv->shutdown();
		} while(0); } TRICEPS_CATCH_CROAK;

void
shutdownFragment(SV *app, char *fragname)
	CODE:
		static char funcName[] =  "Triceps::App::shutdownFragment";
		clearErrMsg();
		try { do {
			Autoref<App> appv;
			parseApp(funcName, "app", app, appv);
			appv->shutdownFragment(fragname);
		} while(0); } TRICEPS_CATCH_CROAK;

#// no requestDrainExclusive(), that is done in the Perl API
#// only through a TrieadOwner method
void
requestDrain(SV *app)
	CODE:
		static char funcName[] =  "Triceps::App::requestDrain";
		clearErrMsg();
		try { do {
			Autoref<App> appv;
			parseApp(funcName, "app", app, appv);
			appv->requestDrain();
		} while(0); } TRICEPS_CATCH_CROAK;

void
waitDrain(SV *app)
	CODE:
		static char funcName[] =  "Triceps::App::waitDrain";
		clearErrMsg();
		try { do {
			Autoref<App> appv;
			parseApp(funcName, "app", app, appv);
			appv->waitDrain();
		} while(0); } TRICEPS_CATCH_CROAK;

void
drain(SV *app)
	CODE:
		static char funcName[] =  "Triceps::App::drain";
		clearErrMsg();
		try { do {
			Autoref<App> appv;
			parseApp(funcName, "app", app, appv);
			appv->drain();
		} while(0); } TRICEPS_CATCH_CROAK;

void
undrain(SV *app)
	CODE:
		static char funcName[] =  "Triceps::App::undrain";
		clearErrMsg();
		try { do {
			Autoref<App> appv;
			parseApp(funcName, "app", app, appv);
			appv->undrain();
		} while(0); } TRICEPS_CATCH_CROAK;

int
isDrained(SV *app)
	CODE:
		static char funcName[] =  "Triceps::App::isDrained";
		clearErrMsg();
		RETVAL = 0;
		try { do {
			Autoref<App> appv;
			parseApp(funcName, "app", app, appv);
			RETVAL = appv->isDrained();
		} while(0); } TRICEPS_CATCH_CROAK;
	OUTPUT:
		RETVAL

# Dups the descriptor before storing it.
void 
storeFd(SV *app, char *name, int fd, char *className)
	CODE:
		static char funcName[] =  "Triceps::App::storeFd";
		clearErrMsg();
		try { do {
			Autoref<App> appv;
			parseApp(funcName, "app", app, appv);
			int dupfd = dup(fd);
			if (dupfd < 0)
				throw Exception::f("%s: dup failed: %s", funcName, strerror(errno));
			try {
				appv->storeFd(name, dupfd, className); // may throw
			} catch (Exception e) {
				close(dupfd);
				throw;
			}
		} while(0); } TRICEPS_CATCH_CROAK;
	
# dies on an unknown name
SV * 
loadFd(SV *app, char *name)
	PPCODE:
		static char funcName[] =  "Triceps::App::loadFd";
		clearErrMsg();
		try { do {
			Autoref<App> appv;
			parseApp(funcName, "app", app, appv);
			string className;
			int fd = appv->loadFd(name, &className);
			if (fd < 0)
				throw Exception::f("%s: unknown file descriptor '%s'", funcName, name);

			XPUSHs(sv_2mortal(newSViv(fd)));
			XPUSHs(sv_2mortal(newSVpvn(className.c_str(), className.size())));
		} while(0); } TRICEPS_CATCH_CROAK;
	
# returns a pair ($fd, $className)
# with a dup()-ed descriptor
# dies on an unknown name
SV * 
loadDupFd(SV *app, char *name)
	PPCODE:
		static char funcName[] =  "Triceps::App::loadDupFd";
		clearErrMsg();
		RETVAL = 0;
		try { do {
			Autoref<App> appv;
			parseApp(funcName, "app", app, appv);
			string className;
			int fd = appv->loadFd(name, &className);
			if (fd < 0)
				throw Exception::f("%s: unknown file descriptor '%s'", funcName, name);
			fd = dup(fd);
			if (fd < 0)
				throw Exception::f("%s: dup failed: %s", funcName, strerror(errno));

			XPUSHs(sv_2mortal(newSViv(fd)));
			XPUSHs(sv_2mortal(newSVpvn(className.c_str(), className.size())));
		} while(0); } TRICEPS_CATCH_CROAK;

# dies on an unknown name
void 
forgetFd(SV *app, char *name)
	CODE:
		static char funcName[] =  "Triceps::App::forgetFd";
		clearErrMsg();
		try { do {
			Autoref<App> appv;
			parseApp(funcName, "app", app, appv);
			if (!appv->forgetFd(name))
				throw Exception::f("%s: unknown file descriptor '%s'", funcName, name);
		} while(0); } TRICEPS_CATCH_CROAK;

# dies on an unknown name
void 
closeFd(SV *app, char *name)
	CODE:
		static char funcName[] =  "Triceps::App::closeFd";
		clearErrMsg();
		try { do {
			Autoref<App> appv;
			parseApp(funcName, "app", app, appv);
			if (!appv->closeFd(name))
				throw Exception::f("%s: unknown file descriptor '%s'", funcName, name);
			if (errno != 0)
				throw Exception::f("%s: failed to close file descriptor '%s': %s", funcName, name, strerror(errno));
		} while(0); } TRICEPS_CATCH_CROAK;
