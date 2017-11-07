package txdtestutil;

sub txdcompare
{
	my ($out, $ref, $epsilon) = @_;
	if(open(my $oh, '<', $out) and open(my $rh, '<', $ref))
	{
		my $li;
		my $ol;
		my $rl;
		while($ol=<$oh>,$rl=<$rh>,(defined $ol or defined $rl))
		{
			++$li;
			if(not defined $ol)
			{
				print STDERR "Line $li: Too few lines in output.\n";
				return -1;
			}
			if(not defined $rl)
			{
				print STDERR "Line $li: Too many lines in output.\n";
				return 1;
			}
			if($rl =~ m/^#/ or $ol =~ m/^#/)
			{
				if($rl ne $ol)
				{
					print STDERR "Line $li: Header line mismatch.\n";
					return -2;
				}
				next;
			}
			my @odat = split('\s+', $ol);
			my @rdat = split('\s+', $rl);
			if(@odat != @rdat)
			{
				print STDERR "Line $li: Column count mismatch.\n";
				return -3;
			}
			for(my $i=0; $i<@odat; ++$i)
			{
				# Textual comparison first. Then on to numerics.
				next
					if $odat[$i] eq $rdat[$i];
				# If they are not textually identical but contain numbers,
				# they can still be considered equal if difference is small.
				if( not ($odat[$i] =~ /^[+\-\d]/ and $odat[$i] =~ /^[+\-\d]/) or
					abs($odat[$i] - $rdat[$i]) > $epsilon )
				{
					print STDERR "Line $li: Difference in column ".($i+1).".\n";
					return -4;
				}
			}
		}
		return 0;
	}
	else
	{
		print STDERR "Cannot access data for comparison.\n";
		return -1;
	}
}

sub txdtest
{
	my ($app, $args, $indata, $reffile, $epsilon) = @_;
	my $outstr;
	open(my $in, '<', $indata);
	open(my $out, '>', \$outstr);
	$app->run($args, $in, $out);
	close($out);
	close($in);

	if(txdtestutil::txdcompare(\$outstr, $reffile, $epsilon) == 0)
	{
		return 1;
	}
	else
	{
		if(ref $reffile eq 'SCALAR')
		{
			print STDERR "Comparison failed. Reference data:\n"; 
			print STDERR $$reffile;
			print STDERR "Computed data:\n"
		}
		else
		{
			print STDERR "Comparison failed: $reffile\n";
		}
		print STDERR "$outstr";
		return 0;
	}
}

1;
