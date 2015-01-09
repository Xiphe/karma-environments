describe 'a spec', ->
  it 'should succeed', ->
    expect(true).toBe true

describe 'sampleLib', ->
  it 'should provide foo', ->
    expect(foo).toBe 'bar'

describe 'tempLibs', ->
  it 'should know lorem', ->
    expect(window.lorem).toEqual 'ipsum'

  it 'should be available in other libs', ->
    expect(drrt).toEqual 'ipsummaeh'

describe 'libs in call', ->
  it 'should know how cookies taste', ->
    expect(cookies).toEqual 'mjummy'
