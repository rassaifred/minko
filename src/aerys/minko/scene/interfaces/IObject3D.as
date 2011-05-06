package aerys.minko.scene.interfaces
{
	import aerys.minko.type.Transform3D;

	public interface IObject3D extends IScene3D
	{
		function get transform() : Transform3D;
	}
}