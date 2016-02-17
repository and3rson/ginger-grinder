(function() {
    'use strict';

    var $$ = function(what) {
        return new Selector(what);
    };

    var Selector = function(what) {
//        Panorama;
//        if
    };

    $$.prototype = {};

    $$.prototype.test = function() {
        $.Msg('Test');
    };

    [1, 2, 3].forEach(function(v, k) {
        $.Msg(k + ': ' + v);
    });

//    $.Msg($.GetContextPanel());

    $.$$ = $$;
})();
