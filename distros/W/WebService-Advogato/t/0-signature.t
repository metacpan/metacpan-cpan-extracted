use Test::More tests => 1;

SKIP: {
    if (!eval { require Module::Signature; 1 }) {
        skip("Next time around, consider install Module::Signature, ".
             "so you can verify the integrity of this distribution.", 1);
    }
    elsif (!eval { require Socket; Socket::inet_aton('wwwkeys.pgp.net') }) {
        skip("Cannot connect to the keyserver", 1);
    }
    else {
        ok(Module::Signature::verify() == Module::Signature::SIGNATURE_OK()
            => "Valid signature" );
    }
}
