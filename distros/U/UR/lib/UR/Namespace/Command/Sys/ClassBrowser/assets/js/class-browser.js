$(document).ready(function() {

    var detail = $('#detail');

    // Called when the user clicks a class name in the treeview on the left
    function classInfoForClassName(e) {
        var $elt = $(e.currentTarget);

        e.preventDefault();
        detail.load( $elt.prop('href'), function() {
            $(this).find('table').sortableTable();
        });
    };

    // Called when the checkbox is changed for show/hide inherited class properties
    function showHideClassProperties(e) {
        var $elt = $(e.target),
            inh_rows = detail.find('table.class-properties tr.inherited');

        if ($elt.prop('checked')) {
            inh_rows.show();
        } else {
            inh_rows.hide();
        }
    };

    // Use the 'href' property of the clicked thing to get content
    // and show it in a modal dialog box
    function showModal(e) {
        var $elt = $(e.currentTarget);

        e.preventDefault();

        if ($('.modal').length) {
            return;  // Open only 1 modal at a time
        }
        $.get($elt.prop('href'),
            function(html) {
                var modal = $(html);
                modal.modal({ show: true, keyboard: true })
                        .appendTo(detail)
                        .focus()
                        .on('hidden', function() {
                            modal.remove();
                        });
            });
    };

    function titleBarFormSubmitted(e) {

        var $submit = $(e.currentTarget),
            which = $submit.val(),
            $form = $submit.closest('form');

        if (which === 'Namespace') {
            // Let the form submit normally

        } else if (which === 'Search') {
        e.preventDefault();
            var textinput = $form.find('input.search-query');
            detail.load('/search-for-class/' + textinput.val());
            textinput.val('');
        }
    };



    $('body').on('click', 'a.class-detail', classInfoForClassName);
    detail.on('change', '[name="show-properties"]', showHideClassProperties);
    detail.on('click', '.modal-link', showModal);
    $('#nav-form input[type="submit"]').click(titleBarFormSubmitted);
});
