# NAME

Vigil::Token - Cryptographically secure, URL-safe token generator for OTPs, sessions, and custom codes.

# SYNOPSIS

>     EXAMPLE 1.
>     #!/user/bin/perl
>         
>     use Vigil::Token;
>     my $token = Vigil::Token->new;
>         
>     my $session_token = $token->custom_token(256);
>         
>     my $short_token = $token->custom_token(12);
>         
>     my $some_token = $token->(16);    #An alias for $token->custom_token(16);
>         
>     my $digits_be_6_for_otp = $token->otp(6);

# DESCRIPTION

Vigil::Token is a sleek, high-octane token generator that effortlessly handles both human-friendly codes and 
machine-to-machine secrets. Need a short, 6-digit OTP that users can type without mistaking a 0 for an O? 
Done. Looking for a massive, 256-character session token to lock down API calls or web sessions? Done. 
Every token is backed by cryptographically strong randomness using Bytes::Random::Secure, ensuring each 
byte of entropy is truly unpredictable. All strings are automatically URL-safe via Base64URL encoding, 
so they slide seamlessly into cookies, query strings, or HTML forms without worrying about escaping. With 
its flexible custom\_token() function, Vigil::Token balances readability and security perfectly: short codes 
are human-friendly, long codes maximize entropy, and all tokens are guaranteed to be the exact length you 
request. Lightweight, reliable, and unrelentingly secure, Vigil::Token is the ultimate Swiss Army knife for 
modern web authentication and cryptographic token needs.

## OBJECT METHODS

- my $one\_time\_password = $obj->otp( LENGTH )

    Returns a string of digits only. Will return up to 12 digits as specified by LENGTH.

- $obj->custom\_token( LENGTH );

    Returns a string that is automatically URL-safe via Base64URL encoding. The number of characters in the string is determined by LENGTH.

## Local Installation

If your host does not allow you to install from CPAN, then you can install this module locally two ways:

- Same Directory

    In the same directory as your script, create a subdirectory called "Vigil". Then add these two lines, in this order, to your script:

            use lib '.';           # Add current directory to @INC
            use Vigil::Token;      # Now Perl can find the module in the same dir
            
            #Then call it as normal:
            my $token = Vigil::Token->new;

- In a different directory

    First, create a subdirectory called "Vigil" then add it to `@INC` array through a `BEGIN{}` block in your script:

            #!/usr/bin/perl
            BEGIN {
                    push(@INC, '/path/on/server/to/Vigil');
            }
            
            use Vigil::Token;
            
            #Then call it as normal:
            my $token = Vigil::Token->new;

# AUTHOR

Jim Melanson (jmelanson1965@gmail.com).

Created: July, 2017.

Last Update: August 2025.

License: Use it as you will, and don't pretend you wrote it - be a mensch.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING
BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
