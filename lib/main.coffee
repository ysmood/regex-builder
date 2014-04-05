###

Regex Builder

Sep 2013 ys

###

$window = $(window)
$exp = $('#exp')
$exp_dsp = $('#exp_dsp')
$txt = $('#txt')
$match = $('#match')
$flags = $('#flags')

# To fix the bug of XRegExp.
# The match object contains some extra properties that
# may be overwrite by the by the group name.
exp_escape_list = ['index', 'input', 'lastIndex']

init = ->
	# Local storage.
	load_data()
	$window.on('beforeunload', save_data)

	on_window_resize()
	$window.resize(on_window_resize)

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

	update_affix()

	init_hide_switches()

init_key_events = ->
	# Edit change
	$txt.keydown(override_return)
	$exp.keydown(override_return)

	$txt.keyup(delay_run_match)
	$exp.keyup(delay_run_match)
	$exp.keyup(update_affix)

	# Force to paste plain text.
	$txt[0].addEventListener('paste', clean_paste_text)
	$exp[0].addEventListener('paste', clean_paste_text)

	$flags.keyup(delay_run_match)

	$exp_dsp.click(select_all_text)

clean_paste_text = (e) ->
	text = e.clipboardData.getData("text/plain")
	document.execCommand("insertHTML", false, escape_html(text))
	e.preventDefault()

update_affix = ->
	$af = $('.affix')
	$ap = $('.affix-placeholder')
	$ap.height($af.outerHeight())

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

		if $this.val() == 'on'
			$this.val('off')
			$tar.hide()
		else
			$this.val('on')
			$tar.show()
	)

	$('.switch_hide').each(->
		$this = $(this)
		if $this.val() == 'off'
			$this.val('on')
			$this.click()
	)

on_window_resize = ->
	if $window.width() < 768
		$('.col-xs-8').removeClass('col-xs-8').addClass('col-xs-12')
		$('.col-xs-2').removeClass('col-xs-2').addClass('col-xs-6')
	else
		$('.col-xs-12').removeClass('col-xs-12').addClass('col-xs-8')
		$('.col-xs-6').removeClass('col-xs-6').addClass('col-xs-2')

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
anchor = (index, j, k) ->
	c = anchor_c++ % 4
	switch c
		when 0
			"<i index='#{index}' pos='#{j} #{k}'>"
		when 1
			"</i>"
		when 2
			"<b index='#{index}' pos='#{j} #{k}'>"
		when 3
			"</b>"

# Escape html.
entityMap = {
	"&": "&amp;"
	"<": "&lt;"
	">": "&gt;"
}
escape_html_exp = /[&<>]/g
escape_html = (str) ->
	return '' if not str
	return str.replace(
		escape_html_exp,
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
	flags = $flags.val()
	txt = $txt.text()

	syntax_highlight(exp, flags)

	if not exp
		input_clear()
		return

	exp = escape_exp(exp)
	try
		r = XRegExp(exp, flags)
	catch e
		input_clear(e)
		return

	# Store the match groups
	ms = []

	is_txt_shown = $txt.is(":visible")
	is_match_shown = $match.is(":visible")

	# Find all groups.
	pos = 0
	while m = XRegExp.exec(txt, r, pos)
		m.lastIndex = m.index + m[0].length
		ms.push m

		pos = m.lastIndex

		# Empty match will also increase the counter.
		if m[0].length == 0
			pos++

		if not r.global
			break

	if is_txt_shown
		visual = ''
		i = 0
		count = 0
		for m in ms
			visual += match_visual(txt, i, m.index, m.lastIndex, count++)
			i = m.lastIndex
		visual += escape_html(txt.slice(i))

		$txt.empty().html(visual)

		$txt.find('[index]').hover(
			match_elem_show_tip
			->
				$(this).popover('destroy')
		)

	# Show the match object as json string.
	if is_match_shown
		list = create_match_ol(ms)
		$match.html(list)

escape_exp = (exp) ->
	for i in exp_escape_list
		exp = exp.replace(
			new RegExp("\\(\\?<#{i}>", 'g')
			"(?<___#{i}>"
		)

	exp

unescape_exp = (name) ->
	for i in exp_escape_list
		if name == '___' + i
			return name.slice(3)
	name

match_visual = (str, i, j, k, c) ->
	# Escaping is important.
	escape_html(str.slice(i, j)) +
	anchor(c, j, k - 1) +
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
	$exp.html(exp + '<br>')
	$exp.find('[title]').removeAttr('title')

create_match_ol = (ms) ->
	if not ms
		return ''

	list = '<ol start="0">'

	for i in ms
		es = escape_html(i[0])
		list += "<li><span class='g'>#{es}</span></li>"

	list += '</ol>'

create_match_table = (m) ->
	if not m or not m.hasOwnProperty('index')
		return ''

	table = '<table>'

	delete m.input
	delete m.index

	for k, v of m
		es_k = unescape_exp(k)
		es_v = escape_html(v)
		table += "<tr><td class='text-right strong'>#{es_k}: </td>" +
			"<td><span class='g'>#{es_v}</span></td></tr>"

	table += '</table>'

match_elem_show_tip = ->
	$this = $(this)

	index = $this.attr('index')
	[j, k] = $this.attr('pos').split(' ')

	# Create match list.
	r = XRegExp(
		escape_exp($exp.text())
		$flags.val().replace('g', '')
	)
	m = XRegExp.exec($this.text(), r, 0)

	$this.popover({
		animation: false
		html: true
		title: "Group : <span class='text-primary'>#{index}</span>
				Range: <span class='text-primary'>[#{j}, #{k}]</span>"
		content: create_match_table(m)
		placement: 'auto'
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

window.share_state = ->
	data = {
		exp: $exp.text()
		flags: $flags.val()
		txt: $txt.text()
	}
	json = JSON.stringify(data)
	compressed = LZString.compressToBase64(json)

	$('#share').val(compressed).select()

window.apply_state = ->
	compressed = $('#share').val()
	json = LZString.decompressFromBase64(compressed)
	data = JSON.parse(json)
	$exp.text(data.exp)
	$flags.val(data.flags)
	$txt.text(data.txt)

	run_match()

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
