# assets

Put your rigged character model here and name it `Character.fbx`, or change
`CHARACTER_MODEL` in `Unit1.pas`.

Supported formats include FBX, glTF / GLB, DAE (COLLADA), OBJ, 3DS, 3MF, STL
and USD. Textures referenced by the model are resolved relative to it, so keep
them in this folder as well.

As long as no model is found here, the blue capsule inside `GorillaModel1`
stands in for the character and the project still runs.

The project looks for this folder next to the executable first and then two
levels up - so running from `Win64\Debug` out of the IDE finds the folder that
sits next to the `.dproj`. See `TForm1.AssetsPath` in `Unit1.pas`.

Do not forget to add the files to **Project > Deployment** before you ship a
build.
