
    if($op->name eq 'sassign') {
	my $dst = $state->next->next;
	my $src = $state->next;
	if($dst->name eq 'padsv' && $dst->next->name eq 'sassign') {
	    my $cv = $op->find_cv();
	    if(exists($pads{$cv->ROOT->seq}) && 
	       exists($pads{$cv->ROOT->seq}->[$dst->targ]) &&
	       $pads{$cv->ROOT->seq}->[$dst->targ]->[1]->{tied}
	       ) {
#		print "sassign tied optimization possible\n";


#		return;
		my $n = $op->next;
#		$op->next(0);
		$op->first(0);
		$op->null();
#		$op->dump();

		my $pushmark = B::OP->new("pushmark",2);
		$state->next($pushmark);
		$pushmark->next($dst);
		$pushmark->seq(optimizer::op_seqmax_inc());
		my $tied = B::UNOP->new('tied',38,$dst);
		$tied->seq(optimizer::op_seqmax_inc());
		$pushmark->sibling($tied);
#		$dst->flags(50);
		$dst->next($tied);
		$tied->next($src);
		$tied->sibling($src);
#		$src->flags(34);
		
		my $method_named = B::SVOP->new('method_named',0,"STORE");
		$method_named->seq(optimizer::op_seqmax_inc());
		$src->next($method_named);
		$src->sibling($method_named);


		my $entersub = B::UNOP->new('entersub',69,0);
		$entersub->seq(optimizer::op_seqmax_inc());
		$method_named->next($entersub);
		$entersub->next($n);		
		$entersub->first($pushmark);
		$state->sibling($entersub);

		if($n->flags & OPf_KIDS) {
		    my $no_sibling = 1;
		    for (my $kid = $n->first; $$kid; $kid = $kid->sibling) {
			if($kid->seq == $entersub->seq) {
			    $no_sibling = 0;
			    last;
			}
		    }
		    if($no_sibling) {
			$entersub->sibling($n);
		    }
		} else {
		    $entersub->sibling($n);
		}
#		print $tied->next->name . "\n";
#		print $src->next->name . "\n";
#		print $dst->next->name . "\n";

	    }
	}
    } elsif($op->name eq 'padsv' && !($op->flags & OPf_MOD)) {
	my $cv = $op->find_cv();
	if(exists($pads{$cv->ROOT->seq}) && 
	   exists($pads{$cv->ROOT->seq}->[$op->targ]) &&
	   $pads{$cv->ROOT->seq}->[$op->targ]->[1]->{tied}
	   ) {
#	    print $old_op->seq . " - " . $state->seq . "\n";
#	    $old_op->dump();
#	    $op->dump();
	    my $sibling = $op->sibling();

	    my $pushmark = B::OP->new("pushmark",2);
	    my $n = $op->next();
            $old_op->next($pushmark);
	    $pushmark->seq(optimizer::op_seqmax_inc());
	    $pushmark->next($op);
	    $op->sibling(0);
	    my $tied = B::UNOP->new('tied',38,$op);
	    $pushmark->sibling($tied);
	    $op->next($tied);
	    my $method_named = B::SVOP->new('method_named',OPf_WANT_SCALAR,"FETCH");
	    $tied->sibling($method_named);
#	    $tied->seq(optimizer::op_seqmax_inc());
	    $tied->next($method_named);
	    my $entersub = B::UNOP->new('entersub',OPf_WANT_SCALAR| OPf_PARENS | OPf_STACKED,0);
#	    $method_named->seq(optimizer::op_seqmax_inc());
	    $method_named->next($entersub);
	    $entersub->first($pushmark);
#	    $entersub->seq(optimizer::op_seqmax_inc());
	    $entersub->next($n);
	    $entersub->sibling($sibling);
	    $n->next->first($entersub);
#	    $old_op->sibling($entersub);
	}
    }

};
