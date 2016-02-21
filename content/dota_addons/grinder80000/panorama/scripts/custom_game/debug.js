(function() {
    var $debug = $('#debug');

    GameEvents.Subscribe('on_debug_message', function(data) {
        var content = '';
        Object.keys(data).forEach(function(key) {
            var item = data[key];
            if (Object.keys(item).length == 2) {
                content += item['1'] + ': ' + item['2'] + '\n';
            } else {
                content += item['1'] + '\n';
            }
        });
        $debug.text = content;
    });
})();
