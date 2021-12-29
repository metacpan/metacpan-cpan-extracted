struct channel;
typedef struct channel Channel;

Channel* channel_alloc(UV);
void channel_send(Channel* channel, SV* message);
SV* S_channel_receive(pTHX_ Channel* channel);
#define channel_receive(channel) S_channel_receive(aTHX_ channel)
void S_channel_set_notify(pTHX_ Channel*, PerlIO*, SV*);
#define channel_set_notify(channel, handle, value) S_channel_set_notify(aTHX_ channel, handle, value)
void channel_close(Channel*);

void channel_refcount_dec(Channel* channel);

SV* S_channel_to_sv(pTHX_ Channel* channel, SV* stash_name);
#define channel_to_sv(channel, stash_name) S_channel_to_sv(aTHX_ channel, stash_name)
#define channel_new(class) channel_to_sv(channel_alloc(1), class)
Channel* S_sv_to_channel(pTHX_ SV* sv);
#define sv_to_channel(sv) S_sv_to_channel(aTHX_ sv)
