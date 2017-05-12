package types;

use 5.008;
use strict;
use warnings;
use optimize;

our $VERSION;
$VERSION = do { my @r = (q$Revision: 1.5 $ =~ /\d+/g); $r[0] = 0; sprintf "%d."."%02d" x $#r, @r }; # must be all one line, for MakeMaker


my %typed;
my %op_returns;
my %function_returns;
my %function_params;
use constant SVpad_TYPED => 0x40000000;
use B qw(OPpTARGET_MY OPf_MOD SVf_POK);
use B::Utils;

our %const_map = (
	  "B::NV" => 'float',
	  "B::IV" => 'int',
	  "B::PV" => 'string',
	    );


sub compare_type {
    my($a,$b) = @_;
    if($a eq $b) {
	return 1;
    }
    return 0;
}

sub B::NULL::name { "void" }
use Data::Dumper;
sub check {
    my $class = shift;
    my $op = shift;
    my $cv = $op->find_cv();

    #if($^H & 0x00000010) {
    unless($optimize::state->private & 0x00000010) {
	return;
    }


#    if($op->name eq 'padsv') {
#	print $op->flags ."\n";
#    }

    if(ref($op) eq 'B::PADOP' && $op->name eq 'gv') {
#	$op->dump;
	my $target = (($cv->PADLIST->ARRAY)[1]->ARRAY)[$op->padix];
#	$target->dump;
#	exit;
    }

    if($op->name eq 'int') {
	$op_returns{$op->seq}->{type} = 'int';
	$op_returns{$op->seq}->{name} = 'int()';
    }

    if($op->name eq 'padsv') {
	my $target = (($cv->PADLIST->ARRAY)[0]->ARRAY)[$op->targ];
	if(UNIVERSAL::isa($target,'B::SV') && $target->FLAGS & SVpad_TYPED) {
	    $typed{$cv->ROOT->seq}->{$op->targ}->{type} = $target->SvSTASH->NAME;
	    $typed{$cv->ROOT->seq}->{$op->targ}->{name} = $target->PV;
	} elsif(UNIVERSAL::isa($target,'B::SV') && 
		exists($typed{$cv->ROOT->seq}->{$target->PV})) {
	    $typed{$cv->ROOT->seq}->{$op->targ} = $typed{$cv->ROOT->seq}->{$target->PV};
	}
    }
    if($cv->FLAGS & SVf_POK && !$function_params{$cv->START->seq}) {
	#we have, we have, we have arguments
	my @type;
	my @name;
	my $i = 1;
	foreach (split ",", $cv->PV)  {
	    my ($type, $sigil, $name) = split /\b/, $_;
	#    print "$type - $sigil - $name \n";	    
	    push @type, $type;
	    if($sigil && $name)  {
		push @name, $sigil.$name;
		$typed{$cv->ROOT->seq}->{"$sigil$name"}->{type} = $type;
		$typed{$cv->ROOT->seq}->{"$sigil$name"}->{name} = $sigil.$name;
	    } else {
		push @name, "Argument $i";
	    }
	    $i++;
	}

	$function_params{$cv->START->seq}->{name} = \@name;
	$function_params{$cv->START->seq}->{type} = \@type;


	#print $cv->PV . "\n";
	$cv->PV(";@");

    }

    if(ref($op->next) ne 'B::NULL' &&
       ($op->next->name =~/2cv$/ || 
	($op->next->name eq 'null' && $op->next->oldname =~/2cv$/))) {
	my $entersub = $op->next;
	my $i = 1;

	while($entersub->name ne 'entersub' && 
	      ref($entersub->next) ne 'B::NULL') {
	    $i++ if($entersub->name ne 'null');
	    $entersub = $entersub->next;

	}
	if($entersub->name eq 'entersub') {
	    my $sv; 
	    if(ref($op) eq 'B::PADOP') {
		$sv = (($cv->PADLIST->ARRAY)[1]->ARRAY)[$op->padix];
	    } else {
		die;
	    }
	    if(ref($sv->CV) ne 'B::SPECIAL') {
		my $foo = $sv->CV->START->seq;
		if(exists($function_returns{$foo})) {
		    $op_returns{$op->seq + $i}->{type} = $function_returns{$foo}->{type};
		    $op_returns{$op->seq + $i}->{name} = $sv->STASH->NAME . "::" . $sv->SAFENAME."()";
#		print "AND IT HAS A RETURN VALUE $i\n";
		}
		if(exists($function_params{$foo})) {
		    my $param_list = $entersub->first();
		    get_list_proto($param_list, $cv);
		    $param_list = delete($op_returns{$param_list->seq});
		    pop(@{$param_list->{type}});
		    pop(@{$param_list->{name}});
#		    print Data::Dumper::Dumper($function_params{$foo});
#		    print Data::Dumper::Dumper($param_list);
		    match_protos($function_params{$foo}, $param_list);
		}
#	    $sv->CV->dump();
	    }
	}
    }

sub match_protos {
    my ($target, $source) = @_;
    my $targets = scalar @{$target->{name}} - 1;
    my $sources = scalar @{$source->{name}} - 1;

    if($sources < $targets) {
	die "Not enough items in list at " . 
	    $optimize::state->file . ":" . 
		$optimize::state->line . "\n";
    }
    foreach my $i (0..$targets) {
	my ($target_name, $target_type) = 
	    ($target->{name}->[$i], $target->{type}->[$i]);
	my ($source_name, $source_type) = 
	    ($source->{name}->[$i], $source->{type}->[$i]);
	if((!$target_type->isa($source_type) and !$source_type->isa($target_type)) or ($target_type->can('check') && !$target_type->check($source_type))) {
	    die "Type mismatch in list for" . 
		" $source_type ($source_name) to $target_type ($target_name) at " . 
		    $optimize::state->file . ":" . 
			$optimize::state->line . "\n";
	}

	 
    }
}
    
    if(ref($op->next) ne 'B::NULL') {
#	print $op->name . " - " . $op->next->name . "\n";
    }
    if(ref($op->next) ne 'B::NULL' &&
       ref($op->next->next) ne 'B::NULL' &&
       $op->next->next->name eq 'entersub') {
#	print "sub entry\n";
    }


    if(ref($op) eq 'B::LISTOP' && $op->first->name eq 'pushmark') {
	get_list_proto($op,$cv);
    }    
    

    if(ref($op->next) ne 'B::NULL' &&
       ref($cv->START) ne 'B::NULL' &&
       ($op->next->name eq 'lineseq' &&
	$op->next->next->name =~/^leave/) ||
       $op->next->name eq 'return') {
	my ($type, $value, $const) = get_type($op, $cv);
	my $lineseq = $op->next;
	my $leave = $lineseq->next;

      	if(exists($function_returns{$cv->START->seq}) &&
	   $function_returns{$cv->START->seq}->{type} ne $type) {
	    die "Return type mismatch: " . $op->name . 
		" $type at " . 
		    $optimize::state->file . ":" . 
			$optimize::state->line . " does not match" .
			    " return value $function_returns{$cv->START->seq}->{type}".
				" at $function_returns{$cv->START->seq}->{file}\n";
	    
	    
	    
	}
	
	
	my $subname = "";
	
	if(ref($cv->GV) ne 'B::SPECIAL' && $cv->GV->SAFENAME ne '__ANON__') {
	    $subname = $cv->GV->STASH->NAME . "::" . $cv->GV->SAFENAME;
	}
	if($subname && exists($function_returns{$subname}) &&
	   $function_returns{$subname}->{type} ne $type) {
	    die "Function $subname redefined with a different type (was $function_returns{$subname}->{type} now $type) at " . $optimize::state->file . ":" . $optimize::state->line . "\n";
	}


	
	$function_returns{$cv->START->seq}->{type}  = $type;
	$function_returns{$cv->START->seq}->{name} = $value;
	$function_returns{$cv->START->seq}->{file} = $optimize::state->file . ":" . $optimize::state->line;

	if($subname) {
	    $function_returns{$subname} = $function_returns{$cv->START->seq};
#	    print "GOT subname $subname\n";
	}
#	print "scope leave retval ($type, $value): " . $op->name . "-" . $lineseq->next->name . "\n";


    }





    if(ref($op) eq 'B::BINOP') {
	
	my ($lhs, $rhs, $target, $expr, $const, $mod);
	my ($lhs_v, $rhs_v, $target_v, $expr_v);
	

	if($op->private & OPpTARGET_MY && 
	   exists($typed{$cv->ROOT->seq}->{$op->targ})) {
		$target   = $typed{$cv->ROOT->seq}->{$op->targ}->{type};
		$target_v = $typed{$cv->ROOT->seq}->{$op->targ}->{name};
	}

	if($op->first->name eq 'padsv'
	   && exists($typed{$cv->ROOT->seq}->{$op->first->targ})) {
	    $rhs    = $typed{$cv->ROOT->seq}->{$op->first->targ}->{type};
	    $rhs_v  = $typed{$cv->ROOT->seq}->{$op->first->targ}->{name};
	} elsif(exists($op_returns{$op->first->seq})) {
	    $rhs = $op_returns{$op->first->seq}->{type};
	    $rhs_v = $op_returns{$op->first->seq}->{name};
	} elsif($op->first->name eq 'const' && 
		exists($const_map{ref($op->first->sv)})) {
	    $rhs = $const_map{ref($op->first->sv)};
	    $rhs_v = "constant '" . $op->first->sv->sv."'";
	    $const++;
	} elsif($op->first->name eq 'null' &&
		$op->first->oldname eq 'list') {
	    get_list_proto($op->first,$cv);
	} 

	if($op->last->name eq 'padsv'
	   && exists($typed{$cv->ROOT->seq}->{$op->last->targ})) {
	    $lhs    = $typed{$cv->ROOT->seq}->{$op->last->targ}->{type};
	    $lhs_v  = $typed{$cv->ROOT->seq}->{$op->last->targ}->{name};
	    if($op->last->flags & OPf_MOD) {
		die "target should be empty" if($target);
		$target = $lhs;
		$target_v = $lhs_v;
		$mod++;
	    }
	} elsif(exists($op_returns{$op->last->seq})) {
	    $lhs = $op_returns{$op->last->seq}->{type};
	    $lhs_v = $op_returns{$op->last->seq}->{name};
	} elsif($op->last->name eq 'const' && 
		exists($const_map{ref($op->last->sv)})) {
	    $lhs = $const_map{ref($op->last->sv)};
	    $lhs_v = "constant '" . $op->last->sv->sv."'";

	} elsif($op->last->name eq 'null' &&
		$op->last->oldname eq 'list') {
	    get_list_proto($op->first,$cv);
	}


	$lhs_v = $lhs = "unknown" unless($lhs);
	$rhs_v = $rhs = "unknown" unless($rhs);
	
	$target_v = $target = "" unless($target);


	return if($target eq '' && $const);


	#first lets deterimne what the expression returns
	# if they are equal the expression returns that
	# otherwise it returns what is higher on he inclusion team

	
	{
	    my($is_lhs, $is_rhs) = (0,0);
	    if($lhs->can("check") && $lhs->check($rhs)) {
		$is_lhs = 1;
	    } elsif($lhs->isa($rhs)) {
		$is_lhs = 1;
	    }

	    if($rhs->can("check") && $rhs->check($lhs)) {
		$is_rhs = 1;
	    } elsif($rhs->isa($lhs)) {
		$is_rhs = 1;
	    }
	    if($is_lhs && $is_rhs) {
		$expr = $lhs;

	    } elsif($is_lhs) {
		$expr = $lhs;
#		print "$lhs < $rhs\n";
	    } elsif($is_rhs) {
		$expr = $rhs;
#		print "$rhs < $lhs\n";
	    } else {
		die "Type mismatch, can't " . $op->name . 
		    " $rhs ($rhs_v) to $lhs ($lhs_v) at " . 
			$optimize::state->file . ":" . 
			    $optimize::state->line . "\n";
	    }
	    $expr_v = "$lhs_v, $rhs_v";
#	    print "Expression returns ($expr) ($expr_v)" .
#		$optimize::state->file . ": . " . 
#		    $optimize::state->line . "\n";
	}
	

#	return if(!$lhs and $op->first->name eq 'const');
	
#

	unless($target) {
	    #the target is empty
	    $op_returns{$op->seq}->{type} = $expr;
	    $op_returns{$op->seq}->{name} = $expr_v;	    
	    return;
	}
	
#	print "$expr - $target\n";
#	print "$target->isa($expr): ". $target->isa($expr) . "\n";
#	print "$expr->isa($target): ". $expr->isa($target) . "\n";



	if((!$target->isa($expr) and !$expr->isa($target)) or ($target->can('check') && !$target->check($expr))) {
	    if($mod) {
		die "Type mismatch, can't " . $op->name . 
		    " $rhs ($rhs_v) to $lhs ($lhs_v) at " . 
			$optimize::state->file . ":" . 
			    $optimize::state->line . "\n";
	    } else {
		die "Type mismatch, can't assign result of $lhs $lhs_v " 
		    . $op->name . " $rhs $rhs_v to $target ($target_v) at " 
			. $optimize::state->file . ":" 
			    . $optimize::state->line . "\n";
	    }
	}
	$op_returns{$op->seq}->{type} = $target;
	$op_returns{$op->seq}->{name} = $target_v;
    }

}

BEGIN { $optimize::loaded{"types"} = __PACKAGE__ }

sub import {
    my ($package, $filename, $line) = caller;
    #$^H |= 0x00020000; 
    #$^H{"use_types"}++;
    $^H |= 0x00000010;
#    optimize->register(\&entry, $package, $filename, $line);
}

sub unimport {
    my ($package, $filename, $line) = caller;
    $^H &= ~ 0x00000010;
    #$^H |= 0x00020000; 
    #delete($^H{"use_types"});
#    optimize->unregister($package);
}

sub get_type {
    my($op, $cv) = @_;
    my ($type, $value, $const) = ("","",0);
    if($op->name eq 'padsv'
       && exists($typed{$cv->ROOT->seq}->{$op->targ})) {
	$type   = $typed{$cv->ROOT->seq}->{$op->targ}->{type};
	$value  = $typed{$cv->ROOT->seq}->{$op->targ}->{name};
    } elsif(exists($op_returns{$op->seq})) {
	$type  = $op_returns{$op->seq}->{type};
	$value = $op_returns{$op->seq}->{name};
    } elsif($op->name eq 'const' && 
	    exists($const_map{ref($op->sv)})) {
	$type  = $const_map{ref($op->sv)};
	$value = "constant '" . $op->sv->sv."'";
	$const++;
    } elsif($op->name eq 'null' &&
	    $op->oldname eq 'list') {
	get_list_proto($op,$cv);
    } else {
	$type = $value = "unknown";
    }
    return ($type, $value, $const);
}

sub get_list_proto {
    my ($op, $cv) = @_;
    my $o = $op->first->sibling();
#    print "start\n";
    my @type;
    my @name;
    while(ref($o) ne 'B::NULL') {
	my $kid = $o;
	if($o->name eq 'null') {
	    $kid = $o->first;
	}
	if($kid->name eq 'padsv' &&
	   exists($typed{$cv->ROOT->seq}->{$kid->targ})) {
	    push @type, $typed{$cv->ROOT->seq}->{$kid->targ}->{type}; 
	    push @name, $typed{$cv->ROOT->seq}->{$kid->targ}->{name};	
	} elsif(exists($op_returns{$kid->seq})) {
	    push @type, $op_returns{$kid->seq}->{type}; 
	    push @name, $op_returns{$kid->seq}->{name};
	} elsif($kid->name eq 'const' && 
		exists($const_map{ref($kid->sv)})) {
	    push @type, $const_map{ref($kid->sv)};
	    push @name, $kid->sv->sv;
	} else {
	    push @type, "unknown";
	    push @name, "unknown";
	}
#	    print $kid->name . "\n";
	$o = $o->sibling;
    }

    if(@type > 1) {
	$op_returns{$op->seq}->{type} = \@type;
	$op_returns{$op->seq}->{name} = \@name;
    } else {
	$op_returns{$op->seq}->{type} = $type[0];
	$op_returns{$op->seq}->{name} = $name[0];
    }
    use Data::Dumper;
#    print Dumper(\@type);

}

package unknown;
our $dummy = 1;


package int;
our $dummy = 1;
sub check {
    return 0 if($_[0] eq 'int' && ($_[1] ne 'number' && $_[1] ne 'int'));    
    return 1;
}
package float;
use base qw(int);
sub check {
    return 0 if($_[1] eq 'string');
    return 1;
}
our $dummy = 1;
package number;
use base qw(float);
sub check {
    return 0 if($_[1] eq 'string');
    return 1;
}
our $dummy = 1;
package string;
use base qw(number);
sub check { return 1};
1;
__END__


=head1 NAME

types - Perl pragma for strict type checking

=head1 SYNOPSIS

  use types;
  my int $int;
  my float $float;
  $int = $float; # BOOM compile time error!

=head1 ABSTRACT

This pragma uses the optimzie module to analyze the optree and
turn on compile time type checking

=head1 SYNOPSIS

    my float $foo = "string"; #compile time error
    sub foo (int $foo) { my ($foo) = @_ };
    foo("hi"); #compile time error   

    my int $int;
    sub foo { my float $foo; return $foo }
    $int = $foo; # compile time error

=head1 DESCRIPTION

This pragma uses the optimzie module to analyze the optree and
turn on compile time type checking

Currently we support int, float, number ,string and user defined classes, 
the implict casting rules are as follows.

    
    int    < > number
    int      > float
    float  < > number
    number   > string


Normall type casting is allowed both up and down the inheritance tree,
so in theory user defined classes should work already, requires one
to do use base or set @ISA at compileitme in a BEGIN block.

=head2 Return values

Return values are implicitly figerd out by the subroutine, this includes 
both falling of the end or by expliticly calling return, if two return 
values of the same sub differ you will get an error message.

=head2 Arguments

Arguments are declared with prototype syntax, they can either be named
or just typed, if typed only the calling convertions are checked, if
named then that named lexical will get that type without the need
for expliticty typing it, thus allowing list assignment from @_

=head2 EXPORT

None.

=head1 BUGS

Please report bugs and submit patches using http://rt.cpan.org/


=head1 SEE ALSO

L<optimize> L<B::Generate> L<optimizer>

=head1 AUTHOR

Arthur Bergman, E<lt>ABERGMAN@CPAN.ORGE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2002 by Arthur Bergman

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
