//checks of unchecks all checkbox available in the form
// this will enable/disable test for the DTS packages listed

var allChecked = false;

function checkAll() {

    if (allChecked) {

        uncheckAll();

        document.selectPackages.all.checked = false;

    } else {

        var form = document.selectPackages;

        for (var i = 0; i < form.elements.length; i++) {

            if (form.elements[i].type == "checkbox") {

                form.elements[i].checked = true;

            }

        }

		allChecked = true;

    }

}

function uncheckAll() {

    var form = document.selectPackages;

    for (var i = 0; i < form.elements.length; i++) {

        if (form.elements[i].type == "checkbox") {

            if ( !( form.elements[i].name == "all" ) ) {

                form.elements[i].checked = false;

            }


        }

    }

		allChecked = false;

}
