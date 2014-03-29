describe 'clean environment', ->
  it 'should not have parents environment', ->
    expect(window.lib).toBeUndefined()
