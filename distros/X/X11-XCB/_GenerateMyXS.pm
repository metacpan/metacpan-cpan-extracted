#!/usr/bin/env perl
# vim:ts=4:sw=4:expandtab

# Known bugs:
# - Does not support _checked or _unchecked variants of function calls
# - Allows Lua to underflow and (maybe) crash C, when it should lua_error instead (so pcall can catch it)
# - ChangeProperty is limited to the 8-bit datatype

# Known warts:
# - Should get string lengths (and other lengths) from Lua, instead of requiring the length to be passed from the script

package _GenerateMyXS;

use strict; use warnings; use v5.10;
use autodie;
use Data::Dump;
use List::Util qw(first);
use ExtUtils::PkgConfig;

use XML::Simple qw(:strict);

use XML::Descent;
my $parser;

# Forward declarations of utility functions:
sub on; sub walk;    # parser
sub slurp; sub spit; # file reading/writing
# Name mangeling:
sub decamelize($); sub xcb_name($); sub xcb_type($); sub perl_name($); sub cname($);

sub indent (&$@); # templating
our $indent_level = 1;

# File descriptors for: XCB_xs.inc typedefs.h typemap
my ($OUT, $OUTTD, $OUTTM);

my $prefix = 'xcb_';
my %const;

# The tmpl_* function push their generated code onto those arrays,
# &generate in turn writes and empties them.
my (@struct, @request);

# XXX currently unused:
# In contrary to %xcbtype, which only holds basic data types like 'int', 'char'
# and so on, the %exacttype hash holds the real type name, like INT16 or CARD32
# for any type which has been specified in the XML definition. For example,
# type KEYCODE is an alias for CARD32. This is necessary later on to correctly
# typecast our intArray type.
my %exacttype = ();

my %xcbtype = (
    BOOL   => 'int',
    BYTE   => 'uint8_t',
    CARD8  => 'uint8_t',
    CARD16 => 'uint16_t',
    CARD32 => 'uint32_t',
    INT8   => 'uint8_t',
    INT16  => 'uint16_t',
    INT32  => 'uint32_t',

    char   => 'char',
    void   => 'void',     # Hack, to partly support ChangeProperty, until we can reverse 'op'.
    float  => 'double',
    double => 'double',
);

sub tmpl_struct {
    my ($name, $params, $types) = @_;

    my $constructor = 'new';

    my $param = join ',', @$params;
    $param = ",$param" if length $param;
    my $param_decl = indent { "$types->{$_} $_" } "\n", @$params;
    my $set_struct = indent { 'buf->' . cname($_) . " = $_;" } "\n", @$params;

    push @struct, << "__"
MODULE = X11::XCB PACKAGE = $name
$name *
$constructor(self$param)
    char *self
$param_decl
  PREINIT:
    $name *buf;
  CODE:
    New(0, buf, 1, $name);
$set_struct
    RETVAL = buf;
  OUTPUT:
    RETVAL

__
}

sub tmpl_struct_getter {
    my ($pkg, $name, $type) = @_;
    my $cname = cname($name);

    push @struct, << "__"
MODULE = X11::XCB PACKAGE = ${pkg}Ptr

$type
$name(self)
    $pkg * self
  CODE:
    RETVAL = self->$cname;
  OUTPUT:
    RETVAL

__
}

sub tmpl_request {
    my ($name, $cookie, $params, $types, $xcb_cast, $cleanups) = @_;

    my $param = join ',', ('conn', @$params);
    my @param = grep { $_ ne '...' } @$params;

    my $param_decl = indent { "$types->{$_} $_" } "\n", @param;

    # XXX should be "$prefix$name", but $name has already a prefix like xinerama_
    my $xcb_name = "xcb_$name";
    my $xcb_param = do {
        local $indent_level = 0;
        $xcb_cast->{conn} = '';
        indent { $xcb_cast->{$_} . $_ } ', ', ('conn', @param);
    };
    my $cleanup = indent { "free($_);" } "\n", @$cleanups;

    push @request, << "__"
HV *
$name($param)
    XCBConnection *conn
$param_decl
  PREINIT:
    HV * hash;
    $cookie cookie;
  CODE:
    cookie = $xcb_name($xcb_param);

    hash = (HV *)sv_2mortal((SV *)newHV());
    hv_store(hash, "sequence", strlen("sequence"), newSViv(cookie.sequence), 0);
    RETVAL = hash;
$cleanup
  OUTPUT:
    RETVAL

__
}

sub on_field {
    my ($fields, $types) = @_;

    on field => sub {
        my $name = $_->{name};
        push @$fields, $name;

        my $type = xcb_type($_->{type});
        # XXX why not XCB\u$1?
        $type =~ s/^xcb_/XCB/;
        $types->{$name} = $type;
    }
}

sub do_structs {
    my $x_name = $_->{name};
    my $xcb_type = xcb_type $x_name;
    my $perlname = perl_name $x_name;

    print $OUTTD " typedef $xcb_type $perlname;\n";
    print $OUTTM "$perlname * T_PTROBJ\n";

    my (@fields, %type);
    on_field(\@fields, \%type);

    my $dogetter = 1;

    my %nostatic = (    # These structs are used from the base protocol
        xcb_setup_t => 1,
    );

    # TODO: unimplemented
    on list => sub {
        $dogetter = 0;    # If it has a list, the get half shouldn't (can't?) be needed.
    };

    # TODO: unimplemented
    # on union => sub { on [ qw/field list/ ] => sub {} };

    walk;

    # TODO: unimplemented
    return if
        $perlname eq 'XCBXkb_set_behavior' or
        $perlname eq 'XCBXkb_sym_interpret';

    tmpl_struct($perlname, \@fields, \%type);

    if ($dogetter) {
        tmpl_struct_getter($perlname, $_, $type{$_}) for @fields;
    }

}

sub do_typedefs {
    my $e = shift;

    if ($e eq 'typedef') {
        $xcbtype{ $_->{newname} }      = $xcbtype{ $_->{oldname} };
        $exacttype{ $_->{newname} }    = $_->{oldname};
    }
    elsif ($e =~ /^(?:xidtype|xidunion)/) {
        $xcbtype{ $_->{name} }      = $xcbtype{CARD32};
    }
}

# items is already in use by XS, see perlapi
# <Variables created by "xsubpp" and "xsubpp" internal functions> for more
# XXX this is currently only used in do_request/on list
sub param_sanitize {
    $_[0] eq 'items' ? 'items_' : $_[0]
}

sub do_requests {
    my $x_name = $_->{name};

    # TODO: unimplemented (incomplete typemap)
    return if $x_name eq "CreateRegionFromBorderClip";

    my $xcb_name  = xcb_name $x_name;

    # XXX hack, to get eg. a xinerama_ prefix
    (my $ns = $prefix) =~ s/^xcb_//;

    my $name = $ns . decamelize $x_name;

    my (@param, %type, %xcb_cast, @cleanup);

    # Skip documentation blocks.
    on doc => sub {};

    on_field(\@param, \%type);

    # array length
    # TODO : rid _len from parameters, use XS to get the length of strings, etc
    on list => sub {
        my $param = param_sanitize($_->{name});
        my $x_type = $_->{type};

        my $push_len = 1;
        on [ qw/fieldref op value/ ] => sub { $push_len = 0 };
        walk;

        push @param, $param . '_len' if $push_len;
        push @param, $param;

        my $type = $xcbtype{$x_type} || perl_name $x_type;

        if ($type =~ /^uint(?:8|16|32)_t$/) {
            $xcb_cast{$param} = " (const $type*)";
            $type = 'intArray'
        }

        # We use char* instead of void* to be able to use pack() in the perl part
        $type = 'char' if $type eq 'void';

        $type{$param} = "$type *";
        $type{$param . '_len'} = 'int' if $push_len;

        push @cleanup, $param unless $type =~ /^(?:char|void)$/;
    };

    # bitmask -> list of value.
    # TODO: ideally this would be a hashref eg. C< { bitname => "value", … } >
    on valueparam => sub {
        my ($mask, $list, $type) = @{$_}{qw/value-mask-name value-list-name value-mask-type/};
        push @param, $mask
        # eg. ConfigureWindow already specifies the mask via <field />
            unless ($param[-1] || '') eq $mask;

        push @param, $list;
        push @param, '...';

        $type{$mask} = xcb_type $type;
        $type{$list} = 'intArray *';

        push @cleanup, $list;
    };

    on switch => sub {
        my ($elem, $attr, $ctx) = @_;
        my $mask = $parser->xml =~ m,<fieldref>(.*?)</fieldref>,m ? $1 : 'value_mask';
        my $list = $attr->{'name'};
        push @param, $mask
        # eg. ConfigureWindow already specifies the mask via <field />
            unless first { $_ eq $mask } @param;

        push @param, $list;
        push @param, '...';

        $type{$list} = 'intArray *';

        push @cleanup, $list;
    };

    my $cookie = 'xcb_void_cookie_t';
    on reply => sub { $cookie = $xcb_name . '_cookie_t'; 'do_reply(@_)' };
    walk;

    $xcb_cast{$_} ||= '' for @param;

    tmpl_request($name, $cookie, \@param, \%type, \%xcb_cast, \@cleanup);

}

sub do_events($) {
    my $xcb = shift;
    my %events;

    # TODO: events
}

sub do_replies($\%\%) {
    my ($xcb, $func, $collect) = @_;

    for my $req (@{ $xcb->{request} }) {
        my $rep = $req->{reply};
        next unless defined($rep);
        # request should return a cookie object, blessed into the right pkg
        # $perlname should be set fixed to 'reply'

        my $name     = xcb_name($req->{name}) . "_reply";
        my $reply    = xcb_name($req->{name}) . "_reply_t";
        my $perlname = $name;
        $perlname =~ s/^xcb_//g;
        my $cookie = xcb_name($req->{name}) . "_cookie_t";

        print $OUT "HV *\n$perlname(conn,sequence)\n";
        print $OUT "    XCBConnection *conn\n";
        print $OUT "    int sequence\n";
        print $OUT "  PREINIT:\n";
        print $OUT "    HV * hash;\n";
        print $OUT "    HV * inner_hash;\n";
        print $OUT "    AV * alist;\n";
        print $OUT "    int c;\n";
        print $OUT "    int _len;\n";
        print $OUT "    $cookie cookie;\n";
        print $OUT "    $reply *reply;\n";
        print $OUT "  CODE:\n";
        print $OUT "    cookie.sequence = sequence;\n";
        print $OUT "    reply = $name(conn, cookie, NULL);\n";
        # XXX use connection_has_error
        print $OUT qq/    if (!reply) croak("Could not get reply for: $name"); /;
        print $OUT "    hash = (HV *)sv_2mortal((SV *)newHV());\n";

        # We ignore pad0 and response_type. Every reply has sequence and length
        print $OUT "    hv_store(hash, \"sequence\", strlen(\"sequence\"), newSViv(reply->sequence), 0);\n";
        print $OUT "    hv_store(hash, \"length\", strlen(\"length\"), newSViv(reply->length), 0);\n";
        for my $var (@{ $rep->[0]->{field} }) {
            my $type = xcb_type($var->{type});
            my $name = cname($var->{name});
            if ($type =~ /^(?:uint(?:8|16|32)_t|int)$/) {
                print $OUT "    hv_store(hash, \"$name\", strlen(\"$name\"), newSViv(reply->$name), 0);\n";
            } else {
                print $OUT "    /* TODO: type $type, name $var->{name} */\n";
            }
        }

        for my $list (@{ $rep->[0]->{list} }) {
            my $listname      = $list->{name};
            my $type          = xcb_name($list->{type}) . '_t';
            my $iterator      = xcb_name($list->{type}) . '_iterator_t';
            my $iterator_next = xcb_name($list->{type}) . '_next';
            my $pre           = xcb_name($req->{name});

            if ($list->{type} eq 'void') {
                # TODO RandR structure randr_get_provider_property_reply is not supported
                last if $perlname eq 'randr_get_provider_property_reply';

                # A byte-array. Provide it as SV.
                print $OUT "    _len = reply->value_len * (reply->format / 8);\n";
                print $OUT "    if (_len > 0)\n";
                print $OUT "        hv_store(hash, \"value\", strlen(\"value\"), newSVpvn((const char*)(reply + 1), _len), 0);\n";
                next;
            }

            # Get the type description of the list’s members
            my $struct = first { $_->{name} eq $list->{type} } @{ $xcb->{struct} };

            next unless defined($struct->{field}) && scalar(@{ $struct->{field} }) > 0;

            print $OUT "    {\n";
            print $OUT "    /* Handling list part of the reply */\n";
            print $OUT "    alist = newAV();\n";
            print $OUT "    $iterator iterator = $pre" . '_' . decamelize($listname) . "_iterator(reply);\n";
            print $OUT "    for (; iterator.rem > 0; $iterator_next(&iterator)) {\n";
            print $OUT "      $type *data = iterator.data;\n";
            print $OUT "      inner_hash = newHV();\n";

            for my $field (@{ $struct->{field} }) {
                my $type = xcb_type($field->{type});
                my $name = cname($field->{name});

                if ($type =~ /^(?:uint(?:8|16|32)_t|int)$/) {
                    print $OUT "      hv_store(inner_hash, \"$name\", strlen(\"$name\"), newSViv(data->$name), 0);\n";
                } else {
                    print $OUT "      /* TODO: type $type, name $name */\n";
                }
            }
            print $OUT "      av_push(alist, newRV((SV*)inner_hash));\n";

            print $OUT "    }\n";
            print $OUT "    hv_store(hash, \"" . $list->{name} . "\", strlen(\"" . $list->{name} . "\"), newRV((SV*)alist), 0);\n";

            print $OUT "    }\n";
        }

        #print Dumper($rep);
        #if (defined($rep->{list})) {

        print $OUT "    RETVAL = hash;\n";

        # Sometimes XCB gives use a lot of data along the reply, like in xcb_get_image_reply()
        print $OUT "    free(reply);\n";

        print $OUT "  OUTPUT:\n    RETVAL\n\n";
    }
}

sub do_enums {
    my ($tag, $attr) = @_;

    # XXX hack, to get eg. a xinerama_ prefix
    (my $ns = $prefix) =~ s/^xcb_//;
    my $name = uc $ns . decamelize $attr->{name};

    if ($tag eq 'enum') {
        on item => sub {
            my $tname = $name . "_" . uc decamelize $_->{name};
            $const{$tname} = "newSViv(XCB_$tname)";
        };
        walk;

    }
    elsif ($tag eq 'event') { # =~ /^(?:event|eventcopy|error|errorcopy)$/) {
        $const{$name} = "newSViv(XCB_$name)";
    }

}

sub generate {
    my $path = ExtUtils::PkgConfig->variable('xcb-proto', 'xcbincludedir') ||
        die "Package xcb-proto was not found in the pkg-config search path.";
    my @xcb_xmls = qw/xproto.xml xinerama.xml randr.xml xkb.xml composite.xml/;

    -d $path or die "$path: $!\n";

    # TODO: Handle all .xmls
    #opendir(DIR, '.');
    #@files = grep { /\.xml$/ } readdir(DIR);
    #closedir DIR;

    my @files = map {
        my $xml = "$path/$_";
        -r $xml or die "$xml: $!\n";
        $xml
    } @xcb_xmls;

    open($OUT,   ">XCB_xs.inc");
    open($OUTTM, ">typemap");
    open($OUTTD, ">typedefs.h");

    my $additional_types = << '__';
XCBConnection *             T_PTROBJ_MG
intArray *                  T_ARRAY
X11_XCB_ICCCM_WMHints *     T_PTROBJ
X11_XCB_ICCCM_SizeHints *   T_PTROBJ
uint8_t                     T_U_CHAR
uint16_t                    T_U_SHORT
uint32_t                    T_UV
__

    print $OUTTM $additional_types;


    # Our own additions: EWMH constants
    $const{_NET_WM_STATE_ADD}    = 'newSViv(1)';
    $const{_NET_WM_STATE_REMOVE} = 'newSViv(0)';
    $const{_NET_WM_STATE_TOGGLE} = 'newSViv(2)';

    # Add some constants manually, as they are missing in xml
    $const{XCB_NONE} = 'newSViv(XCB_NONE)';
    $const{LEAVE_NOTIFY} = 'newSViv(XCB_LEAVE_NOTIFY)';
    $const{KEY_RELEASE} = 'newSViv(XCB_KEY_RELEASE)';
    $const{BUTTON_RELEASE} = 'newSViv(XCB_BUTTON_RELEASE)';
    $const{FOCUS_OUT} = 'newSViv(XCB_FOCUS_OUT)';
    $const{CIRCULATE_REQUEST} = 'newSViv(XCB_CIRCULATE_REQUEST)';

    # ICCCM constants from xcb-util
    for my $const (qw(XCB_ICCCM_WM_STATE_WITHDRAWN XCB_ICCCM_WM_STATE_NORMAL XCB_ICCCM_WM_STATE_ICONIC
        XCB_ICCCM_SIZE_HINT_US_POSITION XCB_ICCCM_SIZE_HINT_US_SIZE XCB_ICCCM_SIZE_HINT_P_POSITION
        XCB_ICCCM_SIZE_HINT_P_SIZE XCB_ICCCM_SIZE_HINT_P_MIN_SIZE XCB_ICCCM_SIZE_HINT_P_MAX_SIZE
        XCB_ICCCM_SIZE_HINT_P_RESIZE_INC XCB_ICCCM_SIZE_HINT_P_ASPECT XCB_ICCCM_SIZE_HINT_BASE_SIZE
        XCB_ICCCM_SIZE_HINT_P_WIN_GRAVITY
        )) {
        my ($name) = ($const =~ /XCB_(.*)/);
        $const{$name} = "newSViv($const)";
    }

    for my $path (@files) {
        say "Processing: $path";
        my $xcb = XMLin("$path", KeyAttr => undef, ForceArray => 1);

        $parser = XML::Descent->new({ Input => $path });

        on xcb => sub {
            my ($e, $attr) = @_;
            my $name = $attr->{header};

            $prefix = $name eq 'xproto' ? 'xcb_' : "xcb_${name}_";

            on [ qw/enum event eventcopy error errorcopy/ ] => \&do_enums;
            on [ qw/typedef xidtype xidunion/ ] => \&do_typedefs;
            on struct => \&do_structs;
            on request => \&do_requests;
            walk;
        };
        walk;

        print $OUT @struct;
        undef @struct;

        do_events($xcb);

        # TODO RandR typemap of mode_info_t, transform_t, monitor_info_t not implemented
        if (index $path, "randr") {
            my $randr_exclude = join "|", qw( randr_create_mode randr_set_monitor randr_set_crtc_transform );
            @request = grep ! /^HV \*\s+$randr_exclude\b/, @request;
        }

        # TODO xkb typemap of XCBXkb_action not implemented
        if (index $path, "xkb") {
            my $xkb_exclude = join "|", qw( xkb_set_device_info );
            @request = grep ! /^HV \*\s+$xkb_exclude\b/, @request;
        }

        print $OUT "MODULE = X11::XCB PACKAGE = X11::XCB\n";
        print $OUT @request;
        undef @request;

        &do_replies($xcb);


    }

    close $OUT;
    close $OUTTM;
    close $OUTTD;

    my @const = sort keys %const;

    spit 'XCB.inc', << "__",
static void boot_constants(HV *stash, AV *tags_all) {
    av_extend(tags_all, ${\ scalar @const });
__
        (map { << "__" } @const),
    newCONSTSUB(stash, "$_", $const{$_});
    av_push(tags_all, newSVpvn("$_", ${\ length $_ }));
__
        "}\n";
}

# utility functions

sub on {
    my ($tag, $code) = @_;
    $parser->on($tag => sub { $code->(@_) for $_[1] });
}
sub walk { $parser->walk }

# reads in a whole file
sub slurp {
    open my $fh, '<', shift;
    local $/;
    <$fh>;
}

sub spit {
    my $file = shift;
    open my $fh, '>', $file;
    print $fh @_;
    say "Writing: $file";
    close $fh;
}

sub perl_name($) {
    my $x_name = shift;
    # XXX hack:
    # get potential extra ns like "xinerama"
    (my $ns = $prefix) =~ s/^xcb_//;

    return 'XCB' . ucfirst +($ns . decamelize($x_name));
}

sub xcb_name($) {
    my $x_name = shift;
    return $prefix . decamelize($x_name);
}

sub xcb_type($) {
    my $type = shift;
    # XXX shouldn't those be in %xcbtype anyway?
    return $xcbtype{$type} || xcb_name($type) . '_t';
}

sub decamelize($) {
    my ($camel) = @_;

    my @special = qw(
        CHAR2B
        INT64
        FLOAT32
        FLOAT64
        BOOL32
        STRING8
        Family_DECnet
        DECnet
   );

    return lc $camel if first { $camel eq $_ } @special;

    # FIXME: eliminate this special case
    return $camel if $camel =~ /^CUT_BUFFER/;

    my $name = '';

    while (length($camel)) {
        my ($char, $next) = ($camel =~ /^(.)(.*)$/);

        $name .= lc($char);

        if (   $camel =~ /^[[:lower:]][[:upper:]]/
            || $camel =~ /^\d[[:alpha:]]/
            || $camel =~ /^[[:alpha:]]\d/
            || $camel =~ /^[[:upper:]][[:upper:]][[:lower:]]/)
        {
            $name .= '_';
        }

        $camel = $next;
    }

    return $name;
}

sub cname($) {
    my $name = shift;
    return "_$name" if first { $name eq $_ } qw/new delete class operator/;
    return $name;
}

sub indent (&$@) {
    my ($code, $join, @input) = @_;
    my $indent = ' ' x ($indent_level * 4);

    return join $join, map { $indent . $code->() } @input;
}

() = $0 =~ (__PACKAGE__ . '.pm') ? generate() : 1;

# Copyright (C) 2009 Michael Stapelberg <michael at stapelberg dot de>
# Copyright (C) 2007 Hummingbird Ltd. All Rights Reserved.
#
# Permission is hereby granted, free of charge, to any person
# obtaining a copy of this software and associated
# documentation files (the "Software"), to deal in the
# Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute,
# sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so,
# subject to the following conditions:
#
# The above copyright notice and this permission notice shall
# be included in all copies or substantial portions of the
# Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY
# KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
# WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
# PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS
# BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
# IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.
#
# Except as contained in this notice, the names of the authors
# or their institutions shall not be used in advertising or
# otherwise to promote the sale, use or other dealings in this
# Software without prior written authorization from the
# authors.
