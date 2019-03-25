package winja;
use 5.018000;
use version;
our $VERSION = '1.0.3';

use utf8;

## define custom warn()
my $warn;

BEGIN {
    $warn = sub {
        my $message = shift;
        if ( $message && $message =~ m!\n\z! ) {
            CORE::warn $message;
        }
        else {
            my ( $pkg, $file, $line ) = caller();
            my $where = '';
            ( $pkg, $file, $line ) = caller(2)
                if $file eq __FILE__;
            if ( defined $file && defined $line ) {
                $where = qq{ at $file line $line.$/};
            }
            print STDERR $message, $where;
        }
    };
}

## check OS & Locale
BEGIN {
    #check OS
    if ( $^O ne 'MSWin32' ) {
        die __PACKAGE__ . qq{ supports "MSWin32 JApanese edition" only};
    }

    #check Locale if possible
    eval { require Win32::API; };
    if ( !$@ ) {
        my $ALLOWED_LOCALE_ID = 1041;    # e.g. Japanese_Japan.932
        my $got;
        eval {
            $got
                = Win32::API::More->new( 'kernel32',
                'unsigned short GetSystemDefaultLangID()' )->Call();
        };
        if ($@) {
            die $@;
        }
        if ( $got != $ALLOWED_LOCALE_ID ) {
            die __PACKAGE__
                . qq{ supports "MSWin32 JApanese edition" only\n}
                . qq{  Your LOCALE ID is $got, not $ALLOWED_LOCALE_ID.};
        }
    }
    else {
        $warn->(qq{Cannot decide your locale is really Japanese_Japan.932});
        die $@;
    }
}

use warnings;
use strict;

require Cwd;
require File::Spec;
require File::Basename;
use Encode;

BEGIN {

    {
        my $package = 'File::Spec::Functions';
        eval <<EOM;
        package ${package};
        winja->import(qw/:FileSpec/);
        1;
EOM
    }
    {

        package CORE::GLOBAL;
        no strict 'refs';
        1;
    }
}

my %tag;

my %override;

##[[[ Begining of Defining Override.

# Constants
my $pre_x5c_pat
    = qr/[\x81\x83\x84\x87 \x89-\x9F \xE0-\xEA \xED\xEE \xFA\xFB]/x;
my $x5c_pat      = qr/${pre_x5c_pat} \x5c/x;
my $x5c_end_pat  = qr/${x5c_pat} \z/x;
my $abs_path_pat = qr!\A (?:[a-zA-Z]:) [/\\]?!x;

# Declare 'normalize_if' class
my $normalize_class = qr/\A File::Path \z | \A Path::Class:: /x;

my $encobj = find_encoding('cp932')
    || die __PACKAGE__, ": encoding 'cp932' not found";

# decoder
my $dec = sub {
    return if !@_ + 0;
    my @args = map { utf8::is_utf8($_) ? $_ : $encobj->decode($_) } @_;
    return wantarray ? @args : $args[0];
};

# encoder
my $enc = sub {
    return if !@_ + 0;
    my @args = map { utf8::is_utf8($_) ? $encobj->encode($_) : $_ } @_;
    return wantarray ? @args : $args[0];
};

my $normalize = sub {
    return unless @_ + 0;
    my ($arg) = @_;
    return if !defined $arg;
    debugs("NORMALIZE: arg='$arg'");
    $arg = $dec->($arg);
    my $delim = $arg =~ /\\/?"\\":"/";
    $arg =~ s!\\!/!g;
    $arg = $enc->($arg);
    my @path = map { $_ =~ $x5c_end_pat ? $_ . q[.] : $_ }
        split '/', $arg, -1;
    my $result = join $delim, @path;
    debugs("NORMALIZE: result='$result'");
    return $result;
};

my $normalize_if = sub {
    return unless @_ + 0;
    my ($arg) = @_;
    debugs("NORMALIZE_IF: arg='$arg' ");
    my ($caller) = caller(2);
    return $enc->($arg) if !$caller || $caller !~ $normalize_class;
    my $normalized = $normalize->($arg);
    debugs("NORMALIZE_IF: $normalized: ");
    return $normalized;
};

## Original methods pool

my %org_methods;

## Override 'File::Basename'
{
    no strict 'refs';
    no warnings 'redefine';
    $org_methods{'File::Basename::fileparse'}
        = *{'File::Basename::fileparse'}{CODE};
    *{'File::Basename::fileparse'} = sub {
        my @args = $dec->(@_);
        my @resp = map { $normalize->($_) }
            $enc->( $org_methods{'File::Basename::fileparse'}->(@args) );
        debugs( qq{BASENAME:}, $resp[0], qq{, DIRNAME:}, $resp[1] );
        return wantarray ? @resp : $resp[0];
    };
}

## Override 'FileSpec'

require File::Spec;
require File::Spec::Win32;
my @ovr_methods = map { 'File::Spec::Win32::' . $_ }
    qw/_canon_cat splitpath splitdir catdir catfile canonpath/;
push @{ $tag{':FileSpec'} }, @ovr_methods;
push @{ $tag{':FileSpec'} }, 'Cwd::getcwd';    # for 'rel2abs'
{
    no strict 'refs';
    @org_methods{@ovr_methods} = map { *{$_}{CODE} } @ovr_methods;
}

# Override 'File::Spec::Win32' only when found valid encoding.

for my $method (@ovr_methods) {
    no strict 'refs';
    $override{$method} = eval qq`sub {
            my \$is_utf8 = utf8::is_utf8(join('',\@_));
            my \$mthd=\$org_methods{'$method'};
            goto \&{\$mthd} if \$is_utf8;
            goto \&{\$mthd} if qq{\@_} !~ \$x5c_pat;
            my \@arg = \$dec->(\@_);
            my \@resp = \$enc->(\&{\$mthd}(\@arg));
            return wantarray ? \@resp : \$resp[0];
        };`;
}

if ( ( eval { File::Spec::Win32->version } || 0 ) < 3.3 ) {
    push @{ $tag{':File::Spec'} }, 'File::Spec::canonpath';
    $override{'File::Spec::canonpath'} = sub {
        # Legacy / compatibility support
        return $_[1] if !defined( $_[1] ) or $_[1] eq '';
        return _canon_cat( $_[1] );
    };
}

## Override 'Cwd';
#  NOTE: fast*() is the same as *(), not "fast" anymore
push @{ $tag{':Cwd'} },
    map { 'Cwd::' . $_ }
    qw/cwd getcwd fastcwd fastgetcwd getdcwd abs_path realpath fast_abs_path/;
$override{'Cwd::cwd'} = $override{'Cwd::getcwd'}
    = $override{'Cwd::fastcwd'} = $override{'Cwd::fastgetcwd'} = sub {
    my $r = join '/', split "\\\\",
        decode( "cp932", File::Spec->rel2abs(".") );
    return encode( "cp932", $r );
    };
$override{'Cwd::getdcwd'} = sub {
    File::Spec->rel2abs(".");
};
$override{'Cwd::abs_path'} = $override{'Cwd::realpath'}
    = $override{'Cwd::fast_abs_path'} = sub {
    return unless @_ + 0;
    my $a = File::Spec->rel2abs(shift);
    return unless -e $a;
    $a = encode( "cp932", join '/', split "\\\\", decode( "cp932", $a ) )
        if -d $a;
    return $a;
    };
push @{ $tag{':Cwd'} }, 'Cwd::chdir';
$override{'Cwd::chdir'} = sub {
    my $res = CORE::chdir(shift);
    $ENV{'PWD'} = $override{'Cwd::getdcwd'}->();
    return $res;
};

##]]] End of Defining Override

## import/unimport

my $MGR = {};

my %init_done;
my %bitmask;
my $bits = 0;
@bitmask{ keys %override } = map { $bits <<= 1; $bits ||= 1; } keys %override;

my $init = sub {
    my ($key) = @_;
    return if !defined $key;
    return if !exists $override{$key};
    my @class = split '::', $key;
    my $name  = pop @class;
    if ( $key =~ /\A CORE::GLOBAL::/x ) {
        $MGR->{$key}->{self} = $override{$key};
    }
    else {
        $MGR->{$key}->{self} = sub {
            my $H;
            my $i = 0;
            $i++ while caller($i);
            while ( --$i >= 0 ) {
                my $h = ( caller($i) )[10];
                next if !$h;
                next if !exists $$h{ __PACKAGE__ . '' };
                $H = $$h{ __PACKAGE__ . '' };
                last;
            }
            goto &{ $override{$key} } if $H && $H & $bitmask{$key};
            goto &{ $MGR->{$key}->{saved} };
        };
    }
    $MGR->{$key}->{name}       = $name;
    $MGR->{$key}->{class}      = [@class];
    $MGR->{$key}->{saved}      = ( $org_methods{$key} || undef );
    $MGR->{$key}->{overridden} = 0;
    $init_done{$key}++;
};

my $make_classref = sub {
    return if !@_;
    no strict 'refs';
    my $self  = *main::;
    my @class = @_;
    for my $key (@class) {
        $self = ${$self}{ $key . '::' };
    }
    $self;
};

my $delete_sub_from = sub {
    return unless @_;
    my $sym = shift;
    no strict 'refs';
    return if !*{$sym}{CODE};
    my $self     = *{$sym}{CODE};
    my $classref = $make_classref->( @{ $MGR->{$sym}->{class} } );
    my $name     = $MGR->{$sym}->{name};
    my @refs     = grep {$_} map { *{$sym}{$_} } qw/SCALAR ARRAY HASH IO/;
    delete ${$classref}{$name};
    *{$sym} = $_ for @refs;
    return $self;
};

my $tags2keys = sub {
    my @invalid = grep { !exists $tag{$_} } @_;
    if (@invalid) {
        require Carp;
        Carp::croak( "Invalid tag '", join( "', '", @invalid ), "'" );
    }
    my (@tags) = @_;
    @tags = keys %tag if !@tags;
    my %seen;
    my @keys = grep { !$seen{$_}++ } map { @{ $tag{$_} } } @tags;
    no strict 'refs';
    no warnings 'once';
    @keys = grep { /\A CORE::GLOBAL::/x || *{$_}{CODE} } @keys;
    return @keys;
};

my $load = sub {
    my ($key) = @_;
    $init->($key) if !$MGR->{$key};
    die "Undefined flag of '$key'" if !exists $bitmask{$key};
    return if ( $^H{ __PACKAGE__ . '' } ||= 0 ) & $bitmask{$key};
    $^H{ __PACKAGE__ . '' } |= $bitmask{$key};
    no strict 'refs';
    no warnings 'redefine';
    no warnings 'prototype';
    my $coderef = *{$key}{CODE};

    if ( !$coderef || $MGR->{$key}->{self} ne $coderef ) {
        $MGR->{$key}->{saved} = $coderef
            if !$MGR->{$key}->{saved}
            || $coderef && $$MGR{$key}{saved} ne $coderef;
        $delete_sub_from->($key);
        *{$key} = $MGR->{$key}->{self};
    }
};

sub import {
    shift;
    my @keys = $tags2keys->(@_);
    return if !@keys;
    $load->($_) for (@keys);
}

sub debugs {
    return unless $ENV{'DEBUG_VERBOSE'};
    my ( $_pkg, $_file, $_line ) = caller(0);
    my ( $pkg,  $file,  $line )  = caller(1);
    print STDERR @_, ' <= ', qq{$_file line $_line}, ' <= ',
        qq{$file line $line}, $/;
}

no warnings 'void';
'End of winja
this module works for WIN32-JApanese only';
__END__

=head1 NAME

winja - dirty patch for handling pathname on MSWin32::Ja_JP.cp932


=head1 DESCRIPTION

winja is a module which works only on Win32-Japanese-Edition
( a.k.a. Win32-CP932-Edition. But not Cygwin ).
This module works to deal with file path which contains
multibytes letter including 0x5C byte correctly.

See C<winja::JP>(described in Japanese) for details.

This module is unnecessary for users besides Win32-Japanese-Edition.

You can not install this module to Perl on non-MSWin32-Japanese-Edition.

Even if you forcibly install this module on non-MSWin32 OS or MSWin32 which is not Japanese-Edition, you can not load this module (OS and Windows default language are checked).


=head1 AUTHOR

kpee  C<< <kpee.cpanx@gmail.com> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2016, kpee C<< <kpee.cpanx@gmail.com> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
