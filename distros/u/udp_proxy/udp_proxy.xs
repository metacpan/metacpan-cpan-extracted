/* @(#) perl binding for udpxy
 *
 * Copyright 2008-2013 Pavel V. Cherenkov (pcherenkov@gmail.com) (pcherenkov@gmail.com)
 * Copyright 2011-2015 Leandr Khaliullov (leandr@cpan.org) (leandr@cpan.org)
 *
 *  This file is not part of udpxy.
 *
 *  udpxy is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  udpxy is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with udpxy.  If not, see <http://www.gnu.org/licenses/>.
 */

#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

#include "ppport.h"
#include "udpxy.h"
#include "netop.h"
#include "uopt.h"
#include "ifaddr.h"
#include "util.h"
#include "dpkt.h"

struct udpxy_opt	g_uopt;
extern const char	IPv4_ALL[];
extern FILE*  g_flog;
extern volatile sig_atomic_t g_quit;

/* calculate values for:
 *  1. number of messages to fit into data buffer
 *  2. recommended (minimal) size of socket buffer
 *     (to read into the data buffer)
 */
static int
calc_buf_settings( ssize_t* bufmsgs, size_t* sock_buflen )
{
	ssize_t nmsgs = -1, max_buf_used = -1, env_snd_buflen = -1;
	size_t buflen = 0;

	/* how many messages should we process? */
	nmsgs = (g_uopt.rbuf_msgs > 0) ? g_uopt.rbuf_msgs :
			 (int)g_uopt.rbuf_len / ETHERNET_MTU;

	/* how many bytes could be written at once
		* to the send socket */
	max_buf_used = (g_uopt.rbuf_msgs > 0)
		? (ssize_t)(nmsgs * ETHERNET_MTU) : g_uopt.rbuf_len;
	if (max_buf_used > g_uopt.rbuf_len) {
		max_buf_used = g_uopt.rbuf_len;
	}

	assert( max_buf_used >= 0 );

	env_snd_buflen = get_sizeval( "UDPXY_SOCKBUF_LEN", 0);
	buflen = (env_snd_buflen > 0) ? (size_t)env_snd_buflen : (size_t)max_buf_used;

	if (buflen < (size_t) MIN_SOCKBUF_LEN) {
		buflen = (size_t) MIN_SOCKBUF_LEN;
	}

	/* cannot go below the size of effective usage */
	if( buflen < (size_t)max_buf_used ) {
		buflen = (size_t)max_buf_used;
	}

	if (bufmsgs) *bufmsgs = nmsgs;
	if (sock_buflen) *sock_buflen = buflen;

	return 0;
}

/* return 1 if the application must gracefully quit
 */
sig_atomic_t must_quit() { return g_quit; }

/* renew multicast subscription if g_uopt.mcast_refresh seconds
 * have passed since the last renewal
 */
static void
check_mcast_refresh( int msockfd, time_t* last_tm,
					 const struct in_addr* mifaddr )
{
	time_t now = 0;

	if( NULL != g_uopt.srcfile ) /* reading from file */
		return;

	assert( (msockfd > 0) && last_tm && mifaddr );
	now = time(NULL);

	if( now - *last_tm >= g_uopt.mcast_refresh ) {
		(void) renew_multicast( msockfd, mifaddr );
		*last_tm = now;
	}

	return;
}

class udp_proxy {

private:
	struct in_addr		mcast_inaddr;
	char				mcast_addr[ IPADDR_STR_SIZE ];
	int					dfilefd;
	FILE*				mlog;
	
	void setError( const char *error_msg ) {
		SV *error = get_sv( "!", FALSE );
		
		sv_setpv( error, error_msg );
	}
	
	ssize_t my_writev( const struct iovec *iov, int iovcnt )
	{
		int i, r;
		char *p;
		ssize_t l, sum;

		sum = 0;
		for( i = 0; i < iovcnt; i++ ) {
			p = ( char * )iov[i].iov_base;
			l = iov[i].iov_len;
			while( l > 0 ) {
				r = PerlIO_write( PerlIO_stdout(), p, l );
				if (r <= 0) {
					return r;
				}
				p += r;
				l -= r;
				sum += r;
			}
		}
		return sum;
	}
	
	ssize_t my_write_buf( const char* data, const ssize_t len )
	{
		ssize_t n = 0, nwr = 0, error = IO_ERR;

		for( n = 0; errno = 0, n < len ; ) {
			nwr = PerlIO_write( PerlIO_stdout(), &( data[ n ] ), len - n );
			if( nwr <= 0 ) {
				if( EINTR == errno ) {
					continue;
				} else {
					if( EAGAIN == errno )
						error = IO_BLK;
						break;
				}
			}

			n += nwr;
		}

		if( nwr <= 0 ) {
			return error;
		}

		return n;
	}
	
	ssize_t my_write_data( const struct dstream_ctx* spc, const char* data, const ssize_t len )
	{
		ssize_t n = 0, error = IO_ERR;
		int32_t n_count = -1;

		if( spc->flags & F_SCATTERED ) {
			n_count = spc->pkt_count;
			n = this->my_writev( spc->pkt, n_count );
			if( n <= 0 ) {
				if( EAGAIN == errno ) {
					error = IO_BLK;
				}
				return error;
			}
		} else {
			n = this->my_write_buf( data, len );
			if( n < 0 )
				error = n;
		}

		return ( n > 0 ) ? n : error;
	}

	int relay_traffic( int ssockfd, const struct in_addr* mifaddr, const char *proto ) {
		volatile sig_atomic_t quit = 0;
		int		rc = 0;
		ssize_t	nmsgs = -1;
		ssize_t	nrcv = 0, nsent = 0, nwr = 0,
			lrcv = 0, lsent = 0;
		char*	data = NULL;
		size_t	data_len = g_uopt.rbuf_len;
		struct rdata_opt ropt;
		time_t pause_time = 0, rfr_tm = time( NULL );

		const int ALLOW_PAUSES = get_flagval( "UDPXY_ALLOW_PAUSES", 0 );
		static const ssize_t t_delta = 0x20;

		struct dstream_ctx ds;
		lrcv = t_delta - t_delta + lsent;

		check_fragments( NULL, 0, 0, 0, 0, g_flog );

		/* INIT */

		rc = calc_buf_settings( &nmsgs, NULL );
		
		if( 0 != rc )
			return -1;
			
		rc = init_dstream_ctx( &ds, proto, NULL, nmsgs );
		if( 0 != rc )
			return -1;
		
		( void )set_nice( g_uopt.nice_incr, g_flog );

		do {
			data = ( char * )malloc( data_len );

			if( NULL == data ) {
				break;
			}

		} while( 0 );

		/* RELAY LOOP */
		ropt.max_frgs = g_uopt.rbuf_msgs;
		ropt.buf_tmout = g_uopt.dhold_tmout;

		pause_time = 0;

		while( ( 0 == rc ) && !( quit = must_quit() ) ) {
			if( g_uopt.mcast_refresh > 0 ) {
				check_mcast_refresh( ssockfd, &rfr_tm, mifaddr );
			}

			nrcv = read_data( &ds, ssockfd, data, data_len, &ropt );
			if( -1 == nrcv )
				break;

			lrcv = nrcv;

			if(  ( nrcv > 0 ) ) {
				if( dfilefd ) {
					nsent = write_data( &ds, data, nrcv, dfilefd );
				} else {
					nsent = this->my_write_data( &ds, data, nrcv );
				}
				if( -1 == nsent )
					break;

				lsent = nsent;
			}

			if( ds.flags & F_SCATTERED )
				reset_pkt_registry( &ds );

		} /* end of RELAY LOOP */

		free_dstream_ctx( &ds );
		if( NULL != data )
			free( data );

		return 0;
	}

public:
	// constructor
	udp_proxy( HV* hash = NULL ) {
		char*				key, * val_pv;
		I32					keylen;
		SV*					val;
		STRLEN				val_length;
		PerlIO*				handle = NULL, *log = NULL;

		int					rc = 0;
		rc = init_uopt( &g_uopt );
		struct stat sb;

		if( rc ) {
			setError( "Unable to init default parameters" );
			return;
		}
		if( hash == NULL ) {
			setError( "Missing mandatory hash structure" );
			return;
		} else {
			hv_iterinit( hash );
			while( ( val = hv_iternextsv( hash, &key, &keylen ) ) ) {
				if( strcasecmp( key, "interface" ) == 0 ) {
					val_pv = SvPV( val, val_length );
					rc = get_ipv4_address( val_pv, mcast_addr, sizeof( mcast_addr ) );
					if( 0 != rc ) {
						setError( "Invalid interface/address" );
					}
				} else if( strcasecmp( key, "log" ) == 0 ) {
					if( SvTYPE( val ) == SVt_PVGV ) {
						log = IoOFP( GvIO( val ) );
					} else if( SvTYPE( val ) == SVt_IV && SvTYPE( SvRV( val ) ) == SVt_PVGV ) {
						log = IoOFP( GvIO( SvRV( val ) ) );
					} else if( SvTYPE( val ) == SVt_PV ) {
						val_pv = SvPV( val, val_length );
						log = PerlIO_open( val_pv, "w" );
						if( log == Nullfp ) {
							croak( "Unable to open log file\n" );
						}
					}
				} else if( strcasecmp( key, "handle" ) == 0 ) {
					if( SvTYPE( val ) == SVt_PVGV ) {
						handle = IoOFP( GvIO( val ) );
					} else if( SvTYPE( val ) == SVt_IV && SvTYPE( SvRV( val ) ) == SVt_PVGV ) {
						handle = IoOFP( GvIO( SvRV( val ) ) );
					} else if( SvTYPE( val ) == SVt_PV ) {
						val_pv = SvPV( val, val_length );
						handle = PerlIO_open( val_pv, "w" );
						if( handle == Nullfp ) {
							croak( "Unable to open output file %s\n", val_pv );
						}
					}
				}
			}
		}
		if( '\0' == mcast_addr[0] ) {
			( void ) strncpy( mcast_addr, IPv4_ALL, sizeof( mcast_addr ) - 1 );
		}
		if( 1 != inet_aton( mcast_addr, &mcast_inaddr ) ) {
			setError( "Unable to get multicast address" );
		}
		if( !log ) {
			log = PerlIO_open( "/dev/null", "w" );
		}
		g_flog = PerlIO_exportFILE( log, 0 );
		setvbuf( g_flog, NULL, _IONBF, 0 );
		if( handle ) {
			dfilefd = PerlIO_fileno( handle );
		} else {
			dfilefd = 0;
		}
	}

	void interruption() {
		g_quit = ( sig_atomic_t )1;
	}

	int do_relay( const char *proto, const char *host, int port ) {
		struct sockaddr_in addr;
		int			rc = 0;
		size_t		rcvbuf_len = 0;
		int			msockfd = -1;

		do {
			if( 1 != inet_aton( host, &addr.sin_addr ) ) {
				rc = ERR_INTERNAL;
				break;
			}
			addr.sin_family = AF_INET;
			addr.sin_port = htons( ( short )port );
		} while( 0 );

		if( 0 != rc )
			return 0;

		do {
			rc = calc_buf_settings( NULL, &rcvbuf_len );
			if ( 0 == rc ) {
				rc = setup_mcast_listener( &addr, &mcast_inaddr, &msockfd, ( g_uopt.nosync_sbuf ? 0 : rcvbuf_len ) );
			}
			if( 0 != rc ) break;
			rc = relay_traffic( msockfd, &mcast_inaddr, proto ); 
		} while( 0 );
		if( msockfd > 0 ) {
			close_mcast_listener( msockfd, &mcast_inaddr );
		}
	}

	// destructor
	~udp_proxy() {
		free_uopt( &g_uopt );
	}
};

MODULE = udp_proxy		PACKAGE = udp_proxy

PROTOTYPES: ENABLE

#udp_proxy *
#udp_proxy::new( HV * hash = NULL )

udp_proxy *
constructor( char * CLASS, HV * hash = NULL )
	CODE:
		RETVAL = new udp_proxy( hash );
	OUTPUT:
		RETVAL

void
udp_proxy::DESTROY()

void
udp_proxy::interruption()

int
udp_proxy::do_relay( const char *proto, const char *host, int port )
