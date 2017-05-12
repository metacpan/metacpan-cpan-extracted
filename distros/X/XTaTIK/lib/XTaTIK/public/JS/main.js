jQuery(function ($) {
    $.fn.sameHeight = function() {
        var max = 0;
        $(this).each(function(){
            var h = $(this).outerHeight();
            if ( h > max ) { max = h }
        });

        $(this).css('min-height', max + 'px')
    }

    fix_nav_padding_top();
    $( window ).resize(function() { fix_nav_padding_top(); });

    setup_feedback_button();
    setup_master_db_filter();

    var art = $('#index_shoutout [src$="shoutout-art.jpg"]');
    if ( art.length ) {
        art.css({'max-height': $(window).height() - art.offset().top - 20});
    }

    $(window).load(function(){
       setup_index_shoutout();
       setup_product_lists();
    });
});

function setup_master_db_filter() {
    if ( ! $('#master_db_update_form').length ) { return; }

    $('#filter').change(function(){
        var re;
        try { re = new RegExp($(this).val()) }
        catch (e) {
            alert('Regex error: ' + e);
        }

        $('#master_db_update_form [name^=number_]')
            .each(function() {
                if ( ! $(this).val().match(re) ) {
                    $(this).parents('li').eq(0).addClass('hidden')
                }
                else {
                    $(this).parents('li').eq(0).removeClass('hidden')
                }
            });
    })

    $('#master_db_update_form').submit(function(){
        $(this).find('.hidden').remove();
    });
}

function setup_product_lists() {
    var el = $('#product_list, #hot_products, #search_results');
    if ( ! el.length ) { return; }

    var thumb = el.find('.thumbnail');
    thumb.sameHeight();
    thumb.css({'line-height': thumb.eq(0).outerHeight() + 'px'});

    el.find('a[href^="/product/"]:not(.thumbnail)').sameHeight();
}

function setup_index_shoutout() {
    if ( ! $('#index_shoutout').length ) {
        $('.hot_products_container').css({opacity: 1});
        return;
    }

    var hot = $('.hot_products_container'),
        shout = $('#index_shoutout'),
        logo  = shout.find('[src$="logo.png"]'),
        art   = shout.find('[src$="shoutout-art.jpg"]'),
        tag   = shout.find('.market_tag');

    // The effect looks horrible on small screens
    if ( $(window).outerWidth() < 500 ) {
        logo.removeClass('art_hidden');
        art.addClass('art_hidden');
        shout.find('.col-sm-12').removeClass('col-sm-12')
            .addClass('col-xs-6');

        logo.css({'margin-top': $('#cart').outerHeight() + 'px'});
        tag.css({'font-size': '100%'});
        hot.css({opacity: 1});

        return;
    }

    hot.css({ opacity: 0 }).find('li').css({ opacity: 0 });
    shout.css({ opacity: 1 });

    if ( art.length ) { // animations for when we do have shoutout art
        var max_art_height = $(window).height()
            - art.offset().top - tag.outerHeight();

        if ( max_art_height > art.outerHeight() ) {
            max_art_height = art.outerHeight();
        }


        setTimeout(function(){
            var end_height = logo.outerHeight();
            if ( end_height > 250 ) { end_height = 250 }
            art.animate({
                height: $(window).height()/3
            }, 500, function(){
                tag.css({transform: 'scale(1.2)'});
                setTimeout(function(){
                    shout.css({ opacity: 0 });
                    logo.css({height: 'auto'});
                    logo.removeClass('art_hidden');
                    art.addClass('art_hidden');
                    shout.find('.col-xs-12').removeClass('col-xs-12')
                        .addClass('col-xs-6');

                    tag.css({
                        'font-size': '200%',
                        transition: 'transform 0s',
                        transform: 'scale(1)'
                    });

                    // Center market tag vertically
                    tag.css({'margin-top': 0});

                    var logo_height = logo.outerHeight(true);

                    // See if we have room to scale up market tag
                    if ( tag.outerHeight(true) < (logo_height/2) ) {
                        tag.css({'font-size': '230%'})
                    }

                    var tag_height = tag.outerHeight(true)
                        + $('#cart').outerHeight(true);

                    // alert(end_height + '  ' + tag_height );
                    if ( logo_height > tag_height ) {
                        // logo is larger than tag
                        tag.css({
                            'padding-top': ((logo_height-tag_height)/2) + 'px'
                        });
                    }
                    else {
                        // tag is larger than logo or same
                        logo.css({
                            'margin-top': ((tag_height-logo_height)/2
                                + 14 // no idea where this value comes from
                            ) + 'px'
                        });
                    }

                    $('#index_shoutout').animate({opacity: 1}, 500, function(){
                        hot.animate({opacity: 1}, 300, function() {
                            $(this).find('li').each(function(i, el) {
                                setTimeout( function() {
                                    $(el).animate({opacity: 1});
                                }, 200*i );
                            });
                        });
                    });
                }, 3000);
            });
        }, 1000);
    }
    else { // logo animations when we do not have art
        setTimeout(function(){
            var end_height = logo.outerHeight();
            if ( end_height > 250 ) { end_height = 250 }

            logo.animate({
                height: end_height
            }, 500, function(){
                tag.css({transform: 'scale(1.2)'});
                setTimeout(function(){
                    shout.css({ opacity: 0 });
                    logo.css({
                        height: 'auto',
                        'max-height': end_height
                    });
                    shout.find('.col-xs-12').removeClass('col-xs-12')
                        .addClass('col-xs-6');

                    tag.css({
                        'font-size': '200%',
                        transition: 'transform 0s',
                        transform: 'scale(1)'
                    });

                    // Center market tag vertically
                    tag.css({'margin-top': 0});

                    var logo_height = logo.outerHeight(true);

                    // See if we have room to scale up market tag
                    if ( tag.outerHeight(true) < (logo_height/2) ) {
                        tag.css({'font-size': '230%'})
                    }

                    var tag_height = tag.outerHeight(true)
                        + $('#cart').outerHeight(true);

                    // alert(end_height + '  ' + tag_height );
                    if ( logo_height > tag_height ) {
                        // logo is larger than tag
                        tag.css({
                            'padding-top': ((logo_height-tag_height)/2) + 'px'
                        });
                    }
                    else {
                        // tag is larger than logo or same
                        logo.css({
                            'margin-top': ((tag_height-logo_height)/2
                                + 14 // no idea where this value comes from
                            ) + 'px'
                        });
                    }

                    $('#index_shoutout').animate({opacity: 1}, 500, function(){
                        hot.animate({opacity: 1}, 300, function() {
                            $(this).find('li').each(function(i, el) {
                                setTimeout( function() {
                                    $(el).animate({opacity: 1});
                                }, 200*i );
                            });
                        });
                    });
                }, 3000);
            });
        }, 700);
    }
}

function fix_nav_padding_top() {
    $('body').css('padding-top',
        ($('.navbar-fixed-top').outerHeight()) + 'px'
    );
}

function setup_feedback_button() {
    if ( $('form[action="/feedback"]').length )  {
        $('#feedback_b').remove();
        return;
    }

    var width = $('#feedback_b span').outerWidth();
    $('#feedback_b span')
        .css({ position: 'static', width: 0, 'padding-left': 0});

    $('#feedback_b')
        .hover(function() {
            $(this).find('span')
                .stop(true, false)
                .animate({
                    width: width + 'px',
                    'padding-left': '10px'
                }, 400);
        }, function() {
            $(this).find('span')
                .stop(true, false)
                .animate({
                    width: 0,
                    'padding-left': 0
                }, 400);
        });
}