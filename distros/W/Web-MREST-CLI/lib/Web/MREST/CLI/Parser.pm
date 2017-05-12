# ************************************************************************* 
# Copyright (c) 2014-2015-2015, SUSE LLC
# 
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# 
# 1. Redistributions of source code must retain the above copyright notice,
# this list of conditions and the following disclaimer.
# 
# 2. Redistributions in binary form must reproduce the above copyright
# notice, this list of conditions and the following disclaimer in the
# documentation and/or other materials provided with the distribution.
# 
# 3. Neither the name of SUSE LLC nor the names of its contributors may be
# used to endorse or promote products derived from this software without
# specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
# ************************************************************************* 
#
# parser module
#
package Web::MREST::CLI::Parser;

use 5.012;
use strict;
use warnings;

use App::CELL qw( $CELL $log );
use Test::Deep::NoTest;
use Web::MREST::CLI qw( send_req );

our $anything = qr/^.+$/i;

=head1 NAME

Web::MREST::CLI::Parser - Parser for demo MREST command line client




=head1 SYNOPSIS

    use Try::Tiny;
    
    my $status;
    my @tokens = split /\s+/, 'MY SAMPLE COMMAND';
    try { 
        Web::MREST::CLI::Parse::parse_tokens( [], \@tokens ); 
    } catch { 
        $status = $_; 
    };




=head1 CLI COMMANDS

The parsing of CLI commands takes place in the C<parse_tokens> function,
which calls itself recursively until it gets to a rather macabre-sounding

    die send_req . . .

This causes control to return to the while loop in C<bin/mrest-cli> with the
return value of the C<send_req>, which is a status object.

All tokens should be chosen to be distinguishable by their first
three characters.

=cut

my $method; # store the HTTP method in a package variable so it is remembered

sub parse_tokens {
    my ( $pre, $tokens ) = @_; 
    return $CELL->status_err( "No more tokens" ) unless ref $tokens;
    my @tokens = @$tokens;
    my $token = shift @tokens;

    # the first token designates the HTTP method
    if ( @$pre == 0 ) { # first token is supposed to be the HTTP method

        # GET ''
        if ( $token =~  m/^GET/i ) {
            $method = 'GET';
            parse_tokens( [ 'GET' ], \@tokens ) if @tokens;
            die send_req( 'GET', '' );
        }

        # PUT ''
        elsif ( $token =~ m/^PUT/i ) {
            $method = 'PUT';
            parse_tokens( [ 'PUT' ], \@tokens ) if @tokens;
            die send_req( 'PUT', '' );
        } 
        
        # POST ''
        elsif ( $token =~ m/^POS/i ) {
            $method = 'POST';
            parse_tokens( [ 'POST' ], \@tokens ) if @tokens;
            die send_req( 'POST', '' );
        } 
        
        # DELETE ''
        elsif ( $token =~ m/^DEL/i ) {
            $method = 'DELETE';
            parse_tokens( [ 'DELETE' ], \@tokens ) if @tokens;
            die send_req( 'DELETE', '' );
        }

        # EXIT, QUIT, and the like
        elsif ( $token =~ m/^(exi)|(qu)|(\\q)/i and eq_deeply( $pre, [] ) ) { 
            die $CELL->status_ok( 'MREST_CLI_EXIT' );
        }   

        die $CELL->status_err( 'MREST_CLI_PARSE_ERROR' );
    }

    # second token represents the resource class ( top-level, employee, priv, etc.)
    if ( @$pre == 1 ) {

        #
        # root resource
        #
        if ( $token eq '/' ) {
            die send_req( $method, '/' );
        }

        #
        #
        # top-level resource: handle it here
        #
        # "/bugreport"
        if ( $token =~ m/^bug/i ) {
            die send_req( $method, 'bugreport' );
        }

        # "/configinfo"
        if ( $token =~ m/^con/i ) {
            die send_req( $method, 'configinfo' );
        }

        # "/docu/{pod,html,text} \"$RESOURCE'""
        if ( $token =~ m/^doc/i ) { 
            if ( @tokens ) {
                my $pod_html = shift @tokens;
                my $json = join( ' ', @tokens );
                if ( $json ) {
                    $json = '"' . $json . '"' unless $json =~ m/^".*"$/;
                    if ( $pod_html =~ m/^pod/i ) {
                        die send_req( $method, 'docu/pod', $json );
                    } elsif ( $pod_html =~ m/^htm/i ) {
                        die send_req( $method, 'docu/html', $json );
                    } elsif ( $pod_html =~ m/^tex/i ) {
                        die send_req( $method, 'docu/text', $json );
                    } 
                } else {
                    print "You should specify a resource\n";
                }
            } else {
                die send_req( $method, 'docu' );
            }
        }   

        # "/echo [$JSON]"
        if ( $token =~ m/^ech/i ) { 
            die send_req( $method, 'echo', join(' ', @tokens) );
        }   

        # "/noop"
        if ( $token =~ m/^noo/i ) {
            die send_req( $method, "noop" );
        }

        # "/param $TYPE $JSON"
        # "/param/:type/:param"
        if ( $token =~ m/^par/i ) {
            if ( scalar( @tokens ) > 1 ) {
                my $type = $tokens[0];
                my $param = $tokens[1];
                my $json = join( ' ', @tokens[2..$#tokens] );
                die send_req( $method, "param/$type/$param", $json );
            }
        }
    
        # "/test/?:specs"
        if ( $token =~ m/^tes/i ) {
            my $uri_path;
            if ( @tokens ) {
                my $uri_ext .= join( ' ', @tokens ) if @tokens;
                $uri_path = "test/$uri_ext";
            } else {
                $uri_path = "test";
            }
            die send_req( $method, $uri_path );
        }

        # "/version"
        if ( $token =~ m/^ver/i and eq_deeply( $pre, [ $method ] ) ) {
            die send_req( $method, 'version' );
        }   

    }

    # we have gone all the way through the state machine without a match
    die $CELL->status_err( 'MREST_CLI_PARSE_ERROR' );
}

1;
