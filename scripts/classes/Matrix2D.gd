class_name Matrix2D

var data: Array = []
var size: Vector2i
var default_value

func setup(_size: Vector2i, _default_value = null):
	self.size = _size
	self.default_value = _default_value
	data = []
	for y in range(size.y):
		var row = []
		for x in range(size.x):
			row.append(_default_value)
		data.append(row)

func getv(x: int, y: int):
	return data[y][x]

func setv(x: int, y: int, value) -> void:
	data[y][x] = value

func get_size() -> Vector2i:
	return size

func is_valid_pos(x: int, y: int) -> bool:
	return x >= 0 and x < size.x and y >= 0 and y < size.y

func reset() -> void:
	for y in range(size.y):
		for x in range(size.x):
			data[y][x] = default_value

func clone() -> Matrix2D:
	var new_matrix = Matrix2D.new()
	new_matrix.setup(size)
	for y in range(size.y):
		for x in range(size.x):
			new_matrix.setv(x, y, data[y][x])
	return new_matrix

func print_matrix() -> void:
	print("Printing matrix:")
	for y in range(size.y):
		var row_str = ""
		for x in range(size.x):
			row_str += str(data[y][x]) + " "
		print(row_str.strip_edges())
