package NewSpirit::Param1x;

# this is an old spirit 1.x module, which is only
# used to convert some data files to the new format

use strict;

sub Hash2Scalar {
	my ($href) = @_;

	my $buffer = "";

	Rec_Hash2Scalar ($href, \$buffer, '');

	return \$buffer;
}

sub Rec_Hash2Scalar {
	my ($href, $sref, $path) = @_;

	my ($k, $v);
	while ( ($k, $v) = each (%{$href}) ) {
		Encode (\$k);
		if ( ref $v eq 'HASH' ) {
			Rec_Hash2Scalar ($v, $sref, $path.$k."\t");
		} else {
			Encode (\$v);
			$$sref .= $path.$k."\t".$v."\n";
		}
	}
}

sub Scalar2Hash {
	my ($sref) = @_;
	my $line;
	my %hash;
	my ($varname, $content);

	while ( $$sref =~ /\G(.*)\n/g ) {
		$line = $1;
		next if $line eq '';
		if ( $line =~ /(.*)\t([^\t]*)$/ ) {
			($varname, $content) = ($1, $2);
		} else {
			return undef;
		}
		$varname =~ s/\t/'}{'/g;
		$varname = '$hash{\''.$varname.'\'}';
		Decode (\$content);
		Decode (\$varname);
		$content =~ s/'/\'/;
		eval ("$varname = \$content;");
		return undef if $@;
	}

	return \%hash;
}

sub Encode {
	my ($value) = @_;

	$$value =~ s/\%/%p/g;
	$$value =~ s/\t/%t/g;
	$$value =~ s/\n/%n/g;

	return $value;
}

sub Decode {
	my ($value) = @_;

	$$value =~ s/%p/%/g;
	$$value =~ s/%t/\t/g;
	$$value =~ s/%n/\n/g;

	return $value;
}

1;
  
