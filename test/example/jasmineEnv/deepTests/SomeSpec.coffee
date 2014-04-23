describe 'something', ->
  it 'is', ->
    expect(1).toEqual 1

  it 'should have a deep fixture', ->
    expect(document.getElementById('ke-deeptests-anotherfixture')).not.toEqual null
