###

Regex Builder

Sep 2013 ys

###


$exp = $('#exp')
$cur_exp = $('#cur_exp')
$txt = $('#txt')
$match = $('#match')
$flag = $('#flag')

delay = null

init = ->
	# Local storage.
	load_data()
	$(window).on('beforeunload', save_data)

	# After data loaded, run once.
	run_match()

	init_events()

	# Focus on the expression input.
	setTimeout(
		-> $exp.select()
		500
	)

init_events = ->
	# Edit change
	$txt.keydown(override_return)
	$txt.keyup(delay_run_match)
	$exp.keyup(delay_run_match)
	$flag.keyup(delay_run_match)

	# Init tooltips.
	$('[title]').tooltip()

	$cur_exp.click(select_all_text)

	delay = $('#exe_delay').change(->
		delay = $(this).val()
	).val()

	$('.switch_hide').click(->
		$this = $(this)
		$tar = $('#' + $this.attr('target'))

		if $this.prop('checked')
			$tar.hide()
		else
			$tar.show()
	)

delay_id = null
delay_run_match = ->
	elem = this
	clearTimeout(delay_id)
	delay_id = setTimeout(
		->
			if elem.id == 'txt'
				saved_sel = saveSelection(elem)

			run_match()

			if elem.id == 'txt'
				restoreSelection(elem, saved_sel)
		delay
	)

# Generate tag for highlighting in turns.
anchor_c = 0
anchor = (index) ->
	c = anchor_c++ % 4
	switch c
		when 0
			"<i index='#{index}'>"
		when 1
			"</i>"
		when 2
			"<b index='#{index}'>"
		when 3
			"</b>"

# Escape html.
entityMap = {
	"&": "&amp;"
	"<": "&lt;"
	">": "&gt;"
}
escape_exp = /[&<>]/g
escape_html = (str) ->
	return String(str).replace(
		escape_exp,
		(s) ->
			return entityMap[s]
	)

select_all_text = ->
	if document.selection
		range = document.body.createTextRange()
		range.moveToElementText(this)
		range.select()
	else if window.getSelection
		range = document.createRange()
		range.selectNode(this)
		window.getSelection().addRange(range)

override_return = (e) ->
	if e.keyCode == 13
		document.execCommand('insertHTML', false, '\n')
		return false

run_match = ->
	exp = $exp.val()
	flag = $flag.val()
	txt = $txt.text()

	if not exp
		$match.text('')
		$cur_exp.html('')
		return

	try
		r = new RegExp(exp, flag)
	catch e
		$match.text(e)
		return

	# Auto format the expression and syntax highlight it.
	cur_exp = r.source
	cur_exp = cur_exp.replace(/\\\//g, '/').replace(/\//g, '\\/')
	cur_exp = RegexColorizer.colorizeText(cur_exp)
	$cur_exp.html('/' + cur_exp + '/' + flag)

	# Store the match groups
	ms = []

	# Highlighting match words.
	visual = ''
	count = 0
	if r.global
		i = 0
		while (m = r.exec(txt)) != null
			ms.push m[0]
			k = r.lastIndex
			j = k - m[0].length
			# Escaping is important.
			visual += escape_html(txt.slice(i, j)) + anchor(count++)
			visual += txt.slice(j, k) + anchor()
			i = k

			# Empty match will also increase the counter.
			if m[0].length == 0
				r.lastIndex++
		visual += escape_html(txt.slice(i))
	else
		visual = txt.replace(r, (m) ->
			ms.push m
			m = anchor(count) + m + anchor()
		)

	$txt.empty().html(visual)

	$txt.find('[index]').hover(
		match_elem_show_tip
		->
			$(this).popover('destroy')
	)

	# Show the match object as json string.
	list = create_match_list(ms)
	json = JSON.stringify(ms)
	list += "<pre>#{json}</pre>"
	$match.html(list)

create_match_list = (m) ->
	list = '<ol start="0">'
	if m
		for i in m
			list += "<li>#{i}</li>"
	list += '</ol>'
	list

match_elem_show_tip = ->
	$this = $(this)

	index = $this.attr('index')

	# Create match list.
	reg = new RegExp($exp.val(), $flag.val().replace('g', ''))
	m = $this.text().match(reg)

	$this.popover({
		html: true
		title: 'Group: ' + index
		content: create_match_list(m)
		placement: 'bottom'
	}).popover('show')

save_data = ->
	$('[save]').each(->
		$this = $(this)
		localStorage.setItem(
			$this.attr('id'),
			$this.val()
		)
	)
	return null

load_data = ->
	# Load data.
	$('[save]').each(->
		$this = $(this)
		v = localStorage.getItem(
			$this.attr('id')
		)
		if v != null
			$this.val(v)

	)

`
if (window.getSelection && document.createRange) {
    saveSelection = function(containerEl) {
        var range = window.getSelection().getRangeAt(0);
        var preSelectionRange = range.cloneRange();
        preSelectionRange.selectNodeContents(containerEl);
        preSelectionRange.setEnd(range.startContainer, range.startOffset);
        var start = preSelectionRange.toString().length;

        return {
            start: start,
            end: start + range.toString().length
        }
    };

    restoreSelection = function(containerEl, savedSel) {
    	if (!savedSel) return;
        var charIndex = 0, range = document.createRange();
        range.setStart(containerEl, 0);
        range.collapse(true);
        var nodeStack = [containerEl], node, foundStart = false, stop = false;

        while (!stop && (node = nodeStack.pop())) {
            if (node.nodeType == 3) {
                var nextCharIndex = charIndex + node.length;
                if (!foundStart && savedSel.start >= charIndex && savedSel.start <= nextCharIndex) {
                    range.setStart(node, savedSel.start - charIndex);
                    foundStart = true;
                }
                if (foundStart && savedSel.end >= charIndex && savedSel.end <= nextCharIndex) {
                    range.setEnd(node, savedSel.end - charIndex);
                    stop = true;
                }
                charIndex = nextCharIndex;
            } else {
                var i = node.childNodes.length;
                while (i--) {
                    nodeStack.push(node.childNodes[i]);
                }
            }
        }

        var sel = window.getSelection();
        sel.removeAllRanges();
        sel.addRange(range);
    }
} else if (document.selection && document.body.createTextRange) {
    saveSelection = function(containerEl) {
        var selectedTextRange = document.selection.createRange();
        var preSelectionTextRange = document.body.createTextRange();
        preSelectionTextRange.moveToElementText(containerEl);
        preSelectionTextRange.setEndPoint("EndToStart", selectedTextRange);
        var start = preSelectionTextRange.text.length;

        return {
            start: start,
            end: start + selectedTextRange.text.length
        }
    };

    restoreSelection = function(containerEl, savedSel) {
        var textRange = document.body.createTextRange();
        textRange.moveToElementText(containerEl);
        textRange.collapse(true);
        textRange.moveEnd("character", savedSel.end);
        textRange.moveStart("character", savedSel.start);
        textRange.select();
    };
}
`

init()
