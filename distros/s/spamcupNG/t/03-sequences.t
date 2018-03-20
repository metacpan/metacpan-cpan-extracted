use warnings;
use strict;
use Test::More;
use SpamcupNG;
use File::Spec;
use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init($WARN);

my $base = File::Spec->catdir( ( 't', 'responses' ) );

is( SpamcupNG::_check_next_id(
        read_html( File::Spec->catfile( $base, 'after_login.html' ) )
    ),
    'z6444645586z5cebd61f7e0464abe28f045afff01b9dz',
    'got the expected next SPAM id'
);

is( SpamcupNG::_check_error(
        read_html( File::Spec->catfile( $base, 'failed_load_header.html' ) )
    ),
    'Failed to load spam header: 64446486 / cebd6f7e464abe28f4afffb9d',
    'get the expected error'
);

is( SpamcupNG::_check_error(
        read_html( File::Spec->catfile( $base, 'mailhost_problem.html' ) )
    ),
    'Mailhost configuration problem, identified internal IP as source',
    'get the expected error'
);

done_testing;

sub read_html {
    my $html_file = shift;
    open( my $in, '<', $html_file ) or die "Cannot read $html_file:$!";
    local $/ = undef;
    my $content = <$in>;
    close($in);

    #$content =~ tr/015//d;
    return \$content;
}

