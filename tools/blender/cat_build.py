"""Build the Nine Lives protagonist cat.

Triangle budget: 3,000-8,000 tris.
Bone list: root, spine_1, spine_2, neck, head, jaw, ear_l, ear_r,
front_upper_l/r, front_lower_l/r, front_paw_l/r, back_upper_l/r,
back_lower_l/r, back_paw_l/r, tail_1..tail_5.

Run:
  blender --background --python tools/blender/cat_build.py
"""

from __future__ import annotations

import math
from pathlib import Path

import bpy
from mathutils import Vector


ROOT = Path(__file__).resolve().parents[2]
EXPORT_PATH = ROOT / "assets" / "models" / "player" / "cat.glb"

SHOULDER_HEIGHT = 0.30
BODY_LENGTH = 0.46
BODY_RADIUS = (0.12, 0.08, 0.105)
HEAD_RADIUS = (0.105, 0.09, 0.09)
PAW_SCALE = (0.045, 0.06, 0.03)
TAIL_LENGTH = 0.32

BODY_COLOR = (0.95, 0.48, 0.16, 1.0)
BELLY_COLOR = (1.0, 0.74, 0.42, 1.0)
STRIPE_COLOR = (0.45, 0.18, 0.07, 1.0)
EAR_COLOR = (0.98, 0.58, 0.58, 1.0)
EYE_COLOR = (0.08, 0.12, 0.10, 1.0)
NOSE_PAD_COLOR = (0.18, 0.08, 0.07, 1.0)

ACTION_SPECS = {
    "idle": 36,
    "walk": 24,
    "run": 18,
    "pounce": 26,
    "claw_1": 16,
    "claw_2": 16,
    "claw_3": 20,
    "dodge_roll": 22,
    "hurt": 14,
    "faint": 30,
    "hairball_spit": 22,
    "rage_idle": 28,
    "rage_attack": 18,
}


def clear_scene() -> None:
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete()


def make_material(name: str, color: tuple[float, float, float, float]) -> bpy.types.Material:
    material = bpy.data.materials.new(name)
    material.diffuse_color = color
    material.use_nodes = True
    bsdf = material.node_tree.nodes.get("Principled BSDF")
    if bsdf is not None:
        bsdf.inputs["Base Color"].default_value = color
        bsdf.inputs["Roughness"].default_value = 0.82
    return material


def apply_transform(obj: bpy.types.Object) -> None:
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)


def shade_flat(obj: bpy.types.Object) -> None:
    for polygon in obj.data.polygons:
        polygon.use_smooth = False


def add_uv_ellipsoid(
    name: str,
    location: tuple[float, float, float],
    scale: tuple[float, float, float],
    material: bpy.types.Material,
    segments: int = 24,
    rings: int = 12,
) -> bpy.types.Object:
    bpy.ops.mesh.primitive_uv_sphere_add(
        segments=segments,
        ring_count=rings,
        radius=1.0,
        location=location,
    )
    obj = bpy.context.object
    obj.name = name
    obj.data.name = f"{name}_mesh"
    obj.scale = scale
    obj.data.materials.append(material)
    shade_flat(obj)
    apply_transform(obj)
    return obj


def add_cube(
    name: str,
    location: tuple[float, float, float],
    scale: tuple[float, float, float],
    material: bpy.types.Material,
    rotation: tuple[float, float, float] = (0.0, 0.0, 0.0),
) -> bpy.types.Object:
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=location, rotation=rotation)
    obj = bpy.context.object
    obj.name = name
    obj.data.name = f"{name}_mesh"
    obj.dimensions = scale
    obj.data.materials.append(material)
    apply_transform(obj)
    return obj


def add_cone(
    name: str,
    location: tuple[float, float, float],
    radius: float,
    depth: float,
    material: bpy.types.Material,
    rotation: tuple[float, float, float],
) -> bpy.types.Object:
    bpy.ops.mesh.primitive_cone_add(vertices=4, radius1=radius, radius2=0.01, depth=depth, location=location, rotation=rotation)
    obj = bpy.context.object
    obj.name = name
    obj.data.name = f"{name}_mesh"
    obj.data.materials.append(material)
    shade_flat(obj)
    apply_transform(obj)
    return obj


def make_cat_meshes(materials: dict[str, bpy.types.Material]) -> list[bpy.types.Object]:
    objects: list[bpy.types.Object] = []
    objects.append(add_uv_ellipsoid("cat_body", (0, 0, 0.19), BODY_RADIUS, materials["body"], 32, 16))
    objects.append(add_uv_ellipsoid("cat_belly_patch", (0, -0.045, 0.17), (0.075, 0.025, 0.075), materials["belly"], 20, 8))
    objects.append(add_uv_ellipsoid("cat_head", (0, -0.25, 0.29), HEAD_RADIUS, materials["body"], 28, 14))
    objects.append(add_uv_ellipsoid("cat_muzzle", (0, -0.325, 0.265), (0.065, 0.035, 0.04), materials["belly"], 16, 8))

    for side, x in [("l", -0.045), ("r", 0.045)]:
        objects.append(add_uv_ellipsoid(f"cat_eye_{side}", (x, -0.335, 0.31), (0.02, 0.012, 0.026), materials["eyes"], 12, 6))
        objects.append(add_cone(f"cat_ear_{side}", (x * 1.35, -0.235, 0.39), 0.045, 0.105, materials["ears"], (0.2, 0.0, 0.25 if side == "l" else -0.25)))

    objects.append(add_uv_ellipsoid("cat_nose", (0, -0.36, 0.272), (0.018, 0.012, 0.012), materials["pads"], 10, 5))

    paw_positions = {
        "front_l": (-0.07, -0.13, 0.045),
        "front_r": (0.07, -0.13, 0.045),
        "back_l": (-0.075, 0.14, 0.045),
        "back_r": (0.075, 0.14, 0.045),
    }
    for name, location in paw_positions.items():
        objects.append(add_uv_ellipsoid(f"cat_paw_{name}", location, PAW_SCALE, materials["pads"], 14, 7))

    for index, y in enumerate([-0.13, -0.03, 0.07, 0.17], start=1):
        objects.append(add_cube(f"cat_body_stripe_{index}", (0, y, 0.285), (0.19, 0.018, 0.026), materials["stripes"]))

    for index, x in enumerate([-0.042, 0.0, 0.042], start=1):
        objects.append(add_cube(f"cat_forehead_stripe_{index}", (x, -0.325, 0.36), (0.018, 0.075, 0.012), materials["stripes"], (0, 0, 0.18 * (index - 2))))

    for index in range(5):
        y = 0.20 + index * (TAIL_LENGTH / 5.0)
        z = 0.23 + math.sin(index / 4.0 * math.pi) * 0.08
        objects.append(add_uv_ellipsoid(f"cat_tail_{index + 1}", (0, y, z), (0.037, 0.055, 0.037), materials["body"], 14, 7))
        if index % 2 == 1:
            objects.append(add_cube(f"cat_tail_stripe_{index + 1}", (0, y, z), (0.075, 0.012, 0.075), materials["stripes"]))

    return objects


def create_armature() -> bpy.types.Object:
    bpy.ops.object.armature_add(enter_editmode=True, location=(0, 0, 0))
    armature = bpy.context.object
    armature.name = "cat_armature"
    armature.data.name = "cat_skeleton"
    bones = armature.data.edit_bones
    bones.remove(bones[0])

    def bone(name: str, head: tuple[float, float, float], tail: tuple[float, float, float], parent: str | None = None) -> None:
        edit_bone = bones.new(name)
        edit_bone.head = head
        edit_bone.tail = tail
        if parent is not None:
            edit_bone.parent = bones[parent]
            edit_bone.use_connect = False

    bone("root", (0, 0, 0.02), (0, 0, 0.12))
    bone("spine_1", (0, 0.1, 0.16), (0, -0.04, 0.21), "root")
    bone("spine_2", (0, -0.04, 0.21), (0, -0.19, 0.26), "spine_1")
    bone("neck", (0, -0.19, 0.26), (0, -0.245, 0.3), "spine_2")
    bone("head", (0, -0.245, 0.3), (0, -0.335, 0.31), "neck")
    bone("jaw", (0, -0.31, 0.27), (0, -0.36, 0.255), "head")
    bone("ear_l", (-0.055, -0.24, 0.35), (-0.075, -0.235, 0.43), "head")
    bone("ear_r", (0.055, -0.24, 0.35), (0.075, -0.235, 0.43), "head")

    for side, x in [("l", -0.07), ("r", 0.07)]:
        bone(f"front_upper_{side}", (x, -0.12, 0.18), (x, -0.13, 0.1), "spine_2")
        bone(f"front_lower_{side}", (x, -0.13, 0.1), (x, -0.13, 0.045), f"front_upper_{side}")
        bone(f"front_paw_{side}", (x, -0.13, 0.045), (x, -0.19, 0.035), f"front_lower_{side}")
        bone(f"back_upper_{side}", (x, 0.12, 0.17), (x, 0.14, 0.1), "spine_1")
        bone(f"back_lower_{side}", (x, 0.14, 0.1), (x, 0.14, 0.045), f"back_upper_{side}")
        bone(f"back_paw_{side}", (x, 0.14, 0.045), (x, 0.2, 0.035), f"back_lower_{side}")

    last_parent = "spine_1"
    for index in range(1, 6):
        y0 = 0.16 + (index - 1) * 0.065
        y1 = 0.16 + index * 0.065
        z0 = 0.21 + math.sin((index - 1) / 4 * math.pi) * 0.08
        z1 = 0.21 + math.sin(index / 4 * math.pi) * 0.08
        bone(f"tail_{index}", (0, y0, z0), (0, y1, z1), last_parent)
        last_parent = f"tail_{index}"

    bpy.ops.object.mode_set(mode="OBJECT")
    return armature


def parent_to_armature(meshes: list[bpy.types.Object], armature: bpy.types.Object) -> None:
    bpy.ops.object.select_all(action="DESELECT")
    for obj in meshes:
        obj.select_set(True)
    armature.select_set(True)
    bpy.context.view_layer.objects.active = armature
    bpy.ops.object.parent_set(type="ARMATURE_AUTO")


def set_pose(armature: bpy.types.Object, rotations: dict[str, tuple[float, float, float]], frame: int) -> None:
    bpy.context.view_layer.objects.active = armature
    bpy.ops.object.mode_set(mode="POSE")
    for bone_name, rotation in rotations.items():
        pose_bone = armature.pose.bones.get(bone_name)
        if pose_bone is None:
            continue
        pose_bone.rotation_mode = "XYZ"
        pose_bone.rotation_euler = rotation
        pose_bone.keyframe_insert(data_path="rotation_euler", frame=frame)
    bpy.ops.object.mode_set(mode="OBJECT")


def reset_pose(armature: bpy.types.Object, frame: int) -> None:
    neutral = {bone.name: (0.0, 0.0, 0.0) for bone in armature.pose.bones}
    set_pose(armature, neutral, frame)


def make_action(armature: bpy.types.Object, name: str, length: int) -> bpy.types.Action:
    action = bpy.data.actions.new(name)
    action.use_fake_user = True
    armature.animation_data.action = action
    reset_pose(armature, 1)

    mid = max(2, length // 2)
    if name in {"walk", "run"}:
        swing = 0.55 if name == "walk" else 0.85
        set_pose(armature, {
            "front_upper_l": (swing, 0, 0),
            "front_upper_r": (-swing, 0, 0),
            "back_upper_l": (-swing, 0, 0),
            "back_upper_r": (swing, 0, 0),
            "tail_2": (0.0, 0.22, 0.0),
        }, mid)
    elif name.startswith("claw") or name == "rage_attack":
        side = "l" if name in {"claw_1", "claw_3", "rage_attack"} else "r"
        set_pose(armature, {
            f"front_upper_{side}": (-1.1, 0.0, 0.35 if side == "l" else -0.35),
            f"front_lower_{side}": (-0.6, 0.0, 0.0),
            "spine_2": (-0.18, 0.0, 0.0),
            "head": (-0.12, 0.0, 0.0),
        }, mid)
    elif name == "pounce":
        set_pose(armature, {"spine_1": (-0.45, 0, 0), "spine_2": (-0.35, 0, 0), "tail_3": (0.4, 0, 0)}, mid)
    elif name == "dodge_roll":
        set_pose(armature, {"root": (0, 0, math.pi), "tail_2": (0.8, 0, 0)}, mid)
    elif name == "hurt":
        set_pose(armature, {"spine_2": (0.35, 0.0, 0.0), "head": (0.45, 0.0, 0.0), "tail_1": (-0.6, 0, 0)}, mid)
    elif name == "faint":
        set_pose(armature, {"root": (0, math.radians(72), 0), "spine_1": (0.35, 0, 0), "tail_2": (-0.8, 0, 0)}, mid)
    elif name == "hairball_spit":
        set_pose(armature, {"head": (-0.35, 0, 0), "jaw": (0.55, 0, 0), "spine_2": (-0.15, 0, 0)}, mid)
    elif name == "rage_idle":
        set_pose(armature, {"tail_2": (0.0, 0.35, 0.0), "head": (-0.12, 0.0, 0.0)}, mid)
    else:
        set_pose(armature, {"tail_2": (0.0, 0.16, 0.0), "head": (-0.04, 0.0, 0.0)}, mid)

    reset_pose(armature, length)
    action.frame_range = (1, length)

    track = armature.animation_data.nla_tracks.new()
    track.name = name
    strip = track.strips.new(name, 1, action)
    strip.action_frame_start = 1
    strip.action_frame_end = length
    track.mute = True
    return action


def create_animations(armature: bpy.types.Object) -> None:
    armature.animation_data_create()
    for name, length in ACTION_SPECS.items():
        make_action(armature, name, length)
    armature.animation_data.action = bpy.data.actions["idle"]


def export_glb() -> None:
    EXPORT_PATH.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.export_scene.gltf(
        filepath=str(EXPORT_PATH),
        export_format="GLB",
        export_yup=True,
        export_apply=True,
        export_animations=True,
        export_nla_strips=True,
        export_anim_slide_to_zero=True,
    )


def main() -> None:
    clear_scene()
    materials = {
        "body": make_material("cat_body_orange", BODY_COLOR),
        "belly": make_material("cat_belly_cream", BELLY_COLOR),
        "stripes": make_material("cat_tiger_stripes", STRIPE_COLOR),
        "ears": make_material("cat_inner_ear", EAR_COLOR),
        "eyes": make_material("cat_eye_dark", EYE_COLOR),
        "pads": make_material("cat_nose_paw_pads", NOSE_PAD_COLOR),
    }
    meshes = make_cat_meshes(materials)
    armature = create_armature()
    parent_to_armature(meshes, armature)
    create_animations(armature)
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=False)
    export_glb()
    print(f"Exported {EXPORT_PATH}")


if __name__ == "__main__":
    main()
