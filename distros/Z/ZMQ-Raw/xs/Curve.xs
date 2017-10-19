MODULE = ZMQ::Raw               PACKAGE = ZMQ::Raw::Curve

void
keypair (class)
	SV *class

	PREINIT:
		int rc, ctx;
		SV *public_key, *private_key;

	PPCODE:
		ctx = GIMME_V;

		if (ctx == G_VOID)
			XSRETURN_EMPTY;

		public_key = sv_2mortal (newSV (41));
		private_key = sv_2mortal (newSV (41));
		SvPOK_on (public_key);
		SvPOK_on (private_key);
		SvCUR_set (public_key, 40);
		SvCUR_set (private_key, 40);

		rc = zmq_curve_keypair (SvPVX (public_key), SvPVX (private_key));
		if (rc < 0)
			zmq_raw_check_error (rc);

		XPUSHs (private_key);
		if (ctx == G_ARRAY)
		{
			XPUSHs (public_key);
			XSRETURN (2);
		}

		XSRETURN (1);

SV *
public (class, private_key)
	SV *class
	SV *private_key

	PREINIT:
		int rc;
		SV *public_key;

	CODE:
		if (SvCUR (private_key) != 40)
			croak_usage ("private_key should be 40 bytes");

		public_key = sv_2mortal (newSV (41));
		SvPOK_on (public_key);
		SvCUR_set (public_key, 40);

		rc = zmq_curve_public (SvPVX (public_key), SvPVX (private_key));
		if (rc < 0)
			zmq_raw_check_error (rc);

		SvREFCNT_inc (public_key);
		RETVAL = public_key;

	OUTPUT: RETVAL

