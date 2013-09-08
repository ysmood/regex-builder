###

Regex Builder

Sep 2013 ys

###


$exp = $('#exp')
$exp_dsp = $('#exp_dsp')
$txt = $('#txt')
$match = $('#match')
$flags = $('#flags')

init = ->
	# Local storage.
	load_data()
	$(window).on('beforeunload', save_data)

	# After data loaded, run once.
	run_match()

	init_key_events()
	init_bind()

	# Init tooltips.
	$('[title]').tooltip()

	# Focus on the expression input.
	setTimeout(
		-> $exp.select()
		500
	)

	init_affix()

	init_hide_switches()

init_key_events = ->
	# Edit change
	$txt.keydown(override_return)
	$exp.keydown(override_return)

	$txt.keyup(delay_run_match)
	$exp.keyup(delay_run_match)

	$flags.keyup(delay_run_match)

	$exp_dsp.click(select_all_text)

init_affix = ->
	h = $('.brand').outerHeight()
	$ag = $('.affix-group')
	$ap = $('.affix-placeholder')
	$(window).scroll(->
		t = $(this).scrollTop()
		if t >= h
			$ag.addClass('affix')
			$ap.height($ag.outerHeight())
		else
			$ag.removeClass('affix')
			$ap.height(0)
	)

init_bind = ->
	$('[bind]').each(->
		$this = $(this)
		window[$this.attr('bind')] = $this.val()

		$this.change(->
			window[$this.attr('bind')] = $this.val()
		)
	)

init_hide_switches = ->
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
			if elem.id == 'txt' or elem.id == 'exp'
				saved_sel = saveSelection(elem)

			run_match()

			if elem.id == 'txt' or elem.id == 'exp'
				restoreSelection(elem, saved_sel)
		window.exe_delay
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
	# Clear other tags.
	$txt.find('div').remove()

	exp = $exp.text()
	txt = $txt.text()
	flags = $flags.val()

	if not exp
		input_clear()
		return

	try
		r = new RegExp(exp, flags)
	catch e
		input_clear(e)
		return

	syntax_highlight(exp, flags)

	# Store the match groups
	ms = []

	is_txt_shown = $txt.is(":visible")
	is_match_shown = $match.is(":visible")

	# Highlighting match words.
	visual = ''
	count = 0
	if r.global
		i = 0
		while (m = r.exec(txt)) != null
			ms.push m[0]
			k = r.lastIndex
			j = k - m[0].length

			if is_txt_shown
				visual += match_visual(txt, i, j, k, count++)

			i = k

			# Empty match will also increase the counter.
			if m[0].length == 0
				r.lastIndex++
	else
		txt.replace(r, (m) ->
			for i in [0 ... arguments.length - 2]
				ms.push arguments[i]

			i = 0
			j = arguments[arguments.length - 2]
			k = j + m.length

			if is_txt_shown
				visual += match_visual(txt, i, j, k, count++)

			i = k
		)

	if is_txt_shown
		visual += escape_html(txt.slice(i))

		$txt.empty().html(visual)

		$txt.find('[index]').hover(
			match_elem_show_tip
			->
				$(this).popover('destroy')
		)

	# Show the match object as json string.
	if is_match_shown
		list = create_match_list(ms)
		$match.html(list)

match_visual = (str, i, j, k, c) ->
	# Escaping is important.
	escape_html(str.slice(i, j)) +
	anchor(c) +
	escape_html(str.slice(j, k)) +
	anchor()

input_clear = (err) ->
	if err
		msg = err.message.replace('Invalid regular expression: ', '')
		$exp_dsp.html("<span class='error'>#{msg}</span>")
	else
		$exp_dsp.text('')

	$match.text('')
	$txt.text($txt.text())

syntax_highlight = (exp, flags) ->
	exp_escaped = exp.replace(/\\\//g, '/').replace(/\//g, '\\/')
	$exp_dsp.text("/#{exp_escaped}/#{flags}")

	exp = RegexColorizer.colorizeText(exp)
	$exp.html(exp)

create_match_list = (m) ->
	list = '<ol start="0">'
	if m
		for i in m
			es = escape_html(i)
			list += "<li><span class='g'>#{es}</span></li>"
	list += '</ol>'
	list

match_elem_show_tip = ->
	$this = $(this)

	index = $this.attr('index')

	# Create match list.
	reg = new RegExp($exp.text(), $flags.val().replace('g', ''))
	m = $this.text().match(reg)

	$this.popover({
		html: true
		title: 'Group: ' + index
		content: create_match_list(m)
		placement: 'bottom'
	}).popover('show')

save_data = (e) ->
	$('[save]').each(->
		$this = $(this)
		$this.find('.popover').remove()
		val = $this[$this.attr('save')]()

		localStorage.setItem(
			$this.attr('id'),
			val
		)
	)
	e.preventDefault()

load_data = ->
	# Load data.
	$('[save]').each(->
		$this = $(this)
		v = localStorage.getItem(
			$this.attr('id')
		)
		if v != null
			$this[$this.attr('save')](v)

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
