# $Id: Win32OLETypeLib.pm,v 1.2 2001/08/02 22:44:26 matt Exp $

package XML::Generator::Win32OLETypeLib;

use strict;
use vars qw($VERSION);

$VERSION = '0.01';

# Create an XML representation of a typelib
# - to eventually convert to WSDL.

use Win32::OLE;
use Win32::OLE::Const;
use Win32::OLE::TypeInfo;

my @Library;
sub libCLSID    () {0}
sub libNAME     () {1}
sub libMAJOR    () {2}
sub libMINOR    () {3}
sub libLANGUAGE () {4}
sub libFILENAME () {5}

# list of all types
sub typeLIB    () {0}
sub typeINFO   () {1}
sub typeDOC    () {2}
sub typeATTR   () {3}
sub typeHIDDEN () {4}

# list of all members
sub membTYPE     () {0}
sub membDESC     () {1}
sub membDOC      () {2}
sub membICON     () {3}
sub membREADONLY () {4}
sub membHIDDEN   () {5}
sub membDETAILS  () {6}

# TYPEKIND sort order:
my @tkorder;
$tkorder[TKIND_COCLASS]  = -4; # Treat COCLASS/DISPATCH the same for sorting
$tkorder[TKIND_DISPATCH] = -4;
$tkorder[TKIND_MODULE]   = -3;
# $tkorder[TKIND_TYPE]     = -2;
$tkorder[TKIND_ENUM]     = -1;

# MEMBERKIND sort order:
my %mkorder = (
        Property => -4,
        Method => -3,
        Event => -2,
        Const => -1,
        );

# Icons - not actually used as icons here.
my @icon;
$icon[TKIND_COCLASS]  = 'Class';
$icon[TKIND_DISPATCH] = 'Class';
$icon[TKIND_ENUM]     = 'Enum';
$icon[TKIND_MODULE]   = 'Module';

my @vt;
$vt[VT_BOOL]     = 'Boolean';
$vt[VT_BSTR]     = 'String';
$vt[VT_DISPATCH] = 'Object';
$vt[VT_INT]      = 'Long';
$vt[VT_I2]       = 'Short';
$vt[VT_I4]       = 'Long';
$vt[VT_R8]       = 'Double';
$vt[VT_UNKNOWN]  = 'Unknown';
$vt[VT_VARIANT]  = 'Variant';
$vt[VT_VOID]     = 'Void';

use vars qw/$ShowHidden $GroupByType/;
$ShowHidden = 0; # change to show hidden objects
$GroupByType = 0; # change to group by type

sub new {
    my $class = shift;
    die "No SAX handler passed" unless @_;
    unshift @_, 'Handler' if @_ == 1;
    my %params = @_;
    return bless \%params, $class;
}

sub find_typelib {
    my $self = shift;
    my $match = shift;

    my $doc_obj = {};

    $self->{Handler}->start_document( $doc_obj );

    $self->send_start("typelibs");

    my @matches = ();
    Win32::OLE::Const->EnumTypeLibs(sub {
        my ($clsid,$title,$version,$langid,$filename) = @_;
        return unless $title =~ /\Q$match\E/;
        return unless $version =~ /^([0-9a-fA-F]+)\.([0-9a-fA-F]+)$/;
        my ($maj,$min) = (hex($1), hex($2));
        push @matches, [$clsid,$title,$maj,$min,$langid,$filename];
    });

    my %typelibs;

    foreach my $lib (@matches) {
        $self->send_start("typelib", 1);
        $self->process_lib($lib);
        $self->send_end("typelib", 1);
    }

    $self->send_end("typelibs");
    $self->{Handler}->end_document( $doc_obj );
}

sub process_lib {
    my $self = shift;
    my $lib = shift;

    # Load new type library
    my @def = @$lib[libNAME,libMAJOR,libMINOR,libLANGUAGE];
    $def[0] = quotemeta $def[0];
    my $tlib = Win32::OLE::Const->LoadRegTypeLib(@def);
    if (Win32::OLE->LastError) {
        die Win32::OLE->LastError;
    }

    my $tcount = $tlib->_GetTypeInfoCount;

    # Hide all interfaces mentioned in a COCLASS definition
    my %hide;
    for (0..$tcount-1) {
        my $tinfo = $tlib->_GetTypeInfo($_);
        ++$hide{$tinfo->_GetImplTypeInfo($_)->_GetTypeAttr->{guid}}
          foreach 0..$tinfo->_GetTypeAttr->{cImplTypes}-1;
    }

    my @Type;

    for (0..$tcount-1) {
        my $tinfo = $tlib->_GetTypeInfo($_);
        my $doc  = $tinfo->_GetDocumentation;
        my $attr = $tinfo->_GetTypeAttr;
        my $tflags = $attr->{wTypeFlags};
        next if $tflags & TYPEFLAG_FRESTRICTED;
        next if $hide{$attr->{guid}};
        next unless $icon[$attr->{typekind}];
        my $hidden = $tflags & TYPEFLAG_FHIDDEN;
        $hidden = 1 if $doc->{Name} =~ /^_/;
        push @Type, [$tlib, $tinfo, $doc, $attr, $hidden];
    }

    # Make a sorted index of visible Types
    my @Index = sort {
        my ($_a,$_b) = @Type[$a,$b];
        my $cmp = 0;
        if ($GroupByType) {
            my $ranka = $tkorder[$_a->[typeATTR]->{typekind}] || 0;
            my $rankb = $tkorder[$_b->[typeATTR]->{typekind}] || 0;
            $cmp = $ranka <=> $rankb;
        }
        $cmp || strcmp($_a->[typeDOC]->{Name}, $_b->[typeDOC]->{Name});
    } grep {
        $ShowHidden || !$Type[$_]->[typeHIDDEN]
    } 0..@Type-1;

    # Create structure for available types
    foreach (0..@Index-1) {
        my $id = $Index[$_];
        $self->send_start("type", 2);
        # name:
        $self->send_tag(name => $Type[$id]->[typeDOC]->{Name}, 3);

        # desc:
        $self->send_tag(description => $Type[$id]->[typeDOC]->{DocString}, 3);

        $self->send_start("members", 3);
        $self->process_members($Type[$id]);
        $self->send_end("members", 3);

        $self->send_end("type", 2);
    }
}

sub process_members {
    my $self = shift;
    my $type = shift;

    my @Members;

    my $tkind = $type->[typeATTR]->{typekind};
    if ($tkind == TKIND_COCLASS) {
	my ($dispatch,$event);
	my $tinfo = $type->[typeINFO];
	for my $impltype (0 .. $type->[typeATTR]->{cImplTypes}-1) {
	    my $tflags = $tinfo->_GetImplTypeFlags($impltype);
	    next unless $tflags & IMPLTYPEFLAG_FDEFAULT;
	    ($tflags & IMPLTYPEFLAG_FSOURCE ? $event : $dispatch) =
	      $tinfo->_GetImplTypeInfo($impltype);
	}
	addFunctions(\@Members, $dispatch);
	addFunctions(\@Members, $event, 'Event');
    }
    else {
	addFunctions(\@Members, $type->[typeINFO]);
        addVariables(\@Members, $type->[typeINFO]);
    }

    # Make a sorted index of visible Types
    my @Index = sort {
	my ($_a,$_b) = @Members[$a,$b];
	my $cmp = 0;
	if ($GroupByType) {
	    my $ranka = $mkorder{$_a->[membICON]} || 0;
	    my $rankb = $mkorder{$_b->[membICON]} || 0;
	    $cmp = $ranka <=> $rankb;
	}
	$cmp || strcmp($_a->[membDOC]->{Name}, $_b->[membDOC]->{Name});
    } grep {
	$ShowHidden || !$Members[$_]->[membHIDDEN]
    } 0..@Members-1;


    my @results;
    foreach my $index ( @Index ) {
        $self->send_start("member", 4);
        $self->getMemberInfo($Members[$index]);
        $self->send_end("member", 4);
    }

}

sub addFunctions {
    my $Members = shift;
    my ($tinfo, $event) = @_;
    return unless defined $tinfo;
    my $attr = $tinfo->_GetTypeAttr;
    my %property;
    for my $func (0 .. $attr->{cFuncs}-1) {
	my $desc = $tinfo->_GetFuncDesc($func);
	next if $desc->{wFuncFlags} & FUNCFLAG_FRESTRICTED;
	my $doc = $tinfo->_GetDocumentation($desc->{memid});
	my $name = $doc->{Name};
	my $invkind = $desc->{invkind};
	next if $event && $invkind != INVOKE_FUNC;

	if ($invkind != INVOKE_FUNC && exists $property{$name}) {
	    if ($invkind & (INVOKE_PROPERTYPUT | INVOKE_PROPERTYPUTREF)) {
		$Members->[$property{$name}]->[membREADONLY] = 0;
	    }
	    if ($invkind == INVOKE_PROPERTYGET) { # prefer GET syntax
		$Members->[$property{$name}]->[membDESC] = $desc;
	    }
	}
	else {
	    $property{$name} = scalar @{ $Members } if $invkind != INVOKE_FUNC;
	    my $icon = $invkind == INVOKE_FUNC ? ($event||'Function') : 'Property';
	    my $readonly = $invkind == INVOKE_PROPERTYGET;
	    my $hidden = $desc->{wFuncFlags} & FUNCFLAG_FHIDDEN;
	    $hidden = 1 if $doc->{Name} =~ /^_/;
	    push @{ $Members }, [$tinfo, $desc, $doc, $icon, $readonly, $hidden];
	}
    }
}

sub addVariables {
    my $Members = shift;
    my ($tinfo) = @_;
    return unless defined $tinfo;
    my $attr = $tinfo->_GetTypeAttr;
    for my $var (0 .. $attr->{cVars}-1) {
	my $desc = $tinfo->_GetVarDesc($var);
	next if $desc->{wVarFlags} & VARFLAG_FRESTRICTED;
	my $doc = $tinfo->_GetDocumentation($desc->{memid});
	push @{ $Members }, [$tinfo, $desc, $doc, 'Const'];
    }
}

sub getMemberInfo {
    my $self = shift;
    my $member = shift;

    my $doc = $member->[membDOC];

    # method name
    $self->send_tag(name => $doc->{Name}, 5);

    # method docs
    $self->send_tag(documentation => $doc->{DocString}, 5);

    # method type
    my $type = $member->[membICON];
    $self->send_tag(type => $type, 5);

    my $desc = $member->[membDESC];

    # Function declaration
    if (exists $desc->{wFuncFlags}) {
	my $tinfo = $member->[membTYPE];
	# Parameter names
	my $cParams = $desc->{cParams};
	my $names = $tinfo->_GetNames($desc->{memid}, $cParams+1);
	shift @$names;

	# Last arg of PROPERTYPUT is property type
	my $retval = ElemDesc($desc->{elemdescFunc});
	my $invkind = $desc->{invkind};
	$retval = ElemDesc($desc->{rgelemdescParam}->[--$cParams])
	  if $invkind == INVOKE_PROPERTYPUT ||
	     $invkind == INVOKE_PROPERTYPUTREF;

	# Decode function arguments
        my $tag_sent;
	for my $param (0 .. $cParams-1) {
            if (!$tag_sent) {
                $self->send_start("arguments", 5);
                $tag_sent++;
            }
	    my $elem = $desc->{rgelemdescParam}->[$param];
            my $arg_tag = {
                Name => "argument",
                Attributes => { ($elem->{wParamFlags} & PARAMFLAG_FOPT ? (optional => "yes") : () )}
                };
            $self->{Handler}->characters({ Data => "      " });
            $self->{Handler}->start_element($arg_tag);
            $self->new_line;

	    if (my $name = $names->[$param]) {
                $self->send_tag(name => $name, 7);
	    }
            $self->send_tag(type => ElemDesc($elem), 7);
	    if (defined $elem->{varDefaultValue}) {
		my $default = $elem->{varDefaultValue};
		# Lookup symbolic name in enum definition
		my $tinfo = $elem->{vt}->[-1];
		$default = getConstantName($tinfo, $default) if ref $tinfo;
                $self->send_tag(default => $default, 7) if $default ne '0';
	    }

            $self->{Handler}->characters({ Data => "      " });
            $self->{Handler}->end_element($arg_tag);
            $self->new_line;
	}

        if ($tag_sent) {
            $self->send_end("arguments", 5);
        }
        elsif ($type ne 'Property') {
            $self->send_tag(arguments => "", 5);
        }

	# Return type
        $self->send_tag(return_type => $retval, 5);
    }
    # Variable declaration
    elsif (exists $desc->{wVarFlags}) {
	my $value = $desc->{varValue};
	if ($value =~ /^-?\d+$/) {
            $self->send_tag(default => sprintf("0x%X", $value), 5);
	}
	else {
            $self->send_tag(default => "\"$value\"", 5);
	}
    }
}

sub getConstantName {
    my ($tinfo,$value) = @_;
    # XXX only int constants supported right now
    # ... everything else is treated as a string XXX
    return qq("$value") unless $value =~ /^-?\d+$/;

    my $attr = $tinfo->_GetTypeAttr;
    for my $var (0 .. $attr->{cVars}-1) {
	my $desc = $tinfo->_GetVarDesc($var);
	next if $desc->{wVarFlags} & VARFLAG_FRESTRICTED;
	return $tinfo->_GetDocumentation($desc->{memid})->{Name}
	  if $value == $desc->{varValue};
    }
    # sorry, not found (this is a typelib bug!)
    return $value;
}

sub ElemDesc {
    my $desc = shift;
    my $vt = $desc->{vt}->[-1];
    if (ref $vt) {
	return $vt->_GetDocumentation(-1)->{Name};
    }
    return $vt[$vt] || $VT[$vt];
}

# String comparison
# =================

sub strcmp {
    my ($x,$y) = @_;
    # skip leading underscores and translate to lowercase
    s/^_*(.*)/\l$1/ for $x, $y;
    return $x cmp $y;
}

sub send_tag {
    my $self = shift;
    my ($name, $contents, $indent) = @_;
    $self->{Handler}->characters({ Data => (" " x $indent) }) if $indent;
    $self->{Handler}->start_element({ Name => $name, Attributes => {} });
    $self->{Handler}->characters({ Data => $contents });
    $self->{Handler}->end_element({ Name => $name, Attributes => {} });
    $self->new_line;
}

sub send_start {
    my $self = shift;
    my ($name, $indent) = @_;
    $self->{Handler}->characters({ Data => (" " x $indent) }) if $indent;
    $self->{Handler}->start_element({ Name => $name, Attributes => {} });
    $self->new_line;
}

sub send_end {
    my $self = shift;
    my ($name, $indent) = @_;
    $self->{Handler}->characters({ Data => (" " x $indent) }) if $indent;
    $self->{Handler}->end_element({ Name => $name, Attributes => {} });
    $self->new_line;
}

sub new_line {
    my $self = shift;
    $self->{Handler}->characters({ Data => "\n" });
}

1;
__END__

=head1 NAME

XML::Generator::Win32OLETypeLib - Generate SAX (XML) from COM typelibs

=head1 SYNOPSIS

  use XML::Generator::Win32OLETypeLib;
  use XML::Handler::Something;
  my $handler = XML::Handler::Something->new();
  my $generator =
    XML::Generator::Win32OLETypeLib->new(Handler => $handler);
  $generator->find_typelib("ASFChop");

=head1 DESCRIPTION

Generates a representation of a COM type library and docs as SAX
events.

=head1 AUTHOR

Matt Sergeant, matt@sergeant.org (with kind permission from Star Internet)

=cut
