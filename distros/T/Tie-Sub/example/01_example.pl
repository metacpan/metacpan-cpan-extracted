#!perl ## no critic (TidyCode)

use strict;
use warnings;

our $VERSION = 0;

use Tie::Sub;

# 1 parameter, 1 return
tie my %sprintf_04d, 'Tie::Sub', sub { sprintf '%04d', shift }; ## no critic (Ties)
() = print "See $sprintf_04d{4}, not $sprintf_04d{5} digits.\n\n";

# many parameters, 1 return
tie my %sprintf, 'Tie::Sub', sub {sprintf shift, shift}; ## no critic (Ties)
() = print "See $sprintf{ [ '%04d', 4 ] } digits.\n\n";

# many parameters, many return
tie my %sprintf_multi, 'Tie::Sub', sub { ## no critic (Ties)
    return
        ! @_
        ? q{}
        : @_ > 1
        ? [ map { sprintf "%04d\n", $_ } @_ ]
        : sprintf "%04d\n", shift;
};
{
    use English qw(-no_match_vars $LIST_SEPARATOR);

    local $LIST_SEPARATOR = q{};
    () = print <<"EOT";
See the following lines
scalar
$sprintf_multi{10}
arrayref
@{ $sprintf_multi{[20 .. 22]} }
and be lucky.

EOT
}

# method calls
my $cgi = CGI->new;
tie my %cgi, 'Tie::Sub', sub { ## no critic (Ties)
    my ($method, @params) = @_;

    my @result = $cgi->$method(@params);

    return
        ! @result
        ? ()
        : @result > 1
        ? \@result
        : $result[0];
};

() = print <<"EOT";
Hello $cgi{ [ param => 'firstname' ] } $cgi{ [ param => 'lastname' ] }!
EOT

# package simulation
package CGI;

sub new {
    return bless {}, shift;
}

sub param {
    my (undef, $name) = @_;

    return {
        firstname => 'Steffen',
        lastname  => 'Winkler',
    }->{$name};
}

# $Id$

__END__

Output:
See 0004, not 0005 digits.

See 0004 digits.

See the following lines
scalar
0010

arrayref
0020
0021
0022

and be lucky.

Hello Steffen Winkler!
