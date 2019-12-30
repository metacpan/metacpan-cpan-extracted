package URPM;

use strict;
use warnings;
# perl_checker: require URPM

=head1 NAME

URPM::Signature - Pubkey routines for URPM/urpmi

=head1 SYNOPSIS

=head1 DESCRIPTION

=over

=cut

=item parse_pubkeys($urpm, %options)

Parse from rpmlib db ("gpg-pubkey")

=cut

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

=item import_needed_pubkeys_from_file($db, $pubkey_file, $o_callback)

Import pubkeys from file, but only if it is needed.
Returns the return value of the optionnal callback.

The optional callback enables to handle success or error.

The callback signature is callback($id, $imported), aka the ID of the key and
whether it was imported or not.

=cut

sub import_needed_pubkeys_from_file {
    my ($db, $pubkey_file, $o_callback) = @_;

    my @keys = parse_pubkeys_($db);

    my $keyid = substr get_gpg_fingerprint($pubkey_file), 8;
    my ($kv) = grep { (hex($keyid) == hex($_->{id})) } @keys;
    my $imported;
    if (!$kv) {
	    $imported = import_pubkey_file($db, $pubkey_file);
	    @keys = parse_pubkeys_($db);
	    ($kv) = grep { (hex($keyid) == hex($_->{id})) } @keys;
    }

    #- let the caller know about what has been found.
    #- this is an error if the key is not found.
    $o_callback and $o_callback->($kv ? $kv->{id} : undef, $imported);
}

1;

__END__

=back
