$exp = $('#exp')
$cur_exp = $('#cur_exp')
$match = $('#match')
$input = $('#input')
$flag = $('#flag')
saveSelection = restoreSelection = savedSelection = null

init = ->

	# Edit change
	$input.keypress(run_match)
	$exp.keypress(run_match)
	$flag.keypress(run_match)

	# Load data.
	$('[save]').each(->
		$this = $(this)
		v = localStorage.getItem(
			$this.attr('id')
		)
		if v
			$this[$this.attr('save')](v)

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

$input.keydown( (e) ->
	sel = window.getSelection()
	if e.keyCode == 13
		if sel
			range = sel.getRangeAt(0)
			node = document.createTextNode('\n')
			n = document.createTextNode('')
			range.deleteContents()
			range.collapse(false)
			range.insertNode(n)
			range.insertNode(node)
			range.selectNodeContents(n)

			sel.removeAllRanges()
			sel.addRange(range)
			savedSelection = saveSelection($input[0])
			return false

		e.preventDefault()

	savedSelection = saveSelection($input[0], 1)
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
	input = $input.text()

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

	$input.html(visual)

	restoreSelection($input[0], savedSelection)

# Save data.
window.onbeforeunload = ->
	$('[save]').each(->
		$this = $(this)
		localStorage.setItem(
			$this.attr('id'),
			$this[$this.attr('save')]()
		)
	)
	return null

`
if (window.getSelection && document.createRange) {
    saveSelection = function(containerEl, offset) {
    	if (!offset) offset = 0
        var range = window.getSelection().getRangeAt(0);
        var preSelectionRange = range.cloneRange();
        preSelectionRange.selectNodeContents(containerEl);
        preSelectionRange.setEnd(range.startContainer, range.startOffset);
        var start = preSelectionRange.toString().length;

        return {
            start: start + offset,
            end: start + range.toString().length + offset
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
