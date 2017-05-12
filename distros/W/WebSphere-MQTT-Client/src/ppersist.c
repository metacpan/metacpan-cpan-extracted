/*
 * Persistence wrapper interface - provide callbacks to a Perl object
 *
 * Brian Candler <B.Candler@pobox.com>
 */

/*
 * FIXME: Is newSVuv() guaranteed to handle all values of 'unsigned long'?
 * If not, what should we use? Probably not an issue, since mspscada.c says:
 *  "Conversion from u_long to u_short is ok as a key greater
 *   than can be accomodated by u_short is never used."
 */

/*
 * FIXME: we don't arrange in any special way for the 'persist' object
 * we are passed not to be garbage-collected. With our implementation
 * of WebSphere::MQTT::Client this isn't a problem, since $self->{'persist'}
 * holds a reference to this object as well, but this could be tidied up.
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "MQIsdp.h"

static int pstOpen(void *pUserData, char *pClientId, char *pBroker, int port)
{
    dSP ;
    int count, rc ;

    ENTER ;
    SAVETMPS ;

    PUSHMARK(SP);
    XPUSHs((SV*)pUserData);
    XPUSHs(sv_2mortal(newSVpv(pClientId, 0)));
    XPUSHs(sv_2mortal(newSVpv(pBroker, 0)));
    XPUSHs(sv_2mortal(newSViv(port)));
    PUTBACK ;

    count = call_method("open", G_SCALAR);

    SPAGAIN ;

    if (count != 1)
        croak("open must return one value");

    rc = POPi;

    PUTBACK ;
    FREETMPS ;
    LEAVE ;
    return rc;
}

static int Close(void *pUserData, const char *method)
{
    dSP ;
    int count, rc ;

    ENTER ;
    SAVETMPS ;

    PUSHMARK(SP);
    XPUSHs((SV*)pUserData);
    PUTBACK ;

    count = call_method(method, G_SCALAR);

    SPAGAIN ;

    if (count != 1)
        croak("%s must return one value", method);

    rc = POPi;

    PUTBACK ;
    FREETMPS ;
    LEAVE ;
    return rc;
}

static int pstClose(void *pUserData)
{
    return Close(pUserData, "close");
}

static int pstReset(void *pUserData)
{
    return Close(pUserData, "reset");
}

/* NOTE: there seems to be nothing in the spec which says the restored
 * data must be kept in the same order as it was saved. The method is
 * expected to return [key,value,key,value...] but this could just be
 * a flattened form of a hash
 */

static int GetAllMessages(void *pUserData, int *numMsgs,
  MQISDP_PMSG **pMsgs, const char *method)
{
    dSP ;
    int count ;
    static MQISDP_PMSG *msgs = NULL;  /* should store in pUserData hash? */

    *numMsgs = 0;
    *pMsgs = NULL;
    
    ENTER ;
    SAVETMPS ;

    PUSHMARK(SP);
    XPUSHs((SV*)pUserData);
    PUTBACK ;

    count = call_method(method, G_ARRAY);

    SPAGAIN ;

    if (count % 2)
        croak("%s must return even number of values", method);

    count /= 2;
    if (count > 0) {
        if (msgs) free(msgs);
        msgs = malloc(count * sizeof(MQISDP_PMSG));
        if (!msgs) croak("out of memory in %s", method);

        *numMsgs = count;
        *pMsgs = msgs;

        while(count--) {
            SV *val = POPs;
            SV *key = POPs;
            char *val1, *val2;
            STRLEN len;
            
            val1 = SvPV(val, len);
            val2 = malloc(len);
            if (!val2) croak("out of memory in %s", method);
            
            msgs[count].key = SvUV(key);
            if (msgs[count].key <= 0)
                warn("Invalid key in %s!", method);
            memcpy(val2, val1, len);
            msgs[count].length = len;
            msgs[count].pWmqttMsg = val2;
        }
    }

#if 0
    fprintf(stderr, "%s: *numMsgs = %d\n", method, *numMsgs);
    for (count=0; count < *numMsgs; count++) {
        int i;
        fprintf(stderr, "Key: %ld\nValue:", msgs[count].key);
        for (i=0; i<msgs[count].length; i++)
            fprintf(stderr, " %02X", msgs[count].pWmqttMsg[i]);
        fprintf(stderr, "\n");
    }
#endif

    PUTBACK ;
    FREETMPS ;
    LEAVE ;
    return 0;
}

static int pstGetAllReceivedMessages(void *pUserData, int *numMsgs,
  MQISDP_PMSG **pMsgs)
{
    return GetAllMessages(pUserData, numMsgs, pMsgs, "getAllReceivedMessages");
}

static int pstGetAllSentMessages(void *pUserData, int *numMsgs,
  MQISDP_PMSG **pMsgs)
{
    return GetAllMessages(pUserData, numMsgs, pMsgs, "getAllSentMessages");
}

static int AddMessage(void *pUserData, unsigned long key,
  int msgLength, char *pWmqttMsg, const char *method)
{
    dSP ;
    int count, rc ;

    ENTER ;
    SAVETMPS ;

    PUSHMARK(SP);
    XPUSHs((SV*)pUserData);
    XPUSHs(sv_2mortal(newSVuv(key)));
    XPUSHs(sv_2mortal(newSVpvn(pWmqttMsg, msgLength)));
    PUTBACK ;

    count = call_method(method, G_SCALAR);

    SPAGAIN ;

    if (count != 1)
        croak("%s must return one value", method);

    rc = POPi;

    PUTBACK ;
    FREETMPS ;
    LEAVE ;
    return rc;
}

static int pstAddSentMessage(void *pUserData, unsigned long key,
  int msgLength, char *pWmqttMsg)
{
   return AddMessage(pUserData, key, msgLength, pWmqttMsg, "addSentMessage");
}

static int pstUpdSentMessage(void *pUserData, unsigned long key,
  int msgLength, char *pWmqttMsg)
{
   return AddMessage(pUserData, key, msgLength, pWmqttMsg, "updSentMessage");
}

static int DelMessage(void *pUserData, unsigned long key, const char *method)
{
    dSP ;
    int count, rc ;

    ENTER ;
    SAVETMPS ;

    PUSHMARK(SP);
    XPUSHs((SV*)pUserData);
    XPUSHs(sv_2mortal(newSVuv(key)));
    PUTBACK ;

    count = call_method(method, G_SCALAR);

    SPAGAIN ;

    if (count != 1)
        croak("%s must return one value", method);

    rc = POPi;

    PUTBACK ;
    FREETMPS ;
    LEAVE ;
    return rc;
}

static int pstDelSentMessage(void *pUserData, unsigned long key)
{
    return DelMessage(pUserData, key, "delSentMessage");
}

static int pstAddReceivedMessage(void *pUserData, unsigned long key,
  int msgLength, char *pWmqttMsg)
{
   return AddMessage(pUserData, key, msgLength, pWmqttMsg, "addReceivedMessage");
}

static int pstUpdReceivedMessage(void *pUserData, unsigned long key)
{
    return DelMessage(pUserData, key, "updReceivedMessage");
}

static int pstDelReceivedMessage(void *pUserData, unsigned long key)
{
    return DelMessage(pUserData, key, "delReceivedMessage");
}

MQISDP_PERSIST *new_persistence_wrapper(SV *object)
{
    MQISDP_PERSIST *p = malloc(sizeof (MQISDP_PERSIST));
    if (!p) croak("new_persistence_wrapper out of memory");
    p->pUserData = (void*)object;
    p->open = pstOpen;
    p->close = pstClose;
    p->reset = pstReset;
    p->getAllReceivedMessages = pstGetAllReceivedMessages;
    p->getAllSentMessages = pstGetAllSentMessages;
    p->addSentMessage = pstAddSentMessage;
    p->updSentMessage = pstUpdSentMessage;
    p->delSentMessage = pstDelSentMessage;
    p->addReceivedMessage = pstAddReceivedMessage;
    p->updReceivedMessage = pstUpdReceivedMessage;
    p->delReceivedMessage = pstDelReceivedMessage;
    return p;
}

