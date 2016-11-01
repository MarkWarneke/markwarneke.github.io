$(document).ready(function() {
    // Default section
    var def = '#home';

    $('section').hide();
    toggleHash(getHash());

    $(window).on('hashchange', function() {
        $('section').hide();
        toggleHash(getHash());
    });

    function getHash() {
        var hash = window.location.hash.substring(1); // hash part of url withou the first letter (#)
        console.log(hash);
        return hash;
    };

    function toggleHash(hash) {
        if(isElement(hash)) {
            showSection(hash);
        } else {
            showDef();
        }
    }

    function showSection(hash) {
        console.log('Show', hash);
        $('#' + hash).show();
    }

    function isElement(hash) {       
        if(hash === '') return false; 
        return $('#' + hash).length;
    }

    function showDef() {
        console.log('Show', def);
        return $(def).show();
    }
});

$(window).on('load', function() {

    $('#work').poptrox({
        caption: function($a) { return $a.next('h3').text(); },
        overlayColor: '#2c2c2c',
        overlayOpacity: 0.85,
        popupCloserText: '',
        popupLoaderText: '',
        selector: '.ref-item a.image',
        usePopupCaption: true,
        usePopupDefaultStyling: false,
        usePopupEasyClose: false,
        usePopupNav: true
    });
});
