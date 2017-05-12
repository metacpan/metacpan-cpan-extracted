#!/usr/bin/perl -w

package Tana;

use Data::Dumper;

use strict;

my %ERROR;
my $debug = 0;

sub error($)
{
    my ($client) = @_;
    return $ERROR{$client};
}

sub readname($)
{
    my ($client) = @_;

    my $len = readnum($client);
    if(!defined($len))
    {
	return undef;
    }

    my ($name,$got) = readbytes($client, $len);
    if(!defined($name))
    {
	return undef;
    }
    
    return $name;
}

sub readnum($)
{
    my ($client) = @_;

    my $got = 0;
    my $num = '';
    my $char = '0';

    while($char =~ /[0-9]/)
    {
	my $bytes = CORE::sysread($client, $char, 1);
	if($bytes != 1)
	{
	    $ERROR{$client} = "Readnum error: $@";
	    !$debug || print STDERR "readnum: $ERROR{$client}\n";
	    return undef;
	}

	if($char =~ /[0-9]/)
	{
	    $num .= $char;
	    $got++;
	}
    }

    if($char =~ /[^\n ]/)
    {
	$ERROR{$client} = "Non-eol/space at end of number. Got '$char' instead.";
	!$debug || print STDERR "readnum: $ERROR{$client}\n";
	return undef;
    }
    if(0 == $got)
    {
	$ERROR{$client} = "No numbers in readnum, got '$char' instead.";
	!$debug || print STDERR "readnum: $ERROR{$client}\n";
	return undef;	
    }

#    warn "Tana::readnum() read num $num";
    
    return $num;
}

sub readbytes($$)
{
    my ($client, $len) = @_;

    my $str = '';


    my $got = CORE::sysread($client, $str, $len);
#    if($len != $got)
#    {
#	warn "Tana::readbytes(): Wanted $len bytes, got $got";
#	$ERROR{$client} = "Wanted $len bytes, got $got";
#	!$debug || print STDERR "readnum: $ERROR{$client}\n";
#	return undef;
#    }

#    warn "Tana::readbytes(): read $str";
    
    return ($str,$got);
}

sub read_field_header($)
{
    my ($client) = @_;

    my $keylen = readnum($client);
    if(!defined($keylen))
    {
	!$debug || print STDERR "read: $ERROR{$client}\n";
	return (undef, undef);
    }
    !$debug || print "keylen = *$keylen*\n";
    
    my ($key,$got) = readbytes($client, $keylen);
    if(!defined($key))
    {
	!$debug || print STDERR "read: $ERROR{$client}\n";
	return (undef, undef);
    }
    !$debug || print "key = $key\n";
    
    my $dummy;
    ($dummy,$got)=readbytes($client, 2);
    if(!defined($dummy))
    {
	!$debug || print STDERR "read: $ERROR{$client}\n";
	return (undef, undef);
    }
    
    return ($keylen, $key);
}

sub read
{
    my ($client, $autoread_arb) = @_;

    my $mtype = '';
    my $got = CORE::sysread($client, $mtype, 4);
    if(4 != $got)
    {
	warn "Tana read() Expected 4, got $got";
	$ERROR{$client} = "$@";
	return undef;
    }
    $mtype =~ s/(...)./$1/;

    my $fieldc = readnum($client);
    if(!defined($fieldc))
    {
	return undef;
    }
    
    if(($mtype ne 'arb') && ($mtype ne 'fix'))
    {
	$ERROR{$client} = "Invalid message type '$mtype'";
	!$debug || print STDERR "read: $ERROR{$client}\n";
	return undef;
    }

    my $read_arb = 1;
    if(defined($$autoread_arb))
    {
	if(! $$autoread_arb)
	{
	    $read_arb = 0;
	}
    }

    my $msg = {};

    if(($mtype eq 'arb') && (!$read_arb))
    {
	$fieldc--;
    }

    for(my $i = 0; $i < $fieldc; $i++)
    {
	my ($keylen, $key) = read_field_header($client);

#	warn "Tana::read(): keylen:$keylen key: $key";

	if(!defined($keylen))
	{
	    return undef;
	}

	my $len = readnum($client);
	if(!defined($len))
	{
	    !$debug || print STDERR "read: $ERROR{$client}\n";
	    return undef;
	}
	!$debug || print "len = $len\n";

	my $value = '';
	my $gotten_so_far=0;
	if($len > 0)
	{
	    while ($gotten_so_far<$len)
	    {
#		warn "before reading to get ",$len-$gotten_so_far," bytes";
		my ($value_piece,$got) = readbytes($client, 
						   $len-$gotten_so_far);
		if(!defined($value_piece))
		{
		    !$debug || print STDERR "read: $ERROR{$client}\n";
		    return undef;
		}
		!$debug || print "value = $value_piece\n";
		
#		warn "after reading $got bytes. Value:$value_piece";
		
		$gotten_so_far+=$got;
		$value.=$value_piece;
	    }	    

	    my ($dummy,$got)=readbytes($client, 1);
	    if(!defined($dummy))
	    {
		!$debug || print STDERR "read: $ERROR{$client}\n";
		return undef;
	    }
	}
	
	$msg->{$key} = $value;
    }

    if(($mtype eq 'arb') && (!$read_arb))
    {
	my ($keylen, $key) = read_field_header($client);

	if(!defined($keylen))
	{
	    return undef;
	}

	!$debug || print STDERR "Tana::read() set autoread_arb to -$key-\n";
	$$autoread_arb = $key;
    }
    elsif(defined($autoread_arb))
    {
	$$autoread_arb = undef;
    }

    return $msg;
}

sub read_arb($$$)
{
    my ($client, $len, $eof) = @_;

    my $str = '';

    $$eof = 0;

    while($len > 0)
    {
	my $char;
	my $got = CORE::sysread($client, $char, 1);

	if(1 != $got)
	{
	    $ERROR{$client} = "Wanted 1 bytes, got $got";
	    !$debug || print STDERR "read_arb: $ERROR{$client}\n";
	    return undef;
	}

	!$debug || print STDERR "Read arb '$char'\n";
	if($char eq "\\")
	{
	    $got = CORE::sysread($client, $char, 1);
	    if(1 != $got)
	    {
		$ERROR{$client} = "Wanted 1 bytes, got $got";
	    !$debug || print STDERR "read_arb: $ERROR{$client}\n";
		return undef;
	    }

	    !$debug || print STDERR "Read arb '$char'\n";
	    if($char eq 'n')
	    {
		$str .= "\n";
	    }
	    elsif($char eq "\\")
	    {
		$str .= "\\";
	    }
	    else
	    {
		$ERROR{$client} = "Invalid escaped char '$char' after '\\'";
		!$debug || print STDERR "read_arb: $ERROR{$client}\n";
		return undef;
	    }
	}
	elsif($char eq "\n")
	{
	    $$eof = 1;
	    last;
	}
	else
	{
	    $str .= $char;
	}

	$len--;
    }

    return $str;
}


sub write_arb($$$)
{
    my ($client, $str, $final) = @_;

    while(length($str) > 0)
    {
	$str =~ s/(.)(.*)/$2/s;
	!$debug || print STDERR "Sending arb '$1'\n";
	if($1 eq "\\")
	{
	    my $out = "\\\\";
	    if(length($out) != CORE::syswrite($client, $out, length($out)))
	    {
		$ERROR{$client} = "write to socket failed: $@";
		return 0;
	    }
	}
        elsif($1 eq "\n")
        {
	    my $out = "\\n";
	    if(length($out) != CORE::syswrite($client, $out, length($out)))
	    {
		$ERROR{$client} = "write to socket failed: $@";
		return 0;
	    }
	}
	else
	{
	    my $out = $1;
	    if(length($out) != CORE::syswrite($client, $out, length($out)))
	    {
		$ERROR{$client} = "write to socket failed: $@";
		return 0;
	    }
	}
    }

    if($final)
    {
	my $out = "\n";
	if(length($out) != CORE::syswrite($client, $out, length($out)))
	{
	    $ERROR{$client} = "write to socket failed: $@";
	    return 0;
	}
    }

    return 1;
}

sub write($$$)
{
    my ($client, $msg, $type) = @_;

    my @keys = keys(%$msg);
    my $fieldc = scalar(@keys);

#    warn "Writing ", Dumper($msg);
#    warn "Client: ", Dumper($client);
#    warn "Type: ", Dumper($type);

    if(defined($type))
    {
	my $afc = $fieldc + 1;

	my $out = "arb $afc\n";
	if(length($out) != CORE::syswrite($client, $out))
	{
	    $ERROR{$client} = "write to socket failed: $@\n";
	    return 0;
	}
    }
    else
    {
	my $out = "fix $fieldc\n";
#	warn "Tana syswriting",Dumper($out);
	my $len = CORE::syswrite($client, $out);
	if(length($out) != $len)
	{
#	    warn "Tana length mismatch lenth8out):",length($out),
#	    " len:",$len;
	    $ERROR{$client} = "write to socket failed: $@";
	    return 0;
	}
    }
    my $key;
    foreach $key (@keys)
    {
	my $len = length($msg->{$key});
	my $val = $msg->{$key};
	my $keylen = length($key);
	my $out = "$keylen $key: $len $val\n";

#	warn "Tana::write()  key:\"$key\" value:\"$val\" lenght of value:$len";

	if($len == 0)
	{
	    $out = "$keylen $key: $len\n";
	}
	if(length($out) != CORE::syswrite($client, $out))
	{
	    $ERROR{$client} = "write to socket failed: $@";
	    return 0;
	}
    }
    if(defined($type))
    {
	my $klen = length($type);
	my $out = "$klen $type: ";
	if(length($out) != CORE::syswrite($client, $out))
	{
	    print "TANA4\n";
	    $ERROR{$client} = "write to socket failed: $@";
	    return 0;
	}
    }

#    warn "Tana at end of of write()";

    return 1;
}

1;
