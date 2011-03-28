package aerys.minko.scene.group
{
	import aerys.minko.scene.Model3D;
	import aerys.minko.scene.material.ColorMaterial3D;
	import aerys.minko.scene.material.IMaterial3D;
	import aerys.minko.scene.mesh.IMesh3D;
	import aerys.minko.scene.mesh.primitive.TriangleMesh3D;
	import aerys.minko.type.Transform3D;
	import aerys.minko.type.interpolation.AbstractSegment;
	import aerys.minko.type.interpolation.BezierCubicSegment;
	import aerys.minko.type.interpolation.BezierQuadSegment;
	import aerys.minko.type.interpolation.CatmullRomSegment;
	import aerys.minko.type.interpolation.CubicSegment;
	import aerys.minko.type.interpolation.HermiteSegment;
	import aerys.minko.type.interpolation.LinearSegment;
	import aerys.minko.type.math.Vector4;
	
	public class PathGroup3D extends TransformGroup3D
	{
		protected var _debugContainer		: IGroup3D;
		
		protected var _at					: Vector4;
		protected var _up					: Vector4;
		
		protected var _begin				: Vector4;
		protected var _lastBegin			: Vector4;
		protected var _firstBezierControl	: Vector4;
		protected var _lastBezierControl	: Vector4;
		protected var _end					: Vector4;
		
		protected var _segments				: Vector.<AbstractSegment>;
		protected var _lastRatio			: Number;
		
		/**
		 * If this flag is set to true, a TriangleMesh will be addChilded on 
		 * all checkpoints and bezier control points created on subsequent
		 * calls to add* and close* methods on this PathGroup
		 */
		public function set debugContainer(v : IGroup3D) : void
		{
			_debugContainer = v;
		}
		
		/**
		 * current interpolation ratio in the path.
		 */
		public function get ratio() : Number
		{
			return _lastRatio;
		}
		
		public function set ratio(t : Number) : void
		{
			_lastRatio = t;
			
			var segmentCount : uint	= _segments.length;
			if (segmentCount == 0)
			{
				transform.position.set(_end.x, _end.y, _end.z, 0);
			}
			else
			{
				t = (t < 0 ? - t : t) % 1;
				var segment	: AbstractSegment = _segments[int(t * segmentCount)];
				var localT	: Number		  = (t * segmentCount) % 1;
				segment.setTransform(transform, localT);
			}
		}
		
		/**
		 * @var start First checkpoint of the path.
		 * @var at forward direction of the elements in this group. This vector will be kept parralel to the tangent of the path when updating the ratio value.
		 * @var up  up direction of the elements in this group. This vector will determine the rotation around the tangent of the path when updateing the ratio value.
		 * @var ...childen Children to be addChilded at the group creation
		 */
		public function PathGroup3D(start 	: Vector4,
									at		: Vector4,
									up		: Vector4,
									...children)
		{
			super(children);
			
			_at			= at;
			_up			= up;
			_begin		= start;
			_end		= start;
			_segments	= new Vector.<AbstractSegment>();
			
			ratio = 0;
		}
		
		/**
		 * Append a straight line to the path.
		 * 
		 * @var end End of the segment, default to the first point of the path
		 * @var begin Begin of the segment, default to last checkpoint.
		 */
		public function addLinearSegment(end	: Vector4 = null, 
										 begin	: Vector4 = null) : PathGroup3D
		{
			if (end == null) end = _begin;
			if (begin == null) begin = _end;
			
			_segments.push(new LinearSegment(begin, end));
			_lastBegin = begin;
			_lastBezierControl = begin;
			_end = end;
			
			if (_firstBezierControl == null && _segments.length == 1)
				_firstBezierControl = end;
			
			if (_segments.length > 1)
			{
				_lastRatio = (_segments.length - 1) * _lastRatio / _segments.length;
				if (_segments[_segments.length - 2] is CubicSegment)
					CubicSegment(_segments[_segments.length - 2]).next = end;
			}
			
			if (_debugContainer)
			{
				addDebugMarker(begin, false);
				addDebugMarker(end, false);
			}

			return this;
		}
		
		/**
		 * Append a cosine segment to the path
		 * 
		 * @var end End of the segment, default to the begining of the path.
		 * @var begin Begin of the segment, default to last checkpoint.
		 */
		public function addCosineSegment(end	: Vector4 = null,
										 begin	: Vector4 = null) : PathGroup3D
		{
			if (begin == null) begin = _end;
			if (end == null) _end = _begin;
			
			_segments.push(new CubicSegment(begin, end, _lastBegin, null));
			_lastBegin = begin;
			_lastBezierControl = null;
			_end = end;
			
			if (_segments.length > 1)
			{
				_lastRatio = (_segments.length - 1) * _lastRatio / _segments.length;
				if (_segments[_segments.length - 2] is CubicSegment)
					CubicSegment(_segments[_segments.length - 2]).next = end;
			}
			
			if (_debugContainer)
			{
				addDebugMarker(begin, false);
				addDebugMarker(end, false);
			}

			return this;
		}
		
		/**
		 * Append a cubic segment to the path
		 * 
		 * @var end End of the segment, default to the first point of the path
		 * @var begin Begin of the segment, default to last checkpoint.
		 */
		public function addCubicSegment(end		: Vector4 = null,
										begin	: Vector4 = null) : PathGroup3D
		{
			if (begin == null) begin = _end;
			if (end == null) end = _begin;
			
			_segments.push(new CubicSegment(begin, end, _lastBegin, null));
			_lastBegin = begin;
			_lastBezierControl = null;
			_end = end;
			
			if (_segments.length > 1)
			{
				_lastRatio = (_segments.length - 1) * _lastRatio / _segments.length;
				if (_segments[_segments.length - 2] is CubicSegment)
					CubicSegment(_segments[_segments.length - 2]).next = end;
			}
			
			if (_debugContainer)
			{
				addDebugMarker(begin, false);
				addDebugMarker(end, false);
			}
			
			return this;
		}
		
		/**
		 * Append a Catmull-Rom cubic segment to the path
		 * 
		 * @var end End of the segment, default to the first point of the path
		 * @var begin Begin of the segment, default to last checkpoint.
		 */
		public function addCatmullRomSegment(end	: Vector4 = null, 
											 begin	: Vector4 = null) : PathGroup3D
		{
			if (begin == null) begin = _end;
			if (end == null) end = _begin;
			
			_segments.push(new CatmullRomSegment(begin, end, _lastBegin, null));
			_lastBegin = begin;
			_lastBezierControl = null;
			_end = end;
			
			if (_segments.length > 1)
			{
				_lastRatio = (_segments.length - 1) * _lastRatio / _segments.length;
				if (_segments[_segments.length - 2] is CubicSegment)
					CubicSegment(_segments[_segments.length - 2]).next = end;
			}
			
			if (_debugContainer)
			{
				addDebugMarker(begin, false);
				addDebugMarker(end, false);
			}

			return this;
		}
		
		/**
		 * Append an Hermite segment to the path
		 * 
		 * @var end End of the segment, default to the first point of the path
		 * @var tension used to tighten up the curvature at the known points. 1 is high, 0 normal, -1 is low.
		 * @var bias used to twist the curve about the known points. 0 is even, positive is towards first segment, negative towards the other
		 * @var begin Begin of the segment, default to last checkpoint.
		 */
		public function addHermiteSegment(end		: Vector4 = null,
										  tension	: Number = 0,
										  bias		: Number = 0,
										  begin		: Vector4 = null) : PathGroup3D
		{
			if (begin == null) begin = _end;
			if (end == null) end = _begin;
			
			_segments.push(new HermiteSegment(begin, end, bias, tension, _lastBegin, null));
			_lastBegin = begin;
			_lastBezierControl = null;
			_end = end;
			
			if (_segments.length > 1)
			{
				_lastRatio = (_segments.length - 1) * _lastRatio / _segments.length;
				if (_segments[_segments.length - 2] is CubicSegment)
					CubicSegment(_segments[_segments.length - 2]).next = end;
			}
			
			if (_debugContainer)
			{
				addDebugMarker(begin, false);
				addDebugMarker(end, false);
			}
			return this;
		}
		
		/**
		 * Append a Bezier quadratic segment to the path
		 * 
		 * @var control Bezier control point
		 * @var end End of the segment, default to the first point of the path
		 * @var begin Begin of the segment, default to last checkpoint.
		 * @see Wikipedia article about bezier curves <http://en.wikipedia.org/wiki/B%C3%A9zier_curve#Quadratic_curves>
		 */
		public function addBezierQuadSegment(control	: Vector4,
											 end		: Vector4 = null,
											 begin		: Vector4 = null) : PathGroup3D
		{
			if (begin == null) begin = _end;
			if (end == null) end = _begin;
			
			_segments.push(new BezierQuadSegment(begin, control, end));
			_lastBegin = begin;
			_lastBezierControl = control;
			_end = end;
			
			if (_firstBezierControl == null && _segments.length == 1)
				_firstBezierControl = control;
			
			if (_segments.length > 1)
			{
				_lastRatio = (_segments.length - 1) * _lastRatio / _segments.length;
				if (_segments[_segments.length - 2] is CubicSegment)
					CubicSegment(_segments[_segments.length - 2]).next = end;
			}
			
			if (_debugContainer)
			{
				addDebugMarker(begin, false);
				addDebugMarker(control, true, false);
				addDebugMarker(end, false);
			}
			
			return this;
		}
		
		/**
		 * Append a Bezier cubic segment to the path.
		 * 
		 * @var control1 Bezier control point
		 * @var control2 Bezier control point
		 * @var end End of the segment, default to the first point of the path
		 * @var begin Begin of the segment, default to last checkpoint.
		 * @see Wikipedia article about bezier curves <http://en.wikipedia.org/wiki/B%C3%A9zier_curve#Quadratic_curves>
		 */
		public function addBezierCubicSegment(control1	: Vector4, 
											  control2	: Vector4, 
								   			  end		: Vector4 = null,
											  begin		: Vector4 = null) : PathGroup3D
		{
			if (begin == null) begin = _end;
			if (end == null) end = _begin;
			
			_segments.push(new BezierCubicSegment(begin, control1, control2, end));
			_lastBegin = begin;
			_lastBezierControl = control2;
			_end = end;
			
			if (_firstBezierControl == null && _segments.length == 1)
				_firstBezierControl = control1;
			
			if (_segments.length > 1)
			{
				_lastRatio = (_segments.length - 1) * _lastRatio / _segments.length;
				if (_segments[_segments.length - 2] is CubicSegment)
					CubicSegment(_segments[_segments.length - 2]).next = end;
			}
			
			if (_debugContainer)
			{
				addDebugMarker(begin, false);
				addDebugMarker(control1, true, false);
				addDebugMarker(control2, true, false);
				addDebugMarker(end, false);
			}
			
			return this;
		}
		
		/**
		 * Append a straight line to the path, going in the same direction.
		 * that the tangent at the last checkpoint.
		 * 
		 * @var length The length of the segment which is appended
		 */
		public function addSmoothLinearSegment(length : Number) : PathGroup3D
		{
			var segmentCount : uint = _segments.length;
			if (segmentCount == 0)
				throw new Error('There is no initial segment to be C1 with');
			
			var end : Vector4 = getControlSymetric(length, _lastBezierControl, _end);
			
			return addLinearSegment(end);
		}
		
		/**
		 * Append a bezier quadratic segment to the path, which smoothly extends it.
		 * To use this method, last segment must be a linear or bezier segment.
		 * 
		 * @var end End of the segment, default to the first point of the path
		 * @var controlDistance
		 * @see Wikipedia article about bezier curves <http://en.wikipedia.org/wiki/B%C3%A9zier_curve#Quadratic_curves>
		 */
		public function addSmoothBezierQuadSegment(end				: Vector4 = null,
												   controlDistance	: Number = 0) : PathGroup3D
		{
			var segmentCount : uint = _segments.length;
			if (segmentCount == 0)
				throw new Error('There is no initial segment to be C1 with');
			
			if (_lastBezierControl == null)
				throw new Error('Last segment was not a bezier segment. Cannot append a smooth segment.');
			
			var control : Vector4 = getControlSymetric(controlDistance, _lastBezierControl, _end);
			
			return addBezierQuadSegment(control, end);
		}
		
		/**
		 * Append a bezier cubic segment to the path, which smoothly extends it.
		 * To use this method, last segment must be a linear or bezier segment.
		 * 
		 * @var control2
		 * @var end End of the segment, default to the first point of the path
		 * @var control1Distance
		 * @see Wikipedia article about bezier curves <http://en.wikipedia.org/wiki/B%C3%A9zier_curve#Quadratic_curves>
		 */
		public function addSmoothBezierCubicSegment(control2			: Vector4,
													end					: Vector4 = null,
													control1Distance	: Number = 0) : PathGroup3D
		{
			var segmentCount : uint = _segments.length;
			if (segmentCount == 0)
				throw new Error('There is no initial segment to be C1 with');
			
			if (_lastBezierControl == null)
				throw new Error('Last segment was not a bezier segment. Cannot append a smooth segment.');
			
			var control1 : Vector4 = getControlSymetric(control1Distance, _lastBezierControl, _end);
			
			addBezierCubicSegment(control1, control2, end);
			return this;
		}
		
		/**
		 * Close the loop, adding a straight line between the last and first checkpoint.
		 */
		public function closeLoopLinear() : PathGroup3D
		{
			return addLinearSegment();
		}
		
		/**
		 * Close the loop, adding a cosine segment between the first and last checkpoint.
		 * If both first and last segments are cosine segments, the path will be smooth.
		 */
		public function closeLoopCosine() : PathGroup3D
		{
			return addCosineSegment();
		}
		
		/**
		 * Close the loop, adding a cubic segment between the first and last checkpoint.
		 * If both first and last segments are cubic segments, the path will be smooth.
		 */
		public function closeLoopCubic() : PathGroup3D
		{
			addCubicSegment();
			
			var cubicSegment : CubicSegment = _segments[_segments.length - 1] as CubicSegment;
			cubicSegment.next = _segments[0].end;
			
			return this;
		}
		
		/**
		 * Close the loop, adding a Catmull-Rom segment between the first and last checkpoint.
		 * If both first and last segments are Catmull-Rom segments, the path will be smooth.
		 */
		public function closeLoopCatmullRom() : PathGroup3D
		{
			addCatmullRomSegment();
			
			var cubicSegment : CatmullRomSegment = _segments[_segments.length - 1] as CatmullRomSegment;
			cubicSegment.next = _segments[0].end;
			
			return this;
		}
		
		/**
		 * Close the loop, adding a Hermite segment between the first and last checkpoint.
		 * If both first and last segments are Hermite segments, the path will be smooth.
		 */
		public function closeLoopHermite() : PathGroup3D
		{
			addHermiteSegment();
			
			var hermiteSegment : HermiteSegment = _segments[_segments.length - 1] as HermiteSegment;
			hermiteSegment.next = _segments[0].end;
			
			return this;
		}
		
		/**
		 * Close the loop adding a Bezier Cubic segment.
		 * First and last segment must be Bezier.
		 * 
		 * @var control1Distance 
		 * @var control2Distance 
		 * @see Wikipedia article about bezier curves <http://en.wikipedia.org/wiki/B%C3%A9zier_curve#Quadratic_curves>
		 */
		public function closeLoopSmoothBezierCubic(control1Distance : Number = 0,
												   control2Distance : Number = 0) : PathGroup3D
		{
			if (_segments.length == 0)
				throw new Error('There is no path to close');
			
			if (control1Distance < 0 || control2Distance < 0)
				throw new Error('Control point distances cannot be negative');
			
			if (_firstBezierControl == null || _lastBezierControl == null)
				throw new Error('First an last segment must be of Bezier type to be able to close the loop.');
			
			var control1 : Vector4 = getControlSymetric(control1Distance, _lastBezierControl, _end);
			var control2 : Vector4 = getControlSymetric(control2Distance, _firstBezierControl, _begin);
			
			return addBezierCubicSegment(control1, control2);
		}
		
		protected function getControlSymetric(distance	: Number, 
											  control	: Vector4, 
											  center	: Vector4) : Vector4
		{
			var control : Vector4;
			
			if (distance < 0)
			{
				throw new Error('Vector length cannot be a negative Number');
			}
			else if (distance == 0)
			{
				control = new Vector4(
					2 * center.x - control.x,
					2 * center.y - control.y,
					2 * center.z - control.z,
					0
				);
			}
			else
			{
				control = new Vector4(
					center.x - control.x,
					center.y - control.y,
					center.z - control.z,
					0
				);
				control.scaleBy(distance / control.length);
				control.set(
					control.x + center.x, 
					control.y + center.y, 
					control.z + center.z, 
					0
				);
			}
			return control;
		}
		
		protected function addDebugMarker(position	: Vector4, 
										  isControl	: Boolean, 
										  isAuto	: Boolean = false) : void 
		{
			var markerMesh	: IMesh3D = new TriangleMesh3D();
			var material	: IMaterial3D = isAuto ? ColorMaterial3D.ORANGE : isControl ? ColorMaterial3D.PURPLE : ColorMaterial3D.BLUE;
			
			var marker : Model3D = new Model3D(markerMesh, material);
			marker.transform.position.set(position.x, position.y, position.z, 0);
			_debugContainer.addChild(marker);
		}
	}
}
