//
// (C) Copyright 2011-2014 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
//
// The scoped App drains.

#ifndef __Triceps_AutoDrain_h__
#define __Triceps_AutoDrain_h__

#include <app/TrieadOwner.h>

namespace TRICEPS_NS {

// The scoped drains. Can be created directly as a scoped
// variable of be kept in a scoped reference.

// The common base for both types of drains. The wait and undrain
// code is all common, and it also makes things easier for the
// Perl wrapping.
class AutoDrain: public Starget
{
public:
	// Can not be constructed directly, only through a subclass.

	~AutoDrain()
	{
		app_->undrain();
	}

	// Wait for the drain to complete. May be used repeatedly inside
	// the scope, since it's possible for the drain owner to insert
	// more data and wait for it to be drained again.
	void wait()
	{
		app_->waitDrain();
	}

protected:
	// @param app - the App that has been drained by subclass
	AutoDrain(App *app):
		app_(app)
	{ }

	Autoref<App> app_;

private:
	AutoDrain();
	AutoDrain(const AutoDrain&);
	void operator=(const AutoDrain &);
};

class AutoDrainShared: public AutoDrain
{
public:
	// @param app - the App to drain
	// @param wait - flag: right away wait for the drain to complete
	AutoDrainShared(App *app, bool wait = true):
		AutoDrain(app)
	{
		if (wait)
			app_->drain();
		else
			app_->requestDrain();
	}
	// @param to - any AutoDrain belonging to the App to drain
	// @param wait - flag: right away wait for the drain to complete
	AutoDrainShared(TrieadOwner *to, bool wait = true):
		AutoDrain(to->app())
	{
		if (wait)
			app_->drain();
		else
			app_->requestDrain();
	}

private:
	AutoDrainShared();
	AutoDrainShared(const AutoDrainShared&);
	void operator=(const AutoDrainShared &);
};

class AutoDrainExclusive: public AutoDrain
{
public:
	// @param to - the AutoDrain that is excepted from the drain
	// @param wait - flag: right away wait for the drain to complete
	AutoDrainExclusive(TrieadOwner *to, bool wait = true):
		AutoDrain(to->app())
	{
		if (wait)
			to->drainExclusive();
		else
			to->requestDrainExclusive();
	}

private:
	AutoDrainExclusive();
	AutoDrainExclusive(const AutoDrainExclusive&);
	void operator=(const AutoDrainExclusive &);
};

}; // TRICEPS_NS

#endif // __Triceps_AutoDrain_h__
