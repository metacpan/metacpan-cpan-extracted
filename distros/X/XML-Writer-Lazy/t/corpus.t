#!perl

use strict;
use warnings;

use Test::More;
use Test::Differences;
use XML::SemanticDiff;

use File::Find;
use XML::Writer::Lazy;

my @corpus;
find(\&wanted, 't/corpus/');
sub wanted { push(@corpus, $File::Find::name) if m/\.xml$/ }

@corpus = @ARGV if @ARGV;

my $diff = XML::SemanticDiff->new();

for my $test ( sort @corpus ) {
    note( $test );
    open( my $fh, '<', $test ) || die "Can't open [$test] for reading $!";
    my $input = join '', <$fh>;
    close $fh;

    my $lazy = XML::Writer::Lazy->new( OUTPUT => 'self', ENCODING => 'utf-8' );
    $lazy->lazily( $input );
    my $output = $lazy->to_string;
    utf8::encode( $output );

    my $errors = '';
    foreach my $change ($diff->compare($input, $output)) {
        $errors .= "$change->{message} in context $change->{context}\n";
    }

    if ( $errors ) {
        diag( $errors );
        eq_or_diff_text( $output, $input, $test );
    } else {
        pass( $test );
    }

}

# There appears to be some kind of cleanup issue without this
undef($diff);

done_testing();
