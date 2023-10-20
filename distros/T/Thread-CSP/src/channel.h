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

#define channel_new(class) channel_alloc(1)

extern const MGVTBL Thread__CSP__Channel_magic;
