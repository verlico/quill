describe('Editor', ->
  describe('applyDelta', ->
    tests =
      'apply to empty':
        lines: []
        deltas: [new Tandem.InsertOp("0123")]
        expected: ['<div><span>0123</span></div>']
      'append character':
        lines: ['<div><span>0123</span></div>']
        deltas: [new Tandem.RetainOp(0,4), new Tandem.InsertOp('4'), new Tandem.RetainOp(4,5)]
        expected: ['<div><span>01234</span></div>']
      'prepend character':
        lines: ['<div><span>0123</span></div>']
        deltas: [new Tandem.InsertOp('4'), new Tandem.RetainOp(0,5)]
        expected: ['<div><span>40123</span></div>']
      'append formatted character':
        lines: ['<div><span>0123</span></div>']
        deltas: [new Tandem.RetainOp(0,4), new Tandem.InsertOp('4', {bold: true}), new Tandem.RetainOp(4,5)]
        expected: ['<div><span>0123</span><b>4</b></div>']
      'append newline':
        lines: ['<div><span>0123</span></div>']
        deltas: [new Tandem.RetainOp(0,5), new Tandem.InsertOp("\n")]
        expected: ['<div><span>0123</span></div>', '<div><br></div>']
      'insert newline in middle of text':
        lines: ['<div><span>0123</span></div>']
        deltas: [new Tandem.RetainOp(0,2), new Tandem.InsertOp("\n"), new Tandem.RetainOp(2,5)]
        expected: ['<div><span>01</span></div>', '<div><span>23</span></div>']
      'insert newline before line with just newline':
        lines: ['<div><span>01</span></div>', '<div><br></div>', '<div><span>23</span></div>']
        deltas: [new Tandem.RetainOp(0,3), new Tandem.InsertOp("\n"), new Tandem.RetainOp(3,7)]
        expected: [0, 1, 1, 2]
      'insert newline after line with just newline':
        lines: ['<div><span>01</span></div>', '<div><br></div>', '<div><span>23</span></div>']
        deltas: [new Tandem.RetainOp(0,4), new Tandem.InsertOp("\n"), new Tandem.RetainOp(4,7)]
        expected: [0, 1, 1, 2]
      'double insert':
        lines: ['<div><span>0123</span></div>']
        deltas: [new Tandem.RetainOp(0,2), new Tandem.InsertOp('a'), new Tandem.InsertOp('b'), new Tandem.RetainOp(2,5)]
        expected: ['<div><span>01ab23</span></div>']
      'append differing formatted texts':
        lines: ['<div><br></div>']
        deltas: [new Tandem.InsertOp('01', {bold:true}), new Tandem.InsertOp('23', {italic:true}), new Tandem.RetainOp(0,1)]
        expected: ['<div><b>01</b><i>23</i></div>']

    _.each(tests, (test, name) ->
      it(name, ->
        html = test.lines.join('')
        $('#editor-container').html(html)
        editor = new Scribe.Editor('editor-container')
        oldDelta = editor.doc.toDelta()
        startLength = oldDelta.endLength
        endLength = _.reduce(test.deltas, ((count, delta) -> return count + delta.getLength()), 0)
        delta = new Tandem.Delta(startLength, endLength, test.deltas)
        expectedHtml = _.map(test.expected, (line) ->
          return if _.isNumber(line) then test.lines[line] else line
        ).join('')
        editor.applyDelta(delta)
        consistent = Scribe.Debug.checkDocumentConsistency(editor.doc)
        newDelta = editor.doc.toDelta()
        $('#editor-container').html(expectedHtml)
        editor = new Scribe.Editor('editor-container')
        expectedDelta = editor.doc.toDelta()
        expect(consistent).to.be.true
        expect(newDelta).to.deep.equal(expectedDelta)
      )
    )
  )



  describe('Format Leaf', ->
    tests = 
      'single node':
        lines: ['<div><s>0</s><u>1</u><s>2</s></div>']
        start: 1, length: 1
        expected: ['<div><s>0</s><#><u>1</u></#><s>2</s></div>']
      'multiple nodes':
        lines: ['<div><s>0</s><u>1</u><s>2</s><u>3</u></div>']
        start: 1, length: 2
        expected: ['<div><s>0</s><#><u>1</u><s>2</s></#><u>3</u></div>']
      'part of node':
        lines: ['<div><#>012</#><i>345</i></div>']
        start: 3, length: 2
        expected: ['<div><#>012</#><#><i>34</i></#><i>5</i></div>']
      'inside of node':
        lines: ['<div><#>012</#><i>345</i></div>']
        start: 4, length: 1
        expected: ['<div><#>012</#><i>3</i><#><i>4</i></#><i>5</i></div>']
      'nodes spanning multiple lines':
        lines: ['<div><#>012</#><i>345</i></div>', '<div><s>7</s><u>8</u></div>']
        start: 3, length: 5
        expected: ['<div><#>012</#><#><i>345</i></#></div>', '<div><#><s>7</s></#><u>8</u></div>']
      'entire line':
        lines: ['<div><#>01</#><i>23</i></div>', '<div><s>5</s><u>6</u></div>', '<div><b>89</b></div>']
        start: 5, length: 2
        expected: [0, '<div><#><s>5</s><u>6</u></#></div>', 2]
      'entire line with trailing newline':
        lines: ['<div><#>01</#><i>23</i></div>', '<div><s>5</s><u>6</u></div>', '<div><b>89</b></div>']
        start: 5, length: 3
        expected: [0, '<div><#><s>5</s><u>6</u></#></div>', 2]
      'entire line with preceding newline':
        lines: ['<div><#>01</#><i>23</i></div>', '<div><s>5</s><u>6</u></div>', '<div><b>89</b></div>']
        start: 4, length: 3
        expected: [0, '<div><#><s>5</s><u>6</u></#></div>', 2]
      'entire line with preceding and trailing newline':
        lines: ['<div><#>01</#><i>23</i></div>', '<div><s>5</s><u>6</u></div>', '<div><b>89</b></div>']
        start: 4, length: 4
        expected: [0, '<div><#><s>5</s><u>6</u></#></div>', 2]

    formatTests = [{
      format: 'bold'
      tagName: 'b'
      value: true
    }, {
      format: 'bold'
      tagName: 'b'
      value: false
    }, {
      format: 'family'
      tagName: 'span'
      value: 'serif'
    }, {
      format: 'family'
      tagName: 'span'
      value: false
    }, {
      format: 'family'
      tagName: 'span'
      value: 'san-serif'
    }]

    _.each(tests, (test, name) ->
      originalHtml = test.lines.join('')
      expectedHtml = _.map(test.expected, (line) ->
        return if _.isNumber(line) then test.lines[line] else line
      ).join('')
      _.each(formatTests, (formatTest) ->
        it("should set #{formatTest.format} to #{formatTest.value} on #{name}", ->
          openTag = if formatTest.tagName == 'span' then "#{formatTest.tagName} class=\"#{formatTest.format}-#{formatTest.value}\"" else formatTest.tagName
          expected = expectedHtml.replace(/\/#/g, "/#{formatTest.tagName}").replace(/#/g, openTag)
          original = originalHtml.replace(/\/#/g, "/#{formatTest.tagName}").replace(/#/g, openTag)
          apply = formatTest.value && Scribe.Utils.getFormatDefault(formatTest.format) != formatTest.value
          [startHtml, endHtml] = if apply then [original, expected] else [expected, original]
          $('#editor-container').html(startHtml)
          editor = new Scribe.Editor('editor-container')
          editor.formatAt(test.start, test.length, formatTest.format, formatTest.value)
          range = new Scribe.Range(editor, test.start, test.start + test.length)
          formats = _.clone(range.getFormats())
          delta = editor.doc.toDelta()
          $('#editor-container').html(endHtml)
          editor = new Scribe.Editor('editor-container')
          expectedDelta = editor.doc.toDelta()
          consistent = Scribe.Debug.checkDocumentConsistency(editor.doc, true)
          if apply
            expect(formats[formatTest.format]).to.equal(formatTest.value)
          else
            if formatTest.format == 'bold'
              expect(formats[formatTest.format]).to.be.undefined
            else if formatTest.format == 'family'
              expect(formats[formatTest.format]).to.equal('san-serif')
          expect(consistent).to.be.true
          expect(delta).to.deep.equal(expectedDelta)
        )
      )
    )
  )



  describe('insertAt', ->
    tests = 
      'should insert simple text':
        lines: ['<div><span>123</span><i>456</i></div>']
        fn: (editor) -> editor.insertAt(1, 'A')
        expected: ['<div><span>1A23</span><i>456</i></div>']
      'should insert text inside formatted tags':
        lines: ['<div><span>123</span><i>456</i></div>']
        fn: (editor) -> editor.insertAt(4, 'A')
        expected: ['<div><span>123</span><i>4</i><span>A</span><i>56</i></div>']
      'should insert newline character':
        lines: ['<div><span>123</span><i>456</i></div>']
        fn: (editor) -> editor.insertAt(1, "\n")
        expected: ['<div><span>1</span></div>', '<div><span>23</span><i>456</i></div>']
      'should insert text with newline':
        lines: ['<div><span>123</span><i>456</i></div>']
        fn: (editor) -> editor.insertAt(1, "A\nB")
        expected: ['<div><span>1A</span></div>', '<div><span>B23</span><i>456</i></div>']
      'should insert multiple newline text':
        lines: ['<div><span>123</span><i>456</i></div>']
        fn: (editor) -> editor.insertAt(1, "A\nB\nC")
        expected: ['<div><span>1A</span></div>', '<div><span>B</span></div>', '<div><span>C23</span><i>456</i></div>']
      'should add preceding newline':
        lines: ['<div><span>123</span><i>456</i></div>']
        fn: (editor) -> editor.insertAt(0, "\n")
        expected: ['<div><br></div>', 0]
      'should add trailing newline':
        lines: ['<div><span>123</span><i>456</i></div>']
        fn: (editor) -> editor.insertAt(6, "\n")
        expected: [0, '<div><br></div>']
      'should add trailing text and newline':
        lines: ['<div><span>123</span><i>456</i></div>']
        fn: (editor) -> editor.insertAt(7, "89\n")
        expected: [0, '<div><span>89</span></div>']
      'should insert mutliple newline in a row text':
        lines: ['<div><span>123</span><i>456</i></div>']
        fn: (editor) -> editor.insertAt(1, "A\n\nC")
        expected: ['<div><span>1A</span></div>', '<div><br></div>', '<div><span>C23</span><i>456</i></div>']

    _.each(tests, (test, name) ->
      it(name, ->
        html = test.lines.join('')
        expectedHtml = _.map(test.expected, (line) ->
          return if _.isNumber(line) then test.lines[line] else line
        ).join('')
        $('#editor-container').html(html)
        editor = new Scribe.Editor('editor-container')
        test.fn(editor)
        consistent = Scribe.Debug.checkDocumentConsistency(editor.doc)
        newDelta = editor.doc.toDelta()
        $('#editor-container').html(expectedHtml)
        editor = new Scribe.Editor('editor-container')
        expectedDelta = editor.doc.toDelta()
        expect(consistent).to.be.true
        expect(newDelta).to.deep.equal(expectedDelta)
      )
    )
  )



  describe('deleteAt', ->
    reset = ->
      $('#editor-container').html(Scribe.Utils.cleanHtml('
        <div>
          <b>123</b>
          <i>456</i>
        </div>
        <div>
          <s>7</s>
          <u>8</u>
          <s>9</s>
          <u>0</u>
        </div>
        <div>
          <b>abcdefg</b>
        </div>
      '))
      return new Scribe.Editor('editor-container')

    tests = [{
      name: 'a node'
      start: 0
      length: 3
      expected:
        '<div>
          <i>456</i>
        </div>
        <div>
          <s>7</s>
          <u>8</u>
          <s>9</s>
          <u>0</u>
        </div>
        <div>
          <b>abcdefg</b>
        </div>'
    }, {
      name: 'part of a node'
      start: [0..2]
      length: 1
      expected: (index) ->
        char = (index + 1).toString()
        html = "
          <div>
            <b>123</b>
            <i>456</i>
          </div>
          <div>
            <s>7</s>
            <u>8</u>
            <s>9</s>
            <u>0</u>
          </div>
          <div>
            <b>abcdefg</b>
          </div>"
        return html.replace(char.toString(), '')
    }, {
      name: 'multiple nodes'
      start: 0
      length: 6
      expected:
        '<div>
          <br>
        </div>
        <div>
          <s>7</s>
          <u>8</u>
          <s>9</s>
          <u>0</u>
        </div>
        <div>
          <b>abcdefg</b>
        </div>'
    }, {
      name: 'across multiple nodes'
      start: [0..2]
      length: 4
      expected: (index) ->
        fragments = [
          "<div><i>56</i></div>"
          "<div><b>1</b><i>6</i></div>"
          "<div><b>12</b></div>"
        ]
        return fragments[index] + "
          <div>
            <s>7</s>
            <u>8</u>
            <s>9</s>
            <u>0</u>
          </div>
          <div>
            <b>abcdefg</b>
          </div>"
    }, {
      name: 'the first line'
      start: 0
      length: 7
      expected:
        '<div>
          <s>7</s>
          <u>8</u>
          <s>9</s>
          <u>0</u>
        </div>
        <div>
          <b>abcdefg</b>
        </div>'
    }, {
      name: 'the last line'
      start: 11
      length: 8
      expected:
        '<div>
          <b>123</b>
          <i>456</i>
        </div>
        <div>
          <s>7</s>
          <u>8</u>
          <s>9</s>
          <u>0</u>
        </div>'
    }, {
      name: 'a middle line + newline'
      start: 7
      length: 5
      expected:
        '<div>
          <b>123</b>
          <i>456</i>
        </div>
        <div>
          <b>abcdefg</b>
        </div>'
    }, {
      name: 'newline + next line'
      start: 6
      length: 5
      expected:
        '<div>
          <b>123</b>
          <i>456</i>
        </div>
        <div>
          <b>abcdefg</b>
        </div>'
    }, {
      name: 'a newline character'
      start: 6
      length: 1
      expected:
        '<div>
          <b>123</b>
          <i>456</i>
          <s>7</s>
          <u>8</u>
          <s>9</s>
          <u>0</u>
        </div>
        <div>
          <b>abcdefg</b>
        </div>'
    }, {
      name: 'entire line and more'
      start: 5
      length: 8
      expected:
        '<div>
          <b>123</b>
          <i>45</i>
          <b>bcdefg</b>
        </div>'
    }, {
      name: 'entire line and more 2'
      start: 0
      length: 8
      expected:
        '<div>
          <u>8</u>
          <s>9</s>
          <u>0</u>
        </div>
        <div>
          <b>abcdefg</b>
        </div>'
    }, {
      name: 'across multiple lines'
      start: [2..4]
      length: 6
      expected: (index) ->
        fragments = [
          '<div><b>12</b><u>8</u><s>9</s><u>0</u></div>'
          '<div><b>123</b><s>9</s><u>0</u></div>'
          '<div><b>123</b><i>4</i><u>0</u></div>'
        ]
        return fragments[index] + '
          <div>
            <b>abcdefg</b>
          </div>'
    }]

    _.each(tests, (test) ->
      starts = if _.isNumber(test.start) then [test.start] else test.start
      _.each(starts, (start, index) ->
        name = 'should delete ' + test.name
        name += ' ' + index if starts.length > 1
        it(name, ->
          editor = reset()
          editor.deleteAt(start, test.length)
          consistent = Scribe.Debug.checkDocumentConsistency(editor.doc, true)
          delta = editor.doc.toDelta()
          if _.isString(test.expected)
            expected = test.expected
          else if _.isArray(test.expected)
            expected = test[index]
          else
            expected = test.expected(index)
          editor.root.innerHTML = Scribe.Utils.cleanHtml(expected)
          editor.doc.buildLines()
          expectedDelta = editor.doc.toDelta()
          expect(consistent).to.be.true
          expect(delta).to.deep.equal(expectedDelta)
        )
      )
    )
  )
)


