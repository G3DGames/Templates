# Gorilla3D Project Templates

RAD Studio project templates that show up under **File > New > Other** on the
*Delphi Projects* page.

```
Templates/
├── Gorilla3D.bdstemplatelib   the manifest - this is what gets registered
├── Icons/
│   └── Gorilla3D.ico          gallery icon for all items
├── Blank/                     Gorilla3D Blank Project
├── FirstPerson/               Gorilla3D First Person Scene
├── ThirdPerson/               Gorilla3D Third Person Scene
├── Physics/                   Gorilla3D Physics Character Scene
├── ModelViewer/               Gorilla3D Model Viewer
└── VolumeRendering/           Gorilla3D Volume Rendering
```

| Template | Scene |
|---|---|
| **Blank** | viewport, light, cube - navigated with the built-in design camera |
| **First Person** | ground, input controller, first person controller with the camera as its child |
| **Third Person** | ground, input controller, third person controller with a capsule body and a chase camera |
| **Physics** | random terrain + Q3 physics system with a terrain collider, physics character controller, third person controller, model and chase camera |
| **Model Viewer** | file drop, design camera with switchable navigation profile and navigation types, fit-to-model |
| **Volume Rendering** | `TGorillaVolumetricMesh` with the two front/back face pre passes, plus example code that generates and uploads its own 3D data |

## Registering

Manually: **Tools > Template Libraries** (German IDE: *Vorlagenbibliotheken*)
> *Add Reference…* > pick `Gorilla3D.bdstemplatelib` > *Open* > *OK*.

The reference is stored per user and per IDE version. Note that
`HKCU\Software\Embarcadero\BDS\<Version>\Repository\TemplateLibs` only holds the
column widths of that dialog - the list of registered libraries is written
elsewhere and has still to be pinned down for the installer.

Adding an `<Item>` to an already registered manifest does **not** need a
re-registration; the IDE re-reads the file when its timestamp changes.

## Where the items show up in the gallery

Every item carries a category chain, so the templates land in a **Gorilla3D**
node underneath *Delphi Projects* instead of directly in it:

```xml
<Categories>
  <Category Value="Gorilla3D.Templates" Parent="Borland.Delphi.New">Gorilla3D</Category>
  <Category Value="Borland.Delphi.New" Parent="Borland.Root">Delphi Projects</Category>
</Categories>
```

`Value` is the category id, `Parent` the id of the category above it, and the
element text is the display name. The chain is listed bottom-up, and a category
that does not exist yet is declared right here - no design time package and no
`IOTAGalleryCategoryManager.AddCategory` call needed. This mirrors what the IDE
does for its own items, see
`ObjRepos\<lang>\Repository.xml` (`Borland.Delphi.MultiDevice` hangs under
`Borland.Delphi.New` exactly this way).

The display name of an **existing** category is language dependent
(`Delphi Projects` / `Delphi-Projekte` / ...). It is matched by id, so the text
in the second line is only a label. If a localized IDE ever ends up showing two
`Delphi Projects` nodes, drop that second `<Category>` line and keep only the
Gorilla3D one.

## How it works

The IDE does **not** do token substitution. Creating a project from a template
copies the whole `FilePath` folder to the target directory, renames the
`.dproj`/`.dpr` to the name the user typed, sanitises the platform artwork
paths and opens the result. Unit names stay as they are - `Unit1.pas` and
`TForm1` keep their names, exactly like the built-in FMX templates.

Consequences for maintaining this folder:

* **One project per subfolder, nothing else in it.** Everything in the folder
  is copied verbatim, so no `__history`, no `__recovery`, no `Win64\Debug`,
  no `.dproj.local`, no `.dsk`, no `.identcache`.
* **No absolute paths in the `.dproj`.** The Gorilla3D units must come from
  the global library path that the package installer sets up.
* **Only registered components in the `.fmx`.** The Gorilla3D design-time
  package has to be installed before a template is used, otherwise the form
  will not open.
* The manifest is the only file that needs to be registered; all three items
  live in it.

## Delphi version compatibility

The `.dproj` files carry `ProjectVersion 20.4` (Delphi 12 Athens), the same as
the current Gorilla3D demos. RAD Studio silently migrates an older project
version on open, so these templates work in Delphi 12 and 13, but a project
saved by a *newer* IDE cannot be opened by an older one.

If templates are to be shipped for the whole supported range (10.1 Berlin …
13 Florence), add a version level and register the matching manifest per IDE:

```
Templates/
├── VER370/Gorilla3D.bdstemplatelib + Blank/ FirstPerson/ ThirdPerson/
├── VER360/…
└── …
```

## Manifest reference

`.bdstemplatelib` is a plain XML manifest. Elements used here:

| Element | Meaning |
|---|---|
| `TemplateLibrary id=` | unique id of the whole library |
| `Item id=` | unique id of one template |
| `Item Creator=` | `DelphiProjectRepositoryCreator` (Delphi) or `CBuilderProjectRepositoryCreator` (C++) - decides the gallery page |
| `FilePath` | project subfolder, relative to this manifest |
| `ProjectFile` | the `.dproj` inside that subfolder |
| `DefaultProjectName` | prefilled name in the New Project dialog |
| `Icon` | gallery icon, relative to this manifest |
| `Categories/Category` | gallery placement, see above |
| `Identities` | `RadStudio` |

The IDE parser also accepts `Frameworks`, `Platforms`, `Personality` and
`IDString`, which can be used to filter the gallery further.

## Materials

The scenes use `TGorillaBlinnMaterialSource`, not `TGorillaDefaultMaterialSource`
directly. Blinn derives from the node based default material but re-publishes
only the subset that makes sense for Blinn-Phong shading, which keeps the
Object Inspector readable.

Every material in these templates sets `UseTexture0 = False`, because none of
them uses a texture - leaving it on costs a sampler and a white default bitmap
for nothing. Switch it back on as soon as you assign a `Texture`.

See <https://docwiki.embarcadero.com/RADStudio/Athens/en/Creating_Template_Libraries>.
