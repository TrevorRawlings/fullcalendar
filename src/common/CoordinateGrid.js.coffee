
class fc.CoordinateGrid

  constructor: ->
    @rows = null
    @cols = null

  build: ->
    throw "CoordinateGrid.build"
    #    @rows = [];
    #    @cols = [];
    #    @buildFunc(@rows, @cols);
    #
    #  buildFunc: (rows, cols) ->
    #    throw "buildFunc"

  cell: (x, y) ->
    r = -1
    c = -1
    for row, i in @rows when y >= row[0] and y < row[1]
        r = i;
        break;

    for col, i in @cols when x >= col[0] and x < col[1]
        c = i;
        break;

    return if (r >= 0 and c >= 0) then { row: r, col: c } else null

  rect: (row0, col0, row1, col1, originElement) -> # row1,col1 is inclusive
    origin = originElement.offset();
    rect =
      top: @rows[row0][0] - origin.top,
      left: @cols[col0][0] - origin.left,
      width: @cols[col1][1] - @cols[col0][0],
      height: @rows[row1][1] - @rows[row0][0]
    return rect
