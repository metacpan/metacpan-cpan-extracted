package Unicode::MapUTF8;

use strict;
use Carp qw(confess croak carp);
use Unicode::String;
use Unicode::Map;
use Unicode::Map8;
use Jcode;

use vars qw ($VERSION @EXPORT @EXPORT_OK @EXPORT_TAGS @ISA);
use subs qw (utf8_supported_charset to_utf8 from_utf8 utf8_charset_alias _init_charsets);

require Exporter;
BEGIN {
    @ISA         = qw(Exporter);
    @EXPORT      = qw ();
    @EXPORT_OK   = qw (utf8_supported_charset to_utf8 from_utf8 utf8_charset_alias);
    @EXPORT_TAGS = qw ();
    $VERSION     = "1.11";
}

############################
# File level package globals (class variables)
my $_Supported_Charsets;
my $_Charset_Names;
my $_Charset_Aliases;
_init_charsets;

##############

sub utf8_charset_alias {
    if ($#_ == -1) {
        my $aliases = {};
        %$aliases   =  %$_Charset_Aliases;
        return $aliases;
    }
    my $parms;
    my @parms_list = @_;
    if (($#parms_list == 0) && (ref ($parms_list[0]) eq 'HASH')) {
        _set_utf8_charset_alias($parms_list[0]);
        return;
    } elsif (($#parms_list > 0) && (($#parms_list % 2) == 1)) {
        _set_utf8_charset_alias({ @parms_list });
        return;
    } elsif ($#parms_list == 0) {
        my $lc_charset = lc($parms_list[0]);
        my $result     = $_Charset_Aliases->{$lc_charset};
        return $result;
    }
    croak( '[' . localtime(time) . '] ' . __PACKAGE__ . "::utf8_charset_alias() - invalid parameters passed\n");
}

######################################################################
# Sets (or clears ;-) ) a runtime character set alias.

sub _set_utf8_charset_alias {
    my ($parms) = @_;
    my @alias_names = keys %$parms;
    foreach my $alias (@alias_names) {
        my $lc_alias = lc ($alias);
        my $charset  = $parms->{$alias};
        if (! defined $charset) {
            if (exists ($_Charset_Aliases->{$lc_alias})) {
                delete $_Charset_Aliases->{$lc_alias};
            }
            next;
        }
        my $lc_charset = lc ($charset);
        if (! exists ($_Charset_Names->{$lc_charset})) {
            croak( '[' . localtime(time) . '] ' . __PACKAGE__ . "::utf8_charset_alias() - attempted to set alias '$alias' to point to unknown charset encoding of '$charset'\n");
        }
        if (exists ($_Charset_Names->{$lc_alias})) {
            carp('[' . localtime(time) . '] [warning] ' . __PACKAGE__ . "::utf8_charset_alias() - Aliased base defined charset name '$alias' to '$charset'.");
        }
        $_Charset_Aliases->{$lc_alias} = $lc_charset;
    }
}

####

sub utf8_supported_charset {
    if ($#_ == -1 && wantarray) {
        my %all_charsets = (%$_Supported_Charsets, %$_Charset_Aliases);
        my @charsets     = sort keys %all_charsets;
        return @charsets;
    }
    my $charset = shift;
    if (not defined $charset) {
        croak( '[' . localtime(time) . '] ' . __PACKAGE__ . "::utf8_supported_charset() - no character set specified\n");
    }
    my $lc_charset = lc($charset);
    return 1 if (exists ($_Charset_Names->{$lc_charset}));
    return 1 if (exists ($_Charset_Aliases->{$lc_charset}));
    return 0;
}

####

sub to_utf8 {
    my @parm_list = @_;
    my $parms  = {};
    if (($#parm_list > 0) && (($#parm_list % 2) == 1)) {
        $parms = { @parm_list };
    } elsif ($#parm_list == 0) {
        $parms = $parm_list[0];
        if (! ref($parms)) {
            croak( '[' . localtime(time) . '] ' . __PACKAGE__ . "::to_utf8() - invalid parameters passed\n");
        }
    } else {
        croak( '[' . localtime(time) . '] ' . __PACKAGE__ . "::to_utf8() - bad parameters passed\n");
    }

    if (! (exists $parms->{-string})) {
        croak( '[' . localtime(time) . '] ' . __PACKAGE__ . "::to_utf8() - missing '-string' parameter\n");
    }
    my $string  = $parms->{-string};
    my $charset = $parms->{-charset};

    if (! defined ($charset)) {
        croak( '[' . localtime(time) . '] ' . __PACKAGE__ . "::to_utf8() - missing '-charset' parameter value\n");
    }
    my $lc_charset    = lc ($charset);
    my $alias_charset = $_Charset_Aliases->{$lc_charset};
    my $true_charset  = defined($alias_charset) ? $_Charset_Names->{$alias_charset} : $_Charset_Names->{$lc_charset};
    if (! defined $true_charset) {
        croak( '[' . localtime(time) . '] ' . __PACKAGE__ . "::to_utf8() - character set '$charset' is not supported\n");
    }

    $string = '' if (! defined ($string));

    my $converter = $_Supported_Charsets->{$true_charset};
    if    ($converter eq 'map8')       { return _unicode_map8_to_utf8   ($string,$true_charset); }
    if    ($converter eq 'unicode-map'){ return _unicode_map_to_utf8    ($string,$true_charset); }
    elsif ($converter eq 'string')     { return _unicode_string_to_utf8 ($string,$true_charset); }
    elsif ($converter eq 'jcode')      { return _jcode_to_utf8          ($string,$true_charset); }
    else {
        croak(  '[' . localtime(time) . '] ' . __PACKAGE__ . "::to_utf8() - charset '$charset' is not supported\n");
    }
}

####

sub from_utf8 {
    my @parm_list = @_;
    my $parms;
    if (($#parm_list > 0) && (($#parm_list % 2) == 1)) {
        $parms = { @parm_list };
    } elsif ($#parm_list == 0) {
        $parms = $parm_list[0];
        if (! ref($parms)) {
            croak( '[' . localtime(time) . '] ' . __PACKAGE__ . "::from_utf8() - invalid parameters passed\n");
        }
    } else {
        croak( '[' . localtime(time) . '] ' . __PACKAGE__ . "::from_utf8() - bad parameters passed\n");
    }

    if (! (exists $parms->{-string})) {
    ; croak( '[' . localtime(time) . '] ' . __PACKAGE__ . "::from_utf8() - missing '-string' parameter\n");
    }

    my $string  = $parms->{-string};
    my $charset = $parms->{-charset};

    if (! defined ($charset)) {
        croak( '[' . localtime(time) . '] ' . __PACKAGE__ . "::from_utf8() - missing '-charset' parameter value\n");
    }
    my $lc_charset    = lc ($charset);
    my $alias_charset = $_Charset_Aliases->{$lc_charset};
    my $true_charset  = defined($alias_charset) ? $_Charset_Names->{$alias_charset} : $_Charset_Names->{$lc_charset};
    if (! defined $true_charset) {
        croak( '[' . localtime(time) . '] ' . __PACKAGE__ . "::from_utf8() - character set '$charset' is not supported\n");
    }

    $string = '' if (! defined ($string));

    my $converter = $_Supported_Charsets->{$true_charset};
    my $result;
    if    ($converter eq 'map8')        { $result = _unicode_map8_from_utf8   ($string,$true_charset); }
    elsif ($converter eq 'unicode-map') { $result = _unicode_map_from_utf8    ($string,$true_charset); }
    elsif ($converter eq 'string')      { $result = _unicode_string_from_utf8 ($string,$true_charset); }
    elsif ($converter eq 'jcode')       { $result = _jcode_from_utf8          ($string,$true_charset); }
    else {
        croak(  '[' . localtime(time) . '] ' . __PACKAGE__ . "::from_utf8() - charset '$charset' is not supported\n");
    }
    return $result;
}

######################################################################
#
# _unicode_map_from_utf8($string,$target_charset);
#
# Returns the string converted from UTF8 to the specified target multibyte charset.
#

sub _unicode_map_from_utf8 {
    my ($string,$target_charset) = @_;

    if (! defined $target_charset) {
        croak( '[' . localtime(time) . '] ' . __PACKAGE__ . '::_unicode_map_from_utf8() - (line ' . __LINE__ . ") No target character set specified\n");
    }

    my $ucs2   = from_utf8 ({ -string => $string, -charset => 'ucs2' });
    my $target = Unicode::Map->new($target_charset);
    if (! defined $target) {
        confess( '[' . localtime(time) . '] ' . __PACKAGE__ . '::_unicode_map_from_utf8() - (line ' . __LINE__ . ") failed to instantate Unicode::Map object for charset '$target_charset': $!\n");
    }
    my $result = $target->from_unicode($ucs2);
    return $result;
}

######################################################################
#
# _unicode_map_to_utf8($string,$source_charset);
#
# Returns the string converted the specified target multibyte charset to UTF8.
#
sub _unicode_map_to_utf8 {
    my ($string,$source_charset) = @_;

    if (! defined $source_charset) {
        croak( '[' . localtime(time) . '] ' . __PACKAGE__ . '::_unicode_map_to_utf8() - (line ' . __LINE__ . ") No source character set specified\n");
    }

    my $source = Unicode::Map->new($source_charset);
    if (! defined $source) {
        confess('[' . localtime(time) . '] ' . __PACKAGE__ . "::_unicode_map_to_utf8() - (line " . __LINE__ . ") failed to instantate a Unicode::Map object: $!\n");
    }
    my $ucs2   = $source->to_unicode($string);
    my $result = to_utf8({ -string => $ucs2, -charset => 'ucs2' });
    return $result;
}

######################################################################
#
# _unicode_map8_from_utf8($string,$target_charset);
#
# Returns the string converted from UTF8 to the specified target 8bit charset.
#

sub _unicode_map8_from_utf8 {
    my ($string,$target_charset) = @_;

    if (! defined $target_charset) {
        croak( '[' . localtime(time) . '] ' . __PACKAGE__ . '::_unicode_map8_from_utf8() - (line ' . __LINE__ . ") No target character set specified\n");
    }

    my $u = Unicode::String::utf8($string);
    if (! defined $u) {
        confess( '[' . localtime(time) . '] ' . __PACKAGE__ . "::_unicode_map8_from_utf8() - (line " . __LINE__ . ") failed to instantate Unicode::String::utf8 object: $!\n");
    }
    my $ordering = $u->ord;
    $u->byteswap if (defined($ordering) && ($ordering == 0xFFFE));
    my $ucs2_string = $u->ucs2;

    my $target = Unicode::Map8->new($target_charset);
    if (! defined $target) {
        confess( '[' . localtime(time) . '] ' . __PACKAGE__ . "::_unicode_map8_from_utf8() - (line " . __LINE__ . ") ailed to instantate Unicode::Map8 object for character set '$target_charset':  $!\n");
    }
    my $result = $target->to8($ucs2_string);

    return $result;
}

######################################################################
#
# _unicode_map8_to_utf8($string,$source_charset);
#
# Returns the string converted the specified target 8bit charset to UTF8.
#
#

sub _unicode_map8_to_utf8 {
    my ($string,$source_charset) = @_;

    my $source = Unicode::Map8->new($source_charset);
    if (! defined $source) {
        confess('[' . localtime(time) . '] ' . __PACKAGE__ . "::_unicode_map8_to_utf8() - (line " . __LINE__ . ") failed to instantate a Unicode::Map8 object for character set '$source_charset': $!\n");
    }

    my $ucs2_string = $source->tou($string);
    if (! defined $ucs2_string) {
            confess('[' . localtime(time) . '] ' . __PACKAGE__ . "::_unicode_map8_to_utf8() - (line " . __LINE__ . ") failed to instantate a Unicode::String::utf16 object: $!\n");
    }
    my $utf8_string = $ucs2_string->utf8;

    return $utf8_string;
}

######################################################################
#
# _unicode_string_from_utf8($string,$target_charset);
#
# Returns the string converted from UTF8 to the specified unicode encoding.
#

sub _unicode_string_from_utf8 {
    my ($string,$target_charset) = @_;

    $target_charset = lc ($target_charset);
    my $final;
    if ($target_charset eq 'utf8') {
        $final = $string;
    } elsif ($target_charset eq 'ucs2') {
        my $u = Unicode::String::utf8($string);
        my $ordering = $u->ord;
        $u->byteswap if (defined($ordering) && ($ordering == 0xFFFE));
        $final = $u->ucs2;
    } elsif ($target_charset eq 'ucs4') {
        my $u = Unicode::String::utf8($string);
        my $ordering = $u->ord;
        $u->byteswap if (defined($ordering) && ($ordering == 0xFFFE));
        $final = $u->ucs4;
    } elsif ($target_charset eq 'utf16') {
        my $u = Unicode::String::utf8($string);
        my $ordering = $u->ord;
        $u->byteswap if (defined($ordering) && ($ordering == 0xFFFE));
        $final = $u->utf16;
    } elsif ($target_charset eq 'utf7') {
        my $u = Unicode::String::utf8($string);
        my $ordering = $u->ord;
        $u->byteswap if (defined($ordering) && ($ordering == 0xFFFE));
        $final = $u->utf7;
    } else {
        croak(  '[' . localtime(time) . '] ' . __PACKAGE__ . "::_unicode_string_from_utf8() - charset '$target_charset' is not supported\n");
    }
    return $final;
}

######################################################################
#
# _unicode_string_to_utf8($string,$source_charset);
#
# Returns the string converted the specified unicode encoding to UTF8.
#

sub _unicode_string_to_utf8 {
    my ($string,$source_charset) = @_;

    $source_charset = lc ($source_charset);
    my $final;
    if    ($source_charset eq 'utf8') {
        $final = $string;
    } elsif ($source_charset eq 'ucs2') {
        my $u = Unicode::String::utf16($string);
        if (! defined $u) {
            confess('[' . localtime(time) . '] ' . __PACKAGE__ . "::_unicode_string_to_utf8() - (line " . __LINE__ . ") failed to instantate a Unicode::String::utf16 object: $!\n");
        }
        my $ordering = $u->ord;
        $u->byteswap if (defined($ordering) && ($ordering == 0xFFFE));
        $final = $u->utf8;
    } elsif ($source_charset eq 'ucs4') {
        my $u = Unicode::String::ucs4($string);
        if (! defined $u) {
            confess('[' . localtime(time) . '] ' . __PACKAGE__ . "::_unicode_string_to_utf8() - (line " . __LINE__ . ") failed to instantate a Unicode::String::ucs4 object: $!\n");
        }
        my $ordering = $u->ord;
        $u->byteswap if (defined($ordering) && ($ordering == 0xFFFE));
        $final = $u->utf8;
    } elsif ($source_charset eq 'utf16') {
        my $u = Unicode::String::utf16($string);
        if (! defined $u) {
            confess('[' . localtime(time) . '] ' . __PACKAGE__ . "::_unicode_string_to_utf8() - (line " . __LINE__ . ") failed to instantate a Unicode::String::utf16 object: $!\n");
        }
        my $ordering = $u->ord;
        $u->byteswap if (defined($ordering) && ($ordering == 0xFFFE));
        $final = $u->utf8;
    } elsif ($source_charset eq 'utf7') {
        my $u = Unicode::String::utf7($string);
        if (! defined $u) {
            confess('[' . localtime(time) . '] ' . __PACKAGE__ . "::_unicode_string_to_utf8() - (line " . __LINE__ . ") failed to instantate a Unicode::String::utf7 object: $!\n");
        }
        my $ordering = $u->ord;
        $u->byteswap if (defined($ordering) && ($ordering == 0xFFFE));
        $final = $u->utf8;
    } else {
        croak(  '[' . localtime(time) . '] ' . __PACKAGE__ . ":: _unicode_string_to_utf8() - charset '$source_charset' is not supported\n");
    }

    return $final;
}

######################################################################
#
# _jcode_from_utf8($string,$target_charset);
#
# Returns the string converted from UTF8 to the specified Jcode encoding.
#

sub _jcode_from_utf8 {
    my ($string,$target_charset) = @_;

    my $j = Jcode->new($string,'utf8');

    $target_charset = lc ($target_charset);
    my $final;
    if    ($target_charset =~ m/^iso[-_]2022[-_]jp$/) {
        $final = $j->iso_2022_jp;
    } elsif ($target_charset eq 'sjis') {
        $final = $j->sjis;
    } elsif ($target_charset eq 'euc-jp') {
        $final = $j->euc;
    } elsif ($target_charset eq 'jis') {
        $final = $j->jis;
    } else {
        croak(  '[' . localtime(time) . '] ' . __PACKAGE__ . "::_jcode_from_utf8() - charset '$target_charset' is not supported\n");
    }
    return $final;
}

######################################################################
#
# _jcode_to_utf8($string,$source_charset);
#
# Returns the string converted from the specified Jcode encoding to UTF8.
#

sub _jcode_to_utf8 {
    my ($string,$source_charset) = @_;

    $source_charset = lc ($source_charset);

    my $final;
    if    ($source_charset =~ m/^iso[-_]2022[-_]jp$/) {
        my $j  = Jcode->new($string,'jis')->h2z;
        $final = $j->utf8;
    } elsif ($source_charset =~m/^(s[-_]?jis|shift[-_]?jis)$/) {
        my $j  = Jcode->new($string,'sjis');
        $final = $j->utf8;
    } elsif ($source_charset eq 'euc-jp') {
        my $j  = Jcode->new($string,'euc');
        $final = $j->utf8;
    } elsif ($source_charset eq 'jis') {
        my $j  = Jcode->new($string,'jis');
        $final = $j->utf8;
    } else {
        croak(  '[' . localtime(time) . '] ' . __PACKAGE__ . "::_jcode_to_utf8() - charset '$source_charset' is not supported\n");
    }

    return $final;
}

#######################################################################
#
# Character set handlers maps
#

sub _init_charsets {

    $_Charset_Aliases    = {};

    $_Supported_Charsets = {
        'utf8'                    => 'string',
        'ucs2'                    => 'string',
        'ucs4'                    => 'string',
        'utf7'                    => 'string',
        'utf16'                   => 'string',
        'sjis'                    => 'jcode',
        's-jis'                   => 'jcode',
        's_jis'                   => 'jcode',
        'shiftjis'                => 'jcode',
        'shift-jis'               => 'jcode',
        'shift_jis'               => 'jcode',
        'iso-2022-jp'             => 'jcode',
        'iso_2022_jp'             => 'jcode',
        'jis'                     => 'jcode',
        'euc-jp'                  => 'jcode',
    };
    $_Charset_Names = { map { lc ($_) => $_ } keys %$_Supported_Charsets };

    # All the Unicode::Map8 charsets
    {
        my @map_ids = &_list_unicode_map8_charsets;
        foreach my $id (@map_ids) {
            my $lc_id = lc ($id);
            next if (exists ($_Charset_Names->{$lc_id}));
            $_Supported_Charsets->{$id} = 'map8';
            $_Charset_Names->{$lc_id}    = $id;
        }
    }
    $_Charset_Names = { map { lc ($_) => $_ } keys %$_Supported_Charsets };

    # Add any charsets not already listed from Unicode::Map
    {
        my $unicode_map = Unicode::Map->new;
        my @map_ids     = $unicode_map->ids;
        foreach my $id (@map_ids) {
            my $lc_id = lc ($id);
            next if (exists ($_Charset_Names->{$lc_id}));
            $_Supported_Charsets->{$id} = 'unicode-map';
            $_Charset_Names->{$lc_id}    = $id;
        }
    }
}

######################################################################
#
# Code taken and modified from the 'usr/bin/umap' code distributed
# with Unicode::Map8. It wouldn't be necessary if Unicode::Map8
# had a direct method for this....
#

sub _list_unicode_map8_charsets {
    my %set = (
           ucs4 => {},
           ucs2 => {utf16 => 1},
           utf7 => {},
           utf8 => {},
          );
    if (opendir(DIR, $Unicode::Map8::MAPS_DIR)) {
        my @files = grep(!/^\.\.?$/,readdir(DIR));
        foreach my $f (@files) {
            next unless -f "$Unicode::Map8::MAPS_DIR/$f";
            $f =~ s/\.(?:bin|txt)$//;
            my $supported =
            $set{$f} = {} if Unicode::Map8->new($f);
        }
    }

    my $avoid_warning = keys %Unicode::Map8::ALIASES;
    while ( my($alias, $charset) = each %Unicode::Map8::ALIASES) {
        if (exists $set{$charset}) {
            $set{$charset}{$alias} = 1;
        }
    }

    my %merged_set = ();
    foreach my $encoding (keys %set) {
        $merged_set{$encoding} = 1;
        my $set_item = $set{$encoding};
        while (my ($key,$value) = each (%$set_item)) {
                $merged_set{$key} = $value;
        }
    }
    my @final_charsets = sort keys %merged_set;
    return @final_charsets;
}

######################################################################

1;
