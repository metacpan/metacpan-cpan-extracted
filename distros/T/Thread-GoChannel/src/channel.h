struct channel;

struct channel* S_channel_alloc(pTHX_ UV);
#define channel_alloc(refcount) S_channel_alloc(aTHX_ refcount)
void channel_send(struct channel* channel, SV* message);
SV* S_channel_receive(pTHX_ struct channel* channel);
#define channel_receive(channel) S_channel_receive(aTHX_ channel)
SV* S_channel_receive_ready_fh(pTHX_ struct channel*);
#define channel_receive_ready_fh(channel) S_channel_receive_ready_fh(aTHX_ channel)
SV* S_channel_send_ready_fh(pTHX_ struct channel*);
#define channel_send_ready_fh(channel) S_channel_send_ready_fh(aTHX_ channel)
void channel_close(struct channel*);

void S_channel_refcount_dec(pTHX_ struct channel* channel);
#define channel_refcount_dec(channel) S_channel_refcount_dec(aTHX_ channel)

SV* S_channel_to_sv(pTHX_ struct channel* channel, SV* stash_name);
#define channel_to_sv(channel, stash_name) S_channel_to_sv(aTHX_ channel, stash_name)
#define channel_new(class) channel_alloc(1)
struct channel* S_sv_to_channel(pTHX_ SV* sv);
#define sv_to_channel(sv) S_sv_to_channel(aTHX_ sv)

extern const MGVTBL Thread__GoChannel_magic;
