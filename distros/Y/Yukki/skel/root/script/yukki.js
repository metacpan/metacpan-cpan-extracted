;(function(){

// TODO Naive
function rebase_url(url) {
    return yukki_base_url + url;
}

var templates = {};
function fetch_template(name, code) {
    
    // Keep a cache of templates already loaded
    if (templates[name]) {
        code(templates[name]);
    }

    // Load a new template if not already cached
    else {
        $.get(rebase_url('template/' + name), function(data) {
            templates[name] = data;
            code(data);
        });
    }
}

setInterval(function() { $(window).trigger('every_10s'); }, 10000);

function updatePosition() {
    if ($('textarea#yukkitext').length > 0) {
        $('#yukkitext_position').val(
            $('textarea#yukkitext').getSelection().end
        );
    }
}

$(document).ready(function() {
    $(':button,.button').button();

    $('#preview-yukkitext').scrollTop('#yukkitext-caret');

    $('every_10s', updatePosition);
    $('form.edit-page').submit(updatePosition);

    if ($('#preview-yukkitext').length > 0) {
        $(window).bind('every_10s', function() {
            var url = String(window.location).replace(/\/edit\//, '/preview/');
            $.post(url, { 
                    'yukkitext'          : $('#yukkitext').val(),
                    'yukkitext_position' : $('#yukkitext').getSelection().end
                }, 
                function(data) {
                    $('#preview-yukkitext').html(data);
                    setTimeout(function() {
                        try {
                            var offset = ($('#yukkitext-caret').offset().top
                                       + $('#preview-yukkitext').scrollTop())
                                       - $('#preview-yukkitext').offset().top
                                       - 100;

                            if (offset < 0) offset = 0;

                            $('#preview-yukkitext').scrollTop(offset);
                        }
                        catch(e) {}
                    }, 10);
                }
            );
        });
    }

    function show_hide_revision_checkbox(rx, object_id) {
        $('input[name="' + rx + '"][value!="' + object_id + '"]').fadeIn();
        $('input[name="' + rx + '"][value="' + object_id + '"]').fadeOut();
    };

    show_hide_revision_checkbox('r2', $('input[name="r1"]:checked').val());
    show_hide_revision_checkbox('r1', $('input[name="r2"]:checked').val());

    $('input[name="r1"]').live('click', function() { show_hide_revision_checkbox('r2', $(this).val()) });
    $('input[name="r2"]').live('click', function() { show_hide_revision_checkbox('r1', $(this).val()) });

    $('.attachments').each(function() {
        var $this = $(this);

        var $picker    = $this.find('.attachment-picker');
        var $file_list = $this.find('.attachment-list');
        var $drop_zone = $this.find('.attachment-dropzone');
        var $starter   = $this.find('.attachment-start');
            
        var uploader = new plupload.Uploader({
            'runtimes'            : 'gears,html5,flash,silverlight,html4',
            'browse_button'       : $picker[0].id,
            'container'           : $file_list[0].id,
            'drop_element'        : $drop_zone[0].id,
            'url'                 : String(window.location).replace(/\/edit\//, '/attach/'),
            'flash_swf_url'       : rebase_url('script/lib/plupload/plupload.flash.swf'),
            'silverlight_xap_url' : rebase_url('script/lib/plupload/plupload.silverlight.xap')
        });

        $starter.click(function(e) {
            uploader.start();
            e.preventDefault();
        });

        $(window).bind('every_10s', function() { uploader.start(); });

        var file_id_memo = {};
        function file_id(file) {
            if (file_id_memo[file.name]) {
                return file_id_memo[file.name];
            }
            else {
                return file_id_memo[file.name] = Sha1.hash(file.name);
            }
        }

        uploader.bind('FilesAdded', function(up, files) {
            fetch_template('page/attachments.html', function(attachments_template) {
                var was_empty = false;
                if ($file_list.is('.empty')) {
                    $file_list.removeClass('empty').empty().append(attachments_template);
                    was_empty = true;
                }

                $.each(files, function(i, file) {
                    var new_row = $file_list.find('.attachment-table #' + file_id(file));
                    var cloned = false;
                    if (new_row.length == 0) {
                        new_row = $file_list.find('.attachment-table .file:first').clone();
                        cloned = true;
                    }

                    new_row.attr('id', file_id(file));
                    new_row.find('.filename').text(file.name);
                    new_row.find('.size').text(plupload.formatSize(file.size));
                    new_row.find('.action').html('<div class="progress"></div>');

                    if (cloned) {
                        $file_list.find('tbody').append(new_row);
                    }

                    $file_list.find('#' + file_id(file) + ' .progress').progressbar({ 'value': 0 });
                });

                if (was_empty) {
                    $file_list.find('.attachment-table .file:first').remove();
                }

                up.refresh();
                $starter.show();
            });
        });

        uploader.bind('UploadProgress', function(up, file) {
            $('#' + file_id(file) + ' .progress').progressbar({ 'value': file.percent });
        });

        uploader.bind('FileUploaded', function(up, file, res) {
            var json = eval('('+res.response+')');

            $('#' + file_id(file) + ' .action').empty().append('<ul class="links"></ul>');
            if (json.viewable) {
                $('#' + file_id(file) + ' .links').append(
                    '<li><a href="' + rebase_url('attachment/view/' + json.repository_path) + '">View</a></li>'
                );
            }

            $('#' + file_id(file) + ' .links').append(
                '<li><a href="' + rebase_url('attachment/download/' + json.repository_path) + '">Download</a></li>'
            );

            $('#' + file_id(file) + ' .links').append(
                '<li><a href="' + rebase_url('attachment/rename/' + json.repository_path) + '">Rename</a></li>'
            );

            $starter.hide();
        });

        uploader.bind('Init', function(up, params) {
            if (up.features.dragdrop) {
                $drop_zone.show();
                $picker.hide();
                $starter.hide();
            }
        });

        uploader.init();

    });
});
})();
