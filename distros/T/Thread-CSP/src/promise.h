struct promise;

struct promise* S_promise_alloc(pTHX_ UV);
#define promise_alloc(count) S_promise_alloc(aTHX_ count)
SV* S_promise_get(pTHX_ struct promise* promise);
#define promise_get(promise) S_promise_get(aTHX_ promise)
void S_promise_set_value(pTHX_ struct promise* promise, SV* value);
#define promise_set_value(promise, value) S_promise_set_value(aTHX_ promise, value)
void S_promise_set_exception(pTHX_ struct promise* promise, SV* value);
#define promise_set_exception(promise, exception) S_promise_set_exception(aTHX_ promise, exception)
bool promise_is_finished(struct promise*);
void S_promise_refcount_dec(pTHX_ struct promise* promise);
#define promise_refcount_dec(promise) S_promise_refcount_dec(aTHX_ promise)
SV* S_promise_finished_fh(pTHX_ struct promise* promise);
#define promise_finished_fh(promise) S_promise_finished_fh(aTHX_ promise)

extern const MGVTBL Thread__CSP__Promise_magic;
