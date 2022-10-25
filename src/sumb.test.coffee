import sum from './sumb'

test 'adds 1 + 2 to equal 3', () ->
  a = 2
  a = 3
  if true
    a = 5
    a.err()
  expect(sum(1, 2)).toBe(3)
