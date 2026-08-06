use strict;
use warnings;
use Test::More;

# README is generated from the module's POD by a rule in Makefile.PL, whose
# comment says the two "cannot drift". They did: `git archive` stamps every
# file with the same mtime, so make's `README : lib/Text/Stencil.pm` dependency
# never fires in a fresh checkout, and three rounds of POD corrections shipped
# in a tarball whose README still described the old behaviour -- including
# telling the reader that a crash we had just fixed was unavoidable. The rule
# is only as good as the timestamps; this checks the actual bytes.

plan skip_all => 'README/POD not both present' unless -f 'README' && -f 'lib/Text/Stencil.pm';

eval { require Pod::Text; 1 } or plan skip_all => 'Pod::Text not available';

my $generated = '';
{
    open my $fh, '>', \$generated or die "in-memory open: $!";
    # same settings as the Makefile.PL rule
    Pod::Text->new(sentence => 0, width => 78)->parse_from_file('lib/Text/Stencil.pm', $fh);
    close $fh;
}

my $shipped = do {
    open my $fh, '<', 'README' or die "README: $!";
    local $/;
    <$fh>;
};

# Compare content, not layout: Pod::Text has rewrapped and requoted C<> across
# versions before, and a spurious failure on one CI perl would be worse than
# the drift this guards against.
sub canon {
    my $s = shift;
    $s =~ tr/"//d;          # C<> quoting differs between Pod::Text versions
    $s =~ s/\s+/ /g;
    $s =~ s/^ | $//g;
    return $s;
}

is canon($shipped), canon($generated),
    'README is current with the POD it is generated from'
    or diag "Regenerate it with:\n"
          . "  perl -MPod::Text -e 'Pod::Text->new(sentence => 0, width => 78)"
          . "->parse_from_file(\@ARGV)' lib/Text/Stencil.pm README";

done_testing;
