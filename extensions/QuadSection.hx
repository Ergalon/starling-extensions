package starling.extensions;
import openfl.geom.Point;
import openfl.utils.Object;
import starling.display.Mesh;
import starling.rendering.IndexData;
import starling.rendering.VertexData;
import starling.textures.Texture;

class QuadSection extends Mesh
{

	private var _width:Float;
	private var _height:Float;
	private var _color:UInt;
	private var _slices:Array<Object>;
	private var _ratio:Float;
	private var _clockwise:Bool;

	private static var sPoint:Point = new Point();
	public function new(width:Float, height:Float, color:UInt=0xffffff)
	{
		_color = color;
		_width = width;
		_height = height;
		_ratio = 1.0;
		_clockwise = true;
		_slices = [
		{ ratio: 0.0,   x: _width / 2, y: 0       },
		{ ratio: 0.125, x: _width,     y: 0       },
		{ ratio: 0.375, x: _width,     y: _height },
		{ ratio: 0.625, x: 0,          y: _height },
		{ ratio: 0.875, x: 0,          y: 0       },
		{ ratio: 1.0,   x: _width / 2, y: 0       }
		];

		var vertexData:VertexData = new VertexData(null, 6);
		var indexData:IndexData = new IndexData(15);

		super(vertexData, indexData);

		this.updateVertices();
	}
	private function updateVertices():Void
	{
		vertexData.numVertices = 0;
		indexData.numIndices = 0;

		if (_ratio > 0)
		{
			var angle:Float = _ratio * Math.PI * 2.0 - Math.PI / 2.0;
			var numSlices:Int = _slices.length;
			updateVertex(0, _width / 2, _height / 2); // center point

			for (i in 1...numSlices)
			{
				var currSlice:Object = _slices[i];
				var prevSlice:Object = _slices[i - 1];
				var nextVertexID:Int = i < 6 ? i + 1 : 1;

				indexData.addTriangle(0, i, nextVertexID);
				updateVertex(i, prevSlice.x, prevSlice.y);

				if (_ratio > currSlice.ratio)
					updateVertex(nextVertexID, currSlice.x, currSlice.y);
				else
				{
					intersectLineWithSlice(
						prevSlice.x, prevSlice.y, currSlice.x, currSlice.y, angle, sPoint);
					updateVertex(nextVertexID, sPoint.x, sPoint.y);
					break;
				}
			}
		}

		setVertexDataChanged();
	}

	private function updateVertex(vertexID:Int, x:Float, y:Float):Void
	{
		if (!_clockwise)
			x = _width - x;

		if (texture!=null)
		{
			texture.setTexCoords(vertexData, vertexID, "texCoords", x / _width, y / _height);
		}

		vertexData.setPoint(vertexID, "position", x, y);
		vertexData.setColor(vertexID, "color", _color);
	}

	private function intersectLineWithSlice(ax:Float, ay:Float, bx:Float, by:Float,
											angle:Float, out:Point=null):Point
	{
		if (out == null)
		{
			out = new Point();
		}

		if (ax == bx && ay == by) return null; // length = 0

		var abx:Float = bx - ax;
		var aby:Float = by - ay;
		var cdx:Float = Math.cos(angle);
		var cdy:Float = Math.sin(angle);
		var tDen:Float = cdy * abx - cdx * aby;

		if (tDen == 0.0) return null; // parallel or identical

		var cx:Float = _width  / 2.0;
		var cy:Float = _height / 2.0;
		var t:Float = (aby * (cx - ax) - abx * (cy - ay)) / tDen;

		out.x = cx + t * cdx;
		out.y = cy + t * cdy;

		return out;
	}

	override public function get_color():UInt
	{
		return _color;
	}
	override public function set_color(value:UInt):UInt
	{
		return super.color = _color = value;

	}

	override public function set_texture(value:Texture):Texture
	{
		super.texture = value;
		if (value.frame!=null)
		{
			trace("Warning: 'QuadSection' will ignore any texture frames.");
		}
		updateVertices();
		return value;
	}

	public function getRatio():Float
	{
		return _ratio;

	}
	public function setRatio(value:Float):Void
	{
		if (_ratio != value)
		{
			_ratio = value;
			updateVertices();
		}
	}

	public function getClockwise():Bool
	{
		return _clockwise;

	}
	public function setClockwise(value:Bool):Void
	{
		if (_clockwise != value)
		{
			_clockwise = value;
			updateVertices();
		}
	}

	public static function fromTexture(texture:Texture):QuadSection
	{
		var quadPie:QuadSection = new QuadSection(texture.width, texture.height);
		quadPie.texture = texture;
		return quadPie;
	}
}
