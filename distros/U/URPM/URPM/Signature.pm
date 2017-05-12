package URPM;

use strict;
use warnings;
# perl_checker: require URPM

#- parse from rpmlib db.
#-
#- side-effects: $urpm
sub parse_pubkeys {
    my ($urpm, %options) = @_;

    my $db = $options{db};
    $db ||= URPM::DB::open($options{root}) or die "Can't open RPM DB, aborting\n";
    my @keys = parse_pubkeys_($db);

    $urpm->{keys}{$_->{id}} = $_ foreach @keys;
}
    
#- side-effects: none
sub parse_pubkeys_ {
    my ($db) = @_;
    
    my ($block, $content);
    my %keys;

    $db->traverse_tag('name', [ 'gpg-pubkey' ], sub {
	    my ($p) = @_;
            # the first blank separates the PEM headers from key data, this
            # flags we found it:
            my $found_blank = 0;
	    foreach (split "\n", $p->description) {
		if ($block) {
                    if (/^$/ && !$found_blank) {
                        # All content until now were the encapsulated pem
                        # headers...
                        $content = '';
                        $found_blank = 1;
                    }
                    elsif (/^-----END PGP PUBLIC KEY BLOCK-----$/) {
                        $keys{$p->version} = {
                            $p->summary =~ /^gpg\((.*)\)$/ ? (name => $1) : @{[]},
                            id => $p->version,
                            content => $content,
                            block => $p->description,
                        };
                        $block = undef;
                        $content = '';
                    }
                    else {
                        $content .= $_;
		    }
		}
		$block ||= /^-----BEGIN PGP PUBLIC KEY BLOCK-----$/;
	    }
	});

    values %keys;
}

#- obsoleted
sub import_needed_pubkeys() {
    warn "import_needed_pubkeys prototype has changed, please give a file directly\n";
    return;
}

#- import pubkeys only if it is needed.
sub import_needed_pubkeys_from_file {
    my ($db, $pubkey_file, $o_callback) = @_;

    my @keys = parse_pubkeys_($db);

    my $keyid = substr get_gpg_fingerprint($pubkey_file), 8;
    my ($kv) = grep { (hex($keyid) == hex($_->{id})) } @keys;
    my $imported;
    if (!$kv) {
	    if (!import_pubkey_file($db, $pubkey_file)) {
		#$urpm->{debug_URPM}("Couldn't import public key from ".$pubkey_file) if $urpm->{debug_URPM};
		$imported = 0;
	    } else {
		$imported = 1;
	    }
	    @keys = parse_pubkeys_($db);
	    ($kv) = grep { (hex($keyid) == hex($_->{id})) } @keys;
    }

    #- let the caller know about what has been found.
    #- this is an error if the key is not found.
    $o_callback and $o_callback->($kv ? $kv->{id} : undef, $imported);
}

1;
