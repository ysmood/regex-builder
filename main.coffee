$exp = $('#exp')
$cur_exp = $('#cur_exp')
$input = $('#input')
$match = $('#match')
$visual_pre = $('#visual-pre')
$flag = $('#flag')

init = ->
	# Edit change
	$input.keyup(run_match)
	$exp.keyup(run_match)
	$flag.keyup(run_match)

	# Load data.
	$('[save]').each(->
		$this = $(this)
		v = localStorage.getItem(
			$this.attr('id')
		)
		if v
			$this.val(v)

	)
	delay_run_match()

	# Init tooltips.
	$('[title]').tooltip()


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
run_match = ->
	clearTimeout(delay_id)
	delay_id = setTimeout(
		delay_run_match,
		delay
	)

# Generate tag for highlighting in turns.
anchor_c = 0
anchor = ->
	c = anchor_c++ % 4
	switch c
		when 0
			'<i>'
		when 1
			'</i>'
		when 2
			'<b>'
		when 3
			'</b>'

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


delay_run_match = ->
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

	$cur_exp.html(
		RegexColorizer.colorizeText(r.toString())
	)

	m = input.match(r)
	json = JSON.stringify(m, null, 1)
	$match.text(json)

	# Highlighting match words.
	visual = ''
	i = 0
	while (m = r.exec(input)) != null
		k = r.lastIndex
		j = k - m[0].length
		# Escaping is important.
		visual += escape_html(input.slice(i, j)) + anchor()
		visual += input.slice(j, k) + anchor()
		i = k

		# Empty match will also increase the counter.
		if m[0].length == 0
			r.lastIndex++

		if not r.global
			break

	visual += escape_html(input.slice(i))

	$visual_pre.html(visual)

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
