#   CONST.PL -- Create lookup.h by parsing constants from egcs 1.1
#   Defines.h, Messages.h, Errors.h, Base.h, & Sockets.h
#   Copyright (C) 1998 Brian Dellert: aspider@pobox.com, 206/689-6828,
#   http://www.applespider.com

#   This program is free software; you can redistribute it and/or modify it
#   under the terms of the GNU General Public License as published by the
#   Free Software Foundation; either version 2 of the License, or (at your
#   option) any later version.
#
#   This program is distributed in the hope that it will be useful, but
#   WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
#   or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
#   for more details.
#
#   You should have received a copy of the GNU General Public License along
#   with this program (gpl.license.txt); if not, write to the Free Software
#   Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.

use strict;
my (%Var_Short, %Var_Long, %Var_ULong, %Var_String, %Var_WString);
my @Num_Vars = (\%Var_Short, \%Var_Long, \%Var_ULong);
my @All_Vars = (@Num_Vars, \%Var_String, \%Var_WString);

if ($ARGV[0] eq '-v') {
	&out_license;
	exit;
}
&out_begin;
&parse_files;
&out_arrays;
&out_end;


sub out_array {
	my ($hash, $type, $format) = @_;
	my @keys = sort keys %$hash;
	my $type_name = $type;
	$type_name =~ s/\s+/_/g;
	$type_name =~ s/\*/ptr/g;

	print qq|const unsigned long const_${type_name}_max = $#keys;\n|,

		qq|const char* const_${type_name}_names[] = {|,
		join(",\n", map{qq|"$_"|} @keys), "\n};\n",

		qq|const $type const_${type_name}_vals[] = {|,

		defined $format
			? join(",\n", map{sprintf($format, $hash->{$_})} @keys)
			: join(",\n", map{$hash->{$_}} @keys),

		"\n};\n";
}

sub out_arrays {
	&out_array(\%Var_Short, 'short');
	&out_array(\%Var_Long, 'long');
	&out_array(\%Var_ULong, 'unsigned long');
	&out_array(\%Var_String, 'char*');
	&out_array(\%Var_WString, 'wchar_t*');
}

sub parse_files {
	my (@preproc, %var_misc);
	while (<>) {
		my $line = $_;
		chomp $line;

		while ($line =~ s/\\$//) {
			$line =~ s/\s+\|$/\|/;
			my $next_line = <>;
			last unless defined $next_line;
			$next_line =~ s/^\s+//;
			$next_line =~ s/\s+$//;
			$line .= $next_line;
		}

		if ($line =~ m/^(#if(n?def)?)\b/) {
			push @preproc, $1;
			next;
		}
		elsif ($line =~ m/^#else\b/) {
			push @preproc, "#else";
			next;
		}
		elsif ($line =~ m/^#endif\b/) {
			my $last = pop @preproc;
			pop @preproc if $last eq "#else";
			next;
		}

		if (@preproc) {
			my $last = $preproc[$#preproc];
			if ($last eq "#if" or $last eq "#ifdef" or ($last eq "#else" and $preproc[$#preproc-1] eq "#ifndef")) {
				next;
			}
		}
		if ($line !~ m/^#define\s+([a-z_]\w*)\s+(.*)/i) {
			next;
		}
		my ($name, $val) = ($1, $2);
		$val =~ s/\s+$//;
		$val =~ s!\s*/\*.*\*/$!!;
		$val =~ s!\(\s*[a-z_]\w*\s*\*?\s*\)!!ig;
		$val =~ s!\b[a-z_]\w*\s*\(([^)]*)\)!$1!ig;
		next unless $val =~ /\S/;

		if ($val =~ m!^".*"$!) {
			$Var_String{$name} = $val;
		}
		elsif ($val =~ m!^L".*"$!) {
			$Var_WString{$name} = $val;
		}
		elsif ($val =~ m!^L?'(.)'$!) {
			&assign_num($name, ord($1));
		}
		else {
			$val =~ s/\b(0x[a-f\d]+)L\b/$1/ig;
			$val =~ s/\b(\d+)L\b/$1/g;
			my $num = &eval_number($val);
			if (defined $num) {
				&assign_num($name, $num);
			}
			elsif (not exists $var_misc{$name}) {
				$var_misc{$name} = $val;
			}
			elsif ($var_misc{$name} ne $val) {
				print STDERR qq|Warning: Duplicate $name = "$var_misc{$name}", "$val"\n|;
			}
		}
	}

	&parse_misc(\%var_misc);
}

sub eval_number {
	my $exp = shift;
	my ($warn, $num);
	{
		local $SIG{__WARN__} = sub {$warn =1};
		$num = eval $exp;
		$warn |= ($@ or $num ne $num+0);   # check for bogus refs with $num+0
	}
	return $warn ? undef : $num;
}

sub parse_misc {
	my $var_misc = shift;

	my $last_key_count;
	while (1) {
		my $key_count = keys %$var_misc;
		last if defined $last_key_count and $key_count >= $last_key_count;
		$last_key_count = $key_count;

		for my $name (keys %$var_misc) {
			my $val = $var_misc->{$name};

			next unless $val =~ m/\b([a-z_]\w*)/i;
			my $dep = $1;

			if ($dep eq $val) {
				for my $hash (@All_Vars) {
					if (defined $hash->{$dep}) {
						$hash->{$name} = $hash->{$dep};
						delete $var_misc->{$name};
						last;
					}
				}
			}
			else {
				my ($hash, $error);
				$val =~ s/\b([a-z_]\w*)/&replace_const($1, $hash, $error)/eig;

				if (!$error) {
					my $num = &eval_number($val);
					if (defined $num) {
						&assign_num($name, $num);
						delete $var_misc->{$name};
						next;
					}
				}
				$var_misc->{$name} = $val;
			}
		}
	}
	for my $name (sort keys %$var_misc) {
		print STDERR qq|Warning: Skipping $name = "$var_misc->{$name}"\n|;
	}
}

sub replace_const {
	my $const = shift;

	for my $hash (@Num_Vars) {
		if (defined $hash->{$const}) {
			$_[0] = $hash;
			return $hash->{$const};
		}
	}
	$_[1] = 1;
	return $const;
}


sub assign_num {
	my ($name, $val) = @_;
	if (-0x8000 <= $val and $val <= 0x7FFF) {
		$Var_Short{$name} = $val;
	}
	elsif (-0x80000000 <= $val and $val <= 0x7FFFFFFF) {
		$Var_Long{$name} = $val;
	}
	elsif (0 <= $val and $val <= 0xFFFFFFFF) {
		$Var_ULong{$name} = $val;
	}
	else {
		print STDERR qq|Warning (out of range): $name = "$val"\n|;
	}
}

sub out_begin {
	print <<'EndHere';
/*
 *  LOOKUP -- Lookup Win32 Constants--constants parsed from egcs 1.1
 *  Defines.h, Messages.h, Errors.h, Base.h, & Sockets.h
 *  Copyright (C) 1998 Brian Dellert: aspider@pobox.com, 206/689-6828,
 *  http://www.applespider.com

 *  This program is free software; you can redistribute it and/or modify it
 *  under the terms of the GNU General Public License as published by the
 *  Free Software Foundation; either version 2 of the License, or (at your
 *  option) any later version.
 *
 *  This program is distributed in the hope that it will be useful, but
 *  WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
 *  or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
 *  for more details.
 *
 *  You should have received a copy of the GNU General Public License along
 *  with this program (gpl.license.txt); if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#ifndef _WINDOWS32_LOOKUP_H
#define _WINDOWS32_LOOKUP_H
EndHere
}

sub out_end {
	print <<'EndHere';
#endif
EndHere
}


sub out_license {
	print <<'EndHere';
CONST.PL -- Create lookup.h by parsing constants from egcs 1.1
Defines.h, Messages.h, Errors.h, Base.h, & Sockets.h
Copyright (C) 1998 Brian Dellert: aspider@pobox.com, 206/689-6828,
http://www.applespider.com

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 2 of the License, or (at your
option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
for more details.

You should have received a copy of the GNU General Public License along
with this program (gpl.license.txt); if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
EndHere
}
