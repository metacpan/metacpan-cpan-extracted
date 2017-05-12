
// Make sure C++ headers are included before PERL headers to avoid errors.
#include<iostream>
#include<leveldb/db.h>
#include<leveldb/slice.h>
#include<leveldb/iterator.h>
#include<leveldb/write_batch.h>

#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

//#include <Tie::LevelDB>

#ifdef __cplusplus
}
#endif

// winnt.h already defines DELETE which overlaps our DELETE method.
#undef DELETE

void status_assert(leveldb::Status s) {
	if(!s.ok()) croak("%s",s.ToString().c_str());
}
SV* newSVstring(std::string str) {
    return newSVpvn(str.data(),str.length());
}
SV* newSVslice(leveldb::Slice slice) {
    return newSVpvn(slice.data(),slice.size());
}
std::string SV2string(SV* sv) {
    STRLEN len;
    char * ptr = SvPV(sv, len);
    return std::string(ptr,len);
}

class Iterator {
protected:
	leveldb::Iterator *it;
public:
	Iterator() {
		it = NULL; // die!
	}
	Iterator(leveldb::Iterator *it) : it(it) { }
	~Iterator() { delete it; it = NULL; }
	void SeekToFirst() { it->SeekToFirst(); }
	void SeekToLast()  { it->SeekToLast(); }
	void Seek(const SV* sv_target) {
		leveldb::Slice target(SvPVX(sv_target), SvCUR(sv_target));
		it->Seek(target);
	}
	void Next()  { it->Next(); }
	void Prev()  { it->Prev(); }
	bool Valid() { return it->Valid(); }
	SV* key() { 
		SV* k = newSVstring(it->key().ToString());
		status_assert(it->status());
		return k;
	}
	SV* value() { 
		SV* v = newSVstring(it->value().ToString());
		status_assert(it->status());
		return v;
	}
};

class WriteBatch {
protected:
	leveldb::WriteBatch *batch;
public:
	leveldb::WriteBatch* get_batch() { return batch; }

	WriteBatch() {
		batch = new leveldb::WriteBatch();
	}
	~WriteBatch() {
		delete batch;
	}
	void Put(const char* key,const char * cvalue) {
		if(cvalue) {
			std::string* value = new std::string(cvalue);
			batch->Put(key, *value);
		} else Delete(key); // LevelDB limitation..
	}
	void Delete(const char * key) {
		batch->Delete(key);
	}
};

class DB {
protected:
	leveldb::DB *db;
public:
	DB() : db(NULL) { }
	DB(const char* name,HV* hv_options=NULL ) : db(NULL) { 
		Open(name,hv_options);
	}
	~DB() {
		if(db) { delete db; db = NULL; }
	}
	void Open(const char* name,HV* hv_options=NULL) { 
		leveldb::Options options; // todo: construct
		options.create_if_missing = true;
		// options.error_if_exists = true;
		if(db) delete db;
		status_assert(leveldb::DB::Open(options, name, &db));
	}
	void Put(const char* key,const char* cvalue=NULL,
			 HV* hv_write_options=NULL) {
		leveldb::WriteOptions write_options;
		if(cvalue) {
			std::string* value = new std::string(cvalue);
			status_assert(db->Put(write_options, key, *value));
		} else {
			status_assert(db->Delete(leveldb::WriteOptions(), key));
		}
	}
	SV* Get(const char* key) {
		std::string value;
		leveldb::Status s = db->Get(leveldb::ReadOptions(), key, &value);
		if(s.IsNotFound()) return NULL;
		status_assert(s);
		return newSVstring(value);
	}
	void Delete(const char* key) {
		status_assert(db->Delete(leveldb::WriteOptions(), key));
	}
	void Write(WriteBatch* batch,HV* hv_write_options=NULL) {
		leveldb::WriteOptions write_options; // todo: construct
		status_assert(db->Write(write_options,batch->get_batch()));
	}
	Iterator* NewIterator(HV* hv_read_options=NULL) {
		leveldb::ReadOptions read_options; // todo: construct
		return new Iterator(db->NewIterator(read_options));
	}
};

class LevelDB {
	leveldb::DB* db;
	leveldb::Iterator* it;
	leveldb::Options options;
	leveldb::WriteOptions write_options;
	leveldb::ReadOptions read_options;
	leveldb::WriteBatch batch;
	
public:
	LevelDB() : db(NULL), it(NULL) {}
	LevelDB(const char* name,HV* hv_options=NULL) {
		db = NULL; it = NULL;
		Open(name,hv_options);
	}
	void Open(const char* name,HV* hv_options=NULL) {
		options.create_if_missing = true;
		status_assert(leveldb::DB::Open(options,name,&db));
	}
	~LevelDB() { 
		if(it) delete it;
		if(db) delete db;
	}
	SV* FETCH(SV* sv_key) {
		std::string key = SV2string(sv_key);
		std::string value;
		leveldb::Status s = db->Get(read_options,key,&value);
		if(s.IsNotFound()) return newSV(0);
		status_assert(s);
		return newSVstring(value);
	}
	void STORE(SV* sv_key,SV* sv_value) {
		std::string key = SV2string(sv_key);
		std::string value = SV2string(sv_value);
		status_assert(db->Put(write_options,key,value));
	}
	void DELETE(SV* sv_key) {
		std::string key = SV2string(sv_key);
		status_assert(db->Delete(write_options,key));
	}
	void CLEAR() {
		leveldb::WriteBatch batch;
		leveldb::Iterator* it = db->NewIterator(read_options);
		for(it->SeekToFirst();it->Valid();it->Next()) 
			batch.Delete(it->key().ToString().c_str()); // TODO: c_str()??
		delete it;
		status_assert(db->Write(write_options,&batch));
	}
	bool EXISTS(SV* sv_key) {
		std::string key = SV2string(sv_key);
		leveldb::Iterator* find = db->NewIterator(read_options);
		find->Seek(key);
		bool valid = find->Valid();
		delete(find);
		return valid;
	}
	SV* FIRSTKEY() {
		if(it) delete it;
		it = db->NewIterator(read_options);
		it->SeekToFirst();
		return it->Valid() ? newSVslice(it->key()) : newSV(0);
	}
	SV* NEXTKEY(SV* sv_lastkey) {
		if(!it) return NULL;
		it->Next();
		return it->Valid() ? newSVslice(it->key()) : newSV(0);
	}
	int SCALAR() {
		int count = 0;
		leveldb::Iterator* it = db->NewIterator(read_options);
		for(it->SeekToFirst();it->Valid();it->Next()) count++;
		delete it;
		return count;
	}
};

MODULE = Tie::LevelDB		PACKAGE = Tie::LevelDB::DB

DB*
DB::new(char* name=NULL,HV* hv_options=Nullhv)

void
DB::Open(char* name,HV* hv_options=Nullhv)

void
DB::DESTROY()

void
DB::Put(char* key,char* value=NULL)

SV* 
DB::Get(const char * key)

void
DB::Delete(char * key)

Iterator*
DB::NewIterator(HV* hv_read_options=Nullhv);
	CODE:
		const char* CLASS = "Tie::LevelDB::Iterator";
		RETVAL = THIS->NewIterator(hv_read_options);
	OUTPUT:
		RETVAL

void
DB::Write(WriteBatch* batch, HV* hv_write_options=Nullhv)

MODULE = Tie::LevelDB		PACKAGE = Tie::LevelDB::WriteBatch

WriteBatch*
WriteBatch::new()

void
WriteBatch::Put(const char* key,const char* value)

void
WriteBatch::Delete(const char* key)

void
WriteBatch::DESTROY()

MODULE = Tie::LevelDB		PACKAGE = Tie::LevelDB::Iterator

Iterator*
Iterator::new()

void
Iterator::DESTROY()

void
Iterator::Seek(SV* sv_target)

void
Iterator::SeekToFirst()

void
Iterator::SeekToLast()

void
Iterator::Prev()

void
Iterator::Next()

bool
Iterator::Valid()

SV*
Iterator::key()

SV*
Iterator::value()

MODULE = Tie::LevelDB		PACKAGE = Tie::LevelDB

LevelDB*
LevelDB::new()

SV* 
LevelDB::FETCH(SV* key)

void
LevelDB::STORE(SV* sv_key,...)
	CODE:
		if(SvOK(ST(2))) THIS->STORE(sv_key,ST(2));
				   else THIS->DELETE(sv_key);

void
LevelDB::DELETE(SV* sv_key)

void
LevelDB::CLEAR()

bool
LevelDB::EXISTS(SV* sv_key)

SV*
LevelDB::FIRSTKEY()

SV*
LevelDB::NEXTKEY(SV* sv_lastkey)

int
LevelDB::SCALAR()

void
LevelDB::DESTROY()

LevelDB*
TIEHASH(const char* CLASS,const char* name,HV* hv_options=Nullhv)
  CODE:
    RETVAL = new LevelDB(name,hv_options);
  OUTPUT:
    RETVAL


