package XML::Parsepp;
$XML::Parsepp::VERSION = '0.08';
use 5.014;

use strict;
use warnings;

use Carp;

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT    = qw();
our @EXPORT_OK = qw();

sub new {
    my $class = shift;

    my %HParam = @_;

    my $self = { _Setters => {}, _Dupatt => '' };
    if ($HParam{Handlers}) {
        $self->{_Setters} = $HParam{Handlers};
    }
    if (defined $HParam{dupatt}) {
        my $cstr = $HParam{dupatt};

        unless ($cstr =~ m{\A [\x{21}-\x{bf}]* \z}xms) {
            croak("Error-0005: invalid dupatt");
        }
        if ($cstr =~ m{[0-9A-Za-z"']}xms) {
            croak("Error-0006: invalid dupatt");
        }

        $self->{_Dupatt} = $cstr;
    }

    bless $self, $class;
}

sub setHandlers {
    my $self = shift;

    %{$self->{_Setters}} = (%{$self->{_Setters}}, @_);
}

sub parsefile {
    my $self = shift;

    my ($inpname) = @_;

    open my $ifh, '<', $inpname or croak("Error-0010: Can't open < '$inpname' because $!");
    $self->_process_handle($ifh);
    close $ifh;
}

sub parse {
    my $self = shift;

    my ($pitem) = @_;

    if (ref($pitem) eq 'GLOB') {
        $self->_process_handle($pitem);
    }
    else {
        open my $ifh, '<', \$pitem or croak("Error-0020: Can't open < \\'...' because $!");
        $self->_process_handle($ifh);
        close $ifh;
    }
}

sub _process_handle {
    my $self = shift;

    my ($fh) = @_;

    my $ExpatNB = $self->parse_start
      or croak("Error-0030: Can't XML::Parsepp->parse_start");
 
    while (1) {
         # Here is the all important reading of a chunk of XML-data from the filehandle...
        read($fh, my $buf, 4096);
 
        # We leave immediately as soon as there is no more data left (EOF)
        last if $buf eq '';
 
        # and here is the all important parsing of that chunk:
        # and we could get exceptions thrown here if the XML is invalid...
        $ExpatNB->parse_more($buf);
    }

    $ExpatNB->parse_done;
}

sub parse_start {
    my $self = shift;

    my $ExpatNB = {
        _Setters     => $self->{_Setters},
        _Dupatt      => $self->{_Dupatt},
        _Text        => '',
        _Action      => 'C', # DEFACT: 'C' = character data
        _Stage       => 1,   # DEFSTA: 1 = XMLDecl, 2 = DTD, 3 = StartTag/EndTag, 4 = Rest
        _QChar       => '',
        _ItemCount   => 0,
        _DoctCount   => 0,
        _Stack       => [],
        _Scount      => 0,
        _Seen        => {},
        _DocOpen     => 0,
        _Read_Bytes  => 2,
        _Read_Lines  => 1,
        _Read_Cols   => 2,

        # Structure of '_Var':
        # ====================
        #   L => a simple replacement character
        #   F => $system is a file name, the content of which will be processed
        #   T => $value is a replacement text

        _Var         => {
          'amp'  => [L => q{&}],
          'lt'   => [L => q{<}],
          'gt'   => [L => q{>}],
          'quot' => [L => q{"}],
          'apos' => [L => q{'}],
        },
    };

    %$ExpatNB = (%$ExpatNB, @_);

    bless $ExpatNB, 'XML::Parsepp::ExpatNB';

    $ExpatNB->_emit_Init;

    return $ExpatNB;
}

package XML::Parsepp::ExpatNB;
$XML::Parsepp::ExpatNB::VERSION = '0.08';
our $version = '0.06';

use Carp;
use File::Spec;

sub regexp_pattern {
    my ($fl, $pn) = $_[0] =~ m{\A \( \? ([\w\^\-]*) : (.*?) \) \z}xms
      or die "Error-0040: Internal Error - Can't disassemble quoted regexp = '$_[0]'";
    return ($pn, $fl);
}

sub negated {
    my ($pattern, $flags) = regexp_pattern($_[0]);
    my ($caret, $class) =
      $pattern =~ m{\A \[ (\^?) (.*?) \] \z}xms
      or die "Error-0050: Internal Error - Can't parse regexp: $_[0] ==> (pattern = '$pattern', flags = '$flags')";

    my $neg_caret = $caret eq '^' ? '' : '^';
    my $neg_regexp = qr{[$neg_caret$class]}xms;

    return $neg_regexp;
} 

my $rx_unc_tok = qr/["']/xms;
my $rx_tok_tok = qr/[!\$&\/;<=\@\\\^`\{\}~\x7f]/xms;
my $rx_syn_tok = qr/[\#\(\]]/xms;
my $rx_tok_syn = qr/[%)*+?]/xms;
my $rx_syn_syn = qr/[,\-.\w:\[|]/xms;

my $ng_unc_tok = negated($rx_unc_tok);
my $ng_tok_tok = negated($rx_tok_tok);
my $ng_syn_tok = negated($rx_syn_tok);
my $ng_tok_syn = negated($rx_tok_syn);
my $ng_syn_syn = negated($rx_syn_syn);

sub parse_more {
    my $self = shift;

    $self->_more(0, '', $_[0]);
}

sub _more {
    my $self  = shift;
    my $level = shift;
    my $hist  = shift;

    my $buffer_text = $self->{_Text}.$_[0]; # Take whatever there was before and add the new parse_more parameter
    $self->{_Text} = '';

    my @buffer_stack = @{$self->{_Stack}};
    $self->{_Stack} = [];

    if (length($buffer_text) > 100_000) {
        $self->crknum("Error-0060: Internal Error - Buffer overflow");
    }

    my $buffer_action = $self->{_Action};

    my $buffer_breakout = 0;
    until ($buffer_breakout or $buffer_text eq '') {
        if ($buffer_action eq 'C') { # DEFACT: 'C' = character data
            if ($self->{_Stage} <= 2) {

                my ($emit, $ch, $remainder);
                if ($buffer_text =~ m{\A (\s*) (\S) (.*) \z}xms) {
                    ($emit, $ch, $remainder) = ($1, $2, $3);
                }
                elsif ($buffer_text =~ m{\A \s* \z}xms) {
                    ($emit, $ch, $remainder) = ($buffer_text, '', '');
                }
                else {
                    $self->crknum("Error-0070: Internal Error - Can't parse buffer_text = '$buffer_text'");
                }

                $self->_emit_Char($emit);
                $self->_update_ctr($emit) if $level == 0;

                if ($ch eq '') {
                    $buffer_text     = '';
                    $buffer_breakout = 1;
                }
                elsif ($ch eq '<') {
                    $buffer_text   = $ch.$remainder;
                    $buffer_action = '<'; # DEFACT: '<' = anything that starts with '<'
                    next;
                }
                elsif ($ch eq ']' and $self->{_DocOpen} > 0) {
                    $buffer_text   = $ch.$remainder;
                    $buffer_action = ']'; # DEFACT: ']' = anything that starts with ']'
                    next;
                }
                elsif ($ch eq q{'} or $ch eq q{"}) {
                    $self->_update_ctr($ch) if $level == 0;
                    $buffer_text    = $remainder;
                    $self->{_QChar} = $ch;
                    $buffer_action  = 'F'; # DEFACT: 'F' = find quote character $self->{_QChar}
                    next;
                }
                elsif ($ch eq '>') {
                    $self->crknum("Error-0080: syntax error");
                }
                elsif ($ch =~ $rx_syn_syn) {
                    $self->_update_ctr($ch) if $level == 0;
                    $buffer_text    = $remainder;
                    $buffer_action  = 'G'; # DEFACT: 'G' = find word delimited by white-space
                    next;
                }
                elsif ($ch =~ $rx_syn_tok) {
                    $self->crknum("Error-0090: syntax error");
                }
                else {
                    $self->crknum("Error-0100: not well-formed (invalid token)");
                }
            }
            else {
                if ($buffer_text =~ m{\A ([^<&]*) ([<&]) (.*) \z}xms) {
                    my ($emit, $ch, $remainder) = ($1, $2, $3);

                    $self->_emit_Char($emit);
                    $self->_update_ctr($emit) if $level == 0;
                    $buffer_text   = $ch.$remainder;
                    $buffer_action = $ch; # DEFACT: '<' = anything that starts with '<' or '&' = anything that starts with '&'
                    next;
                }

                $self->_emit_Char($buffer_text);
                $self->_update_ctr($buffer_text) if $level == 0;
                $buffer_text     = '';
                $buffer_breakout = 1;
                next;
            }
        }
        elsif ($buffer_action eq 'F') {
            my ($emit, $ch, $remainder);

            if ($self->{_QChar} eq q{'}) {
                if ($buffer_text =~ m{\A ([^']*) (') (.*) \z}xms) {
                    ($emit, $ch, $remainder) = ($1, $2, $3);
                }
                else {
                    ($emit, $ch, $remainder) = ($buffer_text, '', '');
                }
            }
            elsif ($self->{_QChar} eq q{"}) {
                if ($buffer_text =~ m{\A ([^"]*) (") (.*) \z}xms) {
                    ($emit, $ch, $remainder) = ($1, $2, $3);
                }
                else {
                    ($emit, $ch, $remainder) = ($buffer_text, '', '');
                }
            }
            else {
                $self->crknum("Error-0110: Internal Error - invalid QChar = '".$self->{_QChar}."'");
            }

            $self->_update_ctr($emit) if $level == 0;

            if ($ch eq '') {
                $buffer_text     = '';
                $buffer_breakout = 1;
                next;
            }
            else {
                $self->crknum("Error-0120: not well-formed (invalid token)");
            }
        }
        elsif ($buffer_action eq 'G') {
            my ($emit, $ch, $remainder);

            if ($buffer_text =~ m{\A (\S*) (\s) (.*) \z}xms) {
                ($emit, $ch, $remainder) = ($1, $2, $3);
            }
            else {
                ($emit, $ch, $remainder) = ($buffer_text, '', '');
            }

            $self->_update_ctr($emit) if $level == 0;

            if ($emit =~ m{($ng_syn_syn)}xms) {
                my $out = $1;
                if ($out =~ $rx_tok_syn or $out eq '>') {
                    $self->crknum("Error-0130: syntax error");
                }
                else {
                    $self->crknum("Error-0140: not well-formed (invalid token)");
                }
            }
            else {
                if ($ch eq '') {
                    $buffer_text     = '';
                    $buffer_breakout = 1;
                    next;
                }
                else {
                    $self->crknum("Error-0150: syntax error");
                }
            }
        }
        elsif ($buffer_action eq '&') { # DEFACT: '&' = anything that starts with '&'
            if ($buffer_text =~ m{\A . ([^<;]*) ([<;]) (.*) \z}xms) {
                my ($emit, $ch, $remainder) = ($1, $2, $3);
                unless ($ch eq ';') {
                    $self->crknum("Error-0160: not well-formed (invalid token)");
                }
                $self->_emit_Amp($level, $hist, '&'.$emit.';');
                $self->_update_ctr('&'.$emit.';') if $level == 0;
                $buffer_text   = $remainder;
                $buffer_action = 'C'; # DEFACT: 'C' = character data
                next;
            }
            $buffer_breakout = 1;
            next;
        }
        elsif ($buffer_action eq '<') { # DEFACT: '<' = anything that starts with '<'
            if (length($buffer_text) < 3) {
                $buffer_breakout = 1;
                next;
            }
            my $c1 = substr($buffer_text, 0, 1);
            my $c2 = substr($buffer_text, 1, 1);
            my $c3 = substr($buffer_text, 2, 1);

            if ($c2 eq '!' and $c3 eq '-') {
                $buffer_action = '!'; # DEFACT: '<!-- ... -->' a comment
                next;
            }
            if ($c2 eq '!' and $c3 eq '[') {
                $buffer_action = 'A'; # DEFACT: '<![CDATA[ ... ]]>' a CDATA section
                next;
            }
            if ($c2 eq '!' and $c3 =~ m{\w}xms) {
                $buffer_action = 'D'; # DEFACT: '<!DOCTYPE [ ... ]>' a DTD section (DOCTYPE, ELEMENT, ATTLIST, etc...)
                next;
            }
            if ($c2 =~ m{[,\-.\w:\[|]}xms) {
                $buffer_action = 'S'; # DEFACT: 'S' = start tag <abc attr1='abc' attr2="def" />
                next;
            }
            if ($c2 eq '/') {
                $buffer_action = 'E'; # DEFACT: 'E' = end tag </abc>
                next;
            }
            if ($c2 eq '?') {
                $buffer_action = '?'; # DEFACT: '?' = processing instruction <?abc def?>
                next;
            }
            $self->crknum("Error-0170: not well-formed (invalid token)");
        }
        elsif ($buffer_action eq '!') { # DEFACT: '<!-- ... -->' a comment
            if (length($buffer_text) < 4) {
                $buffer_breakout = 1;
                next;
            }
            my $prefix = substr($buffer_text, 0, 4);
            unless ($prefix eq '<!--') {
                $self->crknum("Error-0180: not well-formed (invalid token)");
            }
            if ($buffer_text =~ m{\A (.*? -->) (.*) \z}xms) {
                my ($emit, $remainder) = ($1, $2);
                $self->_emit_Comment($emit);
                $self->_update_ctr($emit) if $level == 0;
                $buffer_text = $remainder;
                $buffer_action = 'C'; # DEFACT: 'C' = character data
                next;
            }
            $buffer_breakout = 1;
            next;
        }
        elsif ($buffer_action eq 'A') { # DEFACT: '<![CDATA[ ... ]]>' beginning of a CDATA section
            if (length($buffer_text) < 9) {
                $buffer_breakout = 1;
                next;
            }
            my $prefix    = substr($buffer_text, 0, 9);
            my $remainder = substr($buffer_text, 9);
            unless ($prefix eq '<![CDATA[') {
                $self->crknum("Error-0190: not well-formed (invalid token)");
            }
            $self->_emit_Cdatastart;
            $self->_update_ctr($prefix) if $level == 0;

            $buffer_text = $remainder;
            $buffer_action = 'B'; # DEFACT: 'B' = '<![CDATA[ ... ]]>' text of a CDATA section
            next;
        }
        elsif ($buffer_action eq 'B') { # DEFACT: 'B' = '<![CDATA[ ... ]]>' text of a CDATA section
            if ($buffer_text =~ m{\A (.*?) (\]\]>) (.*) \z}xms) {
                my ($emit, $suffix, $remainder) = ($1, $2, $3);
                $self->_emit_Char($emit);
                $self->_update_ctr($emit) if $level == 0;

                $self->_emit_Cdataend;
                $self->_update_ctr($suffix) if $level == 0;

                $buffer_text   = $remainder;
                $buffer_action = 'C'; # DEFACT: 'C' = character data
                next;
            }
            $self->_emit_Char($buffer_text);
            $self->_update_ctr($buffer_text) if $level == 0;
            $buffer_text     = '';
            $buffer_breakout = 1;
            next;
        }
        # pour identifier les differents possibilites de DTD (DOCTYPE, ELEMENT, ATTLIST, etc...), voir: http://www.u-picardie.fr/~ferment/xml/xml02.html
        elsif ($buffer_action eq 'D') { # DEFACT: '<!DOCTYPE [ ... ]>' a DTD section (DOCTYPE, ELEMENT, ATTLIST, etc...)
            my $finpos = -1;
            pos($buffer_text) = 0;
            while ($buffer_text =~ m{\G \s* (?: ([^'"\s]+) | ' [^']* ' | " [^"]* " ) }xmsgc) {
                if (defined $1) {
                    my $mp = $-[1];
                    my $fragment = $1;
                    if ($fragment =~ m{[>\[]}xms) {
                        $finpos = $mp + $-[0];
                        last;
                    }
                }
            }

            if ($finpos != -1) {
                my $terminal = substr $buffer_text, $finpos, 1;
                unless ($terminal eq '>' or $terminal eq '[') {
                    $self->crknum("Error-0200: Internal Error - found terminal char ('$terminal') not equal to ('>', '[')");
                }
                my $emit = substr($buffer_text, 0, $finpos + 1);
                $self->_emit_Dtd($emit);
                $self->_update_ctr($emit) if $level == 0;
                $buffer_text = substr($buffer_text, $finpos + 1);
                $buffer_action = 'C'; # DEFACT: 'C' = character data
                next;
            }
            $buffer_breakout = 1;
            next;
        }
        elsif ($buffer_action eq ']') { # DEFACT: ']' = closing doctype parenthesis ']>'
            if (length($buffer_text) < 2) {
                $buffer_breakout = 1;
                next;
            }

            unless ($self->{_DocOpen}) {
                $self->crknum("Error-0210: Internal Error - Can't close a closed Doctype");
            }

            unless ($buffer_text =~ m{\A (\] \s* >) (.*) \z}xms) {
                $self->crknum("Error-0220: not well-formed (invalid token)");
            }
            my ($emit, $remainder) = ($1, $2);

            $self->_emit_CloseDoc($emit);
            $self->_update_ctr($emit) if $level == 0;
            $buffer_text = $remainder;
            $buffer_action = 'C'; # DEFACT: 'C' = character data
            next;
        }
        elsif ($buffer_action eq 'S') { # DEFACT: 'S' = start tag <abc attr1='abc' attr2="def" />
            my $finpos = -1;
            pos($buffer_text) = 0;
            while ($buffer_text =~ m{\G \s* (?: ([^'"\s]+) | ' [^']* ' | " [^"]* " ) }xmsgc) {
                if (defined $1) {
                    my $mp = $-[1];
                    my $fragment = $1;
                    if ($fragment =~ m{>}xms) {
                        $finpos = $mp + $-[0];
                        last;
                    }
                }
            }

            if ($finpos != -1) {
                my $emit = substr($buffer_text, 0, $finpos + 1);
                $self->_emit_Start($emit, \@buffer_stack, $level);
                $self->_update_ctr($emit) if $level == 0;
                $buffer_text = substr($buffer_text, $finpos + 1);
                $buffer_action = 'C'; # DEFACT: 'C' = character data
                next;
            }
            $buffer_breakout = 1;
            next;
        }
        elsif ($buffer_action eq 'E') { # DEFACT: 'E' = end tag </abc>
            if ($buffer_text =~ m{\A ([^>]* [>]) (.*) \z}xms) {
                my ($emit, $remainder) = ($1, $2);
                $self->_emit_End($emit, \@buffer_stack, $hist);
                $self->_update_ctr($emit) if $level == 0;
                $buffer_text = $remainder;
                $buffer_action = 'C'; # DEFACT: 'C' = character data
                next;
            }
            $buffer_breakout = 1;
            next;
        }
        elsif ($buffer_action eq '?') { # DEFACT: '?' = processing instruction <?abc def?> 
            if ($buffer_text =~ m{\A ([^>]* [>]) (.*) \z}xms) {
                my ($emit, $remainder) = ($1, $2);
                $self->_emit_Proc($emit);
                $self->_update_ctr($emit) if $level == 0;
                $buffer_text = $remainder;
                $buffer_action = 'C'; # DEFACT: 'C' = character data
                next;
            }
            $buffer_breakout = 1;
            next;
        }
        else {
            $self->crknum("Error-0230: Internal Error - invalid buffer_action = '$buffer_action'");
        }
    }

    $self->{_Text}   = $buffer_text;
    $self->{_Stack}  = [@buffer_stack];
    $self->{_Action} = $buffer_action;
}

sub _emit_Init {
    my $self = shift;

    my $cb_Init = $self->{_Setters}{Init};
    if ($cb_Init) {
        $cb_Init->($self);
    }
}

sub _emit_Final {
    my $self = shift;

    my $cb_Final = $self->{_Setters}{Final};
    if ($cb_Final) {
        $cb_Final->($self);
    }
}

sub _emit_Amp {
    my $self  = shift;
    my $level = shift;
    my $hist  = shift;

    my ($ampersand) = @_;

    my ($var) = $ampersand =~ m{\A & ([^&;]+) ; \z}xms
      or $self->crknum("Error-0240: Internal Error - Can't parse ampersand = '$ampersand'");

    if ($var =~ m{\A \# (\d+) \z}xms) {
        my $value = chr($1);

        $self->_plausi('C'); # PLAUSI ==> 'C' = Character Data

        $self->{_ItemCount}++;

        my $cb_Char = $self->{_Setters}{Char};
        if ($cb_Char) {
            $cb_Char->($self, $value);
        }
    }
    else {
        my $rhs = $self->{_Var}{$var};

        unless (defined $rhs) {
            if ($level == 0) {
                $self->crknum("Error-0250: undefined entity");
            }
            else {
                $self->crknum("Error-0260: error in processing external entity reference");
            }
        }

        my ($code, $value) = @$rhs;

        # Structure of ($code, $value):
        # =============================
        #   L => a simple replacement character
        #   F => $system is a file name, the content of which will be processed
        #   T => $value is a replacement text

        if ($code eq 'L') {
            $self->_plausi('C'); # PLAUSI ==> 'C' = Character Data

            $self->{_ItemCount}++;

            my $cb_Char = $self->{_Setters}{Char};
            if ($cb_Char) {
                $cb_Char->($self, $value);
            }
        }
        elsif ($code eq 'F') {
            if ($self->{_Seen}{$var}) {
                $self->crknum("Error-0270: error in processing external entity reference");
            }
            $self->{_Seen}{$var} = 1;

            my $cb_Exen = $self->{_Setters}{ExternEnt};
            if ($cb_Exen) {
                # ExternEnt (Expat, Base, Sysid, Pubid)
                my $buf = $cb_Exen->($self, undef, $value, undef);

                $self->_more($level + 1, $hist.'X', $buf);

                my $cb_Exef = $self->{_Setters}{ExternEntFin};
                if ($cb_Exef) {
                    # ExternEntFin (Expat)
                    my $buf = $cb_Exef->($self);
                }

                unless ($self->{_Text} eq '') {
                    $self->crknum("Error-0280: error in processing external entity reference");
                }
                if (@{$self->{_Stack}}) {
                    $self->crknum("Error-0290: error in processing external entity reference");
                }
            }
            else {
                my $filepath = File::Spec->rel2abs($value);
                open my $ifh, '<', $value
                  or $self->crknum("Error-0300: Handler couldn't resolve external entity\n"."404 File `$filepath' does not exist");

                while (1) {
                    read($ifh, my $buf, 4096);
                    last if $buf eq '';

                    $self->_more($level + 1, $hist.'F', $buf);
                }

                close $ifh;

                unless ($self->{_Text} eq '') {
                    $self->crknum("Error-0310: error in processing external entity reference");
                }
                if (@{$self->{_Stack}}) {
                    $self->crknum("Error-0320: error in processing external entity reference");
                }
            }

            $self->{_Seen}{$var} = 0;
        }
        elsif ($code eq 'T') {
            if ($self->{_Seen}{$var}) {
                $self->crknum("Error-0330: recursive entity reference");
            }
            $self->{_Seen}{$var} = 1;

            $self->_more($level + 1, $hist.'T', $value);

            unless ($self->{_Text} eq '') {
                $self->crknum("Error-0340: unclosed token");
            }
            if (@{$self->{_Stack}}) {
                $self->crknum("Error-0350: asynchronous entity");
            }

            $self->{_Seen}{$var} = 0;
        }
        else {
            $self->crknum("Error-0360: Internal Error - Found invalid code '$code' not equal to ('F', 'L', 'T')");
        }
    }
}

sub _emit_Char {
    my $self = shift;
    my ($emit) = @_;

    $self->_plausi('C'); # PLAUSI ==> 'C' = Character Data

    my $default = 0;

    unless ($self->{_Stage} == 3) {
        $default = 1;
        if ($emit =~ m{\S}xms) {
            if ($self->{_Stage} == 4) {
                $self->crknum("Error-0370: junk after document element");
            }
            else {
                $self->crknum("Error-0380: Internal Error - non-space data");
            }
        }
    }

    if ($default) {
        unless ($emit eq '') {

            $self->{_ItemCount}++;

            my $cb_Default = $self->{_Setters}{Default};
            if ($cb_Default) {
                # Default (Expat, String)
                $cb_Default->($self, $emit);
            }
        }
    }
    else {
        pos($emit) = 0;
        while ($emit =~ m{\G (?: ([^\n]+) | ([\n]) ) }xmsgc) {
            my $fragment;
            if (defined $1) {
                $fragment = $1;
            }
            elsif (defined $2) {
                $fragment = $2;
            }
            else {
                $self->crknum("Error-0390: Internal Error - inconsistent result from regexp");
            }

            unless ($fragment eq '') {
                $self->{_ItemCount}++;

                my $cb_Char = $self->{_Setters}{Char};
                if ($cb_Char) {
                    $cb_Char->($self, $fragment);
                }
            }
        }
        unless ($emit =~ m{\G (.*) \z}xms) {
            $self->crknum("Error-0400: Internal Error - Can't find regexp rest in CHAR");
        }
        my $rest = $1;
        if ($rest ne '') {
            $self->crknum("Error-0410: Internal Error - Invalid rest ($rest) in CHAR regexp");
        }
    }
}

sub _emit_Start {
    my $self = shift;
    my ($emit, $bstack, $level) = @_;

    my ($elem, $param, $term) = $emit =~ m{\A < \s* ([,\-.\w:\[|]+) (.*?) (/?) > \z}xms
      or $self->crknum("Error-0420: Internal Error - Can't decompose start = '$emit'");

    my @attr;
    my %att_hash;

    pos($param) = 0;
    while ($param =~ m{\G \s* ([,\-.\w:\[|]+) \s* = \s* (?: ' ([^']*) ' | " ([^"]*) " ) }xmsgc) {
        my $def_var = $1;
        my $def_txt;
        if (defined $2) {
            $def_txt = $2;
        }
        elsif (defined $3) {
            $def_txt = $3;
        }
        else {
            $self->crknum("Error-0430: Internal Error - Can't match any param");
        }

        if ($def_txt =~ m{<}xms) {
            $self->crknum("Error-0440: not well-formed (invalid token)");
        }

        $def_txt =~ s{\n}' 'xmsg;
        my $def_res = '';

        pos($def_txt) = 0;
        while ($def_txt =~ m{\G ([^&]*) & ([^&;]+) ; }xmsgc) {
            $def_res .= $1;
            my $var = $2;
            my $rhs = $self->{_Var}{$var};

            unless (defined $rhs) {
                $self->crknum("Error-0450: undefined entity");
            }

            my ($code, $value) = @$rhs;

            # Structure of ($code, $value):
            # =============================
            #   L => a simple replacement character
            #   F => $system is a file name, the content of which will be processed
            #   T => $value is a replacement text

            unless ($code eq 'L') {
                $self->crknum("Error-0460: reference to external entity in attribute");
            }

            $def_res .= $value;
        }
        unless ($def_txt =~ m{\G (.*) \z}xms) {
            $self->crknum("Error-0470: Internal Error - Can't find regexp rest in ELEMENT");
        }

        my $rest = $1;
        if ($rest =~ m{&}xms) {
            $self->crknum("Error-0480: not well-formed (invalid token)");
        }

        $def_res .= $rest;

        if (defined $att_hash{$def_var}) {
            if ($self->{_Dupatt} eq '') {
                $self->crknum("Error-0485: duplicate attribute");
            }
            $att_hash{$def_var} .= $self->{_Dupatt}.$def_res;
        }
        else {
            $att_hash{$def_var} = $def_res;
        }

        push @attr, $def_var, $def_res;
    }
    unless ($param =~ m{\G (.*) \z}xms) {
        $self->crknum("Error-0490: Internal Error - Can't find regexp rest in START");
    }

    my $rest = $1;
    if ($rest =~ m{\S}xms) {
        if ($level == 0) {
            $self->crknum("Error-0500: not well-formed (invalid token)");
        }
        else {
            $self->crknum("Error-0510: error in processing external entity reference");
        }
    }

    unless ($self->{_Dupatt} eq '') {
        @attr = map { $_ => $att_hash{$_} } sort(keys %att_hash);
    }

    $self->_plausi('S'); # PLAUSI ==> 'S' = Start Tag

    $self->{_Scount}++;
    push @$bstack, $elem;

    $self->{_ItemCount}++;

    my $cb_Start = $self->{_Setters}{Start};
    if ($cb_Start) {
        # Start (Expat, Element [, Attr, Val [,...]])
        $cb_Start->($self, $elem, @attr);
    }

    if ($term eq '/') {
        if ($self->{_Scount} < 1) {
            $self->crknum("Error-0520: Internal Error - Underflow in Scount");
        }
        $self->{_Scount}--;

        my $ele_from_stack = pop @$bstack;
        unless (defined $ele_from_stack) {
            $self->crknum("Error-0530: Internal Error - Underflow in stack");
        }

        unless ($elem eq $ele_from_stack) {
            $self->crknum("Error-0540: Internal Error - Mismatch of Start- and End-tag, start = '$ele_from_stack', end = '$elem'");
        }

        $self->_plausi('E'); # PLAUSI ==> 'E' = End Tag

        $self->{_ItemCount}++;

        my $cb_End = $self->{_Setters}{End};
        if ($cb_End) {
            # End (Expat, Element)
            $cb_End->($self, $elem);
        }
    }
    elsif ($term ne '') {
        $self->crknum("Error-0550: Internal Error - in START found closing tag '$term'");
    }
}

sub _emit_End {
    my $self = shift;
    my ($emit, $bstack, $hist) = @_;

    my ($elem) = $emit =~ m{\A < \s* / \s* ([,\-.\w:\[|]+) \s* > \z}xms
      or $self->crknum("Error-0560: not well-formed (invalid token)");

    if ($self->{_Scount} < 1) {
        $self->crknum("Error-0570: not well-formed (invalid token)");
    }
    $self->{_Scount}--;

    my $ele_from_stack = pop @$bstack;
    unless (defined $ele_from_stack) {
        if ($hist =~ m{F}xms) {
            $self->crknum("Error-0580: error in processing external entity reference");
        }
        else {
            $self->crknum("Error-0590: asynchronous entity");
        }
    }

    unless ($elem eq $ele_from_stack) {
        $self->crknum("Error-0600: mismatched tag");
    }

    $self->_plausi('E'); # PLAUSI ==> 'E' = End Tag

    $self->{_ItemCount}++;

    my $cb_End = $self->{_Setters}{End};
    if ($cb_End) {
        # End (Expat, Element)
        $cb_End->($self, $elem);
    }
}

sub _emit_Proc {
    my $self = shift;
    my ($emit) = @_;

    my ($target, $data) = $emit =~ m{\A <\? ([,\-.\w:\[|]+) \s* (.*) \?> \z}xms
      or $self->crknum("Error-0610: not well-formed (invalid token)");

    if ($target =~ m{\A xml}xmsi) {
        unless ($self->{_ItemCount} == 0) {
            $self->crknum("Error-0620: XML or text declaration not at start of entity");
        }

        my @attr;
        pos($data) = 0;

        while ($data =~ m{\G \s* ([,\-.\w:\[|]+) \s* = \s* (?: ' ([^']*) ' | " ([^"]*) " ) }xmsgc) {
            if (defined $2) {
                push @attr, [$1, $2];
            }
            elsif (defined $3) {
                push @attr, [$1, $3];
            }
            else {
                $self->crknum("Error-0630: Internal Error - Can't match any param");
            }
        }

        unless ($data =~ m{\G (.*) \z}xms) {
            $self->crknum("Error-0640: Internal Error - Can't find regexp rest in PROC");
        }

        my $rest = $1;
        if ($rest =~ m{\S}xms) {
            $self->crknum("Error-0650: XML declaration not well-formed");
        }

        # <?xml version="1.0" encoding="ISO-8859-1" standalone="no"?>
        my ($ver, $enc, $stand);

        for my $at (@attr) {
            if ($at->[0] eq 'version') {
                if (defined $ver) {
                    $self->crknum("Error-0660: XML declaration not well-formed");
                }
                $ver = $at->[1];
            }
            elsif ($at->[0] eq 'encoding') {
                if (defined $enc) {
                    $self->crknum("Error-0670: XML declaration not well-formed");
                }
                $enc = $at->[1];
            }
            elsif ($at->[0] eq 'standalone') {
                if (defined $stand) {
                    $self->crknum("Error-0680: XML declaration not well-formed");
                }
                if ($at->[1] eq 'yes') {
                    $stand = '1';
                }
                elsif ($at->[1] eq 'no') {
                    $stand = '';
                }
                else {
                    $self->crknum("Error-0690: XML declaration not well-formed");
                }
            }
            else {
                $self->crknum("Error-0700: XML declaration not well-formed");
            }
        }
        unless (defined $ver) {
            $self->crknum("Error-0710: XML declaration not well-formed");
        }

        $self->_plausi('X'); # PLAUSI ==> 'X' = XML Declaration

        $self->{_ItemCount}++;

        my $cb_Decl = $self->{_Setters}{XMLDecl};
        if ($cb_Decl) {
            # XMLDecl (Expat, Version, Encoding, Standalone)
            $cb_Decl->($self, $ver, $enc, $stand);
        }
    }
    else {
        $self->_plausi('P'); # PLAUSI ==> 'P' = Processing Instruction

        $self->{_ItemCount}++;

        my $cb_Proc = $self->{_Setters}{Proc};
        if ($cb_Proc) {
            # Proc (Expat, Target, Data)
            $cb_Proc->($self, $target, $data);
        }
    }
}

sub _emit_Comment {
    my $self = shift;
    my ($emit) = @_;

    my ($comment) = $emit =~ m{\A <!-- (.*?) --> \z}xms or
      $self->crknum("Error-0720: Internal Error - Can't decompose comment '$emit'");

    $self->_plausi('!'); # PLAUSI ==> '!' = comment

    $self->{_ItemCount}++;

    my $cb_Comment = $self->{_Setters}{Comment};
    if ($cb_Comment) {
        $cb_Comment->($self, $comment);
    }
}

sub _emit_Cdatastart {
    my $self = shift;

    $self->_plausi('A'); # PLAUSI ==> 'A' = CData

    my $cb_CdataStart = $self->{_Setters}{CdataStart};
    if ($cb_CdataStart) {
        $cb_CdataStart->($self);
    }
}

sub _emit_Cdataend {
    my $self = shift;

    $self->_plausi('A'); # PLAUSI ==> 'A' = CData

    my $cb_CdataEnd = $self->{_Setters}{CdataEnd};
    if ($cb_CdataEnd) {
        $cb_CdataEnd->($self);
    }
}

sub _emit_CloseDoc {
    my $self = shift;
    my ($emit) = @_;

    $emit =~ m{\A \] \s* > \z}xms
      or $self->crknum("Error-0730: Internal Error - Invalid closedoc: '$emit'");

    unless ($self->{_DocOpen}) {
        $self->crknum("Error-0740: Internal Error - closedoc found without DocOpen");
    }

    $self->_plausi('F'); # PLAUSI ==> 'F' = DocTypeFin

    $self->{_DocOpen} = 0;

    my $cb_DoctypeFin = $self->{_Setters}{DoctypeFin};
    if ($cb_DoctypeFin) {
        # DoctypeFin (Expat)
        $cb_DoctypeFin->($self);
    }
}

sub _emit_Dtd {
    my $self = shift;
    my ($emit) = @_;

    if ($self->{_Stage} > 2) {
        $self->crknum("Error-0750: not well-formed (invalid token)");
    }

    my ($type, $data, $term) = $emit =~ m{\A <! (\w+) \s+ (\S .*) ([\[>]) \z}xms
      or $self->crknum("Error-0760: not well-formed (invalid token)");

    my @elist;
    pos($data) = 0;
    while ($data =~ m{\G \s* (?: ([^'"\(\s]+) | ' ([^']*) ' | " ([^"]*) " | \( ([^\)]*) \) ) }xmsgc) {
        if (defined $1) {
            push @elist, ['B' => $1];
        }
        elsif (defined $2) {
            push @elist, ['Q' => $2, q{'}];
        }
        elsif (defined $3) {
            push @elist, ['Q' => $3, q{"}];
        }
        elsif (defined $4) {
            my $paran = $4;
            $paran =~ s{\s}''xmsg;
            push @elist, ['P' => $paran];
        }
        else {
            $self->crknum("Error-0770: Internal Error - regexp undefined");
        }
    }

    unless ($data =~ m{\G (.*) \z}xms) {
        $self->crknum("Error-0780: Internal Error - Can't find regexp rest");
    }

    my $rest = $1;
    if ($rest =~ m{\S}xms) {
        $self->crknum("Error-0790: syntax error");
    }

    if ($type eq 'DOCTYPE') {
        $self->_parse_Doctype(\@elist, $term);
    }
    elsif ($type eq 'ENTITY') {
        $self->_parse_Entity(\@elist);
    }
    elsif ($type eq 'ELEMENT') {
        $self->_parse_Element(\@elist);
    }
    elsif ($type eq 'ATTLIST') {
        $self->_parse_Attlist(\@elist);
    }
    elsif ($type eq 'NOTATION') {
        $self->_parse_Notation(\@elist);
    }
    else {
        $self->crknum("Error-0800: syntax error");
    }

    unless ($type eq 'DOCTYPE' or $term eq '>') {
        $self->crknum("Error-0810: syntax error");
    }
}

sub _parse_Doctype {
    my $self = shift;
    my ($plist, $terminal) = @_;

    $self->{_DoctCount}++;
    unless ($self->{_DoctCount} == 1) {
        $self->crknum("Error-0820: syntax error");
    }

    # <!DOCTYPE racine SYSTEM "URI-de-la-dtd">
    #       'DOCT nam=[racine], sys=[URI-de-la-dtd], pub=[*undef*], int=[]'
    #       'DOCF'

    # <!DOCTYPE svg    PUBLIC "-//W3C//DTD SVG December 1999//EN" "http://www.w3.org/Graphics/SVG/SVG-19991203.dtd">
    #      'DOCT nam=[svg], sys=[http://www.w3.org/Graphics/SVG/SVG-19991203.dtd], pub=[-//W3C//DTD SVG December 1999//EN], int=[]'
    #      'DOCF'

    # <!DOCTYPE dialogue [   ==> int=1
    #      'DOCT nam=[dialogue], sys=[*undef*], pub=[*undef*], int=[1]'

    my $param0 = shift(@$plist);

    unless (defined $param0) {
        $self->crknum("Error-0830: Internal Error - Not enough elements in DOCTYPE");
    }

    unless ($param0->[0] eq 'B') {
        $self->crknum("Error-0840: syntax error");
    }

    my $name = $param0->[1];
    my $intern = $terminal eq '[' ? '1' : '';

    my ($system, $public);

    my $param1 = shift(@$plist);
    if (defined $param1) {
        unless ($param1->[0] eq 'B') {
            $self->crknum("Error-0850: syntax error");
        }
        my $syspub;
        if ($param1->[1] eq 'SYSTEM') {
            $syspub = 'S';
        }
        elsif ($param1->[1] eq 'PUBLIC') {
            $syspub = 'P';
        }
        else {
            $self->crknum("Error-0860: syntax error");
        }

        my $param2 = shift(@$plist);
        unless (defined $param2) {
            $self->crknum("Error-0870: syntax error");
        }
        unless ($param2->[0] eq 'Q') {
            $self->crknum("Error-0880: syntax error");
        }

        if ($syspub eq 'S') {
            $system = $param2->[1];
        }
        else {
            $public = $param2->[1];
        }

        my $param3 = shift(@$plist);
        if (defined $param3) {
            unless ($param3->[0] eq 'Q') {
                $self->crknum("Error-0890: syntax error");
            }

            if ($syspub eq 'S') {
                $public = $param3->[1];
            }
            else {
                $system = $param3->[1];
            }
        }
    }

    if (defined $public) {
        if ($public =~ m{[\]\[\\]}xms) {
            $self->crknum("Error-0900: illegal character(s) in public id");
        }
    }

    if (@$plist) {
        $self->crknum("Error-0910: syntax error");
    }

    if ($self->{_DocOpen}) {
        $self->crknum("Error-0920: Internal Error - DOC is open");
    }

    $self->_plausi('D'); # PLAUSI ==> 'D' = DocType

    $self->{_DocOpen} = 1;

    $self->{_ItemCount}++;

    my $cb_Doctype = $self->{_Setters}{Doctype};
    if ($cb_Doctype) {
        # Doctype (Expat, Name, Sysid, Pubid, Internal)
        $cb_Doctype->($self, $name, $system, $public, $intern);
    }

    unless ($intern eq '1') {
        $self->_plausi('F'); # PLAUSI ==> 'F' = DocTypeFin

        $self->{_DocOpen} = 0;

        my $cb_DoctypeFin = $self->{_Setters}{DoctypeFin};
        if ($cb_DoctypeFin) {
            # DoctypeFin (Expat)
            $cb_DoctypeFin->($self);
        }
    }
}

sub _parse_Entity {
    my $self = shift;
    my ($plist) = @_;

    # <!ENTITY prl "madame pernelle">
    #     'ENTT nam=[prl], val=[madame pernelle], sys=[*undef*], pub=[*undef*], nda=[*undef*], isp=[*undef*]'

    # <!ENTITY dialogue_b SYSTEM "dialogue5b.xml">
    #     'ENTT nam=[dialogue_b], val=[*undef*], sys=[dialogue5b.xml], pub=[*undef*], nda=[*undef*], isp=[*undef*]'

    # <!ENTITY animation SYSTEM "../anim.fla" NDATA flash>
    #     'UNPS ent=[animation], base=[*undef*], sys=[../anim.fla], pub=[*undef*], not=[flash]',

    # <!ENTITY % nom3 "chaine3">
    #     'ENTT nam=[nom3], val=[chaine3], sys=[*undef*], pub=[*undef*], nda=[*undef*], isp=[1]',

    # <!ENTITY % nom4 SYSTEM "uri3">
    #     'ENTT nam=[nom4], val=[*undef*], sys=[uri3], pub=[*undef*], nda=[*undef*], isp=[1]',

    my $isparam;

    if (@$plist and $plist->[0][0] eq 'B' and $plist->[0][1] eq '%') {
        $isparam = '1';
        shift @$plist;
    }

    my $param0 = shift(@$plist);

    unless (defined $param0) {
        $self->crknum("Error-0930: Internal Error - Not enough elements in ENTITY");
    }

    unless ($param0->[0] eq 'B') {
        $self->crknum("Error-0940: syntax error");
    }

    my $name = $param0->[1];

    my ($value, $val_quote, $base, $system, $sys_quote, $public, $ndata);

    my $param1 = shift(@$plist);
        
    unless (defined $param1) {
        $self->crknum("Error-0950: syntax error");
    }

    if ($param1->[0] eq 'Q') {
        $value     = $param1->[1];
        $val_quote = $param1->[2];
    }
    else {
        unless ($param1->[1] eq 'SYSTEM') {
            if ($param1->[1] eq 'PUBLIC') {
                $self->crknum("Error-0960: syntax error");
            }
            else {            
                $self->crknum("Error-0970: not well-formed (invalid token)");
            }
        }

        my $param2 = shift(@$plist);

        unless (defined $param2) {
            $self->crknum("Error-0980: syntax error");
        }

        unless ($param2->[0] eq 'Q') {
            $self->crknum("Error-0990: syntax error");
        }

        $system    = $param2->[1];
        $sys_quote = $param2->[2];

        my $param3 = shift(@$plist);
        if (defined $param3) {
            unless ($param3->[0] eq 'B') {
                $self->crknum("Error-1000: syntax error");
            }

            unless ($param3->[1] eq 'NDATA') {
                $self->crknum("Error-1010: syntax error");
            }

            my $param4 = shift(@$plist);
            unless (defined $param4) {
                $self->crknum("Error-1020: syntax error");
            }

            unless ($param4->[0] eq 'Q' or $param4->[0] eq 'B') {
                $self->crknum("Error-1030: syntax error");
            }

            $ndata = $param4->[1];
        }
    }

    if (@$plist) {
        $self->crknum("Error-1040: syntax error");
    }

    unless ($self->{_DocOpen}) {
        $self->crknum("Error-1050: syntax error");
    }

    if (defined $ndata) {
        $self->_plausi('U'); # PLAUSI ==> 'U' = Unparsed

        $self->{_ItemCount}++;

        my $cb_Unparsed = $self->{_Setters}{Unparsed};
        if ($cb_Unparsed) {
            # Unparsed (Expat, Entity, Base, Sysid, Pubid, Notation)
            $cb_Unparsed->($self, $name, $base, $system, $public, $ndata);
        }
    }
    else {
        if (defined $self->{_Var}{$name}) {
            #~ Redefinition of '$name' --> emit 2 or 3 Default lines

            my $object = defined($value) ? $val_quote.$value.$val_quote : $sys_quote.$system.$sys_quote; 

            $self->_plausi('T'); # PLAUSI ==> 'T' = Entity

            $self->{_ItemCount}++;

            my $cb_Default = $self->{_Setters}{Default};
            if ($cb_Default) {
                # Default (Expat, String)
                $cb_Default->($self, $name);
                $cb_Default->($self, $object);
                unless (defined $value) {
                    $cb_Default->($self, '>');
                }
            }
        }
        else {
            unless (defined $isparam) {
                if (defined $value) {
                    $self->{_Var}{$name} = [T => $value];  # T => $value is a replacement text
                }
                else {
                    $self->{_Var}{$name} = [F => $system]; # F => $system is a file name, the content of which will be processed
                }
            }

            $self->_plausi('T'); # PLAUSI ==> 'T' = Entity

            $self->{_ItemCount}++;

            my $cb_Entity = $self->{_Setters}{Entity};
            if ($cb_Entity) {
                # Entity (Expat, Name, Val, Sysid, Pubid, Ndata, IsParam)
                $cb_Entity->($self, $name, $value, $system, $public, $ndata, $isparam);
            }
        }
    }
}

sub _parse_Element {
    my $self = shift;
    my ($plist) = @_;

    # <!ELEMENT replique (   personnage   ,     texte     )     >
    #      'ELEM nam=[replique], mod=[(personnage,texte)]',

    # <!ELEMENT personnage (  #PCDATA ) >
    #      'ELEM nam=[personnage], mod=[(#PCDATA)]',

    my $param0 = shift(@$plist);

    unless (defined $param0) {
        $self->crknum("Error-1060: Internal Error - Not enough elements in ELEMENT");
    }

    unless ($param0->[0] eq 'B') {
        $self->crknum("Error-1070: syntax error");
    }

    my $name = $param0->[1];

    my $param1 = shift(@$plist);
        
    unless (defined $param1) {
        $self->crknum("Error-1080: syntax error");
    }

    unless ($param1->[0] eq 'P') {
        $self->crknum("Error-1090: syntax error");
    }

    my $model = $param1->[1];

    unless ($self->{_DocOpen}) {
        $self->crknum("Error-1100: syntax error");
    }

    $self->_plausi('L'); # PLAUSI ==> 'L' = Element

    $self->{_ItemCount}++;

    my $cb_Element = $self->{_Setters}{Element};
    if ($cb_Element) {
        # Element (Expat, Name, Model)
        $cb_Element->($self, $name, "($model)");
    }

    if (@$plist) {
        $self->crknum("Error-1110: syntax error");
    }
}

sub _parse_Attlist {
    my $self = shift;
    my ($plist) = @_;

    # <!ATTLIST task status (important|normal) "normal">
    #     'ATTL eln=[task], atn=[status], typ=[(important|normal)], def=[\'normal\'], fix=[*undef*]',

    # <!ATTLIST task status NMTOKEN #FIXED "monthly">
    #     'ATTL eln=[task], atn=[status], typ=[NMTOKEN], def=[\'monthly\'], fix=[1]',

    # <!ATTLIST description xml:lang NMTOKEN #FIXED "en">
    #     'ATTL eln=[description], atn=[xml:lang], typ=[NMTOKEN], def=[\'en\'], fix=[1]',

    # <!ATTLIST code xml:space (default|preserve) "preserve">
    #     'ATTL eln=[code], atn=[xml:space], typ=[(default|preserve)], def=[\'preserve\'], fix=[*undef*]',
    
    # <!ATTLIST personnage attitude CDATA #REQUIRED geste CDATA #IMPLIED>
    #     'ATTL eln=[personnage], atn=[attitude], typ=[CDATA], def=[#REQUIRED], fix=[*undef*]',
    #     'ATTL eln=[personnage], atn=[geste], typ=[CDATA], def=[#IMPLIED], fix=[*undef*]',

    # <!ATTLIST texte ton (normal | fort | faible) "normal">
    #     'ATTL eln=[texte], atn=[ton], typ=[(normal|fort|faible)], def=[\'normal\'], fix=[*undef*]',

    my $param0 = shift(@$plist);

    unless (defined $param0) {
        $self->crknum("Error-1120: Internal Error - Not enough elements in ATTLIST");
    }

    unless ($param0->[0] eq 'B') {
        $self->crknum("Error-1130: syntax error");
    }

    my $name = $param0->[1];

    while (@$plist) {
        my $param1 = shift(@$plist);

        unless (defined $param1) {
            $self->crknum("Error-1140: Internal Error - Not enough elements in ATTLIST-PARAM1");
        }

        unless ($param1->[0] eq 'B') {
            $self->crknum("Error-1150: syntax error");
        }

        my $attrib = $param1->[1];

        my $param2 = shift(@$plist);

        unless (defined $param2) {
            $self->crknum("Error-1160: syntax error");
        }

        my $atype;

        if ($param2->[0] eq 'B' and $param2->[1] eq 'NOTATION') {
            my $pm2b = shift(@$plist);

            unless (defined $pm2b) {
                $self->crknum("Error-1170: syntax error");
            }

            unless ($pm2b->[0] eq 'P') {
                $self->crknum("Error-1180: syntax error");
            }
            $atype = $param2->[1]."($pm2b->[1])";
        }
        else {
            if ($param2->[0] eq 'B') {
                $atype = $param2->[1];
            }
            elsif ($param2->[0] eq 'P') {
                $atype = "($param2->[1])";
            }
            else {
                $self->crknum("Error-1190: syntax error");
            }
        }

        my $param3 = shift(@$plist);

        unless (defined $param3) {
            $self->crknum("Error-1200: syntax error");
        }

        my ($default, $fixed);

        if ($param3->[0] eq 'B' and $param3->[1] eq '#FIXED') {
            my $pm3b = shift(@$plist);

            unless (defined $pm3b) {
                $self->crknum("Error-1210: syntax error");
            }

            unless ($pm3b->[0] eq 'Q') {
                $self->crknum("Error-1220: syntax error");
            }

            $default = "'$pm3b->[1]'";
            $fixed   = '1';
        }
        else {
            if ($param3->[0] eq 'B') {
                $default = $param3->[1];
            }
            elsif ($param3->[0] eq 'Q') {
                $default = "'$param3->[1]'";
            }
            else {
                $self->crknum("Error-1230: syntax error");
            }
        }

        unless ($self->{_DocOpen}) {
            $self->crknum("Error-1240: syntax error");
        }

        $self->_plausi('I'); # PLAUSI ==> 'I' = Attlist

        $self->{_ItemCount}++;

        my $cb_Attlist = $self->{_Setters}{Attlist};
        if ($cb_Attlist) {
            # Attlist (Expat, Elname, Attname, Type, Default, Fixed)
            $cb_Attlist->($self, $name, $attrib, $atype, $default, $fixed);
        }
    }
}

sub _parse_Notation {
    my $self = shift;
    my ($plist) = @_;

    # <!NOTATION name1 SYSTEM "URI1">
    #     'NOTA not=[name1], base=[*undef*], sys=[URI1], pub=[*undef*]',

    # <!NOTATION name2 PUBLIC "public_ID2">
    #     'NOTA not=[name2], base=[*undef*], sys=[*undef*], pub=[public_ID2]',

    # <!NOTATION name3 PUBLIC "public_ID3" "URI3">
    #     'NOTA not=[name3], base=[*undef*], sys=[URI3], pub=[public_ID3]',

    my $param0 = shift(@$plist);

    unless (defined $param0) {
        $self->crknum("Error-1250: Internal Error - Not enough elements in NOTATION");
    }

    unless ($param0->[0] eq 'B') {
        $self->crknum("Error-1260: syntax error");
    }

    my $name = $param0->[1];

    my ($base, $system, $public);

    my $param1 = shift(@$plist);
    if (defined $param1) {
        unless ($param1->[0] eq 'B') {
            $self->crknum("Error-1270: syntax error");
        }
        my $syspub;
        if ($param1->[1] eq 'SYSTEM') {
            $syspub = 'S';
        }
        elsif ($param1->[1] eq 'PUBLIC') {
            $syspub = 'P';
        }
        else {
            $self->crknum("Error-1280: syntax error");
        }

        my $param2 = shift(@$plist);
        unless (defined $param2) {
            $self->crknum("Error-1290: syntax error");
        }
        unless ($param2->[0] eq 'Q') {
            $self->crknum("Error-1300: syntax error");
        }

        if ($syspub eq 'S') {
            $system = $param2->[1];
        }
        else {
            $public = $param2->[1];
        }

        my $param3 = shift(@$plist);
        if (defined $param3) {
            unless ($param3->[0] eq 'Q') {
                $self->crknum("Error-1310: syntax error");
            }

            if ($syspub eq 'S') {
                $public = $param3->[1];
            }
            else {
                $system = $param3->[1];
            }
        }
    }

    unless ($self->{_DocOpen}) {
        $self->crknum("Error-1320: syntax error");
    }

    $self->_plausi('O'); # PLAUSI ==> 'O' = Notation

    $self->{_ItemCount}++;

    my $cb_Notation = $self->{_Setters}{Notation};
    if ($cb_Notation) {
        # Notation (Expat, Notation, Base, Sysid, Pubid)
        $cb_Notation->($self, $name, $base, $system, $public);
    }

    if (@$plist) {
        $self->crknum("Error-1330: syntax error");
    }
}

sub _plausi {
    my $self = shift;
    my ($pl) = @_;
    my $tp = $pl eq 'D' || $pl eq 'F' || $pl eq 'U' || $pl eq 'I' || $pl eq 'L' || $pl eq 'O' || $pl eq 'T' ? 'DTD' 
           : $pl eq 'A' || $pl eq 'C' || $pl eq '!'                                                         ? 'TXT'
           : $pl eq 'S' || $pl eq 'E'                                                                       ? 'TAG'
           : $pl eq 'P'                                                                                     ? 'PRC'
           : $pl eq 'X'                                                                                     ? 'XML'
           : $self->crknum("Error-1340: Internal Error - encountered plausi code = '$pl'");

    my $stage = $self->{_Stage};

    # PLAUSI ==> TXT - 'A' = CData
    # PLAUSI ==> TXT - 'C' = Character Data
    # PLAUSI ==> DTD - 'D' = DocType
    # PLAUSI ==> TAG - 'E' = End Tag
    # PLAUSI ==> DTD - 'F' = DocTypeFin
    # PLAUSI ==> DTD - 'I' = Attlist
    # PLAUSI ==> DTD - 'L' = Element
    # PLAUSI ==> DTD - 'O' = Notation
    # PLAUSI ==> PRC - 'P' = Processing Instruction
    # PLAUSI ==> TAG - 'S' = Start Tag
    # PLAUSI ==> DTD - 'T' = Entity
    # PLAUSI ==> DTD - 'U' = Unparsed
    # PLAUSI ==> PRC - 'X' = XML Declaration
    # PLAUSI ==> TXT - '!' = comment

    # Stage = 1 --> <xmldecl>
    # Stage = 2 --> DTD
    # Stage = 3 --> <tag>, Character, CData, </tag>
    # Stage = 4 --> after...

    if ($stage == 1) {
        if ($tp eq 'DTD') {
            $stage = 2;
        }
        elsif ($pl eq 'S') {
            $stage = 3;
        }
    }
    elsif ($stage == 2) {
        if ($pl eq 'S') {
            $stage = 3;
        }
    }

    if ($stage == 1) {
        unless ($pl eq 'X' or $pl eq 'C' or $pl eq '!') {
            $self->crknum("Error-1350: Internal Error - Found invalid callback, plausi = '$pl' at stage 1");
        }
        if ($pl eq 'X') {
            $stage = 2;
        }
    }
    elsif ($stage == 2) {
        unless ($tp eq 'DTD' or $pl eq 'C' or $pl eq '!') {
            $self->crknum("Error-1360: Internal Error - Expected 'DTD', but found '$tp', plausi = '$pl' at stage 2");
        }
    }
    elsif ($stage == 3) {
        unless ($tp eq 'TAG' or $tp eq 'PRC' or $tp eq 'TXT') {
            $self->crknum("Error-1370: Internal Error - Expected 'TAG', 'PRC' or 'TXT', but found '$tp', plausi = '$pl' at stage 3");
        }
        if ($pl eq 'E' and $self->{_Scount} == 0) {
            $stage = 4;
        }
    }
    elsif ($stage == 4) {
        unless ($pl eq 'C') {
            $self->crknum("Error-1380: junk after document element");
        }
    }
    else {
        $self->crknum("Error-1390: Internal Error - invalid stage = $stage");
    }

    $self->{_Stage} = $stage;
}

sub _update_ctr {
    my $self = shift;
    my ($emit) = @_;

    $self->{_Read_Bytes} += length($emit);
    $self->{_Read_Lines} += $emit =~ tr{\n}{};
    
    if($emit =~ m{\n ([^\n]*) \z}xms) {
        $self->{_Read_Cols} = length($1) + 2;
    }
    else { 
        $self->{_Read_Cols} += length($emit);
    }
}

sub parse_done {
    my $self = shift;

    if ($self->{_Action} eq 'F') {
        $self->crknum("Error-1400: unclosed token");
    }

    if ($self->{_Action} eq 'G') {
        $self->crknum("Error-1410: syntax error");
    }

    if (@{$self->{_Stack}}) {
        $self->crknum("Error-1420: no element found");
    }

    unless ($self->{_Scount} == 0) {
        $self->crknum("Error-1430: Internal Error -  no element found");
    }

    unless ($self->{_Text} eq '') {
        $self->crknum("Error-1440: unclosed token");
    }

    $self->_emit_Final;

    # $self->release; # nothing needs to be released, everything is reference counted
}

sub release { # dummy subroutine, nothing needs to be released, everything is reference counted
}

sub crknum {
    my $self = shift;

    my $pos = 'at line '.$self->{_Read_Lines}.', column '.$self->{_Read_Cols}.', byte '.$self->{_Read_Bytes};

    croak($_[0].' '.$pos);
}

1;

__END__

=head1 NAME

XML::Parsepp - Simplified pure perl parser for XML

=head1 SYNOPSIS

  use XML::Parsepp;
  
  $p1 = new XML::Parsepp;
  $p1->parsefile('REC-xml-19980210.xml');
  $p1->parse('<foo id="me">Hello World</foo>');

  # Alternative
  $p2 = new XML::Parsepp(Handlers => {Start => \&handle_start,
                                      End   => \&handle_end,
                                      Char  => \&handle_char});
  $p2->parse($socket);

  # Another alternative
  $p3 = new XML::Parsepp;

  $p3->setHandlers(Char    => \&text,
                   Default => \&other);

  open(FOO, 'xmlgenerator |');
  $p3->parse(*FOO);
  close(FOO);

  $p3->parsefile('junk.xml');

Allow duplicate attributes with option: dupatt => ';'

The concatenation string XML::Parsepp->new(dupatt => $str) is
restricted to printable ascii excluding " and '

  $p1 = new XML::Parsepp(dupatt => ';');
  $p1->parse('<foo id="me" id="too">Hello World</foo>');

This will fire the Start event with the following parameters

  start($ExpatNB, 'foo', 'id', 'me;too');

=head1 DESCRIPTION

This module provides a pure Perl implementation to parse XML documents. Its interface is very
close to that of XML::Parser (in fact, the synopsis has, with some minor modifications, been copied
from XML::Parser).

=head1 USAGE

XML::Parsepp can be used as a pure Perl alternative to XML::Parser. The main use case is with XML::Reader
where it can be used as a drop-in replacement. Here is a sample:

  use XML::Reader qw(XML::Parsepp);

  my $text = q{<init>n <?test pi?> t<page node="400">m <!-- remark --> r</page></init>};

  my $rdr = XML::Reader->new(\$text) or die "Error: $!";
  while ($rdr->iterate) {
      printf "Path: %-19s, Value: %s\n", $rdr->path, $rdr->value;
  }

=head1 AUTO-GENERATE TESTCASES

You can use the module XML::Parsepp::Testgen to generate testcases.

For example, you can generate a test file from an existing XML with the following
program:

  use XML::Parsepp::Testgen qw(xml_2_test);

  my $xml =
    qq{#! Testdata for XML::Parsepp\n}.
    qq{#! Ver 0.01\n}.
    qq{<?xml version="1.0" encoding="ISO-8859-1"?>\n}.
    qq{<!DOCTYPE dialogue [\n}.
    qq{  <!ENTITY nom0 "<data>y<item>y &nom1; zz</data>">\n}.
    qq{  <!ENTITY nom1 "<abc>def</abc></item>">\n}.
    qq{]>\n}.
    qq{<root>&nom0;</root>\n}.
    qq{#! ===\n}.
    qq{<?xml version="1.0" encoding="ISO-8859-1"?>\n}.
    qq{<!DOCTYPE dialogue\n}.
    qq{[\n}.
    qq{  <!ENTITY nom1 "aa &nom2; tt &nom4; bb">\n}.
    qq{  <!ENTITY nom2 "c <xx>abba</xx> c tx <ab> &nom3; dd">\n}.
    qq{  <!ENTITY nom3 "dd </ab> <yy>&nom4;</yy> ee">\n}.
    qq{  <!ENTITY nom4 "gg">\n}.
    qq{]>\n}.
    qq{<root>hh &nom1; ii</root>\n};

  print xml_2_test(\$xml), "\n";

You can also extract the XML from an already existing test file (for example 'test.t') as follows:

  use XML::Parsepp::Testgen qw(test_2_xml);

  say test_2_xml('test.t');

=head1 AUTHOR

Klaus Eichner <klaus03@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2011 by Klaus Eichner

All rights reserved. This program is free software; you can redistribute
it and/or modify it under the terms of the artistic license 2.0,
see http://www.opensource.org/licenses/artistic-license-2.0.php

=head1 SEE ALSO

L<XML::Parsepp::Testgen>,
L<XML::Reader>,
L<XML::Parser>.

=cut
