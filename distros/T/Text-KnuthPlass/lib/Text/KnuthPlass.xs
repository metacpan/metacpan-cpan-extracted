#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#define isPenalty(sv) (SvROK(sv) && sv_derived_from(sv, "Text::KnuthPlass::Penalty"))
#define ivHash(hv, key) (IV)SvIV(*hv_fetch((HV*)hv, key, strlen(key), TRUE))
#define nvHash(hv, key) (NV)SvNVx(*hv_fetch((HV*)hv, key, strlen(key), TRUE))
#define debug(x)

typedef SV * Text_KnuthPlass;

struct Breakpoint_s { 
    struct Breakpoint_s * prev;
    struct Breakpoint_s * next;
    struct Breakpoint_s * previous;
    struct Breakpoint_s * active; /* Just for candidates */
    NV demerits;
    NV ratio;
    IV line;
    IV position;
    IV fitness_class;
    HV* totals;
};

typedef struct Breakpoint_s Breakpoint;

typedef struct LinkedList_s {
    Breakpoint* head;
    Breakpoint* tail;
    IV list_size;
    AV* to_free;
} LinkedList;

// overrides _computeCost() in Perl (note name difference!)
//   a = $active, current_line = $currentLine in Perl
NV _compute_cost(Text_KnuthPlass self, IV start, IV end, Breakpoint* a, 
    IV current_line, AV* nodes) {
    IV  infinity   = ivHash(self, "infinity");  // $self->{'infinity'}
    HV* sum = (HV*)SvRV(*hv_fetch((HV*)self, "sum", 3, FALSE));
    HV* totals = a->totals;
    NV width = nvHash(sum, "width") - nvHash(totals,"width");
    AV* linelengths = (AV*)SvRV(*hv_fetch((HV*)self, "linelengths", 11, FALSE));
    /* ll is index of LAST element of linelengths, NOT the size (length) */
    I32 ll = av_len(linelengths);
    NV stretch = 0;
    NV shrink = 0;
    NV linelength = SvNV(*av_fetch(linelengths, current_line <= ll ? current_line-1 : ll, 0));

    debug(warn("Computing cost from %i to %i\n", start, end));
    debug(warn("Sum width: %f\n", nvHash(sum, "width")));
    debug(warn("Total width: %f\n", nvHash(totals, "width")));

    if (isPenalty(*av_fetch(nodes, end, 0))) {
        debug(warn("Adding penalty width\n"));
        width += nvHash(SvRV(*av_fetch(nodes,end, 0)),"width");
    }
    debug(warn("Width %f, linelength %f\n", width, linelength));

    if (width < linelength) {
        stretch = nvHash(sum, "stretch") - nvHash(totals, "stretch");
        debug(warn("Stretch %f\n", stretch));
        if (stretch > 0) {
            return (linelength - width) / stretch;
        } else {
            return infinity;
        }
    } else if (width > linelength) {
        debug(warn("Shrink %f\n", shrink));
        shrink = nvHash(sum, "shrink") - nvHash(totals, "shrink");
        if (shrink > 0) { 
            return (linelength - width) / shrink;
        } else {
            return infinity;
        }
    } else { return 0; }
}

// overrides _computeSum() in Perl (note name difference!)
HV* _compute_sum(Text_KnuthPlass self, IV index, AV* nodes) {
    HV* result = newHV();
    HV* sum = (HV*)SvRV(*hv_fetch((HV*)self, "sum", 3, FALSE));
    IV  infinity   = ivHash(self, "infinity");
    NV width = nvHash(sum, "width");
    NV stretch = nvHash(sum, "stretch");
    NV shrink = nvHash(sum, "shrink");
    I32 len = av_len(nodes);
    I32 i = index;

    while (i < len) {
        SV* e = *av_fetch(nodes, i, 0);
        if (sv_derived_from(e, "Text::KnuthPlass::Glue")) {
            width   += nvHash(SvRV(e), "width");
            stretch += nvHash(SvRV(e), "stretch");
            shrink  += nvHash(SvRV(e), "shrink");
        } else if (sv_derived_from(e, "Text::KnuthPlass::Box") ||
            (isPenalty(e) && ivHash(SvRV(e), "penalty") == -infinity
               && i > index)) {
               break;
        }
        i++;
    }

    hv_stores(result, "width", newSVnv(width));
    hv_stores(result, "stretch", newSVnv(stretch));
    hv_stores(result, "shrink", newSVnv(shrink));
    return result;
}

Breakpoint* _new_breakpoint (void) {
    Breakpoint* dummy;
    HV* totals = newHV();
    Newxz(dummy, 1, Breakpoint);
    dummy->prev = dummy->next = dummy->previous = dummy->active = NULL;
    dummy->demerits = dummy->ratio = 0;
    dummy->line = dummy->position = dummy->fitness_class = 0;
    hv_stores(totals, "width", newSVnv(0));
    hv_stores(totals, "stretch", newSVnv(0));
    hv_stores(totals, "shrink", newSVnv(0));
    dummy->totals = totals;
    return dummy;
}

void free_breakpoint(Breakpoint* b) {
    while (b) {
        Breakpoint* p = b->previous;
        if (SvROK(b->totals)) {
            sv_free((SV*)b->totals);
            Safefree(b);
        }
        b = p;
    }
    if (b && b->totals) sv_free((SV*)b->totals);
    if (b) Safefree(b);
}

void _unlinkKP(LinkedList* list, Breakpoint* a) {
    if (!a->prev) { list->head = a->next; } else { a->prev->next = a->next; }
    if (!a->next) { list->tail = a->prev; } else { a->next->prev = a->prev; }
    list->list_size--;
    av_push(list->to_free, newSViv((IV)a));
}

MODULE = Text::KnuthPlass		PACKAGE = Text::KnuthPlass		

void
_init_nodelist(self)
    Text_KnuthPlass self

    CODE:
    // overrides _init_nodelist() in Perl
    LinkedList* activelist;
    Newxz(activelist, 1, LinkedList);
    activelist->head = activelist->tail = _new_breakpoint();
    activelist->list_size = 1;
    activelist->to_free = newAV();
    hv_stores((HV*)self, "activeNodes", ((SV *)activelist));

void _active_to_breaks(self)
    Text_KnuthPlass self

    PREINIT:
    LinkedList* activelist;
    Breakpoint* b;
    Breakpoint* best = NULL;

    PPCODE:
    // overrides _active_to_breaks() in Perl
    activelist = (LinkedList*)(*hv_fetch((HV*)self, "activeNodes", 11, FALSE));

    for (b = activelist->head; b; b = b->next) {
        if (!best || b->demerits < best->demerits) best = b;
    }
    while (best) { 
        HV* posnode = newHV();
        hv_stores(posnode, "position", newSViv(best->position));
        hv_stores(posnode, "ratio", newSVnv(best->ratio));
        XPUSHs(sv_2mortal(newRV((SV*)posnode)));
        best = best->previous;
    }

void _cleanup(self)
    Text_KnuthPlass self

    CODE:
    // overrides _cleanup() in Perl (which is a dummy stub) 
    Breakpoint* b;
    LinkedList* activelist;
    activelist = (LinkedList*)(*hv_fetch((HV*)self, "activeNodes", 11, FALSE));
    return;
    /* Free nodes on the activelist */
    b = activelist->head;
    while (b) {
        Breakpoint* n = b->next;
        free_breakpoint(b);
        b = n;
    }
    /* Shut down the activelist itself */
    while (av_len(activelist->to_free)) {
        SV* pointer = av_shift(activelist->to_free);
        if ((Breakpoint*)SvIV(pointer))
            free_breakpoint((Breakpoint*)SvIV(pointer));
        sv_free(pointer);
    } 
    sv_free((SV*)activelist->to_free);
    // Safefree(activelist);

void
_mainloop(self, node, index, nodes)
    Text_KnuthPlass self
    SV* node
    IV index
    AV* nodes

    CODE:
    // overrides _mainloop() in Perl 
    LinkedList* activelist = (LinkedList*)(*hv_fetch((HV*)self, "activeNodes", 11, FALSE));
    IV  tolerance  = ivHash(self, "tolerance");
    IV  infinity   = ivHash(self, "infinity");
    SV* demerits_r = *hv_fetch((HV*)self, "demerits", 8, FALSE);
    NV  ratio = 0;
    IV  nodepenalty = 0;
    NV  demerits = 0;
    IV  linedemerits = 0, flaggeddemerits = 0, fitnessdemerits = 0;
    Breakpoint* candidates[4];
    NV  badness;
    IV  current_line = 0;
    HV* tmpsum;
    IV  current_class = 0;
    Breakpoint* active = activelist->head;
    Breakpoint* next;

    if (demerits_r && SvRV(demerits_r)) {
        linedemerits = ivHash(SvRV(demerits_r), "line");
        flaggeddemerits = ivHash(SvRV(demerits_r), "flagged");
        fitnessdemerits = ivHash(SvRV(demerits_r), "fitness");
    } else {
        croak("Demerits hash not properly set!");
    }

    if (isPenalty(node)) {
        nodepenalty = SvIV(*hv_fetch((HV*)SvRV(node), "penalty", 7, TRUE));
    }

    while (active) {
        int t;
        candidates[0] = NULL; candidates[1] = NULL; 
        candidates[2] = NULL; candidates[3] = NULL;
        debug(warn("Outer\n"));
        while (active) {

            next = active->next;
            IV position = active->position;

            debug(warn("Inner loop\n"));

            current_line = 1+ active->line;
/*warn("_mainloop, current_line=%i\n", current_line);*/
            ratio = _compute_cost(self, position, index, active, current_line, nodes);
            debug(warn("Got a ratio of %f\n", ratio));

            if (ratio < 1 || (isPenalty(node) && nodepenalty == -infinity)) {
                debug(warn("Dropping a node\n"));
                _unlinkKP(activelist, active);
            }

            if (-1 <= ratio && ratio <= tolerance) {
                SV* nodeAtPos = *av_fetch(nodes, position, FALSE); 
                badness = 100 * ratio * ratio * ratio;
                debug(warn("Badness is %f\n", badness));
                if (isPenalty(node) && nodepenalty > 0) {
                    demerits = linedemerits + badness + nodepenalty;
                } else if (isPenalty(node) && nodepenalty != -infinity) {
                    demerits = linedemerits + badness - nodepenalty;
                } else {
                    demerits = linedemerits + badness;
                }
                demerits = demerits * demerits;
                if (isPenalty(node) && isPenalty(SvRV(nodeAtPos))) {
                    demerits = demerits + (flaggeddemerits * 
                        ivHash(node, "flagged") * 
                        ivHash(SvRV(nodeAtPos), "flagged"));
                }

                if      (ratio < -0.5)  current_class = 0; // tight
                else if (ratio <= 0.5)  current_class = 1; // normal
                else if (ratio <= 1)    current_class = 2; // loose
                else                    current_class = 3; // very loose

                if (abs(current_class - active->fitness_class) > 1) 
                    demerits += fitnessdemerits;

                demerits += active->demerits;

                if (!candidates[current_class] ||
                    demerits < candidates[current_class]->demerits) {
                    debug(warn("Setting c %i\n", current_class));
                    if (!candidates[current_class])
                        candidates[current_class] = _new_breakpoint();
                    candidates[current_class]->active = active;
                    candidates[current_class]->demerits = demerits;
                    candidates[current_class]->ratio = ratio;
                }
            }
            active = next;
            if (!active || active->line >= current_line) 
                break;
        }
        debug(warn("Post inner loop\n"));


        for (t = 0; t <= 3; t++) {
            if (candidates[t]) {
                Breakpoint* newnode = _new_breakpoint();
                HV* tmpsum = _compute_sum(self, index, nodes);
                newnode->position = index;
                newnode->demerits = candidates[t]->demerits;
                newnode->ratio = candidates[t]->ratio;
                newnode->line = candidates[t]->active->line + 1;
                newnode->fitness_class = t;
                newnode->totals = tmpsum;
                debug(warn("Setting previous to %p\n", candidates[t]->active));
                newnode->previous = candidates[t]->active;
                if (active) {
                    debug(warn("Before\n"));
                    newnode->prev = active->prev;
                    newnode->next = active;
                    if (!active->prev) { activelist->head = newnode; }
                    else { active->prev->next = newnode; }
                    active->prev = newnode;
                    activelist->list_size++;
                } else {
                    debug(warn("After\n"));
                    if (!activelist->head) {
                        activelist->head = activelist->tail = newnode;
                        newnode->prev = newnode->next = NULL;
                    } else {
                        newnode->prev = activelist->tail;
                        newnode->next = NULL;
                        activelist->tail->next = newnode;
                        activelist->tail = newnode;
                        activelist->list_size++;
                    }
                }
                sv_free((SV*)candidates[t]->totals);
                Safefree(candidates[t]);
           } // demerits check (candidates[fitness class] > 0)
        } // fitness class (t) 0..3 loop
    } // while active loop

