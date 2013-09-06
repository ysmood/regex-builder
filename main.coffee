$exp = $('#exp')
$cur_exp = $('#cur_exp')
$input = $('#input')
$match = $('#match')
$visual_pre = $('#visual-pre')
$flag = $('#flag')

init = ->
	# Edit change
	$input.keyup(delay_run_match)
	$exp.keyup(delay_run_match)
	$flag.keyup(delay_run_match)

	# Load data.
	$('[save]').each(->
		$this = $(this)
		v = localStorage.getItem(
			$this.attr('id')
		)
		if v != null
			$this.val(v)

	)
	run_match()

	$cur_exp.click(select_all_text)

	# Init tooltips.
	$('[title]').tooltip()

	$exp.select()


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
	clearTimeout(delay_id)
	delay_id = setTimeout(
		run_match,
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

select_all_text = (containerid) ->
	if document.selection
		range = document.body.createTextRange()
		range.moveToElementText(this)
		range.select()
	else if window.getSelection
		range = document.createRange()
		range.selectNode(this)
		window.getSelection().addRange(range)

run_match = ->
	exp = $exp.val()
	flag = $flag.val()
	input = $input.val()

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
		while (m = r.exec(input)) != null
			ms.push m[0]
			k = r.lastIndex
			j = k - m[0].length
			# Escaping is important.
			visual += escape_html(input.slice(i, j)) + anchor(count++)
			visual += input.slice(j, k) + anchor()
			i = k

			# Empty match will also increase the counter.
			if m[0].length == 0
				r.lastIndex++
		visual += escape_html(input.slice(i))
	else
		visual = input.replace(r, (m) ->
			ms.push m
			m = anchor(count) + m + anchor()
		)

	$visual_pre.empty().html(visual)
	$visual_pre.find('[index]').hover(
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


# Save data.
window.onbeforeunload = ->
	$('[save]').each(->
		$this = $(this)
		localStorage.setItem(
			$this.attr('id'),
			$this.val()
		)
	)
	return null


init()
