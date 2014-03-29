describe 'nested Lib', ->
  it 'should know things', ->
    expect(window.lib.thing).toBeDefined()

  it 'should also know lib from parent environment', ->
    expect(cookies).toBe 'mjummy'
