$exp = $('#exp')
$cur_exp = $('#cur_exp')
$input = $('#input')
$match = $('#match')
$visual_pre = $('#visual-pre')
$flag = $('#flag')

exp = ''
flag = $flag.val()
input = ''

$input.keyup(->
	input = $input.val()
	run_match()
)

$exp.keyup(->
	exp = $exp.val()
	run_match()
)

$flag.keyup(->
	flag = $flag.val()
	run_match()
)

delay = $('#exe_delay').change(->
	delay = $(this).val()
).val()

$('.switch_hide').click(->
	$this = $(this)
	$tar = $('#' + $this.attr('target'))

	if $this.attr('checked')
		$tar.hide()
	else
		$tar.show()
)

$('[title]').tooltip()


delay_id = null
run_match = ->
	clearTimeout(delay_id)
	delay_id = setTimeout(
		delay_run_match,
		delay
	)

delay_run_match = ->
	if not exp
		$match.text('')
		$cur_exp.val('')
		return

	try
		r = new RegExp(exp, flag)
	catch e
		$match.text(e)
		return

	$cur_exp.val(r)
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
		visual += escape(input.slice(i, j)) + anchor()
		visual += input.slice(j, k) + anchor()
		i = k

		# Empty match will also increase the counter.
		if m[0].length == 0
			r.lastIndex++

		if not r.global
			break

	visual += escape(input.slice(i))

	$visual_pre.html(visual)

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

escape_reg = /[<>]/g
escape = (str) ->
	str.replace(escape_reg, '_')