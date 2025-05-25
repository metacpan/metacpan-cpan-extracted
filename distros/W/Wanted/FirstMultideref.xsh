=begin comment
// NOTE: first_multideref_type
/*
 * first_multideref_type - Determines the reference type (ARRAY or HASH) for an
 *                         OP_MULTIDEREF operation.
 *
 * Perl Version: Requires Perl v5.22.0 or later.
 *               OP_MULTIDEREF was introduced in Perl 5.22.
 *
 * Arguments:
 *     I32 uplevel
 *         How many levels up the call stack to examine the op tree.
 *
 * Return:
 *     A mortalised Perl scalar (SV*) containing a string:
 *         - "ARRAY" if the multideref op resolves to an array dereference
 *         - "HASH"  if it resolves to a hash dereference
 *
 *     Throws a fatal exception if:
 *         - The op at the given uplevel is not of type OP_MULTIDEREF
 *         - The OP_MULTIDEREF action is unrecognised
 *         - Called on a Perl version earlier than v5.22.0
 *
 * Usage Example in Perl (via XS binding):
 *
 *     if( $ref_type = Wanted::first_multideref_type(1) )
 *     {
 *         say "Reference type: $ref_type";  # ARRAY or HASH
 *     }
 *
 * Notes:
 * - This is used internally by the `wantref()` and `context()` functions to determine
 *   whether the user expects an ARRAY or HASH reference in contexts using Perl's
 *   optimised multideref op.
 *
 * - Because OP_MULTIDEREF is a compound op containing a sequence of deref actions
 *   (stored in 'op_aux'), this function inspects the action sequence and identifies
 *   the first relevant dereference type.
 *
 * - If MDEREF_reload is encountered, it advances to the next action.
 *   This loop ensures it finds the actual dereference operation.
 *
 * - Not intended for external use. If exposed, the XS wrapper should sanitise input and
 *   protect against unsupported contexts.
 *
 * Related:
 *     See perldiag: https://perldoc.perl.org/5.22.0/perl5220delta#Internal-Changes
 *     See MDEREF_* constants in perl.h / op.h for more info.
 */
=cut
#if PERL_VERSION_GE(5, 22, 0)

char*
first_multideref_type(uplevel)
I32 uplevel;
  PREINIT:
    OP *r;
    OP *o = parent_op(uplevel, &r);
    UNOP_AUX_item *items;
    UV actions;
    bool repeat;
    char *retval;
  PPCODE:
    if (o->op_type != OP_MULTIDEREF)
        Perl_croak(aTHX_ "Not a multideref op!");

    items = cUNOP_AUXx(o)->op_aux;
    actions = items->uv;

    do
    {
        repeat = FALSE;
        switch (actions & MDEREF_ACTION_MASK)
        {
            case MDEREF_reload:
                actions = (++items)->uv;
                repeat = TRUE;
                continue;
            case MDEREF_AV_pop_rv2av_aelem:
            case MDEREF_AV_gvsv_vivify_rv2av_aelem:
            case MDEREF_AV_padsv_vivify_rv2av_aelem:
            case MDEREF_AV_vivify_rv2av_aelem:
            case MDEREF_AV_padav_aelem:
            case MDEREF_AV_gvav_aelem:
                retval = "ARRAY";
                break;
            case MDEREF_HV_pop_rv2hv_helem:
            case MDEREF_HV_gvsv_vivify_rv2hv_helem:
            case MDEREF_HV_padsv_vivify_rv2hv_helem:
            case MDEREF_HV_vivify_rv2hv_helem:
            case MDEREF_HV_padhv_helem:
            case MDEREF_HV_gvhv_helem:
                retval = "HASH";
                break;
            default:
                Perl_croak(aTHX_ "Unrecognised OP_MULTIDEREF action (%lu)!", actions & MDEREF_ACTION_MASK);
        }
    } while (repeat);

    EXTEND(SP, 1);
    PUSHs(sv_2mortal(newSVpv(retval, 0)));

#else

char*
first_multideref_type(uplevel)
I32 uplevel;
  PPCODE:
    Perl_croak(aTHX_ "first_multideref_type is not supported on this Perl version");

#endif
