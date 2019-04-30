
// --------------------- Variables --------------------------
// Default values for image names of the images/text to expand and collapse the hidden text.
// ----------------------------------------------------------
var expandImage = "expand.gif"; 
var collapseImage = "collapse.gif"; 
var defaultExpandText = "Show More...";
var defaultCollapseText = "Show Less....";

// ---------------- setDefaultExpanderImages(...) ------------------
// Call this method to change the names of the images used for the "expand" and "collapse" buttons
// The parameters should be the actual image URLS for the images, which may be relative or absolute
// ----------------------------------------------------------
function setDefaultExpanderImages(expandImgName, collapseImgName) {
    expandImage = expandImgName;
		collapseImage = collapseImgName;
}

// ---------------- setDefaultExpanderText(...) ------------------
// Call this method to change the strings used for the "expand" and "collapse" links
// expandText = "Expand" or "Show More" or "Reveal Answer" etc.
// collapseText = "Hide" or "Show Less" or "Hide Answer" etc.
// ----------------------------------------------------------
function setDefaultExpanderText(expandText, collapseText) {
    defaultExpandText = expandText;
		defaultCollapseText = collapseText;
}

// ------------------- toggleBlock(...) ---------------------
// Method to Collapse/Expand a block of text, using default image names
// hiddenDivId - the ID of div or span to show/hide
// expander - pass in a reference to the image tag for the expender
//     usually this will just be "this" (without any quotes)
// ----------------------------------------------------------
//function toggleBlockImage (hiddenDivId, expander) {
//	alert(collapseImage);
//		toggleBlockImage(hiddenDivId, expander, expandImage, collapseImage);
//}

// ------------------- toggleBlockImage(...) ---------------------
// Method to Collapse/Expand a block of text, using custom image names
// hiddenDivId - the ID of div or span to show/hide
// expander - pass in a reference to the image tag for the expender
//     usually this will just be "this" (without any quotes)
// expandImageName & collapseImageName are optional parameters
// ----------------------------------------------------------
function toggleBlockImage (hiddenDivId, expander, expandImageName, collapseImageName) {
    if (document.getElementById) {
        if (document.getElementById(hiddenDivId).style.display == "none") {
            document.getElementById(hiddenDivId).style.display = "";
						expander.src = (collapseImageName)?collapseImageName:collapseImage;
        } else {
            document.getElementById(hiddenDivId).style.display = "none";
            expander.src = (expandImageName)?expandImageName:expandImage;
        } 
    }
}


// ----------------- toggleBlockText(...) -------------------
// Method to show or hide a paragraph or other block or span of text. 
// Use this version for text links to show/hide, and custom link text
// Parameters:
// hiddenDivId - the ID attribute of div to show or hide
// expander - pass in a reference to the image tag for the expender
//     usually this will just be "this" (without any quotes)
// expandText - the text to show when the block of text is hidden (to show the text) OPTIONAL
// collapseText - the text to show when the block of text is showing (to hide the text) OPTIONAL
// ----------------------------------------------------------
function toggleBlockText (hiddenDivId, expander, expandText, collapseText) {
    if (document.getElementById) {
        if (document.getElementById(hiddenDivId).style.display == "none") {
            document.getElementById(hiddenDivId).style.display = "";
						expander.innerHTML = collapseText?collapseText:defaultCollapseText;
        } else {
            document.getElementById(hiddenDivId).style.display = "none";
						expander.innerHTML = expandText?expandText:defaultExpandText;
        }  
    }
}

// ----------------------------------------------------------
// another different way to toggle how much is shown...scrollbars
// collapseHeight - eg: "200px"
// ----------------------------------------------------------
function toggleOverflowImage (hiddenDivId, expander, expandImageName, collapseImageName, collapseHeight) {
    if (document.getElementById) {
        if (document.getElementById(hiddenDivId).style.overflow == "scroll") {
            document.getElementById(hiddenDivId).style.overflow = "auto";
						document.getElementById(hiddenDivId).style.height = "";
						expander.src = (collapseImageName)?collapseImageName:collapseImage;
				} else {
            document.getElementById(hiddenDivId).style.overflow = "scroll";
						document.getElementById(hiddenDivId).style.height = collapseHeight;
            expander.src = (expandImageName)?expandImageName:expandImage;
				}  
    }
}

// ----------------------------------------------------------
// another different way to toggle how much is shown...scrollbars
// collapseHeight - eg: "200px"
// ----------------------------------------------------------
function toggleOverflowText (hiddenDivId, expander, expandText, collapseText, collapseHeight) {
    if (document.getElementById) {
        if (document.getElementById(hiddenDivId).style.overflow == "scroll") {
            document.getElementById(hiddenDivId).style.overflow = "auto";
						document.getElementById(hiddenDivId).style.height = "";
					  expander.innerHTML = collapseText?collapseText:defaultHideText;
				} else {
            document.getElementById(hiddenDivId).style.overflow = "scroll";
						document.getElementById(hiddenDivId).style.height = collapseHeight;
						expander.innerHTML = expandText?expandText:defaultExpandText;
				}  
    }
}