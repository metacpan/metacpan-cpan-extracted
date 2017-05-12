package Test::HTTP::Syntax;
use warnings;
use strict;

=head1 NAME

Test::HTTP::Syntax - HTTP tests in a natural style.

=head1 SYNOPSIS

  use Test::HTTP::Syntax;
  use Test::HTTP tests => 9;

or

  use Test::HTTP '-syntax', tests => 9;

then

  test_http 'echo test' {
      >> GET /echo/foo
      >> Accept: text/plain

      << 200
      ~< Content-type: ^text/plain\b
      <<
      << foo
  }


=head1 DESCRIPTION

L<Test::HTTP::Syntax> is a source filter module designed to work with
L<Test::HTTP>.  It provides a simple, linewise syntax for specifying HTTP
tests in a way that looks a lot like HTTP request and response packets.

All this module does is translate the linewise packet syntax into calls to
L<Test::HTTP>.

The actual module used for the tests can be set by setting the variable
C<$Test::HTTP::Syntax::Test_package>.  It defaults to C<Test::HTTP>.

=head1 SYNTAX

=head2 test_http block

L<Test::HTTP::Syntax> only filters sections of code which are delimited by a
C<test_http> block.

  test_http TEST_NAME {
      # Code to be filtered
      # ...
  }

This gets translated into

  {
      my $test = Test::HTTP->new(TEST_NAME);
      # Filtered code
      # ...
  }

=head2 REQUESTS

A request packet consists of a REQUEST START line, 0 or more REQUEST HEADER
lines, and an optional REQUEST BODY.  The packet ends when a blank line is
encountered.

The presence of a REQUEST packet only constructs the request within C<$test>.
The request does not get run unless a RESPONSE packet is encountered or
C<< $test->run_request() >> is called explicitly.

=head3 REQUEST START

This line marks the start of a request block.

  >> METHOD URI

C<METHOD> is one of C<GET>, C<PUT>, C<POST>, C<HEAD>, or C<DELETE>, and C<URI>
is a URI.  This line is followed by 0 or more REQUEST HEADERS, and then
optionally a REQUEST BODY.

=head3 REQUEST HEADER

  >> HEADER: VALUE

This sets the value of an HTTP request header.

=head3 REQUEST BODY

  >>
  >> body line 1
  >> body line 2

This sets the contents of the body of the HTTP packet.

=head2 RESPONSES

A response packet consists of a RESPONSE START line, 0 or more LITERAL or
REGEX RESPONSE HEADER lines, and an optional RESPONSE BODY.

The start of a response packet triggers the execution of the pending request,
and starts testing the response received therefrom.

=head3 RESPONSE START

  << NNN

C<NNN> is a 3-digit HTTP response code which we expect to receive.

=head3 LITERAL RESPONSE HEADER

  << HEADER: VALUE

Performs a literal match on the value of the C<HEADER> header in the HTTP
response packet.

=head3 REGEX RESPONSE HEADER

  ~< HEADER: REGEX

Performs a regular expression match on the value of C<HEADER> against the
REGEX qr{REGEX}.

=head3 RESPONSE BODY

  <<
  << body line 1
  << body line 2

Performs a literal match on the given body with the body of the HTTP response
packet.

=cut

use Filter::Simple;
use Text::Balanced ':ALL';

our $Test_package = 'Test::HTTP';

FILTER {
    my $result;
    my $n;

    while ($_) {
        if (s/^\s*test_http\s+(.*?)\s+{/{/) {
            my $name = $1;
            my $block;
            ($block, $_) = extract_bracketed($_, '{}');
            $result .= filter_block( $name, $block );
        }
        else {
            s/^.*\n//;
            $result .= "$&\n";
        }
    }

    $_ = $result;
};

# The current state of the input block is kept in @lines, while output is
# built in $result.  When filter_block finds the start of a request, it passes
# off to filter_request, and when it finds the start of a response
# specification, it passes it off to filter_response.
#
# Each of these two, in turn, is a linewise finite state machine.
{
    # This quells the warning from using a 'last' to exit a 'while_line' loop.
    no warnings 'exiting';

    my @lines;
    my $result;

    sub while_line(&) {
        my ( $coderef ) = @_;

        while (defined(local $_ = shift @lines)) { $coderef->() }
    }

    sub filter_block {
        my ( $name, $block ) = @_;

        $block =~ s{^\{\n}
{\{
    my \$test = $Test_package->new($name);
};
        $block =~ s/\}\z//;

        $result = '';
        @lines = split /\n/, $block;
        while_line {
            if (/^\s*>> /) {
                unshift @lines, $_;
                filter_request();
            }
            elsif (/^\s*<< /) {
                unshift @lines, $_;
                filter_response();
            }
            else {
                $result .= "$_\n";
            }
        };

        $result .= "}\n";

        return $result;
    }

    sub filter_request {
        my $state = 'first line';
        my @body;

        while_line {
            next if /^\s*#/;
            if ( $state eq 'first line' ) {
                /^\s*>> (\S+) (.*)/
                    or die "unparseable first request line: '$_'\n";
                $result .= "    \$test->new_request($1 => \"$2\");\n";
                $state = 'in request';
            }
            elsif ( $state eq 'in request' ) {
                if (/^\s*>>\s*$/) {
                    $state = 'in body';
                }
                elsif (/^\s*>> ([A-Za-z-]+): (.*)/) {
                    $result
                        .= "    \$test->request->header(\"$1\" => \"$2\");\n";
                }
                elsif (/^\s*$/) {
                    $result .= "$_\n";
                    last;
                }
                else {
                    die "unparseable line in request: '$_'\n";
                }
            }
            elsif ( $state eq 'in body' ) {
                if (/^\s*>> (.*)/) {
                    push @body, $1;
                } elsif (/^\s*$/) {
                    $result .= "$_\n";
                    last;
                }
                else {
                    die "unparseable line in request body: '$_'\n";
                }
            }
        };
        if (@body) {
            my $body = join "\n", @body;
            $result .= <<END_OF_CODE;
    {
        local \$_ = <<END_OF_BODY;
$body
END_OF_BODY
        s/\\n\\z//g; # Remove newline before END_OF_BODY marker.
        \$test->request->content( \$_ );
    }
END_OF_CODE
        }
    }

    sub filter_response {
        my $state = 'first line';
        my @body_exact;
        my @body_res;

        while (defined(local $_ = shift @lines)) {
            next if /^\s*#/;
            if ($state eq 'first line') {
                /^\s*<< (\d+)\s*$/
                    or die "unparseable first response line: '$_'\n";
                $result .= "    \$test->run_request();\n";
                $result .= "    \$test->status_code_is($1);\n";
                $state = 'in header';
            }
            elsif ($state eq 'in header') {
                if (/^\s*<< ([A-Za-z-]+): (.*)/) {
                    $result .= "    \$test->header_is( \"$1\", \"$2\" );\n";
                }
                elsif (/^\s*~< ([A-Za-z-]+): (.*)/) {
                    $result .= "    \$test->header_like( \"$1\", qr{$2} );\n";
                }
                elsif (/^\s*<<\s*$/) {
                    $state = 'in body';
                }
                elsif (/^\s*$/) {
                    $result .= "$_\n";
                    last;
                }
                else {
                    die "unparseable line in response header: '$_'\n";
                }
            }
            elsif ($state eq 'in body') {
                if (/^\s*<< (.*)/) {
                    push @body_exact, $1;
                }
                elsif (/^\s*~< (.*)/) {
                    push @body_res, $1;
                }
                elsif (/^\s*$/) {
                    $result .= "$_\n";
                    last;
                }
                else {
                    die "unparseable line in response body: '$_'\n";
                }
            }
        }

        if (@body_exact && @body_res) {
            die "Can't have both regexes and exact matches for the body.\n";
        }
        elsif (@body_exact) {
            my $body = join "\n", @body_exact;
            $result .= <<END_OF_CODE;
    {
        local \$_ = <<END_OF_BODY;
$body
END_OF_BODY
        s/\\n\\z//g;
        \$test->body_is( \$_ );
    }
END_OF_CODE
        }
        elsif (@body_res) {
            foreach (@body_res) {
                $result .= "    \$test->body_like(qr{$_});\n";
            }
        }
    }
}

=head1 SEE ALSO

L<http://www.w3.org/Protocols/rfc2616/rfc2616.html>,
L<Test::HTTP>

=head1 AUTHOR

Socialtext, Inc. C<< <code@socialtext.com> >>

=head1 COPYRIGHT & LICENSE

Copyright 2006 Socialtext, Inc., all rights reserved.

Same terms as Perl.

=cut

1;
