describe 'headerEnvironmentParser', ->
  parser = require lib 'headerEnvironmentParser/parser'
  result = null
  error = null

  beforeEach ->
    result = null
    error = null

  parse = (header) ->
    try
      result = parser.parse header
    catch e
      error = e
      throw new Error "#{e.message} in line #{e.line}:#{e.column}"

  expectDefaultResult = ->
    expect(result[0][0]).to.equal 'name'
    expect(result[0][1][0]).to.equal 'Foo'

  expectOnlyDefaultResult = ->
    expectDefaultResult()
    expect(result[1]).to.be.undefined

  parseDefinition = (definition) ->
    parse """
        /**
         * Karma Environment
         *   #{definition}
         */
      """

    result[0]

  it 'should exist', ->
    expect(parser).to.be.defined

  describe 'simple header', ->
    beforeEach ->
      parse '''
        /**
         * Karma Environment
         *   name: Foo
         */
      '''

    it 'should return an array', ->
      expect(result).to.be.an 'array'

    it 'should contain a definition in the form of an array', ->
      expect(result[0]).to.be.an 'array'

    it 'should know the method name', ->
      expect(result[0][0]).to.equal 'name'

    it 'should know arguments in form of an array', ->
      expect(result[0][1]).to.be.an 'array'

    it 'should know the first argument', ->
      expect(result[0][1][0]).to.equal 'Foo'

    it 'should not add additional arguments', ->
      expect(result[0][1][1]).to.be.undefined

    it 'should not add additional definitions', ->
      expect(result[1]).to.be.undefined

  describe 'multiple definitions', ->
    beforeEach ->
      parse '''
        /**
         * Karma Environment
         *   name: Foo
         *   surname: Bar
         */
      '''

    it 'should still know the first definition', ->
      expectDefaultResult()

    it 'should now also knot the second definition', ->
      expect(result[1][0]).to.equal 'surname'
      expect(result[1][1][0]).to.equal 'Bar'

  describe 'multiple arguments', ->
    beforeEach ->
      parse '''
        /**
         * Karma Environment
         *   name: Foo|Bar
         */
      '''

    it 'should split the arguments', ->
      expect(result[0][1][0]).to.equal 'Foo'
      expect(result[0][1][1]).to.equal 'Bar'

  describe 'argument types', ->
    it 'should convert to booleans', ->
      expect(parseDefinition('foo: true')[1][0]).to.equal true
      expect(parseDefinition('foo: false')[1][0]).to.equal false

    it 'should convert to numbers', ->
      expect(parseDefinition('foo: 5')[1][0]).to.equal 5
      expect(parseDefinition('foo: 0.45')[1][0]).to.equal .45

    it 'should convert to arrays', ->
      expect(parseDefinition('foo: one, two')[1][0]).to.deep.equal ['one', 'two']

    it 'should convert values inside arrays', ->
      expect(parseDefinition('foo: 5,false')[1][0]).to.deep.equal [5, false]

  describe 'Environment comments', ->
    it 'should ignore disabled lines / comments', ->
      parse '''
        /**
         * Karma Environment
         *   name: Foo
         *   #surname: Bar
         */
      '''
      expectOnlyDefaultResult()

    it 'should not abort on disabled lines', ->
      parse '''
        /**
         * Karma Environment
         *   name: Foo
         *   #surname: Bar
         *   something: Else
         */
      '''
      expect(result[1][0]).to.equal 'something'
      expect(result[1][1][0]).to.equal 'Else'


  describe 'distortion', ->
    it 'should not care about special chars inside the method', ->
      parse '''
        /**
         * Karma Environment
         *   my strange^custom_METHOD: Foo
         */
      '''
      expect(result[0][0]).to.equal 'my strange^custom_METHOD'

    it 'should ignore foo before environment', ->
      parse '''
        /**
         * Some other comment
         *
         * Karma Environment
         *   name: Foo
         */
      '''
      expectOnlyDefaultResult()


    it 'should allow empty lines between definitions', ->
      parse '''
        /**
         * Karma Environment
         *
         *   name: Foo
         */
      '''
      expectOnlyDefaultResult()

    it 'should ignore empty lines after environment', ->
      parse '''
        /**
         * Karma Environment
         *   name: Foo
         *
         */
      '''
      expectOnlyDefaultResult()

    it 'should ignore other comments after environment', ->
      parse '''
        /**
         * Karma Environment
         *   name: Foo
         * Yo, some comment here!
         */
      '''
      expectOnlyDefaultResult()

    it 'should ignore incorrectly indented lines for definitions', ->
      parse '''
        /**
         * Karma Environment
         *   name: Foo
         *  surname: Bar
         */
      '''
      expectOnlyDefaultResult()

    it 'should accept single opening comments', ->
      parse '''
        /*
         * Karma Environment
         *   name: Foo
         */
      '''
      expectOnlyDefaultResult()

    it 'should accept deep indented comment blocks', ->
      parse '''
        /**
                   * Karma Environment
                   *   name: Foo
                   */
      '''
      expectOnlyDefaultResult()

  describe 'coffee', ->
    it 'should also handle coffeescript comments', ->
      parse '''
        ###*
         * Karma Environment
         *   name: Foo
        ###
      '''
      expectOnlyDefaultResult()

    it 'should ignore plain js closing comments in coffee', ->
      parse '''
        ###*
         * Karma Environment
         *   name: Foo
         */
        ###
      '''
      expectOnlyDefaultResult()











