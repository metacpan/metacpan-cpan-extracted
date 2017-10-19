MODULE = ZMQ::Raw               PACKAGE = ZMQ::Raw::Z85

SV *
encode (class, decoded)
	SV *class
	SV *decoded

	PREINIT:
		SV *encoded;
		int size;

	CODE:
		if (SvCUR (decoded)%4)
			croak_usage ("decoded length must be divisible by 4");

		encoded = sv_2mortal (newSV ((SvCUR (decoded)*4)/3+1));
		SvPOK_on (encoded);
		SvCUR_set (encoded, (SvCUR (decoded)*4)/3);

		if (zmq_z85_encode (SvPVX (encoded), (const uint8_t *)SvPVX (decoded), SvCUR (decoded)) == NULL)
			croak_usage ("encode failed");

		SvREFCNT_inc (encoded);
		RETVAL = encoded;

	OUTPUT: RETVAL

SV *
decode (class, encoded)
	SV *class
	SV *encoded

	PREINIT:
		SV *decoded;

	CODE:
		if (SvCUR (encoded)%5)
			croak_usage ("encoded length must be divisible by 5");

		decoded = sv_2mortal (newSV ((SvCUR (encoded)*4)/5+1));
		SvPOK_on (decoded);
		SvCUR_set (decoded, (SvCUR (encoded)*4)/5);

		if (zmq_z85_decode ((uint8_t *)SvPVX (decoded), SvPVX (encoded)) == NULL)
			croak_usage ("decode failed");

		SvREFCNT_inc (decoded);
		RETVAL = decoded;

	OUTPUT: RETVAL

