$exp = $('#exp')
$cur_exp = $('#cur_exp')
$input = $('#input')
$match = $('#match')
$visual = $('#visual')
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
	json = JSON.stringify(m, null, 2)
	$match.text(json)

	# Highlighting match words.
	visual = ''
	i = 0
	while (m = r.exec(input)) != null
		k = r.lastIndex
		j = k - m[0].length
		# Escaping is important.
		visual += _.escape(input.slice(i, j)) + '<span>'
		visual += input.slice(j, k) + '</span>'
		i = k

		# Empty match will also increase the counter.
		if m[0].length == 0
			r.lastIndex++

		if not r.global
			break

	visual += input.slice(i)

	$visual.html(visual)

