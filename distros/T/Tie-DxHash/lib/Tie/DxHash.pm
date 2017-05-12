# $Id $
# $Revision 1.03 $

package Tie::DxHash;

use warnings;
use strict;
use base qw(Tie::Hash);

use Tie::Hash;

our $VERSION = '1.03';

sub CLEAR {
    my ($self) = @_;

    my $test;

    $self->{data}        = [];
    $self->{iterators}   = {};
    $self->{occurrences} = {};
    $self->_ckey(0);

    return $self;
}

sub DELETE {
    my ( $self, $key ) = @_;

    my $offset           = 0;
    my @deleted_elements = ();

ELEMENT:
    while ( $offset < @{ $self->{data} } ) {
        if ( $key eq $self->{data}[$offset]{key} ) {
            push @deleted_elements, $self->{data}[$offset]{value};
            splice @{ $self->{data} }, $offset, 1;
        }
        else {
            $offset++;
        }
    }

    delete $self->{iterators}{$key};
    delete $self->{occurrences}{$key};

    return \@deleted_elements;
}

sub EXISTS {
    my ( $self, $key ) = @_;

    return exists $self->{occurrences}{$key};
}

sub FETCH {
    my ( $self, $key ) = @_;

    my ($dup) = 1;

HASH_KEY:
    foreach my $offset ( 0 .. @{ $self->{data} } - 1 ) {
        next HASH_KEY if $key ne $self->{data}[$offset]{key};
        next HASH_KEY if $dup++ != $self->{iterators}{$key};
        $self->{iterators}{$key}++;

        if ( $self->{iterators}{$key} > $self->{occurrences}{$key} ) {
            $self->{iterators}{$key} = 1;
        }

        return $self->{data}[$offset]{value};
    }

    return;
}

sub FIRSTKEY {
    my ($self) = @_;

    $self->_ckey(0);
    return $self->NEXTKEY;
}

sub NEXTKEY {
    my ($self) = @_;

    my ($ckey) = $self->_ckey;

    if ( $ckey == @{ $self->{data} } ) {
        return;
    }
    else {
        $self->_ckey( $ckey + 1 );
        return $self->{data}[$ckey]{key};
    }
}

sub SCALAR {
    my ($self) = @_;

    my $hash_size = 0;

HASH_KEY:
    foreach my $key ( keys %{ $self->{occurrences} } ) {
        $hash_size += $self->{occurrences}{$key};
    }

    return $hash_size;
}

sub STORE {
    my ( $self, $key, $value ) = @_;

    push @{ $self->{data} }, { key => $key, value => $value };
    $self->{iterators}{$key} ||= 1;
    $self->{occurrences}{$key}++;

    return $self;
}

sub TIEHASH {
    my ( $class, @args ) = @_;

    my ($self);

    $self = {};
    bless $self, $class;

    $self->_init(@args);
    return $self;
}

sub _ckey {
    my ( $self, $ckey ) = @_;

    if ( defined $ckey ) {
        $self->{ckey} = $ckey;
    }
    return $self->{ckey};
}

sub _init {
    my ( $self, @args ) = @_;

    $self->CLEAR;

    while ( my ( $key, $value ) = splice @args, 0, 2 ) {
        $self->STORE( $key, $value );
    }

    return $self;
}

1;    # Magic true value required at end of module
__END__

=head1 NAME

Tie::DxHash - keeps insertion order; allows duplicate keys


=head1 VERSION

This document describes Tie::DxHash version 1.03


=head1 SYNOPSIS

    use Tie::DxHash;
    my(%vhost);
    tie %vhost, 'Tie::DxHash' [, LIST];
    %vhost = (
        ServerName  => 'foo',
        RewriteCond => 'bar',
        RewriteRule => 'bletch',
        RewriteCond => 'phooey',
        RewriteRule => 'squelch',
    );


=head1 DESCRIPTION

This  module was  written to     allow the  use of    rewrite  rules in   Apache
configuration  files written with Perl Sections.   However, a potential user has
stated that he  needs it to support  the use of  multiple ScriptAlias directives
within a single Virtual Host  (which is required by  FrontPage, apparently).  If
you find a completely different use for it, great.

The original purpose of this  module is not quite  so obscure as it might sound.
Perl Sections   bring the power   of a general-purpose  programming  language to
Apache configuration files and,  having  used them  once,  many people use  them
throughout.  (I take this approach since, even  in sections of the configuration
where  I do  not need  the  flexibility, I find  it  easier to use  a consistent
syntax.  This also makes the code easier for XEmacs to  colour in ;-) Similarly,
mod_rewrite is easily the most powerful way to  perform URL rewriting and I tend
to use it  exclusively, even when a  simpler directive  would  do the  trick, in
order to group my redirections together and keep them consistent.  So, I came up
against the following problem quite early on.

The synopsis  shows  some syntax which  might  be needed when using  mod_rewrite
within a  Perl Section.  Clearly,  using an ordinary hash will   not do what you
want.  The two additional features we  need are to  preserve insertion order and
to allow  duplicate keys.   When retrieving an  element from  the hash by  name,
successive requests for the same name must iterate through the duplicate entries
(and,  presumably, wrap around when  the end of  the chain is reached).  This is
where Tie::DxHash  comes   in.   Simply  by  tying   the  offending   hash,  the
corresponding configuration directives work as expected.

Running an Apache syntax  check (with docroot check)  on your configuration file
(with C<httpd -t>) and checking virtual host settings (with C<httpd -S>) succeed
without complaint.   Incidentally,  I  strongly recommend building   your Apache
configuration files with make (or equivalent) in  order to enforce the above two
checks, preceded by a Perl syntax check (with C<perl -cx>).


=head1 SUBROUTINES/METHODS

This module   is  intended to be   called  through Perl's   tie  interface.  For
reference, the following methods have been defined:

    CLEAR
    DELETE
    EXISTS
    FETCH
    FIRSTKEY
    NEXTKEY
    SCALAR
    STORE
    TIEHASH

=head1 DIAGNOSTICS

None.


=head1 CONFIGURATION AND ENVIRONMENT

Tie::DxHash requires no configuration files or environment variables.


=head1 DEPENDENCIES

None.


=head1 INCOMPATIBILITIES

None reported.


=head1 INTERNALS

For those interested, Tie::DxHash works by storing the  hash data in an array of
hash references  (containing  the key/value  pairs).  This  preserves  insertion
order.  A separate set  of iterators (one per  distinct key) keeps track of  the
last retrieved value for a given key, thus  allowing the successive retrieval of
multiple values for the same key to work as expected.


=head1 BUGS AND LIMITATIONS

The algorithms used to retrieve and delete elements by  key run in O(N) time, so
do not expect  this  module to work well   on large data  sets.   This is not  a
problem for the module's intended  use.  If you find  another use for the module
which involves larger quantities of data, let me know and I will put some effort
into optimising for speed.

The  mod_rewrite  directives for  which   this module  was   written  (primarily
RewriteCond and RewriteRule) can  occur in all  four configuration file contexts
(i.e. server config,  virtual host, directory, .htaccess).  However, Tie::DxHash
only helps when  you are using  a directive which  is mapped  onto a  Perl hash.
This limits you to  directives which are block  sections with begin and end tags
(like  <VirtualHost>  and  <Directory>).   I  get  round  this  by   sticking my
mod_rewrite directives in  a name-based virtual host container  (as shown in the
synopsis) even in the degenerate case where the  web server only has one virtual
host.


=head1 SEE ALSO

perltie(1), for information on ties generally.

Tie::IxHash(3), by Gurusamy Sarathy, if you need to preserve insertion order but
not allow duplicate keys.

For   information  on  Ralf S.  Engelschall's   powerful  URL  rewriting module,
mod_rewrite,      check       out     the      reference      documentation   at
"http://httpd.apache.org/docs/mod/mod_rewrite.html" and  the URL Rewriting Guide
at "http://httpd.apache.org/docs/misc/rewriteguide.html".

For help in using Perl Sections to configure Apache,  take a look at the section
called           "Apache        Configuration      in            Perl"        at
"http://perl.apache.org/guide/config.html#Apache_Configuration_in_Perl", part of
the mod_perl    guide, by Stas Bekman.    Alternatively,  buy the  O'Reilly book
Writing Apache Modules with Perl and C, by Lincoln  Stein & Doug MacEachern, and
study Chapter 8: Customizing the Apache Configuration Process.


=head1 AUTHOR

Kevin Ruscoe  C<< <kevin@sapphireoflondon.org> >>


=head1 LICENSE AND COPYRIGHT

Copyright (c) 2006, Kevin Ruscoe C<< <kevin@sapphireoflondon.org> >>. All rights
reserved.

This module is free software; you can redistribute it and/or modify it under the
same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE  OF CHARGE, THERE IS  NO WARRANTY FOR THE
SOFTWARE,  TO THE EXTENT  PERMITTED  BY  APPLICABLE LAW.  EXCEPT WHEN  OTHERWISE
STATED IN  WRITING  THE  COPYRIGHT  HOLDERS  AND/OR  OTHER  PARTIES  PROVIDE THE
SOFTWARE "AS  IS" WITHOUT WARRANTY  OF ANY  KIND,  EITHER EXPRESSED OR  IMPLIED,
INCLUDING, BUT NOT  LIMITED TO, THE   IMPLIED WARRANTIES OF MERCHANTABILITY  AND
FITNESS  FOR  A  PARTICULAR PURPOSE.  THE  ENTIRE  RISK AS  TO THE  QUALITY  AND
PERFORMANCE OF THE  SOFTWARE IS WITH  YOU. SHOULD THE SOFTWARE  PROVE DEFECTIVE,
YOU ASSUME THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED  BY APPLICABLE LAW OR AGREED  TO IN WRITING WILL ANY
COPYRIGHT HOLDER,   OR ANY OTHER PARTY  WHO  MAY MODIFY  AND/OR REDISTRIBUTE THE
SOFTWARE  AS  PERMITTED BY THE  ABOVE  LICENCE,  BE LIABLE   TO YOU FOR DAMAGES,
INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
OF THE USE OR INABILITY TO  USE THE SOFTWARE  (INCLUDING BUT NOT LIMITED TO LOSS
OF DATA OR DATA  BEING RENDERED INACCURATE OR LOSSES  SUSTAINED BY YOU  OR THIRD
PARTIES OR A FAILURE OF THE SOFTWARE  TO OPERATE WITH  ANY OTHER SOFTWARE), EVEN
IF SUCH HOLDER  OR  OTHER PARTY HAS   BEEN  ADVISED OF THE POSSIBILITY   OF SUCH
DAMAGES.
