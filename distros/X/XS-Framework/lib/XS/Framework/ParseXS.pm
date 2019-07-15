package # hide from CPAN
    XS::Framework::ParseXS;
use 5.012;
use XS::Install::ParseXS;

my $tm_cast = 'T_TYPEMAP_CAST';

XS::Install::ParseXS::add_no_typemap_callback(sub {
    my ($typemaps, %args) = @_;

    $typemaps->add_typemap(
        ctype  => $args{ctype},
        xstype => $tm_cast,
    );
        
    unless ($typemaps->get_inputmap(xstype => $tm_cast)) {
        $typemaps->add_inputmap(
            xstype => $tm_cast,
            code   => '$var = xs::in<$type>(aTHX_ $arg);'.
                      '${\\( $var eq q{THIS} ? qq{ if (!SvOK($arg)) throw \\"undef not allowed as THIS\\";} : q{} )}',
        );
        $typemaps->add_outputmap(
            xstype => $tm_cast,
            code   => '$arg = xs::out(aTHX_ $var, PROTO).detach();',
        );
    }
});

XS::Install::ParseXS::add_pre_callback(sub {
    my ($parser, $ctx) = @_;
    my $lines = $parser->{line};
    my $linno = $parser->{line_no};
    my $func  = $ctx->{func};
    my $args  = $ctx->{args};
    my $fa    = $args->[0];
    
    my $is_empty = XS::Install::ParseXS::is_empty($lines);
    
    if ($func eq 'DESTROY' and $fa and $fa->{name} eq 'THIS') {
        my $in_tmap = $parser->{typemap}->get_inputmap(ctype => $fa->{type});
        XS::Install::ParseXS::insert_code_bottom($parser, "        xs::Typemap<$fa->{type}>().destroy(aTHX_ $fa->{name}, SvRV(ST(0)));")
           if $in_tmap && $in_tmap->xstype eq $tm_cast;
    }
    
    my $ret = $ctx->{ret};
    if ($ret !~ /^(void|SV\s*\*|bool)/) {{
        my $out_tmap = $parser->{typemap}->get_outputmap(ctype => $ret);
        last unless $out_tmap and $out_tmap->xstype eq $tm_cast;

	    if ($func eq 'new') {
	        XS::Install::ParseXS::insert_code_top($parser, "    PROTO = $fa->{name};") if $fa->{name};
            XS::Install::ParseXS::insert_code_bottom($parser, "    RETVAL = ".XS::Install::ParseXS::default_constructor($ret, $args).';') if $is_empty;
	    }

        XS::Install::ParseXS::insert_code_top($parser, "    xs::Sv PROTO; PERL_UNUSED_VAR(PROTO);");
    }}
    
});

XS::Install::ParseXS::add_post_callback(sub {
    my $outref = shift;
    if ($XS::Install::ParseXS::cplus) {
        #wrap content of XSUBs into try-catch blocks
        $$outref =~ s/$XS::Install::ParseXS::re_xsub/$1 { xs::throw_guard(aTHX_ cv, [aTHX_ cv]() \n$2); }/g;
        #wrap content of BOOT into try-catch blocks
        $$outref =~ s/$XS::Install::ParseXS::re_boot/$1 { xs::throw_guard(aTHX_ cv, [aTHX_ cv]() mutable\n$2); }/g;
    }
});

1;
