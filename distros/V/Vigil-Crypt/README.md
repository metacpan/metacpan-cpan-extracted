# NAME

Vigil::Crypt

# SYNOPSIS

## Encryption/Decryption

        use Vigil::Crypt;

        my $crypt = Vigil::Crypt->new( ENCRYPTION_KEY );

        my $encrypted = $crypt->encrypt($plaintext_to_encrypt, $secret1, $secret2);

        my $decrypted = $crypt->decrypt($encrypted, $secret1, $secret2);

## Hashing

        use Vigil::Crypt;

        my $crypt = Vigil::Crypt->new( ENCRYPTION_KEY );

        my $stored_hash = $crypt->hash($password, $PEPPER);

        if( $crypt->verify_password($entered_password, $stored_hash, $PEPPER) ) {
                ... passwords match ...
        } else {
                ... passwords did not match. Do not pass go, do not collect $200 ...
        }

# DESCRIPTION

## Encryption/Decryption

The encrypt\_data and decrypt\_data methods handle sensitive information - like emails
or personal IDs - in a way that makes it extremely difficult for anyone without the
right keys to access. They use ChaCha20-Poly1305, a modern authenticated encryption
algorithm trusted in security-critical applications worldwide. Not only does this
algorithm scramble your data (encryption), it also includes a tag to ensure the data
hasn't been tampered with (authentication). The system also derives an additional
authenticated data (AAD) from user-specific information, which means even if someone
guesses part of the input, they still cannot decrypt the data without the full context.
For a newcomer, think of it as a strong lock on your secrets that refuses to open if
anything looks suspicious - all handled automatically for you.

`ChaCha20-Poly1305` is used for encryption/decryption because:

> \* Provides `authenticated encryption`, ensuring data confidentiality `and` integrity.
>
> \* Resistant to tampering: modifying the ciphertext or tag causes decryption to fail completely.
>
> \* Fast and efficient in software, especially on CPUs without dedicated AES hardware.
>
> \* Uses a 256-bit key, providing strong security against brute-force attacks.
>
> \* Includes a `nonce` to ensure the same plaintext encrypts differently each time.
>
> \* Supports `Additional Authenticated Data (AAD)`, allowing context-specific data to be protected without including it in the ciphertext.
>
> \* Widely standardized and recommended for modern secure communications.
>
> \* Constantly reviewed and trusted by the cryptography community.

## Hashing Passwords/Markers

Hashing is used for one-way protection, typically for passwords, but also for any
verification markers or tokens that need to be validated without storing the original
value. With hash and verify\_password, sensitive data is never stored directly - only
the hashed version. The module uses Argon2id, a state-of-the-art password hashing
function designed to resist brute-force attacks while being memory- and CPU-intensive
enough to slow down attackers. We also pre-hash the input with a pepper to add an
extra layer of security. verify\_password (or verify\_hash) lets you safely check
credentials or other verification markers: it confirms the input matches the stored
hash without ever exposing the original value. In short, it's like a magic 
fingerprint - you can confirm it, but nobody can reverse-engineer it.

`Argon2` is used for password hashing because:

> \* It requires a large amount of RAM to compute.
>
> \* GPU/ASIC attackers can't easily parallelize attacks because they run out of memory bandwidth.
>
> \* This makes brute-force attacks extremely expensive on specialized hardware.
>
> \* Resistant to Time-Memory Trade-Off (TMTO) attacks: attackers can't just reduce memory drastically without paying a huge time penalty.
>
> \* Built with side-channel resistance in mind.
>
> \* Future-proof against most foreseeable optimizations in hardware cracking.
>
> \* Included in RFC 9106 as the recommended password hashing scheme.
>
> \* Supported in libraries across most languages.
>
> \* Constantly reviewed by cryptography experts.

# CLASS METHODS

- $obj->new(encryption\_key => ENCRYPTION\_KEY);

    The constructor takes one argument and it is mandatory.

            use Vigil::Crypt;
            my $crypt = Vigil::Crypt->new( ENCRYPTION_KEY );
            

    The encryption key must be a 64-character string of hexadecimal digits, which corresponds
    to 32 bytes of binary data. This value must be stored somewhere permanent and should never
    change; if it does, all previously encrypted items would need to be re-encrypted. The
    recommended approach is to store the key in a configuration file above web-root level,
    which your program can then `require` to access the key.

    Here is a small script that you can run one time to generate a cryptographically secure encryption key:

            use strict;
            use warnings;
            use Bytes::Random::Secure qw(random_bytes);
            use MIME::Base16 qw(encode_base16);

            # Generate 32 random bytes
            my $key_bytes = random_bytes(32);

            # Convert to hex string (64 characters)
            my $key_hex = encode_base16($key_bytes);

            print "Random 32-byte key (hex): $key_hex\n";
            exit;
            

# OBJECT METHODS

## Encryption/Decryption

- $obj->last\_error;

            print $obj->last_error;
            

    If your attempts to encrypt or decrypt a value fail, then you can print out the contents of this method to see why.

- $obj->encrypt($value\_to\_encrypt, $user\_specific\_value\_1, $user\_specific\_value2);

            my $encrypted_data = $obj->encrypt($plaintext, $userid, $user_account_date);
            

    In my time developing things for the web (25+ years now), I've almost always used encryption with sensitive
    user information. This means that there has always been a user profile associated to the encrypted data. For
    this reason, I designed the encryption/decryption that could come directly from a user profile.

    In my case, every profile has an ID number (userid), and every profile will include a date that it was created (user\_account\_date).
    Those two pieces of information will never (should never) change for an account profile. So if I encrypt something today, those two
    pieces of information should still be identical ten years from now.

    The upside to this is that if the database table gets stolen, the bad-hat would only have the userid,
    they would not have the account creation date.

    The second upside to this is that if the bad-hat did decrypt the data for one user, that decryption would
    not work with any other user, as all user's profile ids and dates would be different.

    - userid

        Generally a sequence of digits, but it does not need to be. It just has to be unique to a user.

    - user\_account\_date

        This can be in any format: ymd, timestamp, seconds since epoch, etc.

    _In fact, you can use any kind of data you want for these two values, so long as those pieces of data are unique to the user._

            my $encrypted_data = $obj->encrypt($plaintext, $aad);
            

    If you have your own AAD, then you can pass that as a single argument.

    AAD (Additional Authenticated Data) - Think of it like a label on a locked box. The box (your encrypted data)
    can't be opened unless the label matches exactly what it was when the box was locked. It's extra info used
    to verify the data hasn't been tampered with, without being hidden inside the box itself. If you don't really
    know what AAD is or how to use it, stick with the two pieces of user information as arguments.

            my $encrypted_data = $obj->encrypt($plaintext);

    You CAN do this but you SHOULD NOT do this. When you pass the data to encrypt with no further arguments, the
    module will generate it's own AAD for that encryption. It will be the same AAD generated for anyone else, though,
    so you really do compromise the security you are trying to enable with encryption.

- $obj->decrypt($encrypted\_data, $user\_specific\_value\_1, $user\_specific\_value2);

            my $plaintext = $obj->decrypt($encrypted_data, $userid, $user_account_date);

    In this method, you are returning the encrypted text to plain text. The rules on arguments are the same as well.
    Remember that how you encrypt data (arguments supplied) must be the exact same way you decrypt data (arguments supplied).

## Hashing

- $obj->hash($password, $pepper);

    **IMPORTANT:** The hash method produces a 32-byte binary value. When creating your database
    column to store this value, define it as: `BINARY(32)`.

    The pepper is optional but strongly recommended. It is an additional secret mixed into the
    password before hashing, which makes brute-force attacks significantly harder. Because
    verification requires the same pepper used during hashing, it must be stored securely, 
    separate from the script - ideally in a configuration file above your web root or in a secure
    environment variable. You can generate a pepper in the same way you generate your encryption key.

    In short, the difference between an encryption key and a pepper is: the encryption key is 
    used to encrypt and decrypt data, while the pepper is used to strengthen password hashes.

- $obj->verify\_password($input\_pwd, $stored\_hashed\_pwd, $pepper);

            if($obj->verify_password($input_pwd, $stored_hashed_pwd, $pepper)) {
                ...password challenge was A-OK, do your stuff...
            } else {
                ...password challenge failed, go away!...
            }
            

    You need to pass the password being valided, then the password that was hashed and stored
    previously, and the pepper. Remember that the pepper for the original password and the
    validation method must be identical.

    _NOTE: This method can also be accessed as `$obj->verify_hash($compare_hash, $stored_hash, $pepper);`_

    Don't limit hashing to passwords. It can be used for one-way tokens or other verification
    markers. Let your imagination run rampant!

# ENCRYPTION LENGTHS

Knowing how long the final encryption will be is important when designing your
database tables. The formula to calculate the length of encrypted values is:

        my $Base64_length = 4 * ceil(($plaintext_bytes + 28) / 3);

Since Perl does not have a ceil() function, we would actually calculate it this way:

        my $Base64_length = 4 * int((($plaintext_bytes + 28) + 2) / 3);

Here are some prepresentative values to get you going:

        Plaintext   Encrypted Base64
         (bytes)      (Characters)
        16          4 * ceil((16 + 28)/3)   = 60
        32          4 * ceil((32 + 28)/3)   = 80
        64          4 * ceil((64 + 28)/3)   = 123
        100         4 * ceil((100 + 28)/3)  = 172
        256         4 * ceil((256 + 28)/3)  = 372
        512         4 * ceil((512 + 28)/3)  = 688
        1000        4 * ceil((1000 + 28)/3) = 1376
        2500        4 * ceil((2500 + 28)/3) = 3352
        5000        4 * ceil((5000 + 28)/3) = 6712

## Local Installation

If your host does not allow you to install from CPAN, then you can install this module locally two ways:

- Same Directory

    In the same directory as your script, create a subdirectory called "Vigil". Then add these two lines, in this order, to your script:

            use lib '.';           # Add current directory to @INC
            use Vigil::Crypt;      # Now Perl can find the module in the same dir
            
            #Then call it as normal:
            my $crypt = Vigil::Crypt->new( ENCRYPTION_KEY );

- In a different directory

    First, create a subdirectory called "Vigil" then add it to `@INC` array through a `BEGIN{}` block in your script:

            #!/usr/bin/perl
            BEGIN {
                push(@INC, '/path/on/server/to/Vigil');
            }
            
            use Vigil::Crypt;
            
            #Then call it as normal:
            my $crypt = Vigil::Crypt->new( ENCRYPTION_KEY );

# AUTHOR

Jim Melanson (jmelanson1965@gmail.com).

Created: October, 2018.

Last Update: August 2025.

License: Use it as you will, and don't pretend you wrote it - be a mensch.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING
BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
