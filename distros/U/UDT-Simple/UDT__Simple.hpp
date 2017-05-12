#include <udt.h>
#include <arpa/inet.h>
#include <string.h>
using namespace std;
struct addr {
    sockaddr_in sa;
    int namelen;
};
class UDT__Simple {
public:
    int _domain;
    int _type;
    UDTSOCKET _socket;
    struct addr _addr;
    UDT__Simple(int domain, int type) {
        this->_domain = domain;
        this->_type = type;
        this->_socket = UDT::socket(this->_domain, this->_type, 0);
        if (this->_socket == UDT::INVALID_SOCK)
            croak(UDT::getlasterror().getErrorMessage());
        if (UDT::startup() == UDT::ERROR)
            croak(UDT::getlasterror().getErrorMessage());
    }
    ~UDT__Simple() {
        this->close();
    }
    void close() {
        UDT::close(this->_socket);
    }
    struct addr resolve(char *ip, short port,int domain) {
        if (ip == NULL)
            croak("ip cannot be  NULL");
        struct addr n;
        struct hostent * phe;
        memset(&n,0,sizeof(n));

        n.sa.sin_family = this->_domain;
        n.sa.sin_port = htons(port);
        if (inet_pton(domain, ip, &n.sa.sin_addr) != 1) {
            phe = gethostbyname(ip);
            if (!phe)
                croak("unable to resolve %s",ip);
            if (phe->h_addrtype != this->_domain)
                croak("resolved %d addrtype while UDP::Simple was constructed with: %d domain",phe->h_addrtype,this->_domain);
            if (phe->h_length > sizeof(n.sa.sin_addr))
                croak("gethostbyname -> h_length(%d) > sockaddr_in.sin_addr(%d)",phe->h_length,sizeof(n.sa.sin_addr));
            memcpy(&n.sa.sin_addr,phe->h_addr,phe->h_length);
        }
        n.namelen = sizeof(n.sa);
        return n;
    }
    void bind(char *ip,short port) {
        this->_addr = resolve(ip,port,this->_domain);
        if (UDT::bind(this->_socket, (sockaddr*)&this->_addr.sa, this->_addr.namelen) == UDT::ERROR)
            croak(UDT::getlasterror().getErrorMessage());
    }
    void connect(char *ip, short port) {
        this->_addr = resolve(ip,port,this->_domain);
        if (UDT::connect(this->_socket, (sockaddr*)&this->_addr.sa, this->_addr.namelen) == UDT::ERROR)
            croak(UDT::getlasterror().getErrorMessage());

    }
    UDT__Simple *accept(void) {
        UDT__Simple *r = new UDT__Simple(this->_domain,this->_type);
        r->_socket = UDT::accept(this->_socket, (sockaddr*)&r->_addr.sa, &r->_addr.namelen);
        return r;
    }
#define SET_OR_CROAK(opt,value)                                         \
    do {                                                                \
        if (UDT::ERROR == UDT::setsockopt(this->_socket, 0, opt, &value, sizeof(value))) \
            croak(UDT::getlasterror().getErrorMessage());               \
    } while(0);
    void listen(int backlog) {
        UDT::listen(this->_socket, backlog);
    }
    void udt_sndbuf(int value) {
        SET_OR_CROAK(UDT_SNDBUF,value);
    }
    void udt_rcvbuf(int value) {
        SET_OR_CROAK(UDT_RCVBUF,value);
    }
    void udp_sndbuf(int value) {
        SET_OR_CROAK(UDP_SNDBUF,value);
    }
    void udp_rcvbuf(int value) {
        SET_OR_CROAK(UDP_RCVBUF,value);
    }
    void udt_rcvtimeo(int value) {
        SET_OR_CROAK(UDT_RCVTIMEO,value);
    }
    void udt_sndtimeo(int value) {
        SET_OR_CROAK(UDT_SNDTIMEO,value);
    }
#undef SET_OR_CROAK
    int send(SV *data, int offset = 0) {
        STRLEN len;
        char *ptr;
        ptr = SvPV(data, len);
        if (len == 0 || offset >= len)
            return 0;
        int rc;
        if (this->_type == SOCK_DGRAM)
            rc = UDT::sendmsg(this->_socket, ptr + offset, len - offset);
        else
            rc = UDT::send(this->_socket, ptr + offset, len - offset,0);
        if (rc == UDT::ERROR)
            croak(UDT::getlasterror().getErrorMessage());
        if (rc == 0)
            croak("send timed out");
        return rc;
    }

    SV *recv(int bytes) {
        char *buf = (char *)malloc(bytes);
        int rc;
        if (this->_type == SOCK_DGRAM)
            rc = UDT::recvmsg(this->_socket, buf, bytes);
        else
            rc = UDT::recv(this->_socket, buf, bytes, 0);
        if (rc == UDT::ERROR)
            die(UDT::getlasterror().getErrorMessage());
        if (rc == 0)
            croak("recv timed out");
        SV *out = newSVpv(buf,bytes);
        free(buf);
        return out;
    }
};
