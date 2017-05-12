# CallRep.pm - XDR RPC protocol helper functions
# Copyright (C) 2000  Mountain View Data, Inc.
# Written by Gordon Matzigkeit <gord@fig.org>, 2000-12-15
#
# This file is part of Perl XDR.
#
# Perl XDR is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# Perl XDR is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307
# USA

package XDR::CallReply;
# [guilt]
# [maint
#  File: CallRep.pm
#  Summary: XDR protocol helper functions
#  Package: Perl XDR
#  Owner: Mountain View Data, Inc.
#  Years: 2000
#  Author: Gordon Matzigkeit
#  Contact: <gord@fig.org>
#  Date: 2000-12-15
#  License: GPL]
# [clemency]

use strict;
use Carp;


sub new
{
    my ($type, $prog, $vers) = @_;
    $vers = 0 if (! $vers);
    $prog = 0 if (! $prog);
    bless { PROGRAM => $prog, VERSION => $vers, types => {} }, $type;
}


# Define a new type name.
sub typedef
{
    my ($self, $type, $name, @args) = @_;
    if ($type eq 'struct')
    {
	$self->{TYPES}->{$name} = [@args];
    }
    else
    {
	$self->{TYPES}->{$name} = $type;
    }
}


# Encode a structure.
sub struct
{
    my ($self, $type, $arg) = @_;
    my $types = $self->{TYPES};
    my $ret = '';

    my $tname = $type;
    while (! ref ($type) && defined $self->{TYPES}->{$type})
    {
	$tname = $type;
	$type = $self->{TYPES}->{$type};
    }
    if (UNIVERSAL::isa ($arg, 'XDR::Decode'))
    {
	# We're decoding.
	if (ref $type)
	{
	    my $i;
	    $ret = [];
	    # FIXME: Why is $type getting an undef pushed on it?
	    for ($i = 0; $i < @$type; $i ++)
	    {
		my ($subtype) = $type->[$i];
		($subtype) = split (/\s+/, $subtype) if (! ref $subtype);
		push @$ret, $self->struct ($subtype, $arg);
	    }
	}
	else
	{
	    $ret = eval "\$arg->$type ()";
	    confess $@ if ($@);
	}
    }
    elsif (ref $type)
    {
	# We're encoding a reference.
	confess "\`$arg' is not an array reference" if (ref $arg ne 'ARRAY');
	if (scalar (@$type) != scalar (@$arg))
	{
	    warn "Received ", scalar (@$arg) + 1, " arguments for struct ",
	    $tname, ", not ", scalar (@$type) + 1, "\n";
	}
	my $i;
	# FIXME: Why is $type getting an undef pushed on it?
	for ($i = 0; $i < @$type; $i ++)
	{
	    my ($subtype) = $type->[$i];
	    ($subtype) = split (/\s+/, $subtype) if (! ref $subtype);
	    $ret .= $self->struct ($subtype, $arg->[$i]);
	}
    }
    else
    {
	# Encoding a scalar.
	my ($sub) = eval "XDR::Encode::$type (\$arg)";
	confess $@ if ($@);
	$ret .= $sub;
    }
    return $ret;
}


# Define an RPC.
sub define
{
    my ($self, $proc, $rets, $name, @args) = @_;
    $self->{$proc} = [ $rets, $name, @args ];

    # Automatically determine the package name.
    my ($pkg) = caller;
    my $need_struct = 0;

    # Determine the types and build up a prototype.
    my ($proto, $arg, $nargs, $i);
    $nargs = 0;
    for ($i = 0; $i <= $#args; $i ++)
    {
	my ($type, $name) = split (/ /, $args[$i]);
	$proto .= "\$";
	$arg .= ' . ' if ($i != 0);
	my $tname = $type;
	while (! ref $type && defined $self->{TYPES}->{$type})
	{
	    $tname = $type;
	    $type = $self->{TYPES}->{$type};
	}
	if ($type ne 'void')
	{
	    if (ref $type)
	    {
		$arg .= "\$_xdr_callreply->struct ('$tname', \$_[$nargs])";
	    }
	    else
	    {
		$arg .= "XDR::Encode::$type (\$_[$nargs])";
	    }
	    $nargs ++;
	}
    }

    $arg = "''" if ($nargs == 0);

    my ($type) = split (/ /, $rets);
    my $tname = $type;
    while (! ref $type && defined $self->{TYPES}->{$type})
    {
	$tname = $type;
	$type = $self->{TYPES}->{$type};
    }

    my ($res, $nres);
    $nres = 0;
    if ($type ne 'void')
    {
	if (ref $type)
	{
	    $res = "\$_xdr_callreply->struct ('$tname', \$_[0])";
	}
	else
	{
	    $res = "XDR::Encode::$type (\$_[0])";
	}
	$nres ++;
    }
    $res = "''" if ($nres == 0);

    my ($stub) = "package $pkg;\n";
    if (! $pkg->can ('call'))
    {
  	$stub .= "
# FIXME: It would be nice to close \$self within this eval, but
# perl documentation implies that it is impossible.
use vars qw(\$_xdr_callreply);
\$_xdr_callreply = \$self;

use Carp;

# Return a call packet generator.
sub call
{
    my (\$type) = \@_;
    return bless [ 0, 0 ], \$type;
}


# Return a reply packet generator.
sub reply
{
    my (\$type) = \@_;
    return bless [ 1 ], \$type;
}


# Return a new hook database.
sub hookdb
{
    my (\$type) = \@_;
    return bless [ \$_xdr_callreply, {}, {} ], \$type;
}


# Set up a hook for the given callrep.
use XDR ':vers';
use XDR::RPC;
sub hook
{
    my (\$slf, \$proto, \$hook, \$xid) = \@_;
    if (defined \$xid)
    {
	# We're binding a reply packet.
	\$xid = XDR::RPC->decode (\$xid)->xid
	    if (\$xid !~ /^\d+\$/);
	\$slf->[1]->{\$xid} = [\$hook, \@\$proto];
    }
    else
    {
	# We have a call packet.
	\$slf->[2]->{\&RPCVERS}->{\$proto->[0]}->{\$proto->[1]}->{\$proto->[2]} =
	    [ \$hook, \@\$proto ];
    }
}";
    }

    if (! $pkg->can ('dispatch'))
    {
        $stub .= "

use XDR ':all';
use XDR::RPC;
use XDR::Encode ':all';

# Invoke the hook for a given RPC.
sub dispatch
{
    my (\$slf, \$rpc, \@args) = \@_;

    # Implicitly convert buffers to RPC objects.
    \$rpc = XDR::RPC->decode (\$rpc)
	if (! UNIVERSAL::isa (\$rpc, 'XDR::RPC'));

    my (\$bad, \@proto, \$func);
    if (\$rpc->can ('rpcvers'))
    {
	# Call packet.
	my (\$binding) = \$slf->[2];
	my \$t = \$binding->{\$rpc->rpcvers};
	if (! defined \$t)
	{
	    # Bad version.
	    my (\@vsns, \$low, \$high) = sort keys %\$binding;
	    \$low = \$vsns[0];
	    \$high = \$vsns[\$\#vsns - 1];
	    return reply_packet (\$rpc->xid, MSG_DENIED, RPC_MISMATCH,
				 unsigned (\$low) . unsigned (\$high));
	}

	\$t = \$t->{\$rpc->prog};
	if (! defined \$t)
	{
	    # Bad program.
	    return reply_packet (\$rpc->xid, MSG_ACCEPTED, PROG_UNAVAIL);
	}

	my (\$prog) = \$t;
	\$t = \$t->{\$rpc->vers};
	if (! defined \$t)
	{
	    # Bad version.
	    my (\@vsns, \$low, \$high) = sort keys \%{\$prog};
	    \$low = \$vsns[0];
	    \$high = \$vsns[\$\#vsns - 1];
	    return reply_packet (\$rpc->xid, MSG_ACCEPTED, PROG_MISMATCH,
				 unsigned (\$low) . unsigned (\$high));
	}

	\$t = \$t->{\$rpc->proc};
	if (! defined \$t)
	{
	    # Bad procedure.
	    return reply_packet (\$rpc->xid, MSG_ACCEPTED, PROC_UNAVAIL);
	}

	my (\$hook, \$progt, \$vers, \$proc,
	    \$ret, \$name, \@pto)
	    = @\$t;

	# Invoke the reply hook with the correct arguments.
	\@proto = \@pto;
	\$bad = reply_packet (\$rpc->xid, MSG_ACCEPTED, GARBAGE_ARGS);
	\$func = \$hook;
    }
    else
    {
	# Reply packet.
	my (\$hook, \$prog, \$vers, \$proc, \$ret) =
	    \@{\$slf->[1]->{\$rpc->xid}};

	# Not waiting for that reply xid.
	return \$bad if (! defined \$hook);

	# Reply hooks are one-shot.
	delete \$slf->[1]->{\$rpc->xid};

	\$bad = 1;
	\@proto = (\$ret);
	\$func = \$hook;
    }

    # Call the hook.
    push \@args, eval '\$rpc->args (\$_xdr_callreply, \@proto)';
    return \$bad if \$@;

    return &\$func (\$rpc, \@args);
}
";
    }

    # Actually define the stub.
    $stub .= "


sub $name # ($proto)
{
    my (\$slf) = shift;
    my \$callrep = \$slf->[0];
    if (\$callrep == 0)
    {
	# Return the call packet.
	carp '$pkg->call->$name received ', \$#_ + 1,
	    \" arguments instead of $nargs\\n\"
		if (\$#_ != $nargs - 1);
	call_packet (\$slf->[1] ++, $proc, $arg,
		     \$_xdr_callreply->{VERSION},
		     \$_xdr_callreply->{PROGRAM});
    }
    elsif (\$callrep == 1)
    {
	# Return the reply arguments.
	carp '$pkg->reply->$name received ', \$#_ + 1,
	    \" results instead of $nres\\n\"
		if (\$#_ != $nres - 1);
	$res;
    }
    else
    {
	# Return the callrep specification.
	[\$callrep->{PROGRAM}, \$callrep->{VERSION}, $proc,
	 \@{\$callrep->{$proc}}];
    }
}";

    # warn "FIXME!\n", $stub;
    eval $stub;
    croak $@ if $@;
}

1;
