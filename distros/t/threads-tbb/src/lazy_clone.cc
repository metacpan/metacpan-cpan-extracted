
extern "C" {
#define PERL_NO_GET_CONTEXT /* we want efficiency! */
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

}

#include "tbb.h"


/* this is a recursive clone, limited to the core Perl types; similar
 * to threads::shared::shared_clone, except:
 *
 * - clones from another interpreter; should be safe, so long as the
 *   other interpreter is not changing the marshalled data.  In
 *   particular, hashes are not iterated using hv_iterinit etc; this
 *   code is quite tied to the particular Perl API, until there is a
 *   better C-level (const) iterator API for hashes.
 *
 * - implemented using a stack and map; the approach is quite similar
 *   to the one used in shared_clone's private closure, except using
 *   C++ and STL templates.
 */

#include  <list>
#include  <map>

class graph_walker_slot {
public:
	SV* tsv;
	bool built;
	graph_walker_slot() {};
	graph_walker_slot( SV* tsv, int built = false )
		: tsv(tsv), built(built) { };
};

SV* clone_other_sv(PerlInterpreter* my_perl, const SV* sv, const PerlInterpreter* other_perl) {

	std::list<const SV*> todo;
	std::map<const SV*, graph_walker_slot> done;
	std::map<const SV*, graph_walker_slot>::iterator item, target;

	todo.push_back(sv);

	// undef is a second-class global.  map it.
	done[&other_perl->Isv_undef] = graph_walker_slot( &PL_sv_undef, true );

	const SV* it;
	MAGIC* mg;
	while (todo.size()) {
		it = todo.back();
		IF_DEBUG_CLONE("cloning %x", it);
		todo.pop_back();
		item = done.find( it );
		bool isnew = (item == done.end());
		//IF_DEBUG_CLONE("   SV is %s", (isnew ? "new" : "repeat"));
		if (!isnew && (*item).second.built) {
			// seen before.
			IF_DEBUG_CLONE("   seen, built");
			continue;
		}
		// mg_find is a pTHX_ function but should be OK...
		if (mg = SvTIED_mg(it, PERL_MAGIC_tied)) {
			IF_DEBUG_CLONE("   SV is TIED %s", sv_reftype(it,0));
			if (isnew) {
				done[it] = graph_walker_slot(newSV(0));
				IF_DEBUG_CLONE("   SV is new");
			}
			if ( ! mg->mg_obj ) {
				croak("no magic object to be found for tied %s at %x", sv_reftype(it,0), it);
			}
			target = done.find( mg->mg_obj );
			if ( target == done.end() ) {
				IF_DEBUG_CLONE("   tied SV (%x) unseen", mg->mg_obj);
				todo.push_back(it);
				todo.push_back(mg->mg_obj);
			}
			else {
				SV* obj = (*item).second.tsv;
				SV* mg_obj = (*target).second.tsv;
				IF_DEBUG_CLONE("   upgrading %x to type %d", obj, SvTYPE(it));
				SvUPGRADE(obj, SvTYPE(it));
				sv_magic(obj, mg_obj, PERL_MAGIC_tied, 0, 0);
				IF_DEBUG_CLONE("   made magic: %x (rc=%d)", mg_obj, SvREFCNT(mg_obj));
				done[it].built = true;
			}
		}
		else if (SvROK(it)) {
			IF_DEBUG_CLONE("   SV is ROK (%s)", sv_reftype(it,0));
			if (SvOBJECT(SvRV(it))) {
				IF_DEBUG_CLONE("     In fact, it's blessed");
				// should first check whether the type gets cloned at all...
				HV* pkg = SvSTASH(SvRV(it));
				target = done.find((SV*)pkg);
				if (target == done.end()) {
					const char * pkgname = HvNAME_get(pkg);
					IF_DEBUG_CLONE("     Ok, %s, that's new", pkgname);
					HV* lpkg = gv_stashpv(pkgname, GV_ADD);
					// not found ... before we map to a local package, call the CLONE_SKIP function to see if we should map this type.
					const HEK * const hvname = HvNAME_HEK(pkg);
					GV* const cloner = gv_fetchmethod_autoload(lpkg, "CLONE_SKIP", 0);
					UV status = 0;
					if (cloner && GvCV(cloner)) {
						IF_DEBUG_CLONE("     Calling CLONE_SKIP in %s", pkgname);
						dSP;
						ENTER;
						SAVETMPS;
						PUSHMARK(SP);
						mXPUSHs(newSVhek(hvname));
						PUTBACK;
						call_sv(MUTABLE_SV(GvCV(cloner)), G_SCALAR);
						SPAGAIN;
						status = POPu;
						IF_DEBUG_CLONE("     CLONE_SKIP returned %d", status);
						PUTBACK;
						FREETMPS;
						LEAVE;
					}
					else {
						IF_DEBUG_CLONE("     No CLONE_SKIP defined in %s", pkgname);
					}
					if (status) {
						IF_DEBUG_CLONE("     marking package (%x) as undef", pkg);
						done[(SV*)pkg] = graph_walker_slot(&PL_sv_undef, true);
						IF_DEBUG_CLONE("     CLONE SKIP set: mapping SV %x to undef", it);
						done[it] = graph_walker_slot(&PL_sv_undef, true);
						continue;
					}
					else {
						done[(SV*)pkg] = graph_walker_slot((SV*)lpkg, true);
						IF_DEBUG_CLONE("     adding package (%x) to done hash (%x)", pkg, lpkg);
					}
					target = done.find((SV*)pkg);
				}
				else {
					if ((*target).second.tsv == &PL_sv_undef) {
						IF_DEBUG_CLONE("     CLONE SKIP previously set: mapping SV to undef");
						continue;
					}
				}
			}
			if (isnew) {
				// '0' means that the item is on todo
				done[it] = graph_walker_slot(newSV(0));
				item = done.find( it );
				IF_DEBUG_CLONE("   SV is new");
			}

			// fixme: $x = \$x circular refs
			target = done.find( SvRV(it) );
			if (target == done.end()) {
				IF_DEBUG_CLONE("   refers to unseen ref %x", SvRV(it));
				// nothing, so remember to init self later.
				todo.push_back(it);
				todo.push_back(SvRV(it));
			}
			else {
				IF_DEBUG_CLONE("   refers to seen ref %x (%x)", SvRV(it), (*target).second.tsv);
				if ((*target).second.tsv == &PL_sv_undef) {
					IF_DEBUG_CLONE("   => undef");
					done[it] = graph_walker_slot( &PL_sv_undef, true );
					continue;
				}
				// target exists!  set the ref
				IF_DEBUG_CLONE("   (upgrade %x to RV)", (*item).second.tsv);
				SvUPGRADE((*item).second.tsv, SVt_RV);
				SvRV_set((*item).second.tsv, (*target).second.tsv);
				IF_DEBUG_CLONE("   (set RV targ)");
				SvROK_on((*item).second.tsv);
				IF_DEBUG_CLONE("   (set ROK)");
				SvREFCNT_inc((*target).second.tsv);
				IF_DEBUG_CLONE("   (inc rc to %d)", SvREFCNT((*target).second.tsv));
				(*item).second.tsv;
				
				IF_DEBUG_CLONE("   %x now refers to %x: ",
					       (*item).second.tsv,
					       (*target).second.tsv
					);

				// and here we bless things
				if (SvOBJECT(SvRV(it))) {
					HV* pkg = SvSTASH(SvRV(it));
					target = done.find((SV*)pkg);
					if (target == done.end()) {
						IF_DEBUG_CLONE("     couldn't find package in map :(");
					}
					sv_bless( (*item).second.tsv, (HV*) (*target).second.tsv );
					IF_DEBUG_CLONE("    blessed be! => %s", HvNAME_get(pkg));
					if (SvTYPE(SvRV(it)) == SVt_PVMG) {
						// XS object, it better know how to refcount.
						GV* const rc_inc = gv_fetchmethod_autoload(pkg, "CLONE_REFCNT_inc", 0);
						UV status = -1;
						if (rc_inc && GvCV(rc_inc)) {
							IF_DEBUG_CLONE("     Calling CLONE_REFCNT_inc in %s", HvNAME_get(pkg));
							dSP;
							ENTER;
							SAVETMPS;
							PUSHMARK(SP);
							XPUSHs( (*item).second.tsv );
							PUTBACK;
							call_sv(MUTABLE_SV(GvCV(rc_inc)), G_SCALAR);
							SPAGAIN;
							status = POPu;
							IF_DEBUG_CLONE("     CLONE_REFCNT_inc returned %d", status);
							PUTBACK;
							FREETMPS;
							LEAVE;
						}
						if (status != 42) {
							warn("Leaking memory because XS class %s didn't define CLONE_SKIP nor CLONE_REFCNT_inc (or CLONE_REFCNT_inc didn't return 42)", HvNAME_get(pkg));
						}
					}
				}
				done[it].built = true;
			}
		}
		else {
			// error: jump to case label crosses initialization of ‘...’
			bool all_found = true;
			int num;
			HE** contents;
			HE* he;
			const char* str;
			STRLEN len;
			SV* nsv;
			SV* magic_sv;
			IF_DEBUG_CLONE("   SV is not ROK but type %d", SvTYPE(it));
			switch (SvTYPE(it)) {
			case SVt_NULL:
			null_out:
				IF_DEBUG_CLONE("    => NULL (bugger)");
				done[it] = graph_walker_slot( &PL_sv_undef, true );
				break;
			case SVt_PVAV:
				IF_DEBUG_CLONE("     => AV");
				// array ... seen?
				if (isnew) {
					IF_DEBUG_CLONE("   new AV");
					done[it] = graph_walker_slot((SV*)newAV());
				}

				for (int i = 0; i <= av_len((AV*)it); i++ ) {
					SV** slot = av_fetch((AV*)it, i, 0);
					if (!slot)
						continue;

					target = done.find(*slot);
					if (target == done.end()) {
						if (all_found) {
							IF_DEBUG_CLONE("   contains unseen slot values");
							todo.push_back(it);
							all_found = false;
						}
						todo.push_back(*slot);
					}
				}
				if (all_found) {
					IF_DEBUG_CLONE("   no unseen slot values");
					AV* av = (AV*)done[it].tsv;
					IF_DEBUG_CLONE("   unshift av, %d", av_len((AV*)it)+1);
					av_unshift(av, av_len((AV*)it)+1);
					for (int i = 0; i <= av_len((AV*)it); i++ ) {
						SV** slot = av_fetch((AV*)it, i, 0);
						if (!slot)
							continue;
						SV* targsv = done[*slot].tsv;
						SV** slot2 = av_fetch( av, i, 1 );
						*slot2 = targsv;
						SvREFCNT_inc(targsv);
						IF_DEBUG_CLONE("      slot[%d] = %x (refcnt = %d, type = %d, pok = %d, iok = %d)", i, targsv, SvREFCNT(targsv), SvTYPE(targsv), SvPOK(targsv)?1:0, SvIOK(targsv)?1:0);
					}
					(SV*)av;
					done[it].built = true;
				}
				break;

			case SVt_PVHV:
				IF_DEBUG_CLONE("     => HV");
				// hash
				if (isnew) {
					IF_DEBUG_CLONE("   new HV");
					bool empty = HvARRAY(it) == 0;
					done[it] = graph_walker_slot((SV*)newHV(), empty);
					if (empty) {
						IF_DEBUG_CLONE("   empty HV! done");
						continue;
					}
				}

				// side-effect free hash iteration :)
				num = HvMAX(it);
				contents = HvARRAY(it);
				IF_DEBUG_CLONE("   walking over %d slots at contents @%x", num+1, contents);
				IF_DEBUG_CLONE("   (PL_sv_placeholder = %x)", &PL_sv_placeholder);
				for (int i = 0; i <= num; i++ ) {
				  IF_DEBUG_CLONE("   contents[%d] = %x", i, contents[i]);
					if (!contents[i])
						continue;
					HE* hent = contents[i];
				another_key:
					SV* val = HeVAL(hent);
					IF_DEBUG_CLONE("   {%s} = %x", HePV(hent, len), val);
					hent = hent->hent_next;
					// thankfully, PL_sv_placeholder is a superglobal.
					if (val != &PL_sv_placeholder) {
						target = done.find(val);
						if (target == done.end()) {
							if (all_found) {
								IF_DEBUG_CLONE("   contains unseen slot values");
								todo.push_back(it);
								all_found = false;
							}
							todo.push_back(val);
						}
					}
					if (hent != 0)
						goto another_key;
				}
				if (all_found) {
					IF_DEBUG_CLONE("   no unseen slot values");
					HV* hv = (HV*)done[it].tsv;
					for (int i = 0; i <= num; i++ ) {
						HE* hent = contents[i];
						if (!hent) {
							continue;
						}
					another_key_out:
						SV* val = HeVAL( hent );
						if (val != &PL_sv_placeholder) {
							STRLEN key_len;
							const char* key = HePV( hent, key_len );
						
							target = done.find(val);
							IF_DEBUG_CLONE("   hv_fetch(%x, '%s', %d, 1)", hv, key, key_len);
							SV**slot = hv_fetch( hv, key, key_len, 1); 
							IF_DEBUG_CLONE("   => %x", done[val].tsv);
							*slot = done[val].tsv;
							SvREFCNT_inc(*slot);
							//hv_store( hv, key, key_len, (*target).second.tsv, 0 );
						}
						hent = hent->hent_next;
						if (hent != 0)
							goto another_key_out;
					}
					(SV*)hv;
					//SvREFCNT_inc((SV*)hv);
					done[it].built = true;
				}
				break;
			case SVt_PVCV:
				// for now, barf.
				croak("cannot put CODE reference in a concurrent container");
				break;
			case SVt_PVGV:
				croak("cannot put GLOB reference in a concurrent container");
				break;
			case SVt_NV:
				IF_DEBUG_CLONE("     => NV (%g)", SvNVX(it));
				goto do_it;
			case SVt_IV:
				IF_DEBUG_CLONE("     => IV (%d)", SvIVX(it));
				goto do_it;
			case SVt_PVNV:	
				IF_DEBUG_CLONE("     => PVNV (%s%s%s)",
					       (SvPOK(it)?"POK, ":""),
					       (SvNOK(it)?"NOK, ":""),
					       (SvIOK(it)?"IOK, ":""));
				goto do_it;
			case SVt_PVIV:
				IF_DEBUG_CLONE("     => PVIV (%s%s%s)",
					       (SvPOK(it)?"POK, ":""),
					       (SvNOK(it)?"NOK, ":""),
					       (SvIOK(it)?"IOK, ":""));
				goto do_it;
			case SVt_PV:
				IF_DEBUG_CLONE("     => PV (%s)", SvPVX(it));
			do_it:
			  	if (SvPOK(it)) {
					str = SvPVX(it);
					len = SvCUR(it);
					nsv = newSVpv( str, len );
					IF_DEBUG_CLONE("     => stringval = '%s'", str);
				}
				else {
					nsv = newSV(0);
				}
				SvUPGRADE(nsv, SvTYPE(it));
				if (SvIOK(it)) {
					sv_setiv(nsv, SvIVX(it));
					IF_DEBUG_CLONE("     => int = '%d'", SvIVX(it));
				}
				if (SvNOK(it)) {
					sv_setnv(nsv, SvNVX(it));
					IF_DEBUG_CLONE("     => num = '%g'", SvNVX(it));
				}

				done[it] = graph_walker_slot(nsv, true);
				break;
			case SVt_PVMG:
				IF_DEBUG_CLONE("     => PVMG (%x)", SvIVX(it));
				IF_DEBUG_LEAK("new PVMG: %x", SvIVX(it));
				if (SvIVX(it) == 0)
					goto null_out; // bugger.
				done[it] = graph_walker_slot(newSViv(SvIVX(it)), true);
				break;
			default:
				croak("unknown SV type=%d (IV = %d); cannot marshall through concurrent container",
				      SvTYPE(it), SvIVX(it));
			}
			IF_DEBUG_CLONE("cloned %x => %x / t=%d / rc=%d", it, done[it].tsv, SvTYPE(done[it].tsv), SvREFCNT(done[it].tsv));
		}
	}

	SV* rv = done[sv].tsv;
	IF_DEBUG_CLONE("clone returning %x", rv);
	return rv;
}

SV* perl_concurrent_slot::dup( pTHX ) const {
	SV* rsv;
	if (this->owner == my_perl) {
		rsv = newSV(0);
		SvSetSV_nosteal(rsv, this->thingy);
		IF_DEBUG_CLONE("dup'd %x to %x (refcnt = %d)", this->thingy, rsv, SvREFCNT(rsv));
	}
	else {
		IF_DEBUG_CLONE("CLONING %x (refcnt = %d)", this->thingy, SvREFCNT(this->thingy));
		rsv = clone_other_sv( my_perl, this->thingy, this->owner );
		SvREFCNT_inc(rsv);
	}
	return rsv;
}

SV* perl_concurrent_slot::clone( pTHX ) const {
	IF_DEBUG_CLONE("CLONING %x (refcnt = %d)", this->thingy, SvREFCNT(this->thingy));
	SV* rsv = clone_other_sv( my_perl, this->thingy, this->owner );
	SvREFCNT_inc(rsv);
	return rsv;
}
