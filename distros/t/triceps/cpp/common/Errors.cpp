//
// (C) Copyright 2011-2014 Sergey A. Babkin.
// This file is a part of Triceps.
// See the file COPYRIGHT for the copyright notice and license information
//
//
// A common way for reporting of the errors

#include <common/Common.h>
#include <assert.h>

namespace TRICEPS_NS {

Errors::Epair::Epair()
{ }

Errors::Epair::Epair(const string &msg, Autoref<Errors> child) :
	msg_(msg),
	child_(child)
{ }

Errors::Errors(bool e) :
	error_(e)
{ }

Errors::Errors(const string &msg) :
	error_(true)
{
	appendMultiline(true, msg);
}

Errors::Errors(const char *msg) :
	error_(true)
{
	appendMultiline(true, msg);
}

Errors::Errors(const string &msg, Autoref<Errors> clde) :
	error_(true)
{
	appendMultiline(true, msg);
	if (!clde.isNull())
		elist_.push_back(Epair(string(), clde));
}

bool Errors::append(const string &msg, Autoref<Errors> clde)
{
	if (clde.isNull())
		return false;

	bool ce = clde->error_;
	error_ = (error_ || ce);

	if (clde->isEmpty()) { // nothing in there
		if (ce) { // but there was an error indication, so append the message
			elist_.push_back(Epair(msg, NULL));
		}
		return ce;
	}

	elist_.push_back(Epair(msg, clde));

	return true;
}

bool Errors::absorb(Autoref<Errors> clde)
{
	if (clde.isNull())
		return false;

	bool ce = clde->error_;
	error_ = (error_ || ce);

	if (clde->isEmpty()) { // nothing in there
		return ce;
	}

	for (vector<Epair>::iterator it = clde->elist_.begin(); it != clde->elist_.end(); ++it)
		elist_.push_back(Epair(*it));

	return true;
}

void Errors::appendMsg(bool e, const string &msg)
{
	error_ = (error_ || e);
	elist_.push_back(Epair(msg, NULL));
}

void Errors::appendMultiline(bool e, const string &msg)
{
	error_ = (error_ || e);
	string::size_type from = 0, to = 0;
	while (to < msg.size()) {
		to = msg.find('\n', from);
		if (to == string::npos)
			to = msg.size();
		if (to != 0)
			elist_.push_back(Epair(msg.substr(from, to-from), NULL));
		from = to = to+1;
	}
}

void Errors::replaceMsg(const string &msg)
{
	size_t n = elist_.size();
	if (n != 0)
		elist_[n-1].msg_ = msg;
}

bool Errors::isEmpty()
{
	if (this == NULL)
		return true;

	return elist_.empty();
}

void Errors::printTo(string &res, const string &indent, const string &subindent)
{
	size_t i, n = elist_.size();
	for (i = 0; i < n; i++) {
		if  (!elist_[i].msg_.empty())
			res += indent + elist_[i].msg_ + "\n";
		if  (!elist_[i].child_.isNull())
			elist_[i].child_->printTo(res, indent + subindent, subindent);
	}
}

string Errors::print(const string &indent, const string &subindent)
{
	string res;
	printTo(res, indent, subindent);
	return res;
}

void Errors::clear()
{
	elist_.clear();
	error_ = false;
}

// ------------------------------------ Erref ----------------------------------

bool Erref::fAppend(Autoref<Errors> clde, const char *fmt, ...)
{
	if (!clde->hasError())
		return false;

	va_list ap;
	va_start(ap, fmt);
	string msg = vstrprintf(fmt, ap);
	va_end(ap);

	if (isNull())
		*this = new Errors(msg, clde);
	else
		(*this)->append(msg, clde);

	return true;
}


void Erref::f(const char *fmt, ...)
{
	va_list ap;
	va_start(ap, fmt);
	string msg = vstrprintf(fmt, ap);
	va_end(ap);

	if (isNull())
		*this = new Errors;
	(*this)->appendMultiline(true, msg);
}

}; // TRICEPS_NS
