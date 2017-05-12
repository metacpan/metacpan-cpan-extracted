function slide_index(thing) {
    if (!thing) return 0;

    var i = 0;
    $('.slide').each(function() { if (this == thing) return false; i++ });
    return i;
}

function show_some_slide(slide, effect, delay) {
    $(slide)
        .removeClass('upcoming')
        .removeClass('erstwhile')
        .addClass('current');

    if (effect) {
        if (!delay) { delay = 500; }
        $(slide).show(effect, {}, delay);
    }
    else {
        $(slide).show();
    }

    vertical_center();

    if ($(slide).attr('id')) {
        window.location.hash = '#' + $(slide).attr('id');
    }
}

function jump_to_slide(slide) {
    var current_idx = slide_index($('.slide.current')[0]);
    var goto_idx    = slide_index(slide);

    // Are we jumping ahead?
    if (goto_idx > current_idx) {
        var state = current_idx == 0 ? 'jumping' : 'searching';
        $('.slide').each(function() {
            if (state == 'searching' && $(this).hasClass('current')) {
                $(this).removeClass('current').hide();
                state = 'jumping';
            }

            if (state == 'jumping' && this == slide) {
                show_some_slide(this);
                // $(this).removeClass('upcoming').addClass('current').show();
                // vertical_center();
                return false;
            }

            if (state == 'jumping') {
                $(this).removeClass('upcoming').addClass('erstwhile');
            }
        });
    }

    // Are we jumping back?
    else if (goto_idx < current_idx) {
        var state = 'searching';

        $('.slide').each(function() {
            if (state == 'searching' && this == slide) {
                state = 'jumping';
                return true;
            }

            if (state == 'jumping' && $(this).hasClass('current')) {
                $(this).removeClass('current').hide();
                show_some_slide(slide);
                // $(slide).removeClass('erstwhile').addClass('current').show();
                // vertical_center();
                return false;
            }

            if (state == 'jumping') {
                $(this).removeClass('erstwhile').addClass('upcoming');
            }
        });
    }
}

function show_next_slide(slide) {
    $('.slide.current').not('.final').removeClass('current').addClass('erstwhile').fadeOut(800);
    $('.highlight').removeClass('current');
    show_some_slide(slide, 'fade', 800);
    // slide.removeClass('upcoming').addClass('current').fadeIn(800);
    // vertical_center();
}

function show_next_build(build) {
    $('.build-in,.highlight').removeClass('current').addClass('erstwhile');
    build.removeClass('upcoming').addClass('current');

    if (build.is('.build-in')) {
        build.show('drop', 300);
        vertical_center();
    }

    else if (build.is('.highlight')) {
        build.effect('highlight', { color: '#339933' }, 800);
    }
}

function show_next() {
    var current_slide = $('.slide.current');

    if (current_slide.find('.highlight.upcoming,.build-in.upcoming').length > 0) {
        show_next_build( $(current_slide.find('.highlight.upcoming,.build-in.upcoming')[0]) );
        return;
    }

    show_next_slide( $('.slide.upcoming:first') );
}

function show_previous_slide(slide) {
    $('.slide.current').removeClass('current').addClass('upcoming').fadeOut(200);
    show_some_slide(slide, 'fade', 200);
    // slide.removeClass('erstwhile').addClass('current').fadeIn(200);
}

function show_previous() {
    var current_slide = $('.slide.current');
    show_previous_slide( $('.slide.erstwhile:last') );
    vertical_center();
}

function vertical_center() {
//    $('.vcentered').position({
//        at: 'center',
//        my: 'center',
//        of: 'body'
//    });
}

function start_slides() {
    vertical_center();
    $('.slide, .build-in').hide().addClass('upcoming');
    $('.highlight').addClass('upcoming');

    if (window.sh_highlightDocuent) window.sh_highlightDocument();

    if ($('.here.slide').length > 0) {
        jump_to_slide( $('.here.slide')[0] );
    }

    if (window.location.hash) {
        jump_to_slide( $(window.location.hash)[0] );
    }

    $(document).keyup(function(evt) {
        var k = (evt.keyCode ? evt.keyCode : evt.which);

        // 32 = Space
        // 106 = ???
        // 39 = right arrow
        // 40 = down arrow
        // 74 = j
        if (k == 32 || k == 106 || k == 39 || k == 40 || k == 74) {
            show_next();
            evt.preventDefault();
            return false;
        }

        // 107 = ???
        // 37 = left arrow
        // 38 = up arrow
        // 8 = backspace
        // 75 = k
        else if (k == 107 || k == 37 || k == 38 || k == 8 || k == 75) {
            show_previous();
            evt.preventDefault();
            return false;
        }
    });

//    show_next();
}

$(start_slides);
